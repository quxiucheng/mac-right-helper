#!/bin/bash
set -e

APP_NAME="mac-right-helper"
BUNDLE_ID="com.example.mac-right-helper"
VERSION="1.0"
BUILD_NUMBER="1"
MIN_MACOS_VERSION="12.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/mac-right-helper"
BUILD_DIR="${SCRIPT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

# Code signing identity (empty = ad-hoc sign with "-")
# Set to your Developer ID to sign for distribution:
# CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

echo "=== Packaging ${APP_NAME}.app ==="

# 1. Check for source files
SWIFT_COUNT=$(find "${SRC_DIR}" -name "*.swift" | wc -l | tr -d ' ')
if [ "$SWIFT_COUNT" -eq 0 ]; then
    echo "Error: No Swift source files found in ${SRC_DIR}"
    exit 1
fi

echo "Found ${SWIFT_COUNT} Swift source files"

# 2. Prepare build directory
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 3. Compile binary
echo "Compiling binary..."
ARCH=$(uname -m)
find "${SRC_DIR}" -name "*.swift" -print0 | xargs -0 swiftc \
    -O \
    -whole-module-optimization \
    -target "${ARCH}-apple-macosx${MIN_MACOS_VERSION}" \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    -framework Foundation \
    -framework AppKit \
    -framework ApplicationServices

chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# 4. Copy Info.plist and substitute variables
echo "Copying Info.plist..."
if [ -f "${SRC_DIR}/Info.plist" ]; then
    sed -e "s/\$(EXECUTABLE_NAME)/${APP_NAME}/g" \
        "${SRC_DIR}/Info.plist" > "${APP_BUNDLE}/Contents/Info.plist"
else
    echo "Warning: Info.plist not found at ${SRC_DIR}/Info.plist, generating default..."
    cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS_VERSION}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
fi

# 5. Code sign
echo "Code signing with identity: '${CODE_SIGN_IDENTITY}'"
codesign --force --deep --sign "${CODE_SIGN_IDENTITY}" \
    --options runtime \
    "${APP_BUNDLE}" 2>/dev/null || \
    codesign --force --deep --sign "${CODE_SIGN_IDENTITY}" \
        "${APP_BUNDLE}"

# 6. Validate
echo "Validating bundle..."
codesign -vv --deep "${APP_BUNDLE}"

# 7. Print summary
BINARY_SIZE=$(du -sh "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" | cut -f1)
BUNDLE_SIZE=$(du -sh "${APP_BUNDLE}" | cut -f1)

echo ""
echo "=== Package complete ==="
echo "App bundle: ${APP_BUNDLE}"
echo "Binary size: ${BINARY_SIZE}"
echo "Bundle size: ${BUNDLE_SIZE}"
echo ""
echo "To install locally:"
echo "  cp -R \"${APP_BUNDLE}\" ~/Applications/"
echo ""
echo "To create a ZIP for distribution:"
echo "  ditto -c -k --sequesterRsrc --keepParent \"${APP_BUNDLE}\" \"${BUILD_DIR}/${APP_NAME}.zip\""
echo ""
echo "To create a DMG for distribution:"
echo "  hdiutil create -volname \"${APP_NAME}\" -srcfolder \"${APP_BUNDLE}\" -ov \"${BUILD_DIR}/${APP_NAME}.dmg\""
