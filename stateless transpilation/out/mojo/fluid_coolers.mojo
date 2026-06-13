from math import exp, expm1, pow

enum PerfInputMethod:
    INVALID = -1
    NOMINAL_CAPACITY = 0
    U_FACTOR = 1
    NUM = 2

struct FluidCoolerspecs:
    var name: String
    var fluid_cooler_type: Int
    var performance_input_method_num: PerfInputMethod
    var available: Bool
    var on: Bool
    var design_water_flow_rate: Float64
    var design_water_flow_rate_was_auto_sized: Bool
    var des_water_mass_flow_rate: Float64
    var high_speed_air_flow_rate: Float64
    var high_speed_air_flow_rate_was_auto_sized: Bool
    var high_speed_fan_power: Float64
    var high_speed_fan_power_was_auto_sized: Bool
    var high_speed_fluid_cooler_ua: Float64
    var high_speed_fluid_cooler_ua_was_auto_sized: Bool
    var low_speed_air_flow_rate: Float64
    var low_speed_air_flow_rate_was_auto_sized: Bool
    var low_speed_air_flow_rate_sizing_factor: Float64
    var low_speed_fan_power: Float64
    var low_speed_fan_power_was_auto_sized: Bool
    var low_speed_fan_power_sizing_factor: Float64
    var low_speed_fluid_cooler_ua: Float64
    var low_speed_fluid_cooler_ua_was_auto_sized: Bool
    var low_speed_fluid_cooler_ua_sizing_factor: Float64
    var design_entering_water_temp: Float64
    var design_leaving_water_temp: Float64
    var design_entering_air_temp: Float64
    var design_entering_air_wet_bulb_temp: Float64
    var fluid_cooler_mass_flow_rate_multiplier: Float64
    var fluid_cooler_nominal_capacity: Float64
    var fluid_cooler_low_speed_nom_cap: Float64
    var fluid_cooler_low_speed_nom_cap_was_auto_sized: Bool
    var fluid_cooler_low_speed_nom_cap_sizing_factor: Float64
    var water_inlet_node_num: Int
    var water_outlet_node_num: Int
    var outdoor_air_inlet_node_num: Int
    var high_mass_flow_error_count: Int
    var high_mass_flow_error_index: Int
    var outlet_water_temp_error_count: Int
    var outlet_water_temp_error_index: Int
    var small_water_mass_flow_error_count: Int
    var small_water_mass_flow_error_index: Int
    var wmfr_less_than_min_avail_err_count: Int
    var wmfr_less_than_min_avail_err_index: Int
    var wmfr_greater_than_max_avail_err_count: Int
    var wmfr_greater_than_max_avail_err_index: Int
    var plant_loc: PlantLocation
    var one_time_init_flag: Bool
    var begin_envrn_init: Bool
    var inlet_water_temp: Float64
    var outlet_water_temp: Float64
    var water_mass_flow_rate: Float64
    var qactual: Float64
    var fan_power: Float64
    var fan_energy: Float64
    var water_temp: Float64
    var air_temp: Float64
    var air_hum_rat: Float64
    var air_press: Float64
    var air_wet_bulb: Float64
    var index_in_array: Int

    fn __init__(inout self):
        self.name = ""
        self.fluid_cooler_type = 0
        self.performance_input_method_num = PerfInputMethod.NOMINAL_CAPACITY
        self.available = True
        self.on = True
        self.design_water_flow_rate = 0.0
        self.design_water_flow_rate_was_auto_sized = False
        self.des_water_mass_flow_rate = 0.0
        self.high_speed_air_flow_rate = 0.0
        self.high_speed_air_flow_rate_was_auto_sized = False
        self.high_speed_fan_power = 0.0
        self.high_speed_fan_power_was_auto_sized = False
        self.high_speed_fluid_cooler_ua = 0.0
        self.high_speed_fluid_cooler_ua_was_auto_sized = False
        self.low_speed_air_flow_rate = 0.0
        self.low_speed_air_flow_rate_was_auto_sized = False
        self.low_speed_air_flow_rate_sizing_factor = 0.0
        self.low_speed_fan_power = 0.0
        self.low_speed_fan_power_was_auto_sized = False
        self.low_speed_fan_power_sizing_factor = 0.0
        self.low_speed_fluid_cooler_ua = 0.0
        self.low_speed_fluid_cooler_ua_was_auto_sized = False
        self.low_speed_fluid_cooler_ua_sizing_factor = 0.0
        self.design_entering_water_temp = 0.0
        self.design_leaving_water_temp = 0.0
        self.design_entering_air_temp = 0.0
        self.design_entering_air_wet_bulb_temp = 0.0
        self.fluid_cooler_mass_flow_rate_multiplier = 0.0
        self.fluid_cooler_nominal_capacity = 0.0
        self.fluid_cooler_low_speed_nom_cap = 0.0
        self.fluid_cooler_low_speed_nom_cap_was_auto_sized = False
        self.fluid_cooler_low_speed_nom_cap_sizing_factor = 0.0
        self.water_inlet_node_num = 0
        self.water_outlet_node_num = 0
        self.outdoor_air_inlet_node_num = 0
        self.high_mass_flow_error_count = 0
        self.high_mass_flow_error_index = 0
        self.outlet_water_temp_error_count = 0
        self.outlet_water_temp_error_index = 0
        self.small_water_mass_flow_error_count = 0
        self.small_water_mass_flow_error_index = 0
        self.wmfr_less_than_min_avail_err_count = 0
        self.wmfr_less_than_min_avail_err_index = 0
        self.wmfr_greater_than_max_avail_err_count = 0
        self.wmfr_greater_than_max_avail_err_index = 0
        self.plant_loc = PlantLocation()
        self.one_time_init_flag = True
        self.begin_envrn_init = True
        self.inlet_water_temp = 0.0
        self.outlet_water_temp = 0.0
        self.water_mass_flow_rate = 0.0
        self.qactual = 0.0
        self.fan_power = 0.0
        self.fan_energy = 0.0
        self.water_temp = 0.0
        self.air_temp = 0.0
        self.air_hum_rat = 0.0
        self.air_press = 0.0
        self.air_wet_bulb = 0.0
        self.index_in_array = 0

    fn one_time_init(inout self, state: StateRef) -> None:
        pass

    fn one_time_init_new(inout self, state: StateRef) -> None:
        self.setup_output_vars(state)
        var errors_found = False
        plant_utilities_scan_plant_loops_for_object(state, self.name, self.fluid_cooler_type, self.plant_loc, errors_found)
        if errors_found:
            utility_routines_show_fatal_error(state, "InitFluidCooler: Program terminated due to previous condition(s).")

    fn init_each_environment(inout self, state: StateRef) -> None:
        let routine_name = "FluidCoolerspecs::initEachEnvironment"
        let rho = self.plant_loc.loop.glycol.get_density(state, CONSTANT_INIT_CONV_TEMP, routine_name)
        self.des_water_mass_flow_rate = self.design_water_flow_rate * rho
        plant_utilities_init_component_nodes(state, 0.0, self.des_water_mass_flow_rate, self.water_inlet_node_num, self.water_outlet_node_num)

    fn initialize(inout self, state: StateRef) -> None:
        if self.begin_envrn_init and state.data_global.begin_envrn_flag and state.data_plnt.plant_first_sizes_okay_to_finalize:
            self.init_each_environment(state)
            self.begin_envrn_init = False

        if not state.data_global.begin_envrn_flag:
            self.begin_envrn_init = True

        self.water_temp = get_node_temp(state, self.water_inlet_node_num)

        if self.outdoor_air_inlet_node_num != 0:
            self.air_temp = get_node_temp(state, self.outdoor_air_inlet_node_num)
            self.air_hum_rat = get_node_hum_rat(state, self.outdoor_air_inlet_node_num)
            self.air_press = get_node_press(state, self.outdoor_air_inlet_node_num)
            self.air_wet_bulb = get_node_out_air_wet_bulb(state, self.outdoor_air_inlet_node_num)
        else:
            self.air_temp = state.data_envrn.out_dry_bulb_temp
            self.air_hum_rat = state.data_envrn.out_hum_rat
            self.air_press = state.data_envrn.out_baro_press
            self.air_wet_bulb = state.data_envrn.out_wet_bulb_temp

        self.water_mass_flow_rate = plant_utilities_regulate_condenser_comp_flow_req_op(
            state, self.plant_loc, self.des_water_mass_flow_rate * self.fluid_cooler_mass_flow_rate_multiplier
        )

        plant_utilities_set_component_flow_rate(state, self.water_mass_flow_rate, self.water_inlet_node_num, self.water_outlet_node_num, self.plant_loc)

    fn setup_output_vars(inout self, state: StateRef) -> None:
        output_processor_setup_output_variable(state, "Cooling Tower Inlet Temperature", "C", self.inlet_water_temp)
        output_processor_setup_output_variable(state, "Cooling Tower Outlet Temperature", "C", self.outlet_water_temp)
        output_processor_setup_output_variable(state, "Cooling Tower Mass Flow Rate", "kg/s", self.water_mass_flow_rate)
        output_processor_setup_output_variable(state, "Cooling Tower Heat Transfer Rate", "W", self.qactual)
        output_processor_setup_output_variable(state, "Cooling Tower Fan Electricity Rate", "W", self.fan_power)
        output_processor_setup_output_variable(state, "Cooling Tower Fan Electricity Energy", "J", self.fan_energy)

    fn size(inout self, state: StateRef) -> None:
        let max_ite = 500
        let acc = 0.0001
        let called_from = "SizeFluidCooler"

        var tmp_design_water_flow_rate = self.design_water_flow_rate
        var tmp_high_speed_air_flow_rate = self.high_speed_air_flow_rate
        let plt_siz_cond_num = self.plant_loc.loop.plant_siz_num

        if self.design_water_flow_rate_was_auto_sized:
            if plt_siz_cond_num > 0:
                if get_plant_siz_data_des_vol_flow_rate(state, plt_siz_cond_num) >= HVAC_SMALL_WATER_VOL_FLOW:
                    tmp_design_water_flow_rate = get_plant_siz_data_des_vol_flow_rate(state, plt_siz_cond_num)
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.design_water_flow_rate = tmp_design_water_flow_rate
                else:
                    tmp_design_water_flow_rate = 0.0
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.design_water_flow_rate = tmp_design_water_flow_rate
                self.design_leaving_water_temp = get_plant_siz_data_exit_temp(state, plt_siz_cond_num)

        plant_utilities_register_plant_comp_design_flow(state, self.water_inlet_node_num, tmp_design_water_flow_rate)

        if self.high_speed_fan_power_was_auto_sized:
            if self.performance_input_method_num == PerfInputMethod.NOMINAL_CAPACITY:
                var tmp_high_speed_fan_power = 0.0105 * self.fluid_cooler_nominal_capacity
                if state.data_plnt.plant_first_sizes_okay_to_finalize:
                    self.high_speed_fan_power = tmp_high_speed_fan_power

        if self.high_speed_air_flow_rate_was_auto_sized:
            if self.performance_input_method_num == PerfInputMethod.NOMINAL_CAPACITY:
                tmp_high_speed_air_flow_rate = (
                    self.fluid_cooler_nominal_capacity / (self.design_entering_water_temp - self.design_entering_air_temp) * 4.0
                )
                if state.data_plnt.plant_first_sizes_okay_to_finalize:
                    self.high_speed_air_flow_rate = tmp_high_speed_air_flow_rate

        if self.low_speed_air_flow_rate_was_auto_sized and state.data_plnt.plant_first_sizes_okay_to_finalize:
            self.low_speed_air_flow_rate = self.low_speed_air_flow_rate_sizing_factor * self.high_speed_air_flow_rate

        if self.low_speed_fan_power_was_auto_sized and state.data_plnt.plant_first_sizes_okay_to_finalize:
            self.low_speed_fan_power = self.low_speed_fan_power_sizing_factor * self.high_speed_fan_power

        if self.low_speed_fluid_cooler_ua_was_auto_sized and state.data_plnt.plant_first_sizes_okay_to_finalize:
            self.low_speed_fluid_cooler_ua = self.low_speed_fluid_cooler_ua_sizing_factor * self.high_speed_fluid_cooler_ua

    fn validate_single_speed_inputs(
        inout self, state: StateRef, current_module_object: String, alph_array: StringArray,
        numeric_field_names: StringArray, alpha_field_names: StringArray
    ) -> Bool:
        var errors_found = False

        if self.design_entering_water_temp <= 0.0:
            utility_routines_show_severe_error(state, "Invalid water temp")
            errors_found = True

        return errors_found

    fn validate_two_speed_inputs(
        inout self, state: StateRef, current_module_object: String, alph_array: StringArray,
        numeric_field_names: StringArray, alpha_field_names: StringArray
    ) -> Bool:
        var errors_found = False
        return errors_found

    fn calc_single_speed(inout self, state: StateRef) -> None:
        let routine_name = "SingleSpeedFluidCooler"

        self.qactual = 0.0
        self.fan_power = 0.0
        self.outlet_water_temp = get_node_temp(state, self.water_inlet_node_num)

        var temp_set_point = 0.0
        if is_loop_demand_single_set_point(state, self.plant_loc):
            temp_set_point = get_loop_temp_set_point(state, self.plant_loc)
        else:
            temp_set_point = get_loop_temp_set_point_hi(state, self.plant_loc)

        if self.water_mass_flow_rate <= DATA_BRANCH_AIR_LOOP_PLANT_MASS_FLOW_TOLERANCE:
            return

        if self.outlet_water_temp < temp_set_point:
            return

        let outlet_water_temp_off = get_node_temp(state, self.water_inlet_node_num)
        self.outlet_water_temp = outlet_water_temp_off

        let ua_design = self.high_speed_fluid_cooler_ua
        let air_flow_rate = self.high_speed_air_flow_rate
        let fan_power_on = self.high_speed_fan_power

        calc_fluid_cooler_outlet(state, self.index_in_array, self.water_mass_flow_rate, air_flow_rate, ua_design, self)

        if self.outlet_water_temp <= temp_set_point:
            var fan_mode_frac = 0.0
            if self.outlet_water_temp != outlet_water_temp_off:
                fan_mode_frac = (temp_set_point - outlet_water_temp_off) / (self.outlet_water_temp - outlet_water_temp_off)
            self.fan_power = max(fan_mode_frac * fan_power_on, 0.0)
            self.outlet_water_temp = temp_set_point
        else:
            self.fan_power = fan_power_on

        let cp_water = get_glycol_specific_heat(state, get_node_temp(state, self.water_inlet_node_num), routine_name)
        self.qactual = self.water_mass_flow_rate * cp_water * (
            get_node_temp(state, self.water_inlet_node_num) - self.outlet_water_temp
        )

    fn calc_two_speed(inout self, state: StateRef) -> None:
        let routine_name = "TwoSpeedFluidCooler"

        self.qactual = 0.0
        self.fan_power = 0.0
        self.outlet_water_temp = get_node_temp(state, self.water_inlet_node_num)

        var temp_set_point = 0.0
        if is_loop_demand_single_set_point(state, self.plant_loc):
            temp_set_point = get_loop_temp_set_point(state, self.plant_loc)
        else:
            temp_set_point = get_loop_temp_set_point_hi(state, self.plant_loc)

        if (self.water_mass_flow_rate <= DATA_BRANCH_AIR_LOOP_PLANT_MASS_FLOW_TOLERANCE or
            is_flow_lock_unlocked(state, self.plant_loc)):
            return

        self.water_mass_flow_rate = get_node_mass_flow_rate(state, self.water_inlet_node_num)
        let outlet_water_temp_off = get_node_temp(state, self.water_inlet_node_num)
        var outlet_water_temp_1st_stage = outlet_water_temp_off
        var outlet_water_temp_2nd_stage = outlet_water_temp_off
        var fan_mode_frac = 0.0

        if outlet_water_temp_off < temp_set_point:
            return

        let ua_design_low = self.low_speed_fluid_cooler_ua
        let air_flow_rate_low = self.low_speed_air_flow_rate
        let fan_power_low = self.low_speed_fan_power

        calc_fluid_cooler_outlet(state, self.index_in_array, self.water_mass_flow_rate, air_flow_rate_low, ua_design_low, self)
        outlet_water_temp_1st_stage = self.outlet_water_temp

        if outlet_water_temp_1st_stage <= temp_set_point:
            if outlet_water_temp_1st_stage != outlet_water_temp_off:
                fan_mode_frac = (temp_set_point - outlet_water_temp_off) / (outlet_water_temp_1st_stage - outlet_water_temp_off)
            self.fan_power = fan_mode_frac * fan_power_low
            self.outlet_water_temp = temp_set_point
            self.qactual *= fan_mode_frac
        else:
            let ua_design_high = self.high_speed_fluid_cooler_ua
            let air_flow_rate_high = self.high_speed_air_flow_rate
            let fan_power_high = self.high_speed_fan_power

            calc_fluid_cooler_outlet(state, self.index_in_array, self.water_mass_flow_rate, air_flow_rate_high, ua_design_high, self)
            outlet_water_temp_2nd_stage = self.outlet_water_temp

            if outlet_water_temp_2nd_stage <= temp_set_point and ua_design_high > 0.0:
                fan_mode_frac = (temp_set_point - outlet_water_temp_1st_stage) / (outlet_water_temp_2nd_stage - outlet_water_temp_1st_stage)
                self.fan_power = max((fan_mode_frac * fan_power_high) + (1.0 - fan_mode_frac) * fan_power_low, 0.0)
                self.outlet_water_temp = temp_set_point
            else:
                self.outlet_water_temp = outlet_water_temp_2nd_stage
                self.fan_power = fan_power_high

        let cp_water = get_glycol_specific_heat(state, get_node_temp(state, self.water_inlet_node_num), routine_name)
        self.qactual = self.water_mass_flow_rate * cp_water * (
            get_node_temp(state, self.water_inlet_node_num) - self.outlet_water_temp
        )

    fn simulate(inout self, state: StateRef, called_from_location: PlantLocation, first_hvac_iteration: Bool, cur_load: Float64, run_flag: Bool) -> None:
        self.initialize(state)
        if self.fluid_cooler_type == DATA_PLANT_FLUID_COOLER_SINGLE_SPD:
            self.calc_single_speed(state)
        else:
            self.calc_two_speed(state)
        self.update(state)
        self.report(state, run_flag)

    fn on_init_loop_equip(inout self, state: StateRef, called_from_location: PlantLocation) -> None:
        self.initialize(state)
        self.size(state)

    fn get_design_capacities(inout self, state: StateRef, called_from_location: PlantLocation) -> Tuple[Float64, Float64, Float64]:
        return self.fluid_cooler_nominal_capacity, 0.0, self.fluid_cooler_nominal_capacity

    fn update(inout self, state: StateRef) -> None:
        let water_outlet_node = self.water_outlet_node_num
        set_node_temp(state, water_outlet_node, self.outlet_water_temp)

        if is_flow_lock_unlocked(state, self.plant_loc) or is_warmup_flag(state):
            return

        if get_node_mass_flow_rate(state, water_outlet_node) > self.des_water_mass_flow_rate * self.fluid_cooler_mass_flow_rate_multiplier:
            self.high_mass_flow_error_count += 1

        let loop_min_temp = get_loop_min_temp(state, self.plant_loc)
        if self.outlet_water_temp < loop_min_temp and self.water_mass_flow_rate > 0.0:
            self.outlet_water_temp_error_count += 1

        if self.water_mass_flow_rate > 0.0 and self.water_mass_flow_rate <= DATA_BRANCH_AIR_LOOP_PLANT_MASS_FLOW_TOLERANCE:
            self.small_water_mass_flow_error_count += 1

    fn report(inout self, state: StateRef, run_flag: Bool) -> None:
        let reporting_constant = get_time_step_sys_sec(state)
        if not run_flag:
            self.inlet_water_temp = get_node_temp(state, self.water_inlet_node_num)
            self.outlet_water_temp = get_node_temp(state, self.water_inlet_node_num)
            self.qactual = 0.0
            self.fan_power = 0.0
            self.fan_energy = 0.0
        else:
            self.inlet_water_temp = get_node_temp(state, self.water_inlet_node_num)
            self.fan_energy = self.fan_power * reporting_constant

