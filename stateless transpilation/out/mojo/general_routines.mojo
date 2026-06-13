from math import copysign, pow
from dataclasses import dataclass


struct IntervalHalf:
    var max_flow: F64 = 0.0
    var min_flow: F64 = 0.0
    var max_result: F64 = 0.0
    var min_result: F64 = 0.0
    var mid_flow: F64 = 0.0
    var mid_result: F64 = 0.0
    var max_flow_calc: Bool = False
    var min_flow_calc: Bool = False
    var min_flow_result: Bool = False
    var norm_flow_calc: Bool = False
    
    fn __init__(
        inout self,
        max_flow: F64 = 0.0,
        min_flow: F64 = 0.0,
        max_result: F64 = 0.0,
        min_result: F64 = 0.0,
        mid_flow: F64 = 0.0,
        mid_result: F64 = 0.0,
        max_flow_calc: Bool = False,
        min_flow_calc: Bool = False,
        min_flow_result: Bool = False,
        norm_flow_calc: Bool = False,
    ):
        self.max_flow = max_flow
        self.min_flow = min_flow
        self.max_result = max_result
        self.min_result = min_result
        self.mid_flow = mid_flow
        self.mid_result = mid_result
        self.max_flow_calc = max_flow_calc
        self.min_flow_calc = min_flow_calc
        self.min_flow_result = min_flow_result
        self.norm_flow_calc = norm_flow_calc


struct ZoneEquipControllerProps:
    var set_point: F64 = 0.0
    var max_set_point: F64 = 0.0
    var min_set_point: F64 = 0.0
    var sensed_value: F64 = 0.0
    var calculated_set_point: F64 = 0.0
    
    fn __init__(
        inout self,
        set_point: F64 = 0.0,
        max_set_point: F64 = 0.0,
        min_set_point: F64 = 0.0,
        sensed_value: F64 = 0.0,
        calculated_set_point: F64 = 0.0,
    ):
        self.set_point = set_point
        self.max_set_point = max_set_point
        self.min_set_point = min_set_point
        self.sensed_value = sensed_value
        self.calculated_set_point = calculated_set_point


struct AirLoopHVACCompType:
    alias INVALID = -1
    alias SUPPLY_PLENUM = 0
    alias ZONE_SPLITTER = 1
    alias ZONE_MIXER = 2
    alias RETURN_PLENUM = 3
    alias NUM = 4


struct GeneralRoutinesEquipNums:
    alias PARALLEL_PIU_REHEAT_NUM = 1
    alias SERIES_PIU_REHEAT_NUM = 2
    alias HEATING_COIL_WATER_NUM = 3
    alias BB_WATER_CONV_ONLY_NUM = 4
    alias BB_STEAM_RAD_CONV_NUM = 5
    alias BB_WATER_RAD_CONV_NUM = 6
    alias FOUR_PIPE_FAN_COIL_NUM = 7
    alias OUTDOOR_AIR_UNIT_NUM = 8
    alias UNIT_HEATER_NUM = 9
    alias UNIT_VENTILATOR_NUM = 10
    alias VENTILATED_SLAB_NUM = 11


alias MAX_ITER = 25
alias ITER_FAC = 1.0 / pow(2.0, MAX_ITER - 3)
alias I_REVERSE_ACTION = 1
alias I_NORMAL_ACTION = 2
alias BB_ITER_LIMIT = 0.00001

var AIR_LOOP_HVAC_COMP_TYPE_NAMES_UC = InlineArray[StringRef, 4](
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:RETURNPLENUM"
)

var LIST_OF_COMPONENTS = InlineArray[StringRef, 11](
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "COIL:HEATING:WATER",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:FOURPIPEFANCOIL",
    "ZONEHVAC:OUTDOORAIRUNIT",
    "ZONEHVAC:UNITHEATER",
    "ZONEHVAC:UNITVENTILATOR",
    "ZONEHVAC:VENTILATEDSLAB"
)


