from main import *
from Eigen.Geometry import *
from Eigen.LU import *
from Eigen.QR import *

def hyperplane[HyperplaneType: AnyType](_plane: HyperplaneType):
    """ this test covers the following files:
       Hyperplane.h
    """
    using std.abs
    let dim: Index = _plane.dim()
    enum Options = HyperplaneType.Options
    alias Scalar = HyperplaneType.Scalar
    alias RealScalar = HyperplaneType.RealScalar
    alias VectorType = Matrix[Scalar, HyperplaneType.AmbientDimAtCompileTime, 1]
    alias MatrixType = Matrix[Scalar, HyperplaneType.AmbientDimAtCompileTime, HyperplaneType.AmbientDimAtCompileTime]
    var p0: VectorType = VectorType.Random(dim)
    var p1: VectorType = VectorType.Random(dim)
    var n0: VectorType = VectorType.Random(dim).normalized()
    var n1: VectorType = VectorType.Random(dim).normalized()
    var pl0: HyperplaneType = HyperplaneType(n0, p0)
    var pl1: HyperplaneType = HyperplaneType(n1, p1)
    var pl2: HyperplaneType = pl1
    var s0: Scalar = internal.random[Scalar]()
    var s1: Scalar = internal.random[Scalar]()
    VERIFY_IS_APPROX( n1.dot(n1), Scalar(1) )
    VERIFY_IS_MUCH_SMALLER_THAN( pl0.absDistance(p0), Scalar(1) )
    if numext.abs2(s0) > RealScalar(1e-6):
        VERIFY_IS_APPROX( pl1.signedDistance(p1 + n1 * s0), s0)
    else:
        VERIFY_IS_MUCH_SMALLER_THAN( abs(pl1.signedDistance(p1 + n1 * s0) - s0), Scalar(1) )
    VERIFY_IS_MUCH_SMALLER_THAN( pl1.signedDistance(pl1.projection(p0)), Scalar(1) )
    VERIFY_IS_MUCH_SMALLER_THAN( pl1.absDistance(p1 +  pl1.normal().unitOrthogonal() * s1), Scalar(1) )
    if not NumTraits[Scalar].IsComplex:
        var rot: MatrixType = MatrixType.Random(dim,dim).householderQr().householderQ()
        var scaling: DiagonalMatrix[Scalar, HyperplaneType.AmbientDimAtCompileTime] = DiagonalMatrix[Scalar, HyperplaneType.AmbientDimAtCompileTime](VectorType.Random())
        var translation: Translation[Scalar, HyperplaneType.AmbientDimAtCompileTime] = Translation[Scalar, HyperplaneType.AmbientDimAtCompileTime](VectorType.Random())
        while scaling.diagonal().cwiseAbs().minCoeff() < RealScalar(1e-4):
            scaling.diagonal() = VectorType.Random()
        pl2 = pl1
        VERIFY_IS_MUCH_SMALLER_THAN( pl2.transform(rot).absDistance(rot * p1), Scalar(1) )
        pl2 = pl1
        VERIFY_IS_MUCH_SMALLER_THAN( pl2.transform(rot, Isometry).absDistance(rot * p1), Scalar(1) )
        pl2 = pl1
        VERIFY_IS_MUCH_SMALLER_THAN( pl2.transform(rot*scaling).absDistance((rot*scaling) * p1), Scalar(1) )
        VERIFY_IS_APPROX( pl2.normal().norm(), RealScalar(1) )
        pl2 = pl1
        VERIFY_IS_MUCH_SMALLER_THAN( pl2.transform(rot*scaling*translation)
                                      .absDistance((rot*scaling*translation) * p1), Scalar(1) )
        VERIFY_IS_APPROX( pl2.normal().norm(), RealScalar(1) )
        pl2 = pl1
        VERIFY_IS_MUCH_SMALLER_THAN( pl2.transform(rot*translation, Isometry)
                                     .absDistance((rot*translation) * p1), Scalar(1) )
        VERIFY_IS_APPROX( pl2.normal().norm(), RealScalar(1) )
    let Dim: Int = HyperplaneType.AmbientDimAtCompileTime
    alias OtherScalar = GetDifferentType[Scalar].type
    var hp1f: Hyperplane[OtherScalar, Dim, Options] = pl1.template cast[OtherScalar]()
    VERIFY_IS_APPROX(hp1f.template cast[Scalar](), pl1)
    var hp1d: Hyperplane[Scalar, Dim, Options] = pl1.template cast[Scalar]()
    VERIFY_IS_APPROX(hp1d.template cast[Scalar](), pl1)

