from main import test_precision, g_repeat, VERIFY, VERIFY_IS_APPROX, VERIFY_IS_MUCH_SMALLER_THAN, VERIFY_RAISES_ASSERT, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, EIGEN_ALIGN_MAX, EIGEN_PI
from Eigen.Geometry import Quaternion, AngleAxis, Matrix, Matrix3, Vector3, Map, Aligned, DontAlign, AutoAlign, internal
from math import acos, min, max, abs

def bounded_acos[T: AnyType](v: T) -> T:
    return acos(max(T(-1), min(v, T(1))))

def check_slerp[QuatType: AnyType](q0: QuatType, q1: QuatType):
    var largeEps: Scalar = test_precision[Scalar]()
    var theta_tot: Scalar = AA(q1 * q0.inverse()).angle()
    if theta_tot > Scalar(EIGEN_PI):
        theta_tot = Scalar(2.) * Scalar(EIGEN_PI) - theta_tot
    var t: Scalar = 0.
    while t <= Scalar(1.001):
        var q: QuatType = q0.slerp(t, q1)
        var theta: Scalar = AA(q * q0.inverse()).angle()
        VERIFY(abs(q.norm() - 1) < largeEps)
        if theta_tot == 0:
            VERIFY(theta_tot == 0)
        else:
            VERIFY(abs(theta - t * theta_tot) < largeEps)
        t += Scalar(0.1)

def quaternion[Scalar: AnyType, Options: AnyType]():
    var largeEps: Scalar = test_precision[Scalar]()
    if internal.is_same[Scalar, float]():
        largeEps = Scalar(1e-3)
    var eps: Scalar = internal.random[Scalar]() * Scalar(1e-2)
    var v0: Vector3 = Vector3.Random()
    var v1: Vector3 = Vector3.Random()
    var v2: Vector3 = Vector3.Random()
    var v3: Vector3 = Vector3.Random()
    var a: Scalar = internal.random[Scalar](-Scalar(EIGEN_PI), Scalar(EIGEN_PI))
    var b: Scalar = internal.random[Scalar](-Scalar(EIGEN_PI), Scalar(EIGEN_PI))
    var q1: Quaternionx
    var q2: Quaternionx
    q2.setIdentity()
    VERIFY_IS_APPROX(Quaternionx(Quaternionx.Identity()).coeffs(), q2.coeffs())
    q1.coeffs().setRandom()
    VERIFY_IS_APPROX(q1.coeffs(), (q1 * q2).coeffs())
    q1 *= q2
    q1 = AngleAxisx(a, v0.normalized())
    q2 = AngleAxisx(a, v1.normalized())
    var refangle: Scalar = abs(AngleAxisx(q1.inverse() * q2).angle())
    if refangle > Scalar(EIGEN_PI):
        refangle = Scalar(2) * Scalar(EIGEN_PI) - refangle
    if (q1.coeffs() - q2.coeffs()).norm() > 10 * largeEps:
        VERIFY_IS_MUCH_SMALLER_THAN(abs(q1.angularDistance(q2) - refangle), Scalar(1))
    VERIFY_IS_APPROX(q1 * v2, q1.toRotationMatrix() * v2)
    VERIFY_IS_APPROX(q1 * q2 * v2, q1.toRotationMatrix() * q2.toRotationMatrix() * v2)
    VERIFY((q2 * q1).isApprox(q1 * q2, largeEps) or not (q2 * q1 * v2).isApprox(q1.toRotationMatrix() * q2.toRotationMatrix() * v2))
    q2 = q1.toRotationMatrix()
    VERIFY_IS_APPROX(q1 * v1, q2 * v1)
    var rot1: Matrix3 = Matrix3(q1)
    VERIFY_IS_APPROX(q1 * v1, rot1 * v1)
    var q3: Quaternionx = Quaternionx(rot1.transpose() * rot1)
    VERIFY_IS_APPROX(q3 * v1, v1)
    var aa: AngleAxisx = AngleAxisx(q1)
    VERIFY_IS_APPROX(q1 * v1, Quaternionx(aa) * v1)
    if abs(aa.angle()) > 5 * test_precision[Scalar]() and (aa.axis() - v1.normalized()).norm() < Scalar(1.99) and (aa.axis() + v1.normalized()).norm() < Scalar(1.99):
        VERIFY_IS_NOT_APPROX(q1 * v1, Quaternionx(AngleAxisx(aa.angle() * 2, aa.axis())) * v1)
    VERIFY_IS_APPROX(v2.normalized(), (q2.setFromTwoVectors(v1, v2) * v1).normalized())
    VERIFY_IS_APPROX(v1.normalized(), (q2.setFromTwoVectors(v1, v1) * v1).normalized())
    VERIFY_IS_APPROX(-v1.normalized(), (q2.setFromTwoVectors(v1, -v1) * v1).normalized())
    if internal.is_same[Scalar, double]():
        v3 = (v1.array() + eps).matrix()
        VERIFY_IS_APPROX(v3.normalized(), (q2.setFromTwoVectors(v1, v3) * v1).normalized())
        VERIFY_IS_APPROX(-v3.normalized(), (q2.setFromTwoVectors(v1, -v3) * v1).normalized())
    VERIFY_IS_APPROX(v2.normalized(), (Quaternionx.FromTwoVectors(v1, v2) * v1).normalized())
    VERIFY_IS_APPROX(v1.normalized(), (Quaternionx.FromTwoVectors(v1, v1) * v1).normalized())
    VERIFY_IS_APPROX(-v1.normalized(), (Quaternionx.FromTwoVectors(v1, -v1) * v1).normalized())
    if internal.is_same[Scalar, double]():
        v3 = (v1.array() + eps).matrix()
        VERIFY_IS_APPROX(v3.normalized(), (Quaternionx.FromTwoVectors(v1, v3) * v1).normalized())
        VERIFY_IS_APPROX(-v3.normalized(), (Quaternionx.FromTwoVectors(v1, -v3) * v1).normalized())
    VERIFY_IS_APPROX(q1 * (q1.inverse() * v1), v1)
    VERIFY_IS_APPROX(q1 * (q1.conjugate() * v1), v1)
    var q1f: Quaternion[float] = q1.template cast[float]()
    VERIFY_IS_APPROX(q1f.template cast[Scalar](), q1)
    var q1d: Quaternion[double] = q1.template cast[double]()
    VERIFY_IS_APPROX(q1d.template cast[Scalar](), q1)
    var q: Quaternionx = Quaternionx()
    del q
    q1 = Quaternionx.UnitRandom()
    q2 = Quaternionx.UnitRandom()
    check_slerp(q1, q2)
    q1 = AngleAxisx(b, v1.normalized())
    q2 = AngleAxisx(b + Scalar(EIGEN_PI), v1.normalized())
    check_slerp(q1, q2)
    q1 = AngleAxisx(b, v1.normalized())
    q2 = AngleAxisx(-b, -v1.normalized())
    check_slerp(q1, q2)
    q1 = Quaternionx.UnitRandom()
    q2.coeffs() = -q1.coeffs()
    check_slerp(q1, q2)

