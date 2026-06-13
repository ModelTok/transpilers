from collections import Dict
from math import max, min, abs, isnan
from memory import UnsafePointer

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state struct with .dataPurchasedAirMgr, .dataEnvrn, .dataLoopNodes, etc.)
# - Psychrometrics module (PsyCpAirFnW, PsyHFnTdbW, PsyTdbFnHW, etc.)
# - DataSizing functions (calcDesignSpecificationOutdoorAir, etc.)
# - Utility functions (FindItemInList, SameString, makeUPPER, etc.)
# - Error reporting (ShowFatalError, ShowWarningError, ShowSevereError, etc.)
# - Schedule manager (GetScheduleAlwaysOn, GetSchedule, etc.)
# - Node and zone equipment management
# - Availability and contamination balance checks

@export
struct LimitType:
    alias Invalid = -1
    alias None = 0
    alias FlowRate = 1
    alias Capacity = 2
    alias FlowRateAndCapacity = 3
    alias Num = 4

@export
struct HumControl:
    alias Invalid = -1
    alias None = 0
    alias ConstantSensibleHeatRatio = 1
    alias Humidistat = 2
    alias ConstantSupplyHumidityRatio = 3
    alias Num = 4

@export
struct DCV:
    alias Invalid = -1
    alias None = 0
    alias OccupancySchedule = 1
    alias CO2SetPoint = 2
    alias Num = 3

@export
struct Econ:
    alias Invalid = -1
    alias NoEconomizer = 0
    alias DifferentialDryBulb = 1
    alias DifferentialEnthalpy = 2
    alias Num = 3

@export
struct HeatRecovery:
    alias Invalid = -1
    alias None = 0
    alias Sensible = 1
    alias Enthalpy = 2
    alias Num = 3

@export
struct OpMode:
    alias Invalid = -1
    alias Off = 0
    alias Heat = 1
    alias Cool = 2
    alias DeadBand = 3
    alias Num = 4

