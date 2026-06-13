# Translated from C++ to Mojo: src/EnergyPlus/IndoorGreen.cc
# Faithful 1:1 translation, no refactoring.

from Construction import *
from Data.EnergyPlusData import EnergyPlusData
from DataDaylighting import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataSurfaces import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from DaylightingManager import *
from EMSManager import *
from General import *
from GeneralRoutines import *
from HeatBalanceInternalHeatGains import *
from InputProcessing.InputProcessor import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from api.datatransfer import *

alias ETCalculationMethodsUC = List[StringLiteral](
    "PENMAN-MONTEITH",
    "STANGHELLINI"
)

alias LightingMethodsUC = List[StringLiteral](
    "LED",
    "DAYLIGHT",
    "LED-DAYLIGHT"
)

enum ETCalculationMethod(Int):
    Invalid = -1
    PenmanMonteith = 0
    Stanghellini = 1
    Num = 2

enum LightingMethod(Int):
    Invalid = -1
    LED = 0
    Daylighting = 1
    LEDDaylighting = 2
    Num = 3

struct IndoorGreenParams:
    var Name: String
    var ZoneName: String
    var SurfName: String
    var sched: Optional[Schedule]
    var ledSched: Optional[Schedule]
    var LightRefPtr: Int = 0
    var LightControlPtr: Int = 0
    var ledDaylightTargetSched: Optional[Schedule]
    var LeafArea: Float64 = 0.0
    var LEDNominalPPFD: Float64 = 0.0
    var LEDNominalEleP: Float64 = 0.0
    var LEDRadFraction: Float64 = 0.0
    var ZCO2: Float64 = 400.0
    var ZVPD: Float64 = 0.0
    var ZPPFD: Float64 = 0.0
    var SensibleRate: Float64 = 0.0
    var SensibleRateLED: Float64 = 0.0
    var LatentRate: Float64 = 0.0
    var ETRate: Float64 = 0.0
    var LambdaET: Float64 = 0.0
    var LEDActualPPFD: Float64 = 0.0
    var LEDActualEleP: Float64 = 0.0
    var LEDActualEleCon: Float64 = 0.0
    var SurfPtr: Int = 0
    var ZoneListPtr: Int = 0
    var ZonePtr: Int = 0
    var SpacePtr: Int = 0
    var etCalculationMethod: ETCalculationMethod
    var lightingMethod: LightingMethod
    var CheckIndoorGreenName: Bool = True
    var EMSET: Float64 = 0.0
    var EMSETCalOverrideOn: Bool = False
    var FieldNames: List[String] = List[String]()

struct IndoorGreenData(BaseGlobalStruct):
    var NumIndoorGreen: Int = 0
    var getInputFlag: Bool = True
    var indoorGreens: List[IndoorGreenParams] = List[IndoorGreenParams]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        # Placement new equivalent: reset to default
        self.NumIndoorGreen = 0
        self.getInputFlag = True
        self.indoorGreens = List[IndoorGreenParams]()

def SimIndoorGreen(inout state: EnergyPlusData):
    var lw = state.dataIndoorGreen
    if lw.getInputFlag:
        var ErrorsFound: Bool = False
        GetIndoorGreenInput(state, ErrorsFound)
        if ErrorsFound:
            var RoutineName = "IndoorLivingWall: "  # include trailing blank space
            ShowFatalError(state, "{}Errors found in input.  Program terminates.".format(RoutineName))
        SetIndoorGreenOutput(state)
        lw.getInputFlag = False
    if lw.NumIndoorGreen > 0:
        InitIndoorGreen(state)
        ETModel(state)

