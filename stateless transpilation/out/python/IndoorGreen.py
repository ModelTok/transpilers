from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, List, Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: Main simulation state object from EnergyPlus/Data/EnergyPlusData.hh
# - Schedule: From ScheduleManager, has getCurrentVal() and checkMinVal() methods
# - Surface: From DataSurfaces, surface properties
# - DaylightingControl, RefPointData: From DataDaylighting
# - Psychrometrics: PsyTdpFnWPb, PsyPsatFnTemp, PsyRhoAirFnPbTdbW, PsyHfgAirFnWTdb, PsyTwbFnTdbWPb, PsyWFnTdbRhPb, PsyHFnTdbW, PsyTdbFnHW, PsyCpAirFnW
# - UtilityRoutines: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowSevereBadMin
# - OutputProcessor: SetupZoneInternalGain, SetupOutputVariable
# - EMSManager: SetupEMSActuator
# - General utilities: format (string formatting)


class ETCalculationMethod(Enum):
    Invalid = -1
    PenmanMonteith = 0
    Stanghellini = 1
    Num = 2


class LightingMethod(Enum):
    Invalid = -1
    LED = 0
    Daylighting = 1
    LEDDaylighting = 2
    Num = 3


@dataclass
class IndoorGreenParams:
    Name: str = ""
    ZoneName: str = ""
    SurfName: str = ""
    sched: Optional['Schedule'] = None
    ledSched: Optional['Schedule'] = None
    LightRefPtr: int = 0
    LightControlPtr: int = 0
    ledDaylightTargetSched: Optional['Schedule'] = None
    LeafArea: float = 0.0
    LEDNominalPPFD: float = 0.0
    LEDNominalEleP: float = 0.0
    LEDRadFraction: float = 0.0
    ZCO2: float = 400.0
    ZVPD: float = 0.0
    ZPPFD: float = 0.0
    SensibleRate: float = 0.0
    SensibleRateLED: float = 0.0
    LatentRate: float = 0.0
    ETRate: float = 0.0
    LambdaET: float = 0.0
    LEDActualPPFD: float = 0.0
    LEDActualEleP: float = 0.0
    LEDActualEleCon: float = 0.0
    SurfPtr: int = 0
    ZoneListPtr: int = 0
    ZonePtr: int = 0
    SpacePtr: int = 0
    etCalculationMethod: ETCalculationMethod = ETCalculationMethod.PenmanMonteith
    lightingMethod: LightingMethod = LightingMethod.LED
    CheckIndoorGreenName: bool = True
    EMSET: float = 0.0
    EMSETCalOverrideOn: bool = False
    FieldNames: List[str] = field(default_factory=list)


@dataclass
class IndoorGreenData:
    NumIndoorGreen: int = 0
    getInputFlag: bool = True
    indoorGreens: List[IndoorGreenParams] = field(default_factory=list)

    def clear_state(self):
        self.NumIndoorGreen = 0
        self.getInputFlag = True
        self.indoorGreens = []


ET_CALCULATION_METHODS_UC = ["PENMAN-MONTEITH", "STANGHELLINI"]
LIGHTING_METHODS_UC = ["LED", "DAYLIGHT", "LED-DAYLIGHT"]


def get_enum_value(enum_strings: List[str], test_string: str) -> int:
    test_upper = test_string.upper()
    for i, s in enumerate(enum_strings):
        if s == test_upper:
            return i
    return -1


def SimIndoorGreen(state: 'EnergyPlusData') -> None:
    lw = state.dataIndoorGreen
    if lw.getInputFlag:
        ErrorsFound = False
        GetIndoorGreenInput(state, ErrorsFound)
        if ErrorsFound:
            RoutineName = "IndoorLivingWall: "
            raise RuntimeError(f"{RoutineName}Errors found in input.  Program terminates.")
        SetIndoorGreenOutput(state)
        lw.getInputFlag = False
    
    if lw.NumIndoorGreen > 0:
        InitIndoorGreen(state)
        ETModel(state)


