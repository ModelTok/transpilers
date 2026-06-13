from fmt.chrono import *
from gtest-extra import EXPECT_THROW_MSG
from util import get_locale
from testing import *

alias runtime = fmt.runtime
alias Contains = testing.Contains

def make_tm() -> std.tm:
    var time = std.tm()
    time.tm_mday = 1
    return time

def make_hour(h: int) -> std.tm:
    var time = make_tm()
    time.tm_hour = h
    return time

def make_minute(m: int) -> std.tm:
    var time = make_tm()
    time.tm_min = m
    return time

def make_second(s: int) -> std.tm:
    var time = make_tm()
    time.tm_sec = s
    return time

def test_format_tm():
    var tm = std.tm()
    tm.tm_year = 116
    tm.tm_mon = 3
    tm.tm_mday = 25
    tm.tm_hour = 11
    tm.tm_min = 22
    tm.tm_sec = 33
    EXPECT_EQ(fmt.format("The date is {:%Y-%m-%d %H:%M:%S}.", tm),
              "The date is 2016-04-25 11:22:33.")

def test_grow_buffer():
    var s = std.string("{:")
    for i in range(30):
        s += "%c"
    s += "}\n"
    var t = std.time(None)
    fmt.format(fmt.runtime(s), *std.localtime(&t))

def test_format_to_empty_container():
    var time = std.tm()
    time.tm_sec = 42
    var s = std.string()
    fmt.format_to(std.back_inserter(s), "{:%S}", time)
    EXPECT_EQ(s, "42")

def test_empty_result():
    EXPECT_EQ(fmt.format("{}", std.tm()), "")

def equal(lhs: std.tm, rhs: std.tm) -> bool:
    return lhs.tm_sec == rhs.tm_sec and lhs.tm_min == rhs.tm_min and \
           lhs.tm_hour == rhs.tm_hour and lhs.tm_mday == rhs.tm_mday and \
           lhs.tm_mon == rhs.tm_mon and lhs.tm_year == rhs.tm_year and \
           lhs.tm_wday == rhs.tm_wday and lhs.tm_yday == rhs.tm_yday and \
           lhs.tm_isdst == rhs.tm_isdst

def test_localtime():
    var t = std.time(None)
    var tm = *std.localtime(&t)
    EXPECT_TRUE(equal(tm, fmt.localtime(t)))

def test_gmtime():
    var t = std.time(None)
    var tm = *std.gmtime(&t)
    EXPECT_TRUE(equal(tm, fmt.gmtime(t)))

def strftime[TimePoint: AnyType](tp: TimePoint) -> std.string:
    var t = std.chrono.system_clock.to_time_t(tp)
    var tm = *std.localtime(&t)
    var output = std.array[char, 256]()
    std.strftime(output.data, len(output), "%Y-%m-%d %H:%M:%S", &tm)
    return std.string(output.data)

def test_time_point():
    var t1 = std.chrono.system_clock.now()
    EXPECT_EQ(strftime(t1), fmt.format("{:%Y-%m-%d %H:%M:%S}", t1))
    EXPECT_EQ(strftime(t1), fmt.format("{}", t1))
    alias time_point = std.chrono.time_point[std.chrono.system_clock, std.chrono.seconds]
    var t2 = time_point(std.chrono.seconds(42))
    EXPECT_EQ(strftime(t2), fmt.format("{:%Y-%m-%d %H:%M:%S}", t2))