def GetIndoorGreenInput(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    var s_lw = state.dataIndoorGreen
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_ipsc = state.dataIPShortCut
    var RoutineName = "GetIndoorLivingWallInput: "
    var cCurrentModuleObject = "IndoorLivingWall"  # match the idd
    var NumNums: Int
    var NumAlphas: Int
    var IOStat: Int
    s_lw.NumIndoorGreen = s_ip.getNumObjectsFound(state, cCurrentModuleObject)
    if s_lw.NumIndoorGreen > 0:
        s_lw.indoorGreens = List[IndoorGreenParams](capacity=s_lw.NumIndoorGreen)
        for _ in range(s_lw.NumIndoorGreen):
            s_lw.indoorGreens.append(IndoorGreenParams())
    for IndoorGreenNum in range(1, s_lw.NumIndoorGreen + 1):
        var ig_idx = IndoorGreenNum - 1
        var ig = s_lw.indoorGreens[ig_idx]
        s_ip.getObjectItem(
            state,
            cCurrentModuleObject,
            IndoorGreenNum,
            s_ipsc.cAlphaArgs,
            NumAlphas,
            s_ipsc.rNumericArgs,
            NumNums,
            IOStat,
            s_ipsc.lNumericFieldBlanks,
            s_ipsc.lAlphaFieldBlanks,
            s_ipsc.cAlphaFieldNames,
            s_ipsc.cNumericFieldNames,
        )
        var eoh = ErrorObjectHeader(RoutineName, cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        ig.Name = s_ipsc.cAlphaArgs[0]
        ig.SurfName = s_ipsc.cAlphaArgs[1]
        ig.SurfPtr = Util.FindItemInList(s_ipsc.cAlphaArgs[1], state.dataSurface.Surface)
        if ig.SurfPtr <= 0:
            ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1])
            ErrorsFound = True
        else:
            if state.dataSurface.Surface[ig.SurfPtr - 1].insideHeatSourceTermSched is not None:
                ShowSevereError(
                    state,
                    "The indoor green surface {} has an Inside Face Heat Source Term Schedule defined. This surface cannot also be used for indoor green.".format(s_ipsc.cAlphaArgs[1])
                )
                ErrorsFound = True
            ig.ZonePtr = state.dataSurface.Surface[ig.SurfPtr - 1].Zone
            ig.SpacePtr = state.dataSurface.Surface[ig.SurfPtr - 1].spaceNum
            if ig.ZonePtr <= 0 or ig.SpacePtr <= 0:
                ShowSevereError(
                    state,
                    "{}=\"{}\", invalid {} entered={}, {} is not associated with a thermal zone or space".format(
                        RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaArgs[1]
                    )
                )
                ErrorsFound = True
            elif state.dataSurface.Surface[ig.SurfPtr - 1].ExtBoundCond < 0 or \
                 state.dataSurface.Surface[ig.SurfPtr - 1].HeatTransferAlgorithm != DataSurfaces.HeatTransferModel.CTF:
                ShowSevereError(
                    state,
                    "{}=\"{}\", invalid {} entered={}, not a valid surface for indoor green module".format(
                        RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1]
                    )
                )
                ErrorsFound = True
        if (ig.sched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[2])) is None:
            ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2])
            ErrorsFound = True
        elif not ig.sched.checkMinVal(state, Clusive.In, 0.0):
            Sched.ShowSevereBadMin(state, eoh, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2], Clusive.In, 0.0)
            ErrorsFound = True
        ig.etCalculationMethod = ETCalculationMethod.PenmanMonteith  # default
        ig.etCalculationMethod = getEnumValue(ETCalculationMethodsUC, s_ipsc.cAlphaArgs[3]) as ETCalculationMethod
        ig.lightingMethod = LightingMethod.LED  # default
        ig.lightingMethod = getEnumValue(LightingMethodsUC, s_ipsc.cAlphaArgs[4]) as LightingMethod
        match ig.lightingMethod:
            case LightingMethod.LED:
                if (ig.ledSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[5])) is None:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5])
                    ErrorsFound = True
                elif not ig.ledSched.checkMinVal(state, Clusive.In, 0.0):
                    Sched.ShowSevereBadMin(state, eoh, s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5], Clusive.In, 0.0)
                    ErrorsFound = True
            case LightingMethod.Daylighting:
                ig.LightRefPtr = Util.FindItemInList(
                    s_ipsc.cAlphaArgs[6],
                    state.dataDayltg.DaylRefPt,
                    &Dayltg.RefPointData.Name
                )
                ig.LightControlPtr = Util.FindItemInList(
                    s_ipsc.cAlphaArgs[6],
                    state.dataDayltg.daylightControl,
                    &Dayltg.DaylightingControl.Name
                )
                if ig.LightControlPtr == 0:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[6], s_ipsc.cAlphaArgs[6])
                    ErrorsFound = True
                    continue
            case LightingMethod.LEDDaylighting:
                ig.LightRefPtr = Util.FindItemInList(
                    s_ipsc.cAlphaArgs[6],
                    state.dataDayltg.DaylRefPt,
                    &Dayltg.RefPointData.Name
                )
                ig.LightControlPtr = Util.FindItemInList(
                    s_ipsc.cAlphaArgs[6],
                    state.dataDayltg.daylightControl,
                    &Dayltg.DaylightingControl.Name
                )
                if ig.LightControlPtr == 0:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[6], s_ipsc.cAlphaArgs[6])
                    ErrorsFound = True
                    continue
                if (ig.ledDaylightTargetSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[7])) is None:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[7], s_ipsc.cAlphaArgs[7])
                    ErrorsFound = True
                elif not ig.ledDaylightTargetSched.checkMinVal(state, Clusive.In, 0.0):
                    Sched.ShowSevereBadMin(state, eoh, s_ipsc.cAlphaFieldNames[7], s_ipsc.cAlphaArgs[7], Clusive.In, 0.0)
                    ErrorsFound = True
            case _:

        ig.LeafArea = s_ipsc.rNumericArgs[0]
        if ig.LeafArea < 0:
            ShowSevereError(
                state,
                "{}=\"{}\", invalid {} entered={}".format(
                    RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[0], s_ipsc.rNumericArgs[0]
                )
            )
            ErrorsFound = True
        ig.LEDNominalPPFD = s_ipsc.rNumericArgs[1]
        if ig.LEDNominalPPFD < 0:
            ShowSevereError(
                state,
                "{}=\"{}\", invalid {} entered={}".format(
                    RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[1], s_ipsc.rNumericArgs[1]
                )
            )
            ErrorsFound = True
        ig.LEDNominalEleP = s_ipsc.rNumericArgs[2]
        if ig.LEDNominalEleP < 0:
            ShowSevereError(
                state,
                "{}=\"{}\", invalid {} entered={}".format(
                    RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[2], s_ipsc.rNumericArgs[2]
                )
            )
            ErrorsFound = True
        ig.LEDRadFraction = s_ipsc.rNumericArgs[3]
        if ig.LEDRadFraction < 0 or ig.LEDRadFraction > 1.0:
            ShowSevereError(
                state,
                "{}=\"{}\", invalid {} entered={}".format(
                    RoutineName, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[3], s_ipsc.rNumericArgs[3]
                )
            )
            ErrorsFound = True
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "IndoorLivingWall", ig.Name, "Evapotranspiration Rate", "[kg_m2s]", ig.EMSETCalOverrideOn, ig.EMSET)

