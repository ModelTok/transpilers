from typing import Protocol, Optional, List, Any, Callable
from enum import IntEnum
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: simulation state container (see Data/EnergyPlusData.hh)
# - DataSurfaces.SurfaceData: surface properties
# - DataSurfaces.SurfaceWindowCalc: surface window properties
# - DataSurfaces.NfrcVisionType: enum for NFRC reporting types
# - DataHeatBalance.MaterialBase: material base class (hierarchy: MaterialGlass, MaterialBlind, MaterialShade, MaterialScreen, MaterialComplexShade, MaterialGasMix, MaterialComplexWindowGap)
# - DataConstruction.Construct: construction data
# - DataEnvironment: environmental data (temperature, pressure, wind, sky, clouds)
# - DataHeatBalSurface: surface heat balance data
# - Tarcog.ISO15099: thermal calculation engine (CSingleSystem, CBaseIGULayer, CEnvironment, CIGU, IIGUSystem, CSystem, FrameData, WindowSingleVision, DualVisionHorizontal, DualVisionVertical, CIndoorEnvironment, COutdoorEnvironment, CIGUSolidLayer, CIGUShadeLayer, CShadeOpenings, CIGUGapLayer, ISurface, CSurface, Environments, BoundaryConditionsCoeffModel, SkyModel, AirHorizontalDirection, EnumSide, Side)
# - Gases.CGas, CGasData, CIntCoeff: gas properties
# - FenestrationCommon: common types (WavelengthRange, ScatteringSimple, Side, EnumSide)
# - MultiLayerOptics.CMultiLayerScattered: optical calculations
# - CWindowConstructionsSimplified: construction optics instance
# - Constant: constants module (Kelvin, StefanBoltzmann, DegToRad)
# - Material: material lookups (GetSlatIndicesInterpFac)
# - General.Interp: interpolation
# - UtilityRoutines: error reporting (ShowSevereError, ShowContinueError, ANY_SHADE_SCREEN, ANY_BLIND, ANY_INTERIOR_SHADE_BLIND, ANY_EXTERIOR_SHADE_BLIND_SCREEN, ANY_BETWEENGLASS_SHADE_BLIND)


class ShadePosition(IntEnum):
    Invalid = -1
    NoShade = 0
    Interior = 1
    Exterior = 2
    Between = 3
    Num = 4


class SurfaceData(Protocol):
    def getInsideAirTemperature(self, state: Any, surf_num: int) -> float: ...
    def getOutsideAirTemperature(self, state: Any, surf_num: int) -> float: ...
    def getOutsideIR(self, state: Any, surf_num: int) -> float: ...
    def getSWIncident(self, state: Any, surf_num: int) -> float: ...
    def getTotLayers(self, state: Any) -> int: ...
    @property
    def Construction(self) -> int: ...
    @property
    def Width(self) -> float: ...
    @property
    def Height(self) -> float: ...
    @property
    def Tilt(self) -> float: ...
    @property
    def Area(self) -> float: ...
    @property
    def SolarEnclIndex(self) -> int: ...
    @property
    def FrameDivider(self) -> int: ...
    @property
    def ExtWind(self) -> bool: ...


class SurfaceWindowCalc(Protocol):
    @property
    def thetaFace(self) -> Any: ...
    @property
    def screenNum(self) -> int: ...


class FrameDividerData(Protocol):
    @property
    def FrameConductance(self) -> float: ...
    @property
    def FrEdgeToCenterGlCondRatio(self) -> float: ...
    @property
    def FrameWidth(self) -> float: ...
    @property
    def FrameProjectionIn(self) -> float: ...
    @property
    def FrameSolAbsorp(self) -> float: ...
    @property
    def DividerConductance(self) -> float: ...
    @property
    def DivEdgeToCenterGlCondRatio(self) -> float: ...
    @property
    def DividerWidth(self) -> float: ...
    @property
    def DividerProjectionIn(self) -> float: ...
    @property
    def DividerSolAbsorp(self) -> float: ...
    @property
    def HorDividers(self) -> int: ...
    @property
    def VertDividers(self) -> int: ...


class EnergyPlusData(Protocol):
    class DataSurfaceProxy(Protocol):
        def Surface(self, idx: int) -> SurfaceData: ...
        def SurfaceWindow(self, idx: int) -> SurfaceWindowCalc: ...
        def FrameDivider(self, idx: int) -> FrameDividerData: ...
        def surfShades(self, idx: int) -> Any: ...
        @property
        def SurfWinShadingFlag(self) -> Any: ...
        @property
        def SurfWinActiveShadedConstruction(self) -> Any: ...
        @property
        def SurfWinIRfromParentZone(self) -> Any: ...
        @property
        def SurfWinDividerArea(self) -> Any: ...
        @property
        def SurfWinEffInsSurfTemp(self) -> Any: ...
        @property
        def SurfWinTransSolar(self) -> Any: ...
        @property
        def SurfWinHeatGain(self) -> Any: ...
        @property
        def SurfWinGainIRGlazToZoneRep(self) -> Any: ...
        @property
        def SurfWinGainConvGlazToZoneRep(self) -> Any: ...
        @property
        def SurfWinLossSWZoneToOutWinRep(self) -> Any: ...
        @property
        def SurfOutWindSpeed(self) -> Any: ...

    class DataConstructionProxy(Protocol):
        def Construct(self, idx: int) -> Any: ...

    class DataHeatBalSurfaceProxy(Protocol):
        @property
        def SurfHConvInt(self) -> Any: ...
        @property
        def SurfQdotRadHVACInPerArea(self) -> Any: ...
        @property
        def SurfWinInitialBeamSolInTrans(self) -> Any: ...
        @property
        def SurfWinInitialDifSolInTrans(self) -> Any: ...

    class DataHeatBalProxy(Protocol):
        @property
        def EnclSolQSWRad(self) -> Any: ...
        @property
        def SurfWinFenLaySurfTempFront(self) -> Any: ...
        @property
        def SurfWinFenLaySurfTempBack(self) -> Any: ...

    class DataEnvironmentProxy(Protocol):
        @property
        def OutBaroPress(self) -> float: ...
        @property
        def SkyTempKelvin(self) -> float: ...
        @property
        def CloudFraction(self) -> float: ...

    class DataMaterialProxy(Protocol):
        def materials(self, idx: int) -> Any: ...

    class DataWindowManagerProxy(Protocol):
        @property
        def thetas(self) -> List[float]: ...
        @property
        def nglface(self) -> int: ...
        @property
        def nglfacep(self) -> int: ...
        @property
        def inExtWindowModel(self) -> Any: ...

    @property
    def dataSurface(self) -> DataSurfaceProxy: ...
    @property
    def dataConstruction(self) -> DataConstructionProxy: ...
    @property
    def dataHeatBalSurf(self) -> DataHeatBalSurfaceProxy: ...
    @property
    def dataHeatBal(self) -> DataHeatBalProxy: ...
    @property
    def dataEnvrn(self) -> DataEnvironmentProxy: ...
    @property
    def dataMaterial(self) -> DataMaterialProxy: ...
    @property
    def dataWindowManager(self) -> DataWindowManagerProxy: ...


