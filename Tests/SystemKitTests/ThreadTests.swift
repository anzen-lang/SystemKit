#if !os(Linux)

import XCTest
@testable import SystemKit

final class ThreadTests: XCTestCase {

  func testThinThread() throws {
    class StringRef {
      init(_ value: String) {
        self.value = value
      }
      let value: String
    }

    let thread = try ThinThread { _ in
      return Unmanaged.passRetained(StringRef("foo")).toOpaque()
    }
    let ref = try Unmanaged<StringRef>.fromOpaque(thread.join()!)
    defer { ref.release() }
    XCTAssertEqual(ref.takeUnretainedValue().value, "foo")
    DispatchQueue.main.asyncAfter(
      deadline: .now() + .milliseconds(1), execute: { print(0) })
  }

}

#endif
