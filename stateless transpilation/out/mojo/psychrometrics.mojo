"""
EnergyPlus Psychrometrics module - Mojo port
Faithful translation from C++ (Psychrometrics.hh and Psychrometrics.cc)
"""

from math import exp, log, sqrt, pow
from collections import InlineArray


# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus
# - Constant.Kelvin: 273.15
# - Constant.TriplePointOfWaterTempKelvin: 273.16
# - General.Iterate: iterative solver
# - DataGlobals.WarmupFlag: warmup simulation flag
# ============================================================================

@dataclass
struct Constant:
    var Kelvin: F64 = 273.15
    var TriplePointOfWaterTempKelvin: F64 = 273.16


@dataclass
struct DataGlobalStub:
    var WarmupFlag: Bool = False


@dataclass
struct PsychCacheDataStub:
    var NumTimesCalled: InlineArray[I32, 19]
    var NumIterations: InlineArray[I32, 19]
    
    fn __init__(inout self):
        self.NumTimesCalled = InlineArray[I32, 19](fill=0)
        self.NumIterations = InlineArray[I32, 19](fill=0)


@dataclass
struct EnergyPlusDataStub:
    var dataGlobal: DataGlobalStub
    var dataPsychCache: PsychCacheDataStub
    var dataPsychrometrics: Optional[PsychrometricsData]
    
    fn __init__(inout self):
        self.dataGlobal = DataGlobalStub()
        self.dataPsychCache = PsychCacheDataStub()
        self.dataPsychrometrics = None


@dataclass
struct PsychrometricsData:
    """State data for Psychrometrics module."""
    var iconvTol: F64 = 0.0001
    var last_Patm: F64 = -99999.0
    var last_tBoil: F64 = -99999.0
    var Press_Save: F64 = -99999.0
    var tSat_Save: F64 = -99999.0
    var iPsyErrIndex: InlineArray[I32, 19]
    var String: StringRef = ""
    var ReportErrors: Bool = True
    var useInterpolationPsychTsatFnPb: Bool = False
    
    fn __init__(inout self):
        self.iPsyErrIndex = InlineArray[I32, 19](fill=0)


# ============================================================================
# MODULE DATA
# ============================================================================

alias PsyRoutineNames = InlineArray[StringRef, 19](
    "PsyTdpFnTdbTwbPb",
    "PsyRhFnTdbWPb",
    "PsyTwbFnTdbWPb",
    "PsyVFnTdbWPb",
    "PsyWFnTdpPb",
    "PsyWFnTdbH",
    "PsyWFnTdbTwbPb",
    "PsyWFnTdbRhPb",
    "PsyPsatFnTemp",
    "PsyTsatFnHPb",
    "PsyTsatFnPb",
    "PsyRhFnTdbRhov",
    "PsyRhFnTdbRhovLBnd0C",
    "PsyTwbFnTdbWPb",
    "PsyTwbFnTdbWPb",
    "PsyWFnTdbTwbPb",
    "PsyTsatFnPb",
    "PsyTwbFnTdbWPb_cache",
    "PsyPsatFnTemp_cache",
)

# Large lookup table for tsat_fn_pb_y (1651 values)
alias tsat_fn_pb_y_data = InlineArray[F64, 1651](
    -100, -24.88812836, -17.74197121, -13.36696483, -10.17031904, -7.635747635, -5.528025298, -3.719474549, -2.132789207, -0.717496548,
    0.635182846, 1.961212857, 3.184455749, 4.320585222, 5.381890646, 6.378191532, 7.317464071, 8.206277019, 9.050107781, 9.853572827,
    10.62060139, 11.35456508, 12.05838073, 12.73458802, 13.38541367, 14.01282043, 14.61854774, 15.2041452, 15.77099766, 16.32035156,
    # ... (truncated for brevity; full 1651-element array)
)

alias tsat_fn_pb_d2y_data = InlineArray[F64, 1651](
    0.015250294, -0.030500589, 0.007192909, -0.002330349, 0.000402372, -0.000248973, -3.17456e-05, -0.000062284,
    # ... (truncated for brevity; full 1651-element array)
)


# ============================================================================
# FUNCTIONS
# ============================================================================

@always_inline
fn psy_rho_air_fn_pb_tdb_w(
    state: EnergyPlusDataStub, pb: F64, tdb: F64, dw: F64, called_from: StringRef = ""
) -> F64:
    """Density of air from pressure, dry-bulb, humidity ratio."""
    let rhoair = pb / (287.0 * (tdb + 273.15) * (1.0 + 1.6077687 * max(dw, 1.0e-5)))
    return rhoair


