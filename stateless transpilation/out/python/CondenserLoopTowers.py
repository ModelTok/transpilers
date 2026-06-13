"""
EnergyPlus Cooling Tower Models - Python Port

Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
The Regents of the University of California, through Lawrence Berkeley National Laboratory
and other contributors. All rights reserved.

This is a faithful 1:1 translation of CondenserLoopTowers.hh/cc from EnergyPlus.
"""

from dataclasses import dataclass, field
from enum import IntEnum, auto
from typing import Optional, List, Callable, Any
from abc import ABC, abstractmethod
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter passed throughout)
# - PlantComponent (base class, stubbed as ABC)
# - PlantLocation, DataPlant (enums and types, passed as params)
# - Psychrometrics module (vapor/humidity calculations)
# - Curve module (curve evaluations)
# - Node utilities, PlantUtilities (wired as helper functions)
# - General module (root solver, utility functions)
# - ScheduleManager (schedule evaluation)
# - WaterManager (basin heater, water tank setup)
# - OutputProcessor, OutputReportPredefined (reporting stubs)
# - FaultsManager (fault model evaluation)


class ModelType(IntEnum):
    """Empirical Model Type enumeration."""
    Invalid = -1
    CoolToolsXFModel = 0
    CoolToolsUserDefined = 1
    YorkCalcModel = 2
    YorkCalcUserDefined = 3
    Num = 4


class EvapLoss(IntEnum):
    """Evaporation Loss Mode enumeration."""
    Invalid = -1
    UserFactor = 0
    MoistTheory = 1
    Num = 2


class Blowdown(IntEnum):
    """Blowdown Mode enumeration."""
    Invalid = -1
    Concentration = 0
    Schedule = 1
    Num = 2


class PIM(IntEnum):
    """Performance Input Method enumeration."""
    Invalid = -1
    NominalCapacity = 0
    UFactor = 1
    Num = 2


class CapacityCtrl(IntEnum):
    """Capacity Control Mode enumeration."""
    Invalid = -1
    FanCycling = 0
    FluidBypass = 1
    Num = 2


class CellCtrl(IntEnum):
    """Cell Control Mode enumeration."""
    Invalid = -1
    MinCell = 0
    MaxCell = 1
    Num = 2


CAPACITY_CTRL_NAMES_UC = ["FANCYCLING", "FLUIDBYPASS"]
EVAP_LOSS_NAMES_UC = ["LOSSFACTOR", "SATURATEDEXIT"]
PIM_NAMES_UC = ["NOMINALCAPACITY", "UFACTORTIMESAREAANDDESIGNWATERFLOWRATE"]
BLOWDOWN_NAMES_UC = ["CONCENTRATIONRATIO", "SCHEDULEDRATE"]
CELL_CTRL_NAMES_UC = ["MINIMALCELL", "MAXIMALCELL"]

COOLING_TOWER_SINGLE_SPEED = "CoolingTower:SingleSpeed"
COOLING_TOWER_TWO_SPEED = "CoolingTower:TwoSpeed"
COOLING_TOWER_VARIABLE_SPEED = "CoolingTower:VariableSpeed"
COOLING_TOWER_VARIABLE_SPEED_MERKEL = "CoolingTower:VariableSpeed:Merkel"


