from main import *
from Eigen.StdVector import *
from Eigen.Geometry import *
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Vector4f)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Matrix2f)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Matrix4f)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Matrix4d)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Affine3f)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Affine3d)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Quaternionf)
EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(Quaterniond)

def check_stdvector_matrix[MatrixType: AnyType](m: MatrixType):
    let rows: MatrixType.Index = m.rows()
    let cols: MatrixType.Index = m.cols()
    let x: MatrixType = MatrixType.Random(rows, cols)
    let y: MatrixType = MatrixType.Random(rows, cols)
    var v: std.vector[MatrixType] = std.vector[MatrixType](10, MatrixType(rows, cols))
    var w: std.vector[MatrixType] = std.vector[MatrixType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY((internal.UIntPtr)(address_of(v[22])) == (internal.UIntPtr)(address_of(v[21])) + sizeof[MatrixType]())
    let ref: Pointer[MatrixType] = address_of(w[0])
    var i: Int = 0
    while i < 30 or ((ref == address_of(w[0])) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i] == w[(i - 23) % w.size()])

def check_stdvector_transform[TransformType: AnyType](_: TransformType):
    typealias MatrixType = TransformType.MatrixType
    let x: TransformType = TransformType(MatrixType.Random())
    let y: TransformType = TransformType(MatrixType.Random())
    var v: std.vector[TransformType] = std.vector[TransformType](10)
    var w: std.vector[TransformType] = std.vector[TransformType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY((internal.UIntPtr)(address_of(v[22])) == (internal.UIntPtr)(address_of(v[21])) + sizeof[TransformType]())
    let ref: Pointer[TransformType] = address_of(w[0])
    var i: Int = 0
    while i < 30 or ((ref == address_of(w[0])) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].matrix() == w[(i - 23) % w.size()].matrix())

def check_stdvector_quaternion[QuaternionType: AnyType](_: QuaternionType):
    typealias Coefficients = QuaternionType.Coefficients
    let x: QuaternionType = QuaternionType(Coefficients.Random())
    let y: QuaternionType = QuaternionType(Coefficients.Random())
    var v: std.vector[QuaternionType] = std.vector[QuaternionType](10)
    var w: std.vector[QuaternionType] = std.vector[QuaternionType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY((internal.UIntPtr)(address_of(v[22])) == (internal.UIntPtr)(address_of(v[21])) + sizeof[QuaternionType]())
    let ref: Pointer[QuaternionType] = address_of(w[0])
    var i: Int = 0
    while i < 30 or ((ref == address_of(w[0])) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].coeffs() == w[(i - 23) % w.size()].coeffs())

def test_stdvector_overload():
    CALL_SUBTEST_1(check_stdvector_matrix(Vector2f()))
    CALL_SUBTEST_1(check_stdvector_matrix(Matrix3f()))
    CALL_SUBTEST_2(check_stdvector_matrix(Matrix3d()))
    CALL_SUBTEST_1(check_stdvector_matrix(Matrix2f()))
    CALL_SUBTEST_1(check_stdvector_matrix(Vector4f()))
    CALL_SUBTEST_1(check_stdvector_matrix(Matrix4f()))
    CALL_SUBTEST_2(check_stdvector_matrix(Matrix4d()))
    CALL_SUBTEST_3(check_stdvector_matrix(MatrixXd(1, 1)))
    CALL_SUBTEST_3(check_stdvector_matrix(VectorXd(20)))
    CALL_SUBTEST_3(check_stdvector_matrix(RowVectorXf(20)))
    CALL_SUBTEST_3(check_stdvector_matrix(MatrixXcf(10, 10)))
    CALL_SUBTEST_4(check_stdvector_transform(Affine2f()))
    CALL_SUBTEST_4(check_stdvector_transform(Affine3f()))
    CALL_SUBTEST_4(check_stdvector_transform(Affine3d()))
    CALL_SUBTEST_5(check_stdvector_quaternion(Quaternionf()))
    CALL_SUBTEST_5(check_stdvector_quaternion(Quaterniond()))