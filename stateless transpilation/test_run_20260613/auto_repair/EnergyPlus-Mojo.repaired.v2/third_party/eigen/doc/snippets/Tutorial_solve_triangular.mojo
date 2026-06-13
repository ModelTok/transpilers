from Eigen import Matrix3f, Vector3f, Upper

var A = Matrix3f()
var b = Vector3f()
A << 1,2,3,  0,5,6,  0,0,10
b << 3, 3, 4
print("Here is the matrix A:")
print(A)
print("Here is the vector b:")
print(b)
var x = A.triangularView[Upper]().solve(b)
print("The solution is:")
print(x)