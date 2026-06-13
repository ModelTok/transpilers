from main import *
from limits import *
from Eigen.Eigenvalues import *

def schur[MatrixType: AnyType](size: Int = MatrixType.ColsAtCompileTime) raises:
    type ComplexScalar = ComplexSchur[MatrixType].ComplexScalar
    type ComplexMatrixType = ComplexSchur[MatrixType].ComplexMatrixType
    for counter in range(g_repeat):
        var A: MatrixType = MatrixType.Random(size, size)
        var schurOfA = ComplexSchur[MatrixType](A)
        VERIFY_IS_EQUAL(schurOfA.info(), Success)
        var U: ComplexMatrixType = schurOfA.matrixU()
        var T: ComplexMatrixType = schurOfA.matrixT()
        for row in range(1, size):
            for col in range(0, row):
                VERIFY(T[row, col] == (MatrixType.Scalar(0)))
        VERIFY_IS_APPROX(A.cast[ComplexScalar](), U * T * U.adjoint())
    var csUninitialized = ComplexSchur[MatrixType]()
    VERIFY_RAISES_ASSERT(csUninitialized.matrixT())
    VERIFY_RAISES_ASSERT(csUninitialized.matrixU())
    VERIFY_RAISES_ASSERT(csUninitialized.info())
    var A: MatrixType = MatrixType.Random(size, size)
    var cs1 = ComplexSchur[MatrixType]()
    cs1.compute(A)
    var cs2 = ComplexSchur[MatrixType](A)
    VERIFY_IS_EQUAL(cs1.info(), Success)
    VERIFY_IS_EQUAL(cs2.info(), Success)
    VERIFY_IS_EQUAL(cs1.matrixT(), cs2.matrixT())
    VERIFY_IS_EQUAL(cs1.matrixU(), cs2.matrixU())
    var cs3 = ComplexSchur[MatrixType]()
    cs3.setMaxIterations(ComplexSchur[MatrixType].m_maxIterationsPerRow * size).compute(A)
    VERIFY_IS_EQUAL(cs3.info(), Success)
    VERIFY_IS_EQUAL(cs3.matrixT(), cs1.matrixT())
    VERIFY_IS_EQUAL(cs3.matrixU(), cs1.matrixU())
    cs3.setMaxIterations(1).compute(A)
    VERIFY_IS_EQUAL(cs3.info(), (size > 1 ? NoConvergence : Success))
    VERIFY_IS_EQUAL(cs3.getMaxIterations(), 1)
    var Atriangular: MatrixType = A
    Atriangular.triangularView[StrictlyLower]().setZero()
    cs3.setMaxIterations(1).compute(Atriangular)
    VERIFY_IS_EQUAL(cs3.info(), Success)
    VERIFY_IS_EQUAL(cs3.matrixT(), Atriangular.cast[ComplexScalar]())
    VERIFY_IS_EQUAL(cs3.matrixU(), ComplexMatrixType.Identity(size, size))
    var csOnlyT = ComplexSchur[MatrixType](A, False)
    VERIFY_IS_EQUAL(csOnlyT.info(), Success)
    VERIFY_IS_EQUAL(cs1.matrixT(), csOnlyT.matrixT())
    VERIFY_RAISES_ASSERT(csOnlyT.matrixU())
    if size > 1 and size < 20:
        A[0, 0] = Float64.quiet_NaN  # numeric_limits<...>::quiet_NaN()
        var csNaN = ComplexSchur[MatrixType](A)
        VERIFY_IS_EQUAL(csNaN.info(), NoConvergence)

def test_schur_complex() raises:
    CALL_SUBTEST_1(( schur[Matrix4cd]() ))
    CALL_SUBTEST_2(( schur[MatrixXcf](internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 4)) ))
    CALL_SUBTEST_3(( schur[Matrix[complex[float32], 1, 1]]() ))
    CALL_SUBTEST_4(( schur[Matrix[float32, 3, 3, RowMajor]]() ))
    CALL_SUBTEST_5(ComplexSchur[MatrixXf](10))