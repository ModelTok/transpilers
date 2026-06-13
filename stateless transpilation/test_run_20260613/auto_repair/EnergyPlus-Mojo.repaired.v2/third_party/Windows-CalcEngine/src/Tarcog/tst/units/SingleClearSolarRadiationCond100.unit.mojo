from testing import assert_true, assert_equal, assert_approx_equal
from builtin import List, Float64
from WCETarcog import Tarcog
from WCECommon import Tarcog as TarcogCommon  # Assuming WCECommon also uses Tarcog namespace

struct TestSingleClearSolarCond001:
    var m_TarcogSystem: owned Tarcog.ISO15099.CSingleSystem

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 1000.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert_true(Outdoor is not None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var aIndoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(aIndoor is not None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var solarAbsorptance = 0.094189159572
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer.setSolarAbsorptance(solarAbsorptance, solarRadiation)
        assert_true(aSolidLayer is not None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = owned new Tarcog.ISO15099.CSingleSystem(aIGU, aIndoor, Outdoor)
        assert_true(self.m_TarcogSystem is not None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return self.m_TarcogSystem[]

def TestTempAndRad():
    var fixture = TestSingleClearSolarCond001()
    fixture.SetUp()
    # SCOPED_TRACE("Begin Test: Single Clear (Solar Radiation) - Temperatures and Radiosity.")
    var aSystem = fixture.GetSystem()
    assert_true(aSystem is not None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](299.627742, 299.627975)
    assert_equal(correctTemperature.size(), Temperature.size())
    for i in range(correctTemperature.size()):
        assert_approx_equal(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](444.699763, 451.769813)
    assert_equal(correctRadiosity.size(), Radiosity.size())
    for i in range(correctRadiosity.size()):
        assert_approx_equal(correctRadiosity[i], Radiosity[i], 1e-5)

def TestIndoor():
    var fixture = TestSingleClearSolarCond001()
    fixture.SetUp()
    # SCOPED_TRACE("Begin Test: Single Clear (Solar Radiation) - Indoor heat flow.")
    var aSystem = fixture.GetSystem()
    var convectiveHF = aSystem.getConvectiveHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    var radiativeHF = aSystem.getRadiationHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    var totalHF = aSystem.getHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    assert_approx_equal(-12.135453, convectiveHF, 1e-5)
    assert_approx_equal(-27.311063, radiativeHF, 1e-5)
    assert_approx_equal(-39.446516, totalHF, 1e-5)