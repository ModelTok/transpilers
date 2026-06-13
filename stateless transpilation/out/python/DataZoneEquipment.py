from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Protocol, Optional, List, Dict, Any
from abc import abstractmethod

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData (state object)
# - Node.ConnectionObjectType, Node.ConnectionType, Node.FluidType, Node.CompFluidStream: from EnergyPlus.DataLoopNode
# - Sched.Schedule, Sched.GetSchedule, Sched.GetScheduleAlwaysOn: from EnergyPlus.ScheduleManager
# - OutputProcessor.MeterData: from EnergyPlus.OutputProcessor
# - HVACSystemData: from EnergyPlus.DataHVACSystems
# - DataZoneEnergyDemands.ZoneSystemSensibleDemand, ZoneSystemMoistureDemand: from EnergyPlus.DataZoneEnergyDemands
# - Avail.Status: from EnergyPlus.DataGlobals
# - ExhaustAirSystemManager.ExhaustAir, ExhaustAirSystemManager.ZoneExhaustControl: from EnergyPlus.ExhaustAirSystemManager


class AirNodeType(Enum):
    INVALID = -1
    PATH_INLET = 0
    COMP_INLET = 1
    INTERMEDIATE = 2
    OUTLET = 3
    NUM = 4


class AirLoopHVACZone(Enum):
    INVALID = -1
    SPLITTER = 0
    SUPPLY_PLENUM = 1
    MIXER = 2
    RETURN_PLENUM = 3
    NUM = 4


AIR_LOOP_HVAC_TYPE_NAMES_CC = [
    "AirLoopHVAC:ZoneSplitter",
    "AirLoopHVAC:SupplyPlenum",
    "AirLoopHVAC:ZoneMixer",
    "AirLoopHVAC:ReturnPlenum",
]

AIR_LOOP_HVAC_TYPE_NAMES_UC = [
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:RETURNPLENUM",
]


class ZoneEquipType(Enum):
    INVALID = -1
    DUMMY = 0
    FOUR_PIPE_FAN_COIL = 1
    PACKAGED_TERMINAL_HEAT_PUMP = 2
    PACKAGED_TERMINAL_AIR_CONDITIONER = 3
    PACKAGED_TERMINAL_HEAT_PUMP_WATER_TO_AIR = 4
    WINDOW_AIR_CONDITIONER = 5
    UNIT_HEATER = 6
    UNIT_VENTILATOR = 7
    ENERGY_RECOVERY_VENTILATOR = 8
    VENTILATED_SLAB = 9
    OUTDOOR_AIR_UNIT = 10
    VARIABLE_REFRIGERANT_FLOW_TERMINAL = 11
    PURCHASED_AIR = 12
    EVAPORATIVE_COOLER = 13
    HYBRID_EVAPORATIVE_COOLER = 14
    AIR_DISTRIBUTION_UNIT = 15
    BASEBOARD_CONVECTIVE_WATER = 16
    BASEBOARD_CONVECTIVE_ELECTRIC = 17
    BASEBOARD_STEAM = 18
    BASEBOARD_WATER = 19
    BASEBOARD_ELECTRIC = 20
    HIGH_TEMPERATURE_RADIANT = 21
    LOW_TEMPERATURE_RADIANT_CONST_FLOW = 22
    LOW_TEMPERATURE_RADIANT_VAR_FLOW = 23
    LOW_TEMPERATURE_RADIANT_ELECTRIC = 24
    EXHAUST_FAN = 25
    HEAT_EXCHANGER = 26
    HEAT_PUMP_WATER_HEATER_PUMPED_CONDENSER = 27
    HEAT_PUMP_WATER_HEATER_WRAPPED_CONDENSER = 28
    DEHUMIDIFIER_DX = 29
    REFRIGERATION_CHILLER_SET = 30
    USER_DEFINED_HVAC_FORCED_AIR = 31
    COOLING_PANEL = 32
    UNITARY_SYSTEM = 33
    AIR_TERMINAL_DUAL_DUCT_CONSTANT_VOLUME = 34
    AIR_TERMINAL_DUAL_DUCT_VAV = 35
    AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_REHEAT = 36
    AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_NO_REHEAT = 37
    AIR_TERMINAL_SINGLE_DUCT_VAV_REHEAT = 38
    AIR_TERMINAL_SINGLE_DUCT_VAV_NO_REHEAT = 39
    AIR_TERMINAL_SINGLE_DUCT_SERIES_PIU_REHEAT = 40
    AIR_TERMINAL_SINGLE_DUCT_PARALLEL_PIU_REHEAT = 41
    AIR_TERMINAL_SINGLE_DUCT_CAV_FOUR_PIPE_INDUCTION = 42
    AIR_TERMINAL_SINGLE_DUCT_VAV_REHEAT_VARIABLE_SPEED_FAN = 43
    AIR_TERMINAL_SINGLE_DUCT_VAV_HEAT_AND_COOL_REHEAT = 44
    AIR_TERMINAL_SINGLE_DUCT_VAV_HEAT_AND_COOL_NO_REHEAT = 45
    AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_COOLED_BEAM = 46
    AIR_TERMINAL_DUAL_DUCT_VAV_OUTDOOR_AIR = 47
    AIR_LOOP_HVAC_RETURN_AIR = 48
    NUM = 49


