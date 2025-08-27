#!/bin/bash
# File: macos/Runner/copy_native_lib.sh
# This script copies the native library to the app bundle during build

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
NATIVE_LIB_NAME="libcas_wrapper.dylib"
SOURCE_LIB="${PROJECT_ROOT}/${NATIVE_LIB_NAME}"
TARGET_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/MacOS"
TARGET_LIB="${TARGET_DIR}/${NATIVE_LIB_NAME}"

echo "🔍 Searching for native library..."
echo "Source path: ${SOURCE_LIB}"
echo "Target path: ${TARGET_LIB}"

# Function to build native library
build_native_library() {
    echo "🔨 Building native library..."
    cd "${PROJECT_ROOT}/native"
    
    # Create build directory if it doesn't exist
    mkdir -p build
    cd build
    
    # Configure and build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(sysctl -n hw.ncpu)
    
    # Copy to project root
    if [ -f "libcas_wrapper.dylib" ]; then
        cp libcas_wrapper.dylib ../../
        echo "✅ Native library built successfully"
        return 0
    else
        echo "❌ Failed to build native library"
        return 1
    fi
}

# Check if native library exists at source
if [ -f "${SOURCE_LIB}" ]; then
    echo "✅ Found native library at source location"
else
    echo "⚠️  Native library not found at ${SOURCE_LIB}"
    echo "Attempting to build..."
    
    if ! build_native_library; then
        echo "❌ Failed to build native library"
        echo "⚠️  App will run without native CAS support"
        exit 0  # Don't fail the build, just continue without native lib
    fi
fi

# Create target directory if it doesn't exist
mkdir -p "${TARGET_DIR}"

# Copy the library
if [ -f "${SOURCE_LIB}" ]; then
    echo "📦 Copying ${NATIVE_LIB_NAME} to app bundle..."
    cp "${SOURCE_LIB}" "${TARGET_LIB}"
    
    # Set appropriate permissions
    chmod 755 "${TARGET_LIB}"
    
    # Verify the copy
    if [ -f "${TARGET_LIB}" ]; then
        echo "✅ Native library successfully bundled!"
        echo "📍 Library location: ${TARGET_LIB}"
        
        # Optional: Check library dependencies
        echo "📋 Library info:"
        file "${TARGET_LIB}"
        echo "🔗 Dependencies:"
        otool -L "${TARGET_LIB}" || true
    else
        echo "❌ Failed to copy library to app bundle"
        exit 1
    fi
else
    echo "❌ Source library not found after build attempt"
    echo "⚠️  Continuing without native library support"
fi

echo "🎉 Build script completed successfully"