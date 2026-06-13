from main import *
from iostream import *
def reverse[MatrixType: AnyType](m: MatrixType) raises:
    type Scalar = MatrixType.Scalar
    type VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2: MatrixType
    var v1 = VectorType.Random(rows)
    var m1_r = m1.reverse()
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_r[i, j], m1[rows - 1 - i, cols - 1 - j])
    var m1_rd = Reverse[MatrixType](m1)
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_rd[i, j], m1[rows - 1 - i, cols - 1 - j])
    var m1_rb = Reverse[MatrixType, BothDirections](m1)
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_rb[i, j], m1[rows - 1 - i, cols - 1 - j])
    var m1_rv = Reverse[MatrixType, Vertical](m1)
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_rv[i, j], m1[rows - 1 - i, j])
    var m1_rh = Reverse[MatrixType, Horizontal](m1)
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_rh[i, j], m1[i, cols - 1 - j])
    var v1_r = v1.reverse()
    for i in range(0, rows):
        VERIFY_IS_APPROX(v1_r[i], v1[rows - 1 - i])
    var m1_cr = m1.colwise().reverse()
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_cr[i, j], m1[rows - 1 - i, j])
    var m1_rr = m1.rowwise().reverse()
    for i in range(0, rows):
        for j in range(0, cols):
            VERIFY_IS_APPROX(m1_rr[i, j], m1[i, cols - 1 - j])
    var x = internal.random[Scalar]()
    var r = internal.random[Index](0, rows-1)
    var c = internal.random[Index](0, cols-1)
    m1.reverse()[r, c] = x
    VERIFY_IS_APPROX(x, m1[rows - 1 - r, cols - 1 - c])
    m2 = m1
    m2.reverseInPlace()
    VERIFY_IS_APPROX(m2, m1.reverse().eval())
    m2 = m1
    m2.col(0).reverseInPlace()
    VERIFY_IS_APPROX(m2.col(0), m1.col(0).reverse().eval())
    m2 = m1
    m2.row(0).reverseInPlace()
    VERIFY_IS_APPROX(m2.row(0), m1.row(0).reverse().eval())
    m2 = m1
    m2.rowwise().reverseInPlace()
    VERIFY_IS_APPROX(m2, m1.rowwise().reverse().eval())
    m2 = m1
    m2.colwise().reverseInPlace()
    VERIFY_IS_APPROX(m2, m1.colwise().reverse().eval())
    m1.colwise().reverse()[r, c] = x
    VERIFY_IS_APPROX(x, m1[rows - 1 - r, c])
    m1.rowwise().reverse()[r, c] = x
    VERIFY_IS_APPROX(x, m1[r, cols - 1 - c])

def test_array_reverse() raises:
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(reverse[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(reverse[Matrix2f]())
        CALL_SUBTEST_3(reverse[Matrix4f]())
        CALL_SUBTEST_4(reverse[Matrix4d]())
        CALL_SUBTEST_5(reverse[MatrixXcf](internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE)))
        CALL_SUBTEST_6(reverse[MatrixXi](internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE)))
        CALL_SUBTEST_7(reverse[MatrixXcd](internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE)))
        CALL_SUBTEST_8(reverse[Matrix[float32, 100, 100]]())
        CALL_SUBTEST_9(reverse[Matrix[float32, Dynamic, Dynamic, RowMajor]](internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE)))
    #ifdef EIGEN_TEST_PART_3
    var x: Vector4f
    x << 1, 2, 3, 4
    var y: Vector4f
    y << 4, 3, 2, 1
    VERIFY(x.reverse()[1] == 3)
    VERIFY(x.reverse() == y)
    #endif