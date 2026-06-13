# Mojo translation of TarcogShading.cc
# Faithful 1:1 translation, no refactoring.
# Keep all function, variable, struct, enum names exactly.
# Use 0-based indexing for all arrays (ObjexxFCL 1-based).
# Import necessary modules.

from TARCOGGassesParams import maxgas, Stdrd, e  # note: 'e' is the base of natural log
from TARCOGGasses90 import GASSES90
from TARCOGCommon import IsShadingLayer, AirflowRelaxationParameter, AirflowConvergenceTolerance, NumOfIterations
from TARCOGParams import (
    C1_VENET_HORIZONTAL, C2_VENET_HORIZONTAL, C3_VENET_HORIZONTAL,
    C1_VENET_VERTICAL, C2_VENET_VERTICAL, C3_VENET_VERTICAL,
    C1_SHADE, C2_SHADE, C3_SHADE, C4_SHADE,
    TARCOGLayerType
)
from Constants import Constant
from EnergyPlusData import EnergyPlusData
from DataGlobals import BaseGlobalStruct

# Helper functions for pow_2 and EP_SIZE_CHECK (no-op)
def pow_2(x: Float64) -> Float64:
    return x * x

def EP_SIZE_CHECK(arr: List[Float64], size: Int):
    # not implemented in Mojo translation; assume correct

# Struct for TarcogShadingData
struct TarcogShadingData(BaseGlobalStruct):
    var frct1: List[Float64] = List[Float64](maxgas, 0.0)
    var frct2: List[Float64] = List[Float64](maxgas, 0.0)
    var iprop1: List[Int] = List[Int](maxgas, 0)
    var iprop2: List[Int] = List[Int](maxgas, 0)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.frct1 = List[Float64](maxgas, 0.0)
        self.frct2 = List[Float64](maxgas, 0.0)
        self.iprop1 = List[Int](maxgas, 0)
        self.iprop2 = List[Int](maxgas, 0)

# Main namespace
@value
struct TarcogShading:

