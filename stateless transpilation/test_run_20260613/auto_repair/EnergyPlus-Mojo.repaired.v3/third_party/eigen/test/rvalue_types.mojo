from ...Eigen import *
from ...Eigen.internal import internal

alias EIGEN_HAS_RVALUE_REFERENCES = True

if EIGEN_HAS_RVALUE_REFERENCES:
    def rvalue_copyassign[MatrixType: AnyType](m: MatrixType):
        alias Scalar = internal.traits[MatrixType].Scalar
        var tmp: MatrixType = m
        var src_address: UIntPtr = reinterpret_cast[UIntPtr](tmp.data())
        var n: MatrixType = ^tmp
        var dst_address: UIntPtr = reinterpret_cast[UIntPtr](n.data())
        if MatrixType.RowsAtCompileTime == Dynamic or MatrixType.ColsAtCompileTime == Dynamic:
            VERIFY_IS_EQUAL(src_address, dst_address)
        var abs_diff: Scalar = (m - n).array().abs().sum()
        VERIFY_IS_EQUAL(abs_diff, Scalar(0))
else:
    def rvalue_copyassign[MatrixType: AnyType](m: MatrixType):

def test_rvalue_types():
    CALL_SUBTEST_1(rvalue_copyassign(MatrixXf.Random(50, 50).eval()))
    CALL_SUBTEST_1(rvalue_copyassign(ArrayXXf.Random(50, 50).eval()))
    CALL_SUBTEST_1(rvalue_copyassign(Matrix[float32, 1, Dynamic].Random(50).eval()))
    CALL_SUBTEST_1(rvalue_copyassign(Array[float32, 1, Dynamic].Random(50).eval()))
    CALL_SUBTEST_1(rvalue_copyassign(Matrix[float32, Dynamic, 1].Random(50).eval()))
    CALL_SUBTEST_1(rvalue_copyassign(Array[float32, Dynamic, 1].Random(50).eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 2, 1].Random().eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 3, 1].Random().eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 4, 1].Random().eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 2, 2].Random().eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 3, 3].Random().eval()))
    CALL_SUBTEST_2(rvalue_copyassign(Array[float32, 4, 4].Random().eval()))

def VERIFY_IS_EQUAL[T: Equatable](a: T, b: T):
    assert_eq(a, b)

def CALL_SUBTEST_1(body: fn() -> None):
    body()

def CALL_SUBTEST_2(body: fn() -> None):
    body()