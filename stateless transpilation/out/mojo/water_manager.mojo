from math import max
from sys import sizeof

# EXTERNAL DEPS (stubs — wire these in at runtime)
@value
struct ControlSupplyType:
    alias Invalid = -1
    alias NoControlLevel = 0
    alias MainsFloatValve = 1
    alias WellFloatValve = 2
    alias WellFloatMainsBackup = 3
    alias OtherTankFloatValve = 4
    alias TankMainsBackup = 5
    alias Num = 6

@value
struct TankThermalMode:
    alias Invalid = -1
    alias Scheduled = 0
    alias ZoneCoupled = 1
    alias Num = 2

@value
struct AmbientTempType:
    alias Invalid = -1
    alias Schedule = 0
    alias Zone = 1
    alias Outdoors = 2
    alias Num = 3

@value
struct RainLossFactor:
    alias Invalid = -1
    alias Constant = 0
    alias Scheduled = 1
    alias Num = 2

@value
struct GroundWaterTable:
    alias Invalid = -1
    alias Constant = 0
    alias Scheduled = 1
    alias Num = 2

@value
struct IrrigationMode:
    alias Invalid = -1
    alias SchedDesign = 0
    alias SmartSched = 1
    alias Num = 2

@value
struct RainfallMode:
    alias None_ = 0
    alias RainSchedDesign = 1
    alias EPWPrecipitation = 2
    alias Num = 3

@value
struct Overflow:
    alias Invalid = -1
    alias Discarded = 0
    alias ToTank = 1
    alias Num = 2

@value
struct WaterManagerData:
    var my_one_time_flag: Bool
    var get_input_flag: Bool
    var my_envrrn_flag: Bool
    var my_warmup_flag: Bool
    var my_tank_demand_check_flag: Bool
    var overflow_twater: Float64

    fn __init__() -> Self:
        return Self(
            my_one_time_flag=True,
            get_input_flag=True,
            my_envrrn_flag=True,
            my_warmup_flag=False,
            my_tank_demand_check_flag=True,
            overflow_twater=0.0,
        )

    fn clear_state(inout self):
        self.my_one_time_flag = True
        self.get_input_flag = True
        self.my_envrrn_flag = True
        self.my_warmup_flag = False
        self.my_tank_demand_check_flag = True
        self.overflow_twater = 0.0

# Protocol for external EnergyPlusData with required attributes
trait EnergyPlusDataProtocol:
    fn get_data_water_manager(self) -> WaterManagerData: ...
    fn get_data_water_data(self) -> object: ...
    fn get_data_input_processing(self) -> object: ...
    fn get_data_envrrn(self) -> object: ...
    fn get_data_global(self) -> object: ...
    fn get_data_heat_bal(self) -> object: ...
    fn get_data_surface(self) -> object: ...
    fn get_data_hvac_global(self) -> object: ...
    fn get_data_eco_roof_mgr(self) -> object: ...
    fn get_data_construction(self) -> object: ...
    fn get_data_out_rpt_predefined(self) -> object: ...

# Constants
fn get_control_supply_type_names_uc() -> InlineArray[StringRef, 6]:
    return InlineArray[StringRef, 6](
        "NONE", "MAINS", "GROUNDWATERWELL", 
        "GROUNDWATERWELLMAINSBACKUP", "OTHERTANK", "OTHERTANKMAINSBACKUP"
    )

fn get_tank_thermal_mode_names_uc() -> InlineArray[StringRef, 2]:
    return InlineArray[StringRef, 2]("SCHEDULEDTEMPERATURE", "THERMALMODEL")

fn get_ambient_temp_type_names_uc() -> InlineArray[StringRef, 3]:
    return InlineArray[StringRef, 3]("SCHEDULE", "ZONE", "OUTDOORS")

fn get_rain_loss_factor_names_uc() -> InlineArray[StringRef, 2]:
    return InlineArray[StringRef, 2]("CONSTANT", "SCHEDULED")

fn get_ground_water_table_names_uc() -> InlineArray[StringRef, 2]:
    return InlineArray[StringRef, 2]("CONSTANT", "SCHEDULED")

