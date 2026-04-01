#!/usr/bin/env bash
# Phase 7: Run the build
# Usage: 07-build-release.sh <release_version> [options]
#
# Options (pass as-is, they go directly to build_release.py):
#   -V "SPECIAL_VERSION"  e.g. "2026-Beta-1" (no spaces!)
#   -r                    real release (requires signing, archives nm files)
#   -U                    alpha version specific folders
#   -E                    build education
#   -i                    interactive mode
#
# Example: 07-build-release.sh 2026.07 -V "2026-Beta-1" -r -E
set -e

VER="$1"
shift  # remove version from args, rest are build flags

if [ -z "$VER" ]; then
  echo "ERROR: Release version is required."
  echo "Usage: $0 <release_version> [build_release.py options...]"
  exit 1
fi

# Convert 2026.07 -> 202607 for -v flag
VER_NODOT=$(echo "$VER" | tr -d '.')

cd ~/src/"$VER"

echo "============================================="
echo "  BUILD RELEASE: $VER"
echo "  Version (no dot): $VER_NODOT"
echo "  Extra flags: $*"
echo "============================================="
echo ""

# Determine which build script exists
if [ -f "./install_src/build_release.py" ]; then
  BUILD_CMD="./install_src/build_release.py"
elif [ -f "./install_src/build_release" ]; then
  BUILD_CMD="./install_src/build_release"
else
  echo "ERROR: build_release.py not found!"
  exit 1
fi

echo ">>> Running: $BUILD_CMD -v $VER_NODOT $*"
$BUILD_CMD -v "$VER_NODOT" "$@"

echo ""
echo "=== Build Complete ==="
