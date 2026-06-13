from utilities import *
from STL_interface import STL_interface
from ... import bench
from basic_actions import Action_axpy, Action_axpby, Action_matrix_vector_product, Action_atv_product, Action_symv, Action_syr2, Action_matrix_matrix_product, Action_ata_product, Action_aat_product
from ....hh import BTL_MAIN

def main() -> Int32:
    bench[Action_axpy[STL_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[STL_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_matrix_vector_product[STL_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_atv_product[STL_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_symv[STL_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_syr2[STL_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    bench[Action_matrix_matrix_product[STL_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_ata_product[STL_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    bench[Action_aat_product[STL_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    return 0