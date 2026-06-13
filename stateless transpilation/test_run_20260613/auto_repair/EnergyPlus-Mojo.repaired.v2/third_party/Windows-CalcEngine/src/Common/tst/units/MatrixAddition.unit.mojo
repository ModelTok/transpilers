from memory import pointer
from utils import Error
from WCECommon import SquareMatrix
from testing import *

class TestMatrixAddition:
    def setup(self):

def test_addition():
    scoped_trace("Begin Test: Test matrix addition operation.")
    let a = SquareMatrix(Matrix[[1, 2], [3, 4]])
    let b = SquareMatrix(Matrix[[2, 3], [4, 5]])
    let c = a + b
    expect_near(3, c[0, 0], 1e-6)
    expect_near(5, c[0, 1], 1e-6)
    expect_near(7, c[1, 0], 1e-6)
    expect_near(9, c[1, 1], 1e-6)

def test_addition_exception():
    scoped_trace("Begin Test: Test matrix addition exception.")
    let a = SquareMatrix(Matrix[[1, 2], [3, 4]])
    let b = SquareMatrix(Matrix[[2, 3, 4], [4, 5, 6], [7, 5, 9]])
    try:
        let c = a + b
    except Error as err:
        expect_equal(str(err), "Matrices must be identical in size.")

def test_subtraction():
    scoped_trace("Begin Test: Test matrix subtraction operation.")
    let a = SquareMatrix(Matrix[[1, 2], [3, 4]])
    let b = SquareMatrix(Matrix[[2, 3], [4, 5]])
    let c = a - b
    expect_near(-1, c[0, 0], 1e-6)
    expect_near(-1, c[0, 1], 1e-6)
    expect_near(-1, c[1, 0], 1e-6)
    expect_near(-1, c[1, 1], 1e-6)

def test_subtraction_exception():
    scoped_trace("Begin Test: Test matrix subtraction exception.")
    let aVec = Vector[Vector[Float64]]([Vector[Float64]([1, 2]), Vector[Float64]([3, 4])])
    let a = SquareMatrix(std_move(aVec))
    let b = SquareMatrix(Matrix[[2, 3, 4], [4, 5, 6], [7, 5, 9]])
    try:
        let c = a - b
    except Error as err:
        expect_equal(str(err), "Matrices must be identical in size.")

def test_addition_with_equality():
    scoped_trace("Begin Test: Test matrix += operation.")
    var a = SquareMatrix(Matrix[[1, 2], [3, 4]])
    let b = SquareMatrix(Matrix[[2, 3], [4, 5]])
    a += b
    expect_near(3, a[0, 0], 1e-6)
    expect_near(5, a[0, 1], 1e-6)
    expect_near(7, a[1, 0], 1e-6)
    expect_near(9, a[1, 1], 1e-6)

def test_subtraction_with_equality():
    scoped_trace("Begin Test: Test matrix -= operation.")
    var a = SquareMatrix(Matrix[[1, 2], [3, 4]])
    let b = SquareMatrix(Matrix[[2, 3], [4, 5]])
    a -= b
    expect_near(-1, a[0, 0], 1e-6)
    expect_near(-1, a[0, 1], 1e-6)
    expect_near(-1, a[1, 0], 1e-6)
    expect_near(-1, a[1, 1], 1e-6)