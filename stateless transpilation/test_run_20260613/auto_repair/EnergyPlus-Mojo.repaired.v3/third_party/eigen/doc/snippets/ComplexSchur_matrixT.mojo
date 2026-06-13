# ComplexSchur_matrixT.cpp translated to Mojo

from Eigen import MatrixXcf, ComplexSchur

var A = MatrixXcf.Random(4, 4)
print("Here is a random 4x4 matrix, A:")
print(A)
print()
var schurOfA = ComplexSchur[MatrixXcf](A, False)  # false means do not compute U
print("The triangular matrix T is:")
print(schurOfA.matrixT())