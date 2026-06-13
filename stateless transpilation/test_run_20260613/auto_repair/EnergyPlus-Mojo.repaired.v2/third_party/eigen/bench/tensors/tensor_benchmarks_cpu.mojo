// Translation of tensor_benchmarks_cpu.cc to Mojo
// No refactoring, faithful 1:1 translation

from tensor_benchmarks import BenchmarkSuite, StopBenchmarkTiming
from python import Python
from sys import int

# Define thread pool types
# C++ defines: Eigen::ThreadPool, Eigen::ThreadPoolDevice, Eigen::DefaultDevice
# We'll use Python objects or Mojo structs as needed
struct Eigen_ThreadPool:
    var pool: PythonObject
    def __init__(inout self, num_threads: Int):
        self.pool = Python.evaluate("__import__('threading').ThreadPoolExecutor")(num_threads)

struct Eigen_ThreadPoolDevice:
    var device: PythonObject
    var pool: PythonObject
    def __init__(inout self, pool: PythonObject, num_threads: Int):
        self.pool = pool
        self.device = Python.evaluate("lambda p: p")(pool)

struct Eigen_DefaultDevice:
    var device: PythonObject
    def __init__(inout self):
        self.device = Python.evaluate("lambda: None")()

# Macro equivalent for CREATE_THREAD_POOL
# C++: #define CREATE_THREAD_POOL(threads) \
#      Eigen::ThreadPool pool(threads);                \
#      Eigen::ThreadPoolDevice device(&pool, threads);
# We'll in functions

# Macro equivalent for BM_FuncCPU
# C++: #define BM_FuncCPU(FUNC, THREADS) \
#   static void BM_##FUNC##_##THREADS##T(int iters, int N) { \
#     StopBenchmarkTiming(); \
#     CREATE_THREAD_POOL(THREADS); \
#     BenchmarkSuite<Eigen::ThreadPoolDevice, float> suite(device, N); \
#     suite.FUNC(iters); \
#   } \
#   BENCHMARK_RANGE(BM_##FUNC##_##THREADS##T, 10, 5000);

# We'll define benchmark functions directly
def BM_memcpy_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.memcpy(iters)

def BM_memcpy_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.memcpy(iters)

def BM_memcpy_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.memcpy(iters)

def BM_typeCasting_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.typeCasting(iters)

def BM_typeCasting_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.typeCasting(iters)

def BM_typeCasting_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.typeCasting(iters)

def BM_random_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.random(iters)

def BM_random_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.random(iters)

def BM_random_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.random(iters)

def BM_slicing_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.slicing(iters)

def BM_slicing_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.slicing(iters)

def BM_slicing_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.slicing(iters)

def BM_rowChip_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowChip(iters)

def BM_rowChip_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowChip(iters)

def BM_rowChip_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowChip(iters)

def BM_colChip_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colChip(iters)

def BM_colChip_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colChip(iters)

def BM_colChip_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colChip(iters)

def BM_shuffling_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.shuffling(iters)

def BM_shuffling_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.shuffling(iters)

def BM_shuffling_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.shuffling(iters)

def BM_padding_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.padding(iters)

def BM_padding_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.padding(iters)

def BM_padding_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.padding(iters)

def BM_striding_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.striding(iters)

def BM_striding_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.striding(iters)

def BM_striding_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.striding(iters)

def BM_broadcasting_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.broadcasting(iters)

def BM_broadcasting_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.broadcasting(iters)

def BM_broadcasting_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.broadcasting(iters)

def BM_coeffWiseOp_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.coeffWiseOp(iters)

def BM_coeffWiseOp_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.coeffWiseOp(iters)

def BM_coeffWiseOp_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.coeffWiseOp(iters)

def BM_algebraicFunc_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.algebraicFunc(iters)

def BM_algebraicFunc_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.algebraicFunc(iters)

def BM_algebraicFunc_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.algebraicFunc(iters)

def BM_transcendentalFunc_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.transcendentalFunc(iters)

def BM_transcendentalFunc_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.transcendentalFunc(iters)

def BM_transcendentalFunc_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.transcendentalFunc(iters)

def BM_rowReduction_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowReduction(iters)

def BM_rowReduction_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowReduction(iters)

def BM_rowReduction_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.rowReduction(iters)

def BM_colReduction_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colReduction(iters)

def BM_colReduction_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colReduction(iters)

