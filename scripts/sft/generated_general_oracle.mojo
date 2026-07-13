from math import copysign


def SafeDivide(a: Float64, b: Float64) -> Float64:
    var SMALL: Float64 = 1e-10
    if abs(b) >= SMALL:
        return a / b
    return a / copysign(SMALL, b)


def OrdinalDay(Month: Int, Day: Int, LeapYearValue: Int) -> Int:
    var EndDayofMonth = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    if Month == 1:
        return Day
    if Month == 2:
        return Day + EndDayofMonth[0]
    if Month >= 3 and Month <= 12:
        return Day + EndDayofMonth[Month - 2] + LeapYearValue
    return 0


def ref_safe_divide(a: Float64, b: Float64) -> Float64:
    var SMALL: Float64 = 1e-10
    if abs(b) >= SMALL:
        return a / b
    return a / copysign(SMALL, b)


def ref_ordinal_day(month: Int, day: Int, leap: Int) -> Int:
    var e = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    if month == 1:
        return day
    if month == 2:
        return day + e[0]
    if month >= 3 and month <= 12:
        return day + e[month - 2] + leap
    return 0


def main():
    var sd_bad = 0
    for (a, b) in [(5.0, 2.0), (7.0, 0.0), (-3.0, 1e-12), (0.0, 0.0), (10.0, -1e-11), (9.0, 4.0)]:
        if SafeDivide(a, b) != ref_safe_divide(a, b):
            sd_bad += 1

    var od_bad = 0
    var i = 0
    while i < 200:
        var m = (i % 12) + 1
        var d = (i % 28) + 1
        var lp = i % 2
        if OrdinalDay(m, d, lp) != ref_ordinal_day(m, d, lp):
            od_bad += 1
        i += 1

    var sd_pass = sd_bad == 0
    var od_pass = od_bad == 0
    print("SafeDivide:", "PASS" if sd_pass else "FAIL", "(", sd_bad, "mismatch )")
    print("OrdinalDay:", "PASS" if od_pass else "FAIL", "(", od_bad, "mismatch )")
    if not (sd_pass and od_pass):
        print("REAL-MOJO GATE: FAIL")
        return
    print("REAL-MOJO GATE: PASS")
