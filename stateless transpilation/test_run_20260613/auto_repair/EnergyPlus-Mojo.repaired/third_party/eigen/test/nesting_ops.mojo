// #define TEST_ENABLE_TEMPORARY_TRACKING
from main import *
from internal import *

def use_n_times[N: Int, XprType: AnyType](xpr: XprType):
    var mat: internal.nested_eval[XprType, N].type = internal.nested_eval[XprType, N](xpr)
    var res: XprType.PlainObject(mat.rows(), mat.cols())
    nb_temporaries-- // remove res
    res.setZero()
    for i in range(N):
        res += mat

def verify_eval_type[N: Int, ReferenceType: AnyType, XprType: AnyType](_xpr: XprType, _ref: ReferenceType) -> Bool:
    alias EvalType = internal.nested_eval[XprType, N].type
    return internal.is_same[internal.remove_all[EvalType].type, internal.remove_all[ReferenceType].type].value

def run_nesting_ops_1[MatrixType: AnyType](_m: MatrixType):
    var m: internal.nested_eval[MatrixType, 2].type = internal.nested_eval[MatrixType, 2](_m)
    VERIFY_RAISES_ASSERT(eigen_assert(False))
    VERIFY_IS_APPROX((m.transpose() * m).diagonal().sum(), (m.transpose() * m).diagonal().sum())
    VERIFY_IS_APPROX((m.transpose() * m).diagonal().array().abs().sum(), (m.transpose() * m).diagonal().array().abs().sum())
    VERIFY_IS_APPROX((m.transpose() * m).array().abs().sum(), (m.transpose() * m).array().abs().sum())

def run_nesting_ops_2[MatrixType: AnyType](_m: MatrixType):
    alias Scalar = MatrixType.Scalar
    var rows: Int = _m.rows()
    var cols: Int = _m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime, ColMajor]
    if MatrixType.SizeAtCompileTime == Dynamic:
        VERIFY_EVALUATION_COUNT(use_n_times[1, typeof(m1 + m1*m1)](m1 + m1*m1), 1)
        VERIFY_EVALUATION_COUNT(use_n_times[10, typeof(m1 + m1*m1)](m1 + m1*m1), 1)
        VERIFY_EVALUATION_COUNT(use_n_times[1, typeof(m1.triangularView[Lower]().solve(m1.col(0)))](m1.triangularView[Lower]().solve(m1.col(0))), 1)
        VERIFY_EVALUATION_COUNT(use_n_times[10, typeof(m1.triangularView[Lower]().solve(m1.col(0)))](m1.triangularView[Lower]().solve(m1.col(0))), 1)
        VERIFY_EVALUATION_COUNT(use_n_times[1, typeof(Scalar(2)*m1.triangularView[Lower]().solve(m1.col(0)))](Scalar(2)*m1.triangularView[Lower]().solve(m1.col(0))), 2) // FIXME could be one by applying the scaling in-place on the solve result
        VERIFY_EVALUATION_COUNT(use_n_times[1, typeof(m1.col(0)+m1.triangularView[Lower]().solve(m1.col(0)))](m1.col(0)+m1.triangularView[Lower]().solve(m1.col(0))), 2) // FIXME could be one by adding m1.col() inplace
        VERIFY_EVALUATION_COUNT(use_n_times[10, typeof(m1.col(0)+m1.triangularView[Lower]().solve(m1.col(0)))](m1.col(0)+m1.triangularView[Lower]().solve(m1.col(0))), 2)
    # {
        VERIFY(verify_eval_type[10, typeof(m1), typeof(m1)](m1, m1))
        if not NumTraits[Scalar].IsComplex:
            VERIFY(verify_eval_type[3, typeof(2*m1), typeof(2*m1)](2*m1, 2*m1))
            VERIFY(verify_eval_type[4, typeof(2*m1), typeof(m1)](2*m1, m1))
        else:
            VERIFY(verify_eval_type[2, typeof(2*m1), typeof(2*m1)](2*m1, 2*m1))
            VERIFY(verify_eval_type[3, typeof(2*m1), typeof(m1)](2*m1, m1))
        # }
        VERIFY(verify_eval_type[2, typeof(m1+m1), typeof(m1+m1)](m1+m1, m1+m1))
        VERIFY(verify_eval_type[3, typeof(m1+m1), typeof(m1)](m1+m1, m1))
        VERIFY(verify_eval_type[1, typeof(m1*m1.transpose()), typeof(m2)](m1*m1.transpose(), m2))
        VERIFY(verify_eval_type[1, typeof(m1*(m1+m1).transpose()), typeof(m2)](m1*(m1+m1).transpose(), m2))
        VERIFY(verify_eval_type[2, typeof(m1*m1.transpose()), typeof(m2)](m1*m1.transpose(), m2))
        VERIFY(verify_eval_type[1, typeof(m1+m1*m1), typeof(m1)](m1+m1*m1, m1))
        VERIFY(verify_eval_type[1, typeof(m1.triangularView[Lower]().solve(m1)), typeof(m1)](m1.triangularView[Lower]().solve(m1), m1))
        VERIFY(verify_eval_type[1, typeof(m1+m1.triangularView[Lower]().solve(m1)), typeof(m1)](m1+m1.triangularView[Lower]().solve(m1), m1))

def test_nesting_ops():
    CALL_SUBTEST_1(run_nesting_ops_1(MatrixXf.Random(25,25)))
    CALL_SUBTEST_2(run_nesting_ops_1(MatrixXcd.Random(25,25)))
    CALL_SUBTEST_3(run_nesting_ops_1(Matrix4f.Random()))
    CALL_SUBTEST_4(run_nesting_ops_1(Matrix2d.Random()))
    var s: Int = internal.random[Int](1, EIGEN_TEST_MAX_SIZE)
    CALL_SUBTEST_1(run_nesting_ops_2(MatrixXf(s,s)))
    CALL_SUBTEST_2(run_nesting_ops_2(MatrixXcd(s,s)))
    CALL_SUBTEST_3(run_nesting_ops_2(Matrix4f()))
    CALL_SUBTEST_4(run_nesting_ops_2(Matrix2d()))
    TEST_SET_BUT_UNUSED_VARIABLE(s)