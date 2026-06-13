from math import pow
from memory import sizeof
from sys import int_types
from complex import Complex
from string import String
from testing import *
from ObjexxFCL.numeric import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.unit import *

alias schar = Int8
alias uchar = UInt8
alias sshort = Int16
alias ushort = UInt16
alias sint = Int32
alias uint = UInt32
alias slong = Int64
alias ulong = UInt64
alias longlong = Int64
alias slonglong = Int64
alias ulonglong = UInt64
alias longdouble = Float64

def ARRAY_LENGTH(a: StaticIntTuple) -> Int:
    return a.size

var bool_max: Bool = True
var char_max: Int8 = 127
var schar_max: Int8 = 127
var uchar_max: UInt8 = 255
var short_max: Int16 = 32767
var sshort_max: Int16 = 32767
var ushort_max: UInt16 = 65535
var int_max: Int32 = 2147483647
var sint_max: Int32 = 2147483647
var uint_max: UInt32 = 4294967295
var long_max: Int64 = 9223372036854775807
var slong_max: Int64 = 9223372036854775807
var ulong_max: UInt64 = 18446744073709551615
var longlong_max: Int64 = 9223372036854775807
var slonglong_max: Int64 = 9223372036854775807
var ulonglong_max: UInt64 = 18446744073709551615
var float_min: Float32 = 1.1754943508222875e-38
var float_max: Float32 = 3.4028234663852886e+38
var double_min: Float64 = 2.2250738585072014e-308
var double_max: Float64 = 1.7976931348623157e+308
var longdouble_min: Float64 = 2.2250738585072014e-308
var longdouble_max: Float64 = 1.7976931348623157e+308

@register_passable("trivial")
struct TestNumericKIND:

def test_NumericTest_KIND():
    expect_equal(4, KIND(Bool()))
    expect_equal(1, KIND(Int8()))
    expect_equal(2, KIND(Int16()))
    expect_equal(4, KIND(Int32()))
    expect_equal(8, KIND(Int64()))
    expect_equal(1, KIND(UInt8()))
    expect_equal(2, KIND(UInt16()))
    expect_equal(4, KIND(UInt32()))
    expect_equal(8, KIND(UInt64()))
    expect_equal(4, KIND(Float32()))
    expect_equal(8, KIND(Float64()))
    var long_double: Float64 = 0.0
    expect_equal(16, KIND(long_double))
    expect_equal(4, KIND(Complex[Float32]()))
    expect_equal(8, KIND(Complex[Float64]()))
    expect_equal(16, KIND(Complex[Float64]()))
    expect_equal(1, KIND(Int8()))
    expect_equal(1, KIND(String()))

@register_passable("trivial")
struct TestNumericSELECTED_INT_KIND:

def test_NumericTest_SELECTED_INT_KIND():
    var tests = StaticTuple[Int, Int](23, (
        (0, 1),
        (1, 1),
        (2, 1),
        (3, 2),
        (4, 2),
        (5, 4),
        (6, 4),
        (7, 4),
        (8, 4),
        (9, 4),
        (10, 8),
        (11, 8),
        (12, 8),
        (13, 8),
        (14, 8),
        (15, 8),
        (16, 8),
        (17, 8),
        (18, 8),
        (19, -1),
        (20, -1),
        (1000, -1),
        (-1, 1),
        (-1000, 1)
    ))
    var N: Int = tests.size
    for i in range(N):
        expect_equal(tests[i][1], SELECTED_INT_KIND(tests[i][0]))

@register_passable("trivial")
struct TestNumericSIZEOF:

def test_NumericTest_SIZEOF():
    expect_equal(1, SIZEOF(Int8()))
    expect_equal(2, SIZEOF(Int16()))
    expect_equal(4, SIZEOF(Int32()))
    expect_equal(8, SIZEOF(Int64()))
    expect_equal(1, SIZEOF(UInt8()))
    expect_equal(2, SIZEOF(UInt16()))
    expect_equal(4, SIZEOF(UInt32()))
    expect_equal(8, SIZEOF(UInt64()))
    expect_equal(3, SIZEOF("Cat"))
    expect_equal(3, SIZEOF(String("Cat")))
    var a = UInt8(2)
    expect_equal(2, SIZEOF(a))
    var b = Array1D[Float32](4)
    expect_equal(16, SIZEOF(b))

@register_passable("trivial")
struct TestNumericRADIX:

def test_NumericTest_RADIX():
    expect_equal(2, RADIX(Bool()))
    expect_equal(2, RADIX(Int8()))
    expect_equal(2, RADIX(schar()))
    expect_equal(2, RADIX(uchar()))
    expect_equal(2, RADIX(Int32()))
    expect_equal(2, RADIX(Int32()))
    expect_equal(2, RADIX(Int32()))
    expect_equal(2, RADIX(Int16()))
    expect_equal(2, RADIX(sshort()))
    expect_equal(2, RADIX(ushort()))
    expect_equal(2, RADIX(Int32()))
    expect_equal(2, RADIX(sint()))
    expect_equal(2, RADIX(uint()))
    expect_equal(2, RADIX(Int64()))
    expect_equal(2, RADIX(slong()))
    expect_equal(2, RADIX(ulong()))
    expect_equal(2, RADIX(longlong()))
    expect_equal(2, RADIX(slonglong()))
    expect_equal(2, RADIX(ulonglong()))
    expect_equal(2, RADIX(Float32()))
    expect_equal(2, RADIX(Float64()))
    expect_equal(2, RADIX(longdouble()))

@register_passable("trivial")
struct TestNumericDIGITS:

def test_NumericTest_DIGITS():
    expect_equal(1, DIGITS(Bool()))
    expect_equal(7, DIGITS(Int8()))
    expect_equal(7, DIGITS(schar()))
    expect_equal(8, DIGITS(uchar()))
    expect_equal(31, DIGITS(Int32()))
    expect_equal(31, DIGITS(Int32()))
    expect_equal(31, DIGITS(Int32()))
    expect_equal(15, DIGITS(Int16()))
    expect_equal(15, DIGITS(sshort()))
    expect_equal(16, DIGITS(ushort()))
    expect_equal(31, DIGITS(Int32()))
    expect_equal(31, DIGITS(sint()))
    expect_equal(32, DIGITS(uint()))
    expect_equal(63, DIGITS(Int64()))
    expect_equal(63, DIGITS(slong()))
    expect_equal(64, DIGITS(ulong()))
    expect_equal(63, DIGITS(longlong()))
    expect_equal(63, DIGITS(slonglong()))
    expect_equal(64, DIGITS(ulonglong()))
    expect_equal(24, DIGITS(Float32()))
    expect_equal(53, DIGITS(Float64()))
    expect_equal(64, DIGITS(longdouble()))

@register_passable("trivial")
struct TestNumericHuge:

def test_NumericTest_Huge():
    expect_equal(bool_max, HUGE_(Bool()))
    expect_equal(char_max, HUGE_(Int8()))
    expect_equal(schar_max, HUGE_(schar()))
    expect_equal(uchar_max, HUGE_(uchar()))
    expect_equal(2147483647, HUGE_(Int32()))
    expect_equal(2147483647, HUGE_(Int32()))
    expect_equal(2147483647, HUGE_(Int32()))
    expect_equal(short_max, HUGE_(Int16()))
    expect_equal(sshort_max, HUGE_(sshort()))
    expect_equal(ushort_max, HUGE_(ushort()))
    expect_equal(int_max, HUGE_(Int32()))
    expect_equal(sint_max, HUGE_(sint()))
    expect_equal(uint_max, HUGE_(uint()))
    expect_equal(long_max, HUGE_(Int64()))
    expect_equal(slong_max, HUGE_(slong()))
    expect_equal(ulong_max, HUGE_(ulong()))
    expect_equal(longlong_max, HUGE_(longlong()))
    expect_equal(slonglong_max, HUGE_(slonglong()))
    expect_equal(ulonglong_max, HUGE_(ulonglong()))
    expect_equal(float_max, HUGE_(Float32()))
    expect_equal(double_max, HUGE_(Float64()))
    expect_equal(longdouble_max, HUGE_(longdouble()))

@register_passable("trivial")
struct TestNumericTINY:

def test_NumericTest_TINY():
    expect_equal(float_min, TINY(Float32()))
    expect_equal(double_min, TINY(Float64()))
    expect_equal(longdouble_min, TINY(longdouble()))

@register_passable("trivial")
struct TestNumericEPSILON:

def test_NumericTest_EPSILON():
    expect_equal(1.1920928955078125e-07, EPSILON(Float32()))
    expect_equal(2.220446049250313e-16, EPSILON(Float64()))
    expect_equal(2.220446049250313e-16, EPSILON(longdouble()))

@register_passable("trivial")
struct TestNumericPRECISION:

