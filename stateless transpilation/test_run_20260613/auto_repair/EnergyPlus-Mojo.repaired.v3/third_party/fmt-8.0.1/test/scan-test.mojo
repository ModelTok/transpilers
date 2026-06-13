from fmt import scan, string_view, format_error, scan_parse_context, detail
from time import tm, strptime
from climits import *  # not used directly, but keep import
from gmock import *  # replaced with Mojo testing
from gtest-extra import *  # replaced with Mojo testing

# Helper to mimic EXPECT_EQ
def expect_eq[T: Equatable](actual: T, expected: T):
    if actual != expected:
        print("FAIL: expected", expected, "got", actual)
        # In Mojo testing, we could raise an error
        raise Error("assertion failed")

# Helper to mimic EXPECT_THROW_MSG
def expect_throw_msg(callable: fn() raises Error, expected_type: type, expected_msg: String):
    try:
        callable()
        print("FAIL: expected exception")
        raise Error("expected exception not thrown")
    except e:
        if not isinstance(e, expected_type):
            print("FAIL: wrong exception type")
            raise Error("wrong exception type")
        if str(e) != expected_msg:
            print("FAIL: wrong message")
            raise Error("wrong exception message")

struct scan_test:
    @staticmethod
    def read_text():
        var s = string_view("foo")
        var end = scan(s, "foo")
        expect_eq(end, s.end())
        expect_throw_msg(lambda: scan("fob", "foo"), format_error, "invalid input")

    @staticmethod
    def read_int():
        var n: Int = 0
        scan("42", "{}", n)
        expect_eq(n, 42)
        scan("-42", "{}", n)
        expect_eq(n, -42)

    @staticmethod
    def read_longlong():
        var n: Int64 = 0
        scan("42", "{}", n)
        expect_eq(n, 42)
        scan("-42", "{}", n)
        expect_eq(n, -42)

    @staticmethod
    def read_uint():
        var n: UInt = 0
        scan("42", "{}", n)
        expect_eq(n, 42)
        expect_throw_msg(lambda: scan("-42", "{}", n), format_error, "invalid input")

    @staticmethod
    def read_ulonglong():
        var n: UInt64 = 0
        scan("42", "{}", n)
        expect_eq(n, 42)
        expect_throw_msg(lambda: scan("-42", "{}", n), format_error, "invalid input")

    @staticmethod
    def read_string():
        var s = String()
        scan("foo", "{}", s)
        expect_eq(s, "foo")

    @staticmethod
    def read_string_view():
        var s = string_view()
        scan("foo", "{}", s)
        expect_eq(s, "foo")

    # #ifndef _WIN32
    # In Mojo, we include this unconditionally (assuming non-Windows)
    @staticmethod
    def read_custom():
        var input = "Date: 1985-10-25"
        var t = tm()
        scan(input, "Date: {0:%Y-%m-%d}", t)
        expect_eq(t.tm_year, 85)
        expect_eq(t.tm_mon, 9)
        expect_eq(t.tm_mday, 25)

    @staticmethod
    def invalid_format():
        expect_throw_msg(lambda: scan("", "{}"), format_error, "argument index out of range")
        expect_throw_msg(lambda: scan("", "{"), format_error, "invalid format string")

    @staticmethod
    def example():
        var key = String()
        var value: Int = 0
        scan("answer = 42", "{} = {}", key, value)
        expect_eq(key, "answer")
        expect_eq(value, 42)

# Custom scanner for tm (translation of template specialization)
# Note: In Mojo, we define a struct with the required interface.
# The original C++ code defines `template <> struct scanner<tm>` inside namespace fmt.
# We replicate the logic here.
struct scanner_tm:
    var format: String

    def parse(inout self, ctx: scan_parse_context) -> scan_parse_context.iterator:
        var it = ctx.begin()
        if it != ctx.end() and it[] == ':':
            it += 1
        var end = it
        while end != ctx.end() and end[] != '}':
            end += 1
        self.format.reserve(detail.to_unsigned(end - it + 1))
        self.format.append(it, end)
        self.format.push_back('\0')
        return end

    def scan[T: ScanContext](inout self, t: tm, ctx: T) -> T.iterator:
        var result = strptime(ctx.begin(), self.format.c_str(), t)
        if not result:
            throw format_error("failed to parse time")
        return result

# Register the custom scanner for tm (in Mojo, we need to make scan function aware of it)
# This is a simplified approach; the actual integration would require modifying the fmt module.
# For the test, we assume the scan function can handle a scanner_tm argument.
# We override the scan function for tm? Not possible without modifying fmt.
# Instead, we keep the test as is, assuming the fmt module has been extended.
# The test will call scan with a tm argument, which should use the scanner_tm.
# We'll leave the test as is.

# Run all tests
def main():
    scan_test.read_text()
    scan_test.read_int()
    scan_test.read_longlong()
    scan_test.read_uint()
    scan_test.read_ulonglong()
    scan_test.read_string()
    scan_test.read_string_view()
    scan_test.read_custom()
    scan_test.invalid_format()
    scan_test.example()
    print("All tests passed.")