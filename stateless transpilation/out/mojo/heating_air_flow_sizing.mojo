# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithScalableInputs: parent struct from EnergyPlus.Autosizing.BaseSizerWithScalableInputs
# - EnergyPlusData: state struct from EnergyPlus.Data.EnergyPlusData (passed as parameter)
# - show_severe_error, show_continue_error: from EnergyPlus.UtilityRoutines
# - same_string: from EnergyPlus.UtilityRoutines (case-insensitive string compare)
# - set_coil_air_flow: from EnergyPlus.OutputReportPredefined
# - pre_def_table_entry: from EnergyPlus.OutputReportPredefined
# - state.data_size: flags like zone_cooling_only_fan, zone_heating_only_fan
# - state.data_envrn: properties like std_rho_air
# - state.data_out_rpt_predefined: pdch_fan_des_day, pdch_fan_pk_time
# - outside_air_sys: external array/map access via state
# - AutoSizingType.HeatingAirFlowSizing: enum value
# - DataSizing enum values: SupplyAirFlowRate, None_, FlowPerFloorArea, etc.
# - HVAC.AirDuctType, HVAC.HeatingAirflowSizing: enums

struct AutoSizingType:
    alias HeatingAirFlowSizing = 1

struct DataSizing:
    alias SupplyAirFlowRate = 1
    alias None_ = 2
    alias FlowPerFloorArea = 3
    alias FractionOfAutosizedCoolingAirflow = 4
    alias FractionOfAutosizedHeatingAirflow = 5
    alias FlowPerCoolingCapacity = 6
    alias FlowPerHeatingCapacity = 7

struct HVAC:
    struct AirDuctType:
        alias Main = 1
        alias Cooling = 2
        alias Heating = 3
        alias Other = 4
    alias HeatingAirflowSizing = 0

struct BaseSizerWithScalableInputs:
    var sizing_type: Int32
    var sizing_string: String
    var auto_sized_value: Float64
    var original_value: Float64
    var was_auto_sized: Bool
    var sizing_des_run_this_zone: Bool
    var sizing_des_run_this_air_sys: Bool
    var cur_zone_eq_num: Int32
    var cur_sys_num: Int32
    var cur_oas_num: Int32
    var cur_duct_type: Int32
    var comp_type: String
    var comp_name: String
    var calling_routine: String
    var data_ems_override_on: Bool
    var data_ems_override: Float64
    var data_constant_used_for_sizing: Float64
    var data_fraction_used_for_sizing: Float64
    var zone_eq_sizing: DynamicVector[ZoneEqSizingData]
    var zone_air_flow_siz_method: Int32
    var final_zone_sizing: DynamicVector[FinalZoneSizingData]
    var final_sys_sizing: DynamicVector[FinalSysSizingData]
    var data_frac_of_autosized_cooling_airflow: Float64
    var data_frac_of_autosized_heating_airflow: Float64
    var data_flow_per_cooling_capacity: Float64
    var data_flow_per_heating_capacity: Float64
    var data_autosized_cooling_capacity: Float64
    var data_autosized_heating_capacity: Float64
    var data_non_zone_non_airloop_value: Float64
    var override_size_string: Bool
    var data_scalable_sizing_on: Bool
    var sizing_string_scalable: String
    var is_coil_report_object: Bool
    var is_fan_report_object: Bool
    var coil_report_num: Int32
    var term_unit_iu: Bool
    var cur_term_unit_sizing_num: Int32
    var term_unit_sizing: DynamicVector[TermUnitSizingData]
    var zone_eq_fan_coil: Bool
    var zone_heating_only_fan: Bool
    var oa_sys_eq_sizing: DynamicVector[OASysEqSizingData]
    var airloop_doas: DynamicVector[AirloopDOASData]
    var unitary_sys_eq_sizing: DynamicVector[UnitarySysEqSizingData]
    var data_desic_reg_coil: Bool
    
    fn __init__(inout self):
        self.sizing_type = 0
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
        self.zone_air_flow_siz_method = 0
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
        self.zone_eq_fan_coil = False
        self.zone_heating_only_fan = False
        self.data_desic_reg_coil = False
    
    fn check_initialized(self, state: EnergyPlusData, errors_found: Bool) -> Bool:
        return True
    
    fn pre_size(self, state: EnergyPlusData, original_value: Float64):
        pass
    
    fn select_sizer_output(self, state: EnergyPlusData, errors_found: Bool):
        pass
    
    fn add_error_message(self, msg: String):
        pass
    
    fn clear_state(self):
        pass

