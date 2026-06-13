struct SteamBaseboardParams:
    var name: String
    var equip_type: Int
    var design_object_name: String
    var design_object_ptr: Int
    var surface_names: DynamicVector[String]
    var surface_ptrs: DynamicVector[Int]
    var zone_ptr: Int
    var avail_sched: AnyType
    var steam_inlet_node: Int
    var steam_outlet_node: Int
    var tot_surf_to_distrib: Int
    var steam: AnyType
    var control_comp_type_num: Int
    var comp_err_index: Int
    var deg_of_subcooling: Float64
    var steam_mass_flow_rate: Float64
    var steam_mass_flow_rate_max: Float64
    var steam_vol_flow_rate_max: Float64
    var steam_outlet_temp: Float64
    var steam_inlet_temp: Float64
    var steam_inlet_enthalpy: Float64
    var steam_outlet_enthalpy: Float64
    var steam_inlet_press: Float64
    var steam_outlet_press: Float64
    var steam_inlet_quality: Float64
    var steam_outlet_quality: Float64
    var frac_radiant: Float64
    var frac_convect: Float64
    var frac_distrib_person: Float64
    var frac_distrib_to_surf: DynamicVector[Float64]
    var tot_power: Float64
    var power: Float64
    var conv_power: Float64
    var rad_power: Float64
    var tot_energy: Float64
    var energy: Float64
    var conv_energy: Float64
    var rad_energy: Float64
    var plant_loc: AnyType
    var bb_load_re_sim_index: Int
    var bb_mass_flow_re_sim_index: Int
    var bb_inlet_temp_flow_re_sim_index: Int
    var q_bb_steam_rad_source: Float64
    var q_bb_steam_rad_src_avg: Float64
    var zero_bb_steam_source_sum_ha_tsurf: Float64
    var last_q_bb_steam_rad_src: Float64
    var last_sys_time_elapsed: Float64
    var last_time_step_sys: Float64
    var scaled_heating_capacity: Float64

struct SteamBaseboardDesignData(SteamBaseboardParams):
    var design_name: String
    var heating_cap_method: Int
    var design_scaled_heating_capacity: Float64
    var offset: Float64

struct SteamBaseboardNumericFieldData:
    var field_names: DynamicVector[String]

struct SteamBaseboardDesignNumericFieldData:
    var field_names: DynamicVector[String]

struct SteamBaseboardRadiatorData:
    var c_cmo_bb_radiator_steam: String
    var c_cmo_bb_radiator_steam_design: String
    var num_steam_baseboards: Int
    var num_steam_baseboards_design: Int
    var my_size_flag: DynamicVector[Bool]
    var check_equip_name: DynamicVector[Bool]
    var check_design_object_name: DynamicVector[Bool]
    var set_loop_index_flag: DynamicVector[Bool]
    var get_input_flag: Bool
    var my_one_time_flag: Bool
    var zone_equipment_list_checked: Bool
    var my_envrnflag: DynamicVector[Bool]
    var steam_baseboards: DynamicVector[SteamBaseboardParams]
    var steam_baseboards_design: DynamicVector[SteamBaseboardDesignData]
    var steam_baseboard_numeric_fields: DynamicVector[SteamBaseboardNumericFieldData]
    var steam_baseboard_design_numeric_fields: DynamicVector[SteamBaseboardDesignNumericFieldData]
    var steam_baseboard_design_names: DynamicVector[String]

