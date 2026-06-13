from utilities import *
from eigen3_interface import *
from ... import *
from basic_actions import *

def main() -> Int32:
  bench[Action_matrix_vector_product[eigen3_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  bench[Action_atv_product[eigen3_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  bench[Action_symv[eigen3_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  bench[Action_syr2[eigen3_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  bench[Action_ger[eigen3_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  return 0