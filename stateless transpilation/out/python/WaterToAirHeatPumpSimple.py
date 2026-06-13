"""
Water-to-Air Heat Pump Simple simulation module.
Ported from EnergyPlus C++ implementation.

EXTERNAL DEPS (to wire in glue):
- Psychrometrics: PsyRhoAirFnPbTdbW, PsyHFnTdbW, PsyTwbFnTdbWPb, PsyCpAirFnW, PsyWFnTdbH, PsyTdbFnHW
- Curve: value() method with (state, ...) signature
- PlantUtilities: MyPlantSizingIndex, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, RegisterPlantCompDesignFlow
- DataLoopNode: Node state access via state.dataLoopNodes.Node[]
- ErrorHandling: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd, ShowSevereBadMin, ShowSevereBadMax, ShowSevereItemNotFound, ShowWarningEmptyField
- Report: SetupOutputVariable, OutputReportPredefined, ReportCoilSelection
- GlobalNames: VerifyUniqueCoilName
- Utilities: Util module (FindItemInList, SameString, makeUPPER)
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Any, Protocol
import math


class WatertoAirHP(IntEnum):
    """Water-to-Air HP type enumeration."""
    Invalid = -1
    Heating = 0
    Cooling = 1
    Num = 2


class PlantEquipmentType(IntEnum):
    """Plant equipment type."""
    Invalid = -1
    CoilWAHPCoolingEquationFit = 0
    CoilWAHPHeatingEquationFit = 1


class CoilType(IntEnum):
    """HVAC Coil type."""
    Invalid = -1
    CoolingWAHPSimple = 0
    HeatingWAHPSimple = 1


class FanOp(IntEnum):
    """Fan operation mode."""
    Invalid = -1
    Continuous = 0
    Cycling = 1


class CompressorOp(IntEnum):
    """Compressor operation."""
    Invalid = -1
    Off = 0
    On = 1


class WaterFlow(IntEnum):
    """Water flow mode."""
    Invalid = -1
    Cycling = 0
    Constant = 1
    ConstantOnDemand = 2


class ConnectionObjectType(IntEnum):
    """Node connection object type."""
    Invalid = -1
    CoilCoolingWaterToAirHeatPumpEquationFit = 0
    CoilHeatingWaterToAirHeatPumpEquationFit = 1


class FluidType(IntEnum):
    """Node fluid type."""
    Invalid = -1
    Water = 0
    Air = 1


class ConnectionType(IntEnum):
    """Node connection type."""
    Invalid = -1
    Inlet = 0
    Outlet = 1


class CompFluidStream(IntEnum):
    """Component fluid stream."""
    Invalid = -1
    Primary = 0
    Secondary = 1


WATERTOAIR_HP_NAMES_UC = ["HEATING", "COOLING"]
TREF = 283.15  # Reference temperature for curves, 10C in K
KELVIN = 273.15
AUTOSIZE = -99999.0
SMALL_LOAD = 0.00001
SMALL_AIR_VOL_FLOW = 0.00001


@dataclass
class PlantLocation:
    """Plant location information."""
    loop_num: int = 0
    loop_side: int = 0
    branch: int = 0
    comp: int = 0


@dataclass
class Curve:
    """Curve object (stub)."""
    num: int = 0
    name: str = ""
    num_dims: int = 0
    
    def value(self, state: Any, *args: float) -> float:
        """Evaluate curve at given points."""
        # Stub: must be wired to actual curve evaluation
        return 1.0


@dataclass
class Schedule:
    """Schedule object (stub)."""
    index: int = 0
    name: str = ""


@dataclass
class SimpleWatertoAirHPConditions:
    """Simple Water-to-Air HP condition structure."""
    name: str = ""
    coil_type: int = CoilType.Invalid
    coil_report_num: int = -1
    avail_sched: Optional[Schedule] = None
    wahp_type: int = WatertoAirHP.Invalid
    wahp_plant_type: int = PlantEquipmentType.Invalid
    sim_flag: bool = False
    air_vol_flow_rate: float = 0.0
    air_mass_flow_rate: float = 0.0
    inlet_air_db_temp: float = 0.0
    inlet_air_hum_rat: float = 0.0
    inlet_air_enthalpy: float = 0.0
    outlet_air_db_temp: float = 0.0
    outlet_air_hum_rat: float = 0.0
    outlet_air_enthalpy: float = 0.0
    water_vol_flow_rate: float = 0.0
    water_mass_flow_rate: float = 0.0
    design_water_mass_flow_rate: float = 0.0
    inlet_water_temp: float = 0.0
    inlet_water_enthalpy: float = 0.0
    outlet_water_temp: float = 0.0
    outlet_water_enthalpy: float = 0.0
    power: float = 0.0
    q_load_total: float = 0.0
    q_load_total_report: float = 0.0
    q_sensible: float = 0.0
    q_latent: float = 0.0
    q_source: float = 0.0
    energy: float = 0.0
    energy_load_total: float = 0.0
    energy_sensible: float = 0.0
    energy_latent: float = 0.0
    energy_source: float = 0.0
    cop: float = 0.0
    run_frac: float = 0.0
    part_load_ratio: float = 0.0
    rated_water_vol_flow_rate: float = 0.0
    rated_air_vol_flow_rate: float = 0.0
    rated_cap_heat: float = 0.0
    rated_cap_heat_at_rated_cdts: float = 0.0
    rated_cap_cool_at_rated_cdts: float = 0.0
    rated_cap_cool_sens_des_at_rated_cdts: float = 0.0
    rated_power_heat: float = 0.0
    rated_power_heat_at_rated_cdts: float = 0.0
    rated_cop_heat_at_rated_cdts: float = 0.0
    rated_cap_cool_total: float = 0.0
    rated_cap_cool_sens: float = 0.0
    rated_power_cool: float = 0.0
    rated_power_cool_at_rated_cdts: float = 0.0
    rated_cop_cool_at_rated_cdts: float = 0.0
    rated_ent_water_temp: float = 0.0
    rated_ent_air_wetbulb_temp: float = 0.0
    rated_ent_air_drybulb_temp: float = 0.0
    ratio_rated_heat_rated_tot_cool_cap: float = 0.0
    heat_cap_curve: Optional[Curve] = None
    heat_pow_curve: Optional[Curve] = None
    total_cool_cap_curve: Optional[Curve] = None
    sens_cool_cap_curve: Optional[Curve] = None
    cool_pow_curve: Optional[Curve] = None
    plf_curve: Optional[Curve] = None
    air_inlet_node_num: int = 0
    air_outlet_node_num: int = 0
    water_inlet_node_num: int = 0
    water_outlet_node_num: int = 0
    plant_loc: PlantLocation = field(default_factory=PlantLocation)
    water_cycling_mode: int = WaterFlow.Invalid
    last_operating_mode: int = 0
    water_flow_mode: bool = False
    companion_cooling_coil_num: int = 0
    companion_heating_coil_num: int = 0
    twet_rated: float = 0.0
    gamma_rated: float = 0.0
    max_on_off_cycles_per_hour: float = 0.0
    latent_capacity_time_constant: float = 0.0
    fan_delay_time: float = 0.0
    report_coil_final_sizes: bool = True
    low_flow_flag: bool = True


@dataclass
class WaterToAirHeatPumpSimpleData:
    """Global data structure for WSHP module."""
    num_watertoair_hps: int = 0
    airflow_err_pointer: int = 0
    get_coils_input_flag: bool = True
    my_size_flag: List[bool] = field(default_factory=list)
    simple_hp_time_step_flag: List[bool] = field(default_factory=list)
    q_lat_rated: float = 0.0
    q_lat_actual: float = 0.0
    winput: float = 0.0
    my_one_time_flag: bool = True
    simple_watertoair_hp: List[SimpleWatertoAirHPConditions] = field(default_factory=list)
    my_envrnflag: List[bool] = field(default_factory=list)
    my_plant_scan_flag: List[bool] = field(default_factory=list)


def sim_watertoair_hp_simple(
    state: Any,
    comp_name: str,
    comp_index: int,
    sens_load: float,
    latent_load: float,
    fan_op: int,
    compressor_op: int,
    part_load_ratio: float,
    first_hvac_iteration: bool,
    on_off_air_flow_rat: float = 1.0
) -> int:
    """Main simulation routine for water-to-air heat pump."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    if comp_index == 0:
        hp_num = 0
        for i, coil in enumerate(data.simple_watertoair_hp):
            if coil.name.upper() == comp_name.upper():
                hp_num = i + 1
                break
        if hp_num == 0:
            raise RuntimeError(f"WaterToAirHPSimple not found: {comp_name}")
        comp_index = hp_num
    else:
        hp_num = comp_index
        if hp_num > data.num_watertoair_hps or hp_num < 1:
            raise RuntimeError(f"SimWatertoAirHPSimple: Invalid CompIndex {hp_num}, total {data.num_watertoair_hps}")
        if comp_name and comp_name != data.simple_watertoair_hp[hp_num - 1].name:
            raise RuntimeError(f"SimWatertoAirHPSimple: Name mismatch for index {hp_num}")
    
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    
    if simple_wahp.wahp_plant_type == PlantEquipmentType.CoilWAHPCoolingEquationFit:
        init_simple_watertoair_hp(state, hp_num, sens_load, latent_load, fan_op, on_off_air_flow_rat, first_hvac_iteration, part_load_ratio)
        calc_hp_cooling_simple(state, hp_num, fan_op, sens_load, latent_load, compressor_op, part_load_ratio, on_off_air_flow_rat)
        update_simple_watertoair_hp(state, hp_num)
    elif simple_wahp.wahp_plant_type == PlantEquipmentType.CoilWAHPHeatingEquationFit:
        init_simple_watertoair_hp(state, hp_num, sens_load, 0.0, fan_op, on_off_air_flow_rat, first_hvac_iteration, part_load_ratio)
        calc_hp_heating_simple(state, hp_num, fan_op, sens_load, compressor_op, part_load_ratio, on_off_air_flow_rat)
        update_simple_watertoair_hp(state, hp_num)
    else:
        raise RuntimeError("SimWatertoAirHPSimple: WatertoAir heatpump not in HEATING or COOLING mode")
    
    return comp_index


