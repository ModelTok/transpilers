from ...Eigen.Core import MatrixXf, Map, Unaligned, OuterStride, DenseIndex

# Simulate preprocessor: EIGEN_SHOULD_FAIL_TO_BUILD is defined (build failure test)
alias EIGEN_SHOULD_FAIL_TO_BUILD = True

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias CV_QUALIFIER = ""  # empty, meaning non-const
else:
    alias CV_QUALIFIER = "const"  # not used, kept for faithful naming

# The original code: Map<CV_QUALIFIER MatrixXf, Unaligned, OuterStride<> >
# Since CV_QUALIFIER is empty, we use Map[MatrixXf, Unaligned, OuterStride[]]
def foo(ptr: UnsafePointer[Float], rows: DenseIndex, cols: DenseIndex):
    var m = Map[MatrixXf, Unaligned, OuterStride[]](ptr, rows, cols, OuterStride[](2))

def main():
