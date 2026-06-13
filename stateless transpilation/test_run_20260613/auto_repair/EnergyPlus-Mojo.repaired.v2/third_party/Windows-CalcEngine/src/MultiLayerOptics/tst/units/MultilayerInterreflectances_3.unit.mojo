from WCEMultiLayerOptics import CInterRef, EnergyFlow, Side, Scattering, ScatteringSimple
from WCESingleLayerOptics import CScatteringSurface
from WCECommon import CScatteringLayer

def expect_near(actual: Float64, expected: Float64, tolerance: Float64):
    """Approximate equality check with trace."""
    if abs(actual - expected) > tolerance:
        print("FAIL: expected", expected, "got", actual, "tolerance", tolerance)
        assert false

struct TestMultilayerInterreflectances_3:
    var m_Interref: CInterRef

    def __init__(inout self):
        # Will be initialized in SetUp
        self.m_Interref = CInterRef()  # default constructor

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
        self.m_Interref = CInterRef(aLayer1)
        self.m_Interref.addLayer(aLayer2, Side.Back)
        self.m_Interref.addLayer(aLayer3, Side.Back)

    def getInt(inout self) -> ref[CInterRef]:
        return self.m_Interref

def TestForwardFlowFrontSide():
    print("Begin Test: Triple pane equivalent layer properties (Forward flow - Front Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Forward
    var aSide = Side.Front
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 1.0, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.060802286, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.006080229, 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 1.0, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.519291111, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.36478051, 1e-6)
    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.0, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.526442585, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.407170225, 1e-6)

def TestForwardFlowBackSide():
    print("Begin Test: Triple pane equivalent layer properties (Forward flow - Back Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Forward
    var aSide = Side.Back
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.003085716, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.000304011, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.0, 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.269505052, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.189685865, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.0, 1e-6)
    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.299346813, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.21312697, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.0, 1e-6)

def TestBackwardFlowFrontSide():
    print("Begin Test: Triple pane equivalent layer properties (Backward flow - Front Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Backward
    var aSide = Side.Front
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.0, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.005137793, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.000513779, 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.0, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.097697737, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.381724451, 1e-6)
    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.0, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.07702437, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.274147962, 1e-6)

def TestBackwardFlowBackSide():
    print("Begin Test: Triple pane equivalent layer properties (Backward flow - Back Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Backward
    var aSide = Side.Back
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.019760743, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.130025689, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 1.0, 1e-6)
    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.444080621, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.838496715, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 1.0, 1e-6)
    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(If1, 0.333044677, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(If2, 0.522675109, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(If3, 0.0, 1e-6)

def TestFrontSideAbsorptances():
    print("Begin Test: Triple pane layer by layer absroptances (Front Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aSide = Side.Front
    var aScattering = ScatteringSimple.Direct
    var Af1_dir = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(Af1_dir, 0.362217125, 1e-6)
    var Af2_dir = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(Af2_dir, 0.08499287, 1e-6)
    var Af3_dir = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(Af3_dir, 0.009237846, 1e-6)
    aScattering = ScatteringSimple.Diffuse
    var Af1_dif = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(Af1_dif, 0.057730707, 1e-6)
    var Af2_dif = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(Af2_dif, 0.074691415, 1e-6)
    var Af3_dif = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(Af3_dif, 0.00729561, 1e-6)

def TestBackSideAbsorptances():
    print("Begin Test: Triple pane layer by layer absroptances (Back Side).")
    var fixture = TestMultilayerInterreflectances_3()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aSide = Side.Back
    var aScattering = ScatteringSimple.Direct
    var Ab1_dir = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(Ab1_dir, 0.048602329, 1e-6)
    var Ab2_dir = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(Ab2_dir, 0.1073958, 1e-6)
    var Ab3_dir = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(Ab3_dir, 0.05557544, 1e-6)
    aScattering = ScatteringSimple.Diffuse
    var Ab1_dif = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(Ab1_dif, 0.062171287, 1e-6)
    var Ab2_dif = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(Ab2_dif, 0.110389379, 1e-6)
    var Ab3_dif = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(Ab3_dif, 0.147634489, 1e-6)