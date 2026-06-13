from math import sin, cos, abs as math_abs, pow, min, max
from memory import UnsafePointer
from sys import sizeof

alias REAL64 = Float64

struct ShadePosition:
    alias Invalid = -1
    alias NoShade = 0
    alias Interior = 1
    alias Exterior = 2
    alias Between = 3
    alias Num = 4


struct SurfaceData:
    pass


struct SurfaceWindowCalc:
    pass


struct FrameDividerData:
    pass


struct EnergyPlusData:
    pass


struct Constant:
    alias Kelvin = 273.15
    alias StefanBoltzmann = 5.6697e-08
    alias DegToRad = 0.017453292519943


struct Material:
    @staticmethod
    fn get_slat_indices_interp_fac(slat_ang: REAL64) -> Tuple[Int32, Int32, REAL64]:
        return (0, 0, 0.0)


@always_inline
fn interp(y1: REAL64, y2: REAL64, frac: REAL64) -> REAL64:
    return y1 + frac * (y2 - y1)


fn calc_window_heat_balance_external_routines(
    state: UnsafePointer[EnergyPlusData],
    surf_num: Int32,
    hext_conv_coeff: REAL64,
) -> Tuple[REAL64, REAL64]:
    let solution_tolerance: REAL64 = 0.02

    var surf_inside_temp: REAL64 = 0.0
    var surf_outside_temp: REAL64 = 0.0

    return (surf_inside_temp, surf_outside_temp)


fn get_igu_u_value_for_nfrc_report(
    state: UnsafePointer[EnergyPlusData],
    surf_num: Int32,
    constr_num: Int32,
    window_width: REAL64,
    window_height: REAL64,
) -> REAL64:
    let tilt: REAL64 = 90.0
    var result: REAL64 = 0.0
    return result


fn get_shgc_value_for_nfrc_reporting(
    state: UnsafePointer[EnergyPlusData],
    surf_num: Int32,
    constr_num: Int32,
    window_width: REAL64,
    window_height: REAL64,
) -> REAL64:
    let tilt: REAL64 = 90.0
    var result: REAL64 = 0.0
    return result


fn get_window_assembly_nfrc_for_report(
    state: UnsafePointer[EnergyPlusData],
    surf_num: Int32,
    constr_num: Int32,
    window_width: REAL64,
    window_height: REAL64,
    vision: Int32,
) -> Tuple[REAL64, REAL64, REAL64]:
    var uvalue: REAL64 = 0.0
    var shgc: REAL64 = 0.0
    var vt: REAL64 = 0.0

    let frame_h_ext_conv_coeff: REAL64 = 30.0
    let frame_h_int_conv_coeff: REAL64 = 8.0
    let tilt: REAL64 = 90.0

    return (uvalue, shgc, vt)


struct CWCEHeatTransferFactory:
    var m_surface: SurfaceData
    var m_window: SurfaceWindowCalc
    var m_shade_position: Int32
    var m_surf_num: Int32
    var m_solid_layer_index: Int32
    var m_construction_number: Int32
    var m_tot_lay: Int32
    var m_interior_bsdf_shade: Bool
    var m_exterior_shade: Bool

    fn __init__(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        surface: SurfaceData,
        t_surf_num: Int32,
        t_constr_num: Int32,
    ):
        self.m_surface = surface
        self.m_window = SurfaceWindowCalc()
        self.m_shade_position = ShadePosition.NoShade
        self.m_surf_num = t_surf_num
        self.m_solid_layer_index = 0
        self.m_construction_number = t_constr_num
        self.m_tot_lay = self.get_num_of_layers(state)
        self.m_interior_bsdf_shade = False
        self.m_exterior_shade = False

    fn get_tarcog_system(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        t_hext_conv_coeff: REAL64,
    ):
        pass

    fn get_tarcog_system_for_reporting(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        use_summer_conditions: Bool,
        width: REAL64,
        height: REAL64,
        tilt: REAL64,
    ):
        pass

    fn get_layer_material(
        self,
        state: UnsafePointer[EnergyPlusData],
        t_index: Int32,
    ):
        pass

    fn get_igu_layer(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        t_index: Int32,
    ):
        pass

    fn get_num_of_layers(
        self,
        state: UnsafePointer[EnergyPlusData],
    ) -> Int32:
        return 0

    fn get_solid_layer(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        mat: UnsafePointer[UInt8],
        t_index: Int32,
    ):
        pass

    fn get_gap_layer(
        self,
        material: UnsafePointer[UInt8],
    ):
        pass

    fn get_shade_to_glass_layer(
        self,
        state: UnsafePointer[EnergyPlusData],
        t_index: Int32,
    ):
        pass

    fn get_complex_gap_layer(
        self,
        state: UnsafePointer[EnergyPlusData],
        material_base: UnsafePointer[UInt8],
    ):
        pass

    fn get_gas(
        self,
        material_base: UnsafePointer[UInt8],
    ):
        pass

    @staticmethod
    fn get_air():
        pass

    fn get_indoor(
        self,
        state: UnsafePointer[EnergyPlusData],
    ):
        pass

    fn get_outdoor(
        self,
        state: UnsafePointer[EnergyPlusData],
        t_hext: REAL64,
    ):
        pass

    fn get_igu(self):
        pass

    fn get_igu_with_dims(
        self,
        width: REAL64,
        height: REAL64,
        tilt: REAL64,
    ):
        pass

    @staticmethod
    fn get_active_construction_number(
        state: UnsafePointer[EnergyPlusData],
        surface: SurfaceData,
        t_surf_num: Int32,
    ) -> Int32:
        return 0

    fn is_interior_shade(self) -> Bool:
        return self.m_interior_bsdf_shade

    fn get_outdoor_nfrc(
        self,
        use_summer_conditions: Bool,
    ):
        pass

    fn get_indoor_nfrc(
        self,
        use_summer_conditions: Bool,
    ):
        pass

    @staticmethod
    fn get_shade_type(
        state: UnsafePointer[EnergyPlusData],
        constr_num: Int32,
    ) -> Int32:
        return 0

    fn overall_ufactor_from_films_and_cond(
        self,
        conductance: REAL64,
        inside_film: REAL64,
        outside_film: REAL64,
    ) -> REAL64:
        var r_overall: REAL64 = 0.0
        var u_factor: REAL64 = 0.0
        if inside_film != 0 and outside_film != 0.0 and conductance != 0.0:
            r_overall = 1.0 / inside_film + 1.0 / conductance + 1.0 / outside_film
        if r_overall != 0.0:
            u_factor = 1.0 / r_overall
        return u_factor
