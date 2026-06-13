# EIGEN_TEST_NO_LONGDOUBLE
# EIGEN_TEST_NO_COMPLEX
# EIGEN_TEST_FUNC cxx11_tensor_forced_eval_sycl
# EIGEN_DEFAULT_DENSE_INDEX_TYPE int
# EIGEN_USE_SYCL
from main import *
from unsupported.Eigen.CXX11.Tensor import *
using Eigen.Tensor

def test_forced_eval_sycl(sycl_device: Eigen.SyclDevice):
    var sizeDim1: Int = 100
    var sizeDim2: Int = 200
    var sizeDim3: Int = 200
    var tensorRange: Eigen.array[Int, 3] = Eigen.array[Int, 3](sizeDim1, sizeDim2, sizeDim3)
    var in1: Eigen.Tensor[float32, 3] = Eigen.Tensor[float32, 3](tensorRange)
    var in2: Eigen.Tensor[float32, 3] = Eigen.Tensor[float32, 3](tensorRange)
    var out: Eigen.Tensor[float32, 3] = Eigen.Tensor[float32, 3](tensorRange)
    var gpu_in1_data: Pointer[float32] = Pointer[float32](sycl_device.allocate(in1.dimensions().TotalSize() * sizeof[float32]()))
    var gpu_in2_data: Pointer[float32] = Pointer[float32](sycl_device.allocate(in2.dimensions().TotalSize() * sizeof[float32]()))
    var gpu_out_data: Pointer[float32] = Pointer[float32](sycl_device.allocate(out.dimensions().TotalSize() * sizeof[float32]()))
    in1 = in1.random() + in1.constant(10.0f)
    in2 = in2.random() + in2.constant(10.0f)
    var gpu_in1: Eigen.TensorMap[Eigen.Tensor[float32, 3]] = Eigen.TensorMap[Eigen.Tensor[float32, 3]](gpu_in1_data, tensorRange)
    var gpu_in2: Eigen.TensorMap[Eigen.Tensor[float32, 3]] = Eigen.TensorMap[Eigen.Tensor[float32, 3]](gpu_in2_data, tensorRange)
    var gpu_out: Eigen.TensorMap[Eigen.Tensor[float32, 3]] = Eigen.TensorMap[Eigen.Tensor[float32, 3]](gpu_out_data, tensorRange)
    sycl_device.memcpyHostToDevice(gpu_in1_data, in1.data(), (in1.dimensions().TotalSize()) * sizeof[float32]())
    sycl_device.memcpyHostToDevice(gpu_in2_data, in2.data(), (in1.dimensions().TotalSize()) * sizeof[float32]())
    gpu_out.device(sycl_device) = (gpu_in1 + gpu_in2).eval() * gpu_in2
    sycl_device.memcpyDeviceToHost(out.data(), gpu_out_data, (out.dimensions().TotalSize()) * sizeof[float32]())
    for i in range(sizeDim1):
        for j in range(sizeDim2):
            for k in range(sizeDim3):
                VERIFY_IS_APPROX(out(i, j, k), (in1(i, j, k) + in2(i, j, k)) * in2(i, j, k))
    printf("(a+b)*b Test Passed\n")
    sycl_device.deallocate(gpu_in1_data)
    sycl_device.deallocate(gpu_in2_data)
    sycl_device.deallocate(gpu_out_data)

def test_cxx11_tensor_forced_eval_sycl():
    var s: cl.sycl.gpu_selector = cl.sycl.gpu_selector()
    var sycl_device: Eigen.SyclDevice = Eigen.SyclDevice(s)
    CALL_SUBTEST(test_forced_eval_sycl(sycl_device))