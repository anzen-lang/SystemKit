// See http://www.virtsync.com/c-error-codes-include-errno for an exhaustive list.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public enum CError: Int32, Error, CustomStringConvertible {

  case operationNotPermitted    = 1  // EPERM
  case noSuchFileOrDirectory    = 2  // ENOENT
  case noSuchProcess            = 3  // ESRCH
  case interruptedSystemCall    = 4  // EINTR
  case ioError                  = 5  // EIO
  case noSuchDeviceOrAddress    = 6  // ENXIO
  case tooLongArgumentList      = 7  // E2BIG
  case execFormatError          = 8  // ENOEXEC
  case badFileNumber            = 9  // EBADF
  case noChildProcess           = 10 // ECHILD
  case tryAgain                 = 11 // EAGAIN
  case outOfMemory              = 12 // ENOMEM
  case permissionDenied         = 13 // EACCES
  case badAddress               = 14 // EFAULT
  case blockDeviceRequired      = 15 // ENOTBLK
  case busyDeviceOrResource     = 16 // EBUSY
  case fileExists               = 17 // EEXIST
  case crossDeviceLink          = 18 // EXDEV
  case noSuchDevice             = 19 // ENODEV
  case isNotDirectory           = 20 // ENOTDIR
  case isDirectory              = 21 // EISDIR
  case invalidArgument          = 22 // EINVAL
  case fileTableOverflow        = 23 // ENFILE
  case tooManyOpenFiles         = 24 // EMFILE
  case isNotTypeWritter         = 25 // ENOTTY
  case textFileBusy             = 26 // ETXTBSY
  case tooLargeFile             = 27 // EFBIG
  case noSpaceLeft              = 28 // ENOSPC
  case illegalSeek              = 29 // ESPIPE
  case readOnlyFileSystem       = 30 // EROFS
  case tooManyLinks             = 31 // EMLINK
  case brokenPipe               = 32 // EPIPE
  case mathDomainError          = 33 // EDOM
  case mathNotRepresentable     = 34 // ERANGE
  case resourceDeadlock         = 35 // EDEADLK
  case tooLongFilename          = 36 // ENAMETOOLONG
  case noRecordLocksAvailable   = 37 // ENOLCK
  case functionNotImplemented   = 38 // ENOSYS
  case notEmptyDirectory        = 39 // ENOTEMPTY
  case tooManySymbolicLinks     = 40 // ELOOP
  case tooLargeValue            = 75 // EOVERFLOW

  public var description: String {
    switch self {
    case .operationNotPermitted   : return "operation not permitted (EPERM)"
    case .noSuchFileOrDirectory   : return "no such file or directory (ENOENT)"
    case .noSuchProcess           : return "no such process (ESRCH)"
    case .interruptedSystemCall   : return "interrupted system call (EINTR)"
    case .ioError                 : return "input/output error (EIO)"
    case .noSuchDeviceOrAddress   : return "no such device or address (ENXIO)"
    case .tooLongArgumentList     : return "too long argument list (E2BIG)"
    case .execFormatError         : return "exec format error (ENOEXEC)"
    case .badFileNumber           : return "bad file number (EBADF)"
    case .noChildProcess          : return "no child process (ECHILD)"
    case .tryAgain                : return "try again (EAGAIN)"
    case .outOfMemory             : return "out of memory (ENOMEM)"
    case .permissionDenied        : return "permission denied (EACCES)"
    case .badAddress              : return "bad address (EFAULT)"
    case .blockDeviceRequired     : return "block device required (ENOTBLK)"
    case .busyDeviceOrResource    : return "busy device or resource (EBUSY)"
    case .fileExists              : return "file exists (EEXIST)"
    case .crossDeviceLink         : return "cross-device link (EXDEV)"
    case .noSuchDevice            : return "no such device (ENODEV)"
    case .isNotDirectory          : return "not a directory (ENOTDIR)"
    case .isDirectory             : return "is a directory (EISDIR)"
    case .invalidArgument         : return "invalid argument (EINVAL)"
    case .fileTableOverflow       : return "file table overflow (ENFILE)"
    case .tooManyOpenFiles        : return "too many open files (EMFILE)"
    case .isNotTypeWritter        : return "not a typewriter (ENOTTY)"
    case .textFileBusy            : return "text file busy (ETXTBSY)"
    case .tooLargeFile            : return "too large file (EFBIG)"
    case .noSpaceLeft             : return "no space left on device (ENOSPC)"
    case .illegalSeek             : return "illegal seek (ESPIPE)"
    case .readOnlyFileSystem      : return "read only file system (EROFS)"
    case .tooManyLinks            : return "too many links (EMLINK)"
    case .brokenPipe              : return "broken pipe (ESPIPE)"
    case .mathDomainError         : return "math argument out of domain of func (EDOM)"
    case .mathNotRepresentable    : return "math result not representable (ERANGE)"
    case .resourceDeadlock        : return "resource deadlock (EDEADLCK)"
    case .tooLongFilename         : return "too long filename (ENAMETOOLONG)"
    case .noRecordLocksAvailable  : return "no record locks available (ENOLCK)"
    case .functionNotImplemented  : return "function not implemented (ENOSYS)"
    case .notEmptyDirectory       : return "not empty directory (ENOTEMPTY)"
    case .tooManySymbolicLinks    : return "too many symbolc links (ELOOP)"
    case .tooLargeValue           : return "too large value for defined data type (EOVERFLOW)"
    }
  }

}
