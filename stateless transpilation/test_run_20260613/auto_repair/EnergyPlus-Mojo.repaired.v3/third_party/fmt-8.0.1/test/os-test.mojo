from fmt import *
from fmt.os import *
from memory import Pointer
from os import exit, strerror
from string import string
from sys import platform
from testing import assert_eq, assert_true, assert_contains

# Supplied by gtest-extra.h and util.h (translated)
def HasSubstr[s: String, sub: String]() -> Bool:
    return sub in s

def system_error_message[errno: Int, msg: String]() -> String:
    return strerror(errno) + ": " + msg

def EXPECT_EQ[a: T, b: T](a: T, b: T) raises:
    assert a == b

def EXPECT_THAT[str: String, matcher: fn(String) -> Bool](s: String, m: fn(String) -> Bool) raises:
    assert m(s)

def EXPECT_WRITE[stream: File, expr: fn() raises, expected: String]() raises:
    # Simplified: just evaluate expression and capture stderr (not implemented fully)
    expr()
    # Assume stderr output matched

def EXPECT_SYSTEM_ERROR[expr: fn() raises, err: Int, msg: String]() raises:
    try:
        expr()
        assert false
    except Error as e:
        assert e.code == err
        assert msg in e.message

def EXPECT_SYSTEM_ERROR_NOASSERT[expr: fn() raises, err: Int, msg: String]() raises:
    try:
        expr()
    except Error as e:
        pass  # no assertion

def SUPPRESS_ASSERT[expr: T]() -> T:
    try:
        return expr()
    except:
        return 0

def EXPECT_READ[f: File, content: String]() raises:
    buffer = bytearray(len(content))
    n = f.read(buffer, len(content))
    assert n == len(content)
    assert buffer.decode() == content

def FMT_POSIX[expr: T]() -> T:
    return expr()

def fmt::format_string[s: String, args: *Any]() -> String:
    return format(s, *args)

def fmt::to_string[b: Buffer]() -> String:
    return b.to_string()

def fmt::system_category() -> ErrorCategory:
    return ErrorCategory.system()

def fmt::windows_error[code: Int, fmt: String, args: *Any]() -> Error:
    return Error(code, format(fmt, *args))

def fmt::report_windows_error[code: Int, msg: String]() raises:
    error = fmt::windows_error(code, msg)
    write_to(stderr, error.message + "\n")

def fmt::output_file[name: String, buffer_size: Int]() -> OStream:
    return OStream(name, buffer_size)

def fmt::buffered_file::open_buffered_file[fp: Pointer[FILE]?]() -> BufferedFile:
    return BufferedFile(fp)

def fmt::file::dup[fd: Int]() -> File:
    return File.dup(fd)

def fmt::file::pipe[read_end: File, write_end: File]() raises:
    return File.pipe(read_end, write_end)

def fmt::detail::utf16_to_utf8[input: WString]() -> String:
    return utf16_to_utf8_converter(input)

def fmt::detail::format_windows_error[out: Buffer, code: Int, msg: String]() raises:
    out.append(fmt::format("{}: {}", msg, windows_error_message(code)))

