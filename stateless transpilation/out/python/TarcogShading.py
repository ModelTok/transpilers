"""TarcogShading module - faithful Python port from C++"""

import math
from dataclasses import dataclass
from typing import List, Protocol, Any

# EXTERNAL DEPS (to wire in glue):
# - GASSES90(state, T, iprop, frct, press, nmix, xwght, xgcon, xgvis, xgcp, con, visc, dens, cp, pr, standard, nperr, ErrorMessage)
#   from TARCOGGasses90; mutates con, visc, dens, cp, pr in-place
# - maxgas: int from TARCOGGassesParams (typically 10)
# - Constant.Pi, Constant.Kelvin, Constant.Gravity from constants
# - TARCOGLayerType: enum with VENETBLIND_HORIZ, VENETBLIND_VERT, PERFORATED, DIFFSHADE, BSDF, WOVSHADE
# - IsShadingLayer(layer_type: int) -> bool from TARCOGCommon
# - AirflowRelaxationParameter, AirflowConvergenceTolerance, NumOfIterations from TARCOGParams
# - C1_VENET_HORIZONTAL, C2_VENET_HORIZONTAL, C3_VENET_HORIZONTAL from TARCOGParams
# - C1_VENET_VERTICAL, C2_VENET_VERTICAL, C3_VENET_VERTICAL from TARCOGParams
# - C1_SHADE, C2_SHADE, C3_SHADE, C4_SHADE from TARCOGParams
# - ISO15099 constant from TARCOGGassesParams.Stdrd


class EnergyPlusDataProtocol(Protocol):
    """Protocol for EnergyPlusData state object with dataTarcogShading attribute"""
    dataTarcogShading: 'TarcogShadingData'


@dataclass
class TarcogShadingData:
    """Shading data state container matching TarcogShadingData struct"""
    frct1: List[float]
    frct2: List[float]
    iprop1: List[int]
    iprop2: List[int]
    maxgas: int = 10

    def __init__(self, maxgas: int = 10):
        self.maxgas = maxgas
        self.frct1 = [0.0] * maxgas
        self.frct2 = [0.0] * maxgas
        self.iprop1 = [0] * maxgas
        self.iprop2 = [0] * maxgas

    def clear_state(self) -> None:
        """Reset to initial state"""
        self.frct1 = [0.0] * self.maxgas
        self.frct2 = [0.0] * self.maxgas
        self.iprop1 = [0] * self.maxgas
        self.iprop2 = [0] * self.maxgas


