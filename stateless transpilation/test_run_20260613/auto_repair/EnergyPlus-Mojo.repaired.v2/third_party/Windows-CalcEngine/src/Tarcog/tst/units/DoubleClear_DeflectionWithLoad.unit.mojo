from WCETarcog import Tarcog
from WCECommon import *
from stdlib import shared, collections

class TestDoubleClearDeflectionWithLoad:
    var m_TarcogSystem: shared.SharedPtr[Tarcog.ISO15099.CSystem] = shared.SharedPtr[Tarcog.ISO15099.CSystem]()

    def SetUp(inout self):
        let airTemperature: Float64 = 300.0      # Kelvins
        let airSpeed: Float64 = 5.5              # meters per second
        let tSky: Float64 = 255.15               # Kelvins
        let solarRadiation: Float64 = 0.0
        let outsidePressure: Float64 = 102000.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified, outsidePressure)
        assert(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature: Float64 = 250.0
        let roomPressure: Float64 = 100000.0
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature, roomPressure)
        assert(Indoor != None)
        let solidLayerThickness: Float64 = 0.003048 # [m]
        let solidLayerConductance: Float64 = 1.0    # [W/m2K]
        var aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer1.setSolarAbsorptance(0.099839858711, solarRadiation)
        var aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer2.setSolarAbsorptance(0.076627746224, solarRadiation)
        let gapThickness1: Float64 = 0.006
        var gapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness1)
        assert(gapLayer1 != None)
        let windowWidth: Float64 = 1.0
        let windowHeight: Float64 = 5.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aSolidLayer1, gapLayer1, aSolidLayer2])
        self.m_TarcogSystem = shared.SharedPtr[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        self.m_TarcogSystem.setAppliedLoad([2000.0, 1000.0])
        self.m_TarcogSystem.setDeflectionProperties(320.0, 102000.0)
        assert(self.m_TarcogSystem != None)

    def GetSystem(self) -> shared.SharedPtr[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def Test1():
    # SCOPED_TRACE("Begin Test: Double Clear - Deflection case with loads")
    var fixture = TestDoubleClearDeflectionWithLoad()
    fixture.SetUp()
    let aSystem = fixture.GetSystem()
    assert(aSystem != None)
    let aRun = Tarcog.ISO15099.System.Uvalue
    let Temperature = aSystem.getTemperatures(aRun)
    var correctTemperature = collections.List[Float64]([292.076937, 291.609964, 272.797101, 272.330129])
    assert(correctTemperature.size == Temperature.size)
    for i in range(correctTemperature.size):
        assert(abs(correctTemperature[i] - Temperature[i]) < 1e-5)

    var correctDeflection = collections.List[Float64]([-55.488195e-3, -54.644421e-3])
    let deflection = aSystem.getMaxDeflections(Tarcog.ISO15099.System.Uvalue)
    for i in range(correctDeflection.size):
        assert(abs(correctDeflection[i] - deflection[i]) < 1e-8)