from utilities import *
from eigen3_interface import eigen2_interface
from static.bench_static import bench_static
from action_matrix_vector_product import Action_matrix_vector_product
from action_matrix_matrix_product import Action_matrix_matrix_product
from action_axpy import Action_axpy
from action_lu_solve import Action_lu_solve
from action_ata_product import Action_ata_product
from action_aat_product import Action_aat_product
from action_atv_product import Action_atv_product
from action_cholesky import Action_cholesky
from action_trisolve import Action_trisolve

def main() -> Int32:
    bench_static[Action_axpy, eigen2_interface]()
    bench_static[Action_matrix_matrix_product, eigen2_interface]()
    bench_static[Action_matrix_vector_product, eigen2_interface]()
    bench_static[Action_atv_product, eigen2_interface]()
    bench_static[Action_cholesky, eigen2_interface]()
    bench_static[Action_trisolve, eigen2_interface]()
    return 0