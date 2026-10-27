import Foundation

struct GamingSession: Codable, Equatable {
    private(set) var accumulated: TimeInterval = 0
    private(set) var startedAt: Date?
    var isRunning: Bool { startedAt != nil }
    func elapsed(at now: Date) -> TimeInterval {
        accumulated + (startedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }
    mutating func start(at now: Date) {
        guard startedAt == nil else { return }
        startedAt = now
    }
    mutating func pause(at now: Date) {
        accumulated = elapsed(at: now)
        startedAt = nil
    }
    mutating func reset() { accumulated = 0; startedAt = nil }
}

struct GameProfile: Codable, Equatable, Identifiable {
    var title: String
    var steamAppID: Int? = nil
    var customArtwork: URL? = nil
    var runtime: String? = nil
    var id: String { title }
    var artworkURL: URL? {
        if let customArtwork, customArtwork.scheme == "https" { return customArtwork }
        guard let steamAppID, steamAppID > 0 else { return nil }
        return URL(string: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/\(steamAppID)/library_600x900.jpg")
    }
    var storeURL: URL? { steamAppID.flatMap { URL(string: "https://store.steampowered.com/app/\($0)/") } }
    // Snapshot verified from this user's launcher targets on 2026-10-19.
    // This is a manual picker, not live Mac detection or a Steam ownership claim.
    static let macLibrary = [
        GameProfile(title: "FC 26", runtime: "Astris"),
        GameProfile(title: "Spider-Man: Miles Morales", steamAppID: 1817190, runtime: "Kegworks · Windows"),
        GameProfile(title: "F1 2017", steamAppID: 515220, runtime: "Native Mac · Feral"),
        GameProfile(title: "Sekiro", steamAppID: 814380, runtime: "Wine · Windows")
    ]
}
struct GamingPreferences: Codable, Equatable {
    var profile: GameProfile?
    var session = GamingSession()
    mutating func select(_ profile: GameProfile) {
        guard self.profile != profile else { return }
        session.reset()
        self.profile = profile
    }
}
enum DockMode: String, Codable, CaseIterable { case focus = "Focus", ambient = "Ambient", gaming = "Gaming" }
