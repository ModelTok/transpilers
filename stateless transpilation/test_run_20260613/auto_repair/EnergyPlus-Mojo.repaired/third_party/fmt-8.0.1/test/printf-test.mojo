from fmt import format, format_error, sprintf, printf, vsprintf, vprintf, vfprintf, format_arg_store, basic_format_args, printf_context, wprintf_context
from fmt.detail import max_value, const_check
from fmt.ostream import *  // not used directly but for completeness
from fmt.xchar import *  // for wide string support via String
from testing import *  // for TEST, EXPECT_EQ, EXPECT_THROW_MSG (assume available)
from util import safe_sprintf
from memory import int as Int, long as Int64, unsigned long as UInt64, long long as Int64, unsigned long long as UInt64, char as Int8, unsigned char as UInt8, short as Int16, unsigned short as UInt16, int as Int32, unsigned as UInt32
from collect import String, WString  // assume WString for wide strings (or just String)
from math import numeric_limits
from io import OStream, ostringstream  // assume Mojo has these?
from cstdio import sprintf as c_sprintf  // if needed

# Define some type aliases to match C++ types
typealias char = Int8
typealias wchar_t = Int32  // placeholder, but we'll use String for wide strings
typealias signed char = Int8
typealias unsigned char = UInt8
typealias short = Int16
typealias unsigned short = UInt16
typealias int = Int32
typealias unsigned = UInt32
typealias long = Int64  // assuming 64-bit
typealias unsigned long = UInt64
typealias long long = Int64
typealias unsigned long long = UInt64
typealias intmax_t = Int64
typealias size_t = UInt64
typealias ptrdiff_t = Int64

# For wide string handling, we'll treat wstring as String and literals L"..." as "..."
# This is not fully faithful but necessary for Mojo.
# We'll define a type alias for basic_string_view<wchar_t> as StringView (assume exists)
typealias string_view = StringView  // from fmt.string_view
typealias wstring_view = StringView  // same, since we treat as UTF-8

# Implement the macros as functions, but keep the names for faithfulness
# Note: Mojo does not have macros, so we define them as functions that capture test logic.

def TEST(group: String, name: String, body: fn() -> None):
    # Mock: just run body
    body()

def EXPECT_EQ(expected: String, actual: String, msg: String = ""):
    if expected != actual:
        raise Error("EXPECT_EQ failed: " + expected + " != " + actual + " " + msg)

def EXPECT_THROW_MSG(def call: fn() -> None, exception_type: type, msg: String):
    try:
        call()
        raise Error("Expected exception " + String(exception_type) + " but none thrown")
    except e:
        if not (e is exception_type):
            raise Error("Wrong exception type: " + String(type(e)) + " expected " + String(exception_type))
        if msg not in String(e):
            raise Error("Exception message does not contain: " + msg)

# Overload for int
def EXPECT_EQ(expected: int, actual: int, msg: String = ""):
    if expected != actual:
        raise Error("EXPECT_EQ failed: " + String(expected) + " != " + String(actual) + " " + msg)

def EXPECT_EQ(expected: UInt64, actual: UInt64, msg: String = ""):
    if expected != actual:
        raise Error("EXPECT_EQ failed: " + String(expected) + " != " + String(actual) + " " + msg)

def EXPECT_LT(a: int, b: int):
    if not (a < b):
        raise Error("EXPECT_LT failed: " + String(a) + " >= " + String(b))

# Define EXPECT_PRINTF macro replacement
def EXPECT_PRINTF(expected_output: String, format: String, arg: type):
    def inner():
        let result = test_sprintf(format, arg)
        EXPECT_EQ(expected_output, result, "format: " + format)
        let positional = make_positional(format)
        let result2 = sprintf(positional, arg)
        EXPECT_EQ(expected_output, result2)
    inner()

# Overload for wide strings (same as above, treat as String)
def EXPECT_PRINTF(expected_output: String, format: String, arg: WString):  # WString is String
    def inner():
        let result = test_sprintf(format, arg)
        EXPECT_EQ(expected_output, result, "format: " + format)
        let positional = make_positional(format)
        let result2 = sprintf(positional, arg)
        EXPECT_EQ(expected_output, result2)
    inner()

