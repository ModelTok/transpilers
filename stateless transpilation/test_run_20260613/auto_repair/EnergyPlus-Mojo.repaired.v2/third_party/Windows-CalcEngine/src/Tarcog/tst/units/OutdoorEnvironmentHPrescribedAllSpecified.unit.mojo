from memory import Pointer
from testing import Test, Expect
from WCETarcog import (
    Tarcog,
    CEnvironment,
    CSingleSystem,
    CIGU,
    Environments,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel,
)

@value
class TestOutdoorEnvironmentHPrescribedAllSpecified(Test):
    var Outdoor: Pointer[CEnvironment]
    var m_TarcogSystem: Pointer[CSingleSystem]

    def SetUp(self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        var hout = 20.0
        self.Outdoor = Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        Expect(self.Outdoor.is_not_null())
        self.Outdoor[].setHCoeffModel(BoundaryConditionsCoeffModel.HPrescribed, hout)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        Expect(Indoor.is_not_null())
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        Expect(aSolidLayer.is_not_null())
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = Pointer[CEnvironment].make(CSingleSystem(aIGU, Indoor, self.Outdoor))
        self.m_TarcogSystem[].solve()
        Expect(self.m_TarcogSystem.is_not_null())

    def GetOutdoors(self) -> Pointer[CEnvironment]:
        return self.Outdoor

def TestOutdoorEnvironmentHPrescribedAllSpecified_HPrescribed_AllSpecified():
    SCOPED_TRACE("Begin Test: Outdoors -> H model = Prescribed; Sky Model = All Specified")
    var aOutdoor = TestOutdoorEnvironmentHPrescribedAllSpecified().GetOutdoors()
    Expect(aOutdoor.is_not_null())
    var radiosity = aOutdoor[].getEnvironmentIR()
    Expect.AlmostEqual(459.2457, radiosity, 1e-5)
    var hc = aOutdoor[].getHc()
    Expect.AlmostEqual(14.895502, hc, 1e-5)
    var outIR = aOutdoor[].getRadiationFlow()
    Expect.AlmostEqual(-7.777658, outIR, 1e-5)
    var outConvection = aOutdoor[].getConvectionConductionFlow()
    Expect.AlmostEqual(-22.696083, outConvection, 1e-5)
    var totalHeatFlow = aOutdoor[].getHeatFlow()
    Expect.AlmostEqual(-30.473740, totalHeatFlow, 1e-5)