// #ifdef EIGEN_DEFAULT_TO_ROW_MAJOR
// #undef EIGEN_DEFAULT_TO_ROW_MAJOR
// #endif
from sparse_solver import *
from ...Eigen.SparseLU import SparseLU
from ...unsupported.Eigen.SparseExtra import *

def test_sparselu_T[type: AnyType]():
    var sparselu_colamd = SparseLU[SparseMatrix[type, ColMajor] /*, COLAMDOrdering[int]*/]()
    var sparselu_amd = SparseLU[SparseMatrix[type, ColMajor], AMDOrdering[int]]()
    var sparselu_natural = SparseLU[SparseMatrix[type, ColMajor, Int64], NaturalOrdering[Int64]]()
    check_sparse_square_solving(sparselu_colamd, 300, 100000, true)
    check_sparse_square_solving(sparselu_amd, 300, 10000, true)
    check_sparse_square_solving(sparselu_natural, 300, 2000, true)
    check_sparse_square_abs_determinant(sparselu_colamd)
    check_sparse_square_abs_determinant(sparselu_amd)
    check_sparse_square_determinant(sparselu_colamd)
    check_sparse_square_determinant(sparselu_amd)

def test_sparselu():
    test_sparselu_T[Float32]()
    test_sparselu_T[Float64]()
    test_sparselu_T[Complex[Float32]]()
    test_sparselu_T[Complex[Float64]]()