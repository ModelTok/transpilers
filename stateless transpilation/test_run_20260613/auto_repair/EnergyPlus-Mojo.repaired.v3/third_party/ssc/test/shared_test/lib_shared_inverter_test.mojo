from lib_shared_inverter import SharedInverter, sandia_inverter_t
from testing import assert_false, assert_almost_equal, assert_lt

@value
struct sharedInverterTest_lib_shared_inverter:
    var inv: SharedInverter
    var sandia: sandia_inverter_t
    var pDC: Float64 = 61130.8
    var ratio: Float64 = 0.
    var loss: Float64 = 0.
    var e: Float64 = 0.01

    def __init__(inout self):
        self.sandia = sandia_inverter_t()

    def reset(inout self):
        self.pDC = 61130.8
        self.ratio = 1.
        self.loss = 0.

    def SetUp(inout self):
        self.sandia.C0 = -2.06147e-07
        self.sandia.C1 = 2.7e-05
        self.sandia.C2 = 0.002606
        self.sandia.C3 = 0.000501
        self.sandia.Paco = 59860
        self.sandia.Pdco = 61130.8
        self.sandia.Vdco = 630
        self.sandia.Pso = 97.21398
        self.sandia.Pntare = 17.958
        self.inv = SharedInverter(0, 1, self.sandia, None, None)

    def TearDown(inout self):
        pass  # Mojo handles memory automatically

# Tests
def tempDerateTest_lib_shared_inverter():
    var fixture = sharedInverterTest_lib_shared_inverter()
    fixture.SetUp()
    var inv = fixture.inv
    var pDC = fixture.pDC
    var ratio = fixture.ratio
    var loss = fixture.loss
    var e = fixture.e

    var c1 = List[Float64](200., 20., -0.2, 40., -0.4)
    var c2 = List[Float64](300., 30., -0.3, 60., -0.6)
    var curves = List[List[Float64]](c1, c2)

    assert_false(inv.setTempDerateCurves(curves))  # set up temp derate set 1

    var V = 200.
    var T = 5.
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # zero efficiency error case

    pDC = 0.
    ratio = 1.
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 0., e)  # zero power error case

    pDC = 61130.8
    ratio = 1.
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # no derate

    V = 100.
    T = 11.
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 55017.72, e)  # case 1

    V = 250.
    T = 26.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 45848.1, e)  # case 2

    V = 400.
    T = 41.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 36678.48, e)  # case 3

    var c3 = List[Float64](200., 20., -0.2)
    var c4 = List[Float64](300., 30., -0.3, 60., -0.6)
    var curves2 = List[List[Float64]](c3, c4)
    assert_false(inv.setTempDerateCurves(curves2))  # set up temp derate set 2

    V = 100.
    T = 9.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 7

    V = 100.
    T = 11.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 55017.72, e)  # case 7

    V = 250.
    T = 24.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 9

    V = 250.
    T = 26.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 45848.1, e)  # case 9

    V = 250.
    T = 41.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 36678.48, e)  # case 9

    V = 400.
    T = 9.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 9

    V = 400.
    T = 41.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 36678.48, e)  # case 9

    var c5 = List[Float64](200., 20., -0.2, 60., -0.6)
    var c6 = List[Float64](300., 30., -0.3)
    var curves3 = List[List[Float64]](c5, c6)
    assert_false(inv.setTempDerateCurves(curves3))  # set up temp derate set 3

    V = 100.
    T = 9.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 7

    V = 100.
    T = 11.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 55017.72, e)  # case 7

    V = 250.
    T = 24.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 9

    V = 250.
    T = 26.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 45848.1, e)  # case 9

    V = 250.
    T = 46.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 33621.94, e)  # case 9

    V = 400.
    T = 9.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 61130.8, e)  # case 9

    V = 400.
    T = 41.
    fixture.reset()
    pDC = fixture.pDC
    ratio = fixture.ratio
    loss = fixture.loss
    inv.calculateTempDerate(V, T, pDC, ratio, loss)
    assert_almost_equal(pDC, 36678.48, e)  # case 9

    fixture.TearDown()

def calculateEffForACPower():
    var fixture = sharedInverterTest_lib_shared_inverter()
    fixture.SetUp()
    var inv = fixture.inv
    var sandia = fixture.sandia

    inv.calculateACPower(sandia.Pdco / 1000., sandia.Vdco, 25)
    var p_kwac = .05
    var p_kwdc = inv.calculateRequiredDCPower(p_kwac, sandia.Vdco, 25)
    inv.calculateACPower(p_kwdc, sandia.Vdco, 25)
    assert_lt(inv.powerAC_kW, p_kwac)  # inverter efficiency too low to produce required ac

    for p in List[Float64](0.05, 0.95, 1.):
        p_kwac = sandia.Paco * p / 1000.
        p_kwdc = inv.calculateRequiredDCPower(p_kwac, sandia.Vdco, 25)
        inv.calculateACPower(p_kwdc, sandia.Vdco, 25)
        assert_almost_equal(inv.powerAC_kW, p_kwac, 1e-3)  # inverter should produce required ac of Paco * p
        p_kwac *= -1.
        p_kwdc = inv.calculateRequiredDCPower(p_kwac, sandia.Vdco, 25)
        inv.calculateACPower(p_kwdc, sandia.Vdco, 25)
        assert_almost_equal(inv.powerAC_kW, p_kwac, 1e-3)  # inverter should produce required (negative) ac of Paco * p

    for p in List[Float64](1.05, 1.1):
        p_kwac = sandia.Paco * p / 1000.
        p_kwdc = inv.calculateRequiredDCPower(p_kwac, sandia.Vdco, 25)
        inv.calculateACPower(p_kwdc, sandia.Vdco, 25)
        assert_almost_equal(inv.powerAC_kW, sandia.Paco / 1000., 1e-3)  # inverter cannot produce more than max Paco
        p_kwac *= -1.
        p_kwdc = inv.calculateRequiredDCPower(p_kwac, sandia.Vdco, 25)
        inv.calculateACPower(p_kwdc, sandia.Vdco, 25)
        assert_almost_equal(inv.powerAC_kW, -sandia.Paco / 1000., 1e-3)  # inverter cannot produce more than max (negative) Paco

    fixture.TearDown()