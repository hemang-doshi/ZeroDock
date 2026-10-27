import SwiftUI

struct SettingsView: View {
    @Bindable var store: DockStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockLayout.gap) {
                section("Display", symbol: "sun.max.fill") {
                    Toggle("Keep display awake", isOn: $store.preferences.keepAwake)
                        .accessibilityIdentifier("keepAwake")
                    note("Only while ZeroDock is active. Normal Auto-Lock resumes when you leave.")
                    Toggle("Show clock seconds", isOn: $store.preferences.showSeconds)
                        .accessibilityIdentifier("showSeconds")
                }
                section("Gaming", symbol: "gamecontroller.fill") {
                    Toggle("Animated atmosphere", isOn: $store.preferences.animateGaming)
                        .accessibilityIdentifier("animateGaming")
                    note("Slow colors sampled from original game artwork. Motion pauses with Reduce Motion, Low Power Mode, or when the app is inactive.")
                    note("Game profiles and session timers work locally. A Mac connection for automatic detection and performance metrics is not available in this build.")
                }
                note("Calls and notifications follow your iOS settings. ZeroDock does not read other apps’ notifications.")
                Text("ZeroDock \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0") · Local by design")
                    .font(DockType.label).foregroundStyle(DockTheme.secondary)
            }
            .font(DockType.body)
            .padding(DockLayout.margin)
        }
        .scrollIndicators(.hidden).tint(DockTheme.accent)
        .background(DockTheme.background)
    }

    private func section<Content: View>(_ title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DockLayout.gap) {
            SectionHeader(title: title, symbol: symbol)
            content()
        }
        .padding(DockLayout.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentCard()
    }

    private func note(_ text: String) -> some View {
        Text(text).font(DockType.caption).foregroundStyle(DockTheme.secondary).fixedSize(horizontal: false, vertical: true)
    }
}
