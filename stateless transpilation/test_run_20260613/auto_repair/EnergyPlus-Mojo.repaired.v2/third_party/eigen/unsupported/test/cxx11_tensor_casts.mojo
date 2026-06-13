from main import main, VERIFY_IS_EQUAL, VERIFY_IS_APPROX, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor

def test_simple_cast():
    var ftensor = Tensor[Float32, 2](20, 30)
    ftensor = ftensor.random() * 100.0
    var chartensor = Tensor[Int8, 2](20, 30)
    chartensor.setRandom()
    var cplextensor = Tensor[ComplexFloat32, 2](20, 30)
    cplextensor.setRandom()
    chartensor = ftensor.cast[Int8]()
    cplextensor = ftensor.cast[ComplexFloat32]()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(chartensor[i, j], Int8(ftensor[i, j]))
            VERIFY_IS_EQUAL(cplextensor[i, j], ComplexFloat32(ftensor[i, j]))

def test_vectorized_cast():
    var itensor = Tensor[Int32, 2](20, 30)
    itensor = itensor.random() / 1000
    var ftensor = Tensor[Float32, 2](20, 30)
    ftensor.setRandom()
    var dtensor = Tensor[Float64, 2](20, 30)
    dtensor.setRandom()
    ftensor = itensor.cast[Float32]()
    dtensor = itensor.cast[Float64]()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(itensor[i, j], Int32(ftensor[i, j]))
            VERIFY_IS_EQUAL(dtensor[i, j], Float64(ftensor[i, j]))

def test_float_to_int_cast():
    var ftensor = Tensor[Float32, 2](20, 30)
    ftensor = ftensor.random() * 1000.0
    var dtensor = Tensor[Float64, 2](20, 30)
    dtensor = dtensor.random() * 1000.0
    var i1tensor = ftensor.cast[Int32]()
    var i2tensor = dtensor.cast[Int32]()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(i1tensor[i, j], Int32(ftensor[i, j]))
            VERIFY_IS_EQUAL(i2tensor[i, j], Int32(dtensor[i, j]))

def test_big_to_small_type_cast():
    var dtensor = Tensor[Float64, 2](20, 30)
    dtensor.setRandom()
    var ftensor = Tensor[Float32, 2](20, 30)
    ftensor = dtensor.cast[Float32]()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_APPROX(dtensor[i, j], Float64(ftensor[i, j]))

def test_small_to_big_type_cast():
    var ftensor = Tensor[Float32, 2](20, 30)
    ftensor.setRandom()
    var dtensor = Tensor[Float64, 2](20, 30)
    dtensor = ftensor.cast[Float64]()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_APPROX(dtensor[i, j], Float64(ftensor[i, j]))

def test_cxx11_tensor_casts():
    CALL_SUBTEST(test_simple_cast())
    CALL_SUBTEST(test_vectorized_cast())
    CALL_SUBTEST(test_float_to_int_cast())
    CALL_SUBTEST(test_big_to_small_type_cast())
    CALL_SUBTEST(test_small_to_big_type_cast())