def SetIndoorGreenOutput(inout state: EnergyPlusData):
    var lw = state.dataIndoorGreen
    for IndoorGreenNum in range(1, lw.NumIndoorGreen + 1):
        var ig_idx = IndoorGreenNum - 1
        var ig = lw.indoorGreens[ig_idx]
        SetupZoneInternalGain(
            state,
            ig.ZonePtr,
            ig.Name,
            DataHeatBalance.IntGainType.IndoorGreen,
            &ig.SensibleRate,
            None,
            None,
            &ig.LatentRate,
            None,
            None,
            None,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Plant Surface Temperature",
            Constant.Units.C,
            state.dataHeatBalSurf.SurfTempIn(ig.SurfPtr),
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Sensible Heat Gain Rate",
            Constant.Units.W,
            ig.SensibleRate,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Latent Heat Gain Rate",
            Constant.Units.W,
            ig.LatentRate,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Evapotranspiration Rate",
            Constant.Units.kg_m2s,
            ig.ETRate,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Energy Rate Required For Evapotranspiration Per Unit Area",
            Constant.Units.W_m2,
            ig.LambdaET,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall LED Operational PPFD",
            Constant.Units.umol_m2s,
            ig.LEDActualPPFD,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall PPFD",
            Constant.Units.umol_m2s,
            ig.ZPPFD,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall Vapor Pressure Deficit",
            Constant.Units.Pa,
            ig.ZVPD,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall LED Sensible Heat Gain Rate",
            Constant.Units.W,
            ig.SensibleRateLED,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall LED Operational Power",
            Constant.Units.W,
            ig.LEDActualEleP,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Average,
            ig.Name,
        )
        SetupOutputVariable(
            state,
            "Indoor Living Wall LED Electricity Energy",
            Constant.Units.J,
            ig.LEDActualEleCon,
            OutputProcessor.TimeStepType.Zone,
            OutputProcessor.StoreType.Sum,
            ig.Name,
            Constant.eResource.Electricity,
            OutputProcessor.Group.Building,
            OutputProcessor.EndUseCat.InteriorLights,
            "IndoorLivingWall",  # End-Use subcategory
            state.dataHeatBal.Zone(ig.ZonePtr).Name,
            state.dataHeatBal.Zone(ig.ZonePtr).Multiplier,
            state.dataHeatBal.Zone(ig.ZonePtr).ListMultiplier,
            state.dataHeatBal.space(ig.SpacePtr).spaceType,
        )

