# Define compile-time constants to emulate preprocessor macros
alias _MSC_FULL_VER = 0  # not defined in Mojo
alias FMT_HIDE_MODULE_BUGS = 0
alias FMT_CORE_H_ = 0
alias FMT_FORMAT_H_ = 0
alias FMT_OS_H_ = 1  # prevent os.h inclusion
alias FMT_USE_FCNTL = 0

# Standard library equivalents
from stdlib import bit
from stdlib import chrono
from stdlib import exception
from stdlib import iterator
from stdlib import locale
from stdlib import memory
from stdlib import ostream
from stdlib import string
from stdlib import string_view
from stdlib import system_error
# Conditional includes: skip fcntl (not available)
# #if defined(_WIN32) && !defined(__MINGW32__)
# # define FMT_POSIX(call) _##call
# #else
# # define FMT_POSIX(call) call
# #endif
# #define FMT_OS_H_  // don't pull in os.h directly or indirectly

# Import fmt module (assumed to be in parent directory)
from .. import fmt

# Static variable to track macro leakage
var macro_leaked: Bool = True if (FMT_CORE_H_ != 0 or FMT_FORMAT_H_ != 0) else False

# Include gtest-extra and util modules (assumed to exist in same directory)
from gtest-extra import *
from util import *

# Test: namespace
TEST("module_test", "namespace") {
    ASSERT_TRUE(True);
}

# Namespace detail visibility check
namespace detail:
    bool oops_detail_namespace_is_visible = False

namespace fmt:
    def namespace_detail_invisible() -> Bool:
        #if defined(FMT_HIDE_MODULE_BUGS) && defined(_MSC_FULL_VER) && \
    #    _MSC_FULL_VER <= 192930129
        #  return True;
        #else
        return not oops_detail_namespace_is_visible
        #endif

TEST("module_test", "detail_namespace") {
    EXPECT_TRUE(fmt.namespace_detail_invisible())
}

TEST("module_test", "macros") {
    #if defined(FMT_HIDE_MODULE_BUGS) && defined(_MSC_FULL_VER) && \
    #    _MSC_FULL_VER <= 192930129
    #  macro_leaked = false;
    #endif
    EXPECT_FALSE(macro_leaked)
}

TEST("module_test", "to_string") {
    EXPECT_EQ("42", fmt.to_string(42))
    EXPECT_EQ("42", fmt.to_string(42.0))
    EXPECT_EQ(L"42", fmt.to_wstring(42))
    EXPECT_EQ(L"42", fmt.to_wstring(42.0))
}

TEST("module_test", "format") {
    EXPECT_EQ("42", fmt.format("{:}", 42))
    EXPECT_EQ("-42", fmt.format("{0}", -42.0))
    EXPECT_EQ(L"42", fmt.format(L"{:}", 42))
    EXPECT_EQ(L"-42", fmt.format(L"{0}", -42.0))
}

TEST("module_test", "format_to") {
    var s: String = String()
    fmt.format_to(std.back_inserter(s), "{}", 42)
    EXPECT_EQ("42", s)
    var buffer: StaticArray[Char, 4] = StaticArray[Char, 4]()
    buffer.zero()
    fmt.format_to(buffer, "{}", 42)
    EXPECT_EQ("42", StringView(buffer))
    var mb: fmt.MemoryBuffer = fmt.MemoryBuffer()
    fmt.format_to(mb, "{}", 42)
    EXPECT_EQ("42", StringView(buffer))  # reuse buffer for size check
    var w: WString = WString()
    fmt.format_to(std.back_inserter(w), L"{}", 42)
    EXPECT_EQ(L"42", w)
    var wbuffer: StaticArray[WChar, 4] = StaticArray[WChar, 4]()
    wbuffer.zero()
    fmt.format_to(wbuffer, L"{}", 42)
    EXPECT_EQ(L"42", WStringView(wbuffer))
    var wb: fmt.WMemoryBuffer = fmt.WMemoryBuffer()
    fmt.format_to(wb, L"{}", 42)
    EXPECT_EQ(L"42", WStringView(wbuffer))
}

