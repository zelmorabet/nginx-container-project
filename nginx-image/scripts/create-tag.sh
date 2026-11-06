#!/usr/bin/env bash
set -euo pipefail

# Local helper: ./scripts/create-tag.sh patch|minor|major
BUMP="${1:-}"
if [[ ! "$BUMP" =~ ^(patch|minor|major)$ ]]; then
  echo "Usage: $0 patch|minor|major" >&2
  exit 1
fi

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v git >/dev/null || { echo "git is required" >&2; exit 1; }

CURRENT="$(jq -r '.application.version' config.json)"
if [[ ! "$CURRENT" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Invalid SemVer in config.json: $CURRENT" >&2
  exit 1
fi
IFS=. read -r MAJOR MINOR PATCH <<< "$CURRENT"
case "$BUMP" in
  major) ((MAJOR+=1)); MINOR=0; PATCH=0 ;;
  minor) ((MINOR+=1)); PATCH=0 ;;
  patch) ((PATCH+=1)) ;;
esac
NEXT="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEXT}"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "Tag already exists: $TAG" >&2
  exit 1
fi

tmp="$(mktemp)"
jq --arg version "$NEXT" '.application.version = $version' config.json > "$tmp"
mv "$tmp" config.json
git add config.json
git commit -m "chore(release): ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"
echo "Created local release $TAG. Push with: git push origin HEAD && git push origin $TAG"
