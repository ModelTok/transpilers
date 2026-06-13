from main import *
from Eigen.StdDeque import *
from Eigen.Geometry import *
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Vector4f)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Matrix2f)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Matrix4f)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Matrix4d)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Affine3f)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Affine3d)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Quaternionf)
EIGEN_DEFINE_STL_DEQUE_SPECIALIZATION(Quaterniond)

def check_stddeque_matrix[MatrixType: AnyType](m: MatrixType):
    let rows: MatrixType.Index = m.rows()
    let cols: MatrixType.Index = m.cols()
    let x: MatrixType = MatrixType.Random(rows, cols)
    let y: MatrixType = MatrixType.Random(rows, cols)
    var v: Deque[MatrixType] = Deque[MatrixType](10, MatrixType(rows, cols))
    var w: Deque[MatrixType] = Deque[MatrixType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(0, 20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    let ref: Pointer[MatrixType] = &w[0]
    for i in range(0, 30 if (ref == &w[0]) else 300):
        v.push_back(w[i % w.size()])
    for i in range(23, v.size()):
        VERIFY(v[i] == w[(i - 23) % w.size()])

def check_stddeque_transform[TransformType: AnyType](_: TransformType):
    type MatrixType = TransformType.MatrixType
    let x: TransformType = TransformType(MatrixType.Random())
    let y: TransformType = TransformType(MatrixType.Random())
    var v: Deque[TransformType] = Deque[TransformType](10)
    var w: Deque[TransformType] = Deque[TransformType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(0, 20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    let ref: Pointer[TransformType] = &w[0]
    for i in range(0, 30 if (ref == &w[0]) else 300):
        v.push_back(w[i % w.size()])
    for i in range(23, v.size()):
        VERIFY(v[i].matrix() == w[(i - 23) % w.size()].matrix())

def check_stddeque_quaternion[QuaternionType: AnyType](_: QuaternionType):
    type Coefficients = QuaternionType.Coefficients
    let x: QuaternionType = QuaternionType(Coefficients.Random())
    let y: QuaternionType = QuaternionType(Coefficients.Random())
    var v: Deque[QuaternionType] = Deque[QuaternionType](10)
    var w: Deque[QuaternionType] = Deque[QuaternionType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(0, 20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    let ref: Pointer[QuaternionType] = &w[0]
    for i in range(0, 30 if (ref == &w[0]) else 300):
        v.push_back(w[i % w.size()])
    for i in range(23, v.size()):
        VERIFY(v[i].coeffs() == w[(i - 23) % w.size()].coeffs())

def test_stddeque_overload():
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