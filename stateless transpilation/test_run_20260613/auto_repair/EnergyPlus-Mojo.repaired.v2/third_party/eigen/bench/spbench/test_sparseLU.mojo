from std import Int, Float64, String, Bool, print, assert
from std.fstream import Ifstream
from Eigen.SparseMatrix import SparseMatrix, ColMajor
from Eigen.Dense import Matrix, Dynamic
from Eigen.SparseLU import SparseLU
from Eigen.Ordering import COLAMDOrdering
from unsupported.Eigen.SparseExtra import loadMarket, getMarketHeader, loadMarketVector
from bench.BenchTimer import BenchTimer
from Eigen.SelfAdjointView import Lower

def main(argc: Int, args: List[String]) -> Int:
  alias scalar = Float64
  var A = SparseMatrix[scalar, ColMajor]()
  alias Index = SparseMatrix[scalar, ColMajor].Index
  alias DenseMatrix = Matrix[scalar, Dynamic, Dynamic]
  alias DenseRhs = Matrix[scalar, Dynamic, 1]
  var b = DenseRhs()
  var x = DenseRhs()
  var tmp = DenseRhs()
  var solver = SparseLU[SparseMatrix[scalar, ColMajor], COLAMDOrdering[Int]]()
  print("ORDERING : COLAMD")
  var matrix_file = Ifstream()
  var line = String()
  var n: Int
  var timer = BenchTimer()
  /* Fill the matrix with sparse matrix stored in Matrix-Market coordinate column-oriented format */
  if argc < 2:
    assert(False, "please, give the matrix market file ")
  loadMarket(A, args[1])
  print("End charging matrix ")
  var iscomplex = False
  var isvector = False
  var sym: Int
  getMarketHeader(args[1], sym, iscomplex, isvector)
  if isvector:
    print("The provided file is not a matrix file\n")
    return -1
  if sym != 0:  # symmetric matrices, only the lower part is stored
    var temp = SparseMatrix[scalar, ColMajor]()
    temp = A
    A = temp.selfadjointView[Lower]()
  n = A.cols()
  /* Fill the right hand side */
  if argc > 2:
    loadMarketVector(b, args[2])
  else:
    b.resize(n)
    tmp.resize(n)
    for i in range(n):
      tmp[i] = Float64(i)
    b = A * tmp
  /* Compute the factorization */
  timer.start()
  solver.analyzePattern(A)
  timer.stop()
  print("Time to analyze ", timer.value())
  timer.reset()
  timer.start()
  solver.factorize(A)
  timer.stop()
  print("Factorize Time ", timer.value())
  timer.reset()
  timer.start()
  x = solver.solve(b)
  timer.stop()
  print("solve time ", timer.value())
  /* Check the accuracy */
  var tmp2 = b - A * x
  var tempNorm = tmp2.norm() / b.norm()
  print("Relative norm of the computed solution : ", tempNorm, "\n")
  print("Number of nonzeros in the factor : ", solver.nnzL() + solver.nnzU())
  return 0