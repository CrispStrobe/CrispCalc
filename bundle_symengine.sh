#!/bin/bash

# Script to build and bundle the native library with the Flutter macOS app
# Run this from the project root directory

set -e

echo "🔨 Building native library..."

# Build the native library
cd native
mkdir -p build
cd build

# Configure with CMake
cmake ..

# Build the library
make -j$(sysctl -n hw.ncpu)

# Copy to project root (for development)
cp libcas_wrapper.dylib ../../

echo "📦 Bundling library with app..."

# Go back to project root
cd ../..

# Build the Flutter app
flutter build macos --debug

# Copy the native library to the app bundle
APP_BUNDLE="build/macos/Build/Products/Debug/crisp_calc.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"

if [ -d "$APP_BUNDLE" ]; then
    echo "Copying libcas_wrapper.dylib to app bundle..."
    cp libcas_wrapper.dylib "${MACOS_DIR}/"
    
    # Make sure it has the right permissions
    chmod 755 "${MACOS_DIR}/libcas_wrapper.dylib"
    
    # Verify the library was copied
    if [ -f "${MACOS_DIR}/libcas_wrapper.dylib" ]; then
        echo "✅ Native library successfully bundled!"
        echo "Library location: ${MACOS_DIR}/libcas_wrapper.dylib"
        
        # Check library dependencies
        echo "📋 Library dependencies:"
        otool -L "${MACOS_DIR}/libcas_wrapper.dylib"
    else
        echo "❌ Failed to copy library to app bundle"
        exit 1
    fi
else
    echo "❌ App bundle not found at: $APP_BUNDLE"
    echo "Make sure Flutter build succeeded"
    exit 1
fi

echo "🚀 Ready to run! Use: flutter run -d macos"

