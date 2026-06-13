"""
EnergyPlus HVACMultiSpeedHeatPump module

Multi-speed heat pump simulation module.
AUTHOR: Lixing Gu, Florida Solar Energy Center
DATE WRITTEN: June 2007
"""

from enum import IntEnum
from typing import Optional, Tuple, List
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (dataclass with state.dataHVACMultiSpdHP, state.dataEnvrn, state.dataLoopNodes, etc.)
# - HVAC module: enums (FanOp, CompressorOp, FanType, FanPlace, CoilType), SmallLoad, SmallMassFlow, SmallAirVolFlow
# - DXCoils module: functions (SimDXCoilMultiSpeed, GetDXCoilIndex, GetDXCoilNumberOfSpeeds, GetCoilInletNode, GetCoilOutletNode, GetMinOATCompressor, DisableLatentDegradation, SetMSHPDXCoilHeatRecoveryFlag, GetDXCoilAvailSched, DXCoilPartLoadRatio)
# - HeatingCoils module: functions (GetHeatingCoilIndex, GetHeatingCoilNumberOfStages, GetCoilInletNode, GetCoilOutletNode, GetCoilCapacity, SimulateHeatingCoilComponents)
# - WaterCoils module: functions (GetCoilWaterInletNode, GetCoilMaxWaterFlowRate, GetCoilInletNode, GetCoilOutletNode, SimulateWaterCoilComponents)
# - SteamCoils module: functions (GetSteamCoilIndex, GetCoilAirOutletNode, GetCoilMaxSteamFlowRate, GetCoilAirInletNode, SimulateSteamCoilComponents, GetCoilCapacity)
# - Psychrometrics module: functions (RhoH2O, PsyCpAirFnW, PsyDeltaHSenFnTdb2W2Tdb1W1)
# - ScheduleManager module: functions (GetScheduleAlwaysOn, GetSchedule)
# - Fans module: fan object interface
# - PlantUtilities module: functions (ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode, RegisterPlantCompDesignFlow)
# - NodeInputManager module: GetOnlySingleNode
# - General module: SolveRoot
# - Util module: FindItemInList, SameString
# - OutputProcessor module: SetupOutputVariable
# - OutputReportPredefined module: PreDefTableEntry
# - Constant module: HWInitConvTemp, Units, eResource, Group, EndUseCat
# - DataSizing module: AutoSize, HeatCoilSizMethod
# - DataPlant module: PlantEquipmentType, PlantLocation, CompData
# - ErrorHandling module: ShowWarningError, ShowContinueError, ShowFatalError, ShowSevereError, etc.


class ModeOfOperation(IntEnum):
    """Mode of operation for heat pump"""
    INVALID = -1
    COOLING_MODE = 0
    HEATING_MODE = 1
    NUM = 2


class AirflowControl(IntEnum):
    """Airflow control for constant fan mode"""
    INVALID = -1
    USE_COMPRESSOR_ON_FLOW = 0
    USE_COMPRESSOR_OFF_FLOW = 1
    NUM = 2


class CurveType(IntEnum):
    """Curve types"""
    INVALID = -1
    LINEAR = 0
    BILINEAR = 1
    QUADRATIC = 2
    BIQUADRATIC = 3
    CUBIC = 4
    NUM = 5