def mapQuaternion[Scalar: AnyType]():
    var v0: Vector3 = Vector3.Random()
    var v1: Vector3 = Vector3.Random()
    var a: Scalar = internal.random[Scalar](-Scalar(EIGEN_PI), Scalar(EIGEN_PI))
    EIGEN_ALIGN_MAX var array1: Scalar[4]
    EIGEN_ALIGN_MAX var array2: Scalar[4]
    EIGEN_ALIGN_MAX var array3: Scalar[5]
    var array3unaligned: Scalar* = array3.ptr + 1
    var mq1: MQuaternionA = MQuaternionA(array1)
    var mcq1: MCQuaternionA = MCQuaternionA(array1)
    var mq2: MQuaternionA = MQuaternionA(array2)
    var mq3: MQuaternionUA = MQuaternionUA(array3unaligned)
    var mcq3: MCQuaternionUA = MCQuaternionUA(array3unaligned)
    mq1 = AngleAxisx(a, v0.normalized())
    mq2 = mq1
    mq3 = mq1
    var q1: Quaternionx = Quaternionx(mq1)
    var q2: Quaternionx = Quaternionx(mq2)
    var q3: Quaternionx = Quaternionx(mq3)
    var q4: Quaternionx = Quaternionx(MCQuaternionUA(array3unaligned))
    VERIFY_IS_APPROX(q1.coeffs(), q2.coeffs())
    VERIFY_IS_APPROX(q1.coeffs(), q3.coeffs())
    VERIFY_IS_APPROX(q4.coeffs(), q3.coeffs())
    #ifdef EIGEN_VECTORIZE
    if internal.packet_traits[Scalar].Vectorizable:
        VERIFY_RAISES_ASSERT(MQuaternionA(array3unaligned))
    #endif
    VERIFY_IS_APPROX(mq1 * (mq1.inverse() * v1), v1)
    VERIFY_IS_APPROX(mq1 * (mq1.conjugate() * v1), v1)
    VERIFY_IS_APPROX(mcq1 * (mcq1.inverse() * v1), v1)
    VERIFY_IS_APPROX(mcq1 * (mcq1.conjugate() * v1), v1)
    VERIFY_IS_APPROX(mq3 * (mq3.inverse() * v1), v1)
    VERIFY_IS_APPROX(mq3 * (mq3.conjugate() * v1), v1)
    VERIFY_IS_APPROX(mcq3 * (mcq3.inverse() * v1), v1)
    VERIFY_IS_APPROX(mcq3 * (mcq3.conjugate() * v1), v1)
    VERIFY_IS_APPROX(mq1 * mq2, q1 * q2)
    VERIFY_IS_APPROX(mq3 * mq2, q3 * q2)
    VERIFY_IS_APPROX(mcq1 * mq2, q1 * q2)
    VERIFY_IS_APPROX(mcq3 * mq2, q3 * q2)
    VERIFY_IS_APPROX(mcq3.coeffs().x() + mcq3.coeffs().y() + mcq3.coeffs().z() + mcq3.coeffs().w(), mcq3.coeffs().sum())
    VERIFY_IS_APPROX(mcq3.x() + mcq3.y() + mcq3.z() + mcq3.w(), mcq3.coeffs().sum())
    mq3.w() = 1
    var cq3: Quaternionx = q3
    VERIFY(&cq3.x() == &q3.x())
    var cmq3: MQuaternionUA = mq3
    VERIFY(&cmq3.x() == &mq3.x())

