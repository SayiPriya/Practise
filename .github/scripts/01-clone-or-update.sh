#!/usr/bin/env bash
# Phase 1: Clone a fresh repo or update an existing one
# Usage: 01-clone-or-update.sh <release_version> [branch_override]
# Example: 01-clone-or-update.sh 2026.07
#          01-clone-or-update.sh 2026.07 production
set -e

VER="$1"
BRANCH_OVERRIDE="${2:-}"

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version> [branch_override]"
  exit 1
fi

cd ~/src

if [ ! -d "$VER" ]; then
  echo ">>> Directory does not exist. Cloning fresh repository..."
  git clone git@github.com:Allplan-GmbH/SDS2Prod-sds2.git "$VER"
  cd "$VER"

  if [ -n "$BRANCH_OVERRIDE" ]; then
    echo ">>> Checking out branch: $BRANCH_OVERRIDE"
    git checkout -t "remotes/origin/$BRANCH_OVERRIDE"
  fi

  echo ">>> Initializing submodules..."
  git submodule update --init --recursive
else
  echo ">>> Directory exists. Performing update..."
  cd "$VER"

  if [ ! -d .git ]; then
    echo "ERROR: Directory exists but is not a git repository!"
    exit 1
  fi

  echo ">>> Fetching latest changes..."
  git fetch --all

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo ">>> Current branch: $CURRENT_BRANCH"

  echo ">>> Ensuring branch is tracking upstream..."
  git branch --set-upstream-to="origin/$CURRENT_BRANCH" || true

  echo ">>> Resetting to upstream HEAD..."
  git reset --hard "origin/$CURRENT_BRANCH"

  echo ">>> Cleaning untracked files..."
  git clean -fd

  echo ">>> Updating submodules..."
  git submodule update --init --recursive

  echo ">>> Submodule status:"
  git submodule status
fi

chmod g+w ~/src/"$VER"
echo ""
echo "=== Phase 1 Complete ==="
echo "Repo location: ~/src/$VER"
