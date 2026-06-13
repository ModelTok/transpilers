from ......WCESingleLayerOptics import CThetaLimits, wce

struct TestBSDFThetaLimtisFullBasis:
    var m_Thetas: Pointer[CThetaLimits]

    def __init__(inout self):
        self.m_Thetas = Pointer[CThetaLimits]()
        self.SetUp()

    def SetUp(inout self):
        var thetaAngles = List[Float64](0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 82.5)
        self.m_Thetas = wce.make_unique[CThetaLimits](thetaAngles)

    def GetLimits(self) -> &CThetaLimits:
        return *self.m_Thetas

    def TestFullBasis(inout self):
        print("Begin Test: Theta limits - full basis.")
        let aLimits = self.GetLimits()
        let results = *aLimits.getThetaLimits()
        let correctResults = List[Float64](0.0, 5.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0, 90.0)
        assert results.size == correctResults.size, "Size mismatch"
        for i in range(results.size):
            assert abs(results[i] - correctResults[i]) < 1e-6, "Value mismatch at index " + str(i)

def main():
    var test = TestBSDFThetaLimtisFullBasis()
    test.TestFullBasis()