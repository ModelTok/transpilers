"""
EnergyPlus WindowEquivalentLayer module - faithful Mojo port
Handles equivalent layer (ASHWAT) window model optical and thermal calculations.
"""

from math import sin, cos, sqrt, pow, pi, asin, acos, atan, log, abs, exp
from math import floor, ceil

# ============================================================================
# ENUMS
# ============================================================================

struct LayerType:
    """Layer type enumeration."""
    alias GLAZE = 0
    alias VBHOR = 1
    alias VBVER = 2
    alias DRAPE = 3
    alias ROLLB = 4
    alias INSCRN = 5
    alias NONE = 6
    alias ROOM = 7
    alias GZS = 8


struct SolarArrays:
    """Solar array enumeration."""
    alias DIFF = 0
    alias BEAM = 1


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@register_passable("trivial")
struct CFSLWP:
    """Complex Fenestration System Longwave Properties."""
    var EPSLF: Float64  # front emissivity
    var EPSLB: Float64  # back emissivity
    var TAUL: Float64   # transmittance
    
    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0)
    
    fn __init__(epslf: Float64, epslb: Float64, taul: Float64) -> Self:
        return Self(epslf, epslb, taul)


@register_passable("trivial")
struct CFSSWP:
    """Complex Fenestration System Shortwave Properties."""
    var RHOSFBB: Float64  # front reflectance, beam-beam
    var RHOSBBB: Float64  # back reflectance, beam-beam
    var TAUSFBB: Float64  # front transmittance, beam-beam
    var TAUSBBB: Float64  # back transmittance, beam-beam
    var RHOSFBD: Float64  # front reflectance, beam-diffuse
    var RHOSBBD: Float64  # back reflectance, beam-diffuse
    var TAUSFBD: Float64  # front transmittance, beam-diffuse
    var TAUSBBD: Float64  # back transmittance, beam-diffuse
    var RHOSFDD: Float64  # front reflectance, diffuse-diffuse
    var RHOSBDD: Float64  # back reflectance, diffuse-diffuse
    var TAUS_DD: Float64  # transmittance, diffuse-diffuse
    
    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)


@register_passable("trivial")
struct CFSFILLGAS:
    """Fill gas properties."""
    var AK: Float64
    var BK: Float64
    var CK: Float64
    var ACP: Float64
    var BCP: Float64
    var CCP: Float64
    var AVISC: Float64
    var BVISC: Float64
    var CVISC: Float64
    var MHAT: Float64  # molecular weight
    
    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)


struct CFSGAP:
    """Gap between layers."""
    var Name: String
    var GTYPE: Int32  # gap type
    var TAS: Float64  # thickness
    var TAS_EFF: Float64  # effective thickness
    var FG: CFSFILLGAS
    var RHOGAS: Float64  # gas density
    
    fn __init__() -> Self:
        return Self("", 1, 0.0, 0.0, CFSFILLGAS(), 0.0)


struct CFSLAYER:
    """Complex Fenestration System Layer."""
    var Name: String
    var LTYPE: Int32
    var SWP_MAT: CFSSWP  # material SW properties
    var SWP_EL: CFSSWP   # equivalent layer SW properties
    var LWP_MAT: CFSLWP  # material LW properties
    var LWP_EL: CFSLWP   # equivalent layer LW properties
    var S: Float64  # slat/pleat spacing or wire spacing
    var W: Float64  # slat width or wire diameter
    var C: Float64  # slat crown
    var PHI_DEG: Float64  # slat angle, degrees
    var CNTRL: Int32  # control flag
    
    fn __init__() -> Self:
        return Self("", LayerType.NONE, CFSSWP(), CFSSWP(), CFSLWP(), CFSLWP(), 0.0, 0.0, 0.0, 0.0, 0)


alias CFSMAXNL = 10


struct CFSTY:
    """Complex Fenestration System."""
    var Name: String
    var NL: Int32  # number of layers
    var L: InlineArray[CFSLAYER, CFSMAXNL + 1]
    var G: InlineArray[CFSGAP, CFSMAXNL]
    var VBLayerPtr: Int32
    var ISControlled: Bool
    var WEQLSolverErrorIndex: Int32
    
    fn __init__() -> Self:
        var l_arr = InlineArray[CFSLAYER, CFSMAXNL + 1]()
        var g_arr = InlineArray[CFSGAP, CFSMAXNL]()
        for i in range(CFSMAXNL + 1):
            l_arr[i] = CFSLAYER()
        for i in range(CFSMAXNL):
            g_arr[i] = CFSGAP()
        return Self("", 0, l_arr, g_arr, 0, False, 0)


