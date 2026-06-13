# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): state object with nested dataXXX attributes
# - PlantComponent: base class with abstract methods
# - PlantLocation: structure with loop reference
# - Schedule: schedule object with methods getMaxVal, getCurrentVal, getDayVals
# - DataPlant.PlantEquipmentType: enum for plant equipment type
# - PlantUtilities.SetComponentFlowRate: function signature (state, mass_flow, inlet, outlet, plant_loc)
# - PlantUtilities.InitComponentNodes: function signature
# - PlantUtilities.RegisterPlantCompDesignFlow: function signature
# - PlantUtilities.ScanPlantLoopsForObject: function signature
# - Node.GetOnlySingleNode: function for node lookup
# - Node.TestCompSet: function for component testing
# - Sched.GetSchedule: function to retrieve schedule
# - ShowFatalError, ShowSevereItemNotFound: error reporting functions
# - Util.makeUPPER: string upper case function
# - getEnumValue: enum parsing function
# - SetupOutputVariable, SetupEMSActuator: output setup functions
# - DataEnvironment.StdPressureSeaLevel: constant
# - Constant.InitConvTemp: constant
# - Constant.iHoursInDay: constant

from enum import IntEnum
from typing import Optional, List
from dataclasses import dataclass, field


class PlantLoopFluidType(IntEnum):
    INVALID = -1
    WATER = 0
    STEAM = 1
    NUM = 2


PLANT_LOOP_FLUID_TYPE_NAMES_UC = ["WATER", "STEAM"]


