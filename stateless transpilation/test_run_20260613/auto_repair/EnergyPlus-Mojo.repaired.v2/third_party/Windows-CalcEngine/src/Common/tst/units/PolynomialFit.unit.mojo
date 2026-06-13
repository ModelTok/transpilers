from memory import Pointer
from testing import *
from WCECommon import PolynomialFit

class TestPolynomialFit(Testing[TestPolynomialFit]):
    def SetUp(self):

@fixture
def TestPolynomialFit_Test1():
    SCOPED_TRACE("Begin Test: Polynomial fit test 1.")
    const order: size_t = 2
    const input: vector[pair[float64, float64]] = {{1, 1}, {2, 8}, {3, 12}, {4, 16}}
    var poly = PolynomialFit(order)
    var res = poly.getCoefficients(input)
    var correct: vector[float64] = {-6.75, 8.65, -0.75}
    ASSERT_EQ(correct.size(), res.size())
    for i in range(0, correct.size()):
        EXPECT_NEAR(correct[i], res[i], 1e-6)

@fixture
def TestPolynomialFit_Test2():
    SCOPED_TRACE("Begin Test: Polynomial fit test 2.")
    const order: size_t = 6
    var input: vector[pair[float64, float64]] = {{1.000000000, 0.833848000},
                                                 {0.984807753, 0.833295072},
                                                 {0.939692621, 0.831346909},
                                                 {0.866025404, 0.826927210},
                                                 {0.766044443, 0.817365310},
                                                 {0.642787610, 0.796259808},
                                                 {0.500000000, 0.748087594},
                                                 {0.342020143, 0.635870414},
                                                 {0.173648178, 0.387186362},
                                                 {0.000000000, 0.000000000}}
    var poly = PolynomialFit(order)
    var res = poly.getCoefficients(input)
    var correct: vector[float64] = {
      -9.27348e-6, 2.288300, 1.646894, -15.397616, 26.122771, -19.148321, 5.322077}
    ASSERT_EQ(correct.size(), res.size())
    for i in range(0, correct.size()):
        EXPECT_NEAR(correct[i], res[i], 1e-6)