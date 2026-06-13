from memory import Owned
from WCESingleLayerOptics import CThetaLimits, wce

struct TestBSDFThetaLimtisQuarterBasis:
    private:
        var m_Thetas: Owned[CThetaLimits]

    protected:
        def SetUp(inout self):
            var thetaAngles = List[Float64](0, 18, 36, 54, 76.5)
            self.m_Thetas = wce.make_unique[CThetaLimits](thetaAngles)

    public:
        def GetLimits(borrowed self) -> Borrowed[CThetaLimits]:
            return self.m_Thetas[]

def TestQuarterBasis():
    # SCOPED_TRACE("Begin Test: Theta limits - quarter basis.")
    var fixture = TestBSDFThetaLimtisQuarterBasis()
    fixture.SetUp()
    var aLimits = fixture.GetLimits()
    var results = *aLimits.getThetaLimits()
    var correctResults = List[Float64](0, 9, 27, 45, 63, 90)
    assert(len(results) == len(correctResults))
    for i in range(len(results)):
        assert(abs(results[i] - correctResults[i]) < 1e-6)