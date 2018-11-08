import XCTest

extension PathTests {
    static let __allTests = [
        ("testComponents", testComponents),
        ("testInit", testInit),
        ("testIsRelative", testIsRelative),
        ("testWorkingDirectory", testWorkingDirectory),
    ]
}

extension TextFileTests {
    static let __allTests = [
        ("testWrite", testWrite),
    ]
}

extension ThreadTests {
    static let __allTests = [
        ("testThinThread", testThinThread),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
        testCase(TextFileTests.__allTests),
        testCase(ThreadTests.__allTests),
    ]
}
#endif
