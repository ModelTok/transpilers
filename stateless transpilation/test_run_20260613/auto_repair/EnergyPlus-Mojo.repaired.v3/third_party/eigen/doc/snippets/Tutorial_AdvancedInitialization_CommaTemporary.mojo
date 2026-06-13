from memory import memset_zero
from random import random_float64

def main() raises:
    var mat = MatrixXf.Random(2, 3)
    print(mat)
    print()
    print()
    mat = (MatrixXf(2,2) << 0, 1, 1, 0).finished() * mat
    print(mat)