from memory import Pointer
from testing import *
from WCETarcog import Tarcog  # Assumes module path with same name

struct TestOutdoorEnvironmentHCalcSwingbank:
    var Outdoor: Pointer[Tarcog.ISO15099.CEnvironment]
    var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSingleSystem]

    def __init__(inout self):
        self.Outdoor = Pointer[Tarcog.ISO15099.CEnvironment]()
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem]()

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        self.Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.Swinbank)
        assert (self.Outdoor != None)
        self.Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert (Indoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert (aSolidLayer != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem](Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, self.Outdoor))
        self.m_TarcogSystem.solve()
        assert (self.m_TarcogSystem != None)

    def GetOutdoors(self) -> Pointer[Tarcog.ISO15099.CEnvironment]:
        return self.Outdoor

def test_TestOutdoorEnvironmentHCalcSwingbank_CalculateH_Swinbank():
    var testObj = TestOutdoorEnvironmentHCalcSwingbank()
    testObj.SetUp()
    # SCOPED_TRACE("Begin Test: Outdoors -> H model = Calculate; Sky Model = Swinbank")
    var aOutdoor = testObj.GetOutdoors()
    assert (aOutdoor != None)
    var radiosity = aOutdoor.getEnvironmentIR()
    expect_near(423.17235, radiosity, 1e-6)
    var hc = aOutdoor.getHc()
    expect_near(26, hc, 1e-6)
    var outIR = aOutdoor.getRadiationFlow()
    expect_near(20.7751423, outIR, 1e-6)
    var outConvection = aOutdoor.getConvectionConductionFlow()
    expect_near(-48.607583, outConvection, 1e-6)
    var totalHeatFlow = aOutdoor.getHeatFlow()
    expect_near(-27.83244071, totalHeatFlow, 1e-6)

# Run the test
def main():
    test_TestOutdoorEnvironmentHCalcSwingbank_CalculateH_Swinbank()