TEST("module_test", "formatted_size") {
    EXPECT_EQ(2u, fmt.formatted_size("{}", 42))
    EXPECT_EQ(2u, fmt.formatted_size(L"{}", 42))
}

TEST("module_test", "format_to_n") {
    var s: String = String()
    var result = fmt.format_to_n(std.back_inserter(s), 1, "{}", 42)
    EXPECT_EQ(2u, result.size)
    var buffer: StaticArray[Char, 4] = StaticArray[Char, 4]()
    buffer.zero()
    fmt.format_to_n(buffer, 3, "{}", 12345)
    var w: WString = WString()
    var wresult = fmt.format_to_n(std.back_inserter(w), 1, L"{}", 42)
    EXPECT_EQ(2u, wresult.size)
    var wbuffer: StaticArray[WChar, 4] = StaticArray[WChar, 4]()
    wbuffer.zero()
    fmt.format_to_n(wbuffer, 3, L"{}", 12345)
}

TEST("module_test", "format_args") {
    var no_args = fmt.format_args()
    EXPECT_FALSE(no_args.get(1))
    var args: fmt.BasicFormatArgs = fmt.make_format_args(42)
    EXPECT_TRUE(args.max_size() > 0)
    var arg0 = args.get(0)
    EXPECT_TRUE(arg0)
    arg0 = None  # decltype(arg0) arg_none; in Mojo we use optional type
    EXPECT_FALSE(arg0)
    # The following line checks type difference; skip because Mojo doesn't have type() method
    # EXPECT_TRUE(arg0.type() != arg_none.type())
}

TEST("module_test", "wformat_args") {
    var no_args = fmt.wformat_args()
    EXPECT_FALSE(no_args.get(1))
    var args: fmt.BasicFormatArgs = fmt.make_wformat_args(42)
    EXPECT_TRUE(args.get(0))
}

TEST("module_test", "checked_format_args") {
    var args: fmt.BasicFormatArgs = fmt.make_args_checked[Int]("{}", 42)
    EXPECT_TRUE(args.get(0))
    var wargs: fmt.BasicFormatArgs = fmt.make_args_checked[Int](L"{}", 42)
    EXPECT_TRUE(wargs.get(0))
}

TEST("module_test", "dynamic_format_args") {
    var dyn_store: fmt.DynamicFormatArgStore[fmt.FormatContext] = fmt.DynamicFormatArgStore[fmt.FormatContext]()
    dyn_store.push_back(fmt.arg("a42", 42))
    var args: fmt.BasicFormatArgs = dyn_store
    EXPECT_FALSE(args.get(3))
    EXPECT_TRUE(args.get(fmt.string_view("a42")))
    var wdyn_store: fmt.DynamicFormatArgStore[fmt.WFormatContext] = fmt.DynamicFormatArgStore[fmt.WFormatContext]()
    wdyn_store.push_back(fmt.arg(L"a42", 42))
    var wargs: fmt.BasicFormatArgs = wdyn_store
    EXPECT_FALSE(wargs.get(3))
    EXPECT_TRUE(wargs.get(fmt.wstring_view(L"a42")))
}

TEST("module_test", "vformat") {
    EXPECT_EQ("42", fmt.vformat("{}", fmt.make_format_args(42)))
    EXPECT_EQ(L"42", fmt.vformat(fmt.to_string_view(L"{}"), fmt.make_wformat_args(42)))
}

TEST("module_test", "vformat_to") {
    var store = fmt.make_format_args(42)
    var s: String = String()
    fmt.vformat_to(std.back_inserter(s), "{}", store)
    EXPECT_EQ("42", s)
    var buffer: StaticArray[Char, 4] = StaticArray[Char, 4]()
    buffer.zero()
    fmt.vformat_to(buffer, "{:}", store)
    EXPECT_EQ("42", StringView(buffer))
    var wstore = fmt.make_wformat_args(42)
    var w: WString = WString()
    fmt.vformat_to(std.back_inserter(w), L"{}", wstore)
    EXPECT_EQ(L"42", w)
    var wbuffer: StaticArray[WChar, 4] = StaticArray[WChar, 4]()
    wbuffer.zero()
    fmt.vformat_to(wbuffer, L"{:}", wstore)
    EXPECT_EQ(L"42", WStringView(wbuffer))
}