fn sim_steam_baseboard(state: AnyType, equip_name: String, controlled_zone_num: Int, first_hvac_iteration: Bool) -> Tuple[Float64, Int]:
    var baseboard_num: Int = 0
    var comp_index: Int = 0
    var power_met: Float64 = 0.0
    
    if state.data_steam_baseboard_radiator.get_input_flag:
        get_steam_baseboard_input(state)
        state.data_steam_baseboard_radiator.get_input_flag = False
    
    if comp_index == 0:
        baseboard_num = find_item_in_list(equip_name, state.data_steam_baseboard_radiator.steam_baseboards)
        if baseboard_num < 0:
            show_fatal_error(state, "SimSteamBaseboard: Unit not found=" + equip_name)
        comp_index = baseboard_num
    else:
        baseboard_num = comp_index
        if baseboard_num >= state.data_steam_baseboard_radiator.num_steam_baseboards or baseboard_num < 0:
            show_fatal_error(state, "SimSteamBaseboard:  Invalid CompIndex")
        if state.data_steam_baseboard_radiator.check_equip_name[baseboard_num]:
            if equip_name != state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].name:
                show_fatal_error(state, "SimSteamBaseboard: Invalid CompIndex")
            state.data_steam_baseboard_radiator.check_equip_name[baseboard_num] = False
    
    if comp_index > 0:
        init_steam_baseboard(state, baseboard_num, controlled_zone_num, first_hvac_iteration)
        
        var qzn_req: Float64 = state.data_zone_energy_demand.zone_sys_energy_demand[controlled_zone_num].remaining_output_req_to_heat_sp
        var steam_baseboard_design_data_object = state.data_steam_baseboard_radiator.steam_baseboards_design[
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].design_object_ptr]
        
        var small_load: Float64 = 1.0e-30
        if qzn_req > small_load and not state.data_zone_energy_demand.cur_dead_band_or_setback[controlled_zone_num] and \
           state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].avail_sched.getCurrentVal() > 0.0:
            
            var max_steam_flow: Float64
            var min_steam_flow: Float64
            if first_hvac_iteration:
                max_steam_flow = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate_max
                min_steam_flow = 0.0
            else:
                max_steam_flow = state.data_loop_nodes.nodes[
                    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node].mass_flow_rate_max_avail
                min_steam_flow = state.data_loop_nodes.nodes[
                    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node].mass_flow_rate_min_avail
            
            if state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].equip_type == 1:
                control_comp_output(state,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].name,
                                  state.data_steam_baseboard_radiator.c_cmo_bb_radiator_steam,
                                  baseboard_num,
                                  first_hvac_iteration,
                                  qzn_req,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node,
                                  max_steam_flow,
                                  min_steam_flow,
                                  steam_baseboard_design_data_object.offset,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].control_comp_type_num,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].comp_err_index,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc)
            else:
                show_severe_error(state, "SimSteamBaseboard: Errors in Baseboard")
                show_continue_error(state, "Invalid or unimplemented equipment type")
                show_fatal_error(state, "Preceding condition causes termination.")
            
            power_met = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_power
        else:
            var mdot: Float64 = 0.0
            set_component_flow_rate(state, mdot,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_node,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc)
            var dummy_load: Float64 = 0.0
            calc_steam_baseboard(state, baseboard_num, dummy_load)
            power_met = dummy_load
        
        update_steam_baseboard(state, baseboard_num)
        report_steam_baseboard(state, baseboard_num)
    else:
        show_fatal_error(state, "SimSteamBaseboard: Unit not found=" + equip_name)
    
    return Tuple(power_met, comp_index)

fn get_steam_baseboard_input(state: AnyType) -> None:
    pass

