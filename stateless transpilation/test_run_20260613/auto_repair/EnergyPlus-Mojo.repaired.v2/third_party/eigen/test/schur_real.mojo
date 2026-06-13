from Eigen import Matrix4f, MatrixXd, MatrixXf, RealSchur, Index, Scalar, Success, NoConvergence, internal, StrictlyLower, RowMajor

# Test macros (defined in main.h in C++)
let g_repeat: Int = 1
let EIGEN_TEST_MAX_SIZE: Int = 50

def VERIFY(condition: Bool):
    assert condition

def VERIFY_IS_EQUAL(a: AnyType, b: AnyType):
    assert a == b

def VERIFY_IS_APPROX(a: AnyType, b: AnyType):
    # approximate comparison (placeholder)
    assert a == b

def VERIFY_RAISES_ASSERT(expr: fn() -> None):
    try:
        expr()
        assert False, "Expected assertion"
    except:

def CALL_SUBTEST_1(test: fn() -> None):
    test()

def CALL_SUBTEST_2(test: fn() -> None):
    test()

def CALL_SUBTEST_3(test: fn() -> None):
    test()

def CALL_SUBTEST_4(test: fn() -> None):
    test()

def CALL_SUBTEST_5(test: fn() -> None):
    test()

def verifyIsQuasiTriangular[MatrixType: AnyType](T: MatrixType):
    let size = T.cols()
    alias Scalar = MatrixType.Scalar
    for row in range(2, size):
        for col in range(0, row - 1):
            VERIFY(T[row, col] == Scalar(0))
    for row in range(1, size):
        if T[row, row-1] != Scalar(0):
            VERIFY(row == size-1 or T[row+1, row] == 0)
            let tr = T[row-1, row-1] + T[row, row]
            let det = T[row-1, row-1] * T[row, row] - T[row-1, row] * T[row, row-1]
            VERIFY(4 * det > tr * tr)

def schur[MatrixType: AnyType](size: Int = MatrixType.ColsAtCompileTime):
    for counter in range(0, g_repeat):
        var A = MatrixType.Random(size, size)
        var schurOfA = RealSchur[MatrixType](A)
        VERIFY_IS_EQUAL(schurOfA.info(), Success)
        var U = schurOfA.matrixU()
        var T = schurOfA.matrixT()
        verifyIsQuasiTriangular(T)
        VERIFY_IS_APPROX(A, U * T * U.transpose())
    var rsUninitialized = RealSchur[MatrixType]()
    VERIFY_RAISES_ASSERT(fn() -> None: rsUninitialized.matrixT())
    VERIFY_RAISES_ASSERT(fn() -> None: rsUninitialized.matrixU())
    VERIFY_RAISES_ASSERT(fn() -> None: rsUninitialized.info())
    var A = MatrixType.Random(size, size)
    var rs1 = RealSchur[MatrixType]()
    rs1.compute(A)
    var rs2 = RealSchur[MatrixType](A)
    VERIFY_IS_EQUAL(rs1.info(), Success)
    VERIFY_IS_EQUAL(rs2.info(), Success)
    VERIFY_IS_EQUAL(rs1.matrixT(), rs2.matrixT())
    VERIFY_IS_EQUAL(rs1.matrixU(), rs2.matrixU())
    var rs3 = RealSchur[MatrixType]()
    rs3.setMaxIterations(RealSchur[MatrixType].m_maxIterationsPerRow * size).compute(A)
    VERIFY_IS_EQUAL(rs3.info(), Success)
    VERIFY_IS_EQUAL(rs3.matrixT(), rs1.matrixT())
    VERIFY_IS_EQUAL(rs3.matrixU(), rs1.matrixU())
    if size > 2:
        rs3.setMaxIterations(1).compute(A)
        VERIFY_IS_EQUAL(rs3.info(), NoConvergence)
        VERIFY_IS_EQUAL(rs3.getMaxIterations(), 1)
    var Atriangular = A
    Atriangular.triangularView[StrictlyLower]().setZero()
    rs3.setMaxIterations(1).compute(Atriangular)
    VERIFY_IS_EQUAL(rs3.info(), Success)
    VERIFY_IS_APPROX(rs3.matrixT(), Atriangular)
    VERIFY_IS_EQUAL(rs3.matrixU(), MatrixType.Identity(size, size))
    var rsOnlyT = RealSchur[MatrixType](A, False)
    VERIFY_IS_EQUAL(rsOnlyT.info(), Success)
    VERIFY_IS_EQUAL(rs1.matrixT(), rsOnlyT.matrixT())
    VERIFY_RAISES_ASSERT(fn() -> None: rsOnlyT.matrixU())
    if size > 2 and size < 20:
        alias Scalar = MatrixType.Scalar
        A[0, 0] = std.numeric_limits[Scalar].quiet_NaN()
        var rsNaN = RealSchur[MatrixType](A)
        VERIFY_IS_EQUAL(rsNaN.info(), NoConvergence)

def test_schur_real():
    CALL_SUBTEST_1(fn() -> None: schur[Matrix4f]())
    CALL_SUBTEST_2(fn() -> None: schur[MatrixXd](internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 4)))
    CALL_SUBTEST_3(fn() -> None: schur[Matrix[float32, 1, 1]]())
    CALL_SUBTEST_4(fn() -> None: schur[Matrix[float64, 3, 3, RowMajor]]())
    CALL_SUBTEST_5(fn() -> None: RealSchur[MatrixXf](10))