@export
@dataclass
struct ZonePurchasedAir:
    var cObjectName: String
    var Name: String
    var availSched: UnsafePointer[UInt8]
    var ZoneSupplyAirNodeNum: Int32
    var ZoneExhaustAirNodeNum: Int32
    var PlenumExhaustAirNodeNum: Int32
    var ReturnPlenumIndex: Int32
    var PurchAirArrayIndex: Int32
    var ReturnPlenumName: String
    var ZoneRecircAirNodeNum: Int32
    var MaxHeatSuppAirTemp: Float64
    var MinCoolSuppAirTemp: Float64
    var MaxHeatSuppAirHumRat: Float64
    var MinCoolSuppAirHumRat: Float64
    var HeatingLimit: Int32
    var MaxHeatVolFlowRate: Float64
    var MaxHeatSensCap: Float64
    var CoolingLimit: Int32
    var MaxCoolVolFlowRate: Float64
    var MaxCoolTotCap: Float64
    var heatAvailSched: UnsafePointer[UInt8]
    var coolAvailSched: UnsafePointer[UInt8]
    var DehumidCtrlType: Int32
    var CoolSHR: Float64
    var HumidCtrlType: Int32
    var OARequirementsPtr: Int32
    var DCVType: Int32
    var EconomizerType: Int32
    var OutdoorAir: Bool
    var OutdoorAirNodeNum: Int32
    var HtRecType: Int32
    var HtRecSenEff: Float64
    var HtRecLatEff: Float64
    var oaFlowFracSched: UnsafePointer[UInt8]
    var MaxHeatMassFlowRate: Float64
    var MaxCoolMassFlowRate: Float64
    var EMSOverrideMdotOn: Bool
    var EMSValueMassFlowRate: Float64
    var EMSOverrideOAMdotOn: Bool
    var EMSValueOAMassFlowRate: Float64
    var EMSOverrideSupplyTempOn: Bool
    var EMSValueSupplyTemp: Float64
    var EMSOverrideSupplyHumRatOn: Bool
    var EMSValueSupplyHumRat: Float64
    var MinOAMassFlowRate: Float64
    var OutdoorAirMassFlowRate: Float64
    var OutdoorAirVolFlowRateStdRho: Float64
    var SupplyAirMassFlowRate: Float64
    var SupplyAirVolFlowRateStdRho: Float64
    var HtRecSenOutput: Float64
    var HtRecLatOutput: Float64
    var OASenOutput: Float64
    var OALatOutput: Float64
    var SenOutputToZone: Float64
    var LatOutputToZone: Float64
    var SenCoilLoad: Float64
    var LatCoilLoad: Float64
    var OAFlowMaxCoolOutputError: Int32
    var OAFlowMaxHeatOutputError: Int32
    var SaturationOutputError: Int32
    var OAFlowMaxCoolOutputIndex: Int32
    var OAFlowMaxHeatOutputIndex: Int32
    var SaturationOutputIndex: Int32
    var availStatus: Int32
    var CoolErrIndex: Int32
    var HeatErrIndex: Int32
    var SenHeatEnergy: Float64
    var LatHeatEnergy: Float64
    var TotHeatEnergy: Float64
    var SenCoolEnergy: Float64
    var LatCoolEnergy: Float64
    var TotCoolEnergy: Float64
    var ZoneSenHeatEnergy: Float64
    var ZoneLatHeatEnergy: Float64
    var ZoneTotHeatEnergy: Float64
    var ZoneSenCoolEnergy: Float64
    var ZoneLatCoolEnergy: Float64
    var ZoneTotCoolEnergy: Float64
    var OASenHeatEnergy: Float64
    var OALatHeatEnergy: Float64
    var OATotHeatEnergy: Float64
    var OASenCoolEnergy: Float64
    var OALatCoolEnergy: Float64
    var OATotCoolEnergy: Float64
    var HtRecSenHeatEnergy: Float64
    var HtRecLatHeatEnergy: Float64
    var HtRecTotHeatEnergy: Float64
    var HtRecSenCoolEnergy: Float64
    var HtRecLatCoolEnergy: Float64
    var HtRecTotCoolEnergy: Float64
    var SenHeatRate: Float64
    var LatHeatRate: Float64
    var TotHeatRate: Float64
    var SenCoolRate: Float64
    var LatCoolRate: Float64
    var TotCoolRate: Float64
    var ZoneSenHeatRate: Float64
    var ZoneLatHeatRate: Float64
    var ZoneTotHeatRate: Float64
    var ZoneSenCoolRate: Float64
    var ZoneLatCoolRate: Float64
    var ZoneTotCoolRate: Float64
    var OASenHeatRate: Float64
    var OALatHeatRate: Float64
    var OATotHeatRate: Float64
    var OASenCoolRate: Float64
    var OALatCoolRate: Float64
    var OATotCoolRate: Float64
    var HtRecSenHeatRate: Float64
    var HtRecLatHeatRate: Float64
    var HtRecTotHeatRate: Float64
    var HtRecSenCoolRate: Float64
    var HtRecLatCoolRate: Float64
    var HtRecTotCoolRate: Float64
    var TimeEconoActive: Float64
    var TimeHtRecActive: Float64
    var ZonePtr: Int32
    var HVACSizingIndex: Int32
    var SupplyTemp: Float64
    var SupplyHumRat: Float64
    var MixedAirTemp: Float64
    var MixedAirHumRat: Float64
    var heatFuelEffSched: UnsafePointer[UInt8]
    var coolFuelEffSched: UnsafePointer[UInt8]
    var ZoneTotHeatFuelRate: Float64
    var ZoneTotCoolFuelRate: Float64
    var ZoneTotHeatFuelEnergy: Float64
    var ZoneTotCoolFuelEnergy: Float64
    var TotHeatFuelRate: Float64
    var TotCoolFuelRate: Float64
    var TotHeatFuelEnergy: Float64
    var TotCoolFuelEnergy: Float64
    var heatingFuelType: Int32
    var coolingFuelType: Int32

    fn __init__(inout self):
        self.cObjectName = String()
        self.Name = String()
        self.availSched = UnsafePointer[UInt8]()
        self.ZoneSupplyAirNodeNum = 0
        self.ZoneExhaustAirNodeNum = 0
        self.PlenumExhaustAirNodeNum = 0
        self.ReturnPlenumIndex = 0
        self.PurchAirArrayIndex = 0
        self.ReturnPlenumName = String()
        self.ZoneRecircAirNodeNum = 0
        self.MaxHeatSuppAirTemp = 0.0
        self.MinCoolSuppAirTemp = 0.0
        self.MaxHeatSuppAirHumRat = 0.0
        self.MinCoolSuppAirHumRat = 0.0
        self.HeatingLimit = LimitType.Invalid
        self.MaxHeatVolFlowRate = 0.0
        self.MaxHeatSensCap = 0.0
        self.CoolingLimit = LimitType.Invalid
        self.MaxCoolVolFlowRate = 0.0
        self.MaxCoolTotCap = 0.0
        self.heatAvailSched = UnsafePointer[UInt8]()
        self.coolAvailSched = UnsafePointer[UInt8]()
        self.DehumidCtrlType = HumControl.Invalid
        self.CoolSHR = 0.0
        self.HumidCtrlType = HumControl.Invalid
        self.OARequirementsPtr = 0
        self.DCVType = DCV.Invalid
        self.EconomizerType = Econ.Invalid
        self.OutdoorAir = False
        self.OutdoorAirNodeNum = 0
        self.HtRecType = HeatRecovery.Invalid
        self.HtRecSenEff = 0.0
        self.HtRecLatEff = 0.0
        self.oaFlowFracSched = UnsafePointer[UInt8]()
        self.MaxHeatMassFlowRate = 0.0
        self.MaxCoolMassFlowRate = 0.0
        self.EMSOverrideMdotOn = False
        self.EMSValueMassFlowRate = 0.0
        self.EMSOverrideOAMdotOn = False
        self.EMSValueOAMassFlowRate = 0.0
        self.EMSOverrideSupplyTempOn = False
        self.EMSValueSupplyTemp = 0.0
        self.EMSOverrideSupplyHumRatOn = False
        self.EMSValueSupplyHumRat = 0.0
        self.MinOAMassFlowRate = 0.0
        self.OutdoorAirMassFlowRate = 0.0
        self.OutdoorAirVolFlowRateStdRho = 0.0
        self.SupplyAirMassFlowRate = 0.0
        self.SupplyAirVolFlowRateStdRho = 0.0
        self.HtRecSenOutput = 0.0
        self.HtRecLatOutput = 0.0
        self.OASenOutput = 0.0
        self.OALatOutput = 0.0
        self.SenOutputToZone = 0.0
        self.LatOutputToZone = 0.0
        self.SenCoilLoad = 0.0
        self.LatCoilLoad = 0.0
        self.OAFlowMaxCoolOutputError = 0
        self.OAFlowMaxHeatOutputError = 0
        self.SaturationOutputError = 0
        self.OAFlowMaxCoolOutputIndex = 0
        self.OAFlowMaxHeatOutputIndex = 0
        self.SaturationOutputIndex = 0
        self.availStatus = 0
        self.CoolErrIndex = 0
        self.HeatErrIndex = 0
        self.SenHeatEnergy = 0.0
        self.LatHeatEnergy = 0.0
        self.TotHeatEnergy = 0.0
        self.SenCoolEnergy = 0.0
        self.LatCoolEnergy = 0.0
        self.TotCoolEnergy = 0.0
        self.ZoneSenHeatEnergy = 0.0
        self.ZoneLatHeatEnergy = 0.0
        self.ZoneTotHeatEnergy = 0.0
        self.ZoneSenCoolEnergy = 0.0
        self.ZoneLatCoolEnergy = 0.0
        self.ZoneTotCoolEnergy = 0.0
        self.OASenHeatEnergy = 0.0
        self.OALatHeatEnergy = 0.0
        self.OATotHeatEnergy = 0.0
        self.OASenCoolEnergy = 0.0
        self.OALatCoolEnergy = 0.0
        self.OATotCoolEnergy = 0.0
        self.HtRecSenHeatEnergy = 0.0
        self.HtRecLatHeatEnergy = 0.0
        self.HtRecTotHeatEnergy = 0.0
        self.HtRecSenCoolEnergy = 0.0
        self.HtRecLatCoolEnergy = 0.0
        self.HtRecTotCoolEnergy = 0.0
        self.SenHeatRate = 0.0
        self.LatHeatRate = 0.0
        self.TotHeatRate = 0.0
        self.SenCoolRate = 0.0
        self.LatCoolRate = 0.0
        self.TotCoolRate = 0.0
        self.ZoneSenHeatRate = 0.0
        self.ZoneLatHeatRate = 0.0
        self.ZoneTotHeatRate = 0.0
        self.ZoneSenCoolRate = 0.0
        self.ZoneLatCoolRate = 0.0
        self.ZoneTotCoolRate = 0.0
        self.OASenHeatRate = 0.0
        self.OALatHeatRate = 0.0
        self.OATotHeatRate = 0.0
        self.OASenCoolRate = 0.0
        self.OALatCoolRate = 0.0
        self.OATotCoolRate = 0.0
        self.HtRecSenHeatRate = 0.0
        self.HtRecLatHeatRate = 0.0
        self.HtRecTotHeatRate = 0.0
        self.HtRecSenCoolRate = 0.0
        self.HtRecLatCoolRate = 0.0
        self.HtRecTotCoolRate = 0.0
        self.TimeEconoActive = 0.0
        self.TimeHtRecActive = 0.0
        self.ZonePtr = 0
        self.HVACSizingIndex = 0
        self.SupplyTemp = 0.0
        self.SupplyHumRat = 0.0
        self.MixedAirTemp = 0.0
        self.MixedAirHumRat = 0.0
        self.heatFuelEffSched = UnsafePointer[UInt8]()
        self.coolFuelEffSched = UnsafePointer[UInt8]()
        self.ZoneTotHeatFuelRate = 0.0
        self.ZoneTotCoolFuelRate = 0.0
        self.ZoneTotHeatFuelEnergy = 0.0
        self.ZoneTotCoolFuelEnergy = 0.0
        self.TotHeatFuelRate = 0.0
        self.TotCoolFuelRate = 0.0
        self.TotHeatFuelEnergy = 0.0
        self.TotCoolFuelEnergy = 0.0
        self.heatingFuelType = 0
        self.coolingFuelType = 0

