from memory import memset_zero
from math import sqrt
from sys import print

const size = 6
var mat1 = MatrixXd(size, size)
mat1.topLeftCorner(size/2, size/2)     = MatrixXd.Zero(size/2, size/2)
mat1.topRightCorner(size/2, size/2)    = MatrixXd.Identity(size/2, size/2)
mat1.bottomLeftCorner(size/2, size/2)  = MatrixXd.Identity(size/2, size/2)
mat1.bottomRightCorner(size/2, size/2) = MatrixXd.Zero(size/2, size/2)
print(mat1)
print()
print()
var mat2 = MatrixXd(size, size)
mat2.topLeftCorner(size/2, size/2).setZero()
mat2.topRightCorner(size/2, size/2).setIdentity()
mat2.bottomLeftCorner(size/2, size/2).setIdentity()
mat2.bottomRightCorner(size/2, size/2).setZero()
print(mat2)
print()
print()
var mat3 = MatrixXd(size, size)
mat3 << MatrixXd.Zero(size/2, size/2), MatrixXd.Identity(size/2, size/2),
        MatrixXd.Identity(size/2, size/2), MatrixXd.Zero(size/2, size/2)
print(mat3)