def GetIndoorGreenInput(state: 'EnergyPlusData', ErrorsFound: bool) -> None:
    s_lw = state.dataIndoorGreen
    s_ip = state.dataInputProcessing.inputProcessor
    s_ipsc = state.dataIPShortCut

    RoutineName = "GetIndoorLivingWallInput: "
    cCurrentModuleObject = "IndoorLivingWall"

    s_lw.NumIndoorGreen = s_ip.getNumObjectsFound(state, cCurrentModuleObject)
    if s_lw.NumIndoorGreen > 0:
        s_lw.indoorGreens = [IndoorGreenParams() for _ in range(s_lw.NumIndoorGreen)]

    for IndoorGreenNum in range(s_lw.NumIndoorGreen):
        ig = s_lw.indoorGreens[IndoorGreenNum]
        s_ip.getObjectItem(state,
                          cCurrentModuleObject,
                          IndoorGreenNum + 1,
                          s_ipsc.cAlphaArgs,
                          s_ipsc.rNumericArgs,
                          s_ipsc.lNumericFieldBlanks,
                          s_ipsc.lAlphaFieldBlanks,
                          s_ipsc.cAlphaFieldNames,
                          s_ipsc.cNumericFieldNames)

        ig.Name = s_ipsc.cAlphaArgs[0]
        ig.SurfName = s_ipsc.cAlphaArgs[1]
        ig.SurfPtr = find_item_in_list(s_ipsc.cAlphaArgs[1], state.dataSurface.Surface)

        if ig.SurfPtr <= 0:
            ErrorsFound = True
        else:
            if state.dataSurface.Surface[ig.SurfPtr - 1].insideHeatSourceTermSched is not None:
                ErrorsFound = True
            
            ig.ZonePtr = state.dataSurface.Surface[ig.SurfPtr - 1].Zone
            ig.SpacePtr = state.dataSurface.Surface[ig.SurfPtr - 1].spaceNum

            if ig.ZonePtr <= 0 or ig.SpacePtr <= 0:
                ErrorsFound = True
            elif (state.dataSurface.Surface[ig.SurfPtr - 1].ExtBoundCond < 0 or
                  state.dataSurface.Surface[ig.SurfPtr - 1].HeatTransferAlgorithm != "CTF"):
                ErrorsFound = True

        ig.sched = get_schedule(state, s_ipsc.cAlphaArgs[2])
        if ig.sched is None:
            ErrorsFound = True
        elif not ig.sched.checkMinVal(state, 0.0):
            ErrorsFound = True

        ig.etCalculationMethod = ETCalculationMethod.PenmanMonteith
        ig.etCalculationMethod = ETCalculationMethod(get_enum_value(ET_CALCULATION_METHODS_UC, s_ipsc.cAlphaArgs[3]))
        ig.lightingMethod = LightingMethod.LED
        ig.lightingMethod = LightingMethod(get_enum_value(LIGHTING_METHODS_UC, s_ipsc.cAlphaArgs[4]))

        if ig.lightingMethod == LightingMethod.LED:
            ig.ledSched = get_schedule(state, s_ipsc.cAlphaArgs[5])
            if ig.ledSched is None:
                ErrorsFound = True
            elif not ig.ledSched.checkMinVal(state, 0.0):
                ErrorsFound = True

        elif ig.lightingMethod == LightingMethod.Daylighting:
            ig.LightRefPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.DaylRefPt)
            ig.LightControlPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.daylightControl)
            if ig.LightControlPtr == 0:
                ErrorsFound = True
                continue

        elif ig.lightingMethod == LightingMethod.LEDDaylighting:
            ig.LightRefPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.DaylRefPt)
            ig.LightControlPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.daylightControl)
            if ig.LightControlPtr == 0:
                ErrorsFound = True
                continue

            ig.ledDaylightTargetSched = get_schedule(state, s_ipsc.cAlphaArgs[7])
            if ig.ledDaylightTargetSched is None:
                ErrorsFound = True
            elif not ig.ledDaylightTargetSched.checkMinVal(state, 0.0):
                ErrorsFound = True

        ig.LeafArea = s_ipsc.rNumericArgs[0]
        if ig.LeafArea < 0:
            ErrorsFound = True

        ig.LEDNominalPPFD = s_ipsc.rNumericArgs[1]
        if ig.LEDNominalPPFD < 0:
            ErrorsFound = True

        ig.LEDNominalEleP = s_ipsc.rNumericArgs[2]
        if ig.LEDNominalEleP < 0:
            ErrorsFound = True

        ig.LEDRadFraction = s_ipsc.rNumericArgs[3]
        if ig.LEDRadFraction < 0 or ig.LEDRadFraction > 1.0:
            ErrorsFound = True

        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "IndoorLivingWall", ig.Name, "Evapotranspiration Rate", "[kg_m2s]", ig.EMSETCalOverrideOn, ig.EMSET)