@export
@dataclass
struct PurchAirNumericFieldData:
    var FieldNames: DynamicVector[String]

    fn __init__(inout self):
        self.FieldNames = DynamicVector[String]()

@export
@dataclass
struct PurchAirPlenumArrayData:
    var NumPurchAir: Int32
    var ReturnPlenumIndex: Int32
    var PurchAirArray: DynamicVector[Int32]
    var IsSimulated: DynamicVector[Bool]

    fn __init__(inout self):
        self.NumPurchAir = 0
        self.ReturnPlenumIndex = 0
        self.PurchAirArray = DynamicVector[Int32]()
        self.IsSimulated = DynamicVector[Bool]()

@export
@dataclass
struct PurchasedAirManagerData:
    var NumPurchAir: Int32
    var NumPlenumArrays: Int32
    var GetPurchAirInputFlag: Bool
    var CheckEquipName: DynamicVector[Bool]
    var PurchAir: DynamicVector[ZonePurchasedAir]
    var PurchAirNumericFields: DynamicVector[PurchAirNumericFieldData]
    var PurchAirPlenumArrays: DynamicVector[PurchAirPlenumArrayData]
    var InitPurchasedAirMyOneTimeFlag: Bool
    var InitPurchasedAirZoneEquipmentListChecked: Bool
    var InitPurchasedAirMyEnvrnFlag: DynamicVector[Bool]
    var InitPurchasedAirMySizeFlag: DynamicVector[Bool]
    var InitPurchasedAirOneTimeUnitInitsDone: DynamicVector[Bool]
    var TempPurchAirPlenumArrays: DynamicVector[PurchAirPlenumArrayData]

    fn __init__(inout self):
        self.NumPurchAir = 0
        self.NumPlenumArrays = 0
        self.GetPurchAirInputFlag = True
        self.CheckEquipName = DynamicVector[Bool]()
        self.PurchAir = DynamicVector[ZonePurchasedAir]()
        self.PurchAirNumericFields = DynamicVector[PurchAirNumericFieldData]()
        self.PurchAirPlenumArrays = DynamicVector[PurchAirPlenumArrayData]()
        self.InitPurchasedAirMyOneTimeFlag = True
        self.InitPurchasedAirZoneEquipmentListChecked = False
        self.InitPurchasedAirMyEnvrnFlag = DynamicVector[Bool]()
        self.InitPurchasedAirMySizeFlag = DynamicVector[Bool]()
        self.InitPurchasedAirOneTimeUnitInitsDone = DynamicVector[Bool]()
        self.TempPurchAirPlenumArrays = DynamicVector[PurchAirPlenumArrayData]()

