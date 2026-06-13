from BenchSparseUtil import *
from Eigen.Sparse import *
from Eigen.Cholesky import *
from iostream import *
from BenchTimer import *

# define SIZE 10
# define DENSITY 0.01
# define REPEAT 1
# define MINDENSITY 0.0004
# define NBTRIES 10

# define BENCH(X) \
#   timer.reset(); \
#   for (int _j=0; _j<NBTRIES; ++_j) { \
#     timer.start(); \
#     for (int _k=0; _k<REPEAT; ++_k) { \
#         X  \
#   } timer.stop(); }

alias EigenSparseSelfAdjointMatrix = SparseMatrix[Scalar, SelfAdjoint | LowerTriangular]

def fillSpdMatrix(density: float, rows: int, cols: int, dst: EigenSparseSelfAdjointMatrix):
    dst.startFill(rows * cols * density)
    for j in range(cols):
        dst.fill(j, j) = internal.random[Scalar](10, 20)
        for i in range(j + 1, rows):
            Scalar v = (internal.random[float](0, 1) < density) ? internal.random[Scalar]() : 0
            if v != 0:
                dst.fill(i, j) = v
    dst.endFill()

def doEigen[Backend: int](name: String, sm1: EigenSparseSelfAdjointMatrix, flags: int = 0):
    print(name, "...", end="", flush=True)
    var timer = BenchTimer()
    timer.start()
    var chol = SparseLLT[EigenSparseSelfAdjointMatrix, Backend](sm1, flags)
    timer.stop()
    print(":\t", timer.value())
    print("  nnz: ", sm1.nonZeros(), " => ", chol.matrixL().nonZeros())

def main(argc: int, argv: Pointer[Pointer[UInt8]]):
    var rows = SIZE
    var cols = SIZE
    var density = DENSITY
    var timer = BenchTimer()
    var b = VectorXf.Random(cols)
    var x = VectorXf.Random(cols)
    var densedone = False
    {
        var sm1 = EigenSparseSelfAdjointMatrix(rows, cols)
        print("Generate sparse matrix (might take a while)...")
        fillSpdMatrix(density, rows, cols, sm1)
        print("DONE\n")
        #ifdef DENSEMATRIX
        if not densedone:
            densedone = True
            print("Eigen Dense\t", density * 100, "%")
            var m1 = DenseMatrix(rows, cols)
            eiToDense(sm1, m1)
            m1 = (m1 + m1.transpose()).eval()
            m1.diagonal() *= 0.5
            var timer = BenchTimer()
            timer.start()
            var chol = LLT[DenseMatrix](m1)
            timer.stop()
            print("dense:\t", timer.value())
            var count = 0
            for j in range(cols):
                for i in range(j, rows):
                    if not internal.isMuchSmallerThan(internal.abs(chol.matrixL()(i, j)), 0.1):
                        count += 1
            print("dense: ", "nnz = ", count)
        #endif
        doEigen[Eigen.DefaultBackend]("Eigen/Sparse", sm1, Eigen.IncompleteFactorization)
        #ifdef EIGEN_CHOLMOD_SUPPORT
        doEigen[Eigen.Cholmod]("Eigen/Cholmod", sm1, Eigen.IncompleteFactorization)
        #endif
        #ifdef EIGEN_TAUCS_SUPPORT
        doEigen[Eigen.Taucs]("Eigen/Taucs", sm1, Eigen.IncompleteFactorization)
        #endif
        #if 0
        {
            var A = sm1.asTaucsMatrix()
            var chol = taucs_ccs_factor_llt(&A, 0, 0)
            for j in range(cols):
                for i in range(chol.colptr[j], chol.colptr[j + 1]):
                    print(chol.values.d[i], " ")
        }
        #ifdef EIGEN_CHOLMOD_SUPPORT
        {
            var c = cholmod_common()
            cholmod_start(&c)
            var A = cholmod_sparse()
            var L = cholmod_factor()
            A = sm1.asCholmodMatrix()
            var timer = BenchTimer()
            timer.start()
            var perm = Vector[int](cols)
            for i in range(cols):
                perm[i] = i
            c.nmethods = 1
            c.method[0].ordering = CHOLMOD_NATURAL
            c.postorder = 0
            c.final_ll = 1
            L = cholmod_analyze_p(&A, &perm[0], &perm[0], cols, &c)
            timer.stop()
            print("cholmod/analyze:\t", timer.value())
            timer.reset()
            timer.start()
            cholmod_factorize(&A, L, &c)
            timer.stop()
            print("cholmod/factorize:\t", timer.value())
            var cholmat = cholmod_factor_to_sparse(L, &c)
            cholmod_print_factor(L, "Factors", &c)
            cholmod_print_sparse(cholmat, "Chol", &c)
            cholmod_write_sparse(stdout, cholmat, 0, 0, &c)
        }
        #endif
        #endif
    }
    return 0