def get_simple_watertoair_hp_input(state: Any) -> None:
    """Read input for water-to-air heat pump coils."""
    # Stub: Load coil data from input file
    # This function reads all cooling and heating coils and initializes the data structures
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    data.simple_watertoair_hp = []
    data.num_watertoair_hps = 0


def init_simple_watertoair_hp(
    state: Any,
    hp_num: int,
    sens_load: float,
    latent_load: float,
    fan_op: int,
    on_off_air_flow_ratio: float,
    first_hvac_iteration: bool,
    part_load_ratio: float
) -> None:
    """Initialize water-to-air heat pump."""
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.my_one_time_flag:
        data.my_size_flag = [True] * data.num_watertoair_hps
        data.my_envrnflag = [True] * data.num_watertoair_hps
        data.my_plant_scan_flag = [True] * data.num_watertoair_hps
        data.simple_hp_time_step_flag = [True] * data.num_watertoair_hps
        data.my_one_time_flag = False
    
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    
    # Plant scan and sizing logic would go here (stubs for now)
    
    # Do begin environment initializations
    if getattr(state.dataGlobal, 'BeginEnvrnFlag', False):
        if data.my_envrnflag[hp_num - 1]:
            simple_wahp.air_vol_flow_rate = 0.0
            simple_wahp.inlet_air_db_temp = 0.0
            simple_wahp.inlet_air_hum_rat = 0.0
            simple_wahp.outlet_air_db_temp = 0.0
            simple_wahp.outlet_air_hum_rat = 0.0
            simple_wahp.water_vol_flow_rate = 0.0
            simple_wahp.water_mass_flow_rate = 0.0
            simple_wahp.inlet_water_temp = 0.0
            simple_wahp.inlet_water_enthalpy = 0.0
            simple_wahp.outlet_water_enthalpy = 0.0
            simple_wahp.outlet_water_temp = 0.0
            simple_wahp.power = 0.0
            simple_wahp.q_load_total = 0.0
            simple_wahp.q_load_total_report = 0.0
            simple_wahp.q_sensible = 0.0
            simple_wahp.q_latent = 0.0
            simple_wahp.q_source = 0.0
            simple_wahp.energy = 0.0
            simple_wahp.energy_load_total = 0.0
            simple_wahp.energy_sensible = 0.0
            simple_wahp.energy_latent = 0.0
            simple_wahp.energy_source = 0.0
            simple_wahp.cop = 0.0
            simple_wahp.run_frac = 0.0
            simple_wahp.part_load_ratio = 0.0
            simple_wahp.sim_flag = True
            data.my_envrnflag[hp_num - 1] = False
    
    if not getattr(state.dataGlobal, 'BeginEnvrnFlag', False):
        data.my_envrnflag[hp_num - 1] = True
    
    # Set inlet node conditions
    air_inlet_node = simple_wahp.air_inlet_node_num
    water_inlet_node = simple_wahp.water_inlet_node_num
    
    if (sens_load != 0.0 or latent_load != 0.0):
        simple_wahp.water_flow_mode = True
    else:
        simple_wahp.water_flow_mode = False
    
    simple_wahp.inlet_air_db_temp = getattr(state.dataLoopNodes.Node(air_inlet_node), 'Temp', 0.0)
    simple_wahp.inlet_air_hum_rat = getattr(state.dataLoopNodes.Node(air_inlet_node), 'HumRat', 0.0)
    simple_wahp.inlet_air_enthalpy = getattr(state.dataLoopNodes.Node(air_inlet_node), 'Enthalpy', 0.0)
    simple_wahp.inlet_water_temp = getattr(state.dataLoopNodes.Node(water_inlet_node), 'Temp', 0.0)
    simple_wahp.inlet_water_enthalpy = getattr(state.dataLoopNodes.Node(water_inlet_node), 'Enthalpy', 0.0)
    simple_wahp.outlet_water_temp = simple_wahp.inlet_water_temp
    simple_wahp.outlet_water_enthalpy = simple_wahp.inlet_water_enthalpy
    
    simple_wahp.power = 0.0
    simple_wahp.q_load_total = 0.0
    simple_wahp.q_load_total_report = 0.0
    simple_wahp.q_sensible = 0.0
    simple_wahp.q_latent = 0.0
    simple_wahp.q_source = 0.0
    simple_wahp.energy = 0.0
    simple_wahp.energy_load_total = 0.0
    simple_wahp.energy_sensible = 0.0
    simple_wahp.energy_latent = 0.0
    simple_wahp.energy_source = 0.0
    simple_wahp.cop = 0.0