@dataclass
class CoolingTower:
    """Cooling Tower component structure."""
    name: str = ""
    tower_type: Any = None  # DataPlant::PlantEquipmentType
    performance_input_method_num: PIM = PIM.Invalid
    model_coeff_object_name: str = ""
    available: bool = True
    on: bool = True
    
    design_water_flow_rate: float = 0.0
    design_water_flow_rate_was_autosized: bool = False
    design_water_flow_per_unit_nom_cap: float = 0.0
    des_water_mass_flow_rate: float = 0.0
    des_water_mass_flow_rate_per_cell: float = 0.0
    high_speed_air_flow_rate: float = 0.0
    high_speed_air_flow_rate_was_autosized: bool = False
    design_air_flow_per_unit_nom_cap: float = 0.0
    defaulted_design_air_flow_scaling_factor: bool = False
    high_speed_fan_power: float = 0.0
    high_speed_fan_power_was_autosized: bool = False
    design_fan_power_per_unit_nom_cap: float = 0.0
    
    high_speed_tower_ua: float = 0.0
    high_speed_tower_ua_was_autosized: bool = False
    low_speed_air_flow_rate: float = 0.0
    low_speed_air_flow_rate_was_autosized: bool = False
    low_speed_air_flow_rate_sizing_factor: float = 0.0
    low_speed_fan_power: float = 0.0
    low_speed_fan_power_was_autosized: bool = False
    low_speed_fan_power_sizing_factor: float = 0.0
    low_speed_tower_ua: float = 0.0
    low_speed_tower_ua_was_autosized: bool = False
    low_speed_tower_ua_sizing_factor: float = 0.0
    free_conv_air_flow_rate: float = 0.0
    free_conv_air_flow_rate_was_autosized: bool = False
    free_conv_air_flow_rate_sizing_factor: float = 0.0
    free_conv_tower_ua: float = 0.0
    free_conv_tower_ua_was_autosized: bool = False
    free_conv_tower_ua_sizing_factor: float = 0.0
    
    design_inlet_wb: float = 0.0
    design_approach: float = 0.0
    design_range: float = 0.0
    minimum_vs_air_flow_frac: float = 0.0
    calibrated_water_flow_rate: float = 0.0
    basin_heater_power_f_temp_diff: float = 0.0
    basin_heater_set_point_temp: float = 0.0
    makeup_water_drift: float = 0.0
    free_convection_capacity_fraction: float = 0.0
    tower_mass_flow_rate_multiplier: float = 0.0
    heat_reject_cap_nom_cap_sizing_ratio: float = 1.25
    
    tower_nominal_capacity: float = 0.0
    tower_nominal_capacity_was_autosized: bool = False
    tower_low_speed_nom_cap: float = 0.0
    tower_low_speed_nom_cap_was_autosized: bool = False
    tower_low_speed_nom_cap_sizing_factor: float = 0.0
    tower_free_conv_nom_cap: float = 0.0
    tower_free_conv_nom_cap_was_autosized: bool = False
    tower_free_conv_nom_cap_sizing_factor: float = 0.0
    siz_fac: float = 0.0
    
    water_inlet_node_num: int = 0
    water_outlet_node_num: int = 0
    outdoor_air_inlet_node_num: int = 0
    tower_model_type: ModelType = ModelType.Invalid
    fan_powerf_air_flow_curve: int = 0
    blow_down_sched: Optional[Any] = None
    basin_heater_sched: Optional[Any] = None
    
    high_mass_flow_error_count: int = 0
    high_mass_flow_error_index: int = 0
    outlet_water_temp_error_count: int = 0
    outlet_water_temp_error_index: int = 0
    small_water_mass_flow_error_count: int = 0
    small_water_mass_flow_error_index: int = 0
    wmfr_less_than_min_avail_err_count: int = 0
    wmfr_less_than_min_avail_err_index: int = 0
    wmfr_greater_than_max_avail_err_count: int = 0
    wmfr_greater_than_max_avail_err_index: int = 0
    cooling_tower_afrr_failed_count: int = 0
    cooling_tower_afrr_failed_index: int = 0
    speed_selected: int = 0
    
    capacity_control: CapacityCtrl = CapacityCtrl.Invalid
    bypass_fraction: float = 0.0
    num_cell: int = 0
    cell_ctrl: CellCtrl = CellCtrl.MaxCell
    num_cell_on: int = 0
    min_frac_flow_rate: float = 0.0
    max_frac_flow_rate: float = 0.0
    
    evap_loss_mode: EvapLoss = EvapLoss.MoistTheory
    user_evap_loss_factor: float = 0.0
    drift_loss_fraction: float = 0.008
    blowdown_mode: Blowdown = Blowdown.Concentration
    concentration_ratio: float = 3.0
    supplied_by_water_system: bool = False
    water_tank_id: int = 0
    water_tank_demand_arr_id: int = 0
    
    plant_loc: Optional[Any] = None
    ua_mod_func_air_flow_ratio_curve_ptr: int = 0
    ua_mod_func_wet_bulb_diff_curve_ptr: int = 0
    ua_mod_func_water_flow_ratio_curve_ptr: int = 0
    setpoint_is_on_outlet: bool = False
    vs_merkel_afr_error_iter: int = 0
    vs_merkel_afr_error_iter_index: int = 0
    vs_merkel_afr_error_fail: int = 0
    vs_merkel_afr_error_fail_index: int = 0
    
    des_inlet_water_temp: float = 0.0
    des_outlet_water_temp: float = 0.0
    des_inlet_air_db_temp: float = 0.0
    tower_inlet_conds_auto_size: bool = False
    
    faulty_condenser_swt_flag: bool = False
    faulty_condenser_swt_index: int = 0
    faulty_condenser_swt_offset: float = 0.0
    faulty_tower_fouling_flag: bool = False
    faulty_tower_fouling_index: int = 0
    faulty_tower_fouling_factor: float = 1.0
    end_use_subcategory: str = ""
    envrnflag: bool = True
    one_time_flag: bool = True
    time_step_sys_last: float = 0.0
    current_end_time_last: float = 0.0
    
    air_flow_rate_ratio: float = 0.0
    water_temp: float = 0.0
    air_temp: float = 0.0
    air_wet_bulb: float = 0.0
    air_press: float = 0.0
    air_hum_rat: float = 0.0
    
    inlet_water_temp: float = 0.0
    outlet_water_temp: float = 0.0
    water_mass_flow_rate: float = 0.0
    qactual: float = 0.0
    fan_power: float = 0.0
    fan_energy: float = 0.0
    air_flow_ratio: float = 0.0
    basin_heater_power: float = 0.0
    basin_heater_consumption: float = 0.0
    water_usage: float = 0.0
    water_amount_used: float = 0.0
    fan_cycling_ratio: float = 0.0
    evaporation_vdot: float = 0.0
    evaporation_vol: float = 0.0
    drift_vdot: float = 0.0
    drift_vol: float = 0.0
    blowdown_vdot: float = 0.0
    blowdown_vol: float = 0.0
    makeup_vdot: float = 0.0
    makeup_vol: float = 0.0
    tank_supply_vdot: float = 0.0
    tank_supply_vol: float = 0.0
    starved_makeup_vdot: float = 0.0
    starved_makeup_vol: float = 0.0
    cooling_tower_approach: float = 0.0
    cooling_tower_range: float = 0.0
    
    coeff: List[float] = field(default_factory=lambda: [0.0] * 35)
    found_model_coeff: bool = False
    min_inlet_air_wb_temp: float = 0.0
    max_inlet_air_wb_temp: float = 0.0
    min_range_temp: float = 0.0
    max_range_temp: float = 0.0
    min_approach_temp: float = 0.0
    max_approach_temp: float = 0.0
    min_water_flow_ratio: float = 0.0
    max_water_flow_ratio: float = 0.0
    max_liquid_to_gas_ratio: float = 0.0
    
    vs_error_count_flow_frac: int = 0
    vs_error_count_wfrr: int = 0
    vs_error_count_iawb: int = 0
    vs_error_count_tr: int = 0
    vs_error_count_tr_calc: int = 0
    vs_error_count_ta: int = 0
    err_index_flow_frac: int = 0
    err_index_wfrr: int = 0
    err_index_iawb: int = 0
    err_index_tr: int = 0
    err_index_tr_calc: int = 0
    err_index_ta: int = 0
    err_index_lg: int = 0
    
    tr_buffer1: str = ""
    tr_buffer2: str = ""
    tr_buffer3: str = ""
    twb_buffer1: str = ""
    twb_buffer2: str = ""
    twb_buffer3: str = ""
    ta_buffer1: str = ""
    ta_buffer2: str = ""
    ta_buffer3: str = ""
    wfrr_buffer1: str = ""
    wfrr_buffer2: str = ""
    wfrr_buffer3: str = ""
    lg_buffer1: str = ""
    lg_buffer2: str = ""
    
    print_tr_message: bool = False
    print_twb_message: bool = False
    print_ta_message: bool = False
    print_wfrr_message: bool = False
    print_lg_message: bool = False
    tr_last: float = 0.0
    twb_last: float = 0.0
    ta_last: float = 0.0
    water_flow_rate_ratio_last: float = 0.0
    lg_last: float = 0.0


