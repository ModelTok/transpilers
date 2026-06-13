from sparse_solver import check_sparse_square_solving, CALL_SUBTEST_1
from ...Eigen.SparseLU import SparseLU, SparseMatrix, ColMajor
from ...Eigen.MetisSupport import MetisOrdering
from ...unsupported.Eigen.SparseExtra import *

def test_metis_T[T: AnyType]():
    var sparselu_metis = SparseLU[SparseMatrix[T, ColMajor], MetisOrdering[Int]]()
    check_sparse_square_solving(sparselu_metis)

def test_metis_support():
    CALL_SUBTEST_1(test_metis_T[Float64]())