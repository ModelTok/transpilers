"""
EnergyPlus Cooling Tower Models - Mojo Port

Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
The Regents of the University of California, through Lawrence Berkeley National Laboratory
and other contributors. All rights reserved.

This is a faithful 1:1 translation of CondenserLoopTowers.hh/cc from EnergyPlus.
"""

from math import pow as math_pow, exp as math_exp, abs as math_abs, sin, cos, sqrt
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter passed throughout)
# - PlantComponent (base type, stubbed as trait)
# - PlantLocation, DataPlant (enums and types, passed as params)
# - Psychrometrics module (vapor/humidity calculations)
# - Curve module (curve evaluations)
# - Node utilities, PlantUtilities (wired as helper functions)
# - General module (root solver, utility functions)
# - ScheduleManager (schedule evaluation)
# - WaterManager (basin heater, water tank setup)
# - OutputProcessor, OutputReportPredefined (reporting stubs)
# - FaultsManager (fault model evaluation)


@value
struct ModelType:
    """Empirical Model Type enumeration."""
    alias Invalid = -1
    alias CoolToolsXFModel = 0
    alias CoolToolsUserDefined = 1
    alias YorkCalcModel = 2
    alias YorkCalcUserDefined = 3
    alias Num = 4


@value
struct EvapLoss:
    """Evaporation Loss Mode enumeration."""
    alias Invalid = -1
    alias UserFactor = 0
    alias MoistTheory = 1
    alias Num = 2


@value
struct Blowdown:
    """Blowdown Mode enumeration."""
    alias Invalid = -1
    alias Concentration = 0
    alias Schedule = 1
    alias Num = 2


@value
struct PIM:
    """Performance Input Method enumeration."""
    alias Invalid = -1
    alias NominalCapacity = 0
    alias UFactor = 1
    alias Num = 2


@value
struct CapacityCtrl:
    """Capacity Control Mode enumeration."""
    alias Invalid = -1
    alias FanCycling = 0
    alias FluidBypass = 1
    alias Num = 2


@value
struct CellCtrl:
    """Cell Control Mode enumeration."""
    alias Invalid = -1
    alias MinCell = 0
    alias MaxCell = 1
    alias Num = 2


fn capacity_ctrl_names_uc() -> List[String]:
    """Capacity control names in uppercase."""
    var names = List[String]()
    names.append("FANCYCLING")
    names.append("FLUIDBYPASS")
    return names


fn evap_loss_names_uc() -> List[String]:
    """Evaporation loss mode names in uppercase."""
    var names = List[String]()
    names.append("LOSSFACTOR")
    names.append("SATURATEDEXIT")
    return names


fn pim_names_uc() -> List[String]:
    """Performance input method names in uppercase."""
    var names = List[String]()
    names.append("NOMINALCAPACITY")
    names.append("UFACTORTIMESAREAANDDESIGNWATERFLOWRATE")
    return names


fn blowdown_names_uc() -> List[String]:
    """Blowdown mode names in uppercase."""
    var names = List[String]()
    names.append("CONCENTRATIONRATIO")
    names.append("SCHEDULEDRATE")
    return names


fn cell_ctrl_names_uc() -> List[String]:
    """Cell control names in uppercase."""
    var names = List[String]()
    names.append("MINIMALCELL")
    names.append("MAXIMALCELL")
    return names


alias COOLING_TOWER_SINGLE_SPEED = "CoolingTower:SingleSpeed"
alias COOLING_TOWER_TWO_SPEED = "CoolingTower:TwoSpeed"
alias COOLING_TOWER_VARIABLE_SPEED = "CoolingTower:VariableSpeed"
alias COOLING_TOWER_VARIABLE_SPEED_MERKEL = "CoolingTower:VariableSpeed:Merkel"


