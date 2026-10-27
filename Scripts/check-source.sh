#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
Scripts/test-core.sh
Scripts/prepare-preview-deps.sh
swiftc -frontend -parse App/*.swift Core/Models/*.swift Core/Services/*.swift \
    Core/DesignSystem/*.swift Components/*.swift Features/*/*.swift Tests/*Tests.swift UITests/*.swift
# These shared views also compile on macOS. This is not an iOS SDK build.
swiftc -typecheck -I .build/preview-modules -swift-version 5 -strict-concurrency=targeted -target arm64-apple-macos14.0 \
    Core/Models/*.swift App/DockStore.swift Core/Services/ArtworkStore.swift Core/Services/SpotifyService.swift Core/DesignSystem/*.swift Components/*.swift \
    Features/Clock/*.swift Features/Focus/*.swift \
    Features/Ambient/*.swift Features/Gaming/*.swift Features/Settings/*.swift Features/Music/*.swift
plutil -lint ZeroDock.xcodeproj/project.pbxproj Resources/Info.plist
Scripts/design-lint.sh
git diff --check
