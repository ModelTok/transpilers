# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithScalableInputs: parent class from EnergyPlus.Autosizing.BaseSizerWithScalableInputs
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData (passed as parameter)
# - ShowSevereError, ShowContinueError: from EnergyPlus.UtilityRoutines
# - Util.SameString: from EnergyPlus.UtilityRoutines (case-insensitive string compare)
# - ReportCoilSelection.setCoilAirFlow: from EnergyPlus.OutputReportPredefined
# - OutputReportPredefined.PreDefTableEntry: from EnergyPlus.OutputReportPredefined
# - state.dataSize: flags like ZoneCoolingOnlyFan, ZoneHeatingOnlyFan
# - state.dataEnvrn: properties like StdRhoAir
# - state.dataOutRptPredefined: pdchFanDesDay, pdchFanPkTime
# - outsideAirSys: external array/map access via state
# - AutoSizingType.HeatingAirFlowSizing: enum value
# - DataSizing enum values: SupplyAirFlowRate, None, FlowPerFloorArea, etc.
# - HVAC.AirDuctType, HVAC.HeatingAirflowSizing: enums

class AutoSizingType:
    HeatingAirFlowSizing = 1

class DataSizing:
    SupplyAirFlowRate = 1
    None_ = 2
    FlowPerFloorArea = 3
    FractionOfAutosizedCoolingAirflow = 4
    FractionOfAutosizedHeatingAirflow = 5
    FlowPerCoolingCapacity = 6
    FlowPerHeatingCapacity = 7

class HVAC:
    class AirDuctType:
        Main = 1
        Cooling = 2
        Heating = 3
        Other = 4
    
    HeatingAirflowSizing = 0

class BaseSizerWithScalableInputs:
    def __init__(self):
        self.sizing_type = None
        self.sizing_string = ""
        self.auto_sized_value = 0.0
        self.original_value = 0.0
        self.was_auto_sized = False
        self.sizing_des_run_this_zone = False
        self.sizing_des_run_this_air_sys = False
        self.cur_zone_eq_num = 0
        self.cur_sys_num = 0
        self.cur_oas_num = 0
        self.cur_duct_type = 0
        self.comp_type = ""
        self.comp_name = ""
        self.calling_routine = ""
        self.data_ems_override_on = False
        self.data_ems_override = 0.0
        self.data_constant_used_for_sizing = 0.0
        self.data_fraction_used_for_sizing = 0.0
        self.zone_eq_sizing = []
        self.zone_air_flow_siz_method = 0
        self.final_zone_sizing = []
        self.final_sys_sizing = []
        self.data_frac_of_autosized_cooling_airflow = 0.0
        self.data_frac_of_autosized_heating_airflow = 0.0
        self.data_flow_per_cooling_capacity = 0.0
        self.data_flow_per_heating_capacity = 0.0
        self.data_autosized_cooling_capacity = 0.0
        self.data_autosized_heating_capacity = 0.0
        self.data_non_zone_non_airloop_value = 0.0
        self.override_size_string = False
        self.data_scalable_sizing_on = False
        self.sizing_string_scalable = ""
        self.is_coil_report_object = False
        self.is_fan_report_object = False
        self.coil_report_num = 0
        self.term_unit_iu = False
        self.cur_term_unit_sizing_num = 0
        self.term_unit_sizing = []
        self.zone_eq_fan_coil = False
        self.zone_heating_only_fan = False
        self.oa_sys_eq_sizing = []
        self.airloop_doas = []
        self.unitary_sys_eq_sizing = []
        self.data_desic_reg_coil = False
    
    def check_initialized(self, state, errors_found):
        return True
    
    def pre_size(self, state, original_value):
        pass
    
    def select_sizer_output(self, state, errors_found):
        pass
    
    def add_error_message(self, msg):
        pass
    
    def clear_state(self):
        pass

