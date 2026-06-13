from ...Eigen import Vector2f, Matrix3f, Matrix3d, Matrix2f, Vector4f, Matrix4f, Matrix4d, MatrixXd, VectorXd, RowVectorXf, MatrixXcf, Affine2f, Affine3f, Affine3d, Quaternionf, Quaterniond
from main import VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5

def check_stddeque_matrix[T: AnyType](borrowed m: T):
    var rows = m.rows()
    var cols = m.cols()
    var x = T.random(rows, cols)
    var y = T.random(rows, cols)
    var v = deque[T]([T(rows, cols) for _ in range(10)])
    var w = deque[T]([y for _ in range(20)])
    v[0] = x
    w[0] = w[-1]
    VERIFY_IS_APPROX(w[0], w[-1])
    v = w
    var vi = iter(v)
    var wi = iter(w)
    for i in range(20):
        VERIFY_IS_APPROX(vi.__next__(), wi.__next__())
    v.resize(21)
    v[-1] = x
    VERIFY_IS_APPROX(v[-1], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[-1], y)
    v.append(x)
    VERIFY_IS_APPROX(v[-1], x)

def check_stddeque_transform[TransformType: AnyType](borrowed _: TransformType):
    typedef TransformType::MatrixType MatrixType
    var x = TransformType(MatrixType.random())
    var y = TransformType(MatrixType.random())
    var v = deque[TransformType]([TransformType() for _ in range(10)])
    var w = deque[TransformType]([y for _ in range(20)])
    v[0] = x
    w[0] = w[-1]
    VERIFY_IS_APPROX(w[0], w[-1])
    v = w
    var vi = iter(v)
    var wi = iter(w)
    for i in range(20):
        VERIFY_IS_APPROX(vi.__next__(), wi.__next__())
    v.resize(21)
    v[-1] = x
    VERIFY_IS_APPROX(v[-1], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[-1], y)
    v.append(x)
    VERIFY_IS_APPROX(v[-1], x)

def check_stddeque_quaternion[QuaternionType: AnyType](borrowed _: QuaternionType):
    typedef QuaternionType::Coefficients Coefficients
    var x = QuaternionType(Coefficients.random())
    var y = QuaternionType(Coefficients.random())
    var v = deque[QuaternionType]([QuaternionType() for _ in range(10)])
    var w = deque[QuaternionType]([y for _ in range(20)])
    v[0] = x
    w[0] = w[-1]
    VERIFY_IS_APPROX(w[0], w[-1])
    v = w
    var vi = iter(v)
    var wi = iter(w)
    for i in range(20):
        VERIFY_IS_APPROX(vi.__next__(), wi.__next__())
    v.resize(21)
    v[-1] = x
    VERIFY_IS_APPROX(v[-1], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[-1], y)
    v.append(x)
    VERIFY_IS_APPROX(v[-1], x)

def test_stddeque():
    CALL_SUBTEST_1(check_stddeque_matrix(Vector2f()))
    CALL_SUBTEST_1(check_stddeque_matrix(Matrix3f()))
    CALL_SUBTEST_2(check_stddeque_matrix(Matrix3d()))
    CALL_SUBTEST_1(check_stddeque_matrix(Matrix2f()))
    CALL_SUBTEST_1(check_stddeque_matrix(Vector4f()))
    CALL_SUBTEST_1(check_stddeque_matrix(Matrix4f()))
    CALL_SUBTEST_2(check_stddeque_matrix(Matrix4d()))
    CALL_SUBTEST_3(check_stddeque_matrix(MatrixXd(1, 1)))
    CALL_SUBTEST_3(check_stddeque_matrix(VectorXd(20)))
    CALL_SUBTEST_3(check_stddeque_matrix(RowVectorXf(20)))
    CALL_SUBTEST_3(check_stddeque_matrix(MatrixXcf(10, 10)))
    CALL_SUBTEST_4(check_stddeque_transform(Affine2f()))
    CALL_SUBTEST_4(check_stddeque_transform(Affine3f()))
    CALL_SUBTEST_4(check_stddeque_transform(Affine3d()))
    CALL_SUBTEST_5(check_stddeque_quaternion(Quaternionf()))
    CALL_SUBTEST_5(check_stddeque_quaternion(Quaterniond()))