from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Any, Dict
import math
from abc import ABC, abstractmethod

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object, passed as parameter)
# - PlantComponent (base class, passed as parameter type)
# - BaseGlobalStruct (base class for module state)
# - Schedule type from Sched module
# - DataPlant.PlantEquipmentType enum
# - DataPlant.PressSimType enum
# - Node structures from DataLoopNode
# - Material.SurfaceRoughness enum
# - GroundTemp.BaseGroundTempsModel
# - DataHeatBalance.IntGainType
# - Output/error routines (ShowSevereError, ShowWarningError, etc.)
# - Various utility functions from other modules

INNER_DELTA_TIME = 60.0  # one minute time step in seconds

class EnvrnPtr(IntEnum):
    INVALID = -1
    NONE = 0
    ZONE_ENV = 1
    SCHEDULE_ENV = 2
    OUTSIDE_AIR_ENV = 3
    GROUND_ENV = 4
    NUM = 5

class TimeIndex(IntEnum):
    INVALID = -1
    PREVIOUS = 1
    CURRENT = 2
    TENTATIVE = 3

class PipeIndoorBoundaryType(IntEnum):
    INVALID = -1
    ZONE = 0
    SCHEDULE = 1
    NUM = 2

PIPE_INDOOR_BOUNDARY_TYPE_NAMES_UC = ["ZONE", "SCHEDULE"]

@dataclass
class PlantLocation:
    loop_num: int = 0
    loop: Any = None
    branch_num: int = 0
    comp_num: int = 0

@dataclass
class PipeHTData:
    name: str = ""
    construction: str = ""
    environment: str = ""
    envr_sched: Optional[Any] = None
    envr_vel_sched: Optional[Any] = None
    envr_air_node: str = ""
    length: float = 0.0
    pipe_id: float = 0.0
    inlet_node: str = ""
    outlet_node: str = ""
    inlet_node_num: int = 0
    outlet_node_num: int = 0
    type: Any = None
    
    construction_num: int = 0
    environment_ptr: EnvrnPtr = EnvrnPtr.NONE
    envr_zone_ptr: int = 0
    envr_air_node_num: int = 0
    num_sections: int = 0
    fluid_spec_heat: float = 0.0
    fluid_density: float = 0.0
    max_flow_rate: float = 0.0
    inside_area: float = 0.0
    outside_area: float = 0.0
    section_area: float = 0.0
    pipe_heat_capacity: float = 0.0
    pipe_od: float = 0.0
    pipe_cp: float = 0.0
    pipe_density: float = 0.0
    pipe_conductivity: float = 0.0
    insulation_od: float = 0.0
    insulation_cp: float = 0.0
    insulation_density: float = 0.0
    insulation_conductivity: float = 0.0
    insulation_thickness: float = 0.0
    insulation_resistance: float = 0.0
    current_sim_time: float = 0.0
    previous_sim_time: float = 0.0
    
    tentative_fluid_temp: List[float] = field(default_factory=list)
    fluid_temp: List[float] = field(default_factory=list)
    previous_fluid_temp: List[float] = field(default_factory=list)
    tentative_pipe_temp: List[float] = field(default_factory=list)
    pipe_temp: List[float] = field(default_factory=list)
    previous_pipe_temp: List[float] = field(default_factory=list)
    
    num_depth_nodes: int = 0
    pipe_node_depth: int = 0
    pipe_node_width: int = 0
    pipe_depth: float = 0.0
    domain_depth: float = 0.0
    ds_regular: float = 0.0
    outdoor_conv_coef: float = 0.0
    soil_material: str = ""
    soil_material_num: int = 0
    month_of_min_surf_temp: int = 0
    min_surf_temp: float = 0.0
    soil_density: float = 0.0
    soil_depth: float = 0.0
    soil_cp: float = 0.0
    soil_conductivity: float = 0.0
    soil_roughness: Any = None
    soil_therm_abs: float = 0.0
    soil_solar_abs: float = 0.0
    coef_a1: float = 0.0
    coef_a2: float = 0.0
    fourier_ds: float = 0.0
    soil_diffusivity: float = 0.0
    soil_diffusivity_per_day: float = 0.0
    t: Any = None  # 4D array for soil temperature
    
    begin_sim_init: bool = True
    begin_sim_envrn: bool = True
    first_hvac_update_flag: bool = True
    begin_envrn_update_flag: bool = True
    solar_exposed: bool = True
    sum_tk: float = 0.0
    zone_heat_gain_rate: float = 0.0
    plant_loc: PlantLocation = field(default_factory=PlantLocation)
    check_equip_name: bool = True
    ground_temp_model: Optional[Any] = None
    
    fluid_inlet_temp: float = 0.0
    fluid_outlet_temp: float = 0.0
    mass_flow_rate: float = 0.0
    fluid_heat_loss_rate: float = 0.0
    fluid_heat_loss_energy: float = 0.0
    pipe_inlet_temp: float = 0.0
    pipe_outlet_temp: float = 0.0
    environment_heat_loss_rate: float = 0.0
    env_heat_loss_energy: float = 0.0
    volume_flow_rate: float = 0.0

