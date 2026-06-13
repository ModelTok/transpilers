from ...Eigen.Core import *
#ifdef EIGEN_SHOULD_FAIL_TO_BUILD
#define CV_QUALIFIER const
#else
#define CV_QUALIFIER
#endif
def call_ref(a: Ref[VectorXf]):

def main():
    var a = VectorXf(10)
    CV_QUALIFIER var ac: VectorXf = a
    call_ref(ac)