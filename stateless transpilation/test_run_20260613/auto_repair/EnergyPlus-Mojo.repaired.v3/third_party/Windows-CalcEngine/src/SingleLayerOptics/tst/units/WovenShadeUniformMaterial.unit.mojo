from WCESingleLayerOptics import Material, CBSDFHemisphere, BSDFBasis, CBSDFLayerMaker, CBSDFLayer, CBSDFIntegrator
from WCECommon import Side, PropertySimple

struct TestWovenShadeUniformMaterial:
    var m_Shade: CBSDFLayer

    def __init__(inout self):
        self.m_Shade = CBSDFLayer()

    def SetUp(inout self):
        var Tmat = 0.0
        var Rfmat = 0.1
        var Rbmat = 0.1
        var minLambda = 5.0
        var maxLambda = 40.0
        var aMaterial = Material.singleBandMaterial(
            Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        var diameter = 0.002   # m
        var spacing = 0.003    # m
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getWovenLayer(aMaterial, aBSDF, diameter, spacing)

    def GetShade(self) -> CBSDFLayer:
        return self.m_Shade

def TestSolarProperties():
    var test = TestWovenShadeUniformMaterial()
    test.SetUp()
    var aShade = test.GetShade()
    var aResults = aShade.getResults()
    var tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert(tauDiff - 0.037033896815761802).abs() < 1e-6
    var RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert(RfDiff - 0.096296610318422418).abs() < 1e-6
    var RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
    assert(RbDiff - 0.096296610318422418).abs() < 1e-6
    var theta = 0.0
    var phi = 0.0
    var Emiss = aResults.Abs(Side.Front, theta, phi)
    assert(Emiss - 0.8).abs() < 1e-6