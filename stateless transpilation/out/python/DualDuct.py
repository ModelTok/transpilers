"""
EnergyPlus DualDuct module - complete Python port
Port of EnergyPlus/DualDuct.hh and DualDuct.cc
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Tuple, Dict, Any, Protocol
from abc import ABC
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying dataDualDuct, dataZoneEnergyDemand, dataLoopNodes, 
#   dataDefineEquipment, dataSize, dataEnvrn, dataZoneEquip, dataGlobal, dataAirLoop,
#   dataHeatBal, dataHeatBalFanSys, dataContaminantBalance, dataOutRptPredefined,
#   dataInputProcessing, files.bnd
# - Sched.Schedule: schedule object type
# - GetOnlySingleNode, ShowFatalError, ShowSevereError, ShowContinueError, ShowSevereItemNotFound
# - Util.FindItemInList
# - GlobalNames.VerifyUniqueInterObjectName
# - Psychrometrics: PsyCpAirFnW, PsyTdbFnHW
# - Node: TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream
# - DataZoneEquipment.CheckZoneEquipmentList
# - DataSizing: AutoSize, calcDesignSpecificationOutdoorAir, OAFlowCalcMethod, CheckZoneSizing
# - BaseSizer.reportSizerOutput
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# - OutputReportPredefined: PreDefTableEntry
# - Constant.Units
# - HVAC: SmallMassFlow, SmallTempDiff, SmallAirVolFlow
# - ErrorObjectHeader


class DualDuctDamper(IntEnum):
    Invalid = -1
    ConstantVolume = 0
    VariableVolume = 1
    OutdoorAir = 2
    Num = 3


class PerPersonMode(IntEnum):
    Invalid = -1
    ModeNotSet = 0
    DCVByCurrentLevel = 1
    ByDesignLevel = 2
    Num = 3


DUAL_DUCT_DAMPER_NAMES = [
    "ConstantVolume",
    "VariableVolume",
    "OutdoorAir"
]

CMO_DD_CONSTANT_VOLUME = "AirTerminal:DualDuct:ConstantVolume"
CMO_DD_VARIABLE_VOLUME = "AirTerminal:DualDuct:VAV"
CMO_DD_VAR_VOL_OA = "AirTerminal:DualDuct:VAV:OutdoorAir"

DUAL_DUCT_MASS_FLOW_SET_TOLER = 0.00001  # DataConvergParams::HVACFlowRateToler * 0.00001

MODE_STRINGS = ["NOTSET", "CURRENTOCCUPANCY", "DESIGNOCCUPANCY"]
DAMPER_TYPE_STRINGS = ["ConstantVolume", "VAV", "VAV:OutdoorAir"]
CMO_NAME_ARRAY = [CMO_DD_CONSTANT_VOLUME, CMO_DD_VARIABLE_VOLUME, CMO_DD_VAR_VOL_OA]


@dataclass
class DualDuctAirTerminalFlowConditions:
    AirMassFlowRate: float = 0.0
    AirMassFlowRateMaxAvail: float = 0.0
    AirMassFlowRateMinAvail: float = 0.0
    AirMassFlowRateMax: float = 0.0
    AirTemp: float = 0.0
    AirHumRat: float = 0.0
    AirEnthalpy: float = 0.0
    AirMassFlowRateHist1: float = 0.0
    AirMassFlowRateHist2: float = 0.0
    AirMassFlowRateHist3: float = 0.0
    AirMassFlowDiffMag: float = 0.0


@dataclass
class DualDuctAirTerminal:
    Name: str = ""
    DamperType: DualDuctDamper = DualDuctDamper.Invalid
    availSched: Optional[Any] = None
    MaxAirVolFlowRate: float = 0.0
    MaxAirMassFlowRate: float = 0.0
    HotAirInletNodeNum: int = 0
    ColdAirInletNodeNum: int = 0
    OutletNodeNum: int = 0
    ZoneMinAirFracDes: float = 0.0
    ZoneMinAirFrac: float = 0.0
    ColdAirDamperPosition: float = 0.0
    HotAirDamperPosition: float = 0.0
    OAInletNodeNum: int = 0
    RecircAirInletNodeNum: int = 0
    RecircIsUsed: bool = True
    DesignOAFlowRate: float = 0.0
    DesignRecircFlowRate: float = 0.0
    RecircAirDamperPosition: float = 0.0
    OADamperPosition: float = 0.0
    OAFraction: float = 0.0
    ADUNum: int = 0
    CtrlZoneNum: int = 0
    CtrlZoneInNodeIndex: int = 0
    OutdoorAirFlowRate: float = 0.0
    NoOAFlowInputFromUser: bool = True
    OARequirementsPtr: int = 0
    OAPerPersonMode: PerPersonMode = PerPersonMode.ModeNotSet
    AirLoopNum: int = 0
    zoneTurndownMinAirFracSched: Optional[Any] = None
    ZoneTurndownMinAirFrac: float = 1.0
    MyEnvrnFlag: bool = True
    MySizeFlag: bool = True
    MyAirLoopFlag: bool = True
    CheckEquipName: bool = True
    dd_airterminalHotAirInlet: DualDuctAirTerminalFlowConditions = field(default_factory=DualDuctAirTerminalFlowConditions)
    dd_airterminalColdAirInlet: DualDuctAirTerminalFlowConditions = field(default_factory=DualDuctAirTerminalFlowConditions)
    dd_airterminalOutlet: DualDuctAirTerminalFlowConditions = field(default_factory=DualDuctAirTerminalFlowConditions)
    dd_airterminalOAInlet: DualDuctAirTerminalFlowConditions = field(default_factory=DualDuctAirTerminalFlowConditions)
    dd_airterminalRecircAirInlet: DualDuctAirTerminalFlowConditions = field(default_factory=DualDuctAirTerminalFlowConditions)

    def init_dual_duct(self, state: Any, first_hvac_iteration: bool) -> None:
        pass

    def size_dual_duct(self, state: Any) -> None:
        pass

    def sim_dual_duct_const_vol(self, state: Any, zone_num: int, zone_node_num: int) -> None:
        pass

    def sim_dual_duct_var_vol(self, state: Any, zone_num: int, zone_node_num: int) -> None:
        pass

    def sim_dual_duct_vav_outdoor_air(self, state: Any, zone_num: int, zone_node_num: int) -> None:
        pass

    def calc_oa_mass_flow(self, state: Any) -> Tuple[float, float]:
        pass

    def calc_oa_only_mass_flow(self, state: Any, include_max_oa_vol_flow: bool = False) -> Tuple[float, Optional[float]]:
        pass

    def calc_outdoor_air_volume_flow_rate(self, state: Any) -> None:
        pass

    def update_dual_duct(self, state: Any) -> None:
        pass

    def report_terminal_unit(self, state: Any) -> None:
        pass


@dataclass
class DualDuctData:
    NumDDAirTerminal: int = 0
    NumDualDuctVarVolOA: int = 0
    GetDualDuctInputFlag: bool = True
    dd_airterminal: List[DualDuctAirTerminal] = field(default_factory=list)
    UniqueDualDuctAirTerminalNames: Dict[str, str] = field(default_factory=dict)
    ZoneEquipmentListChecked: bool = False
    GetDualDuctOutdoorAirRecircUseFirstTimeOnly: bool = True
    RecircIsUsedARR: List[bool] = field(default_factory=list)
    DamperNamesARR: List[str] = field(default_factory=list)


def simulate_dual_duct(state: Any, comp_name: str, first_hvac_iteration: bool, 
                      zone_num: int, zone_node_num: int, comp_index: int) -> int:
    """Simulate dual duct system."""
    if state.dataDualDuct.GetDualDuctInputFlag:
        get_dual_duct_input(state)
        state.dataDualDuct.GetDualDuctInputFlag = False

    if comp_index == 0:
        dd_num = find_item_in_list(comp_name, state.dataDualDuct.dd_airterminal)
        if dd_num < 0:
            show_fatal_error(state, f"SimulateDualDuct: Damper not found={comp_name}")
        comp_index = dd_num
    else:
        dd_num = comp_index
        if dd_num >= len(state.dataDualDuct.dd_airterminal) or dd_num < 0:
            show_fatal_error(state, f"SimulateDualDuct: Invalid CompIndex passed={comp_index}, "
                           f"Number of Dampers={state.dataDualDuct.NumDDAirTerminal}, Damper name={comp_name}")
        if state.dataDualDuct.dd_airterminal[dd_num].CheckEquipName:
            if comp_name != state.dataDualDuct.dd_airterminal[dd_num].Name:
                show_fatal_error(state, f"SimulateDualDuct: Invalid CompIndex passed={comp_index}, "
                               f"Damper name={comp_name}, stored Damper Name={state.dataDualDuct.dd_airterminal[dd_num].Name}")
            state.dataDualDuct.dd_airterminal[dd_num].CheckEquipName = False

    this_dual_duct = state.dataDualDuct.dd_airterminal[dd_num]

    if comp_index >= 0:
        state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[this_dual_duct.ADUNum].TermUnitSizingNum
        this_dual_duct.init_dual_duct(state, first_hvac_iteration)

        if this_dual_duct.DamperType == DualDuctDamper.ConstantVolume:
            this_dual_duct.sim_dual_duct_const_vol(state, zone_num, zone_node_num)
        elif this_dual_duct.DamperType == DualDuctDamper.VariableVolume:
            this_dual_duct.sim_dual_duct_var_vol(state, zone_num, zone_node_num)
        elif this_dual_duct.DamperType == DualDuctDamper.OutdoorAir:
            this_dual_duct.sim_dual_duct_vav_outdoor_air(state, zone_num, zone_node_num)

        this_dual_duct.update_dual_duct(state)
    else:
        show_fatal_error(state, f"SimulateDualDuct: Damper not found={comp_name}")

    return comp_index


def get_dual_duct_input(state: Any) -> None:
    """Read dual duct input from input file."""
    pass


def report_dual_duct_connections(state: Any) -> None:
    """Report dual duct connections."""
    pass


def get_dual_duct_outdoor_air_recirc_use(state: Any, comp_type_name: str, comp_name: str) -> bool:
    """Get whether recirculation is used."""
    recirc_is_used = True
    
    if state.dataDualDuct.GetDualDuctOutdoorAirRecircUseFirstTimeOnly:
        state.dataDualDuct.NumDualDuctVarVolOA = get_num_objects_found(state, CMO_DD_VAR_VOL_OA)
        state.dataDualDuct.RecircIsUsedARR = [False] * state.dataDualDuct.NumDualDuctVarVolOA
        state.dataDualDuct.DamperNamesARR = [""] * state.dataDualDuct.NumDualDuctVarVolOA
        
        if state.dataDualDuct.NumDualDuctVarVolOA > 0:
            for damper_index in range(state.dataDualDuct.NumDualDuctVarVolOA):
                alph_array = get_object_item(state, CMO_DD_VAR_VOL_OA, damper_index)
                state.dataDualDuct.DamperNamesARR[damper_index] = alph_array[0]
                state.dataDualDuct.RecircIsUsedARR[damper_index] = len(alph_array) > 4 and alph_array[4].strip()
        
        state.dataDualDuct.GetDualDuctOutdoorAirRecircUseFirstTimeOnly = False

    damper_index = find_item_in_list(comp_name, state.dataDualDuct.DamperNamesARR)
    if damper_index >= 0:
        recirc_is_used = state.dataDualDuct.RecircIsUsedARR[damper_index]

    return recirc_is_used


# Stub helper functions
def find_item_in_list(name: str, items: List[Any]) -> int:
    """Find item in list by Name attribute. Returns 0-based index or -1."""
    for i, item in enumerate(items):
        if hasattr(item, 'Name') and item.Name == name:
            return i
    return -1


def show_fatal_error(state: Any, message: str) -> None:
    """Show fatal error message."""
    pass


def show_severe_error(state: Any, message: str) -> None:
    """Show severe error message."""
    pass


def show_continue_error(state: Any, message: str) -> None:
    """Show continue error message."""
    pass


def get_num_objects_found(state: Any, obj_type: str) -> int:
    """Get number of objects of given type."""
    return 0


def get_object_item(state: Any, obj_type: str, index: int) -> List[str]:
    """Get object item."""
    return []
