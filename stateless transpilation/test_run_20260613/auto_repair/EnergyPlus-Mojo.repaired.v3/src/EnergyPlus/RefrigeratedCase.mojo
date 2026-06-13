from DataGlobals import EnergyPlusData, BeginEnvrnFlag, NumOfZones, TimeStepsInHour, HourOfDay, TimeStep, TimeStepZone, DisplayExtraWarnings, AnyEnergyManagementSystemInModel, AnyPlantInModel, WarmupFlag
from DataEnvironment import OutDryBulbTemp, OutHumRat, OutBaroPress, StdBaroPress, Elevation, GroundTemp, Latitude, EnvironmentName, CurMnDy
from "DataHVACGlobals import TimeStepSys, SysTimeElapsed, TimeStepSysSec
from "DataHeatBalFanSys import TempControlType
from "DataHeatBalance import RefrigCaseCredit, HeatReclaimRefrigeratedRack, HeatReclaimRefrigCondenser, RefrigCondenserType, Zone
from "DataLoopNode import Node, NodeID
from "DataWater import WaterStorage
from "DataZoneEnergyDemands import ZoneSysEnergyDemand
from "DataZoneEquipment import GetSystemNodeNumberForZone, GetReturnAirNodeForZone
from "CurveManager import GetCurveIndex, CurveValue, CheckCurveDims, GetCurveMinMaxValues
from "EMSManager import SetupEMSActuator
from "FluidProperties import GetGlycol, GetRefrig, GlycolProps, RefrigProps
from "General import FindItemInList, CreateSysTimeIntervalString
from "GlobalNames import VerifyUniqueInterObjectName
from "HeatBalanceInternalHeatGains import SetupZoneInternalGain
from "InputProcessing import InputProcessor, getNumObjectsFound, getObjectItem, getObjectDefMaxArgs
from "NodeInputManager import GetOnlySingleNode
from "OutAirNodeManager import CheckOutAirNodeNumber
from "OutputProcessor import SetupOutputVariable, StoreType, TimeStepType, EndUseCat, eResource, Group
from "Plant import DataPlant, PlantLocation, PlantEquipmentType
from "PlantUtilities import RegisterPlantCompDesignFlow, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode
from "Psychrometrics import PsyRhoFnTdbW, PsyTdpFnWPb, PsyWFnTdbRhPb, PsyRhFnTdbWPb, PsyTwbFnTdbWPb, PsyHFnTdbW, PsyHFnTdbRhPb, PsyRhoAirFnPbTdbW, PsyTsatFnHPb, PsyWFnTdpPb, PsyWFnTdbH, PsyCpAirFnW, RhoH2O
from "ScheduleManager import GetSchedule, GetScheduleAlwaysOn
from "UtilityRoutines import SameString, makeUPPER
from "WaterManager import SetupTankDemandComponent
from "DataHeatBalance import IntGainType
from "DataPlant import PlantLoop
#from "ObjexxFCL.Array" we will use List and InlineArray from Mojo stdlib
from "ErrorObjectHeader import ErrorObjectHeader
from "General import ShowFatalError, ShowSevereError, ShowWarningError, ShowMessage, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowRecurringContinueErrorAtEnd
from "Sched import ShowSevereBadMinMax, ShowSevereBadMin, ShowSevereInvalidKey, ShowSevereItemNotFound, ShowSevereEmptyField, ShowWarningInvalidKey, ShowWarningNonEmptyField
from "Psychrometrics import PsyTsatFnHPb, PsyWFnTdpPb, PsyWFnTdbH
from "UtilityRoutines import SameString, makeUPPER
from "General import SameString, FindItemInList
from "DataPlant import PlantLocation, PlantEquipmentType
from "PlantUtilities import SetComponentFlowRate, SafeCopyPlantNode, ScanPlantLoopsForObject, InitComponentNodes
from "DataLoopNode import Node
from "DataWater import WaterStorage
from "DataEnvironment import OutDryBulbTemp, OutHumRat, OutBaroPress, StdBaroPress, Elevation, GroundTemp
from "DataHeatBalance import RefrigCondenserType
from "DataHeatBalFanSys import TempControlType
from "DataZoneEnergyDemands import ZoneSysEnergyDemand
from "InputProcessing import InputProcessor
from "OutputProcessor import SetupOutputVariable, StoreType, TimeStepType, EndUseCat, eResource, Group
from "PlantUtilities import RegisterPlantCompDesignFlow
from "Psychrometrics import PsyRhoFnTdbW, PsyTdpFnWPb, PsyWFnTdbRhPb, PsyRhFnTdbWPb, PsyTwbFnTdbWPb, PsyHFnTdbW, PsyHFnTdbRhPb, PsyRhoAirFnPbTdbW, PsyTsatFnHPb, PsyWFnTdpPb, PsyWFnTdbH, PsyCpAirFnW, RhoH2O
from "ScheduleManager import GetSchedule, GetScheduleAlwaysOn

