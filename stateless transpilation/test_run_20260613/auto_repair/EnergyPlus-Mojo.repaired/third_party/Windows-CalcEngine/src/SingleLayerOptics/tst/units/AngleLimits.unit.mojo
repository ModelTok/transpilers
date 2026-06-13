from testing import *
from WCESingleLayerOptics import CAngleLimits

@value
struct TestAngleLimits:
    def SetUp(self):

@test
def TestAngleLimits_TestAngleLimits1_Test():
    #SCOPED_TRACE("Begin Test: Angle limits 1.")
    var aLimits = CAngleLimits(-15, 15)
    let angle: Float64 = 350
    var isInLimits: Bool = aLimits.isInLimits(angle)
    assert_eq(isInLimits, True)