from ......Eigen.Core import Vector3d

var v = Vector3d(1, 2, 3)
v.array() += 3
v.array() -= 2
print(v)