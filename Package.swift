// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZeroDockPreview",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", exact: "12.8.0"),
        .package(url: "https://github.com/Cindori/FluidGradient.git", exact: "1.0.0")
    ],
    targets: [
        .executableTarget(name: "ZeroDockPreview", dependencies: [
            .product(name: "Nuke", package: "Nuke"),
            .product(name: "NukeUI", package: "Nuke"),
            .product(name: "FluidGradient", package: "FluidGradient")
        ], path: ".", exclude: ["App/ZeroDockApp.swift", "Core/Services/DeviceStatusService.swift", "Resources", "Tests", "UITests", "ZeroDock.xcodeproj", "docs", "README.md", "snapshot.md", "handoff.md", "Scripts/build-simulator.sh", "Scripts/check-source.sh", "Scripts/generate-project.py", "Scripts/render-previews.sh", "Scripts/test-core.sh", "Scripts/verify-simulator.sh", "Scripts/xcode-env.sh"], sources: ["App/DockStore.swift", "Core/Models", "Core/DesignSystem", "Core/Services/ArtworkStore.swift", "Core/Services/SpotifyService.swift", "Components", "Features", "Scripts/Preview/RenderPreviews.swift"])
    ]
)