ZONE_EQUIP_TYPE_NAMES_UC = [
    "DUMMY",
    "ZONEHVAC:FOURPIPEFANCOIL",
    "ZONEHVAC:PACKAGEDTERMINALHEATPUMP",
    "ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER",
    "ZONEHVAC:WATERTOAIRHEATPUMP",
    "ZONEHVAC:WINDOWAIRCONDITIONER",
    "ZONEHVAC:UNITHEATER",
    "ZONEHVAC:UNITVENTILATOR",
    "ZONEHVAC:ENERGYRECOVERYVENTILATOR",
    "ZONEHVAC:VENTILATEDSLAB",
    "ZONEHVAC:OUTDOORAIRUNIT",
    "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW",
    "ZONEHVAC:IDEALLOADSAIRSYSTEM",
    "ZONEHVAC:EVAPORATIVECOOLERUNIT",
    "ZONEHVAC:HYBRIDUNITARYHVAC",
    "ZONEHVAC:AIRDISTRIBUTIONUNIT",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:ELECTRIC",
    "ZONEHVAC:HIGHTEMPERATURERADIANT",
    "ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW",
    "ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW",
    "ZONEHVAC:LOWTEMPERATURERADIANT:ELECTRIC",
    "FAN:ZONEEXHAUST",
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "WATERHEATER:HEATPUMP:PUMPEDCONDENSER",
    "WATERHEATER:HEATPUMP:WRAPPEDCONDENSER",
    "ZONEHVAC:DEHUMIDIFIER:DX",
    "ZONEHVAC:REFRIGERATIONCHILLERSET",
    "ZONEHVAC:FORCEDAIR:USERDEFINED",
    "ZONEHVAC:COOLINGPANEL:RADIANTCONVECTIVE:WATER",
    "AIRLOOPHVAC:UNITARYSYSTEM",
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
    "AIRTERMINAL:DUALDUCT:VAV",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
    "AIRLOOPHVACRETURNAIR",
]

NUM_VALID_SYS_AVAIL_ZONE_COMPONENTS = 14

VALID_SYS_AVAIL_MANAGER_COMP_TYPES = [
    "ZoneHVAC:FourPipeFanCoil",
    "ZoneHVAC:PackagedTerminalHeatPump",
    "ZoneHVAC:PackagedTerminalAirConditioner",
    "ZoneHVAC:WaterToAirHeatPump",
    "ZoneHVAC:WindowAirConditioner",
    "ZoneHVAC:UnitHeater",
    "ZoneHVAC:UnitVentilator",
    "ZoneHVAC:EnergyRecoveryVentilator",
    "ZoneHVAC:VentilatedSlab",
    "ZoneHVAC:OutdoorAirUnit",
    "ZoneHVAC:TerminalUnit:VariableRefrigerantFlow",
    "ZoneHVAC:IdealLoadsAirSystem",
    "ZoneHVAC:EvaporativeCoolerUnit",
    "ZoneHVAC:HybridUnitaryHVAC",
]


