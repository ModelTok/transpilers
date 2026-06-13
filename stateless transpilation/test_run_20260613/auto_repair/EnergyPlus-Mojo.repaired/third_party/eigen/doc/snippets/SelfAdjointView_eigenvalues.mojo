var ones: MatrixXd = MatrixXd.Ones(3,3)
var eivals: VectorXd = ones.selfadjointView[Lower]().eigenvalues()
print("The eigenvalues of the 3x3 matrix of ones are:")
print(eivals)