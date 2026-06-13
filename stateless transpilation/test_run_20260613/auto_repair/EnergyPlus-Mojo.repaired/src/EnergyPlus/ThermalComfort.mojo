# Mojo translation of ThermalComfort.cc

# Import necessary modules
from Construction import Construct
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment as Env
from DataGlobals import DataGlobals as Global
from DataHeatBalFanSys import DataHeatBalFanSys as FanSys
from DataHeatBalSurface import DataHeatBalSurf as HeatBalSurf
from DataHeatBalance import (PeopleData, ClothingType, CalcMRT, space, People, Zone, TotPeople)
from DataIPShortCuts import DataIPShortCuts as IPShortCuts
from DataPrecisionGlobals import EXP_LowerLimit
from DataRoomAirModel import DataRoomAirModel as RoomAir
from DataViewFactorInformation import DataViewFactor as ViewFactor
from DataZoneEnergyDemands import DataZoneEnergyDemands as ZoneDemands
from FileSystem import fileExists, open as fileOpen
from General import General
from InputProcessing.InputProcessor import inputProcessor
from OutputProcessor import (SetupOutputVariable, TimeStepType, StoreType)
from OutputReportPredefined import (PreDefTableEntry, addFootNoteSubTable, pdchSCwinterClothes, pdchSCsummerClothes, pdchSCeitherClothes, pdstSimpleComfort, pdchULnotMetHeat, pdchULnotMetCool, pdchULnotMetHeatOcc, pdchULnotMetCoolOcc, pdstUnmetLoads, pdchLeedSutHrsWeek, TotalTimeNotSimpleASH55EitherForABUPS, TotalNotMetHeatingOccupiedForABUPS, TotalNotMetCoolingOccupiedForABUPS, TotalNotMetOccupiedForABUPS)
from OutputReportTabular import (isInQuadrilateral, GetColumnUsingTabs, StrToReal)
from Psychrometrics import PsyRhFnTdbWPb, PsyPsatFnTemp
from ScheduleManager import schedule
from ThermalComfort import (ThermalComfortDataType, ThermalComfortInASH55Type, ThermalComfortSetPointType, AngleFactorData)
from UtilityRoutines import (ShowWarningError, ShowSevereError, ShowFatalError, ShowContinueError, ShowRecurringWarningErrorAtEnd, FindItemInList, ShowContinueErrorTimeStamp)
from ZoneTempPredictorCorrector import zoneHeatBalance, spaceHeatBalance, ZoneTempPredictorCorrector as ZTPC
from FileSystem import fileExists
from ObjexxFCL.string.functions import index, has

from math import sqrt, exp, abs, pow

# Helper functions for power
def pow_2(x: Float64) -> Float64:
    return x * x

def pow_3(x: Float64) -> Float64:
    return x * x * x

def pow_4(x: Float64) -> Float64:
    let x2 = x * x
    return x2 * x2

def root_4(x: Float64) -> Float64:
    return pow(x, 0.25)

# Constants
alias TAbsConv = 273.15  # Constant::Kelvin
alias ActLevelConv = 58.2
alias BodySurfArea = 1.8
alias BodySurfAreaPierce = 1.8258
alias RadSurfEff = 0.72
alias StefanBoltz = 5.6697e-8

# Data structures (from header)
struct ThermalComfortDataType:
    var FangerPMV: Float64 = 0.0
    var FangerPPD: Float64 = 0.0
    var CloSurfTemp: Float64 = 0.0
    var PiercePMVET: Float64 = 0.0
    var PiercePMVSET: Float64 = 0.0
    var PierceDISC: Float64 = 0.0
    var PierceTSENS: Float64 = 0.0
    var PierceSET: Float64 = 0.0
    var KsuTSV: Float64 = 0.0
    var ThermalComfortMRT: Float64 = 0.0
    var ThermalComfortOpTemp: Float64 = 0.0
    var ClothingValue: Float64 = 0.0
    var ThermalComfortAdaptiveASH5590: Int = 0
    var ThermalComfortAdaptiveASH5580: Int = 0
    var ThermalComfortAdaptiveCEN15251CatI: Int = 0
    var ThermalComfortAdaptiveCEN15251CatII: Int = 0
    var ThermalComfortAdaptiveCEN15251CatIII: Int = 0
    var TComfASH55: Float64 = 0.0
    var TComfCEN15251: Float64 = 0.0
    var ASHRAE55RunningMeanOutdoorTemp: Float64 = 0.0
    var CEN15251RunningMeanOutdoorTemp: Float64 = 0.0
    var CoolingEffectASH55: Float64 = 0.0
    var CoolingEffectAdjustedPMVASH55: Float64 = 0.0
    var CoolingEffectAdjustedPPDASH55: Float64 = 0.0
    var AnkleDraftPPDASH55: Float64 = 0.0

struct ThermalComfortInASH55Type:
    var timeNotSummer: Float64 = 0.0
    var timeNotWinter: Float64 = 0.0
    var timeNotEither: Float64 = 0.0
    var totalTimeNotSummer: Float64 = 0.0
    var totalTimeNotWinter: Float64 = 0.0
    var totalTimeNotEither: Float64 = 0.0
    var ZoneIsOccupied: Bool = False
    var warningIndex: Int = 0
    var warningIndex2: Int = 0
    var Enable55Warning: Bool = False

struct ThermalComfortSetPointType:
    var notMetHeating: Float64 = 0.0
    var notMetCooling: Float64 = 0.0
    var notMetHeatingOccupied: Float64 = 0.0
    var notMetCoolingOccupied: Float64 = 0.0
    var totalNotMetHeating: Float64 = 0.0
    var totalNotMetCooling: Float64 = 0.0
    var totalNotMetHeatingOccupied: Float64 = 0.0
    var totalNotMetCoolingOccupied: Float64 = 0.0

struct AngleFactorData:
    var AngleFactor: List[Float64] = List[Float64]()  # EPVector<Real64>
    var Name: String = ""
    var SurfaceName: List[String] = List[String]()
    var SurfacePtr: List[Int] = List[Int]()
    var TotAngleFacSurfaces: Int = 0
    var EnclosurePtr: Int = 0

# Global data struct (from header)
struct ThermalComfortsData:
    var FirstTimeFlag: Bool = True
    var FirstTimeSurfaceWeightedFlag: Bool = True
    var CoolingEffectWarningInd: Int = 0
    var AnkleDraftAirVelWarningInd: Int = 0
    var AnkleDraftCloUnitWarningInd: Int = 0
    var AnkleDraftActMetWarningInd: Int = 0
    var AbsAirTemp: Float64 = 0.0
    var AbsCloSurfTemp: Float64 = 0.0
    var AbsRadTemp: Float64 = 0.0
    var AcclPattern: Float64 = 0.0
    var ActLevel: Float64 = 0.0
    var ActMet: Float64 = 0.0
    var AirVel: Float64 = 0.0
    var AirTemp: Float64 = 0.0
    var CloBodyRat: Float64 = 0.0
    var CloInsul: Float64 = 0.0
    var CloPermeatEff: Float64 = 0.0
    var CloSurfTemp: Float64 = 0.0
    var CloThermEff: Float64 = 0.0
    var CloUnit: Float64 = 0.0
    var ConvHeatLoss: Float64 = 0.0
    var CoreTempChange: Float64 = 0.0
    var CoreTemp: Float64 = 0.0
    var CoreTempNeut: Float64 = 0.0
    var CoreThermCap: Float64 = 0.0
    var DryHeatLoss: Float64 = 0.0
    var DryHeatLossET: Float64 = 0.0
    var DryHeatLossSET: Float64 = 0.0
    var DryRespHeatLoss: Float64 = 0.0
    var EvapHeatLoss: Float64 = 0.0
    var EvapHeatLossDiff: Float64 = 0.0
    var EvapHeatLossMax: Float64 = 0.0
    var EvapHeatLossRegComf: Float64 = 0.0
    var EvapHeatLossRegSweat: Float64 = 0.0
    var EvapHeatLossSweat: Float64 = 0.0
    var EvapHeatLossSweatPrev: Float64 = 0.0
    var H: Float64 = 0.0
    var Hc: Float64 = 0.0
    var HcFor: Float64 = 0.0
    var HcNat: Float64 = 0.0
    var HeatFlow: Float64 = 0.0
    var Hr: Float64 = 0.0
    var IntHeatProd: Float64 = 0.0
    var IterNum: Int = 0
    var LatRespHeatLoss: Float64 = 0.0
    var MaxZoneNum: Int = 0
    var OpTemp: Float64 = 0.0
    var EffTemp: Float64 = 0.0
    var PeopleNum: Int = 0
    var RadHeatLoss: Float64 = 0.0
    var RadTemp: Float64 = 0.0
    var RelHum: Float64 = 0.0
    var RespHeatLoss: Float64 = 0.0
    var SatSkinVapPress: Float64 = 0.0
    var ShivResponse: Float64 = 0.0
    var SkinComfTemp: Float64 = 0.0
    var SkinComfVPress: Float64 = 0.0
    var SkinTemp: Float64 = 0.0
    var SkinTempChange: Float64 = 0.0
    var SkinTempNeut: Float64 = 0.0
    var SkinThermCap: Float64 = 0.0
    var SkinWetDiff: Float64 = 0.0
    var SkinWetSweat: Float64 = 0.0
    var SkinWetTot: Float64 = 0.0
    var SkinVapPress: Float64 = 0.0
    var SurfaceTemp: Float64 = 0.0
    var AvgBodyTemp: Float64 = 0.0
    var ThermCndct: Float64 = 0.0
    var ThermSensTransCoef: Float64 = 0.0
    var Time: Float64 = 0.0
    var TimeChange: Float64 = 0.0
    var VapPress: Float64 = 0.0
    var VasoconstrictFac: Float64 = 0.0
    var VasodilationFac: Float64 = 0.0
    var WorkEff: Float64 = 0.0
    var ZoneNum: Int = 0
    var TemporarySixAMTemperature: Float64 = 0.0
    var AnyZoneTimeNotSimpleASH55Summer: Float64 = 0.0
    var AnyZoneTimeNotSimpleASH55Winter: Float64 = 0.0
    var AnyZoneTimeNotSimpleASH55Either: Float64 = 0.0
    var AnyZoneNotMetHeating: Float64 = 0.0
    var AnyZoneNotMetCooling: Float64 = 0.0
    var AnyZoneNotMetHeatingOccupied: Float64 = 0.0
    var AnyZoneNotMetCoolingOccupied: Float64 = 0.0
    var AnyZoneNotMetOccupied: Float64 = 0.0
    var TotalAnyZoneTimeNotSimpleASH55Summer: Float64 = 0.0
    var TotalAnyZoneTimeNotSimpleASH55Winter: Float64 = 0.0
    var TotalAnyZoneTimeNotSimpleASH55Either: Float64 = 0.0
    var TotalAnyZoneNotMetHeating: Float64 = 0.0
    var TotalAnyZoneNotMetCooling: Float64 = 0.0
    var TotalAnyZoneNotMetHeatingOccupied: Float64 = 0.0
    var TotalAnyZoneNotMetCoolingOccupied: Float64 = 0.0
    var TotalAnyZoneNotMetOccupied: Float64 = 0.0
    var ZoneOccHrs: List[Float64] = List[Float64]()  # Array1D<Real64>
    var useEpwData: Bool = False
    var DailyAveOutTemp: List[Float64] = List[Float64]()  # Array1D<Real64> size 30
    var ThermalComfortInASH55: List[ThermalComfortInASH55Type] = List[ThermalComfortInASH55Type]()
    var ThermalComfortSetPoint: List[ThermalComfortSetPointType] = List[ThermalComfortSetPointType]()
    var ThermalComfortData: List[ThermalComfortDataType] = List[ThermalComfortDataType]()
    var AngleFactorList: List[AngleFactorData] = List[AngleFactorData]()
    var runningAverageASH: Float64 = 0.0
    var Coeff: List[Float64] = List[Float64](2, 0.0)  # Array1D<Real64>(2)
    var Temp: List[Float64] = List[Float64](2, 0.0)   # Array1D<Real64>(2)
    var TempChange: List[Float64] = List[Float64](2, 0.0)  # Array1D<Real64>(2)
    var FirstTimeError: Bool = True
    var avgDryBulbASH: Float64 = 0.0
    var monthlyTemp: List[Float64] = List[Float64](12, 0.0)  # Array1D<Real64>(12,0.0)
    var useStatData: Bool = False
    var avgDryBulbCEN: Float64 = 0.0
    var runningAverageCEN: Float64 = 0.0
    var useEpwDataCEN: Bool = False
    var firstDaySet: Bool = False

    def __init__(inout self):
        self.DailyAveOutTemp = List[Float64](30, 0.0)

# ======== Functions ========

