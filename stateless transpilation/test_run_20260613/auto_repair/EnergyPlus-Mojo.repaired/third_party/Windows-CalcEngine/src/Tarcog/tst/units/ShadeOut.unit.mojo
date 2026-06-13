from WCETarcog import (
    Tarcog.ISO15099.CSingleSystem,
    Tarcog.ISO15099.Environments,
    Tarcog.ISO15099.Layers,
    Tarcog.ISO15099.CIGU,
    Tarcog.ISO15099.SkyModel,
    Tarcog.ISO15099.BoundaryConditionsCoeffModel,
)
from WCECommon import (
    EffectiveLayers.ShadeOpenness,
    EffectiveLayers.EffectiveLayerOther,
    EffectiveLayers.EffectiveOpenness,
)

struct TestShadeOut:
    private:
        var m_TarcogSystem: Tarcog.ISO15099.CSingleSystem?

    protected:
        def SetUp(self) raises:
            var airTemperature = 255.15   # Kelvins
            var airSpeed = 5.5            # meters per second
            var tSky = 255.15             # Kelvins
            var solarRadiation = 0.0
            var Outdoor = Tarcog.ISO15099.Environments.outdoor(
              airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
            assert Outdoor != None
            Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
            var roomTemperature = 294.15
            var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
            assert Indoor != None
            var emissivity = 0.832855582237
            var transmittance = 0.074604861438
            var shadeLayerThickness = 0.0006
            var shadeLayerConductance = 160.0
            var Atop = 0.0
            var Abot = 0.0
            var Aleft = 0.0
            var Aright = 0.0
            var Afront = 0.5
            var openness = EffectiveLayers.ShadeOpenness(Afront, Aleft, Aright, Atop, Abot)
            var windowWidth = 1.0
            var windowHeight = 1.0
            var effectiveLayer = EffectiveLayers.EffectiveLayerOther(
              windowWidth, windowHeight, shadeLayerThickness, openness
            )
            var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
            var layer1 = Tarcog.ISO15099.Layers.shading(shadeLayerThickness,
                                                        shadeLayerConductance,
                                                        effOpenness,
                                                        emissivity,
                                                        transmittance,
                                                        emissivity,
                                                        transmittance)
            assert layer1 != None
            var solidLayerThickness = 0.0056134   # [m]
            var solidLayerConductance = 1.0
            var emissivity1 = 0.84
            var emissivity2 = 0.038798544556
            transmittance = 0.0
            var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness,
                                                      solidLayerConductance,
                                                      emissivity1,
                                                      transmittance,
                                                      emissivity2,
                                                      transmittance)
            assert layer2 != None
            var gapThickness = 0.0127
            var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
            assert gap != None
            var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
            aIGU.addLayers(List(layer1, gap, layer2))
            self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
            self.m_TarcogSystem.solve()

    public:
        def GetSystem(self) -> Tarcog.ISO15099.CSingleSystem:
            return self.m_TarcogSystem.value

@test
def Test1() raises:
    #SCOPED_TRACE("Begin Test: Single Clear - U-value")
    var aTest = TestShadeOut()
    aTest.SetUp()
    var aSystem = aTest.GetSystem()
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](256.991898, 256.992301, 269.666385, 270.128448)
    assert len(correctTemperature) == len(Temperature)
    for i in range(len(correctTemperature)):
        assert abs(correctTemperature[i] - Temperature[i]) < 1e-5

    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](249.992982, 250.921614, 292.000161, 419.703062)
    assert len(correctRadiosity) == len(Radiosity)
    for i in range(len(correctRadiosity)):
        assert abs(correctRadiosity[i] - Radiosity[i]) < 1e-5