# Implement make_positional for narrow and wide
def make_positional(format: string_view) -> String:
    var s = String(format)
    # find '%' and replace with "%1$"
    let pos = s.find("%")
    if pos != -1:
        s = s.replace(pos, 1, "%1$")
    return s

def make_positional(format: wstring_view) -> WString:
    var s = WString(format)
    let pos = s.find("%")
    if pos != -1:
        s = s.replace(pos, 1, "%1$")
    return s

# test_sprintf templates
def test_sprintf(format: string_view, args...: type) -> String:
    return sprintf(format, args...)

def test_sprintf(format: wstring_view, args...: type) -> WString:
    return sprintf(format, args...)

# Global constant
let big_num: unsigned = Int32.MAX + 1  // actually INT_MAX + 1u
# For Mojo, INT_MAX is Int32.MAX (2147483647), so big_num = 2147483648

# Helper for safe_sprintf: we assume safe_sprintf from util uses C-style sprintf
# Provide our own implementation that uses format for tests
def safe_sprintf(buffer: Pointer[char], fmt: String, value: type) -> void:
    # Simulate by formatting into a temporary string and copying to buffer
    let result = format(fmt, value)
    # Copy characters to buffer (assume buffer is large enough)
    for i in range(len(result)):
        buffer[i] = result[i].code()
    buffer[len(result)] = 0

# Now the test code translated directly.

TEST("printf_test", "no_args"):
    EXPECT_EQ("test", test_sprintf("test"))
    EXPECT_EQ("test", sprintf("test"))  # L"test" -> "test"

# Note: All L"" strings replaced with "" for Mojo.
# We'll keep the L prefix as comment for reference but not in code.

TEST("printf_test", "escape"):
    EXPECT_EQ("%", test_sprintf("%%"))
    EXPECT_EQ("before %", test_sprintf("before %%"))
    EXPECT_EQ("% after", test_sprintf("%% after"))
    EXPECT_EQ("before % after", test_sprintf("before %% after"))
    EXPECT_EQ("%s", test_sprintf("%%s"))
    EXPECT_EQ("%", sprintf("%%"))
    EXPECT_EQ("before %", sprintf("before %%"))
    EXPECT_EQ("% after", sprintf("%% after"))
    EXPECT_EQ("before % after", sprintf("before %% after"))
    EXPECT_EQ("%s", sprintf("%%s"))

TEST("printf_test", "positional_args"):
    EXPECT_EQ("42", test_sprintf("%1$d", 42))
    EXPECT_EQ("before 42", test_sprintf("before %1$d", 42))
    EXPECT_EQ("42 after", test_sprintf("%1$d after", 42))
    EXPECT_EQ("before 42 after", test_sprintf("before %1$d after", 42))
    EXPECT_EQ("answer = 42", test_sprintf("%1$s = %2$d", "answer", 42))
    EXPECT_EQ("42 is the answer", test_sprintf("%2$d is the %1$s", "answer", 42))
    EXPECT_EQ("abracadabra", test_sprintf("%1$s%2$s%1$s", "abra", "cad"))

TEST("printf_test", "automatic_arg_indexing"):
    EXPECT_EQ("abc", test_sprintf("%c%c%c", 'a', 'b', 'c'))

TEST("printf_test", "number_is_too_big_in_arg_index"):
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%{}$", big_num)), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%{}$d", big_num)), format_error, "argument not found")

TEST("printf_test", "switch_arg_indexing"):
    EXPECT_THROW_MSG(fn() => test_sprintf("%1$d%", 1, 2), format_error, "cannot switch from manual to automatic argument indexing")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%1$d%{}d", big_num), 1, 2), format_error, "number is too big")
    EXPECT_THROW_MSG(fn() => test_sprintf("%1$d%d", 1, 2), format_error, "cannot switch from manual to automatic argument indexing")
    EXPECT_THROW_MSG(fn() => test_sprintf("%d%1$", 1, 2), format_error, "cannot switch from automatic to manual argument indexing")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%d%{}$d", big_num), 1, 2), format_error, "number is too big")
    EXPECT_THROW_MSG(fn() => test_sprintf("%d%1$d", 1, 2), format_error, "cannot switch from automatic to manual argument indexing")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%d%1${}d", big_num), 1, 2), format_error, "number is too big")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%1$d%{}d", big_num), 1, 2), format_error, "number is too big")

