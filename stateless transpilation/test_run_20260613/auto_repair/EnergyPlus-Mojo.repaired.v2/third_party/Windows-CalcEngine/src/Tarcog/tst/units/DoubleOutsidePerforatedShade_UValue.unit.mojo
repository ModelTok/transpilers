from memory import Pointer
from testing import assert_true, assert_approx_eq, assert_eq
from WCETarcog import (
    Tarcog,
    ThermalPermeability,
    EffectiveLayers,
)

struct TestDoubleOutsidePerforatedShade_UValue:
    private var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSystem]

    def SetUp(self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert_true(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(Indoor != None)
        var shadeLayerConductance = 0.12
        const thickness_31111: Float64 = 0.00023
        const x: Float64 = 0.00169        # m
        const y: Float64 = 0.00169        # m
        const radius: Float64 = 0.00058   # m
        const CellDimension = ThermalPermeability.Perforated.diameterToXYDimension(2 * radius)
        const frontOpenness = ThermalPermeability.Perforated.openness(
            ThermalPermeability.Perforated.Geometry.Circular,
            x,
            y,
            CellDimension.x,
            CellDimension.y)
        const dl: Float64 = 0.0
        const dr: Float64 = 0.0
        const dtop: Float64 = 0.0
        const dbot: Float64 = 0.0
        var openness = EffectiveLayers.ShadeOpenness(frontOpenness, dl, dr, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayerPerforated = EffectiveLayers.EffectiveLayerPerforated(
            windowWidth, windowHeight, thickness_31111, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(
            effectiveLayerPerforated.getEffectiveOpenness())
        const effectiveThickness = effectiveLayerPerforated.effectiveThickness()
        var Ef: Float64 = 0.640892
        var Eb: Float64 = 0.623812
        var Tirf: Float64 = 0.257367
        var Tirb: Float64 = 0.257367
        var aLayer1 = Tarcog.ISO15099.Layers.shading(
            effectiveThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        aLayer1.setSolarAbsorptance(0.106659, solarRadiation)
        var gapThickness = 0.0127
        var GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert_true(GapLayer1 != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert_true(aLayer2 != None)
        aLayer2.setSolarAbsorptance(0.034677, solarRadiation)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2])
        self.m_TarcogSystem = Pointer[Tarcog.ISO15099.CSystem].alloc()
        self.m_TarcogSystem.init(aIGU, Indoor, Outdoor)
        assert_true(self.m_TarcogSystem != None)

    def GetSystem(self) -> Pointer[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def Test1():
    # SCOPED_TRACE("Begin Test: Outside perforated shade.")
    var testObj = TestDoubleOutsidePerforatedShade_UValue()
    testObj.SetUp()
    var aSystem = testObj.GetSystem()
    const uval = aSystem.getUValue()
    assert_approx_eq(3.213412, uval, 1e-6)
    const effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(
        Tarcog.ISO15099.System.Uvalue)
    const correctEffectConductivites: List[Float64] = List[Float64](0.108207, 1)
    assert_eq(correctEffectConductivites.size, effectiveLayerConductivities.size)
    for i in range(correctEffectConductivites.size):
        assert_approx_eq(correctEffectConductivites[i], effectiveLayerConductivities[i], 1e-6)
    const heatflow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.Uvalue, Tarcog.ISO15099.Environment.Indoor)
    assert_approx_eq(125.323087, heatflow, 1e-6)

# Run the test
Test1()