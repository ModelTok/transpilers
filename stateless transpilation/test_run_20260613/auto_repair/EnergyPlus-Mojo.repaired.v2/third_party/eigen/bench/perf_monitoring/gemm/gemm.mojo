from memory import memset_zero
from math import max, min
from os import PathLike
from python import Python
from sys import argv
from time import perf_counter

# Simulating Eigen types and functions
struct Scalar:

struct Matrix:
    var rows: Int
    var cols: Int
    var data: Pointer[Scalar]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = Pointer[Scalar].alloc(rows * cols)

    def __del__(owned self):
        self.data.free()

    def setRandom(inout self):
        # Placeholder for random initialization

    def setZero(inout self):
        memset_zero(self.data, self.rows * self.cols)

    def noalias(inout self) -> Self:
        return self

    @staticmethod
    def Map(data: Pointer[Scalar], size: Int) -> Matrix:
        var mat = Matrix(size, 1)
        for i in range(size):
            mat.data[i] = data[i]
        return mat

struct RowVectorXd:
    var data: Pointer[Scalar]
    var size: Int

    def __init__(inout self, data: Pointer[Scalar], size: Int):
        self.data = data
        self.size = size

    def __str__(self) -> String:
        var s = String("[")
        for i in range(self.size):
            if i > 0:
                s += " "
            s += str(self.data[i])
        s += "]"
        return s

struct NumTraits:
    @staticmethod
    def IsComplex() -> Bool:
        return False

struct BenchTimer:
    var start_time: Float64
    var best_time: Float64

    def __init__(inout self):
        self.start_time = 0.0
        self.best_time = 1e18

    def start(inout self):
        self.start_time = perf_counter()

    def stop(inout self):
        var elapsed = perf_counter() - self.start_time
        if elapsed < self.best_time:
            self.best_time = elapsed

    def best(self) -> Float64:
        return self.best_time

def BENCH(t: BenchTimer, tries: Int, rep: Int, f: fn() -> None):
    for _ in range(tries):
        t.start()
        for _ in range(rep):
            f()
        t.stop()

def gemm(A: Matrix, B: Matrix, C: Matrix):
    C.noalias() += A * B

def bench(m: Int, n: Int, k: Int) -> Float64:
    var A = Matrix(m, k)
    var B = Matrix(k, n)
    var C = Matrix(m, n)
    A.setRandom()
    B.setRandom()
    C.setZero()
    var t = BenchTimer()
    var up = 1e8 * 4 / sizeof[Scalar]()
    var tm0 = 4.0
    var tm1 = 10.0
    if NumTraits.IsComplex():
        up /= 4
        tm0 = 2.0
        tm1 = 4.0
    var flops = 2.0 * m * n * k
    var rep = max(1.0, min(100.0, up / flops))
    var tries = max(tm0, min(tm1, up / flops))
    BENCH(t, tries, rep, lambda: gemm(A, B, C))
    return 1e-9 * rep * flops / t.best()

def main():
    var results = Python.list[Float64]()
    var settings = Python.open("gemm_settings.txt", "r")
    var m: Int
    var n: Int
    var k: Int
    while settings.read(m, n, k):
        results.append(bench(m, n, k))
    var result_mat = RowVectorXd.Map(results.data(), results.size())
    print(result_mat)