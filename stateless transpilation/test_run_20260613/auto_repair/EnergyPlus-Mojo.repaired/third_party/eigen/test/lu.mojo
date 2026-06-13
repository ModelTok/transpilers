from main import *
from Eigen.LU import *

def matrix_l1_norm[type MatrixType](m: MatrixType) -> MatrixType.RealScalar:
    return m.cwiseAbs().colwise().sum().maxCoeff()

def lu_non_invertible[type MatrixType]():
    type RealScalar = MatrixType.RealScalar
    /* this test covers the following files:
       LU.h
    */
    var rows: Index
    var cols: Index
    var cols2: Index
    if MatrixType.RowsAtCompileTime == Dynamic:
        rows = internal.random[Index](2, EIGEN_TEST_MAX_SIZE)
    else:
        rows = MatrixType.RowsAtCompileTime
    if MatrixType.ColsAtCompileTime == Dynamic:
        cols = internal.random[Index](2, EIGEN_TEST_MAX_SIZE)
        cols2 = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    else:
        cols2 = cols = MatrixType.ColsAtCompileTime
    alias RowsAtCompileTime = MatrixType.RowsAtCompileTime
    alias ColsAtCompileTime = MatrixType.ColsAtCompileTime
    type KernelMatrixType = internal.kernel_retval_base[FullPivLU[MatrixType]].ReturnType
    type ImageMatrixType = internal.image_retval_base[FullPivLU[MatrixType]].ReturnType
    type CMatrixType = Matrix[MatrixType.Scalar, ColsAtCompileTime, ColsAtCompileTime]
    type RMatrixType = Matrix[MatrixType.Scalar, RowsAtCompileTime, RowsAtCompileTime]
    var rank: Index = internal.random[Index](1, (min)(rows, cols)-1)
    VERIFY((MatrixType.Zero(rows,cols).fullPivLu().image(MatrixType.Zero(rows,cols)).cols() == 1))
    var kernel: KernelMatrixType = MatrixType.Zero(rows,cols).fullPivLu().kernel()
    VERIFY((kernel.fullPivLu().isInvertible()))
    var m1: MatrixType = MatrixType(rows, cols)
    var m3: MatrixType = MatrixType(rows, cols2)
    var m2: CMatrixType = CMatrixType(cols, cols2)
    createRandomPIMatrixOfRank(rank, rows, cols, m1)
    var lu: FullPivLU[MatrixType]
    lu.setThreshold(RealScalar(0.01))
    lu.compute(m1)
    var u: MatrixType = MatrixType(rows,cols)
    u = lu.matrixLU().triangularView[Upper]()
    var l: RMatrixType = RMatrixType.Identity(rows,rows)
    l.block(0,0,rows,(min)(rows,cols)).triangularView[StrictlyLower]() = lu.matrixLU().block(0,0,rows,(min)(rows,cols))
    VERIFY_IS_APPROX(lu.permutationP() * m1 * lu.permutationQ(), l*u)
    var m1kernel: KernelMatrixType = lu.kernel()
    var m1image: ImageMatrixType = lu.image(m1)
    VERIFY_IS_APPROX(m1, lu.reconstructedMatrix())
    VERIFY(rank == lu.rank())
    VERIFY(cols - lu.rank() == lu.dimensionOfKernel())
    VERIFY(!lu.isInjective())
    VERIFY(!lu.isInvertible())
    VERIFY(!lu.isSurjective())
    VERIFY_IS_MUCH_SMALLER_THAN((m1 * m1kernel), m1)
    VERIFY(m1image.fullPivLu().rank() == rank)
    VERIFY_IS_APPROX(m1 * m1.adjoint() * m1image, m1image)
    m2 = CMatrixType.Random(cols,cols2)
    m3 = m1*m2
    m2 = CMatrixType.Random(cols,cols2)
    m2.block(0,0,m2.rows(),m2.cols()) = lu.solve(m3)
    VERIFY_IS_APPROX(m3, m1*m2)
    m3 = MatrixType.Random(rows,cols2)
    m2 = m1.transpose()*m3
    m3 = MatrixType.Random(rows,cols2)
    lu._solve_impl_transposed[False](m2, m3)
    VERIFY_IS_APPROX(m2, m1.transpose()*m3)
    m3 = MatrixType.Random(rows,cols2)
    m3 = lu.transpose().solve(m2)
    VERIFY_IS_APPROX(m2, m1.transpose()*m3)
    m3 = MatrixType.Random(rows,cols2)
    m2 = m1.adjoint()*m3
    m3 = MatrixType.Random(rows,cols2)
    lu._solve_impl_transposed[True](m2, m3)
    VERIFY_IS_APPROX(m2, m1.adjoint()*m3)
    m3 = MatrixType.Random(rows,cols2)
    m3 = lu.adjoint().solve(m2)
    VERIFY_IS_APPROX(m2, m1.adjoint()*m3)

