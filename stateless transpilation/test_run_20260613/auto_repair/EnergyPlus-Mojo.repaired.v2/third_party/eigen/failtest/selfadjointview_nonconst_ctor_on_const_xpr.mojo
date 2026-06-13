from ...Eigen.Core import Matrix3d, Upper, SelfAdjointView

alias CV_QUALIFIER = const

def foo(CV_QUALIFIER m: Matrix3d):
    var t = SelfAdjointView[Matrix3d, Upper](m)

def main():
