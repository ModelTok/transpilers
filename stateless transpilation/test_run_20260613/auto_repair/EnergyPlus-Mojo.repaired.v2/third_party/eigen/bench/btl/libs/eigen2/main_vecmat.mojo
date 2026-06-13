from utilities import *
from eigen2_interface import eigen2_interface
from bench import bench
from basic_actions import Action_matrix_vector_product, Action_atv_product

def main() -> Int32:
  bench[Action_matrix_vector_product[eigen2_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  bench[Action_atv_product[eigen2_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
  return 0