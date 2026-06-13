from utilities import *
from eigen2_interface.hh import *
from ....hh import *
from basic_actions.hh import *
BTL_MAIN;
def main() -> Int32
{
  bench[Action_axpy[eigen2_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT);
  bench[Action_axpby[eigen2_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT);
  return 0;
}