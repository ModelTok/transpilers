from utilities import MIN_AXPY, MAX_AXPY, NB_POINT, MIN_MV, MAX_MV, REAL_TYPE, BTL_MAIN
from blaze_interface import blaze_interface
from bench import bench
from basic_actions import Action_axpy, Action_axpby, Action_matrix_vector_product, Action_atv_product

BTL_MAIN;

def main() -> Int32:
    bench[Action_axpy[blaze_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[blaze_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_vector_product[blaze_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[blaze_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    return 0