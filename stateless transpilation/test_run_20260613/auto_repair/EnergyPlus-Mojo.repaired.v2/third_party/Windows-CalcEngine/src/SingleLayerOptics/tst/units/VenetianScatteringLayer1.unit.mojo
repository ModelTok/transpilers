from ......WCESingleLayerOptics import CScatteringLayer
from .........WCECommon import Material, Side, Scattering, ScatteringSimple, PropertySimple, DistributionMethod

struct TestVenetianScatteringLayer1:
    var m_Shade: CScatteringLayer

    def SetUp(inout self):
        let Tmat: Float64 = 0.1
        let Rfmat: Float64 = 0.7
        let Rbmat: Float64 = 0.7
        let minLambda: Float64 = 0.3
        let maxLambda: Float64 = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth: Float64 = 0.010
        let slatSpacing: Float64 = 0.010
        let slatTiltAngle: Int = 45
        let curvatureRadius: Int = 0
        let numOfSlatSegments: Int = 1
        let aDistribution: DistributionMethod = DistributionMethod.UniformDiffuse
        self.m_Shade = CScatteringLayer.createVenetianLayer(
            aMaterial,
            slatWidth,
            slatSpacing,
            slatTiltAngle,
            curvatureRadius,
            numOfSlatSegments,
            aDistribution
        )

    def GetShade(self) -> CScatteringLayer:
        return self.m_Shade

@test
def TestVenetian1():
    # SCOPED_TRACE(
    #   "Begin Test: Venetian scattering layer (Flat, 45 degrees slats) - 0 deg incident.")
    let minLambda: Float64 = 0.3
    let maxLambda: Float64 = 2.5
    var aTest: TestVenetianScatteringLayer1
    aTest.SetUp()
    let aShade = aTest.GetShade()
    let aSide: Side = Side.Front
    var T_dir_dir: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DirectDirect
    )
    assert abs(T_dir_dir - 0.292893) < 1e-6
    var R_dir_dir: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DirectDirect
    )
    assert abs(R_dir_dir - 0.0) < 1e-6
    var T_dir_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DirectDiffuse
    )
    assert abs(T_dir_dif - 0.162897) < 1e-6
    var R_dir_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DirectDiffuse
    )
    assert abs(R_dir_dif - 0.356835) < 1e-6
    var T_dif_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DiffuseDiffuse
    )
    assert abs(T_dif_dif - 0.486233) < 1e-6
    var R_dif_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DiffuseDiffuse
    )
    assert abs(R_dif_dif - 0.329593) < 1e-6
    var A_dir: Float64 = aShade.getAbsorptance(aSide, ScatteringSimple.Direct)
    assert abs(A_dir - 0.187375) < 1e-6
    var A_dif: Float64 = aShade.getAbsorptance(aSide, ScatteringSimple.Diffuse)
    assert abs(A_dif - 0.184173) < 1e-6

@test
def TestVenetian2():
    # SCOPED_TRACE("Begin Test: Venetian scattering layer (Flat, 45 degrees slats) - Theta = 45 deg,"
    #              " Phi = 45 incident.")
    let minLambda: Float64 = 0.3
    let maxLambda: Float64 = 2.5
    var aTest: TestVenetianScatteringLayer1
    aTest.SetUp()
    let aShade = aTest.GetShade()
    let aSide: Side = Side.Front
    let Theta: Float64 = 45
    let Phi: Float64 = 90
    var T_dir_dir: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DirectDirect, Theta, Phi
    )
    assert abs(T_dir_dir - 1.0) < 1e-6
    var R_dir_dir: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DirectDirect, Theta, Phi
    )
    assert abs(R_dir_dir - 0.0) < 1e-6
    var T_dir_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DirectDiffuse, Theta, Phi
    )
    assert abs(T_dir_dif - 0.0) < 1e-6
    var R_dir_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DirectDiffuse, Theta, Phi
    )
    assert abs(R_dir_dif - 0.0) < 1e-6
    var T_dif_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.T, aSide, Scattering.DiffuseDiffuse, Theta, Phi
    )
    assert abs(T_dif_dif - 0.486233) < 1e-6
    var R_dif_dif: Float64 = aShade.getPropertySimple(
        minLambda, maxLambda, PropertySimple.R, aSide, Scattering.DiffuseDiffuse, Theta, Phi
    )
    assert abs(R_dif_dif - 0.329593) < 1e-6
    var A_dir: Float64 = aShade.getAbsorptance(aSide, ScatteringSimple.Direct, Theta, Phi)
    assert abs(A_dir - 0.0) < 1e-6
    var A_dif: Float64 = aShade.getAbsorptance(aSide, ScatteringSimple.Diffuse, Theta, Phi)
    assert abs(A_dif - 0.184173) < 1e-6