from Eigen import Matrix, internal, RowMajor, Dynamic, Lower, Upper
from test_main import VERIFY_IS_APPROX, CALL_SUBTEST, TEST_SET_BUT_UNUSED_VARIABLE, g_repeat, EIGEN_TEST_MAX_SIZE

def syrk[type: MatrixType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    typealias RMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime, RowMajor]
    typealias Rhs1 = Matrix[Scalar, MatrixType.ColsAtCompileTime, Dynamic]
    typealias Rhs2 = Matrix[Scalar, Dynamic, MatrixType.RowsAtCompileTime]
    typealias Rhs3 = Matrix[Scalar, MatrixType.ColsAtCompileTime, Dynamic, RowMajor]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType.Random(rows, cols)
    var rm2 = RMatrixType.Random(rows, cols)
    var rhs1 = Rhs1.Random(internal.random[Int](1,320), cols)
    var rhs11 = Rhs1.Random(rhs1.rows(), cols)
    var rhs2 = Rhs2.Random(rows, internal.random[Int](1,320))
    var rhs22 = Rhs2.Random(rows, rhs2.cols())
    var rhs3 = Rhs3.Random(internal.random[Int](1,320), rows)
    var s1 = internal.random[Scalar]()
    var c = internal.random[Index](0, cols-1)
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Lower]().rankUpdate(rhs2, s1)._expression()),
        ((s1 * rhs2 * rhs2.adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        ((m2.template triangularView[Lower]() += s1 * rhs2 * rhs22.adjoint()).nestedExpression()),
        ((s1 * rhs2 * rhs22.adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        m2.template selfadjointView[Upper]().rankUpdate(rhs2, s1)._expression(),
        (s1 * rhs2 * rhs2.adjoint()).eval().template triangularView[Upper]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template triangularView[Upper]() += s1 * rhs22 * rhs2.adjoint()).nestedExpression(),
        (s1 * rhs22 * rhs2.adjoint()).eval().template triangularView[Upper]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        m2.template selfadjointView[Lower]().rankUpdate(rhs1.adjoint(), s1)._expression(),
        (s1 * rhs1.adjoint() * rhs1).eval().template triangularView[Lower]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template triangularView[Lower]() += s1 * rhs11.adjoint() * rhs1).nestedExpression(),
        (s1 * rhs11.adjoint() * rhs1).eval().template triangularView[Lower]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        m2.template selfadjointView[Upper]().rankUpdate(rhs1.adjoint(), s1)._expression(),
        (s1 * rhs1.adjoint() * rhs1).eval().template triangularView[Upper]().toDenseMatrix()
    )
    VERIFY_IS_APPROX(
        (m2.template triangularView[Upper]() = s1 * rhs1.adjoint() * rhs11).nestedExpression(),
        (s1 * rhs1.adjoint() * rhs11).eval().template triangularView[Upper]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        m2.template selfadjointView[Lower]().rankUpdate(rhs3.adjoint(), s1)._expression(),
        (s1 * rhs3.adjoint() * rhs3).eval().template triangularView[Lower]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        m2.template selfadjointView[Upper]().rankUpdate(rhs3.adjoint(), s1)._expression(),
        (s1 * rhs3.adjoint() * rhs3).eval().template triangularView[Upper]().toDenseMatrix()
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Lower]().rankUpdate(m1.col(c), s1)._expression()),
        ((s1 * m1.col(c) * m1.col(c).adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Upper]().rankUpdate(m1.col(c), s1)._expression()),
        ((s1 * m1.col(c) * m1.col(c).adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )
    rm2.setZero()
    VERIFY_IS_APPROX(
        (rm2.template selfadjointView[Upper]().rankUpdate(m1.col(c), s1)._expression()),
        ((s1 * m1.col(c) * m1.col(c).adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template triangularView[Upper]() += s1 * m3.col(c) * m1.col(c).adjoint()).nestedExpression(),
        ((s1 * m3.col(c) * m1.col(c).adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )
    rm2.setZero()
    VERIFY_IS_APPROX(
        (rm2.template triangularView[Upper]() += s1 * m1.col(c) * m3.col(c).adjoint()).nestedExpression(),
        ((s1 * m1.col(c) * m3.col(c).adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Lower]().rankUpdate(m1.col(c).conjugate(), s1)._expression()),
        ((s1 * m1.col(c).conjugate() * m1.col(c).conjugate().adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Upper]().rankUpdate(m1.col(c).conjugate(), s1)._expression()),
        ((s1 * m1.col(c).conjugate() * m1.col(c).conjugate().adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Lower]().rankUpdate(m1.row(c), s1)._expression()),
        ((s1 * m1.row(c).transpose() * m1.row(c).transpose().adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    rm2.setZero()
    VERIFY_IS_APPROX(
        (rm2.template selfadjointView[Lower]().rankUpdate(m1.row(c), s1)._expression()),
        ((s1 * m1.row(c).transpose() * m1.row(c).transpose().adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template triangularView[Lower]() += s1 * m3.row(c).transpose() * m1.row(c).transpose().adjoint()).nestedExpression(),
        ((s1 * m3.row(c).transpose() * m1.row(c).transpose().adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    rm2.setZero()
    VERIFY_IS_APPROX(
        (rm2.template triangularView[Lower]() += s1 * m3.row(c).transpose() * m1.row(c).transpose().adjoint()).nestedExpression(),
        ((s1 * m3.row(c).transpose() * m1.row(c).transpose().adjoint()).eval().template triangularView[Lower]().toDenseMatrix())
    )
    m2.setZero()
    VERIFY_IS_APPROX(
        (m2.template selfadjointView[Upper]().rankUpdate(m1.row(c).adjoint(), s1)._expression()),
        ((s1 * m1.row(c).adjoint() * m1.row(c).adjoint().adjoint()).eval().template triangularView[Upper]().toDenseMatrix())
    )

def test_product_syrk():
    for i in range(g_repeat):
        var s: Int
        s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST(1, syrk[MatrixXf](MatrixXf(s, s)))
        CALL_SUBTEST(2, syrk[MatrixXd](MatrixXd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2)
        CALL_SUBTEST(3, syrk[MatrixXcf](MatrixXcf(s, s)))
        CALL_SUBTEST(4, syrk[MatrixXcd](MatrixXcd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)