from ...fmt.chrono import format as fmt_format_chrono, seconds
from ...fmt.color import fg, rgb, text_style, print as fmt_print, format as fmt_format_color
from ...fmt.format import format as fmt_format, to_string, to_wstring, format_to, format_to_n
from ...fmt.ostream import format as fmt_format_ostream
from ...fmt.ranges import format as fmt_format_ranges
from ...fmt.xchar import format as fmt_format_xchar
from std.iterator import back_inserter
from std.chrono import seconds as chrono_seconds

def test_format_api():
    fmt_format("{}", 42)
    fmt_format("{}", 42)
    fmt_format("noop")
    to_string(42)
    to_wstring(42)
    var out = List[Int8]()
    format_to(back_inserter(out), "{}", 42)
    var buffer = Array[Int8](4)
    format_to_n(buffer, 3, "{}", 12345)
    var wbuffer = Array[Int32](4)
    format_to_n(wbuffer, 3, "{}", 12345)

def test_chrono():
    fmt_format("{}", chrono_seconds(42))
    fmt_format("{}", chrono_seconds(42))

def test_text_style():
    fmt_print(fg(rgb(255, 20, 30)), "{}", "rgb(255,20,30)")
    fmt_format_color(fg(rgb(255, 20, 30)), "{}", "rgb(255,20,30)")
    var ts = fg(rgb(255, 20, 30))
    var out = String()
    format_to(back_inserter(out), ts, "rgb(255,20,30){}{}{}", 1, 2, 3)

def test_range():
    var hello = List[Int8]([104, 101, 108, 108, 111])
    fmt_format("{}", hello)

def main():
    test_format_api()
    test_chrono()
    test_text_style()
    test_range()