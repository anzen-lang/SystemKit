import XCTest

extension PathTests {
    static let __allTests = [
        ("testComponents", testComponents),
        ("testInit", testInit),
        ("testIsRelative", testIsRelative),
        ("testParent", testParent),
        ("testWorkingDirectory", testWorkingDirectory),
    ]
}

extension TextFileTests {
    static let __allTests = [
        ("testWrite", testWrite),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
        testCase(TextFileTests.__allTests),
    ]
}
#endif
