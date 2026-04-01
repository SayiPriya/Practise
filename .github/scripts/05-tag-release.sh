#!/usr/bin/env bash
# Phase 4: Create release candidate tag
# Usage: 05-tag-release.sh <release_version> <rc_number>
# Example: 05-tag-release.sh 2026.07 1
#          Creates tag: RELEASE_202607_rc1
set -e

VER="$1"
RC_NUM="$2"

if [ -z "$VER" ] || [ -z "$RC_NUM" ]; then
  echo "ERROR: Release version and RC number are required."
  echo "Usage: $0 <release_version> <rc_number>"
  exit 1
fi

cd ~/src/"$VER"

# Convert 2026.07 -> 202607 for tag name
VER_NODOT=$(echo "$VER" | tr -d '.')
TAG_NAME="RELEASE_${VER_NODOT}_rc${RC_NUM}"

# If the tag already exists, keep incrementing RC number until we find a free one
while git tag | grep -qx "$TAG_NAME"; do
  echo ">>> Tag $TAG_NAME already exists. Incrementing RC number..."
  RC_NUM=$((RC_NUM + 1))
  TAG_NAME="RELEASE_${VER_NODOT}_rc${RC_NUM}"
done

echo ">>> Creating tag: $TAG_NAME"
git tag -m "SDS2 $VER release candidate" "$TAG_NAME"

echo ">>> Pushing tag to origin..."
git push origin tag "$TAG_NAME"

echo ""
echo "=== Tag $TAG_NAME created and pushed ==="
