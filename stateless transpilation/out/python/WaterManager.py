from typing import Protocol, Optional, List
from dataclasses import dataclass, field
from enum import IntEnum
import math

# EXTERNAL DEPS (stubs — wire these in at runtime)
class ControlSupplyType(IntEnum):
    Invalid = -1
    NoControlLevel = 0
    MainsFloatValve = 1
    WellFloatValve = 2
    WellFloatMainsBackup = 3
    OtherTankFloatValve = 4
    TankMainsBackup = 5
    Num = 6

class TankThermalMode(IntEnum):
    Invalid = -1
    Scheduled = 0
    ZoneCoupled = 1
    Num = 2

class AmbientTempType(IntEnum):
    Invalid = -1
    Schedule = 0
    Zone = 1
    Outdoors = 2
    Num = 3

class RainLossFactor(IntEnum):
    Invalid = -1
    Constant = 0
    Scheduled = 1
    Num = 2

class GroundWaterTable(IntEnum):
    Invalid = -1
    Constant = 0
    Scheduled = 1
    Num = 2

class IrrigationMode(IntEnum):
    Invalid = -1
    SchedDesign = 0
    SmartSched = 1
    Num = 2

class RainfallMode(IntEnum):
    None_ = 0
    RainSchedDesign = 1
    EPWPrecipitation = 2
    Num = 3

class Overflow(IntEnum):
    Invalid = -1
    Discarded = 0
    ToTank = 1
    Num = 2

@dataclass
class WaterManagerData:
    my_one_time_flag: bool = True
    get_input_flag: bool = True
    my_envrrn_flag: bool = True
    my_warmup_flag: bool = False
    my_tank_demand_check_flag: bool = True
    overflow_twater: float = 0.0

    def clear_state(self):
        self.my_one_time_flag = True
        self.get_input_flag = True
        self.my_envrrn_flag = True
        self.my_warmup_flag = False
        self.my_tank_demand_check_flag = True
        self.overflow_twater = 0.0

# Protocol for external EnergyPlusData with required attributes
class EnergyPlusDataProtocol(Protocol):
    dataWaterManager: WaterManagerData
    dataWaterData: object
    dataInputProcessing: object
    dataEnvrn: object
    dataGlobal: object
    dataHeatBal: object
    dataSurface: object
    dataHVACGlobal: object
    dataEcoRoofMgr: object
    dataConstruction: object
    dataOutRptPredefined: object
    dataIPShortCuts: object

# Constants
CONTROL_SUPPLY_TYPE_NAMES_UC = [
    "NONE", "MAINS", "GROUNDWATERWELL", "GROUNDWATERWELLMAINSBACKUP", "OTHERTANK", "OTHERTANKMAINSBACKUP"
]
TANK_THERMAL_MODE_NAMES_UC = ["SCHEDULEDTEMPERATURE", "THERMALMODEL"]
AMBIENT_TEMP_TYPE_NAMES_UC = ["SCHEDULE", "ZONE", "OUTDOORS"]
RAIN_LOSS_FACTOR_NAMES_UC = ["CONSTANT", "SCHEDULED"]
GROUND_WATER_TABLE_NAMES_UC = ["CONSTANT", "SCHEDULED"]
IRRIGATION_MODE_NAMES_UC = ["SCHEDULE", "SMARTSCHEDULE"]

BIG_NUMBER = 1.0e38
RSECS_IN_HOUR = 1.0 / 3600.0

def manage_water(state: EnergyPlusDataProtocol) -> None:
    if state.dataWaterManager.get_input_flag:
        get_water_manager_input(state)
        state.dataWaterManager.get_input_flag = False
    
    if not state.dataWaterData.any_water_systems_in_model:
        return
    
    # First pass: water storage tanks
    for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
        calc_water_storage_tank(state, tank_num)
    
    # Rain collectors
    for rain_col_num in range(1, state.dataWaterData.num_rain_collectors + 1):
        calc_rain_collector(state, rain_col_num)
    
    # Groundwater wells
    for well_num in range(1, state.dataWaterData.num_ground_water_wells + 1):
        calc_groundwater_well(state, well_num)
    
    # Second pass: tanks again for updated rain and well activity
    for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
        calc_water_storage_tank(state, tank_num)

