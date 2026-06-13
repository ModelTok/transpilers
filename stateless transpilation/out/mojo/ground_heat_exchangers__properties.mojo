# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus/Data/EnergyPlusData.hh
#   - state.data_ground_heat_exchanger.vert_props_vector: list of GLHEVertProps
# - show_fatal_error, show_severe_error, show_warning_error: from EnergyPlus/UtilityRoutines.hh

alias hrs_per_month = 730.0
alias max_ts_in_hr = 60.0
alias MODULE_NAME = "GroundHeatExchanger:Vertical:Properties"


struct GFuncCalcMethod:
    alias Invalid = -1
    alias UniformHeatFlux = 0
    alias UniformBoreholeWallTemp = 1
    alias FullDesign = 2
    alias Num = 3


var gfunc_calc_methods_strs = List[String]()

fn _init_gfunc_strings() -> None:
    gfunc_calc_methods_strs.append("UHFCALC")
    gfunc_calc_methods_strs.append("UBHWTCALC")
    gfunc_calc_methods_strs.append("FULLDESIGN")


struct ThermophysicalProps:
    var k: Float64
    var rho: Float64
    var cp: Float64
    var rho_cp: Float64
    var diffusivity: Float64
    
    fn __init__(inout self):
        self.k = 0.0
        self.rho = 0.0
        self.cp = 0.0
        self.rho_cp = 0.0
        self.diffusivity = 0.0


struct PipeProps:
    var k: Float64
    var rho: Float64
    var cp: Float64
    var rho_cp: Float64
    var diffusivity: Float64
    var out_dia: Float64
    var inner_dia: Float64
    var out_radius: Float64
    var inner_radius: Float64
    var thickness: Float64
    
    fn __init__(inout self):
        self.k = 0.0
        self.rho = 0.0
        self.cp = 0.0
        self.rho_cp = 0.0
        self.diffusivity = 0.0
        self.out_dia = 0.0
        self.inner_dia = 0.0
        self.out_radius = 0.0
        self.inner_radius = 0.0
        self.thickness = 0.0


struct GLHEVertProps:
    var name: String
    var bh_top_depth: Float64
    var bh_length: Float64
    var bh_diameter: Float64
    var grout: ThermophysicalProps
    var pipe: PipeProps
    var bh_utube_dist: Float64
    
    fn __init__(inout self, state, obj_name: String, j):
        self.name = ""
        self.bh_top_depth = 0.0
        self.bh_length = 0.0
        self.bh_diameter = 0.0
        self.grout = ThermophysicalProps()
        self.pipe = PipeProps()
        self.bh_utube_dist = 0.0
        
        for existing_obj in state.data_ground_heat_exchanger.vert_props_vector:
            if obj_name == existing_obj.name:
                show_fatal_error(state, "Invalid input for " + MODULE_NAME + " object: Duplicate name found: " + existing_obj.name)
        
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
    
    fn get_vert_props(state, object_name: String):
        for my_obj in state.data_ground_heat_exchanger.vert_props_vector:
            if my_obj.name == object_name:
                return my_obj
        
        show_severe_error(state, "Object=GroundHeatExchanger:Vertical:Properties, Name=" + object_name + " - not found.")
        show_fatal_error(state, "Preceding errors cause program termination")


fn show_fatal_error(state, message: String) -> None:
    raise Error("FATAL ERROR: " + message)


fn show_severe_error(state, message: String) -> None:
    print("SEVERE ERROR: " + message)


fn show_warning_error(state, message: String) -> None:
    print("WARNING: " + message)