class Constant:
    Kelvin = 273.15
    StefanBoltzmann = 5.6697e-08
    DegToRad = 0.017453292519943


class Material:
    @staticmethod
    def GetSlatIndicesInterpFac(slat_ang: float) -> tuple:
        pass


class Interp:
    @staticmethod
    def __call__(y1: float, y2: float, frac: float) -> float:
        return y1 + frac * (y2 - y1)

Interp = Interp()


def calc_window_heat_balance_external_routines(
    state: EnergyPlusData,
    surf_num: int,
    hext_conv_coeff: float,
) -> tuple:
    surf = state.dataSurface.Surface(surf_num)
    surf_win = state.dataSurface.SurfaceWindow(surf_num)
    constr_num = surf.Construction
    construction = state.dataConstruction.Construct(constr_num)

    solution_tolerance = 0.02

    active_constr_num = CWCEHeatTransferFactory.get_active_construction_number(state, surf, surf_num)
    a_factory = CWCEHeatTransferFactory(state, surf, surf_num, active_constr_num)
    a_system = a_factory.get_tarcog_system(state, hext_conv_coeff)
    a_system.set_tolerance(solution_tolerance)

    guess = []
    tot_solid_layers = construction.TotSolidLayers

    if any_shade_screen(state.dataSurface.SurfWinShadingFlag(surf_num)) or any_blind(state.dataSurface.SurfWinShadingFlag(surf_num)):
        tot_solid_layers += 1

    for k in range(1, 2 * tot_solid_layers + 1):
        guess.append(state.dataSurface.SurfaceWindow(surf_num).thetaFace[k])

    try:
        a_system.set_initial_guess(guess)
        a_system.solve()
    except Exception as ex:
        show_severe_error(state, "Error in Windows Calculation Engine Exterior Module.")
        show_continue_error(state, str(ex))

    a_layers = a_system.get_solid_layers()
    i = 1
    surf_inside_temp = 0.0
    surf_outside_temp = 0.0
    for a_layer in a_layers:
        a_temp = 0.0
        for a_side in fenestration_common_enum_side():
            a_temp = a_layer.get_temperature(a_side)
            state.dataWindowManager.thetas[i - 1] = a_temp
            if i == 1:
                surf_outside_temp = a_temp - Constant.Kelvin
            i += 1
        surf_inside_temp = a_temp - Constant.Kelvin
        if any_interior_shade_blind(state.dataSurface.SurfWinShadingFlag(surf_num)):
            surf_shade = state.dataSurface.surfShades(surf_num)
            eff_sh_bl_emiss = surf_shade.effShadeEmi
            eff_gl_emiss = surf_shade.effGlassEmi
            if surf_shade.blind.movableSlats:
                surf_shade.effShadeEmi = Interp(
                    construction.effShadeBlindEmi[surf_shade.blind.slatAngIdxLo],
                    construction.effShadeBlindEmi[surf_shade.blind.slatAngIdxHi],
                    surf_shade.blind.slatAngInterpFac
                )
                surf_shade.effGlassEmi = Interp(
                    construction.effGlassEmi[surf_shade.blind.slatAngIdxLo],
                    construction.effGlassEmi[surf_shade.blind.slatAngIdxHi],
                    surf_shade.blind.slatAngInterpFac
                )
            state.dataSurface.SurfWinEffInsSurfTemp(surf_num) = \
                (eff_sh_bl_emiss * surf_inside_temp + eff_gl_emiss * (state.dataWindowManager.thetas[2 * tot_solid_layers - 3] - Constant.Kelvin)) / \
                (eff_sh_bl_emiss + eff_gl_emiss)

    state.dataHeatBalSurf.SurfHConvInt(surf_num) = a_system.get_hc("Indoor")
    if any_interior_shade_blind(state.dataSurface.SurfWinShadingFlag(surf_num)) or a_factory.is_interior_shade():
        surf_shade = state.dataSurface.surfShades(surf_num)
        tot_layers = len(a_layers)
        state.dataWindowManager.nglface = 2 * tot_layers - 2
        state.dataWindowManager.nglfacep = state.dataWindowManager.nglface + 2
        a_shade_layer = a_layers[tot_layers - 1]
        a_glass_layer = a_layers[tot_layers - 2]
        shade_area = state.dataSurface.Surface(surf_num).Area + state.dataSurface.SurfWinDividerArea(surf_num)
        front_surface = a_shade_layer.get_surface("Front")
        back_surface = a_shade_layer.get_surface("Back")
        eps_sh_ir1 = front_surface.get_emissivity()
        eps_sh_ir2 = back_surface.get_emissivity()
        tau_sh_ir = front_surface.get_transmittance()
        rho_sh_ir1 = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir1)
        rho_sh_ir2 = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir2)
        glass_emiss = a_glass_layer.get_surface("Back").get_emissivity()
        rho_gl_ir2 = 1.0 - glass_emiss
        sh_gl_refl_fac_ir = 1.0 - rho_gl_ir2 * rho_sh_ir1
        rmir = state.dataSurface.SurfWinIRfromParentZone(surf_num) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(surf_num)
        net_ir_heat_gain_shade = \
            shade_area * eps_sh_ir2 * \
                (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 1], 4) - rmir) + \
            eps_sh_ir1 * (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 2], 4) - rmir) * \
                rho_gl_ir2 * tau_sh_ir / sh_gl_refl_fac_ir
        net_ir_heat_gain_glass = \
            shade_area * (glass_emiss * tau_sh_ir / sh_gl_refl_fac_ir) * \
            (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglface - 1], 4) - rmir)
        tind = surf.getInsideAirTemperature(state, surf_num) + Constant.Kelvin
        conv_heat_gain_fr_zone_side_of_shade = shade_area * state.dataHeatBalSurf.SurfHConvInt(surf_num) * \
                                               (state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 1] - tind)
        state.dataSurface.SurfWinHeatGain(surf_num) = \
            state.dataSurface.SurfWinTransSolar(surf_num) + conv_heat_gain_fr_zone_side_of_shade + net_ir_heat_gain_glass + net_ir_heat_gain_shade

        state.dataSurface.SurfWinGainIRGlazToZoneRep(surf_num) = net_ir_heat_gain_glass

        surf_shade.effShadeEmi = eps_sh_ir1 * (1.0 + rho_gl_ir2 * tau_sh_ir / (1.0 - rho_gl_ir2 * rho_sh_ir2))
        surf_shade.effGlassEmi = glass_emiss * tau_sh_ir / (1.0 - rho_gl_ir2 * rho_sh_ir2)

        glass_temperature = a_glass_layer.get_surface("Back").get_temperature()
        state.dataSurface.SurfWinEffInsSurfTemp(surf_num) = \
            (surf_shade.effShadeEmi * surf_inside_temp + surf_shade.effGlassEmi * (glass_temperature - Constant.Kelvin)) / \
            (surf_shade.effShadeEmi + surf_shade.effGlassEmi)

    else:
        surf_shade = state.dataSurface.surfShades(surf_num)
        tot_layers = len(a_layers)
        a_glass_layer = a_layers[tot_layers - 1]
        back_surface = a_glass_layer.get_surface("Back")

        h_cin = a_system.get_hc("Indoor")
        conv_heat_gain_fr_zone_side_of_glass = \
            surf.Area * h_cin * (back_surface.get_temperature() - a_system.get_air_temperature("Indoor"))

        rmir = state.dataSurface.SurfWinIRfromParentZone(surf_num) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(surf_num)
        net_ir_heat_gain_glass = \
            surf.Area * back_surface.get_emissivity() * (Constant.StefanBoltzmann * pow(back_surface.get_temperature(), 4) - rmir)

        state.dataSurface.SurfWinEffInsSurfTemp(surf_num) = \
            a_layers[tot_layers - 1].get_temperature("Back") - Constant.Kelvin
        surf_shade.effGlassEmi = a_layers[tot_layers - 1].get_surface("Back").get_emissivity()

        state.dataSurface.SurfWinHeatGain(surf_num) = \
            state.dataSurface.SurfWinTransSolar(surf_num) + conv_heat_gain_fr_zone_side_of_glass + net_ir_heat_gain_glass
        state.dataSurface.SurfWinGainConvGlazToZoneRep(surf_num) = conv_heat_gain_fr_zone_side_of_glass
        state.dataSurface.SurfWinGainIRGlazToZoneRep(surf_num) = net_ir_heat_gain_glass

    state.dataSurface.SurfWinLossSWZoneToOutWinRep(surf_num) = \
        state.dataHeatBal.EnclSolQSWRad(state.dataSurface.Surface(surf_num).SolarEnclIndex) * surf.Area * (1 - construction.ReflectSolDiffBack) + \
        state.dataHeatBalSurf.SurfWinInitialBeamSolInTrans(surf_num)
    state.dataSurface.SurfWinHeatGain(surf_num) -= \
        (state.dataSurface.SurfWinLossSWZoneToOutWinRep(surf_num) + state.dataHeatBalSurf.SurfWinInitialDifSolInTrans(surf_num) * surf.Area)

    for k in range(1, surf.getTotLayers(state) + 1):
        surf_win.thetaFace[2 * k - 1] = state.dataWindowManager.thetas[2 * k - 2]
        surf_win.thetaFace[2 * k] = state.dataWindowManager.thetas[2 * k - 1]

        state.dataHeatBal.SurfWinFenLaySurfTempFront(surf_num, k) = state.dataWindowManager.thetas[2 * k - 2] - Constant.Kelvin
        state.dataHeatBal.SurfWinFenLaySurfTempBack(surf_num, k) = state.dataWindowManager.thetas[2 * k - 1] - Constant.Kelvin

    return surf_inside_temp, surf_outside_temp


