from ...Eigen.Core import VectorXf, DenseBase

alias EIGEN_SHOULD_FAIL_TO_BUILD = True

def main():
    var a = VectorXf(10)
    var b = VectorXf(10)
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        let ac: DenseBase[VectorXf] = a
        b.swap(ac)
    else:
        var ac: DenseBase[VectorXf] = a
        b.swap(ac)