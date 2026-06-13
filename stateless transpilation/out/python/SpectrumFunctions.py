# EXTERNAL DEPS (to wire in glue):
# - WCE_PI: float (from WCECommon.hpp, namespace ConstantsData::WCE_PI)
# - SPEEDOFLIGHT: float (from WCECommon.hpp, namespace ConstantsData::SPEEDOFLIGHT)

import math
from typing import List, Tuple


def UVAction(t_data: List[float], a: float = 3.6, b: float = 12.0) -> List[Tuple[float, float]]:
    """Input wavelengths are in micrometers."""
    result: List[Tuple[float, float]] = []
    for val in t_data:
        value = math.exp(a - b * val)
        result.append((val, value))

    return result


def Krochmann(t_data: List[float]) -> List[Tuple[float, float]]:
    """Input wavelengths are in micrometers."""
    return UVAction(t_data, 12.28, 25.56)


def BlackBodySpectrum(t_data: List[float], t_temperature: float,
                      WCE_PI: float, SPEEDOFLIGHT: float) -> List[Tuple[float, float]]:
    """Input wavelengths are in micrometers."""
    result: List[Tuple[float, float]] = []

    ev = 1.602e-19   # J

    k = 8.61739e-5           # eV/K
    h = 4.135669e-15         # eV s
    hc = 1239.842            # eVnm , in nm because we are dividing with lambda
    kT = k * t_temperature   # eV

    for val in t_data:
        lambda_val = val * 1e3   # to convert it to nanometers
        C1 = 8e-9 * WCE_PI * h * ev * SPEEDOFLIGHT / math.pow(lambda_val * 1e-9, 5)
        q1 = 1 / math.expm1(hc / kT / lambda_val)
        energy = C1 * q1
        result.append((val, energy))

    return result