struct WindowEquivalentLayerData:
    """Window Equivalent Layer Data struct."""
    var RadiansToDeg: Float64
    var PAtmSeaLevel: Float64
    var hipRHO: Int32
    var hipTAU: Int32
    var SMALL_ERROR: Float64
    var gtySEALED: Int32
    var gtyOPENin: Int32
    var gtyOPENout: Int32
    var lscNONE: Int32
    var lscVBPROF: Int32
    var lscVBNOBM: Int32
    var hipRHO_BT0: Int32
    var hipTAU_BT0: Int32
    var hipTAU_BB0: Int32
    var hipDIM: Int32
    var X1MRDiff: Float64
    var XTAUDiff: Float64
    
    fn __init__() -> Self:
        return Self(
            180.0 / pi, 101325.0, 1, 2, 0.000001,
            1, 2, 3, 0, 1, 2, 1, 2, 3, 3,
            -1.0, -1.0
        )


# ============================================================================
# MATH UTILITIES
# ============================================================================

@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x


@always_inline
fn pow_3(x: Float64) -> Float64:
    return x * x * x


@always_inline
fn pow_4(x: Float64) -> Float64:
    return x * x * x * x


@always_inline
fn root_4(x: Float64) -> Float64:
    if x >= 0:
        return pow(x, 0.25)
    return 0.0


fn nint(x: Float64) -> Int32:
    """Round half away from zero."""
    if x >= 0:
        return Int32(x + 0.5)
    else:
        return Int32(x - 0.5)


# ============================================================================
# CORE FUNCTIONS
# ============================================================================

fn P01(P: Float64, WHAT: StringRef) -> Float64:
    """Constrain property to range 0-1."""
    if P < -0.05 or P > 1.05:
        # Issue warning (stub)
        pass
    return max(0.0, min(1.0, P))


fn OPENNESS_LW(OPENNESS: Float64, EPSLW0: Float64, TAULW0: Float64) -> Tuple[Float64, Float64]:
    """Modifies long wave properties for shade openness."""
    var EPSLW = EPSLW0 * (1.0 - OPENNESS)
    var TAULW = TAULW0 * (1.0 - OPENNESS) + OPENNESS
    return (EPSLW, TAULW)


fn IS_OPENNESS(D: Float64, S: Float64) -> Float64:
    """Returns openness from wire geometry."""
    if S > 0.0:
        return pow_2(max(S - D, 0.0) / S)
    return 0.0


fn IS_DSRATIO(OPENNESS: Float64) -> Float64:
    """Returns ratio of diameter to spacing."""
    if OPENNESS > 0.0:
        return 1.0 - min(sqrt(OPENNESS), 1.0)
    return 0.0


fn VB_SLAT_RADIUS_RATIO(W: Float64, C: Float64) -> Float64:
    """Returns curved slat radius ratio (W/R)."""
    if C <= 0.0 or W <= 0.0:
        return 0.0
    var CX = min(C, W / 2.001)
    return 2.0 * W * CX / (CX * CX + W * W / 4.0)


fn FRA(
    TM: Float64, T: Float64, DT: Float64,
    AK: Float64, BK: Float64, CK: Float64,
    ACP: Float64, BCP: Float64, CCP: Float64,
    AVISC: Float64, BVISC: Float64, CVISC: Float64,
    RHOGAS: Float64
) -> Float64:
    """Returns Rayleigh number."""
    var Z = 1.0
    var K = AK + BK * TM + CK * TM * TM
    var CP = ACP + BCP * TM + CCP * TM * TM
    var VISC = AVISC + BVISC * TM + CVISC * TM * TM
    
    return (9.81 * RHOGAS * RHOGAS * DT * T * T * T * CP) / (VISC * K * TM * Z * Z)


fn FNU(RA: Float64) -> Float64:
    """Returns Nusselt number given Rayleigh number."""
    var ARA = abs(RA)
    if ARA <= 10000.0:
        return 1.0 + 1.75967e-10 * pow(ARA, 2.2984755)
    elif ARA <= 50000.0:
        return 0.028154 * pow(ARA, 0.413993)
    else:
        return 0.0673838 * pow(ARA, 1.0 / 3.0)


