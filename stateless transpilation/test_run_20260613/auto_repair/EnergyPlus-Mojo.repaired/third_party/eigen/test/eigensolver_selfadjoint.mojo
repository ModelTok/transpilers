# Mojo translation of eigensolver_selfadjoint.cpp
# Assumes existence of Mojo Eigen library with similar API.
# Test macros replaced with direct function calls and assertions.

from Eigen import (
    Matrix,
    SelfAdjointEigenSolver,
    GeneralizedSelfAdjointEigenSolver,
    Tridiagonalization,
    NumTraits,
    numext,
    ComputeEigenvectors,
    Success,
    NoConvergence,
    Symmetric,
    Lower,
    Upper,
    StrictlyUpper,
    Ax_lBx,
    BAx_lx,
    ABx_lx,
    Dynamic,
    RowMajor,
)
from svd_fill import svd_fill_random
from math import min, sqrt, abs, is_nan
from memory import reference

# Constants (from main.h)
alias g_repeat: Int = 1  # placeholder
alias EIGEN_TEST_MAX_SIZE: Int = 100  # placeholder

# Helper functions to mimic Eigen test macros
def test_precision[RealScalar: AnyType]() -> RealScalar:
    # Return machine epsilon for the type
    if issubtype[RealScalar, Float32]:
        return 1.1920929e-07
    elif issubtype[RealScalar, Float64]:
        return 2.220446049250313e-16
    else:
        return 1e-6

def VERIFY_IS_EQUAL(a: AnyType, b: AnyType):
    if a != b:
        raise Error("VERIFY_IS_EQUAL failed")

def VERIFY_IS_APPROX(a: AnyType, b: AnyType, eps: AnyType = None):
    # Simplified: check relative difference
    if eps is None:
        eps = test_precision[type(a)]()
    if abs(a - b) > eps * max(1.0, abs(a), abs(b)):
        raise Error("VERIFY_IS_APPROX failed")

def VERIFY_IS_UNITARY(m: Matrix):
    # Check that m * m.adjoint() is identity
    id = Matrix[type(m[0,0]), m.rows(), m.cols()].identity()
    if not (m * m.adjoint()).isApprox(id):
        raise Error("VERIFY_IS_UNITARY failed")

def VERIFY_RAISES_ASSERT(body: fn() -> None):
    try:
        body()
        raise Error("Expected assertion but none raised")
    except:

def VERIFY_IS_MUCH_SMALLER_THAN(a: AnyType, b: AnyType):
    if abs(a) > 1e-10 * abs(b):
        raise Error("VERIFY_IS_MUCH_SMALLER_THAN failed")

def TEST_SET_BUT_UNUSED_VARIABLE(v: AnyType):

# The main test functions
def selfadjointeigensolver_essential_check[MatrixType: AnyType](m: MatrixType):
    alias Scalar = type(m[0,0])
    alias RealScalar = NumTraits[Scalar].Real
    var eival_eps: RealScalar = min[RealScalar](test_precision[RealScalar](), NumTraits[Scalar].dummy_precision() * 20000)
    var eiSymm = SelfAdjointEigenSolver[MatrixType](m)
    VERIFY_IS_EQUAL(eiSymm.info(), Success)
    var scaling: RealScalar = m.cwiseAbs().maxCoeff()
    if scaling < (Float64.min if issubtype[RealScalar, Float64] else Float32.min):
        VERIFY(eiSymm.eigenvalues().cwiseAbs().maxCoeff() <= (Float64.min if issubtype[RealScalar, Float64] else Float32.min))
    else:
        VERIFY_IS_APPROX((m.selfadjointView[Lower]() * eiSymm.eigenvectors()) / scaling,
                         (eiSymm.eigenvectors() * eiSymm.eigenvalues().asDiagonal()) / scaling)
    VERIFY_IS_APPROX(m.selfadjointView[Lower]().eigenvalues(), eiSymm.eigenvalues())
    VERIFY_IS_UNITARY(eiSymm.eigenvectors())
    if m.cols() <= 4:
        var eiDirect = SelfAdjointEigenSolver[MatrixType]()
        eiDirect.computeDirect(m)
        VERIFY_IS_EQUAL(eiDirect.info(), Success)
        if not eiSymm.eigenvalues().isApprox(eiDirect.eigenvalues(), eival_eps):
            print("reference eigenvalues: ", eiSymm.eigenvalues().transpose())
            print("obtained eigenvalues:  ", eiDirect.eigenvalues().transpose())
            print("diff:                  ", (eiSymm.eigenvalues() - eiDirect.eigenvalues()).transpose())
            print("error (eps):           ", (eiSymm.eigenvalues() - eiDirect.eigenvalues()).norm() / eiSymm.eigenvalues().norm(), "  (", eival_eps, ")")
        if scaling < (Float64.min if issubtype[RealScalar, Float64] else Float32.min):
            VERIFY(eiDirect.eigenvalues().cwiseAbs().maxCoeff() <= (Float64.min if issubtype[RealScalar, Float64] else Float32.min))
        else:
            VERIFY_IS_APPROX(eiSymm.eigenvalues() / scaling, eiDirect.eigenvalues() / scaling)
            VERIFY_IS_APPROX((m.selfadjointView[Lower]() * eiDirect.eigenvectors()) / scaling,
                             (eiDirect.eigenvectors() * eiDirect.eigenvalues().asDiagonal()) / scaling)
            VERIFY_IS_APPROX(m.selfadjointView[Lower]().eigenvalues() / scaling, eiDirect.eigenvalues() / scaling)
        VERIFY_IS_UNITARY(eiDirect.eigenvectors())

