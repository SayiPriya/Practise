#!/usr/bin/env bash
# Phase 5: Create release branch
# Usage: 06-create-branch.sh <release_version> [commit_ref]
# Example: 06-create-branch.sh 2026.07           (branch from HEAD)
#          06-create-branch.sh 2026.07 abc123f    (branch from specific commit)
set -e

VER="$1"
COMMIT_REF="${2:-}"

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version> [commit_ref]"
  exit 1
fi

cd ~/src/"$VER"

if [ -n "$COMMIT_REF" ]; then
  echo ">>> Creating release branch '$VER' from commit: $COMMIT_REF"
  git checkout -b "$VER" "$COMMIT_REF"
else
  echo ">>> Creating release branch '$VER' from HEAD"
  git checkout -b "$VER"
fi

echo ""
echo "=== Release branch '$VER' created ==="
echo "Current commit: $(git rev-parse HEAD)"