def get_igu_u_value_for_nfrc_report(
    state: EnergyPlusData,
    surf_num: int,
    constr_num: int,
    window_width: float,
    window_height: float,
) -> float:
    tilt = 90.0
    surface = state.dataSurface.Surface(surf_num)
    a_factory = CWCEHeatTransferFactory(state, surface, surf_num, constr_num)
    winter_glass_unit = a_factory.get_tarcog_system_for_reporting(state, False, window_width, window_height, tilt)
    return winter_glass_unit.get_u_value()


def get_shgc_value_for_nfrc_reporting(
    state: EnergyPlusData,
    surf_num: int,
    constr_num: int,
    window_width: float,
    window_height: float,
) -> float:
    tilt = 90.0
    surface = state.dataSurface.Surface(surf_num)
    a_factory = CWCEHeatTransferFactory(state, surface, surf_num, constr_num)
    summer_glass_unit = a_factory.get_tarcog_system_for_reporting(state, True, window_width, window_height, tilt)
    return summer_glass_unit.get_shgc(state.dataConstruction.Construct(constr_num).SolTransNorm)


def get_window_assembly_nfrc_for_report(
    state: EnergyPlusData,
    surf_num: int,
    constr_num: int,
    window_width: float,
    window_height: float,
    vision: Any,
) -> tuple:
    surface = state.dataSurface.Surface(surf_num)
    frame_divider = state.dataSurface.FrameDivider(surface.FrameDivider)
    a_factory = CWCEHeatTransferFactory(state, surface, surf_num, constr_num)

    uvalue = 0.0
    shgc = 0.0
    vt = 0.0

    for is_summer in [False, True]:
        frame_h_ext_conv_coeff = 30.0
        frame_h_int_conv_coeff = 8.0
        tilt = 90.0

        insul_glass_unit = a_factory.get_tarcog_system_for_reporting(state, is_summer, window_width, window_height, tilt)
        center_of_glass_uvalue = insul_glass_unit.get_u_value()

        winter_glass_unit = a_factory.get_tarcog_system_for_reporting(state, False, window_width, window_height, tilt)

        frame_uvalue = a_factory.overall_ufactor_from_films_and_cond(
            frame_divider.FrameConductance, frame_h_int_conv_coeff, frame_h_ext_conv_coeff
        )
        frame_edge_u_value = winter_glass_unit.get_u_value() * frame_divider.FrEdgeToCenterGlCondRatio
        frame_projected_dimension = frame_divider.FrameWidth
        frame_wetted_length = frame_projected_dimension + frame_divider.FrameProjectionIn
        frame_absorptance = frame_divider.FrameSolAbsorp

        frame_data = {
            'u_value': frame_uvalue,
            'edge_u_value': frame_edge_u_value,
            'projected_dimension': frame_projected_dimension,
            'wetted_length': frame_wetted_length,
            'absorptance': frame_absorptance,
        }

        divider_uvalue = a_factory.overall_ufactor_from_films_and_cond(
            frame_divider.DividerConductance, frame_h_int_conv_coeff, frame_h_ext_conv_coeff
        )
        divider_edge_u_value = center_of_glass_uvalue * frame_divider.DivEdgeToCenterGlCondRatio
        divider_projected_dimension = frame_divider.DividerWidth
        divider_wetted_length = divider_projected_dimension + frame_divider.DividerProjectionIn
        divider_absorptance = frame_divider.DividerSolAbsorp
        num_horiz_dividers = frame_divider.HorDividers
        num_vert_dividers = frame_divider.VertDividers

        divider_data = {
            'u_value': divider_uvalue,
            'edge_u_value': divider_edge_u_value,
            'projected_dimension': divider_projected_dimension,
            'wetted_length': divider_wetted_length,
            'absorptance': divider_absorptance,
        }

        t_vis = state.dataConstruction.Construct(constr_num).VisTransNorm
        t_sol = state.dataConstruction.Construct(constr_num).SolTransNorm

        vision_str = str(vision)
        if vision_str == "Single":
            window = create_window_single_vision(window_width, window_height, t_vis, t_sol, insul_glass_unit)
            set_frame_top(window, frame_data)
            set_frame_bottom(window, frame_data)
            set_frame_left(window, frame_data)
            set_frame_right(window, frame_data)
            set_dividers(window, divider_data, num_horiz_dividers, num_vert_dividers)

            if is_summer:
                vt = window_vt(window)
                shgc = window_shgc(window)
            else:
                uvalue = window_u_value(window)
        elif vision_str == "DualHorizontal":
            window = create_window_dual_vision_horizontal(window_width, window_height, t_vis, t_sol, insul_glass_unit, t_vis, t_sol, insul_glass_unit)
            set_frame_left(window, frame_data)
            set_frame_right(window, frame_data)
            set_frame_bottom_left(window, frame_data)
            set_frame_bottom_right(window, frame_data)
            set_frame_top_left(window, frame_data)
            set_frame_top_right(window, frame_data)
            set_frame_meeting_rail(window, frame_data)
            set_dividers(window, divider_data, num_horiz_dividers, num_vert_dividers)

            if is_summer:
                vt = window_vt(window)
                shgc = window_shgc(window)
            else:
                uvalue = window_u_value(window)
        elif vision_str == "DualVertical":
            window = create_window_dual_vision_vertical(window_width, window_height, t_vis, t_sol, insul_glass_unit, t_vis, t_sol, insul_glass_unit)
            set_frame_top(window, frame_data)
            set_frame_bottom(window, frame_data)
            set_frame_top_left(window, frame_data)
            set_frame_top_right(window, frame_data)
            set_frame_bottom_left(window, frame_data)
            set_frame_bottom_right(window, frame_data)
            set_frame_meeting_rail(window, frame_data)
            set_dividers(window, divider_data, num_horiz_dividers, num_vert_dividers)

            if is_summer:
                vt = window_vt(window)
                shgc = window_shgc(window)
            else:
                uvalue = window_u_value(window)
        else:
            window = create_window_single_vision(window_width, window_height, t_vis, t_sol, insul_glass_unit)
            set_frame_top(window, frame_data)
            set_frame_bottom(window, frame_data)
            set_frame_left(window, frame_data)
            set_frame_right(window, frame_data)
            set_dividers(window, divider_data, num_horiz_dividers, num_vert_dividers)

            if is_summer:
                vt = window_vt(window)
                shgc = window_shgc(window)
            else:
                uvalue = window_u_value(window)

    return uvalue, shgc, vt


