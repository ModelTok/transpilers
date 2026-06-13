from memory import Pointer, shared_ptr, make_shared
from WCEMultiLayerOptics import CEquivalentScatteringLayer
from WCESingleLayerOptics import CScatteringSurface, CScatteringLayer
from WCECommon import Side, Scattering, PropertySimple

class TestEquivalentLayerWithScattering2:
    var m_EqLayerFront: shared_ptr[CEquivalentScatteringLayer]
    var m_EqLayerBack: shared_ptr[CEquivalentScatteringLayer]

    def __init__(inout self):
        self.m_EqLayerFront = shared_ptr[CEquivalentScatteringLayer]()
        self.m_EqLayerBack = shared_ptr[CEquivalentScatteringLayer]()

    def SetUp(inout self):
        var f1 = CScatteringSurface(0.08, 0.05, 0.46, 0.23, 0.46, 0.52)
        var b1 = CScatteringSurface(0.13, 0.25, 0.38, 0.19, 0.64, 0.22)
        var aLayer1 = CScatteringLayer(f1, b1)
        var f2 = CScatteringSurface(0.1, 0.05, 0.48, 0.26, 0.56, 0.34)
        var b2 = CScatteringSurface(0.15, 0.0, 0.38, 0.19, 0.49, 0.39)
        var aLayer2 = CScatteringLayer(f2, b2)
        var f3 = CScatteringSurface(0.08, 0.05, 0.46, 0.23, 0.46, 0.52)
        var b3 = CScatteringSurface(0.13, 0.25, 0.38, 0.19, 0.64, 0.22)
        var aLayer3 = CScatteringLayer(f3, b3)
        self.m_EqLayerFront = make_shared[CEquivalentScatteringLayer](aLayer1)
        self.m_EqLayerFront.addLayer(aLayer2, Side.Back)
        self.m_EqLayerFront.addLayer(aLayer3, Side.Back)
        self.m_EqLayerBack = make_shared[CEquivalentScatteringLayer](aLayer3)
        self.m_EqLayerBack.addLayer(aLayer2, Side.Front)
        self.m_EqLayerBack.addLayer(aLayer1, Side.Front)

    def getBack(self) -> shared_ptr[CEquivalentScatteringLayer]:
        return self.m_EqLayerBack

    def getFront(self) -> shared_ptr[CEquivalentScatteringLayer]:
        return self.m_EqLayerFront

def TestTripleLayerBack():
    var testObj = TestEquivalentLayerWithScattering2()
    testObj.SetUp()
    # SCOPED_TRACE("Begin Test: Equivalent layer transmittance and reflectances (direct-direct, direct-diffuse and diffuse-diffuse")
    var doubleLayer = testObj.getBack().value()
    var Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDirect)
    # EXPECT_NEAR(0.000648224, Tf, 1e-6)
    var Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDirect)
    # EXPECT_NEAR(0.050534583, Rf, 1e-6)
    var Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDirect)
    # EXPECT_NEAR(0.002567576, Tb, 1e-6)
    var Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDirect)
    # EXPECT_NEAR(0.250039501, Rb, 1e-6)
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.167799034, Tf, 1e-6)
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.692483233, Rf, 1e-6)
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.284211597, Tb, 1e-6)
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.395593248, Rb, 1e-6)
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.197511986, Tf, 1e-6)
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.429497739, Rf, 1e-6)
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.220590948, Tb, 1e-6)
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.316271007, Rb, 1e-6)

def TestTripleLayerFront():
    var testObj = TestEquivalentLayerWithScattering2()
    testObj.SetUp()
    # SCOPED_TRACE("Begin Test: Equivalent layer transmittance and reflectances (direct-direct, direct-diffuse and diffuse-diffuse")
    var doubleLayer = testObj.getFront().value()
    var Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDirect)
    # EXPECT_NEAR(0.000648224, Tf, 1e-6)
    var Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDirect)
    # EXPECT_NEAR(0.050534583, Rf, 1e-6)
    var Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDirect)
    # EXPECT_NEAR(0.002567576, Tb, 1e-6)
    var Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDirect)
    # EXPECT_NEAR(0.250039501, Rb, 1e-6)
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.167799034, Tf, 1e-6)
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.692483233, Rf, 1e-6)
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.284211597, Tb, 1e-6)
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse)
    # EXPECT_NEAR(0.395593248, Rb, 1e-6)
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.197511986, Tf, 1e-6)
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.429497739, Rf, 1e-6)
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.220590948, Tb, 1e-6)
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDiffuse)
    # EXPECT_NEAR(0.316271007, Rb, 1e-6)