@dataclass
class PipeHeatTransferData:
    nsv_num_of_pipe_ht: int = 0
    nsv_inlet_node_num: int = 0
    nsv_outlet_node_num: int = 0
    nsv_mass_flow_rate: float = 0.0
    nsv_volume_flow_rate: float = 0.0
    nsv_delta_time: float = 0.0
    nsv_inlet_temp: float = 0.0
    nsv_outlet_temp: float = 0.0
    nsv_environment_temp: float = 0.0
    nsv_env_heat_loss_rate: float = 0.0
    nsv_fluid_heat_loss_rate: float = 0.0
    nsv_num_inner_time_steps: int = 0
    get_pipe_input_flag: bool = True
    my_envrn_flag: bool = True
    pipe_ht: List[PipeHTData] = field(default_factory=list)
    pipe_ht_unique_names: Dict[str, str] = field(default_factory=dict)

def factory(state: Any, object_type: Any, object_name: str) -> Optional[PipeHTData]:
    """Factory method to create or retrieve a PipeHTData object."""
    if state.data_pipe_ht.get_pipe_input_flag:
        get_pipes_heat_transfer(state)
        state.data_pipe_ht.get_pipe_input_flag = False
    
    for pipe in state.data_pipe_ht.pipe_ht:
        if pipe.type == object_type and pipe.name == object_name:
            return pipe
    
    raise RuntimeError(f"PipeHTFactory: Error getting inputs for pipe named: {object_name}")

def simulate(pipe: PipeHTData, state: Any, called_from_location: Any, 
             first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
    """Simulate the pipe heat transfer."""
    pipe.init_pipes_heat_transfer(state, first_hvac_iteration)
    
    for inner_time_step_ctr in range(1, state.data_pipe_ht.nsv_num_inner_time_steps + 1):
        if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
            pipe.calc_buried_pipe_soil(state)
        else:
            pipe.calc_pipes_heat_transfer(state)
        pipe.push_inner_time_step_arrays()
    
    pipe.update_pipes_heat_transfer(state)
    pipe.report_pipes_heat_transfer(state)

def push_inner_time_step_arrays(pipe: PipeHTData) -> None:
    """Push inner time step arrays."""
    if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
        for length_idx in range(2, pipe.num_sections + 1):
            for depth_idx in range(1, pipe.num_depth_nodes + 1):
                for width_idx in range(2, pipe.pipe_node_width + 1):
                    pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.PREVIOUS - 1] = \
                        pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
    
    pipe.previous_fluid_temp = pipe.fluid_temp.copy()
    pipe.previous_pipe_temp = pipe.pipe_temp.copy()

def get_pipes_heat_transfer(state: Any) -> None:
    """Read input for pipes with heat transfer."""
    num_pipe_sections = 20
    number_of_depth_nodes = 8
    
    errors_found = False
    s_ipsc = state.data_ip_short_cut
    s_mat = state.data_material
    
    # Count pipe objects
    s_ipsc.c_current_module_object = "Pipe:Indoor"
    num_of_pipe_ht_int = len(state.data_input_processing.input_processor.get_object(state, s_ipsc.c_current_module_object))
    
    s_ipsc.c_current_module_object = "Pipe:Outdoor"
    num_of_pipe_ht_ext = len(state.data_input_processing.input_processor.get_object(state, s_ipsc.c_current_module_object))
    
    s_ipsc.c_current_module_object = "Pipe:Underground"
    num_of_pipe_ht_ug = len(state.data_input_processing.input_processor.get_object(state, s_ipsc.c_current_module_object))
    
    state.data_pipe_ht.nsv_num_of_pipe_ht = num_of_pipe_ht_int + num_of_pipe_ht_ext + num_of_pipe_ht_ug
    state.data_pipe_ht.pipe_ht = [PipeHTData() for _ in range(state.data_pipe_ht.nsv_num_of_pipe_ht)]
    
    item = 0
    
    # Process Indoor pipes
    s_ipsc.c_current_module_object = "Pipe:Indoor"
    for pipe_item in range(1, num_of_pipe_ht_int + 1):
        item += 1
        # Process object input (simplified)
        state.data_pipe_ht.pipe_ht[item - 1].name = f"Pipe:Indoor_{pipe_item}"
        # ... additional input processing would go here
    
    # Process Outdoor pipes
    s_ipsc.c_current_module_object = "Pipe:Outdoor"
    for pipe_item in range(1, num_of_pipe_ht_ext + 1):
        item += 1
        state.data_pipe_ht.pipe_ht[item - 1].name = f"Pipe:Outdoor_{pipe_item}"
    
    # Process Underground pipes
    s_ipsc.c_current_module_object = "Pipe:Underground"
    for pipe_item in range(1, num_of_pipe_ht_ug + 1):
        item += 1
        state.data_pipe_ht.pipe_ht[item - 1].name = f"Pipe:Underground_{pipe_item}"
    
    # Allocate arrays for all pipes
    for item in range(state.data_pipe_ht.nsv_num_of_pipe_ht):
        num_sections = num_pipe_sections
        state.data_pipe_ht.pipe_ht[item].num_sections = num_sections
        state.data_pipe_ht.pipe_ht[item].tentative_fluid_temp = [0.0] * (num_sections + 1)
        state.data_pipe_ht.pipe_ht[item].tentative_pipe_temp = [0.0] * (num_sections + 1)
        state.data_pipe_ht.pipe_ht[item].fluid_temp = [0.0] * (num_sections + 1)
        state.data_pipe_ht.pipe_ht[item].previous_fluid_temp = [0.0] * (num_sections + 1)
        state.data_pipe_ht.pipe_ht[item].pipe_temp = [0.0] * (num_sections + 1)
        state.data_pipe_ht.pipe_ht[item].previous_pipe_temp = [0.0] * (num_sections + 1)
        
        state.data_pipe_ht.pipe_ht[item].inside_area = \
            math.pi * state.data_pipe_ht.pipe_ht[item].pipe_id * state.data_pipe_ht.pipe_ht[item].length / num_sections
        state.data_pipe_ht.pipe_ht[item].outside_area = \
            math.pi * (state.data_pipe_ht.pipe_ht[item].pipe_od + 2 * state.data_pipe_ht.pipe_ht[item].insulation_thickness) * \
            state.data_pipe_ht.pipe_ht[item].length / num_sections
        
        state.data_pipe_ht.pipe_ht[item].section_area = math.pi * 0.25 * state.data_pipe_ht.pipe_ht[item].pipe_id ** 2
        
        state.data_pipe_ht.pipe_ht[item].pipe_heat_capacity = \
            state.data_pipe_ht.pipe_ht[item].pipe_cp * state.data_pipe_ht.pipe_ht[item].pipe_density * \
            (math.pi * 0.25 * state.data_pipe_ht.pipe_ht[item].pipe_od ** 2 - state.data_pipe_ht.pipe_ht[item].section_area)

