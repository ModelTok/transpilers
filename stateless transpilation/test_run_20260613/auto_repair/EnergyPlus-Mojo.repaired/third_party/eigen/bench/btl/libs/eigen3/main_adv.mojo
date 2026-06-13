from utilities import *
from eigen3_interface import eigen3_interface
from bench import bench
from action_trisolve import Action_trisolve
from action_trisolve_matrix import Action_trisolve_matrix
from action_cholesky import Action_cholesky
from action_hessenberg import Action_hessenberg
from action_lu_decomp import Action_lu_decomp
from action_partial_lu import Action_partial_lu

def main() -> Int32:
  bench[Action_trisolve[eigen3_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
  bench[Action_trisolve_matrix[eigen3_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
  bench[Action_cholesky[eigen3_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
  bench[Action_partial_lu[eigen3_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
  bench[Action_tridiagonalization[eigen3_interface[REAL_TYPE]]](MIN_LU, MAX_LU, NB_POINT)
  return 0