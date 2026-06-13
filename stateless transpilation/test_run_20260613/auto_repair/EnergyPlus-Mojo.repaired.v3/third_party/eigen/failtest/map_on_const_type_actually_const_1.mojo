# Third-party Eigen failtest translation
# Original: map_on_const_type_actually_const_1.cpp
# #include "../Eigen/Core"
# #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# #define CV_QUALIFIER const
# #else
# #define CV_QUALIFIER
# #endif
# using namespace Eigen;

from ...Eigen.Core import *

def foo(ptr: Pointer[Float32]):
    Map[const Vector3f](ptr).coeffRef(0) = 1.0

def main(): pass