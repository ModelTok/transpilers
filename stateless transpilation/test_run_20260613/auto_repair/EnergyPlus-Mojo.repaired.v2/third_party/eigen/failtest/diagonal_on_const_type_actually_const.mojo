from ...Eigen.Core import *
#failed#ifdef EIGEN_SHOULD_FAIL_TO_BUILD
#failed#define CV_QUALIFIER const
#failed#else
#failed#define CV_QUALIFIER
#failed#endif
#using namespace Eigen;
#failedvoid foo(){
def foo() raises:
    var m: MatrixXf = MatrixXf()
    Diagonal[CV_QUALIFIER MatrixXf](m).coeffRef(0) = 1.0f
#failed}
#failedint main() {}