from Eigen import Matrix3d, Vector3d

var m = Matrix3d.Identity()
m.row(1) = Vector3d(4, 5, 6)
print(m)