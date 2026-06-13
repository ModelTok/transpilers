from WCETarcog import CSingleSystem, CIGU, Environments, Layers, SkyModel, BoundaryConditionsCoeffModel
from builtin import List

struct TestSingleClearSingleSystem:
    var m_TarcogSystem: CSingleSystem? = None

    def SetUp(inout self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        assert Outdoor is not None
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        assert Indoor is not None
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        assert aSolidLayer is not None
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = Some(CSingleSystem(aIGU, Indoor, Outdoor))
        assert self.m_TarcogSystem is not None
        self.m_TarcogSystem.get().solve()

    def GetSystem(self) -> CSingleSystem?:
        return self.m_TarcogSystem

    def Test1(self):
        # SCOPED_TRACE("Begin Test: Single Clear - U-value")
        var aSystem = self.GetSystem()
        assert aSystem is not None
        var Temperature = aSystem.get().getTemperatures()
        var correctTemperature = List[Float64](297.207035, 297.14470)
        assert correctTemperature.size == Temperature.size
        for i in range(correctTemperature.size):
            # EXPECT_NEAR
            assert (correctTemperature[i] - Temperature[i]).abs() < 1e-5
        var Radiosity = aSystem.get().getRadiosities()
        var correctRadiosity = List[Float64](432.444546, 439.201749)
        assert correctRadiosity.size == Radiosity.size
        for i in range(correctRadiosity.size):
            assert (correctRadiosity[i] - Radiosity[i]).abs() < 1e-5

def main():
    var test = TestSingleClearSingleSystem()
    test.SetUp()
    test.Test1()