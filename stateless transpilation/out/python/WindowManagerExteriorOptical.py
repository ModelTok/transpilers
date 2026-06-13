# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (dataMaterial, dataConstruction, dataHeatBal, dataSurface)
# - Material.MaterialBase, MaterialGlass, MaterialBlind, MaterialShade, MaterialScreen: material types
# - Material.Group: enum (Glass, GlassSimple, Blind, Screen, Shade, Gas, GasMixture, ComplexWindowGap, ComplexShade)
# - Material.MaxSlatAngs: constant int
# - FenestrationCommon.WavelengthRange: enum (Solar=0, Visible=1)
# - SingleLayerOptics.CBSDFLayer, CScatteringLayer, CMaterial, CMaterialSingleBand, CMaterialDualBand, CMaterialSample
# - SingleLayerOptics.ICellDescription, CSpecularCellDescription, CVenetianCellDescription, CWovenCellDescription, CFlatCellDescription
# - SingleLayerOptics.CBSDFHemisphere, BSDFBasis, CBSDFLayerMaker, CWavelengthRange, CSpectralSample, CSpectralSampleData
# - FenestrationCommon.PropertySimple, Side, Scattering: enums
# - CWindowConstructionsSimplified.instance(state): singleton access
# - CWCESpecturmProperties: utility class with static methods
# - CalcWindowBlindProperties(state): function
# - CalcWindowScreenProperties(state): function
# - WindowModel.BSDF: enum value

from abc import ABC, abstractmethod
from typing import Optional, Tuple, Any

def get_bsdf_layer(state: 'EnergyPlusData', t_material: 'MaterialBase', t_range: int) -> 'CBSDFLayer':
    """
    SUBROUTINE INFORMATION:
           AUTHOR         Simon Vidanovic
           DATE WRITTEN   September 2016
           MODIFIED       na
           RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    BSDF will be created in different ways that is based on material type
    """
    a_factory: Optional[CWCELayerFactory] = None
    if t_material.group == 0:  # Material::Group::Glass
        a_factory = CWCESpecularLayerFactory(t_material, t_range)
    elif t_material.group == 1:  # Material::Group::Blind
        a_factory = CWCEVenetianBlindLayerFactory(t_material, t_range)
    elif t_material.group == 2:  # Material::Group::Screen
        a_factory = CWCEScreenLayerFactory(t_material, t_range)
    elif t_material.group == 3:  # Material::Group::Shade
        a_factory = CWCEDiffuseShadeLayerFactory(t_material, t_range)
    return a_factory.get_bsdf_layer(state)

def get_scattering_layer(state: 'EnergyPlusData', t_material: 'MaterialBase', t_range: int) -> 'CScatteringLayer':
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
    a_factory: Optional[CWCELayerFactory] = None
    if t_material.group == 0 or t_material.group == 10:  # Glass or GlassSimple
        a_factory = CWCESpecularLayerFactory(t_material, t_range)
    elif t_material.group == 1:  # Blind
        a_factory = CWCEVenetianBlindLayerFactory(t_material, t_range)
    elif t_material.group == 2:  # Screen
        a_factory = CWCEScreenLayerFactory(t_material, t_range)
    elif t_material.group == 3:  # Shade
        a_factory = CWCEDiffuseShadeLayerFactory(t_material, t_range)
    return a_factory.get_layer(state)

