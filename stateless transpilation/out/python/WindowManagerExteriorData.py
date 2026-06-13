# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object passed through
# - Vector: DataVectorTypes.Vector (3D vector)
# - BSDFDirection: SingleLayerOptics.BSDFDirection (enum: Outgoing)
# - WavelengthRange: FenestrationCommon.WavelengthRange (enum: Solar, Visible)
# - CScatteringLayer: SingleLayerOptics.CScatteringLayer
# - CMultiLayerScattered: MultiLayerOptics.CMultiLayerScattered
# - CSpectralSampleData: SpectralAveraging.CSpectralSampleData
# - CSeries: FenestrationCommon.CSeries
# - MaterialGlass: Material.MaterialGlass
# - CMaterialSingleBand, CMaterialDualBand: WCEMultiLayerOptics
# - Property, Side: WCEMultiLayerOptics enums
# - dot: vector dot product function
# - W6CoordsFromWorldVect: WindowComplexManager
# - ShowFatalError: UtilityRoutines
# - RayIdentificationType: WindowComplexManager enum (Front_Incident, Back_Incident)
# - Constant: global constants struct (DegToRad, Pi)

from typing import Tuple, Dict, List, Optional, Any

IGU_Layers = List
Layers_Map = Dict[int, IGU_Layers]


def is_surface_hit(state: Any, t_surf_num: int, t_ray: Any) -> bool:
    dot_prod = dot(t_ray, state.dataSurface.Surface(t_surf_num).NewellSurfaceNormalVector)
    return dot_prod > 0


def get_wce_coordinates(state: Any, t_surf_num: int, t_ray: Any, t_direction: Any) -> Tuple[float, float]:
    theta = 0.0
    phi = 0.0

    gamma = Constant.DegToRad * state.dataSurface.Surface(t_surf_num).Tilt
    alpha = Constant.DegToRad * state.dataSurface.Surface(t_surf_num).Azimuth

    rad_type = RayIdentificationType.Front_Incident

    if t_direction == BSDFDirection.Outgoing:
        rad_type = RayIdentificationType.Back_Incident

    theta, phi = W6CoordsFromWorldVect(state, t_ray, rad_type, gamma, alpha, theta, phi)

    theta = 180.0 / Constant.Pi * theta
    phi = 180.0 / Constant.Pi * phi

    return (theta, phi)


def get_sun_wce_angles(state: Any, t_surf_num: int, t_direction: Any) -> Tuple[float, float]:
    return get_wce_coordinates(
        state,
        t_surf_num,
        state.dataBSDFWindow.SUNCOSTS[state.dataGlobal.TimeStep][state.dataGlobal.HourOfDay],
        t_direction
    )


class CWCESpecturmProperties:

    @staticmethod
    def get_spectral_sample_from_ptr(state: Any, t_sample_data_ptr: int) -> Any:
        s_mat = state.dataMaterial

        assert t_sample_data_ptr != 0
        a_sample_data = CSpectralSampleData()
        spectral_data = s_mat.SpectralData(t_sample_data_ptr)
        num_of_wl = spectral_data.NumOfWavelengths
        for i in range(1, num_of_wl + 1):
            wl = spectral_data.WaveLength(i)
            t = spectral_data.Trans(i)
            rf = spectral_data.ReflFront(i)
            rb = spectral_data.ReflBack(i)
            a_sample_data.addRecord(wl, t, rf, rb)

        return a_sample_data

    @staticmethod
    def get_spectral_sample_from_glass(t_material_properties: Any) -> Any:
        tsol = t_material_properties.Trans
        rfsol = t_material_properties.ReflectSolBeamFront
        rbsol = t_material_properties.ReflectSolBeamBack
        a_sol_mat = CMaterialSingleBand(tsol, tsol, rfsol, rbsol, 0.3, 2.5)

        tvis = t_material_properties.TransVis
        rfvis = t_material_properties.ReflectVisBeamFront
        rbvis = t_material_properties.ReflectVisBeamBack
        a_vis_mat = CMaterialSingleBand(tvis, tvis, rfvis, rbvis, 0.38, 0.78)

        a_mat = CMaterialDualBand(a_vis_mat, a_sol_mat, 0.49)
        a_wl = a_mat.getBandWavelengths()
        a_tf = a_mat.getBandProperties(Property.T, Side.Front)
        a_rf = a_mat.getBandProperties(Property.R, Side.Front)
        a_rb = a_mat.getBandProperties(Property.R, Side.Back)
        a_sample_data = CSpectralSampleData()
        for i in range(len(a_wl)):
            a_sample_data.addRecord(a_wl[i], a_tf[i], a_rf[i], a_rb[i])

        return a_sample_data

    @staticmethod
    def get_default_solar_radiation_spectrum(state: Any) -> Any:
        solar_radiation = CSeries()

        for i in range(1, state.dataWindowManager.nume + 1):
            solar_radiation.addProperty(state.dataWindowManager.wle[i - 1], state.dataWindowManager.e[i - 1])

        return solar_radiation

    @staticmethod
    def get_default_visible_photopic_response(state: Any) -> Any:
        visible_response = CSeries()

        for i in range(1, state.dataWindowManager.numt3 + 1):
            visible_response.addProperty(state.dataWindowManager.wlt3[i - 1], state.dataWindowManager.y30[i - 1])

        return visible_response


class CWindowConstructionsSimplified:

    def __init__(self):
        self.m_layers: Dict[Any, Layers_Map] = {}
        self.m_equivalent: Dict[Tuple[Any, int], Any] = {}
        self.m_layers[WavelengthRange.Solar] = {}
        self.m_layers[WavelengthRange.Visible] = {}

    @staticmethod
    def instance(state: Any) -> 'CWindowConstructionsSimplified':
        if state.dataWindowManagerExterior.p_inst is None:
            state.dataWindowManagerExterior.p_inst = CWindowConstructionsSimplified()
        return state.dataWindowManagerExterior.p_inst

    def push_layer(self, t_range: Any, t_constr_num: int, t_layer: Any) -> None:
        a_map = self.m_layers[t_range]
        if t_constr_num not in a_map:
            a_map[t_constr_num] = []
        a_map[t_constr_num].append(t_layer)

    def get_equivalent_layer(self, state: Any, t_range: Any, t_constr_num: int) -> Any:
        key = (t_range, t_constr_num)
        if key not in self.m_equivalent:
            igu_layers = self.get_layers(state, t_range, t_constr_num)
            a_eq_layer = CMultiLayerScattered(igu_layers[0])
            for i in range(1, len(igu_layers)):
                a_eq_layer.addLayer(igu_layers[i])

            a_solar_spectrum = CWCESpecturmProperties.get_default_solar_radiation_spectrum(state)
            a_eq_layer.setSourceData(a_solar_spectrum)
            self.m_equivalent[key] = a_eq_layer

        return self.m_equivalent[key]

    @staticmethod
    def clear_state() -> None:
        pass

    def get_layers(self, state: Any, t_range: Any, t_constr_num: int) -> IGU_Layers:
        a_map = self.m_layers[t_range]
        if t_constr_num not in a_map:
            ShowFatalError(state, "Incorrect construction selection.")
        return a_map[t_constr_num]


class WindowManagerExteriorData:

    def __init__(self):
        self.p_inst: Optional[CWindowConstructionsSimplified] = None

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.__init__()