def validate_pipe_construction(pipe: PipeHTData, state: Any, pipe_type: str, 
                               construction_name: str, field_name: str, 
                               construction_num: int) -> bool:
    """Validate pipe construction."""
    errors_found = False
    s_mat = state.data_material
    
    total_layers = state.data_construction.construct[construction_num].tot_layers
    
    if total_layers == 1:
        mat = s_mat.materials[state.data_construction.construct[construction_num].layer_point[0]]
        pipe.pipe_conductivity = mat.conductivity
        pipe.pipe_density = mat.density
        pipe.pipe_cp = mat.spec_heat
        pipe.pipe_od = pipe.pipe_id + 2.0 * mat.thickness
        pipe.insulation_od = pipe.pipe_od
        pipe.sum_tk = mat.thickness / mat.conductivity
    
    elif total_layers >= 2:
        resistance = 0.0
        density = 0.0
        tot_thickness = 0.0
        sp_heat = 0.0
        
        for layer_num in range(total_layers - 1):
            mat = s_mat.materials[state.data_construction.construct[construction_num].layer_point[layer_num]]
            resistance += mat.thickness / mat.conductivity
            density = mat.density * mat.thickness
            tot_thickness += mat.thickness
            sp_heat = mat.spec_heat * mat.thickness
            pipe.insulation_thickness = mat.thickness
            pipe.sum_tk += mat.thickness / mat.conductivity
        
        pipe.insulation_resistance = resistance
        pipe.insulation_conductivity = tot_thickness / resistance if resistance > 0 else 0
        pipe.insulation_density = density / tot_thickness if tot_thickness > 0 else 0
        pipe.insulation_cp = sp_heat / tot_thickness if tot_thickness > 0 else 0
        pipe.insulation_thickness = tot_thickness
        
        mat = s_mat.materials[state.data_construction.construct[construction_num].layer_point[total_layers - 1]]
        pipe.pipe_conductivity = mat.conductivity
        pipe.pipe_density = mat.density
        pipe.pipe_cp = mat.spec_heat
        pipe.pipe_od = pipe.pipe_id + 2.0 * mat.thickness
        pipe.insulation_od = pipe.pipe_od + 2.0 * pipe.insulation_thickness
    else:
        errors_found = True
    
    return errors_found