def lu_invertible[type MatrixType]():
    /* this test covers the following files:
       LU.h
    */
    type RealScalar = NumTraits[MatrixType.Scalar].Real
    var size: Index = MatrixType.RowsAtCompileTime
    if size == Dynamic:
        size = internal.random[Index](1, EIGEN_TEST_MAX_SIZE)
    var m1: MatrixType = MatrixType(size, size)
    var m2: MatrixType = MatrixType(size, size)
    var m3: MatrixType = MatrixType(size, size)
    var lu: FullPivLU[MatrixType]
    lu.setThreshold(RealScalar(0.01))
    while True:
        m1 = MatrixType.Random(size, size)
        lu.compute(m1)
        if lu.isInvertible():
            break
    VERIFY_IS_APPROX(m1, lu.reconstructedMatrix())
    VERIFY(0 == lu.dimensionOfKernel())
    VERIFY(lu.kernel().cols() == 1) // the kernel() should consist of a single (zero) column vector
    VERIFY(size == lu.rank())
    VERIFY(lu.isInjective())
    VERIFY(lu.isSurjective())
    VERIFY(lu.isInvertible())
    VERIFY(lu.image(m1).fullPivLu().isInvertible())
    m3 = MatrixType.Random(size, size)
    m2 = lu.solve(m3)
    VERIFY_IS_APPROX(m3, m1*m2)
    var m1_inverse: MatrixType = lu.inverse()
    VERIFY_IS_APPROX(m2, m1_inverse*m3)
    var rcond: RealScalar = (RealScalar(1) / matrix_l1_norm(m1)) / matrix_l1_norm(m1_inverse)
    var rcond_est: RealScalar = lu.rcond()
    VERIFY(rcond_est > rcond / 10 and rcond_est < rcond * 10)
    lu._solve_impl_transposed[False](m3, m2)
    VERIFY_IS_APPROX(m3, m1.transpose()*m2)
    m3 = MatrixType.Random(size, size)
    m3 = lu.transpose().solve(m2)
    VERIFY_IS_APPROX(m2, m1.transpose()*m3)
    lu._solve_impl_transposed[True](m3, m2)
    VERIFY_IS_APPROX(m3, m1.adjoint()*m2)
    m3 = MatrixType.Random(size, size)
    m3 = lu.adjoint().solve(m2)
    VERIFY_IS_APPROX(m2, m1.adjoint()*m3)
    var m4: MatrixType = MatrixType.Random(size, size)
    VERIFY_IS_APPROX(lu.solve(m3*m4), lu.solve(m3)*m4)

def lu_partial_piv[type MatrixType]():
    /* this test covers the following files:
       PartialPivLU.h
    */
    type RealScalar = NumTraits[MatrixType.Scalar].Real
    var size: Index = internal.random[Index](1,4)
    var m1: MatrixType = MatrixType(size, size)
    var m2: MatrixType = MatrixType(size, size)
    var m3: MatrixType = MatrixType(size, size)
    m1.setRandom()
    var plu: PartialPivLU[MatrixType] = PartialPivLU[MatrixType](m1)
    VERIFY_IS_APPROX(m1, plu.reconstructedMatrix())
    m3 = MatrixType.Random(size, size)
    m2 = plu.solve(m3)
    VERIFY_IS_APPROX(m3, m1*m2)
    var m1_inverse: MatrixType = plu.inverse()
    VERIFY_IS_APPROX(m2, m1_inverse*m3)
    var rcond: RealScalar = (RealScalar(1) / matrix_l1_norm(m1)) / matrix_l1_norm(m1_inverse)
    var rcond_est: RealScalar = plu.rcond()
    VERIFY(rcond_est > rcond / 10 and rcond_est < rcond * 10)
    plu._solve_impl_transposed[False](m3, m2)
    VERIFY_IS_APPROX(m3, m1.transpose()*m2)
    m3 = MatrixType.Random(size, size)
    m3 = plu.transpose().solve(m2)
    VERIFY_IS_APPROX(m2, m1.transpose()*m3)
    plu._solve_impl_transposed[True](m3, m2)
    VERIFY_IS_APPROX(m3, m1.adjoint()*m2)
    m3 = MatrixType.Random(size, size)
    m3 = plu.adjoint().solve(m2)
    VERIFY_IS_APPROX(m2, m1.adjoint()*m3)

