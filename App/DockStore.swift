import Foundation
import Observation

@MainActor @Observable
final class DockStore {
    private let storage: PreferenceStorage
    var preferences: DockPreferences { didSet { storage.save(preferences) } }

    init(defaults: UserDefaults = .standard) {
        let storage = PreferenceStorage(defaults: defaults)
        self.storage = storage
        preferences = storage.load()
    }

    func toggleFocus(at now: Date) {
        if preferences.focus.isRunning(at: now) { preferences.focus.pause(at: now) }
        else { preferences.focus.start(at: now) }
    }

    func toggleGaming(at now: Date) {
        guard preferences.gaming.profile != nil else { return }
        if preferences.gaming.session.isRunning { preferences.gaming.session.pause(at: now) }
        else { preferences.gaming.session.start(at: now) }
    }

    func resetGaming() { preferences.gaming.session.reset() }
    func selectGame(_ profile: GameProfile) { preferences.gaming.select(profile) }

    func resetFocus(minutes: Int? = nil) { preferences.focus.reset(minutes: minutes) }
}
