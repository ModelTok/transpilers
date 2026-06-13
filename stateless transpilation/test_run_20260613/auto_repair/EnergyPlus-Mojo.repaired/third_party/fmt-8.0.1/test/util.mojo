# Mojo translation of util.cc with util.h # Note: Mojo does not have preprocessor; constants are used for compile-time switches.
# For cross-module calls, we import from the corresponding .mojo files.
# Assumes fmt/os.mojo provides the necessary types.

from fmt.os import buffered_file, file
from sys import vararg, cstr, memcpy
from locale import locale as _locale, LC_ALL, Error as locale_error
from string import String
from memory import memcpy

# Conditional compilation constants (simulate preprocessor)
let FMT_USE_FCNTL: Bool = True   # assuming on non-Windows
let FMT_MODULE_TEST: Bool = False
let _MSC_VER: Bool = False

# Define vsnprintf equivalent (since Mojo doesn't have C variadic, use Python's format)
# We keep the template function as a generic function with SIZE parameter.
# Note: The original C++ uses va_list and vsnprintf. We approximate with String.format.
def safe_sprintf[SIZE: Int](mut buffer: Array[Int8, SIZE], format: CString, *args: ...):
    var result = String.format(format, *args)
    let len = result.length
    # Copy to buffer (truncate if needed)
    for i in range(min(len, SIZE-1)):
        buffer[i] = result[i].ord()
    buffer[min(len, SIZE-1)] = 0  # null-terminate

# External constant (from util.h)
let file_content: CString = "Don't panic!"

# open_buffered_file implementation
def open_buffered_file(fp: Pointer[Pointer[FILE]]? = None) -> buffered_file:
    if FMT_USE_FCNTL:
        var read_end: file
        var write_end: file
        file.pipe(read_end, write_end)
        write_end.write(file_content, std.strlen(file_content))
        write_end.close()
        var f: buffered_file = read_end.fdopen("r")
        if fp:
            fp.store(f.get())
        return f
    else:
        var f: buffered_file = buffered_file("test-file", "w")
        fputs(file_content, f.get())
        if fp:
            fp.store(f.get())
        return f

# do_get_locale internal helper
def do_get_locale(name: CString) -> _locale:
    try:
        return _locale(name)
    except locale_error:

    return _locale.classic()

# get_locale
def get_locale(name: CString, alt_name: CString? = None) -> _locale:
    var loc = do_get_locale(name)
    if loc == _locale.classic() and alt_name:
        loc = do_get_locale(alt_name)
    if loc == _locale.classic():
        fmt.print(stderr, "{} locale is missing.\n", name)
    return loc

# Template class basic_test_string (generic over Char type)
struct basic_test_string[Char: AnyType]:
    var value_: String[Char]  # would need a proper Char string type; approximate with String
    alias empty: String[Char] = String[Char]()
    
    def __init__(self, value: String[Char]? = None):
        if value:
            self.value_ = value
        else:
            self.value_ = basic_test_string.empty
    
    def value(self) -> String[Char]:
        return self.value_

# Typedefs
alias test_string = basic_test_string[Char8]
alias test_wstring = basic_test_string[Char16]

# operator<< for output
def operator<<[Char: AnyType](os: OStream, s: basic_test_string[Char]) -> OStream:
    os << s.value()
    return os

# Date struct
struct date:
    var year_: Int
    var month_: Int
    var day_: Int
    
    def __init__(self, year: Int, month: Int, day: Int):
        self.year_ = year
        self.month_ = month
        self.day_ = day
    
    def year(self) -> Int: return self.year_
    def month(self) -> Int: return self.month_
    def day(self) -> Int: return self.day_

# safe_fopen (from header)
def safe_fopen(filename: CString, mode: CString) -> Pointer[FILE]:
    if _MSC_VER and not defined(__MINGW32__):
        var f: Pointer[FILE] = None
        errno = fopen_s(addr f, filename, mode)
        return f
    else:
        return std.fopen(filename, mode)

# Note: The original header also includes safe_sprintf defined above,
# and the rest is defined here. All names are preserved exactly.
# The file content (util.mojo) now contains both header and body.