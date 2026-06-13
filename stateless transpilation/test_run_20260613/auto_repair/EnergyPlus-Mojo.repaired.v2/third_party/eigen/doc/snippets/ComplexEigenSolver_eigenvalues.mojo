from ...MatrixXcf import MatrixXcf
from ...ComplexEigenSolver import ComplexEigenSolver

var ones = MatrixXcf.Ones(3,3)
# /* computeEigenvectors = */ false
var ces = ComplexEigenSolver[MatrixXcf](ones, computeEigenvectors=False)
print("The eigenvalues of the 3x3 matrix of ones are:")
print(ces.eigenvalues())