from utilities import *
from tensor_interface import *
from bench import *
from basic_actions import *

def main() raises:
    bench[Action_matrix_matrix_product[tensor_interface[REAL_TYPE]]](MIN_MM, MAX_MM, NB_POINT)
    return