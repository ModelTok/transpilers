# EIGEN_TEST_NO_LONGDOUBLE
# EIGEN_TEST_NO_COMPLEX
# EIGEN_TEST_FUNC cxx11_tensor_broadcast_sycl
# EIGEN_DEFAULT_DENSE_INDEX_TYPE int
# EIGEN_USE_SYCL
# include "main.h"
# include <unsupported/Eigen/CXX11/Tensor>
# using Eigen::array;
# using Eigen::SyclDevice;
# using Eigen::Tensor;
# using Eigen::TensorMap;

from Eigen import array, SyclDevice, Tensor, TensorMap

def test_broadcast_sycl(sycl_device: SyclDevice):
    var in_range: array[int, 4] = array[int, 4](2, 3, 5, 7)
    var broadcasts: array[int, 4] = array[int, 4](2, 3, 1, 4)
    var out_range: array[int, 4]  # = in_range * broadcasts
    for i in range(out_range.size()):
        out_range[i] = in_range[i] * broadcasts[i]
    var input: Tensor[float32, 4] = Tensor[float32, 4](in_range)
    var out: Tensor[float32, 4] = Tensor[float32, 4](out_range)
    for i in range(in_range.size()):
        VERIFY_IS_EQUAL(out.dimension(i), out_range[i])
    for i in range(input.size()):
        input(i) = float32(i)
    var gpu_in_data: Pointer[float32] = sycl_device.allocate(input.dimensions().TotalSize() * sizeof[float32]())
    var gpu_out_data: Pointer[float32] = sycl_device.allocate(out.dimensions().TotalSize() * sizeof[float32]())
    var gpu_in: TensorMap[Tensor[float32, 4]] = TensorMap[Tensor[float32, 4]](gpu_in_data, in_range)
    var gpu_out: TensorMap[Tensor[float32, 4]] = TensorMap[Tensor[float32, 4]](gpu_out_data, out_range)
    sycl_device.memcpyHostToDevice(gpu_in_data, input.data(), (input.dimensions().TotalSize()) * sizeof[float32]())
    gpu_out.device(sycl_device) = gpu_in.broadcast(broadcasts)
    sycl_device.memcpyDeviceToHost(out.data(), gpu_out_data, (out.dimensions().TotalSize()) * sizeof[float32]())
    for i in range(4):
        for j in range(9):
            for k in range(5):
                for l in range(28):
                    VERIFY_IS_APPROX(input(i % 2, j % 3, k % 5, l % 7), out(i, j, k, l))
    printf("Broadcast Test Passed\n")
    sycl_device.deallocate(gpu_in_data)
    sycl_device.deallocate(gpu_out_data)

def test_cxx11_tensor_broadcast_sycl():
    var s: cl.sycl.gpu_selector = cl.sycl.gpu_selector()
    var sycl_device: SyclDevice = SyclDevice(s)
    CALL_SUBTEST(test_broadcast_sycl(sycl_device))