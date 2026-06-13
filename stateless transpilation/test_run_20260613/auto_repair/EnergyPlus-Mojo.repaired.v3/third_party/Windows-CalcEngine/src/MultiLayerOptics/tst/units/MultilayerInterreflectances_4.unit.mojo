from testing import test, expect_near
from memory import Pointer
from ......WCEMultiLayerOptics import CInterRef, CScatteringSurface, CScatteringLayer
from ......SingleLayerOptics.WCESingleLayerOptics import (
    CScatteringSurface as SingleLayerCScatteringSurface,
)
from ......Common.WCECommon import Side, EnergyFlow, Scattering, ScatteringSimple

struct TestMultilayerInterreflectances_4:
    var m_Interref: Pointer[CInterRef]

    def SetUp(inout self):
        var aFront = CScatteringSurface(0.06, 0.04, 0.46, 0.12, 0.46, 0.52)
        var aBack = CScatteringSurface(0.11, 0.26, 0.34, 0.19, 0.64, 0.22)
        var aLayer1 = CScatteringLayer(aFront, aBack)

        aFront = CScatteringSurface(0.1, 0.05, 0.48, 0.26, 0.56, 0.34)
        aBack = CScatteringSurface(0.15, 0.0, 0.38, 0.19, 0.49, 0.39)
        var aLayer2 = CScatteringLayer(aFront, aBack)

        aFront = CScatteringSurface(0.08, 0.05, 0.46, 0.23, 0.46, 0.52)
        aBack = CScatteringSurface(0.13, 0.25, 0.38, 0.19, 0.64, 0.22)
        var aLayer3 = CScatteringLayer(aFront, aBack)

        self.m_Interref = Pointer[CInterRef].init(CInterRef(aLayer3))
        self.m_Interref.value().addLayer(aLayer2, Side.Front)
        self.m_Interref.value().addLayer(aLayer1, Side.Front)

    def getInt(self) -> &CInterRef:
        return self.m_Interref.value()

@test("TestForwardFlowFrontSide")
def TestForwardFlowFrontSide():
    SCOPED_TRACE = "Begin Test: Triple pane equivalent layer properties (Forward flow - Front Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Forward
    var aSide = Side.Front
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(1.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.060802286, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.006080229, If3, 1e-6)

    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(1.0, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.519291111, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.36478051, If3, 1e-6)

    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.0, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.526442585, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.407170225, If3, 1e-6)

@test("TestForwardFlowBackSide")
def TestForwardFlowBackSide():
    SCOPED_TRACE = "Begin Test: Triple pane equivalent layer properties (Forward flow - Back Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Forward
    var aSide = Side.Back
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.003085716, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.000304011, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.0, If3, 1e-6)

    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.269505052, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.189685865, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.0, If3, 1e-6)

    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.299346813, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.21312697, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.0, If3, 1e-6)

@test("TestBackwardFlowFrontSide")
def TestBackwardFlowFrontSide():
    SCOPED_TRACE = "Begin Test: Triple pane equivalent layer properties (Backward flow - Front Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Backward
    var aSide = Side.Front
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.005137793, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.000513779, If3, 1e-6)

    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.0, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.097697737, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.381724451, If3, 1e-6)

    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.0, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.07702437, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.274147962, If3, 1e-6)

@test("TestBackwardFlowBackSide")
def TestBackwardFlowBackSide():
    SCOPED_TRACE = "Begin Test: Triple pane equivalent layer properties (Backward flow - Back Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aFlow = EnergyFlow.Backward
    var aSide = Side.Back
    var aScattering = Scattering.DirectDirect
    var If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.019760743, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.130025689, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(1.0, If3, 1e-6)

    aScattering = Scattering.DiffuseDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.444080621, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.838496715, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(1.0, If3, 1e-6)

    aScattering = Scattering.DirectDiffuse
    If1 = eqLayer.getEnergyToSurface(1, aSide, aFlow, aScattering)
    expect_near(0.333044677, If1, 1e-6)
    If2 = eqLayer.getEnergyToSurface(2, aSide, aFlow, aScattering)
    expect_near(0.522675109, If2, 1e-6)
    If3 = eqLayer.getEnergyToSurface(3, aSide, aFlow, aScattering)
    expect_near(0.0, If3, 1e-6)

@test("TestFrontSideAbsorptances")
def TestFrontSideAbsorptances():
    SCOPED_TRACE = "Begin Test: Triple pane layer by layer absroptances (Front Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aSide = Side.Front
    var aScattering = ScatteringSimple.Direct
    var Af1_dir = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(0.362217125, Af1_dir, 1e-6)
    var Af2_dir = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(0.08499287, Af2_dir, 1e-6)
    var Af3_dir = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(0.009237846, Af3_dir, 1e-6)

    aScattering = ScatteringSimple.Diffuse
    var Af1_dif = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(0.057730707, Af1_dif, 1e-6)
    var Af2_dif = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(0.074691415, Af2_dif, 1e-6)
    var Af3_dif = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(0.00729561, Af3_dif, 1e-6)

@test("TestBackSideAbsorptances")
def TestBackSideAbsorptances():
    SCOPED_TRACE = "Begin Test: Triple pane layer by layer absroptances (Back Side)."
    var fixture = TestMultilayerInterreflectances_4()
    fixture.SetUp()
    var eqLayer = fixture.getInt()
    var aSide = Side.Back
    var aScattering = ScatteringSimple.Direct
    var Ab1_dir = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(0.048602329, Ab1_dir, 1e-6)
    var Ab2_dir = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(0.1073958, Ab2_dir, 1e-6)
    var Ab3_dir = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(0.05557544, Ab3_dir, 1e-6)

    aScattering = ScatteringSimple.Diffuse
    var Ab1_dif = eqLayer.getAbsorptance(1, aSide, aScattering)
    expect_near(0.062171287, Ab1_dif, 1e-6)
    var Ab2_dif = eqLayer.getAbsorptance(2, aSide, aScattering)
    expect_near(0.110389379, Ab2_dif, 1e-6)
    var Ab3_dif = eqLayer.getAbsorptance(3, aSide, aScattering)
    expect_near(0.147634489, Ab3_dif, 1e-6)