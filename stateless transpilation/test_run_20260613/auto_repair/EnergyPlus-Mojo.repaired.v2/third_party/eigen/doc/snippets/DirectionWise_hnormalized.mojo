from Eigen import Matrix, Dynamic, Projective3d, Matrix4d

alias Matrix4Xd = Matrix[Float64, 4, Dynamic]

let M = Matrix4Xd.Random(4, 5)
let P = Projective3d(Matrix4d.Random())
print("The matrix M is:")
print(M)
print("")
print("M.colwise().hnormalized():")
print(M.colwise().hnormalized())
print("")
print("P*M:")
print(P * M)
print("")
print("(P*M).colwise().hnormalized():")
print((P * M).colwise().hnormalized())
print("")