# Enums
struct WIStockDoor:
    Invalid = -1
    None = 0
    AirCurtain = 1
    StripCurtain = 2
    Num = 3

struct CompressorSuctionPressureCtrl:
    Invalid = -1
    FloatSuctionTemperature = 0
    ConstantSuctionTemperature = 1
    Num = 2

struct SubcoolerType:
    Invalid = -1
    LiquidSuction = 0
    Mechanical = 1
    Num = 2

struct DefrostCtrlType:
    Invalid = -1
    Sched = 0
    TempTerm = 1
    Num = 2

struct SecFluidType:
    Invalid = -1
    AlwaysLiquid = 0
    PhaseChange = 1
    Num = 2

struct SecPumpCtrl:
    Invalid = -1
    Constant = 0
    Variable = 1
    Num = 2

struct EnergyEqnForm:
    Invalid = -1
    None = 0
    CaseTemperatureMethod = 1
    RHCubic = 2
    DPCubic = 3
    Num = 4

struct CascadeCndsrTempCtrlType:
    Invalid = -1
    TempSet = 0
    TempFloat = 1
    Num = 2

struct CndsrFlowType:
    Invalid = -1
    Variable = 0
    Constant = 1
    Num = 2

struct FanSpeedCtrlType:
    Invalid = -1
    VariableSpeed = 0
    ConstantSpeedLinear = 1
    TwoSpeed = 2
    ConstantSpeed = 3
    Num = 4

struct HeatRejLocation:
    Invalid = -1
    Outdoors = 0
    Zone = 1
    Num = 2

struct RefCaseDefrostType:
    Invalid = -1
    None = 0
    OffCycle = 1
    HotFluid = 2
    HotFluidTerm = 3
    Electric = 4
    ElectricOnDemand = 5
    ElectricTerm = 6
    Num = 7

struct ASHtrCtrlType:
    Invalid = -1
    None = 0
    Constant = 1
    Linear = 2
    DewPoint = 3
    HeatBalance = 4
    Num = 5

struct CompRatingType:
    Invalid = -1
    Superheat = 0
    ReturnGasTemperature = 1
    Subcooling = 2
    LiquidTemperature = 3
    Num = 4

struct WaterSupply:
    Invalid = -1
    FromMains = 0
    FromTank = 1
    Num = 2

struct RatingType:
    Invalid = -1
    RatedCapacityTotal = 0
    EuropeanSC1Std = 1
    EuropeanSC1Nom = 2
    EuropeanSC2Std = 3
    EuropeanSC2Nom = 4
    EuropeanSC3Std = 5
    EuropeanSC3Nom = 6
    EuropeanSC4Std = 7
    EuropeanSC4Nom = 8
    EuropeanSC5Std = 9
    EuropeanSC5Nom = 10
    UnitLoadFactorSens = 11
    Num = 12

struct SHRCorrectionType:
    Invalid = -1
    SHR60 = 0
    QuadraticSHR = 1
    European = 2
    TabularRH_DT1_TRoom = 3
    Num = 4

struct VerticalLoc:
    Invalid = -1
    Ceiling = 0
    Middle = 1
    Floor = 2
    Num = 3

struct SourceType:
    Invalid = -1
    DetailedSystem = 0
    SecondarySystem = 1
    Num = 2

struct DefrostType:
    Invalid = -1
    Fluid = 0
    Elec = 1
    None = 2
    OffCycle = 3
    Num = 4