def init_wce_simplified_optical_data(state: 'EnergyPlusData') -> None:
    """
    SUBROUTINE INFORMATION:
           AUTHOR         Simon Vidanovic
           DATE WRITTEN   May 2017
           MODIFIED       na
           RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    Initialize scattering construction layers in Solar and Visible spectrum.
    """
    s_mat = state.dataMaterial

    if s_mat.num_blinds > 0:
        CalcWindowBlindProperties(state)

    if s_mat.num_screens > 0:
        CalcWindowScreenProperties(state)

    a_win_const_simp = CWindowConstructionsSimplified.instance(state)
    for constr_num in range(1, state.dataHeatBal.tot_constructs + 1):
        construction = state.dataConstruction.Construct(constr_num)
        if construction.is_glazing_construction(state):
            for lay_num in range(1, construction.tot_layers + 1):
                mat = s_mat.materials(construction.LayerPoint(lay_num))
                if (mat.group != 4 and mat.group != 5 and  # Gas, GasMixture
                    mat.group != 8 and mat.group != 9):     # ComplexWindowGap, ComplexShade
                    construction.TransDiff = 0.1

                    a_range = 0  # WavelengthRange::Solar
                    a_solar_layer = get_scattering_layer(state, mat, a_range)
                    a_win_const_simp.push_layer(a_range, constr_num, a_solar_layer)

                    a_range = 1  # WavelengthRange::Visible
                    a_visible_layer = get_scattering_layer(state, mat, a_range)
                    a_win_const_simp.push_layer(a_range, constr_num, a_visible_layer)

    for surf_num in range(1, state.dataSurface.tot_surfaces + 1):
        surf = state.dataSurface.Surface(surf_num)
        surf_shade = state.dataSurface.surf_shades(surf_num)

        if not surf.HeatTransSurf:
            continue
        if not state.dataConstruction.Construct(surf.Construction).TypeIsWindow:
            continue
        if state.dataSurface.SurfWinWindowModelType(surf_num) == 2:  # WindowModel::BSDF
            continue
        if state.dataConstruction.Construct(surf.Construction).WindowTypeEQL:
            continue

        if surf.activeShadedConstruction == 0:
            continue

        constr_sh = state.dataConstruction.Construct(surf.activeShadedConstruction)
        tot_lay = constr_sh.TotLayers
        mat = s_mat.materials(constr_sh.LayerPoint(tot_lay))

        if mat.group == 3:  # Shade
            mat_shade = mat
            eps_gl_ir = s_mat.materials(constr_sh.LayerPoint(tot_lay - 1)).AbsorpThermalBack
            rho_gl_ir = 1.0 - eps_gl_ir
            tau_sh_ir = mat_shade.TransThermal
            eps_sh_ir = mat_shade.AbsorpThermal
            rho_sh_ir = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir)
            surf_shade.effShadeEmi = eps_sh_ir * (1.0 + rho_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir))
            surf_shade.effGlassEmi = eps_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir)

        elif mat.group == 1:  # Blind
            eps_gl_ir = s_mat.materials(constr_sh.LayerPoint(tot_lay - 1)).AbsorpThermalBack
            rho_gl_ir = 1.0 - eps_gl_ir

            mat_blind = mat
            for i_slat_ang in range(5):  # Material::MaxSlatAngs
                btar = mat_blind.TARs[i_slat_ang]
                tau_sh_ir = btar.IR.Ft.Tra
                eps_sh_ir = btar.IR.Ft.Emi
                rho_sh_ir = max(0.0, 1.0 - tau_sh_ir - eps_sh_ir)
                constr_sh.effShadeBlindEmi[i_slat_ang] = eps_sh_ir * (1.0 + rho_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir))
                constr_sh.effGlassEmi[i_slat_ang] = eps_gl_ir * tau_sh_ir / (1.0 - rho_gl_ir * rho_sh_ir)

def get_solar_trans_direct_hemispherical(state: 'EnergyPlusData', constr_num: int) -> float:
    a_win_const_simp = CWindowConstructionsSimplified.instance(state).get_equivalent_layer(state, 0, constr_num)
    return a_win_const_simp.get_property_simple(0.3, 2.5, 0, 0, 0)  # PropertySimple::T, Side::Front, Scattering::DirectHemispherical

def get_visible_trans_direct_hemispherical(state: 'EnergyPlusData', constr_num: int) -> float:
    a_win_const_simp = CWindowConstructionsSimplified.instance(state).get_equivalent_layer(state, 1, constr_num)
    return a_win_const_simp.get_property_simple(0.38, 0.78, 0, 0, 0)  # PropertySimple::T, Side::Front, Scattering::DirectHemispherical

class CWCEMaterialFactory(ABC):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        self.m_material_properties: 'MaterialBase' = t_material
        self.m_range: int = t_range
        self.m_initialized: bool = False
        self.m_material: Optional['CMaterial'] = None

    def get_material(self, state: 'EnergyPlusData') -> 'CMaterial':
        if not self.m_initialized:
            self.init(state)
            self.m_initialized = True
        return self.m_material

    @abstractmethod
    def init(self, state: 'EnergyPlusData') -> None:
        pass

