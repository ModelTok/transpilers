from Eigen import Matrix4d, Vector3d, Tridiagonalization

var X = Matrix4d.Random(4, 4)
var A = X + X.transpose()
print("Here is a random symmetric 4x4 matrix:")
print(A)
var triOfA = Tridiagonalization[Matrix4d](A)
var hc = triOfA.householderCoefficients()
print("The vector of Householder coefficients is:")
print(hc)