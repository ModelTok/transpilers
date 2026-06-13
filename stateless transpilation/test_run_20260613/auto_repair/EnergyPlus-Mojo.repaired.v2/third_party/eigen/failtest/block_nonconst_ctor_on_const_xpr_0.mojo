# This is a Mojo translation of the C++ failtest.
# The original uses preprocessor macros; we simulate with compile-time constants.

alias EIGEN_SHOULD_FAIL_TO_BUILD = True

# Minimal Eigen-like types for the test.
struct Matrix3d:

struct Block[T: AnyType, rows: Int, cols: Int]:
    var data: T
    def __init__(inout self, m: inout T, row: Int, col: Int):
        self.data = m

# Conditional function definition based on the macro.
@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    # CV_QUALIFIER is const (borrowed) – this should cause a compile error
    # because Block constructor expects inout (non-const).
    def foo(m: borrowed Matrix3d):
        Block[Matrix3d, 3, 3] b(m, 0, 0)
else:
    # CV_QUALIFIER is empty (inout) – this should compile.
    def foo(m: inout Matrix3d):
        Block[Matrix3d, 3, 3] b(m, 0, 0)

def main():
