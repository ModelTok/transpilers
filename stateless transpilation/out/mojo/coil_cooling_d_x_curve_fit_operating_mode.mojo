from collections import InlineArray
from math import max as math_max
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state) - from Data/EnergyPlusData
# - Util.SameString() - from Utilities/String
# - Util.makeUPPER() - from Utilities/String
# - ShowWarningError, ShowContinueError, ShowSevereError, ShowFatalError - from ErrorReporting
# - SetupEMSActuator - from EMSManager
# - HVAC.FanOp enum (Cycling, Continuous) - from DataHVACGlobals
# - DataSizing.AutoSize - from DataSizing
# - Psychrometrics: PsyRhoAirFnPbTdbW, PsyTwbFnTdbWPb, PsyTdbFnHW, PsyTsatFnHPb, PsyWFnTdbH - from Psychrometrics
# - Node.NodeData - from DataLoopNode
# - Sched.Schedule (getCurrentVal) - from ScheduleManager
# - CoilCoolingDXCurveFitSpeed - from CoilCoolingDXCurveFitSpeed
# - CoolingAirFlowSizer, CoolingCapacitySizer, AutoCalculateSizer - from Autosizing/*
# - InputProcessor methods (epJSON, getRealFieldValue, getAlphaFieldValue, getIntFieldValue, etc.) - from InputProcessing/InputProcessor

enum CondenserType:
    Invalid = -1
    AIRCOOLED = 0
    EVAPCOOLED = 1
    Num = 2

struct CoilCoolingDXCurveFitOperatingModeInputSpecification:
    var name: String
    var gross_rated_total_cooling_capacity: Float64
    var rated_evaporator_air_flow_rate: Float64
    var rated_condenser_air_flow_rate: Float64
    var maximum_cycling_rate: Float64
    var ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity: Float64
    var latent_capacity_time_constant: Float64
    var nominal_time_for_condensate_removal_to_begin: Float64
    var apply_part_load_fraction_to_speeds_greater_than_1: String
    var apply_latent_degradation_to_speeds_greater_than_1: String
    var condenser_type: String
    var nominal_evap_condenser_pump_power: Float64
    var nominal_speed_number: Float64
    var speed_data_names: List[String]
    
    fn __init__(inout self):
        self.name = ""
        self.gross_rated_total_cooling_capacity = 0.0
        self.rated_evaporator_air_flow_rate = 0.0
        self.rated_condenser_air_flow_rate = 0.0
        self.maximum_cycling_rate = 0.0
        self.ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity = 0.0
        self.latent_capacity_time_constant = 0.0
        self.nominal_time_for_condensate_removal_to_begin = 0.0
        self.apply_part_load_fraction_to_speeds_greater_than_1 = ""
        self.apply_latent_degradation_to_speeds_greater_than_1 = ""
        self.condenser_type = ""
        self.nominal_evap_condenser_pump_power = 0.0
        self.nominal_speed_number = 0.0
        self.speed_data_names = List[String]()

