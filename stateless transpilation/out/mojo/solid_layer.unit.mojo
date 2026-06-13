# EXTERNAL DEPS (to wire in glue):
# - Tarcog::ISO15099::CSurface (from WCETarcog.hpp)
# - Tarcog::ISO15099::CIGUSolidLayer (from WCETarcog.hpp)

from math import abs


struct CSurface:
    """Stub: Tarcog::ISO15099::CSurface from WCETarcog.hpp"""
    
    fn setTemperature(inout self, temp: Float64):
        pass


struct CIGUSolidLayer:
    """Stub: Tarcog::ISO15099::CIGUSolidLayer from WCETarcog.hpp"""
    
    fn __init__(inout self, thickness: Float64, conductivity: Float64, surface1: CSurface, surface2: CSurface):
        pass
    
    fn getConvectionConductionFlow(self) -> Float64:
        return 0.0


struct TestSolidLayer:
    var m_SolidLayer: CIGUSolidLayer
    
    fn __init__(inout self):
        var surface1 = CSurface()
        surface1.setTemperature(280)
        
        var surface2 = CSurface()
        surface2.setTemperature(300)
        
        self.m_SolidLayer = CIGUSolidLayer(0.01, 2.5, surface1, surface2)
    
    fn GetLayer(self) -> CIGUSolidLayer:
        return self.m_SolidLayer
    
    fn Test1(self):
        var aLayer = self.GetLayer()
        var conductionHeatFlow = aLayer.getConvectionConductionFlow()
        assert abs(conductionHeatFlow - 5000.0) < 1e-6


fn main():
    var test = TestSolidLayer()
    test.Test1()
