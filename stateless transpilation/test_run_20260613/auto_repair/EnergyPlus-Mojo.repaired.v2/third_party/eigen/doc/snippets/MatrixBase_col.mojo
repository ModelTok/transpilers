from mojo.linear import Matrix, Vector

alias Matrix3d = Matrix[Float64, 3, 3]
alias Vector3d = Vector[Float64, 3]

var m = Matrix3d.identity()
m.col(1) = Vector3d(4, 5, 6)
print(m)