def shading(state: EnergyPlusDataProtocol,
            theta: List[float],
            gap: List[float],
            hgas: List[float],
            hcgas: List[float],
            hrgas: List[float],
            frct: List[List[float]],
            iprop: List[List[int]],
            pressure: List[float],
            nmix: List[int],
            xwght: List[float],
            xgcon: List[List[float]],
            xgvis: List[List[float]],
            xgcp: List[List[float]],
            nlayer: int,
            width: float,
            height: float,
            angle: float,
            Tout: float,
            Tin: float,
            Atop: List[float],
            Abot: List[float],
            Al: List[float],
            Ar: List[float],
            Ah: List[float],
            vvent: List[float],
            tvent: List[float],
            LayerType: List[int],
            Tgaps: List[float],
            qv: List[float],
            hcv: List[float],
            nperr: List[int],
            ErrorMessage: List[str],
            vfreevent: List[float],
            maxgas: int,
            IsShadingLayer,
            GASSES90,
            Constant,
            AirflowRelaxationParameter,
            AirflowConvergenceTolerance,
            NumOfIterations,
            ISO15099,
            e) -> None:
    """Main shading function"""

    Atops = 0.0
    Abots = 0.0
    Als = 0.0
    Ars = 0.0
    Ahs = 0.0
    press1 = 0.0
    press2 = 0.0
    s1 = 0.0
    s2 = 0.0
    s = 0.0
    hcvs = 0.0
    qvs = 0.0
    hc = 0.0
    hc1 = 0.0
    hc2 = 0.0
    speed = 0.0
    Tav = 0.0
    Tgap = 0.0
    Temp = 0.0
    speed1 = 0.0
    speed2 = 0.0
    Tav1 = 0.0
    Tav2 = 0.0
    Tgap1 = 0.0
    Tgap2 = 0.0
    hcv1 = 0.0
    hcv2 = 0.0
    qv1 = 0.0
    qv2 = 0.0

    nmix1 = 0
    nmix2 = 0

    # init vectors
    for idx in range(len(qv)):
        qv[idx] = 0.0
    for idx in range(len(hcv)):
        hcv[idx] = 0.0

    # main loop (convert 1-based to 0-based)
    for i in range(nlayer):
        if IsShadingLayer(LayerType[i]):
            # set Shading device geometry
            Atops = Atop[i]
            Abots = Abot[i]
            Als = Al[i]
            Ars = Ar[i]
            Ahs = Ah[i]

            # setting gas properties for two adjacent gaps
            nmix1 = nmix[i]
            nmix2 = nmix[i + 1]
            press1 = pressure[i]
            press2 = pressure[i + 1]
            for j in range(maxgas):
                state.dataTarcogShading.iprop1[j] = iprop[j][i]
                state.dataTarcogShading.iprop2[j] = iprop[j][i + 1]
                state.dataTarcogShading.frct1[j] = frct[j][i]
                state.dataTarcogShading.frct2[j] = frct[j][i + 1]

            # shading on outdoor side
            if i == 0:
                s = gap[0]
                hc = hcgas[1]
                Tav = (theta[1] + theta[2]) / 2.0
                Tgap = Tgaps[1]

                shadingedge(state,
                            state.dataTarcogShading.iprop1,
                            state.dataTarcogShading.frct1,
                            press1,
                            nmix1,
                            state.dataTarcogShading.iprop2,
                            state.dataTarcogShading.frct2,
                            press2,
                            nmix2,
                            xwght,
                            xgcon,
                            xgvis,
                            xgcp,
                            Atops,
                            Abots,
                            Als,
                            Ars,
                            Ahs,
                            s,
                            height,
                            width,
                            angle,
                            vvent[1],
                            hc,
                            Tout,
                            Tav,
                            Tgap,
                            hcvs,
                            qvs,
                            nperr,
                            ErrorMessage,
                            speed,
                            maxgas,
                            GASSES90,
                            Constant,
                            ISO15099,
                            e)

                if (nperr[0] > 0) and (nperr[0] < 1000):
                    return

                Tgaps[1] = Tgap
                hcgas[1] = hcvs / 2.0
                hgas[1] = hcgas[1] + hrgas[1]
                hcv[1] = hcvs
                qv[1] = qvs
                vfreevent[1] = speed

            # shading on indoor side
            if i == nlayer - 1:
                if nlayer > 1:
                    s = gap[nlayer - 2]
                    Tav = (theta[2 * nlayer - 2] + theta[2 * nlayer - 3]) / 2.0
                else:
                    s = 0.0
                    Tav = 273.15

                hc = hcgas[nlayer - 1]
                Tgap = Tgaps[nlayer - 1]

                shadingedge(state,
                            state.dataTarcogShading.iprop2,
                            state.dataTarcogShading.frct2,
                            press2,
                            nmix2,
                            state.dataTarcogShading.iprop1,
                            state.dataTarcogShading.frct1,
                            press1,
                            nmix1,
                            xwght,
                            xgcon,
                            xgvis,
                            xgcp,
                            Atops,
                            Abots,
                            Als,
                            Ars,
                            Ahs,
                            s,
                            height,
                            width,
                            angle,
                            vvent[nlayer - 1],
                            hc,
                            Tin,
                            Tav,
                            Tgap,
                            hcvs,
                            qvs,
                            nperr,
                            ErrorMessage,
                            speed,
                            maxgas,
                            GASSES90,
                            Constant,
                            ISO15099,
                            e)

                if (nperr[0] > 0) and (nperr[0] < 1000):
                    return

                Tgaps[nlayer - 1] = Tgap
                hcgas[nlayer - 1] = hcvs / 2.0
                hgas[nlayer - 1] = hcgas[nlayer - 1] + hrgas[nlayer - 1]
                hcv[nlayer - 1] = hcvs
                qv[nlayer - 1] = qvs
                vfreevent[i] = speed

            # shading between glass layers
            if (i > 0) and (i < nlayer - 1):
                Tav1 = (theta[2 * i - 1] + theta[2 * i]) / 2.0
                Tav2 = (theta[2 * i + 1] + theta[2 * i + 2]) / 2.0
                Tgap1 = Tgaps[i]
                Tgap2 = Tgaps[i + 1]

                hc1 = hcgas[i]
                hc2 = hcgas[i + 1]
                if i > 0:
                    s1 = gap[i - 1]
                s2 = gap[i]

                if (vvent[i] != 0) or (vvent[i + 1] != 0):
                    forcedventilation(state,
                                    state.dataTarcogShading.iprop1,
                                    state.dataTarcogShading.frct1,
                                    press1,
                                    nmix1,
                                    xwght,
                                    xgcon,
                                    xgvis,
                                    xgcp,
                                    s1,
                                    height,
                                    hc1,
                                    vvent[i],
                                    tvent[i],
                                    Temp,
                                    Tav1,
                                    hcv1,
                                    qv1,
                                    nperr,
                                    ErrorMessage,
                                    maxgas,
                                    GASSES90,
                                    Constant,
                                    ISO15099)
                    forcedventilation(state,
                                    state.dataTarcogShading.iprop2,
                                    state.dataTarcogShading.frct2,
                                    press2,
                                    nmix1,
                                    xwght,
                                    xgcon,
                                    xgvis,
                                    xgcp,
                                    s2,
                                    height,
                                    hc1,
                                    vvent[i + 1],
                                    tvent[i + 1],
                                    Temp,
                                    Tav2,
                                    hcv2,
                                    qv2,
                                    nperr,
                                    ErrorMessage,
                                    maxgas,
                                    GASSES90,
                                    Constant,
                                    ISO15099)
                else:
                    shadingin(state,
                            state.dataTarcogShading.iprop1,
                            state.dataTarcogShading.frct1,
                            press1,
                            nmix1,
                            state.dataTarcogShading.iprop2,
                            state.dataTarcogShading.frct2,
                            press2,
                            nmix2,
                            xwght,
                            xgcon,
                            xgvis,
                            xgcp,
                            Atops,
                            Abots,
                            Als,
                            Ars,
                            Ahs,
                            s1,
                            s2,
                            height,
                            width,
                            angle,
                            hc1,
                            hc2,
                            speed1,
                            speed2,
                            Tgap1,
                            Tgap2,
                            Tav1,
                            Tav2,
                            hcv1,
                            hcv2,
                            qv1,
                            qv2,
                            nperr,
                            ErrorMessage,
                            maxgas,
                            GASSES90,
                            Constant,
                            AirflowRelaxationParameter,
                            AirflowConvergenceTolerance,
                            NumOfIterations,
                            ISO15099,
                            e)

                if (nperr[0] > 0) and (nperr[0] < 1000):
                    return

                hcgas[i] = hcv1 / 2.0
                hcgas[i + 1] = hcv2 / 2.0
                hgas[i] = hcgas[i] + hrgas[i]
                hgas[i + 1] = hcgas[i + 1] + hrgas[i + 1]
                hcv[i] = hcv1
                hcv[i + 1] = hcv2
                qv[i] = qv1
                qv[i + 1] = qv2
                Tgaps[i] = Tgap1
                Tgaps[i + 1] = Tgap2
                vfreevent[i] = speed1
                vfreevent[i + 1] = speed2