# Free functions (as module-level functions)
def shading(
    state: EnergyPlusData,
    theta: List[Float64],
    gap: List[Float64],
    hgas: List[Float64],
    hcgas: List[Float64],
    hrgas: List[Float64],
    frct: List[List[Float64]],
    iprop: List[List[Int]],
    pressure: List[Float64],
    nmix: List[Int],
    xwght: List[Float64],
    xgcon: List[List[Float64]],
    xgvis: List[List[Float64]],
    xgcp: List[List[Float64]],
    nlayer: Int,
    width: Float64,
    height: Float64,
    angle: Float64,
    Tout: Float64,
    Tin: Float64,
    Atop: List[Float64],
    Abot: List[Float64],
    Al: List[Float64],
    Ar: List[Float64],
    Ah: List[Float64],
    vvent: List[Float64],
    tvent: List[Float64],
    LayerType: List[TARCOGLayerType],
    Tgaps: List[Float64],
    qv: List[Float64],
    hcv: List[Float64],
    nperr: Int,
    ErrorMessage: String,
    vfreevent: List[Float64]
):
    # Local variables (note: indexing will be adjusted to 0-based)
    var Atops: Float64
    var Abots: Float64
    var Als: Float64
    var Ars: Float64
    var Ahs: Float64
    var press1: Float64
    var press2: Float64
    var s1: Float64
    var s2: Float64
    var s: Float64
    var hcvs: Float64
    var qvs: Float64
    var hc: Float64
    var hc1: Float64
    var hc2: Float64
    var speed: Float64
    var Tav: Float64
    var Tgap: Float64
    var Temp: Float64
    var speed1: Float64
    var speed2: Float64
    var Tav1: Float64
    var Tav2: Float64
    var Tgap1: Float64
    var Tgap2: Float64
    var hcv1: Float64
    var hcv2: Float64
    var qv1: Float64
    var qv2: Float64
    var nmix1: Int
    var nmix2: Int

    # Initialize qv, hcv to 0
    for i in range(len(qv)):
        qv[i] = 0.0
    for i in range(len(hcv)):
        hcv[i] = 0.0

    # Loop over layers (1-based in original, 0-based here)
    for i in range(1, nlayer + 1):
        if IsShadingLayer(LayerType[i - 1]):
            Atops = Atop[i - 1]
            Abots = Abot[i - 1]
            Als = Al[i - 1]
            Ars = Ar[i - 1]
            Ahs = Ah[i - 1]
            nmix1 = nmix[i - 1]
            nmix2 = nmix[i]  # i+1 in 1-based becomes i in 0-based
            press1 = pressure[i - 1]
            press2 = pressure[i]  # i+1
            # Fill iprop1, iprop2, frct1, frct2
            for j in range(1, maxgas + 1):
                state.dataTarcogShading.iprop1[j - 1] = iprop[j - 1][i - 1]  # iprop(j,i) -> iprop[j-1][i-1]
                state.dataTarcogShading.iprop2[j - 1] = iprop[j - 1][i]      # iprop(j,i+1)
                state.dataTarcogShading.frct1[j - 1] = frct[j - 1][i - 1]
                state.dataTarcogShading.frct2[j - 1] = frct[j - 1][i]
            # i == 1 (1-based) -> i == 1 (since i starts at 1, it's the first layer)
            if i == 1:
                s = gap[0]  # gap(1)
                hc = hcgas[1]  # hcgas(2) -> index 1 in 0-based
                Tav = (theta[1] + theta[2]) / 2.0  # theta(2) and theta(3) -> indices 1 and 2
                Tgap = Tgaps[1]  # Tgaps(2) -> index 1
                shadingedge(
                    state,
                    state.dataTarcogShading.iprop1,
                    state.dataTarcogShading.frct1,
                    press1, nmix1,
                    state.dataTarcogShading.iprop2,
                    state.dataTarcogShading.frct2,
                    press2, nmix2,
                    xwght, xgcon, xgvis, xgcp,
                    Atops, Abots, Als, Ars, Ahs,
                    s, height, width, angle,
                    vvent[1],  # vvent(2) -> index 1
                    hc, Tout, Tav, Tgap,
                    hcvs, qvs, nperr, ErrorMessage, speed
                )
                if (nperr > 0) and (nperr < 1000):
                    return
                Tgaps[1] = Tgap
                hcgas[1] = hcvs / 2.0
                hgas[1] = hcgas[1] + hrgas[1]
                hcv[1] = hcvs
                qv[1] = qvs
                vfreevent[1] = speed
            # i == nlayer (1-based)
            if i == nlayer:
                if nlayer > 1:
                    s = gap[nlayer - 2]  # gap(nlayer-1) -> index nlayer-2
                    Tav = (theta[2 * nlayer - 2] + theta[2 * nlayer - 3]) / 2.0  # indices: 2n-1-1, 2n-2-1
                else:
                    s = 0.0
                    Tav = 273.15
                hc = hcgas[nlayer - 1]  # hcgas(nlayer) -> index nlayer-1
                Tgap = Tgaps[nlayer - 1]
                shadingedge(
                    state,
                    state.dataTarcogShading.iprop2,
                    state.dataTarcogShading.frct2,
                    press2, nmix2,
                    state.dataTarcogShading.iprop1,
                    state.dataTarcogShading.frct1,
                    press1, nmix1,
                    xwght, xgcon, xgvis, xgcp,
                    Atops, Abots, Als, Ars, Ahs,
                    s, height, width, angle,
                    vvent[nlayer - 1],  # vvent(nlayer) -> index nlayer-1
                    hc, Tin, Tav, Tgap,
                    hcvs, qvs, nperr, ErrorMessage, speed
                )
                if (nperr > 0) and (nperr < 1000):
                    return
                Tgaps[nlayer - 1] = Tgap
                hcgas[nlayer - 1] = hcvs / 2.0
                hgas[nlayer - 1] = hcgas[nlayer - 1] + hrgas[nlayer - 1]
                hcv[nlayer - 1] = hcvs
                qv[nlayer - 1] = qvs
                vfreevent[i - 1] = speed  # vfreevent(i) -> index i-1
            # i > 1 and i < nlayer
            if (i > 1) and (i < nlayer):
                Tav1 = (theta[2 * i - 3] + theta[2 * i - 2]) / 2.0  # 2i-2, 2i-1 in 1-based -> indices 2i-3, 2i-2
                Tav2 = (theta[2 * i - 1] + theta[2 * i]) / 2.0      # 2i, 2i+1 -> indices 2i-1, 2i
                Tgap1 = Tgaps[i - 1]  # Tgaps(i) -> index i-1
                Tgap2 = Tgaps[i]      # Tgaps(i+1) -> index i
                hc1 = hcgas[i - 1]    # hcgas(i) -> index i-1
                hc2 = hcgas[i]        # hcgas(i+1) -> index i
                if i > 1:
                    s1 = gap[i - 2]  # gap(i-1) -> index i-2
                s2 = gap[i - 1]  # gap(i) -> index i-1
                if (vvent[i - 1] != 0.0) or (vvent[i] != 0.0):
                    forcedventilation(
                        state,
                        state.dataTarcogShading.iprop1,
                        state.dataTarcogShading.frct1,
                        press1, nmix1, xwght, xgcon, xgvis, xgcp,
                        s1, height, hc1,
                        vvent[i - 1], tvent[i - 1], Temp, Tav1, hcv1, qv1,
                        nperr, ErrorMessage
                    )
                    forcedventilation(
                        state,
                        state.dataTarcogShading.iprop2,
                        state.dataTarcogShading.frct2,
                        press2, nmix1, xwght, xgcon, xgvis, xgcp,
                        s2, height, hc1,
                        vvent[i], tvent[i], Temp, Tav2, hcv2, qv2,
                        nperr, ErrorMessage
                    )
                else:
                    shadingin(
                        state,
                        state.dataTarcogShading.iprop1,
                        state.dataTarcogShading.frct1,
                        press1, nmix1,
                        state.dataTarcogShading.iprop2,
                        state.dataTarcogShading.frct2,
                        press2, nmix2,
                        xwght, xgcon, xgvis, xgcp,
                        Atops, Abots, Als, Ars, Ahs,
                        s1, s2, height, width, angle,
                        hc1, hc2,
                        speed1, speed2, Tgap1, Tgap2, Tav1, Tav2,
                        hcv1, hcv2, qv1, qv2, nperr, ErrorMessage
                    )
                if (nperr > 0) and (nperr < 1000):
                    return
                hcgas[i - 1] = hcv1 / 2.0
                hcgas[i] = hcv2 / 2.0
                hgas[i - 1] = hcgas[i - 1] + hrgas[i - 1]
                hgas[i] = hcgas[i] + hrgas[i]
                hcv[i - 1] = hcv1
                hcv[i] = hcv2
                qv[i - 1] = qv1
                qv[i] = qv2
                Tgaps[i - 1] = Tgap1
                Tgaps[i] = Tgap2
                vfreevent[i - 1] = speed1
                vfreevent[i] = speed2

