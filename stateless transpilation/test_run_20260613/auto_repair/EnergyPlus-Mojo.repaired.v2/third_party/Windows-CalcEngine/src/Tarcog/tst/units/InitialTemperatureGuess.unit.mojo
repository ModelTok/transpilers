from memory import Rc
from WCETarcog import Tarcog
from WCECommon import FenestrationCommon

class TestTemperatureInitialGuess:
    var m_TarcogSystem: Rc[Tarcog.ISO15099.CSingleSystem]? = None

    def SetUp(self):
        var airTemperature = 255.15   # Kelvins
        var tSky = airTemperature
        var airSpeed = 5.5   # meters per second
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert(Outdoor is not None)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert(Indoor is not None)
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var solidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert(solidLayer1 is not None)
        var solidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert(solidLayer2 is not None)
        var gapThickness = 0.012
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert(gap is not None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aTarIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aTarIGU.addLayers([solidLayer1, gap, solidLayer2])
        self.m_TarcogSystem = Rc(Tarcog.ISO15099.CSingleSystem(aTarIGU, Indoor, Outdoor))
        assert(self.m_TarcogSystem is not None)

    def getLayer1(self) -> Rc[Tarcog.ISO15099.CIGUSolidLayer]:
        return self.m_TarcogSystem.getSolidLayers()[0]

    def getLayer2(self) -> Rc[Tarcog.ISO15099.CIGUSolidLayer]:
        return self.m_TarcogSystem.getSolidLayers()[1]

def Test1():
    # SCOPED_TRACE("Begin Test: Initial temperature and IR guess")  # Comment preserved
    var testObj = TestTemperatureInitialGuess()
    testObj.SetUp()
    var side = FenestrationCommon.Side
    var layer = testObj.getLayer1()
    var temperature = layer.getTemperature(side.Front)
    var J = layer.J(side.Front)
    assert(abs(temperature - 256.282733081615) < 1e-6)
    assert(abs(J - 244.589307222020) < 1e-6)
    temperature = layer.getTemperature(side.Back)
    J = layer.J(side.Back)
    assert(abs(temperature - 262.756302643044) < 1e-6)
    assert(abs(J - 270.254322031419) < 1e-6)
    layer = testObj.getLayer2()
    temperature = layer.getTemperature(side.Front)
    J = layer.J(side.Front)
    assert(abs(temperature - 276.349099622422) < 1e-6)
    assert(abs(J - 330.668096601357) < 1e-6)
    temperature = layer.getTemperature(side.Back)
    J = layer.J(side.Back)
    assert(abs(temperature - 282.822669183851) < 1e-6)
    assert(abs(J - 362.757956247504) < 1e-6)