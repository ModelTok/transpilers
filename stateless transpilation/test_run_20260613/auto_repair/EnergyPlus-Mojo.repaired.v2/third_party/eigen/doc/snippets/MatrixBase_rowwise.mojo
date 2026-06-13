from Eigen import Matrix3d, Random, rowwise, sum, cwiseAbs, maxCoeff

var m = Matrix3d.Random()
print("Here is the matrix m:")
print(m)
print("Here is the sum of each row:")
print(m.rowwise().sum())
print("Here is the maximum absolute value of each row:")
print(m.cwiseAbs().rowwise().maxCoeff())