# ifndef FMT_STATIC_THOUSANDS_SEPARATOR
def test_format_default():
    EXPECT_EQ("42s", fmt.format("{}", std.chrono.seconds(42)))
    EXPECT_EQ("42as",
              fmt.format("{}", std.chrono.duration[int, std.atto](42)))
    EXPECT_EQ("42fs",
              fmt.format("{}", std.chrono.duration[int, std.femto](42)))
    EXPECT_EQ("42ps",
              fmt.format("{}", std.chrono.duration[int, std.pico](42)))
    EXPECT_EQ("42ns", fmt.format("{}", std.chrono.nanoseconds(42)))
    EXPECT_EQ("42µs", fmt.format("{}", std.chrono.microseconds(42)))
    EXPECT_EQ("42ms", fmt.format("{}", std.chrono.milliseconds(42)))
    EXPECT_EQ("42cs",
              fmt.format("{}", std.chrono.duration[int, std.centi](42)))
    EXPECT_EQ("42ds",
              fmt.format("{}", std.chrono.duration[int, std.deci](42)))
    EXPECT_EQ("42s", fmt.format("{}", std.chrono.seconds(42)))
    EXPECT_EQ("42das",
              fmt.format("{}", std.chrono.duration[int, std.deca](42)))
    EXPECT_EQ("42hs",
              fmt.format("{}", std.chrono.duration[int, std.hecto](42)))
    EXPECT_EQ("42ks",
              fmt.format("{}", std.chrono.duration[int, std.kilo](42)))
    EXPECT_EQ("42Ms",
              fmt.format("{}", std.chrono.duration[int, std.mega](42)))
    EXPECT_EQ("42Gs",
              fmt.format("{}", std.chrono.duration[int, std.giga](42)))
    EXPECT_EQ("42Ts",
              fmt.format("{}", std.chrono.duration[int, std.tera](42)))
    EXPECT_EQ("42Ps",
              fmt.format("{}", std.chrono.duration[int, std.peta](42)))
    EXPECT_EQ("42Es",
              fmt.format("{}", std.chrono.duration[int, std.exa](42)))
    EXPECT_EQ("42m", fmt.format("{}", std.chrono.minutes(42)))
    EXPECT_EQ("42h", fmt.format("{}", std.chrono.hours(42)))
    EXPECT_EQ(
        "42[15]s",
        fmt.format("{}", std.chrono.duration[int, std.ratio[15, 1]](42)))
    EXPECT_EQ(
        "42[15/4]s",
        fmt.format("{}", std.chrono.duration[int, std.ratio[15, 4]](42)))

def test_align():
    var s = std.chrono.seconds(42)
    EXPECT_EQ("42s  ", fmt.format("{:5}", s))
    EXPECT_EQ("42s  ", fmt.format("{:{}}", s, 5))
    EXPECT_EQ("  42s", fmt.format("{:>5}", s))
    EXPECT_EQ("**42s**", fmt.format("{:*^7}", s))
    EXPECT_EQ("03:25:45    ",
              fmt.format("{:12%H:%M:%S}", std.chrono.seconds(12345)))
    EXPECT_EQ("    03:25:45",
              fmt.format("{:>12%H:%M:%S}", std.chrono.seconds(12345)))
    EXPECT_EQ("~~03:25:45~~",
              fmt.format("{:~^12%H:%M:%S}", std.chrono.seconds(12345)))
    EXPECT_EQ("03:25:45    ",
              fmt.format("{:{}%H:%M:%S}", std.chrono.seconds(12345), 12))

def test_format_specs():
    EXPECT_EQ("%", fmt.format("{:%%}", std.chrono.seconds(0)))
    EXPECT_EQ("\n", fmt.format("{:%n}", std.chrono.seconds(0)))
    EXPECT_EQ("\t", fmt.format("{:%t}", std.chrono.seconds(0)))
    EXPECT_EQ("00", fmt.format("{:%S}", std.chrono.seconds(0)))
    EXPECT_EQ("00", fmt.format("{:%S}", std.chrono.seconds(60)))
    EXPECT_EQ("42", fmt.format("{:%S}", std.chrono.seconds(42)))
    EXPECT_EQ("01.234", fmt.format("{:%S}", std.chrono.milliseconds(1234)))
    EXPECT_EQ("00", fmt.format("{:%M}", std.chrono.minutes(0)))
    EXPECT_EQ("00", fmt.format("{:%M}", std.chrono.minutes(60)))
    EXPECT_EQ("42", fmt.format("{:%M}", std.chrono.minutes(42)))
    EXPECT_EQ("01", fmt.format("{:%M}", std.chrono.seconds(61)))
    EXPECT_EQ("00", fmt.format("{:%H}", std.chrono.hours(0)))
    EXPECT_EQ("00", fmt.format("{:%H}", std.chrono.hours(24)))
    EXPECT_EQ("14", fmt.format("{:%H}", std.chrono.hours(14)))
    EXPECT_EQ("01", fmt.format("{:%H}", std.chrono.minutes(61)))
    EXPECT_EQ("12", fmt.format("{:%I}", std.chrono.hours(0)))
    EXPECT_EQ("12", fmt.format("{:%I}", std.chrono.hours(12)))
    EXPECT_EQ("12", fmt.format("{:%I}", std.chrono.hours(24)))
    EXPECT_EQ("04", fmt.format("{:%I}", std.chrono.hours(4)))
    EXPECT_EQ("02", fmt.format("{:%I}", std.chrono.hours(14)))
    EXPECT_EQ("03:25:45",
              fmt.format("{:%H:%M:%S}", std.chrono.seconds(12345)))
    EXPECT_EQ("03:25", fmt.format("{:%R}", std.chrono.seconds(12345)))
    EXPECT_EQ("03:25:45", fmt.format("{:%T}", std.chrono.seconds(12345)))
    EXPECT_EQ("12345", fmt.format("{:%Q}", std.chrono.seconds(12345)))
    EXPECT_EQ("s", fmt.format("{:%q}", std.chrono.seconds(12345)))

