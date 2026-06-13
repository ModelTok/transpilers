from math import isfinite

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object from EnergyPlus core
# BaseSizer: base struct from EnergyPlus.Autosizing.Base
# AutoSizingType: enum from EnergyPlus.Autosizing
# AutoSizingResultType: enum from EnergyPlus.Autosizing
# WaterCoils: module with CalcSimpleHeatingCoil(state, coil_num, fan_op, value, sim_calc)
# General: module with SolveRoot(state, acc, max_iter, sol_fla, x_val, f, x_min, x_max)
#          and constants SOLVEROOT_ERROR_ITER, SOLVEROOT_ERROR_INIT
# HVAC: module with SmallLoad constant
# ReportCoilSelection: module with setCoilUA(state, coil_report_num, auto_sized_value, ...)
# UtilityRoutines: module with ShowSevereError, ShowContinueError, ShowWarningError


struct BaseSizer:
    var sizing_type: String
    var sizing_string: String
    var cur_zone_eq_num: Int
    var cur_sys_num: Int
    var was_auto_sized: Bool
    var sizing_des_run_this_zone: Bool
    var sizing_des_run_this_air_sys: Bool
    var auto_sized_value: Float64
    var data_capacity_used_for_sizing: Float64
    var data_water_flow_used_for_sizing: Float64
    var data_flow_used_for_sizing: Float64
    var data_coil_num: Int
    var data_fan_op: Int
    var comp_name: String
    var final_zone_sizing: OpaquePointer
    var data_des_inlet_air_temp: Float64
    var data_des_inlet_air_hum_rat: Float64
    var data_design_coil_capacity: Float64
    var data_nom_cap_inp_meth: Bool
    var term_unit_sing_duct: Bool
    var term_unit_piu: Bool
    var term_unit_iu: Bool
    var zone_eq_fan_coil: Bool
    var data_des_outlet_air_temp: Float64
    var data_des_outlet_air_hum_rat: Float64
    var error_type: String
    var data_errors_found: Bool
    var plant_siz_data: OpaquePointer
    var data_plt_siz_heat_num: Int
    var data_water_coil_siz_heat_delta_t: Float64
    var final_sys_sizing: OpaquePointer
    var override_size_string: Bool
    var is_coil_report_object: Bool
    var coil_report_num: Int
    
    fn check_initialized(self, state: OpaquePointer, errors_found: OpaquePointer) -> Bool:
        return True
    
    fn pre_size(self, state: OpaquePointer, original_value: Float64):
        pass
    
    fn add_error_message(self, msg: String):
        pass
    
    fn select_sizer_output(self, state: OpaquePointer, errors_found: OpaquePointer):
        pass


