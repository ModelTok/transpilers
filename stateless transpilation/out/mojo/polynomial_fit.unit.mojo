# EXTERNAL DEPS (to wire in glue):
# - PolynomialFit: from WCECommon.hpp (FenestrationCommon namespace) - C++ class for polynomial fitting

from testing import assert_equal, assert_true, TestSuite
from WCECommon import PolynomialFit


fn set_up():
    """Fixture setup - no-op, mirrors the C++ TestPolynomialFit::SetUp()."""
    pass


fn assert_near(actual: Float64, expected: Float64, tolerance: Float64):
    """Assert that two values are within an absolute tolerance (mirrors EXPECT_NEAR)."""
    assert_true(abs(actual - expected) <= tolerance)


fn test_polynomial_fit_test1():
    # SCOPED_TRACE("Begin Test: Polynomial fit test 1.")
    set_up()

    let order: Int = 2

    let input: List[Tuple[Float64, Float64]] = [
        (1.0, 1.0),
        (2.0, 8.0),
        (3.0, 12.0),
        (4.0, 16.0),
    ]

    var poly = PolynomialFit(order)

    var res = poly.getCoefficients(input)

    let correct: List[Float64] = [-6.75, 8.65, -0.75]

    assert_equal(len(correct), len(res))

    for i in range(len(correct)):
        assert_near(correct[i], res[i], 1e-6)


fn test_polynomial_fit_test2():
    # SCOPED_TRACE("Begin Test: Polynomial fit test 2.")
    set_up()

    let order: Int = 6

    let input: List[Tuple[Float64, Float64]] = [
        (1.000000000, 0.833848000),
        (0.984807753, 0.833295072),
        (0.939692621, 0.831346909),
        (0.866025404, 0.826927210),
        (0.766044443, 0.817365310),
        (0.642787610, 0.796259808),
        (0.500000000, 0.748087594),
        (0.342020143, 0.635870414),
        (0.173648178, 0.387186362),
        (0.000000000, 0.000000000),
    ]

    var poly = PolynomialFit(order)

    var res = poly.getCoefficients(input)

    let correct: List[Float64] = [
        -9.27348e-6, 2.288300, 1.646894, -15.397616, 26.122771, -19.148321, 5.322077,
    ]

    assert_equal(len(correct), len(res))

    for i in range(len(correct)):
        assert_near(correct[i], res[i], 1e-6)


fn main():
    TestSuite.discover_tests[__functions_in_module__]().run()
