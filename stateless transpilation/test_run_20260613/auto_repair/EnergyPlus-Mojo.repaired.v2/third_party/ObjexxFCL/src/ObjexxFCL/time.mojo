from time import Array1, Optional, Array1D
from memory import UnsafePointer
from sys import int_type
from math import abs, ceil, log10, pow
from time import time as c_time, localtime, clock as c_clock, sleep as c_sleep
from datetime import datetime, timedelta, timezone
from string import String
from utils import StringRef

# Helper to get current time as tm struct
def _localtime() -> UnsafePointer[TM]:
    let now = c_time()
    return localtime(now)

struct TM:
    var tm_sec: Int32
    var tm_min: Int32
    var tm_hour: Int32
    var tm_mday: Int32
    var tm_mon: Int32
    var tm_year: Int32
    var tm_wday: Int32
    var tm_yday: Int32
    var tm_isdst: Int32

def ITIME(inout timearray: Array1[Int32]):
    assert(timearray.l() <= 1)
    assert(timearray.u() >= 3)
    let current_time = c_time()
    let timeinfo = _localtime()
    timearray[0] = timeinfo[].tm_hour
    timearray[1] = timeinfo[].tm_min
    timearray[2] = timeinfo[].tm_sec

def GETTIM(inout h: Int64, inout m: Int64, inout s: Int64, inout c: Int64):
    let now = datetime.now()
    let ms = now.microsecond // 1000  # milliseconds
    let current_time = c_time()
    let timeinfo = _localtime()
    h = timeinfo[].tm_hour
    m = timeinfo[].tm_min
    s = timeinfo[].tm_sec
    c = ms // 10

def GETTIM(inout h: Int32, inout m: Int32, inout s: Int32, inout c: Int32):
    let now = datetime.now()
    let ms = now.microsecond // 1000
    let current_time = c_time()
    let timeinfo = _localtime()
    h = timeinfo[].tm_hour
    m = timeinfo[].tm_min
    s = timeinfo[].tm_sec
    c = ms // 10

def GETTIM(inout h: Int16, inout m: Int16, inout s: Int16, inout c: Int16):
    let now = datetime.now()
    let ms = now.microsecond // 1000
    let current_time = c_time()
    let timeinfo = _localtime()
    h = timeinfo[].tm_hour
    m = timeinfo[].tm_min
    s = timeinfo[].tm_sec
    c = ms // 10

def TIME() -> Int64:
    let now = datetime.now()
    let epoch = datetime(1970, 1, 1)
    let dur = now - epoch
    return dur.total_seconds()

def TIME(inout time: String):
    let current_time = c_time()
    let timeinfo = _localtime()
    let hh = timeinfo[].tm_hour
    let mm = timeinfo[].tm_min
    let ss = timeinfo[].tm_sec
    var time_stream = String()
    time_stream = String(format("{:02d}:{:02d}:{:02d}", hh, mm, ss))
    time = time_stream

def CLOCK() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let hh = timeinfo[].tm_hour
    let mm = timeinfo[].tm_min
    let ss = timeinfo[].tm_sec
    var time_stream = String()
    time_stream = String(format("{:02d}:{:02d}:{:02d}", hh, mm, ss))
    return time_stream

def SYSTEM_CLOCK(
    count: Optional[Int32] = Optional[Int32](),
    count_rate: Optional[Int32] = Optional[Int32](),
    count_max: Optional[Int32] = Optional[Int32]()
):
    let now = datetime.now()
    let epoch = datetime(1970, 1, 1)
    let dur = now - epoch
    var count_64: Int64 = dur.total_seconds()
    var count_rate_64: Int64 = 1  # system_clock::period::den / period::num = 1 for seconds
    var count_max_64: Int64 = 9223372036854775807  # duration::max().count() approximation
    var mult: Int64 = count_rate_64 // 2147483647  # numeric_limits<Int32>::max()
    if mult > 0:
        mult = Int64(pow(10.0, ceil(log10(Float64(mult)))))
        count_64 //= mult
        count_rate_64 //= mult
        count_max_64 //= mult
    mult = count_max_64 // 2147483647
    if mult > 0:
        mult = Int64(pow(10.0, ceil(log10(Float64(mult)))))
        count_max_64 //= mult
        count_64 %= count_max_64
    if count.present():
        count = count_64
    if count_rate.present():
        count_rate = count_rate_64
    if count_max.present():
        count_max = count_max_64

def CPU_TIME(inout time: Float64):
    time = Float64(c_clock()) / 1000000.0  # CLOCKS_PER_SEC approximation