class CWCEHeatTransferFactory:
    def __init__(self, state: EnergyPlusData, surface: SurfaceData, t_surf_num: int, t_constr_num: int):
        self.m_surface = surface
        self.m_window = state.dataSurface.SurfaceWindow(t_surf_num)
        self.m_shade_position = ShadePosition.NoShade
        self.m_surf_num = t_surf_num
        self.m_solid_layer_index = 0
        self.m_construction_number = t_constr_num
        self.m_tot_lay = self.get_num_of_layers(state)
        self.m_interior_bsdf_shade = False
        self.m_exterior_shade = False

        if not state.dataConstruction.Construct(self.m_construction_number).WindowTypeBSDF and \
           len(state.dataSurface.SurfWinShadingFlag) >= self.m_surf_num:
            if any_shade_screen(state.dataSurface.SurfWinShadingFlag(self.m_surf_num)) or \
               any_blind(state.dataSurface.SurfWinShadingFlag(self.m_surf_num)):
                self.m_construction_number = state.dataSurface.SurfWinActiveShadedConstruction(self.m_surf_num)
                self.m_tot_lay = self.get_num_of_layers(state)

        shade_flag = self.get_shade_type(state, self.m_construction_number)

        if any_interior_shade_blind(shade_flag):
            self.m_shade_position = ShadePosition.Interior
        elif any_exterior_shade_blind_screen(shade_flag):
            self.m_shade_position = ShadePosition.Exterior
        elif any_betweenglass_shade_blind(shade_flag):
            self.m_shade_position = ShadePosition.Between

    def get_tarcog_system(self, state: EnergyPlusData, t_hext_conv_coeff: float) -> Any:
        indoor = self.get_indoor(state)
        outdoor = self.get_outdoor(state, t_hext_conv_coeff)
        a_igu = self.get_igu()

        for i in range(0, self.m_tot_lay):
            a_layer = self.get_igu_layer(state, i + 1)
            assert a_layer is not None
            if self.m_shade_position == ShadePosition.Interior and i == self.m_tot_lay - 1:
                a_air_layer = self.get_shade_to_glass_layer(state, i + 1)
                a_igu.add_layer(a_air_layer)
            a_igu.add_layer(a_layer)
            if self.m_shade_position == ShadePosition.Exterior and i == 0:
                a_air_layer = self.get_shade_to_glass_layer(state, i + 1)
                a_igu.add_layer(a_air_layer)

        return create_single_system(a_igu, indoor, outdoor)

    def get_tarcog_system_for_reporting(
        self,
        state: EnergyPlusData,
        use_summer_conditions: bool,
        width: float,
        height: float,
        tilt: float,
    ) -> Any:
        indoor = self.get_indoor_nfrc(use_summer_conditions)
        outdoor = self.get_outdoor_nfrc(use_summer_conditions)
        a_igu = self.get_igu_with_dims(width, height, tilt)

        self.m_solid_layer_index = 0
        for i in range(0, self.m_tot_lay):
            a_layer = self.get_igu_layer(state, i + 1)
            assert a_layer is not None
            if self.m_shade_position == ShadePosition.Interior and i == self.m_tot_lay - 1:
                a_air_layer = self.get_shade_to_glass_layer(state, i + 1)
                a_igu.add_layer(a_air_layer)
            a_igu.add_layer(a_layer)
            if self.m_shade_position == ShadePosition.Exterior and i == 0:
                a_air_layer = self.get_shade_to_glass_layer(state, i + 1)
                a_igu.add_layer(a_air_layer)

        return create_system(a_igu, indoor, outdoor)

    def get_layer_material(self, state: EnergyPlusData, t_index: int) -> Any:
        constr_num = self.m_construction_number

        if not state.dataConstruction.Construct(constr_num).WindowTypeBSDF and \
           len(state.dataSurface.SurfWinShadingFlag) >= self.m_surf_num:
            if any_shade_screen(state.dataSurface.SurfWinShadingFlag(self.m_surf_num)) or \
               any_blind(state.dataSurface.SurfWinShadingFlag(self.m_surf_num)):
                constr_num = state.dataSurface.SurfWinActiveShadedConstruction(self.m_surf_num)

        construction = state.dataConstruction.Construct(constr_num)
        lay_ptr = construction.LayerPoint(t_index)
        return state.dataMaterial.materials(lay_ptr)

    def get_igu_layer(self, state: EnergyPlusData, t_index: int) -> Any:
        a_layer = None
        material = self.get_layer_material(state, t_index)
        mat_group = material.group

        if mat_group in ["Glass", "GlassSimple", "Blind", "Shade", "Screen", "ComplexShade"]:
            self.m_solid_layer_index += 1
            a_layer = self.get_solid_layer(state, material, self.m_solid_layer_index)
        elif mat_group in ["Gas", "GasMixture"]:
            a_layer = self.get_gap_layer(material)
        elif mat_group == "ComplexWindowGap":
            a_layer = self.get_complex_gap_layer(state, material)

        return a_layer

    def get_num_of_layers(self, state: EnergyPlusData) -> int:
        return state.dataConstruction.Construct(self.m_construction_number).TotLayers

    def get_solid_layer(self, state: EnergyPlusData, mat: Any, t_index: int) -> Any:
        emiss_front = 0.0
        emiss_back = 0.0
        trans_thermal_front = 0.0
        trans_thermal_back = 0.0
        thickness = 0.0
        conductivity = 0.0
        create_openness = False
        atop = 0.0
        abot = 0.0
        aleft = 0.0
        aright = 0.0
        afront = 0.0

        mat_group = mat.group
        if mat_group in ["Glass", "GlassSimple"]:
            emiss_front = mat.AbsorpThermalFront
            emiss_back = mat.AbsorpThermalBack
            trans_thermal_front = mat.TransThermal
            trans_thermal_back = mat.TransThermal
            thickness = mat.Thickness
            conductivity = mat.Conductivity
        elif mat_group == "Blind":
            thickness = mat.SlatThickness
            conductivity = mat.SlatConductivity
            atop = mat.topOpeningMult
            abot = mat.bottomOpeningMult
            aleft = mat.leftOpeningMult
            aright = mat.rightOpeningMult

            slat_ang = mat.SlatAngle * Constant.DegToRad
            perm_a = math.sin(slat_ang) - mat.SlatThickness / mat.SlatSeparation
            perm_b = 1.0 - (abs(mat.SlatWidth * math.cos(slat_ang)) + mat.SlatThickness * math.sin(slat_ang)) / mat.SlatSeparation
            afront = min(1.0, max(0.0, perm_a, perm_b))

            i_slat_lo, i_slat_hi, interp_fac = Material.GetSlatIndicesInterpFac(slat_ang)

            emiss_front = Interp(mat.TARs[i_slat_lo].IR.Ft.Emi, mat.TARs[i_slat_hi].IR.Ft.Emi, interp_fac)
            emiss_back = Interp(mat.TARs[i_slat_lo].IR.Bk.Emi, mat.TARs[i_slat_hi].IR.Bk.Emi, interp_fac)
            trans_thermal_front = Interp(mat.TARs[i_slat_lo].IR.Ft.Tra, mat.TARs[i_slat_hi].IR.Ft.Tra, interp_fac)
            trans_thermal_back = Interp(mat.TARs[i_slat_lo].IR.Bk.Tra, mat.TARs[i_slat_hi].IR.Bk.Tra, interp_fac)

            if t_index == 1:
                self.m_exterior_shade = True
        elif mat_group == "Shade":
            emiss_front = mat.AbsorpThermal
            emiss_back = mat.AbsorpThermal
            trans_thermal_front = mat.TransThermal
            trans_thermal_back = mat.TransThermal
            thickness = mat.Thickness
            conductivity = mat.Conductivity
            atop = mat.topOpeningMult
            abot = mat.bottomOpeningMult
            aleft = mat.leftOpeningMult
            aright = mat.rightOpeningMult
            afront = mat.airFlowPermeability
            if t_index == 1:
                self.m_exterior_shade = True
        elif mat_group == "Screen":
            emiss_front = mat.AbsorpThermal
            emiss_back = mat.AbsorpThermal
            trans_thermal_front = mat.TransThermal
            trans_thermal_back = mat.TransThermal
            thickness = mat.Thickness
            conductivity = mat.Conductivity
            atop = mat.topOpeningMult
            abot = mat.bottomOpeningMult
            aleft = mat.leftOpeningMult
            aright = mat.rightOpeningMult
            afront = mat.airFlowPermeability
            if t_index == 1:
                self.m_exterior_shade = True
        elif mat_group == "ComplexShade":
            thickness = mat.Thickness
            conductivity = mat.Conductivity
            emiss_front = mat.FrontEmissivity
            emiss_back = mat.BackEmissivity
            trans_thermal_front = mat.TransThermal
            trans_thermal_back = mat.TransThermal
            afront = mat.frontOpeningMult
            atop = mat.topOpeningMult
            abot = mat.bottomOpeningMult
            aleft = mat.leftOpeningMult
            aright = mat.rightOpeningMult
            create_openness = True
            self.m_interior_bsdf_shade = ((2 * t_index - 1) == self.m_tot_lay)

        front_surface = create_surface(emiss_front, trans_thermal_front)
        back_surface = create_surface(emiss_back, trans_thermal_back)
        a_solid_layer = create_igu_solid_layer(thickness, conductivity, front_surface, back_surface)

        if create_openness:
            a_openings = create_shade_openings(atop, abot, aleft, aright, afront, afront)
            a_solid_layer = create_igu_shade_layer(a_solid_layer, a_openings)

        standardized_radiation_intensity = 783.0
        if state.dataWindowManager.inExtWindowModel.is_external_library_model():
            surface = state.dataSurface.Surface(self.m_surf_num)
            constr_num = self.get_active_construction_number(state, surface, self.m_surf_num)
            a_layer_equiv = CWindowConstructionsSimplified.instance(state).get_equivalent_layer(
                state, "Solar", constr_num
            )
            theta = 0.0
            phi = 0.0
            abs_coeff = a_layer_equiv.get_absorptance_layer(t_index, "Front", "Diffuse", theta, phi)
            a_solid_layer.set_solar_absorptance(abs_coeff, standardized_radiation_intensity)
        else:
            abs_coeff = state.dataConstruction.Construct(state.dataSurface.Surface(self.m_surf_num).Construction).AbsDiff(t_index)
            a_solid_layer.set_solar_absorptance(abs_coeff, standardized_radiation_intensity)

        return a_solid_layer

    def get_gap_layer(self, material: Any) -> Any:
        pres = 1e5
        thickness = material.Thickness
        a_gas = self.get_gas(material)
        a_layer = create_igu_gap_layer(thickness, pres, a_gas)
        return a_layer

    def get_shade_to_glass_layer(self, state: EnergyPlusData, t_index: int) -> Any:
        pres = 1e5
        a_gas = self.get_air()
        thickness = 0.0

        s_mat = state.dataMaterial
        surf_win = state.dataSurface.SurfaceWindow(self.m_surf_num)
        surf_shade = state.dataSurface.surfShades(self.m_surf_num)

        shade_flag = self.get_shade_type(state, self.m_construction_number)

        if shade_flag in ["IntBlind", "ExtBlind"]:
            thickness = s_mat.materials(surf_shade.blind.matNum).toGlassDist
        elif shade_flag == "ExtScreen":
            thickness = s_mat.materials(surf_win.screenNum).toGlassDist
        elif shade_flag in ["IntShade", "ExtShade"]:
            material = self.get_layer_material(state, t_index)
            assert material is not None
            thickness = material.toGlassDist

        a_layer = create_igu_gap_layer(thickness, pres, a_gas)
        return a_layer

    def get_complex_gap_layer(self, state: EnergyPlusData, material_base: Any) -> Any:
        pres = 1e5
        thickness = material_base.Thickness
        a_gas = self.get_gas(material_base)
        return create_igu_gap_layer(thickness, pres, a_gas)

    def get_gas(self, material_base: Any) -> Any:
        mat_gas = material_base
        num_gases = mat_gas.numGases
        vacuum_coeff = 1.4
        gas_name = mat_gas.Name
        a_gas = create_cgas()

        for i in range(0, num_gases):
            gas = mat_gas.gases[i]
            wght = gas.wght
            fract = mat_gas.gasFracts[i]
            a_con = create_int_coeff(gas.con.c0, gas.con.c1, gas.con.c2)
            a_cp = create_int_coeff(gas.cp.c0, gas.cp.c1, gas.cp.c2)
            a_vis = create_int_coeff(gas.vis.c0, gas.vis.c1, gas.vis.c2)
            a_data = create_gas_data(gas_name, wght, vacuum_coeff, a_cp, a_con, a_vis)
            a_gas.add_gas_item(fract, a_data)

        return a_gas

    @staticmethod
    def get_air() -> Any:
        return create_cgas()

    def get_indoor(self, state: EnergyPlusData) -> Any:
        tin = self.m_surface.getInsideAirTemperature(state, self.m_surf_num) + Constant.Kelvin
        hcin = state.dataHeatBalSurf.SurfHConvInt(self.m_surf_num)
        ir = state.dataSurface.SurfWinIRfromParentZone(self.m_surf_num) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(self.m_surf_num)

        indoor = create_indoor_environment(tin, state.dataEnvrn.OutBaroPress)
        indoor.set_h_coeff_model("CalculateH", hcin)
        indoor.set_environment_ir(ir)
        return indoor

    def get_outdoor(self, state: EnergyPlusData, t_hext: float) -> Any:
        tout = self.m_surface.getOutsideAirTemperature(state, self.m_surf_num) + Constant.Kelvin
        ir = self.m_surface.getOutsideIR(state, self.m_surf_num)
        sw_radiation = self.m_surface.getSWIncident(state, self.m_surf_num)
        t_sky = state.dataEnvrn.SkyTempKelvin
        air_speed = 0.0

        if self.m_surface.ExtWind:
            air_speed = state.dataSurface.SurfOutWindSpeed(self.m_surf_num)

        fclr = 1 - state.dataEnvrn.CloudFraction
        air_direction = "Windward"

        outdoor = create_outdoor_environment(
            tout, air_speed, sw_radiation, air_direction, t_sky, "AllSpecified",
            state.dataEnvrn.OutBaroPress, fclr
        )
        outdoor.set_h_coeff_model("HcPrescribed", t_hext)
        outdoor.set_environment_ir(ir)
        return outdoor

    def get_igu(self) -> Any:
        return create_igu(self.m_surface.Width, self.m_surface.Height, self.m_surface.Tilt)

    def get_igu_with_dims(self, width: float, height: float, tilt: float) -> Any:
        return create_igu(width, height, tilt)

    @staticmethod
    def get_active_construction_number(state: EnergyPlusData, surface: SurfaceData, t_surf_num: int) -> int:
        result = surface.Construction
        shade_flag = state.dataSurface.SurfWinShadingFlag(t_surf_num)

        if any_shade_screen(shade_flag) or any_blind(shade_flag):
            result = state.dataSurface.SurfWinActiveShadedConstruction(t_surf_num)

        return result

    def is_interior_shade(self) -> bool:
        return self.m_interior_bsdf_shade

    def get_outdoor_nfrc(self, use_summer_conditions: bool) -> Any:
        air_temperature = -18.0 + Constant.Kelvin
        air_speed = 5.5
        t_sky = -18.0 + Constant.Kelvin
        solar_radiation = 0.0

        if use_summer_conditions:
            air_temperature = 32.0 + Constant.Kelvin
            air_speed = 2.75
            t_sky = 32.0 + Constant.Kelvin
            solar_radiation = 783.0

        outdoor = create_environment_outdoor(air_temperature, air_speed, solar_radiation, t_sky, "AllSpecified")
        outdoor.set_h_coeff_model("CalculateH", 0.0)
        return outdoor

    def get_indoor_nfrc(self, use_summer_conditions: bool) -> Any:
        room_temperature = 21.0 + Constant.Kelvin
        if use_summer_conditions:
            room_temperature = 24.0 + Constant.Kelvin
        return create_environment_indoor(room_temperature)

    @staticmethod
    def get_shade_type(state: EnergyPlusData, constr_num: int) -> str:
        s_mat = state.dataMaterial
        shade_flag = "NoShade"

        tot_lay = state.dataConstruction.Construct(constr_num).TotLayers
        tot_glass_lay = state.dataConstruction.Construct(constr_num).TotGlassLayers
        mat_out_num = state.dataConstruction.Construct(constr_num).LayerPoint(1)
        mat_in_num = state.dataConstruction.Construct(constr_num).LayerPoint(tot_lay)

        mat_out = s_mat.materials(mat_out_num)
        mat_in = s_mat.materials(mat_in_num)

        if mat_out.group == "Shade":
            shade_flag = "ExtShade"
        elif mat_out.group == "Screen":
            shade_flag = "ExtScreen"
        elif mat_out.group == "Blind":
            shade_flag = "ExtBlind"
        elif mat_in.group == "Shade":
            shade_flag = "IntShade"
        elif mat_in.group == "Blind":
            shade_flag = "IntBlind"
        elif tot_glass_lay == 2:
            mat3 = s_mat.materials(state.dataConstruction.Construct(constr_num).LayerPoint(3))
            if mat3.group == "Shade":
                shade_flag = "BGShade"
            elif mat3.group == "Blind":
                shade_flag = "BGBlind"
        elif tot_glass_lay == 3:
            mat5 = s_mat.materials(state.dataConstruction.Construct(constr_num).LayerPoint(5))
            if mat5.group == "Shade":
                shade_flag = "BGShade"
            elif mat5.group == "Blind":
                shade_flag = "BGBlind"

        return shade_flag

    def overall_ufactor_from_films_and_cond(self, conductance: float, inside_film: float, outside_film: float) -> float:
        r_overall = 0.0
        u_factor = 0.0
        if inside_film != 0 and outside_film != 0.0 and conductance != 0.0:
            r_overall = 1 / inside_film + 1 / conductance + 1 / outside_film
        if r_overall != 0.0:
            u_factor = 1 / r_overall
        return u_factor


