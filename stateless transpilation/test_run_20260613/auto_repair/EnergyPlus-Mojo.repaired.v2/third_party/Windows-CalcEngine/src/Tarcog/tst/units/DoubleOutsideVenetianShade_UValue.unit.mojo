from WCEGases import *
from WCETarcog import *
from WCECommon import *

struct TestDoubleOutsideVenetianShade_UValue:
    var m_TarcogSystem: Tarcog.ISO15099.CSystem

    def SetUp(inout self):
        let airTemperature = 255.15
        let airSpeed = 5.5
        let tSky = 255.15
        let solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert Outdoor != None
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor != None
        let shadeLayerConductance = 160.0
        let matThickness = 0.0001
        let slatWidth = 0.0148
        let slatSpacing = 0.0127
        let slatTiltAngle = 0.0
        let curvatureRadius = 0.0331305656433105
        let frontOpenness = ThermalPermeability.Venetian.openness(
            slatTiltAngle, slatSpacing, matThickness, curvatureRadius, slatWidth)
        let dl = 0.0
        let dr = 0.0
        let dtop = 0.0
        let dbot = 0.0
        var openness = EffectiveLayers.ShadeOpenness(frontOpenness, dl, dr, dtop, dbot)
        let windowWidth = 1.0
        let windowHeight = 1.0
        var effectiveVenetian = EffectiveLayers.EffectiveHorizontalVenetian(
            windowWidth, windowHeight, matThickness, openness, slatTiltAngle, slatWidth)
        var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveVenetian.getEffectiveOpenness())
        let effectiveThickness = effectiveVenetian.effectiveThickness()
        let Ef = 0.5564947806702053
        let Eb = 0.5564947806702053
        let Tirf = 0.42293224373137134
        let Tirb = 0.42293224373137134
        var aLayer1 = Tarcog.ISO15099.Layers.shading(
            effectiveThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        let gapThickness = 0.0127
        var GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert GapLayer1 != None
        let solidLayerThickness = 0.003048
        let solidLayerConductance = 1.0
        var aLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert aLayer2 != None
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2])
        self.m_TarcogSystem = Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor)
        assert self.m_TarcogSystem != None

    def GetSystem(self) -> ref[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def Test1():
    print("Begin Test: Outside venetian shade.")
    var testObj = TestDoubleOutsideVenetianShade_UValue()
    testObj.SetUp()
    let aSystem = testObj.GetSystem()
    let effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(
        Tarcog.ISO15099.System.Uvalue)
    let correctEffectConductivites = List[Float64](1.878064, 1.0)
    assert len(correctEffectConductivites) == len(effectiveLayerConductivities)
    for i in range(len(correctEffectConductivites)):
        assert abs(correctEffectConductivites[i] - effectiveLayerConductivities[i]) < 1e-6
    let systemKeff = aSystem.getEffectiveSystemConductivity(Tarcog.ISO15099.System.Uvalue)
    assert abs(0.106427 - systemKeff) < 1e-6
    let uval = aSystem.getUValue()
    assert abs(3.239692 - uval) < 1e-6
    let heatflow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.Uvalue, Tarcog.ISO15099.Environment.Indoor)
    assert abs(126.347983 - heatflow) < 1e-6

def main():
    Test1()