fn init_steam_baseboard(state: AnyType, baseboard_num: Int, controlled_zone_num: Int, first_hvac_iteration: Bool) -> None:
    if state.data_steam_baseboard_radiator.my_one_time_flag:
        state.data_steam_baseboard_radiator.my_envrnflag = DynamicVector[Bool](state.data_steam_baseboard_radiator.num_steam_baseboards)
        state.data_steam_baseboard_radiator.my_size_flag = DynamicVector[Bool](state.data_steam_baseboard_radiator.num_steam_baseboards)
        state.data_steam_baseboard_radiator.set_loop_index_flag = DynamicVector[Bool](state.data_steam_baseboard_radiator.num_steam_baseboards)
        state.data_steam_baseboard_radiator.my_one_time_flag = False
    
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zone_ptr = controlled_zone_num
    
    if not state.data_steam_baseboard_radiator.zone_equipment_list_checked and state.data_zone_equip.zone_equip_inputs_filled:
        state.data_steam_baseboard_radiator.zone_equipment_list_checked = True
        for loop in range(state.data_steam_baseboard_radiator.num_steam_baseboards):
            if not check_zone_equipment_list(state,
                                            state.data_steam_baseboard_radiator.c_cmo_bb_radiator_steam,
                                            state.data_steam_baseboard_radiator.steam_baseboards[loop].name):
                show_severe_error(state, "InitBaseboard: Unit not on ZoneHVAC:EquipmentList")
    
    if state.data_steam_baseboard_radiator.set_loop_index_flag[baseboard_num]:
        if hasattr(state.data_plant, "plant_loops"):
            var err_flag: Bool = False
            scan_plant_loops_for_object(state,
                                       state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].name,
                                       state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].equip_type,
                                       state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                       err_flag)
            state.data_steam_baseboard_radiator.set_loop_index_flag[baseboard_num] = False
            if err_flag:
                show_fatal_error(state, "InitSteamBaseboard: Program terminated for previous conditions.")
    
    if not state.data_global.sys_sizing_calc and state.data_steam_baseboard_radiator.my_size_flag[baseboard_num] and \
       not state.data_steam_baseboard_radiator.set_loop_index_flag[baseboard_num]:
        size_steam_baseboard(state, baseboard_num)
        state.data_steam_baseboard_radiator.my_size_flag[baseboard_num] = False
    
    if state.data_global.begin_envrnflag and state.data_steam_baseboard_radiator.my_envrnflag[baseboard_num]:
        var steam_inlet_node: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node
        state.data_loop_nodes.nodes[steam_inlet_node].temp = 100.0
        state.data_loop_nodes.nodes[steam_inlet_node].press = 101325.0
        
        var steam = get_steam(state)
        var steam_density: Float64 = steam.getSatDensity(state, 100.0, 1.0, "InitSteamCoil")
        var start_enth_steam: Float64 = steam.getSatEnthalpy(state, 100.0, 1.0, "InitSteamCoil")
        
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate_max = \
            steam_density * state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_vol_flow_rate_max
        
        init_component_nodes(state, 0.0,
                           state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate_max,
                           steam_inlet_node,
                           state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_node)
        
        state.data_loop_nodes.nodes[steam_inlet_node].enthalpy = start_enth_steam
        state.data_loop_nodes.nodes[steam_inlet_node].quality = 1.0
        state.data_loop_nodes.nodes[steam_inlet_node].hum_rat = 0.0
        
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zero_bb_steam_source_sum_ha_tsurf = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_q_bb_steam_rad_src = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_sys_time_elapsed = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_time_step_sys = 0.0
        
        state.data_steam_baseboard_radiator.my_envrnflag[baseboard_num] = False
    
    if not state.data_global.begin_envrnflag:
        state.data_steam_baseboard_radiator.my_envrnflag[baseboard_num] = True
    
    if state.data_global.begin_time_step_flag and first_hvac_iteration:
        var zone_num: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zone_ptr
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zero_bb_steam_source_sum_ha_tsurf = \
            state.data_heat_bal.zones[zone_num].sum_ha_tsurf(state)
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_q_bb_steam_rad_src = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_sys_time_elapsed = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_time_step_sys = 0.0
    
    var steam_inlet_node: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate = \
        state.data_loop_nodes.nodes[steam_inlet_node].mass_flow_rate
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_temp = \
        state.data_loop_nodes.nodes[steam_inlet_node].temp
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_enthalpy = \
        state.data_loop_nodes.nodes[steam_inlet_node].enthalpy
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_press = \
        state.data_loop_nodes.nodes[steam_inlet_node].press
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_quality = \
        state.data_loop_nodes.nodes[steam_inlet_node].quality
    
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_power = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].power = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].conv_power = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].rad_power = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_energy = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].energy = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].conv_energy = 0.0
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].rad_energy = 0.0

fn size_steam_baseboard(state: AnyType, baseboard_num: Int) -> None:
    pass

