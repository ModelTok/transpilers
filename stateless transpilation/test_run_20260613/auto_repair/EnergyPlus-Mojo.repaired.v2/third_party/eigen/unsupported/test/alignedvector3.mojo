from main import *
from ...Eigen.AlignedVector3 import AlignedVector3
from ...Eigen.Core import Matrix, internal

def Eigen.test_relative_error[T: AnyType, Derived: AnyType](a: AlignedVector3[T], b: MatrixBase[Derived]) -> T:
    return test_relative_error(a.coeffs().head[3](), b)

def alignedvector3[Scalar: AnyType]() raises:
    var s1: Scalar = internal.random[Scalar]()
    var s2: Scalar = internal.random[Scalar]()
    type RefType = Matrix[Scalar, 3, 1]
    type Mat33 = Matrix[Scalar, 3, 3]
    type FastType = AlignedVector3[Scalar]
    var r1: RefType = RefType.Random()
    var r2: RefType = RefType.Random()
    var r3: RefType = RefType.Random()
    var r4: RefType = RefType.Random()
    var r5: RefType = RefType.Random()
    var f1: FastType = FastType(r1)
    var f2: FastType = FastType(r2)
    var f3: FastType = FastType(r3)
    var f4: FastType = FastType(r4)
    var f5: FastType = FastType(r5)
    var m1: Mat33 = Mat33.Random()
    VERIFY_IS_APPROX(f1, r1)
    VERIFY_IS_APPROX(f4, r4)
    VERIFY_IS_APPROX(f4 + f1, r4 + r1)
    VERIFY_IS_APPROX(f4 - f1, r4 - r1)
    VERIFY_IS_APPROX(f4 + f1 - f2, r4 + r1 - r2)
    VERIFY_IS_APPROX(f4 += f3, r4 += r3)
    VERIFY_IS_APPROX(f4 -= f5, r4 -= r5)
    VERIFY_IS_APPROX(f4 -= f5 + f1, r4 -= r5 + r1)
    VERIFY_IS_APPROX(f5 + f1 - s1 * f2, r5 + r1 - s1 * r2)
    VERIFY_IS_APPROX(f5 + f1 / s2 - s1 * f2, r5 + r1 / s2 - s1 * r2)
    VERIFY_IS_APPROX(m1 * f4, m1 * r4)
    VERIFY_IS_APPROX(f4.transpose() * m1, r4.transpose() * m1)
    VERIFY_IS_APPROX(f2.dot(f3), r2.dot(r3))
    VERIFY_IS_APPROX(f2.cross(f3), r2.cross(r3))
    VERIFY_IS_APPROX(f2.norm(), r2.norm())
    VERIFY_IS_APPROX(f2.normalized(), r2.normalized())
    VERIFY_IS_APPROX((f2 + f1).normalized(), (r2 + r1).normalized())
    f2.normalize()
    r2.normalize()
    VERIFY_IS_APPROX(f2, r2)
    {
        var f6: FastType = FastType(RefType.Zero())
        var f7: FastType = FastType.Zero()
        VERIFY_IS_APPROX(f6, f7)
        f6 = r4 + r1
        VERIFY_IS_APPROX(f6, r4 + r1)
        f6 -= Scalar(2) * r4
        VERIFY_IS_APPROX(f6, r1 - r4)
    }
    var ss1: String = String(f1)
    var ss2: String = String(r1)
    VERIFY(ss1 == ss2)

def test_alignedvector3() raises:
    for i in range(g_repeat):
        CALL_SUBTEST(alignedvector3[float32]())