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

# Delete local branch if it already exists
if git show-ref --verify --quiet "refs/heads/$VER"; then
  echo ">>> Local branch '$VER' already exists. Deleting it..."
  git checkout HEAD --detach 2>/dev/null || true   # detach so we can delete current branch if needed
  git branch -D "$VER"
fi

# Delete remote branch if it already exists
if git ls-remote --exit-code --heads origin "$VER" > /dev/null 2>&1; then
  echo ">>> Remote branch '$VER' already exists. Deleting it..."
  git push origin --delete "$VER"
fi

# Create the branch
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
