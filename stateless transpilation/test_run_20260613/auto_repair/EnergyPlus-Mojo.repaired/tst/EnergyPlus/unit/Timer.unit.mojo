from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Timer import Timer
import sys
import time

typealias Real64 = Float64

def EXPECT_GE[T: Comparable](a: T, b: T):
    if a < b:
        raise AssertionError("EXPECT_GE(" + str(a) + ", " + str(b) + ") failed")

def EXPECT_LT[T: Comparable](a: T, b: T):
    if a >= b:
        raise AssertionError("EXPECT_LT(" + str(a) + ", " + str(b) + ") failed")

def EXPECT_EQ[T: Comparable](a: T, b: T):
    if a != b:
        raise AssertionError("EXPECT_EQ(" + str(a) + ", " + str(b) + ") failed")

def ASSERT_THROW(code: fn() raises, exc_type: type = Error):
    try:
        code()
    except exc_type:
        return
    else:
        raise Error("ASSERT_THROW: Expected exception of type " + str(exc_type.__name__))

def Timer_ticktock():
    if sys.getenv("CI") is not None:
        return
    const sleep_time_ms: Int = 100
    const sleep_time_s: Real64 = 0.1
    var t = Timer()
    t.tick()
    time.sleep(sleep_time_ms / 1000.0)
    t.tock()
    EXPECT_GE(t.duration().count(), sleep_time_ms)
    EXPECT_LT(t.duration().count(), sleep_time_ms * 2)
    EXPECT_GE(t.elapsedSeconds(), sleep_time_s)
    EXPECT_LT(t.elapsedSeconds(), sleep_time_s * 2)
    time.sleep(sleep_time_ms / 1000.0)
    t.tick()
    time.sleep(sleep_time_ms / 1000.0)
    t.tock()
    EXPECT_GE(t.duration().count(), sleep_time_ms * 2)
    EXPECT_LT(t.duration().count(), sleep_time_ms * 3)
    EXPECT_GE(t.elapsedSeconds(), sleep_time_s * 2)
    EXPECT_LT(t.elapsedSeconds(), sleep_time_s * 3)

@if not defined("NDEBUG")
def Timer_throw_if_not_stopped():
    var t = Timer()
    ASSERT_THROW(lambda: t.tock(), Error)   # Timer not started
    ASSERT_THROW(lambda: t.duration(), Error) # Timer not stopped
@end

def Timer_formatter():
    {
        var t = Timer()
        t.tick()
        t.m_start = Timer.ClockType.now() - 62 * microsecond
        t.tock()
        EXPECT_EQ("00hr 00min  0.06sec", t.formatAsHourMinSecs())
    }
    {
        var t = Timer()
        t.m_start = Timer.ClockType.now() - (2 * hour + 25 * minute + 51 * second + 341 * millisecond)
        t.tock()
        EXPECT_EQ("02hr 25min 51.34sec", t.formatAsHourMinSecs())
    }
    {
        var t = Timer()
        t.m_start = Timer.ClockType.now() - (13 * hour + 25 * minute + 51 * second + 341 * millisecond)
        t.tock()
        EXPECT_EQ("13hr 25min 51.34sec", t.formatAsHourMinSecs())
    }
    {
        var t = Timer()
        t.m_start = Timer.ClockType.now() - (25 * hour + 25 * minute + 51 * second + 341 * millisecond)
        t.tock()
        EXPECT_EQ("25hr 25min 51.34sec", t.formatAsHourMinSecs())
    }