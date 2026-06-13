from main import VERIFY_IS_APPROX, CALL_SUBTEST
from Eigen.Core import MatrixXf
from Eigen.CXX11.Tensor import Tensor, TensorMap, DimensionPair, array

def test_simple():
    var m1 = MatrixXf(3,3)
    var m2 = MatrixXf(3,3)
    m1.setRandom()
    m2.setRandom()
    var mat1 = TensorMap[Tensor[float32, 2]](m1.data(), 3, 3)
    var mat2 = TensorMap[Tensor[float32, 2]](m2.data(), 3, 3)
    var mat3 = Tensor[float32, 2](3, 3)
    mat3 = mat1
    typedef var DimPair = Tensor[float32, 1].DimensionPair
    var dims = array[DimPair, 1]()
    dims[0] = DimPair(1, 0)
    mat3 = mat3.contract(mat2, dims).eval()
    VERIFY_IS_APPROX(mat3(0, 0), (m1*m2).eval()(0,0))
    VERIFY_IS_APPROX(mat3(0, 1), (m1*m2).eval()(0,1))
    VERIFY_IS_APPROX(mat3(0, 2), (m1*m2).eval()(0,2))
    VERIFY_IS_APPROX(mat3(1, 0), (m1*m2).eval()(1,0))
    VERIFY_IS_APPROX(mat3(1, 1), (m1*m2).eval()(1,1))
    VERIFY_IS_APPROX(mat3(1, 2), (m1*m2).eval()(1,2))
    VERIFY_IS_APPROX(mat3(2, 0), (m1*m2).eval()(2,0))
    VERIFY_IS_APPROX(mat3(2, 1), (m1*m2).eval()(2,1))
    VERIFY_IS_APPROX(mat3(2, 2), (m1*m2).eval()(2,2))

def test_const():
    var input = MatrixXf(3,3)
    input.setRandom()
    var output = input
    output.rowwise() -= input.colwise().maxCoeff()
    var depth_dim = array[int32, 1]()
    depth_dim[0] = 0
    var dims2d = Tensor[float32, 2].Dimensions()
    dims2d[0] = 1
    dims2d[1] = 3
    var bcast = array[int32, 2]()
    bcast[0] = 3
    bcast[1] = 1
    var input_tensor = TensorMap[Tensor[const[float32], 2]](input.data(), 3, 3)
    var output_tensor = (input_tensor - input_tensor.maximum(depth_dim).eval().reshape(dims2d).broadcast(bcast))
    for i in range(3):
        for j in range(3):
            VERIFY_IS_APPROX(output(i, j), output_tensor(i, j))

def test_cxx11_tensor_forced_eval():
    CALL_SUBTEST(test_simple())
    CALL_SUBTEST(test_const())