struct PlantLocation:
    fn __init__(inout self):
        pass

struct StateRef:
    fn __init__(inout self):
        pass

struct StringArray:
    fn __init__(inout self):
        pass

struct FluidCoolersData:
    var get_fluid_cooler_input_flag: Bool
    var num_simple_fluid_coolers: Int
    var simple_fluid_cooler: DynamicVector[FluidCoolerspecs]
    var unique_simple_fluid_cooler_names: Dict[String, String]

    fn __init__(inout self):
        self.get_fluid_cooler_input_flag = True
        self.num_simple_fluid_coolers = 0
        self.simple_fluid_cooler = DynamicVector[FluidCoolerspecs]()
        self.unique_simple_fluid_cooler_names = Dict[String, String]()

fn get_fluid_cooler_input(state: StateRef) -> None:
    pass

fn calc_fluid_cooler_outlet(
    state: StateRef, fluid_cooler_num: Int, water_mass_flow_rate: Float64,
    air_flow_rate: Float64, ua_design: Float64, inout cooler: FluidCoolerspecs
) -> None:
    let routine_name = "CalcFluidCoolerOutlet"

    if ua_design == 0.0:
        return

    let inlet_water_temp = cooler.water_temp
    cooler.outlet_water_temp = inlet_water_temp
    let inlet_air_temp = cooler.air_temp

    let air_density = psy_rho_air_fn_pb_tdb_w(state, cooler.air_press, inlet_air_temp, cooler.air_hum_rat)
    let air_mass_flow_rate = air_flow_rate * air_density
    let cp_air = psy_cp_air_fn_w(cooler.air_hum_rat)
    let cp_water = get_glycol_specific_heat(state, inlet_water_temp, routine_name)

    let mdot_cp_water = water_mass_flow_rate * cp_water
    let air_capacity = air_mass_flow_rate * cp_air

    let capacity_ratio_min = min(air_capacity, mdot_cp_water)
    let capacity_ratio_max = max(air_capacity, mdot_cp_water)
    let capacity_ratio = capacity_ratio_min / capacity_ratio_max if capacity_ratio_max > 0 else 0.0

    let num_transfer_units = ua_design / capacity_ratio_min if capacity_ratio_min > 0 else 0.0
    let eta = pow(num_transfer_units, 0.22)
    let a = capacity_ratio * num_transfer_units / eta if eta > 0 else 0.0
    let effectiveness = 1.0 - exp(expm1(-a) / (capacity_ratio / eta if eta > 0 else 1.0))

    let q_actual = effectiveness * capacity_ratio_min * (inlet_water_temp - inlet_air_temp)

    if q_actual >= 0.0:
        cooler.outlet_water_temp = inlet_water_temp - q_actual / mdot_cp_water if mdot_cp_water > 0 else inlet_water_temp
    else:
        cooler.outlet_water_temp = inlet_water_temp

