from utilities import REAL_TYPE, MIN_MV, MAX_MV, NB_POINT
from tensor_interface import tensor_interface
from bench import bench
from basic_actions import Action_matrix_vector_product

## BTL_MAIN;
def main() -> Int:
    bench[Action_matrix_vector_product[tensor_interface[REAL_TYPE]]](MIN_MV, MAX_MV, NB_POINT)
    return 0