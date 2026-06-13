from third_party.eigen.Eigen import Matrix3d, Matrix3dZero

var m = Matrix3dZero()
m[0, 2] = 1e-4
print("Here's the matrix m:")
print(m)
print("m.isZero() returns: ", m.isZero())
print("m.isZero(1e-3) returns: ", m.isZero(1e-3))