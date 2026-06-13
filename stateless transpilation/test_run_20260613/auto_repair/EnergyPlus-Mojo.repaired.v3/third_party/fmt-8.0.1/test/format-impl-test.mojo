from test-assert import *
from fmt.format import *
from util import *
from fmt.detail import bigint, fp, max_value, accumulator, const_check, floor_log10_pow2, get_cached_power, get_round_direction, round_direction, digits, format_float, write_ptr, fallback_uintptr, fixed_handler, char8_type, float_specs, compute_width, count_digits, format_error_code
from fmt.detail.dragonbox import float_info

# Note: Original #include <windows.h> and _WIN32 conditional removed for Mojo portability.

static_assert(!is_copy_constructible[bigint](), "")
static_assert(!is_copy_assignable[bigint](), "")

def test_construct():
    assert_eq(fmt.format("{}", bigint()), "")
    assert_eq(fmt.format("{}", bigint(0x42)), "42")
    assert_eq(fmt.format("{}", bigint(0x123456789abcedf0)), "123456789abcedf0")

def test_compare():
    var n1 = bigint(42)
    var n2 = bigint(42)
    assert(compare(n1, n2) == 0)
    n2 <<= 32
    assert(compare(n1, n2) < 0)
    var n3 = bigint(43)
    assert(compare(n1, n3) < 0)
    assert(compare(n3, n1) > 0)
    var n4 = bigint(42 * 0x100000001)
    assert(compare(n2, n4) < 0)
    assert(compare(n4, n2) > 0)

def test_add_compare():
    assert(add_compare(bigint(0xffffffff), bigint(0xffffffff), bigint(1) <<= 64) < 0)
    assert(add_compare(bigint(1) <<= 32, bigint(1), bigint(1) <<= 96) < 0)
    assert(add_compare(bigint(1) <<= 32, bigint(0), bigint(0xffffffff)) > 0)
    assert(add_compare(bigint(0), bigint(1) <<= 32, bigint(0xffffffff)) > 0)
    assert(add_compare(bigint(42), bigint(1), bigint(42)) > 0)
    assert(add_compare(bigint(0xffffffff), bigint(1), bigint(0xffffffff)) > 0)
    assert(add_compare(bigint(10), bigint(10), bigint(22)) < 0)
    assert(add_compare(bigint(0x100000010), bigint(0x100000010), bigint(0x300000010)) < 0)
    assert(add_compare(bigint(0x1ffffffff), bigint(0x100000002), bigint(0x300000000)) > 0)
    assert(add_compare(bigint(0x1ffffffff), bigint(0x100000002), bigint(0x300000001)) == 0)
    assert(add_compare(bigint(0x1ffffffff), bigint(0x100000002), bigint(0x300000002)) < 0)
    assert(add_compare(bigint(0x1ffffffff), bigint(0x100000002), bigint(0x300000003)) < 0)

def test_shift_left():
    var n = bigint(0x42)
    n <<= 0
    assert_eq(fmt.format("{}", n), "42")
    n <<= 1
    assert_eq(fmt.format("{}", n), "84")
    n <<= 25
    assert_eq(fmt.format("{}", n), "108000000")

def test_multiply():
    var n = bigint(0x42)
    assert_error(lambda: n *= 0)
    n *= 1
    assert_eq(fmt.format("{}", n), "42")
    n *= 2
    assert_eq(fmt.format("{}", n), "84")
    n *= 0x12345678
    assert_eq(fmt.format("{}", n), "962fc95e0")
    var bigmax = bigint(max_value[uint32]())
    bigmax *= max_value[uint32]()
    assert_eq(fmt.format("{}", bigmax), "fffffffe00000001")
    bigmax.assign(max_value[uint64]())
    bigmax *= max_value[uint64]()
    assert_eq(fmt.format("{}", bigmax), "fffffffffffffffe0000000000000001")

def test_accumulator():
    var acc = accumulator()
    assert_eq(acc.lower, 0)
    assert_eq(acc.upper, 0)
    acc.upper = 12
    acc.lower = 34
    assert_eq(static_cast[uint32](acc), 34)
    acc += 56
    assert_eq(acc.lower, 90)
    acc += max_value[uint64]()
    assert_eq(acc.upper, 13)
    assert_eq(acc.lower, 89)
    acc >>= 32
    assert_eq(acc.upper, 0)
    assert_eq(acc.lower, 13 * 0x100000000)

def test_square():
    var n0 = bigint(0)
    n0.square()
    assert_eq(fmt.format("{}", n0), "0")
    var n1 = bigint(0x100)
    n1.square()
    assert_eq(fmt.format("{}", n1), "10000")
    var n2 = bigint(0xfffffffff)
    n2.square()
    assert_eq(fmt.format("{}", n2), "ffffffffe000000001")
    var n3 = bigint(max_value[uint64]())
    n3.square()
    assert_eq(fmt.format("{}", n3), "fffffffffffffffe0000000000000001")
    var n4 = bigint()
    n4.assign_pow10(10)
    assert_eq(fmt.format("{}", n4), "2540be400")

