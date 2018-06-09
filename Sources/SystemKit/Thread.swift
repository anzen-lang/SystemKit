#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public class Thread {

  public init(arguments: [Any] = [], _ body: @escaping ([Any]) throws -> Any) throws {
    closure = Closure(arguments: arguments, body: body)

    let closureRef = Unmanaged.passUnretained(closure)
    let status = pthread_create(&self.id, nil, runThread, closureRef.toOpaque())
    guard status == 0
      else { throw CError(rawValue: status)! }
  }

  deinit {
    pthread_detach(id!)
  }

  private var id: pthread_t?
  private let closure: Closure

  public func join() throws -> Any {
    var value: UnsafeMutableRawPointer?
    let status = pthread_join(id!, &value)
    guard status == 0
      else { throw CError(rawValue: status)! }

    let resultRef = Unmanaged<ThreadResult>.fromOpaque(value!)
    defer { resultRef.release() }

    let result = resultRef.takeUnretainedValue()
    switch result.kind {
    case .success(let payload): return payload
    case .failure(let error)  : throw error
    }
  }

  public func cancel() throws {
    let status = pthread_cancel(id!)
    guard status == 0
      else { throw CError(rawValue: status)! }
  }

}

public struct ThinThread {

  public init(
    _ body: @escaping @convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?) throws
  {
    let status = pthread_create(&self.id, nil, body, nil)
    guard status == 0
      else { throw CError(rawValue: status)! }
  }

  public func join() throws -> UnsafeMutableRawPointer? {
    var result: UnsafeMutableRawPointer?
    let status = pthread_join(id!, &result)
    guard status == 0
      else { throw CError(rawValue: status)! }
    return result
  }

  public func cancel() throws {
    let status = pthread_cancel(id!)
    guard status == 0
      else { throw CError(rawValue: status)! }
  }

  private var id: pthread_t?

}

private func runThread(_ a: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
  let closureRef = Unmanaged<Closure>.fromOpaque(a)
  do {
    let closure = closureRef.takeUnretainedValue()
    let result = try closure.body(closure.arguments)
    return Unmanaged.passRetained(ThreadResult(.success(payload: result))).toOpaque()
  } catch {
    return Unmanaged.passRetained(ThreadResult(.failure(error: error))).toOpaque()
  }
}

private class Closure {

  init(arguments: [Any], body: @escaping ([Any]) throws -> Any) {
    self.body = body
    self.arguments = arguments
  }

  let body: ([Any]) throws -> Any
  let arguments: [Any]

}

private class ThreadResult {

  enum Kind {
    case success(payload: Any)
    case failure(error: Error)
  }

  init(_ kind: Kind) {
    self.kind = kind
  }

  let kind: Kind

}

extension System {

  public static func exit(_ thread: Thread, status: Int32) -> Never {
    pthread_exit(Unmanaged.passRetained(ThreadResult(.success(payload: status))).toOpaque())
  }

}