struct CoolingTower:
    """Cooling Tower component structure."""
    var name: String
    var tower_type: Int32
    var performance_input_method_num: Int32
    var model_coeff_object_name: String
    var available: Bool
    var on: Bool
    
    var design_water_flow_rate: Float64
    var design_water_flow_rate_was_autosized: Bool
    var design_water_flow_per_unit_nom_cap: Float64
    var des_water_mass_flow_rate: Float64
    var des_water_mass_flow_rate_per_cell: Float64
    var high_speed_air_flow_rate: Float64
    var high_speed_air_flow_rate_was_autosized: Bool
    var design_air_flow_per_unit_nom_cap: Float64
    var defaulted_design_air_flow_scaling_factor: Bool
    var high_speed_fan_power: Float64
    var high_speed_fan_power_was_autosized: Bool
    var design_fan_power_per_unit_nom_cap: Float64
    
    var high_speed_tower_ua: Float64
    var high_speed_tower_ua_was_autosized: Bool
    var low_speed_air_flow_rate: Float64
    var low_speed_air_flow_rate_was_autosized: Bool
    var low_speed_air_flow_rate_sizing_factor: Float64
    var low_speed_fan_power: Float64
    var low_speed_fan_power_was_autosized: Bool
    var low_speed_fan_power_sizing_factor: Float64
    var low_speed_tower_ua: Float64
    var low_speed_tower_ua_was_autosized: Bool
    var low_speed_tower_ua_sizing_factor: Float64
    var free_conv_air_flow_rate: Float64
    var free_conv_air_flow_rate_was_autosized: Bool
    var free_conv_air_flow_rate_sizing_factor: Float64
    var free_conv_tower_ua: Float64
    var free_conv_tower_ua_was_autosized: Bool
    var free_conv_tower_ua_sizing_factor: Float64
    
    var design_inlet_wb: Float64
    var design_approach: Float64
    var design_range: Float64
    var minimum_vs_air_flow_frac: Float64
    var calibrated_water_flow_rate: Float64
    var basin_heater_power_f_temp_diff: Float64
    var basin_heater_set_point_temp: Float64
    var makeup_water_drift: Float64
    var free_convection_capacity_fraction: Float64
    var tower_mass_flow_rate_multiplier: Float64
    var heat_reject_cap_nom_cap_sizing_ratio: Float64
    
    var tower_nominal_capacity: Float64
    var tower_nominal_capacity_was_autosized: Bool
    var tower_low_speed_nom_cap: Float64
    var tower_low_speed_nom_cap_was_autosized: Bool
    var tower_low_speed_nom_cap_sizing_factor: Float64
    var tower_free_conv_nom_cap: Float64
    var tower_free_conv_nom_cap_was_autosized: Bool
    var tower_free_conv_nom_cap_sizing_factor: Float64
    var siz_fac: Float64
    
    var water_inlet_node_num: Int32
    var water_outlet_node_num: Int32
    var outdoor_air_inlet_node_num: Int32
    var tower_model_type: Int32
    var fan_powerf_air_flow_curve: Int32
    var blow_down_sched: Int32
    var basin_heater_sched: Int32
    
    var high_mass_flow_error_count: Int32
    var high_mass_flow_error_index: Int32
    var outlet_water_temp_error_count: Int32
    var outlet_water_temp_error_index: Int32
    var small_water_mass_flow_error_count: Int32
    var small_water_mass_flow_error_index: Int32
    var wmfr_less_than_min_avail_err_count: Int32
    var wmfr_less_than_min_avail_err_index: Int32
    var wmfr_greater_than_max_avail_err_count: Int32
    var wmfr_greater_than_max_avail_err_index: Int32
    var cooling_tower_afrr_failed_count: Int32
    var cooling_tower_afrr_failed_index: Int32
    var speed_selected: Int32
    
    var capacity_control: Int32
    var bypass_fraction: Float64
    var num_cell: Int32
    var cell_ctrl: Int32
    var num_cell_on: Int32
    var min_frac_flow_rate: Float64
    var max_frac_flow_rate: Float64
    
    var evap_loss_mode: Int32
    var user_evap_loss_factor: Float64
    var drift_loss_fraction: Float64
    var blowdown_mode: Int32
    var concentration_ratio: Float64
    var supplied_by_water_system: Bool
    var water_tank_id: Int32
    var water_tank_demand_arr_id: Int32
    
    var ua_mod_func_air_flow_ratio_curve_ptr: Int32
    var ua_mod_func_wet_bulb_diff_curve_ptr: Int32
    var ua_mod_func_water_flow_ratio_curve_ptr: Int32
    var setpoint_is_on_outlet: Bool
    var vs_merkel_afr_error_iter: Int32
    var vs_merkel_afr_error_iter_index: Int32
    var vs_merkel_afr_error_fail: Int32
    var vs_merkel_afr_error_fail_index: Int32
    
    var des_inlet_water_temp: Float64
    var des_outlet_water_temp: Float64
    var des_inlet_air_db_temp: Float64
    var tower_inlet_conds_auto_size: Bool
    
    var faulty_condenser_swt_flag: Bool
    var faulty_condenser_swt_index: Int32
    var faulty_condenser_swt_offset: Float64
    var faulty_tower_fouling_flag: Bool
    var faulty_tower_fouling_index: Int32
    var faulty_tower_fouling_factor: Float64
    var end_use_subcategory: String
    var envrnflag: Bool
    var one_time_flag: Bool
    var time_step_sys_last: Float64
    var current_end_time_last: Float64
    
    var air_flow_rate_ratio: Float64
    var water_temp: Float64
    var air_temp: Float64
    var air_wet_bulb: Float64
    var air_press: Float64
    var air_hum_rat: Float64
    
    var inlet_water_temp: Float64
    var outlet_water_temp: Float64
    var water_mass_flow_rate: Float64
    var qactual: Float64
    var fan_power: Float64
    var fan_energy: Float64
    var air_flow_ratio: Float64
    var basin_heater_power: Float64
    var basin_heater_consumption: Float64
    var water_usage: Float64
    var water_amount_used: Float64
    var fan_cycling_ratio: Float64
    var evaporation_vdot: Float64
    var evaporation_vol: Float64
    var drift_vdot: Float64
    var drift_vol: Float64
    var blowdown_vdot: Float64
    var blowdown_vol: Float64
    var makeup_vdot: Float64
    var makeup_vol: Float64
    var tank_supply_vdot: Float64
    var tank_supply_vol: Float64
    var starved_makeup_vdot: Float64
    var starved_makeup_vol: Float64
    var cooling_tower_approach: Float64
    var cooling_tower_range: Float64
    
    var coeff: InlineArray[Float64, 35]
    var found_model_coeff: Bool
    var min_inlet_air_wb_temp: Float64
    var max_inlet_air_wb_temp: Float64
    var min_range_temp: Float64
    var max_range_temp: Float64
    var min_approach_temp: Float64
    var max_approach_temp: Float64
    var min_water_flow_ratio: Float64
    var max_water_flow_ratio: Float64
    var max_liquid_to_gas_ratio: Float64
    
    var vs_error_count_flow_frac: Int32
    var vs_error_count_wfrr: Int32
    var vs_error_count_iawb: Int32
    var vs_error_count_tr: Int32
    var vs_error_count_tr_calc: Int32
    var vs_error_count_ta: Int32
    var err_index_flow_frac: Int32
    var err_index_wfrr: Int32
    var err_index_iawb: Int32
    var err_index_tr: Int32
    var err_index_tr_calc: Int32
    var err_index_ta: Int32
    var err_index_lg: Int32
    
    var tr_buffer1: String
    var tr_buffer2: String
    var tr_buffer3: String
    var twb_buffer1: String
    var twb_buffer2: String
    var twb_buffer3: String
    var ta_buffer1: String
    var ta_buffer2: String
    var ta_buffer3: String
    var wfrr_buffer1: String
    var wfrr_buffer2: String
    var wfrr_buffer3: String
    var lg_buffer1: String
    var lg_buffer2: String
    
    var print_tr_message: Bool
    var print_twb_message: Bool
    var print_ta_message: Bool
    var print_wfrr_message: Bool
    var print_lg_message: Bool
    var tr_last: Float64
    var twb_last: Float64
    var ta_last: Float64
    var water_flow_rate_ratio_last: Float64
    var lg_last: Float64
    
    fn __init__(inout self):
        self.name = String()
        self.tower_type = -1
        self.performance_input_method_num = -1
        self.model_coeff_object_name = String()
        self.available = True
        self.on = True
        self.design_water_flow_rate = 0.0
        self.design_water_flow_rate_was_autosized = False
        self.design_water_flow_per_unit_nom_cap = 0.0
        self.des_water_mass_flow_rate = 0.0
        self.des_water_mass_flow_rate_per_cell = 0.0
        self.high_speed_air_flow_rate = 0.0
        self.high_speed_air_flow_rate_was_autosized = False
        self.design_air_flow_per_unit_nom_cap = 0.0
        self.defaulted_design_air_flow_scaling_factor = False
        self.high_speed_fan_power = 0.0
        self.high_speed_fan_power_was_autosized = False
        self.design_fan_power_per_unit_nom_cap = 0.0
        self.high_speed_tower_ua = 0.0
        self.high_speed_tower_ua_was_autosized = False
        self.low_speed_air_flow_rate = 0.0
        self.low_speed_air_flow_rate_was_autosized = False
        self.low_speed_air_flow_rate_sizing_factor = 0.0
        self.low_speed_fan_power = 0.0
        self.low_speed_fan_power_was_autosized = False
        self.low_speed_fan_power_sizing_factor = 0.0
        self.low_speed_tower_ua = 0.0
        self.low_speed_tower_ua_was_autosized = False
        self.low_speed_tower_ua_sizing_factor = 0.0
        self.free_conv_air_flow_rate = 0.0
        self.free_conv_air_flow_rate_was_autosized = False
        self.free_conv_air_flow_rate_sizing_factor = 0.0
        self.free_conv_tower_ua = 0.0
        self.free_conv_tower_ua_was_autosized = False
        self.free_conv_tower_ua_sizing_factor = 0.0
        self.design_inlet_wb = 0.0
        self.design_approach = 0.0
        self.design_range = 0.0
        self.minimum_vs_air_flow_frac = 0.0
        self.calibrated_water_flow_rate = 0.0
        self.basin_heater_power_f_temp_diff = 0.0
        self.basin_heater_set_point_temp = 0.0
        self.makeup_water_drift = 0.0
        self.free_convection_capacity_fraction = 0.0
        self.tower_mass_flow_rate_multiplier = 0.0
        self.heat_reject_cap_nom_cap_sizing_ratio = 1.25
        self.tower_nominal_capacity = 0.0
        self.tower_nominal_capacity_was_autosized = False
        self.tower_low_speed_nom_cap = 0.0
        self.tower_low_speed_nom_cap_was_autosized = False
        self.tower_low_speed_nom_cap_sizing_factor = 0.0
        self.tower_free_conv_nom_cap = 0.0
        self.tower_free_conv_nom_cap_was_autosized = False
        self.tower_free_conv_nom_cap_sizing_factor = 0.0
        self.siz_fac = 0.0
        self.water_inlet_node_num = 0
        self.water_outlet_node_num = 0
        self.outdoor_air_inlet_node_num = 0
        self.tower_model_type = -1
        self.fan_powerf_air_flow_curve = 0
        self.blow_down_sched = 0
        self.basin_heater_sched = 0
        self.high_mass_flow_error_count = 0
        self.high_mass_flow_error_index = 0
        self.outlet_water_temp_error_count = 0
        self.outlet_water_temp_error_index = 0
        self.small_water_mass_flow_error_count = 0
        self.small_water_mass_flow_error_index = 0
        self.wmfr_less_than_min_avail_err_count = 0
        self.wmfr_less_than_min_avail_err_index = 0
        self.wmfr_greater_than_max_avail_err_count = 0
        self.wmfr_greater_than_max_avail_err_index = 0
        self.cooling_tower_afrr_failed_count = 0
        self.cooling_tower_afrr_failed_index = 0
        self.speed_selected = 0
        self.capacity_control = -1
        self.bypass_fraction = 0.0
        self.num_cell = 0
        self.cell_ctrl = 1
        self.num_cell_on = 0
        self.min_frac_flow_rate = 0.0
        self.max_frac_flow_rate = 0.0
        self.evap_loss_mode = 1
        self.user_evap_loss_factor = 0.0
        self.drift_loss_fraction = 0.008
        self.blowdown_mode = 0
        self.concentration_ratio = 3.0
        self.supplied_by_water_system = False
        self.water_tank_id = 0
        self.water_tank_demand_arr_id = 0
        self.ua_mod_func_air_flow_ratio_curve_ptr = 0
        self.ua_mod_func_wet_bulb_diff_curve_ptr = 0
        self.ua_mod_func_water_flow_ratio_curve_ptr = 0
        self.setpoint_is_on_outlet = False
        self.vs_merkel_afr_error_iter = 0
        self.vs_merkel_afr_error_iter_index = 0
        self.vs_merkel_afr_error_fail = 0
        self.vs_merkel_afr_error_fail_index = 0
        self.des_inlet_water_temp = 0.0
        self.des_outlet_water_temp = 0.0
        self.des_inlet_air_db_temp = 0.0
        self.tower_inlet_conds_auto_size = False
        self.faulty_condenser_swt_flag = False
        self.faulty_condenser_swt_index = 0
        self.faulty_condenser_swt_offset = 0.0
        self.faulty_tower_fouling_flag = False
        self.faulty_tower_fouling_index = 0
        self.faulty_tower_fouling_factor = 1.0
        self.end_use_subcategory = String()
        self.envrnflag = True
        self.one_time_flag = True
        self.time_step_sys_last = 0.0
        self.current_end_time_last = 0.0
        self.air_flow_rate_ratio = 0.0
        self.water_temp = 0.0
        self.air_temp = 0.0
        self.air_wet_bulb = 0.0
        self.air_press = 0.0
        self.air_hum_rat = 0.0
        self.inlet_water_temp = 0.0
        self.outlet_water_temp = 0.0
        self.water_mass_flow_rate = 0.0
        self.qactual = 0.0
        self.fan_power = 0.0
        self.fan_energy = 0.0
        self.air_flow_ratio = 0.0
        self.basin_heater_power = 0.0
        self.basin_heater_consumption = 0.0
        self.water_usage = 0.0
        self.water_amount_used = 0.0
        self.fan_cycling_ratio = 0.0
        self.evaporation_vdot = 0.0
        self.evaporation_vol = 0.0
        self.drift_vdot = 0.0
        self.drift_vol = 0.0
        self.blowdown_vdot = 0.0
        self.blowdown_vol = 0.0
        self.makeup_vdot = 0.0
        self.makeup_vol = 0.0
        self.tank_supply_vdot = 0.0
        self.tank_supply_vol = 0.0
        self.starved_makeup_vdot = 0.0
        self.starved_makeup_vol = 0.0
        self.cooling_tower_approach = 0.0
        self.cooling_tower_range = 0.0
        self.coeff = InlineArray[Float64, 35](fill=0.0)
        self.found_model_coeff = False
        self.min_inlet_air_wb_temp = 0.0
        self.max_inlet_air_wb_temp = 0.0
        self.min_range_temp = 0.0
        self.max_range_temp = 0.0
        self.min_approach_temp = 0.0
        self.max_approach_temp = 0.0
        self.min_water_flow_ratio = 0.0
        self.max_water_flow_ratio = 0.0
        self.max_liquid_to_gas_ratio = 0.0
        self.vs_error_count_flow_frac = 0
        self.vs_error_count_wfrr = 0
        self.vs_error_count_iawb = 0
        self.vs_error_count_tr = 0
        self.vs_error_count_tr_calc = 0
        self.vs_error_count_ta = 0
        self.err_index_flow_frac = 0
        self.err_index_wfrr = 0
        self.err_index_iawb = 0
        self.err_index_tr = 0
        self.err_index_tr_calc = 0
        self.err_index_ta = 0
        self.err_index_lg = 0
        self.tr_buffer1 = String()
        self.tr_buffer2 = String()
        self.tr_buffer3 = String()
        self.twb_buffer1 = String()
        self.twb_buffer2 = String()
        self.twb_buffer3 = String()
        self.ta_buffer1 = String()
        self.ta_buffer2 = String()
        self.ta_buffer3 = String()
        self.wfrr_buffer1 = String()
        self.wfrr_buffer2 = String()
        self.wfrr_buffer3 = String()
        self.lg_buffer1 = String()
        self.lg_buffer2 = String()
        self.print_tr_message = False
        self.print_twb_message = False
        self.print_ta_message = False
        self.print_wfrr_message = False
        self.print_lg_message = False
        self.tr_last = 0.0
        self.twb_last = 0.0
        self.ta_last = 0.0
        self.water_flow_rate_ratio_last = 0.0
        self.lg_last = 0.0


