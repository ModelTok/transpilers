"""TarcogShading module - faithful Mojo port from C++"""

from collections import InlineArray
from math import pi, e, cos, sin, sqrt, abs, pow
import math

alias maxgas_default = 10


struct TarcogShadingData:
    """Shading data state container"""
    var frct1: InlineArray[Float64, 10]
    var frct2: InlineArray[Float64, 10]
    var iprop1: InlineArray[Int32, 10]
    var iprop2: InlineArray[Int32, 10]

    fn __init__(inout self):
        self.frct1 = InlineArray[Float64, 10](fill=0.0)
        self.frct2 = InlineArray[Float64, 10](fill=0.0)
        self.iprop1 = InlineArray[Int32, 10](fill=0)
        self.iprop2 = InlineArray[Int32, 10](fill=0)

    fn clear_state(inout self) -> None:
        self.frct1 = InlineArray[Float64, 10](fill=0.0)
        self.frct2 = InlineArray[Float64, 10](fill=0.0)
        self.iprop1 = InlineArray[Int32, 10](fill=0)
        self.iprop2 = InlineArray[Int32, 10](fill=0)


# EXTERNAL DEPS (to wire in glue):
# - GASSES90(state, T, iprop, frct, press, nmix, xwght, xgcon, xgvis, xgcp, con, visc, dens, cp, pr, standard, nperr, ErrorMessage, maxgas)
#   from TARCOGGasses90; mutates con, visc, dens, cp, pr in-place
# - maxgas: int from TARCOGGassesParams (typically 10)
# - Constant.Pi, Constant.Kelvin, Constant.Gravity from constants
# - IsShadingLayer(layer_type: Int32) -> Bool from TARCOGCommon
# - AirflowRelaxationParameter, AirflowConvergenceTolerance, NumOfIterations from TARCOGParams
# - C1_VENET_HORIZONTAL, C2_VENET_HORIZONTAL, C3_VENET_HORIZONTAL from TARCOGParams
# - C1_VENET_VERTICAL, C2_VENET_VERTICAL, C3_VENET_VERTICAL from TARCOGParams
# - C1_SHADE, C2_SHADE, C3_SHADE, C4_SHADE from TARCOGParams
# - ISO15099 constant from TARCOGGassesParams.Stdrd


@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x


