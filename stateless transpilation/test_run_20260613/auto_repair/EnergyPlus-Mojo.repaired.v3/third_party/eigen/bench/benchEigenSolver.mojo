// This is a faithful 1:1 translation from C++ to Mojo.
// Assumes corresponding Mojo modules exist for Eigen and bench utilities.

from Eigen import (Matrix, SelfAdjointEigenSolver, EigenSolver, internal, Dynamic)
from .BenchUtil import BenchTimer
from math import sqrt

alias REPEAT = 1000
alias TRIES = 4
alias SCALAR = FloatLiteral  # placeholder; original uses float
alias Scalar = SCALAR

@noinline
def benchEigenSolver[MatrixType: AnyType](m: MatrixType):
    var rows = m.rows()
    var cols = m.cols()
    var stdRepeats = max(1, int((REPEAT * 1000) / (rows * rows * sqrt(rows))))
    var saRepeats = stdRepeats * 4
    alias Scalar = MatrixType.Scalar
    alias SquareMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var a = MatrixType.Random(rows, cols)
    var covMat = a * a.adjoint()
    var timerSa = BenchTimer()
    var timerStd = BenchTimer()
    var acc: Scalar = 0.0
    var r = internal.random[Int](0, covMat.rows()-1)
    var c = internal.random[Int](0, covMat.cols()-1)
    {
        var ei = SelfAdjointEigenSolver[SquareMatrixType](covMat)
        for t in range(TRIES):
            timerSa.start()
            for k in range(saRepeats):
                ei.compute(covMat)
                acc += ei.eigenvectors().coeff(r, c)
            timerSa.stop()
    }
    {
        var ei = EigenSolver[SquareMatrixType](covMat)
        for t in range(TRIES):
            timerStd.start()
            for k in range(stdRepeats):
                ei.compute(covMat)
                acc += ei.eigenvectors().coeff(r, c)
            timerStd.stop()
    }
    if MatrixType.RowsAtCompileTime == Dynamic:
        print("dyn   ", end="")
    else:
        print("fixed ", end="")
    print(covMat.rows(), " \t",
          timerSa.value() * REPEAT / saRepeats, "s \t",
          timerStd.value() * REPEAT / stdRepeats, "s", end="")
    #ifdef BENCH_GMM
    @parameter if False:
        if MatrixType.RowsAtCompileTime == Dynamic:
            timerSa.reset()
            timerStd.reset()
            gmmCovMat = gmm_dense_matrix[Scalar](covMat.rows(), covMat.cols())
            eigvect = gmm_dense_matrix[Scalar](covMat.rows(), covMat.cols())
            eigval = std_vector[Scalar](covMat.rows())
            eiToGmm(covMat, gmmCovMat)
            for t in range(TRIES):
                timerSa.start()
                for k in range(saRepeats):
                    gmm.symmetric_qr_algorithm(gmmCovMat, eigval, eigvect)
                    acc += eigvect(r, c)
                timerSa.stop()
            print(" | \t",
                  timerSa.value() * REPEAT / saRepeats, "s",
                  "   na   ", end="")
    #endif
    #ifdef BENCH_GSL
    @parameter if False:
        if MatrixType.RowsAtCompileTime == Dynamic:
            timerSa.reset()
            timerStd.reset()
            gslCovMat = gsl_matrix_alloc(covMat.rows(), covMat.cols())
            gslCopy = gsl_matrix_alloc(covMat.rows(), covMat.cols())
            eigvect = gsl_matrix_alloc(covMat.rows(), covMat.cols())
            eigval = gsl_vector_alloc(covMat.rows())
            eisymm = gsl_eigen_symmv_alloc(covMat.rows())
            eigvectz = gsl_matrix_complex_alloc(covMat.rows(), covMat.cols())
            eigvalz = gsl_vector_complex_alloc(covMat.rows())
            einonsymm = gsl_eigen_nonsymmv_alloc(covMat.rows())
            eiToGsl(covMat, &gslCovMat)
            for t in range(TRIES):
                timerSa.start()
                for k in range(saRepeats):
                    gsl_matrix_memcpy(gslCopy, gslCovMat)
                    gsl_eigen_symmv(gslCopy, eigval, eigvect, eisymm)
                    acc += gsl_matrix_get(eigvect, r, c)
                timerSa.stop()
            for t in range(TRIES):
                timerStd.start()
                for k in range(stdRepeats):
                    gsl_matrix_memcpy(gslCopy, gslCovMat)
                    gsl_eigen_nonsymmv(gslCopy, eigvalz, eigvectz, einonsymm)
                    acc += GSL_REAL(gsl_matrix_complex_get(eigvectz, r, c))
                timerStd.stop()
            print(" | \t",
                  timerSa.value() * REPEAT / saRepeats, "s \t",
                  timerStd.value() * REPEAT / stdRepeats, "s", end="")
            gsl_matrix_free(gslCovMat)
            gsl_vector_free(gslCopy)
            gsl_matrix_free(eigvect)
            gsl_vector_free(eigval)
            gsl_matrix_complex_free(eigvectz)
            gsl_vector_complex_free(eigvalz)
            gsl_eigen_symmv_free(eisymm)
            gsl_eigen_nonsymmv_free(einonsymm)
    #endif
    print("\n", end="")
    if acc == 123:
        print(acc)

def main():
    var dynsizes = [4, 6, 8, 12, 16, 24, 32, 64, 128, 256, 512, 0]
    print("size            selfadjoint       generic", end="")
    #ifdef BENCH_GMM
    @parameter if False:
        print("        GMM++          ", end="")
    #endif
    #ifdef BENCH_GSL
    @parameter if False:
        print("       GSL (double + ATLAS)  ", end="")
    #endif
    print("\n", end="")
    for i in range(len(dynsizes)):
        if dynsizes[i] > 0:
            benchEigenSolver(Matrix[Scalar, Dynamic, Dynamic](dynsizes[i], dynsizes[i]))
    benchEigenSolver(Matrix[Scalar, 2, 2]())
    benchEigenSolver(Matrix[Scalar, 3, 3]())
    benchEigenSolver(Matrix[Scalar, 4, 4]())
    benchEigenSolver(Matrix[Scalar, 6, 6]())
    benchEigenSolver(Matrix[Scalar, 8, 8]())
    benchEigenSolver(Matrix[Scalar, 12, 12]())
    benchEigenSolver(Matrix[Scalar, 16, 16]())