def init_pipes_heat_transfer(pipe: PipeHTData, state: Any, first_hvac_iteration: bool) -> None:
    """Initialize pipe heat transfer."""
    sys_time_elapsed = state.data_hvac_globals.sys_time_elapsed
    time_step_sys_sec = state.data_hvac_globals.time_step_sys_sec
    routine_name = "InitPipesHeatTransfer"
    
    cur_sim_day = float(state.data_global.day_of_sim)
    
    state.data_pipe_ht.nsv_inlet_node_num = pipe.inlet_node_num
    state.data_pipe_ht.nsv_outlet_node_num = pipe.outlet_node_num
    state.data_pipe_ht.nsv_mass_flow_rate = state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate
    state.data_pipe_ht.nsv_inlet_temp = state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].temp
    
    if (state.data_global.begin_sim_flag and pipe.begin_sim_init) or \
       (state.data_global.begin_envrn_flag and pipe.begin_sim_envrn):
        
        if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
            for time_idx in range(TimeIndex.PREVIOUS, TimeIndex.TENTATIVE + 1):
                for length_idx in range(1, pipe.num_sections + 1):
                    for depth_idx in range(1, pipe.num_depth_nodes + 1):
                        for width_idx in range(1, pipe.pipe_node_width + 1):
                            current_depth = (depth_idx - 1) * pipe.ds_regular
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][time_idx - 1] = pipe.tbnd(state, current_depth)
        
        first_temperatures = 21.0
        pipe.tentative_fluid_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.fluid_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.previous_fluid_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.tentative_pipe_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.pipe_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.previous_pipe_temp = [first_temperatures] * (pipe.num_sections + 1)
        pipe.previous_sim_time = 0.0
        state.data_pipe_ht.nsv_delta_time = 0.0
        state.data_pipe_ht.nsv_outlet_temp = 0.0
        state.data_pipe_ht.nsv_environment_temp = 0.0
        state.data_pipe_ht.nsv_env_heat_loss_rate = 0.0
        state.data_pipe_ht.nsv_fluid_heat_loss_rate = 0.0
        
        pipe.begin_sim_init = False
        pipe.begin_sim_envrn = False
    
    if not state.data_global.begin_sim_flag:
        pipe.begin_sim_init = True
    if not state.data_global.begin_envrn_flag:
        pipe.begin_sim_envrn = True
    
    state.data_pipe_ht.nsv_delta_time = time_step_sys_sec
    state.data_pipe_ht.nsv_num_inner_time_steps = int(state.data_pipe_ht.nsv_delta_time / INNER_DELTA_TIME)
    
    if (first_hvac_iteration and pipe.first_hvac_update_flag) or \
       (state.data_global.begin_envrn_flag and pipe.begin_envrn_update_flag):
        
        if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
            for time_idx in range(1, TimeIndex.TENTATIVE + 1):
                for length_idx in range(1, pipe.num_sections + 1):
                    for depth_idx in range(1, pipe.num_depth_nodes + 1):
                        current_depth = (depth_idx - 1) * pipe.ds_regular
                        cur_temp = pipe.tbnd(state, current_depth)
                        pipe.t[1 - 1][depth_idx - 1][length_idx - 1][time_idx - 1] = cur_temp
                    for width_idx in range(1, pipe.pipe_node_width + 1):
                        current_depth = pipe.domain_depth
                        cur_temp = pipe.tbnd(state, current_depth)
                        pipe.t[width_idx - 1][pipe.num_depth_nodes - 1][length_idx - 1][time_idx - 1] = cur_temp
        
        if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
            pass
        elif pipe.environment_ptr == EnvrnPtr.OUTSIDE_AIR_ENV:
            state.data_pipe_ht.nsv_environment_temp = state.data_envrn.out_dry_bulb_temp
        elif pipe.environment_ptr == EnvrnPtr.ZONE_ENV:
            state.data_pipe_ht.nsv_environment_temp = state.data_zone_temp_predictor_corrector.zone_heat_balance[pipe.envr_zone_ptr].mat
        elif pipe.environment_ptr == EnvrnPtr.SCHEDULE_ENV:
            state.data_pipe_ht.nsv_environment_temp = pipe.envr_sched.get_current_val()
        elif pipe.environment_ptr == EnvrnPtr.NONE:
            state.data_pipe_ht.nsv_environment_temp = state.data_envrn.out_dry_bulb_temp
        
        pipe.begin_envrn_update_flag = False
        pipe.first_hvac_update_flag = False
    
    if not state.data_global.begin_envrn_flag:
        pipe.begin_envrn_update_flag = True
    if not first_hvac_iteration:
        pipe.first_hvac_update_flag = True
    
    pipe.current_sim_time = (state.data_global.day_of_sim - 1) * 24 + state.data_global.hour_of_day - 1 + \
                            (state.data_global.time_step - 1) * state.data_global.time_step_zone + sys_time_elapsed
    
    if abs(pipe.current_sim_time - pipe.previous_sim_time) > 1.0e-6:
        push_arrays = True
        pipe.previous_sim_time = pipe.current_sim_time
    else:
        push_arrays = False
    
    if push_arrays:
        if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
            for length_idx in range(2, pipe.num_sections + 1):
                for depth_idx in range(1, pipe.num_depth_nodes + 1):
                    for width_idx in range(2, pipe.pipe_node_width + 1):
                        pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1] = \
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1]
        
        pipe.fluid_temp = pipe.tentative_fluid_temp.copy()
        pipe.pipe_temp = pipe.tentative_pipe_temp.copy()
    else:
        for length_idx in range(2, pipe.num_sections + 1):
            for depth_idx in range(1, pipe.num_depth_nodes + 1):
                for width_idx in range(2, pipe.pipe_node_width + 1):
                    pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = \
                        pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
        
        pipe.tentative_fluid_temp = pipe.fluid_temp.copy()
        pipe.tentative_pipe_temp = pipe.pipe_temp.copy()
    
    pipe.fluid_spec_heat = pipe.plant_loc.loop.glycol.get_specific_heat(state, state.data_pipe_ht.nsv_inlet_temp, routine_name)
    pipe.fluid_density = pipe.plant_loc.loop.glycol.get_density(state, state.data_pipe_ht.nsv_inlet_temp, routine_name)
    
    pipe.fluid_heat_loss_rate = 0.0
    pipe.fluid_heat_loss_energy = 0.0
    pipe.environment_heat_loss_rate = 0.0
    pipe.env_heat_loss_energy = 0.0
    pipe.zone_heat_gain_rate = 0.0
    state.data_pipe_ht.nsv_fluid_heat_loss_rate = 0.0
    state.data_pipe_ht.nsv_env_heat_loss_rate = 0.0
    state.data_pipe_ht.nsv_outlet_temp = 0.0
    
    if pipe.fluid_density > 0.0:
        state.data_pipe_ht.nsv_volume_flow_rate = state.data_pipe_ht.nsv_mass_flow_rate / pipe.fluid_density

