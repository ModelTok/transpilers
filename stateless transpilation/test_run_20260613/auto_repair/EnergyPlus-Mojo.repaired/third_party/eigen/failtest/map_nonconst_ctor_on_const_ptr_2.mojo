from ...Eigen.Core import Map, MatrixXf, DenseIndex

alias EIGEN_SHOULD_FAIL_TO_BUILD = True

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias CV_QUALIFIER = const Float32
else:
    alias CV_QUALIFIER = Float32

def foo(ptr: CV_QUALIFIER*, rows: DenseIndex, cols: DenseIndex):
    let m = Map[MatrixXf](ptr, rows, cols)
    _ = m

def main():
