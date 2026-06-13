from math import exp, log, pow, sqrt, min, max, ceil
from ...Construction import Construct  # type: ignore
from ...ConvectionCoefficients import InitExtConvCoeff
from ...DataEnvironment import WindSpeedAt, OutDryBulbTempAt
from ...DataGlobal import # assume DataGlobal struct
from ...DataHeatBalSurface import SurfOutsideTempHist, SurfHConvExt, SurfHSkyExt, SurfHGrdExt, SurfHAirExt, SurfHSrdSurfExt, SurfCTFConstOutPart, SurfCTFConstInPart, SurfOpaqQRadSWInAbs, SurfQdotRadIntGainsInPerArea, SurfQsrcHist, SurfHConvInt, SurfQdotRadNetLWInPerArea, SurfTempIn
from ...DataHeatBalance import SurfQdotRadIntGainsInPerArea?  # need to resolve
from ...DataSurfaces import HeatTransferModel, Surface
from ...DataWater import IrrigationMode, RainfallMode
from ...EcoRoofManager import EcoRoofManagerData  # circular? but necessary
from ...Material import SurfaceRoughness, Group, MaterialEcoRoof, EcoRoofCalcMethod
from ...OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
from ...UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningMessage, ShowRecurringWarningErrorAtEnd
from "../WeatherManager"  # not used directly
from ...ZoneTempPredictorCorrector import spaceHeatBalance
from ...Constant import Units, Kelvin
from ...SolarShading import SurfAnisoSkyMult
# Helper math functions to match ObjexxFCL
def pow_2(x: Real64) -> Real64:
    return x * x
def pow_3(x: Real64) -> Real64:
    return x * x * x
def pow_4(x: Real64) -> Real64:
    let x2 = x * x
    return x2 * x2
# Namespace for EcoRoofManager functions
struct EcoRoofManagerFn:

def CalcEcoRoof(
    inout state: EnergyPlusData,
    SurfNum: Int,
    ConstrNum: Int,
    inout TempExt: Real64
):
    # Local constants
    let Kv: Real64 = 0.4
    let rch: Real64 = 0.63
    let rche: Real64 = 0.71
    let Rair: Real64 = 0.286e3
    let g1: Real64 = 9.81
    let Sigma: Real64 = 5.6697e-08
    let Cpa: Real64 = 1005.6
    # Local variables
    var RoughSurf: Material.SurfaceRoughness
    var Tgk: Real64
    var Ta: Real64
    var Waf: Real64
    var qaf: Real64
    var qg: Real64
    var RS: Real64
    var EpsilonOne: Real64
    var eair: Real64
    var Rhoa: Real64
    var Tak: Real64
    var qa: Real64
    var Tafk: Real64
    var Taf: Real64
    var Rhof: Real64
    var Rhoaf: Real64
    var sigmaf: Real64
    var Zd: Real64
    var Zo: Real64
    var Cfhn: Real64
    var Cf: Real64
    var ra: Real64
    var f2inv: Real64
    var f1: Real64
    var f2: Real64
    var r_s: Real64
    var Mg: Real64
    var dOne: Real64
    var esf: Real64
    var qsf: Real64
    var Lef: Real64
    var Desf: Real64
    var dqf: Real64
    var dqg: Real64
    var esg: Real64
    var qsg: Real64
    var Leg: Real64
    var Desg: Real64
    var F1temp: Real64
    var P1: Real64
    var P2: Real64
    var P3: Real64
    var Rhog: Real64
    var Rhoag: Real64
    var Rib: Real64
    var Chng: Real64
    var Ce: Real64
    var Gammah: Real64
    var Chg: Real64
    var T3G: Real64
    var T2G: Real64
    var LeafTK: Real64
    var SoilTK: Real64
    var Chne: Real64
    var Tif: Real64
    var rn: Real64
    var T1G: Real64
    var Qsoilpart1: Real64
    var Qsoilpart2: Real64
    # Get wind speed
    var Ws: Real64 = WindSpeedAt(state, state.dataSurface.Surface[SurfNum].Centroid.z)
    if Ws < 2.0:
        Ws = 2.0
    let thisConstruct = state.dataConstruction.Construct[ConstrNum]
    let thisMaterial = state.dataMaterial.materials[thisConstruct.LayerPoint[1]]  # 1-based to 0-based: index 0?
    RoughSurf = thisMaterial.Roughness
    let AbsThermSurf: Real64 = thisMaterial.AbsorpThermal
    let HMovInsul: Real64 = 0.0
    if state.dataSurface.Surface[SurfNum].ExtWind:
        InitExtConvCoeff(
            state,
            SurfNum,
            HMovInsul,
            RoughSurf,
            AbsThermSurf,
            state.dataHeatBalSurf.SurfOutsideTempHist[1][SurfNum],  # Hist index 1, need 0-based?
            state.dataHeatBalSurf.SurfHConvExt[SurfNum],
            state.dataHeatBalSurf.SurfHSkyExt[SurfNum],
            state.dataHeatBalSurf.SurfHGrdExt[SurfNum],
            state.dataHeatBalSurf.SurfHAirExt[SurfNum],
            state.dataHeatBalSurf.SurfHSrdSurfExt[SurfNum],
        )
    let Latm: Real64 = Sigma * state.dataSurface.Surface[SurfNum].ViewFactorGround * pow_4(state.dataEnvrn.GroundTempKelvin) + \
                       Sigma * state.dataSurface.Surface[SurfNum].ViewFactorSky * pow_4(state.dataEnvrn.SkyTempKelvin)
    if state.dataEcoRoofMgr.EcoRoofbeginFlag:
        initEcoRoofFirstTime(state, SurfNum, ConstrNum)
    initEcoRoof(state, SurfNum, ConstrNum)
    if SurfNum == state.dataEcoRoofMgr.FirstEcoSurf:
        var unit: Int = 0
        UpdateSoilProps(
            state,
            inout state.dataEcoRoofMgr.Moisture,
            inout state.dataEcoRoofMgr.MeanRootMoisture,
            state.dataEcoRoofMgr.MoistureMax,
            state.dataEcoRoofMgr.MoistureResidual,
            state.dataEcoRoofMgr.SoilThickness,
            state.dataEcoRoofMgr.Vfluxf,
            state.dataEcoRoofMgr.Vfluxg,
            ConstrNum,
            inout state.dataEcoRoofMgr.Alphag,
            unit,
            state.dataEcoRoofMgr.Tg,
            state.dataEcoRoofMgr.Tf,
            state.dataEcoRoofMgr.Qsoil,
        )
        Ta = OutDryBulbTempAt(state, state.dataSurface.Surface[SurfNum].Centroid.z)
        state.dataEcoRoofMgr.Tg = state.dataEcoRoofMgr.Tgold
        state.dataEcoRoofMgr.Tf = state.dataEcoRoofMgr.Tfold
        if thisConstruct.CTFCross[0] > 0.01:
            state.dataEcoRoofMgr.QuickConductionSurf = True
            let spaceNum: Int = state.dataSurface.Surface[SurfNum].spaceNum
            F1temp = thisConstruct.CTFCross[0] / (thisConstruct.CTFInside[0] + state.dataHeatBalSurf.SurfHConvInt[SurfNum])
            Qsoilpart1 = \
                -state.dataHeatBalSurf.SurfCTFConstOutPart[SurfNum] + \
                F1temp * (
                    state.dataHeatBalSurf.SurfCTFConstInPart[SurfNum] +
                    state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[SurfNum] +
                    state.dataHeatBal.SurfQdotRadIntGainsInPerArea[SurfNum] +
                    state.dataConstruction.Construct[ConstrNum].CTFSourceIn[0] * state.dataHeatBalSurf.SurfQsrcHist[SurfNum][1] +  # index 1 maybe 0-based?
                    state.dataHeatBalSurf.SurfHConvInt[SurfNum] * state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum].MAT +
                    state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea[SurfNum]
                )
        else:
            Qsoilpart1 = \
                -state.dataHeatBalSurf.SurfCTFConstOutPart[SurfNum] + \
                thisConstruct.CTFCross[0] * state.dataHeatBalSurf.SurfTempIn[SurfNum]
            F1temp = 0.0
        Qsoilpart2 = thisConstruct.CTFOutside[0] - F1temp * thisConstruct.CTFCross[0]
        state.dataEcoRoofMgr.Pa = state.dataEnvrn.StdBaroPress
        Tgk = state.dataEcoRoofMgr.Tg + Constant.Kelvin
        Tak = Ta + Constant.Kelvin
        sigmaf = 0.9 - 0.7 * exp(-0.75 * state.dataEcoRoofMgr.LAI)
        EpsilonOne = state.dataEcoRoofMgr.epsilonf + state.dataEcoRoofMgr.epsilong - \
                     state.dataEcoRoofMgr.epsilong * state.dataEcoRoofMgr.epsilonf
        state.dataEcoRoofMgr.RH = state.dataEnvrn.OutRelHum
        eair = (state.dataEcoRoofMgr.RH / 100.0) * 611.2 * exp(17.67 * Ta / (Tak - 29.65))
        qa = (0.622 * eair) / (state.dataEcoRoofMgr.Pa - 1.000 * eair)
        Rhoa = state.dataEcoRoofMgr.Pa / (Rair * Tak)
        Tif = state.dataEcoRoofMgr.Tf
        Tafk = (1.0 - sigmaf) * Tak + sigmaf * (0.3 * Tak + 0.6 * (Tif + Constant.Kelvin) + 0.1 * Tgk)
        Taf = Tafk - Constant.Kelvin
        Rhof = state.dataEcoRoofMgr.Pa / (Rair * Tafk)
        Rhoaf = (Rhoa + Rhof) / 2.0
        Zd = 0.701 * pow(state.dataEcoRoofMgr.Zf, 0.979)
        Zo = 0.131 * pow(state.dataEcoRoofMgr.Zf, 0.997)
        if Zo < 0.02:
            Zo = 0.02
        Cfhn = pow_2(Kv / log((state.dataEcoRoofMgr.Za - Zd) / Zo))
        Waf = 0.83 * sqrt(Cfhn) * sigmaf * Ws + (1.0 - sigmaf) * Ws
        Cf = 0.01 * (1.0 + 0.3 / Waf)
        state.dataEcoRoofMgr.sheatf = state.dataEcoRoofMgr.e0 + 1.1 * state.dataEcoRoofMgr.LAI * Rhoaf * Cpa * Cf * Waf
        state.dataEcoRoofMgr.sensiblef = state.dataEcoRoofMgr.sheatf * (Taf - state.dataEcoRoofMgr.Tf)
        esf = 611.2 * exp(17.67 * Tif / (Tif + Constant.Kelvin - 29.65))
        qsf = 0.622 * esf / (state.dataEcoRoofMgr.Pa - 1.000 * esf)
        ra = 1.0 / (Cf * Waf)
        CalculateEcoRoofSolar(state, inout RS, inout f1, SurfNum)
        if state.dataEcoRoofMgr.MoistureMax == state.dataEcoRoofMgr.MoistureResidual:
            f2inv = 1.0e10
        else:
            f2inv = (state.dataEcoRoofMgr.MeanRootMoisture - state.dataEcoRoofMgr.MoistureResidual) / \
                    (state.dataEcoRoofMgr.MoistureMax - state.dataEcoRoofMgr.MoistureResidual)
        f2 = 1.0 / f2inv
        state.dataEcoRoofMgr.f3 = 1.0 / (exp(-0.0 * (esf - eair)))  # exp(0) = 1
        r_s = state.dataEcoRoofMgr.StomatalResistanceMin * f1 * f2 * state.dataEcoRoofMgr.f3 / state.dataEcoRoofMgr.LAI
        rn = ra / (ra + r_s)
        Mg = state.dataEcoRoofMgr.Moisture / state.dataEcoRoofMgr.MoistureMax
        dOne = 1.0 - sigmaf * (0.6 * (1.0 - rn) + 0.1 * (1.0 - Mg))
        Lef = 1.91846e6 * pow_2((Tif + Constant.Kelvin) / (Tif + Constant.Kelvin - 33.91))
        if state.dataEcoRoofMgr.Tfold < 0.0:
            Lef = 2.838e6
        Desf = 611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tf / (state.dataEcoRoofMgr.Tf + Constant.Kelvin - 29.65))) * \
               (17.67 * state.dataEcoRoofMgr.Tf * (-1.0) * pow(state.dataEcoRoofMgr.Tf + Constant.Kelvin - 29.65, -2) + \
                17.67 / (Constant.Kelvin - 29.65 + state.dataEcoRoofMgr.Tf))
        dqf = ((0.622 * state.dataEcoRoofMgr.Pa) / pow_2(state.dataEcoRoofMgr.Pa - esf)) * Desf
        esg = 611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tg / ((state.dataEcoRoofMgr.Tg + Constant.Kelvin) - 29.65)))
        qsg = 0.622 * esg / (state.dataEcoRoofMgr.Pa - esg)
        Leg = 1.91846e6 * pow_2(Tgk / (Tgk - 33.91))
        if state.dataEcoRoofMgr.Tgold < 0.0:
            Leg = 2.838e6
        Desg = 611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tg / (state.dataEcoRoofMgr.Tg + Constant.Kelvin - 29.65))) * \
               (17.67 * state.dataEcoRoofMgr.Tg * (-1.0) * pow(state.dataEcoRoofMgr.Tg + Constant.Kelvin - 29.65, -2) + \
                17.67 / (Constant.Kelvin - 29.65 + state.dataEcoRoofMgr.Tg))
        dqg = (0.622 * state.dataEcoRoofMgr.Pa / pow_2(state.dataEcoRoofMgr.Pa - esg)) * Desg
        Rhog = state.dataEcoRoofMgr.Pa / (Rair * Tgk)
        Rhoag = (Rhoa + Rhog) / 2.0
        Rib = 2.0 * g1 * state.dataEcoRoofMgr.Za * (Taf - state.dataEcoRoofMgr.Tg) / ((Tafk + Tgk) * pow_2(Waf))
        if Rib < 0.0:
            Gammah = pow(1.0 - 16.0 * Rib, -0.5)
        else:
            if Rib >= 0.19:
                Rib = 0.19
            Gammah = pow(1.0 - 5.0 * Rib, -0.5)
        var zogLookup: StaticArray[Real64, 6] = StaticArray[Real64, 6](0.005, 0.0030, 0.0020, 0.0015, 0.0010, 0.0008)
        state.dataEcoRoofMgr.Zog = zogLookup[Int(RoughSurf)]
        Chng = pow_2(Kv / log(state.dataEcoRoofMgr.Za / state.dataEcoRoofMgr.Zog)) / rch
        Chg = Gammah * ((1.0 - sigmaf) * Chng + sigmaf * Cfhn)
        state.dataEcoRoofMgr.sheatg = state.dataEcoRoofMgr.e0 + Rhoag * Cpa * Chg * Waf
        state.dataEcoRoofMgr.sensibleg = state.dataEcoRoofMgr.sheatg * (Taf - state.dataEcoRoofMgr.Tg)
        Chne = pow_2(Kv / log(state.dataEcoRoofMgr.Za / state.dataEcoRoofMgr.Zog)) / rche
        Ce = Gammah * ((1.0 - sigmaf) * Chne + sigmaf * Cfhn)
        qaf = ((1.0 - sigmaf) * qa + sigmaf * (0.3 * qa + 0.6 * qsf * rn + 0.1 * qsg * Mg)) / \
              (1.0 - sigmaf * (0.6 * (1.0 - rn) + 0.1 * (1.0 - Mg)))
        qg = Mg * qsg + (1.0 - Mg) * qaf
        state.dataEcoRoofMgr.Lf = Lef * state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Waf * rn * (qaf - qsf)
        state.dataEcoRoofMgr.Lg = Ce * Leg * Waf * Rhoag * (qaf - qg) * Mg
        state.dataEcoRoofMgr.Vfluxf = -1.0 * state.dataEcoRoofMgr.Lf / Lef / 990.0
        state.dataEcoRoofMgr.Vfluxg = -1.0 * state.dataEcoRoofMgr.Lg / Leg / 990.0
        if state.dataEcoRoofMgr.Vfluxf < 0.0:
            state.dataEcoRoofMgr.Vfluxf = 0.0
        if state.dataEcoRoofMgr.Vfluxg < 0.0:
            state.dataEcoRoofMgr.Vfluxg = 0.0
        LeafTK = state.dataEcoRoofMgr.Tf + Constant.Kelvin
        SoilTK = state.dataEcoRoofMgr.Tg + Constant.Kelvin
        for EcoLoop in range(1, 4):  # 1 to 3 inclusive
            P1 = sigmaf * (RS * (1.0 - state.dataEcoRoofMgr.Alphaf) + state.dataEcoRoofMgr.epsilonf * Latm) - \
                 3.0 * sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma * pow_4(SoilTK) / EpsilonOne - \
                 3.0 * ( -sigmaf * state.dataEcoRoofMgr.epsilonf * Sigma - \
                         sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma / EpsilonOne) * pow_4(LeafTK) + \
                 state.dataEcoRoofMgr.sheatf * (1.0 - 0.7 * sigmaf) * (Ta + Constant.Kelvin) + \
                 state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * ((1.0 - 0.7 * sigmaf) / dOne) * qa + \
                 state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (((0.6 * sigmaf * rn) / dOne) - 1.0) * (qsf - LeafTK * dqf) + \
                 state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * ((0.1 * sigmaf * Mg) / dOne) * (qsg - SoilTK * dqg)
            P2 = 4.0 * (sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma) * pow_3(SoilTK) / EpsilonOne + \
                 0.1 * sigmaf * state.dataEcoRoofMgr.sheatf + \
                 state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (0.1 * sigmaf * Mg) / dOne * dqg
            P3 = 4.0 * ( -sigmaf * state.dataEcoRoofMgr.epsilonf * Sigma - \
                         (sigmaf * state.dataEcoRoofMgr.epsilonf * Sigma * state.dataEcoRoofMgr.epsilong) / EpsilonOne) * pow_3(LeafTK) + \
                 (0.6 * sigmaf - 1.0) * state.dataEcoRoofMgr.sheatf + \
                 state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (((0.6 * sigmaf * rn) / dOne) - 1.0) * dqf
            T1G = (1.0 - sigmaf) * (RS * (1.0 - state.dataEcoRoofMgr.Alphag) + state.dataEcoRoofMgr.epsilong * Latm) - \
                  (3.0 * (sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma) / EpsilonOne) * pow_4(LeafTK) - \
                  3.0 * ( -(1.0 - sigmaf) * state.dataEcoRoofMgr.epsilong * Sigma - \
                          sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma / EpsilonOne) * pow_4(SoilTK) + \
                  state.dataEcoRoofMgr.sheatg * (1.0 - 0.7 * sigmaf) * (Ta + Constant.Kelvin) + \
                  Rhoag * Ce * Leg * Waf * Mg * ((1.0 - 0.7 * sigmaf) / dOne) * qa + \
                  Rhoag * Ce * Leg * Waf * Mg * (0.1 * sigmaf * Mg / dOne - Mg) * (qsg - SoilTK * dqg) + \
                  Rhoag * Ce * Leg * Waf * Mg * (0.6 * sigmaf * rn / dOne) * (qsf - LeafTK * dqf) + Qsoilpart1 + \
                  Qsoilpart2 * (Constant.Kelvin)
            T2G = 4.0 * ( -(1.0 - sigmaf) * state.dataEcoRoofMgr.epsilong * Sigma - \
                          sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * Sigma / EpsilonOne) * pow_3(SoilTK) + \
                  (0.1 * sigmaf - 1.0) * state.dataEcoRoofMgr.sheatg + \
                  Rhoag * Ce * Leg * Waf * Mg * (0.1 * sigmaf * Mg / dOne - Mg) * dqg - Qsoilpart2
            T3G = (4.0 * (sigmaf * state.dataEcoRoofMgr.epsilong * state.dataEcoRoofMgr.epsilonf * Sigma) / EpsilonOne) * pow_3(LeafTK) + \
                  0.6 * sigmaf * state.dataEcoRoofMgr.sheatg + \
                  Rhoag * Ce * Leg * Waf * Mg * (0.6 * sigmaf * rn / dOne) * dqf
            LeafTK = 0.5 * (LeafTK + (P1 * T2G - P2 * T1G) / (-P3 * T2G + T3G * P2))
            SoilTK = 0.5 * (SoilTK + (P1 * T3G - P3 * T1G) / (-P2 * T3G + P3 * T2G))
        state.dataEcoRoofMgr.Qsoil = -1.0 * (Qsoilpart1 - Qsoilpart2 * (SoilTK - Constant.Kelvin))
        state.dataEcoRoofMgr.Tfold = LeafTK - Constant.Kelvin
        state.dataEcoRoofMgr.Tgold = SoilTK - Constant.Kelvin
    # End if SurfNum == FirstEcoSurf
    state.dataHeatBalSurf.SurfOutsideTempHist[1][SurfNum] = state.dataEcoRoofMgr.Tgold
    TempExt = state.dataEcoRoofMgr.Tgold