def calc_pipes_heat_transfer(pipe: PipeHTData, state: Any, length_index: Optional[int] = None) -> None:
    """Calculate pipes heat transfer."""
    
    if pipe.fluid_spec_heat <= 0.0 or pipe.fluid_density <= 0.0:
        state.data_pipe_ht.nsv_outlet_temp = pipe.tentative_fluid_temp[pipe.num_sections]
        state.data_pipe_ht.nsv_env_heat_loss_rate = 0.0
        state.data_pipe_ht.nsv_fluid_heat_loss_rate = 0.0
        return
    
    if pipe.environment_ptr != EnvrnPtr.GROUND_ENV:
        air_conv_coef = 1.0 / (1.0 / pipe.outside_pipe_heat_trans_coef(state) + pipe.insulation_resistance)
    else:
        air_conv_coef = 0.0
    
    fluid_conv_coef = pipe.calc_pipe_heat_trans_coef(state, state.data_pipe_ht.nsv_inlet_temp, 
                                                      state.data_pipe_ht.nsv_mass_flow_rate, pipe.pipe_id)
    
    if pipe.environment_ptr == EnvrnPtr.GROUND_ENV:
        env_heat_trans_coef = pipe.soil_conductivity / (pipe.ds_regular - (pipe.pipe_id / 2.0))
    elif pipe.environment_ptr == EnvrnPtr.OUTSIDE_AIR_ENV:
        env_heat_trans_coef = air_conv_coef
    elif pipe.environment_ptr == EnvrnPtr.ZONE_ENV:
        env_heat_trans_coef = air_conv_coef
    elif pipe.environment_ptr == EnvrnPtr.SCHEDULE_ENV:
        env_heat_trans_coef = air_conv_coef
    else:
        env_heat_trans_coef = 0.0
    
    fluid_node_heat_capacity = pipe.section_area * pipe.length / pipe.num_sections * pipe.fluid_spec_heat * pipe.fluid_density
    
    a1 = fluid_node_heat_capacity + state.data_pipe_ht.nsv_mass_flow_rate * pipe.fluid_spec_heat * state.data_pipe_ht.nsv_delta_time + \
         fluid_conv_coef * pipe.inside_area * state.data_pipe_ht.nsv_delta_time
    
    a2 = state.data_pipe_ht.nsv_mass_flow_rate * pipe.fluid_spec_heat * state.data_pipe_ht.nsv_delta_time
    
    a3 = fluid_conv_coef * pipe.inside_area * state.data_pipe_ht.nsv_delta_time
    
    a4 = fluid_node_heat_capacity
    
    b1 = pipe.pipe_heat_capacity + fluid_conv_coef * pipe.inside_area * state.data_pipe_ht.nsv_delta_time + \
         env_heat_trans_coef * pipe.outside_area * state.data_pipe_ht.nsv_delta_time
    
    b2 = a3
    
    b3 = env_heat_trans_coef * pipe.outside_area * state.data_pipe_ht.nsv_delta_time
    
    b4 = pipe.pipe_heat_capacity
    
    pipe.tentative_fluid_temp[0] = state.data_pipe_ht.nsv_inlet_temp
    pipe.tentative_pipe_temp[0] = pipe.pipe_temp[1]
    
    if length_index is not None:
        pipe_depth = pipe.pipe_node_depth
        pipe_width = pipe.pipe_node_width
        temp_below = pipe.t[pipe_width - 1][pipe_depth][length_index - 1][TimeIndex.CURRENT - 1]
        temp_beside = pipe.t[pipe_width - 2][pipe_depth - 1][length_index - 1][TimeIndex.CURRENT - 1]
        temp_above = pipe.t[pipe_width - 1][pipe_depth - 2][length_index - 1][TimeIndex.CURRENT - 1]
        state.data_pipe_ht.nsv_environment_temp = (temp_below + temp_beside + temp_above) / 3.0
        
        pipe.tentative_fluid_temp[length_index] = \
            (a2 * pipe.tentative_fluid_temp[length_index - 1] + \
             a3 / b1 * (b3 * state.data_pipe_ht.nsv_environment_temp + b4 * pipe.previous_pipe_temp[length_index]) + \
             a4 * pipe.previous_fluid_temp[length_index]) / (a1 - a3 * b2 / b1)
        
        pipe.tentative_pipe_temp[length_index] = \
            (b2 * pipe.tentative_fluid_temp[length_index] + b3 * state.data_pipe_ht.nsv_environment_temp + \
             b4 * pipe.previous_pipe_temp[length_index]) / b1
        
        numerator = state.data_pipe_ht.nsv_environment_temp - pipe.tentative_fluid_temp[length_index]
        denominator = env_heat_trans_coef * ((1 / env_heat_trans_coef) + pipe.sum_tk)
        surface_temp = state.data_pipe_ht.nsv_environment_temp - numerator / denominator if denominator != 0 else state.data_pipe_ht.nsv_environment_temp
        
        state.data_pipe_ht.nsv_env_heat_loss_rate += env_heat_trans_coef * pipe.outside_area * (surface_temp - state.data_pipe_ht.nsv_environment_temp)
    else:
        for curnode in range(1, pipe.num_sections + 1):
            pipe.tentative_fluid_temp[curnode] = \
                (a2 * pipe.tentative_fluid_temp[curnode - 1] + \
                 a3 / b1 * (b3 * state.data_pipe_ht.nsv_environment_temp + b4 * pipe.previous_pipe_temp[curnode]) + \
                 a4 * pipe.previous_fluid_temp[curnode]) / (a1 - a3 * b2 / b1)
            
            pipe.tentative_pipe_temp[curnode] = \
                (b2 * pipe.tentative_fluid_temp[curnode] + b3 * state.data_pipe_ht.nsv_environment_temp + \
                 b4 * pipe.previous_pipe_temp[curnode]) / b1
            
            numerator = state.data_pipe_ht.nsv_environment_temp - pipe.tentative_fluid_temp[curnode]
            denominator = env_heat_trans_coef * ((1 / env_heat_trans_coef) + pipe.sum_tk)
            surface_temp = state.data_pipe_ht.nsv_environment_temp - numerator / denominator if denominator != 0 else state.data_pipe_ht.nsv_environment_temp
            
            state.data_pipe_ht.nsv_env_heat_loss_rate += env_heat_trans_coef * pipe.outside_area * (surface_temp - state.data_pipe_ht.nsv_environment_temp)
    
    state.data_pipe_ht.nsv_fluid_heat_loss_rate = \
        state.data_pipe_ht.nsv_mass_flow_rate * pipe.fluid_spec_heat * \
        (pipe.tentative_fluid_temp[0] - pipe.tentative_fluid_temp[pipe.num_sections])
    
    state.data_pipe_ht.nsv_outlet_temp = pipe.tentative_fluid_temp[pipe.num_sections]

