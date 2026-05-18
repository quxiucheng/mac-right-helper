#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect full Xcode (xcodebuild available and functional)
if command -v xcodebuild >/dev/null 2>&1 && xcodebuild -version >/dev/null 2>&1; then
    echo "=== Using Xcode build ==="
    xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
    echo "Build complete. Check build/Release/ for the .app bundle."
    exit 0
fi

echo "=== Xcode not found, falling back to standalone packaging ==="

APP_NAME="mac-right-helper"
BUNDLE_ID="com.example.mac-right-helper"
EXT_BUNDLE_ID="${BUNDLE_ID}.FinderSyncExt"
VERSION="1.0"
BUILD_NUMBER="1"
MIN_MACOS_VERSION="12.0"

SRC_DIR="${SCRIPT_DIR}/mac-right-helper"
EXT_SRC_DIR="${SCRIPT_DIR}/FinderSyncExt"
BUILD_DIR="${SCRIPT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
EXT_BUNDLE="${APP_BUNDLE}/Contents/PlugIns/FinderSyncExt.appex"

# Code signing identity (empty = ad-hoc sign with "-")
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

echo "=== Packaging ${APP_NAME}.app (with Finder Sync Extension) ==="

# 1. Check for source files
SWIFT_COUNT=$(find "${SRC_DIR}" -name "*.swift" | wc -l | tr -d ' ')
if [ "$SWIFT_COUNT" -eq 0 ]; then
    echo "Error: No Swift source files found in ${SRC_DIR}"
    exit 1
fi
echo "Found ${SWIFT_COUNT} main app Swift source files"

# 2. Prepare build directories
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${EXT_BUNDLE}/Contents/MacOS"

# 3. Compile main app binary
echo "Compiling main app binary..."
BINARY_PATH="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
TMP_DIR=$(mktemp -d)

echo "  → Building arm64..."
swiftc \
    -O \
    -whole-module-optimization \
    -target "arm64-apple-macosx${MIN_MACOS_VERSION}" \
    -o "${TMP_DIR}/${APP_NAME}_arm64" \
    -framework Foundation \
    -framework AppKit \
    -framework ApplicationServices \
    -framework CoreServices \
    $(find "${SRC_DIR}" -name "*.swift" -print0 | xargs -0 echo)

echo "  → Building x86_64..."
swiftc \
    -O \
    -whole-module-optimization \
    -target "x86_64-apple-macosx${MIN_MACOS_VERSION}" \
    -o "${TMP_DIR}/${APP_NAME}_x86_64" \
    -framework Foundation \
    -framework AppKit \
    -framework ApplicationServices \
    -framework CoreServices \
    $(find "${SRC_DIR}" -name "*.swift" -print0 | xargs -0 echo)

echo "  → Creating universal binary..."
lipo -create \
    "${TMP_DIR}/${APP_NAME}_arm64" \
    "${TMP_DIR}/${APP_NAME}_x86_64" \
    -output "${BINARY_PATH}"

chmod +x "${BINARY_PATH}"
echo "  → Architectures: $(lipo -archs "${BINARY_PATH}")"
rm -rf "${TMP_DIR}"

# 4. Build Finder Sync Extension
echo "Building Finder Sync Extension..."

EXT_BINARY="${EXT_BUNDLE}/Contents/MacOS/FinderSyncExt"
TMP_DIR=$(mktemp -d)

# Extension sources: extension file + shared IPC + shared types
EXT_SOURCES=()
if [ -f "${EXT_SRC_DIR}/FinderSyncExt.swift" ]; then
    EXT_SOURCES+=("${EXT_SRC_DIR}/FinderSyncExt.swift")
fi
if [ -f "${SRC_DIR}/Shared/Messager.swift" ]; then
    EXT_SOURCES+=("${SRC_DIR}/Shared/Messager.swift")
fi
if [ -f "${SRC_DIR}/Shared/AppExIPC.swift" ]; then
    EXT_SOURCES+=("${SRC_DIR}/Shared/AppExIPC.swift")
fi

