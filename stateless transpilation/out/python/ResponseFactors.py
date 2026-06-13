# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: EnergyPlus/Data/EnergyPlusData.hh
# - GLHEVertProps: EnergyPlus/GroundHeatExchangers/Properties.hh
# - GLHEVertSingle: EnergyPlus/GroundHeatExchangers/BoreholeSingle.hh
# - GLHEVertArray: EnergyPlus/GroundHeatExchangers/BoreholeArray.hh
# - ShowFatalError: EnergyPlus/UtilityRoutines.hh
# - ShowSevereError: EnergyPlus/UtilityRoutines.hh
# - MyCartesian: geometry utility struct
# - format: EnergyPlus string formatting utility
# - makeUPPER: string utility

from typing import List, Optional, Any, Dict
import math

Real64 = float


class MyCartesian:
    def __init__(self, x: Real64 = 0.0, y: Real64 = 0.0, z: Real64 = 0.0):
        self.x = x
        self.y = y
        self.z = z


class GLHEVertProps:
    pass


class GLHEVertSingle:
    pass


class GLHEVertArray:
    pass


class EnergyPlusData:
    pass


def show_fatal_error(state: Any, message: str) -> None:
    raise RuntimeError(message)


def show_severe_error(state: Any, message: str) -> None:
    pass


def make_upper(s: str) -> str:
    return s.upper()


class GLHEResponseFactors:
    MODULE_NAME = "GroundHeatExchanger:ResponseFactors"

    def __init__(self, state: Optional[EnergyPlusData] = None, obj_name: str = "", j: Optional[Dict[str, Any]] = None):
        self.name: str = ""
        self.num_boreholes: int = 0
        self.num_gfunc_pairs: int = 0
        self.g_ref_ratio: Real64 = 0.0
        self.max_sim_years: Real64 = 0.0
        self.time: List[Real64] = []
        self.lntts: List[Real64] = []
        self.gfnc: List[Real64] = []
        self.props: Optional[GLHEVertProps] = None
        self.my_boreholes: List[GLHEVertSingle] = []

        if state is not None and j is not None:
            for existing_obj in state.data_ground_heat_exchanger.vert_props_vector:
                if obj_name == existing_obj.name:
                    show_fatal_error(state, f"Invalid input for {self.MODULE_NAME} object: Duplicate name found: {existing_obj.name}")

            self.name = obj_name
            self.props = GLHEVertProps.GetVertProps(
                state,
                make_upper(j["ghe_vertical_properties_object_name"])
            )
            self.num_boreholes = j["number_of_boreholes"]
            self.g_ref_ratio = j["g_function_reference_ratio"]
            self.max_sim_years = state.data_envrn.max_number_sim_years

            vars_list = j["g_functions"]
            for var in vars_list:
                self.lntts.append(var["g_function_ln_t_ts_value"])
                self.gfnc.append(var["g_function_g_value"])

            self.num_gfunc_pairs = len(self.lntts)

    def setup_bh_points_for_response_factors_object(self) -> None:
        for this_bh in self.my_boreholes:
            num_panels_i = 50
            num_panels_ii = 50
            num_panels_j = 560

            this_bh.dl_i = this_bh.props.bh_length / num_panels_i
            for i in range(num_panels_i + 1):
                new_point = MyCartesian()
                new_point.x = this_bh.x_loc
                new_point.y = this_bh.y_loc
                new_point.z = this_bh.props.bh_top_depth + (i * this_bh.dl_i)
                this_bh.point_locations_i.append(new_point)

            this_bh.dl_ii = this_bh.props.bh_length / num_panels_ii
            for i in range(num_panels_ii + 1):
                new_point = MyCartesian()
                new_point.x = this_bh.x_loc + (this_bh.props.bh_diameter / 2.0) / math.sqrt(2.0)
                new_point.y = this_bh.y_loc + (this_bh.props.bh_diameter / 2.0) / (-math.sqrt(2.0))
                new_point.z = this_bh.props.bh_top_depth + (i * this_bh.dl_ii)
                this_bh.point_locations_ii.append(new_point)

            this_bh.dl_j = this_bh.props.bh_length / num_panels_j
            for i in range(num_panels_j + 1):
                new_point = MyCartesian()
                new_point.x = this_bh.x_loc
                new_point.y = this_bh.y_loc
                new_point.z = this_bh.props.bh_top_depth + (i * this_bh.dl_j)
                this_bh.point_locations_j.append(new_point)


def get_response_factor(state: EnergyPlusData, object_name: str) -> GLHEResponseFactors:
    for my_obj in state.data_ground_heat_exchanger.response_factors_vector:
        if my_obj.name == object_name:
            return my_obj

    show_severe_error(state, f"Object=GroundHeatExchanger:ResponseFactors, Name={object_name} - not found.")
    show_fatal_error(state, "Preceding errors cause program termination")