def InitIndoorGreen(state: EnergyPlusData):
    for ig in state.dataIndoorGreen.indoorGreens:
        ig.SensibleRate = 0.0
        ig.SensibleRateLED = 0.0
        ig.LatentRate = 0.0
        ig.ZCO2 = 400.0
        ig.ZPPFD = 0.0

def ETModel(inout state: EnergyPlusData):
    var RoutineName = "ETModel: "
    var lw = state.dataIndoorGreen
    var ZonePreTemp: Float64
    var ZonePreHum: Float64
    var ZoneNewTemp: Float64
    var ZoneNewHum: Float64
    var ZoneSatHum: Float64
    var ZoneCO2: Float64
    var ZonePPFD: Float64
    var ZoneVPD: Float64
    var Timestep: Float64
    var ETTotal: Float64
    var rhoair: Float64
    var Tdp: Float64
    var Twb: Float64
    var HCons: Float64
    var HMid: Float64
    var ZoneAirVol: Float64
    var LAI: Float64
    var LAI_Cal: Float64
    var OutPb: Float64
    var vp: Float64
    var vpSat: Float64
    Timestep = state.dataHVACGlobal.TimeStepSysSec  # s
    for IndoorGreenNum in range(1, lw.NumIndoorGreen + 1):
        var ig_idx = IndoorGreenNum - 1
        var ig = lw.indoorGreens[ig_idx]
        ZonePreTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ig.ZonePtr).ZT
        ZonePreHum = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ig.ZonePtr).airHumRat
        ZoneCO2 = 400.0
        OutPb = state.dataEnvrn.OutBaroPress / 1000.0
        Tdp = Psychrometrics.PsyTdpFnWPb(state, ZonePreHum, OutPb * 1000.0)
        vp = Psychrometrics.PsyPsatFnTemp(state, Tdp, RoutineName) / 1000.0
        vpSat = Psychrometrics.PsyPsatFnTemp(state, ZonePreTemp, RoutineName) / 1000.0
        ig.ZVPD = (vpSat - vp) * 1000.0  # Pa
        LAI_Cal = ig.LeafArea / state.dataSurface.Surface(ig.SurfPtr).Area
        LAI = LAI_Cal
        if LAI_Cal > 10.0:
            LAI = 10.0
            ShowSevereError(
                state,
                "Maximum indoor living wall leaf area index (LAI) =10.0 is used, calculated LAI is {}".format(LAI_Cal),
            )
        match ig.lightingMethod:
            case LightingMethod.LED:
                ig.ZPPFD = ig.ledSched.getCurrentVal() * ig.LEDNominalPPFD  # PPFD
                ig.LEDActualPPFD = ig.ZPPFD
                ig.LEDActualEleP = ig.ledSched.getCurrentVal() * ig.LEDNominalEleP
                ig.LEDActualEleCon = ig.LEDActualEleP * Timestep
            case LightingMethod.Daylighting:
                ig.ZPPFD = 0.0
                ig.LEDActualPPFD = 0.0
                ig.LEDActualEleP = 0.0
                ig.LEDActualEleCon = 0.0
                if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                    ig.ZPPFD = state.dataDayltg.daylightControl(ig.LightControlPtr).refPts(1).lums[DataSurfaces.iLum_Illum] / 77.0
            case LightingMethod.LEDDaylighting:
                var a = ig.ledDaylightTargetSched.getCurrentVal()
                var b = 0.0
                if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                    b = state.dataDayltg.daylightControl(ig.LightControlPtr).refPts(1).lums[DataSurfaces.iLum_Illum] / 77.0
                ig.LEDActualPPFD = max(a - b, 0.0)
                if ig.LEDActualPPFD >= ig.LEDNominalPPFD:
                    ig.ZPPFD = ig.LEDNominalPPFD + b
                    ig.LEDActualEleP = ig.LEDNominalEleP
                    ig.LEDActualEleCon = ig.LEDNominalEleP * Timestep
                else:
                    ig.ZPPFD = a
                    ig.LEDActualEleP = ig.LEDNominalEleP * ig.LEDActualPPFD / ig.LEDNominalPPFD
                    ig.LEDActualEleCon = ig.LEDActualEleP * Timestep
            case _:

        ZonePPFD = ig.ZPPFD
        ZoneVPD = ig.ZVPD / 1000.0  # kPa
        if ig.EMSETCalOverrideOn:
            ig.ETRate = ig.EMSET
        else:
            var SwitchF = 1.0 if ig.etCalculationMethod == ETCalculationMethod.PenmanMonteith else 2.0 * LAI
            ig.ETRate = ETBaseFunction(state, ZonePreTemp, ZonePreHum, ZonePPFD, ZoneVPD, LAI, SwitchF)
        var effectivearea = min(ig.LeafArea, LAI * state.dataSurface.Surface(ig.SurfPtr).Area)
        ETTotal = ig.ETRate * Timestep * effectivearea * ig.sched.getCurrentVal()
        var hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / 10.0 ** 6.0
        ig.LambdaET = ETTotal * hfg * 10.0 ** 6.0 / state.dataSurface.Surface(ig.SurfPtr).Area / Timestep
        rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, ZonePreTemp, ZonePreHum)
        ZoneAirVol = state.dataHeatBal.Zone(ig.ZonePtr).Volume
        ZoneNewHum = ZonePreHum + ETTotal / (rhoair * ZoneAirVol)
        Twb = Psychrometrics.PsyTwbFnTdbWPb(state, ZonePreTemp, ZonePreHum, state.dataEnvrn.OutBaroPress)
        ZoneSatHum = Psychrometrics.PsyWFnTdbRhPb(state, Twb, 1.0, state.dataEnvrn.OutBaroPress)
        HCons = Psychrometrics.PsyHFnTdbW(ZonePreTemp, ZonePreHum)
        if ZoneNewHum <= ZoneSatHum:
            ZoneNewTemp = Psychrometrics.PsyTdbFnHW(HCons, ZoneNewHum)
        else:
            ZoneNewTemp = Twb
            ZoneNewHum = ZoneSatHum
        HMid = Psychrometrics.PsyHFnTdbW(ZoneNewTemp, ZonePreHum)
        ig.LatentRate = ZoneAirVol * rhoair * (HCons - HMid) / Timestep
        ig.SensibleRateLED = (1.0 - ig.LEDRadFraction) * ig.LEDActualEleP
        ig.SensibleRate = -1.0 * ig.LatentRate + ig.SensibleRateLED
        state.dataHeatBalSurf.SurfQAdditionalHeatSourceInside(ig.SurfPtr) = \
            ig.LEDRadFraction * 0.9 * ig.LEDActualEleP / state.dataSurface.Surface(ig.SurfPtr).Area