def manage_water_inits(state: EnergyPlusDataProtocol) -> None:
    if not state.dataWaterData.any_water_systems_in_model:
        return
    
    update_water_manager(state)
    update_irrigation(state)

def get_water_manager_input(state: EnergyPlusDataProtocol) -> None:
    if not (state.dataWaterManager.my_one_time_flag and not state.dataWaterData.water_system_get_input_called):
        return
    
    routine_name = "GetWaterManagerInput"
    
    state.dataWaterData.rain_fall.mode_id = RainfallMode.None_
    
    # Placeholder: simplified input processing
    # In full implementation, would call inputProcessor methods to read input
    # For now, initialize key counts to 0
    state.dataWaterData.num_water_storage_tanks = 0
    state.dataWaterData.num_rain_collectors = 0
    state.dataWaterData.num_ground_water_wells = 0
    state.dataWaterData.num_site_rain_fall = 0
    
    state.dataWaterData.any_water_systems_in_model = False
    state.dataWaterData.water_system_get_input_called = True
    state.dataWaterManager.my_one_time_flag = False

def update_precipitation(state: EnergyPlusDataProtocol) -> None:
    if state.dataWaterData.rain_fall.mode_id == RainfallMode.RainSchedDesign:
        sched_rate = state.dataWaterData.rain_fall.rain_sched.get_current_val()
        if state.dataWaterData.rain_fall.nom_annual_rain > 0.0:
            scale_factor = state.dataWaterData.rain_fall.design_annual_rain / state.dataWaterData.rain_fall.nom_annual_rain
        else:
            scale_factor = 0.0
        state.dataWaterData.rain_fall.current_rate = sched_rate * scale_factor * RSECS_IN_HOUR
    else:
        if state.dataEnvrn.liquid_precipitation > 0.0:
            state.dataWaterData.rain_fall.current_rate = state.dataEnvrn.liquid_precipitation / state.dataGlobal.time_step_zone_sec
        else:
            state.dataWaterData.rain_fall.current_rate = 0.0
    
    state.dataWaterData.rain_fall.current_amount = state.dataWaterData.rain_fall.current_rate * state.dataGlobal.time_step_zone_sec
    state.dataEcoRoofMgr.current_precipitation = state.dataWaterData.rain_fall.current_amount
    
    if state.dataWaterData.rain_fall.mode_id == RainfallMode.RainSchedDesign:
        if state.dataEnvrn.run_period_environment and not state.dataGlobal.warmup_flag:
            month = state.dataEnvrn.month
            state.dataWaterData.rain_fall.monthly_total_prec_in_site_prec[month - 1] += state.dataWaterData.rain_fall.current_amount * 1000.0

def update_irrigation(state: EnergyPlusDataProtocol) -> None:
    time_step_sys = state.dataHVACGlobal.time_step_sys
    state.dataWaterData.irrigation.scheduled_amount = 0.0
    
    if state.dataWaterData.irrigation.mode_id == IrrigationMode.SchedDesign:
        sched_rate = state.dataWaterData.irrigation.irr_sched.get_current_val()
        state.dataWaterData.irrigation.scheduled_amount = sched_rate * time_step_sys
    elif state.dataWaterData.irrigation.mode_id == IrrigationMode.SmartSched:
        sched_rate = state.dataWaterData.irrigation.irr_sched.get_current_val()
        state.dataWaterData.irrigation.scheduled_amount = sched_rate * time_step_sys

