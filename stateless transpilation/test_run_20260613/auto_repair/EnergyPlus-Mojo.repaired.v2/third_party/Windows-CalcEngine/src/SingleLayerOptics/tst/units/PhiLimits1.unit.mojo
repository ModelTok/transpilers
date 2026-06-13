from memory import memory
import gtest
from WCESingleLayerOptics import CPhiLimits
from SingleLayerOptics import *

class TestPhiLimits1(gtesting.Test):
    var m_PhiLimits: CPhiLimits

    def __init__(inout self):
        self.m_PhiLimits = CPhiLimits(8)

    def GetLimits(self) -> CPhiLimits:
        return self.m_PhiLimits

def test_TestPhiLimits1_TestBSDFRingCreation():
    gtesting.SCOPED_TRACE("Begin Test: BSDF Phi limits creation.")
    var aLimits = TestPhiLimits1().GetLimits()
    let results = aLimits.getPhiLimits()
    let correctResults = [-22.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5]
    gtesting.EXPECT_EQ(len(results), len(correctResults))
    for i in range(len(results)):
        gtesting.EXPECT_NEAR(results[i], correctResults[i], 1e-6)