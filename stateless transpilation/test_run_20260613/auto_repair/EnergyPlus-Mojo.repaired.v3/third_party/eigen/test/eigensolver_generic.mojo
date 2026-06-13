from main import VERIFY_IS_EQUAL, VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT, VERIFY_IS_MUCH_SMALLER_THAN, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, TEST_SET_BUT_UNUSED_VARIABLE, g_repeat, EIGEN_TEST_MAX_SIZE
from ...Eigen import EigenSolver, Matrix, NumTraits, RealSchur, internal
from stdlib import math

def eigensolver[MatrixType: AnyType](m: MatrixType):
    """this test covers the following files:
       EigenSolver.h
    """
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias RealVectorType = Matrix[RealScalar, MatrixType.RowsAtCompileTime, 1]
    alias Complex = math.Complex[RealScalar]  # using Mojo's complex type
    var a: MatrixType = MatrixType.Random(rows, cols)
    var a1: MatrixType = MatrixType.Random(rows, cols)
    var symmA: MatrixType = a.adjoint() * a + a1.adjoint() * a1
    var ei0: EigenSolver[MatrixType] = EigenSolver[MatrixType](symmA)
    VERIFY_IS_EQUAL(ei0.info(), Success)
    VERIFY_IS_APPROX(symmA * ei0.pseudoEigenvectors(), ei0.pseudoEigenvectors() * ei0.pseudoEigenvalueMatrix())
    VERIFY_IS_APPROX((symmA.template cast[Complex]()) * (ei0.pseudoEigenvectors().template cast[Complex]()),
        (ei0.pseudoEigenvectors().template cast[Complex]()) * (ei0.eigenvalues().asDiagonal()))
    var ei1: EigenSolver[MatrixType] = EigenSolver[MatrixType](a)
    VERIFY_IS_EQUAL(ei1.info(), Success)
    VERIFY_IS_APPROX(a * ei1.pseudoEigenvectors(), ei1.pseudoEigenvectors() * ei1.pseudoEigenvalueMatrix())
    VERIFY_IS_APPROX(a.template cast[Complex]() * ei1.eigenvectors(),
                     ei1.eigenvectors() * ei1.eigenvalues().asDiagonal())
    VERIFY_IS_APPROX(ei1.eigenvectors().colwise().norm(), RealVectorType.Ones(rows).transpose())
    VERIFY_IS_APPROX(a.eigenvalues(), ei1.eigenvalues())
    var ei2: EigenSolver[MatrixType] = EigenSolver[MatrixType]()
    ei2.setMaxIterations(RealSchur[MatrixType].m_maxIterationsPerRow * rows).compute(a)
    VERIFY_IS_EQUAL(ei2.info(), Success)
    VERIFY_IS_EQUAL(ei2.eigenvectors(), ei1.eigenvectors())
    VERIFY_IS_EQUAL(ei2.eigenvalues(), ei1.eigenvalues())
    if rows > 2:
        ei2.setMaxIterations(1).compute(a)
        VERIFY_IS_EQUAL(ei2.info(), NoConvergence)
        VERIFY_IS_EQUAL(ei2.getMaxIterations(), 1)
    var eiNoEivecs: EigenSolver[MatrixType] = EigenSolver[MatrixType](a, false)
    VERIFY_IS_EQUAL(eiNoEivecs.info(), Success)
    VERIFY_IS_APPROX(ei1.eigenvalues(), eiNoEivecs.eigenvalues())
    VERIFY_IS_APPROX(ei1.pseudoEigenvalueMatrix(), eiNoEivecs.pseudoEigenvalueMatrix())
    var id: MatrixType = MatrixType.Identity(rows, cols)
    VERIFY_IS_APPROX(id.operatorNorm(), RealScalar(1))
    if rows > 2 and rows < 20:
        a(0, 0) = math.nan  # quiet_NaN for RealScalar
        var eiNaN: EigenSolver[MatrixType] = EigenSolver[MatrixType](a)
        VERIFY_IS_EQUAL(eiNaN.info(), NoConvergence)
    {
        var eig: EigenSolver[MatrixType] = EigenSolver[MatrixType](a.adjoint() * a)
        eig.compute(a.adjoint() * a)
    }
    {
        a.setZero()
        var ei3: EigenSolver[MatrixType] = EigenSolver[MatrixType](a)
        VERIFY_IS_EQUAL(ei3.info(), Success)
        VERIFY_IS_MUCH_SMALLER_THAN(ei3.eigenvalues().norm(), RealScalar(1))
        VERIFY((ei3.eigenvectors().transpose() * ei3.eigenvectors().transpose()).eval().isIdentity())
    }

