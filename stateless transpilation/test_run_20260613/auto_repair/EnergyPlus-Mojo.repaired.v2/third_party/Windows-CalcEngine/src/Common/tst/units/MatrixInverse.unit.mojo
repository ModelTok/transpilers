from memory import memory
from stdexcept import stdexcept
from gtest import gtest
from WCECommon import SquareMatrix

class TestMatrixInverse(gtest.Test):
    def SetUp(self):

@testing.fixture
def Test1(self):
    print("Begin Test: Test inverse matrix (3 x 3).")
    const n: size_t = 3
    var a = SquareMatrix([[3.12, 8.56, 4.19], [6.87, 4.39, 7.11], [6.59, 4.98, 7.69]])
    var inverse = a.inverse()
    gtest.expect_eq(n, inverse.size())
    var inverseCorrect = SquareMatrix([[0.048264485, 1.316176934, -1.243204967],
                                       [0.17492546, 0.105952357, -0.193271643],
                                       [-0.15464132, -1.196521292, 1.320573929]])
    for i in range(n):
        for j in range(n):
            gtest.expect_near(inverse[i, j], inverseCorrect[i, j], 1e-6)

@testing.fixture
def Test2(self):
    print("Begin Test: Test inverse matrix (4 x 4).")
    const n: size_t = 4
    var a = SquareMatrix([[2.59, 1.48, 9.54, 4.16],
                          [9.45, 7.25, 6.58, 4.95],
                          [2.12, 5.36, 4.98, 8.23],
                          [4.89, 1.11, 7.45, 3.26]])
    var inverse = a.inverse()
    gtest.expect_eq(n, inverse.size())
    var inverseCorrect = SquareMatrix([[-0.266190489, 0.003957093, -0.001994289, 0.338704853],
                                       [0.313584868, 0.208591568, -0.07062952, -0.538576798],
                                       [0.254839323, 0.035657535, -0.083907777, -0.167507784],
                                       [-0.289865235, -0.15844646, 0.21879257, 0.364873161]])
    for i in range(n):
        for j in range(n):
            gtest.expect_near(inverse[i, j], inverseCorrect[i, j], 1e-6)