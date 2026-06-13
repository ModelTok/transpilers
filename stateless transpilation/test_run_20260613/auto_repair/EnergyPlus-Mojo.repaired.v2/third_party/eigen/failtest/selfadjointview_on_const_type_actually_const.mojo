// #include "../Eigen/Core"
// #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
// #define CV_QUALIFIER const
// #else
// #define CV_QUALIFIER
// #endif
alias EIGEN_SHOULD_FAIL_TO_BUILD = True
alias CV_QUALIFIER = Const
// using namespace Eigen;
def foo():
    var m: MatrixXf
    SelfAdjointView[CV_QUALIFIER[MatrixXf], Upper](m).coeffRef(0, 0) = 1.0f

def main() -> Int32:
    return 0