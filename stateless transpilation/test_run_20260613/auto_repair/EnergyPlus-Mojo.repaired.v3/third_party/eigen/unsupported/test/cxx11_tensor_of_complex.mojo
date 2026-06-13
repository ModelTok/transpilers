from main import *
from Eigen.CXX11.Tensor import Tensor, TensorMap, DimensionPair, Map, Matrix, Dynamic, array as Array

alias MapXcf = Map[Matrix[ComplexFloat32, Dynamic, Dynamic]]

def test_additions():
    var data1: Tensor[ComplexFloat32, 1] = Tensor[ComplexFloat32, 1](3)
    var data2: Tensor[ComplexFloat32, 1] = Tensor[ComplexFloat32, 1](3)
    for i in range(3):
        data1[i] = ComplexFloat32(Float32(i), Float32(-i))
        data2[i] = ComplexFloat32(Float32(i), Float32(7 * i))
    var sum: Tensor[ComplexFloat32, 1] = data1 + data2
    for i in range(3):
        VERIFY_IS_EQUAL(sum[i], ComplexFloat32(Float32(2 * i), Float32(6 * i)))

def test_abs():
    var data1: Tensor[ComplexFloat32, 1] = Tensor[ComplexFloat32, 1](3)
    var data2: Tensor[ComplexFloat64, 1] = Tensor[ComplexFloat64, 1](3)
    data1.setRandom()
    data2.setRandom()
    var abs1: Tensor[Float32, 1] = data1.abs()
    var abs2: Tensor[Float64, 1] = data2.abs()
    for i in range(3):
        VERIFY_IS_APPROX(abs1[i], abs(data1[i]))
        VERIFY_IS_APPROX(abs2[i], abs(data2[i]))

def test_conjugate():
    var data1: Tensor[ComplexFloat32, 1] = Tensor[ComplexFloat32, 1](3)
    var data2: Tensor[ComplexFloat64, 1] = Tensor[ComplexFloat64, 1](3)
    var data3: Tensor[Int32, 1] = Tensor[Int32, 1](3)
    data1.setRandom()
    data2.setRandom()
    data3.setRandom()
    var conj1: Tensor[ComplexFloat32, 1] = data1.conjugate()
    var conj2: Tensor[ComplexFloat64, 1] = data2.conjugate()
    var conj3: Tensor[Int32, 1] = data3.conjugate()
    for i in range(3):
        VERIFY_IS_APPROX(conj1[i], conj(data1[i]))
        VERIFY_IS_APPROX(conj2[i], conj(data2[i]))
        VERIFY_IS_APPROX(conj3[i], data3[i])

def test_contractions():
    var t_left: Tensor[ComplexFloat32, 4] = Tensor[ComplexFloat32, 4](30, 50, 8, 31)
    var t_right: Tensor[ComplexFloat32, 5] = Tensor[ComplexFloat32, 5](8, 31, 7, 20, 10)
    var t_result: Tensor[ComplexFloat32, 5] = Tensor[ComplexFloat32, 5](30, 50, 7, 20, 10)
    t_left.setRandom()
    t_right.setRandom()
    var m_left: MapXcf = MapXcf(t_left.data(), 1500, 248)
    var m_right: MapXcf = MapXcf(t_right.data(), 248, 1400)
    var m_result: Matrix[ComplexFloat32, Dynamic, Dynamic] = Matrix[ComplexFloat32, Dynamic, Dynamic](1500, 1400)
    var dims: Array[DimensionPair, 2] = Array[DimensionPair](2)
    dims[0] = DimensionPair(2, 0)
    dims[1] = DimensionPair(3, 1)
    t_result = t_left.contract(t_right, dims)
    m_result = m_left * m_right
    for i in range(t_result.dimensions().TotalSize()):
        VERIFY_IS_APPROX(t_result.data()[i], m_result.data()[i])

def test_cxx11_tensor_of_complex():
    CALL_SUBTEST(test_additions())
    CALL_SUBTEST(test_abs())
    CALL_SUBTEST(test_conjugate())
    CALL_SUBTEST(test_contractions())