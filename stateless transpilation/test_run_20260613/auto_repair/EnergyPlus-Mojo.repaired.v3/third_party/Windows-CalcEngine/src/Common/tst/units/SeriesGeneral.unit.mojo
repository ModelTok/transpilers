from memory import pointer
from testing import *
from WCECommon import *
from WCECommon import CSeries, CSeriesPoint

class TestSeriesGeneral(Test):
    var m_Series: CSeries

    def SetUp(self) raises:
        var vec = List[Tuple[Float64, Float64]]()
        vec.append((0.5, 3.3))
        vec.append((0.51, 5.2))
        vec.append((0.52, 8.9))
        vec.append((0.53, 10.1))
        vec.append((0.54, 11.4))
        self.m_Series = CSeries(vec)

    def getSeries(self) -> CSeries:
        return self.m_Series

@register_test(TestSeriesGeneral)
def TestSeriesPoint(self: TestSeriesGeneral) raises:
    print("Begin Test: Test simple series point.")
    var a = CSeriesPoint(1, 5)
    var b = CSeriesPoint()
    b = a
    assert_equal(a.value(), b.value())
    assert_equal(a.x(), b.x())
    b.value(7)
    assert_equal(b.value(), 7)
    var c = CSeriesPoint(2, 5)
    assert_true(a < c)

@register_test(TestSeriesGeneral)
def TestSeriesMultiplication(self: TestSeriesGeneral) raises:
    print("Begin Test: Test multiplication over the range of data.")
    var ser = self.getSeries()
    ser.insertToBeginning(0.55, 15.0)
    var correctResults = List[Float64](15.0, 3.3, 5.2, 8.9, 10.1, 11.4)
    assert_equal(ser.size(), correctResults.size)
    for i in range(ser.size()):
        assert_almost_equal(correctResults[i], ser[i].value(), 1e-6)

@register_test(TestSeriesGeneral)
def TestSeriesXValues(self: TestSeriesGeneral) raises:
    print("Begin Test: Test getting x values from series.")
    var ser = self.getSeries()
    var xValues = ser.getXArray()
    var correctResults = List[Float64](0.50, 0.51, 0.52, 0.53, 0.54)
    assert_equal(ser.size(), correctResults.size)
    for i in range(ser.size()):
        assert_almost_equal(correctResults[i], xValues[i], 1e-6)

@register_test(TestSeriesGeneral)
def TestConstantSeries(self: TestSeriesGeneral) raises:
    print("Begin Test: Test setting constant series.")
    var x = List[Float64](1, 2, 3, 4, 5)
    var test = CSeries()
    test.setConstantValues(x, 12)
    var correctResults = List[Float64](12, 12, 12, 12, 12)
    assert_equal(test.size(), correctResults.size)
    for i in range(test.size()):
        assert_almost_equal(correctResults[i], test[i].value(), 1e-6)
        assert_almost_equal(x[i], test[i].x(), 1e-6)
    test.clear()
    assert_equal(test.size(), 0)
    try:
        var _ = test[1]
    except Error as err:
        assert_equal(str(err), "Index out of range.")