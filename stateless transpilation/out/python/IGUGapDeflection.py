# EXTERNAL DEPS (to wire in glue):
# - CIGUGapLayer: from tarcog.iso15099.igu_gap_layer
#   Provides: m_width, m_height, m_thickness (float)
#   Methods: get_thickness() -> float, layer_temperature() -> float
# - CBaseLayer: from tarcog.iso15099.base_layer


class CIGUGapLayer:
    """Placeholder for base class - wire in from actual implementation"""
    def __init__(self, gap_layer=None):
        if gap_layer is not None:
            self.m_width = gap_layer.m_width
            self.m_height = gap_layer.m_height
            self.m_thickness = gap_layer.m_thickness
        else:
            self.m_width = 0.0
            self.m_height = 0.0
            self.m_thickness = 0.0
    
    def get_thickness(self) -> float:
        raise NotImplementedError()
    
    def layer_temperature(self) -> float:
        raise NotImplementedError()


class CBaseLayer:
    """Placeholder for base class - wire in from actual implementation"""
    pass


class CIGUGapLayerDeflection(CIGUGapLayer):
    def __init__(self, t_gap_layer: CIGUGapLayer, t_tini: float, t_pini: float):
        super().__init__(t_gap_layer)
        self.m_tini = t_tini
        self.m_pini = t_pini
    
    def get_pressure(self) -> float:
        vini = self.m_width * self.m_height * self.m_thickness
        mod_thickness = self.get_thickness()
        vgap = self.m_width * self.m_height * mod_thickness
        return self.m_pini * vini * self.layer_temperature() / (self.m_tini * vgap)
    
    def clone(self) -> CBaseLayer:
        return CIGUGapLayerDeflection(self, self.m_tini, self.m_pini)
