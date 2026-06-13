from memory import Arc
from testing import assert_approx_eq, assert_eq
from WCECommon import *
from WCESingleLayerOptics import *

# Simulate gtest macros
def SCOPED_TRACE(msg: String):

def EXPECT_NEAR(actual: Float64, expected: Float64, tolerance: Float64):
    assert_approx_eq(actual, expected, tolerance)

def EXPECT_EQ(actual: Int, expected: Int):
    assert_eq(actual, expected)

def EXPECT_EQ(actual: Float64, expected: Float64):
    assert_eq(actual, expected)

# Test class
class TestVenetianUniformShadeFlat45_1:
    var m_Shade: Arc[CBSDFLayer]

    def __init__(inout self):
        self.m_Shade = Arc[CBSDFLayer]()

    def SetUp(inout self):
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
        let numOfSlatSegments: Int = 1
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = Arc[CBSDFLayer](CBSDFLayerMaker.getVenetianLayer(
            aMaterial,
            aBSDF,
            slatWidth,
            slatSpacing,
            slatTiltAngle,
            curvatureRadius,
            numOfSlatSegments,
            DistributionMethod.UniformDiffuse,
            True
        ))

    def GetShade(self) -> Arc[CBSDFLayer]:
        return self.m_Shade

# Test function
def TestVenetian1():
    SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - solar properties.")
    let testObj = TestVenetianUniformShadeFlat45_1()
    testObj.SetUp()
    let aShade = testObj.GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    EXPECT_NEAR(0.47624006362615717, tauDiff, 1e-6)
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    EXPECT_NEAR(0.33488359240717491, RfDiff, 1e-6)
    let aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    let size = aT.size()
    var correctResults = List[Float64]()
    correctResults.append(3.861585)
    correctResults.append(4.158130)
    correctResults.append(6.423857)
    correctResults.append(7.362352)
    correctResults.append(6.423857)
    correctResults.append(4.158130)
    correctResults.append(1.892403)
    correctResults.append(0.953908)
    correctResults.append(1.892403)
    correctResults.append(3.858581)
    correctResults.append(7.178301)
    correctResults.append(9.608505)
    correctResults.append(10.49802)
    correctResults.append(9.608505)
    correctResults.append(7.178301)
    correctResults.append(3.858581)
    correctResults.append(0.538861)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.538861)
    correctResults.append(3.858581)
    correctResults.append(10.14755)
    correctResults.append(11.25443)
    correctResults.append(9.580691)
    correctResults.append(11.25443)
    correctResults.append(10.14755)
    correctResults.append(3.858581)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(3.670579)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(3.670579)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    EXPECT_EQ(correctResults.size, aT.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aT[i, i], 1e-5)
    let aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.113584)
    correctResults.append(0.113584)
    correctResults.append(0.087488)
    correctResults.append(0.076678)
    correctResults.append(0.087488)
    correctResults.append(0.113584)
    correctResults.append(0.139680)
    correctResults.append(0.150490)
    correctResults.append(0.139680)
    correctResults.append(0.113584)
    correctResults.append(0.072322)
    correctResults.append(0.042116)
    correctResults.append(0.031060)
    correctResults.append(0.042116)
    correctResults.append(0.072322)
    correctResults.append(0.113584)
    correctResults.append(0.154846)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.154846)
    correctResults.append(0.113584)
    correctResults.append(0.035417)
    correctResults.append(0.009955)
    correctResults.append(0.019516)
    correctResults.append(0.009955)
    correctResults.append(0.035417)
    correctResults.append(0.113584)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.113584)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.113584)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    EXPECT_EQ(correctResults.size, aRf.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aRf[i, i], 1e-5)
    let aTb = aResults.getMatrix(Side.Back, PropertySimple.T)
    correctResults.clear()
    correctResults.append(3.861585)
    correctResults.append(4.158130)
    correctResults.append(1.892403)
    correctResults.append(0.953908)
    correctResults.append(1.892403)
    correctResults.append(4.158130)
    correctResults.append(6.423857)
    correctResults.append(7.362352)
    correctResults.append(6.423857)
    correctResults.append(3.858581)
    correctResults.append(0.538861)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.538861)
    correctResults.append(3.858581)
    correctResults.append(7.178301)
    correctResults.append(9.608505)
    correctResults.append(10.49802)
    correctResults.append(9.608505)
    correctResults.append(7.178301)
    correctResults.append(3.858581)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(3.858581)
    correctResults.append(10.14755)
    correctResults.append(11.25443)
    correctResults.append(9.580691)
    correctResults.append(11.25443)
    correctResults.append(10.14755)
    correctResults.append(3.670579)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(3.670579)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    EXPECT_EQ(correctResults.size, aTb.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aTb[i, i], 1e-5)
    let aRb = aResults.getMatrix(Side.Back, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.113584)
    correctResults.append(0.113584)
    correctResults.append(0.139680)
    correctResults.append(0.150490)
    correctResults.append(0.139680)
    correctResults.append(0.113584)
    correctResults.append(0.087488)
    correctResults.append(0.076678)
    correctResults.append(0.087488)
    correctResults.append(0.113584)
    correctResults.append(0.154846)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.154846)
    correctResults.append(0.113584)
    correctResults.append(0.072322)
    correctResults.append(0.042116)
    correctResults.append(0.031060)
    correctResults.append(0.042116)
    correctResults.append(0.072322)
    correctResults.append(0.113584)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.113584)
    correctResults.append(0.035417)
    correctResults.append(0.009955)
    correctResults.append(0.019516)
    correctResults.append(0.009955)
    correctResults.append(0.035417)
    correctResults.append(0.113584)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.160632)
    correctResults.append(0.113584)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    correctResults.append(0.073329)
    EXPECT_EQ(correctResults.size, aRb.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aRb[i, i], 1e-5)