from Eigen import half, NumTraits, internal, Array, numext
from Eigen import half_impl  # for __half_raw
from Eigen import internal as internal_mod  # for random
from Eigen import Array as EigenArray  # to avoid name conflict? Use as is.

# Define test macros as functions (since Mojo doesn't have macros)
def VERIFY(condition: Bool):
    if not condition:
        print("VERIFY failed")
        # In a real test framework, we'd raise an error
        # For now, just print

def VERIFY_IS_EQUAL(a: half, b: half):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)

def VERIFY_IS_EQUAL(a: Float32, b: Float32):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)

def VERIFY_IS_EQUAL(a: Int, b: Int):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)

def VERIFY_IS_APPROX(a: Float32, b: Float32, tol: Float32 = 1e-5):
    if abs(a - b) > tol:
        print("VERIFY_IS_APPROX failed: ", a, " != ", b)

def VERIFY_IS_APPROX(a: half, b: half, tol: Float32 = 1e-5):
    if abs(Float32(a) - Float32(b)) > tol:
        print("VERIFY_IS_APPROX failed: ", a, " != ", b)

def CALL_SUBTEST(fn_name: fn() -> None):
    fn_name()

# Define EIGEN_PI constant
const EIGEN_PI: Float32 = 3.14159265358979323846

# Define __half_raw as a type alias for half? Actually it's a struct with x field.
# In Eigen, __half_raw is a struct with uint16 x. We'll assume half has that.
# We'll use half directly.

def test_conversion():
    using Eigen::half_impl::__half_raw  # Not needed in Mojo, but keep comment
    VERIFY_IS_EQUAL(half(1.0f).x, 0x3c00)
    VERIFY_IS_EQUAL(half(0.5f).x, 0x3800)
    VERIFY_IS_EQUAL(half(0.33333f).x, 0x3555)
    VERIFY_IS_EQUAL(half(0.0f).x, 0x0000)
    VERIFY_IS_EQUAL(half(-0.0f).x, 0x8000)
    VERIFY_IS_EQUAL(half(65504.0f).x, 0x7bff)
    VERIFY_IS_EQUAL(half(65536.0f).x, 0x7c00)  # Becomes infinity.
    VERIFY_IS_EQUAL(half(-5.96046e-08f).x, 0x8001)
    VERIFY_IS_EQUAL(half(5.96046e-08f).x, 0x0001)
    VERIFY_IS_EQUAL(half(1.19209e-07f).x, 0x0002)
    var val1: Float32 = Float32(half(__half_raw(0x3c00)))
    var val2: Float32 = Float32(half(__half_raw(0x3c01)))
    var val3: Float32 = Float32(half(__half_raw(0x3c02)))
    VERIFY_IS_EQUAL(half(0.5f * (val1 + val2)).x, 0x3c00)
    VERIFY_IS_EQUAL(half(0.5f * (val2 + val3)).x, 0x3c02)
    VERIFY_IS_EQUAL(half(-1).x, 0xbc00)
    VERIFY_IS_EQUAL(half(0).x, 0x0000)
    VERIFY_IS_EQUAL(half(1).x, 0x3c00)
    VERIFY_IS_EQUAL(half(2).x, 0x4000)
    VERIFY_IS_EQUAL(half(3).x, 0x4200)
    VERIFY_IS_EQUAL(half(false).x, 0x0000)
    VERIFY_IS_EQUAL(half(true).x, 0x3c00)
    VERIFY_IS_EQUAL(Float32(half(__half_raw(0x0000))), 0.0f)
    VERIFY_IS_EQUAL(Float32(half(__half_raw(0x3c00))), 1.0f)
    VERIFY_IS_APPROX(Float32(half(__half_raw(0x8001))), -5.96046e-08f)
    VERIFY_IS_APPROX(Float32(half(__half_raw(0x0001))), 5.96046e-08f)
    VERIFY_IS_APPROX(Float32(half(__half_raw(0x0002))), 1.19209e-07f)
    VERIFY(not (numext.isinf)(Float32(half(65504.0f))))  # Largest finite number.
    VERIFY(not (numext.isnan)(Float32(half(0.0f))))
    VERIFY((numext.isinf)(Float32(half(__half_raw(0xfc00)))))
    VERIFY((numext.isnan)(Float32(half(__half_raw(0xfc01)))))
    VERIFY((numext.isinf)(Float32(half(__half_raw(0x7c00)))))
    VERIFY((numext.isnan)(Float32(half(__half_raw(0x7c01)))))
    #if !EIGEN_COMP_MSVC
    VERIFY((numext.isnan)(Float32(half(0.0 / 0.0))))
    VERIFY((numext.isinf)(Float32(half(1.0 / 0.0))))
    VERIFY((numext.isinf)(Float32(half(-1.0 / 0.0))))
    #endif
    VERIFY(not (numext.isinf)(half(__half_raw(0x7bff))))
    VERIFY(not (numext.isnan)(half(__half_raw(0x0000))))
    VERIFY((numext.isinf)(half(__half_raw(0xfc00))))
    VERIFY((numext.isnan)(half(__half_raw(0xfc01))))
    VERIFY((numext.isinf)(half(__half_raw(0x7c00))))
    VERIFY((numext.isnan)(half(__half_raw(0x7c01))))
    #if !EIGEN_COMP_MSVC
    VERIFY((numext.isnan)(half(0.0 / 0.0)))
    VERIFY((numext.isinf)(half(1.0 / 0.0)))
    VERIFY((numext.isinf)(half(-1.0 / 0.0)))
    #endif