struct WaterHeatingCoilUASizer(BaseSizer):
    
    fn __init__(inout self):
        self.sizing_type = "WaterHeatingCoilUASizing"
        self.sizing_string = "U-Factor Times Area Value [W/K]"
        self.cur_zone_eq_num = 0
        self.cur_sys_num = 0
        self.was_auto_sized = False
        self.sizing_des_run_this_zone = False
        self.sizing_des_run_this_air_sys = False
        self.auto_sized_value = 0.0
        self.data_capacity_used_for_sizing = 0.0
        self.data_water_flow_used_for_sizing = 0.0
        self.data_flow_used_for_sizing = 0.0
        self.data_coil_num = 0
        self.data_fan_op = 0
        self.comp_name = ""
        self.final_zone_sizing = OpaquePointer()
        self.data_des_inlet_air_temp = 0.0
        self.data_des_inlet_air_hum_rat = 0.0
        self.data_design_coil_capacity = 0.0
        self.data_nom_cap_inp_meth = False
        self.term_unit_sing_duct = False
        self.term_unit_piu = False
        self.term_unit_iu = False
        self.zone_eq_fan_coil = False
        self.data_des_outlet_air_temp = 0.0
        self.data_des_outlet_air_hum_rat = 0.0
        self.error_type = ""
        self.data_errors_found = False
        self.plant_siz_data = OpaquePointer()
        self.data_plt_siz_heat_num = 0
        self.data_water_coil_siz_heat_delta_t = 0.0
        self.final_sys_sizing = OpaquePointer()
        self.override_size_string = False
        self.is_coil_report_object = False
        self.coil_report_num = 0
    
    fn size(inout self, state: OpaquePointer, original_value: Float64, errors_found: OpaquePointer) -> Float64:
        if not self.check_initialized(state, errors_found):
            return 0.0
        
        self.pre_size(state, original_value)
        
        if self.cur_zone_eq_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_zone:
                self.auto_sized_value = original_value
            else:
                if (self.data_capacity_used_for_sizing > 0.0 and 
                    self.data_water_flow_used_for_sizing > 0.0 and 
                    self.data_flow_used_for_sizing > 0.0):
                    
                    var ua0: Float64 = 0.001 * self.data_capacity_used_for_sizing
                    var ua1: Float64 = self.data_capacity_used_for_sizing
                    
                    fn f(ua: Float64) -> Float64:
                        # state.dataWaterCoils->WaterCoil(this->dataCoilNum).UACoilVariable = UA;
                        # WaterCoils::CalcSimpleHeatingCoil(...)
                        # state.dataSize->DataDesignCoilCapacity = ...
                        # return (...)
                        return 0.0
                    
                    var acc: Float64 = 0.0001
                    var sol_fla: Int = 0
                    # General::SolveRoot(state, Acc, 500, SolFla, this->autoSizedValue, f, UA0, UA1);
                    
                    if sol_fla == 1:  # SOLVEROOT_ERROR_ITER
                        var errors_found_ptr = errors_found
                        var msg: String = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.comp_name}"'
                        self.add_error_message(msg)
                        # ShowSevereError(state, msg);
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Lower UA estimate = {ua0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Upper UA estimate = {ua1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.auto_sized_value:.6f} W/m2-K"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f'  Zone "{{zone_name}}" coil sizing conditions (may be different than Sizing inputs):'
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air temperature     = {self.data_des_inlet_air_temp:.3f} C"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air humidity ratio  = {self.data_des_inlet_air_hum_rat:.3f} kgWater/kgDryAir"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air mass flow rate  = {self.data_flow_used_for_sizing:.6f} kg/s"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Capacity           = {self.data_design_coil_capacity:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        if self.data_nom_cap_inp_meth:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air temperature    = {self.data_des_outlet_air_temp:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {self.data_des_outlet_air_hum_rat:.3f} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        elif self.term_unit_sing_duct or self.term_unit_piu or self.term_unit_iu or self.zone_eq_fan_coil:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        else:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air temperature    = {{heat_des_temp:.3f}} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {{heat_des_hum_rat:.3f}} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        self.data_errors_found = True
                    
                    elif sol_fla == 2:  # SOLVEROOT_ERROR_INIT
                        self.error_type = "ErrorType1"
                        var errors_found_ptr = errors_found
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.comp_name}"'
                        self.add_error_message(msg)
                        # ShowSevereError(state, msg);
                        msg = "  Bad starting values for UA"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Lower UA estimate = {ua0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Upper UA estimate = {ua1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f'  Zone "{{zone_name}}" coil sizing conditions (may be different than Sizing inputs):'
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air temperature     = {self.data_des_inlet_air_temp:.3f} C"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air humidity ratio  = {self.data_des_inlet_air_hum_rat:.3f} kgWater/kgDryAir"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air mass flow rate  = {self.data_flow_used_for_sizing:.6f} kg/s"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Capacity           = {self.data_design_coil_capacity:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        if self.data_nom_cap_inp_meth:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air temperature    = {self.data_des_outlet_air_temp:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {self.data_des_outlet_air_hum_rat:.3f} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        elif self.term_unit_sing_duct or self.term_unit_piu or self.term_unit_iu or self.zone_eq_fan_coil:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        else:
                            msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air temperature    = {{heat_des_temp:.3f}} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {{heat_des_hum_rat:.3f}} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        if self.data_design_coil_capacity < self.data_capacity_used_for_sizing:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant Sizing object = {{plant_loop_name}}"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant design loop exit temperature = {{exit_temp:.3f}} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant design loop delta T          = {self.data_water_coil_siz_heat_delta_t:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        self.data_errors_found = True
                else:
                    self.auto_sized_value = 1.0
                    if self.data_water_flow_used_for_sizing > 0.0 and self.data_capacity_used_for_sizing == 0.0:
                        var msg: String = f"The design coil load used for UA sizing is zero for Coil:Heating:Water {self.comp_name}"
                        self.add_error_message(msg)
                        # ShowWarningError(state, msg);
                        msg = "An autosize value for UA cannot be calculated"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "  the zone heating design supply air temperature"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
        
        elif self.cur_sys_num > 0:
            if not self.was_auto_sized and not self.sizing_des_run_this_air_sys:
                self.auto_sized_value = original_value
            else:
                if (self.data_capacity_used_for_sizing >= 1.0 and 
                    self.data_water_flow_used_for_sizing > 0.0 and 
                    self.data_flow_used_for_sizing > 0.0):
                    
                    var ua0: Float64 = 0.001 * self.data_capacity_used_for_sizing
                    var ua1: Float64 = self.data_capacity_used_for_sizing
                    
                    fn f(ua: Float64) -> Float64:
                        return 0.0
                    
                    var acc: Float64 = 0.0001
                    var sol_fla: Int = 0
                    # General::SolveRoot(state, Acc, 500, SolFla, this->autoSizedValue, f, UA0, UA1);
                    
                    if sol_fla == 1:
                        var msg: String = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.comp_name}"'
                        self.add_error_message(msg)
                        # ShowSevereError(state, msg);
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Lower UA estimate = {ua0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Upper UA estimate = {ua1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.auto_sized_value:.6f} W/m2-K"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f'  AirloopHVAC "{{airloop_name}}" coil sizing conditions (may be different than Sizing inputs):'
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air temperature     = {self.data_des_inlet_air_temp:.3f} C"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air humidity ratio  = {self.data_des_inlet_air_hum_rat:.3f} kgWater/kgDryAir"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air mass flow rate  = {self.data_flow_used_for_sizing:.6f} kg/s"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Capacity           = {self.data_design_coil_capacity:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        if self.data_nom_cap_inp_meth:
                            msg = f"  Coil outlet air temperature    = {self.data_des_outlet_air_temp:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {self.data_des_outlet_air_hum_rat:.3f} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        self.data_errors_found = True
                    
                    elif sol_fla == 2:
                        self.error_type = "ErrorType1"
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.comp_name}"'
                        self.add_error_message(msg)
                        # ShowSevereError(state, msg);
                        msg = "  Bad starting values for UA"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Lower UA estimate = {ua0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Upper UA estimate = {ua1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f'  AirloopHVAC "{{airloop_name}}" coil sizing conditions (may be different than Sizing inputs):'
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air temperature     = {self.data_des_inlet_air_temp:.3f} C"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air humidity ratio  = {self.data_des_inlet_air_hum_rat:.3f} kgWater/kgDryAir"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Coil inlet air mass flow rate  = {self.data_flow_used_for_sizing:.6f} kg/s"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Capacity           = {self.data_design_coil_capacity:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = f"  Design Coil Load               = {self.data_capacity_used_for_sizing:.3f} W"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        if self.data_nom_cap_inp_meth:
                            msg = f"  Coil outlet air temperature    = {self.data_des_outlet_air_temp:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Coil outlet air humidity ratio = {self.data_des_outlet_air_hum_rat:.3f} kgWater/kgDryAir"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        if self.data_design_coil_capacity < self.data_capacity_used_for_sizing and not self.data_nom_cap_inp_meth:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant Sizing object = {{plant_loop_name}}"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant design loop exit temperature = {{exit_temp:.3f}} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                            msg = f"  Plant design loop delta T          = {self.data_water_coil_siz_heat_delta_t:.3f} C"
                            self.add_error_message(msg)
                            # ShowContinueError(state, msg);
                        self.data_errors_found = True
                else:
                    self.auto_sized_value = 1.0
                    if self.data_water_flow_used_for_sizing > 0.0 and self.data_capacity_used_for_sizing < 1.0:
                        var msg: String = f"The design coil load used for UA sizing is zero for Coil:Heating:Water {self.comp_name}"
                        self.add_error_message(msg)
                        # ShowWarningError(state, msg);
                        msg = "An autosize value for UA cannot be calculated"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "  the zone heating design supply air temperature"
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.add_error_message(msg)
                        # ShowContinueError(state, msg);
        
        if self.data_errors_found:
            # state.dataSize->DataErrorsFound = true;
            pass
        
        if self.override_size_string:
            self.sizing_string = "U-Factor Times Area Value [W/K]"
        
        self.select_sizer_output(state, errors_found)
        
        # if self.is_coil_report_object and self.cur_sys_num <= state.dataHVACGlobal.NumPrimaryAirSys:
        #     ReportCoilSelection::setCoilUA(...)
        
        return self.auto_sized_value
