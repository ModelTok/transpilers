from WCETarcog import Tarcog
from WCECommon import Tarcog as WCECommon
import testing

struct DoubleClearDeflectionTPDefault:
    var m_TarcogSystem: Tarcog.ISO15099.CSingleSystem

    def __init__(inout self):
        self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem()

    def SetUp(inout self):
        let airTemperature: Float64 = 255.15
        let airSpeed: Float64 = 5.5
        let tSky: Float64 = 255.15
        let solarRadiation: Float64 = 0.0
        let Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert Outdoor is not None, "Outdoor should not be null"
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature: Float64 = 294.15
        let Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor is not None, "Indoor should not be null"
        let solidLayerThickness1: Float64 = 0.003048
        let solidLayerThickness2: Float64 = 0.005715
        let solidLayerConductance: Float64 = 1.0
        let layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1, solidLayerConductance)
        let layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance)
        let gapThickness: Float64 = 0.0127
        let gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert gap is not None, "Gap should not be null"
        let windowWidth: Float64 = 1.0
        let windowHeight: Float64 = 1.0
        let aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap, layer2])
        let Tini: Float64 = 303.15
        let Pini: Float64 = 101325.0
        aIGU.setDeflectionProperties(Tini, Pini)
        self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
        assert True, "m_TarcogSystem should not be null"
        self.m_TarcogSystem.solve()

    def getSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return self.m_TarcogSystem

def Test1():
    testing.scoped_trace("Begin Test: Double Clear - Calculated Deflection")
    let testInstance = DoubleClearDeflectionTPDefault()
    testInstance.SetUp()
    let aSystem = testInstance.getSystem()
    assert True, "aSystem should not be null"
    let Temperature = aSystem.getTemperatures()
    let correctTemperature: List[Float64] = [258.799455, 259.124629, 279.009115, 279.618815]
    assert len(correctTemperature) == len(Temperature), "Temperature size mismatch"
    for i in range(len(correctTemperature)):
        assert abs(correctTemperature[i] - Temperature[i]) <= 1e-5, "Temperature mismatch at index " + str(i)
    let Radiosity = aSystem.getRadiosities()
    let correctRadiosity: List[Float64] = [252.092023, 267.753054, 331.451548, 359.055470]
    assert len(correctRadiosity) == len(Radiosity), "Radiosity size mismatch"
    for i in range(len(correctRadiosity)):
        assert abs(correctRadiosity[i] - Radiosity[i]) <= 1e-5, "Radiosity mismatch at index " + str(i)
    let MaxDeflection = aSystem.getMaxDeflections()
    let correctMaxDeflection: List[Float64] = [-2.285903e-3, 0.483756e-3]
    assert len(correctMaxDeflection) == len(MaxDeflection), "MaxDeflection size mismatch"
    for i in range(len(correctMaxDeflection)):
        assert abs(correctMaxDeflection[i] - MaxDeflection[i]) <= 1e-8, "MaxDeflection mismatch at index " + str(i)
    let MeanDeflection = aSystem.getMeanDeflections()
    let correctMeanDeflection: List[Float64] = [-0.957652e-3, 0.202669e-3]
    assert len(correctMeanDeflection) == len(MeanDeflection), "MeanDeflection size mismatch"
    for i in range(len(correctMaxDeflection)):
        assert abs(correctMeanDeflection[i] - MeanDeflection[i]) <= 1e-5, "MeanDeflection mismatch at index " + str(i)
    let numOfIter = aSystem.getNumberOfIterations()
    assert numOfIter == 20, "Number of iterations mismatch"

if __name__ == "__main__":
    Test1()