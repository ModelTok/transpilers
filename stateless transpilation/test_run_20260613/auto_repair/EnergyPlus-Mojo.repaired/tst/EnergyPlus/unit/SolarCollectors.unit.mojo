alias Real64 = Float64

def expect_true(condition: Bool, msg: String = ""):
    if not condition:
        raise Error("FAIL: " + msg)

def expect_false(condition: Bool, msg: String = ""):
    if condition:
        raise Error("FAIL: " + msg)

def expect_near(expected: Real64, actual: Real64, abs_error: Real64, msg: String = ""):
    if (expected - actual).absolute() > abs_error:
        raise Error("FAIL: " + msg)

from math import isnan, isfinite

def main():
    let TempSurf1: Real64 = 251.0
    let TempSurf2: Real64 = 26.5
    let Tref: Real64 = 0.5 * (TempSurf1 + TempSurf2)
    let maxArrayTemp: Real64 = 126.85
    expect_true(Tref > maxArrayTemp)
    let AirGap: Real64 = 0.05
    let CosTilt: Real64 = 0.87
    let SinTilt: Real64 = 0.80
    from EnergyPlus.SolarCollectors import CollectorData
    let hConvCoef: Real64 = CollectorData.CalcConvCoeffBetweenPlates(TempSurf1, TempSurf2, AirGap, CosTilt, SinTilt)
    expect_false(isnan(hConvCoef))
    expect_true(isfinite(hConvCoef))
    expect_near(4.71593, hConvCoef, 0.001)