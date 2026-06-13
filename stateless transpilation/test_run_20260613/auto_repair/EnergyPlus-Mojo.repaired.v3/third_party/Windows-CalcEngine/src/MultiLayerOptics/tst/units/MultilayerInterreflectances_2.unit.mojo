from WCEMultiLayerOptics import CInterRefSingleComponent
from WCECommon import Side, EnergyFlow
from testing import assert_approx_equal

class TestMultilayerInterreflectances_2:
    var m_Interref: CInterRefSingleComponent

    def __init__(inout self):
        self.m_Interref = CInterRefSingleComponent(0.12, 0.47, 0.33, 0.63)
        self.m_Interref.addLayer(0.56, 0.34, 0.49, 0.39, Side.Front)
        self.m_Interref.addLayer(0.46, 0.52, 0.64, 0.22, Side.Front)

    def getInt(self) -> ref[CInterRefSingleComponent]:
        return self.m_Interref

def TestForwardFlow():
    # SCOPED_TRACE(
    #   "Begin Test: Double pane equivalent layer properties (additonal layer on back side).")
    var test = TestMultilayerInterreflectances_2()
    var eqLayer = test.getInt()
    var aFlow = EnergyFlow.Forward
    var If1 = eqLayer.getEnergyToSurface(1, Side.Front, aFlow)
    assert_approx_equal(1.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, Side.Front, aFlow)
    assert_approx_equal(0.516587502, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, Side.Front, aFlow)
    assert_approx_equal(0.354216972, If3, 1e-6)
    var Ib1 = eqLayer.getEnergyToSurface(1, Side.Back, aFlow)
    assert_approx_equal(0.25721592, Ib1, 1e-6)
    var Ib2 = eqLayer.getEnergyToSurface(2, Side.Back, aFlow)
    assert_approx_equal(0.166481977, Ib2, 1e-6)
    var Ib3 = eqLayer.getEnergyToSurface(3, Side.Back, aFlow)
    assert_approx_equal(0.0, Ib3, 1e-6)

def TestBackwardFlow():
    # SCOPED_TRACE(
    #   "Begin Test: Double pane equivalent layer properties (additonal layer on back side).")
    var test = TestMultilayerInterreflectances_2()
    var eqLayer = test.getInt()
    var aFlow = EnergyFlow.Backward
    var If1 = eqLayer.getEnergyToSurface(1, Side.Front, aFlow)
    assert_approx_equal(0.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, Side.Front, aFlow)
    assert_approx_equal(0.048916594, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, Side.Front, aFlow)
    assert_approx_equal(0.191126843, If3, 1e-6)
    var Ib1 = eqLayer.getEnergyToSurface(1, Side.Back, aFlow)
    assert_approx_equal(0.222348154, Ib1, 1e-6)
    var Ib2 = eqLayer.getEnergyToSurface(2, Side.Back, aFlow)
    assert_approx_equal(0.419829616, Ib2, 1e-6)
    var Ib3 = eqLayer.getEnergyToSurface(3, Side.Back, aFlow)
    assert_approx_equal(1.0, Ib3, 1e-6)

def main():
    TestForwardFlow()
    TestBackwardFlow()