fn control_comp_output(
    state: AnyType,
    comp_name: String,
    comp_type: String,
    inout comp_num: Int,
    first_hvac_iteration: Bool,
    q_zn_req: F64,
    actuated_node: Int,
    max_flow: F64,
    min_flow: F64,
    control_offset: F64,
    inout control_comp_type_num: Int,
    inout comp_err_index: Int,
    temp_in_node: Optional[Int] = None,
    temp_out_node: Optional[Int] = None,
    air_mass_flow: Optional[F64] = None,
    action: Optional[Int] = None,
    equip_index: Optional[Int] = None,
    plant_loc: AnyType = None,
    controlled_zone_index: Optional[Int] = None,
) -> None:
    """Control component output via interval halving."""
    
    var zone_inter_half = state.data_general_routines.zone_inter_half
    var zone_controller = state.data_general_routines.zone_controller
    
    if control_comp_type_num != 0:
        var sim_comp_num = control_comp_type_num
    else:
        var sim_comp_num = util_find_item(comp_type, LIST_OF_COMPONENTS, 11)
        control_comp_type_num = sim_comp_num
    
    var iter_count: Int = 0
    var converged: Bool = False
    var water_coil_air_flow_control: Bool = False
    var load_met: F64 = 0.0
    var halving_prec: F64 = 0.0
    var cp_air: F64 = 0.0
    
    zone_controller.set_point = 0.0
    
    zone_inter_half.max_flow_calc = True
    zone_inter_half.min_flow_calc = False
    zone_inter_half.norm_flow_calc = False
    zone_inter_half.min_flow_result = False
    zone_inter_half.max_result = 1.0
    zone_inter_half.min_result = 0.0
    
    while not converged:
        if first_hvac_iteration:
            state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail = max_flow
            state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail = min_flow
            if min_flow > max_flow:
                pass
        
        if (sim_comp_num == 3) and (air_mass_flow == None):
            zone_controller.max_set_point = state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail
            zone_controller.min_set_point = state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail
        else:
            zone_controller.max_set_point = min(
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail,
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_max
            )
            zone_controller.min_set_point = max(
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail,
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_min
            )
        
        if zone_inter_half.max_flow_calc:
            zone_controller.calculated_set_point = zone_controller.max_set_point
            zone_inter_half.max_flow = zone_controller.max_set_point
            zone_inter_half.max_flow_calc = False
            zone_inter_half.min_flow_calc = True
        
        elif zone_inter_half.min_flow_calc:
            zone_inter_half.max_result = zone_controller.sensed_value
            zone_controller.calculated_set_point = zone_controller.min_set_point
            zone_inter_half.min_flow = zone_controller.min_set_point
            zone_inter_half.min_flow_calc = False
            zone_inter_half.min_flow_result = True
        
        elif zone_inter_half.min_flow_result:
            zone_inter_half.min_result = zone_controller.sensed_value
            halving_prec = (zone_inter_half.max_result - zone_inter_half.min_result) * ITER_FAC
            zone_inter_half.mid_flow = (zone_inter_half.max_flow + zone_inter_half.min_flow) / 2.0
            zone_controller.calculated_set_point = (zone_inter_half.max_flow + zone_inter_half.min_flow) / 2.0
            zone_inter_half.min_flow_result = False
            zone_inter_half.norm_flow_calc = True
        
        elif zone_inter_half.norm_flow_calc:
            zone_inter_half.mid_result = zone_controller.sensed_value
            
            if zone_inter_half.max_result == zone_inter_half.min_result:
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
                
                if 4 <= sim_comp_num <= 6:
                    zone_controller.calculated_set_point = 0.0
                else:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                
                if plant_loc.loop_num != 0:
                    plant_utilities_set_actuated_branch_flow_rate(
                        state, zone_controller.calculated_set_point, actuated_node, plant_loc, False
                    )
                else:
                    state.data_loop_nodes.node[actuated_node].mass_flow_rate = zone_controller.calculated_set_point
                
                return
            
            if zone_inter_half.max_result <= zone_inter_half.min_result:
                if water_coil_air_flow_control:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                else:
                    zone_controller.calculated_set_point = zone_inter_half.min_flow
                converged = True
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
            else:
                if zone_controller.set_point <= zone_inter_half.min_result:
                    zone_controller.calculated_set_point = zone_inter_half.min_flow
                    converged = True
                    zone_inter_half.max_flow_calc = True
                    zone_inter_half.min_flow_calc = False
                    zone_inter_half.norm_flow_calc = False
                    zone_inter_half.min_flow_result = False
                    zone_inter_half.max_result = 1.0
                    zone_inter_half.min_result = 0.0
                
                elif zone_controller.set_point >= zone_inter_half.max_result:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                    converged = True
                    zone_inter_half.max_flow_calc = True
                    zone_inter_half.min_flow_calc = False
                    zone_inter_half.norm_flow_calc = False
                    zone_inter_half.min_flow_result = False
                    zone_inter_half.max_result = 1.0
                    zone_inter_half.min_result = 0.0
                
                elif zone_controller.set_point >= zone_inter_half.mid_result:
                    zone_controller.calculated_set_point = (zone_inter_half.max_flow + zone_inter_half.mid_flow) / 2.0
                    zone_inter_half.min_flow = zone_inter_half.mid_flow
                    zone_inter_half.min_result = zone_inter_half.mid_result
                    zone_inter_half.mid_flow = (zone_inter_half.max_flow + zone_inter_half.mid_flow) / 2.0
                
                else:
                    zone_controller.calculated_set_point = (zone_inter_half.min_flow + zone_inter_half.mid_flow) / 2.0
                    zone_inter_half.max_flow = zone_inter_half.mid_flow
                    zone_inter_half.max_result = zone_inter_half.mid_result
                    zone_inter_half.mid_flow = (zone_inter_half.min_flow + zone_inter_half.mid_flow) / 2.0
        
        if zone_controller.calculated_set_point > zone_controller.max_set_point:
            zone_controller.calculated_set_point = zone_controller.max_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        elif zone_controller.calculated_set_point < zone_controller.min_set_point:
            zone_controller.calculated_set_point = zone_controller.min_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        
        if (iter_count > MAX_ITER / 2) and (zone_controller.calculated_set_point < state.data_branch_air_loop_plant.mass_flow_tolerance):
            zone_controller.calculated_set_point = zone_controller.min_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        
        if plant_loc.loop_num != 0:
            plant_utilities_set_actuated_branch_flow_rate(
                state, zone_controller.calculated_set_point, actuated_node, plant_loc, False
            )
        else:
            state.data_loop_nodes.node[actuated_node].mass_flow_rate = zone_controller.calculated_set_point
        
        var denom = copysign(max(abs(q_zn_req), 100.0), q_zn_req)
        if action != None:
            if action == I_NORMAL_ACTION:
                denom = max(abs(q_zn_req), 100.0)
            elif action == I_REVERSE_ACTION:
                denom = -max(abs(q_zn_req), 100.0)
        
        if sim_comp_num in (1, 2):
            water_coils_simulate_water_coil_components(state, comp_name, first_hvac_iteration, comp_num)
            cp_air = psychrometrics_psy_cp_air_fn_w(state.data_loop_nodes.node[temp_out_node].hum_rat)
            load_met = cp_air * state.data_loop_nodes.node[temp_out_node].mass_flow_rate * (
                state.data_loop_nodes.node[temp_out_node].temp - state.data_loop_nodes.node[temp_in_node].temp
            )
            zone_controller.sensed_value = (load_met - q_zn_req) / denom
        
        elif sim_comp_num == 3:
            water_coils_simulate_water_coil_components(state, comp_name, first_hvac_iteration, comp_num)
            cp_air = psychrometrics_psy_cp_air_fn_w(state.data_loop_nodes.node[temp_out_node].hum_rat)
            if air_mass_flow != None:
                load_met = air_mass_flow * cp_air * state.data_loop_nodes.node[temp_out_node].temp
                zone_controller.sensed_value = (load_met - q_zn_req) / denom
            else:
                water_coil_air_flow_control = True
                load_met = state.data_loop_nodes.node[temp_out_node].mass_flow_rate * cp_air * (
                    state.data_loop_nodes.node[temp_out_node].temp - state.data_loop_nodes.node[temp_in_node].temp
                )
                zone_controller.sensed_value = (load_met - q_zn_req) / denom
        
        if abs(zone_controller.sensed_value) <= control_offset or abs(zone_controller.sensed_value) <= halving_prec:
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
            break
        
        if not converged:
            if bb_converge_check(sim_comp_num, zone_inter_half.max_flow, zone_inter_half.min_flow):
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
                break
        
        iter_count += 1
        if (iter_count > MAX_ITER) and (not state.data_global.warmup_flag):
            break
        
        if iter_count > MAX_ITER * 2:
            break