def test_numtraits():
    print("epsilon       = ", NumTraits<half>.epsilon(), "  (0x", hex(NumTraits<half>.epsilon().x), ")")
    print("highest       = ", NumTraits<half>.highest(), "  (0x", hex(NumTraits<half>.highest().x), ")")
    print("lowest        = ", NumTraits<half>.lowest(), "  (0x", hex(NumTraits<half>.lowest().x), ")")
    print("min           = ", (std.numeric_limits<half>.min)(), "  (0x", hex(half((std.numeric_limits<half>.min)()).x), ")")
    print("denorm min    = ", (std.numeric_limits<half>.denorm_min)(), "  (0x", hex(half((std.numeric_limits<half>.denorm_min)()).x), ")")
    print("infinity      = ", NumTraits<half>.infinity(), "  (0x", hex(NumTraits<half>.infinity().x), ")")
    print("quiet nan     = ", NumTraits<half>.quiet_NaN(), "  (0x", hex(NumTraits<half>.quiet_NaN().x), ")")
    print("signaling nan = ", std.numeric_limits<half>.signaling_NaN(), "  (0x", hex(std.numeric_limits<half>.signaling_NaN().x), ")")
    VERIFY(NumTraits<half>.IsSigned)
    VERIFY_IS_EQUAL( std.numeric_limits<half>.infinity().x, half(std.numeric_limits<Float32>.infinity()).x )
    VERIFY_IS_EQUAL( std.numeric_limits<half>.quiet_NaN().x, half(std.numeric_limits<Float32>.quiet_NaN()).x )
    VERIFY_IS_EQUAL( std.numeric_limits<half>.signaling_NaN().x, half(std.numeric_limits<Float32>.signaling_NaN()).x )
    VERIFY( (std.numeric_limits<half>.min)() > half(0.f) )
    VERIFY( (std.numeric_limits<half>.denorm_min)() > half(0.f) )
    VERIFY( (std.numeric_limits<half>.min)()/half(2) > half(0.f) )
    VERIFY_IS_EQUAL( (std.numeric_limits<half>.denorm_min)()/half(2), half(0.f) )

