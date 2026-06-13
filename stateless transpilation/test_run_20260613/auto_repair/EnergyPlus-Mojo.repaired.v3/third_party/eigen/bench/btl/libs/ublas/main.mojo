from utilities import *
from ublas_interface.mojo import ublas_interface
from ....mojo import bench
from basic_actions.mojo import *
BTL_MAIN;
def main() -> Int32:
  bench[Action_axpy[ublas_interface[REAL_TYPE]]](MIN_AXPY,MAX_AXPY,NB_POINT)
  bench[Action_axpby[ublas_interface[REAL_TYPE]]](MIN_AXPY,MAX_AXPY,NB_POINT)
  bench[Action_matrix_vector_product[ublas_interface[REAL_TYPE]]](MIN_MV,MAX_MV,NB_POINT)
  bench[Action_atv_product[ublas_interface[REAL_TYPE]]](MIN_MV,MAX_MV,NB_POINT)
  bench[Action_matrix_matrix_product[ublas_interface[REAL_TYPE]]](MIN_MM,MAX_MM,NB_POINT)
  bench[Action_trisolve[ublas_interface[REAL_TYPE]]](MIN_MM,MAX_MM,NB_POINT)
  return 0