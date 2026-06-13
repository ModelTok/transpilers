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

from collections import Dict
from memory import UnsafePointer

alias IGU_Layers = DynamicVector
alias Layers_Map = Dict[Int, IGU_Layers]


fn is_surface_hit(state: UnsafePointer[EnergyPlusData], t_surf_num: Int, t_ray: UnsafePointer[Vector]) -> Bool:
    let dot_prod = dot(t_ray, state[][].dataSurface.Surface(t_surf_num).NewellSurfaceNormalVector)
    return dot_prod > 0


fn get_wce_coordinates(state: UnsafePointer[EnergyPlusData], t_surf_num: Int, t_ray: UnsafePointer[Vector], t_direction: BSDFDirection) -> Tuple[Float64, Float64]:
    var theta: Float64 = 0.0
    var phi: Float64 = 0.0

    let gamma: Float64 = Constant.DegToRad * state[][].dataSurface.Surface(t_surf_num).Tilt
    let alpha: Float64 = Constant.DegToRad * state[][].dataSurface.Surface(t_surf_num).Azimuth

    var rad_type: RayIdentificationType = RayIdentificationType.Front_Incident

    if t_direction == BSDFDirection.Outgoing:
        rad_type = RayIdentificationType.Back_Incident

    theta, phi = W6CoordsFromWorldVect(state, t_ray, rad_type, gamma, alpha, theta, phi)

    theta = 180.0 / Constant.Pi * theta
    phi = 180.0 / Constant.Pi * phi

    return (theta, phi)


fn get_sun_wce_angles(state: UnsafePointer[EnergyPlusData], t_surf_num: Int, t_direction: BSDFDirection) -> Tuple[Float64, Float64]:
    return get_wce_coordinates(
        state,
        t_surf_num,
        state[][].dataBSDFWindow.SUNCOSTS[state[][].dataGlobal.TimeStep][state[][].dataGlobal.HourOfDay],
        t_direction
    )


struct CWCESpecturmProperties:

    @staticmethod
    fn get_spectral_sample(state: UnsafePointer[EnergyPlusData], t_sample_data_ptr: Int) -> UnsafePointer[CSpectralSampleData]:
        let s_mat = state[][].dataMaterial

        debug_assert(t_sample_data_ptr != 0, "t_sample_data_ptr must not be zero")
        let a_sample_data = UnsafePointer[CSpectralSampleData].alloc(1)
        a_sample_data[].__init__()
        let spectral_data = s_mat[].SpectralData(t_sample_data_ptr)
        let num_of_wl: Int = spectral_data.NumOfWavelengths
        for i in range(1, num_of_wl + 1):
            let wl: Float64 = spectral_data.WaveLength(i)
            let t: Float64 = spectral_data.Trans(i)
            let rf: Float64 = spectral_data.ReflFront(i)
            let rb: Float64 = spectral_data.ReflBack(i)
            a_sample_data[].addRecord(wl, t, rf, rb)

        return a_sample_data

    @staticmethod
    fn get_spectral_sample(t_material_properties: UnsafePointer[MaterialGlass]) -> UnsafePointer[CSpectralSampleData]:
        let tsol: Float64 = t_material_properties[].Trans
        let rfsol: Float64 = t_material_properties[].ReflectSolBeamFront
        let rbsol: Float64 = t_material_properties[].ReflectSolBeamBack
        let a_sol_mat = CMaterialSingleBand(tsol, tsol, rfsol, rbsol, 0.3, 2.5)

        let tvis: Float64 = t_material_properties[].TransVis
        let rfvis: Float64 = t_material_properties[].ReflectVisBeamFront
        let rbvis: Float64 = t_material_properties[].ReflectVisBeamBack
        let a_vis_mat = CMaterialSingleBand(tvis, tvis, rfvis, rbvis, 0.38, 0.78)

        let a_mat = CMaterialDualBand(a_vis_mat, a_sol_mat, 0.49)
        let a_wl = a_mat.getBandWavelengths()
        let a_tf = a_mat.getBandProperties(Property.T, Side.Front)
        let a_rf = a_mat.getBandProperties(Property.R, Side.Front)
        let a_rb = a_mat.getBandProperties(Property.R, Side.Back)
        let a_sample_data = UnsafePointer[CSpectralSampleData].alloc(1)
        a_sample_data[].__init__()
        for i in range(len(a_wl)):
            a_sample_data[].addRecord(a_wl[i], a_tf[i], a_rf[i], a_rb[i])

        return a_sample_data

    @staticmethod
    fn get_default_solar_radiation_spectrum(state: UnsafePointer[EnergyPlusData]) -> CSeries:
        var solar_radiation = CSeries()

        for i in range(1, state[][].dataWindowManager.nume + 1):
            solar_radiation.addProperty(state[][].dataWindowManager.wle[i - 1], state[][].dataWindowManager.e[i - 1])

        return solar_radiation

    @staticmethod
    fn get_default_visible_photopic_response(state: UnsafePointer[EnergyPlusData]) -> CSeries:
        var visible_response = CSeries()

        for i in range(1, state[][].dataWindowManager.numt3 + 1):
            visible_response.addProperty(state[][].dataWindowManager.wlt3[i - 1], state[][].dataWindowManager.y30[i - 1])

        return visible_response