class CWCESpecularMaterialsFactory(CWCEMaterialFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)

    def init(self, state: 'EnergyPlusData') -> None:
        mat_glass = self.m_material_properties
        
        if mat_glass.GlassSpectralDataPtr > 0:
            a_solar_spectrum = CWCESpecturmProperties.get_default_solar_radiation_spectrum(state)
            a_sample_data = CWCESpecturmProperties.get_spectral_sample(state, mat_glass.GlassSpectralDataPtr)
            a_sample = CSpectralSample(a_sample_data, a_solar_spectrum)
            
            a_type = 0  # MaterialType::Monolithic
            a_range = CWavelengthRange(self.m_range)
            low_lambda = a_range.min_lambda()
            high_lambda = a_range.max_lambda()
            
            if self.m_range == 1 and mat_glass.GlassSpectralDataPtr != 0:  # Visible
                a_photopic_response = CWCESpecturmProperties.get_default_visible_photopic_response(state)
                a_sample.set_detector_data(a_photopic_response)
            
            thickness = mat_glass.Thickness
            self.m_material = CMaterialSample(a_sample, thickness, a_type, low_lambda, high_lambda)
        else:
            if self.m_range == 0:  # Solar
                self.m_material = CMaterialSingleBand(mat_glass.Trans, mat_glass.Trans,
                                                       mat_glass.ReflectSolBeamFront, mat_glass.ReflectSolBeamBack, self.m_range)
            if self.m_range == 1:  # Visible
                self.m_material = CMaterialSingleBand(mat_glass.TransVis, mat_glass.TransVis,
                                                       mat_glass.ReflectVisBeamFront, mat_glass.ReflectVisBeamBack, self.m_range)

class CWCEMaterialDualBandFactory(CWCEMaterialFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)

    def init(self, state: 'EnergyPlusData') -> None:
        if self.m_range == 1:  # Visible
            self.m_material = self.create_visible_range_material(state)
        else:
            a_visible_range_material = self.create_visible_range_material(state)
            a_solar_range_material = self.create_solar_range_material(state)
            ratio = 0.49
            self.m_material = CMaterialDualBand(a_visible_range_material, a_solar_range_material, ratio)

    @abstractmethod
    def create_visible_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        pass

    @abstractmethod
    def create_solar_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        pass

class CWCEVenetianBlindMaterialsFactory(CWCEMaterialDualBandFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)

    def create_visible_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_blind = self.m_material_properties
        a_range = CWavelengthRange(1)  # Visible
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = mat_blind.slatTAR.Vis.Ft.Df.Tra
        tb = mat_blind.slatTAR.Vis.Ft.Df.Tra
        rf = mat_blind.slatTAR.Vis.Ft.Df.Ref
        rb = mat_blind.slatTAR.Vis.Bk.Df.Ref
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    def create_solar_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_blind = self.m_material_properties
        a_range = CWavelengthRange(0)  # Solar
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = mat_blind.slatTAR.Sol.Ft.Df.Tra
        tb = mat_blind.slatTAR.Sol.Ft.Df.Tra
        rf = mat_blind.slatTAR.Sol.Ft.Df.Ref
        rb = mat_blind.slatTAR.Sol.Bk.Df.Ref
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

class CWCEScreenMaterialsFactory(CWCEMaterialDualBandFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)

    def create_visible_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_shade = self.m_material_properties
        a_range = CWavelengthRange(1)  # Visible
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = 0.0
        tb = 0.0
        rf = mat_shade.ReflectShadeVis
        rb = mat_shade.ReflectShadeVis
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    def create_solar_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_shade = self.m_material_properties
        a_range = CWavelengthRange(0)  # Solar
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = 0.0
        tb = 0.0
        rf = mat_shade.ReflectShade
        rb = mat_shade.ReflectShade
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

class CWCEDiffuseShadeMaterialsFactory(CWCEMaterialDualBandFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)

    def create_visible_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_shade = self.m_material_properties
        a_range = CWavelengthRange(1)  # Visible
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = mat_shade.TransVis
        tb = mat_shade.TransVis
        rf = mat_shade.ReflectShadeVis
        rb = mat_shade.ReflectShadeVis
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

    def create_solar_range_material(self, state: 'EnergyPlusData') -> 'CMaterialSingleBand':
        mat_shade = self.m_material_properties
        a_range = CWavelengthRange(0)  # Solar
        low_lambda = a_range.min_lambda()
        high_lambda = a_range.max_lambda()
        
        tf = mat_shade.Trans
        tb = mat_shade.Trans
        rf = mat_shade.ReflectShade
        rb = mat_shade.ReflectShade
        
        return CMaterialSingleBand(tf, tb, rf, rb, low_lambda, high_lambda)

class IWCECellDescriptionFactory(ABC):
    def __init__(self, t_material: 'MaterialBase') -> None:
        self.m_material: 'MaterialBase' = t_material

    @abstractmethod
    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        pass