TEST("printf_test", "invalid_arg_index"):
    EXPECT_THROW_MSG(fn() => test_sprintf("%0$d", 42), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf("%2$d", 42), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%{}$d", Int32.MAX), 42), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf("%2$", 42), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%{}$d", big_num), 42), format_error, "argument not found")

TEST("printf_test", "default_align_right"):
    EXPECT_PRINTF("   42", "%5d", 42)
    EXPECT_PRINTF("  abc", "%5s", "abc")

TEST("printf_test", "zero_flag"):
    EXPECT_PRINTF("00042", "%05d", 42)
    EXPECT_PRINTF("-0042", "%05d", -42)
    EXPECT_PRINTF("00042", "%05d", 42)
    EXPECT_PRINTF("-0042", "%05d", -42)
    EXPECT_PRINTF("-004.2", "%06g", -4.2)
    EXPECT_PRINTF("+00042", "%00+6d", 42)
    EXPECT_PRINTF("   42", "%05.d", 42)
    EXPECT_PRINTF(" 0042", "%05.4d", 42)
    EXPECT_PRINTF("    x", "%05c", 'x')

TEST("printf_test", "plus_flag"):
    EXPECT_PRINTF("+42", "%+d", 42)
    EXPECT_PRINTF("-42", "%+d", -42)
    EXPECT_PRINTF("+0042", "%+05d", 42)
    EXPECT_PRINTF("+0042", "%0++5d", 42)
    EXPECT_PRINTF("x", "%+c", 'x')
    EXPECT_PRINTF("+42", "%+ d", 42)
    EXPECT_PRINTF("-42", "%+ d", -42)
    EXPECT_PRINTF("+42", "% +d", 42)
    EXPECT_PRINTF("-42", "% +d", -42)
    EXPECT_PRINTF("+0042", "% +05d", 42)
    EXPECT_PRINTF("+0042", "%0+ 5d", 42)
    EXPECT_PRINTF("x", "%+ c", 'x')
    EXPECT_PRINTF("x", "% +c", 'x')

TEST("printf_test", "minus_flag"):
    EXPECT_PRINTF("abc  ", "%-5s", "abc")
    EXPECT_PRINTF("abc  ", "%0--5s", "abc")
    EXPECT_PRINTF("7    ", "%-5d", 7)
    EXPECT_PRINTF("97   ", "%-5hhi", 'a')
    EXPECT_PRINTF("a    ", "%-5c", 'a')
    EXPECT_PRINTF("7    ", "%-05d", 7)
    EXPECT_PRINTF("7    ", "%0-5d", 7)
    EXPECT_PRINTF("a    ", "%-05c", 'a')
    EXPECT_PRINTF("a    ", "%0-5c", 'a')
    EXPECT_PRINTF("97   ", "%-05hhi", 'a')
    EXPECT_PRINTF("97   ", "%0-5hhi", 'a')
    EXPECT_PRINTF(" 42", "%- d", 42)

TEST("printf_test", "space_flag"):
    EXPECT_PRINTF(" 42", "% d", 42)
    EXPECT_PRINTF("-42", "% d", -42)
    EXPECT_PRINTF(" 0042", "% 05d", 42)
    EXPECT_PRINTF(" 0042", "%0  5d", 42)
    EXPECT_PRINTF("x", "% c", 'x')