struct CWindowConstructionsSimplified:
    var m_layers: Dict[WavelengthRange, Layers_Map]
    var m_equivalent: Dict[Tuple[WavelengthRange, Int], UnsafePointer[CMultiLayerScattered]]

    fn __init__(inout self):
        self.m_layers = Dict[WavelengthRange, Layers_Map]()
        self.m_equivalent = Dict[Tuple[WavelengthRange, Int], UnsafePointer[CMultiLayerScattered]]()
        self.m_layers[WavelengthRange.Solar] = Layers_Map()
        self.m_layers[WavelengthRange.Visible] = Layers_Map()

    @staticmethod
    fn instance(state: UnsafePointer[EnergyPlusData]) -> UnsafePointer[CWindowConstructionsSimplified]:
        if state[][].dataWindowManagerExterior.p_inst == UnsafePointer[CWindowConstructionsSimplified]():
            state[][].dataWindowManagerExterior.p_inst = UnsafePointer[CWindowConstructionsSimplified].alloc(1)
            state[][].dataWindowManagerExterior.p_inst[].__init__()
        return state[][].dataWindowManagerExterior.p_inst

    fn push_layer(inout self, t_range: WavelengthRange, t_constr_num: Int, t_layer: CScatteringLayer):
        let a_map = self.m_layers[t_range]
        if t_constr_num not in a_map:
            a_map[t_constr_num] = IGU_Layers()
        a_map[t_constr_num].push_back(t_layer)

    fn get_equivalent_layer(inout self, state: UnsafePointer[EnergyPlusData], t_range: WavelengthRange, t_constr_num: Int) -> UnsafePointer[CMultiLayerScattered]:
        let key = (t_range, t_constr_num)
        if key not in self.m_equivalent:
            let igu_layers = self.get_layers(state, t_range, t_constr_num)
            let a_eq_layer = UnsafePointer[CMultiLayerScattered].alloc(1)
            a_eq_layer[].__init__(igu_layers[0])
            for i in range(1, len(igu_layers)):
                a_eq_layer[].addLayer(igu_layers[i])

            let a_solar_spectrum = CWCESpecturmProperties.get_default_solar_radiation_spectrum(state)
            a_eq_layer[].setSourceData(a_solar_spectrum)
            self.m_equivalent[key] = a_eq_layer

        return self.m_equivalent[key]

    @staticmethod
    fn clear_state():
        pass

    fn get_layers(inout self, state: UnsafePointer[EnergyPlusData], t_range: WavelengthRange, t_constr_num: Int) -> IGU_Layers:
        let a_map = self.m_layers[t_range]
        if t_constr_num not in a_map:
            ShowFatalError(state, "Incorrect construction selection.")
        return a_map[t_constr_num]


struct WindowManagerExteriorData:
    var p_inst: UnsafePointer[CWindowConstructionsSimplified]

    fn __init__(inout self):
        self.p_inst = UnsafePointer[CWindowConstructionsSimplified]()

    fn init_constant_state(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn init_state(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn clear_state(inout self):
        self.__init__()
