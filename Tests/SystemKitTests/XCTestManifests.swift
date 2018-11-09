import XCTest

extension PathTests {
    static let __allTests = [
        ("testComponents", testComponents),
        ("testEqual", testEqual),
        ("testExists", testExists),
        ("testFileExtension", testFileExtension),
        ("testFilename", testFilename),
        ("testHashable", testHashable),
        ("testHasPrefix", testHasPrefix),
        ("testHasSuffix", testHasSuffix),
        ("testInit", testInit),
        ("testIsDirectory", testIsDirectory),
        ("testIsFile", testIsFile),
        ("testIsRelative", testIsRelative),
        ("testIsSymbolicLink", testIsSymbolicLink),
        ("testJoined", testJoined),
        ("testMakeDirectory", testMakeDirectory),
        ("testNormalized", testNormalized),
        ("testParent", testParent),
        ("testPermissions", testPermissions),
        ("testPrefixShared", testPrefixShared),
        ("testRelative", testRelative),
        ("testRemove", testRemove),
        ("testResolved", testResolved),
        ("testSequence", testSequence),
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
