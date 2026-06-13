// #define EIGEN_NO_STATIC_ASSERT // otherwise we fail at compile time on unused paths
from main import *

@parameter
if not NumTraits[MatrixType.Scalar].IsComplex:
    def block_real_only[MatrixType: AnyType, Index: AnyType, Scalar: AnyType](m1: MatrixType, r1: Index, r2: Index, c1: Index, c2: Index, s1: Scalar) -> Scalar:
        VERIFY_IS_APPROX(m1.row(r1).cwiseMax(s1), m1.cwiseMax(s1).row(r1))
        VERIFY_IS_APPROX(m1.col(c1).cwiseMin(s1), m1.cwiseMin(s1).col(c1))
        VERIFY_IS_APPROX(m1.block(r1,c1,r2-r1+1,c2-c1+1).cwiseMin(s1), m1.cwiseMin(s1).block(r1,c1,r2-r1+1,c2-c1+1))
        VERIFY_IS_APPROX(m1.block(r1,c1,r2-r1+1,c2-c1+1).cwiseMax(s1), m1.cwiseMax(s1).block(r1,c1,r2-r1+1,c2-c1+1))
        return Scalar(0)
else:
    def block_real_only[MatrixType: AnyType, Index: AnyType, Scalar: AnyType](m1: MatrixType, r1: Index, r2: Index, c1: Index, c2: Index, s1: Scalar) -> Scalar:
        return Scalar(0)

