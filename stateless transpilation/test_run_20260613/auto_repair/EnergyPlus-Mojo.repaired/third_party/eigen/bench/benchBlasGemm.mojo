alias _FLOAT = True

from Eigen import Matrix, BenchTimer, l1CacheSize, l2CacheSize, internal, Dynamic
from BenchTimer import BenchTimer  # Assuming BenchTimer is also available separately? Actually Eigen has it.
from math import floor
from sys import exit

@parameter
if _FLOAT:
    alias Scalar = Float32
    alias CBLAS_GEMM = cblas_sgemm
else:
    alias Scalar = Float64
    alias CBLAS_GEMM = cblas_dgemm

# Declare CBLAS functions
@extern
def cblas_sgemm(
    Order: Int, TransA: Int, TransB: Int,
    M: Int, N: Int, K: Int,
    alpha: Float32, A: Pointer[Float32], lda: Int,
    B: Pointer[Float32], ldb: Int,
    beta: Float32, C: Pointer[Float32], ldc: Int
): ...

@extern
def cblas_dgemm(
    Order: Int, TransA: Int, TransB: Int,
    M: Int, N: Int, K: Int,
    alpha: Float64, A: Pointer[Float64], lda: Int,
    B: Pointer[Float64], ldb: Int,
    beta: Float64, C: Pointer[Float64], ldc: Int
): ...

# Constants for CBLAS
alias CblasRowMajor = 101
alias CblasColMajor = 102
alias CblasNoTrans = 111
alias CblasTrans = 112

alias MyMatrix = Matrix[Scalar, Dynamic, Dynamic]

def bench_eigengemm(mc: MyMatrix, ma: MyMatrix, mb: MyMatrix, nbloops: Int):
    for j in range(nbloops):
        mc.noalias() += ma * mb

def check_product(M: Int, N: Int, K: Int):
    var ma = MyMatrix.random(M, K)
    var mb = MyMatrix.random(K, N)
    var mc = MyMatrix.random(M, N)
    var maT = ma.transpose()
    var mbT = mb.transpose()
    var meigen = MyMatrix(M, N)
    var mref = MyMatrix(M, N)
    meigen = mc
    mref = mc
    var eps: Scalar = 1e-4
    CBLAS_GEMM(CblasColMajor, CblasNoTrans, CblasNoTrans, M, N, K, 1, ma.data(), M, mb.data(), K, 1, mref.data(), M)
    meigen += ma * mb
    MYVERIFY(meigen.isApprox(mref, eps), ". * .")
    meigen = mref = mc
    CBLAS_GEMM(CblasColMajor, CblasTrans, CblasNoTrans, M, N, K, 1, maT.data(), K, mb.data(), K, 1, mref.data(), M)
    meigen += maT.transpose() * mb
    MYVERIFY(meigen.isApprox(mref, eps), "T * .")
    meigen = mref = mc
    CBLAS_GEMM(CblasColMajor, CblasTrans, CblasTrans, M, N, K, 1, maT.data(), K, mbT.data(), N, 1, mref.data(), M)
    meigen += (maT.transpose()) * (mbT.transpose())
    MYVERIFY(meigen.isApprox(mref, eps), "T * T")
    meigen = mref = mc
    CBLAS_GEMM(CblasColMajor, CblasNoTrans, CblasTrans, M, N, K, 1, ma.data(), M, mbT.data(), N, 1, mref.data(), M)
    meigen += ma * mbT.transpose()
    MYVERIFY(meigen.isApprox(mref, eps), ". * T")

