from main import *
from Eigen.Geometry import *
from Eigen.LU import *
from Eigen.QR import *

def parametrizedline[LineType: AnyType](_line: LineType):
    """this test covers the following files:
       ParametrizedLine.h
    """
    using std.abs
    let dim: Index = _line.dim()
    alias Scalar = LineType::Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias VectorType = Matrix[Scalar, LineType::AmbientDimAtCompileTime, 1]
    alias HyperplaneType = Hyperplane[Scalar, LineType::AmbientDimAtCompileTime]
    var p0: VectorType = VectorType.Random(dim)
    var p1: VectorType = VectorType.Random(dim)
    var d0: VectorType = VectorType.Random(dim).normalized()
    var l0: LineType = LineType(p0, d0)
    var s0: Scalar = internal.random[Scalar]()
    var s1: Scalar = abs(internal.random[Scalar]())
    VERIFY_IS_MUCH_SMALLER_THAN(l0.distance(p0), RealScalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(l0.distance(p0 + s0 * d0), RealScalar(1))
    VERIFY_IS_APPROX((l0.projection(p1) - p1).norm(), l0.distance(p1))
    VERIFY_IS_MUCH_SMALLER_THAN(l0.distance(l0.projection(p1)), RealScalar(1))
    VERIFY_IS_APPROX(Scalar(l0.distance((p0 + s0 * d0) + d0.unitOrthogonal() * s1)), s1)
    let Dim: Int = LineType::AmbientDimAtCompileTime
    alias OtherScalar = GetDifferentType[Scalar].type
    var hp1f: ParametrizedLine[OtherScalar, Dim] = l0.template cast[OtherScalar]()
    VERIFY_IS_APPROX(hp1f.template cast[Scalar](), l0)
    var hp1d: ParametrizedLine[Scalar, Dim] = l0.template cast[Scalar]()
    VERIFY_IS_APPROX(hp1d.template cast[Scalar](), l0)
    var p2: VectorType = VectorType.Random(dim)
    var n2: VectorType = VectorType.Random(dim).normalized()
    var hp: HyperplaneType = HyperplaneType(p2, n2)
    var t: Scalar = l0.intersectionParameter(hp)
    var pi: VectorType = l0.pointAt(t)
    VERIFY_IS_MUCH_SMALLER_THAN(hp.signedDistance(pi), RealScalar(1))
    VERIFY_IS_MUCH_SMALLER_THAN(l0.distance(pi), RealScalar(1))
    VERIFY_IS_APPROX(l0.intersectionPoint(hp), pi)

def parametrizedline_alignment[Scalar: AnyType]():
    alias Line4a = ParametrizedLine[Scalar, 4, AutoAlign]
    alias Line4u = ParametrizedLine[Scalar, 4, DontAlign]
    var array1: Scalar[16] __attribute__((aligned(EIGEN_ALIGN_MAX)))
    var array2: Scalar[16] __attribute__((aligned(EIGEN_ALIGN_MAX)))
    var array3: Scalar[17] __attribute__((aligned(EIGEN_ALIGN_MAX)))
    var array3u: Scalar* = array3.data() + 1
    var p1: Line4a* = new (reinterpret[__addressof(array1)]) Line4a
    var p2: Line4u* = new (reinterpret[__addressof(array2)]) Line4u
    var p3: Line4u* = new (reinterpret[__addressof(array3u)]) Line4u
    p1.origin().setRandom()
    p1.direction().setRandom()
    *p2 = *p1
    *p3 = *p1
    VERIFY_IS_APPROX(p1.origin(), p2.origin())
    VERIFY_IS_APPROX(p1.origin(), p3.origin())
    VERIFY_IS_APPROX(p1.direction(), p2.direction())
    VERIFY_IS_APPROX(p1.direction(), p3.direction())
    #if defined(EIGEN_VECTORIZE) and EIGEN_MAX_STATIC_ALIGN_BYTES > 0
    if internal.packet_traits[Scalar].Vectorizable and internal.packet_traits[Scalar].size <= 4:
        VERIFY_RAISES_ASSERT((new (reinterpret[__addressof(array3u)]) Line4a))
    #endif

def test_geo_parametrizedline():
    for i in range(g_repeat):
        CALL_SUBTEST_1(parametrizedline(ParametrizedLine[float32, 2]()))
        CALL_SUBTEST_2(parametrizedline(ParametrizedLine[float32, 3]()))
        CALL_SUBTEST_2(parametrizedline_alignment[float32]())
        CALL_SUBTEST_3(parametrizedline(ParametrizedLine[float64, 4]()))
        CALL_SUBTEST_3(parametrizedline_alignment[float64]())
        CALL_SUBTEST_4(parametrizedline(ParametrizedLine[complex[float64], 5]()))