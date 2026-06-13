from dataclasses import dataclass, field
from typing import List, Protocol, Optional, Any
from enum import IntEnum
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object with .dataPurchasedAirMgr, .dataEnvrn, .dataLoopNodes, etc.)
# - Psychrometrics module (PsyCpAirFnW, PsyHFnTdbW, PsyTdbFnHW, etc.)
# - DataSizing functions (calcDesignSpecificationOutdoorAir, etc.)
# - Utility functions (FindItemInList, SameString, makeUPPER, etc.)
# - Error reporting (ShowFatalError, ShowWarningError, ShowSevereError, etc.)
# - Schedule manager (GetScheduleAlwaysOn, GetSchedule, etc.)
# - Node and zone equipment management
# - Availability and contamination balance checks

class LimitType(IntEnum):
    Invalid = -1
    None_Val = 0
    FlowRate = 1
    Capacity = 2
    FlowRateAndCapacity = 3
    Num = 4

class HumControl(IntEnum):
    Invalid = -1
    None_Val = 0
    ConstantSensibleHeatRatio = 1
    Humidistat = 2
    ConstantSupplyHumidityRatio = 3
    Num = 4

class DCV(IntEnum):
    Invalid = -1
    None_Val = 0
    OccupancySchedule = 1
    CO2SetPoint = 2
    Num = 3

class Econ(IntEnum):
    Invalid = -1
    NoEconomizer = 0
    DifferentialDryBulb = 1
    DifferentialEnthalpy = 2
    Num = 3

class HeatRecovery(IntEnum):
    Invalid = -1
    None_Val = 0
    Sensible = 1
    Enthalpy = 2
    Num = 3

class OpMode(IntEnum):
    Invalid = -1
    Off = 0
    Heat = 1
    Cool = 2
    DeadBand = 3
    Num = 4