def calc_buried_pipe_soil(pipe: PipeHTData, state: Any) -> None:
    """Calculate buried pipe soil heat transfer."""
    const_num_sections = 20
    conv_crit = 0.05
    max_iterations = 200
    stef_boltzmann = 5.6697e-08
    
    pipe.fourier_ds = pipe.soil_diffusivity * state.data_pipe_ht.nsv_delta_time / (pipe.ds_regular ** 2)
    pipe.coef_a1 = pipe.fourier_ds / (1 + 4 * pipe.fourier_ds)
    pipe.coef_a2 = 1 / (1 + 4 * pipe.fourier_ds)
    
    t_o = [[[0.0 for _ in range(const_num_sections)] for _ in range(pipe.num_depth_nodes)] for _ in range(pipe.pipe_node_width)]
    
    for iteration_index in range(1, max_iterations + 1):
        if iteration_index == max_iterations:
            pass  # ShowWarningError
        
        for length_idx in range(2, pipe.num_sections + 1):
            for depth_idx in range(1, pipe.num_depth_nodes):
                for width_idx in range(2, pipe.pipe_node_width + 1):
                    t_o[width_idx - 1][depth_idx - 1][length_idx - 1] = pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1]
        
        for length_idx in range(1, pipe.num_sections + 1):
            for depth_idx in range(1, pipe.num_depth_nodes):
                for width_idx in range(2, pipe.pipe_node_width + 1):
                    
                    if depth_idx == 1:
                        node_past = pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.PREVIOUS - 1]
                        past_node_temp_abs = node_past + 273.15
                        sky_temp_abs = state.data_envrn.sky_temp + 273.15
                        top_roughness = pipe.soil_roughness
                        top_therm_abs = pipe.soil_therm_abs
                        top_solar_abs = pipe.soil_solar_abs
                        k_soil = pipe.soil_conductivity
                        ds = pipe.ds_regular
                        rho = pipe.soil_density
                        cp = pipe.soil_cp
                        
                        conv_coef = state.data_envrn.wind_speed * 5.0 + 3.26
                        
                        if abs(past_node_temp_abs - sky_temp_abs) > 1e-10:
                            rad_coef = stef_boltzmann * top_therm_abs * (past_node_temp_abs ** 4 - sky_temp_abs ** 4) / (past_node_temp_abs - sky_temp_abs)
                        else:
                            rad_coef = 0.0
                        
                        q_sol_absorbed = top_solar_abs * (max(state.data_envrn.solcos[2], 0.0) * state.data_envrn.beam_solar_rad + state.data_envrn.dif_solar_rad)
                        
                        if not pipe.solar_exposed:
                            rad_coef = 0.0
                            q_sol_absorbed = 0.0
                        
                        if width_idx == pipe.pipe_node_width:
                            node_below = pipe.t[width_idx - 1][depth_idx][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_left = pipe.t[width_idx - 2][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                            
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = \
                                (q_sol_absorbed + rad_coef * state.data_envrn.sky_temp + conv_coef * state.data_envrn.out_dry_bulb_temp + \
                                 (k_soil / ds) * (node_below + 2 * node_left) + (rho * cp / state.data_pipe_ht.nsv_delta_time) * node_past) / \
                                (rad_coef + conv_coef + 3 * (k_soil / ds) + (rho * cp / state.data_pipe_ht.nsv_delta_time))
                        else:
                            node_below = pipe.t[width_idx - 1][depth_idx][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_left = pipe.t[width_idx - 2][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_right = pipe.t[width_idx][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                            
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = \
                                (q_sol_absorbed + rad_coef * state.data_envrn.sky_temp + conv_coef * state.data_envrn.out_dry_bulb_temp + \
                                 (k_soil / ds) * (node_below + node_left + node_right) + (rho * cp / state.data_pipe_ht.nsv_delta_time) * node_past) / \
                                (rad_coef + conv_coef + 3 * (k_soil / ds) + (rho * cp / state.data_pipe_ht.nsv_delta_time))
                    
                    elif width_idx == pipe.pipe_node_width:
                        if depth_idx == pipe.pipe_node_depth:
                            calc_pipes_heat_transfer(pipe, state, length_idx)
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = pipe.pipe_temp[length_idx]
                        else:
                            node_left = pipe.t[width_idx - 2][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_above = pipe.t[width_idx - 1][depth_idx - 2][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_below = pipe.t[width_idx - 1][depth_idx][length_idx - 1][TimeIndex.CURRENT - 1]
                            node_past = pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 2]
                            a1 = pipe.coef_a1
                            a2 = pipe.coef_a2
                            
                            pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = \
                                a1 * (node_below + node_above + 2 * node_left) + a2 * node_past
                    
                    else:
                        a1 = pipe.coef_a1
                        a2 = pipe.coef_a2
                        node_below = pipe.t[width_idx - 1][depth_idx][length_idx - 1][TimeIndex.CURRENT - 1]
                        node_above = pipe.t[width_idx - 1][depth_idx - 2][length_idx - 1][TimeIndex.CURRENT - 1]
                        node_right = pipe.t[width_idx][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                        node_left = pipe.t[width_idx - 2][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 1]
                        node_past = pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.CURRENT - 2]
                        
                        pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1] = \
                            a1 * (node_below + node_above + node_right + node_left) + a2 * node_past
        
        converged = True
        for length_idx in range(2, pipe.num_sections + 1):
            for depth_idx in range(1, pipe.num_depth_nodes):
                for width_idx in range(2, pipe.pipe_node_width + 1):
                    ttemp = pipe.t[width_idx - 1][depth_idx - 1][length_idx - 1][TimeIndex.TENTATIVE - 1]
                    if abs(t_o[width_idx - 1][depth_idx - 1][length_idx - 1] - ttemp) > conv_crit:
                        converged = False
                        break
                if not converged:
                    break
            if not converged:
                break
        
        if converged:
            break

def update_pipes_heat_transfer(pipe: PipeHTData, state: Any) -> None:
    """Update pipes heat transfer."""
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].temp = state.data_pipe_ht.nsv_outlet_temp
    
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].temp_min = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].temp_min
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].temp_max = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].temp_max
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].mass_flow_rate = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].mass_flow_rate_min = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate_min
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].mass_flow_rate_max = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate_max
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].mass_flow_rate_min_avail = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate_min_avail
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].mass_flow_rate_max_avail = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].mass_flow_rate_max_avail
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].quality = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].quality
    
    if pipe.plant_loc.loop.pressure_sim_type == 0:  # NoPressure
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].press = \
            state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].press
    
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].enthalpy = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].enthalpy
    state.data_loop_nodes.node[state.data_pipe_ht.nsv_outlet_node_num].hum_rat = \
        state.data_loop_nodes.node[state.data_pipe_ht.nsv_inlet_node_num].hum_rat

