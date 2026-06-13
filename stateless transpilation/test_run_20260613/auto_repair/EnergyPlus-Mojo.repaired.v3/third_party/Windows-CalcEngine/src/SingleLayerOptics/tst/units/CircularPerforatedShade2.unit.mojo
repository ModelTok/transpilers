from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, CBSDFIntegrator, Side, PropertySimple
from WCECommon import Material, CBSDFHemisphere, BSDFBasis
from FenestrationCommon import Side, PropertySimple

struct TestCircularPerforatedShade2:
    var m_Shade: CBSDFLayer

    def set_up(self):
        const Tmat = 0.2
        const Rfmat = 0.8
        const Rbmat = 0.8
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const x = 0.0225           # m
        const y = 0.0381           # m
        const thickness = 0.0050   # m
        const radius = 0.0         # m
        const aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getCircularPerforatedLayer(aMaterial, aBSDF, x, y, thickness, radius)

    def get_shade(self) -> CBSDFLayer:
        return self.m_Shade

def TestSolarProperties():
    # SCOPED_TRACE("Begin Test: Circular perforated cell - Solar properties.")
    var aShade = TestCircularPerforatedShade2()
    aShade.set_up()
    var aShadeLayer = aShade.get_shade()
    var aResults = aShadeLayer.getResults()
    const tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert(abs(tauDiff - 0.2) < 1e-6)
    const RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert(abs(RfDiff - 0.8) < 1e-6)
    const RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
    assert(abs(RbDiff - 0.8) < 1e-6)
    var aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    var size = aT.size()
    var correctResults = [
        0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
        0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
        0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
        0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
        0.063662, 0.063662, 0.063662, 0.063662, 0.063662]
    var calculatedResults = List[Float64]()
    for i in range(size):
        calculatedResults.append(aT[i, i])
    assert(correctResults.size() == calculatedResults.size())
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) < 1e-5)

    correctResults = [0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
                      0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
                      0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
                      0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
                      0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662,
                      0.063662, 0.063662, 0.063662, 0.063662, 0.063662, 0.063662]
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aT[0, i])
    assert(correctResults.size() == calculatedResults.size())
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) < 1e-5)

    var aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults = [0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648]
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aRf[0, i])
    assert(correctResults.size() == calculatedResults.size())
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) < 1e-5)

    var aRb = aResults.getMatrix(Side.Back, PropertySimple.R)
    correctResults = [0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648,
                      0.254648, 0.254648, 0.254648, 0.254648, 0.254648, 0.254648]
    calculatedResults.clear()
    for i in range(size):
        calculatedResults.append(aRb[0, i])
    assert(correctResults.size() == calculatedResults.size())
    for i in range(size):
        assert(abs(correctResults[i] - calculatedResults[i]) < 1e-5)