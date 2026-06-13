from memory import shared_ptr
from WCESingleLayerOptics import CBSDFLayer, CBSDFIntegrator, CBSDFLayerMaker, CBSDFHemisphere, BSDFBasis, DistributionMethod, Material
from WCECommon import Side, PropertySimple
from gtest import Test, EXPECT_NEAR, EXPECT_EQ, SCOPED_TRACE

class TestVenetianDirectionalShadeFlat0_3(Test):
    var m_Shade: shared_ptr[CBSDFLayer]

    def SetUp(self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.016
        let slatSpacing = 0.010
        let slatTiltAngle = 0
        let curvatureRadius = 0
        let numOfSlatSegments: size_t = 5
        let aDistribution = DistributionMethod.DirectionalDiffuse
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial, aBSDF, slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments, aDistribution, True)

    def GetShade(self) -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - solar properties.")
    let aShade = TestVenetianDirectionalShadeFlat0_3().GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    EXPECT_NEAR(0.48775116654942097, tauDiff, 1e-6)
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    EXPECT_NEAR(0.22509839868274970, RfDiff, 1e-6)
    var aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    let size = aT.size()
    var correctResults = List[Float64]()
    correctResults.append(13.00724272523622500)
    correctResults.append(14.01971111841941000)
    correctResults.append(8.879333707559864000)
    correctResults.append(6.757930491107369900)
    correctResults.append(8.879333707559864000)
    correctResults.append(14.01971111841941000)
    correctResults.append(8.879333707559864000)
    correctResults.append(6.757930491107371700)
    correctResults.append(8.879333707559864000)
    correctResults.append(12.99698697545699000)
    correctResults.append(5.476030728175789600)
    correctResults.append(0.098218010371277989)
    correctResults.append(0.095832434781168180)
    correctResults.append(0.098218010371277989)
    correctResults.append(5.476030728175789600)
    correctResults.append(12.99698697545699000)
    correctResults.append(5.476030728175789600)
    correctResults.append(0.098218010371277989)
    correctResults.append(0.095832434781168138)
    correctResults.append(0.098218010371277989)
    correctResults.append(5.476030728175789600)
    correctResults.append(12.99698697545700400)
    correctResults.append(0.094990521299407105)
    correctResults.append(0.062476409862337726)
    correctResults.append(0.052827014930858306)
    correctResults.append(0.062476409862337726)
    correctResults.append(0.094990521299407105)
    correctResults.append(12.99698697545700400)
    correctResults.append(0.094990521299407105)
    correctResults.append(0.062476409862337781)
    correctResults.append(0.052827014930858347)
    correctResults.append(0.062476409862337781)
    correctResults.append(0.094990521299407105)
    correctResults.append(12.35510909608257400)
    correctResults.append(0.034092954478813497)
    correctResults.append(0.026306763651200261)
    correctResults.append(0.034092954478813497)
    correctResults.append(12.35510909608257400)
    correctResults.append(0.034092954478813518)
    correctResults.append(0.026306763651200268)
    correctResults.append(0.034092954478813518)
    EXPECT_EQ(correctResults.size(), aT.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aT[i][i], 1e-6)
    var aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.000000000000000000)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.013333908639926589)
    correctResults.append(0.026667817279853189)
    correctResults.append(0.013333908639926589)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.013333908639926589)
    correctResults.append(0.026667817279853193)
    correctResults.append(0.013333908639926589)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.033334771599816487)
    correctResults.append(0.098232428791164006)
    correctResults.append(0.101397330494051680)
    correctResults.append(0.098232428791164006)
    correctResults.append(0.033334771599816487)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.033334771599816487)
    correctResults.append(0.098232428791163950)
    correctResults.append(0.101397330494051680)
    correctResults.append(0.098232428791163950)
    correctResults.append(0.033334771599816487)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.097542640608995437)
    correctResults.append(0.116785354563414950)
    correctResults.append(0.125238941198961200)
    correctResults.append(0.116785354563414950)
    correctResults.append(0.097542640608995437)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.097542640608995465)
    correctResults.append(0.116785354563414910)
    correctResults.append(0.125238941198961260)
    correctResults.append(0.116785354563414910)
    correctResults.append(0.097542640608995465)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.180352627561802150)
    correctResults.append(0.147864609583900520)
    correctResults.append(0.180352627561802150)
    correctResults.append(0.000000000000000000)
    correctResults.append(0.180352627561802200)
    correctResults.append(0.147864609583900520)
    correctResults.append(0.180352627561802200)
    EXPECT_EQ(correctResults.size(), aRf.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aRf[i][i], 1e-6)