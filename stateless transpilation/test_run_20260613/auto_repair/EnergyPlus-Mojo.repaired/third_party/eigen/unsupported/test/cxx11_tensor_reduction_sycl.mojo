# EIGEN_TEST_NO_LONGDOUBLE
# EIGEN_TEST_NO_COMPLEX
# EIGEN_TEST_FUNC cxx11_tensor_reduction_sycl
# EIGEN_DEFAULT_DENSE_INDEX_TYPE int
# EIGEN_USE_SYCL
from main import *
from unsupported.Eigen.CXX11.Tensor import *

def test_full_reductions_sycl(sycl_device: Eigen.SyclDevice):
    const num_rows: int = 452
    const num_cols: int = 765
    var tensorRange = array[int, 2]({{num_rows, num_cols}})
    var in = Tensor[float32, 2](tensorRange)
    var full_redux = Tensor[float32, 0]()
    var full_redux_gpu = Tensor[float32, 0]()
    in.setRandom()
    full_redux = in.sum()
    var gpu_in_data = (sycl_device.allocate(in.dimensions().TotalSize() * sizeof[float32]())).as_pointer[float32]()
    var gpu_out_data = (sycl_device.allocate(sizeof[float32]())).as_pointer[float32]()
    var in_gpu = TensorMap[Tensor[float32, 2]](gpu_in_data, tensorRange)
    var out_gpu = TensorMap[Tensor[float32, 0]](gpu_out_data)
    sycl_device.memcpyHostToDevice(gpu_in_data, in.data(), (in.dimensions().TotalSize()) * sizeof[float32]())
    out_gpu.device(sycl_device) = in_gpu.sum()
    sycl_device.memcpyDeviceToHost(full_redux_gpu.data(), gpu_out_data, sizeof[float32]())
    VERIFY_IS_APPROX(full_redux_gpu(), full_redux())
    sycl_device.deallocate(gpu_in_data)
    sycl_device.deallocate(gpu_out_data)

def test_first_dim_reductions_sycl(sycl_device: Eigen.SyclDevice):
    var dim_x: int = 145
    var dim_y: int = 1
    var dim_z: int = 67
    var tensorRange = array[int, 3]({{dim_x, dim_y, dim_z}})
    var red_axis = Eigen.array[int, 1]()
    red_axis[0] = 0
    var reduced_tensorRange = array[int, 2]({{dim_y, dim_z}})
    var in = Tensor[float32, 3](tensorRange)
    var redux = Tensor[float32, 2](reduced_tensorRange)
    var redux_gpu = Tensor[float32, 2](reduced_tensorRange)
    in.setRandom()
    redux = in.sum(red_axis)
    var gpu_in_data = (sycl_device.allocate(in.dimensions().TotalSize() * sizeof[float32]())).as_pointer[float32]()
    var gpu_out_data = (sycl_device.allocate(redux_gpu.dimensions().TotalSize() * sizeof[float32]())).as_pointer[float32]()
    var in_gpu = TensorMap[Tensor[float32, 3]](gpu_in_data, tensorRange)
    var out_gpu = TensorMap[Tensor[float32, 2]](gpu_out_data, reduced_tensorRange)
    sycl_device.memcpyHostToDevice(gpu_in_data, in.data(), (in.dimensions().TotalSize()) * sizeof[float32]())
    out_gpu.device(sycl_device) = in_gpu.sum(red_axis)
    sycl_device.memcpyDeviceToHost(redux_gpu.data(), gpu_out_data, redux_gpu.dimensions().TotalSize() * sizeof[float32]())
    for j in range(reduced_tensorRange[0]):
        for k in range(reduced_tensorRange[1]):
            VERIFY_IS_APPROX(redux_gpu(j, k), redux(j, k))
    sycl_device.deallocate(gpu_in_data)
    sycl_device.deallocate(gpu_out_data)

def test_last_dim_reductions_sycl(sycl_device: Eigen.SyclDevice):
    var dim_x: int = 567
    var dim_y: int = 1
    var dim_z: int = 47
    var tensorRange = array[int, 3]({{dim_x, dim_y, dim_z}})
    var red_axis = Eigen.array[int, 1]()
    red_axis[0] = 2
    var reduced_tensorRange = array[int, 2]({{dim_x, dim_y}})
    var in = Tensor[float32, 3](tensorRange)
    var redux = Tensor[float32, 2](reduced_tensorRange)
    var redux_gpu = Tensor[float32, 2](reduced_tensorRange)
    in.setRandom()
    redux = in.sum(red_axis)
    var gpu_in_data = (sycl_device.allocate(in.dimensions().TotalSize() * sizeof[float32]())).as_pointer[float32]()
    var gpu_out_data = (sycl_device.allocate(redux_gpu.dimensions().TotalSize() * sizeof[float32]())).as_pointer[float32]()
    var in_gpu = TensorMap[Tensor[float32, 3]](gpu_in_data, tensorRange)
    var out_gpu = TensorMap[Tensor[float32, 2]](gpu_out_data, reduced_tensorRange)
    sycl_device.memcpyHostToDevice(gpu_in_data, in.data(), (in.dimensions().TotalSize()) * sizeof[float32]())
    out_gpu.device(sycl_device) = in_gpu.sum(red_axis)
    sycl_device.memcpyDeviceToHost(redux_gpu.data(), gpu_out_data, redux_gpu.dimensions().TotalSize() * sizeof[float32]())
    for j in range(reduced_tensorRange[0]):
        for k in range(reduced_tensorRange[1]):
            VERIFY_IS_APPROX(redux_gpu(j, k), redux(j, k))
    sycl_device.deallocate(gpu_in_data)
    sycl_device.deallocate(gpu_out_data)

def test_cxx11_tensor_reduction_sycl():
    var s = cl.sycl.gpu_selector()
    var sycl_device = Eigen.SyclDevice(s)
    CALL_SUBTEST((test_full_reductions_sycl(sycl_device)))
    CALL_SUBTEST((test_first_dim_reductions_sycl(sycl_device)))
    CALL_SUBTEST((test_last_dim_reductions_sycl(sycl_device)))