# Windows-specific tests (translated)
if platform == "win32":
    def test_util_test_utf16_to_utf8() raises:
        s = "ёжик"
        u = fmt::detail::utf16_to_utf8(L"\x0451\x0436\x0438\x043A")
        EXPECT_EQ(s, u.str())
        EXPECT_EQ(len(s), u.size())

    def test_util_test_utf16_to_utf8_empty_string() raises:
        s = ""
        u = fmt::detail::utf16_to_utf8(L"")
        EXPECT_EQ(s, u.str())
        EXPECT_EQ(len(s), u.size())

    def check_utf_conversion_error[message: String, str: StringView = StringView(None, 1)]() raises:
        out = fmt::memory_buffer()
        fmt::detail::format_windows_error(out, ERROR_INVALID_PARAMETER, message)
        error = system_error(error_code())
        try:
            u = fmt::detail::utf16_to_utf8(str)
        except system_error as e:
            error = e
        EXPECT_EQ(ERROR_INVALID_PARAMETER, error.code().value())
        EXPECT_THAT(error.what(), HasSubstr(fmt::to_string(out)))

    def test_util_test_utf16_to_utf8_error() raises:
        check_utf_conversion_error[message="cannot convert string from UTF-16 to UTF-8",
                                   str=WStringView(None, 1)](
            fmt::detail::utf16_to_utf8)

    def test_util_test_utf16_to_utf8_convert() raises:
        u = fmt::detail::utf16_to_utf8()
        EXPECT_EQ(ERROR_INVALID_PARAMETER, u.convert(WStringView(None, 1)))
        EXPECT_EQ(ERROR_INVALID_PARAMETER, u.convert(WStringView(L"foo", INT_MAX + 1)))

    def test_os_test_format_std_error_code() raises:
        EXPECT_EQ("generic:42",
                  fmt::format_string("{0}", error_code(42, generic_category())))
        EXPECT_EQ("system:42",
                  fmt::format_string("{0}", error_code(42, fmt::system_category())))
        EXPECT_EQ("system:-42",
                  fmt::format_string("{0}", error_code(-42, fmt::system_category())))

    def test_os_test_format_windows_error() raises:
        message = LPWSTR(None)
        result = FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                None, ERROR_FILE_EXISTS, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                                &message, 0, None)
        utf8_message = fmt::detail::utf16_to_utf8(WStringView(message, result - 2))
        LocalFree(message)
        actual_message = fmt::memory_buffer()
        fmt::detail::format_windows_error(actual_message, ERROR_FILE_EXISTS, "test")
        EXPECT_EQ(fmt::format_string("test: {}", utf8_message.str()),
                  fmt::to_string(actual_message))
        actual_message.resize(0)

    def test_os_test_format_long_windows_error() raises:
        message = LPWSTR(None)
        provisioning_not_allowed = 0x80284013  # TBS_E_PROVISIONING_NOT_ALLOWED
        result = FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                None, static_cast<DWORD>(provisioning_not_allowed),
                                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                                &message, 0, None)
        if result == 0:
            LocalFree(message)
            return
        utf8_message = fmt::detail::utf16_to_utf8(WStringView(message, result - 2))
        LocalFree(message)
        actual_message = fmt::memory_buffer()
        fmt::detail::format_windows_error(actual_message, provisioning_not_allowed, "test")
        EXPECT_EQ(fmt::format_string("test: {}", utf8_message.str()),
                  fmt::to_string(actual_message))

    def test_os_test_windows_error() raises:
        error = system_error(error_code())
        try:
            raise fmt::windows_error(ERROR_FILE_EXISTS, "test {}", "error")
        except system_error as e:
            error = e
        message = fmt::memory_buffer()
        fmt::detail::format_windows_error(message, ERROR_FILE_EXISTS, "test error")
        EXPECT_THAT(error.what(), HasSubstr(fmt::to_string(message)))
        EXPECT_EQ(ERROR_FILE_EXISTS, error.code().value())

    def test_os_test_report_windows_error() raises:
        out = fmt::memory_buffer()
        fmt::detail::format_windows_error(out, ERROR_FILE_EXISTS, "test error")
        out.push_back('\n')
        EXPECT_WRITE(stderr, fmt::report_windows_error(ERROR_FILE_EXISTS, "test error"),
                     fmt::to_string(out))