fn bb_converge_check(sim_comp_num: Int, max_flow: F64, min_flow: F64) -> Bool:
    """Check baseboard convergence."""
    if sim_comp_num != GeneralRoutinesEquipNums.BB_STEAM_RAD_CONV_NUM and sim_comp_num != GeneralRoutinesEquipNums.BB_WATER_RAD_CONV_NUM:
        return False
    else:
        if (max_flow - min_flow) > BB_ITER_LIMIT:
            return False
        else:
            return True


fn check_sys_sizing(state: AnyType, comp_type: String, comp_name: String) -> None:
    """Check that system sizing run has been done."""
    if not state.data_size.sys_sizing_run_done:
        pass


fn check_this_air_system_for_sizing(state: AnyType, air_loop_num: Int) -> Bool:
    """Check if this air system has sizing."""
    var air_loop_was_sized: Bool = False
    if state.data_size.sys_sizing_run_done:
        for i in range(state.data_size.num_sys_siz_input):
            if state.data_size.sys_siz_input[i].air_loop_num == air_loop_num:
                air_loop_was_sized = True
                break
    return air_loop_was_sized


fn check_zone_sizing(state: AnyType, comp_type: String, comp_name: String) -> None:
    """Check that zone sizing run has been done."""
    if not state.data_size.zone_sizing_run_done:
        pass


