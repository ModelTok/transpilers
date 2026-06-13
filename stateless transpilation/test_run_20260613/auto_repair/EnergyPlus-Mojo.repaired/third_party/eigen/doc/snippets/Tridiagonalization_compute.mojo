from ...Eigen import Tridiagonalization, MatrixXf

var tri = Tridiagonalization[MatrixXf]()
var X = MatrixXf.Random(4, 4)
var A = X + X.transpose()
tri.compute(A)
print("The matrix T in the tridiagonal decomposition of A is: ")
print(tri.matrixT())
tri.compute(2 * A)
print("The matrix T in the tridiagonal decomposition of 2A is: ")
print(tri.matrixT())