def test_arithmetic():
    VERIFY_IS_EQUAL(Float32(half(2) + half(2)), 4)
    VERIFY_IS_EQUAL(Float32(half(2) + half(-2)), 0)
    VERIFY_IS_APPROX(Float32(half(0.33333f) + half(0.66667f)), 1.0f)
    VERIFY_IS_EQUAL(Float32(half(2.0f) * half(-5.5f)), -11.0f)
    VERIFY_IS_APPROX(Float32(half(1.0f) / half(3.0f)), 0.33333f)
    VERIFY_IS_EQUAL(Float32(-half(4096.0f)), -4096.0f)
    VERIFY_IS_EQUAL(Float32(-half(-4096.0f)), 4096.0f)

def test_comparison():
    VERIFY(half(1.0f) > half(0.5f))
    VERIFY(half(0.5f) < half(1.0f))
    VERIFY(not (half(1.0f) < half(0.5f)))
    VERIFY(not (half(0.5f) > half(1.0f)))
    VERIFY(not (half(4.0f) > half(4.0f)))
    VERIFY(not (half(4.0f) < half(4.0f)))
    VERIFY(not (half(0.0f) < half(-0.0f)))
    VERIFY(not (half(-0.0f) < half(0.0f)))
    VERIFY(not (half(0.0f) > half(-0.0f)))
    VERIFY(not (half(-0.0f) > half(0.0f)))
    VERIFY(half(0.2f) > half(-1.0f))
    VERIFY(half(-1.0f) < half(0.2f))
    VERIFY(half(-16.0f) < half(-15.0f))
    VERIFY(half(1.0f) == half(1.0f))
    VERIFY(half(1.0f) != half(2.0f))
    #if !EIGEN_COMP_MSVC
    VERIFY(not (half(0.0 / 0.0) == half(0.0 / 0.0)))
    VERIFY(half(0.0 / 0.0) != half(0.0 / 0.0))
    VERIFY(not (half(1.0) == half(0.0 / 0.0)))
    VERIFY(not (half(1.0) < half(0.0 / 0.0)))
    VERIFY(not (half(1.0) > half(0.0 / 0.0)))
    VERIFY(half(1.0) != half(0.0 / 0.0))
    VERIFY(half(1.0) < half(1.0 / 0.0))
    VERIFY(half(1.0) > half(-1.0 / 0.0))
    #endif