def IDATE(inout datearray: Array1[Int32]):
    assert(datearray.l() <= 1)
    assert(datearray.u() >= 3)
    let current_time = c_time()
    let timeinfo = _localtime()
    datearray[0] = timeinfo[].tm_mday
    datearray[1] = timeinfo[].tm_mon + 1
    #ifdef OBJEXXFCL_IDATE_INTEL
    #    datearray[2] = max(timeinfo[].tm_year, 1969) % 100
    #else
    datearray[2] = timeinfo[].tm_year + 1900
    #endif

def IDATE(inout month: Int64, inout day: Int64, inout year: Int64):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    #ifdef OBJEXXFCL_IDATE_PORTABILITY
    #    year = timeinfo[].tm_year
    #else
    year = timeinfo[].tm_year % 100
    #endif

def IDATE(inout month: Int32, inout day: Int32, inout year: Int32):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    #ifdef OBJEXXFCL_IDATE_PORTABILITY
    #    year = timeinfo[].tm_year
    #else
    year = timeinfo[].tm_year % 100
    #endif

def IDATE(inout month: Int16, inout day: Int16, inout year: Int16):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    #ifdef OBJEXXFCL_IDATE_PORTABILITY
    #    year = timeinfo[].tm_year
    #else
    year = timeinfo[].tm_year % 100
    #endif

def IDATE4(inout datearray: Array1[Int32]):
    assert(datearray.l() <= 1)
    assert(datearray.u() >= 3)
    let current_time = c_time()
    let timeinfo = _localtime()
    datearray[0] = timeinfo[].tm_mday
    datearray[1] = timeinfo[].tm_mon + 1
    datearray[2] = timeinfo[].tm_year + (1900 if timeinfo[].tm_year >= 100 else 0)

def IDATE4(inout month: Int64, inout day: Int64, inout year: Int64):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    year = timeinfo[].tm_year

def IDATE4(inout month: Int32, inout day: Int32, inout year: Int32):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    year = timeinfo[].tm_year

def IDATE4(inout month: Int16, inout day: Int16, inout year: Int16):
    let current_time = c_time()
    let timeinfo = _localtime()
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday
    year = timeinfo[].tm_year

def JDATE() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let day: Int16 = timeinfo[].tm_yday + 1
    let year: Int16 = timeinfo[].tm_year % 100
    var s = String()
    s = String(format("{:02d}{:03d}", year, day))
    return s

def jdate() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let day: Int16 = timeinfo[].tm_yday + 1
    let year: Int16 = timeinfo[].tm_year % 100
    var s = String()
    s = String(format("{:02d}{:03d}", year, day))
    return s

def jdate4() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let day: Int16 = timeinfo[].tm_yday + 1
    let year: Int16 = timeinfo[].tm_year + 1900
    var s = String()
    s = String(format("{:04d}{:03d}", year, day))
    return s

def GETDAT(inout year: Int64, inout month: Int64, inout day: Int64):
    let current_time = c_time()
    let timeinfo = _localtime()
    year = timeinfo[].tm_year + 1900
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday

def GETDAT(inout year: Int32, inout month: Int32, inout day: Int32):
    let current_time = c_time()
    let timeinfo = _localtime()
    year = timeinfo[].tm_year + 1900
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday

def GETDAT(inout year: Int16, inout month: Int16, inout day: Int16):
    let current_time = c_time()
    let timeinfo = _localtime()
    year = timeinfo[].tm_year + 1900
    month = timeinfo[].tm_mon + 1
    day = timeinfo[].tm_mday

def MMM(m: Int) -> String:
    if m == 1:
        return "JAN"
    elif m == 2:
        return "FEB"
    elif m == 3:
        return "MAR"
    elif m == 4:
        return "APR"
    elif m == 5:
        return "MAY"
    elif m == 6:
        return "JUN"
    elif m == 7:
        return "JUL"
    elif m == 8:
        return "AUG"
    elif m == 9:
        return "SEP"
    elif m == 10:
        return "OCT"
    elif m == 11:
        return "NOV"
    elif m == 12:
        return "DEC"
    else:
        assert(False)
        return "???"

def DATE() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let month: Int16 = timeinfo[].tm_mon + 1
    let day: Int16 = timeinfo[].tm_mday
    let year: Int16 = timeinfo[].tm_year % 100
    var s = String()
    s = String(format("{:02d}/{:02d}/{:02d}", month, day, year))
    return s

