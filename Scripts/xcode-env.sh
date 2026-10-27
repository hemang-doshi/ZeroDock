#!/bin/bash
# Source this file. DEVELOPER_DIR applies only to this process and its children.
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
if ! xcodebuild -version >/dev/null 2>&1; then
    echo 'Full Xcode is required. Install Xcode and an iOS Simulator runtime, or set DEVELOPER_DIR to an existing Xcode Developer directory.' >&2
    echo 'No global toolchain, connected device, or location workflow was changed.' >&2
    return 2
fi
