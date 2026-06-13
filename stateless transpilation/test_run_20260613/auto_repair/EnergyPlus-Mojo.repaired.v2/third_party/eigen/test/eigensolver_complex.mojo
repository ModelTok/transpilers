from main import *
from limits import numeric_limits, QuietNaN
from ...Eigen.Eigenvalues import ComplexEigenSolver, ComplexSchur
from ...Eigen.LU import *  // Not used directly, but keep include
from random import random as internal_random
from math import max as numext_maxi

// Helper to replicate pair
@value
struct Pair[Index: Intable]:
    var first: Index
    var second: Index

def find_pivot[MatrixType: AnyRegType](tol: Scalar, diffs: MatrixType, col: Index = 0) -> Bool:
    """
    template<MatrixType> bool find_pivot(MatrixType::Scalar tol, MatrixType &diffs, Index col=0)
    """
    var match = diffs.diagonal().sum() <= tol
    if match or col == diffs.cols():
        return match
    else:
        var n = diffs.cols()
        var transpositions = List[Pair[Index]]()
        for i in range(col, n):
            var best_index = Index(0)
            if diffs.col(col).segment(col, n - i).minCoeff(&best_index) > tol:
                break
            best_index += col
            diffs.row(col).swap(diffs.row(best_index))
            if find_pivot(tol, diffs, col + 1):
                return True
            diffs.row(col).swap(diffs.row(best_index))
            diffs.row(n - (i - col) - 1).swap(diffs.row(best_index))
            transpositions.append(Pair[Index](n - (i - col) - 1, best_index))
        for k in range(len(transpositions) - 1, -1, -1):
            diffs.row(transpositions[k].first).swap(diffs.row(transpositions[k].second))
    return False

/* Check that two column vectors are approximately equal upto permutations.
 * Initially, this method checked that the k-th power sums are equal for all k = 1, ..., vec1.rows(),
 * however this strategy is numerically inacurate because of numerical cancellation issues.
 */
def verify_is_approx_upto_permutation[VectorType: AnyRegType](vec1: VectorType, vec2: VectorType):
    typedef Scalar = VectorType.Scalar
    typedef RealScalar = NumTraits[Scalar].Real
    VERIFY(vec1.cols() == 1)
    VERIFY(vec2.cols() == 1)
    VERIFY(vec1.rows() == vec2.rows())
    var n = vec1.rows()
    var tol = test_precision[RealScalar]() * test_precision[RealScalar]() * numext_maxi(vec1.squaredNorm(), vec2.squaredNorm())
    var diffs = (vec1.rowwise().replicate(n) - vec2.rowwise().replicate(n).transpose()).cwiseAbs2()
    VERIFY(find_pivot(tol, diffs))

def eigensolver[MatrixType: AnyRegType](m: MatrixType):
    /* this test covers the following files:
       ComplexEigenSolver.h, and indirectly ComplexSchur.h
    */
    var rows = m.rows()
    var cols = m.cols()
    typedef Scalar = MatrixType.Scalar
    typedef RealScalar = NumTraits[Scalar].Real
    var a = MatrixType.Random(rows, cols)
    var symmA = a.adjoint() * a
    var ei0 = ComplexEigenSolver[MatrixType](symmA)
    VERIFY_IS_EQUAL(ei0.info(), Success)
    VERIFY_IS_APPROX(symmA * ei0.eigenvectors(), ei0.eigenvectors() * ei0.eigenvalues().asDiagonal())
    var ei1 = ComplexEigenSolver[MatrixType](a)
    VERIFY_IS_EQUAL(ei1.info(), Success)
    VERIFY_IS_APPROX(a * ei1.eigenvectors(), ei1.eigenvectors() * ei1.eigenvalues().asDiagonal())
    verify_is_approx_upto_permutation(a.eigenvalues(), ei1.eigenvalues())
    var ei2 = ComplexEigenSolver[MatrixType]()
    ei2.setMaxIterations(ComplexSchur[MatrixType].m_maxIterationsPerRow * rows)
    ei2.compute(a)
    VERIFY_IS_EQUAL(ei2.info(), Success)
    VERIFY_IS_EQUAL(ei2.eigenvectors(), ei1.eigenvectors())
    VERIFY_IS_EQUAL(ei2.eigenvalues(), ei1.eigenvalues())
    if rows > 2:
        ei2.setMaxIterations(1)
        ei2.compute(a)
        VERIFY_IS_EQUAL(ei2.info(), NoConvergence)
        VERIFY_IS_EQUAL(ei2.getMaxIterations(), 1)
    var eiNoEivecs = ComplexEigenSolver[MatrixType](a, false)
    VERIFY_IS_EQUAL(eiNoEivecs.info(), Success)
    VERIFY_IS_APPROX(ei1.eigenvalues(), eiNoEivecs.eigenvalues())
    var z = MatrixType.Zero(rows, cols)
    var eiz = ComplexEigenSolver[MatrixType](z)
    VERIFY((eiz.eigenvalues().cwiseEqual(0)).all())
    var id = MatrixType.Identity(rows, cols)
    VERIFY_IS_APPROX(id.operatorNorm(), RealScalar(1))
    if rows > 1 and rows < 20:
        a(0, 0) = numeric_limits[RealScalar].quiet_NaN()
        var eiNaN = ComplexEigenSolver[MatrixType](a)
        VERIFY_IS_EQUAL(eiNaN.info(), NoConvergence)
    {
        var eig = ComplexEigenSolver[MatrixType](a.adjoint() * a)
        eig.compute(a.adjoint() * a)
    }
    {
        a.setZero()
        var ei3 = ComplexEigenSolver[MatrixType](a)
        VERIFY_IS_EQUAL(ei3.info(), Success)
        VERIFY_IS_MUCH_SMALLER_THAN(ei3.eigenvalues().norm(), RealScalar(1))
        VERIFY((ei3.eigenvectors().transpose() * ei3.eigenvectors().transpose()).eval().isIdentity())
    }

def eigensolver_verify_assert[MatrixType: AnyRegType](m: MatrixType):
    var eig = ComplexEigenSolver[MatrixType]()
    VERIFY_RAISES_ASSERT(eig.eigenvectors())
    VERIFY_RAISES_ASSERT(eig.eigenvalues())
    var a = MatrixType.Random(m.rows(), m.cols())
    eig.compute(a, false)
    VERIFY_RAISES_ASSERT(eig.eigenvectors())

def test_eigensolver_complex():
    var s = 0
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(eigensolver(Matrix4cf()))
        s = internal_random[Index](1, EIGEN_TEST_MAX_SIZE / 4)
        CALL_SUBTEST_2(eigensolver(MatrixXcd(s, s)))
        CALL_SUBTEST_3(eigensolver(Matrix[cfloat32, 1, 1]()))
        CALL_SUBTEST_4(eigensolver(Matrix3f()))
        _ = s // TEST_SET_BUT_UNUSED_VARIABLE(s)
    CALL_SUBTEST_1(eigensolver_verify_assert(Matrix4cf()))
    s = internal_random[Index](1, EIGEN_TEST_MAX_SIZE / 4)
    CALL_SUBTEST_2(eigensolver_verify_assert(MatrixXcd(s, s)))
    CALL_SUBTEST_3(eigensolver_verify_assert(Matrix[cfloat32, 1, 1]()))
    CALL_SUBTEST_4(eigensolver_verify_assert(Matrix3f()))
    var tmp = ComplexEigenSolver[MatrixXf](s)
    CALL_SUBTEST_5(tmp)
    _ = s // TEST_SET_BUT_UNUSED_VARIABLE(s)