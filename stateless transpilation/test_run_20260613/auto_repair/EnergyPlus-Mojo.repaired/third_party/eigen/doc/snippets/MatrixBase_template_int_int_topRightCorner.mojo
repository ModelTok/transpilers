from Eigen import Matrix4i

var m: Matrix4i = Matrix4i.Random()
print("Here is the matrix m:")
print(m)
print("Here is m.topRightCorner<2,2>():")
print(m.topRightCorner[2,2]())
m.topRightCorner[2,2]().setZero()
print("Now the matrix m is:")
print(m)