from fmt.compile import *
from fmt.chrono import *
from gmock.gmock import *
from gtest-extra import *
from memory import UnsafePointer
from sys import int_type
from time import Time

def test_iterator_test_counting_iterator():
  var it = fmt.detail.counting_iterator()
  var prev = it++
  EXPECT_EQ(prev.count(), 0)
  EXPECT_EQ(it.count(), 1)
  EXPECT_EQ((it + 41).count(), 42)

def test_iterator_test_truncating_iterator():
  var p: UnsafePointer[char] = UnsafePointer[char]()
  var it = fmt.detail.truncating_iterator[UnsafePointer[char]](p, 3)
  var prev = it++
  EXPECT_EQ(prev.base(), p)
  EXPECT_EQ(it.base(), p + 1)

def test_iterator_test_truncating_iterator_default_construct():
  var it = fmt.detail.truncating_iterator[UnsafePointer[char]]()
  EXPECT_EQ(None, it.base())
  EXPECT_EQ(UInt(0), it.count())

def test_iterator_test_truncating_back_inserter():
  var buffer = String()
  var bi = std.back_inserter(buffer)
  var it = fmt.detail.truncating_iterator[decltype(bi)](bi, 2)
  *it++ = '4'
  *it++ = '2'
  *it++ = '1'
  EXPECT_EQ(buffer.size(), 2)
  EXPECT_EQ(buffer, "42")

def test_compile_test_compile_fallback():
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), 42))

struct test_formattable:

def test_compile_test_format_default():
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), 42))
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), 42u))
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), 42ll))
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), 42ull))
  EXPECT_EQ("true", fmt.format(FMT_COMPILE("{}"), true))
  EXPECT_EQ("x", fmt.format(FMT_COMPILE("{}"), 'x'))
  EXPECT_EQ("4.2", fmt.format(FMT_COMPILE("{}"), 4.2))
  EXPECT_EQ("foo", fmt.format(FMT_COMPILE("{}"), "foo"))
  EXPECT_EQ("foo", fmt.format(FMT_COMPILE("{}"), String("foo")))
  EXPECT_EQ("foo", fmt.format(FMT_COMPILE("{}"), test_formattable()))
  var t = std.chrono.system_clock.now()
  EXPECT_EQ(fmt.format("{}", t), fmt.format(FMT_COMPILE("{}"), t))

def test_compile_test_format_wide_string():
  EXPECT_EQ(L"42", fmt.format(FMT_COMPILE(L"{}"), 42))

def test_compile_test_format_specs():
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{:x}"), 0x42))
  EXPECT_EQ("1.2 ms ",
            fmt.format(FMT_COMPILE("{:7.1%Q %q}"),
                        std.chrono.duration[float64, std.milli](1.234)))

def test_compile_test_dynamic_format_specs():
  EXPECT_EQ("foo  ", fmt.format(FMT_COMPILE("{:{}}"), "foo", 5))
  EXPECT_EQ("  3.14", fmt.format(FMT_COMPILE("{:{}.{}f}"), 3.141592, 6, 2))
  EXPECT_EQ(
      "=1.234ms=",
      fmt.format(FMT_COMPILE("{:=^{}.{}}"),
                  std.chrono.duration[float64, std.milli](1.234), 9, 3))

def test_compile_test_manual_ordering():
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{0}"), 42))
  EXPECT_EQ(" -42", fmt.format(FMT_COMPILE("{0:4}"), -42))
  EXPECT_EQ("41 43", fmt.format(FMT_COMPILE("{0} {1}"), 41, 43))
  EXPECT_EQ("41 43", fmt.format(FMT_COMPILE("{1} {0}"), 43, 41))
  EXPECT_EQ("41 43", fmt.format(FMT_COMPILE("{0} {2}"), 41, 42, 43))
  EXPECT_EQ("  41   43", fmt.format(FMT_COMPILE("{1:{2}} {0:4}"), 43, 41, 4))
  EXPECT_EQ("42 1.2 ms ",
            fmt.format(FMT_COMPILE("{0} {1:7.1%Q %q}"), 42,
                        std.chrono.duration[float64, std.milli](1.234)))
  EXPECT_EQ(
      "true 42 42 foo 0x1234 foo",
      fmt.format(FMT_COMPILE("{0} {1} {2} {3} {4} {5}"), true, 42, 42.0f,
                  "foo", reinterpret_cast[UnsafePointer[Void]](0x1234), test_formattable()))
  EXPECT_EQ(L"42", fmt.format(FMT_COMPILE(L"{0}"), 42))