def forcedventilation(
    state: EnergyPlusData,
    iprop: List[Int],
    frct: List[Float64],
    press: Float64,
    nmix: Int,
    xwght: List[Float64],
    xgcon: List[List[Float64]],
    xgvis: List[List[Float64]],
    xgcp: List[List[Float64]],
    s: Float64,
    H: Float64,
    hc: Float64,
    forcedspeed: Float64,
    Tinlet: Float64,
    Toutlet: Float64,
    Tav: Float64,
    hcv: Float64,
    qv: Float64,
    nperr: Int,
    ErrorMessage: String
):
    EP_SIZE_CHECK(iprop, maxgas)
    EP_SIZE_CHECK(frct, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    # Note: xgcon.dim(3, maxgas) etc. - we assume arrays already sized appropriately
    var H0: Float64
    var dens: Float64
    var cp: Float64
    var pr: Float64
    var con: Float64
    var visc: Float64
    GASSES90(
        state, Tav, iprop, frct, press, nmix, xwght, xgcon, xgvis, xgcp,
        con, visc, dens, cp, pr, Stdrd.ISO15099, nperr, ErrorMessage
    )
    H0 = (dens * cp * s * forcedspeed) / (4.0 * hc + 8.0 * forcedspeed)
    Toutlet = Tav - (Tav - Tinlet) * Math.exp(-H / H0)
    qv = -dens * cp * forcedspeed * s * (Toutlet - Tinlet) / H
    hcv = 2.0 * hc + 4.0 * forcedspeed

def shadingin(
    state: EnergyPlusData,
    iprop1: List[Int],
    frct1: List[Float64],
    press1: Float64,
    nmix1: Int,
    iprop2: List[Int],
    frct2: List[Float64],
    press2: Float64,
    nmix2: Int,
    xwght: List[Float64],
    xgcon: List[List[Float64]],
    xgvis: List[List[Float64]],
    xgcp: List[List[Float64]],
    Atop: Float64,
    Abot: Float64,
    Al: Float64,
    Ar: Float64,
    Ah: Float64,
    s1: Float64,
    s2: Float64,
    H: Float64,
    L: Float64,
    angle: Float64,
    hc1: Float64,
    hc2: Float64,
    speed1: Float64,
    speed2: Float64,
    Tgap1: Float64,
    Tgap2: Float64,
    Tav1: Float64,
    Tav2: Float64,
    hcv1: Float64,
    hcv2: Float64,
    qv1: Float64,
    qv2: Float64,
    nperr: Int,
    ErrorMessage: String
):
    EP_SIZE_CHECK(iprop1, maxgas)
    EP_SIZE_CHECK(frct1, maxgas)
    EP_SIZE_CHECK(iprop2, maxgas)
    EP_SIZE_CHECK(frct2, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)

    var A: Float64
    var A1: Float64
    var A2: Float64
    var B1: Float64
    var B2: Float64
    var C1: Float64
    var C2: Float64
    var D1: Float64
    var D2: Float64
    var Zin1: Float64
    var Zin2: Float64
    var Zout1: Float64
    var Zout2: Float64
    var A1eqin: Float64
    var A1eqout: Float64
    var A2eqin: Float64
    var A2eqout: Float64
    var T0: Float64
    var tilt: Float64
    var dens0: Float64
    var visc0: Float64
    var con0: Float64
    var pr0: Float64
    var cp0: Float64
    var dens1: Float64
    var visc1: Float64
    var con1: Float64
    var pr1: Float64
    var cp1: Float64
    var dens2: Float64
    var visc2: Float64
    var con2: Float64
    var pr2: Float64
    var cp2: Float64
    var Tup: Float64
    var Tdown: Float64
    var H01: Float64
    var H02: Float64
    var beta1: Float64
    var beta2: Float64
    var alpha1: Float64
    var alpha2: Float64
    var P1: Float64
    var P2: Float64
    var qsmooth: Float64
    var iter: Int
    var TGapOld1: Float64
    var TGapOld2: Float64
    var Temp1: Float64
    var Temp2: Float64
    var converged: Bool

    TGapOld1 = 0.0
    TGapOld2 = 0.0
    tilt = Constant.Pi / 180.0 * (angle - 90.0)
    T0 = 0.0 + Constant.Kelvin
    A1eqin = 0.0
    A2eqout = 0.0
    A1eqout = 0.0
    A2eqin = 0.0
    P1 = 0.0
    P2 = 0.0

    GASSES90(
        state, T0, iprop1, frct1, press1, nmix1, xwght, xgcon, xgvis, xgcp,
        con0, visc0, dens0, cp0, pr0, Stdrd.ISO15099, nperr, ErrorMessage
    )
    if (nperr > 0) and (nperr < 1000):
        return
    if (Tgap1 * Tgap2) == 0:
        nperr = 15
        ErrorMessage = "Temperature of vented gap must be greater than 0 [K]."
        return
    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001

    converged = False
    iter = 0
    var s1_2: Float64 = pow_2(s1)
    var s2_2: Float64 = pow_2(s2)
    var s1_s2_2: Float64 = pow_2(s1 / s2)
    var cos_Tilt: Float64 = Math.cos(tilt)

    while not converged:
        iter += 1
        GASSES90(
            state, Tgap1, iprop1, frct1, press1, nmix1, xwght, xgcon, xgvis, xgcp,
            con1, visc1, dens1, cp1, pr1, Stdrd.ISO15099, nperr, ErrorMessage
        )
        GASSES90(
            state, Tgap2, iprop2, frct2, press2, nmix2, xwght, xgcon, xgvis, xgcp,
            con2, visc2, dens2, cp2, pr2, Stdrd.ISO15099, nperr, ErrorMessage
        )
        A = dens0 * T0 * Constant.Gravity * H * Math.abs(cos_Tilt) * Math.abs(Tgap1 - Tgap2) / (Tgap1 * Tgap2)
        if A == 0.0:
            qv1 = 0.0
            qv2 = 0.0
            speed1 = 0.0
            speed2 = 0.0
            hcv1 = 2.0 * hc1
            hcv2 = 2.0 * hc2
            return
        B1 = dens1 / 2.0
        B2 = (dens2 / 2.0) * s1_s2_2
        C1 = 12.0 * visc1 * H / s1_2
        C2 = 12.0 * visc2 * (H / s2_2) * (s1 / s2)
        if Tgap1 >= Tgap2:
            A1eqin = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A2eqout = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqout = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
            A2eqin = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
        else:
            A1eqout = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A2eqin = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqin = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
            A2eqout = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
        Zin1 = pow_2((s1 * L / (0.6 * A1eqin)) - 1.0)
        Zin2 = pow_2((s2 * L / (0.6 * A2eqin)) - 1.0)
        Zout1 = pow_2((s1 * L / (0.6 * A1eqout)) - 1.0)
        Zout2 = pow_2((s2 * L / (0.6 * A2eqout)) - 1.0)
        D1 = (dens1 / 2.0) * (Zin1 + Zout1)
        D2 = (dens2 / 2.0) * s1_s2_2 * (Zin2 + Zout2)
        A1 = B1 + D1 + B2 + D2
        A2 = C1 + C2
        speed1 = (Math.sqrt(pow_2(A2) + Math.abs(4.0 * A * A1)) - A2) / (2.0 * A1)
        speed2 = speed1 * s1 / s2

        H01 = (dens1 * cp1 * s1 * speed1) / (4.0 * hc1 + 8.0 * speed1)
        H02 = (dens2 * cp2 * s2 * speed2) / (4.0 * hc2 + 8.0 * speed2)
        if (H01 != 0.0) and (H02 != 0.0):
            P1 = -H / H01
            P2 = -H / H02
        beta1 = Math.exp(P1)
        beta2 = Math.exp(P2)
        alpha1 = 1.0 - beta1
        alpha2 = 1.0 - beta2

        if Tgap1 > Tgap2:
            Tup = (alpha1 * Tav1 + beta1 * alpha2 * Tav2) / (1.0 - beta1 * beta2)
            Tdown = alpha2 * Tav2 + beta2 * Tup
        else:
            Tdown = (alpha1 * Tav1 + beta1 * alpha2 * Tav2) / (1.0 - beta1 * beta2)
            Tup = alpha2 * Tav2 + beta2 * Tdown

        TGapOld1 = Tgap1
        TGapOld2 = Tgap2
        if Tgap1 > Tgap2:
            Temp1 = Tav1 - (H01 / H) * (Tup - Tdown)
            Temp2 = Tav2 - (H02 / H) * (Tdown - Tup)
        else:
            Temp1 = Tav1 - (H01 / H) * (Tdown - Tup)
            Temp2 = Tav2 - (H02 / H) * (Tup - Tdown)

        Tgap1 = AirflowRelaxationParameter * Temp1 + (1.0 - AirflowRelaxationParameter) * TGapOld1
        Tgap2 = AirflowRelaxationParameter * Temp2 + (1.0 - AirflowRelaxationParameter) * TGapOld2
        converged = False
        if (Math.abs(Tgap1 - TGapOld1) < AirflowConvergenceTolerance) or (iter >= NumOfIterations):
            if Math.abs(Tgap2 - TGapOld2) < AirflowConvergenceTolerance:
                converged = True

    hcv1 = 2.0 * hc1 + 4.0 * speed1
    hcv2 = 2.0 * hc2 + 4.0 * speed2

    if Tgap2 >= Tgap1:
        qv1 = -dens1 * cp1 * speed1 * s1 * L * (Tdown - Tup) / (H * L)
        qv2 = -dens2 * cp2 * speed2 * s2 * L * (Tup - Tdown) / (H * L)
    else:
        qv1 = dens1 * cp1 * speed1 * s1 * L * (Tdown - Tup) / (H * L)
        qv2 = dens2 * cp2 * speed2 * s2 * L * (Tup - Tdown) / (H * L)

    qsmooth = (Math.abs(qv1) + Math.abs(qv2)) / 2.0
    if qv1 > 0.0:
        qv1 = qsmooth
        qv2 = -qsmooth
    else:
        qv1 = -qsmooth
        qv2 = qsmooth

def shadingedge(
    state: EnergyPlusData,
    iprop1: List[Int],
    frct1: List[Float64],
    press1: Float64,
    nmix1: Int,
    iprop2: List[Int],
    frct2: List[Float64],
    press2: Float64,
    nmix2: Int,
    xwght: List[Float64],
    xgcon: List[List[Float64]],
    xgvis: List[List[Float64]],
    xgcp: List[List[Float64]],
    Atop: Float64,
    Abot: Float64,
    Al: Float64,
    Ar: Float64,
    Ah: Float64,
    s: Float64,
    H: Float64,
    L: Float64,
    angle: Float64,
    forcedspeed: Float64,
    hc: Float64,
    Tenv: Float64,
    Tav: Float64,
    Tgap: Float64,
    hcv: Float64,
    qv: Float64,
    nperr: Int,
    ErrorMessage: String,
    speed: Float64
):
    EP_SIZE_CHECK(iprop1, maxgas)
    EP_SIZE_CHECK(frct1, maxgas)
    EP_SIZE_CHECK(iprop2, maxgas)
    EP_SIZE_CHECK(frct2, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)

    var A: Float64
    var A1: Float64
    var A2: Float64
    var B1: Float64
    var C1: Float64
    var D1: Float64
    var Zin1: Float64
    var Zout1: Float64
    var A1eqin: Float64
    var A1eqout: Float64
    var T0: Float64
    var tilt: Float64
    var dens0: Float64
    var visc0: Float64
    var con0: Float64
    var pr0: Float64
    var cp0: Float64
    var dens2: Float64
    var visc2: Float64
    var con2: Float64
    var pr2: Float64
    var cp2: Float64
    var Tgapout: Float64
    var H0: Float64
    var P: Float64
    var beta: Float64
    var iter: Int
    var TGapOld: Float64
    var converged: Bool

    tilt = Constant.Pi / 180.0 * (angle - 90.0)
    T0 = 0.0 + Constant.Kelvin

    GASSES90(
        state, T0, iprop1, frct1, press1, nmix1, xwght, xgcon, xgvis, xgcp,
        con0, visc0, dens0, cp0, pr0, Stdrd.ISO15099, nperr, ErrorMessage
    )
    if (nperr > 0) and (nperr < 1000):
        return
    if (Tgap * Tenv) == 0.0:
        nperr = 15
        ErrorMessage = "Temperature of vented air must be greater then 0 [K]."
        return
    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001
    if (Ah + Al + Ar) == 0.0:
        Ah = 0.000001

    converged = False
    iter = 0
    var s_2: Float64 = pow_2(s)
    var abs_cos_tilt: Float64 = Math.abs(Math.cos(tilt))

    while not converged:
        iter += 1
        GASSES90(
            state, Tgap, iprop2, frct2, press2, nmix2, xwght, xgcon, xgvis, xgcp,
            con2, visc2, dens2, cp2, pr2, Stdrd.ISO15099, nperr, ErrorMessage
        )
        if (nperr > 0) and (nperr < 1000):
            return
        A = dens0 * T0 * Constant.Gravity * H * abs_cos_tilt * Math.abs(Tgap - Tenv) / (Tgap * Tenv)
        B1 = dens2 / 2.0
        C1 = 12.0 * visc2 * H / s_2
        if Tgap > Tenv:
            A1eqin = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqout = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
        else:
            A1eqout = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqin = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
        Zin1 = pow_2((s * L / (0.6 * A1eqin)) - 1.0)
        Zout1 = pow_2((s * L / (0.6 * A1eqout)) - 1.0)
        D1 = (dens2 / 2.0) * (Zin1 + Zout1)
        A1 = B1 + D1
        A2 = C1
        if forcedspeed != 0.0:
            speed = forcedspeed
        else:
            speed = (Math.sqrt(pow_2(A2) + Math.abs(4.0 * A * A1)) - A2) / (2.0 * A1)

        TGapOld = Tgap
        if speed != 0.0:
            H0 = (dens2 * cp2 * s * speed) / (4.0 * hc + 8.0 * speed)
            P = -H / H0
            if P < -700.0:
                beta = 0.0
            else:
                beta = Math.exp(P)
            Tgapout = Tav - (Tav - Tenv) * beta
            Tgap = Tav - (H0 / H) * (Tgapout - Tenv)
        else:
            Tgapout = Tav
            Tgap = Tav

        converged = False
        if (Math.abs(Tgap - TGapOld) < AirflowConvergenceTolerance) or (iter >= NumOfIterations):
            converged = True

    hcv = 2.0 * hc + 4.0 * speed
    qv = dens2 * cp2 * speed * s * L * (Tenv - Tgapout) / (H * L)

def updateEffectiveMultipliers(
    nlayer: Int,
    width: Float64,
    height: Float64,
    Atop: List[Float64],
    Abot: List[Float64],
    Al: List[Float64],
    Ar: List[Float64],
    Ah: List[Float64],
    Atop_eff: List[Float64],
    Abot_eff: List[Float64],
    Al_eff: List[Float64],
    Ar_eff: List[Float64],
    Ah_eff: List[Float64],
    LayerType: List[TARCOGLayerType],
    SlatAngle: List[Float64]
):
    for i in range(1, nlayer + 1):
        if (LayerType[i - 1] == TARCOGLayerType.VENETBLIND_HORIZ) or (LayerType[i - 1] == TARCOGLayerType.VENETBLIND_VERT):
            let slatAngRad = SlatAngle[i - 1] * 2.0 * Constant.Pi / 360.0
            var C1_VENET: Float64 = 0.0
            var C2_VENET: Float64 = 0.0
            var C3_VENET: Float64 = 0.0
            if LayerType[i - 1] == TARCOGLayerType.VENETBLIND_HORIZ:
                C1_VENET = C1_VENET_HORIZONTAL
                C2_VENET = C2_VENET_HORIZONTAL
                C3_VENET = C3_VENET_HORIZONTAL
            if LayerType[i - 1] == TARCOGLayerType.VENETBLIND_VERT:
                C1_VENET = C1_VENET_VERTICAL
                C2_VENET = C2_VENET_VERTICAL
                C3_VENET = C3_VENET_VERTICAL
            Ah_eff[i - 1] = width * height * C1_VENET * Math.pow(
                (Ah[i - 1] / (width * height)) * Math.pow(Math.cos(slatAngRad), C2_VENET),
                C3_VENET
            )
            Al_eff[i - 1] = 0.0
            Ar_eff[i - 1] = 0.0
            Atop_eff[i - 1] = Atop[i - 1]
            Abot_eff[i - 1] = Abot[i - 1]
        elif (LayerType[i - 1] == TARCOGLayerType.PERFORATED) or (LayerType[i - 1] == TARCOGLayerType.DIFFSHADE) or \
             (LayerType[i - 1] == TARCOGLayerType.BSDF) or (LayerType[i - 1] == TARCOGLayerType.WOVSHADE):
            Ah_eff[i - 1] = width * height * C1_SHADE * Math.pow((Ah[i - 1] / (width * height)), C2_SHADE)
            Al_eff[i - 1] = Al[i - 1] * C3_SHADE
            Ar_eff[i - 1] = Ar[i - 1] * C3_SHADE
            Atop_eff[i - 1] = Atop[i - 1] * C4_SHADE
            Abot_eff[i - 1] = Abot[i - 1] * C4_SHADE
        else:
            Ah_eff[i - 1] = Ah[i - 1]
            Al_eff[i - 1] = Al[i - 1]
            Ar_eff[i - 1] = Ar[i - 1]
            Atop_eff[i - 1] = Atop[i - 1]
            Abot_eff[i - 1] = Abot[i - 1]