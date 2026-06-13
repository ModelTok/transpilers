from third_party.eigen.Eigen import Matrix3i, Upper, Lower

var m = Matrix3i.Random()
print("Here is the matrix m:")
print(m)
print("Here is the symmetric matrix extracted from the upper part of m:")
print(Matrix3i(m.selfadjointView[Upper]()))
print("Here is the symmetric matrix extracted from the lower part of m:")
print(Matrix3i(m.selfadjointView[Lower]()))