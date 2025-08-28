#!/bin/bash
# FINAL, SAFE, PORTABLE SCRIPT - Recursively bundles all native dependencies.

set -e
echo "✅ Starting native library build and bundle process..."

# 1. Build the native library
echo "🔨 Building native library..."
(cd native/build && cmake .. && make -j$(sysctl -n hw.ncpu))
echo "✅ Native library built successfully."

# 2. Build the Flutter app to create the bundle structure
echo "📦 Building Flutter app..."
flutter build macos --debug

# 3. Define paths and variables
APP_BUNDLE="build/macos/Build/Products/Debug/crisp_calc.app"
FRAMEWORKS_DIR="${APP_BUNDLE}/Contents/Frameworks"
HOMEBREW_PREFIX=$(brew --prefix)
processed_libs=" | "

# --- Recursive function to process a library and its dependencies ---
process_library() {
    local lib_path="$1"
    local lib_name=$(basename "$1")

    if [[ "$processed_libs" == *" | $lib_name | "* ]]; then
        return
    fi
    echo "⚙️  Processing: $lib_name"
    cp "$lib_path" "${FRAMEWORKS_DIR}/"
    processed_libs="$processed_libs$lib_name | "

    local dependencies
    dependencies=$(otool -L "${FRAMEWORKS_DIR}/$lib_name" | grep "$HOMEBREW_PREFIX" | awk '{print $1}' || true)

    for dep_path in $dependencies; do
        local dep_name=$(basename "$dep_path")
        echo "  ➡️  Found dependency: $dep_name"
        echo "  🔗 Patching $lib_name to find $dep_name..."
        install_name_tool -change "$dep_path" "@rpath/$dep_name" "${FRAMEWORKS_DIR}/$lib_name"
        process_library "$dep_path"
    done
}

# 4. Start the recursive bundling process
echo "🚚 Bundling all required libraries..."
# --- SAFE FIX: Ensure the directory exists and is writable ---
mkdir -p "${FRAMEWORKS_DIR}"
chmod -R u+w "${FRAMEWORKS_DIR}"
process_library "native/build/libcas_wrapper.dylib"

# 5. Re-sign the entire app bundle
echo "🖋️  Re-signing the app bundle for macOS..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ All native libraries successfully bundled, patched, and signed!"
echo "📋 Final dependencies for your library:"
otool -L "${FRAMEWORKS_DIR}/libcas_wrapper.dylib"

echo "🚀 Ready to run! Use: flutter run -d macos"