#!/usr/bin/env bash
set -euo pipefail
# Run from repository root: ./tomcat-image/scripts/create-tag.sh patch|minor|major
BUMP="${1:-}"
CONFIG="tomcat-image/config.json"
APP_CONFIG="tomcat-image/app/src/main/webapp/config.json"
if [[ ! "$BUMP" =~ ^(patch|minor|major)$ ]]; then echo "Usage: $0 patch|minor|major" >&2; exit 1; fi
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
CURRENT="$(jq -r '.application.version' "$CONFIG")"
if [[ ! "$CURRENT" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then echo "Invalid SemVer: $CURRENT" >&2; exit 1; fi
IFS=. read -r MAJOR MINOR PATCH <<< "$CURRENT"
case "$BUMP" in
  major) ((MAJOR+=1)); MINOR=0; PATCH=0 ;;
  minor) ((MINOR+=1)); PATCH=0 ;;
  patch) ((PATCH+=1)) ;;
esac
VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="tomcat-v${VERSION}"
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then echo "Tag already exists: $TAG" >&2; exit 1; fi
for FILE in "$CONFIG" "$APP_CONFIG"; do tmp="$(mktemp)"; jq --arg version "$VERSION" '.application.version = $version' "$FILE" > "$tmp"; mv "$tmp" "$FILE"; done
git add "$CONFIG" "$APP_CONFIG"
git commit -m "chore(tomcat): release ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"
echo "Created $TAG locally. Push with: git push origin HEAD:main && git push origin $TAG"
