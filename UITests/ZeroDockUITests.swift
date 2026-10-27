import XCTest
import UIKit

@MainActor
final class ZeroDockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func testNavigationAndLandscapeScreenshots() {
        let app = XCUIApplication()
        app.launch()
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            for page in ["Focus", "Ambient", "Gaming"] {
                app.buttons["nav\(page)"].tap()
                XCTAssertTrue(app.buttons["navFocus"].isHittable)
                XCTAssertGreaterThan(app.frame.width, app.frame.height)
                if page == "Ambient" { XCTAssertTrue(app.staticTexts["liveClock"].exists) }
                let capture = XCTAttachment(screenshot: app.screenshot())
                capture.name = "\(page)-\(orientation.rawValue)"
                capture.lifetime = .keepAlways
                add(capture)
            }
        }
    }

    func testFocusCountsDownPausesRestoresAndResets() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["navFocus"].tap()
        app.buttons["focusReset"].tap()
        app.buttons["preset25"].tap()
        let value = app.staticTexts["focusRemaining"]
        XCTAssertEqual(value.label, "25:00")
        app.buttons["focusToggle"].tap()
        expectation(for: NSPredicate(format: "label != %@", "25:00"), evaluatedWith: value)
        waitForExpectations(timeout: 4)
        app.buttons["focusToggle"].tap()
        let paused = value.label
        app.terminate()
        app.launch()
        XCTAssertEqual(value.label, paused)
        XCTAssertTrue(app.buttons["focusToggle"].label.contains("Resume"))
        app.buttons["focusToggle"].tap()
        app.buttons["navAmbient"].tap()
        app.buttons["navFocus"].tap()
        XCTAssertTrue(app.buttons["focusToggle"].label.contains("Pause"))
        app.buttons["focusReset"].tap()
        XCTAssertEqual(value.label, "25:00")
    }

    func testManualGameSessionPersistsAndMetricsStayUnavailable() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["navGaming"].tap()
        app.buttons["chooseGame"].tap()
        app.buttons["profileF1 2017"].tap()
        app.buttons["saveGameProfile"].tap()
        XCTAssertEqual(app.staticTexts["gameTitle"].label, "F1 2017")
        XCTAssertTrue(app.staticTexts["Mac not connected"].exists)
        app.buttons["gameReset"].tap()
        app.buttons["gameToggle"].tap()
        let value = app.staticTexts["gameElapsed"]
        expectation(for: NSPredicate(format: "label != %@", "00:00:00"), evaluatedWith: value)
        waitForExpectations(timeout: 4)
        app.buttons["gameToggle"].tap()
        let paused = value.label
        app.terminate()
        app.launch()
        XCTAssertEqual(app.staticTexts["gameTitle"].label, "F1 2017")
        XCTAssertEqual(value.label, paused)
        app.buttons["gameToggle"].tap()
        XCTAssertTrue(app.buttons["gameToggle"].label.contains("Pause"))
        app.buttons["gameReset"].tap()
        XCTAssertEqual(value.label, "00:00:00")
    }

    func testDisplaySettingsPersistAndReturnToTheSameMode() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["navAmbient"].tap()
        app.buttons["openSettings"].tap()
        let seconds = app.switches["showSeconds"]
        seconds.tap()
        let saved = seconds.value as? String
        app.buttons["closeSettings"].tap()
        XCTAssertTrue(app.staticTexts["liveClock"].exists)
        app.terminate()
        app.launch()
        app.buttons["openSettings"].tap()
        XCTAssertEqual(seconds.value as? String, saved)
        app.buttons["closeSettings"].tap()
    }

    /// Objective alignment checks. The numbers come from docs/design-system.md: one centre axis,
    /// equal halves, equal side margins, controls of at least 44 pt.
    func testLayoutIsSymmetricAndAligned() {
        let app = XCUIApplication()
        app.launch()
        let screen = app.frame
        func frame(_ id: String) -> CGRect {
            let element = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 3), "\(id) missing")
            return element.frame
        }
        func near(_ a: CGFloat, _ b: CGFloat, _ message: String, tolerance: CGFloat = 1.5) {
            XCTAssertEqual(a, b, accuracy: tolerance, message)
        }
        // Frames are read after the mode-change spring (about 0.5 s) has finished.
        func select(_ mode: String) {
            app.buttons["nav\(mode)"].tap()
            RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        }
        func checkChrome(_ mode: String) {
            let segments = ["Focus", "Ambient", "Gaming"].map { app.buttons["nav\($0)"].frame }
            let switcher = segments.dropFirst().reduce(segments[0]) { $0.union($1) }
            near(switcher.midX, screen.midX, "\(mode): switcher centred on the screen axis")
            // Half a point of slack: frames are read while the mode-change spring may still be settling.
            for button in app.buttons.allElementsBoundByIndex where button.isHittable {
                XCTAssertGreaterThanOrEqual(button.frame.width, 43.5, "\(mode): \(button.identifier) too narrow")
                XCTAssertGreaterThanOrEqual(button.frame.height, 43.5, "\(mode): \(button.identifier) too short")
            }
        }
        // A container's frame is the union of its children, so only halves whose children fill
        // them (the Gaming cards) can be compared by height.
        func checkHalves(_ mode: String, childrenFill: Bool) -> (left: CGRect, right: CGRect) {
            let left = frame("halfLeft"), right = frame("halfRight")
            near(left.width, right.width, "\(mode): halves equal width")
            if childrenFill {
                near(left.height, right.height, "\(mode): halves equal height")
                near(left.minY, right.minY, "\(mode): halves share a top edge")
            }
            near(left.minX - screen.minX, screen.maxX - right.maxX, "\(mode): equal side margins")
            near((left.maxX + right.minX) / 2, screen.midX, "\(mode): gutter on the screen axis")
            return (left, right)
        }

        select("Focus")
        checkChrome("Focus")
        let focus = checkHalves("Focus", childrenFill: false)
        // In Focus the left half measures as the ring and the right half as the controls column.
        near(focus.left.width, focus.right.width, "Focus: ring and controls share a width")
        near(focus.left.midY, focus.right.midY, "Focus: ring and controls share a vertical centre")

        select("Gaming")
        checkChrome("Gaming")
        let gaming = checkHalves("Gaming", childrenFill: true)
        let strip = frame("metricsStrip")
        near(strip.minX, gaming.left.minX, "Gaming: strip starts at the left card edge")
        near(strip.maxX, gaming.right.maxX, "Gaming: strip ends at the right card edge")
        // Cell 0 is a container (content-sized); cells 1 to 3 are leaves whose left edge is a column
        // edge plus the 16 pt card padding.
        let cells = (0..<4).map { frame("metricCell\($0)") }
        let column = strip.width / 4
        let padding: CGFloat = 16
        for index in 1..<4 {
            near(cells[index].minX - padding, strip.minX + column * CGFloat(index), "Gaming: column \(index) starts on the quarter line; frames \(cells), strip \(strip)")
        }
        near(cells[2].minX - padding, screen.midX, "Gaming: middle divider on the screen axis")

        select("Ambient")
        checkChrome("Ambient")
        let ambient = frame("ambientDashboard")
        // The clock drifts up to 12 pt sideways and 8 pt vertically by minute (OLED burn-in protection),
        // so it is centred within that budget plus the usual 1.5 pt.
        near(ambient.midX, screen.midX, "Ambient: centred horizontally on the screen", tolerance: 13.5)
        near(ambient.midY, screen.midY, "Ambient: centred vertically on the screen", tolerance: 9.5)
    }

    func testLaunchHasNoCalendarPromptOrLauncherRow() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertTrue(app.buttons["navFocus"].isHittable)
        XCTAssertFalse(app.buttons["Open Apple"].exists)
        XCTAssertFalse(app.buttons["Open Shortcuts"].exists)
    }
}
