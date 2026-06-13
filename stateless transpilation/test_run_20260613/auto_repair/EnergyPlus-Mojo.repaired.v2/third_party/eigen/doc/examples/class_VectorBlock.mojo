from Eigen.Core import MatrixBase, VectorBlock, Matrix
from IO import print

def segmentFromRange[Derived: MatrixBase](inout v: MatrixBase[Derived], start: Int, end: Int) -> VectorBlock[Derived]:
    return VectorBlock[Derived](v.derived(), start, end - start)

def segmentFromRange[Derived: MatrixBase](borrowed v: MatrixBase[Derived], start: Int, end: Int) -> VectorBlock[Derived]:
    return VectorBlock[Derived](v.derived(), start, end - start)

def main():
    var v: Matrix[Int, 1, 6]
    v << 1,2,3,4,5,6
    print(segmentFromRange(2*v, 2, 4)) # calls the const version
    segmentFromRange(v, 1, 3) *= 5    # calls the non-const version
    print("Now the vector v is:")
    print(v)