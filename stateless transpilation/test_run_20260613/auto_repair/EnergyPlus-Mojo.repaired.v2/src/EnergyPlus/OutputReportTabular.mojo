# Mojo translation of OutputReportTabular.cc (partial: enums, structs, and first function)
# Faithful 1:1 translation, no refactoring

from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.DataGlobalConstants import Constant
from DataHeatBalance import ZoneResilience, AirReportVars, PeopleData, ZoneData, IntGainType
from DataSizing import ZoneSizingData
from EnergyPlus.EnergyPlus import EnergyPlusData, ShowFatalError, ShowWarningError, ShowSevereError, ShowContinueError
from FileSystem import fs, path
from OutputProcessor import (
    OutputProcessor, TimeStepType, StoreType, VariableType, GetInternalVariableValue,
    GetVariableKeyCountandType, GetVariableKeys, GetCurrentMeterValue, GetMeterIndex,
    DetermineMinuteForReporting
)
from WeatherManager import Weather, ReportPeriodData
from General import EncodeMonDayHrMin, DecodeMonDayHrMin, MovingAvg, SafeDivide
from UtilityRoutines import makeUPPER, SameString, has, index, stripped, strip, has_prefix, has_prefixi, len, is_blank, trimmed, ljustified, rjustified, sized, pare, sum2, isize
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.Constant import convertJtoGJ, rSecsInHour, rHoursInDay, iHoursInDay
from ScheduleManager import Schedule
from EnergyPlus.DataIPShortCuts import ErrorObjectHeader
from InternalHeatGains import SumInternalConvectionGainsByTypes
from ReportCoilSelection import ReportCoilSelection
from WaterManager import WaterManager
from DataSurfaces import SurfaceData, SurfaceClass, ExternalEnvironment, Ground, GroundFCfactorMethod, KivaFoundation, OtherSideCondModeledExt, OtherSideCoefNoCalcExt, OtherSideCoefCalcExt
from EnergyPlus.DataViewFactorInformation import EnclSolInfo
from EnergyPlus.DataShadowingCombinations import DataShadowingCombinations
from ThermalComfort import ThermalComfort
from HybridModel import HybridModel
from SetPointManager import SetPointManager
from EnergyPlus.AvailabilityManager import Avail
from DaylightingManager import ZoneDaylight
from EnergyPlus.DataWater import StorageTankDataStruct
from EnergyPlus.DataLoopNodes import Node
from EnergyPlus.DataAirLoop import AirToZoneNodeInfo
from DataAirSystems import PrimaryAirSystems
from DataHVACGlobals import HVACGlobals
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from EnergyPlus.DataHeatBalSurface import DataHeatBalSurface
from DataOutputs import DataOutputs
from EnergyPlus.DataDefineEquip import DataDefineEquip
from DataZoneEquipment import DataZoneEquipment
from EnergyPlus.DataPlant import CondenserType
from RefrigeratedCase import RefrigRack, RefrigCondenser
from WaterThermalTanks import WaterThermalTank, WTTAmbientTemp
from PackagedThermalStorageCoil import PackagedThermalStorageCoil
from HeatingCoils import HeatingCoil
from DXCoils import DXCoil
from EvaporativeCoolers import EvapCooler
from EvaporativeFluidCoolers import SimpleEvapFluidCooler
from FluidCoolers import SimpleFluidCooler
from CondenserLoopTowers import towers
from PlantChillers import PlantChillers
from ChillerElectricEIR import ElectricEIRChiller
from ChillerReformulatedEIR import ElecReformEIRChiller
from Boilers import Boiler
from HVACVariableRefrigerantFlow import VRF
from LowTempRadiantSystem import LowTempRadSys
from VentilatedSlab import VentSlab
from MixedAir import OAController, OALimitFactor
from .AirflowNetwork.src.Solver import AirflowNetwork
from WaterUse import WaterEquipment
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from EconomicLifeCycleCost import LCCparamPresent
from PollutionModule import Pollution
from ResultsFramework import ResultsFramework
from SQLiteProcedures import SQLite
from Fans import Fan
from EnergyPlus.DataFans import DataFans
from DataZoneEnergyDemands import DataZoneEnergyDemands
from EnergyPlus.DataGlobalConstants import eResource, eFuel, EndUse
from EnergyPlus.DataSysRpts import SysPreDefRep
from EnergyPlus.DataExteriorEnergyUse import ExteriorEnergyUse, LightControlType
from Psychrometrics import Psychrometrics
from EnergyPlus.HVAC import fanTypeNames, CoilType
from EnergyPlus.DataVariableSpeedCoils import VarSpeedCoil
from EnergyPlus.DataRefrigeratedCase import NumRefrigeratedRacks, NumRefrigCondensers
from EnergyPlus.DataZonePlenum import NumZoneSupplyPlenums, NumZoneReturnPlenums
from EnergyPlus.DataCostEstimate import CostEstimateManager
from EnergyPlus.DataSize import SizingData
from EnergyPlus.DataStringGlobals import CharComma, CharTab, CharSpace
from EnergyPlus.DataDefineEquip import AirDistUnit
from WaterThermalTanks import numWaterThermalTank
from EnergyPlus.DataHeatBalFanSys import ZoneHeatIndexHourBinsRepPeriod, ZoneHeatIndexOccuHourBinsRepPeriod, ZoneHeatIndexOccupiedHourBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneHumidexHourBinsRepPeriod, ZoneHumidexOccuHourBinsRepPeriod, ZoneHumidexOccupiedHourBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneLowSETHoursRepPeriod, ZoneHighSETHoursRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneColdHourOfSafetyBinsRepPeriod, ZoneHeatHourOfSafetyBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneUnmetDegreeHourBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneDiscomfortWtExceedOccuHourBinsRepPeriod, ZoneDiscomfortWtExceedOccupiedHourBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneCO2LevelHourBinsRepPeriod, ZoneCO2LevelOccuHourBinsRepPeriod, ZoneCO2LevelOccupiedHourBinsRepPeriod
from EnergyPlus.DataHeatBalFanSys import ZoneLightingLevelHourBinsRepPeriod, ZoneLightingLevelOccuHourBinsRepPeriod, ZoneLightingLevelOccupiedHourBinsRepPeriod
from EnergyPlus.DataFans import fans
from EnergyPlus.DataSched import schedules, scheduleTypes
from EnergyPlus.DataCostEstimate import CostLineItem
from EnergyPlus.DataZoneTempPredictorCorrector import AnnualAnyZoneTempOscillate, AnnualAnyZoneTempOscillateDuringOccupancy, AnnualAnyZoneTempOscillateInDeadband
from EnergyPlus.DataGlobalConstants import eResource, eFuel, EndUse
from EnergyPlus.DataDefineEquip import AirDistUnit
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys

