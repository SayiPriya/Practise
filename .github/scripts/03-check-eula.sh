#!/usr/bin/env bash
# Phase 3: Check EULA status (reports only, does not modify)
# Usage: 03-check-eula.sh <release_version>
# Example: 03-check-eula.sh 2026.07
#
# Exit codes:
#   0 = EULAs match (no update needed)
#   2 = EULAs differ (update needed)
#   1 = error

VER="$1"

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version>"
  exit 1
fi

cd ~/src/"$VER" || exit 1

echo "============================================="
echo "  EULA CHECK: $VER"
echo "============================================="
echo ""

# Run UpdateEULA and capture output
EULA_OUTPUT=""
if [ -f "./install_src/UpdateEULA.py" ]; then
  echo ">>> Running UpdateEULA.py..."
  EULA_OUTPUT=$(python3 ./install_src/UpdateEULA.py 2>&1 || python ./install_src/UpdateEULA.py 2>&1) || true
elif [ -f "./install_src/UpdateEULA" ]; then
  echo ">>> Running UpdateEULA (legacy)..."
  EULA_OUTPUT=$(./install_src/UpdateEULA 2>&1) || true
else
  echo "WARNING: Neither UpdateEULA.py nor UpdateEULA found!"
  exit 1
fi

echo "$EULA_OUTPUT"
echo ""

# Check if output contains "differ" (case-insensitive)
# Use grep safely without relying on its exit code
DIFFER_COUNT=$(echo "$EULA_OUTPUT" | grep -ic "differ" || echo "0")

if [ "$DIFFER_COUNT" -gt 0 ]; then
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