def show_severe_error(state: EnergyPlusData, message: str) -> None:
    pass


def show_continue_error(state: EnergyPlusData, message: str) -> None:
    pass


def any_shade_screen(flag: Any) -> bool:
    return False


def any_blind(flag: Any) -> bool:
    return False


def any_interior_shade_blind(flag: Any) -> bool:
    return False


def any_exterior_shade_blind_screen(flag: Any) -> bool:
    return False


def any_betweenglass_shade_blind(flag: Any) -> bool:
    return False


def fenestration_common_enum_side() -> List[str]:
    return ["Front", "Back"]


def create_surface(emissivity: float, transmittance: float) -> Any:
    pass


def create_igu_solid_layer(thickness: float, conductivity: float, front: Any, back: Any) -> Any:
    pass


def create_shade_openings(atop: float, abot: float, aleft: float, aright: float, afront_front: float, afront_back: float) -> Any:
    pass


def create_igu_shade_layer(layer: Any, openings: Any) -> Any:
    pass


def create_igu_gap_layer(thickness: float, pressure: float, gas: Any) -> Any:
    pass


def create_cgas() -> Any:
    pass


def create_int_coeff(c0: float, c1: float, c2: float) -> Any:
    pass


def create_gas_data(name: str, wght: float, vacuum_coeff: float, cp: Any, con: Any, vis: Any) -> Any:
    pass


