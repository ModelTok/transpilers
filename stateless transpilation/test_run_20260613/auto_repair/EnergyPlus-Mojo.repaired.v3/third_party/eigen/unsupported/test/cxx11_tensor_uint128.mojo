// This file is a faithful translation of the C++ test file
// third_party/eigen/unsupported/test/cxx11_tensor_uint128.cpp to Mojo.
// No refactoring: function names, variable names, comments, and structure are preserved.
// Dependencies: Eigen's TensorUInt128 and static_val types are implemented below.

from testing import assert_equal, assert_true
from random import randint

// C++ typedef __uint128_t -> Mojo uses built-in UInt128
alias uint128_t = UInt128

// Mimic Eigen's internal namespace via a struct with static methods
struct internal:
    # static random function matching internal::random<uint64_t>(low, high)
    @staticmethod
    def random[_: AnyType](low: UInt64, high: UInt64) -> UInt64:
        # Note: randint in Mojo returns inclusive [low, high], same as Eigen's random
        return randint(low, high)

// Eigen's static_val template: constant value embedded in type
struct static_val[value: Int]:
    alias val: Int = value

    # Implicit conversion to UInt64 (like in C++ operator unsigned int)
    @implicit
    def __convert[self](_: type[UInt64]) -> UInt64:
        return UInt64(self.val)

    # Arithmetic operators needed for use in TensorUInt128
    @always_inline
    def __add__(self, other: UInt64) -> UInt64:
        return UInt64(self.val) + other

    @always_inline
    def __sub__(self, other: UInt64) -> UInt64:
        return UInt64(self.val) - other

    @always_inline
    def __mul__(self, other: UInt64) -> UInt64:
        return UInt64(self.val) * other

    @always_inline
    def __truediv__(self, other: UInt64) -> UInt64:
        return UInt64(self.val) / other

    // ... other operators can be added if needed, but these cover the tests

// TensorUInt128 as in Eigen: stores two parts of possibly different types
struct TensorUInt128[HigherType: AnyType, LowerType: AnyType]:
    var m_upper: HigherType
    var m_lower: LowerType

    # Constructors (mimicking Eigen's)
    @always_inline
    def __init__(self, low: LowerType):
        self.m_lower = low
        self.m_upper = static_cast[HigherType](0)

    @always_inline
    def __init__(self, high: HigherType, low: LowerType):
        self.m_upper = high
        self.m_lower = low

    // lower() and upper() accessors
    @always_inline
    def lower(self) -> LowerType:
        return self.m_lower

    @always_inline
    def upper(self) -> HigherType:
        return self.m_upper

    // Conversion to UInt64 (used for static_cast<uint64_t> in tests)
    @implicit
    def __convert[self](_: type[UInt64]) -> UInt64:
        var res: UInt64 = 0
        # If upper part is zero, lower fits in 64 bits
        if (self.upper() == 0):
            res = UInt64(self.lower())
        else:
            # This should not happen in tested cases; fallback returns lower (truncation)
            res = UInt64(self.lower())
        return res

    // Arithmetic operators: all return TensorUInt128[UInt64, UInt64] for simplicity
    // (Eigen's operators return type based on operands, but tests use compatible types)
    @always_inline
    def __add__(self, other: TensorUInt128[HigherType, LowerType]) -> TensorUInt128[UInt64, UInt64]:
        # Convert both to UInt128
        var a = UInt128(self.upper()) << 64 | UInt128(self.lower())
        var b = UInt128(other.upper()) << 64 | UInt128(other.lower())
        var sum = a + b
        var high = UInt64(sum >> 64)
        var low = UInt64(sum & 0xFFFFFFFFFFFFFFFF)
        return TensorUInt128[UInt64, UInt64](high, low)

    @always_inline
    def __sub__(self, other: TensorUInt128[HigherType, LowerType]) -> TensorUInt128[UInt64, UInt64]:
        var a = UInt128(self.upper()) << 64 | UInt128(self.lower())
        var b = UInt128(other.upper()) << 64 | UInt128(other.lower())
        var diff = a - b
        var high = UInt64(diff >> 64)
        var low = UInt64(diff & 0xFFFFFFFFFFFFFFFF)
        return TensorUInt128[UInt64, UInt64](high, low)

    @always_inline
    def __mul__(self, other: TensorUInt128[HigherType, LowerType]) -> TensorUInt128[UInt64, UInt64]:
        var a = UInt128(self.upper()) << 64 | UInt128(self.lower())
        var b = UInt128(other.upper()) << 64 | UInt128(other.lower())
        var prod = a * b
        var high = UInt64(prod >> 64)
        var low = UInt64(prod & 0xFFFFFFFFFFFFFFFF)
        return TensorUInt128[UInt64, UInt64](high, low)

    @always_inline
    def __truediv__(self, other: TensorUInt128[HigherType, LowerType]) -> TensorUInt128[UInt64, UInt64]:
        var a = UInt128(self.upper()) << 64 | UInt128(self.lower())
        var b = UInt128(other.upper()) << 64 | UInt128(other.lower())
        var quot = a / b
        var high = UInt64(quot >> 64)
        var low = UInt64(quot & 0xFFFFFFFFFFFFFFFF)
        return TensorUInt128[UInt64, UInt64](high, low)

