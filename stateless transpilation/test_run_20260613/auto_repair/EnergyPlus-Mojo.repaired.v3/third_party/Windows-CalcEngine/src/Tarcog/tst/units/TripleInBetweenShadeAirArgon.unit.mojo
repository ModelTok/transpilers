from memory import Pointer
from testing import assert_approx_eq, assert_eq
from WCEGases import Gases
from WCETarcog import Tarcog, EffectiveLayers

struct TestInBetweenShadeAirArgon:
    var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSingleSystem] = Pointer[Tarcog.ISO15099.CSingleSystem]()

    def SetUp(self) raises:
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert Outdoor != None
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 295.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor != None
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert layer1 != None
        var layer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert layer3 != None
        var shadeLayerThickness = 0.01
        var shadeLayerConductance = 160.0
        var Atop = 0.1
        var Abot = 0.1
        var Aleft = 0.1
        var Aright = 0.1
        var Afront = 0.2
        var openness = EffectiveLayers.ShadeOpenness(Afront, Aleft, Aright, Atop, Abot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayer = EffectiveLayers.EffectiveLayerOther(
          windowWidth, windowHeight, shadeLayerThickness, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
        var layer2 = Tarcog.ISO15099.Layers.shading(
          shadeLayerThickness, shadeLayerConductance, effOpenness)
        assert layer2 != None
        var AirCon = Gases.CIntCoeff(2.8733e-03, 7.76e-05, 0.0)
        var AirCp = Gases.CIntCoeff(1.002737e+03, 1.2324e-02, 0.0)
        var AirVisc = Gases.CIntCoeff(3.7233e-06, 4.94e-08, 0.0)
        var AirData = Gases.CGasData("Air", 28.97, 1.4, AirCp, AirCon, AirVisc)
        var ArgonCon = Gases.CIntCoeff(2.2848e-03, 5.1486e-05, 0.0)
        var ArgonCp = Gases.CIntCoeff(5.21929e+02, 0.0, 0.0)
        var ArgonVisc = Gases.CIntCoeff(3.3786e-06, 6.4514e-08, 0.0)
        var ArgonData = Gases.CGasData("Argon", 39.948, 1.67, ArgonCp, ArgonCon, ArgonVisc)
        var Gas1 = Gases.CGas({{{0.1, AirData}, {0.9, ArgonData}}})
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness, Gas1)
        assert gap1 != None
        var gap2 = Tarcog.ISO15099.Layers.gap(gapThickness, Gas1)
        assert gap2 != None
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers({layer1, gap1, layer2, gap2, layer3})
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem].alloc()
        self.m_TarcogSystem.init(
          Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor))
        assert self.m_TarcogSystem.value != None
        self.m_TarcogSystem.value.solve()

    def GetSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return self.m_TarcogSystem.value

    def Test1(self) raises:
        # SCOPED_TRACE("Begin Test: InBetween Shade - Air(10%)/Argon(90%)")
        var aSystem = self.GetSystem()
        assert aSystem != None
        var Temperature = aSystem.getTemperatures()
        var correctTemperature = List[Float64](
          257.708550, 258.135695, 271.903647, 271.907946, 284.412984, 284.840129)
        assert_eq(correctTemperature.size, Temperature.size)
        for i in range(correctTemperature.size):
            assert_approx_eq(correctTemperature[i], Temperature[i], 1e-6)
        var Radiosity = aSystem.getRadiosities()
        var correctRadiosity = List[Float64](
          248.512463, 259.761987, 301.877098, 318.341741, 362.563088, 382.346347)
        assert_eq(correctRadiosity.size, Radiosity.size)
        for i in range(correctRadiosity.size):
            assert_approx_eq(correctRadiosity[i], Radiosity[i], 1e-6)
        var numOfIter = self.GetSystem().getNumberOfIterations()
        assert_eq(21, numOfIter)

def main() raises:
    var testObj = TestInBetweenShadeAirArgon()
    testObj.SetUp()
    testObj.Test1()