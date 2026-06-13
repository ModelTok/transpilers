from typing import Protocol
from dataclasses import dataclass
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (has dataEnvrn, dataGlobal, dataHVACGlobal, etc.)
# - BaseSizerWithScalableInputs: parent class providing checkInitialized, preSize, selectSizerOutput, clearState, etc.
# - Psychrometrics.PsyCpAirFnW(w): returns specific heat of air at humidity ratio w
# - ShowWarningMessage, ShowContinueError, ShowSevereError: reporting functions
# - Util.SameString(a, b): case-insensitive string comparison
# - ReportCoilSelection: module with setCoilEntAirTemp, setCoilEntAirHumRat, setCoilLvgAirTemp, setCoilLvgAirHumRat, setCoilAirFlow, setCoilHeatingCapacity
# - HVAC constants: SmallMassFlow, SmallLoad, MinRatedVolFlowPerRatedTotCap, MaxRatedVolFlowPerRatedTotCap, AirDuctType enums
# - DataSizing enums: FractionOfAutosizedHeatingCapacity, CapacityPerFloorArea, HeatingDesignCapacity, OAControl


class HeatingCapacitySizer(BaseSizerWithScalableInputs):
    def __init__(self):
        super().__init__()
        self.sizing_type = "HeatingCapacitySizing"
        self.sizing_string = "Heating Capacity [W]"

    def size(self, state, original_value: float, errors_found: list) -> float:
        if not self.check_initialized(state, errors_found):
            return 0.0
        
        self.pre_size(state, original_value)
        
        des_vol_flow = 0.0
        coil_in_temp = -999.0
        coil_in_hum_rat = -999.0
        coil_out_temp = -999.0
        coil_out_hum_rat = -999.0
        
        dx_flow_per_cap_min_ratio = 1.0
        dx_flow_per_cap_max_ratio = 1.0
        nominal_capacity_des = 0.0
        des_mass_flow = 0.0
        des_coil_load = 0.0
        out_air_frac = 0.0
        cp_air_std = PsyCpAirFnW(0.0)
        
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing >= 0 and self.data_fraction_used_for_sizing > 0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.cur_zone_eq_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                    self.auto_sized_value = original_value
                elif self.zone_eq_sizing(self.cur_zone_eq_num).design_size_from_parent:
                    self.auto_sized_value = self.zone_eq_sizing(self.cur_zone_eq_num).des_heating_load
                else:
                    if self.data_coil_is_supp_heater and self.supp_heat_cap > 0.0:
                        nominal_capacity_des = self.supp_heat_cap
                        if self.data_flow_used_for_sizing > 0.0:
                            des_vol_flow = self.data_flow_used_for_sizing
                    elif self.zone_eq_sizing(self.cur_zone_eq_num).heating_capacity:
                        nominal_capacity_des = self.zone_eq_sizing(self.cur_zone_eq_num).des_heating_load
                        if self.data_flow_used_for_sizing > 0.0:
                            des_vol_flow = self.data_flow_used_for_sizing
                    elif self.data_cool_coil_cap > 0.0 and self.data_flow_used_for_sizing > 0.0:
                        nominal_capacity_des = self.data_cool_coil_cap
                        des_vol_flow = self.data_flow_used_for_sizing
                    elif len(self.final_zone_sizing) > 0 and self.final_zone_sizing(self.cur_zone_eq_num).des_heat_mass_flow >= SmallMassFlow:
                        if self.data_flow_used_for_sizing > 0.0:
                            des_vol_flow = self.data_flow_used_for_sizing
                        
                        if self.term_unit_piu and (self.cur_term_unit_sizing_num > 0):
                            min_pri_flow_frac = self.term_unit_sizing(self.cur_term_unit_sizing_num).min_pri_flow_frac
                            if self.term_unit_sizing(self.cur_term_unit_sizing_num).induces_plenum_air:
                                coil_in_temp = (self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_coil_in_temp_tu * min_pri_flow_frac) + \
                                               (self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).zone_ret_temp_at_heat_peak * (1.0 - min_pri_flow_frac))
                            else:
                                coil_in_temp = (self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_coil_in_temp_tu * min_pri_flow_frac) + \
                                               (self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).zone_temp_at_heat_peak * (1.0 - min_pri_flow_frac))
                        elif self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                            coil_in_temp = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).zone_temp_at_heat_peak
                            coil_in_hum_rat = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).zone_hum_rat_at_heat_peak
                        elif self.term_unit_sing_duct and (self.cur_term_unit_sizing_num > 0):
                            coil_in_temp = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_coil_in_temp_tu
                            coil_in_hum_rat = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_coil_in_hum_rat_tu
                        else:
                            if des_vol_flow > 0.0:
                                des_mass_flow = des_vol_flow * state.data_envrn.std_rho_air
                            else:
                                des_mass_flow = self.final_zone_sizing(self.cur_zone_eq_num).des_heat_mass_flow
                            coil_in_temp = self.set_heat_coil_inlet_temp_for_zone_eq_sizing(
                                self.set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing(self.cur_zone_eq_num)),
                                self.zone_eq_sizing(self.cur_zone_eq_num),
                                self.final_zone_sizing(self.cur_zone_eq_num))
                            coil_in_hum_rat = self.set_heat_coil_inlet_hum_rat_for_zone_eq_sizing(
                                self.set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing(self.cur_zone_eq_num)),
                                self.zone_eq_sizing(self.cur_zone_eq_num),
                                self.final_zone_sizing(self.cur_zone_eq_num))
                        
                        if (self.term_unit_sing_duct or self.term_unit_piu) and (self.cur_term_unit_sizing_num > 0):
                            coil_out_temp = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).heat_des_temp
                            coil_out_hum_rat = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).heat_des_hum_rat
                            cp_air = PsyCpAirFnW(coil_out_hum_rat)
                            des_coil_load = cp_air * state.data_envrn.std_rho_air * self.term_unit_sizing(self.cur_term_unit_sizing_num).air_vol_flow * \
                                            (coil_out_temp - coil_in_temp)
                            des_vol_flow = self.term_unit_sizing(self.cur_term_unit_sizing_num).air_vol_flow
                        elif self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                            if self.term_unit_sizing(self.cur_term_unit_sizing_num).induc_rat > 0.01:
                                des_vol_flow = self.term_unit_sizing(self.cur_term_unit_sizing_num).air_vol_flow / \
                                               self.term_unit_sizing(self.cur_term_unit_sizing_num).induc_rat
                                cp_air = PsyCpAirFnW(self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).heat_des_hum_rat)
                                des_coil_load = self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_load - \
                                                (cp_air * state.data_envrn.std_rho_air * des_vol_flow *
                                                 (self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).des_heat_coil_in_temp_tu -
                                                  self.term_unit_final_zone_sizing(self.cur_term_unit_sizing_num).zone_temp_at_heat_peak))
                            else:
                                des_coil_load = 0.0
                        else:
                            coil_out_temp = self.final_zone_sizing(self.cur_zone_eq_num).heat_des_temp
                            coil_out_hum_rat = self.final_zone_sizing(self.cur_zone_eq_num).heat_des_hum_rat
                            cp_air = PsyCpAirFnW(coil_out_hum_rat)
                            des_coil_load = cp_air * self.final_zone_sizing(self.cur_zone_eq_num).des_heat_mass_flow * (coil_out_temp - coil_in_temp)
                            des_vol_flow = self.final_zone_sizing(self.cur_zone_eq_num).des_heat_mass_flow / state.data_envrn.std_rho_air
                        
                        nominal_capacity_des = max(0.0, des_coil_load)
                    else:
                        nominal_capacity_des = 0.0
                        coil_out_temp = -999.0
                    
                    if self.data_cool_coil_cap > 0.0:
                        self.auto_sized_value = nominal_capacity_des * self.data_heat_size_ratio
                    else:
                        self.auto_sized_value = nominal_capacity_des * self.data_heat_size_ratio * self.data_frac_of_autosized_heating_capacity
                    
                    if state.data_global.display_extra_warnings and self.auto_sized_value <= 0.0:
                        ShowWarningMessage(state,
                                           self.calling_routine + ": Potential issue with equipment sizing for " + self.comp_type + ' ' + self.comp_name)
                        ShowContinueError(state, f"...Rated Total Heating Capacity = {self.auto_sized_value:.2f} [W]")
                        if self.zone_eq_sizing(self.cur_zone_eq_num).heating_capacity or \
                           (self.data_cool_coil_cap > 0.0 and self.data_flow_used_for_sizing > 0.0):
                            ShowContinueError(state, f"...Capacity passed by parent object to size child component = {nominal_capacity_des:.2f} [W]")
                        else:
                            if coil_out_temp > -999.0:
                                ShowContinueError(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                                ShowContinueError(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                                ShowContinueError(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                            else:
                                ShowContinueError(state, "...Capacity used to size child component set to 0 [W]")
            
            elif self.cur_sys_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                    self.auto_sized_value = original_value
                else:
                    if self.cur_oa_sys_num > 0:
                        if self.oa_sys_eq_sizing(self.cur_oa_sys_num).air_flow:
                            des_vol_flow = self.oa_sys_eq_sizing(self.cur_oa_sys_num).air_vol_flow
                        elif self.oa_sys_eq_sizing(self.cur_oa_sys_num).heating_air_flow:
                            des_vol_flow = self.oa_sys_eq_sizing(self.cur_oa_sys_num).heating_air_vol_flow
                        elif self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num > -1:
                            des_vol_flow = self.airloop_doas[self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].sizing_mass_flow / state.data_envrn.std_rho_air
                        else:
                            des_vol_flow = self.final_sys_sizing(self.cur_sys_num).des_out_air_vol_flow
                    else:
                        if self.final_sys_sizing(self.cur_sys_num).heating_cap_method == "FractionOfAutosizedHeatingCapacity":
                            self.data_frac_of_autosized_heating_capacity = self.final_sys_sizing(self.cur_sys_num).fraction_of_autosized_heating_capacity
                        
                        if self.data_flow_used_for_sizing > 0.0:
                            des_vol_flow = self.data_flow_used_for_sizing
                        elif self.unitary_sys_eq_sizing(self.cur_sys_num).air_flow:
                            des_vol_flow = self.unitary_sys_eq_sizing(self.cur_sys_num).air_vol_flow
                        elif self.unitary_sys_eq_sizing(self.cur_sys_num).heating_air_flow:
                            des_vol_flow = self.unitary_sys_eq_sizing(self.cur_sys_num).heating_air_vol_flow
                        else:
                            if self.cur_duct_type == "Main":
                                if self.final_sys_sizing(self.cur_sys_num).sys_air_min_flow_rat > 0.0 and not self.data_desic_reg_coil:
                                    des_vol_flow = self.final_sys_sizing(self.cur_sys_num).sys_air_min_flow_rat * self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
                                else:
                                    des_vol_flow = self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
                            elif self.cur_duct_type == "Cooling":
                                if self.final_sys_sizing(self.cur_sys_num).sys_air_min_flow_rat > 0.0 and not self.data_desic_reg_coil:
                                    des_vol_flow = self.final_sys_sizing(self.cur_sys_num).sys_air_min_flow_rat * self.final_sys_sizing(self.cur_sys_num).des_cool_vol_flow
                                else:
                                    des_vol_flow = self.final_sys_sizing(self.cur_sys_num).des_cool_vol_flow
                            elif self.cur_duct_type == "Heating":
                                des_vol_flow = self.final_sys_sizing(self.cur_sys_num).des_heat_vol_flow
                            else:
                                des_vol_flow = self.final_sys_sizing(self.cur_sys_num).des_main_vol_flow
                    
                    des_mass_flow = state.data_envrn.std_rho_air * des_vol_flow
                    
                    if self.cur_oa_sys_num > 0:
                        out_air_frac = 1.0
                    elif self.final_sys_sizing(self.cur_sys_num).heat_oa_option == "MinOA":
                        if des_vol_flow > 0.0:
                            out_air_frac = self.final_sys_sizing(self.cur_sys_num).des_out_air_vol_flow / des_vol_flow
                        else:
                            out_air_frac = 1.0
                        out_air_frac = min(1.0, max(0.0, out_air_frac))
                    else:
                        out_air_frac = 1.0
                    
                    if self.cur_oa_sys_num == 0 and self.primary_air_system(self.cur_sys_num).num_oa_heat_coils > 0:
                        coil_in_temp = out_air_frac * self.final_sys_sizing(self.cur_sys_num).preheat_temp + \
                                       (1.0 - out_air_frac) * self.final_sys_sizing(self.cur_sys_num).heat_ret_temp
                        coil_in_hum_rat = out_air_frac * self.final_sys_sizing(self.cur_sys_num).preheat_hum_rat + \
                                          (1.0 - out_air_frac) * self.final_sys_sizing(self.cur_sys_num).heat_ret_hum_rat
                    elif self.cur_oa_sys_num > 0 and self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num > -1:
                        coil_in_temp = self.airloop_doas[self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].heat_out_temp
                    else:
                        coil_in_temp = out_air_frac * self.final_sys_sizing(self.cur_sys_num).heat_out_temp + \
                                       (1.0 - out_air_frac) * self.final_sys_sizing(self.cur_sys_num).heat_ret_temp
                        coil_in_hum_rat = out_air_frac * self.final_sys_sizing(self.cur_sys_num).heat_out_hum_rat + \
                                          (1.0 - out_air_frac) * self.final_sys_sizing(self.cur_sys_num).heat_ret_hum_rat
                    
                    if self.cur_oa_sys_num > 0:
                        if self.oa_sys_eq_sizing(self.cur_oa_sys_num).heating_capacity:
                            des_coil_load = self.oa_sys_eq_sizing(self.cur_oa_sys_num).des_heating_load
                        elif self.data_desic_reg_coil:
                            des_coil_load = cp_air_std * des_mass_flow * (self.data_des_outlet_air_temp - self.data_des_inlet_air_temp)
                            coil_out_temp = self.data_des_outlet_air_temp
                        elif self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num > -1:
                            des_coil_load = cp_air_std * des_mass_flow * \
                                            (self.airloop_doas[self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].preheat_temp - coil_in_temp)
                            coil_out_temp = self.airloop_doas[self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].preheat_temp
                        else:
                            des_coil_load = cp_air_std * des_mass_flow * (self.final_sys_sizing(self.cur_sys_num).preheat_temp - coil_in_temp)
                            coil_out_temp = self.final_sys_sizing(self.cur_sys_num).preheat_temp
                            coil_out_hum_rat = self.final_sys_sizing(self.cur_sys_num).preheat_hum_rat
                    else:
                        if self.unitary_sys_eq_sizing(self.cur_sys_num).heating_capacity:
                            des_coil_load = self.unitary_sys_eq_sizing(self.cur_sys_num).des_heating_load
                            coil_out_temp = self.final_sys_sizing(self.cur_sys_num).heat_sup_temp
                            coil_out_hum_rat = self.final_sys_sizing(self.cur_sys_num).heat_sup_hum_rat
                        elif self.data_desic_reg_coil:
                            des_coil_load = cp_air_std * des_mass_flow * (self.data_des_outlet_air_temp - self.data_des_inlet_air_temp)
                            coil_out_temp = self.data_des_outlet_air_temp
                        else:
                            des_coil_load = cp_air_std * des_mass_flow * (self.final_sys_sizing(self.cur_sys_num).heat_sup_temp - coil_in_temp)
                            coil_out_temp = self.final_sys_sizing(self.cur_sys_num).heat_sup_temp
                            coil_out_hum_rat = self.final_sys_sizing(self.cur_sys_num).heat_sup_hum_rat
                    
                    if self.cur_sys_num <= state.data_hvac_global.num_primary_air_sys and self.air_loop_control_info(self.cur_sys_num).unitary_sys:
                        if self.data_coil_is_supp_heater:
                            nominal_capacity_des = self.supp_heat_cap
                        elif self.data_cool_coil_cap > 0.0:
                            nominal_capacity_des = self.data_cool_coil_cap
                        else:
                            if self.air_loop_control_info(self.cur_sys_num).unitary_sys_simulating and \
                               not SameString(self.comp_type, "COIL:HEATING:WATER"):
                                nominal_capacity_des = self.unitary_heat_cap
                            else:
                                if des_coil_load >= SmallLoad:
                                    nominal_capacity_des = des_coil_load
                                else:
                                    nominal_capacity_des = 0.0
                        des_coil_load = nominal_capacity_des
                    elif self.cur_sys_num <= state.data_hvac_global.num_primary_air_sys and \
                         self.final_sys_sizing(self.cur_sys_num).heating_cap_method == "CapacityPerFloorArea":
                        nominal_capacity_des = self.final_sys_sizing(self.cur_sys_num).heating_total_capacity
                    elif self.cur_sys_num <= state.data_hvac_global.num_primary_air_sys and \
                         self.final_sys_sizing(self.cur_sys_num).heating_cap_method == "HeatingDesignCapacity" and \
                         self.final_sys_sizing(self.cur_sys_num).heating_total_capacity > 0.0:
                        nominal_capacity_des = self.final_sys_sizing(self.cur_sys_num).heating_total_capacity
                    else:
                        if self.data_cool_coil_cap > 0.0:
                            nominal_capacity_des = self.data_cool_coil_cap
                        elif des_coil_load >= SmallLoad:
                            nominal_capacity_des = des_coil_load
                        else:
                            nominal_capacity_des = 0.0
                    
                    self.auto_sized_value = nominal_capacity_des * self.data_heat_size_ratio
                    
                    if self.cur_oa_sys_num > 0:
                        if not self.oa_sys_eq_sizing(self.cur_oa_sys_num).heating_capacity:
                            self.auto_sized_value = self.auto_sized_value * self.data_frac_of_autosized_heating_capacity
                    else:
                        if not self.unitary_sys_eq_sizing(self.cur_sys_num).heating_capacity:
                            self.auto_sized_value = self.auto_sized_value * self.data_frac_of_autosized_heating_capacity
                    
                    if state.data_global.display_extra_warnings and self.auto_sized_value <= 0.0:
                        ShowWarningMessage(state,
                                           self.calling_routine + ": Potential issue with equipment sizing for " + self.comp_type + ' ' + self.comp_name)
                        ShowContinueError(state, f"...Rated Total Heating Capacity = {self.auto_sized_value:.2f} [W]")
                        if coil_out_temp > -999.0:
                            ShowContinueError(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                            ShowContinueError(state, f"...Outdoor air fraction used for sizing = {out_air_frac:.2f}")
                            ShowContinueError(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                            ShowContinueError(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                        else:
                            ShowContinueError(state, f"...Capacity passed by parent object to size child component = {des_coil_load:.2f} [W]")
            
            elif self.data_non_zone_non_airloop_value > 0:
                self.auto_sized_value = self.data_non_zone_non_airloop_value
            elif not self.was_auto_sized:
                self.auto_sized_value = self.original_value
            else:
                msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                ShowSevereError(state, msg)
                self.add_error_message(msg)
                msg = f"SizingString = {self.sizing_string}, SizingResult = {self.auto_sized_value:.1f}"
                ShowContinueError(state, msg)
                self.add_error_message(msg)
                errors_found[0] = True
        
        if not self.hard_size_no_design_run or self.data_scalable_sizing_on or self.data_scalable_cap_sizing_on:
            if self.was_auto_sized and self.data_fraction_used_for_sizing == 0.0:
                flag_check_vol_flow_per_rated_tot_cap = True
                if SameString(self.comp_type, "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl") or \
                   SameString(self.comp_type, "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl"):
                    flag_check_vol_flow_per_rated_tot_cap = False
                
                if self.data_is_dx_coil and flag_check_vol_flow_per_rated_tot_cap and self.auto_sized_value > 0.0:
                    rated_vol_flow_per_rated_tot_cap = des_vol_flow / self.auto_sized_value
                    min_ratio = MinRatedVolFlowPerRatedTotCap[int(state.data_hvac_global.dxct)]
                    max_ratio = MaxRatedVolFlowPerRatedTotCap[int(state.data_hvac_global.dxct)]
                    
                    if rated_vol_flow_per_rated_tot_cap < min_ratio:
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            ShowWarningError(state, self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name)
                            ShowContinueError(state, "..." + self.sizing_string + " will be limited by the minimum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            ShowContinueError(state, f"...Requested capacity [W] = {self.auto_sized_value:.3f}")
                            ShowContinueError(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            ShowContinueError(state, f"...Minimum flow/capacity ratio [m3/s/W] = {min_ratio:.6e}")
                        
                        dx_flow_per_cap_min_ratio = (des_vol_flow / min_ratio) / self.auto_sized_value
                        self.auto_sized_value = des_vol_flow / min_ratio
                        
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            ShowContinueError(state, f"...Adjusted capacity [W] = {self.auto_sized_value:.3f}")
                    
                    elif rated_vol_flow_per_rated_tot_cap > max_ratio:
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            ShowWarningError(state, self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name)
                            ShowContinueError(state, "..." + self.sizing_string + " will be limited by the maximum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            ShowContinueError(state, f"...Requested capacity [W] = {self.auto_sized_value:.3f}")
                            ShowContinueError(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            ShowContinueError(state, f"...Maximum flow/capacity ratio [m3/s/W] = {max_ratio:.6e}")
                        
                        dx_flow_per_cap_max_ratio = des_vol_flow / max_ratio / self.auto_sized_value
                        self.auto_sized_value = des_vol_flow / max_ratio
                        
                        if not self.data_ems_override_on and state.data_global.display_extra_warnings and self.print_warning_flag:
                            ShowContinueError(state, f"...Adjusted capacity [W] = {self.auto_sized_value:.3f}")
        
        if self.override_size_string:
            self.sizing_string = "Heating Capacity [W]"
        
        if self.data_scalable_cap_sizing_on:
            sizing_method = self.zone_eq_sizing(self.cur_zone_eq_num).sizing_method(HVAC_HeatingCapacitySizing)
            if sizing_method == "CapacityPerFloorArea":
                self.sizing_string_scalable = "(scaled by capacity / area) "
            elif sizing_method == "FractionOfAutosizedHeatingCapacity" or sizing_method == "FractionOfAutosizedCoolingCapacity":
                self.sizing_string_scalable = "(scaled by fractional multiplier) "
        
        self.select_sizer_output(state, errors_found)
        
        if self.is_coil_report_object:
            if coil_in_temp > -999.0:
                ReportCoilSelection_setCoilEntAirTemp(state, self.coil_report_num, coil_in_temp, self.cur_sys_num, self.cur_zone_eq_num)
                ReportCoilSelection_setCoilEntAirHumRat(state, self.coil_report_num, coil_in_hum_rat)
            if coil_out_temp > -999.0:
                ReportCoilSelection_setCoilLvgAirTemp(state, self.coil_report_num, coil_out_temp)
                ReportCoilSelection_setCoilLvgAirHumRat(state, self.coil_report_num, coil_out_hum_rat)
            ReportCoilSelection_setCoilAirFlow(state, self.coil_report_num, des_vol_flow, self.was_auto_sized)
            fan_cool_load = 0.0
            tot_cap_temp_mod_fac = 1.0
            ReportCoilSelection_setCoilHeatingCapacity(state,
                                                       self.coil_report_num,
                                                       self.auto_sized_value,
                                                       self.was_auto_sized,
                                                       self.cur_sys_num,
                                                       self.cur_zone_eq_num,
                                                       self.cur_oa_sys_num,
                                                       fan_cool_load,
                                                       tot_cap_temp_mod_fac,
                                                       dx_flow_per_cap_min_ratio,
                                                       dx_flow_per_cap_max_ratio)
        
        return self.auto_sized_value

    def clear_state(self):
        super().clear_state()