@dataclass
class CondenserLoopTowersData:
    """Global data for condenser loop towers."""
    get_input: bool = True
    towers: List[CoolingTower] = field(default_factory=list)


def factory(state: Any, object_name: str) -> Optional[CoolingTower]:
    """Factory method to find or create a cooling tower by name."""
    if state.data_condenser_loop_towers.get_input:
        get_tower_input(state)
        state.data_condenser_loop_towers.get_input = False
    
    for tower in state.data_condenser_loop_towers.towers:
        if tower.name == object_name:
            return tower
    
    # Tower not found - would show fatal error in real implementation
    return None


def calculate_simple_tower_outlet_temp(
    state: Any,
    tower: CoolingTower,
    water_mass_flow_rate: float,
    air_flow_rate: float,
    ua_design: float
) -> float:
    """Calculate outlet water temperature for simple tower model."""
    if ua_design == 0.0:
        return tower.inlet_water_temp
    
    if water_mass_flow_rate <= 0.0:
        return tower.inlet_water_temp
    
    # Call Psychrometrics stubs
    air_density = _psych_rho_air_fn_pb_tdb_w(state, tower.air_press, tower.air_temp, tower.air_hum_rat)
    air_mass_flow_rate = air_flow_rate * air_density
    cp_air = _psych_cp_air_fn_w(tower.air_hum_rat)
    cp_water = _get_specific_heat(state, tower, tower.water_temp)
    inlet_air_enthalpy = _psych_h_fn_tdb_rhpb(state, tower.air_wet_bulb, 1.0, tower.air_press)
    
    outlet_air_wet_bulb = tower.air_wet_bulb + 6.0
    mdot_cp_water = water_mass_flow_rate * cp_water
    
    iter_count = 0
    iter_max = 50
    wb_error = 1.0
    wb_tolerance = 0.00001
    delta_twb = 1.0
    delta_twb_tolerance = 0.001
    
    while (wb_error > wb_tolerance) and (iter_count <= iter_max) and (delta_twb > delta_twb_tolerance):
        iter_count += 1
        
        outlet_air_enthalpy = _psych_h_fn_tdb_rhpb(state, outlet_air_wet_bulb, 1.0, tower.air_press)
        cp_airside = (outlet_air_enthalpy - inlet_air_enthalpy) / (outlet_air_wet_bulb - tower.air_wet_bulb)
        air_capacity = air_mass_flow_rate * cp_airside
        
        capacity_ratio_min = min(air_capacity, mdot_cp_water)
        capacity_ratio_max = max(air_capacity, mdot_cp_water)
        capacity_ratio = capacity_ratio_min / capacity_ratio_max if capacity_ratio_max > 0 else 0
        
        ua_actual = ua_design * cp_airside / cp_air
        num_transfer_units = ua_actual / capacity_ratio_min if capacity_ratio_min > 0 else 0
        
        if capacity_ratio <= 0.995:
            exponent = num_transfer_units * (1.0 - capacity_ratio)
            if exponent >= 700.0:
                effectiveness = num_transfer_units / (1.0 + num_transfer_units)
            else:
                exp_term = math.exp(-1.0 * num_transfer_units * (1.0 - capacity_ratio))
                effectiveness = (1.0 - exp_term) / (1.0 - capacity_ratio * exp_term)
        else:
            effectiveness = num_transfer_units / (1.0 + num_transfer_units)
        
        q_actual = effectiveness * capacity_ratio_min * (tower.inlet_water_temp - tower.air_wet_bulb)
        outlet_air_wet_bulb_last = outlet_air_wet_bulb
        outlet_air_wet_bulb = tower.air_wet_bulb + (q_actual / air_capacity if air_capacity > 0 else 0)
        
        delta_twb = abs(outlet_air_wet_bulb - tower.air_wet_bulb)
        wb_error = abs((outlet_air_wet_bulb - outlet_air_wet_bulb_last) / (outlet_air_wet_bulb_last + 273.15))
    
    if q_actual >= 0.0:
        outlet_water_temp = tower.inlet_water_temp - (q_actual / mdot_cp_water if mdot_cp_water > 0 else 0)
    else:
        outlet_water_temp = tower.inlet_water_temp
    
    return outlet_water_temp


