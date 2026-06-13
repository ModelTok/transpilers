from main import main, g_repeat, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6
from Eigen.Geometry import *
from Eigen.LU import *
from Eigen.SVD import *
/* this test covers the following files:
   Geometry/OrthoMethods.h
*/
def orthomethods_3[Scalar: DType]():
    alias RealScalar = NumTraits[Scalar].Real
    alias Matrix3 = Matrix[Scalar, 3, 3]
    alias Vector3 = Matrix[Scalar, 3, 1]
    alias Vector4 = Matrix[Scalar, 4, 1]
    var v0: Vector3 = Vector3.Random()
    var v1: Vector3 = Vector3.Random()
    var v2: Vector3 = Vector3.Random()
    VERIFY_IS_MUCH_SMALLER_THAN(v1.cross(v2).dot(v1), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(v1.dot(v1.cross(v2)), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(v1.cross(v2).dot(v2), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(v2.dot(v1.cross(v2)), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(v1.cross(Vector3.Random()).dot(v1), Scalar(1))
    var mat3: Matrix3
    mat3 = Matrix3(v0.normalized(),
         (v0.cross(v1)).normalized(),
         (v0.cross(v1).cross(v0)).normalized())
    VERIFY(mat3.isUnitary())
    mat3.setRandom()
    VERIFY_IS_APPROX(v0.cross(mat3*v1), -(mat3*v1).cross(v0))
    VERIFY_IS_APPROX(v0.cross(mat3.lazyProduct(v1)), -(mat3.lazyProduct(v1)).cross(v0))
    mat3.setRandom()
    var vec3: Vector3 = Vector3.Random()
    var mcross: Matrix3
    var i: Int = internal.random[Int](0,2)
    mcross = mat3.colwise().cross(vec3)
    VERIFY_IS_APPROX(mcross.col(i), mat3.col(i).cross(vec3))
    VERIFY_IS_MUCH_SMALLER_THAN((mat3.adjoint() * mat3.colwise().cross(vec3)).diagonal().cwiseAbs().sum(), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN((mat3.adjoint() * mat3.colwise().cross(Vector3.Random())).diagonal().cwiseAbs().sum(), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN((vec3.adjoint() * mat3.colwise().cross(vec3)).cwiseAbs().sum(), Scalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN((vec3.adjoint() * Matrix3.Random().colwise().cross(vec3)).cwiseAbs().sum(), Scalar(1))
    mcross = mat3.rowwise().cross(vec3)
    VERIFY_IS_APPROX(mcross.row(i), mat3.row(i).cross(vec3))
    var v40: Vector4 = Vector4.Random()
    var v41: Vector4 = Vector4.Random()
    var v42: Vector4 = Vector4.Random()
    v40.w() = v41.w() = v42.w() = 0
    v42.template head[3]() = v40.template head[3]().cross(v41.template head[3]())
    VERIFY_IS_APPROX(v40.cross3(v41), v42)
    VERIFY_IS_MUCH_SMALLER_THAN(v40.cross3(Vector4.Random()).dot(v40), Scalar(1))
    alias RealVector3 = Matrix[RealScalar, 3, 1]
    var rv1: RealVector3 = RealVector3.Random()
    VERIFY_IS_APPROX(v1.cross(rv1.template cast[Scalar]()), v1.cross(rv1))
    VERIFY_IS_APPROX(rv1.template cast[Scalar]().cross(v1), rv1.cross(v1))

def orthomethods[Scalar: DType, Size: Int](size: Int = Size):
    alias RealScalar = NumTraits[Scalar].Real
    alias VectorType = Matrix[Scalar, Size, 1]
    alias Matrix3N = Matrix[Scalar, 3, Size]
    alias MatrixN3 = Matrix[Scalar, Size, 3]
    alias Vector3 = Matrix[Scalar, 3, 1]
    var v0: VectorType = VectorType.Random(size)
    VERIFY_IS_MUCH_SMALLER_THAN(v0.unitOrthogonal().dot(v0), Scalar(1))
    VERIFY_IS_APPROX(v0.unitOrthogonal().norm(), RealScalar(1))
    if size>=3:
        v0.template head[2]().setZero()
        v0.tail(size-2).setRandom()
        VERIFY_IS_MUCH_SMALLER_THAN(v0.unitOrthogonal().dot(v0), Scalar(1))
        VERIFY_IS_APPROX(v0.unitOrthogonal().norm(), RealScalar(1))
    var vec3: Vector3 = Vector3.Random()
    var i: Int = internal.random[Int](0,size-1)
    var mat3N: Matrix3N = Matrix3N(3,size)
    var mcross3N: Matrix3N = Matrix3N(3,size)
    mat3N.setRandom()
    mcross3N = mat3N.colwise().cross(vec3)
    VERIFY_IS_APPROX(mcross3N.col(i), mat3N.col(i).cross(vec3))
    var matN3: MatrixN3 = MatrixN3(size,3)
    var mcrossN3: MatrixN3 = MatrixN3(size,3)
    matN3.setRandom()
    mcrossN3 = matN3.rowwise().cross(vec3)
    VERIFY_IS_APPROX(mcrossN3.row(i), matN3.row(i).cross(vec3))

def test_geo_orthomethods():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1( orthomethods_3[float]() )
        CALL_SUBTEST_2( orthomethods_3[double]() )
        CALL_SUBTEST_4( orthomethods_3[complex[double]]() )
        CALL_SUBTEST_1( (orthomethods[float,2]()) )
        CALL_SUBTEST_2( (orthomethods[double,2]()) )
        CALL_SUBTEST_1( (orthomethods[float,3]()) )
        CALL_SUBTEST_2( (orthomethods[double,3]()) )
        CALL_SUBTEST_3( (orthomethods[float,7]()) )
        CALL_SUBTEST_4( (orthomethods[complex[double],8]()) )
        CALL_SUBTEST_5( (orthomethods[float,Dynamic](36)) )
        CALL_SUBTEST_6( (orthomethods[double,Dynamic](35)) )