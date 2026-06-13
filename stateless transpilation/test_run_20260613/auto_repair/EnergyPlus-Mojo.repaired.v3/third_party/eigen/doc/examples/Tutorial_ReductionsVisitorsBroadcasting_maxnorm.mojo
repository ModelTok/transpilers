from memory import memset_zero
from sys import print as std_cout
from eigen import MatrixXf, Index

def main() raises:
    var mat = MatrixXf(2, 4)
    mat << 1, 2, 6, 9,
           3, 1, 7, 2
    var maxIndex: Index
    var maxNorm = mat.colwise().sum().maxCoeff(&maxIndex)
    std_cout("Maximum sum at position ", maxIndex, "\n")
    std_cout("The corresponding vector is: \n")
    std_cout(mat.col(maxIndex), "\n")
    std_cout("And its sum is is: ", maxNorm, "\n")