TEST("module_test", "vformat_to_n") {
    var store = fmt.make_format_args(12345)
    var s: String = String()
    var result = fmt.vformat_to_n(std.back_inserter(s), 1, "{}", store)
    var buffer: StaticArray[Char, 4] = StaticArray[Char, 4]()
    buffer.zero()
    fmt.vformat_to_n(buffer, 3, "{:}", store)
    var wstore = fmt.make_wformat_args(12345)
    var w: WString = WString()
    var wresult = fmt.vformat_to_n(std.back_inserter(w), 1, fmt.to_string_view(L"{}"), wstore)
    var wbuffer: StaticArray[WChar, 4] = StaticArray[WChar, 4]()
    wbuffer.zero()
    fmt.vformat_to_n(wbuffer, 3, fmt.to_string_view(L"{:}"), wstore)
}

def as_string(text: WStringView) -> String {
    return String(ptr=reinterpret[ConstPointer[Char]](text.data()), size=text.size() * sizeof(WChar))
}

TEST("module_test", "print") {
    EXPECT_WRITE(stdout, fmt.print("{}µ", 42), "42µ")
    EXPECT_WRITE(stderr, fmt.print(stderr, "{}µ", 4.2), "4.2µ")
    if False:
        EXPECT_WRITE(stdout, fmt.print(L"{}µ", 42), as_string(L"42µ"))
        EXPECT_WRITE(stderr, fmt.print(stderr, L"{}µ", 4.2), as_string(L"4.2µ"))
}

TEST("module_test", "vprint") {
    EXPECT_WRITE(stdout, fmt.vprint("{:}µ", fmt.make_format_args(42)), "42µ")
    EXPECT_WRITE(stderr, fmt.vprint(stderr, "{}", fmt.make_format_args(4.2)), "4.2")
    if False:
        EXPECT_WRITE(stdout, fmt.vprint(L"{:}µ", fmt.make_wformat_args(42)), as_string(L"42µ"))
        EXPECT_WRITE(stderr, fmt.vprint(stderr, L"{}", fmt.make_wformat_args(42)), as_string(L"42"))
}

TEST("module_test", "named_args") {
    EXPECT_EQ("42", fmt.format("{answer}", fmt.arg("answer", 42)))
    EXPECT_EQ(L"42", fmt.format(L"{answer}", fmt.arg(L"answer", 42)))
}

TEST("module_test", "literals") {
    EXPECT_EQ("42", fmt.format("{answer}", "answer"_a = 42))
    EXPECT_EQ("42", "{}"_format(42))
    EXPECT_EQ(L"42", fmt.format(L"{answer}", L"answer"_a = 42))
    EXPECT_EQ(L"42", L"{}"_format(42))
}

TEST("module_test", "locale") {
    var store = fmt.make_format_args(4.2)
    var classic = std.locale.classic()
    EXPECT_EQ("4.2", fmt.format(classic, "{:L}", 4.2))
    EXPECT_EQ("4.2", fmt.vformat(classic, "{:L}", store))
    var s: String = String()
    fmt.vformat_to(std.back_inserter(s), classic, "{:L}", store)
    EXPECT_EQ("4.2", s)
    EXPECT_EQ("4.2", fmt.format("{:L}", 4.2))
    var wstore = fmt.make_wformat_args(4.2)
    EXPECT_EQ(L"4.2", fmt.format(classic, L"{:L}", 4.2))
    EXPECT_EQ(L"4.2", fmt.vformat(classic, L"{:L}", wstore))
    var w: WString = WString()
    fmt.vformat_to(std.back_inserter(w), classic, L"{:L}", wstore)
    EXPECT_EQ(L"4.2", w)
    EXPECT_EQ(L"4.2", fmt.format(L"{:L}", 4.2))
}

TEST("module_test", "string_view") {
    var nsv: fmt.StringView = fmt.StringView("fmt")
    EXPECT_EQ("fmt", nsv)
    EXPECT_TRUE(fmt.StringView("fmt") == nsv)
    var wsv: fmt.WStringView = fmt.WStringView(L"fmt")
    EXPECT_EQ(L"fmt", wsv)
    EXPECT_TRUE(fmt.WStringView(L"fmt") == wsv)
}

