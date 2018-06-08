#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

/// An enumeration permissions.
public struct Permission: OptionSet {

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }

  public let rawValue: UInt16

  public static let execute = Permission(rawValue: 1)
  public static let write   = Permission(rawValue: 2)
  public static let read    = Permission(rawValue: 4)

  public static let rx : Permission = [.read, .execute]
  public static let rw : Permission = [.read, .write]
  public static let rwx: Permission = [.read, .write, .execute]

}

/// A permission triplet associated with a path.
public struct PermissionTriplet {

  public init(owner: Permission, group: Permission, other: Permission) {
    self.owner = owner
    self.group = group
    self.other = other
  }

  public init(rawValue: UInt16) {
    self.owner = Permission(rawValue: (rawValue & (7 << 6)) >> 6)
    self.group = Permission(rawValue: (rawValue & (7 << 3)) >> 3)
    self.other = Permission(rawValue: rawValue & 7)
  }

  public var rawValue: UInt16 {
    return (owner.rawValue << 6) + (group.rawValue << 3) + other.rawValue
  }

  public let owner: Permission
  public let group: Permission
  public let other: Permission

}

/// A struct that represents a path on a Unix-like filesystem.
///
/// Note that such a path only represents a location, independantly to the fact that it may or may
/// not actually exist.
public struct Path {

  /// Constructs a path from a pathname.
  public init(pathname: String) {
    self.pathname = pathname.hasSuffix("/")
      ? String(pathname.dropLast())
      : pathname
  }

  /// Constructs a path from a pathname.
  public init<S>(pathname: S) where S: Sequence, S.Element == Character {
    self.init(pathname: String(pathname))
  }

  /// The concrete representation of the path as a character string.
  public let pathname: String

  /// Whether or not the path is relative.
  public var isRelative: Bool {
    return !pathname.starts(with: "/")
  }

  /// Whether or not the path exists on the filesystem.
  public var exists: Bool {
    do {
      let mode = try _stat().st_mode
      return S_ISDIR(mode) || S_ISREG(mode)
    } catch {
      fatalError(String(describing: error))
    }
  }

  /// Whether or not the path is a symbolic link.
  public var isSymbolicLink: Bool {
    do {
      return S_ISLNK(try _lstat().st_mode)
    } catch {
      fatalError(String(describing: error))
    }
  }

  /// Whether or not the path is a file.
  public var isFile: Bool {
    do {
      return S_ISREG(try _stat().st_mode)
    } catch {
      fatalError(String(describing: error))
    }
  }

  /// Whether or not the path is a directory.
  public var isDirectory: Bool {
    do {
      return S_ISDIR(try _stat().st_mode)
    } catch {
      fatalError(String(describing: error))
    }
  }

  /// The permissions associated with the path.
  public var permissions: PermissionTriplet {
    get {
      do {
        return PermissionTriplet(rawValue: try _stat().st_mode)
      } catch {
        fatalError(String(describing: error))
      }
    }

    set {
      guard chmod(pathname, newValue.rawValue) == 0
        else { fatalError(CError(rawValue: errno)!.description) }
    }
  }

  /// The name of the file this path represents, if any.
  public var filename: Substring? {
    return !pathname.hasSuffix("/")
      ? pathname.split(separator: "/").last
      : nil
  }

  /// The extension of the file this path represents, if any.
  public var fileExtension: Substring? {
    return filename?.split(separator: ".").last
  }

  /// The path representing the directory in which this path's located.
  public var parent: Path? {
    guard pathname != "/"
      else { return nil }

    var lastSeparatorIndex: String.Index? = nil
    for i in pathname.indices.dropFirst() {
      if pathname[i] == "/" {
        lastSeparatorIndex = i
      }
    }

    return lastSeparatorIndex != nil
      ? Path(pathname: pathname[pathname.startIndex ..< lastSeparatorIndex!])
      : nil
  }

  /// The normalized form of the path.
  ///
  /// The normalized form is obtained by removing redundant separators and up-level references.
  public var normalized: Path {
    let components = pathname.split(separator: "/")
    return components.reduce(Path(pathname: isRelative ? "" : "/")) { result, component in
      switch component {
      case ".":
        return result
      case "..":
        return result.parent ?? result.joined(with: "..")
      default:
        return result.joined(with: String(component))
      }
    }
  }