if [ ${#EXT_SOURCES[@]} -eq 0 ]; then
    echo "Warning: No extension source files found, skipping extension build"
else
    echo "  → Extension sources: ${EXT_SOURCES[@]}"

    echo "  → Building extension arm64..."
    swiftc \
        -emit-library \
        -Xlinker -bundle \
        -O \
        -target "arm64-apple-macosx${MIN_MACOS_VERSION}" \
        -module-name "FinderSyncExt" \
        -o "${TMP_DIR}/FinderSyncExt_arm64" \
        -framework FinderSync \
        -framework Foundation \
        -framework AppKit \
        "${EXT_SOURCES[@]}"

    echo "  → Building extension x86_64..."
    swiftc \
        -emit-library \
        -Xlinker -bundle \
        -O \
        -target "x86_64-apple-macosx${MIN_MACOS_VERSION}" \
        -module-name "FinderSyncExt" \
        -o "${TMP_DIR}/FinderSyncExt_x86_64" \
        -framework FinderSync \
        -framework Foundation \
        -framework AppKit \
        "${EXT_SOURCES[@]}"

    echo "  → Creating universal extension binary..."
    lipo -create \
        "${TMP_DIR}/FinderSyncExt_arm64" \
        "${TMP_DIR}/FinderSyncExt_x86_64" \
        -output "${EXT_BINARY}"

    chmod +x "${EXT_BINARY}"
    echo "  → Extension architectures: $(lipo -archs "${EXT_BINARY}")"
    rm -rf "${TMP_DIR}"

    # Copy extension Info.plist
    if [ -f "${EXT_SRC_DIR}/Info.plist" ]; then
        sed -e "s/\$(EXECUTABLE_NAME)/FinderSyncExt/g" \
            "${EXT_SRC_DIR}/Info.plist" > "${EXT_BUNDLE}/Contents/Info.plist"
    else
        echo "Error: Extension Info.plist not found"
        exit 1
    fi

    echo "  → Finder Sync Extension built successfully"
fi

# 5. Copy main app Info.plist and substitute variables
echo "Copying main app Info.plist..."
if [ -f "${SRC_DIR}/Info.plist" ]; then
    sed -e "s/\$(EXECUTABLE_NAME)/${APP_NAME}/g" \
        "${SRC_DIR}/Info.plist" > "${APP_BUNDLE}/Contents/Info.plist"
else
    echo "Error: Info.plist not found at ${SRC_DIR}/Info.plist"
    exit 1
fi

# 6. Code sign (extension first, then main app)
echo "Code signing with identity: '${CODE_SIGN_IDENTITY}'"

# Build signing args — hardened runtime only for developer-signed builds
SIGN_ARGS="--force"
if [ "${CODE_SIGN_IDENTITY}" != "-" ]; then
    SIGN_ARGS="${SIGN_ARGS} --options runtime"
fi

# Sign extension first
if [ -d "${EXT_BUNDLE}" ]; then
    codesign --force --sign "${CODE_SIGN_IDENTITY}" "${EXT_BUNDLE}"
    echo "  → Extension signed"
fi

# Sign main app
codesign ${SIGN_ARGS} --sign "${CODE_SIGN_IDENTITY}" "${APP_BUNDLE}"

# 7. Validate
echo "Validating bundle..."
codesign -vv --deep "${APP_BUNDLE}" 2>&1 || echo "  (validation warnings may be normal for ad-hoc signing)"

# 8. Print summary
BINARY_SIZE=$(du -sh "${BINARY_PATH}" | cut -f1)
BUNDLE_SIZE=$(du -sh "${APP_BUNDLE}" | cut -f1)

echo ""
echo "=== Package complete ==="
echo "App bundle:     ${APP_BUNDLE}"
echo "Main binary:    ${BINARY_SIZE}"
echo "Bundle size:    ${BUNDLE_SIZE}"

if [ -d "${EXT_BUNDLE}" ]; then
    EXT_SIZE=$(du -sh "${EXT_BUNDLE}" | cut -f1)
    echo "Extension:      ${EXT_SIZE} (FinderSyncExt.appex)"
fi

echo ""
echo "To install:"
echo "  cp -R \"${APP_BUNDLE}\" /Applications/"
echo ""
echo "After first install, run:  killall Finder"
echo "To verify extension:  pluginkit -m -v -A -D | grep FinderSyncExt"
