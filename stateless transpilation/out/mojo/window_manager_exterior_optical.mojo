# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (dataMaterial, dataConstruction, dataHeatBal, dataSurface)
# - Material.MaterialBase, MaterialGlass, MaterialBlind, MaterialShade, MaterialScreen: material types
# - Material.Group: enum (Glass=0, GlassSimple=10, Blind=1, Screen=2, Shade=3, Gas=4, GasMixture=5, ComplexWindowGap=8, ComplexShade=9)
# - Material.MaxSlatAngs: constant (5)
# - FenestrationCommon.WavelengthRange: enum (Solar=0, Visible=1)
# - SingleLayerOptics.CBSDFLayer, CScatteringLayer, CMaterial, CMaterialSingleBand, CMaterialDualBand, CMaterialSample
# - SingleLayerOptics.ICellDescription, CSpecularCellDescription, CVenetianCellDescription, CWovenCellDescription, CFlatCellDescription
# - SingleLayerOptics.CBSDFHemisphere, BSDFBasis, CBSDFLayerMaker, CWavelengthRange, CSpectralSample, CSpectralSampleData
# - FenestrationCommon.PropertySimple, Side, Scattering: enums
# - CWindowConstructionsSimplified.instance(state): singleton access
# - CWCESpecturmProperties: utility with static methods
# - CalcWindowBlindProperties(state): function
# - CalcWindowScreenProperties(state): function
# - WindowModel.BSDF: enum value (2)

from math import sqrt

alias MaterialBase = AnyType
alias MaterialGlass = AnyType
alias MaterialBlind = AnyType
alias MaterialShade = AnyType
alias MaterialScreen = AnyType
alias CBSDFLayer = AnyType
alias CScatteringLayer = AnyType
alias CMaterial = AnyType
alias CMaterialSingleBand = AnyType
alias CMaterialDualBand = AnyType
alias CMaterialSample = AnyType
alias ICellDescription = AnyType
alias CSpecularCellDescription = AnyType
alias CVenetianCellDescription = AnyType
alias CWovenCellDescription = AnyType
alias CFlatCellDescription = AnyType
alias CBSDFHemisphere = AnyType
alias CBSDFLayerMaker = AnyType
alias CWavelengthRange = AnyType
alias CSpectralSample = AnyType
alias CSpectralSampleData = AnyType
alias EnergyPlusData = AnyType
alias CWindowConstructionsSimplified = AnyType
alias CWCESpecturmProperties = AnyType

fn get_bsdf_layer(state: EnergyPlusData, t_material: MaterialBase, t_range: Int) -> CBSDFLayer:
    """
    SUBROUTINE INFORMATION:
           AUTHOR         Simon Vidanovic
           DATE WRITTEN   September 2016
           MODIFIED       na
           RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    BSDF will be created in different ways that is based on material type
    """
    var a_factory: CWCELayerFactory
    if t_material.group == 0:
        a_factory = CWCESpecularLayerFactory(t_material, t_range)
    elif t_material.group == 1:
        a_factory = CWCEVenetianBlindLayerFactory(t_material, t_range)
    elif t_material.group == 2:
        a_factory = CWCEScreenLayerFactory(t_material, t_range)
    elif t_material.group == 3:
        a_factory = CWCEDiffuseShadeLayerFactory(t_material, t_range)
    return a_factory.get_bsdf_layer(state)

fn get_scattering_layer(state: EnergyPlusData, t_material: MaterialBase, t_range: Int) -> CScatteringLayer:
    """
    SUBROUTINE INFORMATION:
           AUTHOR         Simon Vidanovic
           DATE WRITTEN   May 2017
           MODIFIED       na
           RE-ENGINEERED
              April 2021: returning CScatteringLayer instead of pointer to it

    PURPOSE OF THIS SUBROUTINE:
    Scattering will be created in different ways that is based on material type
    """
    var a_factory: CWCELayerFactory
    if t_material.group == 0 or t_material.group == 10:
        a_factory = CWCESpecularLayerFactory(t_material, t_range)
    elif t_material.group == 1:
        a_factory = CWCEVenetianBlindLayerFactory(t_material, t_range)
    elif t_material.group == 2:
        a_factory = CWCEScreenLayerFactory(t_material, t_range)
    elif t_material.group == 3:
        a_factory = CWCEDiffuseShadeLayerFactory(t_material, t_range)
    return a_factory.get_layer(state)

