from third_party.eigen.Eigen import MatrixXf, RealSchur

var A = MatrixXf.Random(4, 4)
var schur = RealSchur[MatrixXf](4)
schur.compute(A, False)
print("The matrix T in the decomposition of A is:")
print(schur.matrixT())
schur.compute(A.inverse(), False)
print("The matrix T in the decomposition of A^(-1) is:")
print(schur.matrixT())