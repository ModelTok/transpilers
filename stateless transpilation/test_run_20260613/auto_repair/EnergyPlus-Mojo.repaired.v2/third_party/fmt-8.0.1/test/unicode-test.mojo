from testing import *
from fmt.chrono import *
from gmock.gmock import *
from util import get_locale
from memory import String
from os import *
from time import *

using testing.Contains

def test_unicode_test_is_utf8():
    EXPECT_TRUE(fmt.detail.is_utf8())

def test_unicode_test_legacy_locale():
    var loc = get_locale("ru_RU.CP1251", "Russian.1251")
    if loc == std.locale.classic():
        return
    var s = String()
    try:
        s = fmt.format(loc, "День недели: {:L}", fmt.weekday(1))
    except fmt.format_error as e:
        fmt.print("Format error: {}\n", e.what())
        return
    #if !FMT_GCC_VERSION or FMT_GCC_VERSION >= 500
    var os = std.ostringstream()
    os.imbue(loc)
    var tm = std.tm()
    tm.tm_wday = 1
    os << std.put_time(&tm, "%a")
    var wd = os.str()
    if wd == "??":
        EXPECT_EQ(s, "День недели: ??")
        fmt.print("locale gives ?? as a weekday.\n")
        return
    #endif
    EXPECT_THAT((std.vector[std.string]{"День недели: пн", "День недели: Пн"}),
                Contains(s))