import SwiftUI
import NukeUI

struct SpotifyView: View {
    var service: SpotifyService
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockLayout.gap) {
                Label("Spotify", systemImage: "music.note").font(DockType.heading)
                if let track = service.nowPlaying {
                    HStack(alignment: .top, spacing: DockLayout.margin) {
                        // Keep Spotify artwork intact: fit, no blur, masks, overlays or animation.
                        LazyImage(url: track.artwork) { state in
                            if let image = state.image { image.resizable().scaledToFit() }
                            else { Color.white.opacity(0.04).overlay(Image(systemName: "music.note")) }
                        }.frame(width: 160, height: 160)
                        VStack(alignment: .leading, spacing: DockLayout.tight) {
                            Text(track.isPlaying ? "NOW PLAYING" : "PAUSED").font(DockType.label).tracking(1.5).foregroundStyle(DockTheme.secondary)
                            Text(track.title).font(DockType.title)
                            Text(track.artist).font(DockType.body).foregroundStyle(DockTheme.secondary)
                            if let url = track.link { Link("Open in Spotify ↗", destination: url).font(DockType.body) }
                        }
                    }
                } else { Text(service.message).font(DockType.body).foregroundStyle(DockTheme.secondary) }
                if service.connected {
                    Button("Disconnect from ZeroDock") { service.disconnect() }.font(DockType.caption)
                } else {
                    Button { Task { await service.connect() } } label: {
                        Label(service.connecting ? "Connecting…" : "Connect Spotify", systemImage: "arrow.up.right")
                            .font(DockType.control).padding(.horizontal, DockLayout.margin).frame(height: DockLayout.controlLarge)
                            .foregroundStyle(Color.black.opacity(0.85)).background(LinearGradient(colors: [DockTheme.accent, DockTheme.accentSoft], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                    }.buttonStyle(PressableStyle()).disabled(service.connecting).accessibilityIdentifier("connectSpotify")
                }
                if service.connected && service.nowPlaying != nil { Text(service.message).font(DockType.caption).foregroundStyle(DockTheme.secondary) }
                Text("Read-only now playing across your Spotify devices. ZeroDock does not stream audio or change playback.")
                    .font(DockType.caption).foregroundStyle(DockTheme.secondary)
            }.padding(DockLayout.margin)
        }.background(DockTheme.background).preferredColorScheme(.dark).tint(DockTheme.accent)
    }
}
