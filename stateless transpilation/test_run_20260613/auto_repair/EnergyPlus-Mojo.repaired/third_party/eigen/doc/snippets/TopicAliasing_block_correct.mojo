from liblinalg import MatrixXi
from liblinalg import *
from builtin import print

var mat = MatrixXi(3, 3)
mat << 1, 2, 3, 4, 5, 6, 7, 8, 9
print("Here is the matrix mat:\n", mat, "\n")
mat.bottomRightCorner(2, 2) = mat.topLeftCorner(2, 2).eval()
print("After the assignment, mat = \n", mat, "\n")