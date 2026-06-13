from memory import Pointer
from utils.list import List
from math import isclose
from WCETarcog import Tarcog
from WCECommon import testing

struct DoubleLowEVacuumCircularPillar:
    private var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSingleSystem]

    def SetUp(inout self):
        var airTemperature = 255.15  # Kelvins
        var airSpeed = 5.5  # meters per second
        var tSky = 255.15  # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky,
            Tarcog.ISO15099.SkyModel.AllSpecified
        )
        assert Outdoor._ptr() != None
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor._ptr() != None
        var solidLayerThickness = 0.004  # [m]
        var solidLayerConductance = 1.0
        var TransmittanceIR = 0.0
        var emissivityFrontIR = 0.84
        var emissivityBackIR = 0.036749500781
        var layer1 = Tarcog.ISO15099.Layers.solid(
            solidLayerThickness,
            solidLayerConductance,
            emissivityFrontIR,
            TransmittanceIR,
            emissivityBackIR,
            TransmittanceIR
        )
        solidLayerThickness = 0.003962399904
        emissivityBackIR = 0.84
        var layer2 = Tarcog.ISO15099.Layers.solid(
            solidLayerThickness,
            solidLayerConductance,
            emissivityFrontIR,
            TransmittanceIR,
            emissivityBackIR,
            TransmittanceIR
        )
        var gapThickness = 0.0001
        var gapPressure = 0.1333
        var aGapLayer = Tarcog.ISO15099.Layers.gap(gapThickness, gapPressure)
        var pillarConductivity = 999.0
        var pillarSpacing = 0.03
        var pillarRadius = 0.0002
        var pillarGap = Tarcog.ISO15099.Layers.addCircularPillar(
            aGapLayer, pillarConductivity, pillarSpacing, pillarRadius
        )
        assert pillarGap._ptr() != None
        var windowWidth = 1.0  # [m]
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, pillarGap, layer2])
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSingleSystem].make(
            Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
        )
        assert self.m_TarcogSystem._ptr() != None
        self.m_TarcogSystem.solve()

    def GetSystem(inout self) -> Pointer[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

def Test1():
    SCOPED_TRACE = "Begin Test: Double Low-E - vacuum with circular pillar support"
    print(SCOPED_TRACE)
    var fixture = DoubleLowEVacuumCircularPillar()
    fixture.SetUp()
    var aSystem = fixture.GetSystem()
    assert aSystem._ptr() != None
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](255.997063, 256.095933, 290.398479, 290.496419)
    assert correctTemperature.size == Temperature.size
    for i in range(correctTemperature.size):
        var diff = correctTemperature[i] - Temperature[i]
        assert isclose(correctTemperature[i], Temperature[i], abs_tol=1e-5), \
            "Temperature mismatch at index " + str(i) + ": expected " + str(correctTemperature[i]) + ", got " + str(Temperature[i])
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](242.987484, 396.293176, 402.108090, 407.071738)
    assert correctRadiosity.size == Radiosity.size
    for i in range(correctRadiosity.size):
        assert isclose(correctRadiosity[i], Radiosity[i], abs_tol=1e-5), \
            "Radiosity mismatch at index " + str(i) + ": expected " + str(correctRadiosity[i]) + ", got " + str(Radiosity[i])
    var numOfIter = aSystem.getNumberOfIterations()
    assert numOfIter == 21, "Number of iterations mismatch: expected 21, got " + str(numOfIter)

def main():
    Test1()