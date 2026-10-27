import SwiftUI

/// Left half: the ring. Right half: heading, presets, actions. Both are the same width and share
/// one vertical centre, so the screen reads as two mirrored columns.
struct FocusView: View {
    var store: DockStore
    var theme: ModeTheme = DockTheme.theme(for: .focus, gamingAccent: DockTheme.gamingAccent)
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: scenePhase == .active ? 1 : 60)) { context in
            let session = store.preferences.focus
            let remaining = session.remaining(at: context.date)
            let running = session.isRunning(at: context.date)
            let fraction = min(1, remaining / max(1, session.duration))
            GeometryReader { proxy in
                let side = min(proxy.size.height, (proxy.size.width - DockLayout.gutter) / 2)
                DockHalves {
                    ring(remaining: remaining, running: running, fraction: fraction)
                        .frame(width: side, height: side)
                } right: {
                    controls(session: session, remaining: remaining, running: running)
                        .frame(width: side)
                }
            }
        }
    }

    private func ring(remaining: TimeInterval, running: Bool, fraction: Double) -> some View {
        let lineWidth = DockLayout.ringStroke
        return ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: lineWidth)
            Circle().trim(from: 0, to: fraction)
                .stroke(AngularGradient(colors: [theme.accent2, theme.accent, theme.accent2], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(running ? 0.7 : 0.25), radius: running ? 20 : 6)
                .animation(reduceMotion ? nil : .linear(duration: 1), value: fraction)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: running)
            VStack(spacing: 0) {
                HStack(spacing: DockLayout.tight) {
                    Image(systemName: running ? "flame.fill" : remaining == 0 ? "checkmark.seal.fill" : "moon.zzz.fill")
                        .symbolEffect(.pulse, isActive: running && !reduceMotion)
                    Text(running ? "IN SESSION" : remaining == 0 ? "COMPLETE" : "READY").tracking(1.2)
                }
                .font(DockType.label).foregroundStyle(theme.accent)
                Text(time(remaining)).font(DockType.display(64, weight: .medium))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(reduceMotion ? nil : .snappy, value: time(remaining))
                    .accessibilityIdentifier("focusRemaining")
            }
            .padding(lineWidth + DockLayout.gap)
        }
        .padding(DockLayout.ringInset)
    }

    private func controls(session: FocusSession, remaining: TimeInterval, running: Bool) -> some View {
        VStack(alignment: .leading, spacing: DockLayout.gap) {
            Text(running ? "Stay with it." : remaining == 0 ? "Well spent." : "One thing at a time.")
                .font(DockType.title).lineLimit(2).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: DockLayout.tight) {
                ForEach([15, 25, 45], id: \.self) { minutes in
                    presetChip(minutes: minutes, selected: Int(session.duration / 60) == minutes, running: running)
                }
            }
            HStack(spacing: DockLayout.tight) {
                AccentButton(title: running ? "Pause" : remaining == 0 ? "Again" : remaining < session.duration ? "Resume" : "Start focus",
                             symbol: running ? "pause.fill" : "play.fill", accent: theme.accent, accent2: theme.accent2) { store.toggleFocus(at: .now) }
                    .accessibilityIdentifier("focusToggle")
                IconButton(symbol: "arrow.counterclockwise", label: "Reset timer") { store.resetFocus() }
                    .accessibilityIdentifier("focusReset")
            }
        }
    }

    private func presetChip(minutes: Int, selected: Bool, running: Bool) -> some View {
        Button { store.resetFocus(minutes: minutes) } label: {
            Text("\(minutes) min")
                .font(DockType.control).lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: DockLayout.controlLarge)
                .foregroundStyle(selected ? .white : DockTheme.secondary)
                .background {
                    if selected { Capsule().fill(.white.opacity(0.16)) }
                    else { GlassBackground(shape: Capsule(), tint: theme.accent) }
                }
                .overlay { if selected { Capsule().strokeBorder(theme.accent, lineWidth: 2) } }
        }
        .buttonStyle(PressableStyle())
        .disabled(running)
        .opacity(running && !selected ? 0.45 : 1)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("preset\(minutes)")
    }

    private func time(_ seconds: TimeInterval) -> String {
        let value = Int(ceil(seconds))
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