def selfadjointeigensolver[MatrixType: AnyType](m: MatrixType):
    """ this test covers the following files:
        EigenSolver.h, SelfAdjointEigenSolver.h (and indirectly: Tridiagonalization.h)
    """
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    alias Scalar = type(m[0,0])
    alias RealScalar = NumTraits[Scalar].Real
    var largerEps: RealScalar = 10 * test_precision[RealScalar]()
    var a = MatrixType.random(rows, cols)
    var a1 = MatrixType.random(rows, cols)
    var symmA = a.adjoint() * a + a1.adjoint() * a1
    var symmC = symmA
    svd_fill_random(symmA, Symmetric)
    symmA.triangularView[StrictlyUpper]().setZero()
    symmC.triangularView[StrictlyUpper]().setZero()
    var b = MatrixType.random(rows, cols)
    var b1 = MatrixType.random(rows, cols)
    var symmB = b.adjoint() * b + b1.adjoint() * b1
    symmB.triangularView[StrictlyUpper]().setZero()
    selfadjointeigensolver_essential_check(symmA)
    var eiSymm = SelfAdjointEigenSolver[MatrixType](symmA)
    var eiSymmGen = GeneralizedSelfAdjointEigenSolver[MatrixType](symmC, symmB)
    var eiSymmNoEivecs = SelfAdjointEigenSolver[MatrixType](symmA, False)
    VERIFY_IS_EQUAL(eiSymmNoEivecs.info(), Success)
    VERIFY_IS_APPROX(eiSymm.eigenvalues(), eiSymmNoEivecs.eigenvalues())
    eiSymmGen.compute(symmC, symmB, Ax_lBx)
    VERIFY_IS_EQUAL(eiSymmGen.info(), Success)
    VERIFY((symmC.selfadjointView[Lower]() * eiSymmGen.eigenvectors()).isApprox(
            symmB.selfadjointView[Lower]() * (eiSymmGen.eigenvectors() * eiSymmGen.eigenvalues().asDiagonal()), largerEps))
    eiSymmGen.compute(symmC, symmB, BAx_lx)
    VERIFY_IS_EQUAL(eiSymmGen.info(), Success)
    VERIFY((symmB.selfadjointView[Lower]() * (symmC.selfadjointView[Lower]() * eiSymmGen.eigenvectors())).isApprox(
           (eiSymmGen.eigenvectors() * eiSymmGen.eigenvalues().asDiagonal()), largerEps))
    eiSymmGen.compute(symmC, symmB, ABx_lx)
    VERIFY_IS_EQUAL(eiSymmGen.info(), Success)
    VERIFY((symmC.selfadjointView[Lower]() * (symmB.selfadjointView[Lower]() * eiSymmGen.eigenvectors())).isApprox(
           (eiSymmGen.eigenvectors() * eiSymmGen.eigenvalues().asDiagonal()), largerEps))
    eiSymm.compute(symmC)
    var sqrtSymmA = eiSymm.operatorSqrt()
    VERIFY_IS_APPROX(MatrixType(symmC.selfadjointView[Lower]()), sqrtSymmA * sqrtSymmA)
    VERIFY_IS_APPROX(sqrtSymmA, symmC.selfadjointView[Lower]() * eiSymm.operatorInverseSqrt())
    var id = MatrixType.identity(rows, cols)
    VERIFY_IS_APPROX(id.selfadjointView[Lower]().operatorNorm(), RealScalar(1))
    var eiSymmUninitialized = SelfAdjointEigenSolver[MatrixType]()
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.info())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.eigenvalues())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.eigenvectors())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.operatorSqrt())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.operatorInverseSqrt())
    eiSymmUninitialized.compute(symmA, False)
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.eigenvectors())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.operatorSqrt())
    VERIFY_RAISES_ASSERT(lambda: eiSymmUninitialized.operatorInverseSqrt())
    var tridiag = Tridiagonalization[MatrixType](symmC)
    VERIFY_IS_APPROX(tridiag.diagonal(), tridiag.matrixT().diagonal())
    VERIFY_IS_APPROX(tridiag.subDiagonal(), tridiag.matrixT().diagonal[-1]())
    var T = Matrix[RealScalar, Dynamic, Dynamic](tridiag.matrixT())
    if rows > 1 and cols > 1:

    VERIFY_IS_APPROX(tridiag.diagonal(), T.diagonal())
    VERIFY_IS_APPROX(tridiag.subDiagonal(), T.diagonal[1]())
    VERIFY_IS_APPROX(MatrixType(symmC.selfadjointView[Lower]()), tridiag.matrixQ() * tridiag.matrixT().eval() * MatrixType(tridiag.matrixQ()).adjoint())
    VERIFY_IS_APPROX(MatrixType(symmC.selfadjointView[Lower]()), tridiag.matrixQ() * tridiag.matrixT() * tridiag.matrixQ().adjoint())
    if rows > 1:
        var eiSymmTridiag = SelfAdjointEigenSolver[MatrixType]()
        eiSymmTridiag.computeFromTridiagonal(tridiag.matrixT().diagonal(), tridiag.matrixT().diagonal(-1), ComputeEigenvectors)
        VERIFY_IS_APPROX(eiSymm.eigenvalues(), eiSymmTridiag.eigenvalues())
        VERIFY_IS_APPROX(tridiag.matrixT(), eiSymmTridiag.eigenvectors().real() * eiSymmTridiag.eigenvalues().asDiagonal() * eiSymmTridiag.eigenvectors().real().transpose())
    if rows > 1 and rows < 20:
        symmC[0,0] = Float64.nan if issubtype[RealScalar, Float64] else Float32.nan
        var eiSymmNaN = SelfAdjointEigenSolver[MatrixType](symmC)
        VERIFY_IS_EQUAL(eiSymmNaN.info(), NoConvergence)
    {
        var eig = SelfAdjointEigenSolver[MatrixType](a.adjoint() * a)
        eig.compute(a.adjoint() * a)
    }
    {
        a.setZero()
        var ei3 = SelfAdjointEigenSolver[MatrixType](a)
        VERIFY_IS_EQUAL(ei3.info(), Success)
        VERIFY_IS_MUCH_SMALLER_THAN(ei3.eigenvalues().norm(), RealScalar(1))
        VERIFY((ei3.eigenvectors().transpose() * ei3.eigenvectors().transpose()).eval().isIdentity())
    }

