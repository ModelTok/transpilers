from utilities import *
from eigen3_interface import *
from ... import *
from basic_actions import *

def main() -> Int32:
  bench[Action_axpy[eigen3_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
  bench[Action_axpby[eigen3_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
  bench[Action_rot[eigen3_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
  return 0