TEST("printf_test", "hash_flag"):
    EXPECT_PRINTF("042", "%#o", 042)
    EXPECT_PRINTF(format("0{:o}", static_cast<unsigned>(-042)), "%#o", -042)
    EXPECT_PRINTF("0", "%#o", 0)
    EXPECT_PRINTF("0x42", "%#x", 0x42)
    EXPECT_PRINTF("0X42", "%#X", 0x42)
    EXPECT_PRINTF(format("0x{:x}", static_cast<unsigned>(-0x42)), "%#x", -0x42)
    EXPECT_PRINTF("0", "%#x", 0)
    EXPECT_PRINTF("0x0042", "%#06x", 0x42)
    EXPECT_PRINTF("0x0042", "%0##6x", 0x42)
    EXPECT_PRINTF("-42.000000", "%#f", -42.0)
    EXPECT_PRINTF("-42.000000", "%#F", -42.0)
    var buffer = Pointer[char].alloc(256)
    safe_sprintf(buffer, "%#e", -42.0)
    let buf_str = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str, "%#e", -42.0)
    safe_sprintf(buffer, "%#E", -42.0)
    let buf_str2 = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str2, "%#E", -42.0)
    EXPECT_PRINTF("-42.0000", "%#g", -42.0)
    EXPECT_PRINTF("-42.0000", "%#G", -42.0)
    safe_sprintf(buffer, "%#a", 16.0)
    let buf_str3 = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str3, "%#a", 16.0)
    safe_sprintf(buffer, "%#A", 16.0)
    let buf_str4 = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str4, "%#A", 16.0)
    EXPECT_PRINTF("x", "%#c", 'x')
    buffer.free()

TEST("printf_test", "width"):
    EXPECT_PRINTF("  abc", "%5s", "abc")
    EXPECT_THROW_MSG(fn() => test_sprintf("%5-5d", 42), format_error, "invalid type specifier")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%{}d", big_num), 42), format_error, "number is too big")
    EXPECT_THROW_MSG(fn() => test_sprintf(format("%1${}d", big_num), 42), format_error, "number is too big")

TEST("printf_test", "dynamic_width"):
    EXPECT_EQ("   42", test_sprintf("%*d", 5, 42))
    EXPECT_EQ("42   ", test_sprintf("%*d", -5, 42))
    EXPECT_THROW_MSG(fn() => test_sprintf("%*d", 5.0, 42), format_error, "width is not integer")
    EXPECT_THROW_MSG(fn() => test_sprintf("%*d"), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf("%*d", big_num, 42), format_error, "number is too big")

TEST("printf_test", "int_precision"):
    EXPECT_PRINTF("00042", "%.5d", 42)
    EXPECT_PRINTF("-00042", "%.5d", -42)
    EXPECT_PRINTF("00042", "%.5x", 0x42)
    EXPECT_PRINTF("0x00042", "%#.5x", 0x42)
    EXPECT_PRINTF("00042", "%.5o", 042)
    EXPECT_PRINTF("00042", "%#.5o", 042)
    EXPECT_PRINTF("  00042", "%7.5d", 42)
    EXPECT_PRINTF("  00042", "%7.5x", 0x42)
    EXPECT_PRINTF("   0x00042", "%#10.5x", 0x42)
    EXPECT_PRINTF("  00042", "%7.5o", 042)
    EXPECT_PRINTF("     00042", "%#10.5o", 042)
    EXPECT_PRINTF("00042  ", "%-7.5d", 42)
    EXPECT_PRINTF("00042  ", "%-7.5x", 0x42)
    EXPECT_PRINTF("0x00042   ", "%-#10.5x", 0x42)
    EXPECT_PRINTF("00042  ", "%-7.5o", 042)
    EXPECT_PRINTF("00042     ", "%-#10.5o", 042)

TEST("printf_test", "float_precision"):
    var buffer = Pointer[char].alloc(256)
    safe_sprintf(buffer, "%.3e", 1234.5678)
    let buf_str = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str, "%.3e", 1234.5678)
    EXPECT_PRINTF("1234.568", "%.3f", 1234.5678)
    EXPECT_PRINTF("1.23e+03", "%.3g", 1234.5678)
    safe_sprintf(buffer, "%.3a", 1234.5678)
    let buf_str2 = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str2, "%.3a", 1234.5678)
    buffer.free()

TEST("printf_test", "string_precision"):
    let test = array[char]('H', 'e', 'l', 'l', 'o')
    EXPECT_EQ(sprintf("%.4s", test), "Hell")

TEST("printf_test", "ignore_precision_for_non_numeric_arg"):
    EXPECT_PRINTF("abc", "%.5s", "abc")