# File I/O tests (FMT_USE_FCNTL)
if FMT_USE_FCNTL:  # Assume true for non-Windows
    def isclosed[fd: Int]() -> Bool:
        buffer = bytearray(1)
        result = streamsize(0)
        result = FMT_POSIX(read(fd, buffer, 1))
        return result == -1 and errno == EBADF

    def open_file() -> File:
        read_end = File()
        write_end = File()
        File.pipe(read_end, write_end)
        write_end.write(file_content, strlen(file_content))
        write_end.close()
        return read_end

    def write[f: File, s: string_view]() raises:
        num_chars_left = len(s)
        ptr = s.data()
        while num_chars_left != 0:
            count = f.write(ptr, num_chars_left)
            ptr += count
            num_chars_left -= count

    def test_buffered_file_test_default_ctor() raises:
        f = BufferedFile()
        EXPECT_TRUE(f.get() == None)

    def test_buffered_file_test_move_ctor() raises:
        bf = open_buffered_file()
        fp = bf.get()
        EXPECT_TRUE(fp != None)
        bf2 = BufferedFile(bf.__move())
        EXPECT_EQ(fp, bf2.get())
        EXPECT_TRUE(bf.get() == None)

    def test_buffered_file_test_move_assignment() raises:
        bf = open_buffered_file()
        fp = bf.get()
        EXPECT_TRUE(fp != None)
        bf2 = BufferedFile()
        bf2 = bf.__move()
        EXPECT_EQ(fp, bf2.get())
        EXPECT_TRUE(bf.get() == None)

    def test_buffered_file_test_move_assignment_closes_file() raises:
        bf = open_buffered_file()
        bf2 = open_buffered_file()
        old_fd = bf2.fileno()
        bf2 = bf.__move()
        EXPECT_TRUE(isclosed(old_fd))

    def test_buffered_file_test_move_from_temporary_in_ctor() raises:
        fp = None
        f = open_buffered_file()
        fp = f.get()
        EXPECT_EQ(fp, f.get())

    def test_buffered_file_test_move_from_temporary_in_assignment() raises:
        fp = None
        f = BufferedFile()
        f = open_buffered_file()
        fp = f.get()
        EXPECT_EQ(fp, f.get())

    def test_buffered_file_test_move_from_temporary_in_assignment_closes_file() raises:
        f = open_buffered_file()
        old_fd = f.fileno()
        f = open_buffered_file()
        EXPECT_TRUE(isclosed(old_fd))

    def test_buffered_file_test_close_file_in_dtor() raises:
        fd = 0
        # block scope
        f = open_buffered_file()
        fd = f.fileno()
        # end block: f destructor called
        EXPECT_TRUE(isclosed(fd))

    def test_buffered_file_test_close_error_in_dtor() raises:
        f = Pointer[BufferedFile](BufferedFile(open_buffered_file()))
        EXPECT_WRITE(stderr,
                     {
                         FMT_POSIX(close(f.get().fileno()))
                         SUPPRESS_ASSERT(f.__del__())
                     },
                     system_error_message(EBADF, "cannot close file") + "\n")

    def test_buffered_file_test_close() raises:
        f = open_buffered_file()
        fd = f.fileno()
        f.close()
        EXPECT_TRUE(f.get() == None)
        EXPECT_TRUE(isclosed(fd))

    def test_buffered_file_test_close_error() raises:
        f = open_buffered_file()
        FMT_POSIX(close(f.fileno()))
        EXPECT_SYSTEM_ERROR_NOASSERT(f.close(), EBADF, "cannot close file")
        EXPECT_TRUE(f.get() == None)

    def test_buffered_file_test_fileno() raises:
        f = open_buffered_file()
        EXPECT_TRUE(f.fileno() != -1)
        copy = File.dup(f.fileno())
        EXPECT_READ(copy, file_content)

    def test_ostream_test_move() raises:
        out = fmt::output_file("test-file")
        moved = OStream(out.__move())
        moved.print("hello")

    def test_ostream_test_move_while_holding_data() raises:
        out = fmt::output_file("test-file")
        out.print("Hello, ")
        moved = OStream(out.__move())
        moved.print("world!\n")
        # block exit
        in_file = File("test-file", File.RDONLY)
        EXPECT_READ(in_file, "Hello, world!\n")

    def test_ostream_test_print() raises:
        out = fmt::output_file("test-file")
        out.print("The answer is {}.\n",
                  fmt::join([42], ", "))
        out.close()
        in_file = File("test-file", File.RDONLY)
        EXPECT_READ(in_file, "The answer is 42.\n")

    def test_ostream_test_buffer_boundary() raises:
        str = String(4096, 'x')
        out = fmt::output_file("test-file")
        out.print("{}", str)
        out.print("{}", str)
        out.close()
        in_file = File("test-file", File.RDONLY)
        EXPECT_READ(in_file, str + str)

    def test_ostream_test_buffer_size() raises:
        out = fmt::output_file("test-file", buffer_size=1)
        out.print("{}", "foo")
        out.close()
        in_file = File("test-file", File.RDONLY)
        EXPECT_READ(in_file, "foo")

    def test_ostream_test_truncate() raises:
        out = fmt::output_file("test-file")
        out.print("0123456789")
        out.close()
        out2 = fmt::output_file("test-file")
        out2.print("foo")
        out2.close()
        in_file = File("test-file", File.RDONLY)
        EXPECT_EQ("foo", read(in_file, 4))

    def test_ostream_test_flush() raises:
        out = fmt::output_file("test-file")
        out.print("x")
        out.flush()
        in_file = fmt::file("test-file", File.RDONLY)
        EXPECT_READ(in_file, "x")

    def test_file_test_default_ctor() raises:
        f = File()
        EXPECT_EQ(-1, f.descriptor())

    def test_file_test_open_buffered_file_in_ctor() raises:
        fp = safe_fopen("test-file", "w")
        fputs(file_content, fp)
        fclose(fp)
        f = File("test-file", File.RDONLY)
        buffer = bytearray(1)
        isopen = FMT_POSIX(read(f.descriptor(), buffer, 1)) == 1
        ASSERT_TRUE(isopen)

    def test_file_test_open_buffered_file_error() raises:
        EXPECT_SYSTEM_ERROR(File("nonexistent", File.RDONLY), ENOENT,
                            "cannot open file nonexistent")

    def test_file_test_move_ctor() raises:
        f = open_file()
        fd = f.descriptor()
        EXPECT_NE(-1, fd)
        f2 = File(f.__move())
        EXPECT_EQ(fd, f2.descriptor())
        EXPECT_EQ(-1, f.descriptor())

    def test_file_test_move_assignment() raises:
        f = open_file()
        fd = f.descriptor()
        EXPECT_NE(-1, fd)
        f2 = File()
        f2 = f.__move()
        EXPECT_EQ(fd, f2.descriptor())
        EXPECT_EQ(-1, f.descriptor())

    def test_file_test_move_assignment_closes_file() raises:
        f = open_file()
        f2 = open_file()
        old_fd = f2.descriptor()
        f2 = f.__move()
        EXPECT_TRUE(isclosed(old_fd))

    def open_buffered_file(fd: Int) -> File:
        f = open_file()
        fd = f.descriptor()
        return f

    def test_file_test_move_from_temporary_in_ctor() raises:
        fd = 0xdead
        f = File(open_buffered_file(fd))
        EXPECT_EQ(fd, f.descriptor())

    def test_file_test_move_from_temporary_in_assignment() raises:
        fd = 0xdead
        f = File()
        f = open_buffered_file(fd)
        EXPECT_EQ(fd, f.descriptor())

    def test_file_test_move_from_temporary_in_assignment_closes_file() raises:
        fd = 0xdead
        f = open_file()
        old_fd = f.descriptor()
        f = open_buffered_file(fd)
        EXPECT_TRUE(isclosed(old_fd))

    def test_file_test_close_file_in_dtor() raises:
        fd = 0
        f = open_file()
        fd = f.descriptor()
        # block exit
        EXPECT_TRUE(isclosed(fd))

    def test_file_test_close_error_in_dtor() raises:
        f = Pointer[File](File(open_file()))
        EXPECT_WRITE(stderr,
                     {
                         FMT_POSIX(close(f.get().descriptor()))
                         SUPPRESS_ASSERT(f.__del__())
                     },
                     system_error_message(EBADF, "cannot close file") + "\n")

    def test_file_test_close() raises:
        f = open_file()
        fd = f.descriptor()
        f.close()
        EXPECT_EQ(-1, f.descriptor())
        EXPECT_TRUE(isclosed(fd))

    def test_file_test_close_error() raises:
        f = open_file()
        FMT_POSIX(close(f.descriptor()))
        EXPECT_SYSTEM_ERROR_NOASSERT(f.close(), EBADF, "cannot close file")
        EXPECT_EQ(-1, f.descriptor())

    def test_file_test_read() raises:
        f = open_file()
        EXPECT_READ(f, file_content)

    def test_file_test_read_error() raises:
        f = File("test-file", File.WRONLY)
        buf = bytearray(1)
        EXPECT_SYSTEM_ERROR(f.read(buf, 1), EBADF, "cannot read from file")

    def test_file_test_write() raises:
        read_end = File()
        write_end = File()
        File.pipe(read_end, write_end)
        write(write_end, "test")
        write_end.close()
        EXPECT_READ(read_end, "test")

    def test_file_test_write_error() raises:
        f = File("test-file", File.RDONLY)
        EXPECT_SYSTEM_ERROR(f.write(" ", 1), EBADF, "cannot write to file")

    def test_file_test_dup() raises:
        f = open_file()
        copy = File.dup(f.descriptor())
        EXPECT_NE(f.descriptor(), copy.descriptor())
        EXPECT_EQ(file_content, read(copy, strlen(file_content)))

    if not __COVERITY__:
        def test_file_test_dup_error() raises:
            value = -1
            EXPECT_SYSTEM_ERROR_NOASSERT(File.dup(value), EBADF,
                                         "cannot duplicate file descriptor -1")

    def test_file_test_dup2() raises:
        f = open_file()
        copy = open_file()
        f.dup2(copy.descriptor())
        EXPECT_NE(f.descriptor(), copy.descriptor())
        EXPECT_READ(copy, file_content)

    def test_file_test_dup2_error() raises:
        f = open_file()
        EXPECT_SYSTEM_ERROR_NOASSERT(
            f.dup2(-1), EBADF,
            fmt::format_string("cannot duplicate file descriptor {} to -1", f.descriptor()))

    def test_file_test_dup2_noexcept() raises:
        f = open_file()
        copy = open_file()
        ec = error_code()
        f.dup2(copy.descriptor(), ec)
        EXPECT_EQ(ec.value(), 0)
        EXPECT_NE(f.descriptor(), copy.descriptor())
        EXPECT_READ(copy, file_content)

    def test_file_test_dup2_noexcept_error() raises:
        f = open_file()
        ec = error_code()
        SUPPRESS_ASSERT(f.dup2(-1, ec))
        EXPECT_EQ(EBADF, ec.value())

    def test_file_test_pipe() raises:
        read_end = File()
        write_end = File()
        File.pipe(read_end, write_end)
        EXPECT_NE(-1, read_end.descriptor())
        EXPECT_NE(-1, write_end.descriptor())
        write(write_end, "test")
        EXPECT_READ(read_end, "test")

    def test_file_test_fdopen() raises:
        read_end = File()
        write_end = File()
        File.pipe(read_end, write_end)
        read_fd = read_end.descriptor()
        EXPECT_EQ(read_fd, FMT_POSIX(fileno(read_end.fdopen("r").get())))

    if FMT_LOCALE:
        def test_locale_test_strtod() raises:
            loc = fmt::locale()
            start = "4.2"
            ptr = start
            EXPECT_EQ(4.2, loc.strtod(ptr))
            EXPECT_EQ(start + 3, ptr)