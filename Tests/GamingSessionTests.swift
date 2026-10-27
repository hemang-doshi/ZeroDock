import Foundation
#if !CORE_TEST_RUNNER
import XCTest
#endif
#if canImport(ZeroDock)
@testable import ZeroDock
#endif

final class GamingSessionTests: XCTestCase {
    let origin = Date(timeIntervalSince1970: 1000)

    func testElapsedTimeContinuesWithoutViewTicksAndStartIsIdempotent() {
        var session = GamingSession()
        session.start(at: origin)
        session.start(at: origin.addingTimeInterval(50))
        XCTAssertEqual(session.elapsed(at: origin.addingTimeInterval(125)), 125)
        XCTAssertTrue(session.isRunning)
    }

    func testPausedTimeIsExcludedAndResetStopsTheSession() {
        var session = GamingSession()
        session.start(at: origin)
        session.pause(at: origin.addingTimeInterval(120))
        XCTAssertEqual(session.elapsed(at: origin.addingTimeInterval(500)), 120)
        XCTAssertFalse(session.isRunning)
        session.start(at: origin.addingTimeInterval(500))
        XCTAssertEqual(session.elapsed(at: origin.addingTimeInterval(560)), 180)
        session.reset()
        XCTAssertEqual(session.elapsed(at: origin.addingTimeInterval(600)), 0)
        XCTAssertFalse(session.isRunning)
    }

    func testRunningSessionRestoresElapsedTimeAfterRelaunch() throws {
        var session = GamingSession()
        session.start(at: origin)
        let decoded = try JSONDecoder().decode(GamingSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(decoded.elapsed(at: origin.addingTimeInterval(3601)), 3601)
    }

    func testChangingGameResetsTimerButReselectingSameProfilePreservesIt() {
        var value = GamingPreferences()
        value.select(GameProfile(title: "Sekiro", steamAppID: 814380))
        value.session.start(at: origin)
        value.select(GameProfile(title: "Sekiro", steamAppID: 814380))
        XCTAssertEqual(value.session.elapsed(at: origin.addingTimeInterval(60)), 60)
        value.select(GameProfile(title: "F1 2017", steamAppID: 515220))
        XCTAssertEqual(value.session.elapsed(at: origin.addingTimeInterval(120)), 0)
        XCTAssertFalse(value.session.isRunning)
    }

    func testLegacyPreferencesKeepExistingFocusAndDisplaySettings() throws {
        let old = Data(#"{"keepAwake":false,"showSeconds":true,"focus":{"duration":2700,"pausedRemaining":1200},"actions":[]}"#.utf8)
        let value = try JSONDecoder().decode(DockPreferences.self, from: old)
        XCTAssertFalse(value.keepAwake)
        XCTAssertTrue(value.showSeconds)
        XCTAssertEqual(value.focus.remaining(at: origin), 1200)
        XCTAssertEqual(value.mode, .focus)
        XCTAssertNil(value.gaming.profile)
        XCTAssertTrue(value.animateGaming)
    }

    func testGamingProfileModeAndMotionPreferenceRoundTrip() throws {
        var value = DockPreferences()
        value.mode = .gaming
        value.animateGaming = false
        value.gaming.select(GameProfile(title: "Custom game", steamAppID: 1817070))
        value.gaming.session.start(at: origin)
        let decoded = try JSONDecoder().decode(DockPreferences.self, from: JSONEncoder().encode(value))
        XCTAssertEqual(decoded.mode, .gaming)
        XCTAssertEqual(decoded.gaming.profile?.title, "Custom game")
        XCTAssertFalse(decoded.animateGaming)
        XCTAssertEqual(decoded.gaming.session.elapsed(at: origin.addingTimeInterval(80)), 80)
    }
    func testLibraryMatchesVerifiedMacEditions() {
        let library = GameProfile.macLibrary
        XCTAssertEqual(library.map(\.title), ["FC 26", "Spider-Man: Miles Morales", "F1 2017", "Sekiro"])
        XCTAssertEqual(library[1].steamAppID, 1817190)
        XCTAssertEqual(library[2].steamAppID, 515220)
        XCTAssertNil(library[0].steamAppID)
        XCTAssertEqual(library[0].runtime, "Astris")
        XCTAssertEqual(library[2].runtime, "Native Mac · Feral")
    }

}
