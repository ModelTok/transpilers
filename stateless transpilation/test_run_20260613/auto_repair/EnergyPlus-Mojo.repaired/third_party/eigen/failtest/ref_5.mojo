// Translated from third_party/eigen/failtest/ref_5.cpp

// Minimal type definitions to mimic Eigen types for fail test.
struct VectorXf:
    var size: Int
    def __init__(inout self, n: Int):
        self.size = n

struct DenseBase[T: AnyType]:
    var inner: T
    def __init__(inout self, ref other: T):
        self.inner = other
    def derived(self) -> T&:
        return self.inner

struct Ref[T: AnyType]:
    var inner: T
    def __init__(inout self, ref other: T):
        self.inner = other

def call_ref(a: Ref[VectorXf]): pass

alias EIGEN_SHOULD_FAIL_TO_BUILD = True

def main():
    var a = VectorXf(10)
    var ac = DenseBase[VectorXf](a)
    // #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    @parameter
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        call_ref(ac); // Should fail to compile because Ref cannot be constructed from DenseBase
    // #else
    else:
        call_ref(ac.derived()); // Should succeed because derived() returns VectorXf&
    // #endif