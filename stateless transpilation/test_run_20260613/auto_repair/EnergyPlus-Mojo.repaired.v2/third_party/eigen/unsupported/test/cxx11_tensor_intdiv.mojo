from ......CXX11.Tensor import TensorIntDivisor

def VERIFY_IS_EQUAL[T: ComparableEq](a: T, b: T):
    if a != b:
        print("FAIL: ", a, " != ", b)
        abort()

def test_signed_32bit():
    var div_by_one = TensorIntDivisor[Int32, False](1)
    for j in range(25000):
        let j_int32 = Int32(j)
        let fast_div = j_int32 / div_by_one
        let slow_div = j_int32 / 1
        VERIFY_IS_EQUAL(fast_div, slow_div)
    for i in range(2, 25000):
        let i_int32 = Int32(i)
        var div = TensorIntDivisor[Int32, False](i_int32)
        for j in range(25000):
            let j_int32 = Int32(j)
            let fast_div = j_int32 / div
            let slow_div = j_int32 / i_int32
            VERIFY_IS_EQUAL(fast_div, slow_div)
    for i in range(2, 25000):
        let i_int32 = Int32(i)
        var div = TensorIntDivisor[Int32, True](i_int32)
        for j in range(25000):
            let j_int32 = Int32(j)
            let fast_div = j_int32 / div
            let slow_div = j_int32 / i_int32
            VERIFY_IS_EQUAL(fast_div, slow_div)

def test_unsigned_32bit():
    for i in range(1, 25000):
        let i_uint32 = UInt32(i)
        var div = TensorIntDivisor[UInt32](i_uint32)
        for j in range(25000):
            let j_uint32 = UInt32(j)
            let fast_div = j_uint32 / div
            let slow_div = j_uint32 / i_uint32
            VERIFY_IS_EQUAL(fast_div, slow_div)

def test_signed_64bit():
    for i in range(1, 25000):
        let i_int64 = Int64(i)
        var div = TensorIntDivisor[Int64](i_int64)
        for j in range(25000):
            let j_int64 = Int64(j)
            let fast_div = j_int64 / div
            let slow_div = j_int64 / i_int64
            VERIFY_IS_EQUAL(fast_div, slow_div)

def test_unsigned_64bit():
    for i in range(1, 25000):
        let i_uint64 = UInt64(i)
        var div = TensorIntDivisor[UInt64](i_uint64)
        for j in range(25000):
            let j_uint64 = UInt64(j)
            let fast_div = j_uint64 / div
            let slow_div = j_uint64 / i_uint64
            VERIFY_IS_EQUAL(fast_div, slow_div)

def test_powers_32bit():
    for expon in range(1, 31):
        let div: Int32 = 1 << expon
        for num_expon in range(32):
            var start_num: Int32 = (1 << num_expon) - 100
            var end_num: Int32 = (1 << num_expon) + 100
            if start_num < 0:
                start_num = 0
            var num: Int32 = start_num
            while num < end_num:
                var divider = TensorIntDivisor[Int32](div)
                let result = num / div
                let result_op = divider.divide(num)
                VERIFY_IS_EQUAL(result_op, result)
                num += 1

def test_powers_64bit():
    for expon in range(63):
        let div: Int64 = 1 << expon
        for num_expon in range(63):
            var start_num: Int64 = (1 << num_expon) - 10
            var end_num: Int64 = (1 << num_expon) + 10
            if start_num < 0:
                start_num = 0
            var num: Int64 = start_num
            while num < end_num:
                var divider = TensorIntDivisor[Int64](div)
                let result = num / div
                let result_op = divider.divide(num)
                VERIFY_IS_EQUAL(result_op, result)
                num += 1

def test_specific():
    let div: Int64 = 209715200
    let num: Int64 = 3238002688
    var divider = TensorIntDivisor[Int64](div)
    let result = num / div
    let result_op = divider.divide(num)
    VERIFY_IS_EQUAL(result, result_op)

def test_cxx11_tensor_intdiv():
    test_signed_32bit()
    test_unsigned_32bit()
    test_signed_64bit()
    test_unsigned_64bit()
    test_powers_32bit()
    test_powers_64bit()
    test_specific()