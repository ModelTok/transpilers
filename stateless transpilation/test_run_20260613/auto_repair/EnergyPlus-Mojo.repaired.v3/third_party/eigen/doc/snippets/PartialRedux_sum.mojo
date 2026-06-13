from Eigen import Matrix3d, Random, rowwise, sum

var m = Matrix3d.Random()
print("Here is the matrix m:")
print(m)
print("Here is the sum of each row:")
print(m.rowwise().sum())