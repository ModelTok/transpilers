from math import max as math_max, min as math_min


@value
struct BaseSizerWithScalableInputs:
    var sizing_type: String
    var sizing_string: String
    var auto_sized_value: Float64
    var original_value: Float64
    
    fn __init__(inout self):
        self.sizing_type = ""
        self.sizing_string = ""
        self.auto_sized_value = 0.0
        self.original_value = 0.0
    
    fn check_initialized(self, state: ref EnergyPlusData, inout errors_found: Bool) -> Bool:
        return True
    
    fn pre_size(self, state: ref EnergyPlusData, original_value: Float64):
        pass
    
    fn clear_state(inout self):
        pass
    
    fn select_sizer_output(self, state: ref EnergyPlusData, inout errors_found: Bool):
        pass
    
    fn calc_fan_des_heat_gain(self, vol_flow: Float64) -> Float64:
        return 0.0
    
    fn add_error_message(self, msg: String):
        pass


struct CoolingCapacitySizer(BaseSizerWithScalableInputs):
    var data_ems_override_on: Bool
    var data_ems_override: Float64
    var data_constant_used_for_sizing: Float64
    var data_fraction_used_for_sizing: Float64
    var cur_zone_eq_num: Int32
    var was_auto_sized: Bool
    var sizing_des_run_this_zone: Bool
    var zone_eq_sizing: Span[ZoneEqSizingType]
    var term_unit_iu: Bool
    var cur_term_unit_sizing_num: Int32
    var term_unit_sizing: Span[TermUnitSizingType]
    var zone_eq_fan_coil: Bool
    var final_zone_sizing: Span[FinalZoneSizingType]
    var comp_type: String
    var comp_name: String
    var data_flow_used_for_sizing: Float64
    var data_des_account_for_fan_heat: Bool
    var data_cool_coil_type: Int32
    var data_cool_coil_index: Int32
    var data_tot_cap_curve_index: Int32
    var data_tot_cap_curve_value: Float64
    var data_frac_of_autosized_cooling_capacity: Float64
    var calling_routine: String
    var cur_sys_num: Int32
    var sizing_des_run_this_air_sys: Bool
    var oa_sys_flag: Bool
    var cur_oa_sys_num: Int32
    var oa_sys_eq_sizing: Span[OASysEqSizingType]
    var air_loop_sys_flag: Bool
    var unitary_sys_eq_sizing: Span[UnitarySysEqSizingType]
    var coil_report_num: Int32
    var outside_air_sys: Span[OutsideAirSysType]
    var airloop_doas: Span[AirloopDOASType]
    var delta_p: Float64
    var mot_eff: Float64
    var tot_eff: Float64
    var mot_in_air_frac: Float64
    var fan_shaft_pow: Float64
    var mot_in_power: Float64
    var fan_comp_model: String
    var data_fan_type: String
    var data_fan_index: Int32
    var primary_air_system: Span[PrimaryAirSystemType]
    var final_sys_sizing: Span[FinalSysSizingType]
    var data_non_zone_non_airloop_value: Float64
    var data_is_dx_coil: Bool
    var print_warning_flag: Bool
    var hard_size_no_design_run: Bool
    var data_scalable_sizing_on: Bool
    var data_scalable_cap_sizing_on: Bool
    var override_size_string: Bool
    var sizing_string_scalable: String
    var is_coil_report_object: Bool
    var data_air_flow_used_for_sizing: Float64
    var data_des_outlet_air_temp: Float64
    var data_des_outlet_air_hum_rat: Float64
    var data_des_inlet_air_temp: Float64
    var data_des_inlet_air_hum_rat: Float64
    var data_dx_cools_low_speeds_autosized: Bool
    
    fn __init__(inout self):
        self.sizing_type = "CoolingCapacitySizing"
        self.sizing_string = "Cooling Design Capacity [W]"
        self.auto_sized_value = 0.0
        self.original_value = 0.0
        self.data_ems_override_on = False
        self.data_ems_override = 0.0
        self.data_constant_used_for_sizing = 0.0
        self.data_fraction_used_for_sizing = 0.0
        self.cur_zone_eq_num = 0
        self.was_auto_sized = False
        self.sizing_des_run_this_zone = False
        self.term_unit_iu = False
        self.cur_term_unit_sizing_num = 0
        self.zone_eq_fan_coil = False
        self.comp_type = ""
        self.comp_name = ""
        self.data_flow_used_for_sizing = 0.0
        self.data_des_account_for_fan_heat = False
        self.data_cool_coil_type = 0
        self.data_cool_coil_index = 0
        self.data_tot_cap_curve_index = 0
        self.data_tot_cap_curve_value = 0.0
        self.data_frac_of_autosized_cooling_capacity = 1.0
        self.calling_routine = ""
        self.cur_sys_num = 0
        self.sizing_des_run_this_air_sys = False
        self.oa_sys_flag = False
        self.cur_oa_sys_num = 0
        self.air_loop_sys_flag = False
        self.coil_report_num = 0
        self.delta_p = 0.0
        self.mot_eff = 0.0
        self.tot_eff = 0.0
        self.mot_in_air_frac = 0.0
        self.fan_shaft_pow = 0.0
        self.mot_in_power = 0.0
        self.fan_comp_model = ""
        self.data_fan_type = ""
        self.data_fan_index = 0
        self.data_non_zone_non_airloop_value = 0.0
        self.data_is_dx_coil = False
        self.print_warning_flag = False
        self.hard_size_no_design_run = False
        self.data_scalable_sizing_on = False
        self.data_scalable_cap_sizing_on = False
        self.override_size_string = False
        self.sizing_string_scalable = ""
        self.is_coil_report_object = False
        self.data_air_flow_used_for_sizing = 0.0
        self.data_des_outlet_air_temp = 0.0
        self.data_des_outlet_air_hum_rat = 0.0
        self.data_des_inlet_air_temp = 0.0
        self.data_des_inlet_air_hum_rat = 0.0
        self.data_dx_cools_low_speeds_autosized = False
    
    fn size(inout self, state: ref EnergyPlusData, original_value: Float64, inout errors_found: Bool) -> Float64:
        if not self.check_initialized(state, errors_found):
            return 0.0
        
        self.pre_size(state, original_value)
        
        var des_vol_flow: Float64 = 0.0
        var coil_in_temp: Float64 = -999.0
        var coil_in_hum_rat: Float64 = -999.0
        var coil_out_temp: Float64 = -999.0
        var coil_out_hum_rat: Float64 = -999.0
        var fan_cool_load: Float64 = 0.0
        var tot_cap_temp_mod_fac: Float64 = 1.0
        var dx_flow_per_cap_min_ratio: Float64 = 1.0
        var dx_flow_per_cap_max_ratio: Float64 = 1.0

        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing >= 0 and self.data_fraction_used_for_sizing > 0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.cur_zone_eq_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                    self.auto_sized_value = original_value
                elif self.zone_eq_sizing[self.cur_zone_eq_num].design_size_from_parent:
                    self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].des_cooling_load
                else:
                    if self.zone_eq_sizing[self.cur_zone_eq_num].cooling_capacity:
                        self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].des_cooling_load
                        des_vol_flow = self.data_flow_used_for_sizing
                        coil_in_temp = state.data_size.data_coil_sizing_air_in_temp
                        coil_in_hum_rat = state.data_size.data_coil_sizing_air_in_hum_rat
                        coil_out_temp = state.data_size.data_coil_sizing_air_out_temp
                        coil_out_hum_rat = state.data_size.data_coil_sizing_air_out_hum_rat
                        fan_cool_load = state.data_size.data_coil_sizing_fan_cool_load
                        tot_cap_temp_mod_fac = state.data_size.data_coil_sizing_cap_ft
                    else:
                        if (same_string(self.comp_type, "COIL:COOLING:WATER") or
                            same_string(self.comp_type, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                            same_string(self.comp_type, "ZONEHVAC:IDEALLOADSAIRSYSTEM")):
                            if self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                                self.auto_sized_value = self.term_unit_sizing[self.cur_term_unit_sizing_num].des_cooling_load
                            elif self.zone_eq_fan_coil:
                                self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].des_cooling_load
                            else:
                                coil_in_temp = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_temp
                                coil_in_hum_rat = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_hum_rat
                                coil_out_temp = math_min(coil_in_temp, self.final_zone_sizing[self.cur_zone_eq_num].cool_des_temp)
                                coil_out_hum_rat = math_min(coil_in_hum_rat, self.final_zone_sizing[self.cur_zone_eq_num].cool_des_hum_rat)
                                self.auto_sized_value = (
                                    self.final_zone_sizing[self.cur_zone_eq_num].des_cool_mass_flow *
                                    (psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat) - psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat))
                                )
                                des_vol_flow = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_mass_flow / state.data_envrn.std_rho_air
                                fan_cool_load += self.calc_fan_des_heat_gain(des_vol_flow)
                                self.auto_sized_value += fan_cool_load
                        else:
                            des_vol_flow = self.data_flow_used_for_sizing
                            if des_vol_flow >= state.hvac.small_air_vol_flow:
                                if state.data_size.zone_eq_dx_coil:
                                    if self.zone_eq_sizing[self.cur_zone_eq_num].at_mixer_vol_flow > 0.0:
                                        var des_mass_flow: Float64 = des_vol_flow * state.data_envrn.std_rho_air
                                        coil_in_temp = set_cool_coil_inlet_temp_for_zone_eq_sizing(
                                            set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing[self.cur_zone_eq_num]),
                                            self.zone_eq_sizing[self.cur_zone_eq_num],
                                            self.final_zone_sizing[self.cur_zone_eq_num]
                                        )
                                        coil_in_hum_rat = set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(
                                            set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing[self.cur_zone_eq_num]),
                                            self.zone_eq_sizing[self.cur_zone_eq_num],
                                            self.final_zone_sizing[self.cur_zone_eq_num]
                                        )
                                    elif self.zone_eq_sizing[self.cur_zone_eq_num].oa_vol_flow > 0.0:
                                        coil_in_temp = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_temp
                                        coil_in_hum_rat = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_hum_rat
                                    else:
                                        coil_in_temp = self.final_zone_sizing[self.cur_zone_eq_num].zone_ret_temp_at_cool_peak
                                        coil_in_hum_rat = self.final_zone_sizing[self.cur_zone_eq_num].zone_hum_rat_at_cool_peak
                                elif self.zone_eq_fan_coil:
                                    var des_mass_flow: Float64 = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_mass_flow
                                    coil_in_temp = set_cool_coil_inlet_temp_for_zone_eq_sizing(
                                        set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing[self.cur_zone_eq_num]),
                                        self.zone_eq_sizing[self.cur_zone_eq_num],
                                        self.final_zone_sizing[self.cur_zone_eq_num]
                                    )
                                    coil_in_hum_rat = set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(
                                        set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing[self.cur_zone_eq_num]),
                                        self.zone_eq_sizing[self.cur_zone_eq_num],
                                        self.final_zone_sizing[self.cur_zone_eq_num]
                                    )
                                else:
                                    coil_in_temp = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_temp
                                    coil_in_hum_rat = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_coil_in_hum_rat
                                
                                coil_out_temp = math_min(coil_in_temp, self.final_zone_sizing[self.cur_zone_eq_num].cool_des_temp)
                                coil_out_hum_rat = math_min(coil_in_hum_rat, self.final_zone_sizing[self.cur_zone_eq_num].cool_des_hum_rat)
                                var time_step_num_at_max: Int32 = self.final_zone_sizing[self.cur_zone_eq_num].time_step_num_at_cool_max
                                var dd_num: Int32 = self.final_zone_sizing[self.cur_zone_eq_num].cool_dd_num
                                var out_temp: Float64 = 0.0
                                if dd_num > 0 and time_step_num_at_max > 0:
                                    out_temp = state.data_size.des_day_weath[dd_num].temp[time_step_num_at_max]
                                
                                if self.data_cool_coil_type == state.hvac.cooling_wahp_variable_speed_equation_fit:
                                    out_temp = get_vs_coil_rated_source_temp(state, self.data_cool_coil_index)
                                
                                var coil_in_enth: Float64 = psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat)
                                var coil_out_enth: Float64 = psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat)
                                var peak_coil_load: Float64 = math_max(0.0, state.data_envrn.std_rho_air * des_vol_flow * (coil_in_enth - coil_out_enth))
                                fan_cool_load += self.calc_fan_des_heat_gain(des_vol_flow)
                                peak_coil_load += fan_cool_load
                                
                                var cp_air: Float64 = psy_cp_air_fn_w(coil_in_hum_rat)
                                if self.data_des_account_for_fan_heat:
                                    if state.data_size.data_fan_placement == state.hvac.fan_place_blow_thru:
                                        coil_in_temp += fan_cool_load / (cp_air * state.data_envrn.std_rho_air * des_vol_flow)
                                    elif state.data_size.data_fan_placement == state.hvac.fan_place_draw_thru:
                                        coil_out_temp -= fan_cool_load / (cp_air * state.data_envrn.std_rho_air * des_vol_flow)
                                
                                var coil_in_wet_bulb: Float64 = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.data_envrn.std_baro_press, self.calling_routine)
                                
                                if self.data_tot_cap_curve_index > 0:
                                    var num_dims: Int32 = state.data_curve_manager.curves[self.data_tot_cap_curve_index].num_dims
                                    if num_dims == 1:
                                        tot_cap_temp_mod_fac = curve_value(state, self.data_tot_cap_curve_index, coil_in_wet_bulb)
                                    else:
                                        tot_cap_temp_mod_fac = curve_value(state, self.data_tot_cap_curve_index, coil_in_wet_bulb, out_temp)
                                elif self.data_tot_cap_curve_value > 0:
                                    tot_cap_temp_mod_fac = self.data_tot_cap_curve_value
                                else:
                                    tot_cap_temp_mod_fac = 1.0
                                
                                if tot_cap_temp_mod_fac > 0.0:
                                    self.auto_sized_value = peak_coil_load / tot_cap_temp_mod_fac
                                else:
                                    self.auto_sized_value = peak_coil_load
                                
                                state.data_size.data_coil_sizing_air_in_temp = coil_in_temp
                                state.data_size.data_coil_sizing_air_in_hum_rat = coil_in_hum_rat
                                state.data_size.data_coil_sizing_air_out_temp = coil_out_temp
                                state.data_size.data_coil_sizing_air_out_hum_rat = coil_out_hum_rat
                                state.data_size.data_coil_sizing_fan_cool_load = fan_cool_load
                                state.data_size.data_coil_sizing_cap_ft = tot_cap_temp_mod_fac
                            else:
                                self.auto_sized_value = 0.0
                                coil_out_temp = -999.0
                    
                    self.auto_sized_value = self.auto_sized_value * self.data_frac_of_autosized_cooling_capacity
                    self.data_des_account_for_fan_heat = True
                    
                    if state.data_global.display_extra_warnings and self.auto_sized_value <= 0.0:
                        show_warning_message(state, self.calling_routine + ": Potential issue with equipment sizing for " + self.comp_type + ' ' + self.comp_name)
                        show_continue_error(state, f"...Rated Total Cooling Capacity = {self.auto_sized_value:.2f} [W]")
                        
                        if self.zone_eq_sizing[self.cur_zone_eq_num].cooling_capacity:
                            show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.auto_sized_value:.2f} [W]")
                        else:
                            if (same_string(self.comp_type, "COIL:COOLING:WATER") or
                                same_string(self.comp_type, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                                same_string(self.comp_type, "ZONEHVAC:IDEALLOADSAIRSYSTEM")):
                                if self.term_unit_iu or self.zone_eq_fan_coil:
                                    show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.auto_sized_value:.2f} [W]")
                                else:
                                    show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                                    show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                                    show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                            else:
                                if coil_out_temp > -999.0:
                                    show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                                    show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                                    show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                                else:
                                    show_continue_error(state, "...Capacity used to size child component set to 0 [W]")
            
            elif self.cur_sys_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                    self.auto_sized_value = original_value
                else:
                    var out_air_frac: Float64 = 0.0
                    self.data_frac_of_autosized_cooling_capacity = 1.0
                    
                    if self.oa_sys_flag:
                        self.auto_sized_value = self.oa_sys_eq_sizing[self.cur_oa_sys_num].des_cooling_load
                        des_vol_flow = self.data_flow_used_for_sizing
                    elif self.air_loop_sys_flag:
                        self.auto_sized_value = self.unitary_sys_eq_sizing[self.cur_sys_num].des_cooling_load
                        des_vol_flow = self.data_flow_used_for_sizing
                        coil_in_temp = state.data_size.data_coil_sizing_air_in_temp
                        coil_in_hum_rat = state.data_size.data_coil_sizing_air_in_hum_rat
                        coil_out_temp = state.data_size.data_coil_sizing_air_out_temp
                        coil_out_hum_rat = state.data_size.data_coil_sizing_air_out_hum_rat
                        fan_cool_load = state.data_size.data_coil_sizing_fan_cool_load
                        tot_cap_temp_mod_fac = state.data_size.data_coil_sizing_cap_ft
                        
                        if is_comp_type_coil(self.comp_type):
                            set_coil_ent_air_hum_rat(state, self.coil_report_num, coil_in_hum_rat)
                            set_coil_ent_air_temp(state, self.coil_report_num, coil_in_temp, self.cur_sys_num, self.cur_zone_eq_num)
                            set_coil_lvg_air_temp(state, self.coil_report_num, coil_out_temp)
                            set_coil_lvg_air_hum_rat(state, self.coil_report_num, coil_out_hum_rat)
                    
                    elif self.cur_oa_sys_num > 0 and self.outside_air_sys[self.cur_oa_sys_num].air_loop_doas_num > -1:
                        var this_airloop_doas = self.airloop_doas[self.outside_air_sys[self.cur_oa_sys_num].air_loop_doas_num]
                        des_vol_flow = this_airloop_doas.sizing_mass_flow / state.data_envrn.std_rho_air
                        coil_in_temp = this_airloop_doas.sizing_cool_oa_temp
                        coil_out_temp = this_airloop_doas.precool_temp
                        
                        if this_airloop_doas.m_fan_index > 0:
                            var fan_index: Int32 = this_airloop_doas.m_fan_index
                            state.data_fans.fans[fan_index].get_inputs_for_design_heat_gain(
                                state, self.delta_p, self.mot_eff, self.tot_eff, self.mot_in_air_frac,
                                self.fan_shaft_pow, self.mot_in_power, self.fan_comp_model
                            )
                            
                            if this_airloop_doas.m_fan_type_num == state.sim_air_serving_zones.comp_type_fan_component_model:
                                fan_cool_load = self.fan_shaft_pow + (self.mot_in_power - self.fan_shaft_pow) * self.mot_in_air_frac
                            elif this_airloop_doas.m_fan_type_num == state.sim_air_serving_zones.comp_type_fan_system_object:
                                var fan_power_tot: Float64 = (des_vol_flow * self.delta_p) / self.tot_eff
                                fan_cool_load = self.mot_eff * fan_power_tot + (fan_power_tot - self.mot_eff * fan_power_tot) * self.mot_in_air_frac
                            
                            self.data_fan_type = state.data_fans.fans[fan_index].type
                            self.data_fan_index = fan_index
                            
                            var cp_air: Float64 = psy_cp_air_fn_w(state.data_loop_nodes.node[this_airloop_doas.m_fan_inlet_node_num].hum_rat)
                            var delta_t: Float64 = fan_cool_load / (this_airloop_doas.sizing_mass_flow * cp_air)
                            
                            if this_airloop_doas.fan_before_cooling_coil_flag:
                                coil_in_temp += delta_t
                            else:
                                coil_out_temp -= delta_t
                                coil_out_temp = math_max(coil_out_temp, psy_tdp_fn_w_pb(state, this_airloop_doas.precool_hum_rat, state.data_envrn.std_baro_press))
                        
                        coil_in_hum_rat = this_airloop_doas.sizing_cool_oa_hum_rat
                        coil_out_hum_rat = this_airloop_doas.precool_hum_rat
                        self.auto_sized_value = (
                            des_vol_flow * state.data_envrn.std_rho_air *
                            (psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat) - psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat))
                        )
                    
                    else:
                        check_sys_sizing(state, self.comp_type, self.comp_name)
                        var this_final_sys_sizing = self.final_sys_sizing[self.cur_sys_num]
                        des_vol_flow = self.data_flow_used_for_sizing
                        var nominal_capacity_des: Float64 = 0.0
                        
                        if this_final_sys_sizing.cooling_cap_method == state.data_sizing.fraction_of_autosized_cooling_capacity:
                            self.data_frac_of_autosized_cooling_capacity = this_final_sys_sizing.fraction_of_autosized_cooling_capacity
                        
                        if this_final_sys_sizing.cooling_cap_method == state.data_sizing.capacity_per_floor_area:
                            nominal_capacity_des = this_final_sys_sizing.cooling_total_capacity
                            self.auto_sized_value = nominal_capacity_des
                        elif (this_final_sys_sizing.cooling_cap_method == state.data_sizing.cooling_design_capacity and
                              this_final_sys_sizing.cooling_total_capacity > 0.0):
                            nominal_capacity_des = this_final_sys_sizing.cooling_total_capacity
                            self.auto_sized_value = nominal_capacity_des
                        elif des_vol_flow >= state.hvac.small_air_vol_flow:
                            if des_vol_flow > 0.0:
                                out_air_frac = this_final_sys_sizing.des_out_air_vol_flow / des_vol_flow
                            else:
                                out_air_frac = 1.0
                            out_air_frac = math_min(1.0, math_max(0.0, out_air_frac))
                            
                            if self.cur_oa_sys_num > 0:
                                coil_in_temp = this_final_sys_sizing.out_temp_at_cool_peak
                                coil_in_hum_rat = this_final_sys_sizing.out_hum_rat_at_cool_peak
                                coil_out_temp = this_final_sys_sizing.precool_temp
                                coil_out_hum_rat = this_final_sys_sizing.precool_hum_rat
                            else:
                                if self.data_air_flow_used_for_sizing > 0.0:
                                    des_vol_flow = self.data_air_flow_used_for_sizing
                                if self.data_des_outlet_air_temp > 0.0:
                                    coil_out_temp = self.data_des_outlet_air_temp
                                else:
                                    coil_out_temp = this_final_sys_sizing.cool_sup_temp
                                if self.data_des_outlet_air_hum_rat > 0.0:
                                    coil_out_hum_rat = self.data_des_outlet_air_hum_rat
                                else:
                                    coil_out_hum_rat = this_final_sys_sizing.cool_sup_hum_rat
                                
                                if self.primary_air_system[self.cur_sys_num].num_oa_cool_coils == 0:
                                    coil_in_temp = this_final_sys_sizing.mix_temp_at_cool_peak
                                    coil_in_hum_rat = this_final_sys_sizing.mix_hum_rat_at_cool_peak
                                else:
                                    if des_vol_flow > 0.0:
                                        out_air_frac = this_final_sys_sizing.des_out_air_vol_flow / des_vol_flow
                                    else:
                                        out_air_frac = 1.0
                                    out_air_frac = math_min(1.0, math_max(0.0, out_air_frac))
                                    coil_in_temp = (out_air_frac * this_final_sys_sizing.precool_temp +
                                                    (1.0 - out_air_frac) * this_final_sys_sizing.ret_temp_at_cool_peak)
                                    coil_in_hum_rat = (out_air_frac * this_final_sys_sizing.precool_hum_rat +
                                                       (1.0 - out_air_frac) * this_final_sys_sizing.ret_hum_rat_at_cool_peak)
                                
                                if self.data_des_inlet_air_temp > 0.0:
                                    coil_in_temp = self.data_des_inlet_air_temp
                                if self.data_des_inlet_air_hum_rat > 0.0:
                                    coil_in_hum_rat = self.data_des_inlet_air_hum_rat
                            
                            var out_temp: Float64 = this_final_sys_sizing.out_temp_at_cool_peak
                            if self.data_cool_coil_type == state.hvac.cooling_wahp_variable_speed_equation_fit:
                                out_temp = get_vs_coil_rated_source_temp(state, self.data_cool_coil_index)
                            
                            coil_out_temp = math_min(coil_in_temp, coil_out_temp)
                            coil_out_hum_rat = math_min(coil_in_hum_rat, coil_out_hum_rat)
                            
                            var coil_in_enth: Float64 = psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat)
                            var coil_in_wet_bulb: Float64 = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.data_envrn.std_baro_press, self.calling_routine)
                            var coil_out_enth: Float64 = psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat)
                            
                            if self.cur_oa_sys_num > 0:
                                pass
                            else:
                                if self.primary_air_system[self.cur_sys_num].sup_fan_type != state.hvac.fan_type_invalid:
                                    fan_cool_load = self.calc_fan_des_heat_gain(des_vol_flow)
                                if self.primary_air_system[self.cur_sys_num].ret_fan_type != state.hvac.fan_type_invalid:
                                    fan_cool_load += (1.0 - out_air_frac) * self.calc_fan_des_heat_gain(des_vol_flow)
                                self.primary_air_system[self.cur_sys_num].fan_des_cool_load = fan_cool_load
                            
                            var peak_coil_load: Float64 = math_max(0.0, state.data_envrn.std_rho_air * des_vol_flow * (coil_in_enth - coil_out_enth))
                            var cp_air: Float64 = psy_cp_air_fn_w(coil_in_hum_rat)
                            
                            if self.data_des_account_for_fan_heat:
                                peak_coil_load = math_max(0.0, state.data_envrn.std_rho_air * des_vol_flow * (coil_in_enth - coil_out_enth) + fan_cool_load)
                                if self.primary_air_system[self.cur_sys_num].sup_fan_place == state.hvac.fan_place_blow_thru:
                                    coil_in_temp += fan_cool_load / (cp_air * state.data_envrn.std_rho_air * des_vol_flow)
                                    coil_in_wet_bulb = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.data_envrn.std_baro_press, self.calling_routine)
                                elif self.primary_air_system[self.cur_sys_num].sup_fan_place == state.hvac.fan_place_draw_thru:
                                    coil_out_temp -= fan_cool_load / (cp_air * state.data_envrn.std_rho_air * des_vol_flow)
                            
                            if self.data_tot_cap_curve_index > 0:
                                var num_dims: Int32 = state.data_curve_manager.curves[self.data_tot_cap_curve_index].num_dims
                                if num_dims == 1:
                                    tot_cap_temp_mod_fac = curve_value(state, self.data_tot_cap_curve_index, coil_in_wet_bulb)
                                else:
                                    tot_cap_temp_mod_fac = curve_value(state, self.data_tot_cap_curve_index, coil_in_wet_bulb, out_temp)
                            else:
                                tot_cap_temp_mod_fac = 1.0
                            
                            if tot_cap_temp_mod_fac > 0.0:
                                nominal_capacity_des = peak_coil_load / tot_cap_temp_mod_fac
                            else:
                                nominal_capacity_des = peak_coil_load
                            
                            state.data_size.data_coil_sizing_air_in_temp = coil_in_temp
                            state.data_size.data_coil_sizing_air_in_hum_rat = coil_in_hum_rat
                            state.data_size.data_coil_sizing_air_out_temp = coil_out_temp
                            state.data_size.data_coil_sizing_air_out_hum_rat = coil_out_hum_rat
                            state.data_size.data_coil_sizing_fan_cool_load = fan_cool_load
                            state.data_size.data_coil_sizing_cap_ft = tot_cap_temp_mod_fac
                        else:
                            nominal_capacity_des = 0.0
                        
                        self.auto_sized_value = nominal_capacity_des * self.data_frac_of_autosized_cooling_capacity
                    
                    self.data_des_account_for_fan_heat = True
                    
                    if state.data_global.display_extra_warnings and self.auto_sized_value <= 0.0:
                        show_warning_message(state, self.calling_routine + ": Potential issue with equipment sizing for " + self.comp_type + ' ' + self.comp_name)
                        show_continue_error(state, f"...Rated Total Cooling Capacity = {self.auto_sized_value:.2f} [W]")
                        
                        if (self.oa_sys_flag or self.air_loop_sys_flag or
                            this_final_sys_sizing.cooling_cap_method == state.data_sizing.capacity_per_floor_area or
                            (this_final_sys_sizing.cooling_cap_method == state.data_sizing.cooling_design_capacity and
                             this_final_sys_sizing.cooling_total_capacity != 0.0)):
                            show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.auto_sized_value:.2f} [W]")
                        else:
                            show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                            show_continue_error(state, f"...Outdoor air fraction used for sizing = {out_air_frac:.2f}")
                            show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                            show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
            
            elif self.data_non_zone_non_airloop_value > 0:
                self.auto_sized_value = self.data_non_zone_non_airloop_value
            elif not self.was_auto_sized:
                self.auto_sized_value = self.original_value
            else:
                var msg: String = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                show_severe_error(state, msg)
                self.add_error_message(msg)
                msg = f"SizingString = {self.sizing_string}, SizingResult = {self.auto_sized_value:.1f}"
                show_continue_error(state, msg)
                self.add_error_message(msg)
                errors_found = True
        
        if self.data_dx_cools_low_speeds_autosized:
            self.auto_sized_value *= self.data_fraction_used_for_sizing
        
        if not self.hard_size_no_design_run or self.data_scalable_sizing_on or self.data_scalable_cap_sizing_on:
            if self.was_auto_sized:
                var flag_check_vol_flow_per_rated_tot_cap: Bool = True
                if (same_string(self.comp_type, "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl") or
                    same_string(self.comp_type, "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl")):
                    flag_check_vol_flow_per_rated_tot_cap = False
                
                if self.data_is_dx_coil and flag_check_vol_flow_per_rated_tot_cap:
                    var rated_vol_flow_per_rated_tot_cap: Float64 = 0.0
                    if self.auto_sized_value > 0.0:
                        rated_vol_flow_per_rated_tot_cap = des_vol_flow / self.auto_sized_value
                    
                    if rated_vol_flow_per_rated_tot_cap < state.hvac.min_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]:
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            show_warning_error(state, self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name)
                            show_continue_error(state, "..." + self.sizing_string + " will be limited by the minimum rated volume flow per rated total capacity ratio.")
                            show_continue_error(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            show_continue_error(state, f"...Requested capacity [W] = {self.auto_sized_value:.3f}")
                            show_continue_error(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            show_continue_error(state, f"...Minimum flow/capacity ratio [m3/s/W] = {state.hvac.min_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]:.6e}")
                        
                        dx_flow_per_cap_min_ratio = ((des_vol_flow / state.hvac.min_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]) /
                                                      self.auto_sized_value)
                        self.auto_sized_value = des_vol_flow / state.hvac.min_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]
                        
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            show_continue_error(state, f"...Adjusted capacity [W] = {self.auto_sized_value:.3f}")
                    
                    elif rated_vol_flow_per_rated_tot_cap > state.hvac.max_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]:
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            show_warning_error(state, self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name)
                            show_continue_error(state, "..." + self.sizing_string + " will be limited by the maximum rated volume flow per rated total capacity ratio.")
                            show_continue_error(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            show_continue_error(state, f"...Requested capacity [W] = {self.auto_sized_value:.3f}")
                            show_continue_error(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            show_continue_error(state, f"...Maximum flow/capacity ratio [m3/s/W] = {state.hvac.max_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]:.6e}")
                        
                        dx_flow_per_cap_max_ratio = ((des_vol_flow / state.hvac.max_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]) /
                                                      self.auto_sized_value)
                        self.auto_sized_value = des_vol_flow / state.hvac.max_rated_vol_flow_per_rated_tot_cap[Int(state.data_hvac_global.dxct)]
                        
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            show_continue_error(state, f"...Adjusted capacity [W] = {self.auto_sized_value:.3f}")
        
        if self.override_size_string:
            self.sizing_string = "Cooling Design Capacity [W]"
        
        if self.data_scalable_cap_sizing_on:
            var select_case_var: Int32 = self.zone_eq_sizing[self.cur_zone_eq_num].sizing_method[state.hvac.cooling_capacity_sizing]
            if select_case_var == state.data_sizing.capacity_per_floor_area:
                self.sizing_string_scalable = "(scaled by capacity / area) "
            elif (select_case_var == state.data_sizing.fraction_of_autosized_heating_capacity or
                  select_case_var == state.data_sizing.fraction_of_autosized_cooling_capacity):
                self.sizing_string_scalable = "(scaled by fractional multiplier) "
        
        self.select_sizer_output(state, errors_found)
        
        if self.is_coil_report_object and self.cur_sys_num <= state.data_hvac_global.num_primary_air_sys:
            if coil_in_temp > -999.0:
                set_coil_ent_air_temp(state, self.coil_report_num, coil_in_temp, self.cur_sys_num, self.cur_zone_eq_num)
                set_coil_ent_air_hum_rat(state, self.coil_report_num, coil_in_hum_rat)
            if coil_out_temp > -999.0:
                set_coil_lvg_air_temp(state, self.coil_report_num, coil_out_temp)
                set_coil_lvg_air_hum_rat(state, self.coil_report_num, coil_out_hum_rat)
            set_coil_cooling_capacity(state, self.coil_report_num, self.auto_sized_value, self.was_auto_sized,
                                     self.cur_sys_num, self.cur_zone_eq_num, self.cur_oa_sys_num,
                                     fan_cool_load, tot_cap_temp_mod_fac,
                                     dx_flow_per_cap_min_ratio, dx_flow_per_cap_max_ratio)
        
        return self.auto_sized_value
    
    fn clear_state(inout self):
        super.clear_state()


fn same_string(s1: String, s2: String) -> Bool:
    return s1.upper() == s2.upper()


fn psy_h_fn_tdb_w(tdb: Float64, w: Float64) -> Float64:
    return 0.0


fn psy_twb_fn_tdb_w_pb(state: ref EnergyPlusData, tdb: Float64, w: Float64, pb: Float64, routine: String) -> Float64:
    return 0.0


fn psy_cp_air_fn_w(w: Float64) -> Float64:
    return 0.0


fn psy_tdp_fn_w_pb(state: ref EnergyPlusData, w: Float64, pb: Float64) -> Float64:
    return 0.0


fn set_cool_coil_inlet_temp_for_zone_eq_sizing(oa_frac: Float64, zone_eq_sizing: ref ZoneEqSizingType, final_zone_sizing: ref FinalZoneSizingType) -> Float64:
    return 0.0


fn set_oa_frac_for_zone_eq_sizing(state: ref EnergyPlusData, des_mass_flow: Float64, zone_eq_sizing: ref ZoneEqSizingType) -> Float64:
    return 0.0


fn set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(oa_frac: Float64, zone_eq_sizing: ref ZoneEqSizingType, final_zone_sizing: ref FinalZoneSizingType) -> Float64:
    return 0.0


fn curve_value(state: ref EnergyPlusData, curve_index: Int32, *args: Float64) -> Float64:
    return 0.0


fn get_vs_coil_rated_source_temp(state: ref EnergyPlusData, coil_index: Int32) -> Float64:
    return 0.0


fn show_warning_message(state: ref EnergyPlusData, msg: String):
    pass


fn show_continue_error(state: ref EnergyPlusData, msg: String):
    pass


fn show_severe_error(state: ref EnergyPlusData, msg: String):
    pass


fn show_warning_error(state: ref EnergyPlusData, msg: String):
    pass


fn is_comp_type_coil(comp_type: String) -> Bool:
    return False


fn set_coil_ent_air_hum_rat(state: ref EnergyPlusData, report_num: Int32, hum_rat: Float64):
    pass


fn set_coil_ent_air_temp(state: ref EnergyPlusData, report_num: Int32, temp: Float64, sys_num: Int32, zone_num: Int32):
    pass


fn set_coil_lvg_air_temp(state: ref EnergyPlusData, report_num: Int32, temp: Float64):
    pass


fn set_coil_lvg_air_hum_rat(state: ref EnergyPlusData, report_num: Int32, hum_rat: Float64):
    pass


fn set_coil_cooling_capacity(state: ref EnergyPlusData, report_num: Int32, capacity: Float64, was_autosized: Bool,
                             sys_num: Int32, zone_num: Int32, oa_sys_num: Int32,
                             fan_cool_load: Float64, tot_cap_temp_mod_fac: Float64,
                             dx_flow_per_cap_min_ratio: Float64, dx_flow_per_cap_max_ratio: Float64):
    pass


fn check_sys_sizing(state: ref EnergyPlusData, comp_type: String, comp_name: String):
    pass


struct EnergyPlusData:
    pass


struct ZoneEqSizingType:
    pass


struct TermUnitSizingType:
    pass


struct FinalZoneSizingType:
    pass


struct OASysEqSizingType:
    pass


struct UnitarySysEqSizingType:
    pass


struct OutsideAirSysType:
    pass


struct AirloopDOASType:
    pass


struct PrimaryAirSystemType:
    pass


struct FinalSysSizingType:
    pass
