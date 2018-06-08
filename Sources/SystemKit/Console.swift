#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

precedencegroup StreamPrecedence {
  associativity: left
  lowerThan: TernaryPrecedence
}

infix operator <~: StreamPrecedence

public struct Console: TextOutputStream {

  public init(ostream: UnsafeMutablePointer<FILE>) {
    self.ostream = ostream
  }

  private let ostream: UnsafeMutablePointer<FILE>

  public func write(_ string: String) {
    fputs("\(string)", self.ostream)
  }

  public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let string = items.map({ "\($0)" }).joined(separator: separator)
    self.write(string + terminator)
  }

  public static func <~ (console: Console, item: Any) -> Console {
    console.write(String(describing: item))
    return console
  }

}
