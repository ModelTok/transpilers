from ..Eigen import Matrix, Projective3d, Dynamic, Matrix4d

def main() raises:
    alias Matrix3Xd = Matrix[Float64, 3, Dynamic]
    var M: Matrix3Xd = Matrix3Xd.Random(3, 5)
    var P: Projective3d = Projective3d(Matrix4d.Random())
    print("The matrix M is:")
    print(M)
    print()
    print("M.colwise().homogeneous():")
    print(M.colwise().homogeneous())
    print()
    print("P * M.colwise().homogeneous():")
    print(P * M.colwise().homogeneous())
    print()
    print("P * M.colwise().homogeneous().hnormalized():")
    print((P * M.colwise().homogeneous()).colwise().hnormalized())
    print()