from fmt.xchar import *
from fmt.chrono import *
from fmt.color import *
from fmt.ostream import *
from fmt.ranges import *
from gtest.testing import *  # Simulated gtest for Mojo (assumed)
from test.test_ns import TestString, non_string, to_string_view  # Not defined yet
from builtins import *
from max_value import max_value  # Not defined yet
from std.string import String, StringRef
from std.vector import List
from std.complex import Complex
from std.tm import tm  # Not defined yet
from std.chrono import seconds

using fmt.detail.max_value

namespace test_ns:
    struct test_string[Char: AnyType]:
        var s_: StringRef[Char]  # Not quite; but simulate
        def __init__(self, s: Pointer[Char]) -> None:
            self.s_ = StringRef[Char](s)
        def data(self) -> Pointer[Char]:
            return self.s_.data()
        def length(self) -> UInt:
            return self.s_.len()
        def __forward(self) -> Pointer[Char]:
            return self.s_.c_str()

    def to_string_view[Char: AnyType](s: test_string[Char]) -> fmt.basic_string_view[Char]:
        return fmt.basic_string_view[Char](s.data(), s.length())

    struct non_string:

# The following testing macros are adapted for Mojo but keep exact names.

struct is_string_test[T: AnyType]:  # Not a real test

using string_char_types = types_of(char, wchar_t, char16_t, char32_t)
TYPED_TEST_SUITE(is_string_test, string_char_types)

struct derived_from_string_view[Char: AnyType](fmt.basic_string_view[Char]):

TYPED_TEST(is_string_test, is_string):
    EXPECT_TRUE(fmt.detail.is_string[TypeParam*.type].value)
    EXPECT_TRUE(fmt.detail.is_string[Pointer[TypeParam]].value)
    EXPECT_TRUE(fmt.detail.is_string[TypeParam[2]].value)
    EXPECT_TRUE(fmt.detail.is_string[Pointer[TypeParam[2]]].value)
    EXPECT_TRUE(fmt.detail.is_string[String[TypeParam]].value)
    EXPECT_TRUE(fmt.detail.is_string[fmt.basic_string_view[TypeParam]].value)
    EXPECT_TRUE(fmt.detail.is_string[derived_from_string_view[TypeParam]].value)
    using fmt_string_view = fmt.detail.std_string_view[TypeParam]
    EXPECT_TRUE((std.is_empty[fmt_string_view].value) != (fmt.detail.is_string[fmt_string_view].value))
    EXPECT_TRUE(fmt.detail.is_string[test_ns.test_string[TypeParam]].value)
    EXPECT_FALSE(fmt.detail.is_string[test_ns.non_string].value)

#if !FMT_MSC_VER or FMT_MSC_VER >= 1900
struct explicitly_convertible_to_wstring_view:
    def __op_convert(self) -> fmt.wstring_view:
        return fmt.wstring_view("foo")  # L"foo" -> wide string

TEST(xchar_test, format_explicitly_convertible_to_wstring_view):
    EXPECT_EQ[WString]("foo", fmt.format[WString]("{}", explicitly_convertible_to_wstring_view()))
#endif

TEST(xchar_test, format):
    EXPECT_EQ[WString]("42", fmt.format[WString]("{}", 42))
    EXPECT_EQ[WString]("4.2", fmt.format[WString]("{}", 4.2))
    EXPECT_EQ[WString]("abc", fmt.format[WString]("{}", "abc"))
    EXPECT_EQ[WString]("z", fmt.format[WString]("{}", 'z'))
    EXPECT_THROW(fmt.format[WString]("{:*\x343E}", 42), fmt.format_error)
    EXPECT_EQ[WString]("true", fmt.format[WString]("{}", True))
    EXPECT_EQ[WString]("a", fmt.format[WString]("{0}", 'a'))
    EXPECT_EQ[WString]("a", fmt.format[WString]("{0}", WChar('a')))
    EXPECT_EQ[WString]("Cyrillic letter \x42e", fmt.format[WString]("Cyrillic letter {}", WChar('\x42e')))
    EXPECT_EQ[WString]("abc1", fmt.format[WString]("{}c{}", "ab", 1))

