from memory import shared_ptr
from WCECommon import *
from WCESingleLayerOptics import *
from FenestrationCommon import *

class TestVenetianUniformShadeCurvedMinus45_0:
    var m_Shade: shared_ptr[CBSDFLayer]

    def __init__(inout self):
        self.m_Shade = shared_ptr[CBSDFLayer]()

    def SetUp(inout self):
        let Tmat = 0.0
        let Rfmat = 0.95
        let Rbmat = 0.95
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.025400
        let slatSpacing = 0.019000
        let slatTiltAngle = -45
        let curvatureRadius = 0.041322
        let numOfSlatSegments: size_t = 5
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

    def GetShade(self) -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    print("Begin Test: Venetian shade (Curved, -45 degrees slats).")
    let aShade = TestVenetianUniformShadeCurvedMinus45_0().GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    expect_near(0.384231, tauDiff, 1e-6)
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    expect_near(0.542896, RfDiff, 1e-6)