def eigensolver_verify_assert[MatrixType: AnyType](m: MatrixType):
    var eig: EigenSolver[MatrixType] = EigenSolver[MatrixType]()
    VERIFY_RAISES_ASSERT(eig.eigenvectors())
    VERIFY_RAISES_ASSERT(eig.pseudoEigenvectors())
    VERIFY_RAISES_ASSERT(eig.pseudoEigenvalueMatrix())
    VERIFY_RAISES_ASSERT(eig.eigenvalues())
    var a: MatrixType = MatrixType.Random(m.rows(), m.cols())
    eig.compute(a, false)
    VERIFY_RAISES_ASSERT(eig.eigenvectors())
    VERIFY_RAISES_ASSERT(eig.pseudoEigenvectors())

def test_eigensolver_generic():
    var s: Int = 0
    for i in range(g_repeat):
        CALL_SUBTEST_1(eigensolver[Matrix4f](Matrix4f()))
        s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 4)
        CALL_SUBTEST_2(eigensolver[MatrixXd](MatrixXd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        CALL_SUBTEST_2(eigensolver[MatrixXd](MatrixXd(1, 1)))
        CALL_SUBTEST_2(eigensolver[MatrixXd](MatrixXd(2, 2)))
        CALL_SUBTEST_3(eigensolver[Matrix[Float64, 1, 1]](Matrix[Float64, 1, 1]()))
        CALL_SUBTEST_4(eigensolver[Matrix2d](Matrix2d()))
    CALL_SUBTEST_1(eigensolver_verify_assert[Matrix4f](Matrix4f()))
    s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 4)
    CALL_SUBTEST_2(eigensolver_verify_assert[MatrixXd](MatrixXd(s, s)))
    CALL_SUBTEST_3(eigensolver_verify_assert[Matrix[Float64, 1, 1]](Matrix[Float64, 1, 1]()))
    CALL_SUBTEST_4(eigensolver_verify_assert[Matrix2d](Matrix2d()))
    CALL_SUBTEST_5(EigenSolver[MatrixXf] tmp(s))
    CALL_SUBTEST_2(
        {
            var A: MatrixXd = MatrixXd(1, 1)
            A(0, 0) = math.sqrt(-1.0)  # is Not-a-Number
            var solver: Eigen.EigenSolver[MatrixXd] = Eigen.EigenSolver[MatrixXd](A)
            VERIFY_IS_EQUAL(solver.info(), NumericalIssue)
        }
    )
    if EIGEN_TEST_PART_2:
        {
            var a: MatrixXd = MatrixXd(3, 3)
            a << 0, 0, 1,
                1, 1, 1,
                1, 1e+200, 1
            var eig: Eigen.EigenSolver[MatrixXd] = Eigen.EigenSolver[MatrixXd](a)
            var scale: Float64 = 1e-200  # scale to avoid overflow during the comparisons
            VERIFY_IS_APPROX(a * eig.pseudoEigenvectors() * scale, eig.pseudoEigenvectors() * eig.pseudoEigenvalueMatrix() * scale)
            VERIFY_IS_APPROX(a * eig.eigenvectors() * scale, eig.eigenvectors() * eig.eigenvalues().asDiagonal() * scale)
        }
        {
            var a: MatrixXd = MatrixXd(2, 2)
            a << 1, 1,
                -1, -1
            var eig: Eigen.EigenSolver[MatrixXd] = Eigen.EigenSolver[MatrixXd](a)
            VERIFY_IS_APPROX(eig.pseudoEigenvectors().squaredNorm(), 2.0)
            VERIFY_IS_APPROX((a * eig.pseudoEigenvectors()).norm() + 1.0, 1.0)
            VERIFY_IS_APPROX((eig.pseudoEigenvectors() * eig.pseudoEigenvalueMatrix()).norm() + 1.0, 1.0)
            VERIFY_IS_APPROX((a * eig.eigenvectors()).norm() + 1.0, 1.0)
            VERIFY_IS_APPROX((eig.eigenvectors() * eig.eigenvalues().asDiagonal()).norm() + 1.0, 1.0)
        }
    TEST_SET_BUT_UNUSED_VARIABLE(s)