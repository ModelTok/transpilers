from utils import print
from sys import info

from Eigen.Dense import MatrixXf

def main():
    m = MatrixXf(3, 3)
    m << 1, 2, 3,
         4, 5, 6,
         7, 8, 9
    print("Here is the matrix m:", m)
    print("2nd Row: ", m.row(1))
    m.col(2) += 3 * m.col(0)
    print("After adding 3 times the first column into the third column, the matrix m is:\n")
    print(m)