def calc_water_storage_tank(state: EnergyPlusDataProtocol, tank_num: int) -> None:
    time_step_sys_sec = state.dataHVACGlobal.time_step_sys_sec
    
    orig_vdot_supply_avail = 0.0
    tot_vdot_supply_avail = 0.0
    
    if state.dataWaterData.water_storage[tank_num - 1].num_water_supplies > 0:
        orig_vdot_supply_avail = sum(state.dataWaterData.water_storage[tank_num - 1].vdot_avail_supply)
    tot_vdot_supply_avail = orig_vdot_supply_avail
    
    overflow_vdot = 0.0
    if tot_vdot_supply_avail > state.dataWaterData.water_storage[tank_num - 1].max_in_flow_rate:
        overflow_vdot = tot_vdot_supply_avail - state.dataWaterData.water_storage[tank_num - 1].max_in_flow_rate
        if sum(state.dataWaterData.water_storage[tank_num - 1].vdot_avail_supply) > 0:
            state.dataWaterManager.overflow_twater = (
                sum(v * t for v, t in zip(
                    state.dataWaterData.water_storage[tank_num - 1].vdot_avail_supply,
                    state.dataWaterData.water_storage[tank_num - 1].twater_supply
                )) / sum(state.dataWaterData.water_storage[tank_num - 1].vdot_avail_supply)
            )
        tot_vdot_supply_avail = state.dataWaterData.water_storage[tank_num - 1].max_in_flow_rate
    
    tot_vol_supply_avail = tot_vdot_supply_avail * time_step_sys_sec
    overflow_vol = overflow_vdot * time_step_sys_sec
    
    orig_vdot_demand_request = 0.0
    if state.dataWaterData.water_storage[tank_num - 1].num_water_demands > 0:
        orig_vdot_demand_request = sum(state.dataWaterData.water_storage[tank_num - 1].vdot_request_demand)
    
    orig_vol_demand_request = orig_vdot_demand_request * time_step_sys_sec
    tot_vdot_demand_avail = orig_vdot_demand_request
    
    underflow_vdot = 0.0
    if tot_vdot_demand_avail > state.dataWaterData.water_storage[tank_num - 1].max_out_flow_rate:
        underflow_vdot = orig_vdot_demand_request - state.dataWaterData.water_storage[tank_num - 1].max_out_flow_rate
        tot_vdot_demand_avail = state.dataWaterData.water_storage[tank_num - 1].max_out_flow_rate
    
    tot_vol_demand_avail = tot_vdot_demand_avail * time_step_sys_sec
    net_vdot_add = tot_vdot_supply_avail - tot_vdot_demand_avail
    net_vol_add = net_vdot_add * time_step_sys_sec
    
    volume_predict = state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume + net_vol_add
    
    if volume_predict > state.dataWaterData.water_storage[tank_num - 1].max_capacity:
        over_fill_volume = volume_predict - state.dataWaterData.water_storage[tank_num - 1].max_capacity
        state.dataWaterManager.overflow_twater = (
            (state.dataWaterManager.overflow_twater * overflow_vol + 
             over_fill_volume * state.dataWaterData.water_storage[tank_num - 1].twater) /
            (overflow_vol + over_fill_volume)
        )
        overflow_vol += over_fill_volume
        net_vol_add -= over_fill_volume
        net_vdot_add = net_vol_add / time_step_sys_sec
        volume_predict = state.dataWaterData.water_storage[tank_num - 1].max_capacity
    
    if volume_predict < 0.0:
        avail_volume = state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume + tot_vol_supply_avail
        avail_volume = max(0.0, avail_volume)
        tot_vol_demand_avail = avail_volume
        tot_vdot_demand_avail = avail_volume / time_step_sys_sec
        underflow_vdot = orig_vdot_demand_request - tot_vdot_demand_avail
        net_vdot_add = tot_vdot_supply_avail - tot_vdot_demand_avail
        net_vol_add = net_vdot_add * time_step_sys_sec
        volume_predict = 0.0
    
    if tot_vdot_demand_avail < orig_vdot_demand_request:
        if orig_vdot_demand_request > 0.0:
            ratio = tot_vdot_demand_avail / orig_vdot_demand_request
            state.dataWaterData.water_storage[tank_num - 1].vdot_avail_demand = [
                v * ratio for v in state.dataWaterData.water_storage[tank_num - 1].vdot_request_demand
            ]
        else:
            state.dataWaterData.water_storage[tank_num - 1].vdot_avail_demand = [0.0] * len(
                state.dataWaterData.water_storage[tank_num - 1].vdot_request_demand
            )
    else:
        if state.dataWaterData.water_storage[tank_num - 1].num_water_demands > 0:
            state.dataWaterData.water_storage[tank_num - 1].vdot_avail_demand = state.dataWaterData.water_storage[tank_num - 1].vdot_request_demand[:]
    
    fill_vol_request = 0.0
    
    if volume_predict < state.dataWaterData.water_storage[tank_num - 1].valve_on_capacity or state.dataWaterData.water_storage[tank_num - 1].last_time_step_filling:
        fill_vol_request = state.dataWaterData.water_storage[tank_num - 1].valve_off_capacity - volume_predict
        state.dataWaterData.water_storage[tank_num - 1].last_time_step_filling = True
        
        if state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.MainsFloatValve:
            state.dataWaterData.water_storage[tank_num - 1].mains_draw_vdot = fill_vol_request / time_step_sys_sec
            net_vol_add = fill_vol_request
        
        if (state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.OtherTankFloatValve or
            state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.TankMainsBackup):
            supply_tank_id = state.dataWaterData.water_storage[tank_num - 1].supply_tank_id
            demand_idx = state.dataWaterData.water_storage[tank_num - 1].supply_tank_demand_arr_id
            state.dataWaterData.water_storage[supply_tank_id - 1].vdot_request_demand[demand_idx - 1] = fill_vol_request / time_step_sys_sec
        
        if (state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatValve or
            state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup):
            well_id = state.dataWaterData.water_storage[tank_num - 1].ground_well_id
            state.dataWaterData.groundwater_well[well_id - 1].vdot_request = fill_vol_request / time_step_sys_sec
    
    if volume_predict < state.dataWaterData.water_storage[tank_num - 1].backup_mains_capacity:
        if (state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup or
            state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.TankMainsBackup):
            fill_vol_request = state.dataWaterData.water_storage[tank_num - 1].valve_off_capacity - volume_predict
            state.dataWaterData.water_storage[tank_num - 1].mains_draw_vdot = fill_vol_request / time_step_sys_sec
            net_vol_add = fill_vol_request
    
    state.dataWaterData.water_storage[tank_num - 1].this_time_step_volume = state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume + net_vol_add
    if state.dataWaterData.water_storage[tank_num - 1].this_time_step_volume >= state.dataWaterData.water_storage[tank_num - 1].valve_off_capacity:
        state.dataWaterData.water_storage[tank_num - 1].last_time_step_filling = False
    
    state.dataWaterData.water_storage[tank_num - 1].vdot_overflow = overflow_vol / time_step_sys_sec
    state.dataWaterData.water_storage[tank_num - 1].vol_overflow = overflow_vol
    state.dataWaterData.water_storage[tank_num - 1].twater_overflow = state.dataWaterManager.overflow_twater
    state.dataWaterData.water_storage[tank_num - 1].net_vdot = net_vol_add / time_step_sys_sec
    state.dataWaterData.water_storage[tank_num - 1].mains_draw_vol = state.dataWaterData.water_storage[tank_num - 1].mains_draw_vdot * time_step_sys_sec
    state.dataWaterData.water_storage[tank_num - 1].vdot_to_tank = tot_vdot_supply_avail
    state.dataWaterData.water_storage[tank_num - 1].vdot_from_tank = tot_vdot_demand_avail
    
    if state.dataWaterData.water_storage[tank_num - 1].thermal_mode == TankThermalMode.Scheduled:
        state.dataWaterData.water_storage[tank_num - 1].twater = state.dataWaterData.water_storage[tank_num - 1].temp_sched.get_current_val()
        state.dataWaterData.water_storage[tank_num - 1].touter_skin = state.dataWaterData.water_storage[tank_num - 1].twater
    elif state.dataWaterData.water_storage[tank_num - 1].thermal_mode == TankThermalMode.ZoneCoupled:
        raise RuntimeError("WaterUse:Storage zone thermal model incomplete")
    
    if state.dataWaterData.water_storage[tank_num - 1].overflow_mode == Overflow.ToTank:
        overflow_tank_id = state.dataWaterData.water_storage[tank_num - 1].overflow_tank_id
        supply_idx = state.dataWaterData.water_storage[tank_num - 1].overflow_tank_supply_arr_id
        state.dataWaterData.water_storage[overflow_tank_id - 1].vdot_avail_supply[supply_idx - 1] = state.dataWaterData.water_storage[tank_num - 1].vdot_overflow
        state.dataWaterData.water_storage[overflow_tank_id - 1].twater_supply[supply_idx - 1] = state.dataWaterData.water_storage[tank_num - 1].twater_overflow

