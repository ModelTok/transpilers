# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): mojo struct with nested data fields
# - PlantComponent: base struct with abstract methods
# - PlantLocation: structure with loop reference
# - Schedule: schedule struct with methods get_max_val, get_current_val, get_day_vals
# - DataPlant.PlantEquipmentType: enum for plant equipment type
# - PlantUtilities.set_component_flow_rate: function signature
# - PlantUtilities.init_component_nodes: function signature
# - PlantUtilities.register_plant_comp_design_flow: function signature
# - PlantUtilities.scan_plant_loops_for_object: function signature
# - Node.get_only_single_node: function for node lookup
# - Node.test_comp_set: function for component testing
# - Sched.get_schedule: function to retrieve schedule
# - show_fatal_error, show_severe_item_not_found: error reporting functions
# - util_make_upper: string upper case function
# - get_enum_value: enum parsing function
# - setup_output_variable, setup_ems_actuator: output setup functions
# - DataEnvironment.StdPressureSeaLevel: constant
# - Constant.InitConvTemp: constant
# - Constant.iHoursInDay: constant

from math import fabs
from collections import InlineArray


alias PLANT_LOOP_FLUID_TYPE_NAMES_UC = InlineArray[StringLiteral, 2]("WATER", "STEAM")


@value
struct PlantLoopFluidType:
    """Plant loop fluid type enumeration."""
    value: Int32

    alias INVALID = PlantLoopFluidType(-1)
    alias WATER = PlantLoopFluidType(0)
    alias STEAM = PlantLoopFluidType(1)
    alias NUM = PlantLoopFluidType(2)

    fn __eq__(self, other: PlantLoopFluidType) -> Bool:
        return self.value == other.value