struct CoilCoolingDXCurveFitOperatingMode:
    var object_name: String
    var parent_name: String
    var coil_cooling_dx_avail_sched: Optional[Pointer[Schedule]]
    
    var original_input_specs: CoilCoolingDXCurveFitOperatingModeInputSpecification
    
    var name: String
    var rated_gross_total_cap: Float64
    var rated_evap_air_flow_rate: Float64
    var rated_cond_air_flow_rate: Float64
    var rated_evap_air_mass_flow_rate: Float64
    var rated_gross_total_cap_is_autosized: Bool
    var rated_evap_air_flow_rate_is_autosized: Bool
    
    var time_for_condensate_removal: Float64
    var evap_rate_ratio: Float64
    var max_cycling_rate: Float64
    var latent_time_const: Float64
    var latent_degradation_active: Bool
    var apply_part_load_fraction_all_speeds: Bool
    var apply_latent_degradation_all_speeds: Bool
    
    var op_mode_power: Float64
    var op_mode_rtf: Float64
    var op_mode_waste_heat: Float64
    
    var nominal_evaporative_pump_power: Float64
    var nominal_speed_index: Int
    
    var rated_air_vol_flow_ems_override_on: Bool
    var rated_air_vol_flow_ems_override_value: Float64
    var rated_tot_cap_flow_ems_override_on: Bool
    var rated_tot_cap_flow_ems_override_value: Float64
    var min_outdoor_drybulb: Float64
    
    var condenser_type: CondenserType
    var cond_inlet_temp: Float64
    
    var speeds: List[CoilCoolingDXCurveFitSpeed]
    
    fn __init__(inout self):
        self.object_name = "Coil:Cooling:DX:CurveFit:OperatingMode"
        self.parent_name = ""
        self.coil_cooling_dx_avail_sched = None
        self.original_input_specs = CoilCoolingDXCurveFitOperatingModeInputSpecification()
        self.name = ""
        self.rated_gross_total_cap = 0.0
        self.rated_evap_air_flow_rate = 0.0
        self.rated_cond_air_flow_rate = 0.0
        self.rated_evap_air_mass_flow_rate = 0.0
        self.rated_gross_total_cap_is_autosized = False
        self.rated_evap_air_flow_rate_is_autosized = False
        self.time_for_condensate_removal = 0.0
        self.evap_rate_ratio = 0.0
        self.max_cycling_rate = 0.0
        self.latent_time_const = 0.0
        self.latent_degradation_active = False
        self.apply_part_load_fraction_all_speeds = False
        self.apply_latent_degradation_all_speeds = False
        self.op_mode_power = 0.0
        self.op_mode_rtf = 0.0
        self.op_mode_waste_heat = 0.0
        self.nominal_evaporative_pump_power = 0.0
        self.nominal_speed_index = 0
        self.rated_air_vol_flow_ems_override_on = False
        self.rated_air_vol_flow_ems_override_value = 0.0
        self.rated_tot_cap_flow_ems_override_on = False
        self.rated_tot_cap_flow_ems_override_value = 0.0
        self.min_outdoor_drybulb = -25.0
        self.condenser_type = CondenserType.AIRCOOLED
        self.cond_inlet_temp = 0.0
        self.speeds = List[CoilCoolingDXCurveFitSpeed]()

    fn instantiate_from_input_spec(inout self, state: Pointer[EnergyPlusData], input_data: CoilCoolingDXCurveFitOperatingModeInputSpecification) -> None:
        let routine_name = "CoilCoolingDXCurveFitOperatingMode::instantiate_from_input_spec: "
        var errors_found = False
        
        self.original_input_specs = input_data
        self.name = input_data.name
        self.rated_gross_total_cap = input_data.gross_rated_total_cooling_capacity
        
        if self.rated_gross_total_cap == state.data_sizing.AutoSize:
            self.rated_gross_total_cap_is_autosized = True
        
        self.rated_evap_air_flow_rate = input_data.rated_evaporator_air_flow_rate
        if self.rated_evap_air_flow_rate == state.data_sizing.AutoSize:
            self.rated_evap_air_flow_rate_is_autosized = True
        
        self.rated_cond_air_flow_rate = input_data.rated_condenser_air_flow_rate
        self.time_for_condensate_removal = input_data.nominal_time_for_condensate_removal_to_begin
        self.evap_rate_ratio = input_data.ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity
        self.max_cycling_rate = input_data.maximum_cycling_rate
        self.latent_time_const = input_data.latent_capacity_time_constant
        
        if SameString(input_data.apply_part_load_fraction_to_speeds_greater_than_1, "Yes"):
            self.apply_part_load_fraction_all_speeds = True
        else:
            self.apply_part_load_fraction_all_speeds = False
        
        if SameString(input_data.apply_latent_degradation_to_speeds_greater_than_1, "Yes"):
            self.apply_latent_degradation_all_speeds = True
        else:
            self.apply_latent_degradation_all_speeds = False
        
        self.nominal_evaporative_pump_power = input_data.nominal_evap_condenser_pump_power
        
        let any_set = (self.max_cycling_rate > 0.0 or self.evap_rate_ratio > 0.0 or self.latent_time_const > 0.0 or self.time_for_condensate_removal > 0.0)
        let all_set = (self.max_cycling_rate > 0.0 and self.evap_rate_ratio > 0.0 and self.latent_time_const > 0.0 and self.time_for_condensate_removal > 0.0)
        let not_all_set = (self.max_cycling_rate <= 0.0 or self.evap_rate_ratio <= 0.0 or self.latent_time_const <= 0.0 or self.time_for_condensate_removal <= 0.0)
        
        if any_set and not_all_set:
            ShowWarningError(state, routine_name + self.object_name + "=\"" + self.name + "\":")
            ShowContinueError(state, "...At least one of the four input parameters for the latent capacity degradation model")
            ShowContinueError(state, "...is set to zero. Therefore, the latent degradation model will not be used for this simulation.")
            self.latent_degradation_active = False
        elif all_set:
            self.latent_degradation_active = True
        
        if SameString(input_data.condenser_type, "AirCooled"):
            self.condenser_type = CondenserType.AIRCOOLED
        elif SameString(input_data.condenser_type, "EvaporativelyCooled"):
            self.condenser_type = CondenserType.EVAPCOOLED
        else:
            ShowSevereError(state, routine_name + self.object_name + "=\"" + self.name + "\", invalid")
            ShowContinueError(state, "...Condenser Type=\"" + input_data.condenser_type + "\":")
            ShowContinueError(state, "...must be AirCooled or EvaporativelyCooled.")
            errors_found = True
        
        for speed_name in input_data.speed_data_names:
            self.speeds.append(CoilCoolingDXCurveFitSpeed(state, speed_name))
        
        self.nominal_speed_index = Int(input_data.nominal_speed_number) - 1
        
        if errors_found:
            ShowFatalError(state, routine_name + "Errors found in getting " + self.object_name + " input. Preceding condition(s) causes termination.")

    fn __init__(inout self, state: Pointer[EnergyPlusData], name_to_find: String):
        self.__init__()
        
        let input_processor = state.data_input_processing.input_processor
        let mode_instances = input_processor.ep_json.get(self.object_name)
        
        if mode_instances is None:
            pass
        
        let mode_schema_props = input_processor.get_object_schema_props(state, self.object_name)
        var found_it = False
        
        for mode_instance_key in mode_instances:
            let mode_fields = mode_instances[mode_instance_key]
            let mode_name = makeUPPER(mode_instance_key)
            
            if not SameString(name_to_find, mode_name):
                continue
            
            found_it = True
            
            var input_specs = CoilCoolingDXCurveFitOperatingModeInputSpecification()
            
            input_specs.name = mode_name
            input_specs.gross_rated_total_cooling_capacity = input_processor.get_real_field_value(mode_fields, mode_schema_props, "rated_gross_total_cooling_capacity")
            input_specs.rated_evaporator_air_flow_rate = input_processor.get_real_field_value(mode_fields, mode_schema_props, "rated_evaporator_air_flow_rate")
            input_specs.rated_condenser_air_flow_rate = input_processor.get_real_field_value(mode_fields, mode_schema_props, "rated_condenser_air_flow_rate")
            input_specs.maximum_cycling_rate = input_processor.get_real_field_value(mode_fields, mode_schema_props, "maximum_cycling_rate")
            input_specs.ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity = input_processor.get_real_field_value(
                mode_fields, mode_schema_props, "ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity")
            input_specs.latent_capacity_time_constant = input_processor.get_real_field_value(mode_fields, mode_schema_props, "latent_capacity_time_constant")
            input_specs.nominal_time_for_condensate_removal_to_begin = input_processor.get_real_field_value(
                mode_fields, mode_schema_props, "nominal_time_for_condensate_removal_to_begin")
            input_specs.apply_part_load_fraction_to_speeds_greater_than_1 = input_processor.get_alpha_field_value(
                mode_fields, mode_schema_props, "apply_part_load_fraction_to_speeds_greater_than_1")
            input_specs.apply_latent_degradation_to_speeds_greater_than_1 = input_processor.get_alpha_field_value(
                mode_fields, mode_schema_props, "apply_latent_degradation_to_speeds_greater_than_1")
            input_specs.condenser_type = input_processor.get_alpha_field_value(mode_fields, mode_schema_props, "condenser_type")
            input_specs.nominal_evap_condenser_pump_power = input_processor.get_real_field_value(
                mode_fields, mode_schema_props, "nominal_evaporative_condenser_pump_power")
            input_specs.nominal_speed_number = Float64(input_processor.get_int_field_value(mode_fields, mode_schema_props, "nominal_speed_number"))
            
            for field_num in range(1, 11):
                let speed_field_name = String("speed_{0}_name").format(field_num)
                let speed_name = input_processor.get_alpha_field_value(mode_fields, mode_schema_props, speed_field_name)
                if speed_name == "":
                    break
                input_specs.speed_data_names.append(speed_name)
            
            if input_specs.nominal_speed_number == 0.0:
                input_specs.nominal_speed_number = Float64(input_specs.speed_data_names.size())
            
            self.instantiate_from_input_spec(state, input_specs)
            input_processor.mark_object_as_used(self.object_name, mode_instance_key)
            break
        
        if not found_it:
            ShowFatalError(state, "Could not find Coil:Cooling:DX:CurveFit:OperatingMode object with name: " + name_to_find)

    fn one_time_init(inout self, state: Pointer[EnergyPlusData]) -> None:
        if state.data_global.any_energy_management_system_in_model:
            SetupEMSActuator(
                state,
                self.object_name,
                self.name,
                "Autosized Rated Air Flow Rate",
                "[m3/s]",
                Pointer[Bool].address_of(self.rated_air_vol_flow_ems_override_on),
                Pointer[Float64].address_of(self.rated_air_vol_flow_ems_override_value)
            )
            SetupEMSActuator(
                state,
                self.object_name,
                self.name,
                "Autosized Rated Total Cooling Capacity",
                "[W]",
                Pointer[Bool].address_of(self.rated_tot_cap_flow_ems_override_on),
                Pointer[Float64].address_of(self.rated_tot_cap_flow_ems_override_value)
            )

    fn size(inout self, state: Pointer[EnergyPlusData]) -> None:
        let routine_name = "sizeOperatingMode"
        let comp_type = self.object_name
        let comp_name = self.name
        let print_flag = True
        var errors_found = False
        
        var temp_size = self.original_input_specs.rated_evaporator_air_flow_rate
        var sizing_cooling_air_flow = CoolingAirFlowSizer()
        let string_override = "Rated Evaporator Air Flow Rate [m3/s]"
        sizing_cooling_air_flow.override_sizing_string(string_override)
        sizing_cooling_air_flow.initialize_within_ep(state, comp_type, comp_name, print_flag, routine_name)
        self.rated_evap_air_flow_rate = sizing_cooling_air_flow.size(state, temp_size, Pointer[Bool].address_of(errors_found))
        
        let rated_inlet_air_temp = 26.6667
        let rated_inlet_air_hum_rat = 0.0111847
        self.rated_evap_air_mass_flow_rate = (
            self.rated_evap_air_flow_rate *
            PsyRhoAirFnPbTdbW(state, state.data_envr.StdBaroPress, rated_inlet_air_temp, rated_inlet_air_hum_rat, routine_name)
        )
        
        let sizing_string = "Rated Gross Total Cooling Capacity [W]"
        state.data_size.DataFlowUsedForSizing = self.rated_evap_air_flow_rate
        state.data_size.DataTotCapCurveIndex = self.speeds[self.nominal_speed_index].index_cap_ft
        temp_size = self.original_input_specs.gross_rated_total_cooling_capacity
        
        var sizer_cooling_capacity = CoolingCapacitySizer()
        sizer_cooling_capacity.override_sizing_string(sizing_string)
        sizer_cooling_capacity.initialize_within_ep(state, comp_type, comp_name, print_flag, routine_name)
        self.rated_gross_total_cap = sizer_cooling_capacity.size(state, temp_size, Pointer[Bool].address_of(errors_found))
        
        state.data_size.DataConstantUsedForSizing = self.rated_gross_total_cap
        state.data_size.DataFractionUsedForSizing = 0.000114
        temp_size = self.original_input_specs.rated_condenser_air_flow_rate
        
        var sizer_cond_air_flow = AutoCalculateSizer()
        let string_override2 = "Rated Condenser Air Flow Rate [m3/s]"
        sizer_cond_air_flow.override_sizing_string(string_override2)
        sizer_cond_air_flow.initialize_within_ep(state, comp_type, comp_name, print_flag, routine_name)
        self.rated_cond_air_flow_rate = sizer_cond_air_flow.size(state, temp_size, Pointer[Bool].address_of(errors_found))
        
        if self.condenser_type != CondenserType.AIRCOOLED:
            var sizer_cond_evap_pump_power = AutoCalculateSizer()
            state.data_size.DataConstantUsedForSizing = self.rated_gross_total_cap
            state.data_size.DataFractionUsedForSizing = 0.004266
            let string_override3 = "Nominal Evaporative Condenser Pump Power [W]"
            sizer_cond_evap_pump_power.override_sizing_string(string_override3)
            temp_size = self.original_input_specs.nominal_evap_condenser_pump_power
            sizer_cond_evap_pump_power.initialize_within_ep(state, comp_type, comp_name, print_flag, routine_name)
            self.nominal_evaporative_pump_power = sizer_cond_evap_pump_power.size(state, temp_size, Pointer[Bool].address_of(errors_found))
        
        var this_speed_num = 0
        for i in range(self.speeds.size()):
            var cur_speed = Pointer[CoilCoolingDXCurveFitSpeed].address_of(self.speeds[i])
            cur_speed.parent_name = self.parent_name
            cur_speed.parent_mode_rated_gross_total_cap = self.rated_gross_total_cap
            cur_speed.rated_gross_total_cap_is_autosized = self.rated_gross_total_cap_is_autosized
            cur_speed.parent_mode_rated_evap_air_flow_rate = self.rated_evap_air_flow_rate
            cur_speed.rated_evap_air_flow_rate_is_autosized = self.rated_evap_air_flow_rate_is_autosized
            cur_speed.parent_mode_rated_cond_air_flow_rate = self.rated_cond_air_flow_rate
            
            cur_speed.do_latent_degradation = False
            if self.latent_degradation_active:
                if (this_speed_num == 0) or ((this_speed_num > 0) and self.apply_latent_degradation_all_speeds):
                    cur_speed.parent_mode_time_for_condensate_removal = self.time_for_condensate_removal
                    cur_speed.parent_mode_evap_rate_ratio = self.evap_rate_ratio
                    cur_speed.parent_mode_max_cycling_rate = self.max_cycling_rate
                    cur_speed.parent_mode_latent_time_const = self.latent_time_const
                    cur_speed.do_latent_degradation = True
            
            cur_speed.size(state)
            this_speed_num += 1

    fn calc_operating_mode(
        inout self,
        state: Pointer[EnergyPlusData],
        inlet_node: Pointer[NodeData],
        outlet_node: Pointer[NodeData],
        speed_num: Int,
        speed_ratio: Float64,
        fan_op: FanOp,
        cond_inlet_node: Pointer[NodeData],
        cond_outlet_node: Pointer[NodeData],
        single_mode: Bool
    ) -> None:
        let routine_name = "CoilCoolingDXCurveFitOperatingMode::calcOperatingMode"
        
        var this_speed = Pointer[CoilCoolingDXCurveFitSpeed].address_of(self.speeds[math_max(speed_num - 1, 0)])
        
        if ((speed_num == 0) or ((speed_num == 1) and (speed_ratio == 0.0)) or (inlet_node.MassFlowRate == 0.0) or
            (self.coil_cooling_dx_avail_sched.get_current_val() <= 0.0) or (state.data_envr.OutDryBulbTemp < self.min_outdoor_drybulb)):
            outlet_node.Temp = inlet_node.Temp
            outlet_node.HumRat = inlet_node.HumRat
            outlet_node.Enthalpy = inlet_node.Enthalpy
            outlet_node.Press = inlet_node.Press
            self.op_mode_rtf = 0.0
            self.op_mode_power = 0.0
            self.op_mode_waste_heat = 0.0
            return
        
        if cond_inlet_node.Press <= 0.0:
            cond_inlet_node.Press = state.data_envr.OutBaroPress
        
        if self.condenser_type == CondenserType.AIRCOOLED:
            self.cond_inlet_temp = cond_inlet_node.Temp
        elif self.condenser_type == CondenserType.EVAPCOOLED:
            self.cond_inlet_temp = PsyTwbFnTdbWPb(
                state, cond_inlet_node.Temp, cond_inlet_node.HumRat, cond_inlet_node.Press, "CoilCoolingDXCurveFitOperatingMode::CalcOperatingMode"
            )
        
        this_speed.amb_pressure = cond_inlet_node.Press
        this_speed.AirMassFlow = inlet_node.MassFlowRate
        
        if fan_op == FanOp.Cycling and speed_num == 1:
            if speed_ratio > 0.0:
                this_speed.AirMassFlow = this_speed.AirMassFlow / speed_ratio
            else:
                this_speed.AirMassFlow = 0.0
        elif speed_num > 1:
            this_speed.AirMassFlow = state.data_hvac_globals.MSHPMassFlowRateHigh
        
        this_speed.AirMassFlow *= this_speed.active_fraction_of_face_coil_area
        
        if this_speed.RatedAirMassFlowRate > 0.0:
            this_speed.AirFF = this_speed.AirMassFlow / this_speed.RatedAirMassFlowRate
        else:
            this_speed.AirFF = 0.0
        
        this_speed.calc_speed_output(state, inlet_node, outlet_node, speed_ratio, fan_op, self.cond_inlet_temp)
        
        if this_speed.adjust_for_face_area:
            this_speed.AirMassFlow /= this_speed.active_fraction_of_face_coil_area
            let corrected_enthalpy = (
                (1.0 - this_speed.active_fraction_of_face_coil_area) * inlet_node.Enthalpy +
                this_speed.active_fraction_of_face_coil_area * outlet_node.Enthalpy
            )
            var corrected_hum_rat = (
                (1.0 - this_speed.active_fraction_of_face_coil_area) * inlet_node.HumRat +
                this_speed.active_fraction_of_face_coil_area * outlet_node.HumRat
            )
            var corrected_temp = PsyTdbFnHW(corrected_enthalpy, corrected_hum_rat)
            
            if corrected_temp < PsyTsatFnHPb(state, corrected_enthalpy, inlet_node.Press, routine_name):
                corrected_temp = PsyTsatFnHPb(state, corrected_enthalpy, inlet_node.Press, routine_name)
                corrected_hum_rat = PsyWFnTdbH(state, corrected_temp, corrected_enthalpy, routine_name)
            
            outlet_node.Temp = corrected_temp
            outlet_node.HumRat = corrected_hum_rat
            outlet_node.Enthalpy = corrected_enthalpy
        
        let out_speed1_hum_rat = outlet_node.HumRat
        let out_speed1_enthalpy = outlet_node.Enthalpy
        
        if fan_op == FanOp.Continuous:
            outlet_node.HumRat = outlet_node.HumRat * speed_ratio + (1.0 - speed_ratio) * inlet_node.HumRat
            outlet_node.Enthalpy = outlet_node.Enthalpy * speed_ratio + (1.0 - speed_ratio) * inlet_node.Enthalpy
            outlet_node.Temp = PsyTdbFnHW(outlet_node.Enthalpy, outlet_node.HumRat)
            
            let tsat = PsyTsatFnHPb(state, outlet_node.Enthalpy, inlet_node.Press, routine_name)
            if outlet_node.Temp < tsat:
                outlet_node.Temp = tsat
                outlet_node.HumRat = PsyWFnTdbH(state, tsat, outlet_node.Enthalpy)
        
        self.op_mode_rtf = this_speed.RTF
        if (not self.apply_part_load_fraction_all_speeds) and (speed_num > 1):
            self.op_mode_power = this_speed.fullLoadPower * speed_ratio
        else:
            self.op_mode_power = this_speed.fullLoadPower * this_speed.RTF
        self.op_mode_waste_heat = this_speed.fullLoadWasteHeat * this_speed.RTF
        
        if (speed_num > 1) and (speed_ratio < 1.0) and not single_mode:
            var lower_speed = Pointer[CoilCoolingDXCurveFitSpeed].address_of(self.speeds[math_max(speed_num - 2, 0)])
            lower_speed.AirMassFlow = state.data_hvac_globals.MSHPMassFlowRateLow * lower_speed.active_fraction_of_face_coil_area
            
            lower_speed.calc_speed_output(state, inlet_node, outlet_node, 1.0, fan_op, self.cond_inlet_temp)
            
            if lower_speed.adjust_for_face_area:
                lower_speed.AirMassFlow /= lower_speed.active_fraction_of_face_coil_area
                let corrected_enthalpy = (
                    (1.0 - lower_speed.active_fraction_of_face_coil_area) * inlet_node.Enthalpy +
                    lower_speed.active_fraction_of_face_coil_area * outlet_node.Enthalpy
                )
                var corrected_hum_rat = (
                    (1.0 - lower_speed.active_fraction_of_face_coil_area) * inlet_node.HumRat +
                    lower_speed.active_fraction_of_face_coil_area * outlet_node.HumRat
                )
                var corrected_temp = PsyTdbFnHW(corrected_enthalpy, corrected_hum_rat)
                
                if corrected_temp < PsyTsatFnHPb(state, corrected_enthalpy, inlet_node.Press, routine_name):
                    corrected_temp = PsyTsatFnHPb(state, corrected_enthalpy, inlet_node.Press, routine_name)
                    corrected_hum_rat = PsyWFnTdbH(state, corrected_temp, corrected_enthalpy, routine_name)
                
                outlet_node.Temp = corrected_temp
                outlet_node.HumRat = corrected_hum_rat
                outlet_node.Enthalpy = corrected_enthalpy
            
            outlet_node.HumRat = (
                (out_speed1_hum_rat * speed_ratio * this_speed.AirMassFlow + (1.0 - speed_ratio) * outlet_node.HumRat * lower_speed.AirMassFlow) /
                inlet_node.MassFlowRate
            )
            outlet_node.Enthalpy = (
                (out_speed1_enthalpy * speed_ratio * this_speed.AirMassFlow + (1.0 - speed_ratio) * outlet_node.Enthalpy * lower_speed.AirMassFlow) /
                inlet_node.MassFlowRate
            )
            outlet_node.Temp = PsyTdbFnHW(outlet_node.Enthalpy, outlet_node.HumRat)
            
            if not self.apply_part_load_fraction_all_speeds:
                self.op_mode_power += (1.0 - speed_ratio) * lower_speed.fullLoadPower
            else:
                self.op_mode_power += (1.0 - this_speed.RTF) * lower_speed.fullLoadPower
            
            self.op_mode_waste_heat += (1.0 - this_speed.RTF) * lower_speed.fullLoadWasteHeat
            self.op_mode_rtf = 1.0

    fn get_current_evap_cond_pump_power(self, speed_num: Int) -> Float64:
        let this_speed = Pointer[CoilCoolingDXCurveFitSpeed].address_of(self.speeds[math_max(speed_num - 1, 0)])
        let power_fraction = this_speed.evap_condenser_pump_power_fraction
        return self.nominal_evaporative_pump_power * power_fraction
