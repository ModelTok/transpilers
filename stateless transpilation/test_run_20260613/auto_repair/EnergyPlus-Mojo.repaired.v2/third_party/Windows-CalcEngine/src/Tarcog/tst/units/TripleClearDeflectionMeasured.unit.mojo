from memory import shared_ptr, make_shared
from WCETarcog import Tarcog
from WCECommon import *
from testing import *

class TripleClearDeflectionMeasured(Test):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]

    def SetUp(self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert_true(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(Indoor != None)
        var solidLayerThickness1 = 0.003048   # [m]
        var solidLayerThickness2 = 0.005715
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1, solidLayerConductance)
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance)
        var layer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1, solidLayerConductance)
        var gapThickness = 0.0127
        var gapPressure = 101325.0
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness, gapPressure)
        assert_true(gap1 != None)
        var gap2 = Tarcog.ISO15099.Layers.gap(gapThickness, gapPressure)
        assert_true(gap2 != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap1, layer2, gap2, layer3])
        var measuredGapsWidths = List[Float64](0.0135, 0.013)
        aIGU.setDeflectionProperties(measuredGapsWidths)
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSingleSystem](aIGU, Indoor, Outdoor)
        assert_true(self.m_TarcogSystem != None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

def Test1():
    scoped_trace("Begin Test: Triple Clear - Measured Deflection.")
    var aSystem = TripleClearDeflectionMeasured().GetSystem()
    assert_true(aSystem != None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](257.493976, 257.702652, 271.535517, 271.926785, 284.395405, 284.604082)
    assert_equal(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        expect_near(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](247.813715, 258.078374, 300.200818, 318.403140, 362.495875, 380.380188)
    assert_equal(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        expect_near(correctRadiosity[i], Radiosity[i], 1e-5)
    var MaxDeflection = aSystem.getMaxDeflections()
    var correctMaxDeflection = List[Float64](0.00074180, -5.820e-05, -0.0003582)
    assert_equal(correctMaxDeflection.size, MaxDeflection.size)
    for i in range(correctMaxDeflection.size):
        expect_near(correctMaxDeflection[i], MaxDeflection[i], 1e-7)
    var MeanDeflection = aSystem.getMeanDeflections()
    var correctMeanDeflection = List[Float64](0.00031076, -2.437e-05, -0.0001501)
    assert_equal(correctMeanDeflection.size, MeanDeflection.size)
    for i in range(correctMaxDeflection.size):
        expect_near(correctMeanDeflection[i], MeanDeflection[i], 1e-7)
    var numOfIter = aSystem.getNumberOfIterations()
    expect_equal(20, numOfIter)