def block[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias RowVectorType = Matrix[Scalar, 1, MatrixType.ColsAtCompileTime]
    alias DynamicMatrixType = Matrix[Scalar, Dynamic, Dynamic, MatrixType.IsRowMajor ? RowMajor : ColMajor]
    alias DynamicVectorType = Matrix[Scalar, Dynamic, 1]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m1_copy = m1
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    var ones = MatrixType.Ones(rows, cols)
    var v1 = VectorType.Random(rows)
    var s1 = internal.random[Scalar]()
    var r1 = internal.random[Index](0, rows-1)
    var r2 = internal.random[Index](r1, rows-1)
    var c1 = internal.random[Index](0, cols-1)
    var c2 = internal.random[Index](c1, cols-1)
    block_real_only[MatrixType, Index, Scalar](m1, r1, r2, c1, c1, s1)
    VERIFY_IS_EQUAL(m1.col(c1).transpose(), m1.transpose().row(c1))
    m1 = m1_copy
    m1.row(r1) += s1 * m1_copy.row(r2)
    VERIFY_IS_APPROX(m1.row(r1), m1_copy.row(r1) + s1 * m1_copy.row(r2))
    m1.row(r1).row(0) += s1 * m1_copy.row(r2)
    VERIFY_IS_APPROX(m1.row(r1), m1_copy.row(r1) + Scalar(2) * s1 * m1_copy.row(r2))
    m1 = m1_copy
    m1.col(c1) += s1 * m1_copy.col(c2)
    VERIFY_IS_APPROX(m1.col(c1), m1_copy.col(c1) + s1 * m1_copy.col(c2))
    m1.col(c1).col(0) += s1 * m1_copy.col(c2)
    VERIFY_IS_APPROX(m1.col(c1), m1_copy.col(c1) + Scalar(2) * s1 * m1_copy.col(c2))
    var b1 = Matrix[Scalar, Dynamic, Dynamic](1, 1)
    b1[0, 0] = m1[r1, c1]
    var br1 = RowVectorType(m1.block(r1, 0, 1, cols))
    var bc1 = VectorType(m1.block(0, c1, rows, 1))
    VERIFY_IS_EQUAL(b1, m1.block(r1, c1, 1, 1))
    VERIFY_IS_EQUAL(m1.row(r1), br1)
    VERIFY_IS_EQUAL(m1.col(c1), bc1)
    m1.block(r1, c1, r2-r1+1, c2-c1+1) = s1 * m2.block(0, 0, r2-r1+1, c2-c1+1)
    m1.block(r1, c1, r2-r1+1, c2-c1+1)[r2-r1, c2-c1] = m2.block(0, 0, r2-r1+1, c2-c1+1)[0, 0]
    let BlockRows = 2
    let BlockCols = 5
    if rows >= 5 and cols >= 8:
        m1.block[BlockRows, BlockCols](1, 1) *= s1
        m1.block[BlockRows, BlockCols](1, 1)[0, 3] = m1.block[2, 5](1, 1)[1, 2]
        var b = Matrix[Scalar, Dynamic, Dynamic](m1.block[BlockRows, BlockCols](3, 3))
        VERIFY_IS_EQUAL(b, m1.block(3, 3, BlockRows, BlockCols))
        m1.block[BlockRows, Dynamic](1, 1, BlockRows, BlockCols) *= s1
        m1.block[BlockRows, Dynamic](1, 1, BlockRows, BlockCols)[0, 3] = m1.block[2, 5](1, 1)[1, 2]
        var b2 = Matrix[Scalar, Dynamic, Dynamic](m1.block[Dynamic, BlockCols](3, 3, 2, 5))
        VERIFY_IS_EQUAL(b2, m1.block(3, 3, BlockRows, BlockCols))
    if rows > 2:
        VERIFY_IS_EQUAL(v1.head[2](), v1.block(0, 0, 2, 1))
        VERIFY_IS_EQUAL(v1.head[2](), v1.head(2))
        VERIFY_IS_EQUAL(v1.head[2](), v1.segment(0, 2))
        VERIFY_IS_EQUAL(v1.head[2](), v1.segment[2](0))
        var i = rows - 2
        VERIFY_IS_EQUAL(v1.tail[2](), v1.block(i, 0, 2, 1))
        VERIFY_IS_EQUAL(v1.tail[2](), v1.tail(2))
        VERIFY_IS_EQUAL(v1.tail[2](), v1.segment(i, 2))
        VERIFY_IS_EQUAL(v1.tail[2](), v1.segment[2](i))
        i = internal.random[Index](0, rows-2)
        VERIFY_IS_EQUAL(v1.segment(i, 2), v1.segment[2](i))
    VERIFY(numext.real(ones.col(c1).sum()) == RealScalar(rows))
    VERIFY(numext.real(ones.row(r1).sum()) == RealScalar(cols))
    VERIFY(numext.real(ones.col(c1).dot(ones.col(c2))) == RealScalar(rows))
    VERIFY(numext.real(ones.row(r1).dot(ones.row(r2))) == RealScalar(cols))
    m1 = m1_copy
    if (MatrixType.Flags & RowMajorBit) == 0:
        VERIFY_IS_EQUAL(m1.leftCols(c1).coeff(r1 + c1 * rows), m1[r1, c1])
    else:
        VERIFY_IS_EQUAL(m1.topRows(r1).coeff(c1 + r1 * cols), m1[r1, c1])
    VERIFY_IS_EQUAL((m1.block(r1, c1, rows-r1, cols-c1).block(r2-r1, c2-c1, rows-r2, cols-c2)), (m1.block(r2, c2, rows-r2, cols-c2)))
    VERIFY_IS_EQUAL((m1.block(r1, c1, r2-r1+1, c2-c1+1).row(0)), (m1.row(r1).segment(c1, c2-c1+1)))
    VERIFY_IS_EQUAL((m1.block(r1, c1, r2-r1+1, c2-c1+1).col(0)), (m1.col(c1).segment(r1, r2-r1+1)))
    VERIFY_IS_EQUAL((m1.block(r1, c1, r2-r1+1, c2-c1+1).transpose().col(0)), (m1.row(r1).segment(c1, c2-c1+1)).transpose())
    VERIFY_IS_EQUAL((m1.transpose().block(c1, r1, c2-c1+1, r2-r1+1).col(0)), (m1.row(r1).segment(c1, c2-c1+1)).transpose())
    VERIFY_IS_APPROX(((m1 + m2).block(r1, c1, rows-r1, cols-c1).block(r2-r1, c2-c1, rows-r2, cols-c2)), ((m1 + m2).block(r2, c2, rows-r2, cols-c2)))
    VERIFY_IS_APPROX(((m1 + m2).block(r1, c1, r2-r1+1, c2-c1+1).row(0)), ((m1 + m2).row(r1).segment(c1, c2-c1+1)))
    VERIFY_IS_APPROX(((m1 + m2).block(r1, c1, r2-r1+1, c2-c1+1).col(0)), ((m1 + m2).col(c1).segment(r1, r2-r1+1)))
    VERIFY_IS_APPROX(((m1 + m2).block(r1, c1, r2-r1+1, c2-c1+1).transpose().col(0)), ((m1 + m2).row(r1).segment(c1, c2-c1+1)).transpose())
    VERIFY_IS_APPROX(((m1 + m2).transpose().block(c1, r1, c2-c1+1, r2-r1+1).col(0)), ((m1 + m2).row(r1).segment(c1, c2-c1+1)).transpose())
    VERIFY_IS_APPROX((m1 * 1).topRows(r1), m1.topRows(r1))
    VERIFY_IS_APPROX((m1 * 1).leftCols(c1), m1.leftCols(c1))
    VERIFY_IS_APPROX((m1 * 1).transpose().topRows(c1), m1.transpose().topRows(c1))
    VERIFY_IS_APPROX((m1 * 1).transpose().leftCols(r1), m1.transpose().leftCols(r1))
    VERIFY_IS_APPROX((m1 * 1).transpose().middleRows(c1, c2-c1+1), m1.transpose().middleRows(c1, c2-c1+1))
    VERIFY_IS_APPROX((m1 * 1).transpose().middleCols(r1, r2-r1+1), m1.transpose().middleCols(r1, r2-r1+1))
    var dm = DynamicMatrixType()
    var dv = DynamicVectorType()
    dm.setZero()
    dm = m1.block(r1, c1, rows-r1, cols-c1).block(r2-r1, c2-c1, rows-r2, cols-c2)
    VERIFY_IS_EQUAL(dm, (m1.block(r2, c2, rows-r2, cols-c2)))
    dm.setZero()
    dv.setZero()
    dm = m1.block(r1, c1, r2-r1+1, c2-c1+1).row(0).transpose()
    dv = m1.row(r1).segment(c1, c2-c1+1)
    VERIFY_IS_EQUAL(dv, dm)
    dm.setZero()
    dv.setZero()
    dm = m1.col(c1).segment(r1, r2-r1+1)
    dv = m1.block(r1, c1, r2-r1+1, c2-c1+1).col(0)
    VERIFY_IS_EQUAL(dv, dm)
    dm.setZero()
    dv.setZero()
    dm = m1.block(r1, c1, r2-r1+1, c2-c1+1).transpose().col(0)
    dv = m1.row(r1).segment(c1, c2-c1+1)
    VERIFY_IS_EQUAL(dv, dm)
    dm.setZero()
    dv.setZero()
    dm = m1.row(r1).segment(c1, c2-c1+1).transpose()
    dv = m1.transpose().block(c1, r1, c2-c1+1, r2-r1+1).col(0)
    VERIFY_IS_EQUAL(dv, dm)
    VERIFY_IS_EQUAL((m1.block[Dynamic, 1](1, 0, 0, 1)), m1.block(1, 0, 0, 1))
    VERIFY_IS_EQUAL((m1.block[1, Dynamic](0, 1, 1, 0)), m1.block(0, 1, 1, 0))
    VERIFY_IS_EQUAL(((m1 * 1).block[Dynamic, 1](1, 0, 0, 1)), m1.block(1, 0, 0, 1))
    VERIFY_IS_EQUAL(((m1 * 1).block[1, Dynamic](0, 1, 1, 0)), m1.block(0, 1, 1, 0))
    if rows >= 2 and cols >= 2:
        VERIFY_RAISES_ASSERT(m1 += m1.col(0))
        VERIFY_RAISES_ASSERT(m1 -= m1.col(0))
        VERIFY_RAISES_ASSERT(m1.array() *= m1.col(0).array())
        VERIFY_RAISES_ASSERT(m1.array() /= m1.col(0).array())

def compare_using_data_and_stride[MatrixType: AnyType](m: MatrixType):
    var rows = m.rows()
    var cols = m.cols()
    var size = m.size()
    var innerStride = m.innerStride()
    var outerStride = m.outerStride()
    var rowStride = m.rowStride()
    var colStride = m.colStride()
    var data = m.data()
    for j in range(cols):
        for i in range(rows):
            VERIFY(m.coeff(i, j) == data[i * rowStride + j * colStride])
    if not MatrixType.IsVectorAtCompileTime:
        for j in range(cols):
            for i in range(rows):
                VERIFY(m.coeff(i, j) == data[(MatrixType.Flags & RowMajorBit) ? i * outerStride + j * innerStride : j * outerStride + i * innerStride])
    if MatrixType.IsVectorAtCompileTime:
        VERIFY(innerStride == int((&m.coeff(1)) - (&m.coeff(0))))
        for i in range(size):
            VERIFY(m.coeff(i) == data[i * innerStride])

def data_and_stride[MatrixType: AnyType](m: MatrixType):
    var rows = m.rows()
    var cols = m.cols()
    var r1 = internal.random[Index](0, rows-1)
    var r2 = internal.random[Index](r1, rows-1)
    var c1 = internal.random[Index](0, cols-1)
    var c2 = internal.random[Index](c1, cols-1)
    var m1 = MatrixType.Random(rows, cols)
    compare_using_data_and_stride(m1.block(r1, c1, r2-r1+1, c2-c1+1))
    compare_using_data_and_stride(m1.transpose().block(c1, r1, c2-c1+1, r2-r1+1))
    compare_using_data_and_stride(m1.row(r1))
    compare_using_data_and_stride(m1.col(c1))
    compare_using_data_and_stride(m1.row(r1).transpose())
    compare_using_data_and_stride(m1.col(c1).transpose())

def test_block():
    for i in range(g_repeat):
        CALL_SUBTEST_1(block[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(block[Matrix4d]())
        CALL_SUBTEST_3(block[MatrixXcf](3, 3))
        CALL_SUBTEST_4(block[MatrixXi](8, 12))
        CALL_SUBTEST_5(block[MatrixXcd](20, 20))
        CALL_SUBTEST_6(block[MatrixXf](20, 20))
        CALL_SUBTEST_8(block[Matrix[float32, Dynamic, 4]](3, 4))
        @parameter
        if not EIGEN_DEFAULT_TO_ROW_MAJOR:
            CALL_SUBTEST_6(data_and_stride[MatrixXf](MatrixXf(internal.random(5, 50), internal.random(5, 50))))
            CALL_SUBTEST_7(data_and_stride[Matrix[int32, Dynamic, Dynamic, RowMajor]](Matrix[int32, Dynamic, Dynamic, RowMajor](internal.random(5, 50), internal.random(5, 50))))