def calculate_variable_speed_approach(
    state: Any,
    tower: CoolingTower,
    pct_water_flow: float,
    air_flow_ratio_local: float,
    twb: float,
    tr: float = 0.0
) -> float:
    """Calculate approach temperature for variable speed tower."""
    if tower.tower_model_type in (ModelType.YorkCalcModel, ModelType.YorkCalcUserDefined):
        pct_air_flow = air_flow_ratio_local
        flow_factor = pct_water_flow / pct_air_flow if pct_air_flow > 0 else 0
        
        return (
            tower.coeff[0] + tower.coeff[1] * twb + tower.coeff[2] * twb * twb +
            tower.coeff[3] * tr + tower.coeff[4] * twb * tr +
            tower.coeff[5] * twb * twb * tr + tower.coeff[6] * tr * tr +
            tower.coeff[7] * twb * tr * tr + tower.coeff[8] * twb * twb * tr * tr +
            tower.coeff[9] * flow_factor + tower.coeff[10] * twb * flow_factor +
            tower.coeff[11] * twb * twb * flow_factor + tower.coeff[12] * tr * flow_factor +
            tower.coeff[13] * twb * tr * flow_factor + tower.coeff[14] * twb * twb * tr * flow_factor +
            tower.coeff[15] * tr * tr * flow_factor + tower.coeff[16] * twb * tr * tr * flow_factor +
            tower.coeff[17] * twb * twb * tr * tr * flow_factor +
            tower.coeff[18] * flow_factor * flow_factor + tower.coeff[19] * twb * flow_factor * flow_factor +
            tower.coeff[20] * twb * twb * flow_factor * flow_factor +
            tower.coeff[21] * tr * flow_factor * flow_factor +
            tower.coeff[22] * twb * tr * flow_factor * flow_factor +
            tower.coeff[23] * twb * twb * tr * flow_factor * flow_factor +
            tower.coeff[24] * tr * tr * flow_factor * flow_factor +
            tower.coeff[25] * twb * tr * tr * flow_factor * flow_factor +
            tower.coeff[26] * twb * twb * tr * tr * flow_factor * flow_factor
        )
    else:  # CoolTools format
        pct_air_flow = pow(air_flow_ratio_local, 3)
        return (
            tower.coeff[0] + tower.coeff[1] * pct_air_flow +
            tower.coeff[2] * pct_air_flow * pct_air_flow +
            tower.coeff[3] * pct_air_flow * pct_air_flow * pct_air_flow +
            tower.coeff[4] * pct_water_flow +
            tower.coeff[5] * pct_air_flow * pct_water_flow +
            tower.coeff[6] * pct_air_flow * pct_air_flow * pct_water_flow +
            tower.coeff[7] * pct_water_flow * pct_water_flow +
            tower.coeff[8] * pct_air_flow * pct_water_flow * pct_water_flow +
            tower.coeff[9] * pct_water_flow * pct_water_flow * pct_water_flow +
            tower.coeff[10] * twb +
            tower.coeff[11] * pct_air_flow * twb +
            tower.coeff[12] * pct_air_flow * pct_air_flow * twb +
            tower.coeff[13] * pct_water_flow * twb +
            tower.coeff[14] * pct_air_flow * pct_water_flow * twb +
            tower.coeff[15] * pct_water_flow * pct_water_flow * twb +
            tower.coeff[16] * twb * twb +
            tower.coeff[17] * pct_air_flow * twb * twb +
            tower.coeff[18] * pct_water_flow * twb * twb +
            tower.coeff[19] * twb * twb * twb +
            tower.coeff[20] * tr +
            tower.coeff[21] * pct_air_flow * tr +
            tower.coeff[22] * pct_air_flow * pct_air_flow * tr +
            tower.coeff[23] * pct_water_flow * tr +
            tower.coeff[24] * pct_air_flow * pct_water_flow * tr +
            tower.coeff[25] * pct_water_flow * pct_water_flow * tr +
            tower.coeff[26] * twb * tr +
            tower.coeff[27] * pct_air_flow * twb * tr +
            tower.coeff[28] * pct_water_flow * twb * tr +
            tower.coeff[29] * twb * twb * tr +
            tower.coeff[30] * tr * tr +
            tower.coeff[31] * pct_air_flow * tr * tr +
            tower.coeff[32] * pct_water_flow * tr * tr +
            tower.coeff[33] * twb * tr * tr +
            tower.coeff[34] * tr * tr * tr
        )


# Stub implementations for external dependencies
def get_tower_input(state: Any) -> None:
    """Get tower input from data structure."""
    pass


def _psych_rho_air_fn_pb_tdb_w(state: Any, pb: float, tdb: float, hum_rat: float) -> float:
    """Psychrometric: air density from pressure, dry-bulb, humidity ratio."""
    return 1.2  # Stub


def _psych_cp_air_fn_w(hum_rat: float) -> float:
    """Psychrometric: specific heat of air from humidity ratio."""
    return 1006.0  # Stub


def _psych_h_fn_tdb_rhpb(state: Any, tdb: float, rh: float, pb: float) -> float:
    """Psychrometric: enthalpy from dry-bulb, RH, pressure."""
    return 50000.0  # Stub


def _get_specific_heat(state: Any, tower: CoolingTower, temp: float) -> float:
    """Get specific heat from plant glycol at temperature."""
    return 4180.0  # Stub


def calc_basin_heater_power(
    state: Any,
    basin_heater_power_f_temp_diff: float,
    basin_heater_sched: Optional[Any],
    basin_heater_set_point_temp: float,
    tower: CoolingTower
) -> None:
    """Calculate basin heater power."""
    tower.basin_heater_power = 0.0  # Stub
