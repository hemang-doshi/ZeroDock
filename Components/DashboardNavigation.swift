import SwiftUI

/// Segmented mode switcher, centered on the screen axis. The chosen mode shows icon and name;
/// the others stay icon-only so the control stays compact.
struct DashboardNavigation: View {
    @Binding var selection: DockMode
    var theme: ModeTheme
    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DockMode.allCases, id: \.self) { mode in
                let selected = selection == mode
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { selection = mode }
                } label: {
                    HStack(spacing: DockLayout.tight) {
                        Image(systemName: mode.symbol)
                            .symbolVariant(selected ? .fill : .none)
                            .symbolEffect(.bounce, value: selected)
                            .font(DockType.symbol(22))
                        if selected { Text(mode.rawValue).font(DockType.control).lineLimit(1) }
                    }
                    .padding(.horizontal, selected ? DockLayout.gap : DockLayout.chip)
                    .frame(minWidth: DockLayout.controlLarge)
                    .frame(height: DockLayout.minTarget)
                    .foregroundStyle(selected ? Color.black.opacity(0.85) : DockTheme.secondary)
                    .background {
                        if selected {
                            Capsule()
                                .fill(LinearGradient(colors: [theme.accent, theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: theme.accent.opacity(0.45), radius: 8, y: 3)
                                .matchedGeometryEffect(id: "selected", in: highlight)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableStyle())
                .sensoryFeedback(.selection, trigger: selected)
                .accessibilityLabel(mode.rawValue)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityIdentifier("nav\(mode.rawValue)")
            }
        }
        .padding((DockLayout.control - DockLayout.minTarget) / 2)
        .frame(height: DockLayout.control)
        .background { GlassBackground(shape: Capsule(), tint: theme.accent) }
    }
}
