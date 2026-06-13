from ...Eigen.Core import VectorXf

def main() -> Int32:
    var a = VectorXf(10)
    var b = VectorXf(10)
    let ac: VectorXf = a
#ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    b.swap(ac)
#else
    b.swap(ac.const_cast_derived())
#endif
    return 0