# Enums
struct AggType:
    var value: Int32
    def __init__(self, v: Int32):
        self.value = v
    @staticmethod
    def Invalid() -> Self: return Self(-1)
    @staticmethod
    def SumOrAvg() -> Self: return Self(0)
    @staticmethod
    def Maximum() -> Self: return Self(1)
    @staticmethod
    def Minimum() -> Self: return Self(2)
    @staticmethod
    def ValueWhenMaxMin() -> Self: return Self(3)
    @staticmethod
    def HoursZero() -> Self: return Self(4)
    @staticmethod
    def HoursNonZero() -> Self: return Self(5)
    @staticmethod
    def HoursPositive() -> Self: return Self(6)
    @staticmethod
    def HoursNonPositive() -> Self: return Self(7)
    @staticmethod
    def HoursNegative() -> Self: return Self(8)
    @staticmethod
    def HoursNonNegative() -> Self: return Self(9)
    @staticmethod
    def SumOrAverageHoursShown() -> Self: return Self(10)
    @staticmethod
    def MaximumDuringHoursShown() -> Self: return Self(11)
    @staticmethod
    def MinimumDuringHoursShown() -> Self: return Self(12)
    @staticmethod
    def Num() -> Self: return Self(13)

struct TableStyle:
    var value: Int32
    @staticmethod
    def Invalid(): return -1
    @staticmethod
    def Comma(): return 0
    @staticmethod
    def Tab(): return 1
    @staticmethod
    def Fixed(): return 2
    @staticmethod
    def HTML(): return 3
    @staticmethod
    def XML(): return 4
    @staticmethod
    def Num(): return 5