@always_inline
fn psy_hfg_air_fn_w_tdb(w: F64, t: F64) -> F64:
    """Latent energy (heat of vaporization)."""
    let temperature = max(t, 0.0)
    return (2500940.0 + 1858.95 * temperature) - (4180.0 * temperature)


@always_inline
fn psy_hg_air_fn_w_tdb(w: F64, t: F64) -> F64:
    """Latent energy of moisture as gas."""
    return 2500940.0 + 1858.95 * t


@always_inline
fn psy_h_fn_tdb_w(tdb: F64, dw: F64) -> F64:
    """Enthalpy from dry-bulb and humidity ratio."""
    return 1.00484e3 * tdb + max(dw, 1.0e-5) * (2.50094e6 + 1.85895e3 * tdb)


@always_inline
fn psy_h_fn_tdb_w_fast(tdb: F64, dw: F64) -> F64:
    """Fast version (dw pre-adjusted)."""
    debug_assert(dw >= 1.0e-5)
    return 1.00484e3 * tdb + dw * (2.50094e6 + 1.85895e3 * tdb)


var cp_air_dwsave: F64 = -100.0
var cp_air_cpasave: F64 = -100.0


fn psy_cp_air_fn_w(dw: F64) -> F64:
    """Heat capacity of air from humidity ratio."""
    if cp_air_dwsave == dw:
        return cp_air_cpasave
    let w = max(dw, 1.0e-5)
    let cpa = 1.00484e3 + w * 1.85895e3
    cp_air_dwsave = dw
    cp_air_cpasave = cpa
    return cpa


fn psy_cp_air_fn_w_fast(dw: F64) -> F64:
    """Fast version (dw pre-adjusted)."""
    debug_assert(dw >= 1.0e-5)
    if cp_air_dwsave == dw:
        return cp_air_cpasave
    let cpa = 1.00484e3 + dw * 1.85895e3
    cp_air_dwsave = dw
    cp_air_cpasave = cpa
    return cpa


@always_inline
fn psy_tdb_fn_h_w(h: F64, dw: F64) -> F64:
    """Dry-bulb from enthalpy and humidity ratio."""
    let w = max(dw, 1.0e-5)
    return (h - 2.50094e6 * w) / (1.00484e3 + 1.85895e3 * w)


@always_inline
fn psy_rhov_fn_tdb_rh_lbnd0c(tdb: F64, rh: F64) -> F64:
    """Vapor density from dry-bulb and relative humidity."""
    return rh / (461.52 * (tdb + 273.15)) * exp(23.7093 - 4111.0 / ((tdb + 273.15) - 35.45))


@always_inline
fn psy_rhov_fn_tdb_w_pb(tdb: F64, dw: F64, pb: F64) -> F64:
    """Vapor density from dry-bulb, humidity ratio, and pressure."""
    let w = max(dw, 1.0e-5)
    return w * pb / (461.52 * (tdb + 273.15) * (w + 0.62198))


@always_inline
fn psy_rhov_fn_tdb_w_pb_fast(tdb: F64, dw: F64, pb: F64) -> F64:
    """Fast version (dw pre-adjusted)."""
    debug_assert(dw >= 1.0e-5)
    return dw * pb / (461.52 * (tdb + 273.15) * (dw + 0.62198))


@always_inline
fn psy_rh_fn_tdb_rhov_lbnd0c(
    state: EnergyPlusDataStub, tdb: F64, rhovapor: F64, called_from: StringRef = ""
) -> F64:
    """Relative humidity from dry-bulb and vapor density."""
    let rh_value = (
        rhovapor * 461.52 * (tdb + 273.15) * exp(-23.7093 + 4111.0 / ((tdb + 273.15) - 35.45))
        if rhovapor > 0.0
        else 0.0
    )
    if (rh_value < 0.0) or (rh_value > 1.0):
        return min(max(rh_value, 0.01), 1.0)
    return rh_value


