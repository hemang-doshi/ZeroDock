#if CORE_TEST_RUNNER
import Foundation
class XCTestCase {}
var failures = 0
func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #filePath, line: UInt = #line) {
    if actual != expected { failures += 1; print("FAIL \(file):\(line): \(actual) != \(expected)") }
}
func XCTAssertTrue(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) { XCTAssertEqual(value, true, file: file, line: line) }
func XCTAssertFalse(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) { XCTAssertEqual(value, false, file: file, line: line) }
func XCTAssertNil<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) { XCTAssertTrue(value == nil, file: file, line: line) }
#endif