fn get_irrigation_mode_names_uc() -> InlineArray[StringRef, 2]:
    return InlineArray[StringRef, 2]("SCHEDULE", "SMARTSCHEDULE")

alias BIG_NUMBER = 1.0e38
alias RSECS_IN_HOUR = 1.0 / 3600.0

@export
fn manage_water(state: EnergyPlusDataProtocol) -> None:
    var data_mgr = state.get_data_water_manager()
    var data_water = state.get_data_water_data()
    
    if data_mgr.get_input_flag:
        get_water_manager_input(state)
        data_mgr.get_input_flag = False
    
    var any_water = data_water.any_water_systems_in_model
    if not any_water:
        return
    
    var num_tanks = data_water.num_water_storage_tanks
    for tank_num in range(1, num_tanks + 1):
        calc_water_storage_tank(state, tank_num)
    
    var num_collectors = data_water.num_rain_collectors
    for rain_col_num in range(1, num_collectors + 1):
        calc_rain_collector(state, rain_col_num)
    
    var num_wells = data_water.num_ground_water_wells
    for well_num in range(1, num_wells + 1):
        calc_groundwater_well(state, well_num)
    
    for tank_num in range(1, num_tanks + 1):
        calc_water_storage_tank(state, tank_num)

@export
fn manage_water_inits(state: EnergyPlusDataProtocol) -> None:
    var data_water = state.get_data_water_data()
    if not data_water.any_water_systems_in_model:
        return
    
    update_water_manager(state)
    update_irrigation(state)

@export
fn get_water_manager_input(state: EnergyPlusDataProtocol) -> None:
    var data_mgr = state.get_data_water_manager()
    var data_water = state.get_data_water_data()
    
    if not (data_mgr.my_one_time_flag and not data_water.water_system_get_input_called):
        return
    
    var routine_name = "GetWaterManagerInput"
    
    data_water.rain_fall.mode_id = RainfallMode.None_
    
    data_water.num_water_storage_tanks = 0
    data_water.num_rain_collectors = 0
    data_water.num_ground_water_wells = 0
    data_water.num_site_rain_fall = 0
    
    data_water.any_water_systems_in_model = False
    data_water.water_system_get_input_called = True
    data_mgr.my_one_time_flag = False

@export
fn update_precipitation(state: EnergyPlusDataProtocol) -> None:
    var data_water = state.get_data_water_data()
    var data_envrrn = state.get_data_envrrn()
    var data_global = state.get_data_global()
    var data_eco_roof = state.get_data_eco_roof_mgr()
    
    if data_water.rain_fall.mode_id == RainfallMode.RainSchedDesign:
        var sched_rate = data_water.rain_fall.rain_sched.get_current_val()
        var scale_factor: Float64
        if data_water.rain_fall.nom_annual_rain > 0.0:
            scale_factor = data_water.rain_fall.design_annual_rain / data_water.rain_fall.nom_annual_rain
        else:
            scale_factor = 0.0
        data_water.rain_fall.current_rate = sched_rate * scale_factor * RSECS_IN_HOUR
    else:
        if data_envrrn.liquid_precipitation > 0.0:
            data_water.rain_fall.current_rate = data_envrrn.liquid_precipitation / data_global.time_step_zone_sec
        else:
            data_water.rain_fall.current_rate = 0.0
    
    data_water.rain_fall.current_amount = data_water.rain_fall.current_rate * data_global.time_step_zone_sec
    data_eco_roof.current_precipitation = data_water.rain_fall.current_amount
    
    if data_water.rain_fall.mode_id == RainfallMode.RainSchedDesign:
        if data_envrrn.run_period_environment and not data_global.warmup_flag:
            var month = data_envrrn.month
            data_water.rain_fall.monthly_total_prec_in_site_prec[month - 1] += data_water.rain_fall.current_amount * 1000.0

