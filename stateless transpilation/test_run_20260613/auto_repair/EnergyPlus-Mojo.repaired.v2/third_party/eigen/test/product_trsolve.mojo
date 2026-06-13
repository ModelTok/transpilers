from main import (
    VERIFY_IS_APPROX,
    g_repeat,
    CALL_SUBTEST_1,
    CALL_SUBTEST_2,
    CALL_SUBTEST_3,
    CALL_SUBTEST_4,
    CALL_SUBTEST_5,
    CALL_SUBTEST_6,
    CALL_SUBTEST_7,
    CALL_SUBTEST_8,
    CALL_SUBTEST_9,
    CALL_SUBTEST_10,
    CALL_SUBTEST_11,
    CALL_SUBTEST_12,
    CALL_SUBTEST_13,
    CALL_SUBTEST_14,
    EIGEN_TEST_MAX_SIZE,
    Lower,
    Upper,
    UnitLower,
    UnitUpper,
    ColMajor,
    RowMajor,
    OnTheRight,
    OnTheLeft,
)
from internal import random

alias ColMajorInt = Int
alias RowMajorInt = Int
alias Dynamic = Int

def NumTraits[Scalar: AnyType]() -> AnyType:  # placeholder

def triangularView[Mode: Int](self) -> AnyType:  # placeholder

def solveInPlace[Side: Int](self, other: AnyType):  # placeholder

def solve[Side: Int](self, other: AnyType) -> AnyType:  # placeholder

def toDenseMatrix(self) -> AnyType:  # placeholder

def conjugate(self) -> AnyType:  # placeholder

def adjoint(self) -> AnyType:  # placeholder

def transpose(self) -> AnyType:  # placeholder

def setRandom(self):  # placeholder

def diagonal(self) -> AnyType:  # placeholder

def array(self) -> AnyType:  # placeholder

def VERIFY_TRSM[TRI: AnyType, XB: AnyType, Ref: AnyType](inout TRI, inout XB, inout Ref):
    XB.setRandom()
    Ref = XB
    TRI.solveInPlace(XB)
    VERIFY_IS_APPROX(TRI.toDenseMatrix() * XB, Ref)
    XB.setRandom()
    Ref = XB
    XB = TRI.solve(XB)
    VERIFY_IS_APPROX(TRI.toDenseMatrix() * XB, Ref)

def VERIFY_TRSM_ONTHERIGHT[TRI: AnyType, XB: AnyType, Ref: AnyType](inout TRI, inout XB, inout Ref):
    XB.setRandom()
    Ref = XB
    TRI.transpose().solveInPlace[OnTheRight](XB.transpose())
    VERIFY_IS_APPROX(XB.transpose() * TRI.transpose().toDenseMatrix(), Ref.transpose())
    XB.setRandom()
    Ref = XB
    XB.transpose() = TRI.transpose().solve[OnTheRight](XB.transpose())
    VERIFY_IS_APPROX(XB.transpose() * TRI.transpose().toDenseMatrix(), Ref.transpose())

def trsolve[Scalar: AnyType, Size: Int, Cols: Int](size: Int = Size, cols: Int = Cols):
    var cmLhs = Matrix[Scalar, Size, Size, ColMajor](size, size)
    var rmLhs = Matrix[Scalar, Size, Size, RowMajor](size, size)
    alias colmajor = if Size==1: RowMajor else: ColMajor
    alias rowmajor = if Cols==1: ColMajor else: RowMajor
    var cmRhs = Matrix[Scalar, Size, Cols, colmajor](size, cols)
    var rmRhs = Matrix[Scalar, Size, Cols, rowmajor](size, cols)
    var ref = Matrix[Scalar, Dynamic, Dynamic, colmajor](size, cols)

    cmLhs.setRandom()
    cmLhs *= NumTraits[Scalar].Real(0.1)
    cmLhs.diagonal().array() += NumTraits[Scalar].Real(1)
    rmLhs.setRandom()
    rmLhs *= NumTraits[Scalar].Real(0.1)
    rmLhs.diagonal().array() += NumTraits[Scalar].Real(1)

    VERIFY_TRSM(cmLhs.conjugate().triangularView[Lower](), cmRhs, ref)
    VERIFY_TRSM(cmLhs.adjoint().triangularView[Lower](), cmRhs, ref)
    VERIFY_TRSM(cmLhs.triangularView[Upper](), cmRhs, ref)
    VERIFY_TRSM(cmLhs.triangularView[Lower](), rmRhs, ref)
    VERIFY_TRSM(cmLhs.conjugate().triangularView[Upper](), rmRhs, ref)
    VERIFY_TRSM(cmLhs.adjoint().triangularView[Upper](), rmRhs, ref)
    VERIFY_TRSM(cmLhs.conjugate().triangularView[UnitLower](), cmRhs, ref)
    VERIFY_TRSM(cmLhs.triangularView[UnitUpper](), rmRhs, ref)
    VERIFY_TRSM(rmLhs.triangularView[Lower](), cmRhs, ref)
    VERIFY_TRSM(rmLhs.conjugate().triangularView[UnitUpper](), rmRhs, ref)

    VERIFY_TRSM_ONTHERIGHT(cmLhs.conjugate().triangularView[Lower](), cmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(cmLhs.triangularView[Upper](), cmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(cmLhs.triangularView[Lower](), rmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(cmLhs.conjugate().triangularView[Upper](), rmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(cmLhs.conjugate().triangularView[UnitLower](), cmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(cmLhs.triangularView[UnitUpper](), rmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(rmLhs.triangularView[Lower](), cmRhs, ref)
    VERIFY_TRSM_ONTHERIGHT(rmLhs.conjugate().triangularView[UnitUpper](), rmRhs, ref)

    var c = random[Int](0, cols-1)
    VERIFY_TRSM(rmLhs.triangularView[Lower](), rmRhs.col(c), ref)
    VERIFY_TRSM(cmLhs.triangularView[Lower](), rmRhs.col(c), ref)

def test_product_trsolve():
    for i in range(g_repeat):
        CALL_SUBTEST_1((trsolve[Float32, Dynamic, Dynamic](random[Int](1, EIGEN_TEST_MAX_SIZE), random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2((trsolve[Float64, Dynamic, Dynamic](random[Int](1, EIGEN_TEST_MAX_SIZE), random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_3((trsolve[Complex[Float32], Dynamic, Dynamic](random[Int](1, EIGEN_TEST_MAX_SIZE//2), random[Int](1, EIGEN_TEST_MAX_SIZE//2))))
        CALL_SUBTEST_4((trsolve[Complex[Float64], Dynamic, Dynamic](random[Int](1, EIGEN_TEST_MAX_SIZE//2), random[Int](1, EIGEN_TEST_MAX_SIZE//2))))
        CALL_SUBTEST_5((trsolve[Float32, Dynamic, 1](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6((trsolve[Float64, Dynamic, 1](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_7((trsolve[Complex[Float32], Dynamic, 1](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_8((trsolve[Complex[Float64], Dynamic, 1](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_9((trsolve[Float32, 4, 1]()))
        CALL_SUBTEST_10((trsolve[Float64, 4, 1]()))
        CALL_SUBTEST_11((trsolve[Complex[Float32], 4, 1]()))
        CALL_SUBTEST_12((trsolve[Float32, 1, 1]()))
        CALL_SUBTEST_13((trsolve[Float32, 1, 2]()))
        CALL_SUBTEST_14((trsolve[Float32, 3, 1]()))