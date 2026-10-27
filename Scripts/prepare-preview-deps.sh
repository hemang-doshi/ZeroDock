#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/Dependencies .build/preview-modules
for dependency in Nuke FluidGradient; do
    if [[ "$dependency" == Nuke ]]; then
        repository=https://github.com/kean/Nuke.git
        version=12.8.0
        revision=0ead44350d2737db384908569c012fe67c421e4d
    else
        repository=https://github.com/Cindori/FluidGradient.git
        version=1.0.0
        revision=9ddda4cf23671ef0228e88681ec6210cb3e0d7f7
    fi
    folder=".build/Dependencies/$dependency"
    if [[ ! -d "$folder/.git" ]]; then git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$version" "$repository" "$folder"; fi
    [[ "$(git -C "$folder" rev-parse HEAD)" == "$revision" ]] || { echo "Unexpected $dependency revision" >&2; exit 1; }
done
# This CLT installation cannot link SwiftPM manifests. Compile the unchanged pinned
# sources for macOS preview checks only; Xcode uses the package references normally.
for module in Nuke NukeUI FluidGradient; do
    if [[ "$module" == FluidGradient ]]; then source_root=.build/Dependencies/FluidGradient; else source_root=.build/Dependencies/Nuke; fi
    output=".build/preview-modules/lib$module.dylib"
    if [[ ! -f "$output" ]]; then
        sources=()
        while IFS= read -r file; do sources+=("$file"); done < <(find "$source_root/Sources/$module" -name '*.swift' -type f | sort)
        flags=(-I .build/preview-modules)
        if [[ "$module" == NukeUI ]]; then flags+=(-L .build/preview-modules -lNuke); fi
        swiftc -swift-version 5 -target arm64-apple-macos14.0 -parse-as-library -emit-library -emit-module \
            -module-name "$module" -I .build/preview-modules "${flags[@]}" \
            -Xlinker -install_name -Xlinker "@rpath/lib$module.dylib" \
            -emit-module-path ".build/preview-modules/$module.swiftmodule" \
            "${sources[@]}" -o "$output"
    fi
done
