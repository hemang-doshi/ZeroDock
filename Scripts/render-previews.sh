#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
Scripts/prepare-preview-deps.sh
mkdir -p .build/preview docs/evidence
swiftc -parse-as-library -I .build/preview-modules -L .build/preview-modules -lNuke -lNukeUI -lFluidGradient -Xlinker -rpath -Xlinker @executable_path/../preview-modules Core/Models/*.swift App/DockStore.swift Core/Services/ArtworkStore.swift Core/Services/SpotifyService.swift Core/DesignSystem/*.swift Components/*.swift Features/Clock/*.swift Features/Focus/*.swift Features/Ambient/*.swift Features/Gaming/*.swift Features/Settings/*.swift Features/Music/*.swift Scripts/Preview/RenderPreviews.swift -o .build/preview/render
.build/preview/render