def setup_tank_supply_component(state: EnergyPlusDataProtocol, comp_name: str, comp_type: str, tank_name: str, errors_found: List[bool], tank_index: List[int], water_supply_index: List[int]) -> None:
    if not state.dataWaterData.water_system_get_input_called:
        get_water_manager_input(state)
    
    internal_setup_tank_supply_component(state, comp_name, comp_type, tank_name, errors_found, tank_index, water_supply_index)

def internal_setup_tank_supply_component(state: EnergyPlusDataProtocol, comp_name: str, comp_type: str, tank_name: str, errors_found: List[bool], tank_index: List[int], water_supply_index: List[int]) -> None:
    tank_idx = find_item_in_list(tank_name, state.dataWaterData.water_storage)
    if tank_idx == 0:
        errors_found[0] = True
        return
    
    tank_index[0] = tank_idx
    old_num_supply = state.dataWaterData.water_storage[tank_idx - 1].num_water_supplies
    
    if old_num_supply > 0:
        state.dataWaterData.water_storage[tank_idx - 1].supply_comp_names.append(comp_name)
        state.dataWaterData.water_storage[tank_idx - 1].supply_comp_types.append(comp_type)
        state.dataWaterData.water_storage[tank_idx - 1].vdot_avail_supply.append(0.0)
        state.dataWaterData.water_storage[tank_idx - 1].twater_supply.append(0.0)
        water_supply_index[0] = old_num_supply + 1
        state.dataWaterData.water_storage[tank_idx - 1].num_water_supplies += 1
    else:
        state.dataWaterData.water_storage[tank_idx - 1].vdot_avail_supply = [0.0]
        state.dataWaterData.water_storage[tank_idx - 1].twater_supply = [0.0]
        state.dataWaterData.water_storage[tank_idx - 1].supply_comp_names = [comp_name]
        state.dataWaterData.water_storage[tank_idx - 1].supply_comp_types = [comp_type]
        water_supply_index[0] = 1
        state.dataWaterData.water_storage[tank_idx - 1].num_water_supplies = 1

