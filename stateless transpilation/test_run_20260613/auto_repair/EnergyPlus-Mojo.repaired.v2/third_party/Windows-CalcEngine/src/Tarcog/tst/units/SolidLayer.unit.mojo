from memory import unique_ptr, make_shared
from testing import Test, TestFixture, Expect, Assert
from WCETarcog import Tarcog

class TestSolidLayer(TestFixture):
    private:
        var m_SolidLayer: unique_ptr[Tarcog.ISO15099.CIGUSolidLayer]

    def SetUp(self) raises:
        var surface1 = make_shared[Tarcog.ISO15099.CSurface]()
        Assert.True(surface1 != None)
        surface1.setTemperature(280)
        var surface2 = make_shared[Tarcog.ISO15099.CSurface]()
        Assert.True(surface2 != None)
        surface2.setTemperature(300)
        self.m_SolidLayer = unique_ptr[Tarcog.ISO15099.CIGUSolidLayer](
            Tarcog.ISO15099.CIGUSolidLayer(0.01, 2.5, surface1, surface2))
        Assert.True(self.m_SolidLayer != None)

    def GetLayer(self) -> Tarcog.ISO15099.CIGUSolidLayer:
        return self.m_SolidLayer.get()

def Test1():
    TestSolidLayer.Test1()

def TestSolidLayer_Test1():
    SCOPED_TRACE("Begin Test: Test Solid Layer - Conduction heat flow")
    var aLayer = TestSolidLayer().GetLayer()
    Assert.True(aLayer != None)
    var conductionHeatFlow = aLayer.getConvectionConductionFlow()
    Expect.NEAR(5000, conductionHeatFlow, 1e-6)