def calc_hp_cooling_simple(
    state: Any,
    hp_num: int,
    fan_op: int,
    sens_demand: float,
    latent_demand: float,
    compressor_op: int,
    part_load_ratio: float,
    on_off_air_flow_ratio: float
) -> None:
    """Calculate cooling performance."""
    data = state.dataWaterToAirHeatPumpSimple
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    time_step_sys_sec = getattr(state.dataHVACGlobal, 'TimeStepSysSec', 3600.0)
    
    if part_load_ratio > 0.0:
        load_side_full_mass_flow_rate = simple_wahp.air_mass_flow_rate / part_load_ratio
    else:
        load_side_full_mass_flow_rate = 0.0
    
    if simple_wahp.water_mass_flow_rate <= 0.0 or load_side_full_mass_flow_rate <= 0.0:
        simple_wahp.sim_flag = False
        return
    
    if compressor_op == CompressorOp.Off:
        simple_wahp.sim_flag = False
        return
    
    simple_wahp.sim_flag = True
    
    # Calculate part load factor
    plf = 1.0
    if simple_wahp.plf_curve is not None:
        plf = simple_wahp.plf_curve.value(state, part_load_ratio)
    
    simple_wahp.run_frac = part_load_ratio / plf
    
    # Calculate performance at rated conditions
    load_side_inlet_db_temp = 26.7
    load_side_inlet_hum_rat = 0.0111
    load_side_inlet_wb_temp = 19.4
    
    ratio_tdb = (load_side_inlet_db_temp + KELVIN) / TREF
    ratio_twb = (load_side_inlet_wb_temp + KELVIN) / TREF
    ratio_ts = (simple_wahp.inlet_water_temp + KELVIN) / TREF
    
    if simple_wahp.design_water_mass_flow_rate > 0.0:
        ratio_vs = simple_wahp.water_mass_flow_rate / simple_wahp.design_water_mass_flow_rate
    else:
        ratio_vs = 0.0
    
    ratio_vl = load_side_full_mass_flow_rate / (simple_wahp.rated_air_vol_flow_rate * 1.225)
    
    simple_wahp.q_load_total = simple_wahp.rated_cap_cool_total * simple_wahp.total_cool_cap_curve.value(state, ratio_twb, ratio_ts, ratio_vl, ratio_vs)
    simple_wahp.q_sensible = simple_wahp.rated_cap_cool_sens * simple_wahp.sens_cool_cap_curve.value(state, ratio_tdb, ratio_twb, ratio_ts, ratio_vl, ratio_vs)
    data.winput = simple_wahp.rated_power_cool * simple_wahp.cool_pow_curve.value(state, ratio_twb, ratio_ts, ratio_vl, ratio_vs)
    
    if simple_wahp.q_sensible > simple_wahp.q_load_total:
        simple_wahp.q_sensible = simple_wahp.q_load_total
    
    # Scale to part load
    simple_wahp.q_load_total *= part_load_ratio
    simple_wahp.q_sensible *= part_load_ratio
    data.winput *= simple_wahp.run_frac
    simple_wahp.q_source = simple_wahp.q_load_total + data.winput
    
    simple_wahp.power = data.winput
    simple_wahp.q_load_total_report = simple_wahp.q_load_total
    simple_wahp.q_latent = simple_wahp.q_load_total - simple_wahp.q_sensible
    simple_wahp.energy = data.winput * time_step_sys_sec
    simple_wahp.energy_load_total = simple_wahp.q_load_total_report * time_step_sys_sec
    simple_wahp.energy_sensible = simple_wahp.q_sensible * time_step_sys_sec
    simple_wahp.energy_latent = simple_wahp.q_latent * time_step_sys_sec
    simple_wahp.energy_source = simple_wahp.q_source * time_step_sys_sec
    
    if simple_wahp.run_frac == 0.0:
        simple_wahp.cop = 0.0
    else:
        simple_wahp.cop = simple_wahp.q_load_total_report / data.winput
    
    simple_wahp.part_load_ratio = part_load_ratio


