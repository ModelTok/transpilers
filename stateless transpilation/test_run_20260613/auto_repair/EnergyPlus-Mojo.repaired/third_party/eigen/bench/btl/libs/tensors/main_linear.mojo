from utilities import *
from tensor_interface import tensor_interface
from bench import bench
from basic_actions import Action_axpy, Action_axpby

def main() -> Int32:
    bench[Action_axpy[tensor_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    bench[Action_axpby[tensor_interface[REAL_TYPE]]](MIN_AXPY, MAX_AXPY, NB_POINT)
    return 0