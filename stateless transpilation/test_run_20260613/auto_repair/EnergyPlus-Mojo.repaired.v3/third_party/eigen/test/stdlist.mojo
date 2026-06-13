from main import VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5
from Eigen import StdList
from Eigen import Geometry

def check_stdlist_matrix[MatrixType: type](m: MatrixType):
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var x: MatrixType = MatrixType.Random(rows, cols)
    var y: MatrixType = MatrixType.Random(rows, cols)
    var v: List[MatrixType, Eigen.aligned_allocator[MatrixType]] = List[MatrixType, Eigen.aligned_allocator[MatrixType]](10, MatrixType(rows, cols))
    var w: List[MatrixType, Eigen.aligned_allocator[MatrixType]] = List[MatrixType, Eigen.aligned_allocator[MatrixType]](20, y)
    v.front() = x
    w.front() = w.back()
    VERIFY_IS_APPROX(w.front(), w.back())
    v = w
    var vi: List[MatrixType, Eigen.aligned_allocator[MatrixType]].Iterator = v.begin()
    var wi: List[MatrixType, Eigen.aligned_allocator[MatrixType]].Iterator = w.begin()
    for i in range(20):
        VERIFY_IS_APPROX(*vi, *wi)
        ++vi
        ++wi
    v.resize(21)
    v.back() = x
    VERIFY_IS_APPROX(v.back(), x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v.back(), y)
    v.push_back(x)
    VERIFY_IS_APPROX(v.back(), x)

def check_stdlist_transform[TransformType: type](transform: TransformType):
    type MatrixType = TransformType.MatrixType
    var x: TransformType = TransformType(MatrixType.Random())
    var y: TransformType = TransformType(MatrixType.Random())
    var v: List[TransformType, Eigen.aligned_allocator[TransformType]] = List[TransformType, Eigen.aligned_allocator[TransformType]](10)
    var w: List[TransformType, Eigen.aligned_allocator[TransformType]] = List[TransformType, Eigen.aligned_allocator[TransformType]](20, y)
    v.front() = x
    w.front() = w.back()
    VERIFY_IS_APPROX(w.front(), w.back())
    v = w
    var vi: List[TransformType, Eigen.aligned_allocator[TransformType]].Iterator = v.begin()
    var wi: List[TransformType, Eigen.aligned_allocator[TransformType]].Iterator = w.begin()
    for i in range(20):
        VERIFY_IS_APPROX(*vi, *wi)
        ++vi
        ++wi
    v.resize(21)
    v.back() = x
    VERIFY_IS_APPROX(v.back(), x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v.back(), y)
    v.push_back(x)
    VERIFY_IS_APPROX(v.back(), x)

def check_stdlist_quaternion[QuaternionType: type](quat: QuaternionType):
    type Coefficients = QuaternionType.Coefficients
    var x: QuaternionType = QuaternionType(Coefficients.Random())
    var y: QuaternionType = QuaternionType(Coefficients.Random())
    var v: List[QuaternionType, Eigen.aligned_allocator[QuaternionType]] = List[QuaternionType, Eigen.aligned_allocator[QuaternionType]](10)
    var w: List[QuaternionType, Eigen.aligned_allocator[QuaternionType]] = List[QuaternionType, Eigen.aligned_allocator[QuaternionType]](20, y)
    v.front() = x
    w.front() = w.back()
    VERIFY_IS_APPROX(w.front(), w.back())
    v = w
    var vi: List[QuaternionType, Eigen.aligned_allocator[QuaternionType]].Iterator = v.begin()
    var wi: List[QuaternionType, Eigen.aligned_allocator[QuaternionType]].Iterator = w.begin()
    for i in range(20):
        VERIFY_IS_APPROX(*vi, *wi)
        ++vi
        ++wi
    v.resize(21)
    v.back() = x
    VERIFY_IS_APPROX(v.back(), x)
    v.resize(22, y)
    VERIFY_IS_APPROX(v.back(), y)
    v.push_back(x)
    VERIFY_IS_APPROX(v.back(), x)

def test_stdlist():
    CALL_SUBTEST_1(check_stdlist_matrix[Vector2f](Vector2f()))
    CALL_SUBTEST_1(check_stdlist_matrix[Matrix3f](Matrix3f()))
    CALL_SUBTEST_2(check_stdlist_matrix[Matrix3d](Matrix3d()))
    CALL_SUBTEST_1(check_stdlist_matrix[Matrix2f](Matrix2f()))
    CALL_SUBTEST_1(check_stdlist_matrix[Vector4f](Vector4f()))
    CALL_SUBTEST_1(check_stdlist_matrix[Matrix4f](Matrix4f()))
    CALL_SUBTEST_2(check_stdlist_matrix[Matrix4d](Matrix4d()))
    CALL_SUBTEST_3(check_stdlist_matrix[MatrixXd](MatrixXd(1, 1)))
    CALL_SUBTEST_3(check_stdlist_matrix[VectorXd](VectorXd(20)))
    CALL_SUBTEST_3(check_stdlist_matrix[RowVectorXf](RowVectorXf(20)))
    CALL_SUBTEST_3(check_stdlist_matrix[MatrixXcf](MatrixXcf(10, 10)))
    CALL_SUBTEST_4(check_stdlist_transform[Affine2f](Affine2f()))
    CALL_SUBTEST_4(check_stdlist_transform[Affine3f](Affine3f()))
    CALL_SUBTEST_4(check_stdlist_transform[Affine3d](Affine3d()))
    CALL_SUBTEST_5(check_stdlist_quaternion[Quaternionf](Quaternionf()))
    CALL_SUBTEST_5(check_stdlist_quaternion[Quaterniond](Quaterniond()))