@dataclass
class PlantProfileData:
    """Plant load profile component data."""
    
    name: str = ""
    type: int = -1  # DataPlant.PlantEquipmentType
    plant_loc: 'PlantLocation' = field(default_factory=lambda: None)
    fluid_type: PlantLoopFluidType = PlantLoopFluidType.INVALID
    init: bool = True
    init_sizing: bool = True
    inlet_node: int = 0
    inlet_temp: float = 0.0
    outlet_node: int = 0
    outlet_temp: float = 0.0
    load_sched: Optional['Schedule'] = None
    ems_override_power: bool = False
    ems_power_value: float = 0.0
    peak_vol_flow_rate: float = 0.0
    flow_rate_frac_sched: Optional['Schedule'] = None
    vol_flow_rate: float = 0.0
    mass_flow_rate: float = 0.0
    deg_of_subcooling: float = 0.0
    loop_subcool_return: float = 0.0
    ems_override_mass_flow: bool = False
    ems_mass_flow_value: float = 0.0
    power: float = 0.0
    energy: float = 0.0
    heating_energy: float = 0.0
    cooling_energy: float = 0.0

    @staticmethod
    def factory(state, object_name: str):
        """Factory method to create or retrieve PlantProfileData."""
        if state.data_plant_load_profile.get_plant_load_profile_input_flag:
            get_plant_profile_input(state)
            state.data_plant_load_profile.get_plant_load_profile_input_flag = False
        
        for plant_profile in state.data_plant_load_profile.plant_profile:
            if plant_profile.name == object_name:
                return plant_profile
        
        raise RuntimeError(f"PlantLoadProfile::factory: Error getting inputs for pipe named: {object_name}")

    def on_init_loop_equip(self, state, called_from_location):
        """Initialize plant equipment."""
        self.init_plant_profile(state)

    def simulate(self, state, called_from_location, first_hvac_iteration, cur_load, run_flag):
        """Simulate the plant load profile."""
        routine_name = "SimulatePlantProfile"
        delta_temp = 0.0

        self.init_plant_profile(state)

        if self.fluid_type == PlantLoopFluidType.WATER:
            if self.mass_flow_rate > 0.0:
                cp = self.plant_loc.loop.glycol.get_specific_heat(state, self.inlet_temp, routine_name)
                delta_temp = self.power / (self.mass_flow_rate * cp)
            else:
                self.power = 0.0
                delta_temp = 0.0
            self.outlet_temp = self.inlet_temp - delta_temp

        elif self.fluid_type == PlantLoopFluidType.STEAM:
            if self.mass_flow_rate > 0.0 and self.power > 0.0:
                enth_steam_in_dry = self.plant_loc.loop.steam.get_sat_enthalpy(state, self.inlet_temp, 1.0, routine_name)
                enth_steam_out_wet = self.plant_loc.loop.steam.get_sat_enthalpy(state, self.inlet_temp, 0.0, routine_name)
                latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                sat_temp = self.plant_loc.loop.steam.get_sat_temperature(state, state.std_pressure_sea_level, routine_name)
                cp_water = self.plant_loc.loop.glycol.get_specific_heat(state, sat_temp, routine_name)

                self.mass_flow_rate = self.power / (latent_heat_steam + self.deg_of_subcooling * cp_water)
                PlantUtilities.set_component_flow_rate(state, self.mass_flow_rate, self.inlet_node, self.outlet_node, self.plant_loc)
                state.data_loop_nodes.node[self.outlet_node].quality = 0.0
                self.outlet_temp = sat_temp - self.loop_subcool_return
            else:
                self.power = 0.0

        self.update_plant_profile(state)
        self.report_plant_profile(state)

    def init_plant_profile(self, state):
        """Initialize plant profile."""
        routine_name = "InitPlantProfile"
        fluid_density_init = 0.0

        if state.data_global.begin_envrn_flag and self.init:
            state.data_loop_nodes.node[self.outlet_node].temp = 0.0

            if self.fluid_type == PlantLoopFluidType.WATER:
                fluid_density_init = self.plant_loc.loop.glycol.get_density(state, state.init_conv_temp, routine_name)
            else:
                sat_temp_atm_press = self.plant_loc.loop.steam.get_sat_temperature(state, state.std_pressure_sea_level, routine_name)
                fluid_density_init = self.plant_loc.loop.steam.get_sat_density(state, sat_temp_atm_press, 1.0, routine_name)

            max_flow_multiplier = self.flow_rate_frac_sched.get_max_val(state)

            PlantUtilities.init_component_nodes(
                state, 0.0, self.peak_vol_flow_rate * fluid_density_init * max_flow_multiplier, 
                self.inlet_node, self.outlet_node
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
            fluid_density_init = self.plant_loc.loop.glycol.get_density(state, self.inlet_temp, routine_name)
        else:
            fluid_density_init = self.plant_loc.loop.steam.get_sat_density(state, self.inlet_temp, 1.0, routine_name)

        self.vol_flow_rate = self.peak_vol_flow_rate * self.flow_rate_frac_sched.get_current_val(state)
        self.mass_flow_rate = self.vol_flow_rate * fluid_density_init

        if self.ems_override_mass_flow:
            self.mass_flow_rate = self.ems_mass_flow_value

        PlantUtilities.set_component_flow_rate(state, self.mass_flow_rate, self.inlet_node, self.outlet_node, self.plant_loc)
        self.vol_flow_rate = self.mass_flow_rate / fluid_density_init

        if self.init_sizing and not state.data_global.sys_sizing_calc:
            PlantUtilities.register_plant_comp_design_flow(state, self.inlet_node, self.peak_vol_flow_rate)
            
            this_load_sched = self.load_sched.get_day_vals(state, -1, -1)
            this_flow_sched = self.flow_rate_frac_sched.get_day_vals(state, -1, -1)
            plnt_siz_index = self.plant_loc.loop.plant_siz_num
            plnt_delta_t = 0.0
            inlet_temp = state.init_conv_temp

            if plnt_siz_index > 0:
                plnt_delta_t = state.data_size.plant_siz_data[plnt_siz_index - 1].delta_t
                inlet_temp = state.data_size.plant_siz_data[plnt_siz_index - 1].exit_temp

            plnt_comps = self.plant_loc.loop.plant_coil_object_names
            cmp_type = self.plant_loc.loop.plant_coil_object_types
            array_index = -1

            for i in range(len(plnt_comps)):
                if plnt_comps[i] == self.name and cmp_type[i] == self.type:
                    array_index = i
                    break

            if array_index == -1:
                self.plant_loc.loop.plant_coil_object_names.append(self.name)
                self.plant_loc.loop.plant_coil_object_types.append(self.type)

                tmp_flow_data = [-1.0] + [0.0] * (state.hours_in_day * state.time_steps_in_hour)

                if self.fluid_type == PlantLoopFluidType.WATER:
                    fluid_density_init = self.plant_loc.loop.glycol.get_density(state, inlet_temp, routine_name)
                else:
                    fluid_density_init = self.plant_loc.loop.steam.get_sat_density(state, inlet_temp, 1.0, routine_name)

                cp = 0.0
                if self.fluid_type == PlantLoopFluidType.WATER:
                    cp = self.plant_loc.loop.glycol.get_specific_heat(state, inlet_temp, routine_name)
                elif self.fluid_type == PlantLoopFluidType.STEAM:
                    enth_steam_in_dry = self.plant_loc.loop.steam.get_sat_enthalpy(state, inlet_temp, 1.0, routine_name)
                    enth_steam_out_wet = self.plant_loc.loop.steam.get_sat_enthalpy(state, inlet_temp, 0.0, routine_name)
                    latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                    sat_temp = self.plant_loc.loop.steam.get_sat_temperature(state, state.std_pressure_sea_level, routine_name)
                    cp = self.plant_loc.loop.glycol.get_specific_heat(state, sat_temp, routine_name)

                    self.mass_flow_rate = self.power / (latent_heat_steam + self.deg_of_subcooling * cp)
                    PlantUtilities.set_component_flow_rate(state, self.mass_flow_rate, self.inlet_node, self.outlet_node, self.plant_loc)
                    state.data_loop_nodes.node[self.outlet_node].quality = 0.0

                for i in range(1, len(this_load_sched) + 1):
                    if plnt_delta_t > 0:
                        tmp_flow_data[i] = this_load_sched[i - 1] / (fluid_density_init * cp * plnt_delta_t)
                    else:
                        tmp_flow_data[i] = this_flow_sched[i - 1] * self.peak_vol_flow_rate

                plnt_coil_data = self.plant_loc.loop.comp_des_water_flow_rate
                new_entry_index = len(plnt_coil_data)
                plnt_coil_data.append({'ts_des_water_flow_rate': tmp_flow_data})

            self.init_sizing = False

    def update_plant_profile(self, state):
        """Update plant profile node variables."""
        state.data_loop_nodes.node[self.outlet_node].temp = self.outlet_temp

    def report_plant_profile(self, state):
        """Report plant profile variables."""
        time_step_sys_sec = state.data_hvac_global.time_step_sys_sec

        self.energy = self.power * time_step_sys_sec

        if self.energy >= 0.0:
            self.heating_energy = self.energy
            self.cooling_energy = 0.0
        else:
            self.heating_energy = 0.0
            self.cooling_energy = abs(self.energy)

    def one_time_init_new(self, state):
        """One-time initialization (new)."""
        if state.data_plnt.plant_loop:
            err_flag = False
            PlantUtilities.scan_plant_loops_for_object(state, self.name, self.type, self.plant_loc, err_flag)
            if err_flag:
                raise RuntimeError("InitPlantProfile: Program terminated for previous conditions.")

    def one_time_init(self, state):
        """One-time initialization."""
        pass

    def get_current_power(self, state):
        """Get current power."""
        return self.power


@dataclass
class PlantLoadProfileData:
    """Global plant load profile data."""
    
    get_plant_load_profile_input_flag: bool = True
    num_of_plant_profile: int = 0
    plant_profile: List[PlantProfileData] = field(default_factory=list)

    def init_constant_state(self, state):
        """Initialize constant state."""
        pass

    def init_state(self, state):
        """Initialize state."""
        pass

    def clear_state(self):
        """Clear state."""
        self.get_plant_load_profile_input_flag = True
        self.num_of_plant_profile = 0
        self.plant_profile.clear()


def get_plant_profile_input(state):
    """Get plant profile input from input file."""
    routine_name = "GetPlantProfileInput"

    c_current_module_object = "LoadProfile:Plant"
    state.data_plant_load_profile.num_of_plant_profile = (
        state.data_input_processing.input_processor.get_num_objects_found(state, c_current_module_object)
    )

    if state.data_plant_load_profile.num_of_plant_profile > 0:
        state.data_plant_load_profile.plant_profile = [
            PlantProfileData() for _ in range(state.data_plant_load_profile.num_of_plant_profile)
        ]
        errors_found = False

        for profile_num in range(state.data_plant_load_profile.num_of_plant_profile):
            c_alpha_args = [None] * 10
            r_numeric_args = [0.0] * 10
            num_alphas = 0
            num_numbers = 0
            l_numeric_field_blanks = [False] * 10

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

            state.data_plant_load_profile.plant_profile[profile_num].name = c_alpha_args[0]
            state.data_plant_load_profile.plant_profile[profile_num].type = -1  # DataPlant.PlantEquipmentType.PlantLoadProfile

            fluid_type_str = c_alpha_args[5].upper() if c_alpha_args[5] else "WATER"
            try:
                fluid_type_idx = PLANT_LOOP_FLUID_TYPE_NAMES_UC.index(fluid_type_str)
                state.data_plant_load_profile.plant_profile[profile_num].fluid_type = PlantLoopFluidType(fluid_type_idx)
            except ValueError:
                state.data_plant_load_profile.plant_profile[profile_num].fluid_type = PlantLoopFluidType.WATER

            if state.data_plant_load_profile.plant_profile[profile_num].fluid_type == PlantLoopFluidType.WATER:
                state.data_plant_load_profile.plant_profile[profile_num].inlet_node = Node.get_only_single_node(
                    state, c_alpha_args[1], errors_found, "Water", c_alpha_args[0]
                )
                state.data_plant_load_profile.plant_profile[profile_num].outlet_node = Node.get_only_single_node(
                    state, c_alpha_args[2], errors_found, "Water", c_alpha_args[0]
                )
            else:
                state.data_plant_load_profile.plant_profile[profile_num].inlet_node = Node.get_only_single_node(
                    state, c_alpha_args[1], errors_found, "Steam", c_alpha_args[0]
                )
                state.data_plant_load_profile.plant_profile[profile_num].outlet_node = Node.get_only_single_node(
                    state, c_alpha_args[2], errors_found, "Steam", c_alpha_args[0]
                )

            state.data_plant_load_profile.plant_profile[profile_num].load_sched = Sched.get_schedule(state, c_alpha_args[3])
            if not state.data_plant_load_profile.plant_profile[profile_num].load_sched:
                errors_found = True

            state.data_plant_load_profile.plant_profile[profile_num].peak_vol_flow_rate = r_numeric_args[0]

            state.data_plant_load_profile.plant_profile[profile_num].flow_rate_frac_sched = Sched.get_schedule(state, c_alpha_args[4])
            if not state.data_plant_load_profile.plant_profile[profile_num].flow_rate_frac_sched:
                errors_found = True

            if state.data_plant_load_profile.plant_profile[profile_num].fluid_type == PlantLoopFluidType.STEAM:
                if not l_numeric_field_blanks[1]:
                    state.data_plant_load_profile.plant_profile[profile_num].deg_of_subcooling = r_numeric_args[1]
                else:
                    state.data_plant_load_profile.plant_profile[profile_num].deg_of_subcooling = 5.0

                if not l_numeric_field_blanks[2]:
                    state.data_plant_load_profile.plant_profile[profile_num].loop_subcool_return = r_numeric_args[2]
                else:
                    state.data_plant_load_profile.plant_profile[profile_num].loop_subcool_return = 20.0

            Node.test_comp_set(
                state,
                c_current_module_object,
                c_alpha_args[0],
                c_alpha_args[1],
                c_alpha_args[2],
                c_current_module_object + " Nodes",
            )

            OutputProcessor.setup_output_variable(
                state,
                "Plant Load Profile Mass Flow Rate",
                "kg/s",
                state.data_plant_load_profile.plant_profile[profile_num].mass_flow_rate,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            OutputProcessor.setup_output_variable(
                state,
                "Plant Load Profile Heat Transfer Rate",
                "W",
                state.data_plant_load_profile.plant_profile[profile_num].power,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            OutputProcessor.setup_output_variable(
                state,
                "Plant Load Profile Heat Transfer Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            OutputProcessor.setup_output_variable(
                state,
                "Plant Load Profile Heating Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].heating_energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            OutputProcessor.setup_output_variable(
                state,
                "Plant Load Profile Cooling Energy",
                "J",
                state.data_plant_load_profile.plant_profile[profile_num].cooling_energy,
                state.data_plant_load_profile.plant_profile[profile_num].name,
            )

            if state.data_global.any_energy_management_system_in_model:
                OutputProcessor.setup_ems_actuator(
                    state,
                    "Plant Load Profile",
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                    "Mass Flow Rate",
                    "[kg/s]",
                    state.data_plant_load_profile.plant_profile[profile_num].ems_override_mass_flow,
                )
                OutputProcessor.setup_ems_actuator(
                    state,
                    "Plant Load Profile",
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                    "Power",
                    "[W]",
                    state.data_plant_load_profile.plant_profile[profile_num].ems_override_power,
                )

            if state.data_plant_load_profile.plant_profile[profile_num].fluid_type == PlantLoopFluidType.STEAM:
                OutputProcessor.setup_output_variable(
                    state,
                    "Plant Load Profile Steam Outlet Temperature",
                    "C",
                    state.data_plant_load_profile.plant_profile[profile_num].outlet_temp,
                    state.data_plant_load_profile.plant_profile[profile_num].name,
                )

            if errors_found:
                raise RuntimeError(f"Errors in {c_current_module_object} input.")


class PlantUtilities:
    @staticmethod
    def set_component_flow_rate(state, mass_flow, inlet_node, outlet_node, plant_loc):
        pass

    @staticmethod
    def init_component_nodes(state, min_flow, max_flow, inlet_node, outlet_node):
        pass

    @staticmethod
    def register_plant_comp_design_flow(state, inlet_node, peak_vol_flow_rate):
        pass

    @staticmethod
    def scan_plant_loops_for_object(state, name, type_val, plant_loc, err_flag):
        pass


class Node:
    @staticmethod
    def get_only_single_node(state, node_name, errors_found, fluid_type, component_name):
        return 0

    @staticmethod
    def test_comp_set(state, obj_type, obj_name, inlet_node, outlet_node, node_desc):
        pass


class Sched:
    @staticmethod
    def get_schedule(state, schedule_name):
        return None


class OutputProcessor:
    @staticmethod
    def setup_output_variable(state, var_name, units, var_ref, component_name):
        pass

    @staticmethod
    def setup_ems_actuator(state, object_type, object_name, actuator_type, units, actuator_var):
        pass
