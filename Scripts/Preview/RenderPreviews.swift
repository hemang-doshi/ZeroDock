import AppKit
import SwiftUI

/// Static macOS rendering of the shared production views, never an iOS simulator.
/// No calendar permissions, device connections, external URLs or system changes.
@main
struct RenderPreviews {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        URLCache.shared = URLCache(memoryCapacity: 16_000_000, diskCapacity: 0, diskPath: nil)
        let suite = "ZeroDock.StaticPreview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DockStore(defaults: defaults)
        let artwork = ArtworkStore()
        let device = DeviceSnapshot(system: "Static preview", model: "Device data unavailable")
        for mode in DockMode.allCases {
            store.preferences.mode = mode
            try await save(shell(store: store, device: device, artwork: artwork), to: "docs/evidence/\(mode.rawValue.lowercased())-macos-render.png", scale: 2)
        }
        for profile in GameProfile.macLibrary.filter({ ["Sekiro", "Spider-Man: Miles Morales", "F1 2017"].contains($0.title) }) {
            store.selectGame(profile)
            await artwork.load(profile.artworkURL)
            try await save(shell(store: store, device: device, artwork: artwork), to: "docs/evidence/gaming-\(profile.title.lowercased().replacingOccurrences(of: ":", with: "").replacingOccurrences(of: " ", with: "-"))-macos-render.png", scale: 2)
        }
        store.preferences.mode = .focus
        try await save(shell(store: store, device: device, artwork: artwork, width: 852, height: 393), to: "docs/evidence/focus-compact-macos-render.png", scale: 2)
        store.preferences.mode = .gaming
        try await save(shell(store: store, device: device, artwork: artwork, width: 852, height: 393), to: "docs/evidence/gaming-compact-macos-render.png", scale: 2)
        let picker = GamePicker(store: store).frame(width: 650, height: 350).environment(\.colorScheme, .dark)
        try await save(picker, to: "docs/evidence/game-picker-macos-render.png", scale: 2)
        let settings = SettingsView(store: store)
            .frame(width: 580, height: 350).background(DockTheme.background).environment(\.colorScheme, .dark)
        try await save(settings, to: "docs/evidence/settings-macos-render.png", scale: 2)
        let icon = ZStack {
            Color(red: 0.025, green: 0.03, blue: 0.035)
            RoundedRectangle(cornerRadius: 155).stroke(DockTheme.accent, lineWidth: 20).frame(width: 590, height: 590)
            Circle().fill(DockTheme.accent).frame(width: 140, height: 140)
        }.frame(width: 1024, height: 1024)
        try await save(icon, to: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png", scale: 1)
    }

    @MainActor private static func shell(store: DockStore, device: DeviceSnapshot, artwork: ArtworkStore, width: CGFloat = 874, height: CGFloat = 402) -> some View {
        DockShell(store: store, device: device, artwork: artwork, openSettings: {})
            .padding(EdgeInsets(top: 0, leading: 62, bottom: 21, trailing: 62))
            .frame(width: width, height: height).background(.black).environment(\.colorScheme, .dark)
    }

    @MainActor private static func save<V: View>(_ view: V, to path: String, scale: CGFloat) async throws {
        if path.contains("AppIcon") {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            renderer.isOpaque = true
            guard let image = renderer.cgImage,
                  let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
            else { throw NSError(domain: "ZeroDock.Render", code: 3) }
            try data.write(to: URL(fileURLWithPath: path))
            return
        }
        let hosting = NSHostingView(rootView: view)
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.layoutIfNeeded()
        hosting.layoutSubtreeIfNeeded()
        for _ in 0..<4 { try await Task.sleep(for: .milliseconds(80)); hosting.layoutSubtreeIfNeeded() }
        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)
        else { throw NSError(domain: "ZeroDock.Render", code: 1) }
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:])
        else { throw NSError(domain: "ZeroDock.Render", code: 2) }
        try data.write(to: URL(fileURLWithPath: path))
        window.close()
        print("Rendered \(path) [macOS SwiftUI]")
    }
}
