// Transliterated from C++: product_symm.cpp
// Note: Requires an Eigen-like library in Mojo with Matrix, Index, internal, etc.

from main import g_repeat, EIGEN_TEST_MAX_SIZE, VERIFY_IS_EQUAL, VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, CALL_SUBTEST_8

alias RowMajor: Int = 1  // from Eigen::RowMajor (typically 1)

def symm[Scalar: AnyType, Size: Int, OtherSize: Int](size: Int = Size, othersize: Int = OtherSize):
    alias MatrixType = Matrix[Scalar, Size, Size]
    alias Rhs1 = Matrix[Scalar, Size, OtherSize]
    alias Rhs2 = Matrix[Scalar, OtherSize, Size]
    let order: Int = 0 if OtherSize == 1 else RowMajor
    alias Rhs3 = Matrix[Scalar, Size, OtherSize, order]
    var rows: Int = size
    var cols: Int = size
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType.Random(rows, cols)
    var m3: MatrixType
    m1 = (m1 + m1.adjoint()).eval()
    var rhs1: Rhs1 = Rhs1.Random(cols, othersize)
    var rhs12: Rhs1(cols, othersize)
    var rhs13: Rhs1(cols, othersize)
    var rhs2: Rhs2 = Rhs2.Random(othersize, rows)
    var rhs22: Rhs2(othersize, rows)
    var rhs23: Rhs2(othersize, rows)
    var rhs3: Rhs3 = Rhs3.Random(cols, othersize)
    var rhs32: Rhs3(cols, othersize)
    var rhs33: Rhs3(cols, othersize)
    var s1: Scalar = internal.random[Scalar]()
    var s2: Scalar = internal.random[Scalar]()
    m2 = m1.triangularView[Lower]()
    m3 = m2.selfadjointView[Lower]()
    VERIFY_IS_EQUAL(m1, m3)
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Lower]() * (s2 * rhs1),
                     rhs13 = (s1 * m1) * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).transpose().selfadjointView[Upper]() * (s2 * rhs1),
                     rhs13 = (s1 * m1.transpose()) * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Lower]().transpose() * (s2 * rhs1),
                     rhs13 = (s1 * m1.transpose()) * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).conjugate().selfadjointView[Lower]() * (s2 * rhs1),
                     rhs13 = (s1 * m1).conjugate() * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Lower]().conjugate() * (s2 * rhs1),
                     rhs13 = (s1 * m1).conjugate() * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).adjoint().selfadjointView[Upper]() * (s2 * rhs1),
                     rhs13 = (s1 * m1).adjoint() * (s2 * rhs1))
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Lower]().adjoint() * (s2 * rhs1),
                     rhs13 = (s1 * m1).adjoint() * (s2 * rhs1))
    m2 = m1.triangularView[Upper]()
    rhs12.setRandom()
    rhs13 = rhs12
    m3 = m2.selfadjointView[Upper]()
    VERIFY_IS_EQUAL(m1, m3)
    VERIFY_IS_APPROX(rhs12 += (s1 * m2).selfadjointView[Upper]() * (s2 * rhs1),
                     rhs13 += (s1 * m1) * (s2 * rhs1))
    m2 = m1.triangularView[Lower]()
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Lower]() * (s2 * rhs2.adjoint()),
                     rhs13 = (s1 * m1) * (s2 * rhs2.adjoint()))
    m2 = m1.triangularView[Upper]()
    VERIFY_IS_APPROX(rhs12 = (s1 * m2).selfadjointView[Upper]() * (s2 * rhs2.adjoint()),
                     rhs13 = (s1 * m1) * (s2 * rhs2.adjoint()))
    m2 = m1.triangularView[Upper]()
    VERIFY_IS_APPROX(rhs12 = (s1 * m2.adjoint()).selfadjointView[Lower]() * (s2 * rhs2.adjoint()),
                     rhs13 = (s1 * m1.adjoint()) * (s2 * rhs2.adjoint()))
    m2 = m1.triangularView[Lower]()
    rhs12.setRandom()
    rhs13 = rhs12
    VERIFY_IS_APPROX(rhs12 -= (s1 * m2).selfadjointView[Lower]() * (s2 * rhs3),
                     rhs13 -= (s1 * m1) * (s2 * rhs3))
    m2 = m1.triangularView[Upper]()
    VERIFY_IS_APPROX(rhs12 = (s1 * m2.adjoint()).selfadjointView[Lower]() * (s2 * rhs3).conjugate(),
                     rhs13 = (s1 * m1.adjoint()) * (s2 * rhs3).conjugate())
    m2 = m1.triangularView[Upper]()
    rhs13 = rhs12
    VERIFY_IS_APPROX(rhs12.noalias() += s1 * ((m2.adjoint()).selfadjointView[Lower]() * (s2 * rhs3).conjugate()),
                     rhs13 += (s1 * m1.adjoint()) * (s2 * rhs3).conjugate())
    m2 = m1.triangularView[Lower]()
    VERIFY_IS_APPROX(rhs22 = (rhs2) * (m2).selfadjointView[Lower](), rhs23 = (rhs2) * (m1))
    VERIFY_IS_APPROX(rhs22 = (s2 * rhs2) * (s1 * m2).selfadjointView[Lower](), rhs23 = (s2 * rhs2) * (s1 * m1))

def test_product_symm():
    for i in range(g_repeat):
        CALL_SUBTEST_1(( symm[Float32, -1, -1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
        CALL_SUBTEST_2(( symm[Float64, -1, -1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
        CALL_SUBTEST_3(( symm[Complex[Float32], -1, -1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2), internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2)) ))
        CALL_SUBTEST_4(( symm[Complex[Float64], -1, -1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2), internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2)) ))
        CALL_SUBTEST_5(( symm[Float32, -1, 1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
        CALL_SUBTEST_6(( symm[Float64, -1, 1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
        CALL_SUBTEST_7(( symm[Complex[Float32], -1, 1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
        CALL_SUBTEST_8(( symm[Complex[Float64], -1, 1](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
<<<FILE>>>