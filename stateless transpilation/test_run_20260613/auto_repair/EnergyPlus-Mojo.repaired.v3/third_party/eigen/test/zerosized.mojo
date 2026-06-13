def VERIFY(cond: Bool):
    assert(cond)

def zeroReduction[MatrixType](m: MatrixType):
    VERIFY(m.all())
    VERIFY(!m.any())
    VERIFY(m.prod() == 1)
    VERIFY(m.sum() == 0)
    VERIFY(m.count() == 0)
    VERIFY(m.allFinite())
    VERIFY(!m.hasNaN())

def zeroSizedMatrix[MatrixType]():
    var t1: MatrixType = MatrixType()
    alias Scalar = MatrixType.Scalar
    if MatrixType.SizeAtCompileTime == Dynamic or MatrixType.SizeAtCompileTime == 0:
        zeroReduction(t1)
        if MatrixType.RowsAtCompileTime == Dynamic:
            VERIFY(t1.rows() == 0)
        if MatrixType.ColsAtCompileTime == Dynamic:
            VERIFY(t1.cols() == 0)
        if MatrixType.RowsAtCompileTime == Dynamic and MatrixType.ColsAtCompileTime == Dynamic:
            var t2 = MatrixType(0, 0)
            var t3 = t1
            VERIFY(t2.rows() == 0)
            VERIFY(t2.cols() == 0)
            zeroReduction(t2)
            VERIFY(t1 == t2)
    if MatrixType.MaxColsAtCompileTime != 0 and MatrixType.MaxRowsAtCompileTime != 0:
        var rows: Index = MatrixType.RowsAtCompileTime if MatrixType.RowsAtCompileTime != Dynamic else Index(internal.random[Index](1, 10))
        var cols: Index = MatrixType.ColsAtCompileTime if MatrixType.ColsAtCompileTime != Dynamic else Index(internal.random[Index](1, 10))
        var m = MatrixType(rows, cols)
        zeroReduction(m.block[0, MatrixType.ColsAtCompileTime](0, 0, 0, cols))
        zeroReduction(m.block[MatrixType.RowsAtCompileTime, 0](0, 0, rows, 0))
        zeroReduction(m.block[0, 1](0, 0))
        zeroReduction(m.block[1, 0](0, 0))
        var prod: Matrix[Scalar, Dynamic, Dynamic] = m.block[MatrixType.RowsAtCompileTime, 0](0, 0, rows, 0) * m.block[0, MatrixType.ColsAtCompileTime](0, 0, 0, cols)
        VERIFY(prod.rows() == rows and prod.cols() == cols)
        VERIFY(prod.isZero())
        prod = m.block[1, 0](0, 0) * m.block[0, 1](0, 0)
        VERIFY(prod.size() == 1)
        VERIFY(prod.isZero())

def zeroSizedVector[VectorType]():
    var t1: VectorType = VectorType()
    if VectorType.SizeAtCompileTime == Dynamic or VectorType.SizeAtCompileTime == 0:
        zeroReduction(t1)
        VERIFY(t1.size() == 0)
        var t2 = VectorType(DenseIndex(0))  # DenseIndex disambiguates with 0-the-null-pointer (error with gcc 4.4 and MSVC8)
        VERIFY(t2.size() == 0)
        zeroReduction(t2)
        VERIFY(t1 == t2)

def test_zerosized():
    zeroSizedMatrix[Matrix2d]()
    zeroSizedMatrix[Matrix3i]()
    zeroSizedMatrix[Matrix[float, 2, Dynamic]]()
    zeroSizedMatrix[MatrixXf]()
    zeroSizedMatrix[Matrix[float, 0, 0]]()
    zeroSizedMatrix[Matrix[float, Dynamic, 0, 0, 0, 0]]()
    zeroSizedMatrix[Matrix[float, 0, Dynamic, 0, 0, 0]]()
    zeroSizedMatrix[Matrix[float, Dynamic, Dynamic, 0, 0, 0]]()
    zeroSizedMatrix[Matrix[float, 0, 4]]()
    zeroSizedMatrix[Matrix[float, 4, 0]]()
    zeroSizedVector[Vector2d]()
    zeroSizedVector[Vector3i]()
    zeroSizedVector[VectorXf]()
    zeroSizedVector[Matrix[float, 0, 1]]()
    zeroSizedVector[Matrix[float, 1, 0]]()