fn utility_routines_show_fatal_error(state: StateRef, message: String) -> None:
    pass

fn utility_routines_show_severe_error(state: StateRef, message: String) -> None:
    pass

fn plant_utilities_scan_plant_loops_for_object(state: StateRef, name: String, cooler_type: Int, inout plant_loc: PlantLocation, inout errors: Bool) -> None:
    pass

fn plant_utilities_init_component_nodes(state: StateRef, flow_min: Float64, flow_max: Float64, inlet_node: Int, outlet_node: Int) -> None:
    pass

fn plant_utilities_regulate_condenser_comp_flow_req_op(state: StateRef, plant_loc: PlantLocation, design_flow: Float64) -> Float64:
    return design_flow

fn plant_utilities_set_component_flow_rate(state: StateRef, flow: Float64, inlet_node: Int, outlet_node: Int, plant_loc: PlantLocation) -> None:
    pass

fn plant_utilities_register_plant_comp_design_flow(state: StateRef, inlet_node: Int, design_flow: Float64) -> None:
    pass

fn output_processor_setup_output_variable(state: StateRef, variable_name: String, units: String, var value: Float64) -> None:
    pass

fn get_node_temp(state: StateRef, node_num: Int) -> Float64:
    return 0.0

fn get_node_hum_rat(state: StateRef, node_num: Int) -> Float64:
    return 0.0

