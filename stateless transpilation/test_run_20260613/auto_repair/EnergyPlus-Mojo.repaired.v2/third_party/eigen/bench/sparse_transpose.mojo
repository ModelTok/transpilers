from BenchSparseUtil import (
    fillMatrix,
    eiToDense,
    eiToCSparse,
    eiToGmm,
    eiToMtl,
    BenchTimer,
    EigenSparseMatrix,
    DenseMatrix,
    cs,
    GmmSparse,
    GmmDynSparse,
    MtlSparse,
)
from cs import cs_transpose, cs_spfree
from gmm import copy as gmm_copy, transposed as gmm_transposed
from mtl import trans

alias SIZE = 10000
alias DENSITY = 0.01
alias REPEAT = 1
alias MINDENSITY = 0.0004
alias NBTRIES = 10

alias DENSEMATRIX = False
alias CSPARSE = False
alias NOGMM = False
alias NOMTL = False

def BENCH[X: fn() -> None]():
    var _j: Int = 0
    timer.reset()
    for _j in range(NBTRIES):
        timer.start()
        for _k in range(REPEAT):
            X()
        timer.stop()

def main(argc: Int, argv: Pointer[Pointer[UInt8]]?) -> Int:
    var rows: Int = SIZE
    var cols: Int = SIZE
    var density: Float64 = DENSITY
    var sm1 = EigenSparseMatrix(rows, cols)
    var sm3 = EigenSparseMatrix(rows, cols)
    var timer = BenchTimer()
    density = DENSITY
    while density >= MINDENSITY:
        fillMatrix(density, rows, cols, sm1)
        if DENSEMATRIX:
            var m1 = DenseMatrix(rows, cols)
            var m3 = DenseMatrix(rows, cols)
            eiToDense(sm1, m1)
            BENCH(lambda: for k in range(REPEAT): m3 = m1.transpose())
            print("Eigen dense:\t", timer.value(), sep="")
        print("Non zeros: ", sm1.nonZeros() / Float64(sm1.rows() * sm1.cols()) * 100, "%")
        if not DENSEMATRIX:  # always true because DENSEMATRIX=False
            BENCH(lambda: for k in range(REPEAT): sm3 = sm1.transpose())
            print("  Eigen:\t", timer.value(), sep="")
        if CSPARSE:
            var m1: cs
            var m3: cs
            eiToCSparse(sm1, m1)
            BENCH(lambda: for k in range(REPEAT): m3 = cs_transpose(m1, 1); cs_spfree(m3))
            print("  CSparse:\t", timer.value(), sep="")
        if not NOGMM:
            var gmmT3 = GmmDynSparse(rows, cols)
            var m1 = GmmSparse(rows, cols)
            var m3 = GmmSparse(rows, cols)
            eiToGmm(sm1, m1)
            BENCH(lambda: for k in range(REPEAT): gmm_copy(gmm_transposed(m1), m3))
            print("  GMM:\t\t", timer.value(), sep="")
        if not NOMTL:
            var m1 = MtlSparse(rows, cols)
            var m3 = MtlSparse(rows, cols)
            eiToMtl(sm1, m1)
            BENCH(lambda: for k in range(REPEAT): m3 = trans(m1))
            print("  MTL4:\t\t", timer.value(), sep="")
        print("\n\n")
        density *= 0.5
    return 0