def date() -> String:
    let current_time = c_time()
    let timeinfo = _localtime()
    let month: Int16 = timeinfo[].tm_mon + 1
    let day: Int16 = timeinfo[].tm_mday
    let year: Int16 = timeinfo[].tm_year % 100
    var s = String()
    s = String(format("{:02d}/{:02d}/{:02d}", month, day, year))
    return s

def DATE(inout date: String):
    let current_time = c_time()
    let timeinfo = _localtime()
    let day: Int16 = timeinfo[].tm_mday
    let month: Int16 = timeinfo[].tm_mon + 1
    let year: Int16 = timeinfo[].tm_year % 100
    var s = String()
    s = String(format("{:02d}-{}-{:02d}", day, MMM(month), year))
    date = s

def DATE4(inout date: String):
    let current_time = c_time()
    let timeinfo = _localtime()
    let day: Int16 = timeinfo[].tm_mday
    let month: Int16 = timeinfo[].tm_mon + 1
    let year: Int16 = timeinfo[].tm_year + 1900
    var s = String()
    s = String(format("{:02d}-{}-{:04d}", day, MMM(month), year))
    date = s

def time_zone_offset_seconds() -> Int:
    let now = datetime.now()
    let utc_offset = now.utcoffset()
    return Int(utc_offset.total_seconds())

def DATE_AND_TIME(
    date: Optional[String] = Optional[String](),
    time: Optional[String] = Optional[String](),
    zone: Optional[String] = Optional[String](),
    values: Optional[Array1D[Int]] = Optional[Array1D[Int]]()
):
    let now = datetime.now()
    let ms = now.microsecond // 1000
    let current_time = c_time()
    let timeinfo = _localtime()
    let DD = timeinfo[].tm_mday
    let MM = timeinfo[].tm_mon + 1
    let YY = timeinfo[].tm_year + 1900
    if date.present():
        var date_stream = String()
        date_stream = String(format("{:04d}{:02d}{:02d}", YY, MM, DD))
        date = date_stream
    let hh = timeinfo[].tm_hour
    let mm = timeinfo[].tm_min
    let ss = timeinfo[].tm_sec
    if time.present():
        var time_stream = String()
        time_stream = String(format("{:02d}{:02d}{:02d}.{:03d}", hh, mm, ss, ms))
        time = time_stream
    let zs = time_zone_offset_seconds()
    if zone.present():
        let zh = abs(zs) // 3600
        let zm = (abs(zs) - (zh * 3600)) // 60
        var zone_stream = String()
        zone_stream = String(format("{}{:02d}{:02d}", "+" if zs >= 0 else "-", zh, zm))
        zone = zone_stream
    if values.present():
        assert((values().l() <= 1) and (values().u() >= 8))
        values()[0] = YY
        values()[1] = MM
        values()[2] = DD
        values()[3] = zs // 60
        values()[4] = hh
        values()[5] = mm
        values()[6] = ss
        values()[7] = ms

def date_and_time(
    date: Optional[String] = Optional[String](),
    time: Optional[String] = Optional[String](),
    zone: Optional[String] = Optional[String](),
    values: Optional[Array1D[Int]] = Optional[Array1D[Int]]()
):
    let now = datetime.now()
    let ms = now.microsecond // 1000
    let current_time = c_time()
    let timeinfo = _localtime()
    let DD = timeinfo[].tm_mday
    let MM = timeinfo[].tm_mon + 1
    let YY = timeinfo[].tm_year + 1900
    if date.present():
        var date_stream = String()
        date_stream = String(format("{:04d}{:02d}{:02d}", YY, MM, DD))
        date = date_stream
    let hh = timeinfo[].tm_hour
    let mm = timeinfo[].tm_min
    let ss = timeinfo[].tm_sec
    if time.present():
        var time_stream = String()
        time_stream = String(format("{:02d}{:02d}{:02d}.{:03d}", hh, mm, ss, ms))
        time = time_stream
    let zs = time_zone_offset_seconds()
    if zone.present():
        let zh = abs(zs) // 3600
        let zm = (abs(zs) - (zh * 3600)) // 60
        var zone_stream = String()
        zone_stream = String(format("{}{:02d}{:02d}", "+" if zs >= 0 else "-", zh, zm))
        zone = zone_stream
    if values.present():
        assert((values().l() <= 1) and (values().u() >= 8))
        values()[0] = YY
        values()[1] = MM
        values()[2] = DD
        values()[3] = zs // 60
        values()[4] = hh
        values()[5] = mm
        values()[6] = ss
        values()[7] = ms

def SLEEP(sec: Float64):
    c_sleep(sec)