def quaternionAlignment[Scalar: AnyType]():
    EIGEN_ALIGN_MAX var array1: Scalar[4]
    EIGEN_ALIGN_MAX var array2: Scalar[4]
    EIGEN_ALIGN_MAX var array3: Scalar[5]
    var arrayunaligned: Scalar* = array3.ptr + 1
    var q1: QuaternionA = QuaternionA(array1)
    var q2: QuaternionUA = QuaternionUA(array2)
    var q3: QuaternionUA = QuaternionUA(arrayunaligned)
    q1.coeffs().setRandom()
    *q2 = *q1
    *q3 = *q1
    VERIFY_IS_APPROX(q1.coeffs(), q2.coeffs())
    VERIFY_IS_APPROX(q1.coeffs(), q3.coeffs())
    #if defined(EIGEN_VECTORIZE) and EIGEN_MAX_STATIC_ALIGN_BYTES > 0
    if internal.packet_traits[Scalar].Vectorizable and internal.packet_traits[Scalar].size <= 4:
        VERIFY_RAISES_ASSERT(QuaternionA(arrayunaligned))
    #endif

def check_const_correctness[PlainObjectType: AnyType](_: PlainObjectType):
    var ConstPlainObjectType: PlainObjectType = internal.add_const[PlainObjectType]()
    VERIFY(not (internal.traits[Map[ConstPlainObjectType]].Flags & LvalueBit))
    VERIFY(not (internal.traits[Map[ConstPlainObjectType, Aligned]].Flags & LvalueBit))
    VERIFY(not (Map[ConstPlainObjectType].Flags & LvalueBit))
    VERIFY(not (Map[ConstPlainObjectType, Aligned].Flags & LvalueBit))

def test_geo_quaternion():
    for i in range(g_repeat):
        CALL_SUBTEST_1(quaternion[float, AutoAlign]())
        CALL_SUBTEST_1(check_const_correctness(Quaternionf()))
        CALL_SUBTEST_2(quaternion[double, AutoAlign]())
        CALL_SUBTEST_2(check_const_correctness(Quaterniond()))
        CALL_SUBTEST_3(quaternion[float, DontAlign]())
        CALL_SUBTEST_4(quaternion[double, DontAlign]())
        CALL_SUBTEST_5(quaternionAlignment[float]())
        CALL_SUBTEST_6(quaternionAlignment[double]())
        CALL_SUBTEST_1(mapQuaternion[float]())
        CALL_SUBTEST_2(mapQuaternion[double]())