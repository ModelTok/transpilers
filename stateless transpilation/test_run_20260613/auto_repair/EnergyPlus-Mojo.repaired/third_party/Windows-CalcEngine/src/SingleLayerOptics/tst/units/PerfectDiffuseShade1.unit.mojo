from memory import SharedPtr
from gtest import *
from WCESingleLayerOptics import *
from WCECommon import *
from FenestrationCommon import *

class TestPerfectDiffuseShade1(testing.Test):
    var m_Shade: SharedPtr[CBSDFLayer]

    def SetUp(self):
        var Tmat: Float64 = 0.00
        var Rfmat: Float64 = 0.55
        var Rbmat: Float64 = 0.55
        var minLambda: Float64 = 0.3
        var maxLambda: Float64 = 2.5
        var aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getPerfectlyDiffuseLayer(aMaterial, aBSDF)

    def GetShade(self) -> SharedPtr[CBSDFLayer]:
        return self.m_Shade

def TestSolarProperties(self: TestPerfectDiffuseShade1):
    SCOPED_TRACE("Begin Test: Perfect diffuse shade - Solar properties.")
    var aShade: SharedPtr[CBSDFLayer] = self.GetShade()
    var aResults: SharedPtr[CBSDFIntegrator] = aShade.getResults()
    var tauDiff: Float64 = aResults.DiffDiff(Side.Front, PropertySimple.T)
    EXPECT_NEAR(0.000000000, tauDiff, 1e-6)
    var RfDiff: Float64 = aResults.DiffDiff(Side.Front, PropertySimple.R)
    EXPECT_NEAR(0.550000000, RfDiff, 1e-6)
    var aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    var size: size = aT.size()
    var correctResults: List[Float64] = List[Float64](41, 0)
    var calculatedResults: List[Float64] = List[Float64]()
    for i in range(size):
        calculatedResults.append(aT[i, i])
    EXPECT_EQ(correctResults.size(), calculatedResults.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], calculatedResults[i], 1e-5)
    var aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070,
                      0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070,
                      0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070,
                      0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070,
                      0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070,
                      0.175070, 0.175070, 0.175070, 0.175070, 0.175070, 0.175070)
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aRf[i, i])
    EXPECT_EQ(correctResults.size(), calculatedResults.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], calculatedResults[i], 1e-5)