fn HConvGap(G: CFSGAP, T1: Float64, T2: Float64) -> Float64:
    """Returns convective coefficient for a gap."""
    var T = G.TAS_EFF
    var TM = (T1 + T2) / 2.0
    var DT = T1 - T2
    
    var RA = FRA(TM, T, DT, G.FG.AK, G.FG.BK, G.FG.CK,
                 G.FG.ACP, G.FG.BCP, G.FG.CCP,
                 G.FG.AVISC, G.FG.BVISC, G.FG.CVISC, G.RHOGAS)
    var NU = FNU(RA)
    
    var KGAS = G.FG.AK + G.FG.BK * TM + G.FG.CK * TM * TM
    return NU * KGAS / T


fn HRadPar(T1: Float64, T2: Float64, E1: Float64, E2: Float64) -> Float64:
    """Returns radiative coefficient between two surfaces."""
    var result: Float64 = 0.0
    if E1 > 0.001 and E2 > 0.001:
        var DV = (1.0 / E1) + (1.0 / E2) - 1.0
        var SB: Float64 = 5.6697e-8
        result = (SB / DV) * (T1 + T2) * (pow_2(T1) + pow_2(T2))
    return result


fn HIC_ASHRAE(L: Float64, TG: Float64, TI: Float64) -> Float64:
    """Returns inside surface convective coefficient."""
    return 1.46 * pow(abs(TG - TI) / max(L, 0.001), 0.25)


fn DensityCFSFillGas(FG: CFSFILLGAS, P: Float64, T: Float64) -> Float64:
    """Returns gas density at P and T."""
    var R_univ: Float64 = 8.314
    return (P * FG.MHAT) / (R_univ * max(T, 1.0))


fn IsVBLayer(L: CFSLAYER) -> Bool:
    """Returns True if Layer is Venetian blind."""
    return L.LTYPE == LayerType.VBHOR or L.LTYPE == LayerType.VBVER


fn IsGlazeLayerX(L: CFSLAYER) -> Bool:
    """Returns True if Layer is glazing (including GZS)."""
    return L.LTYPE == LayerType.GLAZE or L.LTYPE == LayerType.GZS


fn IsGZSLayer(L: CFSLAYER) -> Bool:
    """Returns True if Layer has glazing data from external file."""
    return L.LTYPE == LayerType.GZS


fn CFSNGlz(FS: CFSTY) -> Int32:
    """Returns number of glazing layers."""
    var count: Int32 = 0
    for iL in range(1, FS.NL + 1):
        if IsGlazeLayerX(FS.L[iL]):
            count += 1
    return count


fn EffectiveEPSLF(FS: CFSTY) -> Float64:
    """Returns effective outside LW emissivity."""
    var E: Float64 = 0.0
    var TX: Float64 = 1.0
    for iL in range(1, FS.NL + 2):
        if iL == FS.NL + 1:
            E += 0.9 * TX
        else:
            E += FS.L[iL].LWP_EL.EPSLF * TX
            if FS.L[iL].LWP_EL.TAUL < 0.001:
                break
            TX *= FS.L[iL].LWP_EL.TAUL
    return E


fn EffectiveEPSLB(FS: CFSTY) -> Float64:
    """Returns effective inside (room side) LW emissivity."""
    var E: Float64 = 0.0
    var TX: Float64 = 1.0
    var iL = FS.NL
    while iL >= 0:
        if iL == 0:
            E += 0.9 * TX
        else:
            E += FS.L[iL].LWP_EL.EPSLB * TX
            if FS.L[iL].LWP_EL.TAUL < 0.001:
                break
            TX *= FS.L[iL].LWP_EL.TAUL
        iL -= 1
    return E


fn FEQX(a: Float64, b: Float64, tolF: Float64, tolAbs: Float64 = 1.0e-10) -> Bool:
    """Returns true if difference between two numbers is within tolerance."""
    var tolAbsX = max(tolAbs, 1.0e-10)
    var d = abs(a - b)
    if d < tolAbsX:
        return True
    return (2.0 * d / (abs(a) + abs(b))) < tolF


fn TRadC(J: Float64, Emiss: Float64) -> Float64:
    """Returns equivalent Celsius temperature from radiosity."""
    var SB: Float64 = 5.6697e-8
    return pow(J / (SB * max(Emiss, 0.001)), 0.25) - 273.15
