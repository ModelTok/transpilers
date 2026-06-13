# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data* members (from EnergyPlus/Data/EnergyPlusData.hh)
# - BaseSizerWithScalableInputs: parent struct (from EnergyPlus/Autosizing/BaseSizerWithScalableInputs.hh)
# - HVAC.CoolingAirflowSizing, HVAC.AirDuctType, HVAC.CoilType: enums (from EnergyPlus/DataHVACGlobals.hh)
# - DataSizing: enum values SupplyAirFlowRate, None, FlowPerFloorArea, FractionOfAutosizedCoolingAirflow, etc.
# - Util.same_string: string comparison function
# - show_severe_error, show_continue_error: error reporting functions
# - ReportCoilSelection.set_coil_air_flow, ReportCoilSelection.get_time_text: reporting functions
# - OutputReportPredefined.predef_table_entry: reporting function
# - outside_air_sys: global array or indexing function

from math import max

struct BaseSizerWithScalableInputs:
    fn check_initialized(inout self, state: AnyType, errorsFound: AnyType) -> Bool:
        return False
    
    fn pre_size(inout self, state: AnyType, originalValue: Float64):
        pass
    
    fn select2_stg_dx_hum_ctrl_sizer_output(inout self, state: AnyType, errorsFound: AnyType):
        pass
    
    fn clear_state(inout self):
        pass
    
    fn add_error_message(inout self, msg: String):
        pass

