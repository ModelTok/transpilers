from ...Eigen import Matrix3f, Block

def foo():
    var m = Matrix3f()
    Block[const Matrix3f](m, 0, 0, 3, 3).coeffRef(0, 0) = 1.0

def main():
