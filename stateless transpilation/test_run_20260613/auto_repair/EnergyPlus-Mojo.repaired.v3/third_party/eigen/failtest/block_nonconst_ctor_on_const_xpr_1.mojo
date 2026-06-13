// This is a faithful 1:1 translation of the C++ file.
// The original used preprocessor macros; we simulate with compile-time constants.
// Eigen types are replaced with minimal stubs to preserve structure.

alias EIGEN_SHOULD_FAIL_TO_BUILD = True  // Set to True to trigger the expected failure
alias CV_QUALIFIER = "const" if EIGEN_SHOULD_FAIL_TO_BUILD else ""  // Kept for name fidelity, not used in signature

struct Matrix3d:

struct Block:
    var data: Matrix3d
    def __init__(inout self, m: inout Matrix3d, a: Int, b: Int, c: Int, d: Int):
        self.data = m

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    def foo(m: borrowed Matrix3d):
        var b = Block(m, 0, 0, 3, 3)
else:
    def foo(m: inout Matrix3d):
        var b = Block(m, 0, 0, 3, 3)

def main():
