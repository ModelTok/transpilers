from Eigen import Matrix3d

var m = Matrix3d.Random()
print("Here is the matrix m:")
print(m)
var inverse = Matrix3d()
var invertible = False
m.computeInverseWithCheck(inverse, invertible)
if invertible:
    print("It is invertible, and its inverse is:")
    print(inverse)
else:
    print("It is not invertible.")