struct CoolingAirFlowSizer(BaseSizerWithScalableInputs):
    var sizing_type: Int32
    var sizing_string: String
    var data_ems_override_on: Bool
    var data_ems_override: Float64
    var data_constant_used_for_sizing: Float64
    var data_fraction_used_for_sizing: Float64
    var auto_sized_value: Float64
    var original_value: Float64
    var cur_zone_eq_num: Int32
    var was_auto_sized: Bool
    var sizing_des_run_this_zone: Bool
    var comp_type: String
    var data_bypass_frac: Float64
    var cur_sys_num: Int32
    var sizing_des_run_this_air_sys: Bool
    var cur_oa_sys_num: Int32
    var data_air_flow_used_for_sizing: Float64
    var cur_duct_type: Int32
    var data_non_zone_non_airloop_value: Float64
    var calling_routine: String
    var comp_name: String
    var override_size_string: Bool
    var coil_type: Int32
    var data_dx_speed_num: Int32
    var is_ep_json: Bool
    var data_scalable_sizing_on: Bool
    var zone_air_flow_siz_method: Int32
    var sizing_string_scalable: String
    var data_dx_cools_low_speeds_autosized: Bool
    var is_coil_report_object: Bool
    var coil_report_num: Int32
    var is_fan_report_object: Bool
    var term_unit_iu: Bool
    var cur_term_unit_sizing_num: Int32
    var zone_eq_fan_coil: Bool
    var zone_heating_only_fan: Bool
    var data_frac_of_autosized_cooling_airflow: Float64
    var data_frac_of_autosized_heating_airflow: Float64
    var data_flow_per_cooling_capacity: Float64
    var data_flow_per_heating_capacity: Float64
    var data_autosized_cooling_capacity: Float64
    var data_autosized_heating_capacity: Float64
    var airloop_doas: AnyType
    
    fn __init__(inout self):
        self.sizing_type = 0
        self.sizing_string = "Cooling Supply Air Flow Rate [m3/s]"
        self.data_ems_override_on = False
        self.data_ems_override = 0.0
        self.data_constant_used_for_sizing = 0.0
        self.data_fraction_used_for_sizing = 0.0
        self.auto_sized_value = 0.0
        self.original_value = 0.0
        self.cur_zone_eq_num = 0
        self.was_auto_sized = False
        self.sizing_des_run_this_zone = False
        self.comp_type = ""
        self.data_bypass_frac = 0.0
        self.cur_sys_num = 0
        self.sizing_des_run_this_air_sys = False
        self.cur_oa_sys_num = 0
        self.data_air_flow_used_for_sizing = 0.0
        self.cur_duct_type = 0
        self.data_non_zone_non_airloop_value = 0.0
        self.calling_routine = ""
        self.comp_name = ""
        self.override_size_string = False
        self.coil_type = 0
        self.data_dx_speed_num = 0
        self.is_ep_json = False
        self.data_scalable_sizing_on = False
        self.zone_air_flow_siz_method = 0
        self.sizing_string_scalable = ""
        self.data_dx_cools_low_speeds_autosized = False
        self.is_coil_report_object = False
        self.coil_report_num = 0
        self.is_fan_report_object = False
        self.term_unit_iu = False
        self.cur_term_unit_sizing_num = 0
        self.zone_eq_fan_coil = False
        self.zone_heating_only_fan = False
        self.data_frac_of_autosized_cooling_airflow = 0.0
        self.data_frac_of_autosized_heating_airflow = 0.0
        self.data_flow_per_cooling_capacity = 0.0
        self.data_flow_per_heating_capacity = 0.0
        self.data_autosized_cooling_capacity = 0.0
        self.data_autosized_heating_capacity = 0.0
        self.airloop_doas = AnyType()
    
    fn size(inout self, state: AnyType, original_value: Float64, errorsFound: AnyType) -> Float64:
        if not self.check_initialized(state, errorsFound):
            return 0.0
        
        self.pre_size(state, original_value)
        var cooling_flow: Bool = False
        var heating_flow: Bool = False
        
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing > 0 and self.data_fraction_used_for_sizing > 0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.cur_zone_eq_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                    self.auto_sized_value = original_value
                    if util_same_string(self.comp_type, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                        self.auto_sized_value /= (1.0 - self.data_bypass_frac)
                        self.original_value /= (1.0 - self.data_bypass_frac)
                elif self.zone_eq_sizing(self.cur_zone_eq_num).design_size_from_parent:
                    self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).air_vol_flow
                else:
                    var sizing_method: Int32 = self.zone_eq_sizing(self.cur_zone_eq_num).sizing_method(0)
                    
                    if sizing_method == 0 or sizing_method == 1 or sizing_method == 2:
                        if self.zone_eq_sizing(self.cur_zone_eq_num).system_air_flow:
                            self.auto_sized_value = max(
                                self.zone_eq_sizing(self.cur_zone_eq_num).air_vol_flow,
                                max(
                                    self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow,
                                    self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                                )
                            )
                            cooling_flow = True
                        else:
                            if state.data_size.zone_cooling_only_fan:
                                self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow
                                cooling_flow = True
                            elif state.data_size.zone_heating_only_fan:
                                self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                                heating_flow = True
                            elif self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow:
                                self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow
                                cooling_flow = True
                            elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                                self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                                heating_flow = True
                            elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                                self.auto_sized_value = max(
                                    self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow,
                                    self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                                )
                                if self.auto_sized_value == self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow:
                                    cooling_flow = True
                                elif self.auto_sized_value == self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow:
                                    heating_flow = True
                            else:
                                self.auto_sized_value = max(
                                    self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow,
                                    self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                                )
                                if self.auto_sized_value == self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow:
                                    cooling_flow = True
                                elif self.auto_sized_value == self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow:
                                    heating_flow = True
                    
                    elif sizing_method == 3:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow
                            cooling_flow = True
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow
                            cooling_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = max(
                                self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow,
                                self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                            )
                            if self.auto_sized_value == self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow:
                                heating_flow = True
                        else:
                            self.auto_sized_value = max(
                                self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow,
                                self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                            )
                            if self.auto_sized_value == self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow:
                                heating_flow = True
                    
                    elif sizing_method == 4:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow
                            cooling_flow = True
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow
                            cooling_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = max(
                                self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow,
                                self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow
                            )
                            if self.auto_sized_value == self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_vol_flow:
                                heating_flow = True
                        else:
                            self.auto_sized_value = max(
                                self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow,
                                self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                            )
                            if self.auto_sized_value == self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow:
                                heating_flow = True
                    
                    elif sizing_method == 5:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                            cooling_flow = True
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                            cooling_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = max(
                                self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            )
                            if self.auto_sized_value == self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity:
                                heating_flow = True
                        else:
                            self.auto_sized_value = max(
                                self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            )
                            if self.auto_sized_value == self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity:
                                heating_flow = True
                    
                    elif sizing_method == 6:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                            cooling_flow = True
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                            cooling_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and not self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            heating_flow = True
                        elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_air_flow and self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = max(
                                self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            )
                            if self.auto_sized_value == self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity:
                                heating_flow = True
                        else:
                            self.auto_sized_value = max(
                                self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                            )
                            if self.auto_sized_value == self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity:
                                cooling_flow = True
                            elif self.auto_sized_value == self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity:
                                heating_flow = True
                    
                    else:
                        if self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_flow:
                            self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).cooling_air_vol_flow
                        elif state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow
                        elif self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                            self.auto_sized_value = self.term_unit_sizing(self.cur_term_unit_sizing_num).air_vol_flow
                        elif self.zone_eq_fan_coil:
                            self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).air_vol_flow
                        elif self.zone_heating_only_fan:
                            self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                        else:
                            self.auto_sized_value = max(
                                self.final_zone_sizing(self.cur_zone_eq_num).des_cool_vol_flow,
                                self.final_zone_sizing(self.cur_zone_eq_num).des_heat_vol_flow
                            )
            
            elif self.cur_sys_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                    self.auto_sized_value = original_value
                    if util_same_string(self.comp_type, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                        self.auto_sized_value /= (1.0 - self.data_bypass_frac)
                        self.original_value /= (1.0 - self.data_bypass_frac)
                else:
                    if self.cur_oa_sys_num > 0:
                        if self.oa_sys_eq_sizing(self.cur_oa_sys_num).air_flow:
                            self.auto_sized_value = self.oa_sys_eq_sizing(self.cur_oa_sys_num).air_vol_flow
                        elif self.oa_sys_eq_sizing(self.cur_oa_sys_num).cooling_air_flow:
                            self.auto_sized_value = self.oa_sys_eq_sizing(self.cur_oa_sys_num).cooling_air_vol_flow
                        elif outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num > -1:
                            self.auto_sized_value = self.airloop_doas[outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].sizing_mass_flow / state.data_envrn.std_rho_air
                        else:
                            self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_out_air_vol_flow
                    elif self.data_air_flow_used_for_sizing > 0.0:
                        self.auto_sized_value = self.data_air_flow_used_for_sizing
                    else:
                        if self.unitary_sys_eq_sizing(self.cur_sys_num).air_flow:
                            self.auto_sized_value = self.unitary_sys_eq_sizing(self.cur_sys_num).air_vol_flow
                        elif self.unitary_sys_eq_sizing(self.cur_sys_num).cooling_air_flow:
                            self.auto_sized_value = self.unitary_sys_eq_sizing(self.cur_sys_num).cooling_air_vol_flow
                        else:
                            if self.cur_duct_type == 0:
                                self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
                            elif self.cur_duct_type == 1:
                                self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_cool_vol_flow
                            elif self.cur_duct_type == 2:
                                self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_heat_vol_flow
                            elif self.cur_duct_type == 3:
                                self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
                            else:
                                self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
            
            elif self.data_non_zone_non_airloop_value > 0:
                self.auto_sized_value = self.data_non_zone_non_airloop_value
            
            elif not self.was_auto_sized:
                self.auto_sized_value = self.original_value
            
            else:
                var msg: String = self.calling_routine + " " + self.comp_type + " " + self.comp_name + ", Developer Error: Component sizing incomplete."
                show_severe_error(state, msg)
                self.add_error_message(msg)
                msg = String(f"SizingString = {self.sizing_string}, SizingResult = {self.auto_sized_value:.1f}")
                show_continue_error(state, msg)
                self.add_error_message(msg)
                errorsFound[0] = True
        
        if self.override_size_string:
            if util_same_string(self.comp_type, "ZoneHVAC:FourPipeFanCoil"):
                self.sizing_string = "Maximum Supply Air Flow Rate [m3/s]"
            elif self.coil_type == 0:
                if self.data_dx_speed_num == 1:
                    self.sizing_string = "High Speed Rated Air Flow Rate [m3/s]"
                elif self.data_dx_speed_num == 2:
                    self.sizing_string = "Low Speed Rated Air Flow Rate [m3/s]"
            elif self.is_ep_json:
                self.sizing_string = "Cooling Supply Air Flow Rate [m3/s]"
        
        if self.data_scalable_sizing_on:
            if self.zone_air_flow_siz_method == 0 or self.zone_air_flow_siz_method == 1:
                self.sizing_string_scalable = "(scaled by flow / zone) "
            elif self.zone_air_flow_siz_method == 2:
                self.sizing_string_scalable = "(scaled by flow / area) "
            elif self.zone_air_flow_siz_method == 3 or self.zone_air_flow_siz_method == 4:
                self.sizing_string_scalable = "(scaled by fractional multiplier) "
            elif self.zone_air_flow_siz_method == 5 or self.zone_air_flow_siz_method == 6:
                self.sizing_string_scalable = "(scaled by flow / capacity) "
        
        if self.data_dx_cools_low_speeds_autosized:
            self.auto_sized_value *= self.data_fraction_used_for_sizing
        
        self.select2_stg_dx_hum_ctrl_sizer_output(state, errorsFound)
        
        if self.is_coil_report_object:
            report_coil_selection_set_coil_air_flow(state, self.coil_report_num, self.auto_sized_value, self.was_auto_sized)
        
        if self.is_fan_report_object:
            var dd_name_fan_peak: String = ""
            var date_time_fan_peak: String = ""
            
            if self.data_scalable_sizing_on:
                dd_name_fan_peak = "Scaled size, not from any peak"
                date_time_fan_peak = "Scaled size, not from any peak"
            else:
                if cooling_flow:
                    if (self.final_zone_sizing(self.cur_zone_eq_num).cool_dd_num > 0 and
                        self.final_zone_sizing(self.cur_zone_eq_num).cool_dd_num <= state.data_envrn.tot_des_days):
                        var cool_dd_num: Int32 = self.final_zone_sizing(self.cur_zone_eq_num).cool_dd_num
                        dd_name_fan_peak = state.data_weather.des_day_input(cool_dd_num).title
                        date_time_fan_peak = (
                            String(state.data_weather.des_day_input(cool_dd_num).month) + "/" +
                            String(state.data_weather.des_day_input(cool_dd_num).day_of_month) + " " +
                            report_coil_selection_get_time_text(state, self.final_zone_sizing(self.cur_zone_eq_num).time_step_num_at_cool_max)
                        )
                elif heating_flow:
                    if (self.final_zone_sizing(self.cur_zone_eq_num).heat_dd_num > 0 and
                        self.final_zone_sizing(self.cur_zone_eq_num).heat_dd_num <= state.data_envrn.tot_des_days):
                        var heat_dd_num: Int32 = self.final_zone_sizing(self.cur_zone_eq_num).heat_dd_num
                        dd_name_fan_peak = state.data_weather.des_day_input(heat_dd_num).title
                        date_time_fan_peak = (
                            String(state.data_weather.des_day_input(heat_dd_num).month) + "/" +
                            String(state.data_weather.des_day_input(heat_dd_num).day_of_month) + " " +
                            report_coil_selection_get_time_text(state, self.final_zone_sizing(self.cur_zone_eq_num).time_step_num_at_heat_max)
                        )
            
            output_report_predefined_predef_table_entry(state, state.data_out_rpt_predefined.pdch_fan_des_day, self.comp_name, dd_name_fan_peak)
            output_report_predefined_predef_table_entry(state, state.data_out_rpt_predefined.pdch_fan_pk_time, self.comp_name, date_time_fan_peak)
        
        return self.auto_sized_value
    
    fn clear_state(inout self):
        super().clear_state()
    
    fn zone_eq_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn final_zone_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn oa_sys_eq_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn term_unit_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn unitary_sys_eq_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn final_sys_sizing(self, index: Int32) -> AnyType:
        return AnyType()

fn util_same_string(a: String, b: String) -> Bool:
    return False

fn show_severe_error(state: AnyType, msg: String):
    pass

fn show_continue_error(state: AnyType, msg: String):
    pass

fn report_coil_selection_set_coil_air_flow(state: AnyType, num: Int32, flow: Float64, was_autosized: Bool):
    pass

fn report_coil_selection_get_time_text(state: AnyType, step_num: Int32) -> String:
    return ""

fn output_report_predefined_predef_table_entry(state: AnyType, entry_type: AnyType, name: String, value: String):
    pass

fn outside_air_sys(index: Int32) -> AnyType:
    return AnyType()
