from sparse_solver import SparseMatrix, SimplicialCholesky, SimplicialLLT, SimplicialLDLT, NaturalOrdering, Lower, Upper, check_sparse_spd_solving, check_sparse_spd_determinant

def test_simplicial_cholesky_T[type T, type I]():
    alias SparseMatrixType = SparseMatrix[T, 0, I]
    var chol_colmajor_lower_amd: SimplicialCholesky[SparseMatrixType, Lower] = SimplicialCholesky[SparseMatrixType, Lower]()
    var chol_colmajor_upper_amd: SimplicialCholesky[SparseMatrixType, Upper] = SimplicialCholesky[SparseMatrixType, Upper]()
    var llt_colmajor_lower_amd: SimplicialLLT[SparseMatrixType, Lower] = SimplicialLLT[SparseMatrixType, Lower]()
    var llt_colmajor_upper_amd: SimplicialLLT[SparseMatrixType, Upper] = SimplicialLLT[SparseMatrixType, Upper]()
    var ldlt_colmajor_lower_amd: SimplicialLDLT[SparseMatrixType, Lower] = SimplicialLDLT[SparseMatrixType, Lower]()
    var ldlt_colmajor_upper_amd: SimplicialLDLT[SparseMatrixType, Upper] = SimplicialLDLT[SparseMatrixType, Upper]()
    var ldlt_colmajor_lower_nat: SimplicialLDLT[SparseMatrixType, Lower, NaturalOrdering[I]] = SimplicialLDLT[SparseMatrixType, Lower, NaturalOrdering[I]]()
    var ldlt_colmajor_upper_nat: SimplicialLDLT[SparseMatrixType, Upper, NaturalOrdering[I]] = SimplicialLDLT[SparseMatrixType, Upper, NaturalOrdering[I]]()
    check_sparse_spd_solving(chol_colmajor_lower_amd)
    check_sparse_spd_solving(chol_colmajor_upper_amd)
    check_sparse_spd_solving(llt_colmajor_lower_amd)
    check_sparse_spd_solving(llt_colmajor_upper_amd)
    check_sparse_spd_solving(ldlt_colmajor_lower_amd)
    check_sparse_spd_solving(ldlt_colmajor_upper_amd)
    check_sparse_spd_determinant(chol_colmajor_lower_amd)
    check_sparse_spd_determinant(chol_colmajor_upper_amd)
    check_sparse_spd_determinant(llt_colmajor_lower_amd)
    check_sparse_spd_determinant(llt_colmajor_upper_amd)
    check_sparse_spd_determinant(ldlt_colmajor_lower_amd)
    check_sparse_spd_determinant(ldlt_colmajor_upper_amd)
    check_sparse_spd_solving(ldlt_colmajor_lower_nat, 300, 1000)
    check_sparse_spd_solving(ldlt_colmajor_upper_nat, 300, 1000)

def test_simplicial_cholesky():
    # CALL_SUBTEST_1(( test_simplicial_cholesky_T<double,int>() ));
    test_simplicial_cholesky_T[Float64, Int]()
    # CALL_SUBTEST_2(( test_simplicial_cholesky_T<complex<double>, int>() ));
    test_simplicial_cholesky_T[ComplexFloat64, Int]()
    # CALL_SUBTEST_3(( test_simplicial_cholesky_T<double,long int>() ));
    test_simplicial_cholesky_T[Float64, Int64]()