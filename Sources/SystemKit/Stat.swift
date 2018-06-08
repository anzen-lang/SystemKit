#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

// The following functions redefine the macros in `sys/stat.h` that are provided to test whether a
// file is of the specified type. The value m supplied to the macros is the value of `st_mode` from
// a `stat` structure. The functions evaluate to a non-zero value if the test is true.
func S_ISBLK(_ m: mode_t)  -> Bool { return (((m) & S_IFMT) == S_IFBLK) }
func S_ISCHR(_ m: mode_t)  -> Bool { return (((m) & S_IFMT) == S_IFCHR) }
func S_ISDIR(_ m: mode_t)  -> Bool { return (((m) & S_IFMT) == S_IFDIR) }
func S_ISFIFO(_ m: mode_t) -> Bool { return (((m) & S_IFMT) == S_IFIFO) }
func S_ISREG(_ m: mode_t)  -> Bool { return (((m) & S_IFMT) == S_IFREG) }
func S_ISLNK(_ m: mode_t)  -> Bool { return (((m) & S_IFMT) == S_IFLNK) }
func S_ISSOCK(_ m: mode_t) -> Bool { return (((m) & S_IFMT) == S_IFSOCK) }
