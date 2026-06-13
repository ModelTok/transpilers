# 1:1 translation from C++ to Mojo, no refactoring
from utilities import MIN_AXPY, MAX_AXPY, NB_POINT, MIN_MV, MAX_MV, MIN_MM, MAX_MM, REAL_TYPE
from gmm_interface import gmm_interface
from ... import bench
from basic_actions import Action_axpy, Action_axpby, Action_matrix_vector_product, Action_atv_product, Action_matrix_matrix_product, Action_trisolve, Action_tridiagonalization
from action_hessenberg import Action_hessenberg
from action_partial_lu import Action_partial_lu

# BTL_MAIN equivalent
def main():
    bench[Action_axpy[gmm_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[gmm_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_vector_product[gmm_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[gmm_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_matrix_matrix_product[gmm_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_trisolve[gmm_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_partial_lu[gmm_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_hessenberg[gmm_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_tridiagonalization[gmm_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    return 0