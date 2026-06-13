from Eigen import Matrix4i, Dynamic

var m = Matrix4i.Random()
print("Here is the matrix m:")
print(m)
print("Here is m.bottomLeftCorner<2,Dynamic>(2,2):")
print(m.bottomLeftCorner[2, Dynamic](2, 2))
m.bottomLeftCorner[2, Dynamic](2, 2).setZero()
print("Now the matrix m is:")
print(m)