@dataclass
class MSHeatPumpData:
    """Multi-speed heat pump data"""
    name: str = ""
    avail_sched: Optional[object] = None
    air_inlet_node_num: int = 0
    air_outlet_node_num: int = 0
    air_inlet_node_name: str = ""
    air_outlet_node_name: str = ""
    control_zone_num: int = 0
    zone_sequence_cooling_num: int = 0
    zone_sequence_heating_num: int = 0
    control_zone_name: str = ""
    node_num_of_controlled_zone: int = 0
    flow_fraction: float = 0.0
    fan_name: str = ""
    fan_type: int = -1
    fan_num: int = 0
    fan_place: int = -1
    fan_inlet_node: int = 0
    fan_outlet_node: int = 0
    fan_vol_flow: float = 0.0
    fan_op_mode_sched: Optional[object] = None
    fan_op: int = -1
    dx_heat_coil_name: str = ""
    heat_coil_type: int = -1
    heat_coil_num: int = 0
    dx_heat_coil_index: int = 0
    heat_coil_name: str = ""
    heat_coil_index: int = 0
    dx_cool_coil_name: str = ""
    cool_coil_type: int = -1
    dx_cool_coil_index: int = 0
    supp_heat_coil_name: str = ""
    supp_heat_coil_type: int = -1
    supp_heat_coil_num: int = 0
    design_supp_heating_capacity: float = 0.0
    supp_max_air_temp: float = 0.0
    supp_max_oa_temp: float = 0.0
    aux_on_cycle_power: float = 0.0
    aux_off_cycle_power: float = 0.0
    design_heat_rec_flow_rate: float = 0.0
    heat_rec_active: bool = False
    heat_rec_name: str = ""
    heat_rec_inlet_node_num: int = 0
    heat_rec_outlet_node_num: int = 0
    max_heat_rec_outlet_temp: float = 0.0
    design_heat_rec_mass_flow_rate: float = 0.0
    hr_plant_loc: Optional[object] = None
    aux_elec_power: float = 0.0
    idle_volume_air_rate: float = 0.0
    idle_mass_flow_rate: float = 0.0
    idle_speed_ratio: float = 0.0
    num_of_speed_cooling: int = 0
    num_of_speed_heating: int = 0
    heat_volume_flow_rate: List[float] = field(default_factory=list)
    heat_mass_flow_rate: List[float] = field(default_factory=list)
    cool_volume_flow_rate: List[float] = field(default_factory=list)
    cool_mass_flow_rate: List[float] = field(default_factory=list)
    heating_speed_ratio: List[float] = field(default_factory=list)
    cooling_speed_ratio: List[float] = field(default_factory=list)
    check_fan_flow: bool = True
    last_mode: int = -1
    heat_cool_mode: int = -1
    air_loop_number: int = 0
    num_controlled_zones: int = 0
    zone_inlet_node: int = 0
    comp_part_load_ratio: float = 0.0
    fan_part_load_ratio: float = 0.0
    tot_cool_energy_rate: float = 0.0
    tot_heat_energy_rate: float = 0.0
    sens_cool_energy_rate: float = 0.0
    sens_heat_energy_rate: float = 0.0
    lat_cool_energy_rate: float = 0.0
    lat_heat_energy_rate: float = 0.0
    elec_power: float = 0.0
    load_met: float = 0.0
    heat_recovery_rate: float = 0.0
    heat_recovery_inlet_temp: float = 0.0
    heat_recovery_outlet_temp: float = 0.0
    heat_recovery_mass_flow_rate: float = 0.0
    air_flow_control: int = -1
    err_index_cyc: int = 0
    err_index_var: int = 0
    load_loss: float = 0.0
    supp_coil_air_inlet_node: int = 0
    supp_coil_air_outlet_node: int = 0
    supp_heat_coil_type_num: int = 0
    supp_heat_coil_index: int = 0
    supp_coil_control_node: int = 0
    max_supp_coil_fluid_flow: float = 0.0
    supp_coil_outlet_node: int = 0
    coil_air_inlet_node: int = 0
    coil_control_node: int = 0
    max_coil_fluid_flow: float = 0.0
    coil_outlet_node: int = 0
    hot_water_coil_control_node: int = 0
    hot_water_coil_outlet_node: int = 0
    hot_water_coil_name: str = ""
    hot_water_coil_num: int = 0
    plant_loc: Optional[object] = None
    supp_plant_loc: Optional[object] = None
    hot_water_plant_loc: Optional[object] = None
    hot_water_coil_max_iter_index: int = 0
    hot_water_coil_max_iter_index2: int = 0
    stage_num: int = 0
    staged: bool = False
    cool_count_avail: int = 0
    cool_index_avail: int = 0
    heat_count_avail: int = 0
    heat_index_avail: int = 0
    first_pass: bool = True
    full_output: List[float] = field(default_factory=list)
    min_oat_compressor_cooling: float = 0.0
    min_oat_compressor_heating: float = 0.0
    my_envrnflag: bool = True
    my_size_flag: bool = True
    my_check_flag: bool = True
    my_flow_frac_flag: bool = True
    my_plant_scant_flag: bool = True
    my_staged_flag: bool = True
    ems_override_coil_speed_num_on: bool = False
    ems_override_coil_speed_num_value: float = 0.0
    coil_speed_err_index: int = 0
    heating_sizing_ratio: float = 1.0
    is_heat_pump: bool = False
    report_acca_manual_s: bool = True


@dataclass
class MSHeatPumpReportData:
    """Multi-speed heat pump report data"""
    elec_power_consumption: float = 0.0
    heat_recovery_energy: float = 0.0
    cyc_ratio: float = 0.0
    speed_ratio: float = 0.0
    speed_num: int = 0
    aux_elec_cool_consumption: float = 0.0
    aux_elec_heat_consumption: float = 0.0


@dataclass
class HVACMultiSpeedHeatPumpData:
    """Global heat pump data"""
    num_msheat_pumps: int = 0
    air_loop_pass: int = 0
    temp_steam_in: float = 100.0
    current_module_object: str = ""
    comp_on_mass_flow: float = 0.0
    comp_off_mass_flow: float = 0.0
    comp_on_flow_ratio: float = 0.0
    comp_off_flow_ratio: float = 0.0
    fan_speed_ratio: float = 0.0
    sup_heater_load: float = 0.0
    save_load_residual: float = 0.0
    save_compressor_plr: float = 0.0
    check_equip_name: List[bool] = field(default_factory=list)
    msheat_pump: List[MSHeatPumpData] = field(default_factory=list)
    msheat_pump_report: List[MSHeatPumpReportData] = field(default_factory=list)
    get_input_flag: bool = True
    flow_frac_flag_ready: bool = True
    err_count_cyc: int = 0
    err_count_var: int = 0
    heat_coil_name: str = ""


