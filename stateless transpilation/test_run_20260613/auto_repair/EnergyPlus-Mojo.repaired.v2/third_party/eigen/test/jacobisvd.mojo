# Define constants (Mojo doesn't have preprocessor, but we can set them as module-level)
# EIGEN_STACK_ALLOCATION_LIMIT 0
# EIGEN_RUNTIME_NO_MALLOC
from main import *
from Eigen.SVD import *
# SVD_DEFAULT(M) -> JacobiSVD<M>
# SVD_FOR_MIN_NORM(M) -> JacobiSVD<M,ColPivHouseholderQRPreconditioner>
from svd_common import *

def jacobisvd[MatrixType: AnyRegType](a: MatrixType = MatrixType(), pickrandom: Bool = True):
    var m: MatrixType = a
    if pickrandom:
        svd_fill_random(m)
    CALL_SUBTEST(( svd_test_all_computation_options[JacobiSVD[MatrixType, FullPivHouseholderQRPreconditioner]](m, True)  )) # check full only
    CALL_SUBTEST(( svd_test_all_computation_options[JacobiSVD[MatrixType, ColPivHouseholderQRPreconditioner]](m, False) ))
    CALL_SUBTEST(( svd_test_all_computation_options[JacobiSVD[MatrixType, HouseholderQRPreconditioner]](m, False) ))
    if m.rows() == m.cols():
        CALL_SUBTEST(( svd_test_all_computation_options[JacobiSVD[MatrixType, NoQRPreconditioner]](m, False) ))

def jacobisvd_verify_assert[MatrixType: AnyRegType](m: MatrixType):
    svd_verify_assert[JacobiSVD[MatrixType]](m)
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    enum ColsAtCompileTime:
        ColsAtCompileTime = MatrixType.ColsAtCompileTime
    var a: MatrixType = MatrixType.Zero(rows, cols)
    a.setZero()
    if ColsAtCompileTime == Dynamic:
        var svd_fullqr: JacobiSVD[MatrixType, FullPivHouseholderQRPreconditioner] = JacobiSVD[MatrixType, FullPivHouseholderQRPreconditioner]()
        VERIFY_RAISES_ASSERT(svd_fullqr.compute(a, ComputeFullU | ComputeThinV))
        VERIFY_RAISES_ASSERT(svd_fullqr.compute(a, ComputeThinU | ComputeThinV))
        VERIFY_RAISES_ASSERT(svd_fullqr.compute(a, ComputeThinU | ComputeFullV))

def jacobisvd_method[MatrixType: AnyRegType]():
    enum Size:
        Size = MatrixType.RowsAtCompileTime
    typedef RealScalar = MatrixType.RealScalar
    typedef RealVecType = Matrix[RealScalar, Size, 1]
    var m: MatrixType = MatrixType.Identity()
    VERIFY_IS_APPROX(m.jacobiSvd().singularValues(), RealVecType.Ones())
    VERIFY_RAISES_ASSERT(m.jacobiSvd().matrixU())
    VERIFY_RAISES_ASSERT(m.jacobiSvd().matrixV())
    VERIFY_IS_APPROX(m.jacobiSvd(ComputeFullU | ComputeFullV).solve(m), m)

namespace Foo:
    class Bar:
        def __init__(inout self): pass
    def operator<(a: Bar, b: Bar) -> Bool: return True

def msvc_workaround():
    var a: Foo.Bar = Foo.Bar()
    var b: Foo.Bar = Foo.Bar()
    std.max EIGEN_NOT_A_MACRO (a, b)

def test_jacobisvd():
    CALL_SUBTEST_3(( jacobisvd_verify_assert(Matrix3f()) ))
    CALL_SUBTEST_4(( jacobisvd_verify_assert(Matrix4d()) ))
    CALL_SUBTEST_7(( jacobisvd_verify_assert(MatrixXf(10, 12)) ))
    CALL_SUBTEST_8(( jacobisvd_verify_assert(MatrixXcd(7, 5)) ))
    CALL_SUBTEST_11(svd_all_trivial_2x2(jacobisvd[Matrix2cd]))
    CALL_SUBTEST_12(svd_all_trivial_2x2(jacobisvd[Matrix2d]))
    for i in range(g_repeat):
        CALL_SUBTEST_3(( jacobisvd[Matrix3f]() ))
        CALL_SUBTEST_4(( jacobisvd[Matrix4d]() ))
        CALL_SUBTEST_5(( jacobisvd[Matrix[float32, 3, 5]]() ))
        CALL_SUBTEST_6(( jacobisvd[Matrix[float64, Dynamic, 2]](Matrix[float64, Dynamic, 2](10, 2)) ))
        var r: int = internal.random[int](1, 30)
        var c: int = internal.random[int](1, 30)
        TEST_SET_BUT_UNUSED_VARIABLE(r)
        TEST_SET_BUT_UNUSED_VARIABLE(c)
        CALL_SUBTEST_10(( jacobisvd[MatrixXd](MatrixXd(r, c)) ))
        CALL_SUBTEST_7(( jacobisvd[MatrixXf](MatrixXf(r, c)) ))
        CALL_SUBTEST_8(( jacobisvd[MatrixXcd](MatrixXcd(r, c)) ))
        (void) r
        (void) c
        CALL_SUBTEST_7((svd_inf_nan[JacobiSVD[MatrixXf], MatrixXf]()))
        CALL_SUBTEST_10((svd_inf_nan[JacobiSVD[MatrixXd], MatrixXd]()))
        CALL_SUBTEST_13(( jacobisvd_verify_assert(Matrix[float64, 6, 1]()) ))
        CALL_SUBTEST_13(( jacobisvd_verify_assert(Matrix[float64, 1, 6]()) ))
        CALL_SUBTEST_13(( jacobisvd_verify_assert(Matrix[float64, Dynamic, 1](r)) ))
        CALL_SUBTEST_13(( jacobisvd_verify_assert(Matrix[float64, 1, Dynamic](c)) ))
    CALL_SUBTEST_7(( jacobisvd[MatrixXf](MatrixXf(internal.random[int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 2), internal.random[int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 2))) ))
    CALL_SUBTEST_8(( jacobisvd[MatrixXcd](MatrixXcd(internal.random[int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 3), internal.random[int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 3))) ))
    CALL_SUBTEST_1(( jacobisvd_method[Matrix2cd]() ))
    CALL_SUBTEST_3(( jacobisvd_method[Matrix3f]() ))
    CALL_SUBTEST_7( JacobiSVD[MatrixXf](10, 10) )
    CALL_SUBTEST_9( svd_preallocate[Void]() )
    CALL_SUBTEST_2( svd_underoverflow[Void]() )
    msvc_workaround()