  /// The resolved form of the path.
  ///
  /// The resolved from is obtained by following symlinks in the normalized form.
  public var resolved: Path {
    guard isSymbolicLink
      else { return normalized }
    let buf = UnsafeMutablePointer<CChar>.allocate(capacity: Int(PATH_MAX + 1))
    defer { buf.deallocate() }
    guard let ptr = realpath(pathname, buf)
      else { fatalError(CError(rawValue: errno)!.description) }
    return Path(pathname: String(cString: ptr))
  }

  /// Returns whether or not the path starts with the given prefix.
  public func hasPrefix(_ prefix: Path) -> Bool {
    return pathname.hasPrefix(prefix.pathname)
  }

  /// Returns whether or not the path starts with the given prefix.
  public func hasPrefix<S>(_ prefix: S) -> Bool where S: Sequence, S.Element == Character {
    return hasPrefix(Path(pathname: prefix))
  }

  /// Returns whether or not the path ends with the given prefix.
  public func hasSuffix(_ suffix: Path) -> Bool {
    return pathname.hasSuffix(suffix.pathname)
  }

  /// Returns whether or not the path ends with the given prefix.
  public func hasSuffix<S>(_ suffix: S) -> Bool where S: Sequence, S.Element == Character {
    return hasSuffix(Path(pathname: suffix))
  }

  /// Returns this path joined with one or more paths.
  ///
  /// If the paths that are joined are relative paths, the result will be the concatenations of all
  /// non-empty paths, separated by exactly one separator. If one of the paths is abolute, then the
  /// path(s) on its left are overridden:
  ///
  ///     let path = Path(pathname: "/foo/bar")
  ///     print(path.joined(with: "baz/", "qux/quux/"))
  ///     // Prints "/foo/bar/baz/qux/quux"
  ///     print(path.joined(with: "baz", "/qux/quux/"))
  ///     // Prints "/qux/quux"
  ///
  public func joined(with others: Path...) -> Path {
    return others.reduce(self) { result, other in
      other.isRelative
        ? Path(pathname: result.pathname + "/" + other.pathname)
        : other
    }
  }

  /// Returns this path joined with one or more paths.
  ///
  /// If the paths that are joined are relative paths, the result will be the concatenations of all
  /// non-empty paths, separated by exactly one separator. If one of the paths is abolute, then the
  /// path(s) on its left are overridden:
  ///
  ///     let path = Path(pathname: "/foo/bar")
  ///     print(path.joined(with: "baz/", "qux/quux/"))
  ///     // Prints "/foo/bar/baz/qux/quux"
  ///     print(path.joined(with: "baz", "/qux/quux/"))
  ///     // Prints "/qux/quux"
  ///
  public func joined(with others: String...) -> Path {
    return others.reduce(self) { result, pathname in
      !pathname.starts(with: "/")
        ? Path(pathname: result.pathname + "/" + pathname)
        : Path(pathname: pathname)
    }
  }

  /// Returns a path that resolves to this path, relative to a given path.
  ///
  /// - Parameters:
  ///   - other: The path from wich the returned path will be relative to. It is expected to
  ///     represent a directory.
  /// - Returns: The relative path that resolves to this path, relative to `other`.
  ///
  /// - Note: If this path is absolute and `other` is relative, this function will return the
  ///   former path, unchanged.
  public func relative(to other: Path) -> Path {
    // If the path is absolute, the other should too or they don't share a common prefix.
    guard isRelative || !other.isRelative
      else { return self }

    let lhs = pathname.split(separator: "/")
    let rhs = other.pathname.split(separator: "/")
    var i = 0
    while i < Swift.min(lhs.count, rhs.count) {
      guard lhs[i] == rhs[i] else { break }
      i += 1
    }

    let rel = [String](repeating: "..", count: rhs.count - i) + lhs.dropFirst(i).map({ String($0) })
    return rel.isEmpty
      ? Path(pathname: ".")
      : Path(pathname: rel.joined(separator: "/"))
  }

