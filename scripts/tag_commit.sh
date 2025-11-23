#!/usr/bin/env bash
set -euo pipefail

# 1. Определяем SHA коммита
COMMIT_SHA="${1:-${CODEBUILD_RESOLVED_SOURCE_VERSION:-}}"

if [ -z "${COMMIT_SHA}" ]; then
  echo "[tag_commit] ERROR: Commit SHA is empty (COMMIT_SHA/CODEBUILD_RESOLVED_SOURCE_VERSION)"
  exit 1
fi

# 2. Проверяем переменные окружения из CodeBuild
if [ -z "${GITHUB_OWNER:-}" ] || [ -z "${GITHUB_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "[tag_commit] ERROR: GITHUB_OWNER / GITHUB_REPO / GITHUB_TOKEN not set"
  echo "  GITHUB_OWNER='${GITHUB_OWNER:-}'"
  echo "  GITHUB_REPO='${GITHUB_REPO:-}'"
  exit 1
fi

TAG_NAME="deployed-dev"
API_BASE="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}"

echo "[tag_commit] Using commit: ${COMMIT_SHA}"
echo "[tag_commit] Tag name: ${TAG_NAME}"
echo "[tag_commit] Repo: ${GITHUB_OWNER}/${GITHUB_REPO}"

############################################
# 3. Проверяем — есть ли уже такой tag ref
############################################

echo "[tag_commit] Checking if tag ref refs/tags/${TAG_NAME} exists..."

GET_STATUS=$(
  curl -sS -o /tmp/tag_get.json -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_BASE}/git/ref/tags/${TAG_NAME}" || echo "000"
)

echo "[tag_commit] GET status: ${GET_STATUS}"
cat /tmp/tag_get.json || true
echo

############################################
# 4. Если 200 — обновляем ref (PATCH)
#    Если 404 — создаём новый ref (POST)
############################################

if [ "${GET_STATUS}" = "200" ]; then
  echo "[tag_commit] Tag exists, updating ref to ${COMMIT_SHA}..."

  PATCH_STATUS=$(
    curl -sS -o /tmp/tag_patch.json -w "%{http_code}" \
      -X PATCH \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"sha\": \"${COMMIT_SHA}\", \"force\": true}" \
      "${API_BASE}/git/refs/tags/${TAG_NAME}" || echo "000"
  )

  echo "[tag_commit] PATCH status: ${PATCH_STATUS}"
  cat /tmp/tag_patch.json || true
  echo

  if [ "${PATCH_STATUS}" != "200" ]; then
    echo "[tag_commit] ERROR: Failed to update tag ref"
    exit 1
  fi

elif [ "${GET_STATUS}" = "404" ]; then
  echo "[tag_commit] Tag does not exist, creating new ref for ${COMMIT_SHA}..."

  POST_STATUS=$(
    curl -sS -o /tmp/tag_post.json -w "%{http_code}" \
      -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"ref\": \"refs/tags/${TAG_NAME}\", \"sha\": \"${COMMIT_SHA}\"}" \
      "${API_BASE}/git/refs" || echo "000"
  )

  echo "[tag_commit] POST status: ${POST_STATUS}"
  cat /tmp/tag_post.json || true
  echo

  if [ "${POST_STATUS}" != "201" ] && [ "${POST_STATUS}" != "200" ]; then
    echo "[tag_commit] ERROR: Failed to create tag ref"
    exit 1
  fi

else
  echo "[tag_commit] ERROR: Unexpected GET status from GitHub: ${GET_STATUS}"
  cat /tmp/tag_get.json || true
  exit 1
fi

echo "[tag_commit] SUCCESS: Tag ${TAG_NAME} now points to ${COMMIT_SHA}"

