from utilities import *
from eigen3_interface import *
from ... import *
from basic_actions import *

def main() -> Int32:
  bench[Action_matrix_matrix_product[eigen3_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_aat_product[eigen3_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_trmm[eigen3_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  return 0