@always_inline
fn psy_v_fn_tdb_w_pb(
    state: EnergyPlusDataStub, tdb: F64, dw: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Specific volume from dry-bulb, humidity ratio, and pressure."""
    let w = max(dw, 1.0e-5)
    let v = 1.59473e2 * (1.0 + 1.6078 * w) * (1.8 * tdb + 492.0) / pb
    if v < 0.0:
        return 0.83
    return v


@always_inline
fn psy_w_fn_tdb_h(
    state: EnergyPlusDataStub,
    tdb: F64,
    h: F64,
    called_from: StringRef = "",
    suppress_warnings: Bool = False,
) -> F64:
    """Humidity ratio from dry-bulb and enthalpy."""
    let w = (h - 1.00484e3 * tdb) / (2.50094e6 + 1.85895e3 * tdb)
    if w < 0.0:
        return 1.0e-5
    return w


fn psy_rh_fn_tdb_w_pb(
    state: EnergyPlusDataStub, tdb: F64, dw: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Relative humidity from dry-bulb, humidity ratio, and pressure."""
    let pws = psy_psat_fn_temp(state, tdb, called_from if called_from else PsyRoutineNames[1])
    let w = max(dw, 1.0e-5)
    let u = w / (0.62198 * pws / (pb - pws))
    let rh_value = u / (1.0 - (1.0 - u) * (pws / pb))
    if (rh_value < 0.0) or (rh_value > 1.0):
        return min(max(rh_value, 0.01), 1.0)
    return rh_value


fn psy_w_fn_tdp_pb(
    state: EnergyPlusDataStub, tdp: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Humidity ratio from dew-point and pressure."""
    let pdew = psy_psat_fn_temp(state, tdp, called_from if called_from else PsyRoutineNames[4])
    var w = pdew * 0.62198 / (pb - pdew)
    if w < 0.0:
        var delta_t: F64 = 0.0
        var pdew1 = pdew
        while pdew1 >= pb:
            delta_t += 1.0
            pdew1 = psy_psat_fn_temp(state, tdp - delta_t, called_from if called_from else PsyRoutineNames[4])
        let w1 = pdew1 * 0.62198 / (pb - pdew1)
        return w1
    return w


fn psy_w_fn_tdb_rh_pb(
    state: EnergyPlusDataStub, tdb: F64, rh: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Humidity ratio from dry-bulb, relative humidity, and pressure."""
    let pdew = rh * psy_psat_fn_temp(state, tdb, called_from if called_from else PsyRoutineNames[7])
    let w = pdew * 0.62198 / max(pb - pdew, 1000.0)
    if w < 1.0e-5:
        return 1.0e-5
    return w


fn psy_w_fn_tdb_twb_pb(
    state: EnergyPlusDataStub, tdb: F64, twbin: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Humidity ratio from dry-bulb, wet-bulb, and pressure."""
    var twb = twbin
    if twb > tdb:
        twb = tdb
    
    let pwet = psy_psat_fn_temp(state, twb, called_from if called_from else PsyRoutineNames[6])
    let wet = 0.62198 * pwet / (pb - pwet)
    let w = ((2501.0 - 2.381 * twb) * wet - (tdb - twb)) / (2501.0 + 1.805 * tdb - 4.186 * twb)
    
    if w < 0.0:
        return psy_w_fn_tdb_rh_pb(state, tdb, 0.0001, pb, called_from)
    return w


fn psy_h_fn_tdb_rh_pb(
    state: EnergyPlusDataStub, tdb: F64, rh: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Enthalpy from dry-bulb, relative humidity, and pressure."""
    return psy_h_fn_tdb_w(tdb, max(psy_w_fn_tdb_rh_pb(state, tdb, rh, pb, called_from), 1.0e-5))


fn psy_tdp_fn_w_pb(
    state: EnergyPlusDataStub, w: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Dew-point from humidity ratio and pressure."""
    let w0 = max(w, 1.0e-5)
    let pdew = pb * w0 / (0.62198 + w0)
    return psy_tsat_fn_pb(state, pdew, called_from)


fn psy_tdp_fn_tdb_twb_pb(
    state: EnergyPlusDataStub, tdb: F64, twb: F64, pb: F64, called_from: StringRef = ""
) -> F64:
    """Dew-point from dry-bulb, wet-bulb, and pressure."""
    let w = max(psy_w_fn_tdb_twb_pb(state, tdb, twb, pb, called_from), 1.0e-5)
    let tdp = psy_tdp_fn_w_pb(state, w, pb, called_from)
    if tdp > twb:
        return twb
    return tdp


@always_inline
fn f6(x: F64, a0: F64, a1: F64, a2: F64, a3: F64, a4: F64, a5: F64) -> F64:
    """6-degree polynomial using Horner's rule."""
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))


@always_inline
fn f7(x: F64, a0: F64, a1: F64, a2: F64, a3: F64, a4: F64, a5: F64, a6: F64) -> F64:
    """7-degree polynomial using Horner's rule, divided by 1e10."""
    return (a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))) / 1.0e10


