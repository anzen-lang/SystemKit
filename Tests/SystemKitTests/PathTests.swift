import XCTest
@testable import SystemKit

final class PathTests: XCTestCase {

  func testInit() {
    var p: Path

    // init(pathname: String)
    p = Path(pathname: "/foo/bar")
    XCTAssertEqual(p.pathname, "/foo/bar")
    p = Path(pathname: "/foo/bar/")
    XCTAssertEqual(p.pathname, "/foo/bar/")
    p = Path(pathname: "foo/bar")
    XCTAssertEqual(p.pathname, "foo/bar")
    p = Path(pathname: "foo/bar/")
    XCTAssertEqual(p.pathname, "foo/bar/")

    // init(pathname: Sequence<Character>)
    p = Path(pathname: "/foo/bar".prefix(while: { _ in true }))
    XCTAssertEqual(p.pathname, "/foo/bar")

    // init(stringLiteral value: String)
    let q: Path = "/foo/bar"
    XCTAssertEqual(q.pathname, "/foo/bar")
  }

  func testComponents() {
    var p: Path

    p = Path(pathname: "/foo/bar")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "/foo/bar/")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "foo/bar")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "foo/bar/")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "/foo//bar")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "/foo//bar//")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo", "bar"])
    p = Path(pathname: "/foo\\//bar")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo\\/", "bar"])
  }

  func testIsRelative() {
    let p: Path = "foo/bar"
    XCTAssertTrue(p.isRelative)
    let q: Path = "/foo/bar"
    XCTAssertFalse(q.isRelative)
  }

  static var allTests = [
    ("testInit", testInit),
    ("testComponents", testComponents),
    ("testIsRelative", testIsRelative),
  ]

}