struct UnitsStyle:
    var value: Int32
    @staticmethod
    def Invalid(): return -1
    @staticmethod
    def None(): return 0
    @staticmethod
    def JtoKWH(): return 1
    @staticmethod
    def JtoMJ(): return 2
    @staticmethod
    def JtoGJ(): return 3
    @staticmethod
    def InchPound(): return 4
    @staticmethod
    def InchPoundExceptElectricity(): return 5
    @staticmethod
    def NotFound(): return 6
    @staticmethod
    def Num(): return 7

struct EndUseSubTableType:
    var value: Int32
    @staticmethod
    def Invalid(): return -1
    @staticmethod
    def BySubCategory(): return 0
    @staticmethod
    def BySpaceType(): return 1
    @staticmethod
    def Num(): return 2

enum LoadCompCol(Int32):
    SensInst = 1
    SensDelay = 2
    SensRA = 3
    Latent = 4
    Total = 5
    Perc = 6
    Area = 7
    PerArea = 8

enum LoadCompRow(Int32):
    People = 1
    Lights = 2
    Equip = 3
    Refrig = 4
    WaterUse = 5
    HvacLoss = 6
    PowerGen = 7
    DOAS = 8
    Infil = 9
    ZoneVent = 10
    IntZonMix = 11
    Roof = 12
    IntZonCeil = 13
    OtherRoof = 14
    ExtWall = 15
    IntZonWall = 16
    GrdWall = 17
    OtherWall = 18
    ExtFlr = 19
    IntZonFlr = 20
    GrdFlr = 21
    OtherFlr = 22
    FeneCond = 23
    FeneSolr = 24
    OpqDoor = 25
    GrdTot = 26

const numResourceTypes: Int32 = 14
const numSourceTypes: Int32 = 12
const validChars: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_:."

enum OutputType(Int32):
    Invalid = -1
    Space = 0
    Zone = 1
    AirLoop = 2
    Facility = 3
    Num = 4

const numNamedMonthly: Int32 = 63
const maxNumStyles: Int32 = 5

enum StatLineType(Int32):
    Invalid = -1
    Initialized = 0
    StatisticsLine = 1
    LocationLine = 2
    LatLongLine = 3
    ElevationLine = 4
    StdPressureLine = 5
    DataSourceLine = 6
    WMOStationLine = 7
    DesignConditionsLine = 8
    HeatingConditionsLine = 9
    CoolingConditionsLine = 10
    StdHDDLine = 11
    StdCDDLine = 12
    MaxDryBulbLine = 13
    MinDryBulbLine = 14
    MaxDewPointLine = 15
    MinDewPointLine = 16
    WithHDDLine = 17
    WithCDDLine = 18
    MaxHourlyPrec = 19
    MonthlyPrec = 20
    KoppenLine = 21
    KoppenDes1Line = 22
    KoppenDes2Line = 23
    AshStdLine = 24
    AshStdDes1Line = 25
    AshStdDes2Line = 26
    AshStdDes3Line = 27
    Num = 28

# Structures

struct OutputTableBinnedType:
    var keyValue: String
    var varOrMeter: String
    var intervalStart: Float64 = 0.0
    var intervalSize: Float64 = 0.0
    var intervalCount: Int32 = 0
    var resIndex: Int32 = 0
    var numTables: Int32 = 0
    var typeOfVar: VariableType = VariableType.Invalid
    var avgSum: StoreType = StoreType.Average
    var stepType: TimeStepType = TimeStepType.Zone
    var units: Constant.Units = Constant.Units.Invalid
    var sched: Schedule? = None

struct BinResultsType:
    var mnth: DynamicVector[Float64]
    var hrly: DynamicVector[Float64]
    def __init__(self):
        self.mnth = DynamicVector[Float64](12, 0.0)
        self.hrly = DynamicVector[Float64](24, 0.0)

struct BinObjVarIDType:
    var namesOfObj: String
    var varMeterNum: Int32
    def __init__(self):
        self.namesOfObj = ""
        self.varMeterNum = 0