def test_invalid_specs():
    var sec = std.chrono.seconds(0)
    EXPECT_THROW_MSG(fmt.format(runtime("{:%a}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%A}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%c}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%x}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%Ex}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%X}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%EX}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%D}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%F}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%Ec}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%w}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%u}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%b}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%B}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%z}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%Z}"), sec), fmt.format_error,
                     "no date")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%Eq}"), sec), fmt.format_error,
                     "invalid format")
    EXPECT_THROW_MSG(fmt.format(runtime("{:%Oq}"), sec), fmt.format_error,
                     "invalid format")

def format_tm(time: std.tm, spec: fmt.string_view, loc: std.locale) -> std.string:
    var facet = std.use_facet[std.time_put[char]](loc)
    var os = std.ostringstream()
    os.imbue(loc)
    facet.put(os, os, ' ', &time, spec.begin(), spec.end())
    return os.str()

def test_locale():
    var loc = get_locale("ja_JP.utf8")
    if loc == std.locale.classic():
        return
    # define EXPECT_TIME(spec, time, duration)                     \
    #   {                                                           \
    #     auto jp_loc = locale("ja_JP.utf8");                  \
    #     EXPECT_EQ(format_tm(time, spec, jp_loc),                  \
    #               fmt.format(jp_loc, "{:L" spec "}", duration)); \
    #   }
    EXPECT_TIME("%OH", make_hour(14), std.chrono.hours(14))
    EXPECT_TIME("%OI", make_hour(14), std.chrono.hours(14))
    EXPECT_TIME("%OM", make_minute(42), std.chrono.minutes(42))
    EXPECT_TIME("%OS", make_second(42), std.chrono.seconds(42))
    var time = make_tm()
    time.tm_hour = 3
    time.tm_min = 25
    time.tm_sec = 45
    var sec = std.chrono.seconds(12345)
    EXPECT_TIME("%r", time, sec)
    EXPECT_TIME("%p", time, sec)

alias dms = std.chrono.duration[float64, std.milli]

def test_format_default_fp():
    typedef fs = std.chrono.duration[float32]
    EXPECT_EQ("1.234s", fmt.format("{}", fs(1.234)))
    typedef fms = std.chrono.duration[float32, std.milli]
    EXPECT_EQ("1.234ms", fmt.format("{}", fms(1.234)))
    typedef ds = std.chrono.duration[float64]
    EXPECT_EQ("1.234s", fmt.format("{}", ds(1.234)))
    EXPECT_EQ("1.234ms", fmt.format("{}", dms(1.234)))

def test_format_precision():
    EXPECT_THROW_MSG(fmt.format(runtime("{:.2}"), std.chrono.seconds(42)),
                     fmt.format_error,
                     "precision not allowed for this argument type")
    EXPECT_EQ("1.2ms", fmt.format("{:.1}", dms(1.234)))
    EXPECT_EQ("1.23ms", fmt.format("{:.{}}", dms(1.234), 2))

def test_format_full_specs():
    EXPECT_EQ("1.2ms ", fmt.format("{:6.1}", dms(1.234)))
    EXPECT_EQ("  1.23ms", fmt.format("{:>8.{}}", dms(1.234), 2))
    EXPECT_EQ(" 1.2ms ", fmt.format("{:^{}.{}}", dms(1.234), 7, 1))
    EXPECT_EQ(" 1.23ms ", fmt.format("{0:^{2}.{1}}", dms(1.234), 2, 8))
    EXPECT_EQ("=1.234ms=", fmt.format("{:=^{}.{}}", dms(1.234), 9, 3))
    EXPECT_EQ("*1.2340ms*", fmt.format("{:*^10.4}", dms(1.234)))

