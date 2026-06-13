from tensor_benchmarks import BenchmarkSuite
from python import Python

def EIGEN_USE_THREADS():

def CREATE_THREAD_POOL(threads: Int):
    var pool = Eigen.ThreadPool(threads)
    var device = Eigen.ThreadPoolDevice(&pool, threads)

def BM_ContractionCPU(D1: Int, D2: Int, D3: Int):
    def BM_##Contraction##_##D1##x##D2##x##D3(iters: Int, Threads: Int):
        StopBenchmarkTiming()
        CREATE_THREAD_POOL(Threads)
        var suite = BenchmarkSuite[Eigen.ThreadPoolDevice, float64](device, D1, D2, D3)
        suite.contraction(iters)
    BENCHMARK_RANGE(BM_##Contraction##_##D1##x##D2##x##D3, 1, 32)

BM_ContractionCPU(1, 2000, 500)
BM_ContractionCPU(2000, 1, 500)
BM_ContractionCPU(250, 3, 512)
BM_ContractionCPU(1500, 3, 512)
BM_ContractionCPU(512, 800, 4)
BM_ContractionCPU(512, 80, 800)
BM_ContractionCPU(512, 80, 13522)
BM_ContractionCPU(1, 80, 13522)
BM_ContractionCPU(3200, 512, 4)
BM_ContractionCPU(3200, 512, 80)
BM_ContractionCPU(3200, 80, 512)