# EIGEN_NO_DEPRECATED_WARNING equivalent not needed in Mojo
from sparse_product import *
from sparse_basic import *
from Eigen.SparseExtra import *

def test_random_setter[SetterType: AnyRegType, DenseType: AnyRegType, Scalar: AnyRegType, Options: Int](sm: SparseMatrix[Scalar, Options], ref: DenseType, nonzeroCoords: std.vector[Vector2i]) -> Bool:
    {
        sm.setZero()
        var w = SetterType(sm)
        var remaining = nonzeroCoords
        while not remaining.empty():
            var i = internal.random[Int](0, static_cast[Int](remaining.size()) - 1)
            w(remaining[i].x(), remaining[i].y()) = ref.coeff(remaining[i].x(), remaining[i].y())
            remaining[i] = remaining.back()
            remaining.pop_back()
    }
    return sm.isApprox(ref)

def test_random_setter[SetterType: AnyRegType, DenseType: AnyRegType, T: AnyRegType](sm: DynamicSparseMatrix[T], ref: DenseType, nonzeroCoords: std.vector[Vector2i]) -> Bool:
    sm.setZero()
    var remaining = nonzeroCoords
    while not remaining.empty():
        var i = internal.random[Int](0, static_cast[Int](remaining.size()) - 1)
        sm.coeffRef(remaining[i].x(), remaining[i].y()) = ref.coeff(remaining[i].x(), remaining[i].y())
        remaining[i] = remaining.back()
        remaining.pop_back()
    return sm.isApprox(ref)

def sparse_extra[SparseMatrixType: AnyRegType](ref: SparseMatrixType):
    const rows = ref.rows()
    const cols = ref.cols()
    alias Scalar = SparseMatrixType.Scalar
    enum Flags = SparseMatrixType.Flags
    var density = (std.max)(8./(rows*cols), 0.01)
    alias DenseMatrix = Matrix[Scalar, Dynamic, Dynamic]
    alias DenseVector = Matrix[Scalar, Dynamic, 1]
    var eps = 1e-6
    var m = SparseMatrixType(rows, cols)
    var refMat = DenseMatrix.Zero(rows, cols)
    var vec1 = DenseVector.Random(rows)
    var zeroCoords = std.vector[Vector2i]()
    var nonzeroCoords = std.vector[Vector2i]()
    initSparse[Scalar](density, refMat, m, 0, &zeroCoords, &nonzeroCoords)
    if zeroCoords.size()==0 or nonzeroCoords.size()==0:
        return
    for i in range(0, zeroCoords.size()):
        VERIFY_IS_MUCH_SMALLER_THAN( m.coeff(zeroCoords[i].x(),zeroCoords[i].y()), eps )
        if internal.is_same[SparseMatrixType, SparseMatrix[Scalar,Flags]]():
            VERIFY_RAISES_ASSERT( m.coeffRef(zeroCoords[0].x(),zeroCoords[0].y()) = 5 )
    VERIFY_IS_APPROX(m, refMat)
    m.coeffRef(nonzeroCoords[0].x(), nonzeroCoords[0].y()) = Scalar(5)
    refMat.coeffRef(nonzeroCoords[0].x(), nonzeroCoords[0].y()) = Scalar(5)
    VERIFY_IS_APPROX(m, refMat)
    VERIFY(( test_random_setter[RandomSetter[SparseMatrixType, StdMapTraits]](m,refMat,nonzeroCoords) ))
    #ifdef EIGEN_UNORDERED_MAP_SUPPORT
    VERIFY(( test_random_setter[RandomSetter[SparseMatrixType, StdUnorderedMapTraits]](m,refMat,nonzeroCoords) ))
    #endif
    #ifdef _DENSE_HASH_MAP_H_
    VERIFY(( test_random_setter[RandomSetter[SparseMatrixType, GoogleDenseHashMapTraits]](m,refMat,nonzeroCoords) ))
    #endif
    #ifdef _SPARSE_HASH_MAP_H_
    VERIFY(( test_random_setter[RandomSetter[SparseMatrixType, GoogleSparseHashMapTraits]](m,refMat,nonzeroCoords) ))
    #endif
    /*{
        SparseMatrixType m1(rows,cols), m2(rows,cols)
        DenseMatrix refM1 = DenseMatrix.Zero(rows, rows)
        initSparse[Scalar](density, refM1, m1)
        {
            Eigen.RandomSetter[SparseMatrixType] setter(m2)
            for j in range(0, m1.outerSize()):
                for i in m1.InnerIterator(m1,j):
                    setter(i.index(), j) = i.value()
        }
        VERIFY_IS_APPROX(m1, m2)
    }*/

def test_sparse_extra():
    for i in range(0, g_repeat):
        var s = Eigen.internal.random[Int](1,50)
        CALL_SUBTEST_1( sparse_extra(SparseMatrix[Float64](8, 8)) )
        CALL_SUBTEST_2( sparse_extra(SparseMatrix[ComplexFloat64](s, s)) )
        CALL_SUBTEST_1( sparse_extra(SparseMatrix[Float64](s, s)) )
        CALL_SUBTEST_3( sparse_extra(DynamicSparseMatrix[Float64](s, s)) )
        CALL_SUBTEST_3( (sparse_product[DynamicSparseMatrix[Float32, ColMajor]]()) )
        CALL_SUBTEST_3( (sparse_product[DynamicSparseMatrix[Float32, RowMajor]]()) )