fn init_wce_simplified_optical_data(state: EnergyPlusData) -> None:
    """
    SUBROUTINE INFORMATION:
           AUTHOR         Simon Vidanovic
           DATE WRITTEN   May 2017
           MODIFIED       na
           RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    Initialize scattering construction layers in Solar and Visible spectrum.
    """
    var s_mat = state.dataMaterial

    if s_mat.num_blinds > 0:
        CalcWindowBlindProperties(state)

    if s_mat.num_screens > 0:
        CalcWindowScreenProperties(state)

    var a_win_const_simp = CWindowConstructionsSimplified.instance(state)
    for constr_num in range(1, state.dataHeatBal.tot_constructs + 1):
        var construction = state.dataConstruction.Construct(constr_num)
        if construction.is_glazing_construction(state):
            for lay_num in range(1, construction.tot_layers + 1):
                var mat = s_mat.materials(construction.LayerPoint(lay_num))
                if mat.group != 4 and mat.group != 5 and mat.group != 8 and mat.group != 9:
                    construction.TransDiff = 0.1

                    var a_range = 0
                    var a_solar_layer = get_scattering_layer(state, mat, a_range)
                    a_win_const_simp.push_layer(a_range, constr_num, a_solar_layer)

                    a_range = 1
                    var a_visible_layer = get_scattering_layer(state, mat, a_range)
                    a_win_const_simp.push_layer(a_range, constr_num, a_visible_layer)

    for surf_num in range(1, state.dataSurface.tot_surfaces + 1):
        var surf = state.dataSurface.Surface(surf_num)
        var surf_shade = state.dataSurface.surf_shades(surf_num)

        if not surf.HeatTransSurf:
            continue
        if not state.dataConstruction.Construct(surf.Construction).TypeIsWindow:
            continue
        if state.dataSurface.SurfWinWindowModelType(surf_num) == 2:
            continue
        if state.dataConstruction.Construct(surf.Construction).WindowTypeEQL:
            continue

        if surf.activeShadedConstruction == 0:
            continue

        var constr_sh = state.dataConstruction.Construct(surf.activeShadedConstruction)
        var tot_lay = constr_sh.TotLayers
        var mat = s_mat.materials(constr_sh.LayerPoint(tot_lay))

        if mat.group == 3:
            var mat_shade = mat
            var eps_gl_ir = s_mat.materials(constr_sh.LayerPoint(tot_lay - 1)).AbsorpThermalBack
            var rho_gl_ir = 1.0 - eps_gl_ir
            var tau_sh_ir = mat_shade.TransThermal
            var eps_sh_ir = mat_shade.AbsorpThermal
            var rho_sh_ir = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir)
            surf_shade.effShadeEmi = eps_sh_ir * (1.0 + rho_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir))
            surf_shade.effGlassEmi = eps_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir)

        elif mat.group == 1:
            var eps_gl_ir = s_mat.materials(constr_sh.LayerPoint(tot_lay - 1)).AbsorpThermalBack
            var rho_gl_ir = 1.0 - eps_gl_ir

            var mat_blind = mat
            for i_slat_ang in range(5):
                var btar = mat_blind.TARs[i_slat_ang]
                var tau_sh_ir = btar.IR.Ft.Tra
                var eps_sh_ir = btar.IR.Ft.Emi
                var rho_sh_ir = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir)
                constr_sh.effShadeBlindEmi[i_slat_ang] = eps_sh_ir * (1.0 + rho_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir))
                constr_sh.effGlassEmi[i_slat_ang] = eps_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir)

fn get_solar_trans_direct_hemispherical(state: EnergyPlusData, constr_num: Int) -> Float64:
    var a_win_const_simp = CWindowConstructionsSimplified.instance(state).get_equivalent_layer(state, 0, constr_num)
    return a_win_const_simp.get_property_simple(0.3, 2.5, 0, 0, 0)

fn get_visible_trans_direct_hemispherical(state: EnergyPlusData, constr_num: Int) -> Float64:
    var a_win_const_simp = CWindowConstructionsSimplified.instance(state).get_equivalent_layer(state, 1, constr_num)
    return a_win_const_simp.get_property_simple(0.38, 0.78, 0, 0, 0)

struct CWCEMaterialFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        pass

struct CWCESpecularMaterialsFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        var mat_glass = self.m_material_properties

        if mat_glass.GlassSpectralDataPtr > 0:
            var a_solar_spectrum = CWCESpecturmProperties.get_default_solar_radiation_spectrum(state)
            var a_sample_data = CWCESpecturmProperties.get_spectral_sample(state, mat_glass.GlassSpectralDataPtr)
            var a_sample = CSpectralSample(a_sample_data, a_solar_spectrum)

            var a_type = 0
            var a_range = CWavelengthRange(self.m_range)
            var low_lambda = a_range.min_lambda()
            var high_lambda = a_range.max_lambda()

            if self.m_range == 1 and mat_glass.GlassSpectralDataPtr != 0:
                var a_photopic_response = CWCESpecturmProperties.get_default_visible_photopic_response(state)
                a_sample.set_detector_data(a_photopic_response)

            var thickness = mat_glass.Thickness
            self.m_material = CMaterialSample(a_sample, thickness, a_type, low_lambda, high_lambda)
        else:
            if self.m_range == 0:
                self.m_material = CMaterialSingleBand(mat_glass.Trans, mat_glass.Trans,
                                                       mat_glass.ReflectSolBeamFront, mat_glass.ReflectSolBeamBack, self.m_range)
            if self.m_range == 1:
                self.m_material = CMaterialSingleBand(mat_glass.TransVis, mat_glass.TransVis,
                                                       mat_glass.ReflectVisBeamFront, mat_glass.ReflectVisBeamBack, self.m_range)

struct CWCEMaterialDualBandFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        if self.m_range == 1:
            self.m_material = self.create_visible_range_material(state)
        else:
            var a_visible_range_material = self.create_visible_range_material(state)
            var a_solar_range_material = self.create_solar_range_material(state)
            var ratio = 0.49
            self.m_material = CMaterialDualBand(a_visible_range_material, a_solar_range_material, ratio)

    fn create_visible_range_material(inout self, state: EnergyPlusData) -> CMaterialSingleBand:
        return CMaterialSingleBand(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    fn create_solar_range_material(inout self, state: EnergyPlusData) -> CMaterialSingleBand:
        return CMaterialSingleBand(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

struct CWCEVenetianBlindMaterialsFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        if self.m_range == 1:
            self.m_material = self.create_visible_range_material(state)
        else:
            var a_visible_range_material = self.create_visible_range_material(state)
            var a_solar_range_material = self.create_solar_range_material(state)
            var ratio = 0.49
            self.m_material = CMaterialDualBand(a_visible_range_material, a_solar_range_material, ratio)

    fn create_visible_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_blind = self.m_material_properties
        var a_range = CWavelengthRange(1)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = mat_blind.slatTAR.Vis.Ft.Df.Tra
        var tb = mat_blind.slatTAR.Vis.Ft.Df.Tra
        var rf = mat_blind.slatTAR.Vis.Ft.Df.Ref
        var rb = mat_blind.slatTAR.Vis.Bk.Df.Ref

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    fn create_solar_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_blind = self.m_material_properties
        var a_range = CWavelengthRange(0)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = mat_blind.slatTAR.Sol.Ft.Df.Tra
        var tb = mat_blind.slatTAR.Sol.Ft.Df.Tra
        var rf = mat_blind.slatTAR.Sol.Ft.Df.Ref
        var rb = mat_blind.slatTAR.Sol.Bk.Df.Ref

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

struct CWCEScreenMaterialsFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        if self.m_range == 1:
            self.m_material = self.create_visible_range_material(state)
        else:
            var a_visible_range_material = self.create_visible_range_material(state)
            var a_solar_range_material = self.create_solar_range_material(state)
            var ratio = 0.49
            self.m_material = CMaterialDualBand(a_visible_range_material, a_solar_range_material, ratio)

    fn create_visible_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_shade = self.m_material_properties
        var a_range = CWavelengthRange(1)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = 0.0
        var tb = 0.0
        var rf = mat_shade.ReflectShadeVis
        var rb = mat_shade.ReflectShadeVis

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    fn create_solar_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_shade = self.m_material_properties
        var a_range = CWavelengthRange(0)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = 0.0
        var tb = 0.0
        var rf = mat_shade.ReflectShade
        var rb = mat_shade.ReflectShade

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

struct CWCEDiffuseShadeMaterialsFactory:
    var m_material_properties: MaterialBase
    var m_range: Int
    var m_initialized: Bool
    var m_material: CMaterial

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material_properties = t_material
        self.m_range = t_range
        self.m_initialized = False

    fn get_material(inout self, state: EnergyPlusData) -> CMaterial:
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    fn init(inout self, state: EnergyPlusData):
        if self.m_range == 1:
            self.m_material = self.create_visible_range_material(state)
        else:
            var a_visible_range_material = self.create_visible_range_material(state)
            var a_solar_range_material = self.create_solar_range_material(state)
            var ratio = 0.49
            self.m_material = CMaterialDualBand(a_visible_range_material, a_solar_range_material, ratio)

    fn create_visible_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_shade = self.m_material_properties
        var a_range = CWavelengthRange(1)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = mat_shade.TransVis
        var tb = mat_shade.TransVis
        var rf = mat_shade.ReflectShadeVis
        var rb = mat_shade.ReflectShadeVis

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    fn create_solar_range_material(self, state: EnergyPlusData) -> CMaterialSingleBand:
        var mat_shade = self.m_material_properties
        var a_range = CWavelengthRange(0)
        var low_lambda = a_range.min_lambda()
        var high_lambda = a_range.max_lambda()

        var tf = mat_shade.Trans
        var tb = mat_shade.Trans
        var rf = mat_shade.ReflectShade
        var rb = mat_shade.ReflectShade

        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

struct IWCECellDescriptionFactory:
    var m_material: MaterialBase

    fn __init__(inout self, t_material: MaterialBase):
        self.m_material = t_material

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return CFlatCellDescription()

struct CWCESpecularCellFactory:
    var m_material: MaterialBase

    fn __init__(inout self, t_material: MaterialBase):
        self.m_material = t_material

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return CSpecularCellDescription()

struct CWCEVenetianBlindCellFactory:
    var m_material: MaterialBase

    fn __init__(inout self, t_material: MaterialBase):
        self.m_material = t_material

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        var mat_blind = self.m_material

        var slat_width = mat_blind.SlatWidth
        var slat_spacing = mat_blind.SlatSeparation
        var slat_tilt_angle = 90.0 - mat_blind.SlatAngle
        var curvature_radius = 0.0
        var num_of_slat_segments = 5

        return CVenetianCellDescription(slat_width, slat_spacing, slat_tilt_angle, curvature_radius, num_of_slat_segments)

struct CWCEScreenCellFactory:
    var m_material: MaterialBase

    fn __init__(inout self, t_material: MaterialBase):
        self.m_material = t_material

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        var diameter = self.m_material.Thickness
        var ratio = 1.0 - sqrt(self.m_material.Trans)
        var spacing = diameter / ratio
        return CWovenCellDescription(diameter, spacing)

struct CWCEDiffuseShadeCellFactory:
    var m_material: MaterialBase

    fn __init__(inout self, t_material: MaterialBase):
        self.m_material = t_material

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return CFlatCellDescription()

struct CWCELayerFactory:
    var m_material: MaterialBase
    var m_range: Int
    var m_bsdf_initialized: Bool
    var m_simple_initialized: Bool
    var m_material_factory: AnyType
    var m_cell_factory: AnyType
    var m_bsdf_layer: CBSDFLayer
    var m_scattering_layer: CScatteringLayer

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material = t_material
        self.m_range = t_range
        self.m_bsdf_initialized = False
        self.m_simple_initialized = False

    fn init(inout self, state: EnergyPlusData) -> Tuple[CMaterial, ICellDescription]:
        self.create_material_factory()
        var a_material = self.m_material_factory.get_material(state)
        var a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    fn get_bsdf_layer(inout self, state: EnergyPlusData) -> CBSDFLayer:
        if not self.m_bsdf_initialized:
            var res = self.init(state)
            var a_bsdf = CBSDFHemisphere.create(0)
            var a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    fn get_layer(inout self, state: EnergyPlusData) -> CScatteringLayer:
        if not self.m_simple_initialized:
            var res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return self.m_cell_factory.get_cell_description(state)

    fn create_material_factory(inout self):
        pass

struct CWCESpecularLayerFactory:
    var m_material: MaterialBase
    var m_range: Int
    var m_bsdf_initialized: Bool
    var m_simple_initialized: Bool
    var m_material_factory: AnyType
    var m_cell_factory: AnyType
    var m_bsdf_layer: CBSDFLayer
    var m_scattering_layer: CScatteringLayer

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material = t_material
        self.m_range = t_range
        self.m_bsdf_initialized = False
        self.m_simple_initialized = False
        self.m_cell_factory = CWCESpecularCellFactory(t_material)

    fn create_material_factory(inout self):
        self.m_material_factory = CWCESpecularMaterialsFactory(self.m_material, self.m_range)

    fn init(inout self, state: EnergyPlusData) -> Tuple[CMaterial, ICellDescription]:
        self.create_material_factory()
        var a_material = self.m_material_factory.get_material(state)
        var a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    fn get_bsdf_layer(inout self, state: EnergyPlusData) -> CBSDFLayer:
        if not self.m_bsdf_initialized:
            var res = self.init(state)
            var a_bsdf = CBSDFHemisphere.create(0)
            var a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    fn get_layer(inout self, state: EnergyPlusData) -> CScatteringLayer:
        if not self.m_simple_initialized:
            var res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return self.m_cell_factory.get_cell_description(state)

struct CWCEVenetianBlindLayerFactory:
    var m_material: MaterialBase
    var m_range: Int
    var m_bsdf_initialized: Bool
    var m_simple_initialized: Bool
    var m_material_factory: AnyType
    var m_cell_factory: AnyType
    var m_bsdf_layer: CBSDFLayer
    var m_scattering_layer: CScatteringLayer

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material = t_material
        self.m_range = t_range
        self.m_bsdf_initialized = False
        self.m_simple_initialized = False
        self.m_cell_factory = CWCEVenetianBlindCellFactory(t_material)

    fn create_material_factory(inout self):
        self.m_material_factory = CWCEVenetianBlindMaterialsFactory(self.m_material, self.m_range)

    fn init(inout self, state: EnergyPlusData) -> Tuple[CMaterial, ICellDescription]:
        self.create_material_factory()
        var a_material = self.m_material_factory.get_material(state)
        var a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    fn get_bsdf_layer(inout self, state: EnergyPlusData) -> CBSDFLayer:
        if not self.m_bsdf_initialized:
            var res = self.init(state)
            var a_bsdf = CBSDFHemisphere.create(0)
            var a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    fn get_layer(inout self, state: EnergyPlusData) -> CScatteringLayer:
        if not self.m_simple_initialized:
            var res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return self.m_cell_factory.get_cell_description(state)

struct CWCEScreenLayerFactory:
    var m_material: MaterialBase
    var m_range: Int
    var m_bsdf_initialized: Bool
    var m_simple_initialized: Bool
    var m_material_factory: AnyType
    var m_cell_factory: AnyType
    var m_bsdf_layer: CBSDFLayer
    var m_scattering_layer: CScatteringLayer

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material = t_material
        self.m_range = t_range
        self.m_bsdf_initialized = False
        self.m_simple_initialized = False
        self.m_cell_factory = CWCEScreenCellFactory(t_material)

    fn create_material_factory(inout self):
        self.m_material_factory = CWCEScreenMaterialsFactory(self.m_material, self.m_range)

    fn init(inout self, state: EnergyPlusData) -> Tuple[CMaterial, ICellDescription]:
        self.create_material_factory()
        var a_material = self.m_material_factory.get_material(state)
        var a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    fn get_bsdf_layer(inout self, state: EnergyPlusData) -> CBSDFLayer:
        if not self.m_bsdf_initialized:
            var res = self.init(state)
            var a_bsdf = CBSDFHemisphere.create(0)
            var a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    fn get_layer(inout self, state: EnergyPlusData) -> CScatteringLayer:
        if not self.m_simple_initialized:
            var res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return self.m_cell_factory.get_cell_description(state)

struct CWCEDiffuseShadeLayerFactory:
    var m_material: MaterialBase
    var m_range: Int
    var m_bsdf_initialized: Bool
    var m_simple_initialized: Bool
    var m_material_factory: AnyType
    var m_cell_factory: AnyType
    var m_bsdf_layer: CBSDFLayer
    var m_scattering_layer: CScatteringLayer

    fn __init__(inout self, t_material: MaterialBase, t_range: Int):
        self.m_material = t_material
        self.m_range = t_range
        self.m_bsdf_initialized = False
        self.m_simple_initialized = False
        self.m_cell_factory = CWCEDiffuseShadeCellFactory(t_material)

    fn create_material_factory(inout self):
        self.m_material_factory = CWCEDiffuseShadeMaterialsFactory(self.m_material, self.m_range)

    fn init(inout self, state: EnergyPlusData) -> Tuple[CMaterial, ICellDescription]:
        self.create_material_factory()
        var a_material = self.m_material_factory.get_material(state)
        var a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    fn get_bsdf_layer(inout self, state: EnergyPlusData) -> CBSDFLayer:
        if not self.m_bsdf_initialized:
            var res = self.init(state)
            var a_bsdf = CBSDFHemisphere.create(0)
            var a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    fn get_layer(inout self, state: EnergyPlusData) -> CScatteringLayer:
        if not self.m_simple_initialized:
            var res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    fn get_cell_description(self, state: EnergyPlusData) -> ICellDescription:
        return self.m_cell_factory.get_cell_description(state)