  /// Returns the prefix shared between this path and another.
  public func prefixShared(with other: Path) -> Path? {
    guard isRelative == other.isRelative
      else { return nil }

    let lhs = pathname.split(separator: "/")
    let rhs = other.pathname.split(separator: "/")
    let shd = Array(zip(lhs, rhs).prefix(while: ==)).map({ String($0.0) }).joined(separator: "/")

    guard !shd.isEmpty
      else { return nil }
    return isRelative
      ? Path(pathname: shd)
      : Path(pathname: "/" + shd)
  }

  /// Creates an iterator that iterates over the files and sub-directories of the path.
  public func makeDirectoryIterator() throws -> DirectoryIterator {
    guard let iterator = DirectoryIterator(directoryPath: self)
      else { throw CError(rawValue: errno)! }
    return iterator
  }

  /// The current working directory.
  public static var currentWorkingDirectory: Path {
    let cwd = getcwd(UnsafeMutablePointer(bitPattern: 0), 0)
    defer { cwd?.deallocate() }
    return Path(pathname: cwd.map({ String(cString: $0) }) ?? "")
  }

  /// A temporary directory.
  ///
  /// This path is equivalent to `$TMPDIR`. If such environment variable isn't defined, then the
  /// property falls back to `/tmp`, which is checked for existence. In last result, the current
  /// working directory is used.
  public static var temporaryDirectory: Path {
    guard let tmpdir = getenv("TMPDIR") else {
      let tmp = Path(pathname: "/tmp")
      return tmp.exists ? tmp : .currentWorkingDirectory
    }
    return Path(pathname: String(cString: tmpdir))
  }

  /// Creates a directory at the given path.
  public static func makeDirectory(
    at path: Path,
    permission: PermissionTriplet = PermissionTriplet(owner: .rwx, group: .rx, other: .rx)) throws
  {
    guard mkdir(path.pathname, permission.rawValue) == 0
      else { throw CError(rawValue: errno)! }
  }

  /// Removes the entry at the given path.
  ///
  /// The path must point to an existing file or directory. If `path` is a directory, it must be
  /// empty unless `recursively` is set to true.
  public static func remove(_ path: Path, recursively: Bool = false) throws {
    if recursively && path.isDirectory {
      for entry in path {
        try Path.remove(entry, recursively: true)
      }
    }
    guard Darwin.remove(path.pathname) == 0
      else { throw CError(rawValue: errno)! }
  }

  /// The result of `stat` for the path.
  internal func _stat() throws -> stat {
    let buf = UnsafeMutablePointer<stat>.allocate(capacity: 1)
    defer { buf.deallocate() }
    guard stat(pathname, buf) == 0
      else { throw CError(rawValue: errno)! }
    return buf.pointee
  }

  /// The result of `lstat` for the path.
  internal func _lstat() throws -> stat {
    let buf = UnsafeMutablePointer<stat>.allocate(capacity: 1)
    defer { buf.deallocate() }
    guard lstat(pathname, buf) == 0
      else { throw CError(rawValue: errno)! }
    return buf.pointee
  }

}

extension Path: Sequence {

  public func makeIterator() -> DirectoryIterator {
    return DirectoryIterator(directoryPath: self)!
  }

}

extension Path: Hashable {

  public var hashValue: Int {
    return pathname.hashValue
  }

  public static func == (lhs: Path, rhs: Path) -> Bool {
    return lhs.pathname == rhs.pathname
  }

}

extension Path: ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {
    self.init(pathname: value)
  }

}

extension Path: CustomStringConvertible {

  public var description: String {
    return pathname
  }

}

/// Class representing an iterator over the entities of a directory.
public class DirectoryIterator: IteratorProtocol {

  fileprivate init?(directoryPath: Path) {
    dir = opendir(directoryPath.pathname)
    guard dir != nil
      else { return nil }
  }

  deinit {
    if dir != nil {
      closedir(dir)
    }
  }

  private let dir: UnsafeMutablePointer<DIR>?

  public func next() -> Path? {
    while let entry = readdir(dir)?.pointee {
      let mirror = Mirror(reflecting: entry.d_name)
      let buf = mirror.children.prefix(Int(entry.d_namlen)).map({ $0.value as! CChar }) + [0]
      let pathname = String(cString: buf)
      guard pathname != "." && pathname != ".."
        else { continue }
      return Path(pathname: pathname)
    }
    return nil
  }

}