def forcedventilation(state: EnergyPlusDataProtocol,
                      iprop: List[int],
                      frct: List[float],
                      press: float,
                      nmix: int,
                      xwght: List[float],
                      xgcon: List[List[float]],
                      xgvis: List[List[float]],
                      xgcp: List[List[float]],
                      s: float,
                      H: float,
                      hc: float,
                      forcedspeed: float,
                      Tinlet: float,
                      Toutlet: float,
                      Tav: float,
                      hcv: float,
                      qv: float,
                      nperr: List[int],
                      ErrorMessage: List[str],
                      maxgas: int,
                      GASSES90,
                      Constant,
                      ISO15099,
                      e) -> None:
    """Handle forced ventilation"""

    con = 0.0
    visc = 0.0
    dens = 0.0
    cp = 0.0
    pr = 0.0

    GASSES90(state,
             Tav,
             iprop,
             frct,
             press,
             nmix,
             xwght,
             xgcon,
             xgvis,
             xgcp,
             con,
             visc,
             dens,
             cp,
             pr,
             ISO15099,
             nperr,
             ErrorMessage,
             maxgas)

    H0 = (dens * cp * s * forcedspeed) / (4.0 * hc + 8.0 * forcedspeed)

    Toutlet = Tav - (Tav - Tinlet) * pow(e, -H / H0)

    qv = -dens * cp * forcedspeed * s * (Toutlet - Tinlet) / H

    hcv = 2.0 * hc + 4.0 * forcedspeed