def calc_hp_heating_simple(
    state: Any,
    hp_num: int,
    fan_op: int,
    sens_demand: float,
    compressor_op: int,
    part_load_ratio: float,
    on_off_air_flow_ratio: float
) -> None:
    """Calculate heating performance."""
    data = state.dataWaterToAirHeatPumpSimple
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    time_step_sys_sec = getattr(state.dataHVACGlobal, 'TimeStepSysSec', 3600.0)
    
    if part_load_ratio > 0.0:
        load_side_full_mass_flow_rate = simple_wahp.air_mass_flow_rate / part_load_ratio
    else:
        load_side_full_mass_flow_rate = 0.0
    
    if simple_wahp.water_mass_flow_rate <= 0.0 or load_side_full_mass_flow_rate <= 0.0:
        simple_wahp.sim_flag = False
        return
    
    if compressor_op == CompressorOp.Off:
        simple_wahp.sim_flag = False
        return
    
    simple_wahp.sim_flag = True
    
    # Calculate part load factor
    plf = 1.0
    if simple_wahp.plf_curve is not None:
        plf = simple_wahp.plf_curve.value(state, part_load_ratio)
    
    simple_wahp.run_frac = part_load_ratio / plf
    
    # Calculate performance
    load_side_inlet_db_temp = simple_wahp.inlet_air_db_temp
    
    ratio_tdb = (load_side_inlet_db_temp + KELVIN) / TREF
    ratio_ts = (simple_wahp.inlet_water_temp + KELVIN) / TREF
    
    if simple_wahp.design_water_mass_flow_rate > 0.0:
        ratio_vs = simple_wahp.water_mass_flow_rate / simple_wahp.design_water_mass_flow_rate
    else:
        ratio_vs = 0.0
    
    ratio_vl = load_side_full_mass_flow_rate / (simple_wahp.rated_air_vol_flow_rate * 1.225)
    
    simple_wahp.q_load_total = simple_wahp.rated_cap_heat * simple_wahp.heat_cap_curve.value(state, ratio_tdb, ratio_ts, ratio_vl, ratio_vs)
    simple_wahp.q_sensible = simple_wahp.q_load_total
    data.winput = simple_wahp.rated_power_heat * simple_wahp.heat_pow_curve.value(state, ratio_tdb, ratio_ts, ratio_vl, ratio_vs)
    
    # Scale to part load
    simple_wahp.q_load_total *= part_load_ratio
    simple_wahp.q_load_total_report = simple_wahp.q_load_total
    simple_wahp.q_sensible *= part_load_ratio
    data.winput *= simple_wahp.run_frac
    simple_wahp.q_source = simple_wahp.q_load_total_report - data.winput
    
    simple_wahp.power = data.winput
    simple_wahp.energy = data.winput * time_step_sys_sec
    simple_wahp.energy_load_total = simple_wahp.q_load_total_report * time_step_sys_sec
    simple_wahp.energy_sensible = simple_wahp.q_sensible * time_step_sys_sec
    simple_wahp.energy_latent = 0.0
    simple_wahp.energy_source = simple_wahp.q_source * time_step_sys_sec
    
    if simple_wahp.run_frac == 0.0:
        simple_wahp.cop = 0.0
    else:
        simple_wahp.cop = simple_wahp.q_load_total_report / data.winput
    
    simple_wahp.part_load_ratio = part_load_ratio