class PerPersonVentRateMode(Enum):
    INVALID = -1
    DCV_BY_CURRENT_LEVEL = 0
    BY_DESIGN_LEVEL = 1
    NUM = 2


class LoadDist(Enum):
    INVALID = -1
    SEQUENTIAL = 0
    UNIFORM = 1
    UNIFORM_PLR = 2
    SEQUENTIAL_UNIFORM_PLR = 3
    NUM = 4


LOAD_DIST_NAMES_UC = [
    "SEQUENTIALLOAD",
    "UNIFORMLOAD",
    "UNIFORMPLR",
    "SEQUENTIALUNIFORMPLR",
]


class LightReturnExhaustConfig(Enum):
    INVALID = -1
    NO_EXHAUST = 0
    SINGLE = 1
    MULTI = 2
    SHARED = 3
    NUM = 4


class ZoneEquipTstatControl(Enum):
    INVALID = -1
    SINGLE_SPACE = 0
    MAXIMUM = 1
    IDEAL = 2
    NUM = 3


ZONE_EQUIP_TSTAT_CONTROL_NAMES_UC = [
    "SINGLESPACE",
    "MAXIMUM",
    "IDEAL",
]


class SpaceEquipSizingBasis(Enum):
    INVALID = -1
    DESIGN_COOLING_LOAD = 0
    DESIGN_HEATING_LOAD = 1
    FLOOR_AREA = 2
    VOLUME = 3
    PERIMETER_LENGTH = 4
    NUM = 5


SPACE_EQUIP_SIZING_BASIS_NAMES_UC = [
    "DESIGNCOOLINGLOAD",
    "DESIGNHEATINGLOAD",
    "FLOORAREA",
    "VOLUME",
    "PERIMETERLENGTH",
]


@dataclass
class SubSubEquipmentData:
    type_of: str = ""
    name: str = ""
    equip_index: int = 0
    on: bool = True
    inlet_node_num: int = 0
    outlet_node_num: int = 0
    num_metered_vars: int = 0
    metered_var: List[Any] = field(default_factory=list)
    energy_trans_comp: int = 0
    zone_eq_to_plant_ptr: int = 0
    op_mode: int = 0
    capacity: float = 0.0
    efficiency: float = 0.0
    tot_plant_supply_elec: float = 0.0
    tot_plant_supply_gas: float = 0.0
    tot_plant_supply_purch: float = 0.0


@dataclass
class SubEquipmentData:
    parent: bool = False
    num_sub_sub_equip: int = 0
    type_of: str = ""
    name: str = ""
    equip_index: int = 0
    on: bool = True
    inlet_node_num: int = 0
    outlet_node_num: int = 0
    num_metered_vars: int = 0
    metered_var: List[Any] = field(default_factory=list)
    sub_sub_equip_data: List[SubSubEquipmentData] = field(default_factory=list)
    energy_trans_comp: int = 0
    zone_eq_to_plant_ptr: int = 0
    op_mode: int = 0
    capacity: float = 0.0
    efficiency: float = 0.0
    tot_plant_supply_elec: float = 0.0
    tot_plant_supply_gas: float = 0.0
    tot_plant_supply_purch: float = 0.0


@dataclass
class AirIn:
    in_node: int = 0
    out_node: int = 0
    supply_air_path_exists: bool = False
    air_loop_num: int = 0
    main_branch_index: int = 0
    supply_branch_index: int = 0
    air_dist_unit_index: int = 0
    term_unit_sizing_index: int = 0
    supply_air_path_index: int = 0
    supply_air_path_out_node_index: int = 0
    coil: List[SubSubEquipmentData] = field(default_factory=list)


