import SwiftUI
import NukeUI

struct GamePicker: View {
    var store: DockStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var steamID: String
    @State private var customURL: String

    init(store: DockStore) {
        self.store = store
        _title = State(initialValue: store.preferences.gaming.profile?.title ?? "")
        _steamID = State(initialValue: store.preferences.gaming.profile?.steamAppID.map(String.init) ?? "")
        _customURL = State(initialValue: store.preferences.gaming.profile?.customArtwork?.absoluteString ?? "")
    }
    private var profile: GameProfile {
        GameProfile(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    steamAppID: Int(steamID), customArtwork: customURL.isEmpty ? nil : URL(string: customURL),
                    runtime: GameProfile.macLibrary.first(where: { $0.title == title && $0.steamAppID == Int(steamID) })?.runtime)
    }
    private var valid: Bool {
        !profile.title.isEmpty && (steamID.isEmpty || (Int(steamID) ?? 0) > 0)
            && (customURL.isEmpty || (profile.customArtwork?.scheme == "https" && profile.customArtwork?.host != nil))
    }
    private var resetsSession: Bool {
        store.preferences.gaming.profile != profile && store.preferences.gaming.session.elapsed(at: .now) > 0
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockLayout.gap) {
                    Text("SUGGESTED GAMES").font(DockType.label).tracking(1.5).foregroundStyle(DockTheme.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DockLayout.gap) {
                        ForEach(GameProfile.macLibrary) { suggestion in
                            Button {
                                title = suggestion.title
                                steamID = suggestion.steamAppID.map(String.init) ?? ""
                                customURL = suggestion.customArtwork?.absoluteString ?? ""
                            } label: {
                                HStack(spacing: DockLayout.gap) {
                                    LazyImage(url: suggestion.artworkURL) { state in
                                        if let image = state.image { image.resizable().scaledToFit() }
                                        else { Image(systemName: "gamecontroller").foregroundStyle(DockTheme.secondary) }
                                    }.frame(width: 40, height: 60)
                                    VStack(alignment: .leading, spacing: DockLayout.inset) {
                                        Text(suggestion.title).font(DockType.body).foregroundStyle(.white).multilineTextAlignment(.leading)
                                        Text(suggestion.runtime ?? "").font(DockType.caption).foregroundStyle(DockTheme.secondary)
                                    }
                                    Spacer(minLength: 0)
                                    if profile == suggestion { Image(systemName: "checkmark").foregroundStyle(DockTheme.accent) }
                                }
                                .padding(DockLayout.pad).contentCard(radius: DockLayout.innerRadius)
                                .overlay { if profile == suggestion { RoundedRectangle(cornerRadius: DockLayout.innerRadius, style: .continuous).strokeBorder(DockTheme.accent, lineWidth: 2) } }
                            }
                            .buttonStyle(PressableStyle()).accessibilityIdentifier("profile\(suggestion.title)")
                        }
                    }
                    TextField("Any game name", text: $title).textFieldStyle(.roundedBorder).accessibilityIdentifier("gameName")
                    TextField("Steam App ID (optional)", text: $steamID).textFieldStyle(.roundedBorder)
                    TextField("Original artwork HTTPS URL (optional)", text: $customURL).textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    Text("Choose a game manually; live detection is not connected. Steam supplies title-matched artwork, not proof of ownership. Edit the suggestions in GameProfile.macLibrary.")
                        .font(DockType.caption).foregroundStyle(DockTheme.secondary)
                    if resetsSession { Text("Using a different profile resets the session timer.").font(DockType.caption).foregroundStyle(DockTheme.accent) }
                }.padding(DockLayout.margin)
            }
            .background(DockTheme.background).navigationTitle("Game artwork")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(resetsSession ? "Use & reset" : "Use profile") { store.selectGame(profile); dismiss() }
                        .disabled(!valid).accessibilityIdentifier("saveGameProfile")
                }
            }
            .frame(minWidth: 340, minHeight: 280)
        }.preferredColorScheme(.dark).tint(DockTheme.accent)
    }
}
