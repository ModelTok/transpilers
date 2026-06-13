from memory import Pointer
from testing import assert_equal, assert_true, assert_approx_equal
from WCEGases import *
from WCETarcog import *
from WCECommon import *
from EffectiveLayers import *   // assuming EffectiveLayers module exists

struct TestInBetweenShadeAir:
    private var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSingleSystem] = Pointer[Tarcog.ISO15099.CSingleSystem]()

    def SetUp(self) raises:
        let airTemperature = 255.15   # Kelvins
        let airSpeed = 5.5            # meters per second
        let tSky = 255.15             # Kelvins
        let solarRadiation = 0.0
        let Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert_true(Outdoor is not None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature = 295.15
        let Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(Indoor is not None)
        let solidLayerThickness = 0.005715   # [m]
        let solidLayerConductance = 1.0
        let aLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert_true(aLayer1 is not None)
        let aLayer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert_true(aLayer3 is not None)
        let shadeLayerThickness = 0.01
        let shadeLayerConductance = 160.0
        let Atop = 0.1
        let Abot = 0.1
        let Aleft = 0.1
        let Aright = 0.1
        let Afront = 0.2
        let openness = EffectiveLayers.ShadeOpenness{Afront: Afront, Aleft: Aleft, Aright: Aright, Atop: Atop, Abot: Abot}
        let windowWidth = 1.0
        let windowHeight = 1.0
        let effectiveLayer = EffectiveLayers.EffectiveLayerOther{
          windowWidth, windowHeight, shadeLayerThickness, openness}
        let effOpenness = EffectiveLayers.EffectiveOpenness{effectiveLayer.getEffectiveOpenness()}
        let aLayer2 = Tarcog.ISO15099.Layers.shading(
          shadeLayerThickness, shadeLayerConductance, effOpenness)
        assert_true(aLayer2 is not None)
        let gapThickness = 0.0127
        let GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert_true(GapLayer1 is not None)
        let GapLayer2 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert_true(GapLayer2 is not None)
        let aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2, GapLayer2, aLayer3])
        let sys = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem](sys^)
        assert_true(self.m_TarcogSystem is not None)
        self.m_TarcogSystem[].solve()

    def GetSystem(self) -> Pointer[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

def main() raises:
    var test = TestInBetweenShadeAir()
    test.SetUp()
    // Test1
    print("Begin Test: InBetween Shade - Air")
    let aSystem = test.GetSystem()
    let temperature = aSystem[].getTemperatures()
    let radiosity = aSystem[].getRadiosities()
    let correctTemp = List[Float64]{257.908909, 258.369563, 271.538276, 271.542725, 283.615433, 284.076088}
    let correctJ = List[Float64]{249.166497, 260.320226, 300.570040, 316.337636, 358.761633, 378.996135}
    assert_equal(correctTemp.size, temperature.size)
    assert_equal(correctJ.size, radiosity.size)
    for i in range(len(temperature)):
        assert_approx_equal(correctTemp[i], temperature[i], atol=1e-6)
        assert_approx_equal(correctJ[i], radiosity[i], atol=1e-6)
    let numOfIter = aSystem[].getNumberOfIterations()
    assert_equal(Int(numOfIter), 20)