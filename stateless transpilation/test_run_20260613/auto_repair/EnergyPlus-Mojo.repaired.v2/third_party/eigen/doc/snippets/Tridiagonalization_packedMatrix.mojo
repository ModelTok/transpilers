from Eigen import Matrix4d, Tridiagonalization

var X = Matrix4d.Random(4, 4)
var A = X + X.transpose()
print("Here is a random symmetric 4x4 matrix:")
print(A)
var triOfA = Tridiagonalization[Matrix4d](A)
var pm = triOfA.packedMatrix()
print("The packed matrix M is:")
print(pm)
print("The diagonal and subdiagonal corresponds to the matrix T, which is:")
print(triOfA.matrixT())