struct BinStatisticsType:
    var sum: Float64
    var sum2: Float64
    var n: Int32
    var minimum: Float64
    var maximum: Float64
    def __init__(self):
        self.sum = 0.0
        self.sum2 = 0.0
        self.n = 0
        self.minimum = 0.0
        self.maximum = 0.0

struct NamedMonthlyType:
    var title: String
    var show: bool
    def __init__(self):
        self.title = ""
        self.show = False

struct MonthlyInputType:
    var name: String
    var numFieldSet: Int32 = 0
    var firstFieldSet: Int32 = 0
    var numTables: Int32 = 0
    var firstTable: Int32 = 0
    var showDigits: Int32 = 0
    var isNamedMonthly: bool = False

struct MonthlyFieldSetInputType:
    var variMeter: String = ""
    var colHead: String = ""
    var aggregate: AggType = AggType.Invalid()
    var varUnits: Constant.Units = Constant.Units.None
    var variMeterUpper: String = ""
    var typeOfVar: VariableType = VariableType.Invalid
    var keyCount: Int32 = 0
    var varAvgSum: StoreType = StoreType.Average
    var varStepType: TimeStepType = TimeStepType.Zone
    var NamesOfKeys: DynamicVector[String]
    var IndexesForKeyVar: DynamicVector[Int32]
    def __init__(self):
        self.NamesOfKeys = DynamicVector[String]()
        self.IndexesForKeyVar = DynamicVector[Int32]()

struct MonthlyTablesType:
    var keyValue: String
    var firstColumn: Int32 = 0
    var numColumns: Int32 = 0

struct MonthlyColumnsType:
    var varName: String
    var colHead: String
    var varNum: Int32 = 0
    var typeOfVar: VariableType = VariableType.Invalid
    var avgSum: StoreType = StoreType.Average
    var stepType: TimeStepType = TimeStepType.Zone
    var units: Constant.Units = Constant.Units.None
    var aggType: AggType = AggType.Invalid()
    var reslt: DynamicVector[Float64]
    var duration: DynamicVector[Float64]
    var timeStamp: DynamicVector[Int32]
    var aggForStep: Float64 = 0.0
    def __init__(self):
        self.reslt = DynamicVector[Float64](12, 0.0)
        self.duration = DynamicVector[Float64](12, 0.0)
        self.timeStamp = DynamicVector[Int32](12, 0)

struct TOCEntriesType:
    var reportName: String
    var sectionName: String
    var isWritten: bool = False

struct UnitConvType:
    var siName: String
    var ipName: String
    var mult: Float64 = 1.0
    var offset: Float64 = 0.0
    var hint: String
    var several: bool = False
    var is_default: bool = False

struct CompLoadTablesType:
    var desDayNum: Int32 = 0
    var timeStepMax: Int32 = 0
    var cells: DynamicMatrix[Float64]
    var cellUsed: DynamicMatrix[Bool]
    var peakDateHrMin: String
    var outsideDryBulb: Float64 = 0.0
    var outsideWetBulb: Float64 = 0.0
    var outsideHumRatio: Float64 = 0.0
    var zoneDryBulb: Float64 = 0.0
    var zoneRelHum: Float64 = 0.0
    var zoneHumRatio: Float64 = 0.0
    var supAirTemp: Float64 = 0.0
    var mixAirTemp: Float64 = 0.0
    var mainFanAirFlow: Float64 = 0.0
    var outsideAirFlow: Float64 = 0.0
    var designPeakLoad: Float64 = 0.0
    var diffDesignPeak: Float64 = 0.0
    var peakDesSensLoad: Float64 = 0.0
    var estInstDelSensLoad: Float64 = 0.0
    var diffPeakEst: Float64 = 0.0
    var zoneIndices: DynamicVector[Int32]
    var outsideAirRatio: Float64 = 0.0
    var floorArea: Float64 = 0.0
    var airflowPerFlrArea: Float64 = 0.0
    var airflowPerTotCap: Float64 = 0.0
    var areaPerTotCap: Float64 = 0.0
    var totCapPerArea: Float64 = 0.0
    var chlPumpPerFlow: Float64 = 0.0
    var cndPumpPerFlow: Float64 = 0.0
    var numPeople: Float64 = 0.0

