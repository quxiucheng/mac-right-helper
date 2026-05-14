#!/bin/bash
set -e

# 检测是否有完整 Xcode（xcodebuild 且能正常执行）
if command -v xcodebuild >/dev/null 2>&1 && xcodebuild -version >/dev/null 2>&1; then
    echo "=== Using Xcode build ==="
    xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
    echo "Build complete. Check build/Release/ for the .app bundle."
else
    echo "=== Xcode not found, falling back to standalone packaging ==="
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    exec "${SCRIPT_DIR}/package.sh"
fi
