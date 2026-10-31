#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v swift >/dev/null || { echo "Swift is required; run on a Mac with Xcode."; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode is required for the iPhone app."; exit 1; }
swift test
xcodebuild -project Bearforming.xcodeproj -scheme Bearforming -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