fn shading(state: UnsafePointer[TarcogShadingData],
           theta: UnsafePointer[Float64],
           gap: UnsafePointer[Float64],
           hgas: UnsafePointer[Float64],
           hcgas: UnsafePointer[Float64],
           hrgas: UnsafePointer[Float64],
           frct: UnsafePointer[UnsafePointer[Float64]],
           iprop: UnsafePointer[UnsafePointer[Int32]],
           pressure: UnsafePointer[Float64],
           nmix: UnsafePointer[Int32],
           xwght: UnsafePointer[Float64],
           xgcon: UnsafePointer[UnsafePointer[Float64]],
           xgvis: UnsafePointer[UnsafePointer[Float64]],
           xgcp: UnsafePointer[UnsafePointer[Float64]],
           nlayer: Int32,
           width: Float64,
           height: Float64,
           angle: Float64,
           Tout: Float64,
           Tin: Float64,
           Atop: UnsafePointer[Float64],
           Abot: UnsafePointer[Float64],
           Al: UnsafePointer[Float64],
           Ar: UnsafePointer[Float64],
           Ah: UnsafePointer[Float64],
           vvent: UnsafePointer[Float64],
           tvent: UnsafePointer[Float64],
           LayerType: UnsafePointer[Int32],
           Tgaps: UnsafePointer[Float64],
           qv: UnsafePointer[Float64],
           hcv: UnsafePointer[Float64],
           nperr: UnsafePointer[Int32],
           ErrorMessage: UnsafePointer[UnsafePointer[UInt8]],
           vfreevent: UnsafePointer[Float64],
           maxgas: Int32,
           GASSES90,
           Constant,
           IsShadingLayer,
           ISO15099,
           e_const: Float64) -> None:
    """Main shading function"""

    var Atops: Float64 = 0.0
    var Abots: Float64 = 0.0
    var Als: Float64 = 0.0
    var Ars: Float64 = 0.0
    var Ahs: Float64 = 0.0
    var press1: Float64 = 0.0
    var press2: Float64 = 0.0
    var s1: Float64 = 0.0
    var s2: Float64 = 0.0
    var s: Float64 = 0.0
    var hcvs: Float64 = 0.0
    var qvs: Float64 = 0.0
    var hc: Float64 = 0.0
    var hc1: Float64 = 0.0
    var hc2: Float64 = 0.0
    var speed: Float64 = 0.0
    var Tav: Float64 = 0.0
    var Tgap: Float64 = 0.0
    var Temp: Float64 = 0.0
    var speed1: Float64 = 0.0
    var speed2: Float64 = 0.0
    var Tav1: Float64 = 0.0
    var Tav2: Float64 = 0.0
    var Tgap1: Float64 = 0.0
    var Tgap2: Float64 = 0.0
    var hcv1: Float64 = 0.0
    var hcv2: Float64 = 0.0
    var qv1: Float64 = 0.0
    var qv2: Float64 = 0.0

    var nmix1: Int32 = 0
    var nmix2: Int32 = 0

    # init vectors
    for idx in range(nlayer + 1):
        qv[idx] = 0.0
    for idx in range(nlayer + 1):
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
                state[].iprop1[j] = iprop[j][i]
                state[].iprop2[j] = iprop[j][i + 1]
                state[].frct1[j] = frct[j][i]
                state[].frct2[j] = frct[j][i + 1]

            # shading on outdoor side
            if i == 0:
                s = gap[0]
                hc = hcgas[1]
                Tav = (theta[1] + theta[2]) / 2.0
                Tgap = Tgaps[1]

                shadingedge(state,
                            UnsafePointer(state[].iprop1),
                            UnsafePointer(state[].frct1),
                            press1,
                            nmix1,
                            UnsafePointer(state[].iprop2),
                            UnsafePointer(state[].frct2),
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
                            e_const)

                if (nperr[] > 0) and (nperr[] < 1000):
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
                            UnsafePointer(state[].iprop2),
                            UnsafePointer(state[].frct2),
                            press2,
                            nmix2,
                            UnsafePointer(state[].iprop1),
                            UnsafePointer(state[].frct1),
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
                            e_const)

                if (nperr[] > 0) and (nperr[] < 1000):
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
                                    UnsafePointer(state[].iprop1),
                                    UnsafePointer(state[].frct1),
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
                                    UnsafePointer(state[].iprop2),
                                    UnsafePointer(state[].frct2),
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
                            UnsafePointer(state[].iprop1),
                            UnsafePointer(state[].frct1),
                            press1,
                            nmix1,
                            UnsafePointer(state[].iprop2),
                            UnsafePointer(state[].frct2),
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
                            e_const)

                if (nperr[] > 0) and (nperr[] < 1000):
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


fn forcedventilation(state: UnsafePointer[TarcogShadingData],
                     iprop: UnsafePointer[Int32],
                     frct: UnsafePointer[Float64],
                     press: Float64,
                     nmix: Int32,
                     xwght: UnsafePointer[Float64],
                     xgcon: UnsafePointer[UnsafePointer[Float64]],
                     xgvis: UnsafePointer[UnsafePointer[Float64]],
                     xgcp: UnsafePointer[UnsafePointer[Float64]],
                     s: Float64,
                     H: Float64,
                     hc: Float64,
                     forcedspeed: Float64,
                     Tinlet: Float64,
                     Toutlet: Float64,
                     Tav: Float64,
                     hcv: Float64,
                     qv: Float64,
                     nperr: UnsafePointer[Int32],
                     ErrorMessage: UnsafePointer[UnsafePointer[UInt8]],
                     maxgas: Int32,
                     GASSES90,
                     Constant,
                     ISO15099) -> None:
    """Handle forced ventilation"""

    var con: Float64 = 0.0
    var visc: Float64 = 0.0
    var dens: Float64 = 0.0
    var cp: Float64 = 0.0
    var pr: Float64 = 0.0

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

    var H0: Float64 = (dens * cp * s * forcedspeed) / (4.0 * hc + 8.0 * forcedspeed)

    Toutlet = Tav - (Tav - Tinlet) * pow(e_const, -H / H0)

    qv = -dens * cp * forcedspeed * s * (Toutlet - Tinlet) / H

    hcv = 2.0 * hc + 4.0 * forcedspeed


