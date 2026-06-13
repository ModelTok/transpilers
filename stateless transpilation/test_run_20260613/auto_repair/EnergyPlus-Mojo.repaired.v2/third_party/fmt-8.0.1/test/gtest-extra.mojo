// Mojo translation of third_party/fmt-8.0.1/test/gtest-extra.cc
// Faithful 1:1 translation, no refactoring.

// Include equivalent: #include "gtest-extra.h"
// The header definitions are incorporated here for completeness.
// Conditional compilation: #if FMT_USE_FCNTL
alias FMT_USE_FCNTL = True

// Import from fmt/os.mojo (assumed to exist)
from fmt.os import file, system_error

// C library externs (equivalent to #include <cstdio>, <cerrno>, etc.)
@extern
def fflush(f: FILE*) -> Int
@extern
def fileno(f: FILE*) -> Int
@extern
def dup2(oldfd: Int, newfd: Int) -> Int
@extern
def pipe(fds: Pointer[Int]) -> Int
@extern
def close(fd: Int) -> Int
@extern
def read(fd: Int, buf: Pointer[UInt8], count: Int) -> Int
@extern
def fputs(s: String, stream: FILE*) -> Int
@extern
var stderr: FILE*
@extern
var errno: Int
alias EOF: Int = -1
alias EINTR: Int = 4

// FILE* type (opaque)
@extern
struct FILE:

// FMT_POSIX macro: assume identity
alias FMT_POSIX = __mlir_op.`pop.identity`  // placeholder; actual usage: FMT_POSIX(c) -> c

// Class output_redirect (from header)
struct output_redirect:
    var file_: FILE*
    var original_: file
    var read_end_: file

    def __init__(self, f: FILE*):
        self.file_ = f
        self.flush()
        let fd: Int = FMT_POSIX(fileno(f))
        self.original_ = file.dup(fd)
        var write_end: file
        file.pipe(self.read_end_, write_end)
        write_end.dup2(fd)

    def __del__(self):
        try:
            self.restore()
        except e:
            fputs(e.what(), stderr)

    def flush(self):
        var result: Int = 0
        while True:
            result = fflush(self.file_)
            if result != EOF or errno != EINTR:
                break
        if result != 0:
            raise system_error(errno, "cannot flush stream")

    def restore(self):
        if self.original_.descriptor() == -1:
            return  // Already restored.
        self.flush()
        self.original_.dup2(FMT_POSIX(fileno(self.file_)))
        self.original_.close()

    def restore_and_read(self) -> String:
        self.restore()
        var content: String = String()
        if self.read_end_.descriptor() == -1:
            return content  // Already read.
        alias BUFFER_SIZE: Int = 4096
        var buffer: Pointer[UInt8] = Pointer[UInt8].alloc(BUFFER_SIZE)
        var count: Int = 0
        while True:
            count = self.read_end_.read(buffer, BUFFER_SIZE)
            content.append(String(buffer, count))
            if count == 0:
                break
        self.read_end_.close()
        return content

// Free function read (declared in header, defined here)
def read(f: file, count: Int) -> String:
    var buffer: String = String(count, '\0')
    var n: Int = 0
    var offset: Int = 0
    while True:
        n = f.read(buffer.data + offset, count - offset)
        offset += n
        if offset >= count or n == 0:
            break
    buffer.resize(offset)
    return buffer

// End of conditional: #endif // FMT_USE_FCNTL