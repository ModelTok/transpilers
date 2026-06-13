from utilities import *
from eigen3_interface import eigen2_interface
from static.bench_static import bench_static
from action_matrix_vector_product import *
from action_matrix_matrix_product import *
from action_axpy import *
from action_lu_solve import *
from action_ata_product import *
from action_aat_product import *
from action_atv_product import *
from action_cholesky import *
from action_trisolve import *

def main() -> Int32:
    bench_static[Action_axpy, eigen2_interface]()
    bench_static[Action_matrix_matrix_product, eigen2_interface]()
    bench_static[Action_matrix_vector_product, eigen2_interface]()
    bench_static[Action_atv_product, eigen2_interface]()
    bench_static[Action_cholesky, eigen2_interface]()
    bench_static[Action_trisolve, eigen2_interface]()
    return 0