def test_divmod_assign_zero_divisor():
    var zero = bigint(0)
    assert_error(lambda: bigint(0).divmod_assign(zero))
    assert_error(lambda: bigint(42).divmod_assign(zero))

def test_divmod_assign_self():
    var n = bigint(100)
    assert_error(lambda: n.divmod_assign(n))

def test_divmod_assign_unaligned():
    var n1 = bigint(42)
    n1 <<= 340
    var n2 = bigint()
    n2.assign_pow10(100)
    var result = n1.divmod_assign(n2)
    assert_eq(result, 9406)
    assert_eq(fmt.format("{}", n1), "10f8353019583bfc29ffc8f564e1b9f9d819dbb4cf783e4507eca1539220p96")

def test_divmod_assign():
    var n1 = bigint(100)
    var result = n1.divmod_assign(bigint(10))
    assert_eq(result, 10)
    assert_eq(fmt.format("{}", n1), "0")
    n1.assign_pow10(100)
    result = n1.divmod_assign(bigint(42) <<= 320)
    assert_eq(result, 111)
    assert_eq(fmt.format("{}", n1), "13ad2594c37ceb0b2784c4ce0bf38ace408e211a7caab24308a82e8f10p96")
    var n2 = bigint(42)
    n1.assign_pow10(2)
    result = n2.divmod_assign(n1)
    assert_eq(result, 0)
    assert_eq(fmt.format("{}", n2), "2a")

# Template for run_double_tests: not directly translatable; we specialize for is_iec559=true
# Equivalent to C++ template specialization, using Mojo's conditional compilation or overload.
# We'll create a function that uses a boolean parameter and constant if.

def run_double_tests[is_iec559: Bool]():
    if not is_iec559:
        print("warning: double is not IEC559, skipping FP tests")
    else:
        assert_eq(fp(1.23), fp(0x13ae147ae147aeu, -52))

def test_double_tests():
    run_double_tests[is_iec559: std.numeric_limits[Float64].is_iec559]()

def test_normalize():
    var v = fp(0xbeef, 42)
    var normalized = normalize(v)
    assert_eq(0xbeef000000000000, normalized.f)
    assert_eq(-6, normalized.e)