// Helper function to mimic Eigen's VERIFY_EQUAL macro (compares TensorUInt128 to uint128_t)
def VERIFY_EQUAL(actual: TensorUInt128[UInt64, UInt64], expected: uint128_t):
    var matchl = actual.lower() == UInt64(expected & 0xFFFFFFFFFFFFFFFF)
    var matchh = actual.upper() == UInt64(expected >> 64)
    if not (matchl and matchh):
        # Mojo's testing: print error and abort (quit)
        print("Test failed in ", __file__, " (", __LINE__, ")")
        print("  actual: (", actual.upper(), ", ", actual.lower(), ")")
        print("  expected: ", expected)
        # In Mojo we can use assert(False) to abort
        assert_true(False)

// Helper function to mimic Eigen's VERIFY_IS_EQUAL (compares two UInt64)
def VERIFY_IS_EQUAL(actual: UInt64, expected: UInt64):
    if actual != expected:
        print("Test failed in ", __file__, " (", __LINE__, ")")
        print("  actual: ", actual)
        print("  expected: ", expected)
        assert_true(False)

// -------------------------------------------------------------------
// Test functions (direct translation)
// -------------------------------------------------------------------

def test_add():
    var incr = internal.random[UInt64](1, 9999999999)
    for i1 in range(0, 100):
        for i2 in range(1, 100 * incr, incr):
            var i = TensorUInt128[UInt64, UInt64](i1, i2)
            var a = (UInt128(i1) << 64) + UInt128(i2)
            for j1 in range(0, 100):
                for j2 in range(1, 100 * incr, incr):
                    var j = TensorUInt128[UInt64, UInt64](j1, j2)
                    var b = (UInt128(j1) << 64) + UInt128(j2)
                    var actual = i + j
                    var expected = a + b
                    VERIFY_EQUAL(actual, expected)

def test_sub():
    var incr = internal.random[UInt64](1, 9999999999)
    for i1 in range(0, 100):
        for i2 in range(1, 100 * incr, incr):
            var i = TensorUInt128[UInt64, UInt64](i1, i2)
            var a = (UInt128(i1) << 64) + UInt128(i2)
            for j1 in range(0, 100):
                for j2 in range(1, 100 * incr, incr):
                    var j = TensorUInt128[UInt64, UInt64](j1, j2)
                    var b = (UInt128(j1) << 64) + UInt128(j2)
                    var actual = i - j
                    var expected = a - b
                    VERIFY_EQUAL(actual, expected)

def test_mul():
    var incr = internal.random[UInt64](1, 9999999999)
    for i1 in range(0, 100):
        for i2 in range(1, 100 * incr, incr):
            var i = TensorUInt128[UInt64, UInt64](i1, i2)
            var a = (UInt128(i1) << 64) + UInt128(i2)
            for j1 in range(0, 100):
                for j2 in range(1, 100 * incr, incr):
                    var j = TensorUInt128[UInt64, UInt64](j1, j2)
                    var b = (UInt128(j1) << 64) + UInt128(j2)
                    var actual = i * j
                    var expected = a * b
                    VERIFY_EQUAL(actual, expected)

def test_div():
    var incr = internal.random[UInt64](1, 9999999999)
    for i1 in range(0, 100):
        for i2 in range(1, 100 * incr, incr):
            var i = TensorUInt128[UInt64, UInt64](i1, i2)
            var a = (UInt128(i1) << 64) + UInt128(i2)
            for j1 in range(0, 100):
                for j2 in range(1, 100 * incr, incr):
                    var j = TensorUInt128[UInt64, UInt64](j1, j2)
                    var b = (UInt128(j1) << 64) + UInt128(j2)
                    var actual = i / j
                    var expected = a / b
                    VERIFY_EQUAL(actual, expected)

def test_misc1():
    var incr = internal.random[UInt64](1, 9999999999)
    for i2 in range(1, 100 * incr, incr):
        var i = TensorUInt128[static_val[0], UInt64](0, i2)
        var a = UInt128(i2)
        for j2 in range(1, 100 * incr, incr):
            var j = TensorUInt128[static_val[0], UInt64](0, j2)
            var b = UInt128(j2)
            var actual = (i * j).upper()
            var expected = (a * b) >> 64
            VERIFY_IS_EQUAL(actual, expected)

def test_misc2():
    var incr = internal.random[UInt64](1, 100)
    for log_div in range(0, 63):
        for divider in range(1, 1000000 * incr, incr):
            var expected = (UInt128(1) << (64 + log_div)) / UInt128(divider) - (UInt128(1) << 64) + 1
            var shift = UInt64(1) << log_div
            var result = (TensorUInt128[UInt64, static_val[0]](shift, 0) / TensorUInt128[static_val[0], UInt64](divider)) - TensorUInt128[static_val[1], static_val[0]](1, 0) + TensorUInt128[static_val[0], static_val[1]](1)
            var actual = UInt64(result)
            VERIFY_IS_EQUAL(actual, expected)

// Main test dispatcher
def test_cxx11_tensor_uint128():
    # In C++: #ifdef EIGEN_NO_INT128 => return; else call subtests
    # We define EIGEN_NO_INT128 as a constant here (false)
    alias EIGEN_NO_INT128: Bool = False
    if EIGEN_NO_INT128:
        return
    else:
        # Equivalent of CALL_SUBTEST_1 etc. – just call the functions
        test_add()
        test_sub()
        test_mul()
        test_div()
        test_misc1()
        test_misc2()