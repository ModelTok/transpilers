from WCECommon import ConstantsData
from math import exp, expm1, pow

def UVAction(t_data: List[Float64], a: Float64 = 3.6, b: Float64 = 12.0) -> List[Tuple[Float64, Float64]]:
    var result = List[Tuple[Float64, Float64]]()
    for val in t_data:
        var value = exp(a - b * val)
        result.append(Tuple[Float64, Float64](val, value))
    return result

def Krochmann(t_data: List[Float64]) -> List[Tuple[Float64, Float64]]:
    return UVAction(t_data, 12.28, 25.56)

def BlackBodySpectrum(t_data: List[Float64], t_temperature: Float64) -> List[Tuple[Float64, Float64]]:
    var result = List[Tuple[Float64, Float64]]()
    var ev: Float64 = 1.602e-19   # J
    var k: Float64 = 8.61739e-5   # eV/K
    var h: Float64 = 4.135669e-15 # eV s
    var hc: Float64 = 1239.842    # eVnm , in nm because we are dividing with lambda
    var kT: Float64 = k * t_temperature   # eV
    for val in t_data:
        var lambda_: Float64 = val * 1e3   # to convert it to nanometers
        var C1: Float64 = 8e-9 * ConstantsData.WCE_PI * h * ev * ConstantsData.SPEEDOFLIGHT / pow(lambda_ * 1e-9, 5)
        var q1: Float64 = 1.0 / expm1(hc / kT / lambda_)
        var energy: Float64 = C1 * q1
        result.append(Tuple[Float64, Float64](val, energy))
    return result