def lu_verify_assert[type MatrixType]():
    var tmp: MatrixType
    var lu: FullPivLU[MatrixType]
    VERIFY_RAISES_ASSERT(lu.matrixLU())
    VERIFY_RAISES_ASSERT(lu.permutationP())
    VERIFY_RAISES_ASSERT(lu.permutationQ())
    VERIFY_RAISES_ASSERT(lu.kernel())
    VERIFY_RAISES_ASSERT(lu.image(tmp))
    VERIFY_RAISES_ASSERT(lu.solve(tmp))
    VERIFY_RAISES_ASSERT(lu.determinant())
    VERIFY_RAISES_ASSERT(lu.rank())
    VERIFY_RAISES_ASSERT(lu.dimensionOfKernel())
    VERIFY_RAISES_ASSERT(lu.isInjective())
    VERIFY_RAISES_ASSERT(lu.isSurjective())
    VERIFY_RAISES_ASSERT(lu.isInvertible())
    VERIFY_RAISES_ASSERT(lu.inverse())
    var plu: PartialPivLU[MatrixType]
    VERIFY_RAISES_ASSERT(plu.matrixLU())
    VERIFY_RAISES_ASSERT(plu.permutationP())
    VERIFY_RAISES_ASSERT(plu.solve(tmp))
    VERIFY_RAISES_ASSERT(plu.determinant())
    VERIFY_RAISES_ASSERT(plu.inverse())

def test_lu():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1( lu_non_invertible[Matrix3f]() )
        CALL_SUBTEST_1( lu_invertible[Matrix3f]() )
        CALL_SUBTEST_1( lu_verify_assert[Matrix3f]() )
        CALL_SUBTEST_2( (lu_non_invertible[Matrix[Float64, 4, 6]]()) )
        CALL_SUBTEST_2( (lu_verify_assert[Matrix[Float64, 4, 6]]()) )
        CALL_SUBTEST_3( lu_non_invertible[MatrixXf]() )
        CALL_SUBTEST_3( lu_invertible[MatrixXf]() )
        CALL_SUBTEST_3( lu_verify_assert[MatrixXf]() )
        CALL_SUBTEST_4( lu_non_invertible[MatrixXd]() )
        CALL_SUBTEST_4( lu_invertible[MatrixXd]() )
        CALL_SUBTEST_4( lu_partial_piv[MatrixXd]() )
        CALL_SUBTEST_4( lu_verify_assert[MatrixXd]() )
        CALL_SUBTEST_5( lu_non_invertible[MatrixXcf]() )
        CALL_SUBTEST_5( lu_invertible[MatrixXcf]() )
        CALL_SUBTEST_5( lu_verify_assert[MatrixXcf]() )
        CALL_SUBTEST_6( lu_non_invertible[MatrixXcd]() )
        CALL_SUBTEST_6( lu_invertible[MatrixXcd]() )
        CALL_SUBTEST_6( lu_partial_piv[MatrixXcd]() )
        CALL_SUBTEST_6( lu_verify_assert[MatrixXcd]() )
        CALL_SUBTEST_7(( lu_non_invertible[Matrix[Float32, Dynamic, 16]]() ))
        CALL_SUBTEST_9( PartialPivLU[MatrixXf](10) )
        CALL_SUBTEST_9( FullPivLU[MatrixXf](10, 20) )