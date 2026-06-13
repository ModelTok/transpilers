from ...Eigen import Matrix3d

var m = Matrix3d.Identity()
m[0, 2] = 1e-4
print("Here's the matrix m:")
print(m)
print("m.isIdentity() returns: ", m.isIdentity())
print("m.isIdentity(1e-3) returns: ", m.isIdentity(1e-3))