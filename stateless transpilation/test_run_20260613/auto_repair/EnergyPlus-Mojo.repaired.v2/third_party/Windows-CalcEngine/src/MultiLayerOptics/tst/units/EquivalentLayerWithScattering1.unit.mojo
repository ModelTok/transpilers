from memory import Pointer
from ......WCEMultiLayerOptics import CEquivalentScatteringLayer
from ......SingleLayerOptics.WCESingleLayerOptics import CScatteringSurface, CScatteringLayer
from ......Common.WCECommon import Side, Scattering, PropertySimple

struct TestEquivalentLayerWithScattering1:
    var m_DoubleBack: Pointer[CEquivalentScatteringLayer]
    var m_DoubleFront: Pointer[CEquivalentScatteringLayer]

    def __init__(inout self):
        self.m_DoubleBack = Pointer[CEquivalentScatteringLayer]()
        self.m_DoubleFront = Pointer[CEquivalentScatteringLayer]()

    def SetUp(inout self):
        var f1 = CScatteringSurface(0.08, 0.05, 0.46, 0.23, 0.46, 0.52)
        var b1 = CScatteringSurface(0.13, 0.25, 0.38, 0.19, 0.64, 0.22)
        var aLayer1 = CScatteringLayer(f1, b1)
        var f2 = CScatteringSurface(0.1, 0.05, 0.48, 0.26, 0.56, 0.34)
        var b2 = CScatteringSurface(0.15, 0.0, 0.38, 0.19, 0.49, 0.39)
        var aLayer2 = CScatteringLayer(f2, b2)
        self.m_DoubleBack = Pointer[CEquivalentScatteringLayer](CEquivalentScatteringLayer(aLayer1))
        self.m_DoubleBack[].addLayer(aLayer2, Side.Back)
        self.m_DoubleFront = Pointer[CEquivalentScatteringLayer](CEquivalentScatteringLayer(aLayer1))
        self.m_DoubleFront[].addLayer(aLayer2, Side.Front)

    def getDoubleBack(self) -> Pointer[CEquivalentScatteringLayer]:
        return self.m_DoubleBack

    def getDoubleFront(self) -> Pointer[CEquivalentScatteringLayer]:
        return self.m_DoubleFront

@test
def TestLayerAtBackSide():
    # SCOPED_TRACE("Begin Test: Equivalent layer transmittance and reflectances (direct-direct, "
    #              "direct-diffuse and diffuse-diffuse")
    var fixture = TestEquivalentLayerWithScattering1()
    fixture.SetUp()
    var doubleLayer = fixture.getDoubleBack()[]
    var Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDirect)
    assert abs(Tf - 0.008101266) < 1e-6
    var Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDirect)
    assert abs(Rf - 0.050526582) < 1e-6
    var Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDirect)
    assert abs(Tb - 0.019746835) < 1e-6
    var Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDirect)
    assert abs(Rb - 0.003797468) < 1e-6
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    assert abs(Tf - 0.278426286) < 1e-6
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    assert abs(Rf - 0.6281885) < 1e-6
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse)
    assert abs(Tb - 0.33895374) < 1e-6
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse)
    assert abs(Rb - 0.455248595) < 1e-6
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDiffuse)
    assert abs(Tf - 0.32058299) < 1e-6
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDiffuse)
    assert abs(Rf - 0.354479119) < 1e-6
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDiffuse)
    assert abs(Tb - 0.334201295) < 1e-6
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDiffuse)
    assert abs(Rb - 0.27761223) < 1e-6

@test
def TestLayerAtFrontSide():
    # SCOPED_TRACE("Begin Test: Equivalent layer transmittance and reflectances (direct-direct, "
    #              "direct-diffuse and diffuse-diffuse")
    var fixture = TestEquivalentLayerWithScattering1()
    fixture.SetUp()
    var doubleLayer = fixture.getDoubleFront()[]
    var Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDirect)
    assert abs(Tf - 0.008) < 1e-6
    var Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDirect)
    assert abs(Rf - 0.05075) < 1e-6
    var Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDirect)
    assert abs(Tb - 0.0195) < 1e-6
    var Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDirect)
    assert abs(Rb - 0.25) < 1e-6
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    assert abs(Tf - 0.323130958) < 1e-6
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    assert abs(Rf - 0.518986453) < 1e-6
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse)
    assert abs(Tb - 0.393376819) < 1e-6
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse)
    assert abs(Rb - 0.364024084) < 1e-6
    Tf = doubleLayer.getPropertySimple(PropertySimple.T, Side.Front, Scattering.DirectDiffuse)
    assert abs(Tf - 0.328693427) < 1e-6
    Rf = doubleLayer.getPropertySimple(PropertySimple.R, Side.Front, Scattering.DirectDiffuse)
    assert abs(Rf - 0.429757577) < 1e-6
    Tb = doubleLayer.getPropertySimple(PropertySimple.T, Side.Back, Scattering.DirectDiffuse)
    assert abs(Tb - 0.290862067) < 1e-6
    Rb = doubleLayer.getPropertySimple(PropertySimple.R, Side.Back, Scattering.DirectDiffuse)
    assert abs(Rb - 0.289766683) < 1e-6