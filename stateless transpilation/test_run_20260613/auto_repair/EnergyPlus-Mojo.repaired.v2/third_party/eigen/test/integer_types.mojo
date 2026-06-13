from main import g_repeat, VERIFY, VERIFY_IS_EQUAL, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, CALL_SUBTEST_8, Matrix, NumTraits, internal, Index

# undef VERIFY_IS_APPROX
# define VERIFY_IS_APPROX(a, b) VERIFY((a)==(b));
def VERIFY_IS_APPROX[T: AnyType](a: T, b: T):
    VERIFY(a == b)

# undef VERIFY_IS_NOT_APPROX
# define VERIFY_IS_NOT_APPROX(a, b) VERIFY((a)!=(b));
def VERIFY_IS_NOT_APPROX[T: AnyType](a: T, b: T):
    VERIFY(a != b)

def signed_integer_type_tests[MatrixType: AnyType](m: MatrixType):
    typedef MatrixType::Scalar Scalar
    enum { is_signed = (Scalar(-1) > Scalar(0)) ? 0 : 1 }
    VERIFY(is_signed == 1)
    Index rows = m.rows()
    Index cols = m.cols()
    MatrixType m1(rows, cols)
    MatrixType m2 = MatrixType.Random(rows, cols)
    MatrixType mzero = MatrixType.Zero(rows, cols)
    do:
        m1 = MatrixType.Random(rows, cols)
    while(m1 == mzero or m1 == m2)
    Scalar s1
    do:
        s1 = internal.random[Scalar]()
    while(s1 == 0)
    VERIFY_IS_EQUAL(-(-m1),                  m1)
    VERIFY_IS_EQUAL(-m2 + m1 + m2,           m1)
    VERIFY_IS_EQUAL((-m1 + m2) * s1,         -s1 * m1 + s1 * m2)

def integer_type_tests[MatrixType: AnyType](m: MatrixType):
    typedef MatrixType::Scalar Scalar
    VERIFY(NumTraits[Scalar].IsInteger)
    enum { is_signed = (Scalar(-1) > Scalar(0)) ? 0 : 1 }
    VERIFY(int(NumTraits[Scalar].IsSigned) == is_signed)
    typedef Matrix[Scalar, MatrixType.RowsAtCompileTime, 1] VectorType
    Index rows = m.rows()
    Index cols = m.cols()
    MatrixType m1(rows, cols)
    MatrixType m2 = MatrixType.Random(rows, cols)
    MatrixType m3(rows, cols)
    MatrixType mzero = MatrixType.Zero(rows, cols)
    typedef Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime] SquareMatrixType
    SquareMatrixType identity = SquareMatrixType.Identity(rows, rows)
    SquareMatrixType square = SquareMatrixType.Random(rows, rows)
    VectorType v1(rows)
    VectorType v2 = VectorType.Random(rows)
    VectorType vzero = VectorType.Zero(rows)
    do:
        m1 = MatrixType.Random(rows, cols)
    while(m1 == mzero or m1 == m2)
    do:
        v1 = VectorType.Random(rows)
    while(v1 == vzero or v1 == v2)
    VERIFY_IS_APPROX(v1,    v1)
    VERIFY_IS_NOT_APPROX(v1,    2 * v1)
    VERIFY_IS_APPROX(vzero, v1 - v1)
    VERIFY_IS_APPROX(m1,    m1)
    VERIFY_IS_NOT_APPROX(m1,    2 * m1)
    VERIFY_IS_APPROX(mzero, m1 - m1)
    VERIFY_IS_APPROX(m3 = m1, m1)
    MatrixType m4
    VERIFY_IS_APPROX(m4 = m1, m1)
    m3.real() = m1.real()
    VERIFY_IS_APPROX(static_cast[const MatrixType &](m3).real(), static_cast[const MatrixType &](m1).real())
    VERIFY_IS_APPROX(static_cast[const MatrixType &](m3).real(), m1.real())
    VERIFY(m1 == m1)
    VERIFY(m1 != m2)
    VERIFY(not (m1 == m2))
    VERIFY(not (m1 != m1))
    m1 = m2
    VERIFY(m1 == m2)
    VERIFY(not (m1 != m2))
    Scalar s1
    do:
        s1 = internal.random[Scalar]()
    while(s1 == 0)
    VERIFY_IS_EQUAL(m1 + m1,                   2 * m1)
    VERIFY_IS_EQUAL(m1 + m2 - m1,              m2)
    VERIFY_IS_EQUAL(m1 * s1,                   s1 * m1)
    VERIFY_IS_EQUAL((m1 + m2) * s1,            s1 * m1 + s1 * m2)
    m3 = m2; m3 += m1
    VERIFY_IS_EQUAL(m3,                        m1 + m2)
    m3 = m2; m3 -= m1
    VERIFY_IS_EQUAL(m3,                        m2 - m1)
    m3 = m2; m3 *= s1
    VERIFY_IS_EQUAL(m3,                        s1 * m2)
    VERIFY_IS_APPROX(identity * m1, m1)
    VERIFY_IS_APPROX(square * (m1 + m2), square * m1 + square * m2)
    VERIFY_IS_APPROX((m1 + m2).transpose() * square, m1.transpose() * square + m2.transpose() * square)
    VERIFY_IS_APPROX((m1 * m2.transpose()) * m1, m1 * (m2.transpose() * m1))

def test_integer_types():
    for i in range(g_repeat):
        CALL_SUBTEST_1(integer_type_tests[Matrix[UInt32, 1, 1]]())
        CALL_SUBTEST_1(integer_type_tests[Matrix[UInt64, 3, 4]]())
        CALL_SUBTEST_2(integer_type_tests[Matrix[Int64, 2, 2]]())
        CALL_SUBTEST_2(signed_integer_type_tests[Matrix[Int64, 2, 2]]())
        CALL_SUBTEST_3(integer_type_tests[Matrix[Int8, 2, -1]](2, 10))
        CALL_SUBTEST_3(signed_integer_type_tests[Matrix[Int8, 2, -1]](2, 10))
        CALL_SUBTEST_4(integer_type_tests[Matrix[UInt8, 3, 3]]())
        CALL_SUBTEST_4(integer_type_tests[Matrix[UInt8, -1, -1]](20, 20))
        CALL_SUBTEST_5(integer_type_tests[Matrix[Int16, -1, 4]](7, 4))
        CALL_SUBTEST_5(signed_integer_type_tests[Matrix[Int16, -1, 4]](7, 4))
        CALL_SUBTEST_6(integer_type_tests[Matrix[UInt16, 4, 4]]())
        CALL_SUBTEST_7(integer_type_tests[Matrix[Int64, 11, 13]]())
        CALL_SUBTEST_7(signed_integer_type_tests[Matrix[Int64, 11, 13]]())
        CALL_SUBTEST_8(integer_type_tests[Matrix[UInt64, -1, 5]](1, 5))

@parameter
var EIGEN_TEST_PART_9: Bool = False

if EIGEN_TEST_PART_9:
    VERIFY_IS_EQUAL(internal.scalar_div_cost[Int32].value, 8)
    VERIFY_IS_EQUAL(internal.scalar_div_cost[UInt32].value, 8)
    if sizeof[Int64]() > sizeof[Int32]():
        VERIFY(int(internal.scalar_div_cost[Int64].value) > int(internal.scalar_div_cost[Int32].value))
        VERIFY(int(internal.scalar_div_cost[UInt64].value) > int(internal.scalar_div_cost[Int32].value))