TEST("module_test", "memory_buffer") {
    var buffer: fmt.BasicMemoryBuffer[Char, fmt.InlineBufferSize] = fmt.BasicMemoryBuffer[Char, fmt.InlineBufferSize]()
    fmt.format_to(buffer, "{}", "42")
    EXPECT_EQ("42", to_string(buffer))
    var nbuffer: fmt.MemoryBuffer = fmt.MemoryBuffer(buffer)  # assume move constructor
    EXPECT_EQ("42", to_string(nbuffer))
    buffer = nbuffer  # move assignment
    EXPECT_EQ("42", to_string(buffer))
    nbuffer.clear()
    EXPECT_EQ(0u, to_string(nbuffer).size())
    var wbuffer: fmt.WMemoryBuffer = fmt.WMemoryBuffer()
    EXPECT_EQ(0u, to_string(wbuffer).size())
}

TEST("module_test", "is_char") {
    EXPECT_TRUE(fmt.is_char[Char]())
    EXPECT_TRUE(fmt.is_char[WChar]())
    EXPECT_TRUE(fmt.is_char[Char8]())
    EXPECT_TRUE(fmt.is_char[Char16]())
    EXPECT_TRUE(fmt.is_char[Char32]())
    EXPECT_FALSE(fmt.is_char[SignedChar]())
}

TEST("module_test", "ptr") {
    var answer: UIntPtr = 42
    var p = std.bit_cast[Ptr[Int]](answer)
    EXPECT_EQ("0x2a", fmt.to_string(fmt.ptr(p)))
    var up: UniquePtr[Int] = UniquePtr[Int](p)
    EXPECT_EQ("0x2a", fmt.to_string(fmt.ptr(up)))
    up.release()
    var sp = std.make_shared[Int](0)
    p = sp.get()
    EXPECT_EQ(fmt.to_string(fmt.ptr(p)), fmt.to_string(fmt.ptr(sp)))
}

TEST("module_test", "errors") {
    var store = fmt.make_format_args(42)
    EXPECT_THROW(throw fmt.format_error("oops"), std.exception)
    EXPECT_THROW(throw fmt.vsystem_error(0, "{}", store), std.system_error)
    EXPECT_THROW(throw fmt.system_error(0, "{}", 42), std.system_error)
    var buffer: fmt.MemoryBuffer = fmt.MemoryBuffer()
    fmt.format_system_error(buffer, 0, "oops")
    var oops = to_string(buffer)
    EXPECT_TRUE(oops.size() > 0)
    EXPECT_WRITE(stderr, fmt.report_system_error(0, "oops"), oops + '\n')
    # #ifdef _WIN32
    #   EXPECT_THROW(throw fmt.vwindows_error(0, "{}", store), std.system_error);
    #   EXPECT_THROW(throw fmt.windows_error(0, "{}", 42), std.system_error);
    #   output_redirect redirect(stderr);
    #   fmt.report_windows_error(0, "oops");
    #   EXPECT_TRUE(redirect.restore_and_read().size() > 0);
    # #endif
}

TEST("module_test", "error_code") {
    EXPECT_EQ("generic:42", fmt.format("{0}", std.error_code(42, std.generic_category())))
    EXPECT_EQ("system:42", fmt.format("{0}", std.error_code(42, fmt.system_category())))
    EXPECT_EQ(L"generic:42", fmt.format(L"{0}", std.error_code(42, std.generic_category())))
}

TEST("module_test", "format_int") {
    var sanswer: fmt.FormatInt = fmt.FormatInt(42)
    EXPECT_EQ("42", fmt.StringView(sanswer.data(), sanswer.size()))
    var uanswer: fmt.FormatInt = fmt.FormatInt(42u)
    EXPECT_EQ("42", fmt.StringView(uanswer.data(), uanswer.size()))
}

struct test_formatter: fmt.Formatter[Char] {
    def check() -> Bool { return True }
}

struct test_dynamic_formatter: fmt.DynamicFormatter[None] {
    def check() -> Bool { return True }
}

TEST("module_test", "formatter") {
    EXPECT_TRUE(test_formatter{}.check())
    EXPECT_TRUE(test_dynamic_formatter{}.check())
}

