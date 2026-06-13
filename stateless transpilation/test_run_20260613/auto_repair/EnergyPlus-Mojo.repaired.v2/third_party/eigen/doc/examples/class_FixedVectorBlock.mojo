from Eigen import MatrixBase, VectorBlock

def firstTwo[Derived: AnyType](v: inout MatrixBase[Derived]) -> VectorBlock[Derived, 2]:
    return VectorBlock[Derived, 2](v.derived(), 0)

def firstTwo[Derived: AnyType](v: borrowed MatrixBase[Derived]) -> VectorBlock[Derived, 2]:
    return VectorBlock[Derived, 2](v.derived(), 0)

def main():
    var v = Matrix[int, 1, 6]()
    v << 1,2,3,4,5,6
    print(firstTwo(4*v))
    firstTwo(v) *= 2
    print("Now the vector v is:")
    print(v)