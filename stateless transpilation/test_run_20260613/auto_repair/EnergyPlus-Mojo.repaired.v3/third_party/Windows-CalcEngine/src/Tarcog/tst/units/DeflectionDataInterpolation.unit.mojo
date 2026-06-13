from ...WCETarcog import DeflectionData, Table
from ...WCECommon import ( )
from test import assert_eq, assert_approx_equal

@value
struct TestDeflectionDataInterpolation:
    def SetUp(inout self):

@test
def InterpolationAtMidPoint():
    var fixture = TestDeflectionDataInterpolation()
    fixture.SetUp()
    var tbl = DeflectionData.getWNData()
    var interpolationValue = 2.5
    var col = Table.columnInterpolation(tbl, interpolationValue)
    var correctX = List[Float64](-5, -2.6, -0.2, 2.2, 4.6, 7)
    var correctY = List[Float64](-4.25694, -1.85765, 0.47293, 2.08248, 3.14455, 4.69143)
    assert_eq(col.size(), 6)
    for i in range(correctY.size):
        assert_approx_equal(col[i].x.value(), correctX[i], 1e-5)
        assert_approx_equal(col[i].y.value(), correctY[i], 1e-5)

@test
def InterpolationAtStartPoint():
    var fixture = TestDeflectionDataInterpolation()
    fixture.SetUp()
    var tbl = DeflectionData.getWNData()
    var interpolationValue = 1.0
    var col = Table.columnInterpolation(tbl, interpolationValue)
    var correctX = List[Float64](-5, -2.6, -0.2, 2.2, 4.6, 7)
    var correctY = List[Float64](-5.296, -2.8966, -0.5569, 1.067, 2.1892, 3.2125)
    assert_eq(col.size(), 6)
    for i in range(correctY.size):
        assert_approx_equal(col[i].x.value(), correctX[i], 1e-5)
        assert_approx_equal(col[i].y.value(), correctY[i], 1e-5)

@test
def InterpolationAtEndPoint():
    var fixture = TestDeflectionDataInterpolation()
    fixture.SetUp()
    var tbl = DeflectionData.getWNData()
    var interpolationValue = 10.0
    var col = Table.columnInterpolation(tbl, interpolationValue)
    var correctX = List[Float64](-5, -2.6, -0.2, 2.2, 4.6, 7)
    var correctY = List[Float64](-4.1207, -1.7207, 0.6846, 3.1262, 4.7056, 6.23315)
    assert_eq(col.size(), 6)
    for i in range(correctY.size):
        assert_approx_equal(col[i].x.value(), correctX[i], 1e-5)
        assert_approx_equal(col[i].y.value(), correctY[i], 1e-5)