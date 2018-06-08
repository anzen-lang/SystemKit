import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(PathTests.allTests),
    testCase(TextFileTests.allTests),
  ]
}
#endif
