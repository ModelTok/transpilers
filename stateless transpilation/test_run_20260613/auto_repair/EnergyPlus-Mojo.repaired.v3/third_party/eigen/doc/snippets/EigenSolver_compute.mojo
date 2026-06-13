from Eigen import EigenSolver, MatrixXf

var es: EigenSolver[MatrixXf]
var A = MatrixXf.Random(4,4)
es.compute(A, # computeEigenvectors = False)
print("The eigenvalues of A are: ", es.eigenvalues().transpose())
es.compute(A + MatrixXf.Identity(4,4), False)  # re-use es to compute eigenvalues of A+I
print("The eigenvalues of A+I are: ", es.eigenvalues().transpose())