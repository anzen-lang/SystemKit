#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public struct System {

  /// A mapping representing the string environment.
  public static var environment = Environment()

  /// The standard output.
  public static let out = Console(ostream: stdout)
  /// The standard error.
  public static let err = Console(ostream: stderr)

  public static func exit(status: Int32) -> Never {
    #if os(Linux)
    Glibc.exit(status)
    #else
    Darwin.exit(status)
    #endif
  }

}
