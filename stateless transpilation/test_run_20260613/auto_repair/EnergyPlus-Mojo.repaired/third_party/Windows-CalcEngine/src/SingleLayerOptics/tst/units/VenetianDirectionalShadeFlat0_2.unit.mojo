from memory import shared_ptr
from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, CBSDFIntegrator, CBSDFHemisphere, BSDFBasis, DistributionMethod, Material
from WCECommon import Side, PropertySimple
from testing import Test, Expect
class TestVenetianDirectionalShadeFlat0_2(Test):
    var m_Shade: shared_ptr[CBSDFLayer]

    def SetUp(self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.010
        let slatSpacing = 0.010
        let slatTiltAngle = 45
        let curvatureRadius = 0
        let numOfSlatSegments: size_t = 1
        let aDistribution = DistributionMethod.DirectionalDiffuse
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial,
                                                        aBSDF,
                                                        slatWidth,
                                                        slatSpacing,
                                                        slatTiltAngle,
                                                        curvatureRadius,
                                                        numOfSlatSegments,
                                                        aDistribution,
                                                        True)

    def GetShade(self) -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    Expect.scoped_trace("Begin Test: Venetian cell (Flat, 45 degrees slats) - solar properties.")
    let aShade = TestVenetianDirectionalShadeFlat0_2().GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    Expect.near(0.45408806110142574, tauDiff, 1e-6)
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    Expect.near(0.27657763790935469, RfDiff, 1e-6)