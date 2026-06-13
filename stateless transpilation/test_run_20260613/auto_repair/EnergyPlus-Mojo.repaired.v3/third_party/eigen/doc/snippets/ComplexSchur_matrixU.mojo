from Eigen import MatrixXcf, ComplexSchur

var A = MatrixXcf.Random(4, 4)
print("Here is a random 4x4 matrix, A:")
print(A)
print()
var schurOfA = ComplexSchur[MatrixXcf](A)
print("The unitary matrix U is:")
print(schurOfA.matrixU())