fn calc_steam_baseboard(state: AnyType, inout baseboard_num: Int, inout load_met: Float64) -> None:
    var steam_baseboard_design_data_object = state.data_steam_baseboard_radiator.steam_baseboards_design[
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].design_object_ptr]
    
    var zone_num: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zone_ptr
    var qzn_req: Float64 = state.data_zone_energy_demand.zone_sys_energy_demand[zone_num].remaining_output_req_to_heat_sp
    var steam_inlet_temp: Float64 = state.data_loop_nodes.nodes[
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node].temp
    var steam_mass_flow_rate: Float64 = state.data_loop_nodes.nodes[
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node].mass_flow_rate
    var subcool_delta_t: Float64 = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].deg_of_subcooling
    
    var small_load: Float64 = 1.0e-30
    var steam_outlet_temp: Float64
    var steam_bb_heat: Float64
    var rad_heat: Float64
    
    if qzn_req > small_load and not state.data_zone_energy_demand.cur_dead_band_or_setback[zone_num] and \
       steam_mass_flow_rate > 0.0 and state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].avail_sched.getCurrentVal() > 0:
        
        var steam = get_steam(state)
        var enth_steam_in_dry: Float64 = steam.getSatEnthalpy(state, steam_inlet_temp, 1.0, "CalcSteamBaseboard")
        var enth_steam_out_wet: Float64 = steam.getSatEnthalpy(state, steam_inlet_temp, 0.0, "CalcSteamBaseboard")
        var latent_heat_steam: Float64 = enth_steam_in_dry - enth_steam_out_wet
        var cp: Float64 = steam.getSatSpecificHeat(state, steam_inlet_temp, 0.0, "CalcSteamBaseboard")
        
        steam_bb_heat = steam_mass_flow_rate * (latent_heat_steam + subcool_delta_t * cp)
        steam_outlet_temp = steam_inlet_temp - subcool_delta_t
        
        rad_heat = steam_bb_heat * steam_baseboard_design_data_object.frac_radiant
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source = rad_heat
        
        distribute_bb_steam_rad_gains(state)
        calc_heat_balance_outside_surf(state, zone_num)
        calc_heat_balance_inside_surf(state, zone_num)
        
        load_met = (state.data_heat_bal.zones[zone_num].sum_ha_tsurf(state) -
                   state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zero_bb_steam_source_sum_ha_tsurf) + \
                  (steam_bb_heat * state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].frac_convect) + \
                  (rad_heat * steam_baseboard_design_data_object.frac_distrib_person)
        
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_enthalpy = \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_enthalpy - steam_bb_heat / steam_mass_flow_rate
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_quality = 0.0
    else:
        steam_outlet_temp = steam_inlet_temp
        steam_bb_heat = 0.0
        load_met = 0.0
        rad_heat = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_quality = 0.0
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_enthalpy = \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_enthalpy
    
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_temp = steam_outlet_temp
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate = steam_mass_flow_rate
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_power = load_met
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].power = steam_bb_heat
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].conv_power = steam_bb_heat - rad_heat
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].rad_power = rad_heat

fn update_steam_baseboard(state: AnyType, baseboard_num: Int) -> None:
    if state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_sys_time_elapsed == \
       state.data_hvac_global.sys_time_elapsed:
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg -= \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_q_bb_steam_rad_src * \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_time_step_sys / \
            state.data_global.time_step_zone
    
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg += \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source * \
        state.data_hvac_global.time_step_sys / state.data_global.time_step_zone
    
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_q_bb_steam_rad_src = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_sys_time_elapsed = \
        state.data_hvac_global.sys_time_elapsed
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].last_time_step_sys = \
        state.data_hvac_global.time_step_sys
    
    var steam_inlet_node: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_inlet_node
    var steam_outlet_node: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_node
    
    safe_copy_plant_node(state, steam_inlet_node, steam_outlet_node)
    state.data_loop_nodes.nodes[steam_outlet_node].temp = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_temp
    state.data_loop_nodes.nodes[steam_outlet_node].enthalpy = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_enthalpy

fn update_bb_steam_rad_source_val_avg(state: AnyType) -> Bool:
    var steam_baseboard_sys_on: Bool = False
    
    if state.data_steam_baseboard_radiator.num_steam_baseboards == 0:
        return steam_baseboard_sys_on
    
    for baseboard_num in range(state.data_steam_baseboard_radiator.num_steam_baseboards):
        if state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg != 0.0:
            steam_baseboard_sys_on = True
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source = \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_src_avg
    
    distribute_bb_steam_rad_gains(state)
    
    return steam_baseboard_sys_on

