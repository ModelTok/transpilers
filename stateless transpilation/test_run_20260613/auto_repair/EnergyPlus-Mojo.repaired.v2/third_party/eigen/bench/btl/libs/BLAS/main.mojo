from utilities import *
from blas_interface import blas_interface
from bench import bench
from basic_actions import (
    Action_axpy,
    Action_axpby,
    Action_matrix_vector_product,
    Action_atv_product,
    Action_symv,
    Action_syr2,
    Action_ger,
    Action_rot,
    Action_matrix_matrix_product,
    Action_aat_product,
    Action_trisolve,
    Action_trisolve_matrix,
    Action_trmm,
)
from action_cholesky import Action_cholesky
from action_lu_decomp import Action_lu_decomp
from action_partial_lu import Action_partial_lu
from action_trisolve_matrix import Action_trisolve_matrix

# ifdef HAS_LAPACK
alias HAS_LAPACK = True  # placeholder – set as needed
@parameter
if HAS_LAPACK:
    from action_hessenberg import Action_hessenberg, Action_tridiagonalization
# endif

BTL_MAIN()

def main() -> Int32:
    bench[Action_axpy[blas_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[blas_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_vector_product[blas_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[blas_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_symv[blas_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_syr2[blas_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_ger[blas_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_rot[blas_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_matrix_product[blas_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_aat_product[blas_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_trisolve[blas_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_trisolve_matrix[blas_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_trmm[blas_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_cholesky[blas_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
    bench[Action_partial_lu[blas_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
    @parameter
    if HAS_LAPACK:
        bench[Action_hessenberg[blas_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
        bench[Action_tridiagonalization[blas_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
    return 0