@export
fn update_irrigation(state: EnergyPlusDataProtocol) -> None:
    var data_water = state.get_data_water_data()
    var data_hvac = state.get_data_hvac_global()
    
    var time_step_sys = data_hvac.time_step_sys
    data_water.irrigation.scheduled_amount = 0.0
    
    if data_water.irrigation.mode_id == IrrigationMode.SchedDesign:
        var sched_rate = data_water.irrigation.irr_sched.get_current_val()
        data_water.irrigation.scheduled_amount = sched_rate * time_step_sys
    elif data_water.irrigation.mode_id == IrrigationMode.SmartSched:
        var sched_rate = data_water.irrigation.irr_sched.get_current_val()
        data_water.irrigation.scheduled_amount = sched_rate * time_step_sys

@export
fn calc_water_storage_tank(state: EnergyPlusDataProtocol, tank_num: Int) -> None:
    var data_water = state.get_data_water_data()
    var data_hvac = state.get_data_hvac_global()
    var data_mgr = state.get_data_water_manager()
    
    var time_step_sys_sec = data_hvac.time_step_sys_sec
    
    var orig_vdot_supply_avail = 0.0
    var tot_vdot_supply_avail = 0.0
    
    if data_water.water_storage[tank_num - 1].num_water_supplies > 0:
        var supplies = data_water.water_storage[tank_num - 1].vdot_avail_supply
        for i in range(len(supplies)):
            orig_vdot_supply_avail += supplies[i]
    
    tot_vdot_supply_avail = orig_vdot_supply_avail
    
    var overflow_vdot = 0.0
    if tot_vdot_supply_avail > data_water.water_storage[tank_num - 1].max_in_flow_rate:
        overflow_vdot = tot_vdot_supply_avail - data_water.water_storage[tank_num - 1].max_in_flow_rate
        if orig_vdot_supply_avail > 0.0:
            var sum_weighted = 0.0
            var supplies = data_water.water_storage[tank_num - 1].vdot_avail_supply
            var temps = data_water.water_storage[tank_num - 1].twater_supply
            for i in range(len(supplies)):
                sum_weighted += supplies[i] * temps[i]
            data_mgr.overflow_twater = sum_weighted / orig_vdot_supply_avail
        tot_vdot_supply_avail = data_water.water_storage[tank_num - 1].max_in_flow_rate
    
    var tot_vol_supply_avail = tot_vdot_supply_avail * time_step_sys_sec
    var overflow_vol = overflow_vdot * time_step_sys_sec
    
    var orig_vdot_demand_request = 0.0
    if data_water.water_storage[tank_num - 1].num_water_demands > 0:
        var demands = data_water.water_storage[tank_num - 1].vdot_request_demand
        for i in range(len(demands)):
            orig_vdot_demand_request += demands[i]
    
    var orig_vol_demand_request = orig_vdot_demand_request * time_step_sys_sec
    var tot_vdot_demand_avail = orig_vdot_demand_request
    
    var underflow_vdot = 0.0
    if tot_vdot_demand_avail > data_water.water_storage[tank_num - 1].max_out_flow_rate:
        underflow_vdot = orig_vdot_demand_request - data_water.water_storage[tank_num - 1].max_out_flow_rate
        tot_vdot_demand_avail = data_water.water_storage[tank_num - 1].max_out_flow_rate
    
    var tot_vol_demand_avail = tot_vdot_demand_avail * time_step_sys_sec
    var net_vdot_add = tot_vdot_supply_avail - tot_vdot_demand_avail
    var net_vol_add = net_vdot_add * time_step_sys_sec
    
    var volume_predict = data_water.water_storage[tank_num - 1].last_time_step_volume + net_vol_add
    
    if volume_predict > data_water.water_storage[tank_num - 1].max_capacity:
        var over_fill_volume = volume_predict - data_water.water_storage[tank_num - 1].max_capacity
        data_mgr.overflow_twater = (
            (data_mgr.overflow_twater * overflow_vol + 
             over_fill_volume * data_water.water_storage[tank_num - 1].twater) /
            (overflow_vol + over_fill_volume)
        )
        overflow_vol += over_fill_volume
        net_vol_add -= over_fill_volume
        net_vdot_add = net_vol_add / time_step_sys_sec
        volume_predict = data_water.water_storage[tank_num - 1].max_capacity
    
    if volume_predict < 0.0:
        var avail_volume = data_water.water_storage[tank_num - 1].last_time_step_volume + tot_vol_supply_avail
        avail_volume = max(0.0, avail_volume)
        tot_vol_demand_avail = avail_volume
        tot_vdot_demand_avail = avail_volume / time_step_sys_sec
        underflow_vdot = orig_vdot_demand_request - tot_vdot_demand_avail
        net_vdot_add = tot_vdot_supply_avail - tot_vdot_demand_avail
        net_vol_add = net_vdot_add * time_step_sys_sec
        volume_predict = 0.0
    
    if tot_vdot_demand_avail < orig_vdot_demand_request:
        if orig_vdot_demand_request > 0.0:
            var ratio = tot_vdot_demand_avail / orig_vdot_demand_request
            var demands = data_water.water_storage[tank_num - 1].vdot_request_demand
            var avail_demands = data_water.water_storage[tank_num - 1].vdot_avail_demand
            for i in range(len(demands)):
                avail_demands[i] = demands[i] * ratio
        else:
            var avail_demands = data_water.water_storage[tank_num - 1].vdot_avail_demand
            for i in range(len(avail_demands)):
                avail_demands[i] = 0.0
    else:
        if data_water.water_storage[tank_num - 1].num_water_demands > 0:
            var demands = data_water.water_storage[tank_num - 1].vdot_request_demand
            var avail_demands = data_water.water_storage[tank_num - 1].vdot_avail_demand
            for i in range(len(demands)):
                avail_demands[i] = demands[i]
    
    var fill_vol_request = 0.0
    
    if (volume_predict < data_water.water_storage[tank_num - 1].valve_on_capacity or 
        data_water.water_storage[tank_num - 1].last_time_step_filling):
        fill_vol_request = data_water.water_storage[tank_num - 1].valve_off_capacity - volume_predict
        data_water.water_storage[tank_num - 1].last_time_step_filling = True
        
        if data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.MainsFloatValve:
            data_water.water_storage[tank_num - 1].mains_draw_vdot = fill_vol_request / time_step_sys_sec
            net_vol_add = fill_vol_request
        
        if (data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.OtherTankFloatValve or
            data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.TankMainsBackup):
            var supply_tank_id = data_water.water_storage[tank_num - 1].supply_tank_id
            var demand_idx = data_water.water_storage[tank_num - 1].supply_tank_demand_arr_id
            var demands = data_water.water_storage[supply_tank_id - 1].vdot_request_demand
            demands[demand_idx - 1] = fill_vol_request / time_step_sys_sec
        
        if (data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatValve or
            data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup):
            var well_id = data_water.water_storage[tank_num - 1].ground_well_id
            data_water.groundwater_well[well_id - 1].vdot_request = fill_vol_request / time_step_sys_sec
    
    if volume_predict < data_water.water_storage[tank_num - 1].backup_mains_capacity:
        if (data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup or
            data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.TankMainsBackup):
            fill_vol_request = data_water.water_storage[tank_num - 1].valve_off_capacity - volume_predict
            data_water.water_storage[tank_num - 1].mains_draw_vdot = fill_vol_request / time_step_sys_sec
            net_vol_add = fill_vol_request
    
    data_water.water_storage[tank_num - 1].this_time_step_volume = data_water.water_storage[tank_num - 1].last_time_step_volume + net_vol_add
    if data_water.water_storage[tank_num - 1].this_time_step_volume >= data_water.water_storage[tank_num - 1].valve_off_capacity:
        data_water.water_storage[tank_num - 1].last_time_step_filling = False
    
    data_water.water_storage[tank_num - 1].vdot_overflow = overflow_vol / time_step_sys_sec
    data_water.water_storage[tank_num - 1].vol_overflow = overflow_vol
    data_water.water_storage[tank_num - 1].twater_overflow = data_mgr.overflow_twater
    data_water.water_storage[tank_num - 1].net_vdot = net_vol_add / time_step_sys_sec
    data_water.water_storage[tank_num - 1].mains_draw_vol = data_water.water_storage[tank_num - 1].mains_draw_vdot * time_step_sys_sec
    data_water.water_storage[tank_num - 1].vdot_to_tank = tot_vdot_supply_avail
    data_water.water_storage[tank_num - 1].vdot_from_tank = tot_vdot_demand_avail
    
    if data_water.water_storage[tank_num - 1].thermal_mode == TankThermalMode.Scheduled:
        data_water.water_storage[tank_num - 1].twater = data_water.water_storage[tank_num - 1].temp_sched.get_current_val()
        data_water.water_storage[tank_num - 1].touter_skin = data_water.water_storage[tank_num - 1].twater
    elif data_water.water_storage[tank_num - 1].thermal_mode == TankThermalMode.ZoneCoupled:
        raise Error("WaterUse:Storage zone thermal model incomplete")
    
    if data_water.water_storage[tank_num - 1].overflow_mode == Overflow.ToTank:
        var overflow_tank_id = data_water.water_storage[tank_num - 1].overflow_tank_id
        var supply_idx = data_water.water_storage[tank_num - 1].overflow_tank_supply_arr_id
        var supplies = data_water.water_storage[overflow_tank_id - 1].vdot_avail_supply
        supplies[supply_idx - 1] = data_water.water_storage[tank_num - 1].vdot_overflow
        var temps = data_water.water_storage[overflow_tank_id - 1].twater_supply
        temps[supply_idx - 1] = data_water.water_storage[tank_num - 1].twater_overflow