def setup_tank_demand_component(state: EnergyPlusDataProtocol, comp_name: str, comp_type: str, tank_name: str, errors_found: List[bool], tank_index: List[int], water_demand_index: List[int]) -> None:
    if not state.dataWaterData.water_system_get_input_called:
        get_water_manager_input(state)
    
    internal_setup_tank_demand_component(state, comp_name, comp_type, tank_name, errors_found, tank_index, water_demand_index)

def internal_setup_tank_demand_component(state: EnergyPlusDataProtocol, comp_name: str, comp_type: str, tank_name: str, errors_found: List[bool], tank_index: List[int], water_demand_index: List[int]) -> None:
    tank_idx = find_item_in_list(tank_name, state.dataWaterData.water_storage)
    if tank_idx == 0:
        errors_found[0] = True
        return
    
    tank_index[0] = tank_idx
    old_num_demand = state.dataWaterData.water_storage[tank_idx - 1].num_water_demands
    
    if old_num_demand > 0:
        state.dataWaterData.water_storage[tank_idx - 1].demand_comp_names.append(comp_name)
        state.dataWaterData.water_storage[tank_idx - 1].demand_comp_types.append(comp_type)
        state.dataWaterData.water_storage[tank_idx - 1].vdot_request_demand.append(0.0)
        state.dataWaterData.water_storage[tank_idx - 1].vdot_avail_demand.append(0.0)
        water_demand_index[0] = old_num_demand + 1
        state.dataWaterData.water_storage[tank_idx - 1].num_water_demands += 1
    else:
        state.dataWaterData.water_storage[tank_idx - 1].vdot_request_demand = [0.0]
        state.dataWaterData.water_storage[tank_idx - 1].vdot_avail_demand = [0.0]
        state.dataWaterData.water_storage[tank_idx - 1].demand_comp_names = [comp_name]
        state.dataWaterData.water_storage[tank_idx - 1].demand_comp_types = [comp_type]
        water_demand_index[0] = 1
        state.dataWaterData.water_storage[tank_idx - 1].num_water_demands = 1