def report_pipes_heat_transfer(pipe: PipeHTData, state: Any) -> None:
    """Report pipes heat transfer."""
    pipe.fluid_inlet_temp = state.data_pipe_ht.nsv_inlet_temp
    pipe.fluid_outlet_temp = state.data_pipe_ht.nsv_outlet_temp
    pipe.mass_flow_rate = state.data_pipe_ht.nsv_mass_flow_rate
    pipe.volume_flow_rate = state.data_pipe_ht.nsv_volume_flow_rate
    
    pipe.fluid_heat_loss_rate = state.data_pipe_ht.nsv_fluid_heat_loss_rate
    pipe.fluid_heat_loss_energy = state.data_pipe_ht.nsv_fluid_heat_loss_rate * state.data_pipe_ht.nsv_delta_time
    pipe.pipe_inlet_temp = pipe.pipe_temp[1]
    pipe.pipe_outlet_temp = pipe.pipe_temp[pipe.num_sections]
    
    pipe.environment_heat_loss_rate = state.data_pipe_ht.nsv_env_heat_loss_rate / max(state.data_pipe_ht.nsv_num_inner_time_steps, 1)
    pipe.env_heat_loss_energy = pipe.environment_heat_loss_rate * state.data_pipe_ht.nsv_delta_time
    
    if pipe.environment_ptr == EnvrnPtr.ZONE_ENV:
        pipe.zone_heat_gain_rate = pipe.environment_heat_loss_rate

def calc_zone_pipes_heat_gain(state: Any) -> None:
    """Calculate zone pipes heat gain."""
    if state.data_pipe_ht.nsv_num_of_pipe_ht == 0:
        return
    
    if state.data_global.begin_envrn_flag and state.data_pipe_ht.my_envrn_flag:
        for pipe in state.data_pipe_ht.pipe_ht:
            pipe.zone_heat_gain_rate = 0.0
        state.data_pipe_ht.my_envrn_flag = False
    
    if not state.data_global.begin_envrn_flag:
        state.data_pipe_ht.my_envrn_flag = True

