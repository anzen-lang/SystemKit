import XCTest
@testable import SystemKit

final class TextFileTests: XCTestCase {

  func testWrite() throws {
    try TextFile.withTemporary {
      try $0.write("Hello, World!")
      XCTAssertEqual(try $0.read(), "Hello, World!")

      try $0.write("")
      XCTAssertEqual(try $0.read(), "Hello, World!")

      try $0.write("\n🔥")
      XCTAssertEqual(try $0.read(), "Hello, World!\n🔥")

      try $0.write("こんにちは")
      XCTAssertEqual(try $0.read(), "Hello, World!\n🔥こんにちは")
    }
  }

}
