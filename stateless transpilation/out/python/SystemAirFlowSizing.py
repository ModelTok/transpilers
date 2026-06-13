from typing import Protocol

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - BaseSizerWithScalableInputs: parent class from EnergyPlus.Autosizing.BaseSizerWithScalableInputs
# - BaseGlobalStruct: parent class from EnergyPlus.Data.BaseData
# - DataSizing: module with sizing method enums
# - HVAC.AirDuctType: enum (Main, Cooling, Heating, Other)
# - ReportCoilSelection: module with isCompTypeFan and getTimeText
# - ShowSevereError, ShowContinueError: from UtilityRoutines
# - OutputReportPredefined: module with PreDefTableEntry
# - Util: module with SameString

class SystemAirFlowSizer(BaseSizerWithScalableInputs):
    def __init__(self):
        super().__init__()
        self.sizing_type = "SystemAirFlowSizing"
        self.sizing_string = "Maximum Flow Rate [m3/s]"

    def size(self, state, original_value, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        dd_name_fan_peak = ""
        date_time_fan_peak = ""
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing > 0.0 and self.data_fraction_used_for_sizing > 0.0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.cur_zone_eq_num > 0:
                self._size_zone_equipment(state, original_value, dd_name_fan_peak, date_time_fan_peak)
            elif self.cur_sys_num > 0:
                self._size_air_system(state, original_value, dd_name_fan_peak, date_time_fan_peak)
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
        if self.data_scalable_sizing_on:
            if self.zone_air_flow_siz_method in ("SupplyAirFlowRate", "None"):
                self.sizing_string_scalable = "(scaled by flow / zone) "
            elif self.zone_air_flow_siz_method == "FlowPerFloorArea":
                self.sizing_string_scalable = "(scaled by flow / area) "
            elif self.zone_air_flow_siz_method in ("FractionOfAutosizedCoolingAirflow", "FractionOfAutosizedHeatingAirflow"):
                self.sizing_string_scalable = "(scaled by fractional multiplier) "
            elif self.zone_air_flow_siz_method in ("FlowPerCoolingCapacity", "FlowPerHeatingCapacity"):
                self.sizing_string_scalable = "(scaled by flow / capacity) "
        if self.override_size_string:
            if Util.same_string(self.comp_type, "ZoneHVAC:FourPipeFanCoil"):
                self.sizing_string = "Maximum Supply Air Flow Rate [m3/s]"
            elif Util.same_string(self.comp_type, "ZoneHVAC:UnitVentilator"):
                self.sizing_string = "Maximum Supply Air Flow Rate [m3/s]"
            elif Util.same_string(self.comp_type, "Fan:SystemModel"):
                self.sizing_string = "Design Maximum Air Flow Rate [m3/s]"
            else:
                self.sizing_string = "Supply Air Maximum Flow Rate [m3/s]"
        self.select_sizer_output(state, errors_found)
        if self.is_fan_report_object:
            if ReportCoilSelection.is_comp_type_fan(self.comp_type):
                if self.data_scalable_sizing_on:
                    dd_name_fan_peak = "Scaled size, not from any peak"
                    date_time_fan_peak = "Scaled size, not from any peak"
                OutputReportPredefined.pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_des_day, self.comp_name, dd_name_fan_peak)
                OutputReportPredefined.pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_pk_time, self.comp_name, date_time_fan_peak)
        return self.auto_sized_value

    def _size_zone_equipment(self, state, original_value, dd_name_fan_peak, date_time_fan_peak):
        if not self.was_auto_sized and not self.sizing_des_run_this_zone:
            self.auto_sized_value = original_value
        elif self.zone_eq_sizing[self.cur_zone_eq_num - 1].design_size_from_parent:
            self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num - 1].air_vol_flow
        else:
            pass

    def _size_air_system(self, state, original_value, dd_name_fan_peak, date_time_fan_peak):
        if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
            self.auto_sized_value = original_value
        else:
            pass

    def clear_state(self):
        super().clear_state()


class SystemAirFlowSizerData(BaseGlobalStruct):
    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        pass
