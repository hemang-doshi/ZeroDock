import Foundation
#if !CORE_TEST_RUNNER
import XCTest
#endif
#if canImport(ZeroDock)
@testable import ZeroDock
#endif

final class PreferencesTests: XCTestCase {
    func testPreferencesAndEditedActionsSurviveStorageRoundTrip() {
        let name = "ZeroDockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let storage = PreferenceStorage(defaults: defaults)
        var value = DockPreferences()
        value.keepAwake = false
        value.showSeconds = true
        value.actions[0].title = "My calendar"
        value.focus.start(at: Date(timeIntervalSince1970: 1000))
        storage.save(value)
        XCTAssertEqual(storage.load(), value)
    }

    func testCorruptStoredDataFallsBackWithoutCrashing() {
        let name = "ZeroDockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("invalid".utf8), forKey: "dock.preferences.v1")
        XCTAssertEqual(PreferenceStorage(defaults: defaults).load().focus.duration, 1500)
    }

    func testQuickActionsRejectUnsafeAndIncompleteURLs() {
        for destination in ["javascript:alert(1)", "file:///private/test", "https://", "not a URL", "prefs:root=General"] {
            XCTAssertNil(QuickAction(title: "Test", symbol: "link", destination: destination).url)
        }
        XCTAssertEqual(QuickAction(title: "Web", symbol: "link", destination: "https://example.com").url?.host, "example.com")
        XCTAssertEqual(QuickAction.defaults[0].url?.scheme, "calshow")
    }

    func testKeepAwakeRequiresBothActiveSceneAndEnabledSetting() {
        XCTAssertTrue(DisplayPolicy.keepAwake(enabled: true, active: true))
        XCTAssertFalse(DisplayPolicy.keepAwake(enabled: true, active: false))
        XCTAssertFalse(DisplayPolicy.keepAwake(enabled: false, active: true))
        XCTAssertFalse(DisplayPolicy.keepAwake(enabled: false, active: false))
    }
}
