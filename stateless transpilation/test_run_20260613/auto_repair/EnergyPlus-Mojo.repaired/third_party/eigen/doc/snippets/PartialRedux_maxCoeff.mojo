from Eigen import Matrix3d

var m = Matrix3d.Random()
print("Here is the matrix m:")
print(m)
print("Here is the maximum of each column:")
print(m.colwise().maxCoeff())