def calc_rain_collector(state: EnergyPlusDataProtocol, rain_col_num: int) -> None:
    time_step_sys_sec = state.dataHVACGlobal.time_step_sys_sec
    
    if state.dataWaterData.rain_fall.current_rate <= 0.0:
        tank_id = state.dataWaterData.rain_collector[rain_col_num - 1].storage_tank_id
        supply_idx = state.dataWaterData.rain_collector[rain_col_num - 1].storage_tank_supply_arr_id
        state.dataWaterData.water_storage[tank_id - 1].vdot_avail_supply[supply_idx - 1] = 0.0
        state.dataWaterData.water_storage[tank_id - 1].twater_supply[supply_idx - 1] = 0.0
        state.dataWaterData.rain_collector[rain_col_num - 1].vdot_avail = 0.0
        state.dataWaterData.rain_collector[rain_col_num - 1].vol_collected = 0.0
    else:
        if state.dataWaterData.rain_collector[rain_col_num - 1].loss_factor_mode == RainLossFactor.Constant:
            loss_factor = state.dataWaterData.rain_collector[rain_col_num - 1].loss_factor
        elif state.dataWaterData.rain_collector[rain_col_num - 1].loss_factor_mode == RainLossFactor.Scheduled:
            loss_factor = state.dataWaterData.rain_collector[rain_col_num - 1].loss_factor_sched.get_current_val()
        else:
            loss_factor = 0.0
        
        vdot_avail = (state.dataWaterData.rain_fall.current_rate * 
                     state.dataWaterData.rain_collector[rain_col_num - 1].horiz_area * 
                     (1.0 - loss_factor))
        
        if vdot_avail > state.dataWaterData.rain_collector[rain_col_num - 1].max_collect_rate:
            vdot_avail = state.dataWaterData.rain_collector[rain_col_num - 1].max_collect_rate
        
        tank_id = state.dataWaterData.rain_collector[rain_col_num - 1].storage_tank_id
        supply_idx = state.dataWaterData.rain_collector[rain_col_num - 1].storage_tank_supply_arr_id
        state.dataWaterData.water_storage[tank_id - 1].vdot_avail_supply[supply_idx - 1] = vdot_avail
        state.dataWaterData.water_storage[tank_id - 1].twater_supply[supply_idx - 1] = state.dataEnvrn.out_wet_bulb_temp
        
        state.dataWaterData.rain_collector[rain_col_num - 1].vdot_avail = vdot_avail
        state.dataWaterData.rain_collector[rain_col_num - 1].vol_collected = vdot_avail * time_step_sys_sec
        
        if state.dataEnvrn.run_period_environment and not state.dataGlobal.warmup_flag:
            month = state.dataEnvrn.month
            state.dataWaterData.rain_collector[rain_col_num - 1].vol_collected_monthly[month - 1] += state.dataWaterData.rain_collector[rain_col_num - 1].vol_collected

