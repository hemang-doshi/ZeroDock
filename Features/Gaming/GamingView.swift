import SwiftUI

/// Two equal cards (game, session) above a four-column strip. The strip's middle divider sits on
/// the same axis as the gap between the cards.
struct GamingView: View {
    var store: DockStore
    var lowPower: Bool
    var artwork: ArtworkStore
    @State private var choosingGame = false
    @Environment(\.scenePhase) private var scenePhase
    private var accent: Color { artwork.accent }

    var body: some View {
        VStack(spacing: DockLayout.gap) {
            DockHalves {
                gameCard
            } right: {
                sessionCard
            }
            metricsStrip.frame(height: DockLayout.strip)
        }
        .sheet(isPresented: $choosingGame) { GamePicker(store: store) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("gamingDashboard")
    }

    // MARK: Game

    private var gameCard: some View {
        HStack(spacing: DockLayout.pad) {
            if store.preferences.gaming.profile != nil { cover }
            VStack(alignment: .leading, spacing: DockLayout.tight) {
                HStack(spacing: DockLayout.tight) {
                    Image(systemName: "gamecontroller.fill")
                    Text(store.preferences.gaming.profile == nil ? "GAMING" : "NOW PLAYING").tracking(1.2)
                }
                .font(DockType.label).foregroundStyle(accent)
                Text(store.preferences.gaming.profile?.title ?? "Your next great session.")
                    .font(DockType.heading).lineLimit(3).minimumScaleFactor(0.6)
                    .accessibilityIdentifier("gameTitle")
                Spacer(minLength: 0)
                Button { choosingGame = true } label: {
                    CapsuleLabel(tint: accent) {
                        HStack(spacing: DockLayout.tight) {
                            Text(store.preferences.gaming.profile == nil ? "Choose a game" : "Change game").lineLimit(1).minimumScaleFactor(0.7)
                            Image(systemName: "chevron.down").font(DockType.symbol(14, weight: .bold))
                        }
                        .foregroundStyle(accent)
                    }
                }
                .buttonStyle(PressableStyle()).accessibilityIdentifier("chooseGame")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(DockLayout.pad)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GamingAtmosphere(colors: artwork.colors, enabled: store.preferences.animateGaming && !lowPower)
                .clipShape(RoundedRectangle(cornerRadius: DockLayout.radius, style: .continuous))
        }
        .contentCard()
    }

    private var cover: some View {
        Group {
            if let image = artwork.image { Image(decorative: image, scale: 1).resizable().scaledToFit() }
            else {
                VStack(spacing: DockLayout.tight) {
                    Image(systemName: "photo").font(.title)
                    Text(artwork.loading ? "Loading" : "No artwork").font(DockType.caption).multilineTextAlignment(.center)
                }
                .foregroundStyle(DockTheme.secondary).frame(width: 96)
            }
        }
        .frame(maxHeight: .infinity)
        .shadow(color: accent.opacity(0.45), radius: 16, y: 6)
        .accessibilityLabel("Original \(store.preferences.gaming.profile?.title ?? "game") cover")
    }

    // MARK: Session

    private var sessionCard: some View {
        TimelineView(.periodic(from: .now, by: scenePhase == .active ? 1 : 60)) { context in
            let session = store.preferences.gaming.session
            VStack(spacing: DockLayout.tight) {
                HStack(spacing: DockLayout.tight) {
                    Circle().fill(session.isRunning ? Color.green : DockTheme.secondary).frame(width: 10, height: 10)
                    Text(session.isRunning ? "SESSION LIVE" : "SESSION TIME").tracking(1.2)
                }
                .font(DockType.label).foregroundStyle(DockTheme.secondary)
                Spacer(minLength: 0)
                Text(time(session.elapsed(at: context.date)))
                    .font(DockType.display(56, weight: .medium)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.55)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("gameElapsed")
                Spacer(minLength: 0)
                HStack(spacing: DockLayout.tight) {
                    AccentButton(title: session.isRunning ? "Pause" : session.elapsed(at: context.date) > 0 ? "Resume" : "Start session",
                                 symbol: session.isRunning ? "pause.fill" : "play.fill", accent: accent, accent2: accent.opacity(0.7)) {
                        if store.preferences.gaming.profile == nil { choosingGame = true }
                        else { store.toggleGaming(at: .now) }
                    }
                    .accessibilityIdentifier("gameToggle")
                    IconButton(symbol: "arrow.counterclockwise", label: "Reset game timer") { store.resetGaming() }
                        .disabled(store.preferences.gaming.profile == nil).accessibilityIdentifier("gameReset")
                }
            }
            .padding(DockLayout.pad)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentCard()
        }
    }

    // MARK: Metrics

    private var metricsStrip: some View {
        GeometryReader { proxy in
            let column = proxy.size.width / 4
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    HStack(spacing: DockLayout.tight) {
                        Image(systemName: "desktopcomputer")
                        Text("Mac not connected").lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .font(DockType.caption)
                    .padding(.horizontal, DockLayout.pad)
                    .frame(width: column, alignment: .leading)
                    .accessibilityElement(children: .contain).accessibilityIdentifier("metricCell0")
                    metric("FPS", index: 1, width: column)
                    metric("Frame time", index: 2, width: column)
                    metric("GPU time", index: 3, width: column)
                }
                ForEach(1..<4, id: \.self) { index in
                    Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: proxy.size.height - DockLayout.gap * 2)
                        .offset(x: column * CGFloat(index) - 0.5)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .contentCard()
        .accessibilityElement(children: .contain).accessibilityIdentifier("metricsStrip")
    }

    private func metric(_ title: String, index: Int, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased()).font(DockType.label).tracking(0.5).foregroundStyle(DockTheme.secondary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text("—").font(DockType.display(32, weight: .medium)).foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, DockLayout.pad)
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) unavailable")
        .accessibilityIdentifier("metricCell\(index)")
    }

    private func time(_ seconds: TimeInterval) -> String {
        let seconds = Int(seconds)
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }
}
