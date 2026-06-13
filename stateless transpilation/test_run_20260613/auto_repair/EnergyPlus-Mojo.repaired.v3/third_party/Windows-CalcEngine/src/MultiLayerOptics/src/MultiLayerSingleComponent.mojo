from WCECommon import Side, Property
from MultiLayerInterRefSingleComponent import CInterRefSingleComponent
from EquivalentLayerSingleComponent import CEquivalentLayerSingleComponent

@value
struct CMultiLayerSingleComponent:
    var m_Inter: CInterRefSingleComponent
    var m_Equivalent: CEquivalentLayerSingleComponent

    def __init__(inout self, t_Tf: Float64 = 0, t_Rf: Float64 = 0, t_Tb: Float64 = 0, t_Rb: Float64 = 0):
        self.m_Inter = CInterRefSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb)
        self.m_Equivalent = CEquivalentLayerSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb)

    def addLayer(self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: Side = Side.Back):
        self.m_Inter.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)
        self.m_Equivalent.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)

    def getProperty(self, t_Property: Property, t_Side: Side) -> Float64:
        return self.m_Equivalent.getProperty(t_Property, t_Side)

    def getLayerAbsorptance(self, Index: Int, t_Side: Side) -> Float64:
        return self.m_Inter.getLayerAbsorptance(Index, t_Side)