def calc_groundwater_well(state: EnergyPlusDataProtocol, well_num: int) -> None:
    time_step_sys_sec = state.dataHVACGlobal.time_step_sys_sec
    
    vdot_delivered = 0.0
    pump_power = 0.0
    
    if state.dataWaterData.groundwater_well[well_num - 1].vdot_request > 0.0:
        if state.dataWaterData.groundwater_well[well_num - 1].vdot_request >= state.dataWaterData.groundwater_well[well_num - 1].pump_nom_vol_flow_rate:
            tank_id = state.dataWaterData.groundwater_well[well_num - 1].storage_tank_id
            supply_idx = state.dataWaterData.groundwater_well[well_num - 1].storage_tank_supply_arr_id
            state.dataWaterData.water_storage[tank_id - 1].vdot_avail_supply[supply_idx - 1] = state.dataWaterData.groundwater_well[well_num - 1].pump_nom_vol_flow_rate
            state.dataWaterData.water_storage[tank_id - 1].twater_supply[supply_idx - 1] = state.dataEnvrn.ground_temp_deep
            vdot_delivered = state.dataWaterData.groundwater_well[well_num - 1].pump_nom_vol_flow_rate
            pump_power = state.dataWaterData.groundwater_well[well_num - 1].pump_nom_power_use
        
        if state.dataWaterData.groundwater_well[well_num - 1].vdot_request < state.dataWaterData.groundwater_well[well_num - 1].pump_nom_vol_flow_rate:
            tank_id = state.dataWaterData.groundwater_well[well_num - 1].storage_tank_id
            supply_idx = state.dataWaterData.groundwater_well[well_num - 1].storage_tank_supply_arr_id
            state.dataWaterData.water_storage[tank_id - 1].vdot_avail_supply[supply_idx - 1] = state.dataWaterData.groundwater_well[well_num - 1].vdot_request
            state.dataWaterData.water_storage[tank_id - 1].twater_supply[supply_idx - 1] = state.dataEnvrn.ground_temp_deep
            vdot_delivered = state.dataWaterData.groundwater_well[well_num - 1].vdot_request
            pump_power = (state.dataWaterData.groundwater_well[well_num - 1].pump_nom_power_use * 
                         state.dataWaterData.groundwater_well[well_num - 1].vdot_request / 
                         state.dataWaterData.groundwater_well[well_num - 1].pump_nom_vol_flow_rate)
    
    state.dataWaterData.groundwater_well[well_num - 1].vdot_delivered = vdot_delivered
    state.dataWaterData.groundwater_well[well_num - 1].vol_delivered = vdot_delivered * time_step_sys_sec
    state.dataWaterData.groundwater_well[well_num - 1].pump_power = pump_power
    state.dataWaterData.groundwater_well[well_num - 1].pump_energy = pump_power * time_step_sys_sec

