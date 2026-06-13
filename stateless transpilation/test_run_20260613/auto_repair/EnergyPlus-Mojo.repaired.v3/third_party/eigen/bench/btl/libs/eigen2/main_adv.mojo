from utilities import *
from eigen2_interface import *
from ... import *
from action_trisolve import *
from action_trisolve_matrix import *
from action_cholesky import *
from action_hessenberg import *
from action_lu_decomp import *

BTL_MAIN;
def main():
  bench[Action_trisolve[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_trisolve_matrix[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_cholesky[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_lu_decomp[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_hessenberg[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  bench[Action_tridiagonalization[eigen2_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
  return 0