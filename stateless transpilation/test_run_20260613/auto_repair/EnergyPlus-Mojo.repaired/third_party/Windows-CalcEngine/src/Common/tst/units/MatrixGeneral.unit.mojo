from memory import Pointer
from utils import Vector
from testing import *
from WCECommon import SquareMatrix

class TestMatrixGeneral:
    def setup__[__type__](inout self):

@fixture
def TestMatrixGeneral_fixture() -> TestMatrixGeneral:
    return TestMatrixGeneral()

def TestSetDiagonal():
    print("Begin Test: Test matrix set diagonal.")
    var a = SquareMatrix(Vector[Vector[Float64]]([Vector[Float64]([1.0, 2.0]), Vector[Float64]([3.0, 4.0])]))
    var b = Vector[Float64]([7.0, 8.0])
    a.setDiagonal(b)
    assert abs(a[0, 0] - 7.0) < 1e-6
    assert abs(a[0, 1] - 0.0) < 1e-6
    assert abs(a[1, 0] - 0.0) < 1e-6
    assert abs(a[1, 1] - 8.0) < 1e-6

def TestSetIdentity():
    print("Begin Test: Test matrix set identity.")
    var a = SquareMatrix(Vector[Vector[Float64]]([Vector[Float64]([1.0, 2.0]), Vector[Float64]([3.0, 4.0])]))
    a.setIdentity()
    assert abs(a[0, 0] - 1.0) < 1e-6
    assert abs(a[0, 1] - 0.0) < 1e-6
    assert abs(a[1, 0] - 0.0) < 1e-6
    assert abs(a[1, 1] - 1.0) < 1e-6

def TestSetDiagonalException():
    print("Begin Test: Test matrix set diagonal exception.")
    var a = SquareMatrix(Vector[Vector[Float64]]([Vector[Float64]([1.0, 2.0]), Vector[Float64]([3.0, 4.0])]))
    var b = Vector[Float64]([7.0, 8.0, 9.0])
    try:
        a.setDiagonal(b)
    except Error as err:
        assert str(err) == "Matrix and vector must be same size."