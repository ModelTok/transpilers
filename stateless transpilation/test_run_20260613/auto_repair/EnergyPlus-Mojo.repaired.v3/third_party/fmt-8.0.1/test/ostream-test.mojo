from fmt import format, runtime, print, format_to_n, string_view, join, detail, to_string, memory_buffer
from fmt.ostream import write_buffer
from fmt.ranges import *
from gmock import Mock, expect_call, InSequence
from gtest_extra import expect_eq, expect_throw_msg
from util import *
from stdlib.ostringstream import OStringStream
from stdlib.ostream import OStream

# NOTE: Mojo does not support operator overloading as in C++.
# The following operator<< functions are replaced with free functions
# that take an OStream and return that OStream, using a string return.

struct test: pass

# The formatter specialization for test is written as a function
# that implements the formatting trait. In Mojo we use a trait.
# For simplicity, we define a function format_test that returns a String.
def format_test(ctx: FormatContext) -> FormatContext:
    return formatter_int_format(42, ctx)

# We cannot have template specialization, so we simulate using a generic
# function that handles test type by calling format_test.

# date struct (must be defined elsewhere, assumed in util)
# operator<< for date (narrow and wide) are replaced with functions
# that return formatted strings.

def date_ostream(os: OStream, d: date) -> OStream:
    # In Mojo, we'd write the string to the stream differently.
    # For simplicity, we just append the formatted string.
    var s: String = d.year().to_string() + '-' + d.month().to_string() + '-' + d.day().to_string()
    os.write(s)
    return os

def date_wostream(os: OStreamWide, d: date) -> OStreamWide:
    var s: WideString = d.year().to_string().wide() + L'-' + d.month().to_string().wide() + L'-' + d.day().to_string().wide()
    os.write(s)
    return os

# type_with_comma_op and associated operators (not used in tests)
struct type_with_comma_op: pass
def comma_operator(op: type_with_comma_op, T: Any) -> None: pass
def shift_operator(T: Any, d: date) -> type_with_comma_op: pass

enum streamable_enum:
    # Mojo enums are types; we define a single variant.
    value

def streamable_enum_ostream(os: OStream, e: streamable_enum) -> OStream:
    os.write("streamable_enum")
    return os

enum unstreamable_enum:
    value

# Test struct for ostream_test group
struct ostream_test:
    def enum():
        expect_eq("streamable_enum", format("{}", streamable_enum()))
        expect_eq("0", format("{}", unstreamable_enum()))

    def format():
        expect_eq("a string", format("{0}", test_string("a string")))
        expect_eq("The date is 2012-12-9", format("The date is {0}", date(2012, 12, 9)))

    def format_specs():
        expect_eq("def  ", format("{0:<5}", test_string("def")))
        expect_eq("  def", format("{0:>5}", test_string("def")))
        expect_eq(" def ", format("{0:^5}", test_string("def")))
        expect_eq("def**", format("{0:*<5}", test_string("def")))
        expect_throw_msg(fn() => format(runtime("{0:+}"), test_string()), "format specifier requires numeric argument")
        expect_throw_msg(fn() => format(runtime("{0:-}"), test_string()), "format specifier requires numeric argument")
        expect_throw_msg(fn() => format(runtime("{0: }"), test_string()), "format specifier requires numeric argument")
        expect_throw_msg(fn() => format(runtime("{0:#}"), test_string()), "format specifier requires numeric argument")
        expect_throw_msg(fn() => format(runtime("{0:05}"), test_string()), "format specifier requires numeric argument")
        expect_eq("test         ", format("{0:13}", test_string("test")))
        expect_eq("test         ", format("{0:{1}}", test_string("test"), 13))
        expect_eq("te", format("{0:.2}", test_string("test")))
        expect_eq("te", format("{0:.{1}}", test_string("test"), 2))

struct empty_test: pass
def empty_test_ostream(os: OStream, et: empty_test) -> OStream:
    os.write("")
    return os

    # empty_custom_output test
    def empty_custom_output():
        expect_eq("", format("{}", empty_test()))

    def print():
        var os: OStringStream
        fmt.print(os, "Don't {}!", "panic")
        expect_eq("Don't panic!", os.str())

    def write_to_ostream():
        var os: OStringStream
        var buffer: memory_buffer
        var foo: String = "foo"
        buffer.append(foo, foo + std.strlen(foo))
        detail.write_buffer(os, buffer)
        expect_eq("foo", os.str())

    def write_to_ostream_max_size():
        var max_size: size_t = detail.max_value[type=size_t]()
        var max_streamsize: std.streamsize = detail.max_value(type[streamsize])
        if max_size <= detail.to_unsigned(max_streamsize):
            return
        var buffer: test_buffer = test_buffer(max_size)
        var streambuf: mock_streambuf
        var os: test_ostream = test_ostream(streambuf)
        var sequence: testing.InSequence
        var data: ptr_char = null
        var size: ustreamsize = max_size
        while size != 0:
            var n: ustreamsize = min(size, detail.to_unsigned(max_streamsize))
            expect_call(streambuf.xsputn(data, static_cast[std.streamsize](n))).will_once(testing.Return(max_streamsize))
            data += n
            size -= n
        detail.write_buffer(os, buffer)

    def join():
        var v: int[3] = [1, 2, 3]
        expect_eq("1, 2, 3", format("{}", fmt.join(v, v + 3, ", ")))

    def join_fallback_formatter():
        var strs: List[test_string] = [test_string("foo"), test_string("bar")]
        expect_eq("foo, bar", format("{}", fmt.join(strs, ", ")))

    # conditional for (not supported in Mojo, but keep structure)
    def constexpr_string():
        expect_eq("42", format(FMT_STRING("{}"), std.string("42")))
        expect_eq("a string", format(FMT_STRING("{0}"), test_string("a string")))

