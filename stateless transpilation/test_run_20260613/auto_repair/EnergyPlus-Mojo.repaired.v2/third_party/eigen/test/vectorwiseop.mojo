// #define TEST_ENABLE_TEMPORARY_TRACKING
// #define EIGEN_NO_STATIC_ASSERT
// #include "main.h"

from main import TEST_ENABLE_TEMPORARY_TRACKING, EIGEN_NO_STATIC_ASSERT, main, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT, VERIFY_EVALUATION_COUNT
from eigen import Array, Matrix, NumTraits, internal

def vectorwiseop_array[ArrayType: AnyType](m: ArrayType):
    type Scalar = ArrayType.Scalar
    type ColVectorType = Array[Scalar, ArrayType.RowsAtCompileTime, 1]
    type RowVectorType = Array[Scalar, 1, ArrayType.ColsAtCompileTime]
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    var r: Int = internal.random[Int](0, rows-1)
    var c: Int = internal.random[Int](0, cols-1)
    var m1: ArrayType = ArrayType.Random(rows, cols)
    var m2: ArrayType = ArrayType(rows, cols)
    var m3: ArrayType = ArrayType(rows, cols)
    var colvec: ColVectorType = ColVectorType.Random(rows)
    var rowvec: RowVectorType = RowVectorType.Random(cols)
    m2 = m1
    m2.colwise() += colvec
    VERIFY_IS_APPROX(m2, m1.colwise() + colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) + colvec)
    VERIFY_RAISES_ASSERT(m2.colwise() += colvec.transpose())
    VERIFY_RAISES_ASSERT(m1.colwise() + colvec.transpose())
    m2 = m1
    m2.rowwise() += rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() + rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) + rowvec)
    VERIFY_RAISES_ASSERT(m2.rowwise() += rowvec.transpose())
    VERIFY_RAISES_ASSERT(m1.rowwise() + rowvec.transpose())
    m2 = m1
    m2.colwise() -= colvec
    VERIFY_IS_APPROX(m2, m1.colwise() - colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) - colvec)
    VERIFY_RAISES_ASSERT(m2.colwise() -= colvec.transpose())
    VERIFY_RAISES_ASSERT(m1.colwise() - colvec.transpose())
    m2 = m1
    m2.rowwise() -= rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() - rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) - rowvec)
    VERIFY_RAISES_ASSERT(m2.rowwise() -= rowvec.transpose())
    VERIFY_RAISES_ASSERT(m1.rowwise() - rowvec.transpose())
    m2 = m1
    m2.colwise() *= colvec
    VERIFY_IS_APPROX(m2, m1.colwise() * colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) * colvec)
    VERIFY_RAISES_ASSERT(m2.colwise() *= colvec.transpose())
    VERIFY_RAISES_ASSERT(m1.colwise() * colvec.transpose())
    m2 = m1
    m2.rowwise() *= rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() * rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) * rowvec)
    VERIFY_RAISES_ASSERT(m2.rowwise() *= rowvec.transpose())
    VERIFY_RAISES_ASSERT(m1.rowwise() * rowvec.transpose())
    m2 = m1
    m2.colwise() /= colvec
    VERIFY_IS_APPROX(m2, m1.colwise() / colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) / colvec)
    VERIFY_RAISES_ASSERT(m2.colwise() /= colvec.transpose())
    VERIFY_RAISES_ASSERT(m1.colwise() / colvec.transpose())
    m2 = m1
    m2.rowwise() /= rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() / rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) / rowvec)
    VERIFY_RAISES_ASSERT(m2.rowwise() /= rowvec.transpose())
    VERIFY_RAISES_ASSERT(m1.rowwise() / rowvec.transpose())
    m2 = m1
    if ArrayType.RowsAtCompileTime > 2 or ArrayType.RowsAtCompileTime == Dynamic:
        m2.rowwise() /= m2.colwise().sum()
        VERIFY_IS_APPROX(m2, m1.rowwise() / m1.colwise().sum())
    var mb: Array[Bool, Dynamic, Dynamic] = Array[Bool, Dynamic, Dynamic](rows, cols)
    mb = (m1.real() <= 0.7).colwise().all()
    VERIFY(((mb.col(c) == (m1.real().col(c) <= 0.7).all()).all()))
    mb = (m1.real() <= 0.7).rowwise().all()
    VERIFY(((mb.row(r) == (m1.real().row(r) <= 0.7).all()).all()))
    mb = (m1.real() >= 0.7).colwise().any()
    VERIFY(((mb.col(c) == (m1.real().col(c) >= 0.7).any()).all()))
    mb = (m1.real() >= 0.7).rowwise().any()
    VERIFY(((mb.row(r) == (m1.real().row(r) >= 0.7).any()).all()))