def calc_pipe_heat_trans_coef(pipe: PipeHTData, state: Any, temperature: float, 
                               mass_flow_rate: float, diameter: float) -> float:
    """Calculate pipe heat transfer coefficient."""
    routine_name = "PipeHeatTransfer::CalcPipeHeatTransCoef:"
    max_laminar_re = 2300.0
    num_of_prop_divisions = 13
    
    temps = [1.85, 6.85, 11.85, 16.85, 21.85, 26.85, 31.85, 36.85, 41.85, 46.85, 51.85, 56.85, 61.85]
    pr_vals = [12.22, 10.26, 8.81, 7.56, 6.62, 5.83, 5.20, 4.62, 4.16, 3.77, 3.42, 3.15, 2.88]
    
    loop_num = pipe.plant_loc.loop_num
    
    idx = 0
    while idx < num_of_prop_divisions:
        if temperature < temps[idx]:
            break
        idx += 1
    
    if idx == 0:
        pr_actual = pr_vals[0]
    elif idx >= num_of_prop_divisions:
        pr_actual = pr_vals[num_of_prop_divisions - 1]
    else:
        interp_frac = (temperature - temps[idx - 1]) / (temps[idx] - temps[idx - 1])
        pr_actual = pr_vals[idx - 1] + interp_frac * (pr_vals[idx] - pr_vals[idx - 1])
    
    kactual = state.data_plant.plant_loop[loop_num].glycol.get_conductivity(state, pipe.fluid_temp[0], routine_name)
    mu_actual = state.data_plant.plant_loop[loop_num].glycol.get_viscosity(state, pipe.fluid_temp[0], routine_name) / 1000.0
    
    re_d = 4.0 * mass_flow_rate / (math.pi * mu_actual * diameter) if mu_actual > 0 else 0.0
    
    if re_d == 0.0:
        nu_d = 3.66
    else:
        if re_d >= max_laminar_re:
            nu_d = 0.023 * (re_d ** 0.8) * (pr_actual ** (1.0 / 3.0))
        else:
            nu_d = 3.66
    
    return kactual * nu_d / diameter

def outside_pipe_heat_trans_coef(pipe: PipeHTData, state: Any) -> float:
    """Calculate outside pipe heat transfer coefficient."""
    pr = 0.7
    cond_air = 0.025
    room_air_vel = 0.381
    natural_conv_nusselt = 0.36
    num_of_param_divisions = 5
    num_of_prop_divisions = 12
    
    c_coef = [0.989, 0.911, 0.683, 0.193, 0.027]
    m_exp = [0.33, 0.385, 0.466, 0.618, 0.805]
    upper_bound = [4.0, 40.0, 4000.0, 40000.0, 400000.0]
    temperatures = [-73.0, -23.0, -10.0, 0.0, 10.0, 20.0, 27.0, 30.0, 40.0, 50.0, 76.85, 126.85]
    dyn_visc = [75.52e-7, 11.37e-6, 12.44e-6, 13.3e-6, 14.18e-6, 15.08e-6, 15.75e-6, 16e-6, 16.95e-6, 17.91e-6, 20.92e-6, 26.41e-6]
    
    if pipe.type == 0:  # PipeInterior
        if pipe.environment_ptr == EnvrnPtr.SCHEDULE_ENV:
            air_temp = pipe.envr_sched.get_current_val()
            air_vel = pipe.envr_vel_sched.get_current_val()
        elif pipe.environment_ptr == EnvrnPtr.ZONE_ENV:
            air_temp = state.data_zone_temp_predictor_corrector.zone_heat_balance[pipe.envr_zone_ptr].mat
            air_vel = room_air_vel
        else:
            air_temp = 0.0
            air_vel = 0.0
    elif pipe.type == 1:  # PipeExterior
        if pipe.environment_ptr == EnvrnPtr.OUTSIDE_AIR_ENV:
            air_temp = state.data_loop_nodes.node[pipe.envr_air_node_num].temp
            air_vel = state.data_envrn.wind_speed
        else:
            air_temp = 0.0
            air_vel = 0.0
    else:
        air_temp = 0.0
        air_vel = 0.0
    
    pipe_od = pipe.insulation_od
    
    air_visc = 0.0
    for idx in range(num_of_prop_divisions):
        if air_temp <= temperatures[idx]:
            air_visc = dyn_visc[idx]
            break
    else:
        air_visc = dyn_visc[num_of_prop_divisions - 1]
    
    if air_visc > 0.0:
        re_d = air_vel * pipe_od / air_visc
    else:
        re_d = 0.0
    
    coef = c_coef[0]
    r_exp = m_exp[0]
    for idx in range(num_of_param_divisions):
        if re_d <= upper_bound[idx]:
            coef = c_coef[idx]
            r_exp = m_exp[idx]
            break
    else:
        coef = c_coef[num_of_param_divisions - 1]
        r_exp = m_exp[num_of_param_divisions - 1]
    
    nu_d = coef * (re_d ** r_exp) * (pr ** (1.0 / 3.0))
    nu_d = max(nu_d, natural_conv_nusselt)
    
    return cond_air * nu_d / pipe_od

def tbnd(pipe: PipeHTData, state: Any, z: float) -> float:
    """Return temperature on boundary."""
    cur_sim_time = state.data_global.day_of_sim * 86400.0
    return pipe.ground_temp_model.get_ground_temp_at_time_in_seconds(state, z, cur_sim_time)
