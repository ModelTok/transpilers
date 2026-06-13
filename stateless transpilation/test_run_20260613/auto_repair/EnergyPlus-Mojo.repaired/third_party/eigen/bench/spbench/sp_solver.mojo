from iostream import cout, endl
from fstream import ifstream
from iomanip import setprecision  # unused but kept for consistency
from Eigen.Jacobi import *
from Eigen.Householder import *
from Eigen.IterativeLinearSolvers import ConjugateGradient, IncompleteCholesky, Success
from Eigen.LU import *
from unsupported.Eigen.SparseExtra import loadMarket, getMarketHeader, loadMarketVector
from Eigen.SuperLUSupport import *
from bench.BenchTimer import BenchTimer
from unsupported.Eigen.IterativeSolvers import *
from Eigen import SparseMatrix, Matrix, VectorXd, Lower, ColMajor, Dynamic

def main(argv: List[String]):
    var A: SparseMatrix[Float64, ColMajor]
    alias Index = SparseMatrix[Float64, ColMajor].Index
    alias DenseMatrix = Matrix[Float64, Dynamic, Dynamic]
    alias DenseRhs = Matrix[Float64, Dynamic, 1]
    var b: VectorXd
    var x: VectorXd
    var tmp: VectorXd
    var timer = BenchTimer()
    var totaltime = BenchTimer()
    var solver = ConjugateGradient[SparseMatrix[Float64, ColMajor], Lower, IncompleteCholesky[Float64, Lower]]()
    var matrix_file: ifstream
    var line: String
    var n: Int

    /* Fill the matrix with sparse matrix stored in Matrix-Market coordinate column-oriented format */
    if len(argv) < 2:
        assert(False, "please, give the matrix market file ")
    timer.start()
    totaltime.start()
    loadMarket(A, argv[1])
    print("End charging matrix ")
    var iscomplex = False
    var isvector = False
    var sym: Int
    getMarketHeader(argv[1], sym, iscomplex, isvector)
    if iscomplex:
        print(" Not for complex matrices ")
        return -1
    if isvector:
        print("The provided file is not a matrix file\n")
        return -1
    if sym != 0:  # symmetric matrices, only the lower part is stored
        var temp: SparseMatrix[Float64, ColMajor]
        temp = A
        A = temp.selfadjointView[Lower]()
    timer.stop()
    n = A.cols()
    print("Time to load the matrix ", timer.value())
    /* Fill the right hand side */
    if len(argv) > 2:
        loadMarketVector(b, argv[2])
    else:
        b.resize(n)
        tmp.resize(n)
        for i in range(n):
            tmp[i] = i
        b = A * tmp
    /* Compute the factorization */
    print("Starting the factorization ")
    timer.reset()
    timer.start()
    print("Size of Input Matrix ", b.size(), "\n\n")
    print("Rows and columns ", A.rows(), " ", A.cols(), "\n")
    solver.compute(A)
    if solver.info() != Success:
        cout << "The solver failed \n"
        return -1
    timer.stop()
    var time_comp = timer.value()
    print(" Compute Time ", time_comp)
    timer.reset()
    timer.start()
    x = solver.solve(b)
    timer.stop()
    var time_solve = timer.value()
    print(" Time to solve ", time_solve)
    /* Check the accuracy */
    var tmp2 = b - A * x
    var tempNorm = tmp2.norm() / b.norm()
    print("Relative norm of the computed solution : ", tempNorm)
    totaltime.stop()
    print("Total time ", totaltime.value())
    return 0