def update_simple_watertoair_hp(state: Any, hp_num: int) -> None:
    """Update outlet node conditions."""
    data = state.dataWaterToAirHeatPumpSimple
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    time_step_sys_sec = getattr(state.dataHVACGlobal, 'TimeStepSysSec', 3600.0)
    
    if not simple_wahp.sim_flag:
        simple_wahp.power = 0.0
        simple_wahp.q_load_total = 0.0
        simple_wahp.q_load_total_report = 0.0
        simple_wahp.q_sensible = 0.0
        simple_wahp.q_latent = 0.0
        simple_wahp.q_source = 0.0
        simple_wahp.energy = 0.0
        simple_wahp.energy_load_total = 0.0
        simple_wahp.energy_sensible = 0.0
        simple_wahp.energy_latent = 0.0
        simple_wahp.energy_source = 0.0
        simple_wahp.cop = 0.0
        simple_wahp.run_frac = 0.0
        simple_wahp.part_load_ratio = 0.0
        simple_wahp.outlet_air_db_temp = simple_wahp.inlet_air_db_temp
        simple_wahp.outlet_air_hum_rat = simple_wahp.inlet_air_hum_rat
        simple_wahp.outlet_air_enthalpy = simple_wahp.inlet_air_enthalpy
        simple_wahp.outlet_water_temp = simple_wahp.inlet_water_temp
        simple_wahp.outlet_water_enthalpy = simple_wahp.inlet_water_enthalpy
    
    # Set outlet nodes
    air_inlet_node = simple_wahp.air_inlet_node_num
    air_outlet_node = simple_wahp.air_outlet_node_num
    
    setattr(state.dataLoopNodes.Node(air_outlet_node), 'MassFlowRate', getattr(state.dataLoopNodes.Node(air_inlet_node), 'MassFlowRate', 0.0))
    setattr(state.dataLoopNodes.Node(air_outlet_node), 'Temp', simple_wahp.outlet_air_db_temp)
    setattr(state.dataLoopNodes.Node(air_outlet_node), 'HumRat', simple_wahp.outlet_air_hum_rat)
    setattr(state.dataLoopNodes.Node(air_outlet_node), 'Enthalpy', simple_wahp.outlet_air_enthalpy)
    
    water_outlet_node = simple_wahp.water_outlet_node_num
    setattr(state.dataLoopNodes.Node(water_outlet_node), 'Temp', simple_wahp.outlet_water_temp)
    setattr(state.dataLoopNodes.Node(water_outlet_node), 'Enthalpy', simple_wahp.outlet_water_enthalpy)
    
    simple_wahp.energy = simple_wahp.power * time_step_sys_sec
    simple_wahp.energy_load_total = simple_wahp.q_load_total * time_step_sys_sec
    simple_wahp.energy_sensible = simple_wahp.q_sensible * time_step_sys_sec
    simple_wahp.energy_latent = simple_wahp.q_latent * time_step_sys_sec
    simple_wahp.energy_source = simple_wahp.q_source * time_step_sys_sec


