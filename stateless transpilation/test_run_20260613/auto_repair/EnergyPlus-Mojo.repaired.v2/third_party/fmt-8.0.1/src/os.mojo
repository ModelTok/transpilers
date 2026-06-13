# Mojo translation of third_party/fmt-8.0.1/src/os.cc
# Faithful 1:1 translation, no refactoring.

from os import (
    FMT_USE_FCNTL,
    FMT_THROW,
    FMT_SYSTEM,
    FMT_POSIX_CALL,
    FMT_RETRY,
    FMT_RETRY_VAL,
    FMT_TRY,
    FMT_CATCH,
    FMT_NOEXCEPT,
    FMT_BEGIN_NAMESPACE,
    FMT_END_NAMESPACE,
    string_view,
    cstring_view,
    basic_string_view,
    wchar_t,
    format_args,
    vformat,
    format_to,
    buffer_appender,
    format_error_code,
    report_error,
    detail,
    utf16_to_utf8,
    utf8_system_category,
    system_category,
    vwindows_error,
    format_windows_error,
    report_windows_error,
    buffered_file,
    file,
    ostream,
    getpagesize,
    system_error,
    windows_error,
    error_code,
    error_category,
    system_error,
    errno,
    INT_MAX,
    UINT_MAX,
    CHAR_BIT,
    ERROR_INVALID_PARAMETER,
    ERROR_SUCCESS,
    GetLastError,
    WideCharToMultiByte,
    CP_UTF8,
    FormatMessageW,
    FORMAT_MESSAGE_ALLOCATE_BUFFER,
    FORMAT_MESSAGE_FROM_SYSTEM,
    FORMAT_MESSAGE_IGNORE_INSERTS,
    MAKELANGID,
    LANG_NEUTRAL,
    SUBLANG_DEFAULT,
    LocalFree,
    GetFileSize,
    INVALID_FILE_SIZE,
    NO_ERROR,
    GetSystemInfo,
    SYSTEM_INFO,
    _get_osfhandle,
    sopen_s,
    _SH_DENYNO,
    _O_BINARY,
    pipe,
    dup,
    dup2,
    fstat,
    stat,
    sysconf,
    _SC_PAGESIZE,
    fclose,
    fopen,
    fileno,
    fdopen,
    read,
    write,
    close,
    open,
    S_IRUSR,
    S_IWUSR,
    O_CREAT,
    O_TRUNC,
    _O_CREAT,
    _O_TRUNC,
    _S_IREAD,
    _S_IWRITE,
    _POSIX_,
    __MINGW32__,
    _MSC_VER,
    _CRT_SECURE_NO_WARNINGS,
    WIN32_LEAN_AND_MEAN,
    _WIN32,
    windows_h,
    io_h,
    unistd_h,
    sys_stat_h,
    sys_types_h,
    climits_h,
)

# Anonymous namespace equivalent
@parameter
if _WIN32:
    alias rwresult = Int
    def convert_rwcount(count: UInt) -> UInt:
        return count if count <= UINT_MAX else UINT_MAX
elif FMT_USE_FCNTL:
    alias rwresult = Int  # ssize_t equivalent
    def convert_rwcount(count: UInt) -> UInt:
        return count

FMT_BEGIN_NAMESPACE