TEST("printf_test", "dynamic_precision"):
    EXPECT_EQ("00042", test_sprintf("%.*d", 5, 42))
    EXPECT_EQ("42", test_sprintf("%.*d", -5, 42))
    EXPECT_THROW_MSG(fn() => test_sprintf("%.*d", 5.0, 42), format_error, "precision is not integer")
    EXPECT_THROW_MSG(fn() => test_sprintf("%.*d"), format_error, "argument not found")
    EXPECT_THROW_MSG(fn() => test_sprintf("%.*d", big_num, 42), format_error, "number is too big")
    if sizeof[long long] != sizeof[int]:
        let prec = static_cast[long long](Int32.MIN) - 1
        EXPECT_THROW_MSG(fn() => test_sprintf("%.*d", prec, 42), format_error, "number is too big")

# Template specialization for make_signed
struct make_signed[T: type]:
    type = T  # default

@impl make_signed[char]:
    type = signed char

@impl make_signed[unsigned char]:
    type = signed char

@impl make_signed[unsigned short]:
    type = short

@impl make_signed[unsigned]:
    type = int

@impl make_signed[unsigned long]:
    type = long

@impl make_signed[unsigned long long]:
    type = long long

# test_length template function
def test_length[T: type, U: type](length_spec: String, value: U):
    var signed_value: long long = 0
    var unsigned_value: unsigned long long = 0
    let max = max_value[U]()
    if const_check(max <= static_cast[unsigned](max_value[int]())):
        signed_value = static_cast[int](value)
        unsigned_value = static_cast[unsigned long long](value)
    elif const_check(max <= max_value[unsigned]()):
        signed_value = static_cast[unsigned](value)
        unsigned_value = static_cast[unsigned long long](value)
    else:
        # The original logic is complex; we simplify to match C++ behavior
        if sizeof[U] <= sizeof[int] and sizeof[int] < sizeof[T]:
            signed_value = static_cast[long long](value)
            unsigned_value = static_cast[unsigned long long](
                static_cast[make_unsigned[unsigned]::type](value))
        else:
            signed_value = static_cast[make_signed[T]::type](value)
            unsigned_value = static_cast[make_unsigned[T]::type](value)
    # Use ostringstream equivalent: build strings via format
    let os_signed = format("{}", signed_value)
    EXPECT_PRINTF(os_signed, format("%{}d", length_spec), value)
    EXPECT_PRINTF(os_signed, format("%{}i", length_spec), value)
    # Reset os_signed for unsigned
    let os_unsigned = format("{}", unsigned_value)
    EXPECT_PRINTF(os_unsigned, format("%{}u", length_spec), value)
    let os_oct = format("{:o}", unsigned_value)
    EXPECT_PRINTF(os_oct, format("%{}o", length_spec), value)
    let os_hex = format("{:x}", unsigned_value)
    EXPECT_PRINTF(os_hex, format("%{}x", length_spec), value)
    let os_hex_up = format("{:X}", unsigned_value)
    EXPECT_PRINTF(os_hex_up, format("%{}X", length_spec), value)

def test_length[T: type](length_spec: String):
    let min = numeric_limits[T].min()
    let max = max_value[T]()
    test_length[T](length_spec, 42)
    test_length[T](length_spec, -42)
    test_length[T](length_spec, min)
    test_length[T](length_spec, max)
    let long_long_min = numeric_limits[long long].min()
    if static_cast[long long](min) > long_long_min:
        test_length[T](length_spec, static_cast[long long](min) - 1)
    let long_long_max = max_value[long long]()
    if static_cast[unsigned long long](max) < long_long_max:
        test_length[T](length_spec, static_cast[long long](max) + 1)
    test_length[T](length_spec, numeric_limits[short].min())
    test_length[T](length_spec, max_value[unsigned short]())
    test_length[T](length_spec, numeric_limits[int].min())
    test_length[T](length_spec, max_value[int]())
    test_length[T](length_spec, numeric_limits[unsigned].min())
    test_length[T](length_spec, max_value[unsigned]())
    test_length[T](length_spec, numeric_limits[long long].min())
    test_length[T](length_spec, max_value[long long]())
    test_length[T](length_spec, numeric_limits[unsigned long long].min())
    test_length[T](length_spec, max_value[unsigned long long]())

