from main import main
from Eigen.CXX11.Tensor import Tensor, TensorMap, RowMajor

def test_assign() raises:
    var data1: StaticFloat64[6]
    var mat1 = TensorMap[Tensor[const[float64], 2]](data1, 2, 3)
    var data2: StaticFloat64[6]
    var mat2 = TensorMap[Tensor[float64, 2]](data2, 2, 3)
    for i in range(6):
        data1[i] = i
        data2[i] = -i
    var rslt1 = Tensor[float64, 2]()
    rslt1 = mat1
    var rslt2 = Tensor[float64, 2]()
    rslt2 = mat2
    var rslt3 = Tensor[float64, 2](mat1)
    var rslt4 = Tensor[float64, 2](mat2)
    var rslt5 = Tensor[float64, 2](mat1)
    var rslt6 = Tensor[float64, 2](mat2)
    for i in range(2):
        for j in range(3):
            VERIFY_IS_APPROX(rslt1[i, j], float64(i + 2*j))
            VERIFY_IS_APPROX(rslt2[i, j], float64(-i - 2*j))
            VERIFY_IS_APPROX(rslt3[i, j], float64(i + 2*j))
            VERIFY_IS_APPROX(rslt4[i, j], float64(-i - 2*j))
            VERIFY_IS_APPROX(rslt5[i, j], float64(i + 2*j))
            VERIFY_IS_APPROX(rslt6[i, j], float64(-i - 2*j))

def test_plus() raises:
    var data1: StaticFloat64[6]
    var mat1 = TensorMap[Tensor[const[float64], 2]](data1, 2, 3)
    var data2: StaticFloat64[6]
    var mat2 = TensorMap[Tensor[float64, 2]](data2, 2, 3)
    for i in range(6):
        data1[i] = i
        data2[i] = -i
    var sum1 = Tensor[float64, 2]()
    sum1 = mat1 + mat2
    var sum2 = Tensor[float64, 2]()
    sum2 = mat2 + mat1
    for i in range(2):
        for j in range(3):
            VERIFY_IS_APPROX(sum1[i, j], 0.0)
            VERIFY_IS_APPROX(sum2[i, j], 0.0)

def test_plus_equal() raises:
    var data1: StaticFloat64[6]
    var mat1 = TensorMap[Tensor[const[float64], 2]](data1, 2, 3)
    var data2: StaticFloat64[6]
    var mat2 = TensorMap[Tensor[float64, 2]](data2, 2, 3)
    for i in range(6):
        data1[i] = i
        data2[i] = -i
    mat2 += mat1
    for i in range(2):
        for j in range(3):
            VERIFY_IS_APPROX(mat2[i, j], 0.0)

def test_cxx11_tensor_of_const_values() raises:
    CALL_SUBTEST(test_assign())
    CALL_SUBTEST(test_plus())
    CALL_SUBTEST(test_plus_equal())