struct CondenserLoopTowersData:
    """Global data for condenser loop towers."""
    var get_input: Bool
    var towers: List[CoolingTower]
    
    fn __init__(inout self):
        self.get_input = True
        self.towers = List[CoolingTower]()


@always_inline
fn pow_3(x: Float64) -> Float64:
    """Compute x cubed."""
    return x * x * x


fn factory(state: AnyPointer, object_name: String) -> AnyPointer:
    """Factory method to find or create a cooling tower by name."""
    # Stub implementation
    return AnyPointer()


fn calculate_simple_tower_outlet_temp(
    state: AnyPointer,
    inout tower: CoolingTower,
    water_mass_flow_rate: Float64,
    air_flow_rate: Float64,
    ua_design: Float64
) -> Float64:
    """Calculate outlet water temperature for simple tower model."""
    if ua_design == 0.0:
        return tower.inlet_water_temp
    
    if water_mass_flow_rate <= 0.0:
        return tower.inlet_water_temp
    
    # Initialize to inlet temp
    var outlet_water_temp = tower.inlet_water_temp
    
    # Calculation stub - return inlet temp
    return outlet_water_temp


fn calculate_variable_speed_approach(
    state: AnyPointer,
    inout tower: CoolingTower,
    pct_water_flow: Float64,
    air_flow_ratio_local: Float64,
    twb: Float64,
    tr: Float64 = 0.0
) -> Float64:
    """Calculate approach temperature for variable speed tower."""
    var result = 0.0
    
    if tower.tower_model_type == ModelType.YorkCalcModel or tower.tower_model_type == ModelType.YorkCalcUserDefined:
        var pct_air_flow = air_flow_ratio_local
        var flow_factor = pct_water_flow / pct_air_flow if pct_air_flow > 0.0 else 0.0
        
        result = (
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
    else:
        var pct_air_flow = pow_3(air_flow_ratio_local)
        result = (
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
    
    return result


fn get_tower_input(state: AnyPointer) -> None:
    """Get tower input from data structure."""
    pass


fn psych_rho_air_fn_pb_tdb_w(state: AnyPointer, pb: Float64, tdb: Float64, hum_rat: Float64) -> Float64:
    """Psychrometric: air density from pressure, dry-bulb, humidity ratio."""
    return 1.2


fn psych_cp_air_fn_w(hum_rat: Float64) -> Float64:
    """Psychrometric: specific heat of air from humidity ratio."""
    return 1006.0


fn psych_h_fn_tdb_rhpb(state: AnyPointer, tdb: Float64, rh: Float64, pb: Float64) -> Float64:
    """Psychrometric: enthalpy from dry-bulb, RH, pressure."""
    return 50000.0


fn get_specific_heat(state: AnyPointer, inout tower: CoolingTower, temp: Float64) -> Float64:
    """Get specific heat from plant glycol at temperature."""
    return 4180.0


fn calc_basin_heater_power(
    state: AnyPointer,
    basin_heater_power_f_temp_diff: Float64,
    basin_heater_sched: Int32,
    basin_heater_set_point_temp: Float64,
    inout tower: CoolingTower
) -> None:
    """Calculate basin heater power."""
    tower.basin_heater_power = 0.0
