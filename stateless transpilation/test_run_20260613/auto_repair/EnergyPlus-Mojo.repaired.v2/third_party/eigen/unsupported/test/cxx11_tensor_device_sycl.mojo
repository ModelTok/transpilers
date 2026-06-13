// #define EIGEN_TEST_NO_LONGDOUBLE
// #define EIGEN_TEST_NO_COMPLEX
// #define EIGEN_TEST_FUNC cxx11_tensor_device_sycl
// #define EIGEN_DEFAULT_DENSE_INDEX_TYPE int
// #define EIGEN_USE_SYCL
from main import CALL_SUBTEST
from ...Eigen.CXX11.Tensor import SyclDevice as Eigen_SyclDevice
from cl.sycl import gpu_selector
from cl.sycl.info.device import name as device_name

def test_device_sycl(sycl_device: Eigen_SyclDevice):
    print("Helo from ComputeCpp: the requested device exists and the device name is : ", sycl_device.m_queue.get_device().get_info[device_name]());;

def test_cxx11_tensor_device_sycl():
    var s = gpu_selector()
    var sycl_device = Eigen_SyclDevice(s)
    CALL_SUBTEST(test_device_sycl(sycl_device))