fn check_this_zone_for_sizing(state: AnyType, zone_num: Int) -> Bool:
    """Check if this zone has sizing."""
    var zone_was_sized: Bool = False
    if state.data_size.zone_sizing_run_done:
        for i in range(state.data_size.num_zone_siz_input):
            if state.data_size.zone_siz_input[i].zone_num == zone_num:
                zone_was_sized = True
                break
    return zone_was_sized


fn validate_component(
    state: AnyType,
    comp_type: String,
    comp_name: String,
    call_string: String,
    comp_val_type: Optional[String] = None,
) -> Bool:
    """Validate component type-name pair."""
    var is_not_ok: Bool = False
    
    var comp_type_upper = comp_type.upper()
    if comp_type_upper in ("HEATPUMP:AIRTOWATER:COOLING", "HEATPUMP:AIRTOWATER:HEATING"):
        comp_type_upper = "HEATPUMP:AIRTOWATER"
    
    var item_num: Int
    if comp_val_type == None:
        item_num = state.data_input_processing.input_processor.get_object_item_num(state, comp_type_upper, comp_name)
    else:
        item_num = state.data_input_processing.input_processor.get_object_item_num(state, comp_type_upper, comp_val_type, comp_name)
    
    if item_num < 0:
        is_not_ok = True
    elif item_num == 0:
        is_not_ok = True
    
    return is_not_ok


fn calc_basin_heater_power(
    state: AnyType,
    capacity: F64,
    sched: Optional[AnyType],
    set_point_temp: F64,
) -> F64:
    """Calculate basin heater power."""
    var power: F64 = 0.0
    
    if sched != None:
        var basin_heater_sch = sched.get_current_val()
        if capacity > 0.0 and basin_heater_sch > 0.0:
            power = max(0.0, capacity * (set_point_temp - state.data_envrn.out_dry_bulb_temp))
    else:
        if capacity > 0.0:
            power = max(0.0, capacity * (set_point_temp - state.data_envrn.out_dry_bulb_temp))
    
    return power


fn test_air_path_integrity(state: AnyType, inout err_found: Bool) -> None:
    """Test supply, return and overall air path integrity."""
    var num_sap_nodes = InlineArray[Int, 1024](fill=0)
    var num_rap_nodes = InlineArray[Int, 1024](fill=0)
    var val_ret_a_paths = InlineArray[Int, 1024](fill=0)
    var val_sup_a_paths = InlineArray[Int, 1024](fill=0)
    
    var err_flag: Bool = False
    test_supply_air_path_integrity(state, err_flag)
    if err_flag:
        err_found = True
    
    err_flag = False
    test_return_air_path_integrity(state, err_flag, val_ret_a_paths)
    if err_flag:
        err_found = True
    
    for loop in range(state.data_hvac_global.num_primary_air_sys):
        if val_ret_a_paths[loop] != 0:
            continue
        if state.data_air_loop.air_to_zone_node_info[loop].num_return_nodes <= 0:
            continue
        val_ret_a_paths[loop] = state.data_air_loop.air_to_zone_node_info[loop].zone_equip_return_node_num[0]


