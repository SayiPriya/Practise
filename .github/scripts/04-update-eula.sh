#!/usr/bin/env bash
# Phase 3b: Update EULA and commit (only run if 03-check-eula.sh reported differences)
# Usage: 04-update-eula.sh <release_version> <release_task_number>
# Example: 04-update-eula.sh 2026.07 RLC-1234
set -e

VER="$1"
TASK_NUM="$2"

if [ -z "$VER" ] || [ -z "$TASK_NUM" ]; then
  echo "ERROR: Release version and task number are required."
  echo "Usage: $0 <release_version> <release_task_number>"
  exit 1
fi

cd ~/src/"$VER"

COMMIT_MSG="$TASK_NUM Update SDS2 EULA(s)"

echo ">>> Updating EULA files..."

# Update EULA files in install_src
cd install_src

if [ -f "../SDS2_EULA.rtf" ]; then
  mv ../SDS2_EULA.rtf ./nsis/license.rtf
  echo "  Copied SDS2_EULA.rtf -> nsis/license.rtf"
fi

if [ -f "../SDS2_TOOLBOX_EULA.rtf" ]; then
  mv ../SDS2_TOOLBOX_EULA.rtf ./nsis/license_toolbox.rtf
  echo "  Copied SDS2_TOOLBOX_EULA.rtf -> nsis/license_toolbox.rtf"
fi

echo ">>> Committing install_src submodule changes..."
git commit -a -m "$COMMIT_MSG"
git push

cd ..

echo ">>> Committing parent repo changes..."
git commit -a -m "$COMMIT_MSG"
echo ""
echo "============================================="
echo "  EULA committed locally."
echo "  Run 'git push' manually or via PR process."
echo "============================================="
