from memory import *
from stdexcept import *
from ......WCETarcog import Tarcog
from ......WCECommon import *
// Note: Mojo does not have gtest, but we simulate the test structure.

struct DoubleIGU_With_TIR_and_Openness:
    var m_TarcogSystem: Tarcog.ISO15099.CSingleSystem?

    def __init__(inout self):
        self.m_TarcogSystem = None

    def SetUp(inout self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert Outdoor is not None
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor is not None
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.shading(solidLayerThickness, solidLayerConductance)
        assert layer1 is not None
        var shadeLayerThickness = 0.001
        var shadeLayerConductance = 0.15
        var emissivity = 0.796259999275
        var tir = 0.10916
        var dtop = 0.0
        var dbot = 0.0
        var dleft = 0.0
        var dright = 0.0
        var Afront = 0.049855
        let openness = EffectiveLayers.ShadeOpenness(Afront, dleft, dright, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        let effectiveLayer = EffectiveLayers.EffectiveLayerBSDF(
            windowWidth, windowHeight, shadeLayerThickness, openness)
        let effOpenness = EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
        var layer2 = Tarcog.ISO15099.Layers.shading(shadeLayerThickness,
                                                    shadeLayerConductance,
                                                    effOpenness,
                                                    emissivity,
                                                    tir,
                                                    emissivity,
                                                    tir)
        assert layer2 is not None
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert gap1 is not None
        let aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers({layer1, gap1, layer2})
        self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
        assert self.m_TarcogSystem is not None
        self.m_TarcogSystem.solve()

    def getSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return self.m_TarcogSystem.value()

def Test1():
    print("Begin Test: Outdoor Shade - Air")
    var fixture = DoubleIGU_With_TIR_and_Openness()
    fixture.SetUp()
    let aSystem = fixture.getSystem()
    let temperature = aSystem.getTemperatures()
    let radiosity = aSystem.getRadiosities()
    let correctTemp = [259.350462, 259.724865, 279.767733, 280.443187]
    let correctJ = [253.917317, 272.505694, 348.677765, 349.142912]
    assert len(correctTemp) == len(temperature)
    assert len(correctJ) == len(radiosity)
    for i in range(len(temperature)):
        assert abs(correctTemp[i] - temperature[i]) < 1e-6
        assert abs(correctJ[i] - radiosity[i]) < 1e-6
    let numOfIter = aSystem.getNumberOfIterations()
    assert 20 == int(numOfIter)
    let ventilatedFlowOutdoor = aSystem.getVentilationFlow(Tarcog.ISO15099.Environment.Outdoor)
    assert abs(0.0 - ventilatedFlowOutdoor) < 1e-6
    let ventilatedFlowIndoor = aSystem.getVentilationFlow(Tarcog.ISO15099.Environment.Indoor)
    assert abs(9.152949 - ventilatedFlowIndoor) < 1e-6
    let uValue = aSystem.getUValue()
    assert abs(3.149632 - uValue) < 1e-6