public protocol FileLike {

  associatedtype Char
  associatedtype CharSequence: Sequence where CharSequence.Element == Char

  /// Read up to `count` elements from the file object, skipping `offset` elements.
  func read(count: Int, from offset: Int) -> CharSequence

  /// Write a sequence of elements into the file object.
  func write<S>(_ elements: S) where S: Sequence, S.Element == Char

  /// The size of the file, in bytes (i.e. 8-bit characters).
  ///
  /// Note that the size of the file may not necessarily be equal to its number of characters. This
  /// depends on the size of `Char`.
  var byteCount: Int { get }

}

public protocol LocalFile: FileLike {

  init(path: Path)

  var path: Path { get }

}

extension LocalFile {

  /// The size of the file, in bytes.
  ///
  /// - Note: The value of this property isn't necessarily equal to the number of "characters" in a
  ///   file, as the size of such characters might be larger than that of a byte.
  public var byteCount: Int {
    return try! Int(path._stat().st_size)
  }

  public static func withTemporary<Result>(
    prefix: String = "swifttemp.",
    body: (Self) throws -> Result) rethrows -> Result
  {
    let template = Path.temporaryDirectory.pathname + prefix + "XXXXXX"
    var buffer = template.utf8CString
    _ = buffer.withUnsafeMutableBufferPointer {
      return mkstemp($0.baseAddress)
    }
    let pathname = String(cString: buffer.withUnsafeBufferPointer { $0.baseAddress! })
    defer { remove(pathname) }
    return try body(Self(path: Path(pathname: pathname)))
  }

}

public struct BinaryFile: LocalFile {

  public typealias Char = Int8
  public typealias CharSequence = [Char]

  public init(path: Path) {
    self.path = path
  }

  public let path: Path

  public func read(count: Int, from offset: Int) -> CharSequence {
    guard let pointer = fopen(path.pathname, "r")
      else { fatalError(CError(rawValue: errno)!.description) }
    defer { fclose(pointer) }

    var buffer = CharSequence(repeating: 0, count: count)
    fseek(pointer, offset, SEEK_SET)
    let readCount = buffer.withUnsafeMutableBytes {
      fread($0.baseAddress!, MemoryLayout<Char>.size, count, pointer)
    }
    return Array(buffer.prefix(readCount))
  }

  public func write<S>(_ elements: S) where S : Sequence, S.Element == Char {
    guard let pointer = fopen(path.pathname, "a")
      else { fatalError(CError(rawValue: errno)!.description) }
    defer { fclose(pointer) }

    let buffer = Array(elements)
    let writeCount = buffer.withUnsafeBytes {
      fwrite($0.baseAddress!, MemoryLayout<Char>.size, buffer.count, pointer)
    }
    guard writeCount == buffer.count
      else { fatalError(CError(rawValue: errno)!.description) }
  }

}

public struct TextFile: LocalFile {

  public typealias Char = Character
  public typealias CharSequence = String

  public init(path: Path) {
    self.path = path
  }

  public let path: Path

  public func read(count: Int, from offset: Int) -> String {
    guard let pointer = fopen(path.pathname, "r")
      else { fatalError(CError(rawValue: errno)!.description) }
    defer { fclose(pointer) }

    setlocale(LC_ALL, "")
    var buffer: [wint_t] = []
    while buffer.count < (count + offset) {
      let char = fgetwc(pointer)
      guard char != WEOF else { break }
      buffer.append(char)
    }

    return String(buffer.dropFirst(offset).map({ Character(Unicode.Scalar(UInt32($0))!) }))
  }

  public func write<S>(_ elements: S) where S : Sequence, S.Element == Character {
    guard let pointer = fopen(path.pathname, "a")
      else { fatalError(CError(rawValue: errno)!.description) }
    defer { fclose(pointer) }

    let string = String(elements)
    let writeCount = string.withCString {
      fwrite($0, MemoryLayout<CChar>.size, strlen($0), pointer)
    }
    guard writeCount == string.count
      else { fatalError(CError(rawValue: errno)!.description) }
  }

}
