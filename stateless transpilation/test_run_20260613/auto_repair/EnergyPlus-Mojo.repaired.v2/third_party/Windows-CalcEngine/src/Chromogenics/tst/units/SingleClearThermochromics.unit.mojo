from memory import unique_ptr
from stdexcept import runtime_error
from testing import *
from WCETarcog import *
from WCEChromogenics import *
from WCECommon import *
from FenestrationCommon import *
from Chromogenics import *

class TestSingleClearThermochromics(Test):
    var m_TarcogSystem: unique_ptr[Tarcog.ISO15099.CSystem]

    def SetUp() raises:
        var airTemperature = 300   # Kelvins
        var airSpeed = 5.5         # meters per second
        var airDirection = Tarcog.ISO15099.AirHorizontalDirection.Windward
        var tSky = 270   # Kelvins
        var solarRadiation = 789
        var Outdoor = shared_ptr[Tarcog.ISO15099.CEnvironment](
            Tarcog.ISO15099.COutdoorEnvironment(
                airTemperature,
                airSpeed,
                solarRadiation,
                airDirection,
                tSky,
                Tarcog.ISO15099.SkyModel.AllSpecified))
        assertTrue(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = shared_ptr[Tarcog.ISO15099.CEnvironment](
            Tarcog.ISO15099.CIndoorEnvironment(roomTemperature))
        assertTrue(Indoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1
        var transmittance = 0
        var emissivity = 0.84
        var emissivities = List[Tuple[float64, float64]]()
        emissivities.append((288.15, 0.84))
        emissivities.append((293.15, 0.74))
        emissivities.append((296.15, 0.64))
        emissivities.append((300.15, 0.54))
        emissivities.append((303.15, 0.44))
        var frontSurface = shared_ptr[Tarcog.ISO15099.ISurface](
            Tarcog.ISO15099.CSurface(emissivity, transmittance))
        var backSurface = shared_ptr[Tarcog.ISO15099.ISurface](
            Chromogenics.ISO15099.CThermochromicSurface(emissivities, transmittance))
        var aSolidLayer = shared_ptr[Tarcog.ISO15099.CIGUSolidLayer](
            Tarcog.ISO15099.CIGUSolidLayer(
                solidLayerThickness, solidLayerConductance, frontSurface, backSurface))
        assertTrue(aSolidLayer != None)
        aSolidLayer.setSolarAbsorptance(0.094189159572, solarRadiation)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        m_TarcogSystem = unique_ptr[Tarcog.ISO15099.CSystem](
            Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        assertTrue(m_TarcogSystem != None)

    def GetSystem() -> Tarcog.ISO15099.CSystem:
        return m_TarcogSystem.get()

def Test1():
    scopedTrace("Begin Test: Single Clear Thermochromics - U-value")
    var aSystem = TestSingleClearThermochromics().GetSystem()
    assertTrue(aSystem != None)
    var aSolidLayers = aSystem.getSolidLayers(Tarcog.ISO15099.System.Uvalue)
    var aLayer = aSolidLayers[0][]
    var emissivity = aLayer.getSurface(Side.Back).getEmissivity()
    expectNear(emissivity, 0.610863, 1e-5)
    var Temperature = aSystem.getTemperatures(Tarcog.ISO15099.System.Uvalue)
    var correctTemperature = List[float64](297.313984, 297.261756)
    assertEqual(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        expectNear(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities(Tarcog.ISO15099.System.Uvalue)
    var correctRadiosity = List[float64](432.979711, 435.605837)
    assertEqual(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        expectNear(correctRadiosity[i], Radiosity[i], 1e-5)
    var numOfIterations = aSystem.getNumberOfIterations(Tarcog.ISO15099.System.Uvalue)
    expectEqual(19, numOfIterations)
    aSolidLayers = aSystem.getSolidLayers(Tarcog.ISO15099.System.SHGC)
    aLayer = aSolidLayers[0][]
    emissivity = aLayer.getSurface(Side.Back).getEmissivity()
    expectNear(emissivity, 0.561212, 1e-5)
    Temperature = aSystem.getTemperatures(Tarcog.ISO15099.System.SHGC)
    correctTemperature = List[float64](299.333611, 299.359313)
    assertEqual(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        expectNear(correctTemperature[i], Temperature[i], 1e-5)
    Radiosity = aSystem.getRadiosities(Tarcog.ISO15099.System.SHGC)
    correctRadiosity = List[float64](443.194727, 441.786960)
    assertEqual(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        expectNear(correctRadiosity[i], Radiosity[i], 1e-5)
    numOfIterations = aSystem.getNumberOfIterations(Tarcog.ISO15099.System.SHGC)
    expectEqual(19, numOfIterations)
    var heatFlow = aSystem.getHeatFlow(Tarcog.ISO15099.System.Uvalue, Tarcog.ISO15099.Environment.Indoor)
    expectNear(heatFlow, -17.135106, 1e-5)
    heatFlow = aSystem.getHeatFlow(Tarcog.ISO15099.System.Uvalue, Tarcog.ISO15099.Environment.Outdoor)
    expectNear(heatFlow, -17.135106, 1e-5)
    heatFlow = aSystem.getHeatFlow(Tarcog.ISO15099.System.SHGC, Tarcog.ISO15099.Environment.Indoor)
    expectNear(heatFlow, -28.725048, 1e-5)
    heatFlow = aSystem.getHeatFlow(Tarcog.ISO15099.System.SHGC, Tarcog.ISO15099.Environment.Outdoor)
    expectNear(heatFlow, 45.590199, 1e-5)
    var UValue = aSystem.getUValue()
    expectNear(UValue, 4.604300, 1e-5)
    var SHGC = aSystem.getSHGC(0.831249)
    expectNear(SHGC, 0.845938, 1e-5)