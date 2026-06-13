# EXTERNAL DEPS (to wire in glue):
# - Tarcog::ISO15099::CSurface (from WCETarcog.hpp)
# - Tarcog::ISO15099::CIGUSolidLayer (from WCETarcog.hpp)

import unittest


class CSurface:
    """Stub: Tarcog::ISO15099::CSurface from WCETarcog.hpp"""
    def setTemperature(self, temp: float) -> None:
        pass


class CIGUSolidLayer:
    """Stub: Tarcog::ISO15099::CIGUSolidLayer from WCETarcog.hpp"""
    def __init__(self, thickness: float, conductivity: float, surface1: CSurface, surface2: CSurface):
        pass
    
    def getConvectionConductionFlow(self) -> float:
        return 0.0


class TestSolidLayer(unittest.TestCase):
    def setUp(self) -> None:
        surface1 = CSurface()
        self.assertTrue(surface1 is not None)
        surface1.setTemperature(280)
        
        surface2 = CSurface()
        self.assertTrue(surface2 is not None)
        surface2.setTemperature(300)
        
        self.m_SolidLayer = CIGUSolidLayer(0.01, 2.5, surface1, surface2)
        self.assertTrue(self.m_SolidLayer is not None)
    
    def GetLayer(self) -> CIGUSolidLayer:
        return self.m_SolidLayer
    
    def test_Test1(self) -> None:
        aLayer = self.GetLayer()
        self.assertTrue(aLayer is not None)
        
        conductionHeatFlow = aLayer.getConvectionConductionFlow()
        
        self.assertAlmostEqual(5000, conductionHeatFlow, delta=1e-6)


if __name__ == '__main__':
    unittest.main()
