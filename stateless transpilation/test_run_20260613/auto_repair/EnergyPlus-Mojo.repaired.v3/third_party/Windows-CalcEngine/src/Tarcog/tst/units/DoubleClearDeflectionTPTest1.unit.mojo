from memory import shared_ptr, make_shared
from stdexcept import *
from gtest.gtest.h import *
from WCETarcog.hpp import *
from WCECommon.hpp import *

class DoubleClearDeflectionTPTest1(testing.Test):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]

    def SetUp(self) raises:
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
        var aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1, solidLayerConductance)
        var youngsModulus = 8.1e10
        aSolidLayer1 = Tarcog.ISO15099.Layers.updateMaterialData(aSolidLayer1, youngsModulus)
        var aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance)
        var gapThickness = 0.0127
        var m_GapLayer = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert_true(m_GapLayer != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aSolidLayer1, m_GapLayer, aSolidLayer2])
        var Tini = 303.15
        var Pini = 101325.0
        aIGU.setDeflectionProperties(Tini, Pini)
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSingleSystem](aIGU, Indoor, Outdoor)
        assert_true(self.m_TarcogSystem != None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

@testing.Test.fixture
def Test1(aSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]):
    var _unused = testing.Test.scoped_trace("Begin Test: Double Clear - Calculated Deflection")
    # aSystem obtained from fixture
    assert_true(aSystem != None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = [258.799454, 259.124627, 279.009121, 279.618821]
    assert_eq(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        expect_near(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = [252.092017, 267.753052, 331.451548, 359.055470]
    assert_eq(len(correctRadiosity), len(Radiosity))
    for i in range(len(correctRadiosity)):
        expect_near(correctRadiosity[i], Radiosity[i], 1e-5)
    var MaxDeflection = aSystem.getMaxDeflections()
    var correctMaxDeflection = [-2.285903e-3, 0.483756e-3]
    assert_eq(len(correctMaxDeflection), len(MaxDeflection))
    for i in range(len(correctMaxDeflection)):
        expect_near(correctMaxDeflection[i], MaxDeflection[i], 1e-8)
    var MeanDeflection = aSystem.getMeanDeflections()
    var correctMeanDeflection = [-0.957624e-3, 0.202658e-3]
    assert_eq(len(correctMeanDeflection), len(MeanDeflection))
    for i in range(len(correctMaxDeflection)):
        expect_near(correctMeanDeflection[i], MeanDeflection[i], 1e-8)
    var numOfIter = aSystem.getNumberOfIterations()
    expect_eq(20, numOfIter)

# Register the test
testing.Test.register_test("DoubleClearDeflectionTPTest1", "Test1", Test1)