// Translation of sparse_lu.cpp to Mojo
// Preprocessor directives converted to Mojo constants/imports

from BenchSparseUtil import BenchTimer, EigenSparseMatrix, fillMatrix, eiToDense, DenseMatrix
from Eigen.LU import SparseLU, FullPivLU

alias EIGEN_SUPERLU_SUPPORT = True
alias EIGEN_UMFPACK_SUPPORT = True
alias SIZE = 10
alias DENSITY = 0.01
alias REPEAT = 1
alias MINDENSITY = 0.0004
alias NBTRIES = 10

// The following types are assumed to be defined in the imported modules
// Scalar, Dynamic, Matrix are from Eigen
alias Scalar = Float64
alias Dynamic = 0
alias VectorX = Matrix[Scalar, Dynamic, 1]

// Enum-like constants for backends (defined in Eigen)
alias EigenNaturalOrdering = 0
alias EigenColApproxMinimumDegree = 1

// Macro BENCH is defined but not used in this file, so omitted

def doEigen[Backend: Int](name: String, sm1: EigenSparseMatrix, b: VectorX, inout x: VectorX, flags: Int = 0):
    print(name, "...", end="", flush=True)
    var timer = BenchTimer()
    timer.start()
    var lu = SparseLU[EigenSparseMatrix, Backend](sm1, flags)
    timer.stop()
    if lu.succeeded():
        print(":\t", timer.value())
    else:
        print(":\t FAILED")
        return
    var ok: Bool
    timer.reset()
    timer.start()
    ok = lu.solve(b, x)
    timer.stop()
    if ok:
        print("  solve:\t", timer.value())
    else:
        print("  solve:\t FAILED")

def main(argc: Int, argv: List[String]):
    var rows = SIZE
    var cols = SIZE
    var density = DENSITY
    var timer = BenchTimer()
    var b = VectorX.Random(cols)
    var x = VectorX.Random(cols)
    var densedone = False
    var sm1 = EigenSparseMatrix(rows, cols)
    fillMatrix(density, rows, cols, sm1)
    #ifdef DENSEMATRIX  // DENSEMATRIX not defined in original, so this block is omitted in translation
    if not densedone:
        densedone = True
        print("Eigen Dense\t", density * 100, "%")
        var m1 = DenseMatrix(rows, cols)
        eiToDense(sm1, m1)
        timer.start()
        var lu = FullPivLU[DenseMatrix](m1)
        timer.stop()
        print("Eigen/dense:\t", timer.value())
        timer.reset()
        timer.start()
        lu.solve(b, x)
        timer.stop()
        print("  solve:\t", timer.value())
    #endif
    if EIGEN_UMFPACK_SUPPORT:
        x.setZero()
        doEigen[0]("Eigen/UmfPack (auto)", sm1, b, x, 0)  // Backend=0 corresponds to UmfPack
    if EIGEN_SUPERLU_SUPPORT:
        x.setZero()
        doEigen[1]("Eigen/SuperLU (nat)", sm1, b, x, EigenNaturalOrdering)
        doEigen[1]("Eigen/SuperLU (COLAMD)", sm1, b, x, EigenColApproxMinimumDegree)
    return 0