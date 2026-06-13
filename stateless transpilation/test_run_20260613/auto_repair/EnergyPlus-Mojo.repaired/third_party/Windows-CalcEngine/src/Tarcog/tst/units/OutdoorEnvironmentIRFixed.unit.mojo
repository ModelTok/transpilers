from memory import owned
from WCETarcog import CEnvironment, CSingleSystem, CIGU, Environments, Layers, SkyModel

struct TestOutdoorEnvironmentIRFixed:
    private var Outdoor: owned[CEnvironment]
    private var m_TarcogSystem: owned[CSingleSystem]

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var tSky = airTemperature
        var airSpeed = 5.5   # meters per second
        var solarRadiation = 0.0
        var IRRadiation = 370.0   # [ W/m2 ]
        self.Outdoor = Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        assert self.Outdoor != None
        self.Outdoor.setEnvironmentIR(IRRadiation)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        assert Indoor != None
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        assert aSolidLayer != None
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = CSingleSystem(aIGU, Indoor, self.Outdoor)
        assert self.m_TarcogSystem != None

    def GetOutdoors(self) -> owned[CEnvironment]:
        return self.Outdoor

def test_CalculateIRFixed():
    var testObj = TestOutdoorEnvironmentIRFixed()
    testObj.SetUp()
    # SCOPED_TRACE("Begin Test: Outdoors -> Infrared radiation fixed (user input).")
    var aOutdoor = testObj.GetOutdoors()
    assert aOutdoor != None
    var radiosity = aOutdoor.getEnvironmentIR()
    assert abs(radiosity - 370) < 1e-6
    var hc = aOutdoor.getHc()
    assert abs(hc - 26) < 1e-6

def main():
    test_CalculateIRFixed()