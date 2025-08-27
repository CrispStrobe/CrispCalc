#!/bin/bash
# File: macos/copy_native_lib.sh
# Copy native library to app bundle during Xcode build

set -e

PROJECT_ROOT="${SRCROOT}/.."
NATIVE_LIB_NAME="libcas_wrapper.dylib"
SOURCE_LIB="${PROJECT_ROOT}/${NATIVE_LIB_NAME}"
TARGET_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/MacOS"
TARGET_LIB="${TARGET_DIR}/${NATIVE_LIB_NAME}"

echo "Copy Native Library Script"
echo "Project root: ${PROJECT_ROOT}"
echo "Source library: ${SOURCE_LIB}"
echo "Target directory: ${TARGET_DIR}"

# Create target directory
mkdir -p "${TARGET_DIR}"

# Check if source library exists
if [ -f "${SOURCE_LIB}" ]; then
    echo "Found native library, copying to app bundle..."
    cp "${SOURCE_LIB}" "${TARGET_LIB}"
    chmod 755 "${TARGET_LIB}"
    echo "Native library copied successfully"
else
    echo "Warning: Native library not found at ${SOURCE_LIB}"
    echo "App will run with fallback calculator only"
fi
