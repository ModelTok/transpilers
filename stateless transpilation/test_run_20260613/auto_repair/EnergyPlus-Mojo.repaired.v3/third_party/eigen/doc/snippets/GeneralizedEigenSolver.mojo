from Eigen import GeneralizedEigenSolver, MatrixXf

var ges: GeneralizedEigenSolver[MatrixXf]
var A: MatrixXf = MatrixXf.Random(4, 4)
var B: MatrixXf = MatrixXf.Random(4, 4)
ges.compute(A, B)
print("The (complex) numerators of the generalzied eigenvalues are: ", ges.alphas().transpose())
print("The (real) denominatore of the generalzied eigenvalues are: ", ges.betas().transpose())
print("The (complex) generalzied eigenvalues are (alphas./beta): ", ges.eigenvalues().transpose())