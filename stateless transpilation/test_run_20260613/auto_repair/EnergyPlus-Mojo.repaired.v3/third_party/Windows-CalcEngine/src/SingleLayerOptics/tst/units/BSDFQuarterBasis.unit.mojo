from WCESingleLayerOptics import CBSDFHemisphere, CBSDFDirections, CBSDFPatch, BSDFBasis, BSDFDirection

class TestBSDFQuarterBasis:
    var m_BSDFHemisphere: CBSDFHemisphere

    def __init__(inout self):
        self.m_BSDFHemisphere = CBSDFHemisphere.create(BSDFBasis.Quarter)

    def GetDirections(self, t_Side: BSDFDirection) -> CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

    def TestQuarterBasisPhis(self):
        print("Begin Test: Phi angles for patches.")
        var aDirections = self.GetDirections(BSDFDirection.Incoming)
        var correctResults = List[Float64](180, 0, 45, 90, 135, 180, 225, 270, 315, 0, 30,
                                          60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 0,
                                          30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330,
                                          0, 45, 90, 135, 180, 225, 270, 315)
        var correctSize: Int = 41
        assert(correctSize == aDirections.size(), "Size mismatch")
        var phiAngles = List[Float64]()
        for aPatch in aDirections:
            phiAngles.append(aPatch.centerPoint().phi())
        for i in range(phiAngles.size):
            assert(abs(phiAngles[i] - correctResults[i]) < 1e-6, "Phi mismatch at " + str(i))

    def TestQuarterBasisThetas(self):
        print("Begin Test: Theta angles for patches.")
        var aDirections = self.GetDirections(BSDFDirection.Incoming)
        var correctResults = List[Float64](0, 18, 18, 18, 18, 18, 18, 18, 18, 36, 36,
                                          36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 54,
                                          54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54,
                                          76.5, 76.5, 76.5, 76.5, 76.5, 76.5, 76.5, 76.5)
        var correctSize: Int = 41
        assert(correctSize == aDirections.size(), "Size mismatch")
        var thetaAngles = List[Float64]()
        for aPatch in aDirections:
            thetaAngles.append(aPatch.centerPoint().theta())
        for i in range(thetaAngles.size):
            assert(abs(thetaAngles[i] - correctResults[i]) < 1e-6, "Theta mismatch at " + str(i))

    def TestQuarterBasisLambdas(self):
        print("Begin Test: Theta angles for patches.")
        var aDirections = self.GetDirections(BSDFDirection.Incoming)
        var correctResults = List[Float64](
          0.076880244, 0.071328146, 0.071328146, 0.071328146, 0.071328146, 0.071328146, 0.071328146,
          0.071328146, 0.071328146, 0.076940910, 0.076940910, 0.076940910, 0.076940910, 0.076940910,
          0.076940910, 0.076940910, 0.076940910, 0.07694091,  0.07694091,  0.07694091,  0.07694091,
          0.076940910, 0.076940910, 0.076940910, 0.076940910, 0.076940910, 0.076940910, 0.076940910,
          0.076940910, 0.07694091,  0.07694091,  0.07694091,  0.07694091,  0.080938176, 0.080938176,
          0.080938176, 0.080938176, 0.080938176, 0.080938176, 0.080938176, 0.080938176)
        var correctSize: Int = 41
        assert(correctSize == aDirections.size(), "Size mismatch")
        var lambdaValues = List[Float64]()
        for aPatch in aDirections:
            lambdaValues.append(aPatch.lambda())
        for i in range(lambdaValues.size):
            assert(abs(lambdaValues[i] - correctResults[i]) < 1e-6, "Lambda mismatch at " + str(i))

def main():
    var test = TestBSDFQuarterBasis()
    test.TestQuarterBasisPhis()
    test.TestQuarterBasisThetas()
    test.TestQuarterBasisLambdas()
    print("All tests passed.")