#!/usr/bin/env bash
set -euo pipefail

# Берём SHA из аргумента ИЛИ из CODEBUILD_RESOLVED_SOURCE_VERSION
COMMIT_SHA="${1:-${CODEBUILD_RESOLVED_SOURCE_VERSION:-}}"

if [ -z "$COMMIT_SHA" ]; then
  echo "Commit SHA is required as first argument or CODEBUILD_RESOLVED_SOURCE_VERSION"
  exit 1
fi

if [ -z "${GITHUB_OWNER:-}" ] || [ -z "${GITHUB_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_OWNER, GITHUB_REPO or GITHUB_TOKEN is not set"
  exit 1
fi

TAG_NAME="deployed-dev"
API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}"

echo "Tagging commit ${COMMIT_SHA} with tag ${TAG_NAME}"

# Проверяем, есть ли тег
status_code=$(
  curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_URL}/git/refs/tags/${TAG_NAME}"
)

if [ "$status_code" -eq 200 ]; then
  echo "Tag exists, updating reference..."
  curl -s \
    -X PATCH \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -d "{\"sha\": \"${COMMIT_SHA}\", \"force\": true}" \
    "${API_URL}/git/refs/tags/${TAG_NAME}" > /dev/null
else
  echo "Tag does not exist, creating new tag..."
  curl -s \
    -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -d "{\"ref\": \"refs/tags/${TAG_NAME}\", \"sha\": \"${COMMIT_SHA}\"}" \
    "${API_URL}/git/refs" > /dev/null
fi

echo "Tag ${TAG_NAME} now points to ${COMMIT_SHA}"