@dataclass
class EquipConfiguration:
    zone_name: str = "Uncontrolled Zone"
    equip_list_name: str = ""
    equip_list_index: int = 0
    control_list_name: str = ""
    zone_node: int = 0
    num_inlet_nodes: int = 0
    num_exhaust_nodes: int = 0
    num_return_nodes: int = 0
    num_return_flow_basis_nodes: int = 0
    return_flow_frac_sched: Optional[Any] = None
    flow_error: bool = False
    inlet_node: List[int] = field(default_factory=list)
    inlet_node_air_loop_num: List[int] = field(default_factory=list)
    inlet_node_adu_num: List[int] = field(default_factory=list)
    exhaust_node: List[int] = field(default_factory=list)
    return_node: List[int] = field(default_factory=list)
    return_node_air_loop_num: List[int] = field(default_factory=list)
    return_node_ret_path_num: List[int] = field(default_factory=list)
    return_node_ret_path_comp_num: List[int] = field(default_factory=list)
    return_node_inlet_num: List[int] = field(default_factory=list)
    fixed_return_flow: List[bool] = field(default_factory=list)
    return_node_plenum_num: List[int] = field(default_factory=list)
    return_node_exhaust_node_num: List[int] = field(default_factory=list)
    shared_exhaust_node: List[LightReturnExhaustConfig] = field(default_factory=list)
    return_node_space_mixer_index: List[int] = field(default_factory=list)
    zonal_system_only: bool = False
    is_controlled: bool = False
    zone_exh: float = 0.0
    zone_exh_balanced: float = 0.0
    plenum_mass_flow: float = 0.0
    excess_zone_exh: float = 0.0
    tot_avail_air_loop_oa: float = 0.0
    tot_inlet_air_mass_flow_rate: float = 0.0
    tot_exhaust_air_mass_flow_rate: float = 0.0
    air_dist_unit_heat: List[AirIn] = field(default_factory=list)
    air_dist_unit_cool: List[AirIn] = field(default_factory=list)
    in_floor_active_element: bool = False
    in_wall_active_element: bool = False
    in_ceiling_active_element: bool = False
    zone_has_air_loop_with_oa_sys: bool = False
    zone_air_distribution_index: int = 0
    zone_design_spec_oa_index: int = 0
    air_loop_des_supply: float = 0.0

    def set_total_inlet_flows(self, state: Any) -> None:
        pass

    def begin_environ_init(self, state: Any) -> None:
        pass

    def hvac_time_step_init(self, state: Any, first_hvac_iteration: bool) -> None:
        pass

    def calc_return_flows(
        self, state: Any, exp_total_return_mass_flow: float, final_total_return_mass_flow: float
    ) -> None:
        pass


@dataclass
class EquipmentData:
    parent: bool = False
    num_sub_equip: int = 0
    type_of: str = ""
    name: str = ""
    on: bool = True
    num_inlets: int = 0
    num_outlets: int = 0
    inlet_node_nums: List[int] = field(default_factory=list)
    outlet_node_nums: List[int] = field(default_factory=list)
    num_metered_vars: int = 0
    metered_var: List[Any] = field(default_factory=list)
    sub_equip_data: List[SubEquipmentData] = field(default_factory=list)
    energy_trans_comp: int = 0
    zone_eq_to_plant_ptr: int = 0
    tot_plant_supply_elec: float = 0.0
    tot_plant_supply_gas: float = 0.0
    tot_plant_supply_purch: float = 0.0
    op_mode: int = 0


