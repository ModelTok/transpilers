from std.format import format, format_to, format_context, format_parse_context, visit_format_arg, format_error
from std.string import String
from std.numeric import numeric_limits
from gtest import Test, EXPECT_EQ, EXPECT_THROW
import std

def test_escaping():
    var s = format("{0}-{{", 8)
    EXPECT_EQ(s, "8-{")

def test_indexing():
    var s0 = format("{} to {}", "a", "b")
    var s1 = format("{1} to {0}", "a", "b")
    EXPECT_EQ(s0, "a to b")
    EXPECT_EQ(s1, "b to a")
    try:
        var s2 = format("{0} to {}", "a", "b")
        EXPECT_THROW(True, False)
    except format_error:

    try:
        var s3 = format("{} to {1}", "a", "b")
        EXPECT_THROW(True, False)
    except format_error:

def test_alignment():
    var c: Int8 = 120
    var s0 = format("{:6}", 42)
    var s1 = format("{:6}", 'x')
    var s2 = format("{:*<6}", 'x')
    var s3 = format("{:*>6}", 'x')
    var s4 = format("{:*^6}", 'x')
    try:
        var s5 = format("{:=6}", 'x')
        EXPECT_THROW(True, False)
    except format_error:

    var s6 = format("{:6d}", c)
    var s7 = format("{:6}", True)
    EXPECT_EQ(s0, "    42")
    EXPECT_EQ(s1, "x     ")
    EXPECT_EQ(s2, "x*****")
    EXPECT_EQ(s3, "*****x")
    EXPECT_EQ(s4, "**x***")
    EXPECT_EQ(s6, "   120")
    EXPECT_EQ(s7, "true  ")

def test_float():
    var inf = std.numeric.numeric_limits[Float64].infinity()
    var nan = std.numeric.numeric_limits[Float64].quiet_NaN()
    var s0 = format("{0:} {0:+} {0:-} {0: }", 1)
    var s1 = format("{0:} {0:+} {0:-} {0: }", -1)
    var s2 = format("{0:} {0:+} {0:-} {0: }", inf)
    var s3 = format("{0:} {0:+} {0:-} {0: }", nan)
    EXPECT_EQ(s0, "1 +1 1  1")
    EXPECT_EQ(s1, "-1 -1 -1 -1")
    EXPECT_EQ(s2, "inf +inf inf  inf")
    EXPECT_EQ(s3, "nan +nan nan  nan")

def test_int():
    var s0 = format("{}", 42)
    var s1 = format("{0:b} {0:d} {0:o} {0:x}", 42)
    var s2 = format("{0:#x} {0:#X}", 42)
    var s3 = format("{:L}", 1234)
    EXPECT_EQ(s0, "42")
    EXPECT_EQ(s1, "101010 42 52 2a")
    EXPECT_EQ(s2, "0x2a 0X2A")
    EXPECT_EQ(s3, "1234")

enum color: Int8:
    red = 0
    green = 1
    blue = 2

var color_names = StaticString("red"), StaticString("green"), StaticString("blue")

def formatter_color(c: color, ctx: format_context) -> format_context.iterator:
    return formatter[StaticString]().format(color_names[Int(c)], ctx)

struct err:

def test_formatter():
    var s0 = format("{}", 42)
    var s2 = format("{}", color.red)
    EXPECT_EQ(s0, "42")
    EXPECT_EQ(s2, "red")

struct S:
    var value: Int32

def formatter_S(s: S, ctx: format_context) -> format_context.iterator:
    var width_arg_id: UInt = 0
    # The parse method is defined for simplicity
    # Since Mojo doesn't support custom formatter specialization via template,
    # we implement format directly with width from arg(0)
    var width = visit_format_arg[Int](fn(width_arg_value: AnyType) -> Int:
        var value_type = __type_of(width_arg_value)
        if not isinstance(value_type, Int32) and not isinstance(value_type, Int64):
            raise format_error("width is not integral")
        elif width_arg_value < 0 or width_arg_value > numeric_limits[Int32].max():
            raise format_error("invalid width")
        else:
            return Int(width_arg_value)
    , ctx.arg(0))
    return format_to(ctx.out(), "{0:{1}}", s.value, width)

def test_parsing():
    var s = format("{0:{1}}", S{value=42}, 10)
    EXPECT_EQ(s, "        42")

# #if FMT_USE_INT128
# template <> struct formatter<__int128_t> : formatter<long long> {
#   auto format(__int128_t n, format_context& ctx) {
#     return formatter<long long>::format(static_cast<long long>(n), ctx);
#   }
# };
# TEST(std_format_test, int128) {
#   __int128_t n = 42;
#   auto s = format("{}", n);
#   EXPECT_EQ(s, "42");
# }
# #endif  // FMT_USE_INT128