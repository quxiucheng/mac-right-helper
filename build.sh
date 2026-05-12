#!/bin/bash
set -e

SCHEME="mac-right-helper"
DEST="platform=macOS"

xcodebuild -scheme "$SCHEME" -destination "$DEST" -configuration Release build

echo "Build complete. Check build/Release/ for the .app bundle."