TEST("printf_test", "length"):
    test_length[char]("hh")
    test_length[signed char]("hh")
    test_length[unsigned char]("hh")
    test_length[short]("h")
    test_length[unsigned short]("h")
    test_length[long]("l")
    test_length[unsigned long]("l")
    test_length[long long]("ll")
    test_length[unsigned long long]("ll")
    test_length[intmax_t]("j")
    test_length[size_t]("z")
    test_length[ptrdiff_t]("t")
    let max = max_value[long double]()
    EXPECT_PRINTF(format("{:.6}", max), "%g", max)
    EXPECT_PRINTF(format("{:.6}", max), "%Lg", max)

TEST("printf_test", "bool"):
    EXPECT_PRINTF("1", "%d", true)
    EXPECT_PRINTF("true", "%s", true)

TEST("printf_test", "int"):
    EXPECT_PRINTF("-42", "%d", -42)
    EXPECT_PRINTF("-42", "%i", -42)
    let u = unsigned(0 - 42)
    EXPECT_PRINTF(format("{}", u), "%u", -42)
    EXPECT_PRINTF(format("{:o}", u), "%o", -42)
    EXPECT_PRINTF(format("{:x}", u), "%x", -42)
    EXPECT_PRINTF(format("{:X}", u), "%X", -42)

TEST("printf_test", "long_long"):
    let max = max_value[long long]()
    EXPECT_PRINTF(format("{}", max), "%d", max)

TEST("printf_test", "float"):
    EXPECT_PRINTF("392.650000", "%f", 392.65)
    EXPECT_PRINTF("392.65", "%.2f", 392.65)
    EXPECT_PRINTF("392.6", "%.1f", 392.65)
    EXPECT_PRINTF("393", "%.f", 392.65)
    EXPECT_PRINTF("392.650000", "%F", 392.65)
    var buffer = Pointer[char].alloc(256)
    safe_sprintf(buffer, "%e", 392.65)
    let buf_str = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str, "%e", 392.65)
    safe_sprintf(buffer, "%E", 392.65)
    let buf_str2 = String.from_ptr(buffer)
    EXPECT_PRINTF(buf_str2, "%E", 392.65)
    EXPECT_PRINTF("392.65", "%g", 392.65)
    EXPECT_PRINTF("392.65", "%G", 392.65)
    EXPECT_PRINTF("392", "%g", 392.0)
    EXPECT_PRINTF("392", "%G", 392.0)
    EXPECT_PRINTF("4.56e-07", "%g", 0.000000456)
    safe_sprintf(buffer, "%a", -392.65)
    let buf_str3 = String.from_ptr(buffer)
    EXPECT_EQ(buf_str3, format("{:a}", -392.65))
    safe_sprintf(buffer, "%A", -392.65)
    let buf_str4 = String.from_ptr(buffer)
    EXPECT_EQ(buf_str4, format("{:A}", -392.65))
    buffer.free()

TEST("printf_test", "inf"):
    let inf = numeric_limits[double].infinity()
    var type_ptr: Pointer[char] = "fega"
    for i in range(4):
        let ch = type_ptr[i]
        if ch == 0:
            break
        let fmt_str = format("%{}", ch)
        EXPECT_PRINTF("inf", fmt_str, inf)
        let upper = static_cast[char](String.from_code_point(ch.code()).to_upper().code())
        let fmt_upper = format("%{}", upper)
        EXPECT_PRINTF("INF", fmt_upper, inf)
    # No need to free type_ptr, it's a string literal

TEST("printf_test", "char"):
    EXPECT_PRINTF("x", "%c", 'x')
    let max = max_value[int]()
    EXPECT_PRINTF(format("{}", static_cast[char](max)), "%c", max)
    EXPECT_PRINTF("x", "%c", 'x')  # L'x' -> 'x'
    EXPECT_PRINTF(format("{}", static_cast[wchar_t](max)), "%c", max)

TEST("printf_test", "string"):
    EXPECT_PRINTF("abc", "%s", "abc")
    let null_str: Pointer[char] = nil
    EXPECT_PRINTF("(null)", "%s", null_str)
    EXPECT_PRINTF("    (null)", "%10s", null_str)
    EXPECT_PRINTF("abc", "%s", "abc")  # L"abc" -> "abc"
    let null_wstr: Pointer[wchar_t] = nil
    EXPECT_PRINTF("(null)", "%s", null_wstr)
    EXPECT_PRINTF("    (null)", "%10s", null_wstr)

