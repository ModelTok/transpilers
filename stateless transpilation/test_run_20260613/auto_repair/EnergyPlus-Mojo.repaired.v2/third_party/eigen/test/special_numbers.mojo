def VERIFY(condition: Bool):
    assert condition

alias Dynamic = Int(0)

// Following the original header: #include "main.h"

def special_numbers[Scalar: AnyType]():
    alias MatType = Matrix[Scalar, Dynamic, Dynamic]
    let rows = internal.random[Int](1, 300)
    let cols = internal.random[Int](1, 300)
    let nan = std.numeric_limits[Scalar]().quiet_NaN()
    let inf = std.numeric_limits[Scalar]().infinity()
    let s1 = internal.random[Scalar]()
    var m1: MatType = MatType.random(rows, cols)
    var mnan: MatType = MatType.random(rows, cols)
    var minf: MatType = MatType.random(rows, cols)
    var mboth: MatType = MatType.random(rows, cols)
    let n = internal.random[Int](1, 10)
    for k in range(n):
        mnan[internal.random[Int](0, rows - 1), internal.random[Int](0, cols - 1)] = nan
        minf[internal.random[Int](0, rows - 1), internal.random[Int](0, cols - 1)] = inf
    mboth = mnan + minf
    VERIFY(not m1.hasNaN())
    VERIFY(m1.allFinite())
    VERIFY(mnan.hasNaN())
    VERIFY((s1 * mnan).hasNaN())
    VERIFY(not minf.hasNaN())
    VERIFY(not (2 * minf).hasNaN())
    VERIFY(mboth.hasNaN())
    VERIFY(mboth.array().hasNaN())
    VERIFY(not mnan.allFinite())
    VERIFY(not minf.allFinite())
    VERIFY(not (minf - mboth).allFinite())
    VERIFY(not mboth.allFinite())
    VERIFY(not mboth.array().allFinite())

def test_special_numbers():
    for i in range(10 * g_repeat):
        special_numbers[Float32]()
        special_numbers[Float64]()