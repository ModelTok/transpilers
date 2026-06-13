from WCECommon import ConstantsData
from OpticalSurface import (
    FenestrationCommon,
    Property,
    PropertySimple,
    Scattering,
    ScatteringSimple,
    CSurface,
    CScatteringSurface,
)
from memory import Dict
from utils import StringRef

@value
class CSurface:
    var m_Property: Dict[Property, Float64]

    def __init__(inout self, t_T: Float64, t_R: Float64):
        if t_T + t_R > (1.0 + ConstantsData.floatErrorTolerance):
            var err_msg: StringRef = StringRef(
                "Sum of Transmittance and Reflectance is greater than one.\n"
                "Transmittance: " + str(t_T) + "\nReflectance: " + str(t_R)
            )
            raise Error(err_msg)
        self.m_Property[Property.T] = t_T
        self.m_Property[Property.R] = t_R
        self.m_Property[Property.Abs] = 1 - t_T - t_R

    def getProperty(inout self, t_Property: Property) -> Float64:
        return self.m_Property[t_Property]

@value
class CScatteringSurface:
    var m_PropertySimple: Dict[Tuple[PropertySimple, Scattering], Float64]
    var m_Absorptance: Dict[ScatteringSimple, Float64]

    def __init__(
        inout self,
        T_dir_dir: Float64,
        R_dir_dir: Float64,
        T_dir_dif: Float64,
        R_dir_dif: Float64,
        T_dif_dif: Float64,
        R_dif_dif: Float64,
    ):
        if R_dir_dif != 0 and 1 == T_dir_dir:
            R_dir_dif = 0
        if T_dir_dif != 0 and 1 == T_dir_dir:
            T_dir_dif = 0
        self.m_PropertySimple[(PropertySimple.T, Scattering.DirectDirect)] = T_dir_dir
        self.m_PropertySimple[(PropertySimple.R, Scattering.DirectDirect)] = R_dir_dir
        self.m_PropertySimple[(PropertySimple.T, Scattering.DirectDiffuse)] = T_dir_dif
        self.m_PropertySimple[(PropertySimple.R, Scattering.DirectDiffuse)] = R_dir_dif
        self.m_PropertySimple[(PropertySimple.T, Scattering.DirectHemispherical)] = (
            T_dir_dif + T_dir_dir
        )
        self.m_PropertySimple[(PropertySimple.R, Scattering.DirectHemispherical)] = (
            R_dir_dif + R_dir_dir
        )
        self.m_PropertySimple[(PropertySimple.T, Scattering.DiffuseDiffuse)] = T_dif_dif
        self.m_PropertySimple[(PropertySimple.R, Scattering.DiffuseDiffuse)] = R_dif_dif
        self.m_Absorptance[ScatteringSimple.Direct] = (
            1 - T_dir_dir - T_dir_dif - R_dir_dir - R_dir_dif
        )
        self.m_Absorptance[ScatteringSimple.Diffuse] = 1 - T_dif_dif - R_dif_dif

    def getPropertySimple(
        inout self, t_Property: PropertySimple, t_Scattering: Scattering
    ) -> Float64:
        return self.m_PropertySimple[(t_Property, t_Scattering)]

    def setPropertySimple(
        inout self,
        t_Property: PropertySimple,
        t_Scattering: Scattering,
        value: Float64,
    ):
        self.m_PropertySimple[(t_Property, t_Scattering)] = value

    def getAbsorptance(inout self, t_Scattering: ScatteringSimple) -> Float64:
        return self.m_Absorptance[t_Scattering]

    def getAbsorptance(inout self) -> Float64:
        return self.m_Absorptance[ScatteringSimple.Direct] + self.m_Absorptance[ScatteringSimple.Diffuse]