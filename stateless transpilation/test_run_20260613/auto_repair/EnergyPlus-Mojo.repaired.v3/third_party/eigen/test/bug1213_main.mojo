from bug1213 import *

def main() -> Int32:
    return 0

def bug1213_2[T: AnyType, dim: Int](arg: Eigen.Matrix[T, dim, 1]) -> Bool:
    return True

# template bool bug1213_2<float,3>(const Eigen::Vector3f&);