from tcstype import (
    tcstypeinterface,
    tcsvarinfo,
    TCS_PARAM,
    TCS_MATRIX,
    TCS_NUMBER,
    TCS_OUTPUT,
    TCS_INVALID,
    TCS_ERROR,
    TCS_IMPLEMENT_TYPE,
)
from math import ceil

enum:
    P_WEEKDAY_SCHEDULE = 0
    P_WEEKEND_SCHEDULE = 1
    O_TOU_VALUE = 2
    N_MAX = 3

var tou_translator_variables: List[tcsvarinfo] = List[
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_WEEKDAY_SCHEDULE, "weekday_schedule", "12x24 matrix of values for weekdays", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_WEEKEND_SCHEDULE, "weekend_schedule", "12x24 matrix of values for weekend days", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TOU_VALUE, "tou_value", "Value during time step", "", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0),
]

class tou_translator(tcstypeinterface):
    var m_hourly_tou: Array[Float64, 8760]

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        for i in range(8760):
            self.m_hourly_tou[i] = 0.0

    def __del__(owned self):

    def init(inout self) -> Int:
        var nrows: Int
        var ncols: Int
        var weekdays = self.value(P_WEEKDAY_SCHEDULE, &nrows, &ncols)
        if nrows != 12 or ncols != 24:
            self.message(TCS_ERROR, "The TOU translator did not get a 12x24 matrix for the weekday schedule.")
            return -1
        var weekends = self.value(P_WEEKEND_SCHEDULE, &nrows, &ncols)
        if nrows != 12 or ncols != 24:
            self.message(TCS_ERROR, "The TOU translator did not get a 12x24 matrix for the weekend schedule.")
            return -1
        var nday: Array[Int, 12] = Array[Int, 12](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        var wday: Int = 5
        var i: Int = 0
        for m in range(12):
            for d in range(nday[m]):
                var bWeekend: Bool = (wday <= 0)
                if wday >= 0:
                    wday -= 1
                else:
                    wday = 5
                for h in range(24):
                    if i >= 8760 or m * 24 + h >= 288:
                        break
                    if bWeekend:
                        self.m_hourly_tou[i] = weekends[m * 24 + h]
                    else:
                        self.m_hourly_tou[i] = weekdays[m * 24 + h]
                    i += 1
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var ihour: Int = int(ceil(time / 3600.0 - 1e-6) - 1)
        if ihour > 8760 - 1 or ihour < 0:
            return -1
        var tou: Float64 = self.m_hourly_tou[ihour]
        self.value(O_TOU_VALUE, tou)
        return 0

TCS_IMPLEMENT_TYPE(tou_translator, "Time of Use translator", "Tom Ferguson", 1, tou_translator_variables, None, 0)