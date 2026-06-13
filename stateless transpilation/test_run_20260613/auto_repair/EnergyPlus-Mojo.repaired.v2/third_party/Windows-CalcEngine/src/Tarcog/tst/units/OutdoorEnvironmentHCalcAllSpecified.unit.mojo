from ......WCETarcog import *

def expect_near(actual: Float64, expected: Float64, tol: Float64):
    if abs(actual - expected) > tol:
        print("FAIL: expected", expected, "but got", actual, "tolerance", tol)
        abort()

def expect_true(condition: Bool, msg: String = ""):
    if not condition:
        print("FAIL:", msg)
        abort()

struct TestOutdoorEnvironmentHCalcAllSpecified:
    var Outdoor: Tarcog.ISO15099.CEnvironment? = None
    var m_TarcogSystem: Tarcog.ISO15099.CSingleSystem? = None

    def __init__(inout self):

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        self.Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        expect_true(self.Outdoor is not None, "Outdoor is null")
        self.Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        expect_true(Indoor is not None, "Indoor is null")
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer =
          Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        expect_true(aSolidLayer is not None, "aSolidLayer is null")
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, self.Outdoor)
        self.m_TarcogSystem.solve()
        expect_true(self.m_TarcogSystem is not None, "m_TarcogSystem is null")

    def GetOutdoors(self) -> Tarcog.ISO15099.CEnvironment:
        return self.Outdoor

    def test_CalculateH_AllSpecified(self):
        print("Begin Test: Outdoors -> H model = Calculate; Sky Model = All Specified")
        var aOutdoor = self.GetOutdoors()
        expect_true(aOutdoor is not None, "aOutdoor is null")
        var radiosity = aOutdoor.getEnvironmentIR()
        expect_near(radiosity, 380.278401885, 1e-6)
        var hc = aOutdoor.getHc()
        expect_near(hc, 26.0, 1e-6)
        var outIR = aOutdoor.getRadiationFlow()
        expect_near(outIR, 52.1067777, 1e-6)
        var outConvection = aOutdoor.getConvectionConductionFlow()
        expect_near(outConvection, -72.9257342, 1e-6)
        var totalHeatFlow = aOutdoor.getHeatFlow()
        expect_near(totalHeatFlow, -20.81895645, 1e-6)

def main():
    var test = TestOutdoorEnvironmentHCalcAllSpecified()
    test.SetUp()
    test.test_CalculateH_AllSpecified()
<<<FILE>>>