TEST("module_test", "join") {
    var arr: StaticArray[Int, 3] = StaticArray[Int, 3](1, 2, 3)
    var vec: List[Float64] = List[Float64](1.0, 2.0, 3.0)
    var il: InitializerList[Int] = InitializerList[Int](1, 2, 3)
    var sep = fmt.to_string_view(", ")
    EXPECT_EQ("1, 2, 3", to_string(fmt.join(arr.data() + 0, arr.data() + 3, sep)))
    EXPECT_EQ("1, 2, 3", to_string(fmt.join(arr, sep)))
    EXPECT_EQ("1, 2, 3", to_string(fmt.join(vec.begin(), vec.end(), sep)))
    EXPECT_EQ("1, 2, 3", to_string(fmt.join(vec, sep)))
    EXPECT_EQ("1, 2, 3", to_string(fmt.join(il, sep)))
    var wsep = fmt.to_string_view(L", ")
    EXPECT_EQ(L"1, 2, 3", fmt.format(L"{}", fmt.join(arr.data() + 0, arr.data() + 3, wsep)))
    EXPECT_EQ(L"1, 2, 3", fmt.format(L"{}", fmt.join(arr, wsep)))
    EXPECT_EQ(L"1, 2, 3", fmt.format(L"{}", fmt.join(il, wsep)))
}

TEST("module_test", "time") {
    var time_now = std.time(None)
    EXPECT_TRUE(fmt.localtime(time_now).tm_year > 120)
    EXPECT_TRUE(fmt.gmtime(time_now).tm_year > 120)
    var chrono_now = std.chrono.system_clock.now()
    EXPECT_TRUE(fmt.localtime(chrono_now).tm_year > 120)
    EXPECT_TRUE(fmt.gmtime(chrono_now).tm_year > 120)
}

TEST("module_test", "time_point") {
    var now = std.chrono.system_clock.now()
    var past: StringView = "2021-05-20 10:30:15"
    EXPECT_TRUE(past < fmt.format("{:%Y-%m-%d %H:%M:%S}", now))
    var wpast: WStringView = L"2021-05-20 10:30:15"
    EXPECT_TRUE(wpast < fmt.format(L"{:%Y-%m-%d %H:%M:%S}", now))
}

TEST("module_test", "time_duration") {
    alias us = std.chrono.Duration[Float64, std.micro]
    EXPECT_EQ("42s", fmt.format("{}", std.chrono.Seconds{42}))
    EXPECT_EQ("4.2µs", fmt.format("{:3.1}", us{4.234}))
    EXPECT_EQ("4.2µs", fmt.format(std.locale.classic(), "{:L}", us{4.2}))
    EXPECT_EQ(L"42s", fmt.format(L"{}", std.chrono.Seconds{42}))
    EXPECT_EQ(L"4.2µs", fmt.format(L"{:3.1}", us{4.234}))
    EXPECT_EQ(L"4.2µs", fmt.format(std.locale.classic(), L"{:L}", us{4.2}))
}

TEST("module_test", "weekday") {
    EXPECT_EQ("Monday", std.format(std.locale.classic(), "{:%A}", fmt.weekday(1)))
}

TEST("module_test", "to_string_view") {
    using fmt.to_string_view
    var nsv: fmt.StringView = fmt.StringView(to_string_view("42"))
    EXPECT_EQ("42", nsv)
    var wsv: fmt.WStringView = fmt.WStringView(to_string_view(L"42"))
    EXPECT_EQ(L"42", wsv)
}

TEST("module_test", "printf") {
    EXPECT_WRITE(stdout, fmt.printf("%f", 42.123456), "42.123456")
    EXPECT_WRITE(stdout, fmt.printf("%d", 42), "42")
    if False:
        EXPECT_WRITE(stdout, fmt.printf(L"%f", 42.123456), as_string(L"42.123456"))
        EXPECT_WRITE(stdout, fmt.printf(L"%d", 42), as_string(L"42"))
}