fn distribute_bb_steam_rad_gains(state: AnyType) -> None:
    var smallest_area: Float64 = 0.001
    var max_rad_heat_flux: Float64 = 50000.0
    
    for i in range(state.data_steam_baseboard_radiator.num_steam_baseboards):
        var steam_bb = state.data_steam_baseboard_radiator.steam_baseboards[i]
        for rad_surf_num in range(steam_bb.tot_surf_to_distrib):
            var surf_num: Int = steam_bb.surface_ptrs[rad_surf_num]
            state.data_heat_bal_fan_sys.surf_q_rad_from_hvac[surf_num].steam_baseboard = 0.0
    
    for i in range(len(state.data_heat_bal.zones)):
        state.data_heat_bal_fan_sys.zone_q_steam_baseboard_to_person[i] = 0.0
    
    for baseboard_num in range(state.data_steam_baseboard_radiator.num_steam_baseboards):
        var zone_num: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].zone_ptr
        var steam_baseboard_design_data_object = state.data_steam_baseboard_radiator.steam_baseboards_design[
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].design_object_ptr]
        
        state.data_heat_bal_fan_sys.zone_q_steam_baseboard_to_person[zone_num] += \
            state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source * \
            steam_baseboard_design_data_object.frac_distrib_person
        
        for rad_surf_num in range(state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_surf_to_distrib):
            var surf_num: Int = state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].surface_ptrs[rad_surf_num]
            
            if state.data_surface.surfaces[surf_num].area > smallest_area:
                var this_surf_intensity: Float64 = (state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].q_bb_steam_rad_source *
                                      state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].frac_distrib_to_surf[rad_surf_num] /
                                      state.data_surface.surfaces[surf_num].area)
                
                state.data_heat_bal_fan_sys.surf_q_rad_from_hvac[surf_num].steam_baseboard += this_surf_intensity
                
                if this_surf_intensity > max_rad_heat_flux:
                    show_severe_error(state, "DistributeBBSteamRadGains: excessive thermal radiation intensity")
                    show_fatal_error(state, "DistributeBBSteamRadGains: excessive thermal radiation heat flux intensity detected")
            else:
                show_severe_error(state, "DistributeBBSteamRadGains: surface not large enough")
                show_fatal_error(state, "DistributeBBSteamRadGains: surface not large enough to receive thermal radiation heat flux")

fn report_steam_baseboard(state: AnyType, baseboard_num: Int) -> None:
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_energy = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].tot_power * state.data_hvac_global.time_step_sys_sec
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].energy = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].power * state.data_hvac_global.time_step_sys_sec
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].conv_energy = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].conv_power * state.data_hvac_global.time_step_sys_sec
    state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].rad_energy = \
        state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].rad_power * state.data_hvac_global.time_step_sys_sec

fn update_steam_baseboard_plant_connection(state: AnyType, baseboard_type: Int, baseboard_name: String,
                                          equip_flow_ctrl: Int, loop_num: Int, loop_side: AnyType,
                                          inout comp_index: Int, first_hvac_iteration: Bool, init_loop_equip: Bool) -> None:
    var baseboard_num: Int = 0
    
    if comp_index == 0:
        baseboard_num = find_item_in_list(baseboard_name, state.data_steam_baseboard_radiator.steam_baseboards)
        if baseboard_num < 0:
            show_fatal_error(state, "UpdateSteamBaseboardPlantConnection: Specified baseboard not valid")
        comp_index = baseboard_num
    else:
        baseboard_num = comp_index
        if baseboard_num >= state.data_steam_baseboard_radiator.num_steam_baseboards or baseboard_num < 0:
            show_fatal_error(state, "UpdateSteamBaseboardPlantConnection: Invalid CompIndex")
        
        if state.data_global.kick_off_simulation:
            if baseboard_name != state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].name:
                show_fatal_error(state, "UpdateSteamBaseboardPlantConnection: Invalid CompIndex")
            if baseboard_type != 1:
                show_fatal_error(state, "UpdateSteamBaseboardPlantConnection: Invalid equipment type")
    
    if init_loop_equip:
        return
    
    pull_comp_interconnect_trigger(state,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].bb_load_re_sim_index,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  "HeatTransferRate",
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].power)
    
    pull_comp_interconnect_trigger(state,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].bb_mass_flow_re_sim_index,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  "MassFlowRate",
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_mass_flow_rate)
    
    pull_comp_interconnect_trigger(state,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].bb_inlet_temp_flow_re_sim_index,
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].plant_loc,
                                  "Temperature",
                                  state.data_steam_baseboard_radiator.steam_baseboards[baseboard_num].steam_outlet_temp)