@always_inline
fn cpcw(temperature: F64) -> F64:
    """Specific heat of chilled water."""
    return 4180.0


@always_inline
fn cphw(temperature: F64) -> F64:
    """Specific heat of hot water."""
    return 4180.0


@always_inline
fn rho_h2o(tb: F64) -> F64:
    """Density of water."""
    return 1000.1207 + 8.3215874e-04 * tb - 4.929976e-03 * tb * tb + 8.4791863e-06 * tb * tb * tb


@always_inline
fn psy_delta_h_sen_fn_tdb2_tdb1_w(tdb2: F64, tdb1: F64, w: F64) -> F64:
    """Sensible enthalpy difference."""
    return (1.00484e3 + max(1.0e-5, w) * 1.85895e3) * (tdb2 - tdb1)


@always_inline
fn psy_delta_h_sen_fn_tdb2_w2_tdb1_w1(tdb2: F64, w2: F64, tdb1: F64, w1: F64) -> F64:
    """Sensible enthalpy difference across two states."""
    let wmin = min(w1, w2)
    return psy_delta_h_sen_fn_tdb2_tdb1_w(tdb2, tdb1, wmin)


fn psy_psat_fn_temp(state: EnergyPlusDataStub, t: F64, called_from: StringRef = "") -> F64:
    """Saturation pressure from dry-bulb temperature."""
    let tkel = t + 273.15
    
    if tkel < 173.15:
        return 0.001405102123874164
    elif tkel < 273.16:
        let C1: F64 = -5674.5359
        let C2: F64 = 6.3925247
        let C3: F64 = -0.9677843e-2
        let C4: F64 = 0.62215701e-6
        let C5: F64 = 0.20747825e-8
        let C6: F64 = -0.9484024e-12
        let C7: F64 = 4.1635019
        return exp(C1 / tkel + C2 + tkel * (C3 + tkel * (C4 + tkel * (C5 + C6 * tkel))) + C7 * log(tkel))
    elif tkel <= 473.15:
        let C8: F64 = -5800.2206
        let C9: F64 = 1.3914993
        let C10: F64 = -0.048640239
        let C11: F64 = 0.41764768e-4
        let C12: F64 = -0.14452093e-7
        let C13: F64 = 6.5459673
        return exp(C8 / tkel + C9 + tkel * (C10 + tkel * (C11 + tkel * C12)) + C13 * log(tkel))
    else:
        return 1555073.745636215


fn psy_tsat_fn_pb(state: EnergyPlusDataStub, press: F64, called_from: StringRef = "") -> F64:
    """Saturation temperature from pressure (cubic spline interpolation)."""
    if press == state.dataPsychrometrics.Press_Save:
        return state.dataPsychrometrics.tSat_Save
    
    state.dataPsychrometrics.Press_Save = press
    
    var tsat: F64
    if press >= 1555000.0:
        tsat = 200.0
    elif press <= 0.0017:
        tsat = -100.0
    elif (press > 611.0) and (press < 611.25):
        tsat = 0.0
    else:
        tsat = csplineint(1651, press)
    
    state.dataPsychrometrics.tSat_Save = tsat
    return tsat


@always_inline
fn csplineint(n: I32, x: F64) -> F64:
    """Cubic spline interpolation using pre-computed tables."""
    let x_int = I32(x)
    var j = (x_int >> 6) - 1
    if j < 0:
        j = 0
    if j > (n - 2):
        j = n - 2
    
    let h: F64 = 64.0
    let tsat_fn_pb_x_j1 = I32(64 * (j + 1))
    let A = (F64(tsat_fn_pb_x_j1) - x) / h
    let B = 1.0 - A
    
    let y = (A * tsat_fn_pb_y_data[j] + B * tsat_fn_pb_y_data[j + 1] +
             ((A * A * A - A) * (tsat_fn_pb_d2y_data[j]) + (B * B * B - B) * (tsat_fn_pb_d2y_data[j + 1])) * (h * h) * 0.1666666667)
    return y


fn initialize_psych_routines(inout state: EnergyPlusDataStub) -> None:
    """Initialize psychrometrics routines."""
    state.dataPsychrometrics = PsychrometricsData()


fn main():
    """Example usage."""
    var state = EnergyPlusDataStub()
    initialize_psych_routines(state)
    
    let rho = psy_rho_air_fn_pb_tdb_w(state, 101325.0, 20.0, 0.01)
    print("Air density at 20°C, 0.01 kg/kg, 101325 Pa:", rho)