def sim_msheat_pump(state, comp_name: str, first_hvac_iteration: bool, air_loop_num: int, comp_index: int):
    """Simulate multi-speed heat pump"""
    msheat_pump_num = 0
    on_off_air_flow_ratio = 0.0
    qzn_load = 0.0
    qsens_unit_out = 0.0

    if state.dataHVACMultiSpdHP.get_input_flag:
        get_msheat_pump_input(state)
        state.dataHVACMultiSpdHP.get_input_flag = False

    if comp_index == 0:
        msheat_pump_num = next((i + 1 for i, hp in enumerate(state.dataHVACMultiSpdHP.msheat_pump) if hp.name == comp_name), 0)
        if msheat_pump_num == 0:
            raise ValueError(f"MultiSpeed Heat Pump is not found={comp_name}")
        comp_index = msheat_pump_num
    else:
        msheat_pump_num = comp_index
        if msheat_pump_num > state.dataHVACMultiSpdHP.num_msheat_pumps or msheat_pump_num < 1:
            raise ValueError(f"SimMSHeatPump: Invalid CompIndex passed={msheat_pump_num}")

    on_off_air_flow_ratio = 0.0

    init_msheat_pump(state, msheat_pump_num, first_hvac_iteration, air_loop_num, qzn_load, on_off_air_flow_ratio)
    sim_mshp(state, msheat_pump_num, first_hvac_iteration, air_loop_num, qsens_unit_out, qzn_load, on_off_air_flow_ratio)
    update_msheat_pump(state, msheat_pump_num)
    report_msheat_pump(state, msheat_pump_num)

    return comp_index


def sim_mshp(state, msheat_pump_num: int, first_hvac_iteration: bool, air_loop_num: int, qsens_unit_out: float, qzn_req: float, on_off_air_flow_ratio: float):
    """Simulate multi-speed heat pump"""
    pass  # Placeholder - complex implementation would follow


def get_msheat_pump_input(state):
    """Get multi-speed heat pump input"""
    pass  # Placeholder


def init_msheat_pump(state, msheat_pump_num: int, first_hvac_iteration: bool, air_loop_num: int, qzn_req: float, on_off_air_flow_ratio: float):
    """Initialize multi-speed heat pump"""
    pass  # Placeholder


def size_msheat_pump(state, msheat_pump_num: int):
    """Size multi-speed heat pump"""
    pass  # Placeholder


def control_mshp_output(state, msheat_pump_num: int, first_hvac_iteration: bool, compressor_op: int, fan_op: int, qzn_req: float, zone_num: int, speed_num: int, speed_ratio: float, part_load_frac: float, on_off_air_flow_ratio: float, sup_heater_load: float):
    """Control multi-speed heat pump output"""
    pass  # Placeholder


def control_mshp_sup_heater(state, msheat_pump_num: int, first_hvac_iteration: bool, compressor_op: int, fan_op: int, qzn_req: float, ems_output: int, speed_num: int, speed_ratio: float, part_load_frac: float, on_off_air_flow_ratio: float, sup_heater_load: float):
    """Control supplemental heater"""
    pass  # Placeholder


def control_mshp_output_ems(state, msheat_pump_num: int, first_hvac_iteration: bool, compressor_op: int, fan_op: int, qzn_req: float, speed_val: float, speed_num: int, speed_ratio: float, part_load_frac: float, on_off_air_flow_ratio: float, sup_heater_load: float):
    """Control multi-speed heat pump output with EMS"""
    pass  # Placeholder


def calc_msheat_pump(state, msheat_pump_num: int, first_hvac_iteration: bool, compressor_op: int, speed_num: int, speed_ratio: float, part_load_frac: float, load_met: float, qzn_req: float, on_off_air_flow_ratio: float, sup_heater_load: float):
    """Calculate multi-speed heat pump performance"""
    pass  # Placeholder


def update_msheat_pump(state, msheat_pump_num: int):
    """Update multi-speed heat pump"""
    pass  # Placeholder


def report_msheat_pump(state, msheat_pump_num: int):
    """Report multi-speed heat pump"""
    pass  # Placeholder


def mshp_heat_recovery(state, msheat_pump_num: int):
    """Calculate heat recovery"""
    pass  # Placeholder


def set_average_air_flow(state, msheat_pump_num: int, part_load_ratio: float, on_off_air_flow_ratio: float, speed_num: Optional[int] = None, speed_ratio: Optional[float] = None):
    """Set average air flow"""
    pass  # Placeholder


def calc_non_dx_heating_coils(state, msheat_pump_num: int, first_hvac_iteration: bool, heating_load: float, fan_op: int, heat_coil_loadmet: float, part_load_frac: Optional[float] = None):
    """Calculate non-DX heating coils"""
    pass  # Placeholder