def SetIndoorGreenOutput(state: 'EnergyPlusData') -> None:
    lw = state.dataIndoorGreen
    for IndoorGreenNum in range(lw.NumIndoorGreen):
        ig = lw.indoorGreens[IndoorGreenNum]
        SetupZoneInternalGain(state,
                             ig.ZonePtr,
                             ig.Name,
                             "IndoorGreen",
                             ig.SensibleRate,
                             ig.LatentRate)

        SetupOutputVariable(state,
                           "Indoor Living Wall Plant Surface Temperature",
                           "C",
                           state.dataHeatBalSurf.SurfTempIn[ig.SurfPtr - 1],
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Sensible Heat Gain Rate",
                           "W",
                           ig.SensibleRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Latent Heat Gain Rate",
                           "W",
                           ig.LatentRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Evapotranspiration Rate",
                           "kg_m2s",
                           ig.ETRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Energy Rate Required For Evapotranspiration Per Unit Area",
                           "W_m2",
                           ig.LambdaET,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Operational PPFD",
                           "umol_m2s",
                           ig.LEDActualPPFD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall PPFD",
                           "umol_m2s",
                           ig.ZPPFD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Vapor Pressure Deficit",
                           "Pa",
                           ig.ZVPD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Sensible Heat Gain Rate",
                           "W",
                           ig.SensibleRateLED,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Operational Power",
                           "W",
                           ig.LEDActualEleP,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Electricity Energy",
                           "J",
                           ig.LEDActualEleCon,
                           "Zone",
                           "Sum",
                           ig.Name,
                           "Electricity",
                           "Building",
                           "InteriorLights",
                           "IndoorLivingWall",
                           state.dataHeatBal.Zone[ig.ZonePtr - 1].Name,
                           state.dataHeatBal.Zone[ig.ZonePtr - 1].Multiplier,
                           state.dataHeatBal.Zone[ig.ZonePtr - 1].ListMultiplier,
                           state.dataHeatBal.space[ig.SpacePtr - 1].spaceType)


def InitIndoorGreen(state: 'EnergyPlusData') -> None:
    for ig in state.dataIndoorGreen.indoorGreens:
        ig.SensibleRate = 0.0
        ig.SensibleRateLED = 0.0
        ig.LatentRate = 0.0
        ig.ZCO2 = 400.0
        ig.ZPPFD = 0.0


def ETModel(state: 'EnergyPlusData') -> None:
    RoutineName = "ETModel: "
    lw = state.dataIndoorGreen
    Timestep = state.dataHVACGlobal.TimeStepSysSec

    for IndoorGreenNum in range(lw.NumIndoorGreen):
        ig = lw.indoorGreens[IndoorGreenNum]
        ZonePreTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ig.ZonePtr - 1].ZT
        ZonePreHum = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ig.ZonePtr - 1].airHumRat
        ZoneCO2 = 400.0
        OutPb = state.dataEnvrn.OutBaroPress / 1000.0
        
        Tdp = Psychrometrics.PsyTdpFnWPb(state, ZonePreHum, OutPb * 1000)
        vp = Psychrometrics.PsyPsatFnTemp(state, Tdp, RoutineName) / 1000.0
        vpSat = Psychrometrics.PsyPsatFnTemp(state, ZonePreTemp, RoutineName) / 1000.0
        ig.ZVPD = (vpSat - vp) * 1000.0

        LAI_Cal = ig.LeafArea / state.dataSurface.Surface[ig.SurfPtr - 1].Area
        LAI = LAI_Cal
        if LAI_Cal > 10.0:
            LAI = 10.0

        if ig.lightingMethod == LightingMethod.LED:
            ig.ZPPFD = ig.ledSched.getCurrentVal() * ig.LEDNominalPPFD
            ig.LEDActualPPFD = ig.ZPPFD
            ig.LEDActualEleP = ig.ledSched.getCurrentVal() * ig.LEDNominalEleP
            ig.LEDActualEleCon = ig.LEDActualEleP * Timestep

        elif ig.lightingMethod == LightingMethod.Daylighting:
            ig.ZPPFD = 0.0
            ig.LEDActualPPFD = 0.0
            ig.LEDActualEleP = 0.0
            ig.LEDActualEleCon = 0.0
            if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                ig.ZPPFD = state.dataDayltg.daylightControl[ig.LightControlPtr - 1].refPts[0].lums[0] / 77.0

        elif ig.lightingMethod == LightingMethod.LEDDaylighting:
            a = ig.ledDaylightTargetSched.getCurrentVal()
            b = 0.0
            if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                b = state.dataDayltg.daylightControl[ig.LightControlPtr - 1].refPts[0].lums[0] / 77.0
            
            ig.LEDActualPPFD = max((a - b), 0.0)
            if ig.LEDActualPPFD >= ig.LEDNominalPPFD:
                ig.ZPPFD = ig.LEDNominalPPFD + b
                ig.LEDActualEleP = ig.LEDNominalEleP
                ig.LEDActualEleCon = ig.LEDNominalEleP * Timestep
            else:
                ig.ZPPFD = a
                ig.LEDActualEleP = ig.LEDNominalEleP * ig.LEDActualPPFD / ig.LEDNominalPPFD
                ig.LEDActualEleCon = ig.LEDActualEleP * Timestep

        ZonePPFD = ig.ZPPFD
        ZoneVPD = ig.ZVPD / 1000.0

        if ig.EMSETCalOverrideOn:
            ig.ETRate = ig.EMSET
        else:
            SwitchF = 1.0 if ig.etCalculationMethod == ETCalculationMethod.PenmanMonteith else 2.0 * LAI
            ig.ETRate = ETBaseFunction(state, ZonePreTemp, ZonePreHum, ZonePPFD, ZoneVPD, LAI, SwitchF)

        effectivearea = min(ig.LeafArea, LAI * state.dataSurface.Surface[ig.SurfPtr - 1].Area)
        ETTotal = ig.ETRate * Timestep * effectivearea * ig.sched.getCurrentVal()
        
        hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / (10 ** 6)
        ig.LambdaET = ETTotal * hfg * (10 ** 6) / state.dataSurface.Surface[ig.SurfPtr - 1].Area / Timestep

        rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, ZonePreTemp, ZonePreHum)
        ZoneAirVol = state.dataHeatBal.Zone[ig.ZonePtr - 1].Volume
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

        state.dataHeatBalSurf.SurfQAdditionalHeatSourceInside[ig.SurfPtr - 1] = \
            ig.LEDRadFraction * 0.9 * ig.LEDActualEleP / state.dataSurface.Surface[ig.SurfPtr - 1].Area