def shadingin(state: EnergyPlusDataProtocol,
              iprop1: List[int],
              frct1: List[float],
              press1: float,
              nmix1: int,
              iprop2: List[int],
              frct2: List[float],
              press2: float,
              nmix2: int,
              xwght: List[float],
              xgcon: List[List[float]],
              xgvis: List[List[float]],
              xgcp: List[List[float]],
              Atop: float,
              Abot: float,
              Al: float,
              Ar: float,
              Ah: float,
              s1: float,
              s2: float,
              H: float,
              L: float,
              angle: float,
              hc1: float,
              hc2: float,
              speed1: float,
              speed2: float,
              Tgap1: float,
              Tgap2: float,
              Tav1: float,
              Tav2: float,
              hcv1: float,
              hcv2: float,
              qv1: float,
              qv2: float,
              nperr: List[int],
              ErrorMessage: List[str],
              maxgas: int,
              GASSES90,
              Constant,
              AirflowRelaxationParameter,
              AirflowConvergenceTolerance,
              NumOfIterations,
              ISO15099,
              e) -> None:
    """Handle shading between glass layers"""

    A = 0.0
    A1 = 0.0
    A2 = 0.0
    B1 = 0.0
    B2 = 0.0
    C1 = 0.0
    C2 = 0.0
    D1 = 0.0
    D2 = 0.0
    Zin1 = 0.0
    Zin2 = 0.0
    Zout1 = 0.0
    Zout2 = 0.0
    A1eqin = 0.0
    A1eqout = 0.0
    A2eqin = 0.0
    A2eqout = 0.0
    T0 = 0.0
    tilt = 0.0
    dens0 = 0.0
    visc0 = 0.0
    con0 = 0.0
    pr0 = 0.0
    cp0 = 0.0
    dens1 = 0.0
    visc1 = 0.0
    con1 = 0.0
    pr1 = 0.0
    cp1 = 0.0
    dens2 = 0.0
    visc2 = 0.0
    con2 = 0.0
    pr2 = 0.0
    cp2 = 0.0
    Tup = 0.0
    Tdown = 0.0
    H01 = 0.0
    H02 = 0.0
    beta1 = 0.0
    beta2 = 0.0
    alpha1 = 0.0
    alpha2 = 0.0
    P1 = 0.0
    P2 = 0.0
    qsmooth = 0.0

    iter = 0
    TGapOld1 = 0.0
    TGapOld2 = 0.0
    Temp1 = 0.0
    Temp2 = 0.0
    converged = False

    tilt = Constant.Pi / 180.0 * (angle - 90.0)
    T0 = 0.0 + Constant.Kelvin
    A1eqin = 0.0
    A2eqout = 0.0
    A1eqout = 0.0
    A2eqin = 0.0
    P1 = 0.0
    P2 = 0.0

    GASSES90(state,
             T0,
             iprop1,
             frct1,
             press1,
             nmix1,
             xwght,
             xgcon,
             xgvis,
             xgcp,
             con0,
             visc0,
             dens0,
             cp0,
             pr0,
             ISO15099,
             nperr,
             ErrorMessage,
             maxgas)

    if (nperr[0] > 0) and (nperr[0] < 1000):
        return

    if (Tgap1 * Tgap2) == 0:
        nperr[0] = 15
        ErrorMessage[0] = "Temperature of vented gap must be greater than 0 [K]."
        return

    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001

    converged = False
    iter = 0
    s1_2 = s1 ** 2
    s2_2 = s2 ** 2
    s1_s2_2 = (s1 / s2) ** 2
    cos_Tilt = math.cos(tilt)

    while not converged:
        iter += 1
        GASSES90(state,
                 Tgap1,
                 iprop1,
                 frct1,
                 press1,
                 nmix1,
                 xwght,
                 xgcon,
                 xgvis,
                 xgcp,
                 con1,
                 visc1,
                 dens1,
                 cp1,
                 pr1,
                 ISO15099,
                 nperr,
                 ErrorMessage,
                 maxgas)
        GASSES90(state,
                 Tgap2,
                 iprop2,
                 frct2,
                 press2,
                 nmix2,
                 xwght,
                 xgcon,
                 xgvis,
                 xgcp,
                 con2,
                 visc2,
                 dens2,
                 cp2,
                 pr2,
                 ISO15099,
                 nperr,
                 ErrorMessage,
                 maxgas)

        A = dens0 * T0 * Constant.Gravity * H * abs(cos_Tilt) * abs(Tgap1 - Tgap2) / (Tgap1 * Tgap2)

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

        Zin1 = ((s1 * L / (0.6 * A1eqin)) - 1.0) ** 2
        Zin2 = ((s2 * L / (0.6 * A2eqin)) - 1.0) ** 2
        Zout1 = ((s1 * L / (0.6 * A1eqout)) - 1.0) ** 2
        Zout2 = ((s2 * L / (0.6 * A2eqout)) - 1.0) ** 2

        D1 = (dens1 / 2.0) * (Zin1 + Zout1)
        D2 = (dens2 / 2.0) * s1_s2_2 * (Zin2 + Zout2)

        A1 = B1 + D1 + B2 + D2
        A2 = C1 + C2

        speed1 = (math.sqrt(A2 ** 2 + abs(4.0 * A * A1)) - A2) / (2.0 * A1)
        speed2 = speed1 * s1 / s2

        H01 = (dens1 * cp1 * s1 * speed1) / (4.0 * hc1 + 8.0 * speed1)
        H02 = (dens2 * cp2 * s2 * speed2) / (4.0 * hc2 + 8.0 * speed2)

        if (H01 != 0.0) and (H02 != 0.0):
            P1 = -H / H01
            P2 = -H / H02

        beta1 = pow(e, P1)
        beta2 = pow(e, P2)

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
        if (abs(Tgap1 - TGapOld1) < AirflowConvergenceTolerance) or (iter >= NumOfIterations):
            if abs(Tgap2 - TGapOld2) < AirflowConvergenceTolerance:
                converged = True

    hcv1 = 2.0 * hc1 + 4.0 * speed1
    hcv2 = 2.0 * hc2 + 4.0 * speed2

    if Tgap2 >= Tgap1:
        qv1 = -dens1 * cp1 * speed1 * s1 * L * (Tdown - Tup) / (H * L)
        qv2 = -dens2 * cp2 * speed2 * s2 * L * (Tup - Tdown) / (H * L)
    else:
        qv1 = dens1 * cp1 * speed1 * s1 * L * (Tdown - Tup) / (H * L)
        qv2 = dens2 * cp2 * speed2 * s2 * L * (Tup - Tdown) / (H * L)

    qsmooth = (abs(qv1) + abs(qv2)) / 2.0

    if qv1 > 0.0:
        qv1 = qsmooth
        qv2 = -qsmooth
    else:
        qv1 = -qsmooth
        qv2 = qsmooth


