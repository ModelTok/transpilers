from Eigen import Matrix3d

var m = Matrix3d.Ones()
m[0,2] += 1e-4
print("Here's the matrix m:")
print(m)
print("m.isOnes() returns: ", m.isOnes())
print("m.isOnes(1e-3) returns: ", m.isOnes(1e-3))