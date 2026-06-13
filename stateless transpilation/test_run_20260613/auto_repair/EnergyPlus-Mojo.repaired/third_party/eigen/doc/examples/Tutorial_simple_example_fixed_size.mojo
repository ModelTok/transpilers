from Eigen import Matrix3f, Matrix4f, Vector4i

def main():
    var m3 = Matrix3f()
    m3 << 1, 2, 3, 4, 5, 6, 7, 8, 9
    var m4 = Matrix4f.Identity()
    var v4 = Vector4i(1, 2, 3, 4)
    print("m3\n", m3, "\nm4:\n", m4, "\nv4:\n", v4)