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
    self.pathname = pathname
  }

  /// Constructs a path from a pathname.
  public init<S>(pathname: S) where S: Sequence, S.Element == Character {
    self.init(pathname: String(pathname))
  }

  /// The concrete representation of the path as a character string.
  public let pathname: String

  /// The components of the pathname.
  public var components: [Substring] {
    guard pathname != "/"
      else { return [] }

    var i = pathname.startIndex
    var j = i
    var result: [Substring] = []

    while j != pathname.endIndex {
      if pathname[j] == "/" {
        guard i != j else {
          // Skip consecutive separators.
          j = pathname.index(after: j)
          i = j
          continue
        }
        result.append(pathname[i ..< j])
        j = pathname.index(after: j)
        i = j
      } else if pathname[j] == "\\" {
        // Skip escaped separators.
        j = pathname.index(after: j)
        if pathname[j] == "/" {
          j = pathname.index(after: j)
        }
      } else {
        j = pathname.index(after: j)
      }
    }

    // Add the last component.
    if j > i {
      result.append(pathname[i ..< j])
    }

    return result
  }

  /// Whether or not the path is relative.
  public var isRelative: Bool {
    return !pathname.starts(with: "/")
  }

  /// Whether or not the path exists on the filesystem.
  ///
  /// - Remark: The value of this property is determined using the result of `stat` on the pathname.
  ///   If the call to `stat` failed for some reason, the property will be considered false.
  ///
  /// - Note: Attempting to predicate behavior based on the state of the filesystem is discouraged,
  ///   as it can cause unexpected results with respect to race conditions. Attempting operations
  ///   directly and handling potential subsequent errors should be preferred.
  public var exists: Bool {
    guard let mode = try? _stat().st_mode
      else { return false }
    return S_ISDIR(mode) || S_ISREG(mode)
  }

  /// Whether or not the path is a symbolic link.
  ///
  /// - Remark: The value of this property is determined using the result of `stat` on the pathname.
  ///   If the call to `stat` failed for some reason, the property will be considered false.
  ///
  /// - Note: Attempting to predicate behavior based on the state of the filesystem is discouraged,
  ///   as it can cause unexpected results with respect to race conditions. Attempting operations
  ///   directly and handling potential subsequent errors should be preferred.
  public var isSymbolicLink: Bool {
    guard let mode = try? _stat().st_mode
      else { return false }
    return S_ISLNK(mode)
  }

  /// Whether or not the path is a file.
  ///
  /// - Remark: The value of this property is determined using the result of `stat` on the pathname.
  ///   If the call to `stat` failed for some reason, the property will be considered false.
  ///
  /// - Note: Attempting to predicate behavior based on the state of the filesystem is discouraged,
  ///   as it can cause unexpected results with respect to race conditions. Attempting operations
  ///   directly and handling potential subsequent errors should be preferred.
  public var isFile: Bool {
    guard let mode = try? _stat().st_mode
      else { return false }
    return S_ISREG(mode)
  }

  /// Whether or not the path is a directory.
  ///
  /// - Remark: The value of this property is determined using the result of `stat` on the pathname.
  ///   If the call to `stat` failed for some reason, the property will be considered false.
  ///
  /// - Note: Attempting to predicate behavior based on the state of the filesystem is discouraged,
  ///   as it can cause unexpected results with respect to race conditions. Attempting operations
  ///   directly and handling potential subsequent errors should be preferred.
  public var isDirectory: Bool {
    guard let mode = try? _stat().st_mode
      else { return false }
    return S_ISDIR(mode)
  }

  /// The permissions associated with the path.
  ///
  /// - Remark: This property is an optional, because it relies on the result of a call to `stat` on
  ///   the pathname of the path, which may fail for some reason. In thoses instances, the property
  ///   will be computed as a `nil` value.
  ///   Setting the property is done by calling `chmod`. If the call to this function fails for some
  ///   reason, the program will ends with an unrecoverable error. Setting the property to a `nil`
  ///   value is a no-op.
  ///
  /// - Note: Attempting to predicate behavior based on the state of the filesystem is discouraged,
  ///   as it can cause unexpected results with respect to race conditions. Attempting operations
  ///   directly and handling potential subsequent errors should be preferred.
  public var permissions: PermissionTriplet? {
    get {
      return (try? _stat().st_mode).map { PermissionTriplet(rawValue: $0) }
    }

    set {
      guard let mode = newValue?.rawValue
        else { return }
      guard chmod(pathname, mode) == 0
        else { fatalError(CError(rawValue: errno)!.description) }
    }
  }

  /// The name of the file this path represents, if any.
  public var filename: Substring? {
    return !pathname.hasSuffix("/")
      ? components.last
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

    let parentComponents = components.dropLast().joined()
    return !parentComponents.isEmpty
      ? Path(pathname: parentComponents)
      : nil
  }

  /// The normalized form of the path.
  ///
  /// The normalized form is obtained by removing redundant separators and up-level references.
  public var normalized: Path {
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
  ///
  /// - Remark: This property is an optional, because it relies on the result of a call to
  ///   `realpath` on the pathname of the path, which may fail for some reason. In thoses instances,
  ///   the property will be computed as a `nil` value.
  public var resolved: Path? {
    let buf = UnsafeMutablePointer<CChar>.allocate(capacity: Int(PATH_MAX + 1))
    defer { buf.deallocate() }
    guard let ptr = realpath(pathname, buf)
      else { return nil }
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

    let lhs = components
    let rhs = other.components
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

    let lhs = components
    let rhs = other.components
    let shd = Array(zip(lhs, rhs).prefix(while: ==)).map({ String($0.0) }).joined(separator: "/")

    guard !shd.isEmpty
      else { return nil }
    return isRelative
      ? Path(pathname: shd)
      : Path(pathname: "/" + shd)
  }

  /// Creates an iterator that iterates over the files and sub-directories of the path.
  public func makeDirectoryIterator() throws -> DirectoryIterator {
    guard let iterator = DirectoryIterator(base: self)
      else { throw CError(rawValue: errno)! }
    return iterator
  }

  /// The current working directory.
  ///
  /// - Remark: Setting the property is done by calling `chdir`. If the call to this function fails
  ///   for some reason, the program will ends with an unrecoverable error.
  public static var workingDirectory: Path {
    get {
      let cwd = getcwd(UnsafeMutablePointer(bitPattern: 0), 0)
      defer { cwd?.deallocate() }
      return Path(pathname: cwd.map({ String(cString: $0) }) ?? "")
    }

    set {
      guard chdir(newValue.pathname) == 0
        else { fatalError(CError(rawValue: errno)!.description) }
    }
  }

  /// A temporary directory.
  ///
  /// This path is equivalent to `$TMPDIR`. If such environment variable isn't defined, then the
  /// property falls back to `/tmp`, which is checked for existence. In last result, the current
  /// working directory is used.
  public static var temporaryDirectory: Path {
    guard let tmpdir = getenv("TMPDIR") else {
      let tmp = Path(pathname: "/tmp")
      return tmp.exists ? tmp : .workingDirectory
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
    #if os(Linux)
    guard Glibc.remove(path.pathname) == 0
      else { throw CError(rawValue: errno)! }
    #else
    guard Darwin.remove(path.pathname) == 0
      else { throw CError(rawValue: errno)! }
    #endif
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
    return DirectoryIterator(base: self)!
  }

}

extension Path: Hashable {

  public var hashValue: Int {
    return pathname.hashValue
  }

  public static func == (lhs: Path, rhs: Path) -> Bool {
    return lhs.pathname == rhs.pathname
        || lhs.isRelative == rhs.isRelative && lhs.components == rhs.components
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

  fileprivate init?(base: Path) {
    dir = opendir(base.pathname)
    guard dir != nil
      else { return nil }
    self.base = base
  }

  deinit {
    if dir != nil {
      closedir(dir)
    }
  }

  public let base: Path
  private let dir: UnsafeMutablePointer<DIR>?

  public func next() -> Path? {
    while let entry = readdir(dir)?.pointee {
      let mirror = Mirror(reflecting: entry.d_name)
      let buf = mirror.children.prefix(Int(entry.d_namlen)).map({ $0.value as! CChar }) + [0]
      let pathname = String(cString: buf)
      guard pathname != "." && pathname != ".."
        else { continue }
      return base.joined(with: pathname)
    }
    return nil
  }

}

public protocol FileLike {

  associatedtype Char
  associatedtype CharSequence: Sequence where CharSequence.Element == Char

  /// Reads up to `count` elements from the file object, skipping `offset` elements.
  func read(count: Int, from offset: Int) throws -> CharSequence

  /// Reads the entire file.
  func read() throws -> CharSequence

  /// Writes a sequence of elements into the file object.
  func write<S>(_ elements: S) throws where S: Sequence, S.Element == Char

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

  // MARK: Safe methods

  public func safeByteCount() throws -> Int {
    return try Int(path._stat().st_size)
  }

}

public struct BinaryFile: LocalFile {

  public typealias Char = Int8
  public typealias CharSequence = [Char]

  public init(path: Path) {
    self.path = path
  }

  public let path: Path

  public func read(count: Int, from offset: Int) throws -> CharSequence {
    guard let pointer = fopen(path.pathname, "r")
      else { throw CError(rawValue: errno)! }
    defer { fclose(pointer) }

    var buffer = CharSequence(repeating: 0, count: count)
    fseek(pointer, offset, SEEK_SET)
    let readCount = buffer.withUnsafeMutableBytes {
      fread($0.baseAddress!, MemoryLayout<Char>.size, count, pointer)
    }
    return Array(buffer.prefix(readCount))
  }

  public func read() throws -> CharSequence {
    return try read(count: safeByteCount(), from: 0)
  }

  public func write<S>(_ elements: S) throws where S : Sequence, S.Element == Char {
    guard let pointer = fopen(path.pathname, "a")
      else { throw CError(rawValue: errno)! }
    defer { fclose(pointer) }

    let buffer = Array(elements)
    let writeCount = buffer.withUnsafeBytes {
      fwrite($0.baseAddress!, MemoryLayout<Char>.size, buffer.count, pointer)
    }
    guard writeCount == buffer.count
      else { throw CError(rawValue: errno)! }
  }

}

public struct TextFile: LocalFile {

  public typealias Char = Character
  public typealias CharSequence = String

  public init(path: Path) {
    self.path = path
  }

  public let path: Path

  public func read(count: Int, from offset: Int) throws -> String {
    guard let pointer = fopen(path.pathname, "r")
      else { throw CError(rawValue: errno)! }
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

  public func read() throws -> CharSequence {
    guard let pointer = fopen(path.pathname, "r")
      else { throw CError(rawValue: errno)! }
    defer { fclose(pointer) }

    let nitems = byteCount
    var buffer = [Int8](repeating: 0, count: nitems + 1)
    try buffer.withUnsafeMutableBytes {
      guard fread($0.baseAddress!, MemoryLayout<CChar>.size, nitems, pointer) == nitems
        else { throw CError(rawValue: errno)! }
    }
    return String(cString: buffer)
  }

  public func write<S>(_ elements: S) throws where S : Sequence, S.Element == Character {
    guard let pointer = fopen(path.pathname, "a")
      else { throw CError(rawValue: errno)! }
    defer { fclose(pointer) }

    let string = String(elements)
    let writeCount = string.withCString {
      fwrite($0, MemoryLayout<CChar>.size, strlen($0), pointer)
    }
    guard writeCount == string.utf8CString.count - 1
      else { throw CError(rawValue: errno)! }
  }

}
