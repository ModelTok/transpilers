from sparse import *
from Eigen import *

# template<T>
# Eigen::internal::enable_if<(T::Flags&RowMajorBit)==RowMajorBit, T::RowXpr>::type
# innervec(T& A, Index i)
# {
#   return A.row(i);
# }
# template<T>
# Eigen::internal::enable_if<(T::Flags&RowMajorBit)==0, T::ColXpr>::type
# innervec(T& A, Index i)
# {
#   return A.col(i);
# }
@parameter
def innervec[T: AnyType](A: T, i: Index) -> T.RowXpr if (T.Flags & RowMajorBit) == RowMajorBit:
    return A.row(i)

@parameter
def innervec[T: AnyType](A: T, i: Index) -> T.ColXpr if (T.Flags & RowMajorBit) == 0:
    return A.col(i)

# template<SparseMatrixType> void sparse_block(SparseMatrixType& ref )
def sparse_block[SparseMatrixType: AnyType](ref: SparseMatrixType):
    const rows: Index = ref.rows()
    const cols: Index = ref.cols()
    const inner: Index = ref.innerSize()
    const outer: Index = ref.outerSize()
    typedef SparseMatrixType::Scalar Scalar
    typedef SparseMatrixType::StorageIndex StorageIndex
    var density: Float64 = (max)(8.0 / (rows * cols), 0.01)
    typedef Matrix[Scalar, Dynamic, Dynamic, SparseMatrixType.IsRowMajor ? RowMajor : ColMajor] DenseMatrix
    typedef Matrix[Scalar, Dynamic, 1] DenseVector
    typedef Matrix[Scalar, 1, Dynamic] RowDenseVector
    typedef SparseVector[Scalar] SparseVectorType
    var s1: Scalar = internal.random[Scalar]()
    {
        var m: SparseMatrixType = SparseMatrixType(rows, cols)
        var refMat: DenseMatrix = DenseMatrix.Zero(rows, cols)
        initSparse[Scalar](density, refMat, m)
        VERIFY_IS_APPROX(m, refMat)
        for t in range(0, 10):
            var j: Index = internal.random[Index](0, cols - 2)
            var i: Index = internal.random[Index](0, rows - 2)
            var w: Index = internal.random[Index](1, cols - j)
            var h: Index = internal.random[Index](1, rows - i)
            VERIFY_IS_APPROX(m.block(i, j, h, w), refMat.block(i, j, h, w))
            for c in range(0, w):
                VERIFY_IS_APPROX(m.block(i, j, h, w).col(c), refMat.block(i, j, h, w).col(c))
                for r in range(0, h):
                    VERIFY_IS_APPROX(m.block(i, j, h, w).col(c).coeff(r), refMat.block(i, j, h, w).col(c).coeff(r))
                    VERIFY_IS_APPROX(m.block(i, j, h, w).coeff(r, c), refMat.block(i, j, h, w).coeff(r, c))
            for r in range(0, h):
                VERIFY_IS_APPROX(m.block(i, j, h, w).row(r), refMat.block(i, j, h, w).row(r))
                for c in range(0, w):
                    VERIFY_IS_APPROX(m.block(i, j, h, w).row(r).coeff(c), refMat.block(i, j, h, w).row(r).coeff(c))
                    VERIFY_IS_APPROX(m.block(i, j, h, w).coeff(r, c), refMat.block(i, j, h, w).coeff(r, c))
            VERIFY_IS_APPROX(m.middleCols(j, w), refMat.middleCols(j, w))
            VERIFY_IS_APPROX(m.middleRows(i, h), refMat.middleRows(i, h))
            for r in range(0, h):
                VERIFY_IS_APPROX(m.middleCols(j, w).row(r), refMat.middleCols(j, w).row(r))
                VERIFY_IS_APPROX(m.middleRows(i, h).row(r), refMat.middleRows(i, h).row(r))
                for c in range(0, w):
                    VERIFY_IS_APPROX(m.col(c).coeff(r), refMat.col(c).coeff(r))
                    VERIFY_IS_APPROX(m.row(r).coeff(c), refMat.row(r).coeff(c))
                    VERIFY_IS_APPROX(m.middleCols(j, w).coeff(r, c), refMat.middleCols(j, w).coeff(r, c))
                    VERIFY_IS_APPROX(m.middleRows(i, h).coeff(r, c), refMat.middleRows(i, h).coeff(r, c))
                    if m.middleCols(j, w).coeff(r, c) != Scalar(0):
                        VERIFY_IS_APPROX(m.middleCols(j, w).coeffRef(r, c), refMat.middleCols(j, w).coeff(r, c))
                    if m.middleRows(i, h).coeff(r, c) != Scalar(0):
                        VERIFY_IS_APPROX(m.middleRows(i, h).coeff(r, c), refMat.middleRows(i, h).coeff(r, c))
            for c in range(0, w):
                VERIFY_IS_APPROX(m.middleCols(j, w).col(c), refMat.middleCols(j, w).col(c))
                VERIFY_IS_APPROX(m.middleRows(i, h).col(c), refMat.middleRows(i, h).col(c))
        for c in range(0, cols):
            VERIFY_IS_APPROX(m.col(c) + m.col(c), (m + m).col(c))
            VERIFY_IS_APPROX(m.col(c) + m.col(c), refMat.col(c) + refMat.col(c))
        for r in range(0, rows):
            VERIFY_IS_APPROX(m.row(r) + m.row(r), (m + m).row(r))
            VERIFY_IS_APPROX(m.row(r) + m.row(r), refMat.row(r) + refMat.row(r))
    }
    {
        var refMat2: DenseMatrix = DenseMatrix.Zero(rows, cols)
        var m2: SparseMatrixType = SparseMatrixType(rows, cols)
        initSparse[Scalar](density, refMat2, m2)
        var j0: Index = internal.random[Index](0, outer - 1)
        var j1: Index = internal.random[Index](0, outer - 1)
        var r0: Index = internal.random[Index](0, rows - 1)
        var c0: Index = internal.random[Index](0, cols - 1)
        VERIFY_IS_APPROX(m2.innerVector(j0), innervec(refMat2, j0))
        VERIFY_IS_APPROX(m2.innerVector(j0) + m2.innerVector(j1), innervec(refMat2, j0) + innervec(refMat2, j1))
        m2.innerVector(j0) *= Scalar(2)
        innervec(refMat2, j0) *= Scalar(2)
        VERIFY_IS_APPROX(m2, refMat2)
        m2.row(r0) *= Scalar(3)
        refMat2.row(r0) *= Scalar(3)
        VERIFY_IS_APPROX(m2, refMat2)
        m2.col(c0) *= Scalar(4)
        refMat2.col(c0) *= Scalar(4)
        VERIFY_IS_APPROX(m2, refMat2)
        m2.row(r0) /= Scalar(3)
        refMat2.row(r0) /= Scalar(3)
        VERIFY_IS_APPROX(m2, refMat2)
        m2.col(c0) /= Scalar(4)
        refMat2.col(c0) /= Scalar(4)
        VERIFY_IS_APPROX(m2, refMat2)
        var v1: SparseVectorType
        VERIFY_IS_APPROX(v1 = m2.col(c0) * 4, refMat2.col(c0) * 4)
        VERIFY_IS_APPROX(v1 = m2.row(r0) * 4, refMat2.row(r0).transpose() * 4)
        var m3: SparseMatrixType = SparseMatrixType(rows, cols)
        m3.reserve(VectorXi.Constant(outer, int(inner / 2)))
        for j in range(0, outer):
            for k in range(0, (min)(j, inner)):
                m3.insertByOuterInner(j, k) = internal.convert_index[StorageIndex](k + 1)
        for j in range(0, (min)(outer, inner)):
            VERIFY(j == numext.real(m3.innerVector(j).nonZeros()))
            if j > 0:
                VERIFY(j == numext.real(m3.innerVector(j).lastCoeff()))
        m3.makeCompressed()
        for j in range(0, (min)(outer, inner)):
            VERIFY(j == numext.real(m3.innerVector(j).nonZeros()))
            if j > 0:
                VERIFY(j == numext.real(m3.innerVector(j).lastCoeff()))
        VERIFY(m3.innerVector(j0).nonZeros() == m3.transpose().innerVector(j0).nonZeros())
    }
    {
        var refMat2: DenseMatrix = DenseMatrix.Zero(rows, cols)
        var m2: SparseMatrixType = SparseMatrixType(rows, cols)
        initSparse[Scalar](density, refMat2, m2)
        if internal.random[Float32](0, 1) > 0.5:
            m2.makeCompressed()
        var j0: Index = internal.random[Index](0, outer - 2)
        var j1: Index = internal.random[Index](0, outer - 2)
        var n0: Index = internal.random[Index](1, outer - (max)(j0, j1))
        if SparseMatrixType.IsRowMajor:
            VERIFY_IS_APPROX(m2.innerVectors(j0, n0), refMat2.block(j0, 0, n0, cols))
        else:
            VERIFY_IS_APPROX(m2.innerVectors(j0, n0), refMat2.block(0, j0, rows, n0))
        if SparseMatrixType.IsRowMajor:
            VERIFY_IS_APPROX(m2.innerVectors(j0, n0) + m2.innerVectors(j1, n0),
                             refMat2.middleRows(j0, n0) + refMat2.middleRows(j1, n0))
        else:
            VERIFY_IS_APPROX(m2.innerVectors(j0, n0) + m2.innerVectors(j1, n0),
                             refMat2.block(0, j0, rows, n0) + refMat2.block(0, j1, rows, n0))
        VERIFY_IS_APPROX(m2, refMat2)
        VERIFY(m2.innerVectors(j0, n0).nonZeros() == m2.transpose().innerVectors(j0, n0).nonZeros())
        m2.innerVectors(j0, n0) = m2.innerVectors(j0, n0) + m2.innerVectors(j1, n0)
        if SparseMatrixType.IsRowMajor:
            refMat2.middleRows(j0, n0) = (refMat2.middleRows(j0, n0) + refMat2.middleRows(j1, n0)).eval()
        else:
            refMat2.middleCols(j0, n0) = (refMat2.middleCols(j0, n0) + refMat2.middleCols(j1, n0)).eval()
        VERIFY_IS_APPROX(m2, refMat2)
    }
    {
        var refMat2: DenseMatrix = DenseMatrix.Zero(rows, cols)
        var m2: SparseMatrixType = SparseMatrixType(rows, cols)
        initSparse[Scalar](density, refMat2, m2)
        var j0: Index = internal.random[Index](0, outer - 2)
        var j1: Index = internal.random[Index](0, outer - 2)
        var n0: Index = internal.random[Index](1, outer - (max)(j0, j1))
        if SparseMatrixType.IsRowMajor:
            VERIFY_IS_APPROX(m2.block(j0, 0, n0, cols), refMat2.block(j0, 0, n0, cols))
        else:
            VERIFY_IS_APPROX(m2.block(0, j0, rows, n0), refMat2.block(0, j0, rows, n0))
        if SparseMatrixType.IsRowMajor:
            VERIFY_IS_APPROX(m2.block(j0, 0, n0, cols) + m2.block(j1, 0, n0, cols),
                             refMat2.block(j0, 0, n0, cols) + refMat2.block(j1, 0, n0, cols))
        else:
            VERIFY_IS_APPROX(m2.block(0, j0, rows, n0) + m2.block(0, j1, rows, n0),
                             refMat2.block(0, j0, rows, n0) + refMat2.block(0, j1, rows, n0))
        var i: Index = internal.random[Index](0, m2.outerSize() - 1)
        if SparseMatrixType.IsRowMajor:
            m2.innerVector(i) = m2.innerVector(i) * s1
            refMat2.row(i) = refMat2.row(i) * s1
            VERIFY_IS_APPROX(m2, refMat2)
        else:
            m2.innerVector(i) = m2.innerVector(i) * s1
            refMat2.col(i) = refMat2.col(i) * s1
            VERIFY_IS_APPROX(m2, refMat2)
        var r0: Index = internal.random[Index](0, rows - 2)
        var c0: Index = internal.random[Index](0, cols - 2)
        var r1: Index = internal.random[Index](1, rows - r0)
        var c1: Index = internal.random[Index](1, cols - c0)
        VERIFY_IS_APPROX(DenseVector(m2.col(c0)), refMat2.col(c0))
        VERIFY_IS_APPROX(m2.col(c0), refMat2.col(c0))
        VERIFY_IS_APPROX(RowDenseVector(m2.row(r0)), refMat2.row(r0))
        VERIFY_IS_APPROX(m2.row(r0), refMat2.row(r0))
        VERIFY_IS_APPROX(m2.block(r0, c0, r1, c1), refMat2.block(r0, c0, r1, c1))
        VERIFY_IS_APPROX((2 * m2).block(r0, c0, r1, c1), (2 * refMat2).block(r0, c0, r1, c1))
        if m2.nonZeros() > 0:
            VERIFY_IS_APPROX(m2, refMat2)
            var m3: SparseMatrixType = SparseMatrixType(rows, cols)
            var refMat3: DenseMatrix = DenseMatrix(rows, cols)
            refMat3.setZero()
            var n: Index = internal.random[Index](1, 10)
            for k in range(0, n):
                var o1: Index = internal.random[Index](0, outer - 1)
                var o2: Index = internal.random[Index](0, outer - 1)
                if SparseMatrixType.IsRowMajor:
                    m3.innerVector(o1) = m2.row(o2)
                    refMat3.row(o1) = refMat2.row(o2)
                else:
                    m3.innerVector(o1) = m2.col(o2)
                    refMat3.col(o1) = refMat2.col(o2)
                if internal.random[Bool]():
                    m3.makeCompressed()
            if m3.nonZeros() > 0:
                VERIFY_IS_APPROX(m3, refMat3)
    }

