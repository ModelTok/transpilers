from .. import Tarcog

class TestGapLayerStandardPressure:
    var m_GapLayer: Pointer[Tarcog.ISO15099.CIGUGapLayer]
    var m_IGU: Tarcog.ISO15099.CIGU

    def SetUp(self):
        var surface1 = Pointer[Tarcog.ISO15099.CSurface](new Tarcog.ISO15099.CSurface())
        assert surface1 != None
        var surface2 = Pointer[Tarcog.ISO15099.CSurface](new Tarcog.ISO15099.CSurface())
        assert surface2 != None
        var surface3 = Pointer[Tarcog.ISO15099.CSurface](new Tarcog.ISO15099.CSurface())
        assert surface3 != None
        var surface4 = Pointer[Tarcog.ISO15099.CSurface](new Tarcog.ISO15099.CSurface())
        assert surface4 != None
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var gapSurface1Temperature = 262.756296539528
        var gapSurface2Temperature = 276.349093518906
        surface2[].setTemperature(gapSurface1Temperature)
        surface3[].setTemperature(gapSurface2Temperature)
        var solidLayer1 = Pointer[Tarcog.ISO15099.CIGUSolidLayer](
            new Tarcog.ISO15099.CIGUSolidLayer(solidLayerThickness, solidLayerConductance, surface1, surface2))
        assert solidLayer1 != None
        var solidLayer2 = Pointer[Tarcog.ISO15099.CIGUSolidLayer](
            new Tarcog.ISO15099.CIGUSolidLayer(solidLayerThickness, solidLayerConductance, surface3, surface4))
        assert solidLayer2 != None
        var gapThickness = 0.012
        self.m_GapLayer = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert self.m_GapLayer != None
        var windowWidth = 1.0
        var windowHeight = 1.0
        self.m_IGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        self.m_IGU.addLayers([solidLayer1, self.m_GapLayer, solidLayer2])

    def GetLayer(self) -> Pointer[Tarcog.ISO15099.CIGUGapLayer]:
        return self.m_GapLayer

def main():
    var test = TestGapLayerStandardPressure()
    test.SetUp()
    print("Begin Test: Test Gap Layer - Convection heat flow [Pa = 101325 Pa]")
    var aLayer = test.GetLayer()
    assert aLayer != None
    var convectionHeatFlow = aLayer[].getConvectionConductionFlow()
    var expected = 27.673789062350764
    var diff = convectionHeatFlow - expected
    if diff < 0:
        diff = -diff
    assert diff < 1e-6, "Convection heat flow mismatch"
    print("Test passed")