def create_indoor_environment(temperature: float, pressure: float) -> Any:
    pass


def create_outdoor_environment(
    temperature: float, air_speed: float, solar_radiation: float,
    air_direction: str, t_sky: float, sky_model: str, pressure: float, clear_fraction: float
) -> Any:
    pass


def create_environment_outdoor(temperature: float, air_speed: float, solar_radiation: float, t_sky: float, sky_model: str) -> Any:
    pass


def create_environment_indoor(temperature: float) -> Any:
    pass


def create_igu(width: float, height: float, tilt: float) -> Any:
    pass


def create_single_system(igu: Any, indoor: Any, outdoor: Any) -> Any:
    pass


def create_system(igu: Any, indoor: Any, outdoor: Any) -> Any:
    pass


def create_window_single_vision(width: float, height: float, t_vis: float, t_sol: float, igu: Any) -> Any:
    pass


def create_window_dual_vision_horizontal(
    width: float, height: float, t_vis1: float, t_sol1: float, igu1: Any,
    t_vis2: float, t_sol2: float, igu2: Any
) -> Any:
    pass


def create_window_dual_vision_vertical(
    width: float, height: float, t_vis1: float, t_sol1: float, igu1: Any,
    t_vis2: float, t_sol2: float, igu2: Any
) -> Any:
    pass


