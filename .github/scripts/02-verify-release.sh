#!/usr/bin/env bash
# Phase 2: Verify release prerequisites (branch, version.h, preferred-tags)
# Usage: 02-verify-release.sh <release_version> <version_major>
# Example: 02-verify-release.sh 2026.07 2026
#
# This script PRINTS information for human review.
# It does NOT make changes — it only reports.
set -e

VER="$1"
VER_MAJ="${2:-}"

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version> <version_major>"
  exit 1
fi

cd ~/src/"$VER"

echo "============================================="
echo "  RELEASE VERIFICATION: $VER"
echo "============================================="
echo ""

# --- Check current branch ---
echo "--- Branch Info ---"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"
echo ""
echo "All branches:"
git branch -a
echo ""

# --- Check version.h ---
VERSION_FILE="include/sds2/version.h"
if [ -f "$VERSION_FILE" ]; then
  echo "--- version.h Contents ---"
  cat "$VERSION_FILE"
  echo ""
else
  echo "WARNING: $VERSION_FILE not found!"
  echo ""
fi

# --- Check preferred-tags ---
TAGS_FILE="etc/preferred-tags"
if [ -f "$TAGS_FILE" ]; then
  echo "--- preferred-tags Contents ---"
  cat "$TAGS_FILE"
  echo ""
else
  echo "WARNING: $TAGS_FILE not found!"
  echo ""
fi

# --- Submodule status ---
echo "--- Submodule Status ---"
git submodule status
echo ""

echo "============================================="
echo "  REVIEW THE ABOVE OUTPUT CAREFULLY"
echo "  - Is the branch correct for this release?"
echo "  - Is version.h set to $VER?"
if [ -n "$VER_MAJ" ]; then
  echo "  - Is preferred-tags updated for $VER_MAJ?"
fi
echo "============================================="