TEST(xchar_test, is_formattable):
    static_assert(!fmt.is_formattable[Pointer[WChar]].value, "")

TEST(xchar_test, compile_time_string):
    #if defined(FMT_USE_STRING_VIEW) and __cplusplus >= 201703L
    EXPECT_EQ[WString]("42", fmt.format(FMT_STRING(std.wstring_view("{}")), 42))
    #endif

#if __cplusplus > 201103L
struct custom_char:
    var value: Int32
    def __init__() -> self:
        self.value = 0
    def __init__[T: AnyType](self, val: T) -> None:
        self.value = Int32(val)
    def __int__(self) -> Int32:
        return self.value

def to_ascii(c: custom_char) -> Int32:
    return c

FMT_BEGIN_NAMESPACE
struct is_char[custom_char] <: std.true_type:

FMT_END_NAMESPACE

TEST(xchar_test, format_custom_char):
    const format: custom_char = [custom_char('{'), custom_char('}'), custom_char(0)]
    var result = fmt.format(format, custom_char('x'))
    EXPECT_EQ(result.size(), 1)
    EXPECT_EQ(result[0], custom_char('x'))
#endif

def from_u8str[S: AnyType](str: S) -> String:
    return String(str.begin(), str.end())

TEST(xchar_test, format_utf8_precision):
    using str_type = String[fmt.detail.char8_type]
    var format = str_type(reinterpret[Pointer[fmt.detail.char8_type]](u8"{:.4}"))
    var str = str_type(reinterpret[Pointer[fmt.detail.char8_type]](u8"caf\u00e9s"))
    var result = fmt.format(format, str)
    EXPECT_EQ(fmt.detail.compute_width(result), 4)
    EXPECT_EQ(result.size(), 5)
    EXPECT_EQ(from_u8str(result), from_u8str(str.substr(0, 5)))

TEST(xchar_test, format_to):
    var buf = List[WChar]()
    fmt.format_to(std.back_inserter(buf), WString("{}{}"), 42, WChar(0))
    EXPECT_STREQ(buf.data(), WString("42"))

TEST(xchar_test, vformat_to):
    using wcontext = fmt.wformat_context
    var warg = fmt.basic_format_arg[wcontext](fmt.detail.make_arg[wcontext](42))
    var wargs = fmt.basic_format_args[wcontext](ref[warg], 1)
    var w = WString()
    fmt.vformat_to(std.back_inserter(w), WString("{}"), wargs)
    EXPECT_EQ[WString]("42", w)
    w.clear()
    fmt.vformat_to(std.back_inserter(w), FMT_STRING(WString("{}")), wargs)
    EXPECT_EQ[WString]("42", w)

TEST(format_test, wide_format_to_n):
    var buffer: StaticArray[WChar, 4]
    buffer[3] = 'x'
    var result = fmt.format_to_n[WChar](buffer, 3, WString("{}"), 12345)
    EXPECT_EQ(5u, result.size)
    EXPECT_EQ(buffer + 3, result.out)
    EXPECT_EQ(fmt.wstring_view(buffer, 4), WString("123x"))
    buffer[0] = 'x'
    buffer[1] = 'x'
    buffer[2] = 'x'
    result = fmt.format_to_n[WChar](buffer, 3, WString("{}"), WChar('A'))
    EXPECT_EQ(1u, result.size)
    EXPECT_EQ(buffer + 1, result.out)
    EXPECT_EQ(fmt.wstring_view(buffer, 4), WString("Axxx"))
    result = fmt.format_to_n[WChar](buffer, 3, WString("{}{} "), WChar('B'), WChar('C'))
    EXPECT_EQ(3u, result.size)
    EXPECT_EQ(buffer + 3, result.out)
    EXPECT_EQ(fmt.wstring_view(buffer, 4), WString("BC x"))