class CWCESpecularCellFactory(IWCECellDescriptionFactory):
    def __init__(self, t_material: 'MaterialBase') -> None:
        super().__init__(t_material)

    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        return CSpecularCellDescription()

class CWCEVenetianBlindCellFactory(IWCECellDescriptionFactory):
    def __init__(self, t_material: 'MaterialBase') -> None:
        super().__init__(t_material)

    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        mat_blind = self.m_material
        
        slat_width = mat_blind.SlatWidth
        slat_spacing = mat_blind.SlatSeparation
        slat_tilt_angle = 90.0 - mat_blind.SlatAngle
        curvature_radius = 0.0
        num_of_slat_segments = 5
        
        return CVenetianCellDescription(slat_width, slat_spacing, slat_tilt_angle, curvature_radius, num_of_slat_segments)

class CWCEScreenCellFactory(IWCECellDescriptionFactory):
    def __init__(self, t_material: 'MaterialBase') -> None:
        super().__init__(t_material)

    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        diameter = self.m_material.Thickness
        ratio = 1.0 - (self.m_material.Trans ** 0.5)
        spacing = diameter / ratio
        return CWovenCellDescription(diameter, spacing)

class CWCEDiffuseShadeCellFactory(IWCECellDescriptionFactory):
    def __init__(self, t_material: 'MaterialBase') -> None:
        super().__init__(t_material)

    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        return CFlatCellDescription()

class CWCELayerFactory(ABC):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        self.m_material: 'MaterialBase' = t_material
        self.m_range: int = t_range
        self.m_bsdf_initialized: bool = False
        self.m_simple_initialized: bool = False
        self.m_material_factory: Optional[CWCEMaterialFactory] = None
        self.m_cell_factory: Optional[IWCECellDescriptionFactory] = None
        self.m_bsdf_layer: Optional['CBSDFLayer'] = None
        self.m_scattering_layer: Optional['CScatteringLayer'] = None

    def init(self, state: 'EnergyPlusData') -> Tuple['CMaterial', 'ICellDescription']:
        self.create_material_factory()
        a_material = self.m_material_factory.get_material(state)
        a_cell_description = self.get_cell_description(state)
        return (a_material, a_cell_description)

    def get_bsdf_layer(self, state: 'EnergyPlusData') -> 'CBSDFLayer':
        if not self.m_bsdf_initialized:
            res = self.init(state)
            a_bsdf = CBSDFHemisphere.create(0)  # BSDFBasis::Full
            a_maker = CBSDFLayerMaker(res[0], a_bsdf, res[1])
            self.m_bsdf_layer = a_maker.get_layer()
            self.m_bsdf_initialized = True
        return self.m_bsdf_layer

    def get_layer(self, state: 'EnergyPlusData') -> 'CScatteringLayer':
        if not self.m_simple_initialized:
            res = self.init(state)
            self.m_scattering_layer = CScatteringLayer(res[0], res[1])
            self.m_simple_initialized = True
        return self.m_scattering_layer

    def get_cell_description(self, state: 'EnergyPlusData') -> 'ICellDescription':
        return self.m_cell_factory.get_cell_description(state)

    @abstractmethod
    def create_material_factory(self) -> None:
        pass

class CWCESpecularLayerFactory(CWCELayerFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)
        self.m_cell_factory = CWCESpecularCellFactory(t_material)

    def create_material_factory(self) -> None:
        self.m_material_factory = CWCESpecularMaterialsFactory(self.m_material, self.m_range)

class CWCEVenetianBlindLayerFactory(CWCELayerFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)
        self.m_cell_factory = CWCEVenetianBlindCellFactory(t_material)

    def create_material_factory(self) -> None:
        self.m_material_factory = CWCEVenetianBlindMaterialsFactory(self.m_material, self.m_range)

class CWCEScreenLayerFactory(CWCELayerFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)
        self.m_cell_factory = CWCEScreenCellFactory(t_material)

    def create_material_factory(self) -> None:
        self.m_material_factory = CWCEScreenMaterialsFactory(self.m_material, self.m_range)

class CWCEDiffuseShadeLayerFactory(CWCELayerFactory):
    def __init__(self, t_material: 'MaterialBase', t_range: int) -> None:
        super().__init__(t_material, t_range)
        self.m_cell_factory = CWCEDiffuseShadeCellFactory(t_material)

    def create_material_factory(self) -> None:
        self.m_material_factory = CWCEDiffuseShadeMaterialsFactory(self.m_material, self.m_range)
