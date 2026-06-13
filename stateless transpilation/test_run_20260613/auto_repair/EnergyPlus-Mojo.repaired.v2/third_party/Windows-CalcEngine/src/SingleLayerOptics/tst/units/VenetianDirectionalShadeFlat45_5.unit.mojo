from memory import shared_ptr
from WCECommon import *
from WCESingleLayerOptics import *
from testing import *

class TestVenetianDirectionalShadeFlat45_5(Test):
    var m_Shade: shared_ptr[CBSDFLayer]

    def SetUp():
        let Tmat = 0.2
        let Rfmat = 0.6
        let Rbmat = 0.6
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.016
        let slatSpacing = 0.012
        let slatTiltAngle = 45
        let curvatureRadius = 0
        let numOfSlatSegments: size = 5
        let aDistribution = DistributionMethod.DirectionalDiffuse
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial,
                                                    aBSDF,
                                                    slatWidth,
                                                    slatSpacing,
                                                    slatTiltAngle,
                                                    curvatureRadius,
                                                    numOfSlatSegments,
                                                    aDistribution,
                                                    True)

    def GetShade() -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - single band properties.")
    let aShade = TestVenetianDirectionalShadeFlat45_5().GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    EXPECT_NEAR(0.38194085830991792, tauDiff, 1e-6)
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    EXPECT_NEAR(0.37327866349094058, RfDiff, 1e-6)
    let aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    let size = aT.size()
    var correctResults = List[Float64]()
    correctResults.append(0.836275880754398400)
    correctResults.append(0.894179918528413050)
    correctResults.append(3.893461019742295200)
    correctResults.append(5.138660438286230200)
    correctResults.append(3.893461019742295200)
    correctResults.append(0.894179918528413050)
    correctResults.append(0.088417695248090525)
    correctResults.append(0.088474910851309277)
    correctResults.append(0.088417695248090525)
    correctResults.append(0.835689344595229480)
    correctResults.append(5.232171511989904800)
    correctResults.append(8.466077293836708200)
    correctResults.append(9.653035509249107800)
    correctResults.append(8.466077293836708200)
    correctResults.append(5.232171511989904800)
    correctResults.append(0.835689344595229480)
    correctResults.append(0.083366975858566325)
    correctResults.append(0.061722153521553885)
    correctResults.append(0.058886242955618555)
    correctResults.append(0.061722153521553885)
    correctResults.append(0.083366975858566325)
    correctResults.append(0.835689344595230370)
    correctResults.append(9.185161324998347300)
    correctResults.append(10.64790998036374100)
    correctResults.append(8.398011303285587200)
    correctResults.append(10.64790998036374100)
    correctResults.append(9.185161324998347300)
    correctResults.append(0.835689344595230370)
    correctResults.append(0.059735559077405055)
    correctResults.append(0.027508020796803857)
    correctResults.append(0.024511810701834273)
    correctResults.append(0.027508020796803857)
    correctResults.append(0.059735559077405055)
    correctResults.append(0.798979733486533950)
    correctResults.append(0.093292300851503973)
    correctResults.append(0.079357844380076134)
    correctResults.append(0.093292300851503973)
    correctResults.append(0.798979733486533950)
    correctResults.append(0.017310537462612144)
    correctResults.append(0.018209736057913754)
    correctResults.append(0.017310537462612144)
    EXPECT_EQ(correctResults.size(), aT.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aT(i, i), 1e-6)
    let aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.165903843794496520)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.127956545925703070)
    correctResults.append(0.117843124975481240)
    correctResults.append(0.127956545925703070)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.134906386909191520)
    correctResults.append(0.117926403568254980)
    correctResults.append(0.134906386909191520)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.108225759077810250)
    correctResults.append(0.060355829056359361)
    correctResults.append(0.046206747713723524)
    correctResults.append(0.060355829056359361)
    correctResults.append(0.108225759077810250)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.111117195342986560)
    correctResults.append(0.064266151443683694)
    correctResults.append(0.047276114717840656)
    correctResults.append(0.064266151443683694)
    correctResults.append(0.111117195342986560)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.051783295867258577)
    correctResults.append(0.014108177373773591)
    correctResults.append(0.027952498113038276)
    correctResults.append(0.014108177373773591)
    correctResults.append(0.051783295867258577)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.053960092644205690)
    correctResults.append(0.016014184991125564)
    correctResults.append(0.030913799813821443)
    correctResults.append(0.016014184991125564)
    correctResults.append(0.053960092644205690)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.107196920174651770)
    correctResults.append(0.181881555366362770)
    correctResults.append(0.107196920174651770)
    correctResults.append(0.165903843794496520)
    correctResults.append(0.128611259539473550)
    correctResults.append(0.180142928161266060)
    correctResults.append(0.128611259539473550)
    EXPECT_EQ(correctResults.size(), aRf.size())
    for i in range(size):
        EXPECT_NEAR(correctResults[i], aRf(i, i), 1e-5)