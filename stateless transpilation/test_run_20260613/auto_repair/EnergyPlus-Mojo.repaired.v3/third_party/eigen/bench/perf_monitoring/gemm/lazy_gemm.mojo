from BenchTimer import BenchTimer
from Eigen.Core import *
import sys
import os

# SCALAR must be defined
# typedef SCALAR Scalar
alias Scalar = SCALAR

def lazy_gemm[MatA: AnyType, MatB: AnyType, MatC: AnyType](A: MatA, B: MatB, C: MatC):
    C.noalias() += A.lazyProduct(B)

def bench[m: Int, n: Int, k: Int, TA: Int]() -> Float64:
    alias MatA = Matrix[Scalar, m, k, TA]
    alias MatB = Matrix[Scalar, k, n]
    alias MatC = Matrix[Scalar, m, n]
    var A = MatA(m, k)
    var B = MatB(k, n)
    var C = MatC(m, n)
    A.setRandom()
    B.setRandom()
    C.setZero()
    var t = BenchTimer()
    var up = 1e7 * 4 / sizeof(Scalar)
    var tm0 = 10.0
    var tm1 = 20.0
    var flops = 2.0 * m * n * k
    var rep = max(10.0, min(10000.0, up / flops))
    var tries = max(tm0, min(tm1, up / flops))
    BENCH(t, tries, rep, lazy_gemm(A, B, C))
    return 1e-9 * rep * flops / t.best()

def bench_t[m: Int, n: Int, k: Int](t: Int) -> Float64:
    if t:
        return bench[m, n, k, RowMajor]()
    else:
        return bench[m, n, k, 0]()

def bench_mnk(m: Int, n: Int, k: Int, t: Int) -> Float64:
    var id = m * 10000 + n * 100 + k
    if id == 10101:
        return bench_t[1, 1, 1](t)
    elif id == 20202:
        return bench_t[2, 2, 2](t)
    elif id == 30303:
        return bench_t[3, 3, 3](t)
    elif id == 40404:
        return bench_t[4, 4, 4](t)
    elif id == 50505:
        return bench_t[5, 5, 5](t)
    elif id == 60606:
        return bench_t[6, 6, 6](t)
    elif id == 70707:
        return bench_t[7, 7, 7](t)
    elif id == 80808:
        return bench_t[8, 8, 8](t)
    elif id == 90909:
        return bench_t[9, 9, 9](t)
    elif id == 101010:
        return bench_t[10, 10, 10](t)
    elif id == 111111:
        return bench_t[11, 11, 11](t)
    elif id == 121212:
        return bench_t[12, 12, 12](t)
    return 0.0

def main():
    var results = List[Float64]()
    var settings = ifstream("lazy_gemm_settings.txt")
    var m: Int
    var n: Int
    var k: Int
    var t: Int
    while settings >> m >> n >> k >> t:
        results.append(bench_mnk(m, n, k, t))
    print(RowVectorXd.Map(results.data(), results.size()))