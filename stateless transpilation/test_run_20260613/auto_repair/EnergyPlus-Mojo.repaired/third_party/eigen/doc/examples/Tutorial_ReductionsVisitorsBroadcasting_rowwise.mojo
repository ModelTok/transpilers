from memory import memset_zero
from sys import print as std_cout
from eigen import MatrixXf

def main() raises:
    var mat = MatrixXf(2, 4)
    mat << 1, 2, 6, 9,
           3, 1, 7, 2
    std_cout("Row's maximum: ", "\n",
        mat.rowwise().maxCoeff(), "\n")