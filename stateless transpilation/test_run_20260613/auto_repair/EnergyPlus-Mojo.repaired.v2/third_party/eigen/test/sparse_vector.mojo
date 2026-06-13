from sparse import *
from Eigen import internal, Dynamic, Matrix, SparseVector, SparseMatrix, DenseMatrix, DenseVector
from Eigen import VERIFY_IS_MUCH_SMALLER_THAN, VERIFY_IS_APPROX, VERIFY
from Eigen import initSparse, g_repeat, CALL_SUBTEST_1, CALL_SUBTEST_2, EIGEN_UNUSED_VARIABLE

def sparse_vector[Scalar: AnyType, StorageIndex: AnyType](rows: Int, cols: Int):
    var densityMat: Float64 = (max)(8.0 / (rows * cols), 0.01)
    var densityVec: Float64 = (max)(8.0 / rows, 0.1)
    alias DenseMatrix = Matrix[Scalar, Dynamic, Dynamic]
    alias DenseVector = Matrix[Scalar, Dynamic, 1]
    alias SparseVectorType = SparseVector[Scalar, 0, StorageIndex]
    alias SparseMatrixType = SparseMatrix[Scalar, 0, StorageIndex]
    var eps: Scalar = 1e-6
    var m1: SparseMatrixType = SparseMatrixType(rows, rows)
    var v1: SparseVectorType = SparseVectorType(rows)
    var v2: SparseVectorType = SparseVectorType(rows)
    var v3: SparseVectorType = SparseVectorType(rows)
    var refM1: DenseMatrix = DenseMatrix.Zero(rows, rows)
    var refV1: DenseVector = DenseVector.Random(rows)
    var refV2: DenseVector = DenseVector.Random(rows)
    var refV3: DenseVector = DenseVector.Random(rows)
    var zerocoords: List[Int] = List[Int]()
    var nonzerocoords: List[Int] = List[Int]()
    initSparse[Scalar](densityVec, refV1, v1, &zerocoords, &nonzerocoords)
    initSparse[Scalar](densityMat, refM1, m1)
    initSparse[Scalar](densityVec, refV2, v2)
    initSparse[Scalar](densityVec, refV3, v3)
    var s1: Scalar = internal.random[Scalar]()
    for i in range(zerocoords.size):
        VERIFY_IS_MUCH_SMALLER_THAN(v1.coeff(zerocoords[i]), eps)
    do:
        VERIFY(int(nonzerocoords.size) == v1.nonZeros())
        var j: Int = 0
        for it in SparseVectorType.InnerIterator(v1):
            VERIFY(nonzerocoords[j] == it.index())
            VERIFY(it.value() == v1.coeff(it.index()))
            VERIFY(it.value() == refV1.coeff(it.index()))
            j += 1
    do:
        var v4: SparseVectorType = SparseVectorType(rows)
        var v5: DenseVector = DenseVector.Zero(rows)
        for k in range(rows):
            var i: Int = internal.random[Int](0, rows - 1)
            var v: Scalar = internal.random[Scalar]()
            v4.coeffRef(i) += v
            v5.coeffRef(i) += v
        VERIFY_IS_APPROX(v4, v5)
    v1.coeffRef(nonzerocoords[0]) = Scalar(5)
    refV1.coeffRef(nonzerocoords[0]) = Scalar(5)
    VERIFY_IS_APPROX(v1, refV1)
    VERIFY_IS_APPROX(v1 + v2, refV1 + refV2)
    VERIFY_IS_APPROX(v1 + v2 + v3, refV1 + refV2 + refV3)
    VERIFY_IS_APPROX(v1 * s1 - v2, refV1 * s1 - refV2)
    VERIFY_IS_APPROX(v1 *= s1, refV1 *= s1)
    VERIFY_IS_APPROX(v1 /= s1, refV1 /= s1)
    VERIFY_IS_APPROX(v1 += v2, refV1 += refV2)
    VERIFY_IS_APPROX(v1 -= v2, refV1 -= refV2)
    VERIFY_IS_APPROX(v1.dot(v2), refV1.dot(refV2))
    VERIFY_IS_APPROX(v1.dot(refV2), refV1.dot(refV2))
    VERIFY_IS_APPROX(m1 * v2, refM1 * refV2)
    VERIFY_IS_APPROX(v1.dot(m1 * v2), refV1.dot(refM1 * refV2))
    do:
        var i: Int = internal.random[Int](0, rows - 1)
        VERIFY_IS_APPROX(v1.dot(m1.col(i)), refV1.dot(refM1.col(i)))
    VERIFY_IS_APPROX(v1.squaredNorm(), refV1.squaredNorm())
    VERIFY_IS_APPROX(v1.blueNorm(), refV1.blueNorm())
    VERIFY_IS_APPROX((v1 = -v1), (refV1 = -refV1))
    VERIFY_IS_APPROX((v1 = v1.transpose()), (refV1 = refV1.transpose().eval()))
    VERIFY_IS_APPROX((v1 += -v1), (refV1 += -refV1))
    var mv1: SparseMatrixType
    VERIFY_IS_APPROX((mv1 = v1), v1)
    VERIFY_IS_APPROX(mv1, (v1 = mv1))
    VERIFY_IS_APPROX(mv1, (v1 = mv1.transpose()))
    refV3.resize(0)
    VERIFY_IS_APPROX(refV3 = v1.transpose(), v1.toDense())
    VERIFY_IS_APPROX(DenseVector(v1), v1.toDense())
    do:
        var inc: List[StorageIndex] = List[StorageIndex]()
        if rows > 3:
            inc.push_back(-3)
        inc.push_back(0)
        inc.push_back(3)
        inc.push_back(1)
        inc.push_back(10)
        for i in range(inc.size):
            var incRows: StorageIndex = inc[i]
            var vec1: SparseVectorType = SparseVectorType(rows)
            var refVec1: DenseVector = DenseVector.Zero(rows)
            initSparse[Scalar](densityVec, refVec1, vec1)
            vec1.conservativeResize(rows + incRows)
            refVec1.conservativeResize(rows + incRows)
            if incRows > 0:
                refVec1.tail(incRows).setZero()
            VERIFY_IS_APPROX(vec1, refVec1)
            if incRows > 0:
                vec1.insert(vec1.rows() - 1) = 1
                refVec1(refVec1.rows() - 1) = 1
            VERIFY_IS_APPROX(vec1, refVec1)

def test_sparse_vector():
    for i in range(g_repeat):
        var r: Int = Eigen.internal.random[Int](1, 500)
        var c: Int = Eigen.internal.random[Int](1, 500)
        if Eigen.internal.random[Int](0, 4) == 0:
            r = c
        EIGEN_UNUSED_VARIABLE(r + c)
        CALL_SUBTEST_1((sparse_vector[Float64, Int](8, 8)))
        CALL_SUBTEST_2((sparse_vector[ComplexFloat64, Int](r, c)))
        CALL_SUBTEST_1((sparse_vector[Float64, Int64](r, c)))
        CALL_SUBTEST_1((sparse_vector[Float64, Int16](r, c)))