@dataclass
class ZonePurchasedAir:
    cObjectName: str = ""
    Name: str = ""
    availSched: Optional[Any] = None
    ZoneSupplyAirNodeNum: int = 0
    ZoneExhaustAirNodeNum: int = 0
    PlenumExhaustAirNodeNum: int = 0
    ReturnPlenumIndex: int = 0
    PurchAirArrayIndex: int = 0
    ReturnPlenumName: str = ""
    ZoneRecircAirNodeNum: int = 0
    MaxHeatSuppAirTemp: float = 0.0
    MinCoolSuppAirTemp: float = 0.0
    MaxHeatSuppAirHumRat: float = 0.0
    MinCoolSuppAirHumRat: float = 0.0
    HeatingLimit: LimitType = LimitType.Invalid
    MaxHeatVolFlowRate: float = 0.0
    MaxHeatSensCap: float = 0.0
    CoolingLimit: LimitType = LimitType.Invalid
    MaxCoolVolFlowRate: float = 0.0
    MaxCoolTotCap: float = 0.0
    heatAvailSched: Optional[Any] = None
    coolAvailSched: Optional[Any] = None
    DehumidCtrlType: HumControl = HumControl.Invalid
    CoolSHR: float = 0.0
    HumidCtrlType: HumControl = HumControl.Invalid
    OARequirementsPtr: int = 0
    DCVType: DCV = DCV.Invalid
    EconomizerType: Econ = Econ.Invalid
    OutdoorAir: bool = False
    OutdoorAirNodeNum: int = 0
    HtRecType: HeatRecovery = HeatRecovery.Invalid
    HtRecSenEff: float = 0.0
    HtRecLatEff: float = 0.0
    oaFlowFracSched: Optional[Any] = None
    MaxHeatMassFlowRate: float = 0.0
    MaxCoolMassFlowRate: float = 0.0
    EMSOverrideMdotOn: bool = False
    EMSValueMassFlowRate: float = 0.0
    EMSOverrideOAMdotOn: bool = False
    EMSValueOAMassFlowRate: float = 0.0
    EMSOverrideSupplyTempOn: bool = False
    EMSValueSupplyTemp: float = 0.0
    EMSOverrideSupplyHumRatOn: bool = False
    EMSValueSupplyHumRat: float = 0.0
    MinOAMassFlowRate: float = 0.0
    OutdoorAirMassFlowRate: float = 0.0
    OutdoorAirVolFlowRateStdRho: float = 0.0
    SupplyAirMassFlowRate: float = 0.0
    SupplyAirVolFlowRateStdRho: float = 0.0
    HtRecSenOutput: float = 0.0
    HtRecLatOutput: float = 0.0
    OASenOutput: float = 0.0
    OALatOutput: float = 0.0
    SenOutputToZone: float = 0.0
    LatOutputToZone: float = 0.0
    SenCoilLoad: float = 0.0
    LatCoilLoad: float = 0.0
    OAFlowMaxCoolOutputError: int = 0
    OAFlowMaxHeatOutputError: int = 0
    SaturationOutputError: int = 0
    OAFlowMaxCoolOutputIndex: int = 0
    OAFlowMaxHeatOutputIndex: int = 0
    SaturationOutputIndex: int = 0
    availStatus: int = 0
    CoolErrIndex: int = 0
    HeatErrIndex: int = 0
    SenHeatEnergy: float = 0.0
    LatHeatEnergy: float = 0.0
    TotHeatEnergy: float = 0.0
    SenCoolEnergy: float = 0.0
    LatCoolEnergy: float = 0.0
    TotCoolEnergy: float = 0.0
    ZoneSenHeatEnergy: float = 0.0
    ZoneLatHeatEnergy: float = 0.0
    ZoneTotHeatEnergy: float = 0.0
    ZoneSenCoolEnergy: float = 0.0
    ZoneLatCoolEnergy: float = 0.0
    ZoneTotCoolEnergy: float = 0.0
    OASenHeatEnergy: float = 0.0
    OALatHeatEnergy: float = 0.0
    OATotHeatEnergy: float = 0.0
    OASenCoolEnergy: float = 0.0
    OALatCoolEnergy: float = 0.0
    OATotCoolEnergy: float = 0.0
    HtRecSenHeatEnergy: float = 0.0
    HtRecLatHeatEnergy: float = 0.0
    HtRecTotHeatEnergy: float = 0.0
    HtRecSenCoolEnergy: float = 0.0
    HtRecLatCoolEnergy: float = 0.0
    HtRecTotCoolEnergy: float = 0.0
    SenHeatRate: float = 0.0
    LatHeatRate: float = 0.0
    TotHeatRate: float = 0.0
    SenCoolRate: float = 0.0
    LatCoolRate: float = 0.0
    TotCoolRate: float = 0.0
    ZoneSenHeatRate: float = 0.0
    ZoneLatHeatRate: float = 0.0
    ZoneTotHeatRate: float = 0.0
    ZoneSenCoolRate: float = 0.0
    ZoneLatCoolRate: float = 0.0
    ZoneTotCoolRate: float = 0.0
    OASenHeatRate: float = 0.0
    OALatHeatRate: float = 0.0
    OATotHeatRate: float = 0.0
    OASenCoolRate: float = 0.0
    OALatCoolRate: float = 0.0
    OATotCoolRate: float = 0.0
    HtRecSenHeatRate: float = 0.0
    HtRecLatHeatRate: float = 0.0
    HtRecTotHeatRate: float = 0.0
    HtRecSenCoolRate: float = 0.0
    HtRecLatCoolRate: float = 0.0
    HtRecTotCoolRate: float = 0.0
    TimeEconoActive: float = 0.0
    TimeHtRecActive: float = 0.0
    ZonePtr: int = 0
    HVACSizingIndex: int = 0
    SupplyTemp: float = 0.0
    SupplyHumRat: float = 0.0
    MixedAirTemp: float = 0.0
    MixedAirHumRat: float = 0.0
    heatFuelEffSched: Optional[Any] = None
    coolFuelEffSched: Optional[Any] = None
    ZoneTotHeatFuelRate: float = 0.0
    ZoneTotCoolFuelRate: float = 0.0
    ZoneTotHeatFuelEnergy: float = 0.0
    ZoneTotCoolFuelEnergy: float = 0.0
    TotHeatFuelRate: float = 0.0
    TotCoolFuelRate: float = 0.0
    TotHeatFuelEnergy: float = 0.0
    TotCoolFuelEnergy: float = 0.0
    heatingFuelType: int = 0
    coolingFuelType: int = 0

@dataclass
class PurchAirNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)

@dataclass
class PurchAirPlenumArrayData:
    NumPurchAir: int = 0
    ReturnPlenumIndex: int = 0
    PurchAirArray: List[int] = field(default_factory=list)
    IsSimulated: List[bool] = field(default_factory=list)

