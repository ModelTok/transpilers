from Eigen.Core import *
from Eigen.Cholesky import *
from .BenchUtil import *

alias REPEAT: Int = 10000
alias TRIES: Int = 10
alias Scalar: DType = Float32

def benchLLT[MatrixType: AnyType](borrowed m: MatrixType):
    let rows: Int = m.rows()
    let cols: Int = m.cols()
    var cost: Float64 = 0.0
    for j in range(rows):
        let r: Int = max(rows - j - 1, 0)
        cost += 2.0 * Float64(r * j + r + j)
    let repeats: Int = (REPEAT * 1000) // (rows * rows)

    alias ScalarInner: DType = MatrixType.Scalar
    alias SquareMatrixType: AnyType = Matrix[ScalarInner, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var a: MatrixType = MatrixType.Random(rows, cols)
    var covMat: SquareMatrixType = a * a.adjoint()
    var timerNoSqrt: BenchTimer
    var timerSqrt: BenchTimer
    var acc: ScalarInner = 0
    let r: Int = internal.random[Int](0, covMat.rows() - 1)
    let c: Int = internal.random[Int](0, covMat.cols() - 1)

    for t in range(TRIES):
        timerNoSqrt.start()
        for k in range(repeats):
            var cholnosqrt: LDLT[SquareMatrixType] = LDLT[SquareMatrixType](covMat)
            acc += cholnosqrt.matrixL().coeff(r, c)
        timerNoSqrt.stop()

    for t in range(TRIES):
        timerSqrt.start()
        for k in range(repeats):
            var chol: LLT[SquareMatrixType] = LLT[SquareMatrixType](covMat)
            acc += chol.matrixL().coeff(r, c)
        timerSqrt.stop()

    if MatrixType.RowsAtCompileTime == Dynamic:
        print("dyn   ", end="")
    else:
        print("fixed ", end="")
    print(
        covMat.rows(), "\t",
        (timerNoSqrt.best()) / repeats, "s ",
        "(", 1e-9 * cost * repeats / timerNoSqrt.best(), " GFLOPS)\t",
        (timerSqrt.best()) / repeats, "s ",
        "(", 1e-9 * cost * repeats / timerSqrt.best(), " GFLOPS)\n",
        sep="", end=""
    )

    alias BENCH_GSL: Bool = False
    if BENCH_GSL:
        if MatrixType.RowsAtCompileTime == Dynamic:
            timerSqrt.reset()
            var gslCovMat: gsl_matrix = gsl_matrix_alloc(covMat.rows(), covMat.cols())
            var gslCopy: gsl_matrix = gsl_matrix_alloc(covMat.rows(), covMat.cols())
            eiToGsl(covMat, &gslCovMat)
            for t in range(TRIES):
                timerSqrt.start()
                for k in range(repeats):
                    gsl_matrix_memcpy(gslCopy, gslCovMat)
                    gsl_linalg_cholesky_decomp(gslCopy)
                    acc += gsl_matrix_get(gslCopy, r, c)
                timerSqrt.stop()
            print(" | \t", timerSqrt.value() * REPEAT / repeats, "s", sep="", end="")
            gsl_matrix_free(gslCovMat)

    print("\n")
    if acc == 123:
        print(acc)

def main() raises:
    let dynsizes: List[Int] = List[Int](4, 6, 8, 16, 24, 32, 49, 64, 128, 256, 512, 900, 1500, 0)
    print("size            LDLT                            LLT")
    print("\n", end="")
    var i: Int = 0
    while dynsizes[i] > 0:
        benchLLT[Matrix[Scalar, Dynamic, Dynamic]](Matrix[Scalar, Dynamic, Dynamic](dynsizes[i], dynsizes[i]))
        i += 1
    benchLLT[Matrix[Scalar, 2, 2]](Matrix[Scalar, 2, 2]())
    benchLLT[Matrix[Scalar, 3, 3]](Matrix[Scalar, 3, 3]())
    benchLLT[Matrix[Scalar, 4, 4]](Matrix[Scalar, 4, 4]())
    benchLLT[Matrix[Scalar, 5, 5]](Matrix[Scalar, 5, 5]())
    benchLLT[Matrix[Scalar, 6, 6]](Matrix[Scalar, 6, 6]())
    benchLLT[Matrix[Scalar, 7, 7]](Matrix[Scalar, 7, 7]())
    benchLLT[Matrix[Scalar, 8, 8]](Matrix[Scalar, 8, 8]())
    benchLLT[Matrix[Scalar, 12, 12]](Matrix[Scalar, 12, 12]())
    benchLLT[Matrix[Scalar, 16, 16]](Matrix[Scalar, 16, 16]())