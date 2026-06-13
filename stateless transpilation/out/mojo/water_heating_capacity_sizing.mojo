# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: struct from EnergyPlus/Data/EnergyPlusData.hh
# - AutoSizingType: enum from EnergyPlus/Autosizing/Base.hh
# - BaseSizer: base struct from EnergyPlus/Autosizing/Base.hh
# - Constant.HWInitConvTemp: float constant from EnergyPlus (60.0)
# - Psychrometrics.PsyCpAirFnW: function from EnergyPlus/Psychrometrics.hh
# - ReportCoilSelection.setCoilWaterHeaterCapacityPltSizNum: function from EnergyPlus/ReportCoilSelection.hh
# - ShowWarningMessage: function from EnergyPlus/UtilityRoutines.hh
# - ShowContinueError: function from EnergyPlus/UtilityRoutines.hh

from math import floor

alias Real64 = Float64

struct WaterHeatingCapacitySizer:
    var sizing_type: String
    var sizing_string: String
    var cur_zone_eq_num: Int32
    var cur_sys_num: Int32
    var cur_term_unit_sizing_num: Int32
    var was_auto_sized: Bool
    var sizing_des_run_this_zone: Bool
    var sizing_des_run_this_air_sys: Bool
    var term_unit_sing_duct: Bool
    var term_unit_piu: Bool
    var term_unit_iu: Bool
    var zone_eq_fan_coil: Bool
    var zone_eq_unit_heater: Bool
    var override_size_string: Bool
    var is_coil_report_object: Bool
    var data_water_loop_num: Int32
    var data_water_coil_siz_heat_delta_t: Real64
    var data_heat_size_ratio: Real64
    var calling_routine: String
    var comp_type: String
    var comp_name: String
    var coil_report_num: Int32
    var data_plt_siz_heat_num: Int32
    var auto_sized_value: Real64
    
    fn __init__(inout self):
        self.sizing_type = "WaterHeatingCapacitySizing"
        self.sizing_string = "Rated Capacity [W]"
        self.cur_zone_eq_num = 0
        self.cur_sys_num = 0
        self.cur_term_unit_sizing_num = 0
        self.was_auto_sized = False
        self.sizing_des_run_this_zone = False
        self.sizing_des_run_this_air_sys = False
        self.term_unit_sing_duct = False
        self.term_unit_piu = False
        self.term_unit_iu = False
        self.zone_eq_fan_coil = False
        self.zone_eq_unit_heater = False
        self.override_size_string = False
        self.is_coil_report_object = False
        self.data_water_loop_num = 0
        self.data_water_coil_siz_heat_delta_t = 0.0
        self.data_heat_size_ratio = 1.0
        self.calling_routine = ""
        self.comp_type = ""
        self.comp_name = ""
        self.coil_report_num = 0
        self.data_plt_siz_heat_num = 0
        self.auto_sized_value = 0.0
    
    fn check_initialized(self, state: UnsafePointer[AnyType], errors_found: UnsafePointer[Bool]) -> Bool:
        return True
    
    fn pre_size(self, state: UnsafePointer[AnyType], original_value: Real64):
        pass
    
    fn select_sizer_output(self, state: UnsafePointer[AnyType], errors_found: UnsafePointer[Bool]):
        pass
    
    fn add_error_message(self, msg: String):
        pass
    
    fn set_oa_frac_for_zone_eq_sizing(self, state: UnsafePointer[AnyType], mass_flow: Real64, zone_eq_sizing: AnyType) -> AnyType:
        return AnyType()
    
    fn set_heat_coil_inlet_temp_for_zone_eq_sizing(self, oa_frac: AnyType, zone_eq_sizing: AnyType, final_zone_sizing: AnyType) -> Real64:
        return 0.0
    
    fn term_unit_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn zone_eq_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn final_zone_sizing(self, index: Int32) -> AnyType:
        return AnyType()
    
    fn size(inout self, state: UnsafePointer[AnyType], original_value: Real64, errors_found: UnsafePointer[Bool]) -> Real64:
        if not self.check_initialized(state, errors_found):
            return 0.0
        
        self.pre_size(state, original_value)
        
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                var des_mass_flow: Real64 = 0.0
                var nominal_capacity_des: Real64 = 0.0
                var coil_in_temp: Real64 = 0.0
                var coil_out_temp: Real64 = 0.0
                var coil_out_hum_rat: Real64 = 0.0
                
                if (self.term_unit_sing_duct or self.term_unit_piu or self.term_unit_iu) and (self.cur_term_unit_sizing_num > 0):
                    des_mass_flow = self.term_unit_sizing(self.cur_term_unit_sizing_num).MaxHWVolFlow
                    var cp: Real64 = state.dataPlnt.PlantLoop[self.data_water_loop_num].glycol.getSpecificHeat(
                        state, 60.0, self.calling_routine)
                    var rho: Real64 = state.dataPlnt.PlantLoop[self.data_water_loop_num].glycol.getDensity(
                        state, 60.0, self.calling_routine)
                    nominal_capacity_des = des_mass_flow * self.data_water_coil_siz_heat_delta_t * cp * rho
                
                elif self.zone_eq_fan_coil or self.zone_eq_unit_heater:
                    des_mass_flow = self.zone_eq_sizing(self.cur_zone_eq_num).MaxHWVolFlow
                    var cp: Real64 = state.dataPlnt.PlantLoop[self.data_water_loop_num].glycol.getSpecificHeat(
                        state, 60.0, self.calling_routine)
                    var rho: Real64 = state.dataPlnt.PlantLoop[self.data_water_loop_num].glycol.getDensity(
                        state, 60.0, self.calling_routine)
                    nominal_capacity_des = des_mass_flow * self.data_water_coil_siz_heat_delta_t * cp * rho
                
                else:
                    if self.zone_eq_sizing(self.cur_zone_eq_num).SystemAirFlow:
                        des_mass_flow = self.zone_eq_sizing(self.cur_zone_eq_num).AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zone_eq_sizing(self.cur_zone_eq_num).HeatingAirFlow:
                        des_mass_flow = self.zone_eq_sizing(self.cur_zone_eq_num).HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        des_mass_flow = self.final_zone_sizing(self.cur_zone_eq_num).DesHeatMassFlow
                    
                    coil_in_temp = self.set_heat_coil_inlet_temp_for_zone_eq_sizing(
                        self.set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zone_eq_sizing(self.cur_zone_eq_num)),
                        self.zone_eq_sizing(self.cur_zone_eq_num),
                        self.final_zone_sizing(self.cur_zone_eq_num))
                    
                    coil_out_temp = self.final_zone_sizing(self.cur_zone_eq_num).HeatDesTemp
                    coil_out_hum_rat = self.final_zone_sizing(self.cur_zone_eq_num).HeatDesHumRat
                    nominal_capacity_des = psychrometrics_psy_cp_air_fn_w(coil_out_hum_rat) * des_mass_flow * (coil_out_temp - coil_in_temp)
                
                self.auto_sized_value = nominal_capacity_des * self.data_heat_size_ratio
                
                if state.dataGlobal.DisplayExtraWarnings and self.auto_sized_value <= 0.0:
                    var msg: String = self.calling_routine + ": Potential issue with equipment sizing for " + self.comp_type + ' ' + self.comp_name
                    self.add_error_message(msg)
                    show_warning_message(state, msg)
                    
                    msg = "...Rated Total Heating Capacity = " + str(self.auto_sized_value, 2) + " [W]"
                    self.add_error_message(msg)
                    show_continue_error(state, msg)
                    
                    msg = "...Air flow rate used for sizing = " + str(des_mass_flow / state.dataEnvrn.StdRhoAir, 5) + " [m3/s]"
                    self.add_error_message(msg)
                    show_continue_error(state, msg)
                    
                    if self.term_unit_sing_duct or self.term_unit_piu or self.term_unit_iu or self.zone_eq_fan_coil or self.zone_eq_unit_heater:
                        msg = "...Air flow rate used for sizing = " + str(des_mass_flow / state.dataEnvrn.StdRhoAir, 5) + " [m3/s]"
                        self.add_error_message(msg)
                        show_continue_error(state, msg)
                        
                        msg = "...Plant loop temperature difference = " + str(self.data_water_coil_siz_heat_delta_t, 2) + " [C]"
                        self.add_error_message(msg)
                        show_continue_error(state, msg)
                    else:
                        msg = "...Coil inlet air temperature used for sizing = " + str(coil_in_temp, 2) + " [C]"
                        self.add_error_message(msg)
                        show_continue_error(state, msg)
                        
                        msg = "...Coil outlet air temperature used for sizing = " + str(coil_out_temp, 2) + " [C]"
                        self.add_error_message(msg)
                        show_continue_error(state, msg)
                        
                        msg = "...Coil outlet air humidity ratio used for sizing = " + str(coil_out_hum_rat, 2) + " [kgWater/kgDryAir]"
                        self.add_error_message(msg)
                        show_continue_error(state, msg)
        
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
        
        if self.override_size_string:
            self.sizing_string = "Rated Capacity [W]"
        
        self.select_sizer_output(state, errors_found)
        
        if self.is_coil_report_object:
            report_coil_selection_set_coil_water_heater_capacity_plt_siz_num(
                state, self.coil_report_num, self.auto_sized_value, self.was_auto_sized, 
                self.data_plt_siz_heat_num, self.data_water_loop_num)
        
        return self.auto_sized_value


fn psychrometrics_psy_cp_air_fn_w(humidity_ratio: Real64) -> Real64:
    return 0.0


fn report_coil_selection_set_coil_water_heater_capacity_plt_siz_num(state: UnsafePointer[AnyType], coil_report_num: Int32, auto_sized_value: Real64, was_auto_sized: Bool, data_plt_siz_heat_num: Int32, data_water_loop_num: Int32):
    pass


fn show_warning_message(state: UnsafePointer[AnyType], msg: String):
    pass


fn show_continue_error(state: UnsafePointer[AnyType], msg: String):
    pass
