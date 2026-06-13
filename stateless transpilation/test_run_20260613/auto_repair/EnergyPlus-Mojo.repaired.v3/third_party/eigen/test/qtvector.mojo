from main import main
from Eigen.Geometry import Geometry
from Eigen.QtAlignedMalloc import QtAlignedMalloc
from tensor import Tensor
from pointer import Pointer
from memory import sizeof
from sys import int

def is_approx(a: Tensor, b: Tensor) -> bool:
    return (a - b).norm() < 1e-6

def VERIFY_IS_APPROX(a: Tensor, b: Tensor):
    if not is_approx(a, b):
        print("VERIFY_IS_APPROX failed")
        exit(1)

def VERIFY(condition: bool):
    if not condition:
        print("VERIFY failed")
        exit(1)

template<MatrixType>
def check_qtvector_matrix(m: MatrixType):
    rows = m.rows()
    cols = m.cols()
    x = MatrixType.Random(rows, cols)
    y = MatrixType.Random(rows, cols)
    v = QVector[MatrixType](10, MatrixType(rows, cols))
    w = QVector[MatrixType](20, y)
    for i in range(20):
        VERIFY_IS_APPROX(w[i], y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.fill(y, 22)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY(Pointer.address_of(v[22]) == Pointer.address_of(v[21]) + sizeof[MatrixType]())
    ref = Pointer.address_of(w[0])
    i = 0
    while i < 30 or (ref == Pointer.address_of(w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i] == w[(i - 23) % w.size()])

template<TransformType>
def check_qtvector_transform(t: TransformType):
    MatrixType = TransformType.MatrixType
    x = TransformType(MatrixType.Random())
    y = TransformType(MatrixType.Random())
    v = QVector[TransformType](10)
    w = QVector[TransformType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.fill(y, 22)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY(Pointer.address_of(v[22]) == Pointer.address_of(v[21]) + sizeof[TransformType]())
    ref = Pointer.address_of(w[0])
    i = 0
    while i < 30 or (ref == Pointer.address_of(w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].matrix() == w[(i - 23) % w.size()].matrix())

template<QuaternionType>
def check_qtvector_quaternion(q: QuaternionType):
    Coefficients = QuaternionType.Coefficients
    x = QuaternionType(Coefficients.Random())
    y = QuaternionType(Coefficients.Random())
    v = QVector[QuaternionType](10)
    w = QVector[QuaternionType](20, y)
    v[5] = x
    w[6] = v[5]
    VERIFY_IS_APPROX(w[6], v[5])
    v = w
    for i in range(20):
        VERIFY_IS_APPROX(w[i], v[i])
    v.resize(21)
    v[20] = x
    VERIFY_IS_APPROX(v[20], x)
    v.fill(y, 22)
    VERIFY_IS_APPROX(v[21], y)
    v.push_back(x)
    VERIFY_IS_APPROX(v[22], x)
    VERIFY(Pointer.address_of(v[22]) == Pointer.address_of(v[21]) + sizeof[QuaternionType]())
    ref = Pointer.address_of(w[0])
    i = 0
    while i < 30 or (ref == Pointer.address_of(w[0]) and i < 300):
        v.push_back(w[i % w.size()])
        i += 1
    for i in range(23, v.size()):
        VERIFY(v[i].coeffs() == w[(i - 23) % w.size()].coeffs())

def test_qtvector():
    CALL_SUBTEST(check_qtvector_matrix(Vector2f()))
    CALL_SUBTEST(check_qtvector_matrix(Matrix3f()))
    CALL_SUBTEST(check_qtvector_matrix(Matrix3d()))
    CALL_SUBTEST(check_qtvector_matrix(Matrix2f()))
    CALL_SUBTEST(check_qtvector_matrix(Vector4f()))
    CALL_SUBTEST(check_qtvector_matrix(Matrix4f()))
    CALL_SUBTEST(check_qtvector_matrix(Matrix4d()))
    CALL_SUBTEST(check_qtvector_matrix(MatrixXd(1, 1)))
    CALL_SUBTEST(check_qtvector_matrix(VectorXd(20)))
    CALL_SUBTEST(check_qtvector_matrix(RowVectorXf(20)))
    CALL_SUBTEST(check_qtvector_matrix(MatrixXcf(10, 10)))
    CALL_SUBTEST(check_qtvector_transform(Affine2f()))
    CALL_SUBTEST(check_qtvector_transform(Affine3f()))
    CALL_SUBTEST(check_qtvector_transform(Affine3d()))
    CALL_SUBTEST(check_qtvector_quaternion(Quaternionf()))
    CALL_SUBTEST(check_qtvector_quaternion(Quaternionf()))