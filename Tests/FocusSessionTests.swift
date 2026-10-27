import Foundation
#if !CORE_TEST_RUNNER
import XCTest
#endif
#if canImport(ZeroDock)
@testable import ZeroDock
#endif

final class FocusSessionTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1000)

    func testCountdownUsesDeadlineInsteadOfNumberOfViewUpdates() {
        var session = FocusSession()
        session.start(at: start)
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(91)), 1409)
        XCTAssertTrue(session.isRunning(at: start.addingTimeInterval(91)))
    }

    func testPauseFreezesTimeAndResumePreservesRemainingDuration() {
        var session = FocusSession()
        session.start(at: start)
        session.pause(at: start.addingTimeInterval(60))
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(500)), 1440)
        XCTAssertFalse(session.isRunning(at: start.addingTimeInterval(500)))
        session.start(at: start.addingTimeInterval(500))
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(530)), 1410)
    }

    func testExpiredSessionClampsToZeroAndCanRestart() {
        var session = FocusSession()
        session.start(at: start)
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(1600)), 0)
        XCTAssertFalse(session.isRunning(at: start.addingTimeInterval(1600)))
        session.start(at: start.addingTimeInterval(1700))
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(1700)), 1500)
    }

    func testRunningDeadlineSurvivesPersistenceAndAppAbsence() throws {
        var session = FocusSession()
        session.start(at: start)
        let restored = try JSONDecoder().decode(FocusSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(restored.remaining(at: start.addingTimeInterval(720)), 780)
    }

    func testResetClearsDeadlineAndChangesDuration() {
        var session = FocusSession()
        session.start(at: start)
        session.reset(minutes: 45)
        XCTAssertNil(session.deadline)
        XCTAssertEqual(session.remaining(at: start), 2700)
    }
}
