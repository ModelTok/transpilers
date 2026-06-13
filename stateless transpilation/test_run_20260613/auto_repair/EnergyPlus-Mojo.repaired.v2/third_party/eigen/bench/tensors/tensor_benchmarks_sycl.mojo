from SYCL import cl
from io import print
from tensor_benchmarks import *
alias Eigen.array = array
alias Eigen.SyclDevice = SyclDevice
alias Eigen.Tensor = Tensor
alias Eigen.TensorMap = TensorMap

def sycl_queue[device_selector: type]() -> cl.sycl.queue:
  return cl.sycl.queue(device_selector(), fn(l: cl.sycl.exception_list):
    for e in l:
      try:
        rethrow_exception(e)
      except cl.sycl.exception as e:
        print(e.what())
    )
  )

def BM_broadcasting(iters: Int, N: Int):
  StopBenchmarkTiming()
  let q = sycl_queue[cl.sycl.gpu_selector]()
  let device = Eigen.SyclDevice(q)
  let suite = BenchmarkSuite[Eigen.SyclDevice, float32](device, N)
  suite.broadcasting(iters)

BENCHMARK_RANGE(BM_broadcasting, 10, 5000)

def BM_coeffWiseOp(iters: Int, N: Int):
  StopBenchmarkTiming()
  let q = sycl_queue[cl.sycl.gpu_selector]()
  let device = Eigen.SyclDevice(q)
  let suite = BenchmarkSuite[Eigen.SyclDevice, float32](device, N)
  suite.coeffWiseOp(iters)

BENCHMARK_RANGE(BM_coeffWiseOp, 10, 5000)
<<<FILE>>>