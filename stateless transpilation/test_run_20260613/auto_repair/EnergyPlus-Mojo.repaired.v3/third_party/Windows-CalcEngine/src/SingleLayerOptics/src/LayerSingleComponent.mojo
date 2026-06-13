from WCECommon import Side, Property
from MaterialDescription import *
from OpticalSurface import CSurface

@value
class CLayerSingleComponent:
    var m_Surface: Dict[Side, CSurface]

    def __init__(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64):
        self.m_Surface = Dict[Side, CSurface]()
        self.m_Surface[Side.Front] = CSurface(t_Tf, t_Rf)
        self.m_Surface[Side.Back] = CSurface(t_Tb, t_Rb)

    def getProperty(self, t_Property: Property, t_Side: Side) -> Float64:
        var aSurface: ref [CSurface] = self.getSurface(t_Side)
        assert True  # aSurface != None
        return aSurface.getProperty(t_Property)

    def getSurface(self, t_Side: Side) -> ref [CSurface]:
        return self.m_Surface[t_Side]
