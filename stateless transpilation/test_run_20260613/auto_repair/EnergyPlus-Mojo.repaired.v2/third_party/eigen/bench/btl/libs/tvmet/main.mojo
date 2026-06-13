from utilities import *
from tvmet_interface import tvmet_interface
from static.bench_static import bench_static
from action_matrix_vector_product import Action_matrix_vector_product
from action_matrix_matrix_product import Action_matrix_matrix_product
from action_atv_product import Action_atv_product
from action_axpy import Action_axpy

def main() -> Int32:
    bench_static[Action_axpy, tvmet_interface]()
    bench_static[Action_matrix_matrix_product, tvmet_interface]()
    bench_static[Action_matrix_vector_product, tvmet_interface]()
    bench_static[Action_atv_product, tvmet_interface]()
    return 0