@export
fn setup_tank_supply_component(
    state: EnergyPlusDataProtocol,
    comp_name: StringRef,
    comp_type: StringRef,
    tank_name: StringRef,
    errors_found: Pointer[Bool],
    tank_index: Pointer[Int],
    water_supply_index: Pointer[Int],
) -> None:
    var data_water = state.get_data_water_data()
    if not data_water.water_system_get_input_called:
        get_water_manager_input(state)
    
    internal_setup_tank_supply_component(state, comp_name, comp_type, tank_name, errors_found, tank_index, water_supply_index)

@export
fn internal_setup_tank_supply_component(
    state: EnergyPlusDataProtocol,
    comp_name: StringRef,
    comp_type: StringRef,
    tank_name: StringRef,
    errors_found: Pointer[Bool],
    tank_index: Pointer[Int],
    water_supply_index: Pointer[Int],
) -> None:
    var data_water = state.get_data_water_data()
    var tank_idx = find_item_in_list(tank_name, data_water.water_storage)
    if tank_idx == 0:
        errors_found.store(True)
        return
    
    tank_index.store(tank_idx)
    var old_num_supply = data_water.water_storage[tank_idx - 1].num_water_supplies
    
    if old_num_supply > 0:
        data_water.water_storage[tank_idx - 1].supply_comp_names.append(comp_name)
        data_water.water_storage[tank_idx - 1].supply_comp_types.append(comp_type)
        data_water.water_storage[tank_idx - 1].vdot_avail_supply.append(0.0)
        data_water.water_storage[tank_idx - 1].twater_supply.append(0.0)
        water_supply_index.store(old_num_supply + 1)
        data_water.water_storage[tank_idx - 1].num_water_supplies += 1
    else:
        data_water.water_storage[tank_idx - 1].vdot_avail_supply.append(0.0)
        data_water.water_storage[tank_idx - 1].twater_supply.append(0.0)
        data_water.water_storage[tank_idx - 1].supply_comp_names.append(comp_name)
        data_water.water_storage[tank_idx - 1].supply_comp_types.append(comp_type)
        water_supply_index.store(1)
        data_water.water_storage[tank_idx - 1].num_water_supplies = 1