#if FMT_USE_USER_DEFINED_LITERALS
TEST(xchar_test, format_udl):
    using fmt.literals.*
    EXPECT_EQ(WString("{}c{}").format("ab", 1), fmt.format(WString("{}c{}"), "ab", 1))

TEST(xchar_test, named_arg_udl):
    using fmt.literals.*
    var udl_a = fmt.format(WString("{first}{second}{first}{third}"),
                           WString("first")_a = "abra",
                           WString("second")_a = "cad",
                           WString("third")_a = 99)
    EXPECT_EQ(fmt.format(WString("{first}{second}{first}{third}"),
                         fmt.arg(WString("first"), "abra"),
                         fmt.arg(WString("second"), "cad"),
                         fmt.arg(WString("third"), 99)), udl_a)
#endif

TEST(xchar_test, print):
    if fmt.detail.const_check(False):
        fmt.print[WString]("test")

TEST(xchar_test, join):
    var v: StaticArray[Int32, 3] = [1, 2, 3]
    EXPECT_EQ[WString](fmt.format(WString("({})"), fmt.join(v, v + 3, WString(", "))), WString("(1, 2, 3)"))
    var t = (WChar('a'), 1, 2.0f)
    EXPECT_EQ[WString](fmt.format(WString("({})"), fmt.join(t, WString(", "))), WString("(a, 1, 2)"))

enum streamable_enum:
    member: Int32

def operator<<(os: WOutputStream, se: streamable_enum) -> WOutputStream:
    os << WString("streamable_enum")
    return os

enum unstreamable_enum:

TEST(xchar_test, enum):
    EXPECT_EQ[WString]("streamable_enum", fmt.format[WString]("{}", streamable_enum()))
    EXPECT_EQ[WString]("0", fmt.format[WString]("{}", unstreamable_enum()))

TEST(xchar_test, sign_not_truncated):
    var format_str: StaticArray[WChar, 5] = [
        WChar('{'), WChar(':'),
        WChar('+' | (WChar(1) << fmt.detail.num_bits[WChar]())),
        WChar('}'), WChar(0)
    ]
    EXPECT_THROW(fmt.format[WString](format_str, 42), fmt.format_error)

namespace fake_qt:
    struct QString:
        var s_: WString
        def __init__(self, s: Pointer[WChar]) -> None:
            self.s_ = WString(s)
        def utf16(self) -> Pointer[WChar]:
            return self.s_.data()
        def size(self) -> Int32:
            return Int32(self.s_.len())

    def to_string_view(s: QString) -> fmt.basic_string_view[WChar]:
        return fmt.basic_string_view[WChar](s.utf16(), UInt(s.size()))

TEST(format_test, format_foreign_strings):
    using fake_qt.QString
    EXPECT_EQ[WString](fmt.format[WString](QString(WString("{}")), 42), WString("42"))
    EXPECT_EQ[WString](fmt.format[WString](QString(WString("{}")), QString(WString("42"))), WString("42"))

TEST(xchar_test, chrono):
    var tm = tm()
    tm.tm_year = 116
    tm.tm_mon = 3
    tm.tm_mday = 25
    tm.tm_hour = 11
    tm.tm_min = 22
    tm.tm_sec = 33
    EXPECT_EQ[String](fmt.format("The date is {:%Y-%m-%d %H:%M:%S}.", tm),
                     "The date is 2016-04-25 11:22:33.")
    EXPECT_EQ[WString]("42s", fmt.format[WString]("{}", seconds(42)))

TEST(xchar_test, color):
    EXPECT_EQ[WString](fmt.format(fg(fmt.rgb(255, 20, 30)), WString("rgb(255,20,30) wide")),
                     WString("\x1b[38;2;255;020;030mrgb(255,20,30) wide\x1b[0m"))

