from memory import Pointer
from testing import assert_approx_eq
from ......WCETarcog import Tarcog

struct TestOutdoorEnvironmentHPrescribedSwingbank:
    var Outdoor: Pointer[Tarcog.ISO15099.CEnvironment]
    var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSingleSystem]

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        var hout = 20.0
        self.Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.Swinbank)
        assert self.Outdoor != None
        self.Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.HPrescribed, hout)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor != None
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert aSolidLayer != None
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem](Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, self.Outdoor))
        self.m_TarcogSystem.solve()
        assert self.m_TarcogSystem != None

    def GetOutdoors(self) -> Pointer[Tarcog.ISO15099.CEnvironment]:
        return self.Outdoor

def HPrescribed_Swinbank():
    # SCOPED_TRACE("Begin Test: Outdoors -> H model = Prescribed; Sky Model = Swinbank")
    var fixture = TestOutdoorEnvironmentHPrescribedSwingbank()
    fixture.SetUp()
    var aOutdoor = fixture.GetOutdoors()
    assert aOutdoor != None
    var radiosity = aOutdoor.getEnvironmentIR()
    assert_approx_eq(459.2457, radiosity, 1e-5)
    var hc = aOutdoor.getHc()
    assert_approx_eq(14.895502, hc, 1e-5)
    var outIR = aOutdoor.getRadiationFlow()
    assert_approx_eq(-7.777658, outIR, 1e-5)
    var outConvection = aOutdoor.getConvectionConductionFlow()
    assert_approx_eq(-22.696083, outConvection, 1e-5)
    var totalHeatFlow = aOutdoor.getHeatFlow()
    assert_approx_eq(-30.473740, totalHeatFlow, 1e-5)

HPrescribed_Swinbank()