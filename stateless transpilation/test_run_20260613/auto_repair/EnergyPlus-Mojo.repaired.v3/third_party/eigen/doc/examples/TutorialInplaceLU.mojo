from memory import memset_zero
from sys import print
from math import sqrt
from Eigen.Dense import *

struct init:
    def __init__(inout self):
        print("[", "init", "]", sep="")

var init_obj = init()

def main() raises:
    var A = MatrixXd(2, 2)
    A << 2, -1, 1, 3
    print("Here is the input matrix A before decomposition:\n", A)
    print("[init]")
    print("[declaration]")
    var lu = PartialPivLU[Ref[MatrixXd]](A)
    print("Here is the input matrix A after decomposition:\n", A)
    print("[declaration]")
    print("[matrixLU]")
    print("Here is the matrix storing the L and U factors:\n", lu.matrixLU())
    print("[matrixLU]")
    print("[solve]")
    var A0 = MatrixXd(2, 2)
    A0 << 2, -1, 1, 3
    var b = VectorXd(2)
    b << 1, 2
    var x = lu.solve(b)
    print("Residual: ", (A0 * x - b).norm())
    print("[solve]")
    print("[modifyA]")
    A << 3, 4, -2, 1
    x = lu.solve(b)
    print("Residual: ", (A0 * x - b).norm())
    print("[modifyA]")
    print("[recompute]")
    A0 = A
    lu.compute(A)
    x = lu.solve(b)
    print("Residual: ", (A0 * x - b).norm())
    print("[recompute]")
    print("[recompute_bis0]")
    var A1 = MatrixXd(2, 2)
    A1 << 5, -2, 3, 4
    lu.compute(A1)
    print("Here is the input matrix A1 after decomposition:\n", A1)
    print("[recompute_bis0]")
    print("[recompute_bis1]")
    x = lu.solve(b)
    print("Residual: ", (A1 * x - b).norm())
    print("[recompute_bis1]")