class HeatingAirFlowSizer(BaseSizerWithScalableInputs):
    def __init__(self):
        super().__init__()
        self.sizing_type = AutoSizingType.HeatingAirFlowSizing
        self.sizing_string = "Heating Supply Air Flow Rate [m3/s]"
    
    def size(self, state, original_value, errors_found):
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        
        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing > 0 and self.data_fraction_used_for_sizing > 0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.cur_zone_eq_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                    self.auto_sized_value = original_value
                elif self.zone_eq_sizing[self.cur_zone_eq_num].design_size_from_parent:
                    self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].air_vol_flow
                else:
                    sizing_method = self.zone_eq_sizing[self.cur_zone_eq_num].sizing_method[HVAC.HeatingAirflowSizing]
                    
                    if sizing_method == DataSizing.SupplyAirFlowRate or sizing_method == DataSizing.None_ or sizing_method == DataSizing.FlowPerFloorArea:
                        if self.zone_eq_sizing[self.cur_zone_eq_num].system_air_flow:
                            self.auto_sized_value = max(self.zone_eq_sizing[self.cur_zone_eq_num].air_vol_flow,
                                                       self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow,
                                                       self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow)
                        else:
                            if state.data_size.zone_cooling_only_fan:
                                self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow
                            elif state.data_size.zone_heating_only_fan:
                                self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow
                            elif self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                                self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow
                            elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                                self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow
                            elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                                self.auto_sized_value = max(self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow,
                                                           self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow)
                            else:
                                self.auto_sized_value = max(self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow,
                                                           self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow)
                    
                    elif sizing_method == DataSizing.FractionOfAutosizedCoolingAirflow:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = max(self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow,
                                                       self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow)
                        else:
                            self.auto_sized_value = max(self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow,
                                                       self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow)
                    
                    elif sizing_method == DataSizing.FractionOfAutosizedHeatingAirflow:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = max(self.data_frac_of_autosized_cooling_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_vol_flow,
                                                       self.data_frac_of_autosized_heating_airflow * self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow)
                        else:
                            self.auto_sized_value = max(self.data_frac_of_autosized_cooling_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow,
                                                       self.data_frac_of_autosized_heating_airflow * self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow)
                    
                    elif sizing_method == DataSizing.FlowPerCoolingCapacity:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = max(self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                                       self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity)
                        else:
                            self.auto_sized_value = max(self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                                       self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity)
                    
                    elif sizing_method == DataSizing.FlowPerHeatingCapacity:
                        if state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                        elif state.data_size.zone_heating_only_fan:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                            self.auto_sized_value = self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and not self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity
                        elif self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow and self.zone_eq_sizing[self.cur_zone_eq_num].cooling_air_flow:
                            self.auto_sized_value = max(self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                                       self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity)
                        else:
                            self.auto_sized_value = max(self.data_flow_per_cooling_capacity * self.data_autosized_cooling_capacity,
                                                       self.data_flow_per_heating_capacity * self.data_autosized_heating_capacity)
                    
                    else:
                        if self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_flow:
                            self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].heating_air_vol_flow
                        elif state.data_size.zone_cooling_only_fan:
                            self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow
                        elif self.term_unit_iu and (self.cur_term_unit_sizing_num > 0):
                            self.auto_sized_value = self.term_unit_sizing[self.cur_term_unit_sizing_num].air_vol_flow
                        elif self.zone_eq_fan_coil:
                            self.auto_sized_value = self.zone_eq_sizing[self.cur_zone_eq_num].air_vol_flow
                        elif self.zone_heating_only_fan:
                            self.auto_sized_value = self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow
                        else:
                            self.auto_sized_value = max(self.final_zone_sizing[self.cur_zone_eq_num].des_cool_vol_flow,
                                                       self.final_zone_sizing[self.cur_zone_eq_num].des_heat_vol_flow)
            
            elif self.cur_sys_num > 0:
                if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                    self.auto_sized_value = original_value
                else:
                    if self.cur_oas_num > 0:
                        if self.oa_sys_eq_sizing[self.cur_oas_num].air_flow:
                            self.auto_sized_value = self.oa_sys_eq_sizing[self.cur_oas_num].air_vol_flow
                        elif self.oa_sys_eq_sizing[self.cur_oas_num].heating_air_flow:
                            self.auto_sized_value = self.oa_sys_eq_sizing[self.cur_oas_num].heating_air_vol_flow
                        elif len(self.airloop_doas) > 0 and self.airloop_doas[self.cur_oas_num].air_loop_doas_num > -1:
                            self.auto_sized_value = self.airloop_doas[self.airloop_doas[self.cur_oas_num].air_loop_doas_num].sizing_mass_flow / state.data_envrn.std_rho_air
                        else:
                            self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_out_air_vol_flow
                    else:
                        if self.unitary_sys_eq_sizing[self.cur_sys_num].air_flow:
                            self.auto_sized_value = self.unitary_sys_eq_sizing[self.cur_sys_num].air_vol_flow
                        elif self.unitary_sys_eq_sizing[self.cur_sys_num].heating_air_flow:
                            self.auto_sized_value = self.unitary_sys_eq_sizing[self.cur_sys_num].heating_air_vol_flow
                        else:
                            if self.cur_duct_type == HVAC.AirDuctType.Main:
                                if same_string(self.comp_type, "COIL:HEATING:WATER"):
                                    if self.final_sys_sizing[self.cur_sys_num].sys_air_min_flow_rat > 0.0 and not self.data_desic_reg_coil:
                                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].sys_air_min_flow_rat * self.final_sys_sizing[self.cur_sys_num].des_main_vol_flow
                                    else:
                                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_main_vol_flow
                                else:
                                    self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_main_vol_flow
                            elif self.cur_duct_type == HVAC.AirDuctType.Cooling:
                                if same_string(self.comp_type, "COIL:HEATING:WATER"):
                                    if self.final_sys_sizing[self.cur_sys_num].sys_air_min_flow_rat > 0.0 and not self.data_desic_reg_coil:
                                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].sys_air_min_flow_rat * self.final_sys_sizing[self.cur_sys_num].des_cool_vol_flow
                                    else:
                                        self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_cool_vol_flow
                                else:
                                    self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_cool_vol_flow
                            elif self.cur_duct_type == HVAC.AirDuctType.Heating:
                                self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_heat_vol_flow
                            elif self.cur_duct_type == HVAC.AirDuctType.Other:
                                self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_main_vol_flow
                            else:
                                self.auto_sized_value = self.final_sys_sizing[self.cur_sys_num].des_main_vol_flow
            
            elif self.data_non_zone_non_airloop_value > 0:
                self.auto_sized_value = self.data_non_zone_non_airloop_value
            elif not self.was_auto_sized:
                self.auto_sized_value = self.original_value
            else:
                msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                show_severe_error(state, msg)
                self.add_error_message(msg)
                msg = f"SizingString = {self.sizing_string}, SizingResult = {self.auto_sized_value:.1f}"
                show_continue_error(state, msg)
                self.add_error_message(msg)
                errors_found[0] = True
            
            if self.override_size_string:
                self.sizing_string = "Heating Supply Air Flow Rate [m3/s]"
            
            if self.data_scalable_sizing_on:
                if self.zone_air_flow_siz_method == DataSizing.SupplyAirFlowRate or self.zone_air_flow_siz_method == DataSizing.None_:
                    self.sizing_string_scalable = "(scaled by flow / zone) "
                elif self.zone_air_flow_siz_method == DataSizing.FlowPerFloorArea:
                    self.sizing_string_scalable = "(scaled by flow / area) "
                elif self.zone_air_flow_siz_method == DataSizing.FractionOfAutosizedCoolingAirflow or self.zone_air_flow_siz_method == DataSizing.FractionOfAutosizedHeatingAirflow:
                    self.sizing_string_scalable = "(scaled by fractional multiplier) "
                elif self.zone_air_flow_siz_method == DataSizing.FlowPerCoolingCapacity or self.zone_air_flow_siz_method == DataSizing.FlowPerHeatingCapacity:
                    self.sizing_string_scalable = "(scaled by flow / capacity) "
        
        self.select_sizer_output(state, errors_found)
        
        if self.is_coil_report_object:
            set_coil_air_flow(state, self.coil_report_num, self.auto_sized_value, self.was_auto_sized)
        
        if self.is_fan_report_object:
            dd_name_fan_peak = ""
            date_time_fan_peak = ""
            if self.data_scalable_sizing_on:
                dd_name_fan_peak = "Scaled size, not from any peak"
                date_time_fan_peak = "Scaled size, not from any peak"
            pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_des_day, self.comp_name, dd_name_fan_peak)
            pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_pk_time, self.comp_name, date_time_fan_peak)
        
        return self.auto_sized_value
    
    def clear_state(self):
        super().clear_state()

def same_string(a, b):
    return a.upper() == b.upper() if isinstance(a, str) and isinstance(b, str) else False

def show_severe_error(state, msg):
    pass

def show_continue_error(state, msg):
    pass

def set_coil_air_flow(state, coil_report_num, auto_sized_value, was_auto_sized):
    pass

def pre_def_table_entry(state, entry_type, name, value):
    pass
