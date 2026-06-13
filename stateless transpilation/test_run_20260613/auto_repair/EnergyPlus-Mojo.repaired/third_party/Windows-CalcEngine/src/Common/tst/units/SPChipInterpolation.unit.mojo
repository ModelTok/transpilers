from memory import Arc
from testing import assert_approx_equal
from WCECommon import IInterpolation2D, CSPChipInterpolation2D

struct TestSPChipInterpolation:
    var m_Interpolation: Arc[IInterpolation2D]

    def SetUp(inout self):
        var aPoints = List[Tuple[Float64, Float64]](
            (24, 0.683876),
            (34, 0.631739),
            (48, 0.532746),
            (62, 0.410234),
            (75, 0.330733)
        )
        self.m_Interpolation = Arc(CSPChipInterpolation2D(aPoints))

    def getInterpolation(self) -> Arc[IInterpolation2D]:
        return self.m_Interpolation

@test
def TestInterpolations():
    # SCOPED_TRACE("Begin Test: Interpolation in various ranges.")
    var aTest = TestSPChipInterpolation()
    aTest.SetUp()
    var aInterpolation: Arc[IInterpolation2D] = aTest.getInterpolation()
    var value: Float64 = 28
    value = aInterpolation.getValue(value)
    assert_approx_equal(value, 0.664845, abs_tol=1e-5)
    value = 40.9106
    value = aInterpolation.getValue(value)
    assert_approx_equal(value, 0.586155, abs_tol=1e-5)
    value = 20
    value = aInterpolation.getValue(value)
    assert_approx_equal(value, 0.683876, abs_tol=1e-5)
    value = 80
    value = aInterpolation.getValue(value)
    assert_approx_equal(value, 0.330733, abs_tol=1e-5)