def set_frame_top(window: Any, frame_data: dict) -> None:
    pass


def set_frame_bottom(window: Any, frame_data: dict) -> None:
    pass


def set_frame_left(window: Any, frame_data: dict) -> None:
    pass


def set_frame_right(window: Any, frame_data: dict) -> None:
    pass


def set_frame_top_left(window: Any, frame_data: dict) -> None:
    pass


def set_frame_top_right(window: Any, frame_data: dict) -> None:
    pass


def set_frame_bottom_left(window: Any, frame_data: dict) -> None:
    pass


def set_frame_bottom_right(window: Any, frame_data: dict) -> None:
    pass


def set_frame_meeting_rail(window: Any, frame_data: dict) -> None:
    pass


def set_dividers(window: Any, divider_data: dict, num_horiz: int, num_vert: int) -> None:
    pass


def window_vt(window: Any) -> float:
    return 0.0


def window_shgc(window: Any) -> float:
    return 0.0


def window_u_value(window: Any) -> float:
    return 0.0


class CWindowConstructionsSimplified:
    _instance = None

    @classmethod
    def instance(cls, state: EnergyPlusData) -> 'CWindowConstructionsSimplified':
        if cls._instance is None:
            cls._instance = CWindowConstructionsSimplified()
        return cls._instance

    def get_equivalent_layer(self, state: EnergyPlusData, wavelength_range: str, constr_num: int) -> Any:
        pass
