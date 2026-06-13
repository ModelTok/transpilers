from utilities import *
from mtl4_interface import *
from ... import *
from basic_actions import *
from action_cholesky import *

BTL_MAIN;
def main() -> Int32:
    bench[Action_axpy[mtl4_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[mtl4_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_vector_product[mtl4_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[mtl4_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_matrix_matrix_product[mtl4_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_trisolve[mtl4_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    return 0