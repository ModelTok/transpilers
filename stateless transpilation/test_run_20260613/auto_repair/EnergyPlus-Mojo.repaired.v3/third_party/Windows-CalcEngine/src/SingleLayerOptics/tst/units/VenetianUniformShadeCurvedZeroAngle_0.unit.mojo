from std.memory import shared_ptr
from WCECommon import Side, PropertySimple, BSDFBasis, DistributionMethod
from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, CBSDFIntegrator, CBSDFHemisphere, Material

class TestVenetianUniformShadeCurvedZeroAngle_0:
    var m_Shade: shared_ptr[CBSDFLayer]

    def SetUp(self):
        let Tmat = 0.0
        let Rfmat = 0.1
        let Rbmat = 0.1
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.0148
        let slatSpacing = 0.0127
        let slatTiltAngle = 0
        let curvatureRadius = 0.03313057
        let numOfSlatSegments: Int = 5
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial, aBSDF, slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments, DistributionMethod.UniformDiffuse, True)

    def GetShade(self) -> shared_ptr[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian shade (Curved, -45 degrees slats).")
    let aShade = TestVenetianUniformShadeCurvedZeroAngle_0()
    aShade.SetUp()
    let aResults = aShade.GetShade().getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert abs(tauDiff - 0.422932) < 1e-6
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert abs(RfDiff - 0.020573) < 1e-6
    let theta: Float64 = 0.0
    let phi: Float64 = 0.0
    let tauDir = aResults.DirDir(Side.Front, PropertySimple.T, theta, phi)
    assert abs(tauDir - 0.936759) < 1e-6
    let rhoDir = aResults.DirDir(Side.Front, PropertySimple.R, theta, phi)
    assert abs(rhoDir - 7.583e-05) < 1e-6
    let absIR = aResults.Abs(Side.Front, theta, phi)
    assert abs(absIR - 0.059455) < 1e-6