def shadingedge(state: EnergyPlusDataProtocol,
                iprop1: List[int],
                frct1: List[float],
                press1: float,
                nmix1: int,
                iprop2: List[int],
                frct2: List[float],
                press2: float,
                nmix2: int,
                xwght: List[float],
                xgcon: List[List[float]],
                xgvis: List[List[float]],
                xgcp: List[List[float]],
                Atop: float,
                Abot: float,
                Al: float,
                Ar: float,
                Ah: float,
                s: float,
                H: float,
                L: float,
                angle: float,
                forcedspeed: float,
                hc: float,
                Tenv: float,
                Tav: float,
                Tgap: float,
                hcv: float,
                qv: float,
                nperr: List[int],
                ErrorMessage: List[str],
                speed: float,
                maxgas: int,
                GASSES90,
                Constant,
                ISO15099,
                e) -> None:
    """Handle shading at edges"""

    A = 0.0
    A1 = 0.0
    A2 = 0.0
    B1 = 0.0
    C1 = 0.0
    D1 = 0.0
    Zin1 = 0.0
    Zout1 = 0.0
    A1eqin = 0.0
    A1eqout = 0.0
    T0 = 0.0
    tilt = 0.0
    dens0 = 0.0
    visc0 = 0.0
    con0 = 0.0
    pr0 = 0.0
    cp0 = 0.0
    dens2 = 0.0
    visc2 = 0.0
    con2 = 0.0
    pr2 = 0.0
    cp2 = 0.0
    Tgapout = 0.0
    H0 = 0.0
    P = 0.0
    beta = 0.0

    iter = 0
    TGapOld = 0.0
    converged = False

    tilt = Constant.Pi / 180.0 * (angle - 90.0)
    T0 = 0.0 + Constant.Kelvin

    GASSES90(state,
             T0,
             iprop1,
             frct1,
             press1,
             nmix1,
             xwght,
             xgcon,
             xgvis,
             xgcp,
             con0,
             visc0,
             dens0,
             cp0,
             pr0,
             ISO15099,
             nperr,
             ErrorMessage,
             maxgas)

    if (nperr[0] > 0) and (nperr[0] < 1000):
        return

    if (Tgap * Tenv) == 0.0:
        nperr[0] = 15
        ErrorMessage[0] = "Temperature of vented air must be greater then 0 [K]."
        return

    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001
    if (Ah + Al + Ar) == 0.0:
        Ah = 0.000001

    converged = False
    iter = 0
    s_2 = s ** 2
    abs_cos_tilt = abs(math.cos(tilt))

    while not converged:
        iter += 1
        GASSES90(state,
                 Tgap,
                 iprop2,
                 frct2,
                 press2,
                 nmix2,
                 xwght,
                 xgcon,
                 xgvis,
                 xgcp,
                 con2,
                 visc2,
                 dens2,
                 cp2,
                 pr2,
                 ISO15099,
                 nperr,
                 ErrorMessage,
                 maxgas)

        if (nperr[0] > 0) and (nperr[0] < 1000):
            return

        A = dens0 * T0 * Constant.Gravity * H * abs_cos_tilt * abs(Tgap - Tenv) / (Tgap * Tenv)

        B1 = dens2 / 2.0
        C1 = 12.0 * visc2 * H / s_2

        if Tgap > Tenv:
            A1eqin = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqout = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)
        else:
            A1eqout = Abot + 0.5 * Atop * (Al + Ar + Ah) / (Abot + Atop)
            A1eqin = Atop + 0.5 * Abot * (Al + Ar + Ah) / (Abot + Atop)

        Zin1 = ((s * L / (0.6 * A1eqin)) - 1.0) ** 2
        Zout1 = ((s * L / (0.6 * A1eqout)) - 1.0) ** 2

        D1 = (dens2 / 2.0) * (Zin1 + Zout1)

        A1 = B1 + D1
        A2 = C1

        if forcedspeed != 0.0:
            speed = forcedspeed
        else:
            speed = (math.sqrt(A2 ** 2 + abs(4.0 * A * A1)) - A2) / (2.0 * A1)

        TGapOld = Tgap

        if speed != 0.0:
            H0 = (dens2 * cp2 * s * speed) / (4.0 * hc + 8.0 * speed)

            P = -H / H0
            if P < -700.0:
                beta = 0.0
            else:
                beta = pow(e, P)
            Tgapout = Tav - (Tav - Tenv) * beta
            Tgap = Tav - (H0 / H) * (Tgapout - Tenv)
        else:
            Tgapout = Tav
            Tgap = Tav

        converged = False
        if (abs(Tgap - TGapOld) < AirflowConvergenceTolerance) or (iter >= NumOfIterations):
            converged = True

    hcv = 2.0 * hc + 4.0 * speed

    qv = dens2 * cp2 * speed * s * L * (Tenv - Tgapout) / (H * L)