def check_product():
    var M: Int
    var N: Int
    var K: Int
    for i in range(1000):
        M = internal.random[Int](1, 64)
        N = internal.random[Int](1, 768)
        K = internal.random[Int](1, 768)
        M = (0 + M) * 1
        print(M, " x ", N, " x ", K)
        check_product(M, N, K)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    #ifdef __GNUC__
    # asm block omitted (not supported in Mojo)
    #endif
    var nbtries: Int = 1
    var nbloops: Int = 1
    var M: Int
    var N: Int
    var K: Int
    if argc == 2:
        if String(argv[1]) == "check":
            check_product()
        else:
            M = N = K = int(String(argv[1]))
    elif (argc == 3) and (String(argv[1]) == "auto"):
        M = N = K = int(String(argv[2]))
        nbloops = 1000000000 / (M * M * M)
        if nbloops < 1:
            nbloops = 1
        nbtries = 6
    elif argc == 4:
        M = N = K = int(String(argv[1]))
        nbloops = int(String(argv[2]))
        nbtries = int(String(argv[3]))
    elif argc == 6:
        M = int(String(argv[1]))
        N = int(String(argv[2]))
        K = int(String(argv[3]))
        nbloops = int(String(argv[4]))
        nbtries = int(String(argv[5]))
    else:
        print("Usage: ", argv[0], " size  ")
        print("Usage: ", argv[0], " auto size")
        print("Usage: ", argv[0], " size nbloops nbtries")
        print("Usage: ", argv[0], " M N K nbloops nbtries")
        print("Usage: ", argv[0], " check")
        print("Options:")
        print("    size       unique size of the 2 matrices (integer)")
        print("    auto       automatically set the number of repetitions and tries")
        print("    nbloops    number of times the GEMM routines is executed")
        print("    nbtries    number of times the loop is benched (return the best try)")
        print("    M N K      sizes of the matrices: MxN  =  MxK * KxN (integers)")
        print("    check      check eigen product using cblas as a reference")
        exit(1)
    var nbmad: Float64 = Float64(M) * Float64(N) * Float64(K) * Float64(nbloops)
    if not (String(argv[1]) == "auto"):
        print(M, " x ", N, " x ", K)
    var alpha: Scalar
    var beta: Scalar
    var ma = MyMatrix.random(M, K)
    var mb = MyMatrix.random(K, N)
    var mc = MyMatrix.random(M, N)
    var timer = BenchTimer()
    alpha = 1
    beta = 1
    if not (String(argv[1]) == "auto"):
        timer.reset()
        for k in range(nbtries):
            timer.start()
            for j in range(nbloops):
                #ifdef EIGEN_DEFAULT_TO_ROW_MAJOR
                #CBLAS_GEMM(CblasRowMajor, CblasNoTrans, CblasNoTrans, M, N, K, alpha, ma.data(), K, mb.data(), N, beta, mc.data(), N)
                #else
                CBLAS_GEMM(CblasColMajor, CblasNoTrans, CblasNoTrans, M, N, K, alpha, ma.data(), M, mb.data(), K, beta, mc.data(), M)
                #endif
            timer.stop()
        if not (String(argv[1]) == "auto"):
            print("cblas: ", timer.value(), " (", 1e-3 * floor(1e-6 * nbmad / timer.value()), " GFlops/s)")
        else:
            print(M, " : ", timer.value(), " ; ", 1e-3 * floor(1e-6 * nbmad / timer.value()))
    ma = MyMatrix.random(M, K)
    mb = MyMatrix.random(K, N)
    mc = MyMatrix.random(M, N)
    {
        timer.reset()
        for k in range(nbtries):
            timer.start()
            bench_eigengemm(mc, ma, mb, nbloops)
            timer.stop()
        if not (String(argv[1]) == "auto"):
            print("eigen : ", timer.value(), " (", 1e-3 * floor(1e-6 * nbmad / timer.value()), " GFlops/s)")
        else:
            print(M, " : ", timer.value(), " ; ", 1e-3 * floor(1e-6 * nbmad / timer.value()))
    }
    print("l1: ", l1CacheSize())
    print("l2: ", l2CacheSize())
    return 0

# Helper macro replacement
def MYVERIFY(condition: Bool, message: String):
    if not condition:
        print("FAIL: ", message)