def bug_854[_: Int]():
    var m = Matrix[Float64, 3, 3]()
    m[0,0] = 850.961; m[0,1] = 51.966; m[0,2] = 0
    m[1,0] = 51.966; m[1,1] = 254.841; m[1,2] = 0
    m[2,0] = 0; m[2,1] = 0; m[2,2] = 0
    selfadjointeigensolver_essential_check(m)

def bug_1014[_: Int]():
    var m = Matrix[Float64, 3, 3]()
    m[0,0] = 0.11111111111111114658; m[0,1] = 0; m[0,2] = 0
    m[1,0] = 0; m[1,1] = 0.11111111111111109107; m[1,2] = 0
    m[2,0] = 0; m[2,1] = 0; m[2,2] = 0.11111111111111107719
    selfadjointeigensolver_essential_check(m)

def bug_1225[_: Int]():
    var m1 = Matrix[Float64, 3, 3]()
    var m2 = Matrix[Float64, 3, 3]()
    m1.setRandom()
    m1 = m1 * m1.transpose()
    m2 = m1.triangularView[Upper]()
    var eig1 = SelfAdjointEigenSolver[Matrix[Float64, 3, 3]](m1)
    var eig2 = SelfAdjointEigenSolver[Matrix[Float64, 3, 3]](m2.selfadjointView[Upper]())
    VERIFY_IS_APPROX(eig1.eigenvalues(), eig2.eigenvalues())

def bug_1204[_: Int]():
    var A = SparseMatrix[Float64](2, 2)
    A.setIdentity()
    var eig = SelfAdjointEigenSolver[SparseMatrix[Float64]](A)

def test_eigensolver_selfadjoint():
    var s: Int = 0
    for i in range(g_repeat):
        selfadjointeigensolver(Matrix[Float32, 1, 1]())
        selfadjointeigensolver(Matrix[Float64, 1, 1]())
        selfadjointeigensolver(Matrix2f())
        selfadjointeigensolver(Matrix2d())
        selfadjointeigensolver(Matrix3f())
        selfadjointeigensolver(Matrix3d())
        selfadjointeigensolver(Matrix4d())
        s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE // 4)
        selfadjointeigensolver(MatrixXf(s, s))
        selfadjointeigensolver(MatrixXd(s, s))
        selfadjointeigensolver(MatrixXcd(s, s))
        selfadjointeigensolver(Matrix[Complex[Float64], Dynamic, Dynamic, RowMajor](s, s))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        selfadjointeigensolver(MatrixXd(1, 1))
        selfadjointeigensolver(MatrixXd(2, 2))
        selfadjointeigensolver(Matrix[Float64, 1, 1]())
        selfadjointeigensolver(Matrix[Float64, 2, 2]())
    bug_854[0]()
    bug_1014[0]()
    bug_1204[0]()
    bug_1225[0]()
    s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE // 4)
    var tmp1 = SelfAdjointEigenSolver[MatrixXf](s)
    var tmp2 = Tridiagonalization[MatrixXf](s)
    TEST_SET_BUT_UNUSED_VARIABLE(s)