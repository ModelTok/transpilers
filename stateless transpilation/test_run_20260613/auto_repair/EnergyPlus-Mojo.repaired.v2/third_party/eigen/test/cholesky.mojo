# EIGEN_NO_ASSERTION_CHECKING not directly translatable; Mojo has its own assertion handling
# TEST_ENABLE_TEMPORARY_TRACKING not directly translatable
from main import *
from Eigen.Cholesky import *
from Eigen.QR import *

def matrix_l1_norm[MatrixType: AnyType, UpLo: Int](m: MatrixType) -> MatrixType.RealScalar:
    if m.cols() == 0:
        return MatrixType.RealScalar(0)
    MatrixType symm = m.template selfadjointView[UpLo]()
    return symm.cwiseAbs().colwise().sum().maxCoeff()

def test_chol_update[MatrixType: AnyType, CholType: AnyType](symm: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    MatrixType symmLo = symm.template triangularView[Lower]()
    MatrixType symmUp = symm.template triangularView[Upper]()
    MatrixType symmCpy = symm
    CholType[MatrixType, Lower] chollo(symmLo)
    CholType[MatrixType, Upper] cholup(symmUp)
    for k in range(0, 10):
        VectorType vec = VectorType.Random(symm.rows())
        RealScalar sigma = internal.random[RealScalar]()
        symmCpy += sigma * vec * vec.adjoint()
        CholType[MatrixType, Lower] chol(symmCpy)
        if chol.info() != Success:
            break
        chollo.rankUpdate(vec, sigma)
        VERIFY_IS_APPROX(symmCpy, chollo.reconstructedMatrix())
        cholup.rankUpdate(vec, sigma)
        VERIFY_IS_APPROX(symmCpy, cholup.reconstructedMatrix())

def cholesky[MatrixType: AnyType](m: MatrixType):
    """ this test covers the following files:
     LLT.h LDLT.h
  """
    Index rows = m.rows()
    Index cols = m.cols()
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias SquareMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    MatrixType a0 = MatrixType.Random(rows, cols)
    VectorType vecB = VectorType.Random(rows), vecX(rows)
    MatrixType matB = MatrixType.Random(rows, cols), matX(rows, cols)
    SquareMatrixType symm = a0 * a0.adjoint()
    for k in range(0, 3):
        MatrixType a1 = MatrixType.Random(rows, cols)
        symm += a1 * a1.adjoint()
    {
        SquareMatrixType symmUp = symm.template triangularView[Upper]()
        SquareMatrixType symmLo = symm.template triangularView[Lower]()
        LLT[SquareMatrixType, Lower] chollo(symmLo)
        VERIFY_IS_APPROX(symm, chollo.reconstructedMatrix())
        vecX = chollo.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
        matX = chollo.solve(matB)
        VERIFY_IS_APPROX(symm * matX, matB)
        MatrixType symmLo_inverse = chollo.solve(MatrixType.Identity(rows, cols))
        RealScalar rcond = (RealScalar(1) / matrix_l1_norm[MatrixType, Lower](symmLo)) / matrix_l1_norm[MatrixType, Lower](symmLo_inverse)
        RealScalar rcond_est = chollo.rcond()
        VERIFY(rcond_est >= rcond / 10 and rcond_est <= rcond * 10)
        LLT[SquareMatrixType, Upper] cholup(symmUp)
        VERIFY_IS_APPROX(symm, cholup.reconstructedMatrix())
        vecX = cholup.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
        matX = cholup.solve(matB)
        VERIFY_IS_APPROX(symm * matX, matB)
        MatrixType symmUp_inverse = cholup.solve(MatrixType.Identity(rows, cols))
        rcond = (RealScalar(1) / matrix_l1_norm[MatrixType, Upper](symmUp)) / matrix_l1_norm[MatrixType, Upper](symmUp_inverse)
        rcond_est = cholup.rcond()
        VERIFY(rcond_est >= rcond / 10 and rcond_est <= rcond * 10)
        MatrixType neg = -symmLo
        chollo.compute(neg)
        VERIFY(neg.size() == 0 or chollo.info() == NumericalIssue)
        VERIFY_IS_APPROX(MatrixType(chollo.matrixL().transpose().conjugate()), MatrixType(chollo.matrixU()))
        VERIFY_IS_APPROX(MatrixType(chollo.matrixU().transpose().conjugate()), MatrixType(chollo.matrixL()))
        VERIFY_IS_APPROX(MatrixType(cholup.matrixL().transpose().conjugate()), MatrixType(cholup.matrixU()))
        VERIFY_IS_APPROX(MatrixType(cholup.matrixU().transpose().conjugate()), MatrixType(cholup.matrixL()))
        MatrixType m1 = MatrixType.Random(rows, cols), m2(rows, cols)
        m2 = m1
        m2 += symmLo.template selfadjointView[Lower]().llt().solve(matB)
        VERIFY_IS_APPROX(m2, m1 + symmLo.template selfadjointView[Lower]().llt().solve(matB))
        m2 = m1
        m2 -= symmLo.template selfadjointView[Lower]().llt().solve(matB)
        VERIFY_IS_APPROX(m2, m1 - symmLo.template selfadjointView[Lower]().llt().solve(matB))
        m2 = m1
        m2.noalias() += symmLo.template selfadjointView[Lower]().llt().solve(matB)
        VERIFY_IS_APPROX(m2, m1 + symmLo.template selfadjointView[Lower]().llt().solve(matB))
        m2 = m1
        m2.noalias() -= symmLo.template selfadjointView[Lower]().llt().solve(matB)
        VERIFY_IS_APPROX(m2, m1 - symmLo.template selfadjointView[Lower]().llt().solve(matB))
    }
    {
        int sign = 1 if internal.random[int]() % 2 else -1
        if sign == -1:
            symm = -symm  # test a negative matrix
        SquareMatrixType symmUp = symm.template triangularView[Upper]()
        SquareMatrixType symmLo = symm.template triangularView[Lower]()
        LDLT[SquareMatrixType, Lower] ldltlo(symmLo)
        VERIFY(ldltlo.info() == Success)
        VERIFY_IS_APPROX(symm, ldltlo.reconstructedMatrix())
        vecX = ldltlo.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
        matX = ldltlo.solve(matB)
        VERIFY_IS_APPROX(symm * matX, matB)
        MatrixType symmLo_inverse = ldltlo.solve(MatrixType.Identity(rows, cols))
        RealScalar rcond = (RealScalar(1) / matrix_l1_norm[MatrixType, Lower](symmLo)) / matrix_l1_norm[MatrixType, Lower](symmLo_inverse)
        RealScalar rcond_est = ldltlo.rcond()
        VERIFY(rcond_est >= rcond / 10 and rcond_est <= rcond * 10)
        LDLT[SquareMatrixType, Upper] ldltup(symmUp)
        VERIFY(ldltup.info() == Success)
        VERIFY_IS_APPROX(symm, ldltup.reconstructedMatrix())
        vecX = ldltup.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
        matX = ldltup.solve(matB)
        VERIFY_IS_APPROX(symm * matX, matB)
        MatrixType symmUp_inverse = ldltup.solve(MatrixType.Identity(rows, cols))
        rcond = (RealScalar(1) / matrix_l1_norm[MatrixType, Upper](symmUp)) / matrix_l1_norm[MatrixType, Upper](symmUp_inverse)
        rcond_est = ldltup.rcond()
        VERIFY(rcond_est >= rcond / 10 and rcond_est <= rcond * 10)
        VERIFY_IS_APPROX(MatrixType(ldltlo.matrixL().transpose().conjugate()), MatrixType(ldltlo.matrixU()))
        VERIFY_IS_APPROX(MatrixType(ldltlo.matrixU().transpose().conjugate()), MatrixType(ldltlo.matrixL()))
        VERIFY_IS_APPROX(MatrixType(ldltup.matrixL().transpose().conjugate()), MatrixType(ldltup.matrixU()))
        VERIFY_IS_APPROX(MatrixType(ldltup.matrixU().transpose().conjugate()), MatrixType(ldltup.matrixL()))
        if MatrixType.RowsAtCompileTime == Dynamic:
            matX = matB
            VERIFY_EVALUATION_COUNT(matX = ldltlo.solve(matX), 0)
            VERIFY_IS_APPROX(matX, ldltlo.solve(matB).eval())
            matX = matB
            VERIFY_EVALUATION_COUNT(matX = ldltup.solve(matX), 0)
            VERIFY_IS_APPROX(matX, ldltup.solve(matB).eval())
        if sign == -1:
            symm = -symm
        if rows >= 3:
            SquareMatrixType A = symm
            Index c = internal.random[Index](0, rows - 2)
            A.bottomRightCorner(c, c).setZero()
            vecX.setRandom()
            vecB = A * vecX
            vecX.setZero()
            ldltlo.compute(A)
            VERIFY_IS_APPROX(A, ldltlo.reconstructedMatrix())
            vecX = ldltlo.solve(vecB)
            VERIFY_IS_APPROX(A * vecX, vecB)
        if rows >= 3:
            Index r = internal.random[Index](1, rows - 1)
            Matrix[Scalar, Dynamic, Dynamic] a = Matrix[Scalar, Dynamic, Dynamic].Random(rows, r)
            SquareMatrixType A = a * a.adjoint()
            vecX.setRandom()
            vecB = A * vecX
            vecX.setZero()
            ldltlo.compute(A)
            VERIFY_IS_APPROX(A, ldltlo.reconstructedMatrix())
            vecX = ldltlo.solve(vecB)
            VERIFY_IS_APPROX(A * vecX, vecB)
        if rows >= 3:
            using std.pow
            using std.sqrt
            RealScalar s = (min)(16, std.numeric_limits[RealScalar].max_exponent10 / 8)
            Matrix[Scalar, Dynamic, Dynamic] a = Matrix[Scalar, Dynamic, Dynamic].Random(rows, rows)
            Matrix[RealScalar, Dynamic, 1] d = Matrix[RealScalar, Dynamic, 1].Random(rows)
            for k in range(0, rows):
                d(k) = d(k) * pow(RealScalar(10), internal.random[RealScalar](-s, s))
            SquareMatrixType A = a * d.asDiagonal() * a.adjoint()
            vecX.setRandom()
            vecB = A * vecX
            vecX.setZero()
            ldltlo.compute(A)
            VERIFY_IS_APPROX(A, ldltlo.reconstructedMatrix())
            vecX = ldltlo.solve(vecB)
            if ldltlo.vectorD().real().cwiseAbs().minCoeff() > RealScalar(0):
                VERIFY_IS_APPROX(A * vecX, vecB)
            else:
                RealScalar large_tol = sqrt(test_precision[RealScalar]())
                VERIFY((A * vecX).isApprox(vecB, large_tol))
                ++g_test_level
                VERIFY_IS_APPROX(A * vecX, vecB)
                --g_test_level
    }
    CALL_SUBTEST(( test_chol_update[SquareMatrixType, LLT](symm) ))
    CALL_SUBTEST(( test_chol_update[SquareMatrixType, LDLT](symm) ))

def cholesky_cplx[MatrixType: AnyType](m: MatrixType):
    cholesky(m)
    Index rows = m.rows()
    Index cols = m.cols()
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias RealMatrixType = Matrix[RealScalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    RealMatrixType a0 = RealMatrixType.Random(rows, cols)
    VectorType vecB = VectorType.Random(rows), vecX(rows)
    MatrixType matB = MatrixType.Random(rows, cols), matX(rows, cols)
    RealMatrixType symm = a0 * a0.adjoint()
    for k in range(0, 3):
        RealMatrixType a1 = RealMatrixType.Random(rows, cols)
        symm += a1 * a1.adjoint()
    {
        RealMatrixType symmLo = symm.template triangularView[Lower]()
        LLT[RealMatrixType, Lower] chollo(symmLo)
        VERIFY_IS_APPROX(symm, chollo.reconstructedMatrix())
        vecX = chollo.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
    }
    {
        int sign = 1 if internal.random[int]() % 2 else -1
        if sign == -1:
            symm = -symm  # test a negative matrix
        RealMatrixType symmLo = symm.template triangularView[Lower]()
        LDLT[RealMatrixType, Lower] ldltlo(symmLo)
        VERIFY(ldltlo.info() == Success)
        VERIFY_IS_APPROX(symm, ldltlo.reconstructedMatrix())
        vecX = ldltlo.solve(vecB)
        VERIFY_IS_APPROX(symm * vecX, vecB)
    }

def cholesky_bug241[MatrixType: AnyType](m: MatrixType):
    eigen_assert(m.rows() == 2 and m.cols() == 2)
    alias Scalar = MatrixType.Scalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    MatrixType matA
    matA << 1, 1, 1, 1
    VectorType vecB
    vecB << 1, 1
    VectorType vecX = matA.ldlt().solve(vecB)
    VERIFY_IS_APPROX(matA * vecX, vecB)

def cholesky_definiteness[MatrixType: AnyType](m: MatrixType):
    eigen_assert(m.rows() == 2 and m.cols() == 2)
    MatrixType mat
    LDLT[MatrixType] ldlt(2)
    {
        mat << 1, 0, 0, -1
        ldlt.compute(mat)
        VERIFY(ldlt.info() == Success)
        VERIFY(!ldlt.isNegative())
        VERIFY(!ldlt.isPositive())
        VERIFY_IS_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat << 1, 2, 2, 1
        ldlt.compute(mat)
        VERIFY(ldlt.info() == Success)
        VERIFY(!ldlt.isNegative())
        VERIFY(!ldlt.isPositive())
        VERIFY_IS_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat << 0, 0, 0, 0
        ldlt.compute(mat)
        VERIFY(ldlt.info() == Success)
        VERIFY(ldlt.isNegative())
        VERIFY(ldlt.isPositive())
        VERIFY_IS_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat << 0, 0, 0, 1
        ldlt.compute(mat)
        VERIFY(ldlt.info() == Success)
        VERIFY(!ldlt.isNegative())
        VERIFY(ldlt.isPositive())
        VERIFY_IS_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat << -1, 0, 0, 0
        ldlt.compute(mat)
        VERIFY(ldlt.info() == Success)
        VERIFY(ldlt.isNegative())
        VERIFY(!ldlt.isPositive())
        VERIFY_IS_APPROX(mat, ldlt.reconstructedMatrix())
    }

def cholesky_faillure_cases[AnyType]():
    MatrixXd mat
    LDLT[MatrixXd] ldlt
    {
        mat.resize(2, 2)
        mat << 0, 1, 1, 0
        ldlt.compute(mat)
        VERIFY_IS_NOT_APPROX(mat, ldlt.reconstructedMatrix())
        VERIFY(ldlt.info() == NumericalIssue)
    }
    #if (!EIGEN_ARCH_i386) or defined(EIGEN_VECTORIZE_SSE2)
    {
        mat.resize(3, 3)
        mat << -1, -3, 3,
               -3, -8.9999999999999999999, 1,
                3, 1, 0
        ldlt.compute(mat)
        VERIFY(ldlt.info() == NumericalIssue)
        VERIFY_IS_NOT_APPROX(mat, ldlt.reconstructedMatrix())
    }
    #endif
    {
        mat.resize(3, 3)
        mat << 1, 2, 3,
               2, 4, 1,
               3, 1, 0
        ldlt.compute(mat)
        VERIFY(ldlt.info() == NumericalIssue)
        VERIFY_IS_NOT_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat.resize(8, 8)
        mat << 0.1, 0, -0.1, 0, 0, 0, 1, 0,
               0, 4.24667, 0, 2.00333, 0, 0, 0, 0,
               -0.1, 0, 0.2, 0, -0.1, 0, 0, 0,
               0, 2.00333, 0, 8.49333, 0, 2.00333, 0, 0,
               0, 0, -0.1, 0, 0.1, 0, 0, 1,
               0, 0, 0, 2.00333, 0, 4.24667, 0, 0,
               1, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 1, 0, 0, 0
        ldlt.compute(mat)
        VERIFY(ldlt.info() == NumericalIssue)
        VERIFY_IS_NOT_APPROX(mat, ldlt.reconstructedMatrix())
    }
    {
        mat.resize(4, 4)
        mat << 1, 2, 0, 1,
               2, 4, 0, 2,
               0, 0, 0, 1,
               1, 2, 1, 1
        ldlt.compute(mat)
        VERIFY(ldlt.info() == NumericalIssue)
        VERIFY_IS_NOT_APPROX(mat, ldlt.reconstructedMatrix())
    }

def cholesky_verify_assert[MatrixType: AnyType]():
    MatrixType tmp
    LLT[MatrixType] llt
    VERIFY_RAISES_ASSERT(llt.matrixL())
    VERIFY_RAISES_ASSERT(llt.matrixU())
    VERIFY_RAISES_ASSERT(llt.solve(tmp))
    VERIFY_RAISES_ASSERT(llt.solveInPlace(&tmp))
    LDLT[MatrixType] ldlt
    VERIFY_RAISES_ASSERT(ldlt.matrixL())
    VERIFY_RAISES_ASSERT(ldlt.permutationP())
    VERIFY_RAISES_ASSERT(ldlt.vectorD())
    VERIFY_RAISES_ASSERT(ldlt.isPositive())
    VERIFY_RAISES_ASSERT(ldlt.isNegative())
    VERIFY_RAISES_ASSERT(ldlt.solve(tmp))
    VERIFY_RAISES_ASSERT(ldlt.solveInPlace(&tmp))

def test_cholesky():
    int s = 0
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(cholesky(Matrix[float64, 1, 1]()))
        CALL_SUBTEST_3(cholesky(Matrix2d()))
        CALL_SUBTEST_3(cholesky_bug241(Matrix2d()))
        CALL_SUBTEST_3(cholesky_definiteness(Matrix2d()))
        CALL_SUBTEST_4(cholesky(Matrix3f()))
        CALL_SUBTEST_5(cholesky(Matrix4d()))
        s = internal.random[int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST_2(cholesky(MatrixXd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal.random[int](1, EIGEN_TEST_MAX_SIZE / 2)
        CALL_SUBTEST_6(cholesky_cplx(MatrixXcd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
    CALL_SUBTEST_2(cholesky(MatrixXd(0, 0)))
    CALL_SUBTEST_4(cholesky_verify_assert[Matrix3f]())
    CALL_SUBTEST_7(cholesky_verify_assert[Matrix3d]())
    CALL_SUBTEST_8(cholesky_verify_assert[MatrixXf]())
    CALL_SUBTEST_2(cholesky_verify_assert[MatrixXd]())
    CALL_SUBTEST_9(LLT[MatrixXf](10))
    CALL_SUBTEST_9(LDLT[MatrixXf](10))
    CALL_SUBTEST_2(cholesky_faillure_cases[Void]())
    TEST_SET_BUT_UNUSED_VARIABLE(nb_temporaries)