@dataclass
class EquipList:
    name: str = ""
    load_dist_scheme: LoadDist = LoadDist.SEQUENTIAL
    num_of_equip_types: int = 0
    num_avail_heat_equip: int = 0
    num_avail_cool_equip: int = 0
    equip_type_name: List[str] = field(default_factory=list)
    equip_type: List[ZoneEquipType] = field(default_factory=list)
    equip_name: List[str] = field(default_factory=list)
    equip_index: List[int] = field(default_factory=list)
    zone_equip_splitter_index: List[int] = field(default_factory=list)
    comp_pointer: List[Optional[Any]] = field(default_factory=list)
    cooling_priority: List[int] = field(default_factory=list)
    heating_priority: List[int] = field(default_factory=list)
    sequential_cooling_fraction_scheds: List[Optional[Any]] = field(default_factory=list)
    sequential_heating_fraction_scheds: List[Optional[Any]] = field(default_factory=list)
    cooling_capacity: List[int] = field(default_factory=list)
    heating_capacity: List[int] = field(default_factory=list)
    equip_data: List[EquipmentData] = field(default_factory=list)

    def get_priorities_for_inlet_node(
        self, state: Any, inlet_node_num: int
    ) -> tuple[int, int]:
        pass

    def sequential_heating_fraction(self, state: Any, equip_num: int) -> float:
        pass

    def sequential_cooling_fraction(self, state: Any, equip_num: int) -> float:
        pass


@dataclass
class ZoneEquipSplitterMixerSpace:
    space_index: int = 0
    fraction: float = 0.0
    space_node_num: int = 0


@dataclass
class ZoneEquipmentSplitterMixer:
    name: str = ""
    space_equip_type: Optional[Any] = None
    space_sizing_basis: SpaceEquipSizingBasis = SpaceEquipSizingBasis.INVALID
    spaces: List[ZoneEquipSplitterMixerSpace] = field(default_factory=list)

    def size(self, state: Any) -> None:
        pass


@dataclass
class ZoneEquipmentSplitter(ZoneEquipmentSplitterMixer):
    zone_equip_type: ZoneEquipType = ZoneEquipType.INVALID
    zone_equip_name: str = ""
    zone_equip_outlet_node_num: int = 0
    tstat_control: ZoneEquipTstatControl = ZoneEquipTstatControl.INVALID
    control_space_index: int = 0
    control_space_number: int = 0
    save_zone_sys_sensible_demand: Optional[Any] = None
    save_zone_sys_moisture_demand: Optional[Any] = None

    def distribute_output(
        self,
        state: Any,
        zone_num: int,
        sys_output_provided: float,
        lat_output_provided: float,
        non_air_sys_output: float,
        equip_type_num: int,
    ) -> None:
        pass

    def adjust_loads(self, state: Any, zone_num: int, equip_type_num: int) -> None:
        pass


@dataclass
class ZoneMixer(ZoneEquipmentSplitterMixer):
    outlet_node_num: int = 0

    def set_outlet_conditions(self, state: Any) -> None:
        pass


@dataclass
class ZoneEquipmentMixer(ZoneMixer):
    def set_inlet_flows(self, state: Any) -> None:
        pass


@dataclass
class ZoneReturnMixer(ZoneMixer):
    def set_inlet_conditions(self, state: Any) -> None:
        pass

    def set_inlet_flows(self, state: Any) -> None:
        pass


@dataclass
class ControlList:
    name: str = ""
    num_of_controls: int = 0
    control_type: List[str] = field(default_factory=list)
    control_name: List[str] = field(default_factory=list)


@dataclass
class SupplyAir:
    name: str = ""
    num_of_components: int = 0
    inlet_node_num: int = 0
    component_type: List[str] = field(default_factory=list)
    component_type_enum: List[AirLoopHVACZone] = field(default_factory=list)
    component_name: List[str] = field(default_factory=list)
    component_index: List[int] = field(default_factory=list)
    splitter_index: List[int] = field(default_factory=list)
    plenum_index: List[int] = field(default_factory=list)
    num_outlet_nodes: int = 0
    outlet_node: List[int] = field(default_factory=list)
    outlet_node_supply_path_comp_num: List[int] = field(default_factory=list)
    num_nodes: int = 0
    node: List[int] = field(default_factory=list)
    node_type: List[AirNodeType] = field(default_factory=list)


@dataclass
class ReturnAir:
    name: str = ""
    num_of_components: int = 0
    outlet_node_num: int = 0
    outlet_ret_path_comp_num: int = 0
    component_type: List[str] = field(default_factory=list)
    component_type_enum: List[AirLoopHVACZone] = field(default_factory=list)
    component_name: List[str] = field(default_factory=list)
    component_index: List[int] = field(default_factory=list)