def test_compile_test_named():
  var runtime_named_field_compiled =
      fmt.detail.compile[decltype(fmt.arg("arg", 42))](FMT_COMPILE("{arg}"))
  EXPECT_EQ("42", fmt.format(FMT_COMPILE("{}"), fmt.arg("arg", 42)))
  EXPECT_EQ("41 43", fmt.format(FMT_COMPILE("{} {}"), fmt.arg("arg", 41),
                                 fmt.arg("arg", 43)))
  EXPECT_EQ("foobar",
            fmt.format(FMT_COMPILE("{a0}{a1}"), fmt.arg("a0", "foo"),
                        fmt.arg("a1", "bar")))
  EXPECT_EQ("foobar", fmt.format(FMT_COMPILE("{}{a1}"), fmt.arg("a0", "foo"),
                                  fmt.arg("a1", "bar")))
  EXPECT_EQ("foofoo", fmt.format(FMT_COMPILE("{a0}{}"), fmt.arg("a0", "foo"),
                                  fmt.arg("a1", "bar")))
  EXPECT_EQ("foobar", fmt.format(FMT_COMPILE("{0}{a1}"), fmt.arg("a0", "foo"),
                                  fmt.arg("a1", "bar")))
  EXPECT_EQ("foobar", fmt.format(FMT_COMPILE("{a0}{1}"), fmt.arg("a0", "foo"),
                                  fmt.arg("a1", "bar")))
  EXPECT_EQ("foobar",
            fmt.format(FMT_COMPILE("{}{a1}"), "foo", fmt.arg("a1", "bar")))
  EXPECT_EQ("foobar",
            fmt.format(FMT_COMPILE("{a0}{a1}"), fmt.arg("a1", "bar"),
                        fmt.arg("a2", "baz"), fmt.arg("a0", "foo")))
  EXPECT_EQ(" bar foo ",
            fmt.format(FMT_COMPILE(" {foo} {bar} "), fmt.arg("foo", "bar"),
                        fmt.arg("bar", "foo")))
  EXPECT_THROW(fmt.format(FMT_COMPILE("{invalid}"), fmt.arg("valid", 42)),
               fmt.format_error)

def test_compile_test_format_to():
  var buf = UnsafePointer[char].alloc(8)
  var end = fmt.format_to(buf, FMT_COMPILE("{}"), 42)
  *end = '\0'
  EXPECT_STREQ("42", buf)
  end = fmt.format_to(buf, FMT_COMPILE("{:x}"), 42)
  *end = '\0'
  EXPECT_STREQ("2a", buf)
  buf.free()

def test_compile_test_format_to_n():
  var buffer_size = 8
  var buffer = UnsafePointer[char].alloc(buffer_size)
  var res = fmt.format_to_n(buffer, buffer_size, FMT_COMPILE("{}"), 42)
  *res.out = '\0'
  EXPECT_STREQ("42", buffer)
  res = fmt.format_to_n(buffer, buffer_size, FMT_COMPILE("{:x}"), 42)
  *res.out = '\0'
  EXPECT_STREQ("2a", buffer)
  buffer.free()

def test_compile_test_formatted_size():
  EXPECT_EQ(2, fmt.formatted_size(FMT_COMPILE("{0}"), 42))
  EXPECT_EQ(5, fmt.formatted_size(FMT_COMPILE("{0:<4.2f}"), 42.0))

def test_compile_test_text_and_arg():
  EXPECT_EQ(">>>42<<<", fmt.format(FMT_COMPILE(">>>{}<<<"), 42))
  EXPECT_EQ("42!", fmt.format(FMT_COMPILE("{}!"), 42))

def test_compile_test_unknown_format_fallback():
  EXPECT_EQ(" 42 ",
            fmt.format(FMT_COMPILE("{name:^4}"), fmt.arg("name", 42)))
  var v = List[char]()
  fmt.format_to(std.back_inserter(v), FMT_COMPILE("{name:^4}"),
                 fmt.arg("name", 42))
  EXPECT_EQ(" 42 ", fmt.string_view(v.data(), v.size()))
  var buffer = UnsafePointer[char].alloc(4)
  var result = fmt.format_to_n(buffer, 4, FMT_COMPILE("{name:^5}"),
                                 fmt.arg("name", 42))
  EXPECT_EQ(5u, result.size)
  EXPECT_EQ(buffer + 4, result.out)
  EXPECT_EQ(" 42 ", fmt.string_view(buffer, 4))
  buffer.free()

def test_compile_test_empty():
  EXPECT_EQ("", fmt.format(FMT_COMPILE("")))

struct to_stringable:

def test_compile_test_to_string_and_formatter():
  fmt.format(FMT_COMPILE("{}"), to_stringable())

def test_compile_test_print():
  EXPECT_WRITE(stdout, fmt.print(FMT_COMPILE("Don't {}!"), "panic"),
               "Don't panic!")
  EXPECT_WRITE(stderr, fmt.print(stderr, FMT_COMPILE("Don't {}!"), "panic"),
               "Don't panic!")

def test_compile_test_compile_format_string_literal():
  EXPECT_EQ("", fmt.format(""_cf))
  EXPECT_EQ("42", fmt.format("{}"_cf, 42))
  EXPECT_EQ(L"42", fmt.format(L"{}"_cf, 42))

