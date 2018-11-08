#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

/// A mapping structure representing the string environment.
public struct Environment: RandomAccessCollection {

  internal init() {}

  public struct Index: Comparable {

    fileprivate let offset: Int

    fileprivate static var start: Index {
      return Index(offset: 0)
    }

    fileprivate static var end: Index {
      var offset = 0
      var key = environ
      repeat {
        offset += 1
        key = key.advanced(by: 1)
      } while key.pointee != nil
      return Index(offset: offset)
    }

    public static func < (lhs: Index, rhs: Index) -> Bool {
      return lhs.offset < rhs.offset
    }

  }

  /// A view of the environment keys.
  public struct Keys: RandomAccessCollection {

    public var startIndex: Index { return Index.start }
    public var endIndex: Index { return Index.end }

    public func index(after i: Index) -> Index {
      return Index(offset: i.offset + 1)
    }

    public func index(before i: Index) -> Index {
      return Index(offset: i.offset - 1)
    }

    public subscript(position: Index) -> String {
      return String(cString: environ.advanced(by: position.offset).pointee!)
    }

  }

  /// A view of the environment values.
  public struct Values: RandomAccessCollection {

    public var startIndex: Index { return Index.start }
    public var endIndex: Index { return Index.end }

    public func index(after i: Index) -> Index {
      return Index(offset: i.offset + 1)
    }

    public func index(before i: Index) -> Index {
      return Index(offset: i.offset - 1)
    }

    public subscript(position: Index) -> String {
      let key: UnsafeMutablePointer! = environ.advanced(by: position.offset).pointee
      guard let cString = getenv(key)
        else { fatalError(CError(rawValue: errno)!.description) }
      return String(cString: cString)
    }

  }

  public var startIndex: Index { return Index.start }
  public var endIndex: Index { return Index.end }

  public func index(after i: Index) -> Index {
    return Index(offset: i.offset + 1)
  }

  public func index(before i: Index) -> Index {
    return Index(offset: i.offset - 1)
  }

  public subscript(position: Index) -> (key: String, value: String) {
    return (key: keys[position], value: values[position])
  }

  public subscript(key: String) -> String? {
    get {
      let cString = getenv(key)
      return cString.map({ String(cString: $0) })
    }
    set {
      if newValue != nil {
        guard setenv(key, newValue!, 1) == 0
          else { fatalError(CError(rawValue: errno)!.description) }
      } else {
        guard unsetenv(key) == 0
          else { fatalError(CError(rawValue: errno)!.description) }
      }
    }
  }

  public var keys: Keys { return Keys() }
  public var values: Values { return Values() }

  // MARK: Safe methods

  public func safeSet(value: String, forKey key: String) throws {
    guard setenv(key, value, 1) == 0
      else { throw CError(rawValue: errno)! }
  }

  public func safeUnset(key: String) throws {
    guard unsetenv(key) == 0
      else { throw CError(rawValue: errno)! }
  }

}
