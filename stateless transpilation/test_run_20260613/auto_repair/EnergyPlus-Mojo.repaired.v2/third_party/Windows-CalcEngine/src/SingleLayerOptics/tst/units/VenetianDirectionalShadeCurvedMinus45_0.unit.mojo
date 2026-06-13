from WCECommon import Material, Side, PropertySimple
from WCESingleLayerOptics import CBSDFLayer, CBSDFIntegrator, CBSDFHemisphere, CBSDFLayerMaker, BSDFBasis, DistributionMethod

struct TestVenetianDirectionalShadeCurvedMinus45_0:
    var m_Shade: CBSDFLayer

    def SetUp(self):
        let Tmat = 0.0
        let Rfmat = 0.95
        let Rbmat = 0.95
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.025400     # m
        let slatSpacing = 0.019000   # m
        let slatTiltAngle = -45
        let curvatureRadius = 0.041322
        let numOfSlatSegments: Int = 5
        let aDistribution = DistributionMethod.DirectionalDiffuse
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial,
                                                        aBSDF,
                                                        slatWidth,
                                                        slatSpacing,
                                                        slatTiltAngle,
                                                        curvatureRadius,
                                                        numOfSlatSegments,
                                                        aDistribution,
                                                        True)

    def GetShade(self) -> CBSDFLayer:
        return self.m_Shade

@test
def TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian shade (Curved, -45 degrees slats).")
    let fixture = TestVenetianDirectionalShadeCurvedMinus45_0()
    fixture.SetUp()
    let aShade = fixture.GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert abs(tauDiff - 0.382240) < 1e-6
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert abs(RfDiff - 0.541774) < 1e-6