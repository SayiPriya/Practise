#!/usr/bin/env bash
# Phase 3: Check EULA status (reports only, does not modify)
# Usage: 03-check-eula.sh <release_version>
# Example: 03-check-eula.sh 2026.07
#
# Exit codes:
#   0 = EULAs match (no update needed)
#   2 = EULAs differ (update needed)
#   1 = error
set -e

VER="$1"

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version>"
  exit 1
fi

cd ~/src/"$VER"

echo "============================================="
echo "  EULA CHECK: $VER"
echo "============================================="
echo ""

# Capture output from UpdateEULA
if [ -f "./install_src/UpdateEULA.py" ]; then
  echo ">>> Running UpdateEULA.py..."
  EULA_OUTPUT=$(python3 ./install_src/UpdateEULA.py 2>&1 || python ./install_src/UpdateEULA.py 2>&1)
elif [ -f "./install_src/UpdateEULA" ]; then
  echo ">>> Running UpdateEULA (legacy)..."
  EULA_OUTPUT=$(./install_src/UpdateEULA 2>&1)
else
  echo "WARNING: Neither UpdateEULA.py nor UpdateEULA found!"
  exit 1
fi

echo "$EULA_OUTPUT"
echo ""

# Check if output contains "differ" (case-insensitive) without relying on grep exit codes.
EULA_OUTPUT_LC=$(printf '%s' "$EULA_OUTPUT" | tr '[:upper:]' '[:lower:]')
if [[ "$EULA_OUTPUT_LC" == *"differ"* ]]; then
  echo "============================================="
  echo "  RESULT: EULAs DIFFER — update is needed"
  echo "============================================="
  exit 2
else
  echo "============================================="
  echo "  RESULT: EULAs MATCH — no update needed"
  echo "============================================="
  exit 0
fi