@export
fn setup_tank_demand_component(
    state: EnergyPlusDataProtocol,
    comp_name: StringRef,
    comp_type: StringRef,
    tank_name: StringRef,
    errors_found: Pointer[Bool],
    tank_index: Pointer[Int],
    water_demand_index: Pointer[Int],
) -> None:
    var data_water = state.get_data_water_data()
    if not data_water.water_system_get_input_called:
        get_water_manager_input(state)
    
    internal_setup_tank_demand_component(state, comp_name, comp_type, tank_name, errors_found, tank_index, water_demand_index)

@export
fn internal_setup_tank_demand_component(
    state: EnergyPlusDataProtocol,
    comp_name: StringRef,
    comp_type: StringRef,
    tank_name: StringRef,
    errors_found: Pointer[Bool],
    tank_index: Pointer[Int],
    water_demand_index: Pointer[Int],
) -> None:
    var data_water = state.get_data_water_data()
    var tank_idx = find_item_in_list(tank_name, data_water.water_storage)
    if tank_idx == 0:
        errors_found.store(True)
        return
    
    tank_index.store(tank_idx)
    var old_num_demand = data_water.water_storage[tank_idx - 1].num_water_demands
    
    if old_num_demand > 0:
        data_water.water_storage[tank_idx - 1].demand_comp_names.append(comp_name)
        data_water.water_storage[tank_idx - 1].demand_comp_types.append(comp_type)
        data_water.water_storage[tank_idx - 1].vdot_request_demand.append(0.0)
        data_water.water_storage[tank_idx - 1].vdot_avail_demand.append(0.0)
        water_demand_index.store(old_num_demand + 1)
        data_water.water_storage[tank_idx - 1].num_water_demands += 1
    else:
        data_water.water_storage[tank_idx - 1].vdot_request_demand.append(0.0)
        data_water.water_storage[tank_idx - 1].vdot_avail_demand.append(0.0)
        data_water.water_storage[tank_idx - 1].demand_comp_names.append(comp_name)
        data_water.water_storage[tank_idx - 1].demand_comp_types.append(comp_type)
        water_demand_index.store(1)
        data_water.water_storage[tank_idx - 1].num_water_demands = 1

