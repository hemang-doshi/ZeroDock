import SwiftUI
import UIKit

@main
struct ZeroDockApp: App {
    var body: some Scene {
        WindowGroup { DockRootView().preferredColorScheme(.dark) }
    }
}

struct DockRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = DockStore()
    @State private var device = DeviceStatusService()
    @State private var artwork = ArtworkStore()
    @State private var spotify = SpotifyService()
    @State private var showingMusic = false
    @State private var showingSettings = false

    var body: some View {
        DockShell(store: store, device: device.snapshot, artwork: artwork, openSettings: { showingSettings = true },
                  nowPlaying: spotify.nowPlaying, spotifyConnected: spotify.connected, openMusic: { showingMusic = true })
            .sheet(isPresented: $showingMusic) {
                NavigationStack {
                    SpotifyView(service: spotify).navigationTitle("Music")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingMusic = false } } }
                }.preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(store: store)
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingSettings = false }.accessibilityIdentifier("closeSettings")
                            }
                        }
                }
                .preferredColorScheme(.dark).tint(DockTheme.accent)
            }
            .task { spotify.restore() }
            .task(id: "\(scenePhase)-\(spotify.connected)") {
                guard scenePhase == .active, spotify.connected else { return }
                while !Task.isCancelled {
                    await spotify.refresh()
                    do { try await Task.sleep(for: .seconds(20)) } catch { return }
                }
            }
            .task(id: store.preferences.gaming.profile?.artworkURL) { await artwork.load(store.preferences.gaming.profile?.artworkURL) }
            .onChange(of: scenePhase, initial: true) { _, phase in
                updateDisplay()
                device.refresh(active: phase == .active)
            }
            .onChange(of: store.preferences.keepAwake) { updateDisplay() }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in device.refresh(active: scenePhase == .active) }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in device.refresh(active: scenePhase == .active) }
            .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in device.refresh(active: scenePhase == .active) }
    }

    private func updateDisplay() {
        UIApplication.shared.isIdleTimerDisabled = DisplayPolicy.keepAwake(enabled: store.preferences.keepAwake, active: scenePhase == .active)
    }
}
