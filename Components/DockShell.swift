import SwiftUI
import NukeUI

/// Presentation stays separate from scene lifecycle and platform integrations.
/// One canvas, symmetric margins, one centre axis: the mode switcher sits on it, content hangs off it.
struct DockShell: View {
    @Bindable var store: DockStore
    var device: DeviceSnapshot
    var artwork: ArtworkStore
    var openSettings: () -> Void
    var nowPlaying: NowPlaying? = nil
    var spotifyConnected = false
    var openMusic: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var mode: DockMode { store.preferences.mode }
    private var theme: ModeTheme { DockTheme.theme(for: mode, gamingAccent: artwork.accent) }
    private var backdropMoves: Bool { mode == .focus && !reduceMotion && !device.lowPower && scenePhase == .active }
    private var barBand: CGFloat { DockLayout.control + DockLayout.gap }

    var body: some View {
        GeometryReader { proxy in
            // The Dynamic Island inset exists on one side only. Mirror the larger inset so the
            // canvas, and therefore the centre axis, is centred on the physical screen.
            // `proxy` is the safe-area frame, so each side only adds what the safe area lacks.
            let insets = proxy.safeAreaInsets
            let horizontal = max(DockLayout.margin, insets.leading, insets.trailing)
            let vertical = max(DockLayout.margin, insets.top, insets.bottom)
            ZStack(alignment: .top) {
                Group {
                    switch mode {
                    case .focus: FocusView(store: store, theme: theme)
                    case .ambient: AmbientView(showSeconds: store.preferences.showSeconds)
                    case .gaming: GamingView(store: store, lowPower: device.lowPower, artwork: artwork)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, mode == .ambient ? 0 : barBand)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .id(mode)
                topBar.opacity(mode == .ambient ? 0.4 : 1)
            }
            .padding(.leading, horizontal - insets.leading)
            .padding(.trailing, horizontal - insets.trailing)
            .padding(.top, vertical - insets.top)
            .padding(.bottom, vertical - insets.bottom)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .foregroundStyle(.white)
        .background { AuroraBackdrop(theme: theme, animated: backdropMoves, showsOrbs: mode != .ambient) }
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85), value: mode)
    }

    /// Switcher in the exact centre; matching groups left and right.
    private var topBar: some View {
        ZStack {
            DashboardNavigation(selection: $store.preferences.mode, theme: theme)
            HStack(spacing: 0) {
                if mode != .ambient { leadingGroup }
                Spacer(minLength: 0)
                trailingGroup
            }
        }
        .frame(height: DockLayout.control)
    }

    private var leadingGroup: some View {
        HStack(spacing: DockLayout.gap) {
            TimelineView(.everyMinute) { context in
                VStack(alignment: .leading, spacing: 0) {
                    Text(context.date, format: .dateTime.hour().minute()).font(DockType.body).monospacedDigit()
                    Text(context.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .font(DockType.caption).foregroundStyle(DockTheme.secondary)
                }
                .lineLimit(1).fixedSize()
            }
            CapsuleLabel(tint: theme.accent) {
                HStack(spacing: DockLayout.tight) {
                    Image(systemName: device.power == "Charging" ? "battery.100.bolt" : "battery.100")
                    Text(device.percentage.map { "\($0)%" } ?? "—").monospacedDigit()
                }
                .font(DockType.caption).foregroundStyle(DockTheme.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(device.percentage.map { "Battery \($0) percent, \(device.power)" } ?? "Battery unavailable")
        }
    }

    private var trailingGroup: some View {
        HStack(spacing: DockLayout.chip) {
            musicChip
            IconButton(symbol: "gearshape.fill", label: "Settings", size: DockLayout.control, action: openSettings)
                .accessibilityIdentifier("openSettings")
        }
    }

    private var musicChip: some View {
        Button(action: openMusic) {
            CapsuleLabel(tint: theme.accent) {
                HStack(spacing: DockLayout.tight) {
                    if let track = nowPlaying {
                        // Spotify artwork stays intact: fit, no blur, mask or overlay.
                        LazyImage(url: track.artwork) { state in
                            if let image = state.image { image.resizable().scaledToFit() }
                            else { Image(systemName: "music.note") }
                        }.frame(width: 32, height: 32)
                        Text(track.title).lineLimit(1).frame(maxWidth: 110, alignment: .leading)
                    } else {
                        Image(systemName: "music.note")
                        Text("Spotify")
                    }
                }
                .font(DockType.caption).foregroundStyle(.white.opacity(0.9))
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(spotifyConnected ? "Spotify" : "Connect Spotify")
        .accessibilityIdentifier("openSpotify")
    }
}
