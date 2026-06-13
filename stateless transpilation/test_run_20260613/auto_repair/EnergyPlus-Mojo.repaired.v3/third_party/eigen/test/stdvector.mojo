from main import *
from Eigen.StdVector import *
from Eigen.Geometry import *

def check_stdvector_matrix[MatrixType: AnyType](m: MatrixType):
    let rows = m.rows()
    let cols = m.cols()
    var x = MatrixType.Random(rows, cols)
    var y = MatrixType.Random(rows, cols)
    var v = List[MatrixType](10, MatrixType(rows, cols))
    var w = List[MatrixType](20, y)
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
    VERIFY((internal.UIntPtr)(&(v[22])) == (internal.UIntPtr)(&(v[21])) + sizeof[MatrixType]())
    var ref = &w[0]
    var i = 0
    while i < 30 or ((ref == &w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i] == w[(i - 23) % w.size()])

def check_stdvector_transform[TransformType: AnyType](_: TransformType):
    type MatrixType = TransformType.MatrixType
    var x = TransformType(MatrixType.Random())
    var y = TransformType(MatrixType.Random())
    var v = List[TransformType](10)
    var w = List[TransformType](20, y)
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
    VERIFY((internal.UIntPtr)(&(v[22])) == (internal.UIntPtr)(&(v[21])) + sizeof[TransformType]())
    var ref = &w[0]
    var i = 0
    while i < 30 or ((ref == &w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].matrix() == w[(i - 23) % w.size()].matrix())

def check_stdvector_quaternion[QuaternionType: AnyType](_: QuaternionType):
    type Coefficients = QuaternionType.Coefficients
    var x = QuaternionType(Coefficients.Random())
    var y = QuaternionType(Coefficients.Random())
    var v = List[QuaternionType](10)
    var w = List[QuaternionType](20, y)
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
    VERIFY((internal.UIntPtr)(&(v[22])) == (internal.UIntPtr)(&(v[21])) + sizeof[QuaternionType]())
    var ref = &w[0]
    var i = 0
    while i < 30 or ((ref == &w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].coeffs() == w[(i - 23) % w.size()].coeffs())

def std_vector_gcc_warning():
    type T = Eigen.Vector3f
    var v = List[T]()
    v.push_back(T())

def test_stdvector():
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
    CALL_SUBTEST_4(check_stdvector_transform(Projective2f()))
    CALL_SUBTEST_4(check_stdvector_transform(Projective3f()))
    CALL_SUBTEST_4(check_stdvector_transform(Projective3d()))
    CALL_SUBTEST_5(check_stdvector_quaternion(Quaternionf()))
    CALL_SUBTEST_5(check_stdvector_quaternion(Quaterniond()))