fn find_item_in_list(name: String, items: DynamicVector[SteamBaseboardParams]) -> Int:
    for i in range(len(items)):
        if items[i].name == name:
            return i
    return -1

fn same_string(str1: String, str2: String) -> Bool:
    return str1.lower() == str2.lower()

fn show_fatal_error(state: AnyType, msg: String) -> None:
    pass

fn show_severe_error(state: AnyType, msg: String) -> None:
    pass

fn show_continue_error(state: AnyType, msg: String) -> None:
    pass

fn show_warning_error(state: AnyType, msg: String) -> None:
    pass

fn show_message(state: AnyType, msg: String) -> None:
    pass

fn control_comp_output(state: AnyType, args: VariadicList) -> None:
    pass

fn set_component_flow_rate(state: AnyType, args: VariadicList) -> None:
    pass

fn init_component_nodes(state: AnyType, args: VariadicList) -> None:
    pass

fn scan_plant_loops_for_object(state: AnyType, args: VariadicList) -> None:
    pass

fn register_plant_comp_design_flow(state: AnyType, args: VariadicList) -> None:
    pass

fn safe_copy_plant_node(state: AnyType, args: VariadicList) -> None:
    pass

fn pull_comp_interconnect_trigger(state: AnyType, args: VariadicList) -> None:
    pass

fn check_zone_equipment_list(state: AnyType, args: VariadicList) -> Bool:
    return True

fn get_num_objects_found(state: AnyType, object_name: String) -> Int:
    return 0

fn get_object_item(state: AnyType, args: VariadicList) -> None:
    pass

fn get_num_numeric_fields(state: AnyType) -> Int:
    return 0

fn get_numeric_field_names(state: AnyType) -> DynamicVector[String]:
    return DynamicVector[String]()

fn get_alpha_arg(state: AnyType, index: Int) -> String:
    return ""

fn get_numeric_arg(state: AnyType, index: Int) -> Float64:
    return 0.0

fn get_numeric_field_name(state: AnyType, index: Int) -> String:
    return ""

fn verify_unique_baseboard_name(state: AnyType, args: VariadicList) -> None:
    pass

fn is_alpha_field_blank(state: AnyType, index: Int) -> Bool:
    return False

fn is_numeric_field_blank(state: AnyType, index: Int) -> Bool:
    return False

fn get_schedule_always_on(state: AnyType) -> AnyType:
    return AnyType()

fn get_schedule(state: AnyType, name: String) -> AnyType:
    return AnyType()

fn get_only_single_node(state: AnyType, name: String, inout errors_found: Bool) -> Int:
    return 0

fn test_comp_set(state: AnyType, args: VariadicList) -> None:
    pass

fn get_steam(state: AnyType) -> AnyType:
    return AnyType()

fn get_radiant_system_surface(state: AnyType, args: VariadicList) -> Int:
    return -1

fn setup_output_variable(state: AnyType, args: VariadicList) -> None:
    pass

fn check_zone_sizing(state: AnyType, args: VariadicList) -> None:
    pass

fn report_sizer_output(state: AnyType, args: VariadicList) -> None:
    pass

fn get_current_zone_eq_num(state: AnyType) -> Int:
    return 0

fn calc_heat_balance_outside_surf(state: AnyType, zone_num: Int) -> None:
    pass

fn calc_heat_balance_inside_surf(state: AnyType, zone_num: Int) -> None:
    pass

fn hasattr(obj: AnyType, attr_name: String) -> Bool:
    return False
