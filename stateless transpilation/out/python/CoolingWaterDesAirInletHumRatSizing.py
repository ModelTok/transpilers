# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus.Autosizing.Base
# - AutoSizingType: enum from EnergyPlus
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - ReportCoilSelection: module from EnergyPlus

class CoolingWaterDesAirInletHumRatSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.CoolingWaterDesAirInletHumRatSizing
        self.sizing_string = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"

    def size(self, state, original_value, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        
        self.pre_size(state, original_value)

        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                if self.term_unit_iu:
                    self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).zone_hum_rat_at_cool_peak
                elif self.zone_eq_fan_coil:
                    des_mass_flow = self.final_zone_sizing(self.cur_zone_eq_num).des_cool_mass_flow
                    self.auto_sized_value = self.set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(
                        self.set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing(self.cur_zone_eq_num)),
                        self.zone_eq_sizing(self.cur_zone_eq_num),
                        self.final_zone_sizing(self.cur_zone_eq_num)
                    )
                else:
                    self.auto_sized_value = self.final_zone_sizing(self.cur_zone_eq_num).des_cool_coil_in_hum_rat
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.cur_oa_sys_num > 0:
                    if self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num > -1:
                        self.auto_sized_value = self.airloop_doas[self.outside_air_sys(self.cur_oa_sys_num).air_loop_doas_num].sizing_cool_oa_hum_rat
                    else:
                        self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).out_hum_rat_at_cool_peak
                elif self.data_des_inlet_air_hum_rat > 0.0:
                    self.auto_sized_value = self.data_des_inlet_air_hum_rat
                else:
                    if self.primary_air_system(self.cur_sys_num).num_oa_cool_coils == 0:
                        self.auto_sized_value = self.final_sys_sizing(self.cur_sys_num).mix_hum_rat_at_cool_peak
                    else:
                        out_air_frac = 1.0
                        if self.data_flow_used_for_sizing > 0.0:
                            out_air_frac = self.final_sys_sizing(self.cur_sys_num).des_out_air_vol_flow / self.data_flow_used_for_sizing
                            out_air_frac = min(1.0, max(0.0, out_air_frac))
                        self.auto_sized_value = (out_air_frac * self.final_sys_sizing(self.cur_sys_num).precool_hum_rat +
                                               (1.0 - out_air_frac) * self.final_sys_sizing(self.cur_sys_num).ret_hum_rat_at_cool_peak)

        if self.override_size_string:
            self.sizing_string = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
        
        self.select_sizer_output(state, errors_found)
        
        if self.is_coil_report_object:
            ReportCoilSelection.set_coil_ent_air_hum_rat(state, self.coil_report_num, self.auto_sized_value)
        
        return self.auto_sized_value