@parameter
if _WIN32:
    struct utf16_to_utf8:
        var buffer_: List[UInt8]

        def __init__(inout self, s: basic_string_view[wchar_t]):
            if var error_code = self.convert(s):
                FMT_THROW(windows_error(error_code, "cannot convert string from UTF-16 to UTF-8"))

        def convert(inout self, s: basic_string_view[wchar_t]) -> Int:
            if s.size() > INT_MAX:
                return ERROR_INVALID_PARAMETER
            var s_size: Int = s.size()
            if s_size == 0:
                self.buffer_.resize(1)
                self.buffer_[0] = 0
                return 0
            var length: Int = WideCharToMultiByte(CP_UTF8, 0, s.data(), s_size, None, 0, None, None)
            if length == 0:
                return GetLastError()
            self.buffer_.resize(length + 1)
            length = WideCharToMultiByte(CP_UTF8, 0, s.data(), s_size, self.buffer_.data, length, None, None)
            if length == 0:
                return GetLastError()
            self.buffer_[length] = 0
            return 0

    @parameter
    if True:
        struct system_message:
            var result_: UInt
            var message_: wchar_t*

            def __init__(inout self, error_code: UInt):
                self.result_ = 0
                self.message_ = None
                self.result_ = FormatMessageW(
                    FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    None, error_code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    self.message_.as_ptr(), 0, None)
                if self.result_ != 0:
                    while self.result_ != 0 and self.is_whitespace(self.message_[self.result_ - 1]):
                        self.result_ -= 1

            def __del__(owned self):
                LocalFree(self.message_)

            def __bool__(self) -> Bool:
                return self.result_ != 0

            def __as_basic_string_view_wchar_t(self) -> basic_string_view[wchar_t]:
                return basic_string_view[wchar_t](self.message_, self.result_)

            @staticmethod
            def is_whitespace(c: wchar_t) -> Bool:
                return c == ' ' or c == '\n' or c == '\r' or c == '\t' or c == '\0'

        struct utf8_system_category:
            def name(self) -> String:
                return "system"

            def message(self, error_code: Int) -> String:
                var msg = system_message(error_code)
                if msg:
                    var utf8_message = utf16_to_utf8()
                    if utf8_message.convert(msg.__as_basic_string_view_wchar_t()) == ERROR_SUCCESS:
                        return utf8_message.str()
                return "unknown error"

    def system_category() -> error_category:
        var category = utf8_system_category()
        return category

    def vwindows_error(err_code: Int, format_str: string_view, args: format_args) -> system_error:
        var ec = error_code(err_code, system_category())
        return system_error(ec, vformat(format_str, args))

    def format_windows_error(inout out: detail.buffer[UInt8], error_code: Int, message: String):
        FMT_TRY:
            var msg = system_message(error_code)
            if msg:
                var utf8_message = utf16_to_utf8()
                if utf8_message.convert(msg.__as_basic_string_view_wchar_t()) == ERROR_SUCCESS:
                    format_to(buffer_appender[UInt8](out), "{}: {}", message, utf8_message.str())
                    return
        FMT_CATCH(...):

        format_error_code(out, error_code, message)

    def report_windows_error(error_code: Int, message: String):
        report_error(format_windows_error, error_code, message)

# End _WIN32

struct buffered_file:
    var file_: FILE*

    def __del__(owned self):
        if self.file_ and FMT_SYSTEM(fclose(self.file_)) != 0:
            report_system_error(errno, "cannot close file")

    def __init__(inout self, filename: cstring_view, mode: cstring_view):
        FMT_RETRY_VAL(self.file_, FMT_SYSTEM(fopen(filename.c_str(), mode.c_str())), None)
        if not self.file_:
            FMT_THROW(system_error(errno, "cannot open file {}", filename.c_str()))

    def close(inout self):
        if not self.file_:
            return
        var result = FMT_SYSTEM(fclose(self.file_))
        self.file_ = None
        if result != 0:
            FMT_THROW(system_error(errno, "cannot close file"))

    def fileno(self) -> Int:
        var fd = FMT_POSIX_CALL(fileno(self.file_))
        if fd == -1:
            FMT_THROW(system_error(errno, "cannot get file descriptor"))
        return fd

