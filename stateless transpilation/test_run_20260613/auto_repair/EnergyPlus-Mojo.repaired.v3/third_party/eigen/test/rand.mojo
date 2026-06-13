from random import uniform, randint
from math import abs as math_abs
from builtin import print, abort, assert as mojo_assert

alias int64 = Int64

var g_repeat: Int32 = 1
var RAND_MAX: Int32 = 2147483647

def NumTraits_long_highest() -> Int64:
    return Int64(9223372036854775807)

def internal_random[Scalar: AnyType](x: Scalar, y: Scalar) -> Scalar:
    if issubtype[Scalar, Float64] or issubtype[Scalar, Float32]:
        return Scalar(uniform(Float64(x), Float64(y)))
    else:
        return Scalar(randint(Int64(x), Int64(y)))

def VERIFY(cond: Bool):
    if not cond:
        print("VERIFY failed")
        abort()

struct Array1D[T: AnyType]:
    var data: List[T]
    var size: Int

    def __init__(inout self, size: Int):
        self.data = List[T]()
        self.size = size
        for _ in range(size):
            self.data.append(T(0))

    def fill(inout self, value: T):
        for i in range(self.size):
            self.data[i] = value

    def __getitem__(self, index: Int) -> T:
        return self.data[index]

    def __setitem__(inout self, index: Int, value: T):
        self.data[index] = value

    def size(self) -> Int:
        return self.size

    def cast_to_float64(self) -> Array1D[Float64]:
        var result = Array1D[Float64](self.size)
        for i in range(self.size):
            result[i] = Float64(self.data[i])
        return result

    def abs(self) -> Array1D[T]:
        var result = Array1D[T](self.size)
        for i in range(self.size):
            result[i] = math_abs(self.data[i])
        return result

    def all(self) -> Bool:
        for i in range(self.size):
            if not self.data[i]:
                return False
        return True

    def __gt__(self, other: T) -> Array1D[Bool]:
        var result = Array1D[Bool](self.size)
        for i in range(self.size):
            result[i] = self.data[i] > other
        return result

def check_in_range[Scalar: AnyType](x: Scalar, y: Scalar) -> Scalar:
    var r: Scalar = internal_random[Scalar](x, y)
    VERIFY(r >= x)
    if y >= x:
        VERIFY(r <= y)
    return r

def check_all_in_range[Scalar: AnyType](x: Scalar, y: Scalar):
    var mask = Array1D[Int32](Int32(y) - Int32(x) + 1)
    mask.fill(0)
    var n: Int64 = (Int64(y) - Int64(x) + 1) * 32
    for k in range(Int64(0), n):
        mask[Int32(check_in_range[Scalar](x, y) - x)] += 1
    for i in range(mask.size()):
        if mask[i] == 0:
            print("WARNING: value ", x + Scalar(i), " not reached.")
    VERIFY((mask > 0).all())

def check_histogram[Scalar: AnyType](x: Scalar, y: Scalar, bins: Int32):
    var hist = Array1D[Int32](bins)
    hist.fill(0)
    var f: Int32 = 100000
    var n: Int32 = bins * f
    var range: int64 = int64(y) - int64(x)
    var divisor: Int32 = Int32((range + 1) / bins)
    mojo_assert(((range + 1) % bins) == 0)
    for k in range(n):
        var r: Scalar = check_in_range[Scalar](x, y)
        hist[Int32((int64(r) - int64(x)) / divisor)] += 1
    var hist_double = hist.cast_to_float64()
    var diff = Array1D[Float64](bins)
    for i in range(bins):
        diff[i] = (hist_double[i] / Float64(f)) - 1.0
    VERIFY((diff.abs() < 0.02).all())

def test_rand():
    var long_ref: Int64 = NumTraits_long_highest() / 10
    var char_offset: Int8 = Int8(min(g_repeat, 64))
    var short_offset: Int16 = Int16(min(g_repeat, 16000))
    for i in range(g_repeat * 10000):
        check_in_range[Float32](10.0, 11.0)
        check_in_range[Float32](1.24234523, 1.24234523)
        check_in_range[Float32](-1.0, 1.0)
        check_in_range[Float32](-1432.2352, -1432.2352)
        check_in_range[Float64](10.0, 11.0)
        check_in_range[Float64](1.24234523, 1.24234523)
        check_in_range[Float64](-1.0, 1.0)
        check_in_range[Float64](-1432.2352, -1432.2352)
        check_in_range[Int32](0, -1)
        check_in_range[Int16](0, -1)
        check_in_range[Int64](0, -1)
        check_in_range[Int32](-673456, 673456)
        check_in_range[Int32](-RAND_MAX + 10, RAND_MAX - 10)
        check_in_range[Int16](-24345, 24345)
        check_in_range[Int64](-long_ref, long_ref)
    check_all_in_range[Int8](11, 11)
    check_all_in_range[Int8](11, 11 + char_offset)
    check_all_in_range[Int8](-5, 5)
    check_all_in_range[Int8](-11 - char_offset, -11)
    check_all_in_range[Int8](-126, -126 + char_offset)
    check_all_in_range[Int8](126 - char_offset, 126)
    check_all_in_range[Int8](-126, 126)
    check_all_in_range[Int16](11, 11)
    check_all_in_range[Int16](11, 11 + short_offset)
    check_all_in_range[Int16](-5, 5)
    check_all_in_range[Int16](-11 - short_offset, -11)
    check_all_in_range[Int16](-24345, -24345 + short_offset)
    check_all_in_range[Int16](24345, 24345 + short_offset)
    check_all_in_range[Int32](11, 11)
    check_all_in_range[Int32](11, 11 + g_repeat)
    check_all_in_range[Int32](-5, 5)
    check_all_in_range[Int32](-11 - g_repeat, -11)
    check_all_in_range[Int32](-673456, -673456 + g_repeat)
    check_all_in_range[Int32](673456, 673456 + g_repeat)
    check_all_in_range[Int64](11, 11)
    check_all_in_range[Int64](11, 11 + g_repeat)
    check_all_in_range[Int64](-5, 5)
    check_all_in_range[Int64](-11 - g_repeat, -11)
    check_all_in_range[Int64](-long_ref, -long_ref + g_repeat)
    check_all_in_range[Int64](long_ref, long_ref + g_repeat)
    check_histogram[Int32](-5, 5, 11)
    var bins: Int32 = 100
    check_histogram[Int32](-3333, -3333 + bins * (3333 / bins) - 1, bins)
    bins = 1000
    check_histogram[Int32](-RAND_MAX + 10, -RAND_MAX + 10 + bins * (RAND_MAX / bins) - 1, bins)
    check_histogram[Int32](-RAND_MAX + 10, -int64(RAND_MAX) + 10 + bins * (2 * int64(RAND_MAX) / bins) - 1, bins)