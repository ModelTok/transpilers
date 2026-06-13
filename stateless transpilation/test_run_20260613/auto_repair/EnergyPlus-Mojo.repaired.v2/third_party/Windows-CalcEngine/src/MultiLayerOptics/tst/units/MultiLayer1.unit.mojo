from WCEMultiLayerOptics import CMultiLayerScattered
from WCESingleLayerOptics import CScatteringSurface, CScatteringLayer
from WCECommon import Side, Scattering, ScatteringSimple, PropertySimple

class TestMultiLayer1:
    var m_Layer: Pointer[CMultiLayerScattered]

    def __init__(inout self):
        self.m_Layer = Pointer[CMultiLayerScattered]()

    def SetUp(inout self):
        var aFront = CScatteringSurface(0.06, 0.04, 0.46, 0.12, 0.46, 0.52)
        var aBack = CScatteringSurface(0.11, 0.26, 0.34, 0.19, 0.64, 0.22)
        var aLayer1 = CScatteringLayer(aFront, aBack)
        aFront = CScatteringSurface(0.1, 0.05, 0.48, 0.26, 0.56, 0.34)
        aBack = CScatteringSurface(0.15, 0, 0.38, 0.19, 0.49, 0.39)
        var aLayer2 = CScatteringLayer(aFront, aBack)
        aFront = CScatteringSurface(0.08, 0.05, 0.46, 0.23, 0.46, 0.52)
        aBack = CScatteringSurface(0.13, 0.25, 0.38, 0.19, 0.64, 0.22)
        var aLayer3 = CScatteringLayer(aFront, aBack)
        self.m_Layer = CMultiLayerScattered.create([aLayer1, aLayer2, aLayer3])

    def getLayer(inout self) -> Pointer[CMultiLayerScattered]:
        return self.m_Layer

def TestTripleLayerFront():
    # SCOPED_TRACE("Begin Test: Test triple layer with scattering properties (Front).")
    var minLambda: Float64 = 0.3
    var maxLambda: Float64 = 2.5
    var fixture = TestMultiLayer1()
    fixture.SetUp()
    var aLayer = fixture.getLayer()
    var aSide = Side.Front
    var aScattering = Scattering.DirectDirect
    var Tf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tf - 0.000486418) < 1e-6)
    var Rf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rf - 0.040339429) < 1e-6)
    aScattering = Scattering.DirectDiffuse
    Tf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tf - 0.190095209) < 1e-6)
    Rf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rf - 0.312631104) < 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    Tf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tf - 0.167799034) < 1e-6)
    Rf = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rf - 0.692483233) < 1e-6)

def TestTripleLayerBack():
    # SCOPED_TRACE("Begin Test: Test triple layer with scattering properties (Back).")
    var minLambda: Float64 = 0.3
    var maxLambda: Float64 = 2.5
    var fixture = TestMultiLayer1()
    fixture.SetUp()
    var aLayer = fixture.getLayer()
    var aSide = Side.Back
    var aScattering = Scattering.DirectDirect
    var Tb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tb - 0.002173682) < 1e-6)
    var Rb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rb - 0.250041102) < 1e-6)
    aScattering = Scattering.DirectDiffuse
    Tb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tb - 0.219867246) < 1e-6)
    Rb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rb - 0.316344401) < 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    Tb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.T, aSide, aScattering)
    assert(abs(Tb - 0.284211597) < 1e-6)
    Rb = aLayer.value.getPropertySimple(minLambda, maxLambda, PropertySimple.R, aSide, aScattering)
    assert(abs(Rb - 0.395593248) < 1e-6)

def TestFrontSideAbsorptances():
    # SCOPED_TRACE("Begin Test: Triple pane layer by layer absroptances (Front Side).")
    var minLambda: Float64 = 0.3
    var maxLambda: Float64 = 2.5
    var fixture = TestMultiLayer1()
    fixture.SetUp()
    var aLayer = fixture.getLayer()
    var aSide = Side.Front
    var aScattering = ScatteringSimple.Direct
    var Af1_dir = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 1, aSide, aScattering)
    assert(abs(Af1_dir - 0.362217125) < 1e-6)
    var Af2_dir = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 2, aSide, aScattering)
    assert(abs(Af2_dir - 0.08499287) < 1e-6)
    var Af3_dir = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 3, aSide, aScattering)
    assert(abs(Af3_dir - 0.009237846) < 1e-6)
    var Aftotal_dir = aLayer.value.getAbsorptance(aSide, aScattering)
    assert(abs(Aftotal_dir - 0.456447841) < 1e-6)
    aScattering = ScatteringSimple.Diffuse
    var Af1_dif = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 1, aSide, aScattering)
    assert(abs(Af1_dif - 0.057730707) < 1e-6)
    var Af2_dif = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 2, aSide, aScattering)
    assert(abs(Af2_dif - 0.074691415) < 1e-6)
    var Af3_dif = aLayer.value.getAbsorptanceLayer(minLambda, maxLambda, 3, aSide, aScattering)
    assert(abs(Af3_dif - 0.00729561) < 1e-6)
    var Aftotal_dif = aLayer.value.getAbsorptance(aSide, aScattering)
    assert(abs(Aftotal_dif - 0.139717732) < 1e-6)

def TestBackSideAbsorptances():
    # SCOPED_TRACE("Begin Test: Triple pane layer by layer absroptances (Back Side).")
    var fixture = TestMultiLayer1()
    fixture.SetUp()
    var aLayer = fixture.getLayer()
    var aSide = Side.Back
    var aScattering = ScatteringSimple.Direct
    var Ab1_dir = aLayer.value.getAbsorptanceLayer(1, aSide, aScattering)
    assert(abs(Ab1_dir - 0.048602329) < 1e-6)
    var Ab2_dir = aLayer.value.getAbsorptanceLayer(2, aSide, aScattering)
    assert(abs(Ab2_dir - 0.1073958) < 1e-6)
    var Ab3_dir = aLayer.value.getAbsorptanceLayer(3, aSide, aScattering)
    assert(abs(Ab3_dir - 0.05557544) < 1e-6)
    var Abtotal_dir = aLayer.value.getAbsorptance(aSide, aScattering)
    assert(abs(Abtotal_dir - 0.211573569) < 1e-6)
    aScattering = ScatteringSimple.Diffuse
    var Ab1_dif = aLayer.value.getAbsorptanceLayer(1, aSide, aScattering)
    assert(abs(Ab1_dif - 0.062171287) < 1e-6)
    var Ab2_dif = aLayer.value.getAbsorptanceLayer(2, aSide, aScattering)
    assert(abs(Ab2_dif - 0.110389379) < 1e-6)
    var Ab3_dif = aLayer.value.getAbsorptanceLayer(3, aSide, aScattering)
    assert(abs(Ab3_dif - 0.147634489) < 1e-6)
    var Abtotal_dif = aLayer.value.getAbsorptance(aSide, aScattering)
    assert(abs(Abtotal_dif - 0.320195155) < 1e-6)

def main():
    TestTripleLayerFront()
    TestTripleLayerBack()
    TestFrontSideAbsorptances()
    TestBackSideAbsorptances()