@parameter
if FMT_USE_FCNTL:
    struct file:
        var fd_: Int

        def __init__(inout self, path: cstring_view, oflag: Int):
            var mode = S_IRUSR | S_IWUSR
            @parameter
            if _WIN32 and not __MINGW32__:
                self.fd_ = -1
                FMT_POSIX_CALL(sopen_s(self.fd_.ptr, path.c_str(), oflag, _SH_DENYNO, mode))
            else:
                FMT_RETRY(self.fd_, FMT_POSIX_CALL(open(path.c_str(), oflag, mode)))
            if self.fd_ == -1:
                FMT_THROW(system_error(errno, "cannot open file {}", path.c_str()))

        def __del__(owned self):
            if self.fd_ != -1 and FMT_POSIX_CALL(close(self.fd_)) != 0:
                report_system_error(errno, "cannot close file")

        def close(inout self):
            if self.fd_ == -1:
                return
            var result = FMT_POSIX_CALL(close(self.fd_))
            self.fd_ = -1
            if result != 0:
                FMT_THROW(system_error(errno, "cannot close file"))

        def size(self) -> Int64:
            @parameter
            if _WIN32:
                var size_upper: UInt32 = 0
                var handle = _get_osfhandle(self.fd_)
                var size_lower = FMT_SYSTEM(GetFileSize(handle, size_upper.ptr))
                if size_lower == INVALID_FILE_SIZE:
                    var error = GetLastError()
                    if error != NO_ERROR:
                        FMT_THROW(windows_error(GetLastError(), "cannot get file size"))
                var long_size: UInt64 = size_upper
                return (long_size << (sizeof(UInt32) * CHAR_BIT)) | size_lower
            else:
                var file_stat = stat()
                if FMT_POSIX_CALL(fstat(self.fd_, file_stat.ptr)) == -1:
                    FMT_THROW(system_error(errno, "cannot get file attributes"))
                return file_stat.st_size

        def read(inout self, buffer: Pointer[UInt8], count: UInt) -> UInt:
            var result: rwresult = 0
            FMT_RETRY(result, FMT_POSIX_CALL(read(self.fd_, buffer, convert_rwcount(count))))
            if result < 0:
                FMT_THROW(system_error(errno, "cannot read from file"))
            return detail.to_unsigned(result)

        def write(inout self, buffer: Pointer[UInt8], count: UInt) -> UInt:
            var result: rwresult = 0
            FMT_RETRY(result, FMT_POSIX_CALL(write(self.fd_, buffer, convert_rwcount(count))))
            if result < 0:
                FMT_THROW(system_error(errno, "cannot write to file"))
            return detail.to_unsigned(result)

        @staticmethod
        def dup(fd: Int) -> file:
            var new_fd = FMT_POSIX_CALL(dup(fd))
            if new_fd == -1:
                FMT_THROW(system_error(errno, "cannot duplicate file descriptor {}", fd))
            return file(new_fd)

        def dup2(inout self, fd: Int):
            var result = 0
            FMT_RETRY(result, FMT_POSIX_CALL(dup2(self.fd_, fd)))
            if result == -1:
                FMT_THROW(system_error(errno, "cannot duplicate file descriptor {} to {}", self.fd_, fd))

        def dup2(inout self, fd: Int, inout ec: error_code):
            var result = 0
            FMT_RETRY(result, FMT_POSIX_CALL(dup2(self.fd_, fd)))
            if result == -1:
                ec = error_code(errno, std.generic_category())

        @staticmethod
        def pipe(inout read_end: file, inout write_end: file):
            read_end.close()
            write_end.close()
            var fds: StaticArray[Int, 2] = StaticArray[Int, 2](0, 0)
            @parameter
            if _WIN32:
                enum DEFAULT_CAPACITY = 65536
                var result = FMT_POSIX_CALL(pipe(fds.data, DEFAULT_CAPACITY, _O_BINARY))
            else:
                var result = FMT_POSIX_CALL(pipe(fds.data))
            if result != 0:
                FMT_THROW(system_error(errno, "cannot create pipe"))
            read_end = file(fds[0])
            write_end = file(fds[1])

        def fdopen(inout self, mode: String) -> buffered_file:
            @parameter
            if __MINGW32__ and _POSIX_:
                var f = ::fdopen(self.fd_, mode)
            else:
                var f = FMT_POSIX_CALL(fdopen(self.fd_, mode))
            if not f:
                FMT_THROW(system_error(errno, "cannot associate stream with file descriptor"))
            var bf = buffered_file(f)
            self.fd_ = -1
            return bf

    def getpagesize() -> Int:
        @parameter
        if _WIN32:
            var si: SYSTEM_INFO
            GetSystemInfo(si.ptr)
            return si.dwPageSize
        else:
            var size = FMT_POSIX_CALL(sysconf(_SC_PAGESIZE))
            if size < 0:
                FMT_THROW(system_error(errno, "cannot get memory page size"))
            return size

    struct ostream:
        def grow(inout self, size: UInt):
            if self.size() == self.capacity():
                self.flush()

# End FMT_USE_FCNTL

FMT_END_NAMESPACE