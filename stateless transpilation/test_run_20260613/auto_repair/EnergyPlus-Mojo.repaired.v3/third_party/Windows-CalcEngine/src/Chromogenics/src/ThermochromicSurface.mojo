from WCETarcog import ISurface
from memory import shared_ptr, make_shared
from IInterpolation2D import IInterpolation2D
from CSPChipInterpolation2D import CSPChipInterpolation2D

@value
struct CThermochromicSurface(ISurface):
    var m_EmissivityInterpolator: shared_ptr[IInterpolation2D]
    var m_TransmittanceInterpolator: shared_ptr[IInterpolation2D]

    def __init__(inout self, t_Emissivity: List[Tuple[Float64, Float64]], t_Transmittance: List[Tuple[Float64, Float64]]):
        ISurface.__init__(self, 0, 0)
        self.m_EmissivityInterpolator = make_shared[CSPChipInterpolation2D](t_Emissivity)
        self.m_TransmittanceInterpolator = make_shared[CSPChipInterpolation2D](t_Transmittance)

    def __init__(inout self, t_Emissivity: Float64, t_Transmittance: List[Tuple[Float64, Float64]]):
        ISurface.__init__(self, t_Emissivity, 0)
        self.m_EmissivityInterpolator = shared_ptr[IInterpolation2D]()
        self.m_TransmittanceInterpolator = make_shared[CSPChipInterpolation2D](t_Transmittance)

    def __init__(inout self, t_Emissivity: List[Tuple[Float64, Float64]], t_Transmittance: Float64):
        ISurface.__init__(self, 0, t_Transmittance)
        self.m_EmissivityInterpolator = make_shared[CSPChipInterpolation2D](t_Emissivity)
        self.m_TransmittanceInterpolator = shared_ptr[IInterpolation2D]()

    def __init__(inout self, t_Surface: CThermochromicSurface):
        ISurface.__init__(self, t_Surface)
        self.m_EmissivityInterpolator = t_Surface.m_EmissivityInterpolator
        self.m_TransmittanceInterpolator = t_Surface.m_TransmittanceInterpolator

    def __copyinit__(inout self, other: CThermochromicSurface):
        self.m_EmissivityInterpolator = other.m_EmissivityInterpolator
        self.m_TransmittanceInterpolator = other.m_TransmittanceInterpolator

    def clone(self) -> shared_ptr[ISurface]:
        return make_shared[CThermochromicSurface](self)

    def setTemperature(inout self, t_Temperature: Float64):
        if self.m_EmissivityInterpolator:
            self.m_Emissivity = self.m_EmissivityInterpolator.getValue(t_Temperature)
            self.calculateReflectance()
        if self.m_TransmittanceInterpolator:
            self.m_Transmittance = self.m_TransmittanceInterpolator.getValue(t_Temperature)
            self.calculateReflectance()
        self.m_Temperature = t_Temperature