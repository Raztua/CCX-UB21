#!/bin/bash
# ==============================================================================
#  Installer Script for UB21 User Beam Element in CalculiX CCX 2.23
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/ub21_ccx223.patch"

echo "======================================================================"
echo "      CalculiX CCX 2.23 — UB21 Beam Element Auto-Installer"
echo "======================================================================"

if [ ! -f "$PATCH_FILE" ]; then
    echo "ERROR: Patch file '$PATCH_FILE' not found!"
    exit 1
fi

# Determine target directory
TARGET_DIR="${1:-.}"

# Find src directory
if [ -f "${TARGET_DIR}/ccx_2.23.c" ]; then
    SRC_DIR="$(cd "$TARGET_DIR" && pwd)"
elif [ -d "${TARGET_DIR}/CalculiX/ccx_2.23/src" ]; then
    SRC_DIR="$(cd "${TARGET_DIR}/CalculiX/ccx_2.23/src" && pwd)"
elif [ -d "${TARGET_DIR}/src" ] && [ -f "${TARGET_DIR}/src/ccx_2.23.c" ]; then
    SRC_DIR="$(cd "${TARGET_DIR}/src" && pwd)"
else
    echo "ERROR: Could not locate CCX 2.23 src directory in '$TARGET_DIR'."
    echo "Usage: $0 [/path/to/ccx_2.23/src]"
    exit 1
fi

echo "Target CCX source directory: $SRC_DIR"
cd "$SRC_DIR"

# Apply patch
echo ""
echo "--> Applying UB21 patch..."
if patch -p4 --dry-run < "$PATCH_FILE" > /dev/null 2>&1; then
    patch -p4 < "$PATCH_FILE"
elif patch -p1 --dry-run < "$PATCH_FILE" > /dev/null 2>&1; then
    patch -p1 < "$PATCH_FILE"
elif patch -p0 --dry-run < "$PATCH_FILE" > /dev/null 2>&1; then
    patch -p0 < "$PATCH_FILE"
else
    echo "ERROR: Failed to apply patch cleanly. Check if CCX source version is 2.23."
    exit 1
fi

echo "--> UB21 source files successfully patched!"

# Build CCX
echo ""
echo "--> Building ccx_2.23 binary..."
NPROC=$(nproc 2>/dev/null || echo 2)
make -j"$NPROC"

if [ -f "$SRC_DIR/ccx_2.23" ]; then
    echo ""
    echo "======================================================================"
    echo " SUCCESS: CCX 2.23 with UB21 User Beam Element built successfully!"
    echo " Binary path: ${SRC_DIR}/ccx_2.23"
    echo "======================================================================"
else
    echo ""
    echo "ERROR: Compilation finished but binary 'ccx_2.23' was not created."
    exit 1
fi
