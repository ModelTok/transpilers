// Translation of MultilayerSingleComponent_1.unit.cpp to Mojo
// Faithful 1:1 translation, no refactoring.

from ......WCEMultiLayerOptics import CMultiLayerSingleComponent
from .........WCESingleLayerOptics import // Not used directly, but kept for faithfulness
from .........WCECommon import Property, Side

// Helper to mimic EXPECT_NEAR from gtest.
def expect_near(actual: Float64, expected: Float64, tol: Float64 = 1e-6):
    if abs(actual - expected) > tol:
        raise Error("Assertion failed: expected " + str(expected) + " but got " + str(actual))

// SCOPED_TRACE is a gtest macro; replaced with a print statement.
def SCOPED_TRACE(msg: String):
    print(msg)

// Test fixture class.
struct TestMultilayerSingleComponent_1:
    var m_IGU: CMultiLayerSingleComponent

    def SetUp(inout self):
        self.m_IGU = CMultiLayerSingleComponent(0.46, 0.52, 0.64, 0.22)
        self.m_IGU.addLayer(0.56, 0.34, 0.49, 0.39)
        self.m_IGU.addLayer(0.12, 0.47, 0.33, 0.63)

    def getIGU(inout self) -> CMultiLayerSingleComponent:
        return self.m_IGU

// Test case: TestOpticalProperties
def TestOpticalProperties():
    SCOPED_TRACE("Begin Test: Combined layers optical properties.")
    var test = TestMultilayerSingleComponent_1()
    test.SetUp()
    var eqLayer = test.getIGU()
    var Tf = eqLayer.getProperty(Property.T, Side.Front)
    expect_near(0.042506037, Tf)
    var Rf = eqLayer.getProperty(Property.R, Side.Front)
    expect_near(0.684618188, Rf)
    var Af = eqLayer.getProperty(Property.Abs, Side.Front)
    expect_near(0.272875775, Af)
    var Tb = eqLayer.getProperty(Property.T, Side.Back)
    expect_near(0.142302818, Tb)
    var Rb = eqLayer.getProperty(Property.R, Side.Back)
    expect_near(0.652935221, Rb)
    var Ab = eqLayer.getProperty(Property.Abs, Side.Back)
    expect_near(0.20476196, Ab)

// Test case: TestLayerAbsorptances
def TestLayerAbsorptances():
    SCOPED_TRACE("Begin Test: Layer by layer absorptances.")
    var test = TestMultilayerSingleComponent_1()
    test.SetUp()
    var eqLayer = test.getIGU()
    var Af1 = eqLayer.getLayerAbsorptance(1, Side.Front)
    expect_near(0.056010229, Af1)
    var Af2 = eqLayer.getLayerAbsorptance(2, Side.Front)
    expect_near(0.071636587, Af2)
    var Af3 = eqLayer.getLayerAbsorptance(3, Side.Front)
    expect_near(0.145228959, Af3)
    var Ab1 = eqLayer.getLayerAbsorptance(1, Side.Back)
    expect_near(0.031128742, Ab1)
    var Ab2 = eqLayer.getLayerAbsorptance(2, Side.Back)
    expect_near(0.055271213, Ab2)
    var Ab3 = eqLayer.getLayerAbsorptance(3, Side.Back)
    expect_near(0.118362006, Ab3)