def ManageThermalComfort(inout state: EnergyPlusData, InitializeOnly: Bool):
    if state.dataThermalComforts.FirstTimeFlag:
        InitThermalComfort(state)
        state.dataThermalComforts.FirstTimeFlag = False
    if state.dataGlobal.DayOfSim == 1:
        if state.dataGlobal.HourOfDay < 7:
            state.dataThermalComforts.TemporarySixAMTemperature = 1.868132
        elif state.dataGlobal.HourOfDay == 7:
            if state.dataGlobal.TimeStep == 1:
                state.dataThermalComforts.TemporarySixAMTemperature = state.dataEnvrn.OutDryBulbTemp
    else:
        if state.dataGlobal.HourOfDay == 7:
            if state.dataGlobal.TimeStep == 1:
                state.dataThermalComforts.TemporarySixAMTemperature = state.dataEnvrn.OutDryBulbTemp
    if InitializeOnly:
        return
    if state.dataGlobal.BeginEnvrnFlag:
        state.dataThermalComforts.ZoneOccHrs = List[Float64](state.dataGlobal.NumOfZones, 0.0)  # reinitialize
    if not state.dataGlobal.DoingSizing and not state.dataGlobal.WarmupFlag:
        CalcThermalComfortFanger(state)
        if state.dataHeatBal.AnyThermalComfortPierceModel:
            CalcThermalComfortPierceASHRAE(state)
        if state.dataHeatBal.AnyThermalComfortKSUModel:
            CalcThermalComfortKSU(state)
        if state.dataHeatBal.AnyThermalComfortCoolingEffectModel:
            CalcThermalComfortCoolingEffectASH(state)
        if state.dataHeatBal.AnyThermalComfortAnkleDraftModel:
            CalcThermalComfortAnkleDraftASH(state)
        CalcThermalComfortSimpleASH55(state)
        CalcIfSetPointMet(state)
        if state.dataHeatBal.AdaptiveComfortRequested_ASH55:
            CalcThermalComfortAdaptiveASH55(state, False)
        if state.dataHeatBal.AdaptiveComfortRequested_CEN15251:
            CalcThermalComfortAdaptiveCEN15251(state, False)

