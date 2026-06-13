# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base struct from EnergyPlus.Autosizing.Base
# - AutoSizingType: enum from EnergyPlus.Autosizing.Base
# - EnergyPlusData: struct from EnergyPlus.Data.EnergyPlusData with dataEnvrn
# - ReportCoilSelection: module with setCoilEntAirTemp function

struct AutoSizingType:
    var HeatingWaterDesAirInletTempSizing: StringRef

fn get_autosizing_type_heating_water_des_air_inlet_temp_sizing() -> StringRef:
    return "HeatingWaterDesAirInletTempSizing"

struct HeatingWaterDesAirInletTempSizer:
    var sizing_type: StringRef
    var sizing_string: StringRef

    fn __init__(inout self):
        self.sizing_type = "HeatingWaterDesAirInletTempSizing"
        self.sizing_string = "Rated Inlet Air Temperature"

    fn size(inout self, state: EnergyPlusData, original_value: Float64, inout errors_found: List[Bool]) -> Float64:
        if not self.checkInitialized(state, errors_found):
            return 0.0
        self.preSize(state, original_value)

        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                if self.term_unit_piu and (self.cur_term_unit_sizing_num > 0):
                    var min_flow_frac = self.term_unit_sizing[self.cur_term_unit_sizing_num - 1].min_pri_flow_frac
                    if self.term_unit_sizing[self.cur_term_unit_sizing_num - 1].induces_plenum_air:
                        self.auto_sized_value = (self.term_unit_final_zone_sizing[self.cur_term_unit_sizing_num - 1].des_heat_coil_in_temp_tu * min_flow_frac) + \
                                               (self.term_unit_final_zone_sizing[self.cur_term_unit_sizing_num - 1].zone_ret_temp_at_heat_peak * (1.0 - min_flow_frac))
                    else:
                        self.auto_sized_value = self.term_unit_final_zone_sizing[self.cur_term_unit_sizing_num - 1].des_heat_coil_in_temp_tu * min_flow_frac + \
                                               self.final_zone_sizing[self.cur_zone_eq_num - 1].zone_temp_at_heat_peak * (1.0 - min_flow_frac)
                elif self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                    self.auto_sized_value = self.term_unit_final_zone_sizing[self.cur_term_unit_sizing_num - 1].zone_temp_at_heat_peak
                elif self.term_unit_sing_duct and (self.cur_term_unit_sizing_num > 0):
                    self.auto_sized_value = self.term_unit_final_zone_sizing[self.cur_term_unit_sizing_num - 1].des_heat_coil_in_temp_tu
                else:
                    var des_mass_flow: Float64
                    if self.zone_eq_sizing[self.cur_zone_eq_num - 1].system_air_flow:
                        des_mass_flow = self.zone_eq_sizing[self.cur_zone_eq_num - 1].air_vol_flow * state.data_envrn.std_rho_air
                    elif self.zone_eq_sizing[self.cur_zone_eq_num - 1].heating_air_flow:
                        des_mass_flow = self.zone_eq_sizing[self.cur_zone_eq_num - 1].heating_air_vol_flow * state.data_envrn.std_rho_air
                    else:
                        des_mass_flow = self.final_zone_sizing[self.cur_zone_eq_num - 1].des_heat_mass_flow
                    self.auto_sized_value = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, des_mass_flow, self.zone_eq_sizing[self.cur_zone_eq_num - 1]),
                        self.zone_eq_sizing[self.cur_zone_eq_num - 1],
                        self.final_zone_sizing[self.cur_zone_eq_num - 1])
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                var out_air_frac: Float64 = 1.0
                if self.cur_oa_sys_num > 0:
                    out_air_frac = 1.0
                elif self.final_sys_sizing[self.cur_sys_num - 1].heat_oa_option == self.min_oa:
                    if self.data_flow_used_for_sizing > 0.0:
                        out_air_frac = self.final_sys_sizing[self.cur_sys_num - 1].des_out_air_vol_flow / self.data_flow_used_for_sizing
                    else:
                        out_air_frac = 1.0
                    out_air_frac = min(1.0, max(0.0, out_air_frac))

                if self.cur_oa_sys_num == 0 and self.primary_air_system[self.cur_sys_num - 1].num_oa_heat_coils > 0:
                    self.auto_sized_value = out_air_frac * self.final_sys_sizing[self.cur_sys_num - 1].preheat_temp + \
                                           (1.0 - out_air_frac) * self.final_sys_sizing[self.cur_sys_num - 1].heat_ret_temp
                elif self.cur_oa_sys_num > 0 and self.outside_air_sys[self.cur_oa_sys_num - 1].air_loop_doas_num > -1:
                    self.auto_sized_value = self.airloop_doas[self.outside_air_sys[self.cur_oa_sys_num - 1].air_loop_doas_num].heat_out_temp
                else:
                    self.auto_sized_value = out_air_frac * self.final_sys_sizing[self.cur_sys_num - 1].heat_out_temp + \
                                           (1.0 - out_air_frac) * self.final_sys_sizing[self.cur_sys_num - 1].heat_ret_temp

        if self.override_size_string:
            self.sizing_string = "Rated Inlet Air Temperature [C]"
        self.selectSizerOutput(state, errors_found)

        if self.cur_sys_num <= self.num_primary_air_sys:
            if self.is_coil_report_object:
                ReportCoilSelection.setCoilEntAirTemp(state, self.coil_report_num, self.auto_sized_value, self.cur_sys_num, self.cur_zone_eq_num)

        return self.auto_sized_value