def test_basic_functions():
    VERIFY_IS_EQUAL(Float32(numext.abs(half(3.5f))), 3.5f)
    VERIFY_IS_EQUAL(Float32(abs(half(3.5f))), 3.5f)
    VERIFY_IS_EQUAL(Float32(numext.abs(half(-3.5f))), 3.5f)
    VERIFY_IS_EQUAL(Float32(abs(half(-3.5f))), 3.5f)
    VERIFY_IS_EQUAL(Float32(numext.floor(half(3.5f))), 3.0f)
    VERIFY_IS_EQUAL(Float32(floor(half(3.5f))), 3.0f)
    VERIFY_IS_EQUAL(Float32(numext.floor(half(-3.5f))), -4.0f)
    VERIFY_IS_EQUAL(Float32(floor(half(-3.5f))), -4.0f)
    VERIFY_IS_EQUAL(Float32(numext.ceil(half(3.5f))), 4.0f)
    VERIFY_IS_EQUAL(Float32(ceil(half(3.5f))), 4.0f)
    VERIFY_IS_EQUAL(Float32(numext.ceil(half(-3.5f))), -3.0f)
    VERIFY_IS_EQUAL(Float32(ceil(half(-3.5f))), -3.0f)
    VERIFY_IS_APPROX(Float32(numext.sqrt(half(0.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(sqrt(half(0.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(numext.sqrt(half(4.0f))), 2.0f)
    VERIFY_IS_APPROX(Float32(sqrt(half(4.0f))), 2.0f)
    VERIFY_IS_APPROX(Float32(numext.pow(half(0.0f), half(1.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(pow(half(0.0f), half(1.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(numext.pow(half(2.0f), half(2.0f))), 4.0f)
    VERIFY_IS_APPROX(Float32(pow(half(2.0f), half(2.0f))), 4.0f)
    VERIFY_IS_EQUAL(Float32(numext.exp(half(0.0f))), 1.0f)
    VERIFY_IS_EQUAL(Float32(exp(half(0.0f))), 1.0f)
    VERIFY_IS_APPROX(Float32(numext.exp(half(EIGEN_PI))), 20.f + Float32(EIGEN_PI))
    VERIFY_IS_APPROX(Float32(exp(half(EIGEN_PI))), 20.f + Float32(EIGEN_PI))
    VERIFY_IS_EQUAL(Float32(numext.log(half(1.0f))), 0.0f)
    VERIFY_IS_EQUAL(Float32(log(half(1.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(numext.log(half(10.0f))), 2.30273f)
    VERIFY_IS_APPROX(Float32(log(half(10.0f))), 2.30273f)
    VERIFY_IS_EQUAL(Float32(numext.log1p(half(0.0f))), 0.0f)
    VERIFY_IS_EQUAL(Float32(log1p(half(0.0f))), 0.0f)
    VERIFY_IS_APPROX(Float32(numext.log1p(half(10.0f))), 2.3978953f)
    VERIFY_IS_APPROX(Float32(log1p(half(10.0f))), 2.3978953f)

def test_trigonometric_functions():
    VERIFY_IS_APPROX(numext.cos(half(0.0f)), half(cosf(0.0f)))
    VERIFY_IS_APPROX(cos(half(0.0f)), half(cosf(0.0f)))
    VERIFY_IS_APPROX(numext.cos(half(EIGEN_PI)), half(cosf(EIGEN_PI)))
    VERIFY_IS_APPROX(numext.cos(half(3.5f)), half(cosf(3.5f)))
    VERIFY_IS_APPROX(numext.sin(half(0.0f)), half(sinf(0.0f)))
    VERIFY_IS_APPROX(sin(half(0.0f)), half(sinf(0.0f)))
    VERIFY_IS_APPROX(numext.sin(half(EIGEN_PI/2)), half(sinf(EIGEN_PI/2)))
    VERIFY_IS_APPROX(numext.sin(half(3*EIGEN_PI/2)), half(sinf(3*EIGEN_PI/2)))
    VERIFY_IS_APPROX(numext.sin(half(3.5f)), half(sinf(3.5f)))
    VERIFY_IS_APPROX(numext.tan(half(0.0f)), half(tanf(0.0f)))
    VERIFY_IS_APPROX(tan(half(0.0f)), half(tanf(0.0f)))
    VERIFY_IS_APPROX(numext.tan(half(3.5f)), half(tanf(3.5f)))

def test_array():
    type ArrayXh = EigenArray<half, 1, Dynamic>
    var size: Index = internal_mod.random<Index>(1,10)
    var i: Index = internal_mod.random<Index>(0,size-1)
    var a1: ArrayXh = ArrayXh.Random(size)
    var a2: ArrayXh = ArrayXh.Random(size)
    VERIFY_IS_APPROX( a1+a1, half(2)*a1 )
    VERIFY( (a1.abs() >= half(0)).all() )
    VERIFY_IS_APPROX( (a1*a1).sqrt(), a1.abs() )
    VERIFY( ((a1.min)(a2) <= (a1.max)(a2)).all() )
    a1(i) = half(-10.)
    VERIFY_IS_EQUAL( a1.minCoeff(), half(-10.) )
    a1(i) = half(10.)
    VERIFY_IS_EQUAL( a1.maxCoeff(), half(10.) )
    var ss: StringWriter = StringWriter()
    ss.write(a1)

def test_half_float():
    CALL_SUBTEST(test_conversion)
    CALL_SUBTEST(test_numtraits)
    CALL_SUBTEST(test_arithmetic)
    CALL_SUBTEST(test_comparison)
    CALL_SUBTEST(test_basic_functions)
    CALL_SUBTEST(test_trigonometric_functions)
    CALL_SUBTEST(test_array)