struct HeatingAirFlowSizer(BaseSizerWithScalableInputs):
    fn __init__(inout self):
        super().__init__()
        self.sizing_type = AutoSizingType.HeatingAirFlowSizing
        self.sizing_string = "Heating Supply Air Flow Rate [m3/s]"
    
    fn size(inout self, state: EnergyPlusData, original_value: Float64, inout errors_found: Bool) -> Float64:
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
                    var sizing_method = self.zone_eq_sizing[self.cur_zone_eq_num].sizing_method[HVAC.HeatingAirflowSizing]
                    
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
                var msg = self.calling_routine + ' ' + self.comp_type + ' ' + self.comp_name + ", Developer Error: Component sizing incomplete."
                show_severe_error(state, msg)
                self.add_error_message(msg)
                msg = "SizingString = " + self.sizing_string + ", SizingResult = " + String(self.auto_sized_value)
                show_continue_error(state, msg)
                self.add_error_message(msg)
                errors_found = True
            
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
            var dd_name_fan_peak = ""
            var date_time_fan_peak = ""
            if self.data_scalable_sizing_on:
                dd_name_fan_peak = "Scaled size, not from any peak"
                date_time_fan_peak = "Scaled size, not from any peak"
            pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_des_day, self.comp_name, dd_name_fan_peak)
            pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_fan_pk_time, self.comp_name, date_time_fan_peak)
        
        return self.auto_sized_value
    
    fn clear_state(self):
        super().clear_state()

fn same_string(a: String, b: String) -> Bool:
    return a.upper() == b.upper()

fn show_severe_error(state: EnergyPlusData, msg: String):
    pass

fn show_continue_error(state: EnergyPlusData, msg: String):
    pass

fn set_coil_air_flow(state: EnergyPlusData, coil_report_num: Int32, auto_sized_value: Float64, was_auto_sized: Bool):
    pass

fn pre_def_table_entry(state: EnergyPlusData, entry_type: Int32, name: String, value: String):
    pass

struct ZoneEqSizingData:
    var design_size_from_parent: Bool
    var air_vol_flow: Float64
    var sizing_method: DynamicVector[Int32]
    var system_air_flow: Bool
    var cooling_air_vol_flow: Float64
    var heating_air_vol_flow: Float64
    var cooling_air_flow: Bool
    var heating_air_flow: Bool

struct FinalZoneSizingData:
    var des_cool_vol_flow: Float64
    var des_heat_vol_flow: Float64

struct FinalSysSizingData:
    var des_out_air_vol_flow: Float64
    var sys_air_min_flow_rat: Float64
    var des_main_vol_flow: Float64
    var des_cool_vol_flow: Float64
    var des_heat_vol_flow: Float64

struct TermUnitSizingData:
    var air_vol_flow: Float64

struct OASysEqSizingData:
    var air_flow: Bool
    var air_vol_flow: Float64
    var heating_air_flow: Bool
    var heating_air_vol_flow: Float64

struct AirloopDOASData:
    var air_loop_doas_num: Int32
    var sizing_mass_flow: Float64

struct UnitarySysEqSizingData:
    var air_flow: Bool
    var air_vol_flow: Float64
    var heating_air_flow: Bool
    var heating_air_vol_flow: Float64

struct DataSize:
    var zone_cooling_only_fan: Bool
    var zone_heating_only_fan: Bool

struct DataEnvrn:
    var std_rho_air: Float64

struct DataOutRptPredefined:
    var pdch_fan_des_day: Int32
    var pdch_fan_pk_time: Int32

struct EnergyPlusData:
    var data_size: DataSize
    var data_envrn: DataEnvrn
    var data_out_rpt_predefined: DataOutRptPredefined