def calc_effective_shr(
    state: Any,
    hp_num: int,
    shr_ss: float,
    fan_op: int,
    rtf: float,
    q_lat_rated: float,
    q_lat_actual: float,
    entering_db: float,
    entering_wb: float
) -> float:
    """Calculate effective sensible heat ratio."""
    if rtf >= 1.0 or q_lat_rated <= 0.0 or q_lat_actual <= 0.0:
        return shr_ss
    
    data = state.dataWaterToAirHeatPumpSimple
    simple_wahp = data.simple_watertoair_hp[hp_num - 1]
    
    twet = simple_wahp.twet_rated * q_lat_rated / max(q_lat_actual, 1e-10)
    gamma = simple_wahp.gamma_rated * q_lat_rated * (entering_db - entering_wb) / max((26.7 - 19.4) * q_lat_actual, 1e-10)
    
    ton = 3600.0 / (4.0 * simple_wahp.max_on_off_cycles_per_hour * max(1.0 - rtf, 1e-10))
    
    if fan_op == FanOp.Cycling and simple_wahp.fan_delay_time != 0.0:
        toff = simple_wahp.fan_delay_time
    else:
        toff = 3600.0 / (4.0 * simple_wahp.max_on_off_cycles_per_hour * max(rtf, 1e-10))
    
    if gamma > 0.0:
        toffa = min(toff, 2.0 * twet / gamma)
    else:
        toffa = toff
    
    aa = (gamma * toffa) - (0.25 / twet) * gamma * gamma * toffa * toffa
    to1 = aa + simple_wahp.latent_capacity_time_constant
    
    error = 1.0
    while error > 0.001:
        exp_val = math.exp(min(700.0, -to1 / simple_wahp.latent_capacity_time_constant)) - 1.0
        to2 = aa - simple_wahp.latent_capacity_time_constant * exp_val
        error = abs((to2 - to1) / to1) if to1 != 0.0 else 0.0
        to1 = to2
    
    aa = math.exp(max(-700.0, -ton / simple_wahp.latent_capacity_time_constant))
    lhr_mult = max((ton - to2) / (ton + simple_wahp.latent_capacity_time_constant * (aa - 1.0)), 0.0)
    
    shr_eff = 1.0 - (1.0 - shr_ss) * lhr_mult
    
    if shr_eff < shr_ss:
        shr_eff = shr_ss
    if shr_eff > 1.0:
        shr_eff = 1.0
    
    return shr_eff


