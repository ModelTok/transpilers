# EXTERNAL DEPS (to wire in glue):
# - WCE_PI: Float64 (from WCECommon.hpp, namespace ConstantsData::WCE_PI)
# - SPEEDOFLIGHT: Float64 (from WCECommon.hpp, namespace ConstantsData::SPEEDOFLIGHT)

from math import exp, expm1, pow


struct Pair:
    """Mimics std::pair<double, double>."""
    var first: Float64
    var second: Float64

    fn __init__(inout self, first: Float64, second: Float64):
        self.first = first
        self.second = second


fn UVAction(t_data: List[Float64], a: Float64 = 3.6, b: Float64 = 12.0) -> List[Pair]:
    """Input wavelengths are in micrometers."""
    var result = List[Pair]()
    for val in t_data:
        let value = exp(a - b * val)
        result.append(Pair(val, value))

    return result^


fn Krochmann(t_data: List[Float64]) -> List[Pair]:
    """Input wavelengths are in micrometers."""
    return UVAction(t_data, 12.28, 25.56)


fn BlackBodySpectrum(t_data: List[Float64], t_temperature: Float64,
                     WCE_PI: Float64, SPEEDOFLIGHT: Float64) -> List[Pair]:
    """Input wavelengths are in micrometers."""
    var result = List[Pair]()

    let ev: Float64 = 1.602e-19   # J

    let k: Float64 = 8.61739e-5           # eV/K
    let h: Float64 = 4.135669e-15         # eV s
    let hc: Float64 = 1239.842            # eVnm , in nm because we are dividing with lambda
    let kT: Float64 = k * t_temperature   # eV

    for val in t_data:
        let lambda_val = val * 1e3   # to convert it to nanometers
        let C1 = 8e-9 * WCE_PI * h * ev * SPEEDOFLIGHT / pow(lambda_val * 1e-9, 5)
        let q1 = 1.0 / expm1(hc / kT / lambda_val)
        let energy = C1 * q1
        result.append(Pair(val, energy))

    return result^