alias SMALL_DELTA_HUM_RAT = 0.00025
alias LIMIT_TYPE_NAMES = InlineArray[StringLiteral, 4]("NoLimit", "LimitFlowRate", "LimitCapacity", "LimitFlowRateAndCapacity")
alias LIMIT_TYPE_NAMES_UC = InlineArray[StringLiteral, 4]("NOLIMIT", "LIMITFLOWRATE", "LIMITCAPACITY", "LIMITFLOWRATEANDCAPACITY")
alias HUM_CONTROL_NAMES = InlineArray[StringLiteral, 4]("None", "ConstantSensibleHeatRatio", "Humidistat", "ConstantSupplyHumidityRatio")
alias HUM_CONTROL_NAMES_UC = InlineArray[StringLiteral, 4]("NONE", "CONSTANTSENSIBLEHEATRATIO", "HUMIDISTAT", "CONSTANTSUPPLYHUMIDITYRATIO")
alias DCV_NAMES = InlineArray[StringLiteral, 3]("None", "OccupancySchedule", "CO2SetPoint")
alias DCV_NAMES_UC = InlineArray[StringLiteral, 3]("NONE", "OCCUPANCYSCHEDULE", "CO2SETPOINT")
alias ECON_NAMES = InlineArray[StringLiteral, 3]("NoEconomizer", "DifferentialDryBulb", "DifferentialEnthalpy")
alias ECON_NAMES_UC = InlineArray[StringLiteral, 3]("NOECONOMIZER", "DIFFERENTIALDRYBULB", "DIFFERENTIALENTHALPY")
alias HEAT_RECOVERY_NAMES = InlineArray[StringLiteral, 3]("None", "Sensible", "Enthalpy")
alias HEAT_RECOVERY_NAMES_UC = InlineArray[StringLiteral, 3]("NONE", "SENSIBLE", "ENTHALPY")