# namespace fmt_test
struct fmt_test:
    struct abc: pass
    def abc_ostream(out: Output, a: abc) -> Output:
        out.write("abc")
        return out

struct test_template[T: type]:

def test_template_ostream[T: type](os: OStream, t: test_template[T]) -> OStream:
    os.write(1)
    return os
def test_template_formatter[T: type](t: test_template[T], ctx: FormatContext) -> FormatContext:
    return formatter_int_format(2, ctx)

def template():
    expect_eq("2", format("{}", test_template[int]()))

def format_to_n():
    var buffer: char[4]
    buffer[3] = 'x'
    var result = fmt.format_to_n(buffer, 3, "{}", fmt_test.abc())
    expect_eq(3_u, result.size)
    expect_eq(buffer + 3, result.out)
    expect_eq("abcx", fmt.string_view(buffer, 4))
    result = fmt.format_to_n(buffer, 3, "x{}y", fmt_test.abc())
    expect_eq(5_u, result.size)
    expect_eq(buffer + 3, result.out)
    expect_eq("xabx", fmt.string_view(buffer, 4))

struct convertible[T: type]:
    var value: T
    def __init__(self, val: T):
        self.value = val
    def __convert__(self) -> T:  # conversion operator
        return self.value

def disable_builtin_ostream_operators():
    expect_eq("42", format("{:d}", convertible[unsigned_short](42)))
    expect_eq("foo", format("{}", convertible[const_char_ptr]("foo")))

struct explicitly_convertible_to_string_like:
    def __explicit_convert__[StringType](self) -> StringType:
        return StringType("foo", 3_u)

def explicitly_convertible_to_string_like_ostream(os: OStream, e: explicitly_convertible_to_string_like) -> OStream:
    os.write("bar")
    return os

def format_explicitly_convertible_to_string_like():
    expect_eq("bar", format("{}", explicitly_convertible_to_string_like()))

# Conditional for FMT_USE_STRING_VIEW (assume true)
struct explicitly_convertible_to_std_string_view:
    def __explicit_convert__(self) -> fmt.detail.std_string_view[char]:
        return {"foo", 3_u}

def explicitly_convertible_to_std_string_view_ostream(os: OStream, e: explicitly_convertible_to_std_string_view) -> OStream:
    os.write("bar")
    return os

def format_explicitly_convertible_to_std_string_view():
    expect_eq("bar", format("{}", explicitly_convertible_to_string_like()))

struct streamable_and_convertible_to_bool:
    def __convert_to_bool(self) -> bool:
        return true

def streamable_and_convertible_to_bool_ostream(os: OStream, e: streamable_and_convertible_to_bool) -> OStream:
    os.write("foo")
    return os

def format_convertible_to_bool():
    expect_eq("foo", format("{}", streamable_and_convertible_to_bool()))

struct copyfmt_test:

def copyfmt_test_ostream(os: OStream, ct: copyfmt_test) -> OStream:
    var ios: OStream = null
    ios.copyfmt(os)
    os.write("foo")
    return os

def copyfmt():
    expect_eq("foo", format("{}", copyfmt_test()))

def to_string():
    expect_eq("abc", fmt.to_string(fmt_test.abc()))

def range():
    var strs: List[test_string] = [test_string("foo"), test_string("bar")]
    expect_eq("[foo, bar]", format("{}", strs))

# Run all tests
def main():
    ostream_test.enum()
    ostream_test.format()
    ostream_test.format_specs()
    ostream_test.empty_custom_output()
    ostream_test.print()
    ostream_test.write_to_ostream()
    ostream_test.write_to_ostream_max_size()
    ostream_test.join()
    ostream_test.join_fallback_formatter()
    # constexpr_string not supported, skip
    ostream_test.template()
    format_to_n()
    disable_builtin_ostream_operators()
    format_explicitly_convertible_to_string_like()
    format_explicitly_convertible_to_std_string_view()
    format_convertible_to_bool()
    copyfmt()
    to_string()
    range()