fn shadingin(state: UnsafePointer[TarcogShadingData],
             iprop1: UnsafePointer[Int32],
             frct1: UnsafePointer[Float64],
             press1: Float64,
             nmix1: Int32,
             iprop2: UnsafePointer[Int32],
             frct2: UnsafePointer[Float64],
             press2: Float64,
             nmix2: Int32,
             xwght: UnsafePointer[Float64],
             xgcon: UnsafePointer[UnsafePointer[Float64]],
             xgvis: UnsafePointer[UnsafePointer[Float64]],
             xgcp: UnsafePointer[UnsafePointer[Float64]],
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
             nperr: UnsafePointer[Int32],
             ErrorMessage: UnsafePointer[UnsafePointer[UInt8]],
             maxgas: Int32,
             GASSES90,
             Constant,
             AirflowRelaxationParameter,
             AirflowConvergenceTolerance,
             NumOfIterations,
             ISO15099,
             e_const: Float64) -> None:
    """Handle shading between glass layers"""

    var A: Float64 = 0.0
    var A1: Float64 = 0.0
    var A2: Float64 = 0.0
    var B1: Float64 = 0.0
    var B2: Float64 = 0.0
    var C1: Float64 = 0.0
    var C2: Float64 = 0.0
    var D1: Float64 = 0.0
    var D2: Float64 = 0.0
    var Zin1: Float64 = 0.0
    var Zin2: Float64 = 0.0
    var Zout1: Float64 = 0.0
    var Zout2: Float64 = 0.0
    var A1eqin: Float64 = 0.0
    var A1eqout: Float64 = 0.0
    var A2eqin: Float64 = 0.0
    var A2eqout: Float64 = 0.0
    var T0: Float64 = 0.0
    var tilt: Float64 = 0.0
    var dens0: Float64 = 0.0
    var visc0: Float64 = 0.0
    var con0: Float64 = 0.0
    var pr0: Float64 = 0.0
    var cp0: Float64 = 0.0
    var dens1: Float64 = 0.0
    var visc1: Float64 = 0.0
    var con1: Float64 = 0.0
    var pr1: Float64 = 0.0
    var cp1: Float64 = 0.0
    var dens2: Float64 = 0.0
    var visc2: Float64 = 0.0
    var con2: Float64 = 0.0
    var pr2: Float64 = 0.0
    var cp2: Float64 = 0.0
    var Tup: Float64 = 0.0
    var Tdown: Float64 = 0.0
    var H01: Float64 = 0.0
    var H02: Float64 = 0.0
    var beta1: Float64 = 0.0
    var beta2: Float64 = 0.0
    var alpha1: Float64 = 0.0
    var alpha2: Float64 = 0.0
    var P1: Float64 = 0.0
    var P2: Float64 = 0.0
    var qsmooth: Float64 = 0.0

    var iter: Int32 = 0
    var TGapOld1: Float64 = 0.0
    var TGapOld2: Float64 = 0.0
    var Temp1: Float64 = 0.0
    var Temp2: Float64 = 0.0
    var converged: Bool = False

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

    if (nperr[] > 0) and (nperr[] < 1000):
        return

    if (Tgap1 * Tgap2) == 0:
        nperr[] = 15
        return

    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001

    converged = False
    iter = 0
    var s1_2: Float64 = pow_2(s1)
    var s2_2: Float64 = pow_2(s2)
    var s1_s2_2: Float64 = pow_2(s1 / s2)
    var cos_Tilt: Float64 = cos(tilt)

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

        Zin1 = pow_2((s1 * L / (0.6 * A1eqin)) - 1.0)
        Zin2 = pow_2((s2 * L / (0.6 * A2eqin)) - 1.0)
        Zout1 = pow_2((s1 * L / (0.6 * A1eqout)) - 1.0)
        Zout2 = pow_2((s2 * L / (0.6 * A2eqout)) - 1.0)

        D1 = (dens1 / 2.0) * (Zin1 + Zout1)
        D2 = (dens2 / 2.0) * s1_s2_2 * (Zin2 + Zout2)

        A1 = B1 + D1 + B2 + D2
        A2 = C1 + C2

        speed1 = (sqrt(pow_2(A2) + abs(4.0 * A * A1)) - A2) / (2.0 * A1)
        speed2 = speed1 * s1 / s2

        H01 = (dens1 * cp1 * s1 * speed1) / (4.0 * hc1 + 8.0 * speed1)
        H02 = (dens2 * cp2 * s2 * speed2) / (4.0 * hc2 + 8.0 * speed2)

        if (H01 != 0.0) and (H02 != 0.0):
            P1 = -H / H01
            P2 = -H / H02

        beta1 = pow(e_const, P1)
        beta2 = pow(e_const, P2)

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