@export
fn calc_rain_collector(state: EnergyPlusDataProtocol, rain_col_num: Int) -> None:
    var data_water = state.get_data_water_data()
    var data_hvac = state.get_data_hvac_global()
    var data_envrrn = state.get_data_envrrn()
    var data_global = state.get_data_global()
    
    var time_step_sys_sec = data_hvac.time_step_sys_sec
    
    if data_water.rain_fall.current_rate <= 0.0:
        var tank_id = data_water.rain_collector[rain_col_num - 1].storage_tank_id
        var supply_idx = data_water.rain_collector[rain_col_num - 1].storage_tank_supply_arr_id
        var supplies = data_water.water_storage[tank_id - 1].vdot_avail_supply
        supplies[supply_idx - 1] = 0.0
        var temps = data_water.water_storage[tank_id - 1].twater_supply
        temps[supply_idx - 1] = 0.0
        data_water.rain_collector[rain_col_num - 1].vdot_avail = 0.0
        data_water.rain_collector[rain_col_num - 1].vol_collected = 0.0
    else:
        var loss_factor: Float64
        if data_water.rain_collector[rain_col_num - 1].loss_factor_mode == RainLossFactor.Constant:
            loss_factor = data_water.rain_collector[rain_col_num - 1].loss_factor
        elif data_water.rain_collector[rain_col_num - 1].loss_factor_mode == RainLossFactor.Scheduled:
            loss_factor = data_water.rain_collector[rain_col_num - 1].loss_factor_sched.get_current_val()
        else:
            loss_factor = 0.0
        
        var vdot_avail = (data_water.rain_fall.current_rate * 
                         data_water.rain_collector[rain_col_num - 1].horiz_area * 
                         (1.0 - loss_factor))
        
        if vdot_avail > data_water.rain_collector[rain_col_num - 1].max_collect_rate:
            vdot_avail = data_water.rain_collector[rain_col_num - 1].max_collect_rate
        
        var tank_id = data_water.rain_collector[rain_col_num - 1].storage_tank_id
        var supply_idx = data_water.rain_collector[rain_col_num - 1].storage_tank_supply_arr_id
        var supplies = data_water.water_storage[tank_id - 1].vdot_avail_supply
        supplies[supply_idx - 1] = vdot_avail
        var temps = data_water.water_storage[tank_id - 1].twater_supply
        temps[supply_idx - 1] = data_envrrn.out_wet_bulb_temp
        
        data_water.rain_collector[rain_col_num - 1].vdot_avail = vdot_avail
        data_water.rain_collector[rain_col_num - 1].vol_collected = vdot_avail * time_step_sys_sec
        
        if data_envrrn.run_period_environment and not data_global.warmup_flag:
            var month = data_envrrn.month
            data_water.rain_collector[rain_col_num - 1].vol_collected_monthly[month - 1] += data_water.rain_collector[rain_col_num - 1].vol_collected