@dataclass
class PurchasedAirManagerData:
    NumPurchAir: int = 0
    NumPlenumArrays: int = 0
    GetPurchAirInputFlag: bool = True
    CheckEquipName: List[bool] = field(default_factory=list)
    PurchAir: List[ZonePurchasedAir] = field(default_factory=list)
    PurchAirNumericFields: List[PurchAirNumericFieldData] = field(default_factory=list)
    PurchAirPlenumArrays: List[PurchAirPlenumArrayData] = field(default_factory=list)
    InitPurchasedAirMyOneTimeFlag: bool = True
    InitPurchasedAirZoneEquipmentListChecked: bool = False
    InitPurchasedAirMyEnvrnFlag: List[bool] = field(default_factory=list)
    InitPurchasedAirMySizeFlag: List[bool] = field(default_factory=list)
    InitPurchasedAirOneTimeUnitInitsDone: List[bool] = field(default_factory=list)
    TempPurchAirPlenumArrays: List[PurchAirPlenumArrayData] = field(default_factory=list)

SMALL_DELTA_HUM_RAT = 0.00025
LIMIT_TYPE_NAMES = ["NoLimit", "LimitFlowRate", "LimitCapacity", "LimitFlowRateAndCapacity"]
LIMIT_TYPE_NAMES_UC = ["NOLIMIT", "LIMITFLOWRATE", "LIMITCAPACITY", "LIMITFLOWRATEANDCAPACITY"]
HUM_CONTROL_NAMES = ["None", "ConstantSensibleHeatRatio", "Humidistat", "ConstantSupplyHumidityRatio"]
HUM_CONTROL_NAMES_UC = ["NONE", "CONSTANTSENSIBLEHEATRATIO", "HUMIDISTAT", "CONSTANTSUPPLYHUMIDITYRATIO"]
DCV_NAMES = ["None", "OccupancySchedule", "CO2SetPoint"]
DCV_NAMES_UC = ["NONE", "OCCUPANCYSCHEDULE", "CO2SETPOINT"]
ECON_NAMES = ["NoEconomizer", "DifferentialDryBulb", "DifferentialEnthalpy"]
ECON_NAMES_UC = ["NOECONOMIZER", "DIFFERENTIALDRYBULB", "DIFFERENTIALENTHALPY"]
HEAT_RECOVERY_NAMES = ["None", "Sensible", "Enthalpy"]
HEAT_RECOVERY_NAMES_UC = ["NONE", "SENSIBLE", "ENTHALPY"]

