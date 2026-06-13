from WCESingleLayerOptics import CPhiLimits
from testing import assert_eq, assert_almost_equal

struct TestPhiLimits2:
    private var m_PhiLimits: CPhiLimits

    def __init__(inout self):
        self.m_PhiLimits = CPhiLimits(1)

    def GetLimits(self) -> borrowed CPhiLimits:
        return self.m_PhiLimits

def TestBSDFRingCreation():
    # SCOPED_TRACE("Begin Test: BSDF Phi limits creation.")
    var fixture = TestPhiLimits2()
    var aLimits = fixture.GetLimits()
    var results = aLimits.getPhiLimits()
    var correctResults = List[Float64](0.0, 360.0)
    assert_eq(results.size(), correctResults.size())
    for i in range(results.size()):
        assert_almost_equal(results[i], correctResults[i], 1e-6)

if __name__ == "__main__":
    TestBSDFRingCreation()