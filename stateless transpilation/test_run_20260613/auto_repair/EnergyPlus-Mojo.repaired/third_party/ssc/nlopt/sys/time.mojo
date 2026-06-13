# Translated from C++: third_party/ssc/nlopt/sys/time.cpp

typealias clock_t = Int64

struct _timeb:
    var time: Int64
    var millitm: UInt16

struct timeval:
    var tv_sec: Int64
    var tv_usec: Int64

struct tms:
    var tms_utime: clock_t
    var tms_stime: clock_t
    var tms_cstime: clock_t
    var tms_cutime: clock_t

extern def _ftime(out timebuffer: _timeb)

extern def clock() -> clock_t

def gettimeofday(inout t: timeval, _: None) -> Int32:
    var timebuffer: _timeb
    _ftime(timebuffer)
    t.tv_sec = timebuffer.time
    t.tv_usec = 1000 * timebuffer.millitm
    return 0

def times(inout __buffer: tms) -> clock_t:
    __buffer.tms_utime = clock()
    __buffer.tms_stime = 0
    __buffer.tms_cstime = 0
    __buffer.tms_cutime = 0
    return __buffer.tms_utime