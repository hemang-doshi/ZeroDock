import SwiftUI

/// Control layer: glass that floats above flat content. Use it only on things people press.
struct GlassBackground<S: InsettableShape>: View {
    var shape: S
    var tint: Color = DockTheme.accent
    var body: some View {
        shape.fill(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(shape.fill(RadialGradient(colors: [tint.opacity(0.18), .clear], center: .topLeading, startRadius: 0, endRadius: 200)))
            .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

struct SectionHeader: View {
    var title: String
    var symbol: String
    var tint: Color = DockTheme.accent
    var body: some View {
        HStack(spacing: DockLayout.tight) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(title.uppercased()).tracking(1.2)
            Spacer(minLength: 0)
        }
        .font(DockType.label)
        .foregroundStyle(.white.opacity(0.9))
    }
}

/// Springy press feedback shared by every tappable control.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// A circular glass control. Same shape and size family everywhere.
struct IconButton: View {
    var symbol: String
    var label: String
    var size: CGFloat = DockLayout.controlLarge
    var action: () -> Void
    @State private var taps = 0
    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Image(systemName: symbol).font(DockType.symbol(size * 0.38))
                .frame(width: size, height: size)
                .background { GlassBackground(shape: Circle(), tint: DockTheme.accent) }
        }
        .buttonStyle(PressableStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .accessibilityLabel(label)
    }
}

/// A capsule glass control for secondary actions and chips. Height comes from `DockLayout`.
struct CapsuleLabel<Content: View>: View {
    var height: CGFloat = DockLayout.control
    var tint: Color = DockTheme.accent
    @ViewBuilder var content: Content
    var body: some View {
        content
            .font(DockType.control)
            .padding(.horizontal, DockLayout.pad)
            .frame(height: height)
            .background { GlassBackground(shape: Capsule(), tint: tint) }
    }
}

struct StatusIndicator: View {
    var text: String
    var color: Color = DockTheme.accent
    var body: some View {
        HStack(spacing: DockLayout.tight) {
            Circle().fill(color).frame(width: 10, height: 10).shadow(color: color, radius: 4)
            Text(text).font(DockType.caption)
        }
        .foregroundStyle(DockTheme.secondary)
    }
}

/// The one prominent action on a screen.
struct AccentButton: View {
    var title: String
    var symbol: String
    var accent: Color = DockTheme.accent
    var accent2: Color = DockTheme.accentSoft
    var action: () -> Void
    @State private var taps = 0
    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(DockType.control)
                .contentTransition(.symbolEffect(.replace))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: DockLayout.controlLarge)
                .foregroundStyle(Color.black.opacity(0.82))
                .background(LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1))
                .shadow(color: accent.opacity(0.4), radius: 12, y: 5)
        }
        .buttonStyle(PressableStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: taps)
    }
}

/// Slow-drifting color orbs behind a mode. Plain gradients, no blur, so it stays cheap on the GPU.
struct AuroraBackdrop: View {
    var theme: ModeTheme
    var animated: Bool
    var showsOrbs = true
    @State private var drift = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.backdropTop, theme.backdropBottom], startPoint: .top, endPoint: .bottom)
            GeometryReader { proxy in
                orb(theme.accent, size: proxy.size.width * 0.7)
                    .offset(x: drift ? proxy.size.width * 0.35 : -proxy.size.width * 0.1, y: drift ? -proxy.size.height * 0.15 : proxy.size.height * 0.1)
                orb(theme.accent2, size: proxy.size.width * 0.55)
                    .offset(x: drift ? proxy.size.width * 0.1 : proxy.size.width * 0.55, y: drift ? proxy.size.height * 0.55 : proxy.size.height * 0.3)
            }
            .opacity(showsOrbs ? 0.5 : 0)
        }
        .ignoresSafeArea()
        .onAppear { updateDrift() }
        .onChange(of: animated) { updateDrift() }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func orb(_ color: Color, size: CGFloat) -> some View {
        Circle().fill(RadialGradient(colors: [color.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
    }

    private func updateDrift() {
        if animated { withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) { drift = true } }
        else { withAnimation(.default) { drift = false } }
    }
}
