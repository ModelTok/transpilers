from third_party.eigen.Eigen import Matrix3d, Random, colwise, sum, cwiseAbs, maxCoeff

var m = Matrix3d.Random()
print("Here is the matrix m:")
print(m)
print("Here is the sum of each column:")
print(m.colwise().sum())
print("Here is the maximum absolute value of each column:")
print(m.cwiseAbs().colwise().maxCoeff())