def get_coil_index(state: Any, coil_type: str, coil_name: str) -> int:
    """Get coil index by name."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            return i + 1
    
    return 0


def get_coil_capacity(state: Any, coil_type: str, coil_name: str) -> float:
    """Get rated coil capacity."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    which_coil = 0
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            which_coil = i + 1
            break
    
    if which_coil == 0:
        return -1000.0
    
    coil = data.simple_watertoair_hp[which_coil - 1]
    if "HEATING" in coil_type.upper():
        return coil.rated_cap_heat
    else:
        return coil.rated_cap_cool_total


def get_coil_air_flow_rate(state: Any, coil_type: str, coil_name: str) -> float:
    """Get rated air flow rate."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    which_coil = 0
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            which_coil = i + 1
            break
    
    if which_coil == 0:
        return -1000.0
    
    return data.simple_watertoair_hp[which_coil - 1].rated_air_vol_flow_rate


def get_coil_inlet_node(state: Any, coil_type: str, coil_name: str) -> int:
    """Get coil air inlet node."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    which_coil = 0
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            which_coil = i + 1
            break
    
    if which_coil == 0:
        return 0
    
    return data.simple_watertoair_hp[which_coil - 1].air_inlet_node_num


def get_coil_outlet_node(state: Any, coil_type: str, coil_name: str) -> int:
    """Get coil air outlet node."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    which_coil = 0
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            which_coil = i + 1
            break
    
    if which_coil == 0:
        return 0
    
    return data.simple_watertoair_hp[which_coil - 1].air_outlet_node_num


def set_simple_wshp_data(
    state: Any,
    simple_wshp_num: int,
    water_cycling_mode: int,
    companion_cooling_coil_num: Optional[int] = None,
    companion_heating_coil_num: Optional[int] = None
) -> None:
    """Set companion coil information."""
    if not hasattr(state, 'dataWaterToAirHeatPumpSimple'):
        state.dataWaterToAirHeatPumpSimple = WaterToAirHeatPumpSimpleData()
    
    data = state.dataWaterToAirHeatPumpSimple
    
    if data.get_coils_input_flag:
        get_simple_watertoair_hp_input(state)
        data.get_coils_input_flag = False
    
    if simple_wshp_num <= 0 or simple_wshp_num > data.num_watertoair_hps:
        raise RuntimeError(f"SetSimpleWSHPData: WSHP number {simple_wshp_num} out of range")
    
    data.simple_watertoair_hp[simple_wshp_num - 1].water_cycling_mode = water_cycling_mode
    
    if companion_cooling_coil_num is not None:
        data.simple_watertoair_hp[simple_wshp_num - 1].companion_cooling_coil_num = companion_cooling_coil_num
        data.simple_watertoair_hp[companion_cooling_coil_num - 1].companion_heating_coil_num = simple_wshp_num
        data.simple_watertoair_hp[companion_cooling_coil_num - 1].water_cycling_mode = water_cycling_mode
    
    if companion_heating_coil_num is not None:
        data.simple_watertoair_hp[simple_wshp_num - 1].companion_heating_coil_num = companion_heating_coil_num
        data.simple_watertoair_hp[companion_heating_coil_num - 1].companion_cooling_coil_num = simple_wshp_num
        data.simple_watertoair_hp[companion_heating_coil_num - 1].water_cycling_mode = water_cycling_mode


def check_simple_wahp_rated_curves_outputs(state: Any, coil_name: str) -> None:
    """Check curve outputs at rated conditions."""
    data = state.dataWaterToAirHeatPumpSimple
    
    which_coil = 0
    for i, coil in enumerate(data.simple_watertoair_hp):
        if coil.name.upper() == coil_name.upper():
            which_coil = i + 1
            break
    
    if which_coil == 0:
        return
    
    wahp = data.simple_watertoair_hp[which_coil - 1]
    
    if wahp.wahp_type == WatertoAirHP.Cooling:
        if wahp.rated_ent_air_wetbulb_temp != AUTOSIZE and wahp.total_cool_cap_curve and wahp.cool_pow_curve:
            rated_ratio_twb = (wahp.rated_ent_air_wetbulb_temp + KELVIN) / TREF
            rated_ratio_ts = (wahp.rated_ent_water_temp + KELVIN) / TREF
            rated_tot_cap_temp_mod_fac = wahp.total_cool_cap_curve.value(state, rated_ratio_twb, rated_ratio_ts, 1.0, 1.0)
            rated_cool_power_temp_mod_fac = wahp.cool_pow_curve.value(state, rated_ratio_twb, rated_ratio_ts, 1.0, 1.0)
            
            if rated_tot_cap_temp_mod_fac > 1.02 or rated_tot_cap_temp_mod_fac < 0.98:
                pass  # Warning would be logged here
    
    elif wahp.wahp_type == WatertoAirHP.Heating:
        if wahp.rated_ent_air_drybulb_temp != AUTOSIZE and wahp.heat_cap_curve and wahp.heat_pow_curve:
            rated_heat_ratio_tdb = (wahp.rated_ent_air_drybulb_temp + KELVIN) / TREF
            rated_heat_ratio_ts = (wahp.rated_ent_water_temp + KELVIN) / TREF
            rated_heat_cap_temp_mod_fac = wahp.heat_cap_curve.value(state, rated_heat_ratio_tdb, rated_heat_ratio_ts, 1.0, 1.0)
            rated_heat_power_temp_mod_fac = wahp.heat_pow_curve.value(state, rated_heat_ratio_tdb, rated_heat_ratio_ts, 1.0, 1.0)
            
            if rated_heat_cap_temp_mod_fac > 1.02 or rated_heat_cap_temp_mod_fac < 0.98:
                pass  # Warning would be logged here
