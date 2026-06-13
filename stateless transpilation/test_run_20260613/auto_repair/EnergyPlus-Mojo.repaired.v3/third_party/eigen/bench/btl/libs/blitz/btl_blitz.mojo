from utilities import *
from blitz_interface import *
from blitz_LU_solve_interface import *
from ... import *
from action_matrix_vector_product import *
from action_matrix_matrix_product import *
from action_axpy import *
from action_lu_solve import *
from action_ata_product import *
from action_aat_product import *
from action_atv_product import *

BTL_MAIN;

def main():
    bench[Action_matrix_vector_product[blitz_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[blitz_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_matrix_matrix_product[blitz_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_ata_product[blitz_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_aat_product[blitz_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_axpy[blitz_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    return 0