def vectorwiseop_matrix[MatrixType: AnyType](m: MatrixType):
    type Scalar = MatrixType.Scalar
    type RealScalar = NumTraits[Scalar].Real
    type ColVectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    type RowVectorType = Matrix[Scalar, 1, MatrixType.ColsAtCompileTime]
    type RealColVectorType = Matrix[RealScalar, MatrixType.RowsAtCompileTime, 1]
    type RealRowVectorType = Matrix[RealScalar, 1, MatrixType.ColsAtCompileTime]
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    var r: Int = internal.random[Int](0, rows-1)
    var c: Int = internal.random[Int](0, cols-1)
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType(rows, cols)
    var m3: MatrixType = MatrixType(rows, cols)
    var colvec: ColVectorType = ColVectorType.Random(rows)
    var rowvec: RowVectorType = RowVectorType.Random(cols)
    var rcres: RealColVectorType
    var rrres: RealRowVectorType
    m2 = m1
    m2.colwise() += colvec
    VERIFY_IS_APPROX(m2, m1.colwise() + colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) + colvec)
    if rows > 1:
        VERIFY_RAISES_ASSERT(m2.colwise() += colvec.transpose())
        VERIFY_RAISES_ASSERT(m1.colwise() + colvec.transpose())
    m2 = m1
    m2.rowwise() += rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() + rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) + rowvec)
    if cols > 1:
        VERIFY_RAISES_ASSERT(m2.rowwise() += rowvec.transpose())
        VERIFY_RAISES_ASSERT(m1.rowwise() + rowvec.transpose())
    m2 = m1
    m2.colwise() -= colvec
    VERIFY_IS_APPROX(m2, m1.colwise() - colvec)
    VERIFY_IS_APPROX(m2.col(c), m1.col(c) - colvec)
    if rows > 1:
        VERIFY_RAISES_ASSERT(m2.colwise() -= colvec.transpose())
        VERIFY_RAISES_ASSERT(m1.colwise() - colvec.transpose())
    m2 = m1
    m2.rowwise() -= rowvec
    VERIFY_IS_APPROX(m2, m1.rowwise() - rowvec)
    VERIFY_IS_APPROX(m2.row(r), m1.row(r) - rowvec)
    if cols > 1:
        VERIFY_RAISES_ASSERT(m2.rowwise() -= rowvec.transpose())
        VERIFY_RAISES_ASSERT(m1.rowwise() - rowvec.transpose())
    rrres = m1.colwise().norm()
    VERIFY_IS_APPROX(rrres(c), m1.col(c).norm())
    rcres = m1.rowwise().norm()
    VERIFY_IS_APPROX(rcres(r), m1.row(r).norm())
    VERIFY_IS_APPROX(m1.cwiseAbs().colwise().sum(), m1.colwise().template lpNorm[1]())
    VERIFY_IS_APPROX(m1.cwiseAbs().rowwise().sum(), m1.rowwise().template lpNorm[1]())
    VERIFY_IS_APPROX(m1.cwiseAbs().colwise().maxCoeff(), m1.colwise().template lpNorm[Infinity]())
    VERIFY_IS_APPROX(m1.cwiseAbs().rowwise().maxCoeff(), m1.rowwise().template lpNorm[Infinity]())
    VERIFY_IS_APPROX(m1.cwiseAbs().colwise().sum().x(), m1.col(0).cwiseAbs().sum())
    m2 = m1.colwise().normalized()
    VERIFY_IS_APPROX(m2.col(c), m1.col(c).normalized())
    m2 = m1.rowwise().normalized()
    VERIFY_IS_APPROX(m2.row(r), m1.row(r).normalized())
    m2 = m1
    m2.colwise().normalize()
    VERIFY_IS_APPROX(m2.col(c), m1.col(c).normalized())
    m2 = m1
    m2.rowwise().normalize()
    VERIFY_IS_APPROX(m2.row(r), m1.row(r).normalized())
    var m1m1: Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime] = m1 * m1.transpose()
    VERIFY_IS_APPROX((m1 * m1.transpose()).colwise().sum(), m1m1.colwise().sum())
    var tmp: Matrix[Scalar, 1, MatrixType.RowsAtCompileTime] = Matrix[Scalar, 1, MatrixType.RowsAtCompileTime](rows)
    VERIFY_EVALUATION_COUNT(tmp = (m1 * m1.transpose()).colwise().sum(), 1)
    m2 = m1.rowwise() - (m1.colwise().sum() / RealScalar(m1.rows())).eval()
    m1 = m1.rowwise() - (m1.colwise().sum() / RealScalar(m1.rows()))
    VERIFY_IS_APPROX(m1, m2)
    VERIFY_EVALUATION_COUNT(m2 = (m1.rowwise() - m1.colwise().sum() / RealScalar(m1.rows())), (MatrixType.RowsAtCompileTime != 1 ? 1 : 0))

def test_vectorwiseop():
    CALL_SUBTEST_1(vectorwiseop_array(Array22cd()))
    CALL_SUBTEST_2(vectorwiseop_array(Array[double, 3, 2]()))
    CALL_SUBTEST_3(vectorwiseop_array(ArrayXXf(3, 4)))
    CALL_SUBTEST_4(vectorwiseop_matrix(Matrix4cf()))
    CALL_SUBTEST_5(vectorwiseop_matrix(Matrix[float, 4, 5]()))
    CALL_SUBTEST_6(vectorwiseop_matrix(MatrixXd(internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
    CALL_SUBTEST_7(vectorwiseop_matrix(VectorXd(internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
    CALL_SUBTEST_7(vectorwiseop_matrix(RowVectorXd(internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
<<<FILE>>>