fn get_node_press(state: StateRef, node_num: Int) -> Float64:
    return 0.0

fn get_node_out_air_wet_bulb(state: StateRef, node_num: Int) -> Float64:
    return 0.0

fn get_node_mass_flow_rate(state: StateRef, node_num: Int) -> Float64:
    return 0.0

fn set_node_temp(state: StateRef, node_num: Int, temp: Float64) -> None:
    pass

fn is_loop_demand_single_set_point(state: StateRef, plant_loc: PlantLocation) -> Bool:
    return True

fn get_loop_temp_set_point(state: StateRef, plant_loc: PlantLocation) -> Float64:
    return 0.0

fn get_loop_temp_set_point_hi(state: StateRef, plant_loc: PlantLocation) -> Float64:
    return 0.0

fn is_flow_lock_unlocked(state: StateRef, plant_loc: PlantLocation) -> Bool:
    return False

fn is_warmup_flag(state: StateRef) -> Bool:
    return False

fn get_loop_min_temp(state: StateRef, plant_loc: PlantLocation) -> Float64:
    return 0.0

fn get_time_step_sys_sec(state: StateRef) -> Float64:
    return 0.0

fn get_glycol_specific_heat(state: StateRef, temp: Float64, routine_name: String) -> Float64:
    return 0.0

fn psy_rho_air_fn_pb_tdb_w(state: StateRef, press: Float64, dry_bulb: Float64, humidity_ratio: Float64) -> Float64:
    return 0.0

fn psy_cp_air_fn_w(humidity_ratio: Float64) -> Float64:
    return 0.0

fn get_plant_siz_data_des_vol_flow_rate(state: StateRef, siz_num: Int) -> Float64:
    return 0.0

fn get_plant_siz_data_exit_temp(state: StateRef, siz_num: Int) -> Float64:
    return 0.0

let CONSTANT_INIT_CONV_TEMP = 20.0
let HVAC_SMALL_WATER_VOL_FLOW = 1e-6
let DATA_BRANCH_AIR_LOOP_PLANT_MASS_FLOW_TOLERANCE = 0.001
let DATA_PLANT_FLUID_COOLER_SINGLE_SPD = 0
let DATA_PLANT_FLUID_COOLER_TWO_SPD = 1
