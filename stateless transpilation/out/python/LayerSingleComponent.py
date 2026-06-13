# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: enum from FenestrationCommon
# - FenestrationCommon.Property: enum from FenestrationCommon
# - CSurface: class from OpticalSurface

class CLayerSingleComponent:
    def __init__(self, t_Tf: float, t_Rf: float, t_Tb: float, t_Rb: float) -> None:
        self.m_Surface = {}
        self.m_Surface[FenestrationCommon.Side.Front] = CSurface(t_Tf, t_Rf)
        self.m_Surface[FenestrationCommon.Side.Back] = CSurface(t_Tb, t_Rb)
    
    def getProperty(self, t_Property, t_Side):
        a_surface = self.getSurface(t_Side)
        assert a_surface is not None
        return a_surface.getProperty(t_Property)
    
    def getSurface(self, t_Side):
        return self.m_Surface[t_Side]