def update_water_manager(state: EnergyPlusDataProtocol) -> None:
    if state.dataGlobal.begin_envrrn_flag and state.dataWaterManager.my_envrrn_flag:
        for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
            state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume = state.dataWaterData.water_storage[tank_num - 1].initial_volume
            state.dataWaterData.water_storage[tank_num - 1].this_time_step_volume = state.dataWaterData.water_storage[tank_num - 1].initial_volume
        
        if (not state.dataGlobal.doing_sizing and not state.dataGlobal.kick_off_simulation and 
            state.dataWaterManager.my_tank_demand_check_flag):
            if state.dataWaterData.num_water_storage_tanks > 0:
                for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
                    if state.dataWaterData.water_storage[tank_num - 1].num_water_demands == 0:
                        pass  # Placeholder for warning
            state.dataWaterManager.my_tank_demand_check_flag = False
        
        state.dataWaterManager.my_envrrn_flag = False
        state.dataWaterManager.my_warmup_flag = True
    
    if not state.dataGlobal.begin_envrrn_flag:
        state.dataWaterManager.my_envrrn_flag = True
    
    if state.dataWaterManager.my_warmup_flag and not state.dataGlobal.warmup_flag:
        for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
            state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume = state.dataWaterData.water_storage[tank_num - 1].initial_volume
            state.dataWaterData.water_storage[tank_num - 1].this_time_step_volume = state.dataWaterData.water_storage[tank_num - 1].initial_volume
            state.dataWaterData.water_storage[tank_num - 1].last_time_step_temp = state.dataWaterData.water_storage[tank_num - 1].initial_tank_temp
        state.dataWaterManager.my_warmup_flag = False
    
    for tank_num in range(1, state.dataWaterData.num_water_storage_tanks + 1):
        state.dataWaterData.water_storage[tank_num - 1].last_time_step_volume = max(state.dataWaterData.water_storage[tank_num - 1].this_time_step_volume, 0.0)
        state.dataWaterData.water_storage[tank_num - 1].mains_draw_vdot = 0.0
        state.dataWaterData.water_storage[tank_num - 1].mains_draw_vol = 0.0
        state.dataWaterData.water_storage[tank_num - 1].net_vdot = 0.0
        state.dataWaterData.water_storage[tank_num - 1].vdot_from_tank = 0.0
        state.dataWaterData.water_storage[tank_num - 1].vdot_to_tank = 0.0
        if state.dataWaterData.water_storage[tank_num - 1].num_water_demands > 0:
            state.dataWaterData.water_storage[tank_num - 1].vdot_avail_demand = [0.0] * state.dataWaterData.water_storage[tank_num - 1].num_water_demands
        state.dataWaterData.water_storage[tank_num - 1].vdot_overflow = 0.0
        if state.dataWaterData.water_storage[tank_num - 1].num_water_supplies > 0:
            state.dataWaterData.water_storage[tank_num - 1].vdot_avail_supply = [0.0] * state.dataWaterData.water_storage[tank_num - 1].num_water_supplies
        
        if (state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatValve or
            state.dataWaterData.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup):
            if state.dataWaterData.groundwater_well:
                well_id = state.dataWaterData.water_storage[tank_num - 1].ground_well_id
                state.dataWaterData.groundwater_well[well_id - 1].vdot_request = 0.0
    
    for rain_col_num in range(1, state.dataWaterData.num_rain_collectors + 1):
        state.dataWaterData.rain_collector[rain_col_num - 1].vdot_avail = 0.0
        state.dataWaterData.rain_collector[rain_col_num - 1].vol_collected = 0.0
    
    for well_num in range(1, state.dataWaterData.num_ground_water_wells + 1):
        state.dataWaterData.groundwater_well[well_num - 1].vdot_request = 0.0
        state.dataWaterData.groundwater_well[well_num - 1].vdot_delivered = 0.0
        state.dataWaterData.groundwater_well[well_num - 1].vol_delivered = 0.0
        state.dataWaterData.groundwater_well[well_num - 1].pump_power = 0.0
        state.dataWaterData.groundwater_well[well_num - 1].pump_energy = 0.0

def report_rainfall(state: EnergyPlusDataProtocol) -> None:
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    for i in range(12):
        pass  # Placeholder for output reporting

# Helper functions
def find_item_in_list(name: str, items: List) -> int:
    for i, item in enumerate(items):
        if hasattr(item, 'name') and item.name == name:
            return i + 1
    return 0