TEST(xchar_test, ostream):
    var wos = WStringStream()
    fmt.print[WString](wos, "Don't {}", "panic")
    EXPECT_EQ[WString](wos.str(), "Don't panic!")

TEST(xchar_test, to_wstring):
    EXPECT_EQ[WString]("42", fmt.to_wstring(42))

#ifndef FMT_STATIC_THOUSANDS_SEPARATOR
struct numpunct[Char: AnyType](std.numpunct[Char]):
    def do_decimal_point(self) -> Char: return '?'
    def do_grouping(self) -> String: return "\03"
    def do_thousands_sep(self) -> Char: return '~'

struct no_grouping[Char: AnyType](std.numpunct[Char]):
    def do_decimal_point(self) -> Char: return '.'
    def do_grouping(self) -> String: return ""
    def do_thousands_sep(self) -> Char: return ','

struct special_grouping[Char: AnyType](std.numpunct[Char]):
    def do_decimal_point(self) -> Char: return '.'
    def do_grouping(self) -> String: return "\03\02"
    def do_thousands_sep(self) -> Char: return ','

struct small_grouping[Char: AnyType](std.numpunct[Char]):
    def do_decimal_point(self) -> Char: return '.'
    def do_grouping(self) -> String: return "\01"
    def do_thousands_sep(self) -> Char: return ','

TEST(locale_test, localized_double):
    var loc = std.locale(std.locale(), new numpunct[char]())
    EXPECT_EQ("1?23", fmt.format(loc, "{:L}", 1.23))
    EXPECT_EQ("1?230000", fmt.format(loc, "{:Lf}", 1.23))
    EXPECT_EQ("1~234?5", fmt.format(loc, "{:L}", 1234.5))
    EXPECT_EQ("12~000", fmt.format(loc, "{:L}", 12000.0))

TEST(locale_test, format):
    var loc = std.locale(std.locale(), new numpunct[char]())
    EXPECT_EQ("1234567", fmt.format(std.locale(), "{:L}", 1234567))
    EXPECT_EQ("1~234~567", fmt.format(loc, "{:L}", 1234567))
    EXPECT_EQ("-1~234~567", fmt.format(loc, "{:L}", -1234567))
    EXPECT_EQ("-256", fmt.format(loc, "{:L}", -256))
    var as = fmt.format_arg_store[fmt.format_context, Int32](1234567)
    EXPECT_EQ("1~234~567", fmt.vformat(loc, "{:L}", fmt.format_args(as)))
    var s = String()
    fmt.format_to(std.back_inserter(s), loc, "{:L}", 1234567)
    EXPECT_EQ("1~234~567", s)
    var no_grouping_loc = std.locale(std.locale(), new no_grouping[char]())
    EXPECT_EQ("1234567", fmt.format(no_grouping_loc, "{:L}", 1234567))
    var special_grouping_loc = std.locale(std.locale(), new special_grouping[char]())
    EXPECT_EQ("1,23,45,678", fmt.format(special_grouping_loc, "{:L}", 12345678))
    EXPECT_EQ("12,345", fmt.format(special_grouping_loc, "{:L}", 12345))
    var small_grouping_loc = std.locale(std.locale(), new small_grouping[char]())
    EXPECT_EQ("4,2,9,4,9,6,7,2,9,5",
              fmt.format(small_grouping_loc, "{:L}", max_value[UInt32]()))

TEST(locale_test, format_detault_align):
    var loc = std.locale({}, new special_grouping[char]())
    EXPECT_EQ("  12,345", fmt.format(loc, "{:8L}", 12345))

TEST(locale_test, format_plus):
    var loc = std.locale({}, new special_grouping[char]())
    EXPECT_EQ("+100", fmt.format(loc, "{:+L}", 100))