def ETBaseFunction(
    state: EnergyPlusData,
    ZonePreTemp: Float64,
    ZonePreHum: Float64,
    ZonePPFD: Float64,
    ZoneVPD: Float64,
    LAI: Float64,
    SwitchF: Float64,
) -> Float64:
    var hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / 10.0 ** 6.0
    var slopepat = 0.200 * (0.00738 * ZonePreTemp + 0.8072) ** 7 - 0.000116
    var CpAir = Psychrometrics.PsyCpAirFnW(ZonePreHum) / 10.0 ** 6.0
    var OutPb = state.dataEnvrn.OutBaroPress / 1000.0
    var mw: Float64 = 0.622
    var psyconst = CpAir * OutPb / (hfg * mw)
    var In = ZonePPFD * 0.327 / 10.0 ** 6.0
    var G = 0.0
    var rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, OutPb * 1000.0, ZonePreTemp, ZonePreHum)
    var ETRate: Float64
    var rs = 60.0 * (1500.0 + ZonePPFD) / (200.0 + ZonePPFD)
    var ra = 350.0 * ((0.1 / 0.1) ** 0.5) * (1.0 / (LAI + 1e-10))
    ETRate = (1.0 / hfg) * (slopepat * (In - G) + (SwitchF * rhoair * CpAir * ZoneVPD) / ra) \
             / (slopepat + psyconst * (1.0 + rs / ra))
    return ETRate