fn test_supply_air_path_integrity(state: AnyType, inout err_found: Bool) -> None:
    """Test supply air path integrity."""
    pass


fn test_return_air_path_integrity(state: AnyType, inout err_found: Bool, inout val_ret_a_paths: InlineArray) -> None:
    """Test return air path integrity."""
    pass


fn calc_component_sensible_latent_output(
    mass_flow: F64,
    tdb2: F64,
    w2: F64,
    tdb1: F64,
    w1: F64,
) -> Tuple[F64, F64, F64]:
    """Calculate sensible and latent output."""
    var total_output: F64 = 0.0
    var latent_output: F64 = 0.0
    var sensible_output: F64 = 0.0
    
    if mass_flow > 0.0:
        total_output = mass_flow * (
            psychrometrics_psy_h_fn_tdb_w(tdb2, w2) - psychrometrics_psy_h_fn_tdb_w(tdb1, w1)
        )
        sensible_output = mass_flow * psychrometrics_psy_delta_h_sen_fn_tdb2_w2_tdb1_w1(tdb2, w2, tdb1, w1)
        latent_output = total_output - sensible_output
    
    return (sensible_output, latent_output, total_output)


fn calc_zone_sensible_latent_output(
    mass_flow: F64,
    tdb_equip: F64,
    w_equip: F64,
    tdb_zone: F64,
    w_zone: F64,
) -> Tuple[F64, F64, F64]:
    """Calculate zone sensible and latent output."""
    var total_output: F64 = 0.0
    var latent_output: F64 = 0.0
    var sensible_output: F64 = 0.0
    
    if mass_flow > 0.0:
        total_output = mass_flow * (
            psychrometrics_psy_h_fn_tdb_w(tdb_equip, w_equip) - psychrometrics_psy_h_fn_tdb_w(tdb_zone, w_zone)
        )
        sensible_output = mass_flow * psychrometrics_psy_delta_h_sen_fn_tdb2_tdb1_w(tdb_equip, tdb_zone, w_zone)
        latent_output = total_output - sensible_output
    
    return (sensible_output, latent_output, total_output)


fn calc_zone_sensible_output(
    mass_flow: F64,
    tdb_equip: F64,
    tdb_zone: F64,
    w_zone: F64,
) -> F64:
    """Calculate zone sensible output."""
    var sensible_output: F64 = 0.0
    if mass_flow > 0.0:
        sensible_output = mass_flow * psychrometrics_psy_delta_h_sen_fn_tdb2_tdb1_w(tdb_equip, tdb_zone, w_zone)
    return sensible_output


@always_inline
fn water_coils_simulate_water_coil_components(state: AnyType, comp_name: String, first_hvac_iteration: Bool, comp_num: Int) -> None:
    pass


@always_inline
fn psychrometrics_psy_cp_air_fn_w(humidity_ratio: F64) -> F64:
    return 0.0


@always_inline
fn psychrometrics_psy_h_fn_tdb_w(tdb: F64, w: F64) -> F64:
    return 0.0


@always_inline
fn psychrometrics_psy_delta_h_sen_fn_tdb2_w2_tdb1_w1(tdb2: F64, w2: F64, tdb1: F64, w1: F64) -> F64:
    return 0.0


@always_inline
fn psychrometrics_psy_delta_h_sen_fn_tdb2_tdb1_w(tdb2: F64, tdb1: F64, w: F64) -> F64:
    return 0.0


@always_inline
fn plant_utilities_set_actuated_branch_flow_rate(state: AnyType, flow_rate: F64, node: Int, plant_loc: AnyType, autodesk_optional: Bool) -> None:
    pass


@always_inline
fn util_find_item(item: String, list_items: InlineArray, num_items: Int) -> Int:
    return 0
