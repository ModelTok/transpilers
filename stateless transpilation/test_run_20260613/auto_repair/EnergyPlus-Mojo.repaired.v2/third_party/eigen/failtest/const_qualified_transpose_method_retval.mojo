from ...Eigen.Core import Matrix3d, Transpose

def foo(borrowed m: Matrix3d):
    var b: Transpose[Matrix3d] = m.transpose()

def main():