struct test_string[max_string_length: Int, Char: type = char]:
  var buffer: StaticArray[Char, max_string_length]

  def __eq__[T: type](self, rhs: T) -> Bool:
    return fmt.basic_string_view[Char](rhs).compare(self.buffer) == 0

def test_format[max_string_length: Int, Char: type = char, *Args: type](format: String, args: *Args) -> test_string[max_string_length, Char]:
  var string = test_string[max_string_length, Char]()
  fmt.format_to(string.buffer, format, *args)
  return string

def test_compile_time_formatting_test_bool():
  EXPECT_EQ("true", test_format[5](FMT_COMPILE("{}"), true))
  EXPECT_EQ("false", test_format[6](FMT_COMPILE("{}"), false))
  EXPECT_EQ("true ", test_format[6](FMT_COMPILE("{:5}"), true))
  EXPECT_EQ("1", test_format[2](FMT_COMPILE("{:d}"), true))

def test_compile_time_formatting_test_integer():
  EXPECT_EQ("42", test_format[3](FMT_COMPILE("{}"), 42))
  EXPECT_EQ("420", test_format[4](FMT_COMPILE("{}"), 420))
  EXPECT_EQ("42 42", test_format[6](FMT_COMPILE("{} {}"), 42, 42))
  EXPECT_EQ("42 42",
            test_format[6](FMT_COMPILE("{} {}"), uint32{42}, uint64{42}))
  EXPECT_EQ("+42", test_format[4](FMT_COMPILE("{:+}"), 42))
  EXPECT_EQ("42", test_format[3](FMT_COMPILE("{:-}"), 42))
  EXPECT_EQ(" 42", test_format[4](FMT_COMPILE("{: }"), 42))
  EXPECT_EQ("-0042", test_format[6](FMT_COMPILE("{:05}"), -42))
  EXPECT_EQ("101010", test_format[7](FMT_COMPILE("{:b}"), 42))
  EXPECT_EQ("0b101010", test_format[9](FMT_COMPILE("{:#b}"), 42))
  EXPECT_EQ("0B101010", test_format[9](FMT_COMPILE("{:#B}"), 42))
  EXPECT_EQ("042", test_format[4](FMT_COMPILE("{:#o}"), 042))
  EXPECT_EQ("0x4a", test_format[5](FMT_COMPILE("{:#x}"), 0x4a))
  EXPECT_EQ("0X4A", test_format[5](FMT_COMPILE("{:#X}"), 0x4a))
  EXPECT_EQ("   42", test_format[6](FMT_COMPILE("{:5}"), 42))
  EXPECT_EQ("   42", test_format[6](FMT_COMPILE("{:5}"), 42ll))
  EXPECT_EQ("   42", test_format[6](FMT_COMPILE("{:5}"), 42ull))
  EXPECT_EQ("42  ", test_format[5](FMT_COMPILE("{:<4}"), 42))
  EXPECT_EQ("  42", test_format[5](FMT_COMPILE("{:>4}"), 42))
  EXPECT_EQ(" 42 ", test_format[5](FMT_COMPILE("{:^4}"), 42))
  EXPECT_EQ("**-42", test_format[6](FMT_COMPILE("{:*>5}"), -42))

def test_compile_time_formatting_test_char():
  EXPECT_EQ("c", test_format[2](FMT_COMPILE("{}"), 'c'))
  EXPECT_EQ("c  ", test_format[4](FMT_COMPILE("{:3}"), 'c'))
  EXPECT_EQ("99", test_format[3](FMT_COMPILE("{:d}"), 'c'))

def test_compile_time_formatting_test_string():
  EXPECT_EQ("42", test_format[3](FMT_COMPILE("{}"), "42"))
  EXPECT_EQ("The answer is 42",
            test_format[17](FMT_COMPILE("{} is {}"), "The answer", "42"))
  EXPECT_EQ("abc**", test_format[6](FMT_COMPILE("{:*<5}"), "abc"))
  EXPECT_EQ("**🤡**", test_format[9](FMT_COMPILE("{:*^6}"), "🤡"))

def test_compile_time_formatting_test_combination():
  EXPECT_EQ("420, true, answer",
            test_format[18](FMT_COMPILE("{}, {}, {}"), 420, true, "answer"))
  EXPECT_EQ(" -42", test_format[5](FMT_COMPILE("{:{}}"), -42, 4))

def test_compile_time_formatting_test_custom_type():
  EXPECT_EQ("foo", test_format[4](FMT_COMPILE("{}"), test_formattable()))
  EXPECT_EQ("bar", test_format[4](FMT_COMPILE("{:b}"), test_formattable()))

def test_compile_time_formatting_test_multibyte_fill():
  EXPECT_EQ("жж42", test_format[8](FMT_COMPILE("{:ж>4}"), 42))