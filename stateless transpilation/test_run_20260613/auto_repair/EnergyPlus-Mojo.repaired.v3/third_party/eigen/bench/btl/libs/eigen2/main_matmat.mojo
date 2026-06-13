from utilities import *
from eigen2_interface import eigen2_interface
from ... import bench
from basic_actions import Action_matrix_matrix_product, Action_aat_product

def main() -> Int32:
  bench[Action_matrix_matrix_product[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_aat_product[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  return 0