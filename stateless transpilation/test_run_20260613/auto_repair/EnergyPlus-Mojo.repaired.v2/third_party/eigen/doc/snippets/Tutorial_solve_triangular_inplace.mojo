from Eigen import Matrix3f, Vector3f

var A = Matrix3f()
var b = Vector3f()
A << 1,2,3,  0,5,6,  0,0,10
b << 3, 3, 4
A.triangularView[Upper]().solveInPlace(b)
print("The solution is:")
print(b)