def test_sparse_block():
    for i in range(0, g_repeat):
        var r: Int = Eigen.internal.random[Int](1, 200)
        var c: Int = Eigen.internal.random[Int](1, 200)
        if Eigen.internal.random[Int](0, 4) == 0:
            r = c  # check square matrices in 25% of tries
        EIGEN_UNUSED_VARIABLE(r + c)
        CALL_SUBTEST_1(( sparse_block[SparseMatrix[Float64]](SparseMatrix[Float64](1, 1)) ))
        CALL_SUBTEST_1(( sparse_block[SparseMatrix[Float64]](SparseMatrix[Float64](8, 8)) ))
        CALL_SUBTEST_1(( sparse_block[SparseMatrix[Float64]](SparseMatrix[Float64](r, c)) ))
        CALL_SUBTEST_2(( sparse_block[SparseMatrix[ComplexFloat64, ColMajor]](SparseMatrix[ComplexFloat64, ColMajor](r, c)) ))
        CALL_SUBTEST_2(( sparse_block[SparseMatrix[ComplexFloat64, RowMajor]](SparseMatrix[ComplexFloat64, RowMajor](r, c)) ))
        CALL_SUBTEST_3(( sparse_block[SparseMatrix[Float64, ColMajor, Int64]](SparseMatrix[Float64, ColMajor, Int64](r, c)) ))
        CALL_SUBTEST_3(( sparse_block[SparseMatrix[Float64, RowMajor, Int64]](SparseMatrix[Float64, RowMajor, Int64](r, c)) ))
        r = Eigen.internal.random[Int](1, 100)
        c = Eigen.internal.random[Int](1, 100)
        if Eigen.internal.random[Int](0, 4) == 0:
            r = c  # check square matrices in 25% of tries
        CALL_SUBTEST_4(( sparse_block[SparseMatrix[Float64, ColMajor, Int16]](SparseMatrix[Float64, ColMajor, Int16](Int16(r), Int16(c))) ))
        CALL_SUBTEST_4(( sparse_block[SparseMatrix[Float64, RowMajor, Int16]](SparseMatrix[Float64, RowMajor, Int16](Int16(r), Int16(c))) ))