from WCETarcog import CSystem, Environments, Layers, CIGU, System, SkyModel, BoundaryConditionsCoeffModel, AirHorizontalDirection
from WCECommon import *  # noqa: F403 – import all common types

class TestDoubleClearLeeward:
    private var m_TarcogSystem: CSystem?

    def SetUp(self) raises:
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var pressure = 101325.0
        var airDirection = AirHorizontalDirection.Leeward
        var tSky = 255.15   # Kelvins
        var solarRadiation = 789.0
        var Outdoor = Environments.outdoor(
            airTemperature,
            airSpeed,
            solarRadiation,
            tSky,
            SkyModel.AllSpecified,
            pressure,
            airDirection
        )
        assert Outdoor is not None
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        assert Indoor is not None
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Layers.solid(solidLayerThickness, solidLayerConductance)
        layer1.setSolarAbsorptance(0.166707709432, solarRadiation)
        var layer2 = Layers.solid(solidLayerThickness, solidLayerConductance)
        layer2.setSolarAbsorptance(0.112737670541, solarRadiation)
        var gapThickness = 0.012
        var gap = Layers.gap(gapThickness)
        assert gap is not None
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap, layer2])
        self.m_TarcogSystem = CSystem(aIGU, Indoor, Outdoor)
        assert self.m_TarcogSystem is not None

    def GetSystem(self) -> CSystem:
        return self.m_TarcogSystem

def Test1() raises:
    print("Begin Test: Double Clear - Surface temperatures")
    var aSystem = TestDoubleClearLeeward()
    aSystem.SetUp()
    var sys = aSystem.GetSystem()
    assert sys is not None
    var aRun = System.Uvalue
    var Temperature = sys.getTemperatures(aRun)
    var correctTemperature = List[Float64](258.756688, 259.359226, 279.178510, 279.781048)
    assert len(correctTemperature) == len(Temperature)
    for i in range(len(correctTemperature)):
        assert abs(correctTemperature[i] - Temperature[i]) < 1e-5
    var Radiosity = sys.getRadiosities(aRun)
    var correctRadiosity = List[Float64](251.950834, 268.667346, 332.299338, 359.731700)
    assert len(correctRadiosity) == len(Radiosity)
    for i in range(len(correctRadiosity)):
        assert abs(correctRadiosity[i] - Radiosity[i]) < 1e-5
    var numOfIter = sys.getNumberOfIterations(aRun)
    assert 20 == int(numOfIter)
    aRun = System.SHGC
    Temperature = sys.getTemperatures(aRun)
    correctTemperature = List[Float64](264.022835, 265.134421, 287.947300, 288.428857)
    assert len(correctTemperature) == len(Temperature)
    for i in range(len(correctTemperature)):
        assert abs(correctTemperature[i] - Temperature[i]) < 1e-5
    Radiosity = sys.getRadiosities(aRun)
    correctRadiosity = List[Float64](269.869356, 295.289318, 374.655901, 397.518724)
    assert len(correctRadiosity) == len(Radiosity)
    for i in range(len(correctRadiosity)):
        assert abs(correctRadiosity[i] - Radiosity[i]) < 1e-5
    numOfIter = sys.getNumberOfIterations(aRun)
    assert 21 == int(numOfIter)
    var Uvalue = sys.getUValue()
    assert abs(Uvalue - 2.703359) < 1e-5
    var SHGC = sys.getSHGC(0.606897)
    assert abs(SHGC - 0.690096) < 1e-5

def main() raises:
    Test1()
<<<FILE>>>