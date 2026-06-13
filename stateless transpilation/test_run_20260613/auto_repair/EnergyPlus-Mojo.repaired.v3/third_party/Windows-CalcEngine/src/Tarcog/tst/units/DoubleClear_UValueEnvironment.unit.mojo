from WCETarcog import Tarcog
from WCECommon import *

struct TestDoubleClearUValueEnvironment:
    var m_TarcogSystem: Rc[Tarcog.ISO15099.CSystem]

    def SetUp(self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 789.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert(Outdoor is not None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert(Indoor is not None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0      # [W/m2K]
        var aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer1.setSolarAbsorptance(0.096489921212, solarRadiation)
        var aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer2.setSolarAbsorptance(0.072256758809, solarRadiation)
        var gapThickness = 0.0127
        var gapLayer = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert(gapLayer is not None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aSolidLayer1, gapLayer, aSolidLayer2])
        self.m_TarcogSystem = Rc::new(Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        assert(self.m_TarcogSystem is not None)

    def GetSystem(self) -> Rc[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def test_Test1():
    var testObj = TestDoubleClearUValueEnvironment()
    testObj.SetUp()
    # SCOPED_TRACE("Begin Test: Double Clear - Surface temperatures")
    var aSystem = testObj.GetSystem()
    assert(aSystem is not None)
    var aRun = Tarcog.ISO15099.System.Uvalue
    var Temperature = aSystem.getTemperatures(aRun)
    var correctTemperature = List[Float64](258.791640, 259.116115, 279.323983, 279.648458)
    assert(len(correctTemperature) == len(Temperature))
    for i in range(len(correctTemperature)):
        assert(abs(correctTemperature[i] - Temperature[i]) < 1e-5)
    var SolidLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(aRun)
    var correctSolidConductivities = List[Float64](1, 1)
    assert(len(SolidLayerConductivities) == len(correctSolidConductivities))
    for i in range(len(SolidLayerConductivities)):
        assert(abs(correctSolidConductivities[i] - SolidLayerConductivities[i]) < 1e-6)
    var GapLayerConductivities = aSystem.getGapEffectiveLayerConductivities(aRun)
    var correctGapConductivities = List[Float64](0.066904)
    assert(len(GapLayerConductivities) == len(correctGapConductivities))
    for i in range(len(GapLayerConductivities)):
        assert(abs(correctGapConductivities[i] - GapLayerConductivities[i]) < 1e-6)
    var Radiosity = aSystem.getRadiosities(aRun)
    var correctRadiosity = List[Float64](252.066216, 267.938384, 332.786197, 359.178924)
    assert(len(correctRadiosity) == len(Radiosity))
    for i in range(len(correctRadiosity)):
        assert(abs(correctRadiosity[i] - Radiosity[i]) < 1e-5)
    var effectiveSystemConductivity = aSystem.getEffectiveSystemConductivity(aRun)
    assert(abs(0.095937 - effectiveSystemConductivity) < 1e-6)
    var thickness = aSystem.thickness(aRun)
    assert(abs(0.018796 - thickness) < 1e-6)
    var numOfIter = aSystem.getNumberOfIterations(aRun)
    assert(20 == Int(numOfIter))
    aRun = Tarcog.ISO15099.System.SHGC
    Temperature = aSystem.getTemperatures(aRun)
    correctTemperature = List[Float64](261.920088, 262.408524, 284.752662, 285.038190)
    assert(len(correctTemperature) == len(Temperature))
    for i in range(len(correctTemperature)):
        assert(abs(correctTemperature[i] - Temperature[i]) < 1e-5)
    SolidLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(aRun)
    correctSolidConductivities = List[Float64](1, 1)
    assert(len(SolidLayerConductivities) == len(correctSolidConductivities))
    for i in range(len(SolidLayerConductivities)):
        assert(abs(correctSolidConductivities[i] - SolidLayerConductivities[i]) < 1e-6)
    GapLayerConductivities = aSystem.getGapEffectiveLayerConductivities(aRun)
    correctGapConductivities = List[Float64](0.069446)
    assert(len(GapLayerConductivities) == len(correctGapConductivities))
    for i in range(len(GapLayerConductivities)):
        assert(abs(correctGapConductivities[i] - GapLayerConductivities[i]) < 1e-6)
    Radiosity = aSystem.getRadiosities(aRun)
    correctRadiosity = List[Float64](262.584530, 283.162254, 358.425764, 382.290985)
    assert(len(correctRadiosity) == len(Radiosity))
    for i in range(len(correctRadiosity)):
        assert(abs(correctRadiosity[i] - Radiosity[i]) < 1e-5)
    effectiveSystemConductivity = aSystem.getEffectiveSystemConductivity(aRun)
    assert(abs(0.052988 - effectiveSystemConductivity) < 1e-6)
    thickness = aSystem.thickness(aRun)
    assert(abs(0.018796 - thickness) < 1e-6)
    numOfIter = aSystem.getNumberOfIterations(aRun)
    assert(20 == Int(numOfIter))
    var Uvalue = aSystem.getUValue()
    assert(abs(Uvalue - 2.729619) < 1e-5)
    var SHGC = aSystem.getSHGC(0.703296)
    assert(abs(SHGC - 0.755619) < 1e-5)
    var relativeHeatGain = aSystem.relativeHeatGain(0.703296)
    assert(abs(relativeHeatGain - 569.190777) < 1e-5)