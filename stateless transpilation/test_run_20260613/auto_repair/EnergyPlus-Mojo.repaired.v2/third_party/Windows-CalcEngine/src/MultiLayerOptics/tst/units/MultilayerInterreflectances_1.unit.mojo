from testing import assert_almost_equal, test
from ......src.WCEMultiLayerOptics import CInterRefSingleComponent
from ......src.WCECommon import EnergyFlow, Side

struct TestMultilayerInterreflectances_1:
    var m_Interref: CInterRefSingleComponent

    def __init__(self):
        self.set_up()

    def set_up(self):
        self.m_Interref = CInterRefSingleComponent(0.46, 0.52, 0.64, 0.22)
        self.m_Interref.addLayer(0.56, 0.34, 0.49, 0.39)
        self.m_Interref.addLayer(0.12, 0.47, 0.33, 0.63)

    def getInt(self) -> ref[CInterRefSingleComponent]:
        return self.m_Interref

@test
def TestForwardFlow():
    # SCOPED_TRACE("Begin Test: Double pane equivalent layer properties (additonal layer on back side).")
    var test_obj = TestMultilayerInterreflectances_1()
    var eqLayer = test_obj.getInt()
    var aFlow = EnergyFlow.Forward
    var If1 = eqLayer.getEnergyToSurface(1, Side.Front, aFlow)
    assert_almost_equal(1.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, Side.Front, aFlow)
    assert_almost_equal(0.516587502, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, Side.Front, aFlow)
    assert_almost_equal(0.354216972, If3, 1e-6)
    var Ib1 = eqLayer.getEnergyToSurface(1, Side.Back, aFlow)
    assert_almost_equal(0.25721592, Ib1, 1e-6)
    var Ib2 = eqLayer.getEnergyToSurface(2, Side.Back, aFlow)
    assert_almost_equal(0.166481977, Ib2, 1e-6)
    var Ib3 = eqLayer.getEnergyToSurface(3, Side.Back, aFlow)
    assert_almost_equal(0.0, Ib3, 1e-6)

@test
def TestBackwardFlow():
    # SCOPED_TRACE("Begin Test: Double pane equivalent layer properties (additonal layer on back side).")
    var test_obj = TestMultilayerInterreflectances_1()
    var eqLayer = test_obj.getInt()
    var aFlow = EnergyFlow.Backward
    var If1 = eqLayer.getEnergyToSurface(1, Side.Front, aFlow)
    assert_almost_equal(0.0, If1, 1e-6)
    var If2 = eqLayer.getEnergyToSurface(2, Side.Front, aFlow)
    assert_almost_equal(0.048916594, If2, 1e-6)
    var If3 = eqLayer.getEnergyToSurface(3, Side.Front, aFlow)
    assert_almost_equal(0.191126843, If3, 1e-6)
    var Ib1 = eqLayer.getEnergyToSurface(1, Side.Back, aFlow)
    assert_almost_equal(0.222348154, Ib1, 1e-6)
    var Ib2 = eqLayer.getEnergyToSurface(2, Side.Back, aFlow)
    assert_almost_equal(0.419829616, Ib2, 1e-6)
    var Ib3 = eqLayer.getEnergyToSurface(3, Side.Back, aFlow)
    assert_almost_equal(1.0, Ib3, 1e-6)