def test_multiply():
    var v = fp(123ULL << 32, 4) * fp(56ULL << 32, 7)
    assert_eq(v.f, 123u * 56u)
    assert_eq(v.e, 4 + 7 + 64)
    v = fp(123ULL << 32, 4) * fp(567ULL << 31, 8)
    assert_eq(v.f, (123 * 567 + 1u) // 2)
    assert_eq(v.e, 4 + 8 + 64)

def test_get_cached_power():
    using limits = std.numeric_limits[Float64]
    for exp in range(limits.min_exponent, limits.max_exponent + 1):
        var dec_exp = 0
        var fp_val = get_cached_power(exp, dec_exp)
        var exact = bigint()
        var cache = bigint(fp_val.f)
        if dec_exp >= 0:
            exact.assign_pow10(dec_exp)
            if fp_val.e <= 0:
                exact <<= -fp_val.e
            else:
                cache <<= fp_val.e
            exact.align(cache)
            cache.align(exact)
            var exact_str = fmt.format("{}", exact)
            var cache_str = fmt.format("{}", cache)
            assert_eq(exact_str.size(), cache_str.size())
            assert_eq(exact_str.substr(0, 15), cache_str.substr(0, 15))
            var diff = cache_str[15] - exact_str[15]
            if diff == 1:
                assert(exact_str[16] > '8')
            else:
                assert_eq(diff, 0)
        else:
            cache.assign_pow10(-dec_exp)
            cache *= fp_val.f + 1
            exact.assign(1)
            exact <<= -fp_val.e
            exact.align(cache)
            var exact_str = fmt.format("{}", exact)
            var cache_str = fmt.format("{}", cache)
            assert_eq(exact_str.size(), cache_str.size())
            assert_eq(exact_str.substr(0, 16), cache_str.substr(0, 16))

def test_dragonbox_max_k():
    using float_info_f = float_info[Float32]
    assert_eq(const_check(float_info_f.max_k), float_info_f.kappa - floor_log10_pow2(float_info_f.min_exponent - float_info_f.significand_bits))
    using double_info = float_info[Float64]
    assert_eq(const_check(double_info.max_k), double_info.kappa - floor_log10_pow2(double_info.min_exponent - double_info.significand_bits))

def test_get_round_direction():
    assert_eq(round_direction.down, get_round_direction(100, 50, 0))
    assert_eq(round_direction.up, get_round_direction(100, 51, 0))
    assert_eq(round_direction.down, get_round_direction(100, 40, 10))
    assert_eq(round_direction.up, get_round_direction(100, 60, 10))
    for i in range(41, 60):
        assert_eq(round_direction.unknown, get_round_direction(100, i, 10))
    var max_val = max_value[uint64]()
    assert_error(lambda: get_round_direction(100, 100, 0))
    assert_error(lambda: get_round_direction(100, 0, 100))
    assert_error(lambda: get_round_direction(100, 0, 50))
    assert_eq(round_direction.up, get_round_direction(max_val, max_val - 1, 2))
    assert_eq(round_direction.unknown, get_round_direction(max_val, max_val // 2 + 1, max_val // 2))
    assert_eq(round_direction.unknown, get_round_direction(100, 40, 41))
    assert_eq(round_direction.up, get_round_direction(max_val, max_val - 1, 1))

# Note: struct handler inheritance adapted to class
class handler(fixed_handler):
    var buffer: StaticArray[Int8, 10]
    def __init__(inout self, prec: Int = 0):
        self.buf = buffer.data
        self.precision = prec

def test_fixed_handler():
    var exp = 0
    var h = handler()
    h.on_digit('0', 100, 99, 0, exp, False)
    assert_error(lambda: handler().on_digit('0', 100, 100, 0, exp, False))
    assert_eq(handler(1).on_digit('0', 100, 10, 10, exp, False), digits.error)
    assert_eq(handler(1).on_digit('0', 100, 10, 101, exp, False), digits.error)
    var max_val = max_value[uint64]()
    assert_eq(handler(1).on_digit('0', max_val, 10, max_val - 1, exp, False), digits.error)

def test_grisu_format_compiles_with_on_ieee_double():
    var buf = fmt.memory_buffer()
    format_float(0.42, -1, float_specs(), buf)

def test_format_error_code():
    var msg = "error 42"
    var sep = ": "
    # First block
    var buffer1 = fmt.memory_buffer()
    format_to[fmt.appender](buffer1, "garbage")
    fmt.detail.format_error_code(buffer1, 42, "test")
    assert_eq(to_string(buffer1), "test: " + msg)
    # Second block
    var buffer2 = fmt.memory_buffer()
    var prefix1 = String("x") * (fmt.inline_buffer_size - msg.size() - sep.size() + 1)
    fmt.detail.format_error_code(buffer2, 42, prefix1)
    assert_eq(to_string(buffer2), msg)
    # Codes loop
    var codes = [42, -1]
    for idx in range(2):
        msg = fmt.format("error {}", codes[idx])
        var buffer3 = fmt.memory_buffer()
        var prefix2 = String("x") * (fmt.inline_buffer_size - msg.size() - sep.size())
        fmt.detail.format_error_code(buffer3, codes[idx], prefix2)
        assert_eq(to_string(buffer3), prefix2 + sep + msg)
        assert_eq(fmt.inline_buffer_size, buffer3.size())
        buffer3.resize(0)
        prefix2 += "x"
        fmt.detail.format_error_code(buffer3, codes[idx], prefix2)
        assert_eq(to_string(buffer3), msg)

def test_compute_width():
    # Note: char8_type assumed from fmt.detail
    var s = basic_string_view[char8_type](ptr=reinterpret[Ptr[char8_type]]("ёжик".data()), size=4)
    assert_eq(4, compute_width(s))

def test_count_digits():
    # Test for uint32
    for i in range(10):
        assert_eq(1u, count_digits[uint32](i))
    var n: uint32 = 1
    for i in range(1, 11): # approximate upper bound
        if n > max_value[uint32]() // 10:
            break
        n *= 10
        assert_eq(i, count_digits[uint32](n - 1))
        assert_eq(i + 1, count_digits[uint32](n))
    # Test for uint64
    for i in range(10):
        assert_eq(1u, count_digits[uint64](i))
    var n64: uint64 = 1
    for i in range(1, 21): # approximate upper bound
        if n64 > max_value[uint64]() // 10:
            break
        n64 *= 10
        assert_eq(i, count_digits[uint64](n64 - 1))
        assert_eq(i + 1, count_digits[uint64](n64))

def test_write_fallback_uintptr():
    var s = String()
    write_ptr[char](
        std.back_inserter(s),
        fallback_uintptr(reinterpret[Ptr[Void]](0xface)),
        None)
    assert_eq(s, "0xface")

# _WIN32 section: WriteConsoleW test omitted for portability
# The following is commented out because Mojo does not support Windows header.
# If compiled on Windows, uncomment:
# from windows import WriteConsoleW
# def test_write_console_signature():
#     var p: Ptr[decltype(WriteConsoleW)] = fmt.detail.WriteConsoleW
#     pass