def updateEffectiveMultipliers(nlayer: int,
                               width: float,
                               height: float,
                               Atop: List[float],
                               Abot: List[float],
                               Al: List[float],
                               Ar: List[float],
                               Ah: List[float],
                               Atop_eff: List[float],
                               Abot_eff: List[float],
                               Al_eff: List[float],
                               Ar_eff: List[float],
                               Ah_eff: List[float],
                               LayerType: List[int],
                               SlatAngle: List[float],
                               VENETBLIND_HORIZ,
                               VENETBLIND_VERT,
                               PERFORATED,
                               DIFFSHADE,
                               BSDF,
                               WOVSHADE,
                               C1_VENET_HORIZONTAL,
                               C2_VENET_HORIZONTAL,
                               C3_VENET_HORIZONTAL,
                               C1_VENET_VERTICAL,
                               C2_VENET_VERTICAL,
                               C3_VENET_VERTICAL,
                               C1_SHADE,
                               C2_SHADE,
                               C3_SHADE,
                               C4_SHADE,
                               Constant) -> None:
    """Update effective multipliers for layer openings"""

    for i in range(nlayer):
        if LayerType[i] == VENETBLIND_HORIZ or LayerType[i] == VENETBLIND_VERT:
            slatAngRad = SlatAngle[i] * 2 * Constant.Pi / 360.0
            C1_VENET = 0.0
            C2_VENET = 0.0
            C3_VENET = 0.0

            if LayerType[i] == VENETBLIND_HORIZ:
                C1_VENET = C1_VENET_HORIZONTAL
                C2_VENET = C2_VENET_HORIZONTAL
                C3_VENET = C3_VENET_HORIZONTAL
            if LayerType[i] == VENETBLIND_VERT:
                C1_VENET = C1_VENET_VERTICAL
                C2_VENET = C2_VENET_VERTICAL
                C3_VENET = C3_VENET_VERTICAL

            Ah_eff[i] = width * height * C1_VENET * pow((Ah[i] / (width * height)) * pow(math.cos(slatAngRad), C2_VENET), C3_VENET)
            Al_eff[i] = 0.0
            Ar_eff[i] = 0.0
            Atop_eff[i] = Atop[i]
            Abot_eff[i] = Abot[i]
        elif LayerType[i] == PERFORATED or LayerType[i] == DIFFSHADE or LayerType[i] == BSDF or LayerType[i] == WOVSHADE:
            Ah_eff[i] = width * height * C1_SHADE * pow((Ah[i] / (width * height)), C2_SHADE)
            Al_eff[i] = Al[i] * C3_SHADE
            Ar_eff[i] = Ar[i] * C3_SHADE
            Atop_eff[i] = Atop[i] * C4_SHADE
            Abot_eff[i] = Abot[i] * C4_SHADE
        else:
            Ah_eff[i] = Ah[i]
            Al_eff[i] = Al[i]
            Ar_eff[i] = Ar[i]
            Atop_eff[i] = Atop[i]
            Abot_eff[i] = Abot[i]
