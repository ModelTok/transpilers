# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.
#
# NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
# U.S. Government consequently retains certain rights. As such, the U.S. Government has been
# granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
# worldwide license in the Software to reproduce, distribute copies to the public, prepare
# derivative works, and perform publicly and display publicly, and to permit others to do so.

# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus/Autosizing/Base.hh
# - EnergyPlusData: state object from EnergyPlus/Data/EnergyPlusData.hh
# - AutoSizingType: enum from EnergyPlus/Autosizing/Base.hh
# - AutoSizingResultType: enum from EnergyPlus/Autosizing/Base.hh
# - Psychrometrics.PsyCpAirFnW: function from EnergyPlus/Psychrometrics.hh
# - ShowSevereError, ShowContinueError: error reporting functions
# - ReportCoilSelection: module with setCoilEntAirTemp, setCoilLvgAirTemp, setCoilEntAirHumRat

import Psychrometrics
import ReportCoilSelection


class AutoCalculateSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.AutoCalculateSizing
        self.sizing_string = "AutoCalculate: Set string in Component Model using overrideSizingString"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        else:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class MaxHeaterOutletTempSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.MaxHeaterOutletTempSizing
        self.sizing_string = "Maximum Supply Air Temperature [C]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].heat_des_temp
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].heat_sup_temp
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class ZoneCoolingLoadSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.ZoneCoolingLoadSizing
        self.sizing_string = "Zone Cooling Sensible Load [W]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_load
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                self.error_type = AutoSizingResultType.ErrorType1
                self.auto_sized_value = 0.0
                msg = "Developer Error: For autosizing of " + self.comp_type + ' ' + self.comp_name + ", Airloop equipment not implemented."
                self.add_error_message(msg)
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class ZoneHeatingLoadSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.ZoneHeatingLoadSizing
        self.sizing_string = "Zone Heating Sensible Load [W]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_heat_load
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                self.error_type = AutoSizingResultType.ErrorType1
                self.auto_sized_value = 0.0
                msg = "Developer Error: For autosizing of " + self.comp_type + ' ' + self.comp_name + ", Airloop equipment not implemented."
                self.add_error_message(msg)
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class ASHRAEMinSATCoolingSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.ASHRAEMinSATCoolingSizing
        self.sizing_string = "Minimum Supply Air Temperature in Cooling Mode [C]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                if self.data_capacity_used_for_sizing > 0.0 and self.data_flow_used_for_sizing > 0.0:
                    self.auto_sized_value = (
                        self.final_zone_sizing[self.cur_zone_eq_num].zone_temp_at_cool_peak -
                        (self.data_capacity_used_for_sizing / (self.data_flow_used_for_sizing * state.data_envrn.std_rho_air *
                                                                Psychrometrics.PsyCpAirFnW(self.final_zone_sizing[self.cur_zone_eq_num].zone_hum_rat_at_cool_peak)))
                    )
                else:
                    self.error_type = AutoSizingResultType.ErrorType1
                    msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                    self.add_error_message(msg)
                    ShowSevereError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataCapacityUsedForSizing = {self.data_capacity_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataFlowUsedForSizing = {self.data_flow_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.data_capacity_used_for_sizing > 0.0 and self.data_flow_used_for_sizing > 0.0 and self.data_zone_used_for_sizing > 0:
                    self.auto_sized_value = (
                        self.final_zone_sizing[self.data_zone_used_for_sizing].zone_temp_at_cool_peak -
                        (self.data_capacity_used_for_sizing /
                         (self.data_flow_used_for_sizing * state.data_envrn.std_rho_air *
                          Psychrometrics.PsyCpAirFnW(self.final_zone_sizing[self.data_zone_used_for_sizing].zone_hum_rat_at_cool_peak)))
                    )
                else:
                    self.error_type = AutoSizingResultType.ErrorType1
                    msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                    self.add_error_message(msg)
                    ShowSevereError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataCapacityUsedForSizing = {self.data_capacity_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataFlowUsedForSizing = {self.data_flow_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataZoneUsedForSizing = {float(self.data_zone_used_for_sizing):.0f}"
                    ShowContinueError(state, msg)
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class ASHRAEMaxSATHeatingSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.ASHRAEMaxSATHeatingSizing
        self.sizing_string = "Maximum Supply Air Temperature in Heating Mode [C]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                if self.data_capacity_used_for_sizing > 0.0 and self.data_flow_used_for_sizing > 0.0:
                    self.auto_sized_value = (
                        self.final_zone_sizing[self.cur_zone_eq_num].zone_temp_at_heat_peak +
                        (self.data_capacity_used_for_sizing / (self.data_flow_used_for_sizing * state.data_envrn.std_rho_air *
                                                                Psychrometrics.PsyCpAirFnW(self.final_zone_sizing[self.cur_zone_eq_num].zone_hum_rat_at_heat_peak)))
                    )
                else:
                    self.error_type = AutoSizingResultType.ErrorType1
                    msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                    self.add_error_message(msg)
                    ShowSevereError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataCapacityUsedForSizing = {self.data_capacity_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataFlowUsedForSizing = {self.data_flow_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.data_capacity_used_for_sizing > 0.0 and self.data_flow_used_for_sizing > 0.0 and self.data_zone_used_for_sizing > 0:
                    self.auto_sized_value = (
                        self.final_zone_sizing[self.data_zone_used_for_sizing].zone_temp_at_heat_peak +
                        (self.data_capacity_used_for_sizing /
                         (self.data_flow_used_for_sizing * state.data_envrn.std_rho_air *
                          Psychrometrics.PsyCpAirFnW(self.final_zone_sizing[self.data_zone_used_for_sizing].zone_hum_rat_at_heat_peak)))
                    )
                else:
                    self.error_type = AutoSizingResultType.ErrorType1
                    msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                    self.add_error_message(msg)
                    ShowSevereError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataCapacityUsedForSizing = {self.data_capacity_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataFlowUsedForSizing = {self.data_flow_used_for_sizing:.1f}"
                    self.add_error_message(msg)
                    ShowContinueError(state, msg)
                    msg = f"SizingString = {self.sizing_string}, DataZoneUsedForSizing = {float(self.data_zone_used_for_sizing):.0f}"
                    ShowContinueError(state, msg)
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class DesiccantDehumidifierBFPerfDataFaceVelocitySizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.DesiccantDehumidifierBFPerfDataFaceVelocitySizing
        self.sizing_string = "Nominal Air Face Velocity [m/s]"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        else:
            self.auto_sized_value = 4.30551 + 0.01969 * self.data_air_flow_used_for_sizing
            self.auto_sized_value = min(6.0, self.auto_sized_value)
        if self.is_epjson:
            self.sizing_string = "Nominal Air Face Velocity [m/s]"
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value


class HeatingCoilDesAirInletTempSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.HeatingCoilDesAirInletTempSizing
        self.sizing_string = "Rated Inlet Air Temperature"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.error_type = AutoSizingResultType.ErrorType1
                self.auto_sized_value = 0.0
                msg = "Developer Error: For autosizing of " + self.comp_type + ' ' + self.comp_name + ", Zone equipment not implemented."
                self.add_error_message(msg)
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.data_desic_reg_coil and self.data_desic_dehum_num > 0:
                    if state.data_desiccant_dehumidifiers.desic_dehum[self.data_desic_dehum_num].regen_inlet_is_outside_air_node:
                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].heat_out_temp
                    else:
                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].heat_ret_temp
        self.select_sizer_output(state, errors_found)
        if self.is_coil_report_object:
            ReportCoilSelection.setCoilEntAirTemp(state, self.coil_report_num, self.auto_sized_value, self.cur_sys_num, self.cur_zone_eq_num)
        return self.auto_sized_value


class HeatingCoilDesAirOutletTempSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.HeatingCoilDesAirOutletTempSizing
        self.sizing_string = "Rated Outlet Air Temperature"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.error_type = AutoSizingResultType.ErrorType1
                self.auto_sized_value = 0.0
                msg = "Developer Error: For autosizing of " + self.comp_type + ' ' + self.comp_name + ", Zone equipment not implemented."
                self.add_error_message(msg)
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.data_desic_reg_coil and self.data_desic_dehum_num > 0:
                    self.auto_sized_value = state.data_desiccant_dehumidifiers.desic_dehum[self.data_desic_dehum_num].regen_set_point_temp
        self.select_sizer_output(state, errors_found)
        if self.is_coil_report_object:
            ReportCoilSelection.setCoilLvgAirTemp(state, self.coil_report_num, self.auto_sized_value)
        return self.auto_sized_value


class HeatingCoilDesAirInletHumRatSizer(BaseSizer):
    def __init__(self):
        self.sizing_type = AutoSizingType.HeatingCoilDesAirInletHumRatSizing
        self.sizing_string = "Rated Inlet Air Humidity Ratio"
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                self.error_type = AutoSizingResultType.ErrorType1
                self.auto_sized_value = 0.0
                msg = "Developer Error: For autosizing of " + self.comp_type + ' ' + self.comp_name + ", Zone equipment not implemented."
                self.add_error_message(msg)
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if self.data_desic_reg_coil:
                    if state.data_desiccant_dehumidifiers.desic_dehum[self.data_desic_dehum_num].regen_inlet_is_outside_air_node:
                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].heat_out_hum_rat
                    else:
                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].heat_ret_hum_rat
        self.select_sizer_output(state, errors_found)
        if self.is_coil_report_object:
            ReportCoilSelection.setCoilEntAirHumRat(state, self.coil_report_num, self.auto_sized_value)
        return self.auto_sized_value