def ETBaseFunction(state: 'EnergyPlusData', ZonePreTemp: float, ZonePreHum: float, 
                   ZonePPFD: float, ZoneVPD: float, LAI: float, SwitchF: float) -> float:
    hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / (10 ** 6)
    slopepat = 0.200 * ((0.00738 * ZonePreTemp + 0.8072) ** 7) - 0.000116
    CpAir = Psychrometrics.PsyCpAirFnW(ZonePreHum) / (10 ** 6)
    OutPb = state.dataEnvrn.OutBaroPress / 1000.0
    mw = 0.622
    psyconst = CpAir * OutPb / (hfg * mw)
    In = ZonePPFD * 0.327 / (10 ** 6)
    G = 0.0
    rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, OutPb * 1000.0, ZonePreTemp, ZonePreHum)
    rs = 60.0 * (1500.0 + ZonePPFD) / (200.0 + ZonePPFD)
    ra = 350.0 * ((0.1 / 0.1) ** 0.5) * (1.0 / (LAI + 1e-10))
    ETRate = (1.0 / hfg) * (slopepat * (In - G) + (SwitchF * rhoair * CpAir * ZoneVPD) / ra) / \
             (slopepat + psyconst * (1.0 + rs / ra))
    return ETRate


def find_item_in_list(item: str, item_list: List[object]) -> int:
    for i, x in enumerate(item_list):
        if x.Name == item:
            return i + 1
    return 0


def get_schedule(state: 'EnergyPlusData', schedule_name: str) -> Optional['Schedule']:
    pass


def SetupEMSActuator(state: 'EnergyPlusData', component_type: str, component_name: str,
                     control_type: str, units: str, override_flag: bool, setpoint: float) -> None:
    pass


def SetupZoneInternalGain(state: 'EnergyPlusData', zone_ptr: int, name: str, gain_type: str,
                          sensible_rate: float, latent_rate: float) -> None:
    pass


def SetupOutputVariable(state: 'EnergyPlusData', variable_name: str, units: str, variable_ref: float,
                        timestepping: str, store_type: str, name: str, *args) -> None:
    pass


class Psychrometrics:
    @staticmethod
    def PsyTdpFnWPb(state: 'EnergyPlusData', W: float, Pb: float) -> float:
        pass

    @staticmethod
    def PsyPsatFnTemp(state: 'EnergyPlusData', T: float, routine_name: str) -> float:
        pass

    @staticmethod
    def PsyRhoAirFnPbTdbW(state: 'EnergyPlusData', Pb: float, Tdb: float, W: float) -> float:
        pass

    @staticmethod
    def PsyHfgAirFnWTdb(W: float, T: float) -> float:
        pass

    @staticmethod
    def PsyTwbFnTdbWPb(state: 'EnergyPlusData', Tdb: float, W: float, Pb: float) -> float:
        pass

    @staticmethod
    def PsyWFnTdbRhPb(state: 'EnergyPlusData', Tdb: float, Rh: float, Pb: float) -> float:
        pass

    @staticmethod
    def PsyHFnTdbW(Tdb: float, W: float) -> float:
        pass

    @staticmethod
    def PsyTdbFnHW(H: float, W: float) -> float:
        pass

    @staticmethod
    def PsyCpAirFnW(W: float) -> float:
        pass