fn shadingedge(state: UnsafePointer[TarcogShadingData],
               iprop1: UnsafePointer[Int32],
               frct1: UnsafePointer[Float64],
               press1: Float64,
               nmix1: Int32,
               iprop2: UnsafePointer[Int32],
               frct2: UnsafePointer[Float64],
               press2: Float64,
               nmix2: Int32,
               xwght: UnsafePointer[Float64],
               xgcon: UnsafePointer[UnsafePointer[Float64]],
               xgvis: UnsafePointer[UnsafePointer[Float64]],
               xgcp: UnsafePointer[UnsafePointer[Float64]],
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
               nperr: UnsafePointer[Int32],
               ErrorMessage: UnsafePointer[UnsafePointer[UInt8]],
               speed: Float64,
               maxgas: Int32,
               GASSES90,
               Constant,
               ISO15099,
               e_const: Float64) -> None:
    """Handle shading at edges"""

    var A: Float64 = 0.0
    var A1: Float64 = 0.0
    var A2: Float64 = 0.0
    var B1: Float64 = 0.0
    var C1: Float64 = 0.0
    var D1: Float64 = 0.0
    var Zin1: Float64 = 0.0
    var Zout1: Float64 = 0.0
    var A1eqin: Float64 = 0.0
    var A1eqout: Float64 = 0.0
    var T0: Float64 = 0.0
    var tilt: Float64 = 0.0
    var dens0: Float64 = 0.0
    var visc0: Float64 = 0.0
    var con0: Float64 = 0.0
    var pr0: Float64 = 0.0
    var cp0: Float64 = 0.0
    var dens2: Float64 = 0.0
    var visc2: Float64 = 0.0
    var con2: Float64 = 0.0
    var pr2: Float64 = 0.0
    var cp2: Float64 = 0.0
    var Tgapout: Float64 = 0.0
    var H0: Float64 = 0.0
    var P: Float64 = 0.0
    var beta: Float64 = 0.0

    var iter: Int32 = 0
    var TGapOld: Float64 = 0.0
    var converged: Bool = False

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

    if (nperr[] > 0) and (nperr[] < 1000):
        return

    if (Tgap * Tenv) == 0.0:
        nperr[] = 15
        return

    if (Atop + Abot) == 0:
        Atop = 0.000001
        Abot = 0.000001
    if (Ah + Al + Ar) == 0.0:
        Ah = 0.000001

    converged = False
    iter = 0
    var s_2: Float64 = pow_2(s)
    var abs_cos_tilt: Float64 = abs(cos(tilt))

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

        if (nperr[] > 0) and (nperr[] < 1000):
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

        Zin1 = pow_2((s * L / (0.6 * A1eqin)) - 1.0)
        Zout1 = pow_2((s * L / (0.6 * A1eqout)) - 1.0)

        D1 = (dens2 / 2.0) * (Zin1 + Zout1)

        A1 = B1 + D1
        A2 = C1

        if forcedspeed != 0.0:
            speed = forcedspeed
        else:
            speed = (sqrt(pow_2(A2) + abs(4.0 * A * A1)) - A2) / (2.0 * A1)

        TGapOld = Tgap

        if speed != 0.0:
            H0 = (dens2 * cp2 * s * speed) / (4.0 * hc + 8.0 * speed)

            P = -H / H0
            if P < -700.0:
                beta = 0.0
            else:
                beta = pow(e_const, P)
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


fn updateEffectiveMultipliers(nlayer: Int32,
                              width: Float64,
                              height: Float64,
                              Atop: UnsafePointer[Float64],
                              Abot: UnsafePointer[Float64],
                              Al: UnsafePointer[Float64],
                              Ar: UnsafePointer[Float64],
                              Ah: UnsafePointer[Float64],
                              Atop_eff: UnsafePointer[Float64],
                              Abot_eff: UnsafePointer[Float64],
                              Al_eff: UnsafePointer[Float64],
                              Ar_eff: UnsafePointer[Float64],
                              Ah_eff: UnsafePointer[Float64],
                              LayerType: UnsafePointer[Int32],
                              SlatAngle: UnsafePointer[Float64],
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
            var slatAngRad: Float64 = SlatAngle[i] * 2 * Constant.Pi / 360.0
            var C1_VENET: Float64 = 0.0
            var C2_VENET: Float64 = 0.0
            var C3_VENET: Float64 = 0.0

            if LayerType[i] == VENETBLIND_HORIZ:
                C1_VENET = C1_VENET_HORIZONTAL
                C2_VENET = C2_VENET_HORIZONTAL
                C3_VENET = C3_VENET_HORIZONTAL
            if LayerType[i] == VENETBLIND_VERT:
                C1_VENET = C1_VENET_VERTICAL
                C2_VENET = C2_VENET_VERTICAL
                C3_VENET = C3_VENET_VERTICAL

            Ah_eff[i] = width * height * C1_VENET * pow((Ah[i] / (width * height)) * pow(cos(slatAngRad), C2_VENET), C3_VENET)
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