@value
struct PlantProfileData:
    """Plant load profile component data."""
    var name: String
    var type: Int32
    var plant_loc: PlantLocation
    var fluid_type: PlantLoopFluidType
    var init: Bool
    var init_sizing: Bool
    var inlet_node: Int32
    var inlet_temp: Float64
    var outlet_node: Int32
    var outlet_temp: Float64
    var load_sched: Schedule
    var ems_override_power: Bool
    var ems_power_value: Float64
    var peak_vol_flow_rate: Float64
    var flow_rate_frac_sched: Schedule
    var vol_flow_rate: Float64
    var mass_flow_rate: Float64
    var deg_of_subcooling: Float64
    var loop_subcool_return: Float64
    var ems_override_mass_flow: Bool
    var ems_mass_flow_value: Float64
    var power: Float64
    var energy: Float64
    var heating_energy: Float64
    var cooling_energy: Float64

    fn __init__(
        inout self,
        name: String = "",
        type: Int32 = -1,
        plant_loc: PlantLocation = PlantLocation(),
        fluid_type: PlantLoopFluidType = PlantLoopFluidType.INVALID,
    ):
        self.name = name
        self.type = type
        self.plant_loc = plant_loc
        self.fluid_type = fluid_type
        self.init = True
        self.init_sizing = True
        self.inlet_node = 0
        self.inlet_temp = 0.0
        self.outlet_node = 0
        self.outlet_temp = 0.0
        self.load_sched = Schedule()
        self.ems_override_power = False
        self.ems_power_value = 0.0
        self.peak_vol_flow_rate = 0.0
        self.flow_rate_frac_sched = Schedule()
        self.vol_flow_rate = 0.0
        self.mass_flow_rate = 0.0
        self.deg_of_subcooling = 0.0
        self.loop_subcool_return = 0.0
        self.ems_override_mass_flow = False
        self.ems_mass_flow_value = 0.0
        self.power = 0.0
        self.energy = 0.0
        self.heating_energy = 0.0
        self.cooling_energy = 0.0

    @staticmethod
    fn factory(state: EnergyPlusData, object_name: String) -> Self:
        """Factory method to create or retrieve PlantProfileData."""
        if state.data_plant_load_profile.get_plant_load_profile_input_flag:
            get_plant_profile_input(state)
            state.data_plant_load_profile.get_plant_load_profile_input_flag = False

        for plant_profile in state.data_plant_load_profile.plant_profile:
            if plant_profile.name == object_name:
                return plant_profile

        show_fatal_error(
            state,
            "PlantLoadProfile::factory: Error getting inputs for pipe named: " + object_name,
        )
        return Self()

    fn on_init_loop_equip(inout self, state: EnergyPlusData, called_from_location: PlantLocation):
        """Initialize plant equipment."""
        self.init_plant_profile(state)

    fn simulate(
        inout self,
        state: EnergyPlusData,
        called_from_location: PlantLocation,
        first_hvac_iteration: Bool,
        inout cur_load: Float64,
        run_flag: Bool,
    ):
        """Simulate the plant load profile."""
        var routine_name = "SimulatePlantProfile"
        var delta_temp = 0.0

        self.init_plant_profile(state)

        if self.fluid_type == PlantLoopFluidType.WATER:
            if self.mass_flow_rate > 0.0:
                var cp = self.plant_loc.loop.glycol.get_specific_heat(
                    state, self.inlet_temp, routine_name
                )
                delta_temp = self.power / (self.mass_flow_rate * cp)
            else:
                self.power = 0.0
                delta_temp = 0.0
            self.outlet_temp = self.inlet_temp - delta_temp

        elif self.fluid_type == PlantLoopFluidType.STEAM:
            if self.mass_flow_rate > 0.0 and self.power > 0.0:
                var enth_steam_in_dry = self.plant_loc.loop.steam.get_sat_enthalpy(
                    state, self.inlet_temp, 1.0, routine_name
                )
                var enth_steam_out_wet = self.plant_loc.loop.steam.get_sat_enthalpy(
                    state, self.inlet_temp, 0.0, routine_name
                )
                var latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                var sat_temp = self.plant_loc.loop.steam.get_sat_temperature(
                    state, state.std_pressure_sea_level, routine_name
                )
                var cp_water = self.plant_loc.loop.glycol.get_specific_heat(
                    state, sat_temp, routine_name
                )

                self.mass_flow_rate = self.power / (
                    latent_heat_steam + self.deg_of_subcooling * cp_water
                )
                plant_utilities_set_component_flow_rate(
                    state, self.mass_flow_rate, self.inlet_node, self.outlet_node, self.plant_loc
                )
                state.data_loop_nodes.node[self.outlet_node].quality = 0.0
                self.outlet_temp = sat_temp - self.loop_subcool_return
            else:
                self.power = 0.0

        self.update_plant_profile(state)
        self.report_plant_profile(state)

    fn init_plant_profile(inout self, state: EnergyPlusData):
        """Initialize plant profile."""
        var routine_name = "InitPlantProfile"
        var fluid_density_init = 0.0

        if state.data_global.begin_envrn_flag and self.init:
            state.data_loop_nodes.node[self.outlet_node].temp = 0.0

            if self.fluid_type == PlantLoopFluidType.WATER:
                fluid_density_init = self.plant_loc.loop.glycol.get_density(
                    state, state.init_conv_temp, routine_name
                )
            else:
                var sat_temp_atm_press = (
                    self.plant_loc.loop.steam.get_sat_temperature(
                        state, state.std_pressure_sea_level, routine_name
                    )
                )
                fluid_density_init = self.plant_loc.loop.steam.get_sat_density(
                    state, sat_temp_atm_press, 1.0, routine_name
                )

            var max_flow_multiplier = self.flow_rate_frac_sched.get_max_val(state)

            plant_utilities_init_component_nodes(
                state,
                0.0,
                self.peak_vol_flow_rate * fluid_density_init * max_flow_multiplier,
                self.inlet_node,
                self.outlet_node,
            )

            self.ems_override_mass_flow = False
            self.ems_mass_flow_value = 0.0
            self.ems_override_power = False
            self.ems_power_value = 0.0
            self.init = False

        if not state.data_global.begin_envrn_flag:
            self.init = True

        self.inlet_temp = state.data_loop_nodes.node[self.inlet_node].temp
        self.power = self.load_sched.get_current_val(state)

        if self.ems_override_power:
            self.power = self.ems_power_value

        if self.fluid_type == PlantLoopFluidType.WATER:
            fluid_density_init = self.plant_loc.loop.glycol.get_density(
                state, self.inlet_temp, routine_name
            )
        else:
            fluid_density_init = self.plant_loc.loop.steam.get_sat_density(
                state, self.inlet_temp, 1.0, routine_name
            )

        self.vol_flow_rate = (
            self.peak_vol_flow_rate * self.flow_rate_frac_sched.get_current_val(state)
        )
        self.mass_flow_rate = self.vol_flow_rate * fluid_density_init

        if self.ems_override_mass_flow:
            self.mass_flow_rate = self.ems_mass_flow_value

        plant_utilities_set_component_flow_rate(
            state, self.mass_flow_rate, self.inlet_node, self.outlet_node, self.plant_loc
        )
        self.vol_flow_rate = self.mass_flow_rate / fluid_density_init

        if self.init_sizing and not state.data_global.sys_sizing_calc:
            plant_utilities_register_plant_comp_design_flow(
                state, self.inlet_node, self.peak_vol_flow_rate
            )

            var this_load_sched = self.load_sched.get_day_vals(state, -1, -1)
            var this_flow_sched = self.flow_rate_frac_sched.get_day_vals(state, -1, -1)
            var plnt_siz_index = self.plant_loc.loop.plant_siz_num
            var plnt_delta_t = 0.0
            var inlet_temp = state.init_conv_temp

            if plnt_siz_index > 0:
                plnt_delta_t = state.data_size.plant_siz_data[plnt_siz_index - 1].delta_t
                inlet_temp = (
                    state.data_size.plant_siz_data[plnt_siz_index - 1].exit_temp
                )

            var plnt_comps = self.plant_loc.loop.plant_coil_object_names
            var cmp_type = self.plant_loc.loop.plant_coil_object_types
            var array_index = -1

            for i in range(len(plnt_comps)):
                if plnt_comps[i] == self.name and cmp_type[i] == self.type:
                    array_index = i
                    break

            if array_index == -1:
                self.plant_loc.loop.plant_coil_object_names.append(self.name)
                self.plant_loc.loop.plant_coil_object_types.append(self.type)

                var tmp_flow_data = InlineArray[Float64, 256](fill=-1.0)
                var hours_in_day = state.hours_in_day
                var time_steps_in_hour = state.time_steps_in_hour
                var flow_data_size = hours_in_day * time_steps_in_hour + 1

                if self.fluid_type == PlantLoopFluidType.WATER:
                    fluid_density_init = self.plant_loc.loop.glycol.get_density(
                        state, inlet_temp, routine_name
                    )
                else:
                    fluid_density_init = self.plant_loc.loop.steam.get_sat_density(
                        state, inlet_temp, 1.0, routine_name
                    )

                var cp = 0.0
                if self.fluid_type == PlantLoopFluidType.WATER:
                    cp = self.plant_loc.loop.glycol.get_specific_heat(
                        state, inlet_temp, routine_name
                    )
                elif self.fluid_type == PlantLoopFluidType.STEAM:
                    var enth_steam_in_dry = (
                        self.plant_loc.loop.steam.get_sat_enthalpy(
                            state, inlet_temp, 1.0, routine_name
                        )
                    )
                    var enth_steam_out_wet = (
                        self.plant_loc.loop.steam.get_sat_enthalpy(
                            state, inlet_temp, 0.0, routine_name
                        )
                    )
                    var latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                    var sat_temp = self.plant_loc.loop.steam.get_sat_temperature(
                        state, state.std_pressure_sea_level, routine_name
                    )
                    cp = self.plant_loc.loop.glycol.get_specific_heat(
                        state, sat_temp, routine_name
                    )

                    self.mass_flow_rate = self.power / (
                        latent_heat_steam + self.deg_of_subcooling * cp
                    )
                    plant_utilities_set_component_flow_rate(
                        state,
                        self.mass_flow_rate,
                        self.inlet_node,
                        self.outlet_node,
                        self.plant_loc,
                    )
                    state.data_loop_nodes.node[self.outlet_node].quality = 0.0

                for i in range(1, len(this_load_sched) + 1):
                    if plnt_delta_t > 0:
                        tmp_flow_data[i] = (
                            this_load_sched[i - 1]
                            / (fluid_density_init * cp * plnt_delta_t)
                        )
                    else:
                        tmp_flow_data[i] = (
                            this_flow_sched[i - 1] * self.peak_vol_flow_rate
                        )

                var plnt_coil_data = self.plant_loc.loop.comp_des_water_flow_rate
                var new_entry_index = len(plnt_coil_data)
                plnt_coil_data.append(tmp_flow_data)

            self.init_sizing = False

    fn update_plant_profile(self, state: EnergyPlusData):
        """Update plant profile node variables."""
        state.data_loop_nodes.node[self.outlet_node].temp = self.outlet_temp

    fn report_plant_profile(inout self, state: EnergyPlusData):
        """Report plant profile variables."""
        var time_step_sys_sec = state.data_hvac_global.time_step_sys_sec

        self.energy = self.power * time_step_sys_sec

        if self.energy >= 0.0:
            self.heating_energy = self.energy
            self.cooling_energy = 0.0
        else:
            self.heating_energy = 0.0
            self.cooling_energy = fabs(self.energy)

    fn one_time_init_new(inout self, state: EnergyPlusData):
        """One-time initialization (new)."""
        if state.data_plnt.plant_loop:
            var err_flag = False
            plant_utilities_scan_plant_loops_for_object(
                state, self.name, self.type, self.plant_loc, err_flag
            )
            if err_flag:
                show_fatal_error(
                    state,
                    "InitPlantProfile: Program terminated for previous conditions.",
                )

    fn one_time_init(self, state: EnergyPlusData):
        """One-time initialization."""
        pass

    fn get_current_power(self, state: EnergyPlusData) -> Float64:
        """Get current power."""
        return self.power


