import Foundation

struct QuickAction: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var symbol: String
    var destination: String
    var url: URL? {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: destination.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["https", "http", "calshow", "shortcuts", "music", "tel", "facetime"].contains(scheme)
        else { return nil }
        if ["https", "http"].contains(scheme), url.host?.isEmpty != false { return nil }
        return url
    }
    static let defaults = [QuickAction(title: "Calendar", symbol: "calendar", destination: "calshow://"), QuickAction(title: "Shortcuts", symbol: "square.stack.3d.up", destination: "shortcuts://"), QuickAction(title: "Apple", symbol: "safari", destination: "https://www.apple.com")]
}
struct DockPreferences: Codable, Equatable {
    var keepAwake = true
    var showSeconds = false
    var focus = FocusSession()
    var actions = QuickAction.defaults
    var mode = DockMode.focus
    var gaming = GamingPreferences()
    var animateGaming = true

    init() {}

    // New mode fields must not erase a saved focus session from the first build.
    private enum CodingKeys: String, CodingKey {
        case keepAwake, showSeconds, focus, actions, mode, gaming, animateGaming
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        keepAwake = try values.decodeIfPresent(Bool.self, forKey: .keepAwake) ?? true
        showSeconds = try values.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? false
        focus = try values.decodeIfPresent(FocusSession.self, forKey: .focus) ?? FocusSession()
        actions = try values.decodeIfPresent([QuickAction].self, forKey: .actions) ?? QuickAction.defaults
        mode = try values.decodeIfPresent(DockMode.self, forKey: .mode) ?? .focus
        gaming = try values.decodeIfPresent(GamingPreferences.self, forKey: .gaming) ?? GamingPreferences()
        animateGaming = try values.decodeIfPresent(Bool.self, forKey: .animateGaming) ?? true
    }
}
struct PreferenceStorage {
    var defaults: UserDefaults
    private let key = "dock.preferences.v1"
    func load() -> DockPreferences {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(DockPreferences.self, from: data)
        else { return DockPreferences() }
        return value
    }
    func save(_ value: DockPreferences) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
enum DisplayPolicy {
    static func keepAwake(enabled: Bool, active: Bool) -> Bool { enabled && active }
}