def lines[Scalar: AnyType]():
    using std.abs
    alias HLine = Hyperplane[Scalar, 2]
    alias PLine = ParametrizedLine[Scalar, 2]
    alias Vector = Matrix[Scalar, 2, 1]
    alias CoeffsType = Matrix[Scalar, 3, 1]
    for i in range(0, 10):
        var center: Vector = Vector.Random()
        var u: Vector = Vector.Random()
        var v: Vector = Vector.Random()
        var a: Scalar = internal.random[Scalar]()
        while abs(a-1) < Scalar(1e-4):
            a = internal.random[Scalar]()
        while u.norm() < Scalar(1e-4):
            u = Vector.Random()
        while v.norm() < Scalar(1e-4):
            v = Vector.Random()
        var line_u: HLine = HLine.Through(center + u, center + a*u)
        var line_v: HLine = HLine.Through(center + v, center + a*v)
        VERIFY_IS_APPROX(line_u.normal().norm(), Scalar(1))
        VERIFY_IS_APPROX(line_v.normal().norm(), Scalar(1))
        var result: Vector = line_u.intersection(line_v)
        if abs(a-1) > Scalar(1e-2) and abs(v.normalized().dot(u.normalized())) < Scalar(0.9):
            VERIFY_IS_APPROX(result, center)
        var pl: PLine = PLine(line_u)  # gcc 3.3 will commit suicide if we don't name this variable
        var line_u2: HLine = HLine(pl)
        var converted_coeffs: CoeffsType = line_u2.coeffs()
        if line_u2.normal().dot(line_u.normal()) < Scalar(0):
            converted_coeffs = -line_u2.coeffs()
        VERIFY(line_u.coeffs().isApprox(converted_coeffs))

def planes[Scalar: AnyType]():
    using std.abs
    alias Plane = Hyperplane[Scalar, 3]
    alias Vector = Matrix[Scalar, 3, 1]
    for i in range(0, 10):
        var v0: Vector = Vector.Random()
        var v1: Vector = v0
        var v2: Vector = v0
        if internal.random[float64](0, 1) > 0.25:
            v1 += Vector.Random()
        if internal.random[float64](0, 1) > 0.25:
            v2 += v1 * std.pow(internal.random[Scalar](0, 1), internal.random[Int](1, 16))
        if internal.random[float64](0, 1) > 0.25:
            v2 += Vector.Random() * std.pow(internal.random[Scalar](0, 1), internal.random[Int](1, 16))
        var p0: Plane = Plane.Through(v0, v1, v2)
        VERIFY_IS_APPROX(p0.normal().norm(), Scalar(1))
        VERIFY_IS_MUCH_SMALLER_THAN(p0.absDistance(v0), Scalar(1))
        VERIFY_IS_MUCH_SMALLER_THAN(p0.absDistance(v1), Scalar(1))
        VERIFY_IS_MUCH_SMALLER_THAN(p0.absDistance(v2), Scalar(1))

def hyperplane_alignment[Scalar: AnyType]():
    alias Plane3a = Hyperplane[Scalar, 3, AutoAlign]
    alias Plane3u = Hyperplane[Scalar, 3, DontAlign]
    var array1: Scalar[4] __aligned__(EIGEN_ALIGN_MAX)
    var array2: Scalar[4] __aligned__(EIGEN_ALIGN_MAX)
    var array3: Scalar[5] __aligned__(EIGEN_ALIGN_MAX)
    var array3u: Scalar* = array3.ptr + 1
    var p1: Plane3a* = new (reinterpret[Pointer[NoneType]](array1.ptr)) Plane3a
    var p2: Plane3u* = new (reinterpret[Pointer[NoneType]](array2.ptr)) Plane3u
    var p3: Plane3u* = new (reinterpret[Pointer[NoneType]](array3u)) Plane3u
    p1[].coeffs().setRandom()
    p2[] = p1[]
    p3[] = p1[]
    VERIFY_IS_APPROX(p1[].coeffs(), p2[].coeffs())
    VERIFY_IS_APPROX(p1[].coeffs(), p3[].coeffs())
    #if defined(EIGEN_VECTORIZE) and EIGEN_MAX_STATIC_ALIGN_BYTES > 0
    if internal.packet_traits[Scalar].Vectorizable and internal.packet_traits[Scalar].size <= 4:
        VERIFY_RAISES_ASSERT((new (reinterpret[Pointer[NoneType]](array3u)) Plane3a))
    #endif

def test_geo_hyperplane():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1( hyperplane[Hyperplane[float32, 2]](Hyperplane[float32, 2]()) )
        CALL_SUBTEST_2( hyperplane[Hyperplane[float32, 3]](Hyperplane[float32, 3]()) )
        CALL_SUBTEST_2( hyperplane[Hyperplane[float32, 3, DontAlign]](Hyperplane[float32, 3, DontAlign]()) )
        CALL_SUBTEST_2( hyperplane_alignment[float32]() )
        CALL_SUBTEST_3( hyperplane[Hyperplane[float64, 4]](Hyperplane[float64, 4]()) )
        CALL_SUBTEST_4( hyperplane[Hyperplane[complex[float64], 5]](Hyperplane[complex[float64], 5]()) )
        CALL_SUBTEST_1( lines[float32]() )
        CALL_SUBTEST_3( lines[float64]() )
        CALL_SUBTEST_2( planes[float32]() )
        CALL_SUBTEST_5( planes[float64]() )