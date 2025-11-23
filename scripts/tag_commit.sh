#!/usr/bin/env bash
set -euo pipefail

TAG_NAME="deployed-dev"

# SHA коммита из CodeBuild
COMMIT_SHA="${CODEBUILD_RESOLVED_SOURCE_VERSION:-}"

if [ -z "$COMMIT_SHA" ]; then
  echo "ERROR: CODEBUILD_RESOLVED_SOURCE_VERSION is empty. Cannot tag."
  exit 1
fi

if [ -z "${GITHUB_OWNER:-}" ] || [ -z "${GITHUB_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_OWNER, GITHUB_REPO or GITHUB_TOKEN is not set"
  exit 1
fi

API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}"

echo "Tagging commit ${COMMIT_SHA} with tag ${TAG_NAME}"
echo "Repo: ${GITHUB_OWNER}/${GITHUB_REPO}"

# 1. Проверяем, есть ли тег
echo "Checking if tag already exists..."
GET_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  "${API_URL}/git/refs/tags/${TAG_NAME}" || true)

echo "GET /git/refs/tags/${TAG_NAME} -> HTTP ${GET_STATUS}"

if [ "$GET_STATUS" -eq 200 ]; then
  echo "Tag exists, updating reference..."
  PATCH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"sha\": \"${COMMIT_SHA}\", \"force\": true}" \
    "${API_URL}/git/refs/tags/${TAG_NAME}" || true)

  echo "PATCH /git/refs/tags/${TAG_NAME} -> HTTP ${PATCH_STATUS}"

  if [ "$PATCH_STATUS" -lt 200 ] || [ "$PATCH_STATUS" -ge 300 ]; then
    echo "ERROR: failed to update tag. HTTP ${PATCH_STATUS}"
    exit 1
  fi
else
  echo "Tag does not exist, creating new tag..."
  POST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"ref\": \"refs/tags/${TAG_NAME}\", \"sha\": \"${COMMIT_SHA}\"}" \
    "${API_URL}/git/refs" || true)

  echo "POST /git/refs -> HTTP ${POST_STATUS}"

  if [ "$POST_STATUS" -lt 200 ] || [ "$POST_STATUS" -ge 300 ]; then
    echo "ERROR: failed to create tag. HTTP ${POST_STATUS}"
    exit 1
  fi
fi

echo "SUCCESS: tag ${TAG_NAME} now points to ${COMMIT_SHA}"

