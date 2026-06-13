from sparse import initSparse
from Eigen.internal import random, is_same
from Eigen import (
    SparseMatrix,
    Matrix,
    DenseMatrix,
    DenseVector,
    VectorXi,
    Triplet,
    Map,
    MappedSparseMatrix,
    Transpose,
    SparseSparseProduct,
)
from Eigen.test import (
    VERIFY_IS_APPROX,
    VERIFY_IS_EQUAL,
    VERIFY_RAISES_ASSERT,
    VERIFY,
    CALL_SUBTEST_1,
    CALL_SUBTEST_2,
    CALL_SUBTEST_3,
    CALL_SUBTEST_4,
    CALL_SUBTEST_5,
    CALL_SUBTEST_6,
)
from utils import numext_abs
from math import abs

var g_realloc_count: Int = 0
# define EIGEN_SPARSE_COMPRESSED_STORAGE_REALLOCATE_PLUGIN g_realloc_count++; // simulated by macro, no action in Mojo

def sparse_basic[SparseMatrixType: AnyType](ref: SparseMatrixType):
    type StorageIndex = SparseMatrixType.StorageIndex
    type Vector2 = Matrix[StorageIndex, 2, 1]
    var rows = ref.rows()
    var cols = ref.cols()
    type Scalar = SparseMatrixType.Scalar
    type RealScalar = SparseMatrixType.RealScalar
    alias Flags = SparseMatrixType.Flags
    var density = (max)(8.0 / (rows * cols), 0.01)
    type DenseMatrix = Matrix[Scalar, Dynamic, Dynamic]
    type DenseVector = Matrix[Scalar, Dynamic, 1]
    var eps: Scalar = 1e-6
    var s1: Scalar = random[Scalar]()
    # first block
    var m = SparseMatrixType(rows, cols)
    var refMat = DenseMatrix.Zero(rows, cols)
    var vec1 = DenseVector.Random(rows)
    var zeroCoords = List[Vector2]()
    var nonzeroCoords = List[Vector2]()
    initSparse[Scalar](density, refMat, m, 0, zeroCoords, nonzeroCoords)
    for i in range(zeroCoords.size):
        VERIFY_IS_MUCH_SMALLER_THAN(m.coeff(zeroCoords[i].x(), zeroCoords[i].y()), eps)
        if is_same[SparseMatrixType, SparseMatrix[Scalar, Flags]]():
            VERIFY_RAISES_ASSERT(m.coeffRef(zeroCoords[i].x(), zeroCoords[i].y()) = 5)
    VERIFY_IS_APPROX(m, refMat)
    if not nonzeroCoords.empty():
        m.coeffRef(nonzeroCoords[0].x(), nonzeroCoords[0].y()) = Scalar(5)
        refMat.coeffRef(nonzeroCoords[0].x(), nonzeroCoords[0].y()) = Scalar(5)
    VERIFY_IS_APPROX(m, refMat)
    VERIFY_RAISES_ASSERT(m.coeffRef(-1, 1) = 0)
    VERIFY_RAISES_ASSERT(m.coeffRef(0, m.cols()) = 0)

    # second block
    var m1 = DenseMatrix(rows, cols)
    m1.setZero()
    var m2 = SparseMatrixType(rows, cols)
    var call_reserve = (random[Int]() % 2) != 0
    var nnz = random[Int](1, int(rows) / 2)
    if call_reserve:
        if (random[Int]() % 2) != 0:
            m2.reserve(VectorXi.Constant(m2.outerSize(), int(nnz)))
        else:
            m2.reserve(m2.outerSize() * nnz)
    g_realloc_count = 0
    for j in range(cols):
        for k in range(nnz):
            var i = random[Index](0, rows - 1)
            if m1.coeff(i, j) == Scalar(0):
                m2.insert(i, j) = m1(i, j) = random[Scalar]()
    if call_reserve and not SparseMatrixType.IsRowMajor:
        VERIFY(g_realloc_count == 0)
    m2.finalize()
    VERIFY_IS_APPROX(m2, m1)

    # third block
    var m1b = DenseMatrix(rows, cols)
    m1b.setZero()
    var m2b = SparseMatrixType(rows, cols)
    if (random[Int]() % 2) != 0:
        m2b.reserve(VectorXi.Constant(m2b.outerSize(), 2))
    for k in range(rows * cols):
        var i = random[Index](0, rows - 1)
        var j = random[Index](0, cols - 1)
        if (m1b.coeff(i, j) == Scalar(0)) and ((random[Int]() % 2) != 0):
            m2b.insert(i, j) = m1b(i, j) = random[Scalar]()
        else:
            var v = random[Scalar]()
            m2b.coeffRef(i, j) += v
            m1b(i, j) += v
    VERIFY_IS_APPROX(m2b, m1b)

    # fourth block (mode loop)
    for mode in range(4):
        var m1c = DenseMatrix(rows, cols)
        m1c.setZero()
        var m2c = SparseMatrixType(rows, cols)
        var r = VectorXi.Constant(
            m2c.outerSize(),
            (mode % 2 == 0) ? int(m2c.innerSize()) : max(1, int(m2c.innerSize()) / 8),
        )
        m2c.reserve(r)
        for k in range(rows * cols):
            var i = random[Index](0, rows - 1)
            var j = random[Index](0, cols - 1)
            if m1c.coeff(i, j) == Scalar(0):
                m2c.insert(i, j) = m1c(i, j) = random[Scalar]()
            if mode == 3:
                m2c.reserve(r)
        if (random[Int]() % 2) != 0:
            m2c.makeCompressed()
        VERIFY_IS_APPROX(m2c, m1c)

    # fifth block (arithmetic and inner product)
    var refM1 = DenseMatrix.Zero(rows, cols)
    var refM2 = DenseMatrix.Zero(rows, cols)
    var refM3 = DenseMatrix.Zero(rows, cols)
    var refM4 = DenseMatrix.Zero(rows, cols)
    var md1 = SparseMatrixType(rows, cols)
    var md2 = SparseMatrixType(rows, cols)
    var md3 = SparseMatrixType(rows, cols)
    var md4 = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refM1, md1)
    initSparse[Scalar](density, refM2, md2)
    initSparse[Scalar](density, refM3, md3)
    initSparse[Scalar](density, refM4, md4)
    if random[Bool]():
        md1.makeCompressed()
    var m1_nnz = md1.nonZeros()
    VERIFY_IS_APPROX(md1 * s1, refM1 * s1)
    VERIFY_IS_APPROX(md1 + md2, refM1 + refM2)
    VERIFY_IS_APPROX(md1 + md2 + md3, refM1 + refM2 + refM3)
    VERIFY_IS_APPROX(md3.cwiseProduct(md1 + md2), refM3.cwiseProduct(refM1 + refM2))
    VERIFY_IS_APPROX(md1 * s1 - md2, refM1 * s1 - refM2)
    VERIFY_IS_APPROX(md4 = md1 / s1, refM1 / s1)
    VERIFY_IS_EQUAL(md4.nonZeros(), m1_nnz)
    if SparseMatrixType.IsRowMajor:
        VERIFY_IS_APPROX(md1.innerVector(0).dot(refM2.row(0)), refM1.row(0).dot(refM2.row(0)))
    else:
        VERIFY_IS_APPROX(md1.innerVector(0).dot(refM2.col(0)), refM1.col(0).dot(refM2.col(0)))
    var rv = DenseVector.Random(md1.cols())
    var cv = DenseVector.Random(md1.rows())
    var r = random[Index](0, md1.rows() - 2)
    var c = random[Index](0, md1.cols() - 1)
    VERIFY_IS_APPROX((md1.template block[1, Dynamic](r, 0, 1, md1.cols()).dot(rv)), refM1.row(r).dot(rv))
    VERIFY_IS_APPROX(md1.row(r).dot(rv), refM1.row(r).dot(rv))
    VERIFY_IS_APPROX(md1.col(c).dot(cv), refM1.col(c).dot(cv))
    VERIFY_IS_APPROX(md1.conjugate(), refM1.conjugate())
    VERIFY_IS_APPROX(md1.real(), refM1.real())
    refM4.setRandom()
    VERIFY_IS_APPROX(md3.cwiseProduct(refM4), refM3.cwiseProduct(refM4))
    VERIFY_IS_APPROX(refM4.cwiseProduct(md3), refM4.cwiseProduct(refM3))
    VERIFY_IS_APPROX(refM4 + md3, refM4 + refM3)
    VERIFY_IS_APPROX(md3 + refM4, refM3 + refM4)
    VERIFY_IS_APPROX(refM4 - md3, refM4 - refM3)
    VERIFY_IS_APPROX(md3 - refM4, refM3 - refM4)
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + RealScalar(0.5) * md3).eval(), RealScalar(0.5) * refM4 + RealScalar(0.5) * refM3)
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + md3 * RealScalar(0.5)).eval(), RealScalar(0.5) * refM4 + RealScalar(0.5) * refM3)
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + md3.cwiseProduct(md3)).eval(), RealScalar(0.5) * refM4 + refM3.cwiseProduct(refM3))
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + RealScalar(0.5) * md3).eval(), RealScalar(0.5) * refM4 + RealScalar(0.5) * refM3)
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + md3 * RealScalar(0.5)).eval(), RealScalar(0.5) * refM4 + RealScalar(0.5) * refM3)
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + (md3 + md3)).eval(), RealScalar(0.5) * refM4 + (refM3 + refM3))
    VERIFY_IS_APPROX(((refM3 + md3) + RealScalar(0.5) * md3).eval(), RealScalar(0.5) * refM3 + (refM3 + refM3))
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + (refM3 + md3)).eval(), RealScalar(0.5) * refM4 + (refM3 + refM3))
    VERIFY_IS_APPROX((RealScalar(0.5) * refM4 + (md3 + refM3)).eval(), RealScalar(0.5) * refM4 + (refM3 + refM3))
    VERIFY_IS_APPROX(md1.sum(), refM1.sum())
    md4 = md1
    refM4 = md4
    VERIFY_IS_APPROX(md1 *= s1, refM1 *= s1)
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    VERIFY_IS_APPROX(md1 /= s1, refM1 /= s1)
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    VERIFY_IS_APPROX(md1 += md2, refM1 += refM2)
    VERIFY_IS_APPROX(md1 -= md2, refM1 -= refM2)
    if rows >= 2 and cols >= 2:
        VERIFY_RAISES_ASSERT(md1 += md1.innerVector(0))
        VERIFY_RAISES_ASSERT(md1 -= md1.innerVector(0))
        VERIFY_RAISES_ASSERT(refM1 -= md1.innerVector(0))
        VERIFY_RAISES_ASSERT(refM1 += md1.innerVector(0))
    md1 = md4
    refM1 = refM4
    VERIFY_IS_APPROX((md1 = -md1), (refM1 = -refM1))
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    md1 = md4
    refM1 = refM4
    VERIFY_IS_APPROX((md1 = md1.transpose()), (refM1 = refM1.transpose().eval()))
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    md1 = md4
    refM1 = refM4
    VERIFY_IS_APPROX((md1 = -md1.transpose()), (refM1 = -refM1.transpose().eval()))
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    md1 = md4
    refM1 = refM4
    VERIFY_IS_APPROX((md1 += -md1), (refM1 += -refM1))
    VERIFY_IS_EQUAL(md1.nonZeros(), m1_nnz)
    md1 = md4
    refM1 = refM4
    if md1.isCompressed():
        VERIFY_IS_APPROX(md1.coeffs().sum(), md1.sum())
        md1.coeffs() += s1
        for j in range(md1.outerSize()):
            for it in md1.innerIterators(j):
                refM1(it.row(), it.col()) += s1
        VERIFY_IS_APPROX(md1, refM1)

    # SpBool section
    type SpBool = SparseMatrix[Bool, SparseMatrixType.Options, SparseMatrixType.StorageIndex]
    var mb1: SpBool = md1.real().template cast[Bool]()
    var mb2: SpBool = md2.real().template cast[Bool]()
    VERIFY_IS_EQUAL(mb1.template cast[Int]().sum(), refM1.real().template cast[Bool]().count())
    VERIFY_IS_EQUAL((mb1 && mb2).template cast[Int]().sum(), (refM1.real().template cast[Bool]() && refM2.real().template cast[Bool]()).count())
    VERIFY_IS_EQUAL((mb1 || mb2).template cast[Int]().sum(), (refM1.real().template cast[Bool]() || refM2.real().template cast[Bool]()).count())
    var mb3 = mb1 && mb2
    if mb1.coeffs().all() and mb2.coeffs().all():
        VERIFY_IS_EQUAL(mb3.nonZeros(), (refM1.real().template cast[Bool]() && refM2.real().template cast[Bool]()).count())

    # ReverseInnerIterator block
    var refMat2 = DenseMatrix.Zero(rows, cols)
    var m2e = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2, m2e)
    var ref_value = List[Scalar](m2e.innerSize())
    var ref_index = List[Index](m2e.innerSize())
    if random[Bool]():
        m2e.makeCompressed()
    for j in range(m2e.outerSize()):
        var count_forward = 0
        for it in m2e.innerIterators(j):
            ref_value[ref_value.size() - 1 - count_forward] = it.value()
            ref_index[ref_index.size() - 1 - count_forward] = it.index()
            count_forward += 1
        var count_reverse = 0
        for it in m2e.reverseInnerIterators(j):
            VERIFY_IS_APPROX(abs(ref_value[ref_value.size() - count_forward + count_reverse]) + 1, abs(it.value()) + 1)
            VERIFY_IS_EQUAL(ref_index[ref_index.size() - count_forward + count_reverse], it.index())
            count_reverse += 1
        VERIFY_IS_EQUAL(count_forward, count_reverse)

    # transpose/adjoint block
    var refMat2b = DenseMatrix.Zero(rows, cols)
    var m2f = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2b, m2f)
    VERIFY_IS_APPROX(m2f.transpose().eval(), refMat2b.transpose().eval())
    VERIFY_IS_APPROX(m2f.transpose(), refMat2b.transpose())
    VERIFY_IS_APPROX(SparseMatrixType(m2f.adjoint()), refMat2b.adjoint())
    var m3g = Transpose[SparseMatrixType].PlainObject(m2f)
    VERIFY(m2f.isApprox(m3g))

    # prune block
    var m2h = SparseMatrixType(rows, cols)
    var refM2h = DenseMatrix(rows, cols)
    refM2h.setZero()
    var countFalseNonZero = 0
    var countTrueNonZero = 0
    m2h.reserve(VectorXi.Constant(m2h.outerSize(), int(m2h.innerSize())))
    for j in range(m2h.cols()):
        for i in range(m2h.rows()):
            var x = random[float](0, 1)
            if x < 0.1:

            elif x < 0.5:
                countFalseNonZero += 1
                m2h.insert(i, j) = Scalar(0)
            else:
                countTrueNonZero += 1
                m2h.insert(i, j) = Scalar(1)
                refM2h(i, j) = Scalar(1)
    if random[Bool]():
        m2h.makeCompressed()
    VERIFY(countFalseNonZero + countTrueNonZero == m2h.nonZeros())
    if countTrueNonZero > 0:
        VERIFY_IS_APPROX(m2h, refM2h)
    m2h.prune(Scalar(1))
    VERIFY(countTrueNonZero == m2h.nonZeros())
    VERIFY_IS_APPROX(m2h, refM2h)

    # Triplet block
    type TripletType = Triplet[Scalar, StorageIndex]
    var triplets = List[TripletType]()
    var ntriplets = rows * cols
    triplets.reserve(ntriplets)
    var refMat_sum = DenseMatrix.Zero(rows, cols)
    var refMat_prod = DenseMatrix.Zero(rows, cols)
    var refMat_last = DenseMatrix.Zero(rows, cols)
    for i in range(ntriplets):
        var r = random[StorageIndex](0, StorageIndex(rows - 1))
        var c = random[StorageIndex](0, StorageIndex(cols - 1))
        var v = random[Scalar]()
        triplets.append(TripletType(r, c, v))
        refMat_sum(r, c) += v
        if abs(refMat_prod(r, c)) == 0:
            refMat_prod(r, c) = v
        else:
            refMat_prod(r, c) *= v
        refMat_last(r, c) = v
    var m3i = SparseMatrixType(rows, cols)
    m3i.setFromTriplets(triplets.begin(), triplets.end())
    VERIFY_IS_APPROX(m3i, refMat_sum)
    m3i.setFromTriplets(triplets.begin(), triplets.end(), lambda a, b: a * b) # multiplies
    VERIFY_IS_APPROX(m3i, refMat_prod)
    # C++11 lambda: [](Scalar, Scalar b) -> Scalar { return b; }
    m3i.setFromTriplets(triplets.begin(), triplets.end(), lambda a, b: b)
    VERIFY_IS_APPROX(m3i, refMat_last)

    # Map block
    var refMat2c = DenseMatrix(rows, cols), refMat3c = DenseMatrix(rows, cols)
    var m2j = SparseMatrixType(rows, cols), m3j = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2c, m2j)
    initSparse[Scalar](density, refMat3c, m3j)
    # Map version 1
    var mapMat2 = Map[SparseMatrixType](m2j.rows(), m2j.cols(), m2j.nonZeros(), m2j.outerIndexPtr(), m2j.innerIndexPtr(), m2j.valuePtr(), m2j.innerNonZeroPtr())
    var mapMat3 = Map[SparseMatrixType](m3j.rows(), m3j.cols(), m3j.nonZeros(), m3j.outerIndexPtr(), m3j.innerIndexPtr(), m3j.valuePtr(), m3j.innerNonZeroPtr())
    VERIFY_IS_APPROX(mapMat2 + mapMat3, refMat2c + refMat3c)
    VERIFY_IS_APPROX(mapMat2 + mapMat3, refMat2c + refMat3c)
    # Mapped version
    var mapMat2b = MappedSparseMatrix[Scalar, SparseMatrixType.Options, StorageIndex](m2j.rows(), m2j.cols(), m2j.nonZeros(), m2j.outerIndexPtr(), m2j.innerIndexPtr(), m2j.valuePtr(), m2j.innerNonZeroPtr())
    var mapMat3b = MappedSparseMatrix[Scalar, SparseMatrixType.Options, StorageIndex](m3j.rows(), m3j.cols(), m3j.nonZeros(), m3j.outerIndexPtr(), m3j.innerIndexPtr(), m3j.valuePtr(), m3j.innerNonZeroPtr())
    VERIFY_IS_APPROX(mapMat2b + mapMat3b, refMat2c + refMat3c)
    VERIFY_IS_APPROX(mapMat2b + mapMat3b, refMat2c + refMat3c)
    var i = random[Index](0, rows - 1)
    var j = random[Index](0, cols - 1)
    m2j.coeffRef(i, j) = 123
    if random[Bool]():
        m2j.makeCompressed()
    var mapMat2c = Map[SparseMatrixType](rows, cols, m2j.nonZeros(), m2j.outerIndexPtr(), m2j.innerIndexPtr(), m2j.valuePtr(), m2j.innerNonZeroPtr())
    VERIFY_IS_EQUAL(m2j.coeff(i, j), Scalar(123))
    VERIFY_IS_EQUAL(mapMat2c.coeff(i, j), Scalar(123))
    mapMat2c.coeffRef(i, j) = -123
    VERIFY_IS_EQUAL(m2j.coeff(i, j), Scalar(-123))

    # triangularView block
    var refMat2d = DenseMatrix(rows, cols), refMat3d = DenseMatrix(rows, cols)
    var m2k = SparseMatrixType(rows, cols), m3k = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2d, m2k)
    refMat3d = refMat2d.template triangularView[Lower]()
    m3k = m2k.template triangularView[Lower]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = refMat2d.template triangularView[Upper]()
    m3k = m2k.template triangularView[Upper]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = refMat2d.template triangularView[UnitUpper]()
    m3k = m2k.template triangularView[UnitUpper]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = refMat2d.template triangularView[UnitLower]()
    m3k = m2k.template triangularView[UnitLower]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = refMat2d.template triangularView[StrictlyUpper]()
    m3k = m2k.template triangularView[StrictlyUpper]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = refMat2d.template triangularView[StrictlyLower]()
    m3k = m2k.template triangularView[StrictlyLower]()
    VERIFY_IS_APPROX(m3k, refMat3d)
    refMat3d = m2k.template triangularView[StrictlyUpper]()
    VERIFY_IS_APPROX(refMat3d, DenseMatrix(refMat2d.template triangularView[StrictlyUpper]()))

    # selfadjointView block (column-major only)
    if not SparseMatrixType.IsRowMajor:
        var refMat2e = DenseMatrix(rows, rows), refMat3e = DenseMatrix(rows, rows)
        var m2l = SparseMatrixType(rows, rows), m3l = SparseMatrixType(rows, rows)
        initSparse[Scalar](density, refMat2e, m2l)
        refMat3e = refMat2e.template selfadjointView[Lower]()
        m3l = m2l.template selfadjointView[Lower]()
        VERIFY_IS_APPROX(m3l, refMat3e)
        refMat3e += refMat2e.template selfadjointView[Lower]()
        m3l += m2l.template selfadjointView[Lower]()
        VERIFY_IS_APPROX(m3l, refMat3e)
        refMat3e -= refMat2e.template selfadjointView[Lower]()
        m3l -= m2l.template selfadjointView[Lower]()
        VERIFY_IS_APPROX(m3l, refMat3e)
        var m4l = SparseMatrixType(rows, rows + 1)
        VERIFY_RAISES_ASSERT(m4l.template selfadjointView[Lower]())
        VERIFY_RAISES_ASSERT(m4l.template selfadjointView[Upper]())

    # product & sparseView block
    var refMat2f = DenseMatrix.Zero(rows, rows)
    var m2m = SparseMatrixType(rows, rows)
    initSparse[Scalar](density, refMat2f, m2m)
    VERIFY_IS_APPROX(m2m.eval(), refMat2f.sparseView().eval())
    VERIFY_IS_APPROX((s1 * m2m).eval(), (s1 * refMat2f).sparseView().eval())
    VERIFY_IS_APPROX((m2m + m2m).eval(), (refMat2f + refMat2f).sparseView().eval())
    VERIFY_IS_APPROX((m2m * m2m).eval(), (refMat2f.lazyProduct(refMat2f)).sparseView().eval())
    VERIFY_IS_APPROX((m2m * m2m).eval(), (refMat2f * refMat2f).sparseView().eval())

    # diagonal block
    var refMat2g = DenseMatrix.Zero(rows, cols)
    var m2n = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2g, m2n)
    VERIFY_IS_APPROX(m2n.diagonal(), refMat2g.diagonal().eval())
    var d = m2n.diagonal()
    VERIFY_IS_APPROX(d, refMat2g.diagonal().eval())
    d = m2n.diagonal().array()
    VERIFY_IS_APPROX(d, refMat2g.diagonal().eval())
    # const_cast version: use as_const? we assume m2n is not const
    VERIFY_IS_APPROX(m2n.diagonal(), refMat2g.diagonal().eval()) # const override not needed
    initSparse[Scalar](density, refMat2g, m2n, ForceNonZeroDiag)
    m2n.diagonal() += refMat2g.diagonal()
    refMat2g.diagonal() += refMat2g.diagonal()
    VERIFY_IS_APPROX(m2n, refMat2g)

    # asDiagonal block
    var dx = DenseVector.Random(rows)
    var refMat2h = dx.asDiagonal()
    var m2o = SparseMatrixType(rows, rows)
    m2o = dx.asDiagonal()
    VERIFY_IS_APPROX(m2o, refMat2h)
    var m3o = SparseMatrixType(dx.asDiagonal())
    VERIFY_IS_APPROX(m3o, refMat2h)
    refMat2h += dx.asDiagonal()
    m2o += dx.asDiagonal()
    VERIFY_IS_APPROX(m2o, refMat2h)

    # conservativeResize block
    var inc = List[(StorageIndex, StorageIndex)]()
    if rows > 3 and cols > 2:
        inc.append((-3, -2))
    inc.append((0, 0))
    inc.append((3, 2))
    inc.append((3, 0))
    inc.append((0, 3))
    for pair in inc:
        var incRows = pair[0]
        var incCols = pair[1]
        var m1p = SparseMatrixType(rows, cols)
        var refMat1p = DenseMatrix.Zero(rows, cols)
        initSparse[Scalar](density, refMat1p, m1p)
        m1p.conservativeResize(rows + incRows, cols + incCols)
        refMat1p.conservativeResize(rows + incRows, cols + incCols)
        if incRows > 0:
            refMat1p.bottomRows(incRows).setZero()
        if incCols > 0:
            refMat1p.rightCols(incCols).setZero()
        VERIFY_IS_APPROX(m1p, refMat1p)
        if incRows > 0:
            m1p.insert(m1p.rows() - 1, 0) = refMat1p(refMat1p.rows() - 1, 0) = 1
        if incCols > 0:
            m1p.insert(0, m1p.cols() - 1) = refMat1p(0, refMat1p.cols() - 1) = 1
        VERIFY_IS_APPROX(m1p, refMat1p)

    # setIdentity block
    var refMat1q = DenseMatrix.Identity(rows, rows)
    var m1q = SparseMatrixType(rows, rows)
    m1q.setIdentity()
    VERIFY_IS_APPROX(m1q, refMat1q)
    for k in range(rows * rows // 4):
        var iq = random[Index](0, rows - 1)
        var jq = random[Index](0, rows - 1)
        var vq = random[Scalar]()
        m1q.coeffRef(iq, jq) = vq
        refMat1q.coeffRef(iq, jq) = vq
        VERIFY_IS_APPROX(m1q, refMat1q)
        if random[Index](0, 10) < 2:
            m1q.makeCompressed()
    m1q.setIdentity()
    refMat1q.setIdentity()
    VERIFY_IS_APPROX(m1q, refMat1q)

    # Iterator block (InnerIterator)
    type IteratorType = SparseMatrixType.InnerIterator
    var refMat2r = DenseMatrix.Zero(rows, cols)
    var m2r = SparseMatrixType(rows, cols)
    initSparse[Scalar](density, refMat2r, m2r)
    var static_array = List[IteratorType](2)
    static_array[0] = IteratorType(m2r, 0)
    static_array[1] = IteratorType(m2r, m2r.outerSize() - 1)
    VERIFY(static_array[0] or m2r.innerVector(static_array[0].outer()).nonZeros() == 0)
    VERIFY(static_array[1] or m2r.innerVector(static_array[1].outer()).nonZeros() == 0)
    if static_array[0] and static_array[1]:
        ++static_array[1]
        static_array[1] = IteratorType(m2r, 0)
        VERIFY(static_array[1])
        VERIFY(static_array[1].index() == static_array[0].index())
        VERIFY(static_array[1].outer() == static_array[0].outer())
        VERIFY(static_array[1].value() == static_array[0].value())
    var iters = List[IteratorType](2)
    iters[0] = IteratorType(m2r, 0)
    iters[1] = IteratorType(m2r, m2r.outerSize() - 1)

def big_sparse_triplet[SparseMatrixType: AnyType](rows: Index, cols: Index, density: double):
    type StorageIndex = SparseMatrixType.StorageIndex
    type Scalar = SparseMatrixType.Scalar
    type TripletType = Triplet[Scalar, Index]
    var triplets = List[TripletType]()
    var nelements = density * rows * cols
    VERIFY(nelements >= 0 and nelements < NumTraits[StorageIndex].highest())
    var ntriplets = Index(nelements)
    triplets.reserve(ntriplets)
    var sum = Scalar(0)
    for i in range(ntriplets):
        var r = random[Index](0, rows - 1)
        var c = random[Index](0, cols - 1)
        var v = numext_abs(random[Scalar]())
        triplets.append(TripletType(r, c, v))
        sum += v
    var m = SparseMatrixType(rows, cols)
    m.setFromTriplets(triplets.begin(), triplets.end())
    VERIFY(m.nonZeros() <= ntriplets)
    VERIFY_IS_APPROX(sum, m.sum())

def test_sparse_basic():
    for i in range(g_repeat):
        var r = random[Int](1, 200)
        var c = random[Int](1, 200)
        if random[Int](0, 4) == 0:
            r = c
        # EIGEN_UNUSED_VARIABLE(r+c) // ignore
        CALL_SUBTEST_1(sparse_basic[SparseMatrix[double]](SparseMatrix[double](1, 1)))
        CALL_SUBTEST_1(sparse_basic[SparseMatrix[double]](SparseMatrix[double](8, 8)))
        CALL_SUBTEST_2(sparse_basic[SparseMatrix[complex[double], ColMajor]](SparseMatrix[complex[double], ColMajor](r, c)))
        CALL_SUBTEST_2(sparse_basic[SparseMatrix[complex[double], RowMajor]](SparseMatrix[complex[double], RowMajor](r, c)))
        CALL_SUBTEST_1(sparse_basic[SparseMatrix[double]](SparseMatrix[double](r, c)))
        CALL_SUBTEST_5(sparse_basic[SparseMatrix[double, ColMajor, long int]](SparseMatrix[double, ColMajor, long int](r, c)))
        CALL_SUBTEST_5(sparse_basic[SparseMatrix[double, RowMajor, long int]](SparseMatrix[double, RowMajor, long int](r, c)))
        r = random[Int](1, 100)
        c = random[Int](1, 100)
        if random[Int](0, 4) == 0:
            r = c
        CALL_SUBTEST_6(sparse_basic[SparseMatrix[double, ColMajor, short int]](SparseMatrix[double, ColMajor, short int](short(r), short(c))))
        CALL_SUBTEST_6(sparse_basic[SparseMatrix[double, RowMajor, short int]](SparseMatrix[double, RowMajor, short int](short(r), short(c))))
    CALL_SUBTEST_3(big_sparse_triplet[SparseMatrix[float, RowMajor, int]](10000, 10000, 0.125))
    CALL_SUBTEST_4(big_sparse_triplet[SparseMatrix[double, ColMajor, long int]](10000, 10000, 0.125))
    # EIGEN_TEST_PART_7 block
    # ifdef not directly translatable; include if EIGEN_TEST_PART_7 defined
    if True: # assume test part 7 active
        var n = random[Int](200, 600)
        var mat = SparseMatrix[complex[double], 0, long](n, n)
        var val: complex[double]
        for i in range(n):
            mat.coeffRef(i, i % (n // 10)) = val
            VERIFY(mat.data().allocatedSize() < 20 * n)