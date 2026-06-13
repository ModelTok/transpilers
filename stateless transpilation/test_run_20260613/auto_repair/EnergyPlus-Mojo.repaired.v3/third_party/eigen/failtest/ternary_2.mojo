from ...Eigen import Core

alias Eigen = Core

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    var a = Eigen.VectorXf(10), b = Eigen.VectorXf(10)
    #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    b = argc > 1 ? 2 * a : a + a
    #else
    b = argc > 1 ? Eigen.VectorXf(2 * a) : Eigen.VectorXf(a + a)
    #endif