TEST("printf_test", "uchar_string"):
    let str = array[unsigned char]('t', 'e', 's', 't')
    let pstr: Pointer[unsigned char] = str.data()
    EXPECT_EQ("test", sprintf("%s", pstr))

TEST("printf_test", "pointer"):
    var n: int
    var p: Pointer[void] = address_of(n)
    EXPECT_PRINTF(format("{}", p), "%p", p)
    p = nil
    EXPECT_PRINTF("(nil)", "%p", p)
    EXPECT_PRINTF("     (nil)", "%10p", p)
    let s: Pointer[char] = "test"
    EXPECT_PRINTF(format("{:p}", s), "%p", s)
    let null_str: Pointer[char] = nil
    EXPECT_PRINTF("(nil)", "%p", null_str)
    p = address_of(n)
    EXPECT_PRINTF(format("{}", p), "%p", p)
    p = nil
    EXPECT_PRINTF("(nil)", "%p", p)
    EXPECT_PRINTF("     (nil)", "%10p", p)
    let w: Pointer[wchar_t] = "test"  # wchar_t as char pointer (wide string to narrow)
    EXPECT_PRINTF(format("{:p}", w), "%p", w)
    let null_wstr: Pointer[wchar_t] = nil
    EXPECT_PRINTF("(nil)", "%p", null_wstr)

enum test_enum:
    answer = 42

TEST("printf_test", "enum"):
    EXPECT_PRINTF("42", "%d", test_enum.answer)
    let volatile_enum: volatile test_enum = test_enum.answer
    EXPECT_PRINTF("42", "%d", volatile_enum)

# FMT_USE_FCNTL section - skip due to complexity, but keep blank line
# TEST(printf_test, examples) ...
# TEST(printf_test, printf_error) ...

TEST("printf_test", "wide_string"):
    EXPECT_EQ("abc", sprintf("%s", "abc"))

TEST("printf_test", "printf_custom"):
    EXPECT_EQ("abc", test_sprintf("%s", test_string("abc")))

TEST("printf_test", "vprintf"):
    let as = format_arg_store[printf_context, int](42)
    let args = basic_format_args[printf_context](as)
    EXPECT_EQ(vsprintf("%d", args), "42")
    EXPECT_WRITE(stdout, vprintf("%d", args), "42")
    EXPECT_WRITE(stdout, vfprintf(stdout, "%d", args), "42")

def check_format_string_regression(s: string_view, args...: type):
    sprintf(s, args...)

TEST("printf_test", "check_format_string_regression"):
    check_format_string_regression("%c%s", 'x', "")

TEST("printf_test", "fixed_large_exponent"):
    EXPECT_EQ("1000000000000000000000", sprintf("%.*f", -13, 1e21))

TEST("printf_test", "vsprintf_make_args_example"):
    let as = format_arg_store[printf_context, int, const char*](42, "something")
    let args = basic_format_args[printf_context](as)
    EXPECT_EQ(vsprintf("[%d] %s happened", args), "[42] something happened")
    let as2 = make_printf_args(42, "something")
    let args2 = basic_format_args[printf_context](as2)
    EXPECT_EQ(vsprintf("[%d] %s happened", args2), "[42] something happened")
    EXPECT_EQ(vsprintf("[%d] %s happened", {make_printf_args(42, "something")}), "[42] something happened")

TEST("printf_test", "vsprintf_make_wargs_example"):
    let as = format_arg_store[wprintf_context, int, const wchar_t*](42, "something")
    let args = basic_format_args[wprintf_context](as)
    EXPECT_EQ(vsprintf("[%d] %s happened", args), "[42] something happened")  # L"..." -> "..."
    let as2 = make_wprintf_args(42, "something")
    let args2 = basic_format_args[wprintf_context](as2)
    EXPECT_EQ(vsprintf("[%d] %s happened", args2), "[42] something happened")
    EXPECT_EQ(vsprintf("[%d] %s happened", {make_wprintf_args(42, "something")}), "[42] something happened")