def get_zone_equipment_data(state: Any) -> None:
    pass


def process_zone_equipment_input(
    state: Any,
    zone_eq_module_object: str,
    zone_or_space_num: int,
    is_space: bool,
    loc_term_unit_sizing_counter: int,
    overall_equip_count: int,
    this_equip_config: EquipConfiguration,
    alph_array: List[str],
    c_alpha_fields: List[str],
    l_alpha_blanks: List[bool],
    node_nums: List[int],
) -> None:
    pass


def process_zone_equip_splitter_input(
    state: Any,
    zeq_splitter_module_object: str,
    zeq_splitter_num: int,
    zone_num: int,
    object_schema_props: Any,
    object_fields: Any,
    this_zeq_splitter: ZoneEquipmentSplitter,
) -> None:
    pass


def process_zone_equip_mixer_input(
    state: Any,
    zeq_mixer_module_object: str,
    zone_num: int,
    object_schema_props: Any,
    object_fields: Any,
    this_zeq_mixer: ZoneEquipmentMixer,
) -> None:
    pass


def process_zone_return_mixer_input(
    state: Any,
    zeq_mixer_module_object: str,
    zone_num: int,
    object_schema_props: Any,
    object_fields: Any,
    mixer_index: int,
) -> None:
    pass


def check_zone_equipment_list(
    state: Any,
    component_type: str,
    component_name: str,
    ctrl_zone_num: Optional[int] = None,
) -> bool:
    pass


def get_controlled_zone_index(state: Any, zone_name: str) -> int:
    pass


def find_controlled_zone_index_from_system_node_number_for_zone(
    state: Any, trial_zone_node_num: int
) -> int:
    pass


def get_system_node_number_for_zone(state: Any, zone_num: int) -> int:
    pass


def get_return_air_node_for_zone(
    state: Any,
    zone_num: int,
    node_name: str,
    called_from_description: str,
) -> int:
    pass


def get_return_num_for_zone(state: Any, zone_num: int, node_name: str) -> int:
    pass


def get_zone_equip_controlled_zone_num(
    state: Any, zone_equip_type: ZoneEquipType, equipment_name: str
) -> int:
    pass


def verify_lights_exhaust_node_for_zone(
    state: Any, zone_num: int, zone_exhaust_node_num: int
) -> bool:
    pass


def check_shared_exhaust(state: Any) -> None:
    pass


def scale_inlet_flows(
    state: Any, zone_node_num: int, space_node_num: int, frac: float
) -> None:
    pass


@dataclass
class DataZoneEquipmentData:
    get_zone_equipment_data_errors_found: bool = False
    get_zone_equipment_data_found: int = 0
    num_supply_air_paths: int = 0
    num_return_air_paths: int = 0
    num_exhaust_air_systems: int = 0
    num_zone_exhaust_controls: int = 0
    zone_equip_inputs_filled: bool = False
    zone_equip_simulated_once: bool = False
    num_of_zone_equip_lists: int = 0
    zone_equip_avail: List[Any] = field(default_factory=list)
    zone_equip_config: List[EquipConfiguration] = field(default_factory=list)
    space_equip_config: List[EquipConfiguration] = field(default_factory=list)
    unique_zone_equip_list_names: set = field(default_factory=set)
    zone_equip_list: List[EquipList] = field(default_factory=list)
    supply_air_path: List[SupplyAir] = field(default_factory=list)
    return_air_path: List[ReturnAir] = field(default_factory=list)
    exhaust_air_system: List[Any] = field(default_factory=list)
    zone_exhaust_control_system: List[Any] = field(default_factory=list)
    zone_equip_splitter: List[ZoneEquipmentSplitter] = field(default_factory=list)
    zone_equip_mixer: List[ZoneEquipmentMixer] = field(default_factory=list)
    zone_return_mixer: List[ZoneReturnMixer] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        pass
