from third_party.eigen.Eigen import Matrix3d, Matrix3d_Identity

var m = 10000 * Matrix3d_Identity()
m(0,2) = 1
print("Here's the matrix m:")
print(m)
print("m.isDiagonal() returns: ", m.isDiagonal())
print("m.isDiagonal(1e-3) returns: ", m.isDiagonal(1e-3))