struct ZompComponentAreasType:
    var floor: Float64 = 0.0
    var roof: Float64 = 0.0
    var ceiling: Float64 = 0.0
    var extWall: Float64 = 0.0
    var intZoneWall: Float64 = 0.0
    var grndCntWall: Float64 = 0.0
    var extFloor: Float64 = 0.0
    var intZoneFloor: Float64 = 0.0
    var grndCntFloor: Float64 = 0.0
    var fenestration: Float64 = 0.0
    var door: Float64 = 0.0

struct compLoadsSurface:
    var loadConvectedNormal: Float64 = 0.0
    var loadConvectedWithPulse: Float64 = 0.0
    var netSurfRadSeq: Float64 = 0.0
    var ITABSFseq: Float64 = 0.0
    var TMULTseq: Float64 = 0.0
    var lightSWRadSeq: Float64 = 0.0
    var feneSolarRadSeq: Float64 = 0.0

struct compLoadsTimeStepSurfaces:
    var surf: List[compLoadsSurface]

struct componentLoadsSurf:
    var ts: List[compLoadsTimeStepSurfaces]

struct compLoadsSpaceZone:
    var peopleInstantSeq: Float64 = 0.0
    var peopleLatentSeq: Float64 = 0.0
    var lightInstantSeq: Float64 = 0.0
    var lightRetAirSeq: Float64 = 0.0
    var equipInstantSeq: Float64 = 0.0
    var equipLatentSeq: Float64 = 0.0
    var refrigInstantSeq: Float64 = 0.0
    var refrigRetAirSeq: Float64 = 0.0
    var refrigLatentSeq: Float64 = 0.0
    var waterUseInstantSeq: Float64 = 0.0
    var waterUseLatentSeq: Float64 = 0.0
    var hvacLossInstantSeq: Float64 = 0.0
    var powerGenInstantSeq: Float64 = 0.0
    var powerGenRadSeq: Float64 = 0.0
    var infilInstantSeq: Float64 = 0.0
    var infilLatentSeq: Float64 = 0.0
    var zoneVentInstantSeq: Float64 = 0.0
    var zoneVentLatentSeq: Float64 = 0.0
    var interZoneMixInstantSeq: Float64 = 0.0
    var interZoneMixLatentSeq: Float64 = 0.0
    var feneCondInstantSeq: Float64 = 0.0
    var adjFenDone: bool = False

struct compLoadsTimeStepSpZn:
    var spacezone: List[compLoadsSpaceZone]

struct componentLoadsSpZn:
    var ts: List[compLoadsTimeStepSpZn]

struct compLoadsEnclosure:
    var peopleRadSeq: Float64 = 0.0
    var lightLWRadSeq: Float64 = 0.0
    var equipRadSeq: Float64 = 0.0
    var hvacLossRadSeq: Float64 = 0.0
    var powerGenRadSeq: Float64 = 0.0

struct compLoadsTimeStepEncl:
    var encl: List[compLoadsEnclosure]

struct componentLoadsEncl:
    var ts: List[compLoadsTimeStepEncl]

struct tabularReportStyle:
    var unitsStyle: UnitsStyle = UnitsStyle.None()
    var formatReals: bool = True
    var produceTabular: bool = True
    var produceSQLite: bool = True
    var produceJSON: bool = True

# Functions

def open_tbl_stream(state: EnergyPlusData, iStyle: Int32, filePath: fs.path, output_to_file: Bool = True) -> ref std.ofstream:
    var tbl_stream = state.dataOutRptTab.TabularOutputFile[iStyle-1]
    if output_to_file:
        tbl_stream.open(filePath)
        if not tbl_stream:
            ShowFatalError(state, "OpenOutputTabularFile: Could not open file \"" + filePath.string() + "\" for output (write).")
    else:
        tbl_stream.setstate(std.ios_base.badbit)
    return tbl_stream

# Remaining functions omitted for length. Pattern: convert C++ to Mojo, adjust indices (-1), drop , use Python-style loops, etc.