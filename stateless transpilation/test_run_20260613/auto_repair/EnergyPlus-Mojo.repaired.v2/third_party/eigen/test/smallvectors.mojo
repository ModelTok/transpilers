// #define EIGEN_NO_STATIC_ASSERT
from main import internal, NumTraits, VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT, CALL_SUBTEST, g_repeat, Matrix, Dynamic

def smallVectors[Scalar: AnyType]():
    alias V2 = Matrix[Scalar, 1, 2]
    alias V3 = Matrix[Scalar, 3, 1]
    alias V4 = Matrix[Scalar, 1, 4]
    alias VX = Matrix[Scalar, Dynamic, 1]
    var x1 = internal.random[Scalar]()
    var x2 = internal.random[Scalar]()
    var x3 = internal.random[Scalar]()
    var x4 = internal.random[Scalar]()
    var v2 = V2(x1, x2)
    var v3 = V3(x1, x2, x3)
    var v4 = V4(x1, x2, x3, x4)
    VERIFY_IS_APPROX(x1, v2.x())
    VERIFY_IS_APPROX(x1, v3.x())
    VERIFY_IS_APPROX(x1, v4.x())
    VERIFY_IS_APPROX(x2, v2.y())
    VERIFY_IS_APPROX(x2, v3.y())
    VERIFY_IS_APPROX(x2, v4.y())
    VERIFY_IS_APPROX(x3, v3.z())
    VERIFY_IS_APPROX(x3, v4.z())
    VERIFY_IS_APPROX(x4, v4.w())
    if not NumTraits[Scalar].IsInteger:
        VERIFY_RAISES_ASSERT(fn() => V3(2, 1))
        VERIFY_RAISES_ASSERT(fn() => V3(3, 2))
        VERIFY_RAISES_ASSERT(fn() => V3(Scalar(3), 1))
        VERIFY_RAISES_ASSERT(fn() => V3(3, Scalar(1)))
        VERIFY_RAISES_ASSERT(fn() => V3(Scalar(3), Scalar(1)))
        VERIFY_RAISES_ASSERT(fn() => V3(Scalar(123), Scalar(123)))
        VERIFY_RAISES_ASSERT(fn() => V4(1, 3))
        VERIFY_RAISES_ASSERT(fn() => V4(2, 4))
        VERIFY_RAISES_ASSERT(fn() => V4(1, Scalar(4)))
        VERIFY_RAISES_ASSERT(fn() => V4(Scalar(1), 4))
        VERIFY_RAISES_ASSERT(fn() => V4(Scalar(1), Scalar(4)))
        VERIFY_RAISES_ASSERT(fn() => V4(Scalar(123), Scalar(123)))
        VERIFY_RAISES_ASSERT(fn() => VX(3, 2))
        VERIFY_RAISES_ASSERT(fn() => VX(Scalar(3), 1))
        VERIFY_RAISES_ASSERT(fn() => VX(3, Scalar(1)))
        VERIFY_RAISES_ASSERT(fn() => VX(Scalar(3), Scalar(1)))
        VERIFY_RAISES_ASSERT(fn() => VX(Scalar(123), Scalar(123)))

def test_smallvectors():
    for i in range(0, g_repeat):
        CALL_SUBTEST(fn() => smallVectors[Int]())
        CALL_SUBTEST(fn() => smallVectors[Float32]())
        CALL_SUBTEST(fn() => smallVectors[Float64]())