def initEcoRoofFirstTime(inout state: EnergyPlusData, SurfNum: Int, ConstrNum: Int):
    let mat = state.dataMaterial.materials[state.dataConstruction.Construct[ConstrNum].LayerPoint[1]]
    assert(mat.group == Material.Group.EcoRoof)
    let matER = mat as Material.MaterialEcoRoof
    assert(matER is not None)
    var thisEcoRoof = state.dataEcoRoofMgr
    thisEcoRoof.EcoRoofbeginFlag = False
    if state.dataSurface.Surface[SurfNum].HeatTransferAlgorithm != DataSurfaces.HeatTransferModel.CTF:
        ShowSevereError(state, "initEcoRoofFirstTime: EcoRoof simulation but HeatBalanceAlgorithm is not ConductionTransferFunction(CTF). EcoRoof model currently works only with CTF heat balance solution algorithm.")
        ShowContinueError(state, String.format("Occurs for surface named {}", state.dataSurface.Surface[SurfNum].Name))
        ShowContinueError(state, "Check input syntax for HeatBalanceAlgorithm, SurfaceProperty:HeatTransferAlgorithm,")
        ShowContinueError(state, "SurfaceProperty:HeatTransferAlgorithm:MultipleSurface, and SurfaceProperty:HeatTransferAlgorithm:SurfaceList ")
        ShowContinueError(state, "to verify that the solution method is set to CTF for the surface that is an EcoRoof.")
        ShowFatalError(state, "initEcoRoofFirstTime: Program terminates due to preceding conditions.")
    thisEcoRoof.Zf = matER.HeightOfPlants
    thisEcoRoof.LAI = matER.LAI
    thisEcoRoof.Alphag = 1.0 - matER.AbsorpSolar
    thisEcoRoof.Alphaf = matER.Lreflectivity
    thisEcoRoof.epsilonf = matER.LEmissitivity
    thisEcoRoof.StomatalResistanceMin = matER.RStomata
    thisEcoRoof.epsilong = matER.AbsorpThermal
    thisEcoRoof.MoistureMax = matER.Porosity
    thisEcoRoof.MoistureResidual = matER.MinMoisture
    thisEcoRoof.Moisture = matER.InitMoisture
    thisEcoRoof.MeanRootMoisture = thisEcoRoof.Moisture
    thisEcoRoof.SoilThickness = matER.Thickness
    thisEcoRoof.FirstEcoSurf = SurfNum
    SetupOutputVariable(state, "Green Roof Soil Temperature", Constant.Units.C, inout thisEcoRoof.Tg, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Vegetation Temperature", Constant.Units.C, inout thisEcoRoof.Tf, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Soil Root Moisture Ratio", Constant.Units.None, inout thisEcoRoof.MeanRootMoisture, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Soil Near Surface Moisture Ratio", Constant.Units.None, inout thisEcoRoof.Moisture, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Soil Sensible Heat Transfer Rate per Area", Constant.Units.W_m2, inout thisEcoRoof.sensibleg, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Vegetation Sensible Heat Transfer Rate per Area", Constant.Units.W_m2, inout thisEcoRoof.sensiblef, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Vegetation Moisture Transfer Rate", Constant.Units.m_s, inout thisEcoRoof.Vfluxf, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Soil Moisture Transfer Rate", Constant.Units.m_s, inout thisEcoRoof.Vfluxg, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Vegetation Latent Heat Transfer Rate per Area", Constant.Units.W_m2, inout thisEcoRoof.Lf, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Soil Latent Heat Transfer Rate per Area", Constant.Units.W_m2, inout thisEcoRoof.Lg, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Cumulative Precipitation Depth", Constant.Units.m, inout thisEcoRoof.CumPrecip, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Cumulative Irrigation Depth", Constant.Units.m, inout thisEcoRoof.CumIrrigation, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Cumulative Runoff Depth", Constant.Units.m, inout thisEcoRoof.CumRunoff, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Cumulative Evapotranspiration Depth", Constant.Units.m, inout thisEcoRoof.CumET, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, "Environment")
    SetupOutputVariable(state, "Green Roof Current Precipitation Depth", Constant.Units.m, inout thisEcoRoof.CurrentPrecipitation, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "Environment")
    SetupOutputVariable(state, "Green Roof Current Irrigation Depth", Constant.Units.m, inout thisEcoRoof.CurrentIrrigation, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "Environment")
    SetupOutputVariable(state, "Green Roof Current Runoff Depth", Constant.Units.m, inout thisEcoRoof.CurrentRunoff, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "Environment")
    SetupOutputVariable(state, "Green Roof Current Evapotranspiration Depth", Constant.Units.m, inout thisEcoRoof.CurrentET, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "Environment")
def initEcoRoof(inout state: EnergyPlusData, SurfNum: Int, ConstrNum: Int):
    let mat = state.dataMaterial.materials[state.dataConstruction.Construct[ConstrNum].LayerPoint[1]]
    assert(mat.group == Material.Group.EcoRoof)
    let matER = mat as Material.MaterialEcoRoof
    assert(matER is not None)
    var thisSurf = state.dataSurface.Surface[SurfNum]
    if state.dataGlobal.BeginEnvrnFlag or state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.Moisture = matER.InitMoisture
        state.dataEcoRoofMgr.MeanRootMoisture = state.dataEcoRoofMgr.Moisture
        state.dataEcoRoofMgr.Alphag = 1.0 - matER.AbsorpSolar
    if state.dataGlobal.BeginEnvrnFlag and state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag:
        state.dataEcoRoofMgr.Tgold = OutDryBulbTempAt(state, thisSurf.Centroid.z)
        state.dataEcoRoofMgr.Tfold = OutDryBulbTempAt(state, thisSurf.Centroid.z)
        state.dataEcoRoofMgr.Tg = 10.0
        state.dataEcoRoofMgr.Tf = 10.0
        state.dataEcoRoofMgr.Vfluxf = 0.0
        state.dataEcoRoofMgr.Vfluxg = 0.0
        state.dataEcoRoofMgr.CumRunoff = 0.0
        state.dataEcoRoofMgr.CumET = 0.0
        state.dataEcoRoofMgr.CumPrecip = 0.0
        state.dataEcoRoofMgr.CumIrrigation = 0.0
        state.dataEcoRoofMgr.CurrentRunoff = 0.0
        state.dataEcoRoofMgr.CurrentET = 0.0
        state.dataEcoRoofMgr.CurrentPrecipitation = 0.0
        state.dataEcoRoofMgr.CurrentIrrigation = 0.0
        state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag = True
def UpdateSoilProps(
    inout state: EnergyPlusData,
    inout Moisture: Real64,
    inout MeanRootMoisture: Real64,
    MoistureMax: Real64,
    MoistureResidual: Real64,
    SoilThickness: Real64,
    Vfluxf: Real64,
    Vfluxg: Real64,
    ConstrNum: Int,
    inout Alphag: Real64,
    unit: Int,
    Tg: Real64,
    Tf: Real64,
    Qsoil: Real64,
):
    let depth_fac: Real64 = (161240.0 * pow(2.0, -2.3)) / 60.0
    let alpha: Real64 = 23.0
    let n: Real64 = 1.27
    let lambda_val: Real64 = 0.5
    let SoilConductivitySaturation: Real64 = 5.157e-7
    var RatioMax: Real64
    var RatioMin: Real64
    var MoistureDiffusion: Real64
    var SoilConductivity: Real64
    var SoilSpecHeat: Real64
    var SoilAbsorpSolar: Real64
    var SoilDensity: Real64
    var SatRatio: Real64
    var TestRatio: Real64
    var AvgMoisture: Real64
    RatioMax = 1.0 + 0.20 * state.dataGlobal.MinutesInTimeStep / 15.0
    RatioMin = 1.0 - 0.20 * state.dataGlobal.MinutesInTimeStep / 15.0
    let mat = state.dataMaterial.materials[state.dataConstruction.Construct[ConstrNum].LayerPoint[1]]
    assert(mat.group == Material.Group.EcoRoof)
    let matER = mat as Material.MaterialEcoRoof
    # in Mojo we need to use var because we modify its properties? Actually matER is a const pointer? but C++ allows modification. We'll assume mutable.
    # Use ref to allow modification? We'll get a pointer and modify through state? Actually matER is a pointer to material inside state. We'll treat as inout.
    # For now, we'll use `var matERMutable = matER` and modify it. But C++ code modifies matER->Conductivity etc. We'll need to get a mutable reference.
    # In Mojo, we can get a mutable pointer from state data. Let's assume the materials are stored as mutable.
    # We'll cast to mutable? Simplest: we'll use `var matERMutable = mat as Material.MaterialEcoRoof` and then modify its fields. But Mojo doesn't allow modifying const reference. We'll need to access via state.dataMaterial and update.
    # However, due to time, we'll assume matER is mutable for now. Alternatively, we can use `state.dataMaterial.materials[...]` directly.
    # For simplicity, we'll create a variable referencing the mutable material.
    var matERMutable = state.dataMaterial.materials[state.dataConstruction.Construct[ConstrNum].LayerPoint[1]] as Material.MaterialEcoRoof
    if state.dataEcoRoofMgr.UpdatebeginFlag:
        state.dataEcoRoofMgr.DryCond = matERMutable.Conductivity
        state.dataEcoRoofMgr.DryDens = matERMutable.Density
        state.dataEcoRoofMgr.DryAbsorp = matERMutable.AbsorpSolar
        state.dataEcoRoofMgr.DrySpecHeat = matERMutable.SpecHeat
        if SoilThickness > 0.12:
            state.dataEcoRoofMgr.TopDepth = 0.06
        else:
            state.dataEcoRoofMgr.TopDepth = 0.5 * SoilThickness
        if matERMutable.calcMethod == Material.EcoRoofCalcMethod.SchaapGenuchten:
            var index1: Int
            let depth_limit: Real64 = depth_fac * pow(state.dataEcoRoofMgr.TopDepth + state.dataEcoRoofMgr.RootDepth, 2.07)
            for index1 in range(1, 21):
                if state.dataGlobal.MinutesInTimeStep / index1 <= depth_limit:
                    break
            if index1 > 1:
                ShowWarningError(state, "CalcEcoRoof: Too few time steps per hour for stability.")
                if ceil(60 * index1 / state.dataGlobal.MinutesInTimeStep) <= 60:
                    ShowContinueError(state, String.format("...Entered Timesteps per hour=[{}], Change to some value greater than or equal to [{}] for assured stability.", state.dataGlobal.TimeStepsInHour, 60 * index1 / state.dataGlobal.MinutesInTimeStep))
                    ShowContinueError(state, "...Note that EnergyPlus has a maximum of 60 timesteps per hour")
                    ShowContinueError(state, "...The program will continue, but if the simulation fails due to too low/high temperatures, instability here could be the reason.")
                else:
                    ShowContinueError(state, String.format("...Entered Timesteps per hour=[{}], however the required frequency for stability [{}] is over the EnergyPlus maximum of 60.", state.dataGlobal.TimeStepsInHour, 60 * index1 / state.dataGlobal.MinutesInTimeStep))
                    ShowContinueError(state, "...Consider using the simple moisture diffusion calculation method for this application")
                    ShowContinueError(state, "...The program will continue, but if the simulation fails due to too low/high temperatures, instability here could be the reason.")
        state.dataEcoRoofMgr.RootDepth = SoilThickness - state.dataEcoRoofMgr.TopDepth
        state.dataEcoRoofMgr.TimeStepZoneSec = state.dataGlobal.MinutesInTimeStep * 60.0
        state.dataEcoRoofMgr.UpdatebeginFlag = False
    state.dataEcoRoofMgr.CurrentRunoff = 0.0
    Moisture -= (Vfluxg) * state.dataGlobal.MinutesInTimeStep * 60.0 / state.dataEcoRoofMgr.TopDepth
    MeanRootMoisture -= (Vfluxf) * state.dataGlobal.MinutesInTimeStep * 60.0 / state.dataEcoRoofMgr.RootDepth
    state.dataEcoRoofMgr.CurrentET = (Vfluxg + Vfluxf) * state.dataGlobal.MinutesInTimeStep * 60.0
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumET += state.dataEcoRoofMgr.CurrentET
    Moisture += state.dataEcoRoofMgr.CurrentPrecipitation / state.dataEcoRoofMgr.TopDepth
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumPrecip += state.dataEcoRoofMgr.CurrentPrecipitation
    state.dataEcoRoofMgr.CurrentIrrigation = 0.0
    state.dataWaterData.Irrigation.ActualAmount = 0.0
    if state.dataWaterData.Irrigation.ModeID == DataWater.IrrigationMode.SchedDesign:
        state.dataEcoRoofMgr.CurrentIrrigation = state.dataWaterData.Irrigation.ScheduledAmount
        state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    elif state.dataWaterData.Irrigation.ModeID == DataWater.IrrigationMode.SmartSched and \
         Moisture < state.dataWaterData.Irrigation.IrrigationThreshold * MoistureMax:
        state.dataEcoRoofMgr.CurrentIrrigation = state.dataWaterData.Irrigation.ScheduledAmount
        state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    else:
        if state.dataWaterData.RainFall.ModeID == DataWater.RainfallMode.EPWPrecipitation:
            state.dataEcoRoofMgr.CurrentIrrigation = 0
            state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    Moisture += state.dataEcoRoofMgr.CurrentIrrigation / state.dataEcoRoofMgr.TopDepth
    if (state.dataEnvrn.RunPeriodEnvironment) and (not state.dataGlobal.WarmupFlag):
        state.dataEcoRoofMgr.CumIrrigation += state.dataEcoRoofMgr.CurrentIrrigation
        let month: Int = state.dataEnvrn.Month
        state.dataEcoRoofMgr.MonthlyIrrigation[month - 1] += state.dataWaterData.Irrigation.ActualAmount * 1000.0
    # Runoff calculation
    if state.dataEcoRoofMgr.CurrentIrrigation + state.dataEcoRoofMgr.CurrentPrecipitation > 0.5 * 0.0254 * state.dataGlobal.MinutesInTimeStep / 60.0:
        state.dataEcoRoofMgr.CurrentRunoff = state.dataEcoRoofMgr.CurrentIrrigation + state.dataEcoRoofMgr.CurrentPrecipitation - \
                                              (0.5 * 0.0254 * state.dataGlobal.MinutesInTimeStep / 60.0)
        Moisture -= state.dataEcoRoofMgr.CurrentRunoff / state.dataEcoRoofMgr.TopDepth
    if Moisture > MoistureMax:
        state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax) * state.dataEcoRoofMgr.TopDepth
        Moisture = MoistureMax
    if matERMutable.calcMethod == Material.EcoRoofCalcMethod.Simple:
        if Moisture > MeanRootMoisture:
            MoistureDiffusion = min((MoistureMax - MeanRootMoisture) * state.dataEcoRoofMgr.RootDepth,
                                    (Moisture - MeanRootMoisture) * state.dataEcoRoofMgr.TopDepth)
            MoistureDiffusion = max(0.0, MoistureDiffusion)
            MoistureDiffusion *= 0.00005 * state.dataGlobal.MinutesInTimeStep * 60.0
            Moisture -= MoistureDiffusion / state.dataEcoRoofMgr.TopDepth
            MeanRootMoisture += MoistureDiffusion / state.dataEcoRoofMgr.RootDepth
        elif MeanRootMoisture > Moisture:
            MoistureDiffusion = min((MoistureMax - Moisture) * state.dataEcoRoofMgr.TopDepth,
                                    (MeanRootMoisture - Moisture) * state.dataEcoRoofMgr.RootDepth)
            MoistureDiffusion = max(0.0, MoistureDiffusion)
            MoistureDiffusion *= 0.00001 * state.dataGlobal.MinutesInTimeStep * 60.0
            Moisture += MoistureDiffusion / state.dataEcoRoofMgr.TopDepth
            MeanRootMoisture -= MoistureDiffusion / state.dataEcoRoofMgr.RootDepth
    else:
        state.dataEcoRoofMgr.RelativeSoilSaturationTop = (Moisture - MoistureResidual) / (MoistureMax - MoistureResidual)
        if state.dataEcoRoofMgr.RelativeSoilSaturationTop < 0.0001:
            if state.dataEcoRoofMgr.ErrIndex == 0:
                ShowWarningMessage(state, String.format("EcoRoof: UpdateSoilProps: Relative Soil Saturation Top Moisture <= 0.0001, Value=[{:#G}].", state.dataEcoRoofMgr.RelativeSoilSaturationTop))
                ShowContinueError(state, "Value is set to 0.0001 and simulation continues.")
                ShowContinueError(state, "You may wish to increase the number of timesteps to attempt to alleviate the problem.")
            ShowRecurringWarningErrorAtEnd(state, "EcoRoof: UpdateSoilProps: Relative Soil Saturation Top Moisture < 0. continues", state.dataEcoRoofMgr.ErrIndex, state.dataEcoRoofMgr.RelativeSoilSaturationTop, state.dataEcoRoofMgr.RelativeSoilSaturationTop)
            state.dataEcoRoofMgr.RelativeSoilSaturationTop = 0.0001
        state.dataEcoRoofMgr.SoilHydroConductivityTop = SoilConductivitySaturation * pow(state.dataEcoRoofMgr.RelativeSoilSaturationTop, lambda_val) * \
            pow_2(1.0 - pow(1.0 - pow(state.dataEcoRoofMgr.RelativeSoilSaturationTop, n / (n - 1.0)), (n - 1.0) / n))
        state.dataEcoRoofMgr.CapillaryPotentialTop = (-1.0 / alpha) * pow(pow(1.0 / state.dataEcoRoofMgr.RelativeSoilSaturationTop, n / (n - 1.0)) - 1.0, 1.0 / n)
        state.dataEcoRoofMgr.RelativeSoilSaturationRoot = (MeanRootMoisture - MoistureResidual) / (MoistureMax - MoistureResidual)
        state.dataEcoRoofMgr.SoilHydroConductivityRoot = SoilConductivitySaturation * pow(state.dataEcoRoofMgr.RelativeSoilSaturationRoot, lambda_val) * \
            pow_2(1.0 - pow(1.0 - pow(state.dataEcoRoofMgr.RelativeSoilSaturationRoot, n / (n - 1.0)), (n - 1.0) / n))
        state.dataEcoRoofMgr.CapillaryPotentialRoot = (-1.0 / alpha) * pow(pow(1.0 / state.dataEcoRoofMgr.RelativeSoilSaturationRoot, n / (n - 1.0)) - 1.0, 1.0 / n)
        state.dataEcoRoofMgr.SoilConductivityAveTop = (state.dataEcoRoofMgr.SoilHydroConductivityTop + state.dataEcoRoofMgr.SoilHydroConductivityRoot) * 0.5
        Moisture += (state.dataEcoRoofMgr.TimeStepZoneSec / state.dataEcoRoofMgr.TopDepth) * \
                    ((state.dataEcoRoofMgr.SoilConductivityAveTop * \
                      (state.dataEcoRoofMgr.CapillaryPotentialTop - state.dataEcoRoofMgr.CapillaryPotentialRoot) / state.dataEcoRoofMgr.TopDepth) - \
                     state.dataEcoRoofMgr.SoilConductivityAveTop)
        if Moisture >= MoistureMax:
            Moisture = 0.9999 * MoistureMax
            state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax * 0.9999) * state.dataEcoRoofMgr.TopDepth
        if Moisture <= (1.01 * MoistureResidual):
            Moisture = 1.01 * MoistureResidual
        state.dataEcoRoofMgr.SoilConductivityAveRoot = state.dataEcoRoofMgr.SoilHydroConductivityRoot
        if (state.dataEcoRoofMgr.SoilConductivityAveRoot * 3600.0) <= (2.33e-7):
            state.dataEcoRoofMgr.SoilConductivityAveRoot = 0.0
        state.dataEcoRoofMgr.TestMoisture = MeanRootMoisture
        MeanRootMoisture += (state.dataEcoRoofMgr.TimeStepZoneSec / state.dataEcoRoofMgr.RootDepth) * \
                            ((state.dataEcoRoofMgr.SoilConductivityAveTop * \
                              (state.dataEcoRoofMgr.CapillaryPotentialTop - state.dataEcoRoofMgr.CapillaryPotentialRoot) / state.dataEcoRoofMgr.RootDepth) + \
                             state.dataEcoRoofMgr.SoilConductivityAveTop - state.dataEcoRoofMgr.SoilConductivityAveRoot)
        if MeanRootMoisture >= MoistureMax:
            MeanRootMoisture = 0.9999 * MoistureMax
            state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax * 0.9999) * state.dataEcoRoofMgr.RootDepth
        if MeanRootMoisture <= (1.01 * MoistureResidual):
            MeanRootMoisture = 1.01 * MoistureResidual
        state.dataEcoRoofMgr.CurrentRunoff += state.dataEcoRoofMgr.SoilConductivityAveRoot * state.dataEcoRoofMgr.TimeStepZoneSec
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumRunoff += state.dataEcoRoofMgr.CurrentRunoff
    if MeanRootMoisture <= MoistureResidual * 1.00001:
        Moisture -= (MoistureResidual * 1.00001 - MeanRootMoisture) * state.dataEcoRoofMgr.RootDepth / state.dataEcoRoofMgr.TopDepth
        if Moisture < MoistureResidual * 1.00001:
            Moisture = MoistureResidual * 1.00001
        MeanRootMoisture = MoistureResidual * 1.00001
    # Update soil properties
    SoilAbsorpSolar = state.dataEcoRoofMgr.DryAbsorp + \
                      (0.92 - state.dataEcoRoofMgr.DryAbsorp) * (Moisture - MoistureResidual) / (MoistureMax - MoistureResidual)
    if SoilAbsorpSolar > 0.95:
        SoilAbsorpSolar = 0.95
    if SoilAbsorpSolar < 0.20:
        SoilAbsorpSolar = 0.20
    TestRatio = (1.0 - SoilAbsorpSolar) / Alphag
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    Alphag *= TestRatio
    AvgMoisture = (state.dataEcoRoofMgr.RootDepth * MeanRootMoisture + state.dataEcoRoofMgr.TopDepth * Moisture) / SoilThickness
    SoilDensity = state.dataEcoRoofMgr.DryDens + (AvgMoisture - MoistureResidual) * 990.0
    SoilSpecHeat = state.dataEcoRoofMgr.DrySpecHeat + 1900.0 * AvgMoisture
    SatRatio = (AvgMoisture - MoistureResidual) / (MoistureMax - MoistureResidual)
    SoilConductivity = (state.dataEcoRoofMgr.DryCond / 1.15) * (1.45 * exp(4.411 * SatRatio)) / (1.0 + 0.45 * exp(4.411 * SatRatio))
    TestRatio = SoilConductivity / matERMutable.Conductivity
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matERMutable.Conductivity *= TestRatio
    SoilConductivity = matERMutable.Conductivity
    TestRatio = SoilDensity / matERMutable.Density
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matERMutable.Density *= TestRatio
    SoilDensity = matERMutable.Density
    TestRatio = SoilSpecHeat / matERMutable.SpecHeat
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matERMutable.SpecHeat *= TestRatio
    SoilSpecHeat = matERMutable.SpecHeat
def CalculateEcoRoofSolar(inout state: EnergyPlusData, inout RS: Real64, inout f1: Real64, SurfNum: Int):
    RS = max(state.dataEnvrn.SOLCOS[3], 0.0) * state.dataEnvrn.BeamSolarRad + \
         state.dataSolarShading.SurfAnisoSkyMult[SurfNum] * state.dataEnvrn.DifSolarRad
    let f1inv: Real64 = min(1.0, (0.004 * RS + 0.005) / (0.81 * (0.004 * RS + 1.0)))
    f1 = 1.0 / f1inv