def sim_purchased_air(state, purch_air_name: str, controlled_zone_num: int, comp_index: int):
    """Manages Purchased Air component simulation."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    
    if comp_index == 0:
        purch_air_num = find_item_in_list(purch_air_name, [p.Name for p in state.dataPurchasedAirMgr.PurchAir])
        if purch_air_num == 0:
            raise RuntimeError(f"SimPurchasedAir: Unit not found={purch_air_name}")
        comp_index = purch_air_num
    else:
        purch_air_num = comp_index
        if purch_air_num > state.dataPurchasedAirMgr.NumPurchAir or purch_air_num < 1:
            raise RuntimeError(f"SimPurchasedAir: Invalid CompIndex passed={purch_air_num}")
    
    init_purchased_air(state, purch_air_num, controlled_zone_num)
    sys_output_provided, moist_output_provided = calc_purch_air_loads(state, purch_air_num, controlled_zone_num)
    update_purchased_air(state, purch_air_num, True)
    report_purchased_air(state, purch_air_num)
    
    return sys_output_provided, moist_output_provided, comp_index

def get_purchased_air(state):
    """Get input data for Purchased Air objects."""
    s_ipsc = state.dataIPShortCut
    s_ipsc.cCurrentModuleObject = "ZoneHVAC:IdealLoadsAirSystem"
    state.dataPurchasedAirMgr.NumPurchAir = len([x for x in state.dataInputProcessing.get_objects(s_ipsc.cCurrentModuleObject, state)])
    
    state.dataPurchasedAirMgr.PurchAir = [ZonePurchasedAir() for _ in range(state.dataPurchasedAirMgr.NumPurchAir)]
    state.dataPurchasedAirMgr.CheckEquipName = [True] * state.dataPurchasedAirMgr.NumPurchAir
    state.dataPurchasedAirMgr.PurchAirNumericFields = [PurchAirNumericFieldData() for _ in range(state.dataPurchasedAirMgr.NumPurchAir)]

def init_purchased_air(state, purch_air_num: int, controlled_zone_num: int):
    """Initialize PurchAir data structure."""
    if state.dataPurchasedAirMgr.InitPurchasedAirMyOneTimeFlag:
        state.dataPurchasedAirMgr.InitPurchasedAirMyEnvrnFlag = [True] * state.dataPurchasedAirMgr.NumPurchAir
        state.dataPurchasedAirMgr.InitPurchasedAirMySizeFlag = [True] * state.dataPurchasedAirMgr.NumPurchAir
        state.dataPurchasedAirMgr.InitPurchasedAirOneTimeUnitInitsDone = [False] * state.dataPurchasedAirMgr.NumPurchAir
        state.dataPurchasedAirMgr.InitPurchasedAirMyOneTimeFlag = False

def size_purchased_air(state, purch_air_num: int):
    """Size Purchased Air components."""
    pass

def calc_purch_air_loads(state, purch_air_num: int, controlled_zone_num: int):
    """Calculate loads for purchased air system."""
    purch_air = state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1]
    sys_output_provided = 0.0
    moist_output_provided = 0.0
    return sys_output_provided, moist_output_provided

def calc_purch_air_min_oa_mass_flow(state, purch_air_num: int, zone_num: int):
    """Calculate minimum outdoor air mass flow rate."""
    purch_air = state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1]
    oa_mass_flow_rate = 0.0
    if purch_air.OutdoorAir:
        oa_mass_flow_rate = 0.0
    purch_air.MinOAMassFlowRate = oa_mass_flow_rate
    return oa_mass_flow_rate

def calc_purch_air_mixed_air(state, purch_air_num: int, oa_mass_flow_rate: float, supply_mass_flow_rate: float, operating_mode: OpMode):
    """Calculate mixed air conditions accounting for heat recovery."""
    purch_air = state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1]
    mixed_air_temp = 0.0
    mixed_air_hum_rat = 0.0
    mixed_air_enthalpy = 0.0
    return mixed_air_temp, mixed_air_hum_rat, mixed_air_enthalpy

def update_purchased_air(state, purch_air_num: int, first_hvac_iteration: bool):
    """Update node data for Ideal Loads system."""
    pass

def report_purchased_air(state, purch_air_num: int):
    """Calculate report variables."""
    purch_air = state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1]
    purch_air.SenHeatRate = max(purch_air.SenCoilLoad, 0.0)
    purch_air.SenCoolRate = abs(min(purch_air.SenCoilLoad, 0.0))

def get_purchased_air_out_air_mass_flow(state, purch_air_num: int) -> float:
    """Lookup function for OA inlet mass flow."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    return state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1].OutdoorAirMassFlowRate

def get_purchased_air_zone_inlet_air_node(state, purch_air_num: int) -> int:
    """Lookup function for zone inlet node."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    if 0 < purch_air_num <= state.dataPurchasedAirMgr.NumPurchAir:
        return state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1].ZoneSupplyAirNodeNum
    return 0

def get_purchased_air_return_air_node(state, purch_air_num: int) -> int:
    """Lookup function for recirculation air node."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    if 0 < purch_air_num <= state.dataPurchasedAirMgr.NumPurchAir:
        return state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1].ZoneRecircAirNodeNum
    return 0

def get_purchased_air_index(state, purch_air_name: str) -> int:
    """Lookup function for purchased air index by name."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    for i, purch_air in enumerate(state.dataPurchasedAirMgr.PurchAir):
        if purch_air.Name.upper() == purch_air_name.upper():
            return i + 1
    return 0

def get_purchased_air_mixed_air_temp(state, purch_air_num: int) -> float:
    """Lookup function for mixed air temperature."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    return state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1].MixedAirTemp

def get_purchased_air_mixed_air_hum_rat(state, purch_air_num: int) -> float:
    """Lookup function for mixed air humidity ratio."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    return state.dataPurchasedAirMgr.PurchAir[purch_air_num - 1].MixedAirHumRat

def check_purchased_air_for_return_plenum(state, return_plenum_index: int) -> bool:
    """Check if return plenum is used."""
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        get_purchased_air(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
    for purch_air in state.dataPurchasedAirMgr.PurchAir:
        if purch_air.ReturnPlenumIndex == return_plenum_index:
            return True
    return False

def initialize_plenum_arrays(state, purch_air_num: int):
    """Initialize arrays for managing ideal load air systems with return plenums."""
    pass

def find_item_in_list(name: str, name_list: List[str]) -> int:
    """Find index of item in list (1-based)."""
    for i, item in enumerate(name_list):
        if item.upper() == name.upper():
            return i + 1
    return 0
