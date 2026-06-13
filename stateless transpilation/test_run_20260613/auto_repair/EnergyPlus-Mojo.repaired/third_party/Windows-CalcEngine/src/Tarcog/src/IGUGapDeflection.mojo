from IGUGapLayer import CIGUGapLayer
from WCECommon import *
from Surface import *
from memory import shared_ptr, make_shared
from BaseLayer import CBaseLayer

@value
struct CIGUGapLayerDeflection(CIGUGapLayer):
    var m_Tini: Float64
    var m_Pini: Float64

    def __init__(inout self, t_GapLayer: CIGUGapLayer, t_Tini: Float64, t_Pini: Float64):
        CIGUGapLayer.__init__(self, t_GapLayer)
        self.m_Tini = t_Tini
        self.m_Pini = t_Pini

    def getPressure(inout self) -> Float64:
        var Vini = self.m_Width * self.m_Height * self.m_Thickness
        var modThickness = self.getThickness()
        var Vgap = self.m_Width * self.m_Height * modThickness
        return self.m_Pini * Vini * self.layerTemperature() / (self.m_Tini * Vgap)

    def clone(self) -> shared_ptr[CBaseLayer]:
        return make_shared[CIGUGapLayerDeflection](self)