from memory import std
from gtest import *
from WCEMultiLayerOptics import *
from WCESingleLayerOptics import *
from WCECommon import *
from MultiLayerOptics import *
from FenestrationCommon import *

class TestMultilayerSingleComponent_2(Test):
    var m_IGU: CMultiLayerSingleComponent

    def SetUp(self):
        self.m_IGU = CMultiLayerSingleComponent(0.12, 0.47, 0.33, 0.63)
        self.m_IGU.addLayer(0.56, 0.34, 0.49, 0.39, Side.Front)
        self.m_IGU.addLayer(0.46, 0.52, 0.64, 0.22, Side.Front)

    def getIGU(self) -> CMultiLayerSingleComponent:
        return self.m_IGU

def TestOpticalProperties():
    SCOPED_TRACE("Begin Test: Combined layers optical properties.")
    var eqLayer = getIGU()
    var Tf = eqLayer.getProperty(Property.T, Side.Front)
    EXPECT_NEAR(0.042506037, Tf, 1e-6)
    var Rf = eqLayer.getProperty(Property.R, Side.Front)
    EXPECT_NEAR(0.684618188, Rf, 1e-6)
    var Af = eqLayer.getProperty(Property.Abs, Side.Front)
    EXPECT_NEAR(0.272875775, Af, 1e-6)
    var Tb = eqLayer.getProperty(Property.T, Side.Back)
    EXPECT_NEAR(0.142302818, Tb, 1e-6)
    var Rb = eqLayer.getProperty(Property.R, Side.Back)
    EXPECT_NEAR(0.652935221, Rb, 1e-6)
    var Ab = eqLayer.getProperty(Property.Abs, Side.Back)
    EXPECT_NEAR(0.20476196, Ab, 1e-6)

def TestLayerAbsorptances():
    SCOPED_TRACE("Begin Test: Layer by layer absorptances.")
    var eqLayer = getIGU()
    var Af1 = eqLayer.getLayerAbsorptance(1, Side.Front)
    EXPECT_NEAR(0.056010229, Af1, 1e-6)
    var Af2 = eqLayer.getLayerAbsorptance(2, Side.Front)
    EXPECT_NEAR(0.071636587, Af2, 1e-6)
    var Af3 = eqLayer.getLayerAbsorptance(3, Side.Front)
    EXPECT_NEAR(0.145228959, Af3, 1e-6)
    var Ab1 = eqLayer.getLayerAbsorptance(1, Side.Back)
    EXPECT_NEAR(0.031128742, Ab1, 1e-6)
    var Ab2 = eqLayer.getLayerAbsorptance(2, Side.Back)
    EXPECT_NEAR(0.055271213, Ab2, 1e-6)
    var Ab3 = eqLayer.getLayerAbsorptance(3, Side.Back)
    EXPECT_NEAR(0.118362006, Ab3, 1e-6)