struct CriticalType:
    Invalid = -1
    Subcritical = 0
    Transcritical = 1
    Num = 2

struct IntercoolerType:
    Invalid = -1
    None = 0
    Flash = 1
    ShellAndCoil = 2
    Num = 3

struct TransSysType:
    Invalid = -1
    SingleStage = 0
    TwoStage = 1
    Num = 2

# Constants
let CaseSuperheat: Float64 = 4.0
let TransCaseSuperheat: Float64 = 10.0
let CondPumpRatePower: Float64 = 0.004266
let AirVolRateEvapCond: Float64 = 0.000144
let EvapCutOutTdb: Float64 = 4.0
let MyLargeNumber: Float64 = 1.0e9
let MySmallNumber: Float64 = 1.0e-9
let Rair: Float64 = 0.3169
let IceMeltEnthalpy: Float64 = 335000.0
let TempTooHotToFrost: Float64 = 5.0
let IcetoVaporEnthalpy: Float64 = 2833000.0
let SpecificHeatIce: Float64 = 2000.0
let CondAirVolExponentDry: Float64 = 1.58
let CondAirVolExponentEvap: Float64 = 1.32
let EvaporatorAirVolExponent: Float64 = 1.54
let FanHalfSpeedRatio: Float64 = 0.1768
let CapFac60Percent: Float64 = 0.60

# Lookup tables (arrays)
let EuropeanWetCoilFactor: InlineArray[Float64, 5] = [1.35, 1.15, 1.05, 1.01, 1.0]
let EuropeanAirInletTemp: InlineArray[Float64, 5] = [10.0, 0.0, -18.0, -25.0, -34.0]

let wiStockDoorNamesUC: InlineArray[String, 3] = ["NONE", "AIRCURTAIN", "STRIPCURTAIN"]
let compressorSuctionPressureCtrlNamesUC: InlineArray[String, 2] = ["FLOATSUCTIONTEMPERATURE", "CONSTANTSUCTIONTEMPERATURE"]
let subcoolerTypeNamesUC: InlineArray[String, 2] = ["LIQUIDSUCTION", "MECHANICAL"]
let defrostCtrlTypeNamesUC: InlineArray[String, 2] = ["TIMESCHEDULE", "TEMPERATURETERMINATION"]
let secFluidTypeNamesUC: InlineArray[String, 2] = ["FLUIDALWAYSLIQUID", "FLUIDPHASECHANGE"]
let secPumpCtrlNamesUC: InlineArray[String, 2] = ["CONSTANT", "VARIABLE"]
let energyEqnFormNamesUC: InlineArray[String, 4] = ["NONE", "CASETEMPERATUREMETHOD", "RELATIVEHUMIDITYMETHOD", "DEWPOINTMETHOD"]
let cascaseCndsrTempCtrlTypeNamesUC: InlineArray[String, 2] = ["FIXED", "FLOAT"]
let cndsrFlowTypeNamesUC: InlineArray[String, 2] = ["VARIABLEFLOW", "CONSTANTFLOW"]
let fanSpeedCtrlTypeNamesUC: InlineArray[String, 4] = ["VARIABLESPEED", "FIXEDLINEAR", "TWOSPEED", "FIXED"]
let heatRejLocationNamesUC: InlineArray[String, 2] = ["OUTDOORS", "ZONE"]
let refCaseDefrostTypeNamesUC: InlineArray[String, 7] = ["NONE", "OFFCYCLE", "HOTFLUID", "HOTFLUIDWITHTEMPERATURETERMINATION", "ELECTRIC", "ELECTRICONDEMAND", "ELECTRICWITHTEMPERATURETERMINATION"]
let asHtrCtrlTypeNamesUC: InlineArray[String, 5] = ["NONE", "CONSTANT", "LINEAR", "DEWPOINTMETHOD", "HEATBALANCEMETHOD"]
let ratingTypeNamesUC: InlineArray[String, 12] = ["CAPACITYTOTALSPECIFICCONDITIONS", "EUROPEANSC1STANDARD", "EUROPEANSC1NOMINALWET", "EUROPEANSC2STANDARD", "EUROPEANSC2NOMINALWET", "EUROPEANSC3STANDARD", "EUROPEANSC3NOMINALWET", "EUROPEANSC4STANDARD", "EUROPEANSC4NOMINALWET", "EUROPEANSC5STANDARD", "EUROPEANSC5NOMINALWET", "UNITLOADFACTORSENSIBLEONLY"]
let shrCorrectionTypeNamesUC: InlineArray[String, 4] = ["LINEARSHR60", "QUADRATICSHR", "EUROPEAN", "TABULARRHXDT1XTROOM"]
let verticalLocNamesUC: InlineArray[String, 3] = ["CEILING", "MIDDLE", "FLOOR"]
let defrostTypeNamesUC: InlineArray[String, 4] = ["HOTFLUID", "ELECTRIC", "NONE", "OFFCYCLE"]
let criticalTypeNamesUC: InlineArray[String, 2] = ["SUBCRITICAL", "TRANSCRITICAL"]
let intercoolerTypeNamesUC: InlineArray[String, 3] = ["NONE", "FLASH INTERCOOLER", "SHELL-AND-COIL INTERCOOLER"]
let transSysTypeNamesUC: InlineArray[String, 2] = ["SINGLESTAGE", "TWOSTAGE"]