@export
fn calc_groundwater_well(state: EnergyPlusDataProtocol, well_num: Int) -> None:
    var data_water = state.get_data_water_data()
    var data_hvac = state.get_data_hvac_global()
    var data_envrrn = state.get_data_envrrn()
    
    var time_step_sys_sec = data_hvac.time_step_sys_sec
    
    var vdot_delivered = 0.0
    var pump_power = 0.0
    
    if data_water.groundwater_well[well_num - 1].vdot_request > 0.0:
        if data_water.groundwater_well[well_num - 1].vdot_request >= data_water.groundwater_well[well_num - 1].pump_nom_vol_flow_rate:
            var tank_id = data_water.groundwater_well[well_num - 1].storage_tank_id
            var supply_idx = data_water.groundwater_well[well_num - 1].storage_tank_supply_arr_id
            var supplies = data_water.water_storage[tank_id - 1].vdot_avail_supply
            supplies[supply_idx - 1] = data_water.groundwater_well[well_num - 1].pump_nom_vol_flow_rate
            var temps = data_water.water_storage[tank_id - 1].twater_supply
            temps[supply_idx - 1] = data_envrrn.ground_temp_deep
            vdot_delivered = data_water.groundwater_well[well_num - 1].pump_nom_vol_flow_rate
            pump_power = data_water.groundwater_well[well_num - 1].pump_nom_power_use
        
        if data_water.groundwater_well[well_num - 1].vdot_request < data_water.groundwater_well[well_num - 1].pump_nom_vol_flow_rate:
            var tank_id = data_water.groundwater_well[well_num - 1].storage_tank_id
            var supply_idx = data_water.groundwater_well[well_num - 1].storage_tank_supply_arr_id
            var supplies = data_water.water_storage[tank_id - 1].vdot_avail_supply
            supplies[supply_idx - 1] = data_water.groundwater_well[well_num - 1].vdot_request
            var temps = data_water.water_storage[tank_id - 1].twater_supply
            temps[supply_idx - 1] = data_envrrn.ground_temp_deep
            vdot_delivered = data_water.groundwater_well[well_num - 1].vdot_request
            pump_power = (data_water.groundwater_well[well_num - 1].pump_nom_power_use * 
                         data_water.groundwater_well[well_num - 1].vdot_request / 
                         data_water.groundwater_well[well_num - 1].pump_nom_vol_flow_rate)
    
    data_water.groundwater_well[well_num - 1].vdot_delivered = vdot_delivered
    data_water.groundwater_well[well_num - 1].vol_delivered = vdot_delivered * time_step_sys_sec
    data_water.groundwater_well[well_num - 1].pump_power = pump_power
    data_water.groundwater_well[well_num - 1].pump_energy = pump_power * time_step_sys_sec

