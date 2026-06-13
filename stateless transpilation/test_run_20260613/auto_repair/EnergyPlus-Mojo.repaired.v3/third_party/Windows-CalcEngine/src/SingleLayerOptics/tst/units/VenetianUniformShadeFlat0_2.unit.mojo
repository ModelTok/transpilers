from WCECommon import Side, PropertySimple
from WCESingleLayerOptics import CBSDFLayer, CBSDFIntegrator, CBSDFHemisphere, CBSDFLayerMaker, Material, DistributionMethod, BSDFBasis
from testing import assert_almost_equal

struct TestVenetianUniformShadeFlat0_2:
    var m_Shade: Pointer[CBSDFLayer]

    def SetUp(self):
        let Tmat = 0.0
        let Rfmat = 0.1
        let Rbmat = 0.1
        let minLambda = 5.0
        let maxLambda = 40.0
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.016     # m
        let slatSpacing = 0.012   # m
        let slatTiltAngle = 0
        let curvatureRadius = 0
        let numOfSlatSegments: Int = 5
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial,
                                                        aBSDF,
                                                        slatWidth,
                                                        slatSpacing,
                                                        slatTiltAngle,
                                                        curvatureRadius,
                                                        numOfSlatSegments,
                                                        DistributionMethod.UniformDiffuse,
                                                        True)

    def GetShade(self) -> Pointer[CBSDFLayer]:
        return self.m_Shade

@test
def TestDefaultA0Venetian():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 0 degrees slats) - A0 Venetian.")
    var aShade = TestVenetianUniformShadeFlat0_2()
    aShade.SetUp()
    var aResults = aShade.GetShade()[].getResults()
    let tauDiff = aResults[].DiffDiff(Side.Front, PropertySimple.T)
    assert_almost_equal(tauDiff, 0.397, 1e-6)
    let RfDiff = aResults[].DiffDiff(Side.Front, PropertySimple.R)
    assert_almost_equal(RfDiff, 0.019894, 1e-6)