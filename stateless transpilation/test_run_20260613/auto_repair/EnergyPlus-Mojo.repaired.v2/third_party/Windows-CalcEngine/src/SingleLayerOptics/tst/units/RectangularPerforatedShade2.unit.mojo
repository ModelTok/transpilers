from memory import shared_ptr
from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, CBSDFIntegrator, CBSDFHemisphere, BSDFBasis, Material, Side, PropertySimple
from WCECommon import (nothing)
from testing import *

class TestRectangularPerforatedShade2(Test):
    var m_Shade: shared_ptr[CBSDFLayer]

    def SetUp() raises:
        const Tmat = 0.1
        const Rfmat = 0.5
        const Rbmat = 0.6
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const x = 20.0          # mm
        const y = 25.0          # mm
        const thickness = 7.0   # mm
        const xHole = 5.0       # mm
        const yHole = 8.0       # mm
        const aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getRectangularPerforatedLayer(
            aMaterial, aBSDF, x, y, thickness, xHole, yHole)

    def GetShade() -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestSolarProperties():
    SCOPED_TRACE("Begin Test: Rectangular perforated cell - Solar properties.")
    var aShade = TestRectangularPerforatedShade2().GetShade()
    var aResults = aShade.getResults()
    const tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    EXPECT_NEAR(0.112843786, tauDiff, 1e-6)
    const RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    EXPECT_NEAR(0.492864523, RfDiff, 1e-6)
    const RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
    EXPECT_NEAR(0.591437306, RbDiff, 1e-6)
    var aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    const size = aT.size()
    var correctResults = List[Float64](
        1.069864, 0.641828, 0.638318, 0.832716, 0.638318, 0.641828, 0.638318, 0.832716, 0.638318,
        0.031831, 0.116107, 0.260917, 0.409662, 0.260917, 0.116107, 0.031831, 0.116107, 0.260917,
        0.409662, 0.260917, 0.116107, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831,
        0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831,
        0.031831, 0.031831, 0.031831, 0.031831, 0.031831)
    var calculatedResults = List[Float64]()
    for i in range(size):
        calculatedResults.append(aT[i, i])
    EXPECT_EQ(correctResults.size(), calculatedResults.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], calculatedResults[i], 1e-5)
    correctResults = List[Float64](
        1.069864, 0.030443, 0.030451, 0.030008, 0.030451, 0.030443, 0.030451,
        0.030008, 0.030451, 0.031831, 0.031624, 0.031269, 0.030903, 0.031269,
        0.031624, 0.031831, 0.031624, 0.031269, 0.030903, 0.031269, 0.031624,
        0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831,
        0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831,
        0.031831, 0.031831, 0.031831, 0.031831, 0.031831, 0.031831)
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aT[0, i])
    EXPECT_EQ(correctResults.size(), calculatedResults.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], calculatedResults[i], 1e-5)
    var aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.146423, 0.152214, 0.152254, 0.150042, 0.152254, 0.152214, 0.152254,
        0.150042, 0.152254, 0.159155, 0.158120, 0.156343, 0.154517, 0.156343,
        0.158120, 0.159155, 0.158120, 0.156343, 0.154517, 0.156343, 0.158120,
        0.159155, 0.159155, 0.159155, 0.159155, 0.159155, 0.159155, 0.159155,
        0.159155, 0.159155, 0.159155, 0.159155, 0.159155, 0.159155, 0.159155,
        0.159155, 0.159155, 0.159155, 0.159155, 0.159155, 0.159155)
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aRf[0, i])
    EXPECT_EQ(correctResults.size(), calculatedResults.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], calculatedResults[i], 1e-5)