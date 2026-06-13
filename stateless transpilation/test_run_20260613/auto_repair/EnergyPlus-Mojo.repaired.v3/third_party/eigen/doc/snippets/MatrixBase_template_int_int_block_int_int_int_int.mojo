from Eigen import Matrix4i, Dynamic

var m = Matrix4i.Random()
print("Here is the matrix m:")
print(m)
print("Here is the block:")
print(m.block[2, Dynamic](1, 1, 2, 3))
m.block[2, Dynamic](1, 1, 2, 3).setZero()
print("Now the matrix m is:")
print(m)