@export
fn sim_purchased_air(state: UnsafePointer[UInt8], purch_air_name: String, controlled_zone_num: Int32) -> (Float64, Float64, Int32):
    """Manages Purchased Air component simulation."""
    return (0.0, 0.0, 0)

@export
fn get_purchased_air(state: UnsafePointer[UInt8]):
    """Get input data for Purchased Air objects."""
    pass

@export
fn init_purchased_air(state: UnsafePointer[UInt8], purch_air_num: Int32, controlled_zone_num: Int32):
    """Initialize PurchAir data structure."""
    pass

@export
fn size_purchased_air(state: UnsafePointer[UInt8], purch_air_num: Int32):
    """Size Purchased Air components."""
    pass

@export
fn calc_purch_air_loads(state: UnsafePointer[UInt8], purch_air_num: Int32, controlled_zone_num: Int32) -> (Float64, Float64):
    """Calculate loads for purchased air system."""
    return (0.0, 0.0)

@export
fn calc_purch_air_min_oa_mass_flow(state: UnsafePointer[UInt8], purch_air_num: Int32, zone_num: Int32) -> Float64:
    """Calculate minimum outdoor air mass flow rate."""
    return 0.0

@export
fn calc_purch_air_mixed_air(state: UnsafePointer[UInt8], purch_air_num: Int32, oa_mass_flow_rate: Float64, supply_mass_flow_rate: Float64, operating_mode: Int32) -> (Float64, Float64, Float64):
    """Calculate mixed air conditions accounting for heat recovery."""
    return (0.0, 0.0, 0.0)

@export
fn update_purchased_air(state: UnsafePointer[UInt8], purch_air_num: Int32, first_hvac_iteration: Bool):
    """Update node data for Ideal Loads system."""
    pass

@export
fn report_purchased_air(state: UnsafePointer[UInt8], purch_air_num: Int32):
    """Calculate report variables."""
    pass

@export
fn get_purchased_air_out_air_mass_flow(state: UnsafePointer[UInt8], purch_air_num: Int32) -> Float64:
    """Lookup function for OA inlet mass flow."""
    return 0.0

@export
fn get_purchased_air_zone_inlet_air_node(state: UnsafePointer[UInt8], purch_air_num: Int32) -> Int32:
    """Lookup function for zone inlet node."""
    return 0

@export
fn get_purchased_air_return_air_node(state: UnsafePointer[UInt8], purch_air_num: Int32) -> Int32:
    """Lookup function for recirculation air node."""
    return 0

@export
fn get_purchased_air_index(state: UnsafePointer[UInt8], purch_air_name: String) -> Int32:
    """Lookup function for purchased air index by name."""
    return 0

@export
fn get_purchased_air_mixed_air_temp(state: UnsafePointer[UInt8], purch_air_num: Int32) -> Float64:
    """Lookup function for mixed air temperature."""
    return 0.0

@export
fn get_purchased_air_mixed_air_hum_rat(state: UnsafePointer[UInt8], purch_air_num: Int32) -> Float64:
    """Lookup function for mixed air humidity ratio."""
    return 0.0

@export
fn check_purchased_air_for_return_plenum(state: UnsafePointer[UInt8], return_plenum_index: Int32) -> Bool:
    """Check if return plenum is used."""
    return False

@export
fn initialize_plenum_arrays(state: UnsafePointer[UInt8], purch_air_num: Int32):
    """Initialize arrays for managing ideal load air systems with return plenums."""
    pass

fn find_item_in_list(name: String, name_list: DynamicVector[String]) -> Int32:
    """Find index of item in list (1-based)."""
    for i in range(name_list.size):
        if name.upper() == name_list[i].upper():
            return i.__int__() + 1
    return 0
