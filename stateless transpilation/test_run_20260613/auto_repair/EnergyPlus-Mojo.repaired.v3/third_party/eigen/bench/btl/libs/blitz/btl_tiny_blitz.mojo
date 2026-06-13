from utilities import *
from tiny_blitz_interface import tiny_blitz_interface
from static.bench_static import bench_static
from action_matrix_vector_product import Action_matrix_vector_product
from action_matrix_matrix_product import Action_matrix_matrix_product
from action_axpy import Action_axpy

# BTL_MAIN
def main() -> Int32:
    bench_static[Action_axpy, tiny_blitz_interface]()
    bench_static[Action_matrix_matrix_product, tiny_blitz_interface]()
    bench_static[Action_matrix_vector_product, tiny_blitz_interface]()
    return 0