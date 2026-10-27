#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source Scripts/xcode-env.sh
xcodebuild -project ZeroDock.xcodeproj -scheme ZeroDock \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$PWD/DerivedData" \
    build CODE_SIGNING_ALLOWED=NO
