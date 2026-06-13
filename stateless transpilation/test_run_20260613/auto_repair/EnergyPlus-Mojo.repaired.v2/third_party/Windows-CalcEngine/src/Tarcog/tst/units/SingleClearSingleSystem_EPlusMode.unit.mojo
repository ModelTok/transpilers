from memory import unique_ptr
from testing import Test, Expect
from WCETarcog import (
    Tarcog,
    ISO15099,
    CSingleSystem,
    CIGU,
    Environments,
    Layers,
    AirHorizontalDirection,
    SkyModel,
    BoundaryConditionsCoeffModel,
)
from WCECommon import *

@value
class TestSingleClearSingleSystem_EPlusMode(Test):
    var m_TarcogSystem: unique_ptr[CSingleSystem]

    def SetUp() raises:
        var airTemperature = 252.0484   # Kelvins
        var pressure = 99100.0          # Pascals
        var airSpeed = 4.2967           # meters per second
        var tSky = 231.2005             # Kelvins
        var direction = AirHorizontalDirection.Windward
        var solarRadiation = 0.0
        var fclr = 1.0
        var Outdoor = Environments.outdoor(
            airTemperature,
            airSpeed,
            solarRadiation,
            tSky,
            SkyModel.AllSpecified,
            pressure,
            direction,
            fclr,
        )
        Expect(Outdoor.is_not_none())
        var hcout = 21.8733
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.HcPrescribed, hcout)
        var IR = 205.1969
        Outdoor.setEnvironmentIR(IR)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature, pressure)
        Expect(Indoor.is_not_none())
        var hcin = 2.6262
        Indoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH, hcin)
        IR = 389.8318
        Indoor.setEnvironmentIR(IR)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        Expect(aSolidLayer.is_not_none())
        var windowWidth = 2.7130375
        var windowHeight = 3.02895
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = unique_ptr[CSingleSystem](
            CSingleSystem(aIGU, Indoor, Outdoor)
        )
        Expect(self.m_TarcogSystem.is_not_none())
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> CSingleSystem:
        return self.m_TarcogSystem.get()

def Test1():
    TestSingleClearSingleSystem_EPlusMode.SetUp()
    var aSystem = TestSingleClearSingleSystem_EPlusMode.GetSystem()
    Expect(aSystem.is_not_none())
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](259.293476, 259.907311)
    Expect(correctTemperature.size() == Temperature.size())
    for i in range(correctTemperature.size()):
        Expect(  # noqa: F821
            (correctTemperature[i] - Temperature[i]).abs() <= 1e-5
        )
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](248.112516, 279.699920)
    Expect(correctRadiosity.size() == Radiosity.size())
    for i in range(correctRadiosity.size()):
        Expect(  # noqa: F821
            (correctRadiosity[i] - Radiosity[i]).abs() <= 1e-5
        )
    var isToleranceAchieved = aSystem.isToleranceAchieved()
    Expect(isToleranceAchieved == True)
    var solutionTolerance = aSystem.solutionTolarance()
    Expect((9.264811e-07 - solutionTolerance).abs() <= 1e-10)