@export
fn update_water_manager(state: EnergyPlusDataProtocol) -> None:
    var data_water = state.get_data_water_data()
    var data_global = state.get_data_global()
    var data_mgr = state.get_data_water_manager()
    
    if data_global.begin_envrrn_flag and data_mgr.my_envrrn_flag:
        for tank_num in range(1, data_water.num_water_storage_tanks + 1):
            data_water.water_storage[tank_num - 1].last_time_step_volume = data_water.water_storage[tank_num - 1].initial_volume
            data_water.water_storage[tank_num - 1].this_time_step_volume = data_water.water_storage[tank_num - 1].initial_volume
        
        if (not data_global.doing_sizing and not data_global.kick_off_simulation and 
            data_mgr.my_tank_demand_check_flag):
            if data_water.num_water_storage_tanks > 0:
                for tank_num in range(1, data_water.num_water_storage_tanks + 1):
                    if data_water.water_storage[tank_num - 1].num_water_demands == 0:
                        pass
            data_mgr.my_tank_demand_check_flag = False
        
        data_mgr.my_envrrn_flag = False
        data_mgr.my_warmup_flag = True
    
    if not data_global.begin_envrrn_flag:
        data_mgr.my_envrrn_flag = True
    
    if data_mgr.my_warmup_flag and not data_global.warmup_flag:
        for tank_num in range(1, data_water.num_water_storage_tanks + 1):
            data_water.water_storage[tank_num - 1].last_time_step_volume = data_water.water_storage[tank_num - 1].initial_volume
            data_water.water_storage[tank_num - 1].this_time_step_volume = data_water.water_storage[tank_num - 1].initial_volume
            data_water.water_storage[tank_num - 1].last_time_step_temp = data_water.water_storage[tank_num - 1].initial_tank_temp
        data_mgr.my_warmup_flag = False
    
    for tank_num in range(1, data_water.num_water_storage_tanks + 1):
        data_water.water_storage[tank_num - 1].last_time_step_volume = max(data_water.water_storage[tank_num - 1].this_time_step_volume, 0.0)
        data_water.water_storage[tank_num - 1].mains_draw_vdot = 0.0
        data_water.water_storage[tank_num - 1].mains_draw_vol = 0.0
        data_water.water_storage[tank_num - 1].net_vdot = 0.0
        data_water.water_storage[tank_num - 1].vdot_from_tank = 0.0
        data_water.water_storage[tank_num - 1].vdot_to_tank = 0.0
        if data_water.water_storage[tank_num - 1].num_water_demands > 0:
            var avail_demands = data_water.water_storage[tank_num - 1].vdot_avail_demand
            for i in range(len(avail_demands)):
                avail_demands[i] = 0.0
        data_water.water_storage[tank_num - 1].vdot_overflow = 0.0
        if data_water.water_storage[tank_num - 1].num_water_supplies > 0:
            var supplies = data_water.water_storage[tank_num - 1].vdot_avail_supply
            for i in range(len(supplies)):
                supplies[i] = 0.0
        
        if (data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatValve or
            data_water.water_storage[tank_num - 1].control_supply == ControlSupplyType.WellFloatMainsBackup):
            if data_water.groundwater_well.size() > 0:
                var well_id = data_water.water_storage[tank_num - 1].ground_well_id
                data_water.groundwater_well[well_id - 1].vdot_request = 0.0
    
    for rain_col_num in range(1, data_water.num_rain_collectors + 1):
        data_water.rain_collector[rain_col_num - 1].vdot_avail = 0.0
        data_water.rain_collector[rain_col_num - 1].vol_collected = 0.0
    
    for well_num in range(1, data_water.num_ground_water_wells + 1):
        data_water.groundwater_well[well_num - 1].vdot_request = 0.0
        data_water.groundwater_well[well_num - 1].vdot_delivered = 0.0
        data_water.groundwater_well[well_num - 1].vol_delivered = 0.0
        data_water.groundwater_well[well_num - 1].pump_power = 0.0
        data_water.groundwater_well[well_num - 1].pump_energy = 0.0

@export
fn report_rainfall(state: EnergyPlusDataProtocol) -> None:
    var months = InlineArray[StringRef, 12](
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    )
    for i in range(12):
        pass

@always_inline
fn find_item_in_list(name: StringRef, items: DynamicVector[object]) -> Int:
    for i in range(items.size()):
        var item_name = items[i].name
        if item_name == name:
            return i + 1
    return 0
