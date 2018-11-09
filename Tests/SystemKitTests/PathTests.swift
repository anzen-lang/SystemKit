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

    p = Path(pathname: "/")
    XCTAssert(p.components.isEmpty)
    p = Path(pathname: "/foo")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo"])
    p = Path(pathname: "foo")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo"])
    p = Path(pathname: "foo/")
    XCTAssertEqual(p.components.map({ String($0) }), ["foo"])
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

  func testExists() {
    XCTAssert(Path(pathname: "/").exists)
    XCTAssertFalse(Path(pathname: "/this/is/unlikely/to/exist").exists)
    TextFile.withTemporary {
      XCTAssert($0.path.exists)
    }
  }

  func testIsSymbolicLink() {
    XCTAssertFalse(Path(pathname: "/").isSymbolicLink)
    XCTAssertFalse(Path(pathname: "/this/is/unlikely/to/exist").isSymbolicLink)
  }

  func testIsFile() {
    XCTAssertFalse(Path(pathname: "/").isFile)
    XCTAssertFalse(Path(pathname: "/this/is/unlikely/to/exist").isFile)
    TextFile.withTemporary {
      XCTAssert($0.path.isFile)
    }
  }

  func testIsDirectory() {
    XCTAssert(Path(pathname: "/").isDirectory)
    XCTAssertFalse(Path(pathname: "/this/is/unlikely/to/exist").isDirectory)
    TextFile.withTemporary {
      XCTAssertFalse($0.path.isDirectory)
    }
  }

  func testPermissions() {
    TextFile.withTemporary {
      // Note we can't use `$0.path` directly because `$0` is a constant.
      var path = $0.path

      path.permissions = PermissionTriplet(rawValue: 0)
      XCTAssertEqual(path.permissions!.owner, [])
      XCTAssertEqual(path.permissions!.group, [])
      XCTAssertEqual(path.permissions!.other, [])

      path.permissions = PermissionTriplet(owner: .rx, group: .rw, other: .read)
      XCTAssertEqual(path.permissions!.owner, .rx)
      XCTAssertEqual(path.permissions!.group, .rw)
      XCTAssertEqual(path.permissions!.other, .read)
    }
  }

  func testFilename() {
    var p: Path

    p = Path(pathname: "/")
    XCTAssertNil(p.filename)
    p = Path(pathname: "/foo")
    XCTAssertEqual(p.filename, "foo")
    p = Path(pathname: "/foo.bar")
    XCTAssertEqual(p.filename, "foo.bar")
  }

  func testFileExtension() {
    var p: Path

    p = Path(pathname: "/")
    XCTAssertNil(p.fileExtension)
    p = Path(pathname: "/foo")
    XCTAssertNil(p.fileExtension)
    p = Path(pathname: "/foo.bar")
    XCTAssertEqual(p.fileExtension, "bar")
  }

  func testParent() {
    var p: Path

    p = "foo/bar"
    XCTAssertEqual(p.parent?.pathname, "foo")
    p = "/foo/bar"
    XCTAssertEqual(p.parent?.pathname, "/foo")
  }

  func testNormalized() {
    var p: Path

    p = "foo/bar"
    XCTAssertEqual(p.normalized, "foo/bar")
    p = "/foo/bar"
    XCTAssertEqual(p.normalized, "/foo/bar")

    p = "."
    XCTAssertEqual(p.normalized, ".")
    p = "./foo/bar"
    XCTAssertEqual(p.normalized, "foo/bar")
    p = "foo/./bar"
    XCTAssertEqual(p.normalized, "foo/bar")
    p = "foo/bar/."
    XCTAssertEqual(p.normalized, "foo/bar")

    p = ".."
    XCTAssertEqual(p.normalized, "..")
    p = "../foo/bar"
    XCTAssertEqual(p.normalized, "../foo/bar")
    p = "foo/../bar"
    XCTAssertEqual(p.normalized, "bar")
    p = "foo/bar/.."
    XCTAssertEqual(p.normalized, "foo")
  }

  func testResolved() {
    var p: Path

    p = "/"
    XCTAssertEqual(p.resolved, "/")
    p = "/this/is/unlikely/to/exist"
    XCTAssertNil(p.resolved)
  }

  func testHasPrefix() {
    let p: Path = "/foo/bar"
    XCTAssert(p.hasPrefix("/foo"))
    XCTAssert(p.hasPrefix("/foo/".prefix(3)))
  }

  func testHasSuffix() {
    let p: Path = "/foo/bar"
    XCTAssert(p.hasSuffix("bar"))
    XCTAssert(p.hasSuffix("/bar".suffix(3)))
  }

  func testPrefixShared() {
    var p: Path

    p = "/foo/bar"
    XCTAssertNil(p.prefixShared(with: "qux"))
    XCTAssertEqual(p.prefixShared(with: "/qux"), "/")
    XCTAssertEqual(p.prefixShared(with: "/foo"), "/foo")
    XCTAssertEqual(p.prefixShared(with: "/foo/bar"), "/foo/bar")

    p = "foo/bar"
    XCTAssertNil(p.prefixShared(with: "/qux"))
    XCTAssertNil(p.prefixShared(with: "qux"))
    XCTAssertEqual(p.prefixShared(with: "foo"), "foo")
    XCTAssertEqual(p.prefixShared(with: "foo/bar"), "foo/bar")
  }

  func testJoined() {
    let p: Path = "foo/bar"

    XCTAssertEqual(p.joined(with: "baz/", "qux/quux/"), "foo/bar/baz/qux/quux/")
    XCTAssertEqual(p.joined(with: "baz/", "/qux/quux/"), "/qux/quux/")

    XCTAssertEqual(p.joined(with: p, p), "foo/bar/foo/bar/foo/bar")
    XCTAssertEqual(p.joined(with: p, Path(pathname: "/qux/quux")), "/qux/quux/")
  }

  func testRelative() {
    var p: Path

    p = "/foo/bar"
    XCTAssertEqual(p.relative(to: "qux"), "/foo/bar")
    XCTAssertEqual(p.relative(to: "/qux"), "../foo/bar")
    XCTAssertEqual(p.relative(to: "/foo"), "bar")
    XCTAssertEqual(p.relative(to: "/foo/bar"), ".")

    p = "foo/bar"
    XCTAssertEqual(p.relative(to: "qux"), "../foo/bar")
    XCTAssertEqual(p.relative(to: "/qux"), "foo/bar")
    XCTAssertEqual(p.relative(to: "foo"), "bar")
    XCTAssertEqual(p.relative(to: "foo/bar"), ".")
  }

  func testWorkingDirectory() {
    let tmp = Path.temporaryDirectory.resolved!
    Path.workingDirectory = tmp
    XCTAssertEqual(Path.workingDirectory, tmp)
  }

  func testMakeDirectory() {
    let tmp = Path.temporaryDirectory.resolved!
    let dirname = "__tmp_" + String(describing: DispatchTime.now().uptimeNanoseconds)
    let dirpath = tmp.joined(with: dirname)

    try! Path.makeDirectory(at: dirpath)
    XCTAssert(dirpath.exists)
    XCTAssert(dirpath.isDirectory)
    try! Path.remove(dirpath)
  }

  func testRemove() {
    let tmp = Path.temporaryDirectory.resolved!
    let dirname = "__tmp_" + String(describing: DispatchTime.now().uptimeNanoseconds)
    let dirpath = tmp.joined(with: dirname)

    try! Path.makeDirectory(at: dirpath)
    try! Path.remove(dirpath)
    XCTAssertFalse(dirpath.exists)

    try! Path.makeDirectory(at: dirpath)
    let file = TextFile(path: dirpath.joined(with: "file"))
    try! file.write("Hello, World!")
    try! Path.remove(dirpath, recursively: true)
    XCTAssertFalse(dirpath.exists)
  }

  func testHashable() {
    XCTAssertEqual(Path(pathname: "/foo/bar").hashValue, Path(pathname: "/foo/bar").hashValue)
    XCTAssertNotEqual(Path(pathname: "/foo/bar").hashValue, Path(pathname: "foo/bar").hashValue)
  }

  func testEqual() {
    XCTAssertEqual(Path(pathname: "/foo/bar"), Path(pathname: "/foo/bar"))
    XCTAssertNotEqual(Path(pathname: "/foo/bar"), Path(pathname: "foo/bar"))
  }

  func testSequence() {
    let tmp = Path.temporaryDirectory.resolved!
    let dirname = "__tmp_" + String(describing: DispatchTime.now().uptimeNanoseconds)
    let dirpath = tmp.joined(with: dirname)

    try! Path.makeDirectory(at: dirpath)
    for name in ["a", "b", "c"] {
      let file = TextFile(path: dirpath.joined(with: name))
      try! file.write("Hello, World!")
    }

    let files = Array(dirpath)
    XCTAssertEqual(files.count, 3)
    XCTAssertEqual(Set(files.map({ $0.filename! })), ["a", "b", "c"])

    try! Path.remove(dirpath, recursively: true)
  }

}