def BM_colReduction_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.colReduction(iters)

# Macro equivalent for BM_FuncWithInputDimsCPU
# We'll define functions directly, with branching for THREADS == 1

def BM_contraction_NxNxN_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, N, N, N)
    suite.contraction(iters)

def BM_contraction_NxNxN_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, N)
    suite.contraction(iters)

def BM_contraction_NxNxN_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, N)
    suite.contraction(iters)

def BM_contraction_NxNxN_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, N)
    suite.contraction(iters)

def BM_contraction_NxNxN_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, N)
    suite.contraction(iters)

def BM_contraction_64xNxN_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, 64, N, N)
    suite.contraction(iters)

def BM_contraction_64xNxN_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 64, N, N)
    suite.contraction(iters)

def BM_contraction_64xNxN_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 64, N, N)
    suite.contraction(iters)

def BM_contraction_64xNxN_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 64, N, N)
    suite.contraction(iters)

def BM_contraction_64xNxN_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 64, N, N)
    suite.contraction(iters)

def BM_contraction_Nx64xN_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, N, 64, N)
    suite.contraction(iters)

def BM_contraction_Nx64xN_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, 64, N)
    suite.contraction(iters)

def BM_contraction_Nx64xN_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, 64, N)
    suite.contraction(iters)

def BM_contraction_Nx64xN_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, 64, N)
    suite.contraction(iters)

def BM_contraction_Nx64xN_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, 64, N)
    suite.contraction(iters)

def BM_contraction_NxNx64_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, N, N, 64)
    suite.contraction(iters)

def BM_contraction_NxNx64_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 64)
    suite.contraction(iters)

def BM_contraction_NxNx64_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 64)
    suite.contraction(iters)

def BM_contraction_NxNx64_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 64)
    suite.contraction(iters)

def BM_contraction_NxNx64_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 64)
    suite.contraction(iters)

def BM_contraction_1xNxN_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, 1, N, N)
    suite.contraction(iters)

def BM_contraction_1xNxN_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 1, N, N)
    suite.contraction(iters)

def BM_contraction_1xNxN_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 1, N, N)
    suite.contraction(iters)

def BM_contraction_1xNxN_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 1, N, N)
    suite.contraction(iters)

def BM_contraction_1xNxN_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, 1, N, N)
    suite.contraction(iters)

def BM_contraction_NxNx1_1T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var device_eigen = Eigen_DefaultDevice()
    var suite = BenchmarkSuite[Eigen_DefaultDevice, Float32](device_eigen, N, N, 1)
    suite.contraction(iters)

def BM_contraction_NxNx1_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 1)
    suite.contraction(iters)

def BM_contraction_NxNx1_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 1)
    suite.contraction(iters)

def BM_contraction_NxNx1_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 1)
    suite.contraction(iters)

def BM_contraction_NxNx1_16T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(16)
    var device = Eigen_ThreadPoolDevice(pool.pool, 16)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N, N, 1)
    suite.contraction(iters)

# BM_FuncWithKernelDimsCPU macro expansion
def BM_convolution_7x1_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 1)

def BM_convolution_7x1_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 1)

def BM_convolution_7x1_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 1)

def BM_convolution_1x7_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 1, 7)

def BM_convolution_1x7_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 1, 7)

def BM_convolution_1x7_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 1, 7)

def BM_convolution_7x4_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 4)

def BM_convolution_7x4_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 4)

def BM_convolution_7x4_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 4)

def BM_convolution_4x7_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 4, 7)

def BM_convolution_4x7_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 4, 7)

def BM_convolution_4x7_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 4, 7)

def BM_convolution_7x64_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 64)

def BM_convolution_7x64_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 64)

def BM_convolution_7x64_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 7, 64)

def BM_convolution_64x7_4T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(4)
    var device = Eigen_ThreadPoolDevice(pool.pool, 4)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 64, 7)

def BM_convolution_64x7_8T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(8)
    var device = Eigen_ThreadPoolDevice(pool.pool, 8)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 64, 7)

def BM_convolution_64x7_12T(iters: Int, N: Int):
    StopBenchmarkTiming()
    var pool = Eigen_ThreadPool(12)
    var device = Eigen_ThreadPoolDevice(pool.pool, 12)
    var suite = BenchmarkSuite[Eigen_ThreadPoolDevice, Float32](device, N)
    suite.convolution(iters, 64, 7)