def test_NumericTest_PRECISION():
    expect_equal(6, PRECISION(Float32()))
    expect_equal(15, PRECISION(Float64()))
    expect_equal(18, PRECISION(longdouble()))
    expect_equal(6, PRECISION(Complex[Float32]()))
    expect_equal(15, PRECISION(Complex[Float64]()))
    expect_equal(18, PRECISION(Complex[Float64]()))

@register_passable("trivial")
struct TestNumericEXPONENT_RANGE:

def test_NumericTest_EXPONENT_RANGE():
    expect_equal(2, EXPONENT_RANGE(Int8()))
    expect_equal(4, EXPONENT_RANGE(Int16()))
    expect_equal(9, EXPONENT_RANGE(Int32()))
    expect_equal(18, EXPONENT_RANGE(Int64()))
    expect_equal(2, EXPONENT_RANGE(UInt8()))
    expect_equal(4, EXPONENT_RANGE(UInt16()))
    expect_equal(9, EXPONENT_RANGE(UInt32()))
    expect_equal(18, EXPONENT_RANGE(UInt64()))
    expect_equal(37, EXPONENT_RANGE(Float32()))
    expect_equal(307, EXPONENT_RANGE(Float64()))
    expect_equal(4931, EXPONENT_RANGE(longdouble()))
    expect_equal(37, EXPONENT_RANGE(Complex[Float32]()))
    expect_equal(307, EXPONENT_RANGE(Complex[Float64]()))
    expect_equal(4931, EXPONENT_RANGE(Complex[Float64]()))

@register_passable("trivial")
struct TestNumericMINEXPONENT:

def test_NumericTest_MINEXPONENT():
    expect_equal(-125, MINEXPONENT(Float32()))
    expect_equal(-1021, MINEXPONENT(Float64()))
    expect_equal(-16381, MINEXPONENT(longdouble()))

@register_passable("trivial")
struct TestNumericEXPONENT:

def test_NumericTest_EXPONENT():
    expect_equal(0, EXPONENT(Float32()))
    expect_equal(-125, EXPONENT(float_min))
    expect_equal(129, EXPONENT(float_max))
    expect_equal(0, EXPONENT(Float64()))
    expect_equal(-1021, EXPONENT(double_min))
    expect_equal(1025, EXPONENT(double_max))
    expect_equal(0, EXPONENT(longdouble()))
    expect_equal(-16381, EXPONENT(longdouble_min))
    expect_equal(16385, EXPONENT(longdouble_max))
    expect_equal(0, EXPONENT(Float32()))
    expect_equal(0, EXPONENT(Float64()))
    expect_equal(0, EXPONENT(longdouble()))

@register_passable("trivial")
struct TestNumericSCALE:

def test_NumericTest_SCALE():
    expect_equal(128.0, SCALE(4.0, 5))
    expect_equal(24.0, SCALE(3.0, 3))

@register_passable("trivial")
struct TestNumericFRACTION:

def test_NumericTest_FRACTION():
    expect_equal(0, FRACTION(Float32()))
    expect_almost_equal(0.5, FRACTION(float_min))
    expect_almost_equal(0.5, FRACTION(float_max))
    expect_equal(0, FRACTION(Float64()))
    expect_almost_equal(0.5, FRACTION(double_min))
    expect_almost_equal(0.5, FRACTION(double_max))
    expect_equal(0, FRACTION(longdouble()))
    expect_almost_equal(0.5, FRACTION(longdouble_min))
    expect_almost_equal(0.5, FRACTION(longdouble_max))
    expect_equal(0, FRACTION(Float32()))
    expect_equal(0, FRACTION(Float64()))
    expect_equal(0, FRACTION(longdouble()))

@register_passable("trivial")
struct TestNumericSPACING:

def test_NumericTest_SPACING():
    expect_equal(SPACING(0.0), TINY(1.0))
    expect_equal(SPACING(1.0), EPSILON(1.0))

@register_passable("trivial")
struct TestNumericNEAREST:

def test_NumericTest_NEAREST():
    expect_almost_equal(3.0 + pow(2.0, -22), NEAREST(3.0, 2.0))
    expect_almost_equal(3.0 + pow(2.0, -22), NEAREST(3.0, 2.0))
    expect_almost_equal(3.0 - pow(2.0, -22), NEAREST(3.0, -2.0))
    expect_almost_equal(3.0 - pow(2.0, -22), NEAREST(3.0, -2.0))
    var eps: Float64 = pow(2.0, -52)
    expect_almost_equal(1.0 + eps, NEAREST(1.0, 1.0))
    expect_almost_equal(1.0 - eps, NEAREST(1.0, -1.0))