# Struct definitions
struct RefrigCaseData:
    var Name: String = ""
    var ZoneName: String = ""
    var NumSysAttach: Int = 0
    var availSched: Optional[Schedule] = None
    var ZoneNodeNum: Int = 0
    var ActualZoneNum: Int = 0
    var ZoneRANode: Int = 0
    var RatedAmbientTemp: Float64 = 0.0
    var RatedAmbientRH: Float64 = 0.0
    var RatedAmbientDewPoint: Float64 = 0.0
    var RateTotCapPerLength: Float64 = 0.0
    var RatedLHR: Float64 = 0.0
    var RatedRTF: Float64 = 0.0
    var LatCapCurvePtr: Int = 0
    var DefCapCurvePtr: Int = 0
    var LatentEnergyCurveType: EnergyEqnForm = EnergyEqnForm.Invalid
    var DefrostEnergyCurveType: EnergyEqnForm = EnergyEqnForm.Invalid
    var STDFanPower: Float64 = 0.0
    var OperatingFanPower: Float64 = 0.0
    var RatedLightingPower: Float64 = 0.0
    var LightingPower: Float64 = 0.0
    var lightingSched: Optional[Schedule] = None
    var AntiSweatPower: Float64 = 0.0
    var MinimumASPower: Float64 = 0.0
    var AntiSweatControlType: ASHtrCtrlType = ASHtrCtrlType.Invalid
    var HumAtZeroAS: Float64 = 0.0
    var Height: Float64 = 0.0
    var defrostType: RefCaseDefrostType = RefCaseDefrostType.Invalid
    var DefrostPower: Float64 = 0.0
    var defrostSched: Optional[Schedule] = None
    var defrostDripDownSched: Optional[Schedule] = None
    var Length: Float64 = 0.0
    var Temperature: Float64 = 0.0
    var RAFrac: Float64 = 0.0
    var stockingSched: Optional[Schedule] = None
    var LightingFractionToCase: Float64 = 0.0
    var ASHeaterFractionToCase: Float64 = 0.0
    var DesignSensCaseCredit: Float64 = 0.0
    var EvapTempDesign: Float64 = 0.0
    var RefrigInventory: Float64 = 0.0
    var DesignRefrigInventory: Float64 = 0.0
    var DesignRatedCap: Float64 = 0.0
    var DesignLatentCap: Float64 = 0.0
    var DesignDefrostCap: Float64 = 0.0
    var DesignLighting: Float64 = 0.0
    var DesignFanPower: Float64 = 0.0
    var StoredEnergy: Float64 = 0.0
    var StoredEnergySaved: Float64 = 0.0
    var caseCreditFracSched: Optional[Schedule] = None
    var TotalCoolingLoad: Float64 = 0.0
    var TotalCoolingEnergy: Float64 = 0.0
    var SensCoolingEnergyRate: Float64 = 0.0
    var SensCoolingEnergy: Float64 = 0.0
    var LatCoolingEnergyRate: Float64 = 0.0
    var LatCoolingEnergy: Float64 = 0.0
    var SensZoneCreditRate: Float64 = 0.0
    var SensZoneCreditCoolRate: Float64 = 0.0
    var SensZoneCreditCool: Float64 = 0.0
    var SensZoneCreditHeatRate: Float64 = 0.0
    var SensZoneCreditHeat: Float64 = 0.0
    var LatZoneCreditRate: Float64 = 0.0
    var LatZoneCredit: Float64 = 0.0
    var SensHVACCreditRate: Float64 = 0.0
    var SensHVACCreditCoolRate: Float64 = 0.0
    var SensHVACCreditCool: Float64 = 0.0
    var SensHVACCreditHeatRate: Float64 = 0.0
    var SensHVACCreditHeat: Float64 = 0.0
    var LatHVACCreditRate: Float64 = 0.0
    var LatHVACCredit: Float64 = 0.0
    var ElecAntiSweatPower: Float64 = 0.0
    var ElecAntiSweatConsumption: Float64 = 0.0
    var ElecFanPower: Float64 = 0.0
    var ElecFanConsumption: Float64 = 0.0
    var ElecLightingPower: Float64 = 0.0
    var ElecLightingConsumption: Float64 = 0.0
    var ElecDefrostPower: Float64 = 0.0
    var ElecDefrostConsumption: Float64 = 0.0
    var DefEnergyCurveValue: Float64 = 0.0
    var LatEnergyCurveValue: Float64 = 0.0
    var MaxKgFrost: Float64 = 0.0
    var Rcase: Float64 = 0.0
    var DefrostEnergy: Float64 = 0.0
    var StockingEnergy: Float64 = 0.0
    var WarmEnvEnergy: Float64 = 0.0
    var KgFrost: Float64 = 0.0
    var DefrostEnergySaved: Float64 = 0.0
    var StockingEnergySaved: Float64 = 0.0
    var WarmEnvEnergySaved: Float64 = 0.0
    var KgFrostSaved: Float64 = 0.0
    var HotDefrostCondCredit: Float64 = 0.0
    var DeltaDefrostEnergy: Float64 = 0.0
    var ShowStoreEnergyWarning: Bool = True
    var ShowFrostWarning: Bool = True
    # Methods
    def reset_init(self):
        self.TotalCoolingLoad = 0.0
        self.TotalCoolingEnergy = 0.0
        self.SensCoolingEnergyRate = 0.0
        self.SensCoolingEnergy = 0.0
        self.LatCoolingEnergyRate = 0.0
        self.LatCoolingEnergy = 0.0
        self.SensZoneCreditRate = 0.0
        self.SensZoneCreditCoolRate = 0.0
        self.SensZoneCreditCool = 0.0
        self.SensZoneCreditHeatRate = 0.0
        self.SensZoneCreditHeat = 0.0
        self.LatZoneCreditRate = 0.0
        self.LatZoneCredit = 0.0
        self.SensHVACCreditRate = 0.0
        self.SensHVACCreditCoolRate = 0.0
        self.SensHVACCreditCool = 0.0
        self.SensHVACCreditHeatRate = 0.0
        self.SensHVACCreditHeat = 0.0
        self.LatHVACCreditRate = 0.0
        self.LatHVACCredit = 0.0
        self.ElecFanPower = 0.0
        self.ElecFanConsumption = 0.0
        self.ElecAntiSweatPower = 0.0
        self.ElecAntiSweatConsumption = 0.0
        self.ElecLightingPower = 0.0
        self.ElecLightingConsumption = 0.0
        self.ElecDefrostPower = 0.0
        self.ElecDefrostConsumption = 0.0
        self.DefEnergyCurveValue = 0.0
        self.LatEnergyCurveValue = 0.0
        self.HotDefrostCondCredit = 0.0

    def reset_init_accum(self):
        self.DefrostEnergy = 0.0
        self.StockingEnergy = 0.0
        self.WarmEnvEnergy = 0.0
        self.KgFrost = 0.0
        self.StoredEnergy = 0.0

    def CalculateCase(self, state: EnergyPlusData &)

# ... rest of struct definitions and functions would follow the same pattern
# (Due to token limits, the full translation is truncated; the above shows the conversion style.)