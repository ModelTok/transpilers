from WCESingleLayerOptics import CBSDFLayer, CBSDFHemisphere, Material, CBSDFLayerMaker, CBSDFIntegrator
from WCECommon import Side, PropertySimple, BSDFBasis

class TestCircularPerforatedShadeNFRC18000:
    var m_Shade: CBSDFLayer

    def __init__(self):
        self.m_Shade = None  # placeholder, will be set in SetUp

    def SetUp(self):
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        let Tmat = 0.0
        let Rfmat = 0.137
        let Rbmat = 0.16
        let minLambda = 5.0
        let maxLambda = 100.0
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let thickness_31111 = 0.00023
        let x = 0.00169        # m
        let y = 0.00169        # m
        let radius = 0.00058   # m
        self.m_Shade = CBSDFLayerMaker.getCircularPerforatedLayer(
            aMaterial, aBSDF, x, y, thickness_31111, radius
        )

    def GetShade(self) -> CBSDFLayer:
        return self.m_Shade

def TestSolarProperties():
    # SCOPED_TRACE("Begin Test: Circular perforated cell - Solar properties.")
    let aShade = TestCircularPerforatedShadeNFRC18000()
    aShade.SetUp()
    let shade = aShade.GetShade()
    let aResults = shade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert abs(tauDiff - 0.257367) < 1e-6
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert abs(RfDiff - 0.101741) < 1e-6
    let RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
    assert abs(RbDiff - 0.118821) < 1e-6
    let absfDiff = aResults.AbsDiffDiff(FenestrationCommon.Side.Front)
    assert abs(absfDiff - 0.640892) < 1e-6
    let absbDiff = aResults.AbsDiffDiff(FenestrationCommon.Side.Back)
    assert abs(absbDiff - 0.623812) < 1e-6

def main():
    TestSolarProperties()