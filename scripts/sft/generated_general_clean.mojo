# Model-generated Mojo from fine-tuned LoRA — EnergyPlus General.cc leaves
# This file contains ONLY the model's output (no test harness) to
# prove the fine-tuned adapter produces Mojo that compiles on real 1.0.0b2.

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