from mojo.linear import Matrix

def main() raises:
    var m = Matrix[Float32](4, 4)
    m = Matrix[Float32]([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
        [13, 14, 15, 16]
    ])
    print("m.leftCols(2) =")
    print(m.leftCols(2))
    print()
    print("m.bottomRows<2>() =")
    print(m.bottomRows(2))
    print()
    m.topLeftCorner(1, 3) = m.bottomRightCorner(3, 1).transpose()
    print("After assignment, m =")
    print(m)