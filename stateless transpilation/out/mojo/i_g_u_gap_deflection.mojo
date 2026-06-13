# EXTERNAL DEPS (to wire in glue):
# - CIGUGapLayer: from tarcog.iso15099.i_g_u_gap_layer
#   Provides: m_width, m_height, m_thickness (Float64)
#   Methods: get_thickness() -> Float64, layer_temperature() -> Float64
# - CBaseLayer: from tarcog.iso15099.base_layer


struct CIGUGapLayer:
    var m_width: Float64
    var m_height: Float64
    var m_thickness: Float64
    
    fn __init__(inout self):
        self.m_width = 0.0
        self.m_height = 0.0
        self.m_thickness = 0.0
    
    fn get_thickness(self) -> Float64:
        raise Error("Not implemented - subclass must override")
    
    fn layer_temperature(self) -> Float64:
        raise Error("Not implemented - subclass must override")


struct CBaseLayer:
    pass


struct CIGUGapLayerDeflection:
    var m_width: Float64
    var m_height: Float64
    var m_thickness: Float64
    var m_tini: Float64
    var m_pini: Float64
    
    fn __init__(inout self, t_gap_layer: CIGUGapLayer, t_tini: Float64, t_pini: Float64):
        self.m_width = t_gap_layer.m_width
        self.m_height = t_gap_layer.m_height
        self.m_thickness = t_gap_layer.m_thickness
        self.m_tini = t_tini
        self.m_pini = t_pini
    
    fn get_thickness(self) -> Float64:
        raise Error("Not implemented - subclass must override")
    
    fn layer_temperature(self) -> Float64:
        raise Error("Not implemented - subclass must override")
    
    fn get_pressure(self) -> Float64:
        let vini = self.m_width * self.m_height * self.m_thickness
        let mod_thickness = self.get_thickness()
        let vgap = self.m_width * self.m_height * mod_thickness
        return self.m_pini * vini * self.layer_temperature() / (self.m_tini * vgap)
    
    fn clone(self) -> CIGUGapLayerDeflection:
        return CIGUGapLayerDeflection(CIGUGapLayer(), self.m_tini, self.m_pini)