TEST(locale_test, wformat):
    var loc = std.locale(std.locale(), new numpunct[wchar_t]())
    EXPECT_EQ[WString]("1234567", fmt.format[WString](std.locale(), L"{:L}", 1234567))
    EXPECT_EQ[WString]("1~234~567", fmt.format[WString](loc, L"{:L}", 1234567))
    using wcontext = fmt.buffer_context[WChar]
    var as = fmt.format_arg_store[wcontext, Int32](1234567)
    EXPECT_EQ[WString]("1~234~567",
                       fmt.vformat[WString](loc, L"{:L}", fmt.basic_format_args[wcontext](as)))
    EXPECT_EQ[WString]("1234567", fmt.format[WString](std.locale("C"), L"{:L}", 1234567))
    var no_grouping_loc = std.locale(std.locale(), new no_grouping[wchar_t]())
    EXPECT_EQ[WString]("1234567", fmt.format[WString](no_grouping_loc, L"{:L}", 1234567))
    var special_grouping_loc = std.locale(std.locale(), new special_grouping[wchar_t]())
    EXPECT_EQ[WString]("1,23,45,678",
                       fmt.format[WString](special_grouping_loc, L"{:L}", 12345678))
    var small_grouping_loc = std.locale(std.locale(), new small_grouping[wchar_t]())
    EXPECT_EQ[WString]("4,2,9,4,9,6,7,2,9,5",
                       fmt.format[WString](small_grouping_loc, L"{:L}", max_value[UInt32]()))

TEST(locale_test, double_formatter):
    var loc = std.locale(std.locale(), new special_grouping[char]())
    var f = fmt.formatter[Int32]()
    var parse_ctx = fmt.format_parse_context("L")
    f.parse(parse_ctx)
    var buf: StaticArray[char, 10] = {0}
    var format_ctx = fmt.basic_format_context[Pointer[char], char](buf, {}, fmt.detail.locale_ref(loc))
    *f.format(12345, format_ctx) = 0
    EXPECT_STREQ("12,345", buf)

FMT_BEGIN_NAMESPACE
struct formatter[Complex[Float64], charT: AnyType]:
    var specs_: detail.dynamic_format_specs[char]
    def parse[ctx: fmt.basic_format_parse_context[charT]](self, ctx: ref ctx) -> Iterator:
        using handler_type = detail.dynamic_specs_handler[ctx]
        var handler = handler_type(detail.dynamic_specs_handler(self.specs_, ctx), detail.type.string_type)
        var it = parse_format_specs(ctx.begin(), ctx.end(), handler)
        detail.parse_float_type_spec(self.specs_, ctx.error_handler())
        return it
    def format[Context: fmt.FormatContext](self, c: Complex[Float64], ctx: ref Context) -> Iterator:
        detail.handle_dynamic_spec[detail.precision_checker](self.specs_.precision, self.specs_.precision_ref, ctx)
        var specs = String()
        if self.specs_.precision > 0: specs = fmt.format(".{}", self.specs_.precision)
        if self.specs_.type: specs += self.specs_.type
        var real = fmt.format(ctx.locale().template get[std.locale](), fmt.runtime("{:" + specs + "}"), c.real())
        var imag = fmt.format(ctx.locale().template get[std.locale](), fmt.runtime("{:" + specs + "}"), c.imag())
        var fill_align_width = String()
        if self.specs_.width > 0: fill_align_width = fmt.format(">{}", self.specs_.width)
        return format_to(ctx.out(), runtime("{:" + fill_align_width + "}"),
                         (c.real() != 0) ? fmt.format("({}+{}i)", real, imag) : fmt.format("{}i", imag))
FMT_END_NAMESPACE

TEST(locale_test, complex):
    var s = fmt.format("{}", Complex[Float64](1, 2))
    EXPECT_EQ(s, "(1+2i)")
    EXPECT_EQ(fmt.format("{:.2f}", Complex[Float64](1, 2)), "(1.00+2.00i)")
    EXPECT_EQ(fmt.format("{:8}", Complex[Float64](1, 2)), "  (1+2i)")
#endif