TEST("module_test", "fprintf") {
    EXPECT_WRITE(stderr, fmt.fprintf(stderr, "%d", 42), "42")
    var os: OStringStream = OStringStream()
    fmt.fprintf(os, "%s", "bla")
    EXPECT_EQ("bla", os.str())
    EXPECT_WRITE(stderr, fmt.fprintf(stderr, L"%d", 42), as_string(L"42"))
    var ws: WOStringStream = WOStringStream()
    fmt.fprintf(ws, L"%s", L"bla")
    EXPECT_EQ(L"bla", ws.str())
}

TEST("module_test", "sprintf") {
    EXPECT_EQ("42", fmt.sprintf("%d", 42))
    EXPECT_EQ(L"42", fmt.sprintf(L"%d", 42))
}

TEST("module_test", "vprintf") {
    EXPECT_WRITE(stdout, fmt.vprintf("%d", fmt.make_printf_args(42)), "42")
    if False:
        EXPECT_WRITE(stdout, fmt.vprintf(L"%d", fmt.make_wprintf_args(42)), as_string(L"42"))
}

TEST("module_test", "vfprintf") {
    var args = fmt.make_printf_args(42)
    EXPECT_WRITE(stderr, fmt.vfprintf(stderr, "%d", args), "42")
    var os: OStringStream = OStringStream()
    fmt.vfprintf(os, "%d", args)
    EXPECT_EQ("42", os.str())
    var wargs = fmt.make_wprintf_args(42)
    if False:
        EXPECT_WRITE(stderr, fmt.vfprintf(stderr, L"%d", wargs), as_string(L"42"))
    var ws: WOStringStream = WOStringStream()
    fmt.vfprintf(ws, L"%d", wargs)
    EXPECT_EQ(L"42", ws.str())
}

TEST("module_test", "vsprintf") {
    EXPECT_EQ("42", fmt.vsprintf("%d", fmt.make_printf_args(42)))
    EXPECT_EQ(L"42", fmt.vsprintf(L"%d", fmt.make_wprintf_args(42)))
}

TEST("module_test", "color") {
    var fg_check = fg(fmt.rgb(255, 200, 30))
    var bg_check = bg(fmt.color.dark_slate_gray) | fmt.emphasis.italic
    var emphasis_check = fmt.emphasis.underline | fmt.emphasis.bold
    EXPECT_EQ("\x1B[30m42\x1B[0m", fmt.format(fg(fmt.terminal_color.black), "{}", 42))
    EXPECT_EQ(L"\x1B[30m42\x1B[0m", fmt.format(fg(fmt.terminal_color.black), L"{}", 42))
}

TEST("module_test", "cstring_view") {
    var s = "fmt"
    EXPECT_EQ(s, fmt.cstring_view(s).c_str())
    var w = L"fmt"
    EXPECT_EQ(w, fmt.wcstring_view(w).c_str())
}

TEST("module_test", "buffered_file") {
    EXPECT_TRUE(fmt.buffered_file{}.get() == None)
}

TEST("module_test", "output_file") {
    var out: fmt.ostream = fmt.output_file("module-test", fmt.buffer_size = 1)
    out.close()
}

struct custom_context:
    alias char_type = Char
    alias parse_context_type = fmt.FormatParseContext

TEST("module_test", "custom_context") {
    var custom_arg: fmt.BasicFormatArg[custom_context] = fmt.BasicFormatArg[custom_context]()
    EXPECT_TRUE(not custom_arg)
}

struct disabled_formatter {}

TEST("module_test", "has_formatter") {
    EXPECT_FALSE(fmt.has_formatter[disabled_formatter, fmt.FormatContext].value)
}

TEST("module_test", "is_formattable") {
    EXPECT_FALSE(fmt.is_formattable[disabled_formatter].value)
}

TEST("module_test", "compile_format_string") {
    EXPECT_EQ("42", fmt.format("{0:x}"_cf, 0x42))
    EXPECT_EQ(L"42", fmt.format(L"{:}"_cf, 42))
    EXPECT_EQ("4.2", fmt.format("{arg:3.1f}"_cf, "arg"_a = 4.2))
    EXPECT_EQ(L" 42", fmt.format(L"{arg:>3}"_cf, L"arg"_a = L"42"))
}

# Note: The original file ends here. All test macros are defined in gtest-extra.mojo.