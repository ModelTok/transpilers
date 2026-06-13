from main import main, CALL_SUBTEST, VERIFY_IS_EQUAL, VERIFY, VERIFY_IS_APPROX, g_repeat
from Eigen.Core import NumTraits, numext, internal

def check_abs[T: AnyType]():
    alias Real = NumTraits[T].Real
    if NumTraits[T].IsSigned:
        VERIFY_IS_EQUAL(numext.abs(-T(1)), T(1))
    VERIFY_IS_EQUAL(numext.abs(T(0)), T(0))
    VERIFY_IS_EQUAL(numext.abs(T(1)), T(1))
    for k in range(0, g_repeat * 100):
        var x: T = internal.random[T]()
        if not internal.is_same[T, bool].value:
            x = x / Real(2)
        if NumTraits[T].IsSigned:
            VERIFY_IS_EQUAL(numext.abs(x), numext.abs(-x))
            VERIFY(numext.abs(-x) >= Real(0))
        VERIFY(numext.abs(x) >= Real(0))
        VERIFY_IS_APPROX(numext.abs2(x), numext.abs2(numext.abs(x)))

def test_numext():
    CALL_SUBTEST(check_abs[bool]())
    CALL_SUBTEST(check_abs[signed char]())
    CALL_SUBTEST(check_abs[unsigned char]())
    CALL_SUBTEST(check_abs[short]())
    CALL_SUBTEST(check_abs[unsigned short]())
    CALL_SUBTEST(check_abs[int]())
    CALL_SUBTEST(check_abs[unsigned int]())
    CALL_SUBTEST(check_abs[long]())
    CALL_SUBTEST(check_abs[unsigned long]())
    CALL_SUBTEST(check_abs[half]())
    CALL_SUBTEST(check_abs[float]())
    CALL_SUBTEST(check_abs[double]())
    CALL_SUBTEST(check_abs[long double]())
    CALL_SUBTEST(check_abs[complex[float]]())
    CALL_SUBTEST(check_abs[complex[double]]())