def test_format_simple_q():
    typedef fs = std.chrono.duration[float32]
    EXPECT_EQ("1.234 s", fmt.format("{:%Q %q}", fs(1.234)))
    typedef fms = std.chrono.duration[float32, std.milli]
    EXPECT_EQ("1.234 ms", fmt.format("{:%Q %q}", fms(1.234)))
    typedef ds = std.chrono.duration[float64]
    EXPECT_EQ("1.234 s", fmt.format("{:%Q %q}", ds(1.234)))
    EXPECT_EQ("1.234 ms", fmt.format("{:%Q %q}", dms(1.234)))

def test_format_precision_q():
    EXPECT_THROW_MSG(fmt.format(runtime("{:.2%Q %q}"), std.chrono.seconds(42)),
                     fmt.format_error,
                     "precision not allowed for this argument type")
    EXPECT_EQ("1.2 ms", fmt.format("{:.1%Q %q}", dms(1.234)))
    EXPECT_EQ("1.23 ms", fmt.format("{:.{}%Q %q}", dms(1.234), 2))

def test_format_full_specs_q():
    EXPECT_EQ("1.2 ms ", fmt.format("{:7.1%Q %q}", dms(1.234)))
    EXPECT_EQ(" 1.23 ms", fmt.format("{:>8.{}%Q %q}", dms(1.234), 2))
    EXPECT_EQ(" 1.2 ms ", fmt.format("{:^{}.{}%Q %q}", dms(1.234), 8, 1))
    EXPECT_EQ(" 1.23 ms ", fmt.format("{0:^{2}.{1}%Q %q}", dms(1.234), 2, 9))
    EXPECT_EQ("=1.234 ms=", fmt.format("{:=^{}.{}%Q %q}", dms(1.234), 10, 3))
    EXPECT_EQ("*1.2340 ms*", fmt.format("{:*^11.4%Q %q}", dms(1.234)))

def test_invalid_width_id():
    EXPECT_THROW(fmt.format(runtime("{:{o}"), std.chrono.seconds(0)),
                 fmt.format_error)

def test_invalid_colons():
    EXPECT_THROW(fmt.format(runtime("{0}=:{0::"), std.chrono.seconds(0)),
                 fmt.format_error)

def test_negative_durations():
    EXPECT_EQ("-12345", fmt.format("{:%Q}", std.chrono.seconds(-12345)))
    EXPECT_EQ("-03:25:45",
              fmt.format("{:%H:%M:%S}", std.chrono.seconds(-12345)))
    EXPECT_EQ("-00:01",
              fmt.format("{:%M:%S}", std.chrono.duration[float64](-1)))
    EXPECT_EQ("s", fmt.format("{:%q}", std.chrono.seconds(-12345)))
    EXPECT_EQ("-00.127",
              fmt.format("{:%S}",
                          std.chrono.duration[signed char, std.milli](-127)))
    var min = std.numeric_limits[int].min()
    EXPECT_EQ(fmt.format("{}", min),
              fmt.format("{:%Q}", std.chrono.duration[int](min)))

def test_special_durations():
    EXPECT_EQ(
        "40.",
        fmt.format("{:%S}", std.chrono.duration[float64](1e20)).substr(0, 3))
    var nan = std.numeric_limits[float64].quiet_NaN()
    EXPECT_EQ(
        "nan nan nan nan nan:nan nan",
        fmt.format("{:%I %H %M %S %R %r}", std.chrono.duration[float64](nan)))
    fmt.format("{:%S}",
                std.chrono.duration[float32, std.atto](1.79400457e+31f))
    EXPECT_EQ(fmt.format("{}", std.chrono.duration[float32, std.exa](1)),
              "1Es")
    EXPECT_EQ(fmt.format("{}", std.chrono.duration[float32, std.atto](1)),
              "1as")
    EXPECT_EQ(fmt.format("{:%R}", std.chrono.duration[char, std.mega](2)),
              "03:33")
    EXPECT_EQ(fmt.format("{:%T}", std.chrono.duration[char, std.mega](2)),
              "03:33:20")

def test_unsigned_duration():
    EXPECT_EQ("42s", fmt.format("{}", std.chrono.duration[unsigned int](42)))

def test_weekday():
    var loc = get_locale("ru_RU.UTF-8")
    std.locale.global(loc)
    var mon = fmt.weekday(1)
    EXPECT_EQ(fmt.format("{}", mon), "Mon")
    if loc != std.locale.classic():
        EXPECT_THAT((std.vector[std.string]{"пн", "Пн", "пнд", "Пнд"}),
                    Contains(fmt.format(loc, "{:L}", mon)))
# endif  // FMT_STATIC_THOUSANDS_SEPARATOR