def InitThermalComfort(inout state: EnergyPlusData):
    var Loop: Int
    state.dataThermalComforts.ThermalComfortData = List[ThermalComfortDataType](state.dataHeatBal.TotPeople)
    for Loop in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[Loop]
        if people.Fanger:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Fanger Model PMV",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].FangerPMV,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Fanger Model PPD",
                                "Perc",
                                state.dataThermalComforts.ThermalComfortData[Loop].FangerPPD,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Clothing Surface Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].CloSurfTemp,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.Pierce:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Pierce Model Effective Temperature PMV",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].PiercePMVET,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Pierce Model Standard Effective Temperature PMV",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].PiercePMVSET,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Pierce Model Discomfort Index",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].PierceDISC,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Pierce Model Thermal Sensation Index",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].PierceTSENS,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Pierce Model Standard Effective Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].PierceSET,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.KSU:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort KSU Model Thermal Sensation Vote",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].KsuTSV,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.Fanger or people.Pierce or people.KSU:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Mean Radiant Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortMRT,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Operative Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortOpTemp,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort Clothing Value",
                                "clo",
                                state.dataThermalComforts.ThermalComfortData[Loop].ClothingValue,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.AdaptiveASH55:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Adaptive Model 90% Acceptability Status",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortAdaptiveASH5590,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Adaptive Model 80% Acceptability Status",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortAdaptiveASH5580,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Adaptive Model Running Average Outdoor Air Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].ASHRAE55RunningMeanOutdoorTemp,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Adaptive Model Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].TComfASH55,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.AdaptiveCEN15251:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort CEN 15251 Adaptive Model Category I Status",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortAdaptiveCEN15251CatI,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort CEN 15251 Adaptive Model Category II Status",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortAdaptiveCEN15251CatII,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort CEN 15251 Adaptive Model Category III Status",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].ThermalComfortAdaptiveCEN15251CatIII,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort CEN 15251 Adaptive Model Running Average Outdoor Air Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].CEN15251RunningMeanOutdoorTemp,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort CEN 15251 Adaptive Model Temperature",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].TComfCEN15251,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.CoolingEffectASH55:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Elevated Air Speed Cooling Effect",
                                "C",
                                state.dataThermalComforts.ThermalComfortData[Loop].CoolingEffectASH55,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Elevated Air Speed Cooling Effect Adjusted PMV",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].CoolingEffectAdjustedPMVASH55,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Elevated Air Speed Cooling Effect Adjusted PPD",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].CoolingEffectAdjustedPPDASH55,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
        if people.AnkleDraftASH55:
            SetupOutputVariable(state,
                                "Zone Thermal Comfort ASHRAE 55 Ankle Draft PPD",
                                "None",
                                state.dataThermalComforts.ThermalComfortData[Loop].AnkleDraftPPDASH55,
                                TimeStepType.Zone,
                                StoreType.Average,
                                people.Name)
    state.dataThermalComforts.ThermalComfortInASH55 = List[ThermalComfortInASH55Type](state.dataGlobal.NumOfZones)
    for Loop in range(state.dataHeatBal.TotPeople):
        if state.dataHeatBal.People[Loop].Show55Warning:
            state.dataThermalComforts.ThermalComfortInASH55[state.dataHeatBal.People[Loop].ZonePtr].Enable55Warning = True
    for Loop in range(state.dataGlobal.NumOfZones):
        SetupOutputVariable(state,
                            "Zone Thermal Comfort ASHRAE 55 Simple Model Summer Clothes Not Comfortable Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortInASH55[Loop].timeNotSummer,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
        SetupOutputVariable(state,
                            "Zone Thermal Comfort ASHRAE 55 Simple Model Winter Clothes Not Comfortable Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortInASH55[Loop].timeNotWinter,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
        SetupOutputVariable(state,
                            "Zone Thermal Comfort ASHRAE 55 Simple Model Summer or Winter Clothes Not Comfortable Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortInASH55[Loop].timeNotEither,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
    SetupOutputVariable(state,
                        "Facility Thermal Comfort ASHRAE 55 Simple Model Summer Clothes Not Comfortable Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Summer,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    SetupOutputVariable(state,
                        "Facility Thermal Comfort ASHRAE 55 Simple Model Winter Clothes Not Comfortable Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Winter,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    SetupOutputVariable(state,
                        "Facility Thermal Comfort ASHRAE 55 Simple Model Summer or Winter Clothes Not Comfortable Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Either,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    state.dataThermalComforts.ThermalComfortSetPoint = List[ThermalComfortSetPointType](state.dataGlobal.NumOfZones)
    for Loop in range(state.dataGlobal.NumOfZones):
        SetupOutputVariable(state,
                            "Zone Heating Setpoint Not Met Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortSetPoint[Loop].notMetHeating,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
        SetupOutputVariable(state,
                            "Zone Heating Setpoint Not Met While Occupied Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortSetPoint[Loop].notMetHeatingOccupied,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
        SetupOutputVariable(state,
                            "Zone Cooling Setpoint Not Met Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortSetPoint[Loop].notMetCooling,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
        SetupOutputVariable(state,
                            "Zone Cooling Setpoint Not Met While Occupied Time",
                            "hr",
                            state.dataThermalComforts.ThermalComfortSetPoint[Loop].notMetCoolingOccupied,
                            TimeStepType.Zone,
                            StoreType.Sum,
                            state.dataHeatBal.Zone[Loop].Name)
    SetupOutputVariable(state,
                        "Facility Heating Setpoint Not Met Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneNotMetHeating,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    SetupOutputVariable(state,
                        "Facility Cooling Setpoint Not Met Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneNotMetCooling,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    SetupOutputVariable(state,
                        "Facility Heating Setpoint Not Met While Occupied Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneNotMetHeatingOccupied,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    SetupOutputVariable(state,
                        "Facility Cooling Setpoint Not Met While Occupied Time",
                        "hr",
                        state.dataThermalComforts.AnyZoneNotMetCoolingOccupied,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Facility")
    GetAngleFactorList(state)
    state.dataThermalComforts.ZoneOccHrs = List[Float64](state.dataGlobal.NumOfZones, 0.0)

def CalcThermalComfortFanger(inout state: EnergyPlusData,
                             PNum: Optional[Int] = None,
                             Tset: Optional[Float64] = None,
                             PMVResult: Optional[Float64] = None):
    for state.dataThermalComforts.PeopleNum in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
        let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
        if PNum.is_some():
            if state.dataThermalComforts.PeopleNum != PNum.value():
                continue
        if (not people.Fanger) and (not PNum.is_some()):
            continue
        state.dataThermalComforts.ZoneNum = people.ZonePtr
        let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataThermalComforts.ZoneNum]
        if PNum.is_some():
            state.dataThermalComforts.AirTemp = Tset.value()
        else:
            state.dataThermalComforts.AirTemp = thisZoneHB.ZTAVComf
        if state.dataRoomAir.anyNonMixingRoomAirModel:
            let zoneNum = people.ZonePtr
            if state.dataRoomAir.IsZoneDispVent3Node(zoneNum) or state.dataRoomAir.IsZoneUFAD(zoneNum):
                state.dataThermalComforts.AirTemp = state.dataRoomAir.TCMF[zoneNum]
            elif state.dataRoomAir.IsZoneCrossVent(zoneNum):
                if state.dataRoomAir.ZoneCrossVent[zoneNum].VforComfort == RoomAir.Comfort.Jet:
                    state.dataThermalComforts.AirTemp = state.dataRoomAir.ZTJET[zoneNum]
                elif state.dataRoomAir.ZoneCrossVent[zoneNum].VforComfort == RoomAir.Comfort.Recirculation:
                    state.dataThermalComforts.AirTemp = state.dataRoomAir.ZTJET[zoneNum]
        state.dataThermalComforts.RadTemp = CalcRadTemp(state, state.dataThermalComforts.PeopleNum)
        if PNum.is_some():
            state.dataThermalComforts.RelHum = PsyRhFnTdbWPb(state,
                                                              state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataThermalComforts.ZoneNum].MAT,
                                                              thisZoneHB.airHumRatAvgComf,
                                                              state.dataEnvrn.OutBaroPress)
        else:
            state.dataThermalComforts.RelHum = PsyRhFnTdbWPb(state, state.dataThermalComforts.AirTemp, thisZoneHB.airHumRatAvgComf, state.dataEnvrn.OutBaroPress)
        people.TemperatureInZone = state.dataThermalComforts.AirTemp
        people.RelativeHumidityInZone = state.dataThermalComforts.RelHum * 100.0
        state.dataThermalComforts.ActLevel = people.activityLevelSched.getCurrentVal() / BodySurfArea
        state.dataThermalComforts.WorkEff = people.workEffSched.getCurrentVal() * state.dataThermalComforts.ActLevel
        var IntermediateClothing: Float64
        match people.clothingType:
            case ClothingType.InsulationSchedule:
                state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
            case ClothingType.DynamicAshrae55:
                comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
                DynamicClothingModel(state)
                state.dataThermalComforts.CloUnit = comfort.ClothingValue
            case ClothingType.CalculationSchedule:
                IntermediateClothing = people.clothingMethodSched.getCurrentVal()
                if IntermediateClothing == 1.0:
                    state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                    comfort.ClothingValue = state.dataThermalComforts.CloUnit
                elif IntermediateClothing == 2.0:
                    comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                    comfort.ClothingValue = state.dataThermalComforts.CloUnit
                    DynamicClothingModel(state)
                    state.dataThermalComforts.CloUnit = comfort.ClothingValue
                else:
                    state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                    ShowWarningError(state,
                                    "PEOPLE=\"{}\", Scheduled clothing value will be used rather than clothing calculation method.".format(people.Name))
            case _:
                ShowSevereError(state, "PEOPLE=\"{}\", Incorrect Clothing Type".format(people.Name))
        if state.dataRoomAir.anyNonMixingRoomAirModel and state.dataRoomAir.IsZoneCrossVent(state.dataThermalComforts.ZoneNum):
            if state.dataRoomAir.ZoneCrossVent[state.dataThermalComforts.ZoneNum].VforComfort == RoomAir.Comfort.Jet:
                state.dataThermalComforts.AirVel = state.dataRoomAir.Ujet[state.dataThermalComforts.ZoneNum]
            elif state.dataRoomAir.ZoneCrossVent[state.dataThermalComforts.ZoneNum].VforComfort == RoomAir.Comfort.Recirculation:
                state.dataThermalComforts.AirVel = state.dataRoomAir.Urec[state.dataThermalComforts.ZoneNum]
            else:
                state.dataThermalComforts.AirVel = 0.2
        else:
            state.dataThermalComforts.AirVel = people.airVelocitySched.getCurrentVal()
            if PNum.is_some() and (state.dataThermalComforts.AirVel < 0.1 or state.dataThermalComforts.AirVel > 0.5):
                if people.AirVelErrIndex == 0:
                    ShowWarningMessage(state,
                                       "PEOPLE=\"{}\", Air velocity is beyond the reasonable range (0.1,0.5) for thermal comfort control.".format(people.Name))
                    ShowContinueErrorTimeStamp(state, "")
                ShowRecurringWarningErrorAtEnd(state,
                                               "PEOPLE=\"" + people.Name + "\",Air velocity is still beyond the reasonable range (0.1,0.5)",
                                               people.AirVelErrIndex,
                                               state.dataThermalComforts.AirVel,
                                               state.dataThermalComforts.AirVel,
                                               _,
                                               "[m/s]",
                                               "[m/s]")
        let PMV = CalcFangerPMV(state,
                                state.dataThermalComforts.AirTemp,
                                state.dataThermalComforts.RadTemp,
                                state.dataThermalComforts.RelHum,
                                state.dataThermalComforts.AirVel,
                                state.dataThermalComforts.ActLevel,
                                state.dataThermalComforts.CloUnit,
                                state.dataThermalComforts.WorkEff)
        comfort.FangerPMV = PMV
        if PMVResult.is_some():
            PMVResult.value() = PMV
        comfort.ThermalComfortMRT = state.dataThermalComforts.RadTemp
        comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
        comfort.CloSurfTemp = state.dataThermalComforts.CloSurfTemp
        let PPD = CalcFangerPPD(PMV)
        comfort.FangerPPD = PPD

def CalcFangerPMV(state: EnergyPlusData, AirTemp: Float64, RadTemp: Float64, RelHum: Float64, AirVel: Float64, ActLevel: Float64, CloUnit: Float64, WorkEff: Float64) -> Float64:
    let MaxIter = 150
    let StopIterCrit = 0.00015
    var P1: Float64
    var P2: Float64
    var P3: Float64
    var P4: Float64
    var XF: Float64
    var XN: Float64
    var PMV: Float64
    state.dataThermalComforts.VapPress = PsyPsatFnTemp(state, AirTemp)
    state.dataThermalComforts.VapPress *= RelHum
    state.dataThermalComforts.IntHeatProd = ActLevel - WorkEff
    let stdICL = 0.155 * CloUnit
    if stdICL < 0.078:
        state.dataThermalComforts.CloBodyRat = 1.0 + 1.29 * stdICL
    else:
        state.dataThermalComforts.CloBodyRat = 1.05 + 0.645 * stdICL
    state.dataThermalComforts.AbsRadTemp = RadTemp + TAbsConv
    state.dataThermalComforts.AbsAirTemp = AirTemp + TAbsConv
    state.dataThermalComforts.CloInsul = stdICL * state.dataThermalComforts.CloBodyRat
    P2 = state.dataThermalComforts.CloInsul * 3.96
    P3 = state.dataThermalComforts.CloInsul * 100.0
    P1 = state.dataThermalComforts.CloInsul * state.dataThermalComforts.AbsAirTemp
    P4 = 308.7 - 0.028 * state.dataThermalComforts.IntHeatProd + P2 * pow_4(state.dataThermalComforts.AbsRadTemp / 100.0)
    state.dataThermalComforts.AbsCloSurfTemp = state.dataThermalComforts.AbsAirTemp + (35.5 - AirTemp) / (3.5 * stdICL + 0.1)
    XN = state.dataThermalComforts.AbsCloSurfTemp / 100.0
    state.dataThermalComforts.HcFor = 12.1 * sqrt(AirVel)
    state.dataThermalComforts.IterNum = 0
    XF = XN
    while ((abs(XN - XF) > StopIterCrit) or (state.dataThermalComforts.IterNum == 0)) and (state.dataThermalComforts.IterNum < MaxIter):
        XF = (XF + XN) / 2.0
        state.dataThermalComforts.HcNat = 2.38 * root_4(abs(100.0 * XF - state.dataThermalComforts.AbsAirTemp))
        state.dataThermalComforts.Hc = max(state.dataThermalComforts.HcFor, state.dataThermalComforts.HcNat)
        XN = (P4 + P1 * state.dataThermalComforts.Hc - P2 * pow_4(XF)) / (100.0 + P3 * state.dataThermalComforts.Hc)
        state.dataThermalComforts.IterNum += 1
        if state.dataThermalComforts.IterNum > MaxIter:
            ShowWarningError(state, "Max iteration exceeded in CalcThermalFanger")
    state.dataThermalComforts.AbsCloSurfTemp = 100.0 * XN
    state.dataThermalComforts.CloSurfTemp = state.dataThermalComforts.AbsCloSurfTemp - TAbsConv
    state.dataThermalComforts.RadHeatLoss = 3.96 * state.dataThermalComforts.CloBodyRat * (pow_4(state.dataThermalComforts.AbsCloSurfTemp * 0.01) - pow_4(state.dataThermalComforts.AbsRadTemp * 0.01))
    state.dataThermalComforts.ConvHeatLoss = state.dataThermalComforts.CloBodyRat * state.dataThermalComforts.Hc * (state.dataThermalComforts.CloSurfTemp - AirTemp)
    state.dataThermalComforts.DryHeatLoss = state.dataThermalComforts.RadHeatLoss + state.dataThermalComforts.ConvHeatLoss
    state.dataThermalComforts.EvapHeatLossRegComf = 0.0
    if state.dataThermalComforts.IntHeatProd > 58.2:
        state.dataThermalComforts.EvapHeatLossRegComf = 0.42 * (state.dataThermalComforts.IntHeatProd - ActLevelConv)
    state.dataThermalComforts.EvapHeatLossDiff = 3.05 * 0.001 * (5733.0 - 6.99 * state.dataThermalComforts.IntHeatProd - state.dataThermalComforts.VapPress)
    state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.EvapHeatLossRegComf + state.dataThermalComforts.EvapHeatLossDiff
    state.dataThermalComforts.LatRespHeatLoss = 1.7 * 0.00001 * ActLevel * (5867.0 - state.dataThermalComforts.VapPress)
    state.dataThermalComforts.DryRespHeatLoss = 0.0014 * ActLevel * (34.0 - AirTemp)
    state.dataThermalComforts.RespHeatLoss = state.dataThermalComforts.LatRespHeatLoss + state.dataThermalComforts.DryRespHeatLoss
    state.dataThermalComforts.ThermSensTransCoef = 0.303 * exp(-0.036 * ActLevel) + 0.028
    PMV = state.dataThermalComforts.ThermSensTransCoef * (state.dataThermalComforts.IntHeatProd - state.dataThermalComforts.EvapHeatLoss - state.dataThermalComforts.RespHeatLoss - state.dataThermalComforts.DryHeatLoss)
    return PMV

def CalcFangerPPD(PMV: Float64) -> Float64:
    var PPD: Float64
    let expTest1 = -0.03353 * pow_4(PMV) - 0.2179 * pow_2(PMV)
    if expTest1 > EXP_LowerLimit:
        PPD = 100.0 - 95.0 * exp(expTest1)
    else:
        PPD = 100.0
    if PPD < 0.0:
        PPD = 0.0
    elif PPD > 100.0:
        PPD = 100.0
    return PPD

def CalcRelativeAirVelocity(AirVel: Float64, ActMet: Float64) -> Float64:
    if ActMet > 1:
        return AirVel + 0.3 * (ActMet - 1)
    return AirVel

def GetThermalComfortInputsASHRAE(inout state: EnergyPlusData):
    let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
    let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
    state.dataThermalComforts.ZoneNum = people.ZonePtr
    let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataThermalComforts.ZoneNum]
    state.dataThermalComforts.AirTemp = thisZoneHB.ZTAVComf
    if state.dataRoomAir.anyNonMixingRoomAirModel:
        if state.dataRoomAir.IsZoneDispVent3Node(state.dataThermalComforts.ZoneNum) or state.dataRoomAir.IsZoneUFAD(state.dataThermalComforts.ZoneNum):
            state.dataThermalComforts.AirTemp = state.dataRoomAir.TCMF[state.dataThermalComforts.ZoneNum]
    state.dataThermalComforts.RadTemp = CalcRadTemp(state, state.dataThermalComforts.PeopleNum)
    state.dataThermalComforts.RelHum = PsyRhFnTdbWPb(state, state.dataThermalComforts.AirTemp, thisZoneHB.airHumRatAvgComf, state.dataEnvrn.OutBaroPress)
    state.dataThermalComforts.ActLevel = people.activityLevelSched.getCurrentVal() / BodySurfAreaPierce
    state.dataThermalComforts.WorkEff = people.workEffSched.getCurrentVal() * state.dataThermalComforts.ActLevel
    var IntermediateClothing: Float64
    match people.clothingType:
        case ClothingType.InsulationSchedule:
            state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
            comfort.ClothingValue = state.dataThermalComforts.CloUnit
        case ClothingType.DynamicAshrae55:
            comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
            comfort.ClothingValue = state.dataThermalComforts.CloUnit
            DynamicClothingModel(state)
            state.dataThermalComforts.CloUnit = comfort.ClothingValue
        case ClothingType.CalculationSchedule:
            IntermediateClothing = people.clothingMethodSched.getCurrentVal()
            if IntermediateClothing == 1.0:
                state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
            elif IntermediateClothing == 2.0:
                comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
                DynamicClothingModel(state)
                state.dataThermalComforts.CloUnit = comfort.ClothingValue
            else:
                state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                ShowWarningError(state, "Scheduled clothing value will be used rather than clothing calculation method.")
        case _:
            ShowSevereError(state, "Incorrect Clothing Type")
    state.dataThermalComforts.AirVel = people.airVelocitySched.getCurrentVal()
    state.dataThermalComforts.ActMet = state.dataThermalComforts.ActLevel / ActLevelConv

def CalcStandardEffectiveTemp(state: EnergyPlusData, AirTemp: Float64, RadTemp: Float64, RelHum: Float64, AirVel: Float64, ActMet: Float64, CloUnit: Float64, WorkEff: Float64) -> Float64:
    let CloFac = 0.25
    let BodyWeight = 69.9
    let SweatContConst = 170.0
    let DriCoeffVasodilation = 120.0
    let DriCoeffVasoconstriction = 0.5
    let MaxSkinBloodFlow = 90.0
    let MinSkinBloodFlow = 0.5
    let RegSweatMax = 500.0
    let SkinTempSet = 33.7
    let CoreTempSet = 36.8
    let SkinBloodFlowSet = 6.3
    let SkinMassRatSet = 0.1
    if AirVel < 0.1:
        AirVel = 0.1
    state.dataThermalComforts.VapPress = RelHum * CalcSatVapPressFromTempTorr(AirTemp)
    let ActLevel = ActLevelConv * ActMet
    state.dataThermalComforts.IntHeatProd = ActLevel - WorkEff
    let PInAtmospheres = state.dataEnvrn.OutBaroPress / 101325.0
    let RClo = CloUnit * 0.155
    let TotCloFac = 1.0 + 0.15 * CloUnit
    let LewisRatio = 2.2 / PInAtmospheres
    var EvapEff: Float64
    state.dataThermalComforts.SkinTemp = SkinTempSet
    state.dataThermalComforts.CoreTemp = CoreTempSet
    var SkinBloodFlow = SkinBloodFlowSet
    var SkinMassRat = SkinMassRatSet
    if CloUnit <= 0:
        EvapEff = 0.38 * pow(AirVel, -0.29)
        state.dataThermalComforts.CloInsul = 1.0
    else:
        EvapEff = 0.59 * pow(AirVel, -0.08)
        state.dataThermalComforts.CloInsul = 0.45
    let CorrectedHC = 3.0 * pow(PInAtmospheres, 0.53)
    let ForcedHC = 8.600001 * pow((AirVel * PInAtmospheres), 0.53)
    state.dataThermalComforts.Hc = max(CorrectedHC, ForcedHC)
    state.dataThermalComforts.Hr = 4.7
    state.dataThermalComforts.EvapHeatLoss = 0.1 * ActMet
    let RAir = 1.0 / (TotCloFac * (state.dataThermalComforts.Hc + state.dataThermalComforts.Hr))
    state.dataThermalComforts.OpTemp = (state.dataThermalComforts.Hr * RadTemp + state.dataThermalComforts.Hc * AirTemp) / (state.dataThermalComforts.Hc + state.dataThermalComforts.Hr)
    let ActLevelStart = ActLevel
    let AvgBodyTempSet = SkinMassRatSet * SkinTempSet + (1.0 - SkinMassRatSet) * CoreTempSet
    for IterMin in range(60):
        state.dataThermalComforts.CloSurfTemp = (RAir * state.dataThermalComforts.SkinTemp + RClo * state.dataThermalComforts.OpTemp) / (RAir + RClo)
        var converged = False
        while not converged:
            state.dataThermalComforts.Hr = 4.0 * StefanBoltz * pow((state.dataThermalComforts.CloSurfTemp + RadTemp) / 2.0 + 273.15, 3) * 0.72
            RAir = 1.0 / (TotCloFac * (state.dataThermalComforts.Hc + state.dataThermalComforts.Hr))
            state.dataThermalComforts.OpTemp = (state.dataThermalComforts.Hr * RadTemp + state.dataThermalComforts.Hc * AirTemp) / (state.dataThermalComforts.Hc + state.dataThermalComforts.Hr)
            let CloSurfTempNew = (RAir * state.dataThermalComforts.SkinTemp + RClo * state.dataThermalComforts.OpTemp) / (RAir + RClo)
            if abs(CloSurfTempNew - state.dataThermalComforts.CloSurfTemp) <= 0.01:
                converged = True
            state.dataThermalComforts.CloSurfTemp = CloSurfTempNew
        state.dataThermalComforts.H = state.dataThermalComforts.Hr + state.dataThermalComforts.Hc
        state.dataThermalComforts.DryHeatLoss = (state.dataThermalComforts.SkinTemp - state.dataThermalComforts.OpTemp) / (RAir + RClo)
        state.dataThermalComforts.LatRespHeatLoss = 0.0023 * ActLevel * (44.0 - state.dataThermalComforts.VapPress)
        state.dataThermalComforts.DryRespHeatLoss = 0.0014 * ActLevel * (34.0 - AirTemp)
        state.dataThermalComforts.RespHeatLoss = state.dataThermalComforts.LatRespHeatLoss + state.dataThermalComforts.DryRespHeatLoss
        state.dataThermalComforts.HeatFlow = (state.dataThermalComforts.CoreTemp - state.dataThermalComforts.SkinTemp) * (5.28 + 1.163 * SkinBloodFlow)
        let CoreHeatStorage = ActLevel - state.dataThermalComforts.HeatFlow - state.dataThermalComforts.RespHeatLoss - WorkEff
        let SkinHeatStorage = state.dataThermalComforts.HeatFlow - state.dataThermalComforts.DryHeatLoss - state.dataThermalComforts.EvapHeatLoss
        state.dataThermalComforts.CoreThermCap = 0.97 * (1 - SkinMassRat) * BodyWeight
        state.dataThermalComforts.SkinThermCap = 0.97 * SkinMassRat * BodyWeight
        state.dataThermalComforts.CoreTempChange = (CoreHeatStorage * BodySurfAreaPierce / (state.dataThermalComforts.CoreThermCap * 60.0))
        state.dataThermalComforts.SkinTempChange = (SkinHeatStorage * BodySurfAreaPierce) / (state.dataThermalComforts.SkinThermCap * 60.0)
        state.dataThermalComforts.CoreTemp += state.dataThermalComforts.CoreTempChange
        state.dataThermalComforts.SkinTemp += state.dataThermalComforts.SkinTempChange
        state.dataThermalComforts.AvgBodyTemp = SkinMassRat * state.dataThermalComforts.SkinTemp + (1.0 - SkinMassRat) * state.dataThermalComforts.CoreTemp
        var SkinThermSigWarm: Float64
        var SkinThermSigCold: Float64
        let SkinSignal = state.dataThermalComforts.SkinTemp - SkinTempSet
        if SkinSignal > 0:
            SkinThermSigWarm = SkinSignal
            SkinThermSigCold = 0.0
        else:
            SkinThermSigCold = -SkinSignal
            SkinThermSigWarm = 0.0
        var CoreThermSigWarm: Float64
        var CoreThermSigCold: Float64
        let CoreSignal = state.dataThermalComforts.CoreTemp - CoreTempSet
        if CoreSignal > 0:
            CoreThermSigWarm = CoreSignal
            CoreThermSigCold = 0.0
        else:
            CoreThermSigCold = -CoreSignal
            CoreThermSigWarm = 0.0
        var BodyThermSigWarm: Float64
        let BodySignal = state.dataThermalComforts.AvgBodyTemp - AvgBodyTempSet
        if BodySignal > 0:
            BodyThermSigWarm = BodySignal
        else:
            BodyThermSigWarm = 0.0
        state.dataThermalComforts.VasodilationFac = DriCoeffVasodilation * CoreThermSigWarm
        state.dataThermalComforts.VasoconstrictFac = DriCoeffVasoconstriction * SkinThermSigCold
        SkinBloodFlow = (SkinBloodFlowSet + state.dataThermalComforts.VasodilationFac) / (1.0 + state.dataThermalComforts.VasoconstrictFac)
        if SkinBloodFlow < MinSkinBloodFlow:
            SkinBloodFlow = MinSkinBloodFlow
        if SkinBloodFlow > MaxSkinBloodFlow:
            SkinBloodFlow = MaxSkinBloodFlow
        SkinMassRat = 0.0417737 + 0.7451832 / (SkinBloodFlow + 0.585417)
        let RegSweat = SweatContConst * BodyThermSigWarm * exp(SkinThermSigWarm / 10.7)
        if RegSweat > RegSweatMax:
            RegSweat = RegSweatMax
        state.dataThermalComforts.EvapHeatLossRegSweat = 0.68 * RegSweat
        state.dataThermalComforts.ShivResponse = 19.4 * SkinThermSigCold * CoreThermSigCold
        ActLevel = ActLevelStart + state.dataThermalComforts.ShivResponse
        let AirEvapHeatResist = 1.0 / (LewisRatio * TotCloFac * state.dataThermalComforts.Hc)
        let CloEvapHeatResist = RClo / (LewisRatio * state.dataThermalComforts.CloInsul)
        let TotEvapHeatResist = AirEvapHeatResist + CloEvapHeatResist
        state.dataThermalComforts.SatSkinVapPress = CalcSatVapPressFromTempTorr(state.dataThermalComforts.SkinTemp)
        state.dataThermalComforts.EvapHeatLossMax = (state.dataThermalComforts.SatSkinVapPress - state.dataThermalComforts.VapPress) / TotEvapHeatResist
        state.dataThermalComforts.SkinWetSweat = state.dataThermalComforts.EvapHeatLossRegSweat / state.dataThermalComforts.EvapHeatLossMax
        state.dataThermalComforts.SkinWetDiff = (1.0 - state.dataThermalComforts.SkinWetSweat) * 0.06
        state.dataThermalComforts.EvapHeatLossDiff = state.dataThermalComforts.SkinWetDiff * state.dataThermalComforts.EvapHeatLossMax
        state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.EvapHeatLossRegSweat + state.dataThermalComforts.EvapHeatLossDiff
        state.dataThermalComforts.SkinWetTot = state.dataThermalComforts.EvapHeatLoss / state.dataThermalComforts.EvapHeatLossMax
        if state.dataThermalComforts.SkinWetTot >= EvapEff:
            state.dataThermalComforts.SkinWetTot = EvapEff
            state.dataThermalComforts.SkinWetSweat = EvapEff / 0.94
            state.dataThermalComforts.EvapHeatLossRegSweat = state.dataThermalComforts.SkinWetSweat * state.dataThermalComforts.EvapHeatLossMax
            state.dataThermalComforts.SkinWetDiff = (1.0 - state.dataThermalComforts.SkinWetSweat) * 0.06
            state.dataThermalComforts.EvapHeatLossDiff = state.dataThermalComforts.SkinWetDiff * state.dataThermalComforts.EvapHeatLossMax
            state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.EvapHeatLossRegSweat + state.dataThermalComforts.EvapHeatLossDiff
        if state.dataThermalComforts.EvapHeatLossMax < 0.0:
            state.dataThermalComforts.SkinWetDiff = 0.0
            state.dataThermalComforts.EvapHeatLossDiff = 0.0
            state.dataThermalComforts.EvapHeatLoss = 0.0
            state.dataThermalComforts.SkinWetTot = EvapEff
            state.dataThermalComforts.SkinWetSweat = EvapEff
            state.dataThermalComforts.EvapHeatLossRegSweat = 0.0
        state.dataThermalComforts.SkinVapPress = state.dataThermalComforts.SkinWetTot * state.dataThermalComforts.SatSkinVapPress + (1.0 - state.dataThermalComforts.SkinWetTot) * state.dataThermalComforts.VapPress
    state.dataThermalComforts.EvapHeatLossMax *= EvapEff
    let EffectSkinHeatLoss = state.dataThermalComforts.DryHeatLoss + state.dataThermalComforts.EvapHeatLoss
    state.dataThermalComforts.CloBodyRat = 1.0 + CloFac * CloUnit
    let EffectCloUnit = CloUnit - (state.dataThermalComforts.CloBodyRat - 1.0) / (0.155 * state.dataThermalComforts.CloBodyRat * state.dataThermalComforts.H)
    let EffectCloThermEff = 1.0 / (1.0 + 0.155 * state.dataThermalComforts.Hc * EffectCloUnit)
    state.dataThermalComforts.CloPermeatEff = 1.0 / (1.0 + (0.155 / state.dataThermalComforts.CloInsul) * state.dataThermalComforts.Hc * EffectCloUnit)
    var ET = state.dataThermalComforts.SkinTemp - EffectSkinHeatLoss / (state.dataThermalComforts.H * EffectCloThermEff)
    var EnergyBalErrET: Float64
    while True:
        let StdVapPressET = CalcSatVapPressFromTempTorr(ET)
        EnergyBalErrET = EffectSkinHeatLoss - state.dataThermalComforts.H * EffectCloThermEff * (state.dataThermalComforts.SkinTemp - ET) - state.dataThermalComforts.SkinWetTot * LewisRatio * state.dataThermalComforts.Hc * state.dataThermalComforts.CloPermeatEff * (state.dataThermalComforts.SatSkinVapPress - StdVapPressET / 2.0)
        if EnergyBalErrET >= 0.0:
            break
        ET += 0.1
    state.dataThermalComforts.EffTemp = ET
    let StdHr = state.dataThermalComforts.Hr
    var StdHc: Float64
    if ActMet <= 0.85:
        StdHc = 3.0
    else:
        StdHc = 5.66 * pow(ActMet - 0.85, 0.39)
    if StdHc <= 3.0:
        StdHc = 3.0
    let StdH = StdHc + StdHr
    let StdCloUnit = 1.52 / (ActMet - WorkEff / ActLevelConv + 0.6944) - 0.1835
    let StdRClo = 0.155 * StdCloUnit
    let StdCloBodyRat = 1.0 + CloFac * StdCloUnit
    let StdEffectCloThermEff = 1.0 / (1.0 + 0.155 * StdCloBodyRat * StdH * StdCloUnit)
    let StdCloInsul = state.dataThermalComforts.CloInsul * StdHc / StdH * (1 - StdEffectCloThermEff) / (StdHc / StdH - state.dataThermalComforts.CloInsul * StdEffectCloThermEff)
    let StdREvap = 1.0 / (LewisRatio * StdCloBodyRat * StdHc)
    let StdREvapClo = StdRClo / (LewisRatio * StdCloInsul)
    let StdHEvap = 1.0 / (StdREvap + StdREvapClo)
    let StdRAir = 1.0 / (StdCloBodyRat * StdH)
    let StdHDry = 1.0 / (StdRAir + StdRClo)
    let StdEffectSkinHeatLoss = state.dataThermalComforts.DryHeatLoss + state.dataThermalComforts.EvapHeatLoss
    var OldSET = round((state.dataThermalComforts.SkinTemp - StdEffectSkinHeatLoss / StdHDry) * 100) / 100
    let delta = 0.0001
    var err = 100.0
    while abs(err) > 0.01:
        let StdVapPressSET_1 = CalcSatVapPressFromTempTorr(OldSET)
        let EnergyBalErrSET_1 = StdEffectSkinHeatLoss - StdHDry * (state.dataThermalComforts.SkinTemp - OldSET) - state.dataThermalComforts.SkinWetTot * StdHEvap * (state.dataThermalComforts.SatSkinVapPress - StdVapPressSET_1 / 2.0)
        let StdVapPressSET_2 = CalcSatVapPressFromTempTorr(OldSET + delta)
        let EnergyBalErrSET_2 = StdEffectSkinHeatLoss - StdHDry * (state.dataThermalComforts.SkinTemp - (OldSET + delta)) - state.dataThermalComforts.SkinWetTot * StdHEvap * (state.dataThermalComforts.SatSkinVapPress - StdVapPressSET_2 / 2.0)
        let NewSET = OldSET - delta * EnergyBalErrSET_1 / (EnergyBalErrSET_2 - EnergyBalErrSET_1)
        err = NewSET - OldSET
        OldSET = NewSET
    let SET = OldSET
    state.dataThermalComforts.DryHeatLossET = StdH * StdEffectCloThermEff * (state.dataThermalComforts.SkinTemp - ET)
    state.dataThermalComforts.DryHeatLossSET = StdH * StdEffectCloThermEff * (state.dataThermalComforts.SkinTemp - SET)
    return SET

def CalcThermalComfortPierceASHRAE(inout state: EnergyPlusData):
    for state.dataThermalComforts.PeopleNum in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
        if not people.Pierce:
            continue
        let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
        GetThermalComfortInputsASHRAE(state)
        let SET = CalcStandardEffectiveTemp(state,
                                            state.dataThermalComforts.AirTemp,
                                            state.dataThermalComforts.RadTemp,
                                            state.dataThermalComforts.RelHum,
                                            state.dataThermalComforts.AirVel,
                                            state.dataThermalComforts.ActMet,
                                            state.dataThermalComforts.CloUnit,
                                            state.dataThermalComforts.WorkEff)
        state.dataThermalComforts.ThermSensTransCoef = 0.303 * exp(-0.036 * state.dataThermalComforts.ActLevel) + 0.028
        state.dataThermalComforts.EvapHeatLossRegComf = (state.dataThermalComforts.IntHeatProd - ActLevelConv) * 0.42
        comfort.PiercePMVET = state.dataThermalComforts.ThermSensTransCoef * (state.dataThermalComforts.IntHeatProd - state.dataThermalComforts.RespHeatLoss - state.dataThermalComforts.DryHeatLossET - state.dataThermalComforts.EvapHeatLossDiff - state.dataThermalComforts.EvapHeatLossRegComf)
        comfort.PiercePMVSET = state.dataThermalComforts.ThermSensTransCoef * (state.dataThermalComforts.IntHeatProd - state.dataThermalComforts.RespHeatLoss - state.dataThermalComforts.DryHeatLossSET - state.dataThermalComforts.EvapHeatLossDiff - state.dataThermalComforts.EvapHeatLossRegComf)
        comfort.PierceDISC = 5.0 * (state.dataThermalComforts.EvapHeatLossRegSweat - state.dataThermalComforts.EvapHeatLossRegComf) / (state.dataThermalComforts.EvapHeatLossMax - state.dataThermalComforts.EvapHeatLossRegComf - state.dataThermalComforts.EvapHeatLossDiff)
        let AvgBodyTempLow = (0.185 / ActLevelConv) * (state.dataThermalComforts.ActLevel - state.dataThermalComforts.WorkEff) + 36.313
        let AvgBodyTempHigh = (0.359 / ActLevelConv) * (state.dataThermalComforts.ActLevel - state.dataThermalComforts.WorkEff) + 36.664
        if state.dataThermalComforts.AvgBodyTemp > AvgBodyTempLow:
            comfort.PierceTSENS = 4.7 * (state.dataThermalComforts.AvgBodyTemp - AvgBodyTempLow) / (AvgBodyTempHigh - AvgBodyTempLow)
        else:
            comfort.PierceTSENS = 0.68175 * (state.dataThermalComforts.AvgBodyTemp - AvgBodyTempLow)
            comfort.PierceDISC = comfort.PierceTSENS
        comfort.ThermalComfortMRT = state.dataThermalComforts.RadTemp
        comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
        comfort.ClothingValue = state.dataThermalComforts.CloUnit
        comfort.PierceSET = SET

def CalcThermalComfortCoolingEffectASH(inout state: EnergyPlusData):
    for state.dataThermalComforts.PeopleNum in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
        if not people.CoolingEffectASH55:
            continue
        let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
        GetThermalComfortInputsASHRAE(state)
        var CoolingEffect: Float64 = 0
        var CoolingEffectAdjustedPMV: Float64
        CalcCoolingEffectAdjustedPMV(state, CoolingEffect, CoolingEffectAdjustedPMV)
        comfort.CoolingEffectASH55 = CoolingEffect
        comfort.CoolingEffectAdjustedPMVASH55 = CoolingEffectAdjustedPMV
        comfort.CoolingEffectAdjustedPPDASH55 = CalcFangerPPD(CoolingEffectAdjustedPMV)

def CalcCoolingEffectAdjustedPMV(inout state: EnergyPlusData, inout CoolingEffect: Float64, inout CoolingEffectAdjustedPMV: Float64):
    let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
    let RelAirVel = CalcRelativeAirVelocity(state.dataThermalComforts.AirVel, state.dataThermalComforts.ActMet)
    let SET = CalcStandardEffectiveTemp(state,
                                        state.dataThermalComforts.AirTemp,
                                        state.dataThermalComforts.RadTemp,
                                        state.dataThermalComforts.RelHum,
                                        RelAirVel,
                                        state.dataThermalComforts.ActMet,
                                        state.dataThermalComforts.CloUnit,
                                        state.dataThermalComforts.WorkEff)
    let ASHRAE55PMV = CalcFangerPMV(state,
                                    state.dataThermalComforts.AirTemp,
                                    state.dataThermalComforts.RadTemp,
                                    state.dataThermalComforts.RelHum,
                                    RelAirVel,
                                    state.dataThermalComforts.ActLevel,
                                    state.dataThermalComforts.CloUnit,
                                    state.dataThermalComforts.WorkEff)
    let StillAirVel = 0.1
    # bisect root finding
    def ce_root_function(x: Float64) -> Float64:
        return CalcStandardEffectiveTemp(state,
                                         state.dataThermalComforts.AirTemp - x,
                                         state.dataThermalComforts.RadTemp - x,
                                         state.dataThermalComforts.RelHum,
                                         StillAirVel,
                                         state.dataThermalComforts.ActMet,
                                         state.dataThermalComforts.CloUnit,
                                         state.dataThermalComforts.WorkEff) - SET
    def ce_root_termination(min: Float64, max: Float64) -> Bool:
        return abs(max - min) <= 0.01
    var lowerBound = 0.0
    var upperBound = 50.0
    try:
        let (resultLow, resultHigh) = bisect(ce_root_function, lowerBound, upperBound, ce_root_termination)
        CoolingEffect = (resultLow + resultHigh) / 2.0
    except:
        ShowRecurringWarningErrorAtEnd(state,
                                       "The cooling effect could not be solved for People=\"" + people.Name + "\"" +
                                       "As a result, no cooling effect will be applied to adjust the PMV and PPD results.",
                                       state.dataThermalComforts.CoolingEffectWarningInd)
        CoolingEffect = 0.0
    if CoolingEffect > 0.0:
        CoolingEffectAdjustedPMV = CalcFangerPMV(state,
                                                 state.dataThermalComforts.AirTemp - CoolingEffect,
                                                 state.dataThermalComforts.RadTemp - CoolingEffect,
                                                 state.dataThermalComforts.RelHum,
                                                 StillAirVel,
                                                 state.dataThermalComforts.ActLevel,
                                                 state.dataThermalComforts.CloUnit,
                                                 state.dataThermalComforts.WorkEff)
    else:
        CoolingEffectAdjustedPMV = ASHRAE55PMV

def bisect(f: fn(Float64) -> Float64, low: Float64, high: Float64, term: fn(Float64, Float64) -> Bool) -> (Float64, Float64):
    var a = low
    var b = high
    while not term(a, b):
        let mid = (a + b) / 2.0
        if f(mid) == 0.0:
            return (mid, mid)
        if f(a) * f(mid) < 0:
            b = mid
        else:
            a = mid
    return (a, b)

def CalcThermalComfortAnkleDraftASH(inout state: EnergyPlusData):
    for state.dataThermalComforts.PeopleNum in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
        if not people.AnkleDraftASH55:
            continue
        let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
        GetThermalComfortInputsASHRAE(state)
        let RelAirVel = CalcRelativeAirVelocity(state.dataThermalComforts.AirVel, state.dataThermalComforts.ActMet)
        var PPD_AD = -1.0
        if state.dataThermalComforts.ActMet < 1.3 and state.dataThermalComforts.CloUnit < 0.7 and RelAirVel < 0.2:
            let AnkleAirVel = people.ankleAirVelocitySched.getCurrentVal()
            let PMV = CalcFangerPMV(state,
                                    state.dataThermalComforts.AirTemp,
                                    state.dataThermalComforts.RadTemp,
                                    state.dataThermalComforts.RelHum,
                                    RelAirVel,
                                    state.dataThermalComforts.ActLevel,
                                    state.dataThermalComforts.CloUnit,
                                    state.dataThermalComforts.WorkEff)
            PPD_AD = (exp(-2.58 + 3.05 * AnkleAirVel - 1.06 * PMV) / (1 + exp(-2.58 + 3.05 * AnkleAirVel - 1.06 * PMV))) * 100.0
        else:
            if state.dataGlobal.DisplayExtraWarnings:
                if RelAirVel >= 0.2:
                    ShowRecurringWarningErrorAtEnd(state,
                                                   "Relative air velocity is above 0.2 m/s in Ankle draft PPD calculations. PPD at ankle draft will be set to -1.0.",
                                                   state.dataThermalComforts.AnkleDraftAirVelWarningInd,
                                                   RelAirVel,
                                                   RelAirVel,
                                                   _,
                                                   "[m/s]",
                                                   "[m/s]")
                if state.dataThermalComforts.ActMet >= 1.3:
                    ShowRecurringWarningErrorAtEnd(state,
                                                   "Metabolic rate is above 1.3 met in Ankle draft PPD calculations. PPD at ankle draft will be set to -1.0.",
                                                   state.dataThermalComforts.AnkleDraftActMetWarningInd,
                                                   state.dataThermalComforts.ActMet,
                                                   state.dataThermalComforts.ActMet,
                                                   _,
                                                   "[m/s]",
                                                   "[m/s]")
                if state.dataThermalComforts.CloUnit >= 0.7:
                    ShowRecurringWarningErrorAtEnd(state,
                                                   "Clothing unit is above 0.7 in Ankle draft PPD calculations. PPD at ankle draft will be set to -1.0.",
                                                   state.dataThermalComforts.AnkleDraftCloUnitWarningInd,
                                                   state.dataThermalComforts.CloUnit,
                                                   state.dataThermalComforts.CloUnit,
                                                   _,
                                                   "[m/s]",
                                                   "[m/s]")
        comfort.AnkleDraftPPDASH55 = PPD_AD

def CalcThermalComfortKSU(inout state: EnergyPlusData):
    let CloEmiss = 0.8
    var BodyWt: Float64
    var DayNum: Float64
    var NumDay: Int
    var EmissAvg: Float64
    var IncreDayNum: Int
    var IntHeatProdMet: Float64
    var IntHeatProdMetMax: Float64
    var LastDayNum: Int
    var SkinWetFac: Float64
    var SkinWetNeut: Float64
    var StartDayNum: Int
    var SweatSuppFac: Float64
    var TempDiffer: Float64
    var TempIndiceNum: Int
    var ThermCndctMin: Float64
    var ThermCndctNeut: Float64
    var TimeExpos: Float64
    var TimeInterval: Float64
    var TSVMax: Float64
    var IntermediateClothing: Float64
    TempIndiceNum = 2
    TimeInterval = 1.0
    TSVMax = 4.0
    StartDayNum = 1
    LastDayNum = 1
    IncreDayNum = 1
    TimeExpos = 1.0
    TempDiffer = 0.5
    for state.dataThermalComforts.PeopleNum in range(state.dataHeatBal.TotPeople):
        let people = state.dataHeatBal.People[state.dataThermalComforts.PeopleNum]
        if not people.KSU:
            continue
        let comfort = state.dataThermalComforts.ThermalComfortData[state.dataThermalComforts.PeopleNum]
        state.dataThermalComforts.ZoneNum = people.ZonePtr
        let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataThermalComforts.ZoneNum]
        state.dataThermalComforts.AirTemp = thisZoneHB.ZTAVComf
        if state.dataRoomAir.anyNonMixingRoomAirModel:
            if state.dataRoomAir.IsZoneDispVent3Node(state.dataThermalComforts.ZoneNum) or state.dataRoomAir.IsZoneUFAD(state.dataThermalComforts.ZoneNum):
                state.dataThermalComforts.AirTemp = state.dataRoomAir.TCMF[state.dataThermalComforts.ZoneNum]
        state.dataThermalComforts.RadTemp = CalcRadTemp(state, state.dataThermalComforts.PeopleNum)
        state.dataThermalComforts.RelHum = PsyRhFnTdbWPb(state, state.dataThermalComforts.AirTemp, thisZoneHB.airHumRatAvgComf, state.dataEnvrn.OutBaroPress)
        state.dataThermalComforts.ActLevel = people.activityLevelSched.getCurrentVal() / BodySurfArea
        state.dataThermalComforts.WorkEff = people.workEffSched.getCurrentVal() * state.dataThermalComforts.ActLevel
        match people.clothingType:
            case ClothingType.InsulationSchedule:
                state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
            case ClothingType.DynamicAshrae55:
                comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                comfort.ClothingValue = state.dataThermalComforts.CloUnit
                DynamicClothingModel(state)
                state.dataThermalComforts.CloUnit = comfort.ClothingValue
            case ClothingType.CalculationSchedule:
                IntermediateClothing = people.clothingMethodSched.getCurrentVal()
                if IntermediateClothing == 1.0:
                    state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                    comfort.ClothingValue = state.dataThermalComforts.CloUnit
                elif IntermediateClothing == 2.0:
                    comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                    comfort.ClothingValue = state.dataThermalComforts.CloUnit
                    DynamicClothingModel(state)
                    state.dataThermalComforts.CloUnit = comfort.ClothingValue
                else:
                    state.dataThermalComforts.CloUnit = people.clothingSched.getCurrentVal()
                    ShowWarningError(state, "PEOPLE=\"{}\", Scheduled clothing value will be used rather than clothing calculation method.".format(people.Name))
            case _:
                ShowSevereError(state, "PEOPLE=\"{}\", Incorrect Clothing Type".format(people.Name))
        state.dataThermalComforts.AirVel = people.airVelocitySched.getCurrentVal()
        state.dataThermalComforts.IntHeatProd = state.dataThermalComforts.ActLevel - state.dataThermalComforts.WorkEff
        BodyWt = 70.0
        state.dataThermalComforts.CoreTemp = 37.0
        state.dataThermalComforts.SkinTemp = 31.0
        state.dataThermalComforts.CoreThermCap = 0.9 * BodyWt * 0.97 / BodySurfArea
        state.dataThermalComforts.SkinThermCap = 0.1 * BodyWt * 0.97 / BodySurfArea
        if state.dataThermalComforts.AirVel < 0.137:
            state.dataThermalComforts.AirVel = 0.137
        state.dataThermalComforts.Hc = 8.3 * sqrt(state.dataThermalComforts.AirVel)
        EmissAvg = RadSurfEff * CloEmiss + (1.0 - RadSurfEff) * 1.0
        state.dataThermalComforts.Hr = EmissAvg * (3.87 + 0.031 * state.dataThermalComforts.RadTemp)
        state.dataThermalComforts.H = state.dataThermalComforts.Hr + state.dataThermalComforts.Hc
        state.dataThermalComforts.OpTemp = (state.dataThermalComforts.Hc * state.dataThermalComforts.AirTemp + state.dataThermalComforts.Hr * state.dataThermalComforts.RadTemp) / state.dataThermalComforts.H
        state.dataThermalComforts.VapPress = CalcSatVapPressFromTemp(state.dataThermalComforts.AirTemp)
        state.dataThermalComforts.VapPress *= state.dataThermalComforts.RelHum
        state.dataThermalComforts.CloBodyRat = 1.0 + 0.2 * state.dataThermalComforts.CloUnit
        state.dataThermalComforts.CloThermEff = 1.0 / (1.0 + 0.155 * state.dataThermalComforts.H * state.dataThermalComforts.CloBodyRat * state.dataThermalComforts.CloUnit)
        state.dataThermalComforts.CloPermeatEff = 1.0 / (1.0 + 0.143 * state.dataThermalComforts.Hc * state.dataThermalComforts.CloUnit)
        IntHeatProdMet = state.dataThermalComforts.IntHeatProd / ActLevelConv
        IntHeatProdMetMax = max(1.0, IntHeatProdMet)
        ThermCndctNeut = 12.05 * exp(0.2266 * (IntHeatProdMetMax - 1.0))
        SkinWetNeut = 0.02 + 0.4 * (1.0 - exp(-0.6 * (IntHeatProdMetMax - 1.0)))
        ThermCndctMin = (ThermCndctNeut - 5.3) * 0.26074074 + 5.3
        let ThemCndct_75_fac = 1.0 / (75.0 - ThermCndctNeut)
        let ThemCndct_fac = 1.0 / (ThermCndctNeut - ThermCndctMin)
        for NumDay in range(StartDayNum, LastDayNum + 1, IncreDayNum):
            DayNum = Float64(NumDay)
            state.dataThermalComforts.Time = 0.0
            state.dataThermalComforts.TimeChange = 0.01
            SweatSuppFac = 1.0
            state.dataThermalComforts.Temp[0] = state.dataThermalComforts.CoreTemp
            state.dataThermalComforts.Temp[1] = state.dataThermalComforts.SkinTemp
            state.dataThermalComforts.Coeff[0] = 0.0
            state.dataThermalComforts.Coeff[1] = 0.0
            state.dataThermalComforts.AcclPattern = 1.0 - exp(-0.12 * (DayNum - 1.0))
            state.dataThermalComforts.CoreTempNeut = 36.9 - 0.6 * state.dataThermalComforts.AcclPattern
            state.dataThermalComforts.SkinTempNeut = 33.8 - 1.6 * state.dataThermalComforts.AcclPattern
            state.dataThermalComforts.ActLevel -= 0.07 * state.dataThermalComforts.ActLevel * state.dataThermalComforts.AcclPattern
            let SkinTempNeut_fac = 1.0 / (1.0 - SkinWetNeut)
            DERIV(state, TempIndiceNum, state.dataThermalComforts.Temp, state.dataThermalComforts.TempChange)
            while True:
                SkinWetFac = (state.dataThermalComforts.SkinWetSweat - SkinWetNeut) * SkinTempNeut_fac
                state.dataThermalComforts.VasodilationFac = (state.dataThermalComforts.ThermCndct - ThermCndctNeut) * ThemCndct_75_fac
                state.dataThermalComforts.VasoconstrictFac = (ThermCndctNeut - state.dataThermalComforts.ThermCndct) * ThemCndct_fac
                if state.dataThermalComforts.VasodilationFac < 0:
                    comfort.KsuTSV = -1.46153 * state.dataThermalComforts.VasoconstrictFac + 3.74721 * pow_2(state.dataThermalComforts.VasoconstrictFac) - 6.168856 * pow_3(state.dataThermalComforts.VasoconstrictFac)
                else:
                    comfort.KsuTSV = (5.0 - 6.56 * (state.dataThermalComforts.RelHum - 0.50)) * SkinWetFac
                    if comfort.KsuTSV > TSVMax:
                        comfort.KsuTSV = TSVMax
                comfort.ThermalComfortMRT = state.dataThermalComforts.RadTemp
                comfort.ThermalComfortOpTemp = (state.dataThermalComforts.RadTemp + state.dataThermalComforts.AirTemp) / 2.0
                state.dataThermalComforts.CoreTemp = state.dataThermalComforts.Temp[0]
                state.dataThermalComforts.SkinTemp = state.dataThermalComforts.Temp[1]
                state.dataThermalComforts.EvapHeatLossSweatPrev = state.dataThermalComforts.EvapHeatLossSweat
                RKG(state, TempIndiceNum, state.dataThermalComforts.TimeChange, state.dataThermalComforts.Time, state.dataThermalComforts.Temp, state.dataThermalComforts.TempChange, state.dataThermalComforts.Coeff)
                if state.dataThermalComforts.Time > TimeExpos:
                    break

def DERIV(state: EnergyPlusData, TempIndiceNum: Int, Temp: List[Float64], inout TempChange: List[Float64]):
    # TempIndiceNum and Temp are unused
    var ActLevelTot: Float64
    var CoreSignalShiv: Float64
    var CoreSignalShivMax: Float64
    var CoreSignalSkinSens: Float64
    var CoreSignalSweatMax: Float64
    var CoreSignalSweatWarm: Float64
    var CoreTempSweat: Float64
    var CoreSignalWarm: Float64
    var CoreSignalWarmMax: Float64
    var EvapHeatLossDrySweat: Float64
    var Err: Float64
    var ErrPrev: Float64
    var EvapHeatLossSweatEst: Float64
    var EvapHeatLossSweatEstNew: Float64
    var IntHeatProdTot: Float64
    var SkinCndctMax: Float64
    var SkinSignalCold: Float64
    var SkinSignalColdMax: Float64
    var SkinSignalSweatCold: Float64
    var SkinSignalSweatColdMax: Float64
    var SkinCndctDilation: Float64
    var SkinCndctConstriction: Float64
    var SkinSignalShiv: Float64
    var SkinSignalShivMax: Float64
    var SkinSignalSweatMax: Float64
    var SkinSignalSweatWarm: Float64
    var SkinSignalWarm: Float64
    var SkinSignalWarmMax: Float64
    var SkinTempSweat: Float64
    var SkinWetSignal: Float64
    var SweatCtrlFac: Float64
    var SweatSuppFac: Float64
    var WeighFac: Float64
    CoreSignalWarm = state.dataThermalComforts.CoreTemp - 36.98
    SkinSignalWarm = state.dataThermalComforts.SkinTemp - 33.8
    SkinSignalCold = 32.1 - state.dataThermalComforts.SkinTemp
    CoreSignalSkinSens = state.dataThermalComforts.CoreTemp - 35.15
    CoreSignalWarmMax = max(0.0, CoreSignalWarm)
    SkinSignalWarmMax = max(0.0, SkinSignalWarm)
    SkinSignalColdMax = max(0.0, SkinSignalCold)
    CoreTempSweat = state.dataThermalComforts.CoreTemp
    if CoreTempSweat > 38.29:
        CoreTempSweat = 38.29
    CoreSignalSweatWarm = CoreTempSweat - state.dataThermalComforts.CoreTempNeut
    SkinTempSweat = state.dataThermalComforts.SkinTemp
    if SkinTempSweat > 36.1:
        SkinTempSweat = 36.1
    SkinSignalSweatWarm = SkinTempSweat - state.dataThermalComforts.SkinTempNeut
    CoreSignalSweatMax = max(0.0, CoreSignalSweatWarm)
    SkinSignalSweatMax = max(0.0, SkinSignalSweatWarm)
    SkinSignalSweatCold = 33.37 - state.dataThermalComforts.SkinTemp
    if state.dataThermalComforts.SkinTempNeut < 33.37:
        SkinSignalSweatCold = state.dataThermalComforts.SkinTempNeut - state.dataThermalComforts.SkinTemp
    SkinSignalSweatColdMax = max(0.0, SkinSignalSweatCold)
    CoreSignalShiv = 36.9 - state.dataThermalComforts.CoreTemp
    SkinSignalShiv = 32.5 - state.dataThermalComforts.SkinTemp
    CoreSignalShivMax = max(0.0, CoreSignalShiv)
    SkinSignalShivMax = max(0.0, SkinSignalShiv)
    state.dataThermalComforts.ShivResponse = 20.0 * CoreSignalShivMax * SkinSignalShivMax + 5.0 * SkinSignalShivMax
    if state.dataThermalComforts.CoreTemp >= 37.1:
        state.dataThermalComforts.ShivResponse = 0.0
    WeighFac = 260.0 + 70.0 * state.dataThermalComforts.AcclPattern
    SweatCtrlFac = 1.0 + 0.05 * pow(SkinSignalSweatColdMax, 2.4)
    EvapHeatLossDrySweat = ((WeighFac * CoreSignalSweatMax + 0.1 * WeighFac * SkinSignalSweatMax) * exp(SkinSignalSweatMax / 8.5)) / SweatCtrlFac
    state.dataThermalComforts.SkinVapPress = CalcSatVapPressFromTemp(state.dataThermalComforts.SkinTemp)
    state.dataThermalComforts.EvapHeatLossMax = 2.2 * state.dataThermalComforts.Hc * (state.dataThermalComforts.SkinVapPress - state.dataThermalComforts.VapPress) * state.dataThermalComforts.CloPermeatEff
    if state.dataThermalComforts.EvapHeatLossMax > 0.0:
        state.dataThermalComforts.SkinWetSweat = EvapHeatLossDrySweat / state.dataThermalComforts.EvapHeatLossMax
        state.dataThermalComforts.EvapHeatLossDiff = 0.408 * (state.dataThermalComforts.SkinVapPress - state.dataThermalComforts.VapPress)
        state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.SkinWetSweat * state.dataThermalComforts.EvapHeatLossMax + (1.0 - state.dataThermalComforts.SkinWetSweat) * state.dataThermalComforts.EvapHeatLossDiff
        state.dataThermalComforts.SkinWetTot = state.dataThermalComforts.EvapHeatLoss / state.dataThermalComforts.EvapHeatLossMax
        if state.dataThermalComforts.Time == 0.0:
            state.dataThermalComforts.EvapHeatLossSweat = EvapHeatLossDrySweat
            state.dataThermalComforts.EvapHeatLossSweatPrev = EvapHeatLossDrySweat
        if state.dataThermalComforts.SkinWetTot > 0.4:
            state.dataThermalComforts.IterNum = 0
            if state.dataThermalComforts.SkinWetSweat > 1.0:
                state.dataThermalComforts.SkinWetSweat = 1.0
            while True:
                EvapHeatLossSweatEst = state.dataThermalComforts.EvapHeatLossSweatPrev
                state.dataThermalComforts.SkinWetSweat = EvapHeatLossSweatEst / state.dataThermalComforts.EvapHeatLossMax
                if state.dataThermalComforts.SkinWetSweat > 1.0:
                    state.dataThermalComforts.SkinWetSweat = 1.0
                state.dataThermalComforts.EvapHeatLossDiff = 0.408 * (state.dataThermalComforts.SkinVapPress - state.dataThermalComforts.VapPress)
                state.dataThermalComforts.EvapHeatLoss = (1.0 - state.dataThermalComforts.SkinWetTot) * state.dataThermalComforts.EvapHeatLossDiff + state.dataThermalComforts.EvapHeatLossSweat
                state.dataThermalComforts.SkinWetTot = state.dataThermalComforts.EvapHeatLoss / state.dataThermalComforts.EvapHeatLossMax
                if state.dataThermalComforts.SkinWetTot > 1.0:
                    state.dataThermalComforts.SkinWetTot = 1.0
                SkinWetSignal = max(0.0, state.dataThermalComforts.SkinWetTot - 0.4)
                SweatSuppFac = 0.5 + 0.5 * exp(-5.6 * SkinWetSignal)
                EvapHeatLossSweatEstNew = SweatSuppFac * EvapHeatLossDrySweat
                if state.dataThermalComforts.IterNum == 0:
                    state.dataThermalComforts.EvapHeatLossSweat = EvapHeatLossSweatEstNew
                Err = EvapHeatLossSweatEst - EvapHeatLossSweatEstNew
                if state.dataThermalComforts.IterNum != 0:
                    if (ErrPrev * Err) < 0.0:
                        state.dataThermalComforts.EvapHeatLossSweat = (EvapHeatLossSweatEst + EvapHeatLossSweatEstNew) / 2.0
                    if (ErrPrev * Err) >= 0.0:
                        state.dataThermalComforts.EvapHeatLossSweat = EvapHeatLossSweatEstNew
                if (abs(Err) <= 0.5) or (state.dataThermalComforts.IterNum >= 10):
                    break
                state.dataThermalComforts.IterNum += 1
                state.dataThermalComforts.EvapHeatLossSweatPrev = state.dataThermalComforts.EvapHeatLossSweat
                ErrPrev = Err
        else:
            state.dataThermalComforts.EvapHeatLossSweat = EvapHeatLossDrySweat
    else:
        state.dataThermalComforts.SkinWetSweat = 1.0
        state.dataThermalComforts.SkinWetTot = 1.0
        state.dataThermalComforts.EvapHeatLossSweat = 0.5 * EvapHeatLossDrySweat
        state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.EvapHeatLossSweat
    SkinCndctDilation = 42.45 * CoreSignalWarmMax + 8.15 * pow(CoreSignalSkinSens, 0.8) * SkinSignalWarmMax
    SkinCndctConstriction = 1.0 + 0.4 * SkinSignalColdMax
    state.dataThermalComforts.ThermCndct = 5.3 + (6.75 + SkinCndctDilation) / SkinCndctConstriction
    SkinCndctMax = 75.0 + 10.0 * state.dataThermalComforts.AcclPattern
    if state.dataThermalComforts.ThermCndct > SkinCndctMax:
        state.dataThermalComforts.ThermCndct = SkinCndctMax
    ActLevelTot = state.dataThermalComforts.ActLevel + state.dataThermalComforts.ShivResponse
    IntHeatProdTot = ActLevelTot - state.dataThermalComforts.WorkEff
    state.dataThermalComforts.LatRespHeatLoss = 0.0023 * ActLevelTot * (44.0 - state.dataThermalComforts.VapPress)
    state.dataThermalComforts.DryRespHeatLoss = 0.0014 * ActLevelTot * (34.0 - state.dataThermalComforts.AirTemp)
    state.dataThermalComforts.RespHeatLoss = state.dataThermalComforts.LatRespHeatLoss + state.dataThermalComforts.DryRespHeatLoss
    state.dataThermalComforts.HeatFlow = state.dataThermalComforts.ThermCndct * (state.dataThermalComforts.CoreTemp - state.dataThermalComforts.SkinTemp)
    TempChange[0] = (IntHeatProdTot - state.dataThermalComforts.RespHeatLoss - state.dataThermalComforts.HeatFlow) / state.dataThermalComforts.CoreThermCap
    if state.dataThermalComforts.EvapHeatLoss > state.dataThermalComforts.EvapHeatLossMax:
        state.dataThermalComforts.EvapHeatLoss = state.dataThermalComforts.EvapHeatLossMax
    state.dataThermalComforts.DryHeatLoss = state.dataThermalComforts.H * state.dataThermalComforts.CloBodyRat * state.dataThermalComforts.CloThermEff * (state.dataThermalComforts.SkinTemp - state.dataThermalComforts.OpTemp)
    TempChange[1] = (state.dataThermalComforts.HeatFlow - state.dataThermalComforts.EvapHeatLoss - state.dataThermalComforts.DryHeatLoss) / state.dataThermalComforts.SkinThermCap

def RKG(state: EnergyPlusData, NEQ: Int, H: Float64, inout X: Float64, inout Y: List[Float64], inout DY: List[Float64], inout C: List[Float64]):
    # EP_SIZE_CHECK(Y, NEQ); EP_SIZE_CHECK(DY, NEQ); EP_SIZE_CHECK(C, NEQ);
    var I: Int
    var J: Int
    var B: Float64
    var H2: Float64
    let A: List[Float64] = List[Float64]([0.29289321881345, 1.70710678118654])
    H2 = 0.5 * H
    DERIV(state, NEQ, Y, DY)
    for I in range(NEQ):
        B = H2 * DY[I] - C[I]
        Y[I] += B
        C[I] += 3.0 * B - H2 * DY[I]
    X += H2
    for J in range(2):
        DERIV(state, NEQ, Y, DY)
        for I in range(NEQ):
            B = A[J] * (H * DY[I] - C[I])
            Y[I] += B
            C[I] += 3.0 * B - A[J] * H * DY[I]
    X += H2
    DERIV(state, NEQ, Y, DY)
    for I in range(NEQ):
        B = (H * DY[I] - 2.0 * C[I]) / 6.0
        Y[I] += B
        C[I] += 3.0 * B - H2 * DY[I]
    DERIV(state, NEQ, Y, DY)

def GetAngleFactorList(inout state: EnergyPlusData):
    let routineName = "GetAngleFactorList: "
    let AngleFacLimit = 0.01
    var ErrorsFound = False
    var IOStatus: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var cCurrentModuleObject = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "ComfortViewFactorAngles"
    let NumOfAngleFactorLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataThermalComforts.AngleFactorList = List[AngleFactorData](NumOfAngleFactorLists)
    for Item in range(NumOfAngleFactorLists):
        var AllAngleFacSummed = 0.0
        let thisAngFacList = state.dataThermalComforts.AngleFactorList[Item]
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                               cCurrentModuleObject,
                                                               Item + 1,  # 1-based in C++
                                                               state.dataIPShortCut.cAlphaArgs,
                                                               NumAlphas,
                                                               state.dataIPShortCut.rNumericArgs,
                                                               NumNumbers,
                                                               IOStatus,
                                                               state.dataIPShortCut.lNumericFieldBlanks,
                                                               state.dataIPShortCut.lAlphaFieldBlanks,
                                                               state.dataIPShortCut.cAlphaFieldNames,
                                                               state.dataIPShortCut.cNumericFieldNames)
        thisAngFacList.Name = state.dataIPShortCut.cAlphaArgs[0]
        thisAngFacList.TotAngleFacSurfaces = NumNumbers
        thisAngFacList.SurfaceName = List[String](thisAngFacList.TotAngleFacSurfaces)
        thisAngFacList.SurfacePtr = List[Int](thisAngFacList.TotAngleFacSurfaces)
        thisAngFacList.AngleFactor = List[Float64](thisAngFacList.TotAngleFacSurfaces)
        for SurfNum in range(thisAngFacList.TotAngleFacSurfaces):
            thisAngFacList.SurfaceName[SurfNum] = state.dataIPShortCut.cAlphaArgs[SurfNum + 1]
            thisAngFacList.SurfacePtr[SurfNum] = FindItemInList(state.dataIPShortCut.cAlphaArgs[SurfNum + 1], state.dataSurface.Surface)
            thisAngFacList.AngleFactor[SurfNum] = state.dataIPShortCut.rNumericArgs[SurfNum]
            if thisAngFacList.SurfacePtr[SurfNum] == 0:
                ShowSevereError(state,
                                "{}: invalid {}, entered value={}".format(cCurrentModuleObject,
                                                                          state.dataIPShortCut.cAlphaFieldNames[SurfNum + 1],
                                                                          state.dataIPShortCut.cAlphaArgs[SurfNum + 1]))
                ShowContinueError(state,
                                  "ref {}={} not found in {}={}".format(state.dataIPShortCut.cAlphaFieldNames[0],
                                                                        state.dataIPShortCut.cAlphaArgs[0],
                                                                        state.dataIPShortCut.cAlphaFieldNames[1],
                                                                        state.dataIPShortCut.cAlphaArgs[1]))
                ErrorsFound = True
            else:
                let thisSurf = state.dataSurface.Surface[thisAngFacList.SurfacePtr[SurfNum]]
                if SurfNum == 0:
                    thisAngFacList.EnclosurePtr = thisSurf.RadEnclIndex
                if thisAngFacList.EnclosurePtr != thisSurf.RadEnclIndex:
                    ShowWarningError(state,
                                     "{}: For {}=\"{}\", surfaces are not all in the same radiant enclosure.".format(routineName, cCurrentModuleObject, thisAngFacList.Name))
                    ShowContinueError(state,
                                      "... Surface=\"{}\" is in enclosure=\"{}\"".format(state.dataSurface.Surface[thisAngFacList.SurfacePtr[0]].Name,
                                                                                        state.dataViewFactor.EnclRadInfo[thisAngFacList.EnclosurePtr].Name))
                    ShowContinueError(state,
                                      "... Surface=\"{}\" is in enclosure=\"{}\"".format(thisSurf.Name,
                                                                                        state.dataViewFactor.EnclRadInfo[thisSurf.RadEnclIndex].Name))
            AllAngleFacSummed += thisAngFacList.AngleFactor[SurfNum]
        if abs(AllAngleFacSummed - 1.0) > AngleFacLimit:
            ShowSevereError(state,
                            "{}=\"{}\", invalid - Sum[AngleFactors]".format(cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state,
                              "...Sum of Angle Factors [{:.3R}] should not deviate from expected sum [1.0] by more than limit [{:.3R}].".format(AllAngleFacSummed, AngleFacLimit))
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetAngleFactorList: Program terminated due to preceding errors.")
    for Item in range(state.dataHeatBal.TotPeople):
        let thisPeople = state.dataHeatBal.People[Item]
        if thisPeople.MRTCalcType != CalcMRT.AngleFactor:
            continue
        thisPeople.AngleFactorListPtr = FindItemInList(thisPeople.AngleFactorListName, state.dataThermalComforts.AngleFactorList)
        let WhichAFList = thisPeople.AngleFactorListPtr
        if WhichAFList == 0 and (thisPeople.Fanger or thisPeople.Pierce or thisPeople.KSU):
            ShowSevereError(state, "{}{}=\"{}\", invalid".format(routineName, cCurrentModuleObject, thisPeople.AngleFactorListName))
            ShowContinueError(state, "... Angle Factor List Name not found for PEOPLE=\"{}\"".format(thisPeople.Name))
            ErrorsFound = True
        else:
            let thisAngFacList = state.dataThermalComforts.AngleFactorList[WhichAFList]
            if state.dataHeatBal.space[thisPeople.spaceIndex].radiantEnclosureNum != thisAngFacList.EnclosurePtr and (thisPeople.Fanger or thisPeople.Pierce or thisPeople.KSU):
                ShowWarningError(state,
                                 "{}{}=\"{}\", radiant enclosure mismatch.".format(routineName, cCurrentModuleObject, thisAngFacList.Name))
                ShowContinueError(state,
                                  "...Enclosure=\"{}\" does not match enclosure=\"{}\" for PEOPLE=\"{}\"".format(
                                      state.dataViewFactor.EnclRadInfo[thisAngFacList.EnclosurePtr].Name,
                                      state.dataViewFactor.EnclRadInfo[state.dataHeatBal.space[thisPeople.spaceIndex].radiantEnclosureNum].Name,
                                      thisPeople.Name))
    if ErrorsFound:
        ShowFatalError(state, "GetAngleFactorList: Program terminated due to preceding errors.")

def CalcAngleFactorMRT(state: EnergyPlusData, AngleFacNum: Int) -> Float64:
    var CalcAngleFactorMRT: Float64
    var SurfTempEmissAngleFacSummed = 0.0
    var SumSurfaceEmissAngleFactor = 0.0
    let thisAngFacList = state.dataThermalComforts.AngleFactorList[AngleFacNum]
    for SurfNum in range(thisAngFacList.TotAngleFacSurfaces):
        let SurfaceTemp = state.dataHeatBalSurf.SurfInsideTempHist[0][thisAngFacList.SurfacePtr[SurfNum]] + Constant.Kelvin  # hist index 1? C++ uses (1) maybe first index. We'll assume 0.
        let SurfEAF = state.dataConstruction.Construct[state.dataSurface.Surface[thisAngFacList.SurfacePtr[SurfNum]].Construction].InsideAbsorpThermal * thisAngFacList.AngleFactor[SurfNum]
        SurfTempEmissAngleFacSummed += SurfEAF * pow_4(SurfaceTemp)
        SumSurfaceEmissAngleFactor += SurfEAF
    CalcAngleFactorMRT = root_4(SurfTempEmissAngleFacSummed / SumSurfaceEmissAngleFactor) - Constant.Kelvin
    return CalcAngleFactorMRT

def CalcSurfaceWeightedMRT(state: EnergyPlusData, SurfNum: Int, AverageWithSurface: Bool = True) -> Float64:
    var CalcSurfaceWeightedMRT = 0.0
    if state.dataThermalComforts.FirstTimeSurfaceWeightedFlag:
        state.dataThermalComforts.FirstTimeError = True
        state.dataThermalComforts.FirstTimeSurfaceWeightedFlag = False
        for thisRadEnclosure in state.dataViewFactor.EnclRadInfo:
            for SurfNum2 in thisRadEnclosure.SurfacePtr:
                let thisSurface2 = state.dataSurface.Surface[SurfNum2]
                thisSurface2.AE = thisSurface2.Area * state.dataConstruction.Construct[thisSurface2.Construction].InsideAbsorpThermal
            for SurfNum1 in thisRadEnclosure.SurfacePtr:
                let thisSurface1 = state.dataSurface.Surface[SurfNum1]
                thisSurface1.enclAESum = 0.0
                for SurfNum2 in thisRadEnclosure.SurfacePtr:
                    if SurfNum2 == SurfNum1:
                        continue
                    let thisSurface2 = state.dataSurface.Surface[SurfNum2]
                    thisSurface1.enclAESum += thisSurface2.AE
    var sumAET = 0.0
    let thisSurface = state.dataSurface.Surface[SurfNum]
    let thisRadEnclosure = state.dataViewFactor.EnclRadInfo[thisSurface.RadEnclIndex]
    if thisRadEnclosure.radReCalc:
        thisSurface.enclAESum = 0.0
        for SurfNum2 in thisRadEnclosure.SurfacePtr:
            if SurfNum2 == SurfNum:
                continue
            let thisSurface2 = state.dataSurface.Surface[SurfNum2]
            thisSurface2.AE = thisSurface2.Area * state.dataConstruction.Construct[thisSurface2.Construction].InsideAbsorpThermal
            thisSurface.enclAESum += thisSurface2.AE
    for SurfNum2 in thisRadEnclosure.SurfacePtr:
        if SurfNum2 == SurfNum:
            continue
        sumAET += state.dataSurface.Surface[SurfNum2].AE * state.dataHeatBalSurf.SurfInsideTempHist[0][SurfNum2]  # hist index 0? 
    let thisSurfaceTemp = state.dataHeatBalSurf.SurfInsideTempHist[0][SurfNum]
    if thisSurface.enclAESum > 0.01:
        CalcSurfaceWeightedMRT = sumAET / thisSurface.enclAESum
        if AverageWithSurface:
            CalcSurfaceWeightedMRT = 0.5 * (thisSurfaceTemp + CalcSurfaceWeightedMRT)
    else:
        if state.dataThermalComforts.FirstTimeError:
            let spaceNum = thisSurface.spaceNum
            ShowWarningError(state,
                             "CalcSurfaceWeightedMRT: Areas*Inside surface emissivities are summing to zero for Enclosure=\"{}\"".format(thisRadEnclosure.Name))
            ShowContinueError(state,
                              "As a result, the MAT for Space={} will be used for MRT when calculating the surface weighted MRT.".format(state.dataHeatBal.space[spaceNum].Name))
            ShowContinueError(state, "for Surface={}".format(thisSurface.Name))
            state.dataThermalComforts.FirstTimeError = False
            CalcSurfaceWeightedMRT = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum].MAT
            if AverageWithSurface:
                CalcSurfaceWeightedMRT = 0.5 * (thisSurfaceTemp + CalcSurfaceWeightedMRT)
    return CalcSurfaceWeightedMRT

def CalcSatVapPressFromTemp(Temp: Float64) -> Float64:
    let XT = Temp / 100.0
    return 6.16796 + 358.1855 * pow_2(XT) - 550.3543 * pow_3(XT) + 1048.8115 * pow_4(XT)

def CalcSatVapPressFromTempTorr(Temp: Float64) -> Float64:
    return exp(18.6686 - 4030.183 / (Temp + 235.0))

def CalcRadTemp(state: EnergyPlusData, PeopleListNum: Int) -> Float64:
    var CalcRadTemp = 0.0
    let AreaEff = 1.8
    let StefanBoltzmannConst = 5.6697e-8
    let thisPeople = state.dataHeatBal.People[PeopleListNum]
    match thisPeople.MRTCalcType:
        case CalcMRT.EnclosureAveraged:
            let enclNum = state.dataHeatBal.space[thisPeople.spaceIndex].radiantEnclosureNum
            state.dataThermalComforts.RadTemp = state.dataViewFactor.EnclRadInfo[enclNum].MRT
        case CalcMRT.SurfaceWeighted:
            state.dataThermalComforts.RadTemp = CalcSurfaceWeightedMRT(state, thisPeople.SurfacePtr)
        case CalcMRT.AngleFactor:
            state.dataThermalComforts.RadTemp = CalcAngleFactorMRT(state, thisPeople.AngleFactorListPtr)
        case _:

    state.dataHeatBalFanSys.ZoneQdotRadHVACToPerson[state.dataThermalComforts.ZoneNum] = state.dataHeatBalFanSys.ZoneQHTRadSysToPerson[state.dataThermalComforts.ZoneNum] + state.dataHeatBalFanSys.ZoneQCoolingPanelToPerson[state.dataThermalComforts.ZoneNum] + state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[state.dataThermalComforts.ZoneNum] + state.dataHeatBalFanSys.ZoneQSteamBaseboardToPerson[state.dataThermalComforts.ZoneNum] + state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson[state.dataThermalComforts.ZoneNum]
    if state.dataHeatBalFanSys.ZoneQdotRadHVACToPerson[state.dataThermalComforts.ZoneNum] > 0.0:
        state.dataThermalComforts.RadTemp += Constant.Kelvin
        state.dataThermalComforts.RadTemp = root_4(pow_4(state.dataThermalComforts.RadTemp) + (state.dataHeatBalFanSys.ZoneQdotRadHVACToPerson[state.dataThermalComforts.ZoneNum] / AreaEff / StefanBoltzmannConst))
        state.dataThermalComforts.RadTemp -= Constant.Kelvin
    CalcRadTemp = state.dataThermalComforts.RadTemp
    return CalcRadTemp

def CalcThermalComfortSimpleASH55(inout state: EnergyPlusData):
    var OperTemp: Float64
    var NumberOccupants: Float64
    var isComfortableWithSummerClothes: Bool
    var isComfortableWithWinterClothes: Bool
    var allowedHours: Float64
    state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Summer = 0.0
    state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Winter = 0.0
    state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Either = 0.0
    for e in state.dataThermalComforts.ThermalComfortInASH55:
        e.ZoneIsOccupied = False
    for people in state.dataHeatBal.People:
        state.dataThermalComforts.ZoneNum = people.ZonePtr
        NumberOccupants = people.NumberOfPeople * people.sched.getCurrentVal()
        if NumberOccupants > 0:
            state.dataThermalComforts.ThermalComfortInASH55[state.dataThermalComforts.ZoneNum].ZoneIsOccupied = True
    for iZone in range(state.dataGlobal.NumOfZones):
        if state.dataThermalComforts.ThermalComfortInASH55[iZone].ZoneIsOccupied:
            let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[iZone]
            state.dataThermalComforts.ZoneOccHrs[iZone] += state.dataGlobal.TimeStepZone
            var CurAirTemp = thisZoneHB.ZTAVComf
            if state.dataRoomAir.anyNonMixingRoomAirModel:
                if state.dataRoomAir.IsZoneDispVent3Node(iZone) or state.dataRoomAir.IsZoneUFAD(iZone):
                    CurAirTemp = state.dataRoomAir.TCMF[iZone]
            let CurMeanRadiantTemp = thisZoneHB.MRT
            OperTemp = CurAirTemp * 0.5 + CurMeanRadiantTemp * 0.5
            isComfortableWithSummerClothes = isInQuadrilateral(OperTemp, thisZoneHB.airHumRatAvgComf, 25.1, 0.0, 23.6, 0.012, 26.8, 0.012, 28.3, 0.0)
            isComfortableWithWinterClothes = isInQuadrilateral(OperTemp, thisZoneHB.airHumRatAvgComf, 21.7, 0.0, 19.6, 0.012, 23.9, 0.012, 26.3, 0.0)
            if isComfortableWithSummerClothes:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotSummer = 0.0
            else:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotSummer = state.dataGlobal.TimeStepZone
                state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotSummer += state.dataGlobal.TimeStepZone
                state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Summer = state.dataGlobal.TimeStepZone
            if isComfortableWithWinterClothes:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotWinter = 0.0
            else:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotWinter = state.dataGlobal.TimeStepZone
                state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotWinter += state.dataGlobal.TimeStepZone
                state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Winter = state.dataGlobal.TimeStepZone
            if isComfortableWithSummerClothes or isComfortableWithWinterClothes:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotEither = 0.0
            else:
                state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotEither = state.dataGlobal.TimeStepZone
                state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither += state.dataGlobal.TimeStepZone
                state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Either = state.dataGlobal.TimeStepZone
        else:
            state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotSummer = 0.0
            state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotWinter = 0.0
            state.dataThermalComforts.ThermalComfortInASH55[iZone].timeNotEither = 0.0
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Summer += state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Summer
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Winter += state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Winter
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Either += state.dataThermalComforts.AnyZoneTimeNotSimpleASH55Either
    if state.dataGlobal.EndDesignDayEnvrnsFlag:
        allowedHours = Float64(state.dataGlobal.NumOfDayInEnvrn) * 24.0 * 0.04
        var showWarning = False
        for iZone in range(state.dataGlobal.NumOfZones):
            if state.dataThermalComforts.ThermalComfortInASH55[iZone].Enable55Warning:
                if state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither > allowedHours:
                    showWarning = True
        if showWarning:
            ShowWarningError(state, "More than 4% of time ({:.1R} hours) uncomfortable in one or more zones ".format(allowedHours))
            ShowContinueError(state, "Based on ASHRAE 55-2004 graph (Section 5.2.1.1)")
            if state.dataEnvrn.RunPeriodEnvironment:
                ShowContinueError(state, "During Environment [{}]: {}".format(state.dataEnvrn.EnvironmentStartEnd, state.dataEnvrn.EnvironmentName))
            else:
                ShowContinueError(state, "During SizingPeriod Environment [{}]: {}".format(state.dataEnvrn.EnvironmentStartEnd, state.dataEnvrn.EnvironmentName))
            for iZone in range(state.dataGlobal.NumOfZones):
                if state.dataThermalComforts.ThermalComfortInASH55[iZone].Enable55Warning:
                    if state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither > allowedHours:
                        ShowContinueError(state, "{:.1R} hours were uncomfortable in zone: {}".format(
                            state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither,
                            state.dataHeatBal.Zone[iZone].Name))
        for iZone in range(state.dataGlobal.NumOfZones):
            PreDefTableEntry(state,
                             pdchSCwinterClothes,
                             state.dataHeatBal.Zone[iZone].Name,
                             state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotWinter)
            PreDefTableEntry(state,
                             pdchSCsummerClothes,
                             state.dataHeatBal.Zone[iZone].Name,
                             state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotSummer)
            PreDefTableEntry(state,
                             pdchSCeitherClothes,
                             state.dataHeatBal.Zone[iZone].Name,
                             state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither)
        PreDefTableEntry(state, pdchSCwinterClothes, "Facility", state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Winter)
        PreDefTableEntry(state, pdchSCsummerClothes, "Facility", state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Summer)
        PreDefTableEntry(state, pdchSCeitherClothes, "Facility", state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Either)
        state.dataOutRptPredefined.TotalTimeNotSimpleASH55EitherForABUPS = state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Either
        for iZone in range(state.dataGlobal.NumOfZones):
            state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotWinter = 0.0
            state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotSummer = 0.0
            state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither = 0.0
        state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Winter = 0.0
        state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Summer = 0.0
        state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Either = 0.0
        match state.dataGlobal.KindOfSim:
            case Constant.KindOfSim.DesignDay:
                addFootNoteSubTable(state, pdstSimpleComfort, "Aggregated over the Design Days")
            case Constant.KindOfSim.RunPeriodDesign:
                addFootNoteSubTable(state, pdstSimpleComfort, "Aggregated over the RunPeriods for Design")
            case Constant.KindOfSim.RunPeriodWeather:
                addFootNoteSubTable(state, pdstSimpleComfort, "Aggregated over the RunPeriods for Weather")
            case _:

        for iZone in range(state.dataGlobal.NumOfZones):
            PreDefTableEntry(state,
                             pdchLeedSutHrsWeek,
                             state.dataHeatBal.Zone[iZone].Name,
                             7 * 24 * (state.dataThermalComforts.ZoneOccHrs[iZone] / (state.dataGlobal.NumOfDayInEnvrn * 24)))

def ResetThermalComfortSimpleASH55(inout state: EnergyPlusData):
    var iZone: Int
    for iZone in range(state.dataGlobal.NumOfZones):
        state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotWinter = 0.0
        state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotSummer = 0.0
        state.dataThermalComforts.ThermalComfortInASH55[iZone].totalTimeNotEither = 0.0
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Winter = 0.0
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Summer = 0.0
    state.dataThermalComforts.TotalAnyZoneTimeNotSimpleASH55Either = 0.0

def CalcIfSetPointMet(inout state: EnergyPlusData):
    let deviationFromSetPtThresholdClg = state.dataHVACGlobal.deviationFromSetPtThresholdClg
    let deviationFromSetPtThresholdHtg = state.dataHVACGlobal.deviationFromSetPtThresholdHtg
    var SensibleLoadPredictedNoAdj: Float64
    var deltaT: Float64
    var iZone: Int
    state.dataThermalComforts.AnyZoneNotMetHeating = 0.0
    state.dataThermalComforts.AnyZoneNotMetCooling = 0.0
    state.dataThermalComforts.AnyZoneNotMetOccupied = 0.0
    state.dataThermalComforts.AnyZoneNotMetHeatingOccupied = 0.0
    state.dataThermalComforts.AnyZoneNotMetCoolingOccupied = 0.0
    for iZone in range(state.dataGlobal.NumOfZones):
        let zoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[iZone]
        SensibleLoadPredictedNoAdj = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[iZone].TotalOutputRequired
        state.dataThermalComforts.ThermalComfortSetPoint[iZone].notMetCooling = 0.0
        state.dataThermalComforts.ThermalComfortSetPoint[iZone].notMetHeating = 0.0
        state.dataThermalComforts.ThermalComfortSetPoint[iZone].notMetCoolingOccupied = 0.0
        state.dataThermalComforts.ThermalComfortSetPoint[iZone].notMetHeatingOccup