# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: enum from FenestrationCommon
# - FenestrationCommon.Property: enum from FenestrationCommon
# - CSurface: struct from OpticalSurface

struct CLayerSingleComponent:
    var m_Surface: dict[Side, CSurface]
    
    fn __init__(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64):
        self.m_Surface = dict[Side, CSurface]()
        self.m_Surface[Side.Front] = CSurface(t_Tf, t_Rf)
        self.m_Surface[Side.Back] = CSurface(t_Tb, t_Rb)
    
    fn getProperty(self, t_Property: Property, t_Side: Side) -> Float64:
        var a_surface = self.getSurface(t_Side)
        return a_surface.getProperty(t_Property)
    
    fn getSurface(self, t_Side: Side) -> CSurface:
        return self.m_Surface[t_Side]