def build_and_get_response_factor_object_from_array(state: EnergyPlusData, array_object_ptr: GLHEVertArray) -> GLHEResponseFactors:
    this_rf = GLHEResponseFactors()
    this_rf.name = array_object_ptr.name
    this_rf.props = array_object_ptr.props

    x_loc = 0.0
    bh_counter = 0
    for x_bh in range(1, array_object_ptr.num_bh_in_x_direction + 1):
        y_loc = 0.0
        for y_bh in range(1, array_object_ptr.num_bh_in_y_direction + 1):
            bh_counter += 1
            this_bh = GLHEVertSingle()
            this_bh.name = f"{this_rf.name} BH {bh_counter} loc: ({x_loc}, {y_loc})"
            this_bh.props = GLHEVertProps.GetVertProps(state, array_object_ptr.props.name)
            this_bh.x_loc = x_loc
            this_bh.y_loc = y_loc
            this_rf.my_boreholes.append(this_bh)
            state.data_ground_heat_exchanger.single_boreholes_vector.append(this_bh)
            y_loc += array_object_ptr.bh_spacing
            this_rf.num_boreholes += 1
        x_loc += array_object_ptr.bh_spacing

    this_rf.setup_bh_points_for_response_factors_object()
    state.data_ground_heat_exchanger.response_factors_vector.append(this_rf)
    return this_rf


def build_and_get_response_factors_object_from_single_bhs(state: EnergyPlusData, single_bhs_for_rf_vect: List[GLHEVertSingle]) -> GLHEResponseFactors:
    this_rf = GLHEResponseFactors()
    this_rf.name = f"Response Factor Object Auto Generated No: {state.data_ground_heat_exchanger.num_auto_generated_response_factors + 1}"

    this_props = GLHEVertProps()
    this_props.name = f"Response Factor Auto Generated Mean Props No: {state.data_ground_heat_exchanger.num_auto_generated_response_factors + 1}"

    for this_bh in single_bhs_for_rf_vect:
        this_props.bh_diameter += this_bh.props.bh_diameter
        this_props.bh_length += this_bh.props.bh_length
        this_props.bh_top_depth += this_bh.props.bh_top_depth
        this_props.bh_utube_dist += this_bh.props.bh_utube_dist

        this_props.grout.cp += this_bh.props.grout.cp
        this_props.grout.diffusivity += this_bh.props.grout.diffusivity
        this_props.grout.k += this_bh.props.grout.k
        this_props.grout.rho += this_bh.props.grout.rho
        this_props.grout.rho_cp += this_bh.props.grout.rho_cp

        this_props.pipe.cp += this_bh.props.pipe.cp
        this_props.pipe.diffusivity += this_bh.props.pipe.diffusivity
        this_props.pipe.k += this_bh.props.pipe.k
        this_props.pipe.rho += this_bh.props.pipe.rho
        this_props.pipe.rho_cp += this_bh.props.pipe.rho_cp

        this_props.pipe.out_dia += this_bh.props.pipe.out_dia
        this_props.pipe.thickness += this_bh.props.pipe.thickness

        this_props.pipe.inner_dia += (this_bh.props.pipe.out_dia - 2 * this_bh.props.pipe.thickness)

        this_rf.my_boreholes.append(this_bh)

    num_bh = len(single_bhs_for_rf_vect)

    this_props.bh_diameter /= num_bh
    this_props.bh_length /= num_bh
    this_props.bh_top_depth /= num_bh
    this_props.bh_utube_dist /= num_bh

    this_props.grout.cp /= num_bh
    this_props.grout.diffusivity /= num_bh
    this_props.grout.k /= num_bh
    this_props.grout.rho /= num_bh
    this_props.grout.rho_cp /= num_bh

    this_props.pipe.cp /= num_bh
    this_props.pipe.diffusivity /= num_bh
    this_props.pipe.k /= num_bh
    this_props.pipe.rho /= num_bh
    this_props.pipe.rho_cp /= num_bh

    this_props.pipe.out_dia /= num_bh
    this_props.pipe.thickness /= num_bh

    this_props.pipe.inner_dia /= num_bh

    this_rf.props = this_props
    this_rf.num_boreholes = len(this_rf.my_boreholes)
    state.data_ground_heat_exchanger.vert_props_vector.append(this_props)

    this_rf.setup_bh_points_for_response_factors_object()

    state.data_ground_heat_exchanger.response_factors_vector.append(this_rf)

    state.data_ground_heat_exchanger.num_auto_generated_response_factors += 1

    return this_rf
