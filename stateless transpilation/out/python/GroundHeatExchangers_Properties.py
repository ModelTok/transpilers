# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus/Data/EnergyPlusData.hh
#   - state.data_ground_heat_exchanger.vert_props_vector: list of GLHEVertProps
# - show_fatal_error, show_severe_error, show_warning_error: from EnergyPlus/UtilityRoutines.hh

from typing import Dict, Any

hrs_per_month = 730.0
max_ts_in_hr = 60.0


class GFuncCalcMethod:
    Invalid = -1
    UniformHeatFlux = 0
    UniformBoreholeWallTemp = 1
    FullDesign = 2
    Num = 3


gfunc_calc_methods_strs = [
    "UHFCALC",
    "UBHWTCALC",
    "FULLDESIGN"
]


class ThermophysicalProps:
    def __init__(self):
        self.k = 0.0
        self.rho = 0.0
        self.cp = 0.0
        self.rho_cp = 0.0
        self.diffusivity = 0.0


class PipeProps(ThermophysicalProps):
    def __init__(self):
        super().__init__()
        self.out_dia = 0.0
        self.inner_dia = 0.0
        self.out_radius = 0.0
        self.inner_radius = 0.0
        self.thickness = 0.0


class GLHEVertProps:
    module_name = "GroundHeatExchanger:Vertical:Properties"
    
    def __init__(self, state, obj_name: str, j: Dict[str, Any]):
        self.name = ""
        self.bh_top_depth = 0.0
        self.bh_length = 0.0
        self.bh_diameter = 0.0
        self.grout = ThermophysicalProps()
        self.pipe = PipeProps()
        self.bh_utube_dist = 0.0
        
        for existing_obj in state.data_ground_heat_exchanger.vert_props_vector:
            if obj_name == existing_obj.name:
                show_fatal_error(state, f"Invalid input for {self.module_name} object: Duplicate name found: {existing_obj.name}")
        
        self.name = obj_name
        self.bh_top_depth = j["depth_of_top_of_borehole"]
        self.bh_length = j["borehole_length"]
        self.bh_diameter = j["borehole_diameter"]
        self.grout.k = j["grout_thermal_conductivity"]
        self.grout.rho_cp = j["grout_thermal_heat_capacity"]
        self.pipe.k = j["pipe_thermal_conductivity"]
        self.pipe.rho_cp = j["pipe_thermal_heat_capacity"]
        self.pipe.out_dia = j["pipe_outer_diameter"]
        self.pipe.thickness = j["pipe_thickness"]
        self.bh_utube_dist = j["u_tube_distance"]
        
        if self.bh_utube_dist < self.pipe.out_dia:
            show_warning_error(state, "Borehole shank spacing is less than the pipe diameter. U-tube spacing is reference from the u-tube pipe center.")
            show_warning_error(state, "Shank spacing is set to the outer pipe diameter.")
            self.bh_utube_dist = self.pipe.out_dia
        
        self.pipe.inner_dia = self.pipe.out_dia - 2 * self.pipe.thickness
        self.pipe.out_radius = self.pipe.out_dia / 2
        self.pipe.inner_radius = self.pipe.inner_dia / 2
    
    @staticmethod
    def get_vert_props(state, object_name: str):
        for my_obj in state.data_ground_heat_exchanger.vert_props_vector:
            if my_obj.name == object_name:
                return my_obj
        
        show_severe_error(state, f"Object=GroundHeatExchanger:Vertical:Properties, Name={object_name} - not found.")
        show_fatal_error(state, "Preceding errors cause program termination")


def show_fatal_error(state, message: str) -> None:
    raise RuntimeError(f"FATAL ERROR: {message}")


def show_severe_error(state, message: str) -> None:
    print(f"SEVERE ERROR: {message}")


def show_warning_error(state, message: str) -> None:
    print(f"WARNING: {message}")
