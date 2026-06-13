from memory import memset_zero
from random import random
from time import now
from math import floor

# Simulating Eigen types and functions
struct Matrix:
    var data: Pointer[Float64]
    var rows: Int
    var cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = Pointer[Float64].alloc(rows * cols)

    def __del__(owned self):
        self.data.free()

    def setRandom(inout self):
        for i in range(self.rows * self.cols):
            self.data[i] = random()

    def noalias(inout self, other: Matrix):
        for i in range(self.rows * self.cols):
            self.data[i] += other.data[i]

    def __add__(self, other: Matrix) -> Matrix:
        var result = Matrix(self.rows, self.cols)
        for i in range(self.rows * self.cols):
            result.data[i] = self.data[i] + other.data[i]
        return result

    def __mul__(self, other: Matrix) -> Matrix:
        var result = Matrix(self.rows, other.cols)
        memset_zero(result.data, result.rows * result.cols)
        for i in range(self.rows):
            for k in range(self.cols):
                for j in range(other.cols):
                    result.data[i * result.cols + j] += self.data[i * self.cols + k] * other.data[k * other.cols + j]
        return result

# Simulating BenchTimer
struct BenchTimer:
    var start_time: Float64
    var best_time: Float64

    def __init__(inout self):
        self.start_time = 0.0
        self.best_time = 1e9

    def reset(inout self):
        self.start_time = now()
        self.best_time = 1e9

    def start(inout self):
        self.start_time = now()

    def stop(inout self):
        var elapsed = now() - self.start_time
        if elapsed < self.best_time:
            self.best_time = elapsed

    def best(self) -> Float64:
        return self.best_time

# Constants
alias InnerProduct = 0
alias OuterProduct = 1
alias CoeffBasedProductMode = 2
alias LazyCoeffBasedProductMode = 3
alias GemvProduct = 4
alias GemmProduct = 5
alias END = 9

# Template structs
struct map_size[S: Int]:
    alias ret = S

struct map_size_10:
    alias ret = 20

struct map_size_11:
    alias ret = 50

struct map_size_12:
    alias ret = 100

struct map_size_13:
    alias ret = 300

struct alt_prod[M: Int, N: Int, K: Int]:
    alias ret = (M == 1 and N == 1) ? InnerProduct : (K == 1) ? OuterProduct : (M == 1) ? GemvProduct : (N == 1) ? GemvProduct : GemmProduct

def print_mode(mode: Int):
    if mode == InnerProduct:
        print("i", end="")
    if mode == OuterProduct:
        print("o", end="")
    if mode == CoeffBasedProductMode:
        print("c", end="")
    if mode == LazyCoeffBasedProductMode:
        print("l", end="")
    if mode == GemvProduct:
        print("v", end="")
    if mode == GemmProduct:
        print("m", end="")

def prod[Mode: Int, Lhs: Matrix, Rhs: Matrix, Res: Matrix](a: Lhs, b: Rhs, inout c: Res):
    c.noalias(a * b)

def bench_prod[M: Int, N: Int, K: Int, Scalar: Float64, Mode: Int]():
    var a = Matrix(M, K)
    a.setRandom()
    var b = Matrix(K, N)
    b.setRandom()
    var c = Matrix(M, N)
    c.setRandom()
    var t = BenchTimer()
    var n = 2.0 * Float64(M) * Float64(N) * Float64(K)
    var rep = Int(100000.0 / n)
    rep = rep // 2
    if rep < 1:
        rep = 1
    while True:
        rep *= 2
        t.reset()
        for _ in range(rep):
            prod[CoeffBasedProductMode](a, b, c)
        if t.best() >= 0.1:
            break
    t.reset()
    for _ in range(5 * rep):
        prod[Mode](a, b, c)
    print_mode(Mode)
    print(Int(1e-6 * n * rep / t.best()), end="\t")

struct print_n[N: Int]:
    def run():
        if N < END:
            print(map_size[N].ret, end="\t")
            print_n[N + 1].run()

struct loop_on_k[M: Int, N: Int, K: Int]:
    def run():
        print("K=", K, "\t", end="")
        print_n[N].run()
        print("\n", end="")
        loop_on_m[M, N, K].run()
        print("\n\n", end="")
        loop_on_k[M, N, K + 1].run()

struct loop_on_k_END[M: Int, N: Int]:
    def run():

struct loop_on_m[M: Int, N: Int, K: Int]:
    def run():
        if M < END:
            print(M, "f\t", end="")
            loop_on_n[M, N, K, Float64, CoeffBasedProductMode].run()
            print("\n", end="")
            print(M, "f\t", end="")
            loop_on_n[M, N, K, Float64, -1].run()
            print("\n", end="")
            loop_on_m[M + 1, N, K].run()

struct loop_on_m_END[N: Int, K: Int]:
    def run():

struct loop_on_n[M: Int, N: Int, K: Int, Scalar: Float64, Mode: Int]:
    def run():
        if N < END:
            bench_prod[M, N, K, Scalar, (Mode == -1) ? alt_prod[M, N, K].ret : Mode]()
            loop_on_n[M, N + 1, K, Scalar, Mode].run()

struct loop_on_n_END[M: Int, K: Int, Scalar: Float64, Mode: Int]:
    def run():

def main():
    loop_on_k[1, 1, 1].run()