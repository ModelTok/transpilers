from memory import unique_ptr
from testing import Test
from WCESingleLayerOptics import CThetaLimits
from WCESingleLayerOptics import wce

class TestBSDFThetaLimtisHalfBasis(Test):
    private:
        var m_Thetas: unique_ptr[CThetaLimits]

    protected:
        def SetUp() raises:
            var thetaAngles = List[Float64](0, 13, 26, 39, 52, 65, 80.75)
            self.m_Thetas = wce.make_unique[CThetaLimits](thetaAngles)

    public:
        def GetLimits() raises -> CThetaLimits:
            return *self.m_Thetas

def TestHalfBasis() raises:
    print("Begin Test: Theta limits - half basis.")
    var aLimits = TestBSDFThetaLimtisHalfBasis().GetLimits()
    var results = *(aLimits.getThetaLimits())
    var correctResults = List[Float64](0, 6.5, 19.5, 32.5, 45.5, 58.5, 71.5, 90)
    assert_eq(results.size, correctResults.size)
    for i in range(results.size):
        assert_approx_eq(results[i], correctResults[i], 1e-6)