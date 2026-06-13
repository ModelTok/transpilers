from memory import unique_ptr
from testing import Test, Expect
from WCECommon import SquareMatrix

@value
class TestMatrixCopyFrom(Test):
    def SetUp(self):

def Test1():
    print("Begin Test: Test matrix addition operation.")
    var a = SquareMatrix({{1, 2}, {3, 4}})
    let b = SquareMatrix({{2, 3}, {4, 5}})
    a = b
    Expect.near(2, a[0, 0], 1e-6)
    Expect.near(3, a[0, 1], 1e-6)
    Expect.near(4, a[1, 0], 1e-6)
    Expect.near(5, a[1, 1], 1e-6)