@value
struct PlantLoadProfileData:
    """Global plant load profile data."""
    var get_plant_load_profile_input_flag: Bool
    var num_of_plant_profile: Int32
    var plant_profile: DynamicVector[PlantProfileData]

    fn __init__(inout self):
        self.get_plant_load_profile_input_flag = True
        self.num_of_plant_profile = 0
        self.plant_profile = DynamicVector[PlantProfileData]()

    fn init_constant_state(self, state: EnergyPlusData):
        """Initialize constant state."""
        pass

    fn init_state(self, state: EnergyPlusData):
        """Initialize state."""
        pass

    fn clear_state(inout self):
        """Clear state."""
        self.get_plant_load_profile_input_flag = True
        self.num_of_plant_profile = 0
        self.plant_profile.clear()


fn get_plant_profile_input(state: EnergyPlusData):
    """Get plant profile input from input file."""
    var routine_name = "GetPlantProfileInput"

    var c_current_module_object = "LoadProfile:Plant"
    state.data_plant_load_profile.num_of_plant_profile = (
        state.data_input_processing.input_processor.get_num_objects_found(
            state, c_current_module_object
        )
    )

    if state.data_plant_load_profile.num_of_plant_profile > 0:
        state.data_plant_load_profile.plant_profile.resize(
            state.data_plant_load_profile.num_of_plant_profile
        )
        var errors_found = False

        for profile_num in range(state.data_plant_load_profile.num_of_plant_profile):
            var c_alpha_args = InlineArray[String, 10]()
            var r_numeric_args = InlineArray[Float64, 10](fill=0.0)
            var num_alphas = 0
            var num_numbers = 0
            var l_numeric_field_blanks = InlineArray[Bool, 10](fill=False)

            state.data_input_processing.input_processor.get_object_item(
                state,
                c_current_module_object,
                profile_num + 1,
                c_alpha_args,
                num_alphas,
                r_numeric_args,
                num_numbers,
                l_numeric_field_blanks,
            )

            state.data_plant_load_profile.plant_profile[profile_num].name = (
                c_alpha_args[0]
            )
            state.data_plant_load_profile.plant_profile[profile_num].type = (
                -1
            )

            var fluid_type_str = c_alpha_args[5].upper() if c_alpha_args[5] else "WATER"
            var fluid_type = PlantLoopFluidType.WATER
            if fluid_type_str == "WATER":
                fluid_type = PlantLoopFluidType.WATER
            elif fluid_type_str == "STEAM":
                fluid_type = PlantLoopFluidType.STEAM
            else:
                fluid_type = PlantLoopFluidType.WATER

            state.data_plant_load_profile.plant_profile[profile_num].fluid_type = (
                fluid_type
            )

            if (
                state.data_plant_load_profile.plant_profile[profile_num].fluid_type
                == PlantLoopFluidType.WATER
            ):
                state.data_plant_load_profile.plant_profile[profile_num].inlet_node = (
                    node_get_only_single_node(
                        state, c_alpha_args[1], errors_found, "Water", c_alpha_args[0]
                    )
                )
                state.data_plant_load_profile.plant_profile[
                    profile_num
                ].outlet_node = node_get_only_single_node(
                    state, c_alpha_args[2], errors_found, "Water", c_alpha_args[0]
                )
            else:
                state.data_plant_load_profile.plant_profile[profile_num].inlet_node = (
                    node_get_only_single_node(
                        state, c_alpha_args[1], errors_found, "Steam", c_alpha_args[0]
                    )
                )
                state.data_plant_load_profile.plant_profile[
                    profile_num
                ].outlet_node = node_get_only_single_node(
                    state, c_alpha_args[2], errors_found, "Steam", c_alpha_args[0]
                )

            state.data_plant_load_profile.plant_profile[profile_num].load_sched = (
                sched_get_schedule(state, c_alpha_args[3])
            )
            if not state.data_plant_load_profile.plant_profile[
                profile_num
            ].load_sched:
                errors_found = True

            state.data_plant_load_profile.plant_profile[profile_num].peak_vol_flow_rate = r_numeric_args[0]

            state.data_plant_load_profile.plant_profile[
                profile_num
            ].flow_rate_frac_sched = sched_get_schedule(state, c_alpha_args[4])
            if not state.data_plant_load_profile.plant_profile[
                profile_num
            ].flow_rate_frac_sched:
                errors_found = True

            if (
                state.data_plant_load_profile.plant_profile[profile_num].fluid_type
                == PlantLoopFluidType.STEAM
            ):
                if not l_numeric_field_blanks[1]:
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].deg_of_subcooling = r_numeric_args[1]
                else:
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].deg_of_subcooling = 5.0

                if not l_numeric_field_blanks[2]:
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].loop_subcool_return = r_numeric_args[2]
                else:
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].loop_subcool_return = 20.0

            node_test_comp_set(
                state,
                c_current_module_object,
                c_alpha_args[0],
                c_alpha_args[1],
                c_alpha_args[2],
                c_current_module_object + " Nodes",
            )

            output_processor_setup_output_variable(
                state,
                "Plant Load Profile Mass Flow Rate",
                "kg/s",
                state.data_plant_load_profile.plant_profile[profile_num].mass_flow_rate,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            output_processor_setup_output_variable(
                state,
                "Plant Load Profile Heat Transfer Rate",
                "W",
                state.data_plant_load_profile.plant_profile[profile_num].power,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            output_processor_setup_output_variable(
                state,
                "Plant Load Profile Heat Transfer Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            output_processor_setup_output_variable(
                state,
                "Plant Load Profile Heating Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].heating_energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            output_processor_setup_output_variable(
                state,
                "Plant Load Profile Cooling Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].cooling_energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            if state.data_global.any_energy_management_system_in_model:
                output_processor_setup_ems_actuator(
                    state,
                    "Plant Load Profile",
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                    "Mass Flow Rate",
                    "[kg/s]",
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].ems_override_mass_flow,
                )
                output_processor_setup_ems_actuator(
                    state,
                    "Plant Load Profile",
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                    "Power",
                    "[W]",
                    state.data_plant_load_profile.plant_profile[
                        profile_num
                    ].ems_override_power,
                )

            if (
                state.data_plant_load_profile.plant_profile[profile_num].fluid_type
                == PlantLoopFluidType.STEAM
            ):
                output_processor_setup_output_variable(
                    state,
                    "Plant Load Profile Steam Outlet Temperature",
                    "C",
                    state.data_plant_load_profile.plant_profile[profile_num].outlet_temp,
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                )

            if errors_found:
                show_fatal_error(
                    state,
                    "Errors in " + c_current_module_object + " input.",
                )


fn plant_utilities_set_component_flow_rate(
    state: EnergyPlusData,
    mass_flow: Float64,
    inlet_node: Int32,
    outlet_node: Int32,
    plant_loc: PlantLocation,
):
    """Set component flow rate."""
    pass


fn plant_utilities_init_component_nodes(
    state: EnergyPlusData,
    min_flow: Float64,
    max_flow: Float64,
    inlet_node: Int32,
    outlet_node: Int32,
):
    """Initialize component nodes."""
    pass


fn plant_utilities_register_plant_comp_design_flow(
    state: EnergyPlusData, inlet_node: Int32, peak_vol_flow_rate: Float64
):
    """Register plant component design flow."""
    pass


fn plant_utilities_scan_plant_loops_for_object(
    state: EnergyPlusData,
    name: String,
    type_val: Int32,
    plant_loc: PlantLocation,
    inout err_flag: Bool,
):
    """Scan plant loops for object."""
    pass


fn node_get_only_single_node(
    state: EnergyPlusData,
    node_name: String,
    inout errors_found: Bool,
    fluid_type: String,
    component_name: String,
) -> Int32:
    """Get only single node."""
    return 0


fn node_test_comp_set(
    state: EnergyPlusData,
    obj_type: String,
    obj_name: String,
    inlet_node: String,
    outlet_node: String,
    node_desc: String,
):
    """Test component set."""
    pass


fn sched_get_schedule(state: EnergyPlusData, schedule_name: String) -> Schedule:
    """Get schedule."""
    return Schedule()


fn output_processor_setup_output_variable(
    state: EnergyPlusData,
    var_name: String,
    units: String,
    inout var_ref: Float64,
    component_name: String,
):
    """Setup output variable."""
    pass


fn output_processor_setup_ems_actuator(
    state: EnergyPlusData,
    object_type: String,
    object_name: String,
    actuator_type: String,
    units: String,
    inout actuator_var: Bool,
):
    """Setup EMS actuator."""
    pass


fn show_fatal_error(state: EnergyPlusData, message: String):
    """Show fatal error."""
    pass


@value
struct EnergyPlusData:
    """Placeholder for EnergyPlusData."""
    pass


@value
struct PlantLocation:
    """Placeholder for PlantLocation."""
    pass


@value
struct Schedule:
    """Placeholder for Schedule."""
    fn get_max_val(self, state: EnergyPlusData) -> Float64:
        return 0.0

    fn get_current_val(self, state: EnergyPlusData) -> Float64:
        return 0.0

    fn get_day_vals(
        self, state: EnergyPlusData, start: Int32, end: Int32
    ) -> DynamicVector[Float64]:
        return DynamicVector[Float64]()
