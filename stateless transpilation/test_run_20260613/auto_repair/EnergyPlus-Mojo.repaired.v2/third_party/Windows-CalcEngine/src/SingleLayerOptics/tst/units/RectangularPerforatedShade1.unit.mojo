from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, Material, CBSDFHemisphere, BSDFBasis, CBSDFIntegrator
from WCECommon import Side, PropertySimple
from memory import Pointer, reference

struct TestRectangularPerforatedShade1:
    var m_Shade: Pointer[CBSDFLayer]

    def SetUp(inout self):
        let Tmat: Float64 = 0.0
        let Rfmat: Float64 = 0.7
        let Rbmat: Float64 = 0.7
        let minLambda: Float64 = 0.3
        let maxLambda: Float64 = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let x: Float64 = 19.05          # mm
        let y: Float64 = 19.05          # mm
        let thickness: Float64 = 0.6    # mm
        let xHole: Float64 = 3.175      # mm
        let yHole: Float64 = 6.35       # mm
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = Pointer.allocate[CBSDFLayer]()
        self.m_Shade.initialize(CBSDFLayer(CBSDFLayerMaker.getRectangularPerforatedLayer(
            aMaterial, aBSDF, x, y, thickness, xHole, yHole)))

    def GetShade(self, inout owning: Pointer[CBSDFLayer]): 
        owning = self.m_Shade

def testSolarProperties():
    print("Begin Test: Rectangular perforated cell - Solar properties.")
    var aShadePtr: Pointer[CBSDFLayer]
    var testFixture = TestRectangularPerforatedShade1()
    testFixture.SetUp()
    testFixture.GetShade(aShadePtr)
    let aShade: CBSDFLayer = aShadePtr.take()
    let aResults: CBSDFIntegrator = aShade.getResults()
    let tauDiff: Float64 = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert(abs(tauDiff - 0.041876313) <= 1e-6, "tauDiff mismatch")
    let RfDiff: Float64 = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert(abs(RfDiff - 0.670686365) <= 1e-6, "RfDiff mismatch")
    let theta: Int = 0
    let phi: Int = 0
    let tauDirHem: Float64 = aResults.DirHem(Side.Front, PropertySimple.T, theta, phi)
    assert(abs(tauDirHem - 0.055556) <= 1e-6, "tauDirHem mismatch")
    let RfDirHem: Float64 = aResults.DirHem(Side.Front, PropertySimple.R, theta, phi)
    assert(abs(RfDirHem - 0.661111) <= 1e-6, "RfDirHem mismatch")
    let aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    let size: Int = aT.size()
    var correctResults: List[Float64]
    correctResults.append(0.722625)
    correctResults.append(0.731048)
    correctResults.append(0.728881)
    correctResults.append(0.754961)
    correctResults.append(0.728881)
    correctResults.append(0.731048)
    correctResults.append(0.728881)
    correctResults.append(0.754961)
    correctResults.append(0.728881)
    correctResults.append(0.622917)
    correctResults.append(0.614362)
    correctResults.append(0.632505)
    correctResults.append(0.672486)
    correctResults.append(0.632505)
    correctResults.append(0.614362)
    correctResults.append(0.622917)
    correctResults.append(0.614362)
    correctResults.append(0.632505)
    correctResults.append(0.672486)
    correctResults.append(0.632505)
    correctResults.append(0.614362)
    correctResults.append(0.534246)
    correctResults.append(0.523031)
    correctResults.append(0.557403)
    correctResults.append(0.628150)
    correctResults.append(0.557403)
    correctResults.append(0.523031)
    correctResults.append(0.534246)
    correctResults.append(0.523031)
    correctResults.append(0.557403)
    correctResults.append(0.628150)
    correctResults.append(0.557403)
    correctResults.append(0.523031)
    correctResults.append(0.146104)
    correctResults.append(0.219651)
    correctResults.append(0.416249)
    correctResults.append(0.219651)
    correctResults.append(0.146104)
    correctResults.append(0.219651)
    correctResults.append(0.416249)
    correctResults.append(0.219651)
    var calculatedResults: List[Float64]
    for i in range(size):
        calculatedResults.append(aT[i, i])
    assert(len(correctResults) == len(calculatedResults), "size mismatch")
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) <= 1e-5, "matrix T mismatch at " + str(i))
    let aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.210438)
    correctResults.append(0.211198)
    correctResults.append(0.211233)
    correctResults.append(0.210818)
    correctResults.append(0.211233)
    correctResults.append(0.211198)
    correctResults.append(0.211233)
    correctResults.append(0.210818)
    correctResults.append(0.211233)
    correctResults.append(0.212138)
    correctResults.append(0.212284)
    correctResults.append(0.211973)
    correctResults.append(0.211288)
    correctResults.append(0.211973)
    correctResults.append(0.212284)
    correctResults.append(0.212138)
    correctResults.append(0.212284)
    correctResults.append(0.211973)
    correctResults.append(0.211288)
    correctResults.append(0.211973)
    correctResults.append(0.212284)
    correctResults.append(0.213658)
    correctResults.append(0.213850)
    correctResults.append(0.213261)
    correctResults.append(0.212048)
    correctResults.append(0.213261)
    correctResults.append(0.213850)
    correctResults.append(0.213658)
    correctResults.append(0.213850)
    correctResults.append(0.213261)
    correctResults.append(0.212048)
    correctResults.append(0.213261)
    correctResults.append(0.213850)
    correctResults.append(0.220182)
    correctResults.append(0.218856)
    correctResults.append(0.215310)
    correctResults.append(0.218856)
    correctResults.append(0.220182)
    correctResults.append(0.218856)
    correctResults.append(0.215310)
    correctResults.append(0.218856)
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aRf[i, i])
    assert(len(correctResults) == len(calculatedResults), "size mismatch")
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) <= 1e-5, "matrix Rf mismatch at " + str(i))

def main():
    testSolarProperties()
<<<FILE>>>