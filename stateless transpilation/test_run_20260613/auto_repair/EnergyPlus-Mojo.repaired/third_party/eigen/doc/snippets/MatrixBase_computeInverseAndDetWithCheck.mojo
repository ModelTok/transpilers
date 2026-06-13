from ...Eigen import Matrix3d

def main():
    var m: Matrix3d = Matrix3d.Random()
    print("Here is the matrix m:")
    print(m)
    var inverse: Matrix3d
    var invertible: Bool
    var determinant: Float64
    m.computeInverseAndDetWithCheck(inverse, determinant, invertible)
    print("Its determinant is ", determinant)
    if invertible:
        print("It is invertible, and its inverse is:")
        print(inverse)
    else:
        print("It is not invertible.")