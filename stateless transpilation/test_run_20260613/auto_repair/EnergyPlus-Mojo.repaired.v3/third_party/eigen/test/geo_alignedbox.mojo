from main import g_repeat, VERIFY, VERIFY_IS_APPROX, CALL_SUBTEST_
from Eigen.Geometry import AlignedBox, Matrix, Vector, NumTraits, internal
from Eigen.LU import *
from Eigen.QR import *
from math import sqrt

def kill_extra_precision[T: AnyType](x: T):
    debug_assert(True)  # placeholder: eigen_assert((void*)(&x) != (void*)0)

def alignedbox[BoxType: AnyType](_box: BoxType):
    # /* this test covers the following files:
    #    AlignedBox.h
    # */
    Scalar = BoxType.Scalar
    RealScalar = NumTraits[Scalar].Real
    VectorType = Matrix[Scalar, BoxType.AmbientDimAtCompileTime, 1]
    dim = _box.dim()
    var p0 = VectorType.Random(dim)
    var p1 = VectorType.Random(dim)
    while p1 == p0:
        p1 = VectorType.Random(dim)
    s1 = internal.random[RealScalar](0, 1)
    var b0 = BoxType(dim)
    var b1 = BoxType(VectorType.Random(dim), VectorType.Random(dim))
    var b2 = BoxType()
    kill_extra_precision(b1)
    kill_extra_precision(p0)
    kill_extra_precision(p1)
    b0.extend(p0)
    b0.extend(p1)
    VERIFY(b0.contains(p0 * s1 + (Scalar(1) - s1) * p1))
    VERIFY(b0.contains(b0.center()))
    VERIFY_IS_APPROX(b0.center(), (p0 + p1) / Scalar(2))
    (b2 = b0).extend(b1)
    VERIFY(b2.contains(b0))
    VERIFY(b2.contains(b1))
    VERIFY_IS_APPROX(b2.clamp(b0), b0)
    var box1 = BoxType(VectorType.Random(dim))
    box1.extend(VectorType.Random(dim))
    var box2 = BoxType(VectorType.Random(dim))
    box2.extend(VectorType.Random(dim))
    VERIFY(box1.intersects(box2) == not box1.intersection(box2).isEmpty())
    var bp0 = BoxType(dim)
    var bp1 = BoxType(dim)
    bp0.extend(bp1)
    for i in range(10):
        r = b0.sample()
        VERIFY(b0.contains(r))

def alignedboxCastTests[BoxType: AnyType](_box: BoxType):
    Scalar = BoxType.Scalar
    VectorType = Matrix[Scalar, BoxType.AmbientDimAtCompileTime, 1]
    dim = _box.dim()
    var p0 = VectorType.Random(dim)
    var p1 = VectorType.Random(dim)
    var b0 = BoxType(dim)
    b0.extend(p0)
    b0.extend(p1)
    Dim = BoxType.AmbientDimAtCompileTime
    OtherScalar = GetDifferentType[Scalar].type
    var hp1f = AlignedBox[OtherScalar, Dim](b0.template cast[OtherScalar]())
    VERIFY_IS_APPROX(hp1f.template cast[Scalar](), b0)
    var hp1d = AlignedBox[Scalar, Dim](b0.template cast[Scalar]())
    VERIFY_IS_APPROX(hp1d.template cast[Scalar](), b0)

def specificTest1():
    var m = Vector2f()
    m[0] = -1.0
    m[1] = -2.0
    var M = Vector2f()
    M[0] = 1.0
    M[1] = 5.0
    BoxType = AlignedBox2f
    var box = BoxType(m, M)
    var sides = M - m
    VERIFY_IS_APPROX(sides, box.sizes())
    VERIFY_IS_APPROX(sides[1], box.sizes()[1])
    VERIFY_IS_APPROX(sides[1], box.sizes().maxCoeff())
    VERIFY_IS_APPROX(sides[0], box.sizes().minCoeff())
    VERIFY_IS_APPROX(14.0, box.volume())
    VERIFY_IS_APPROX(53.0, box.diagonal().squaredNorm())
    VERIFY_IS_APPROX(sqrt(53.0), box.diagonal().norm())
    VERIFY_IS_APPROX(m, box.corner(BoxType.BottomLeft))
    VERIFY_IS_APPROX(M, box.corner(BoxType.TopRight))
    var bottomRight = Vector2f()
    bottomRight[0] = M[0]
    bottomRight[1] = m[1]
    var topLeft = Vector2f()
    topLeft[0] = m[0]
    topLeft[1] = M[1]
    VERIFY_IS_APPROX(bottomRight, box.corner(BoxType.BottomRight))
    VERIFY_IS_APPROX(topLeft, box.corner(BoxType.TopLeft))

def specificTest2():
    var m = Vector3i()
    m[0] = -1
    m[1] = -2
    m[2] = 0
    var M = Vector3i()
    M[0] = 1
    M[1] = 5
    M[2] = 3
    BoxType = AlignedBox3i
    var box = BoxType(m, M)
    var sides = M - m
    VERIFY_IS_APPROX(sides, box.sizes())
    VERIFY_IS_APPROX(sides[1], box.sizes()[1])
    VERIFY_IS_APPROX(sides[1], box.sizes().maxCoeff())
    VERIFY_IS_APPROX(sides[0], box.sizes().minCoeff())
    VERIFY_IS_APPROX(42, box.volume())
    VERIFY_IS_APPROX(62, box.diagonal().squaredNorm())
    VERIFY_IS_APPROX(m, box.corner(BoxType.BottomLeftFloor))
    VERIFY_IS_APPROX(M, box.corner(BoxType.TopRightCeil))
    var bottomRightFloor = Vector3i()
    bottomRightFloor[0] = M[0]
    bottomRightFloor[1] = m[1]
    bottomRightFloor[2] = m[2]
    var topLeftFloor = Vector3i()
    topLeftFloor[0] = m[0]
    topLeftFloor[1] = M[1]
    topLeftFloor[2] = m[2]
    VERIFY_IS_APPROX(bottomRightFloor, box.corner(BoxType.BottomRightFloor))
    VERIFY_IS_APPROX(topLeftFloor, box.corner(BoxType.TopLeftFloor))

def test_geo_alignedbox():
    for i in range(g_repeat):
        CALL_SUBTEST_(1, alignedbox(AlignedBox2f()))
        CALL_SUBTEST_(2, alignedboxCastTests(AlignedBox2f()))
        CALL_SUBTEST_(3, alignedbox(AlignedBox3f()))
        CALL_SUBTEST_(4, alignedboxCastTests(AlignedBox3f()))
        CALL_SUBTEST_(5, alignedbox(AlignedBox4d()))
        CALL_SUBTEST_(6, alignedboxCastTests(AlignedBox4d()))
        CALL_SUBTEST_(7, alignedbox(AlignedBox1d()))
        CALL_SUBTEST_(8, alignedboxCastTests(AlignedBox1d()))
        CALL_SUBTEST_(9, alignedbox(AlignedBox1i()))
        CALL_SUBTEST_(10, alignedbox(AlignedBox2i()))
        CALL_SUBTEST_(11, alignedbox(AlignedBox3i()))
        CALL_SUBTEST_(14, alignedbox(AlignedBox[float64, Dynamic](4)))
    CALL_SUBTEST_(12, specificTest1())
    CALL_SUBTEST_(13, specificTest2())