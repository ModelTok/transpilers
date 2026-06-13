// #define TEST_ENABLE_TEMPORARY_TRACKING
from main import VERIFY_EVALUATION_COUNT, VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, randomPermutationVector, g_repeat, internal

def permutationmatrices[MatrixType: AnyType](m: MatrixType) raises:
    type Scalar = MatrixType.Scalar
    alias Rows = MatrixType.RowsAtCompileTime
    alias Cols = MatrixType.ColsAtCompileTime
    alias Options = MatrixType.Options
    type LeftPermutationType = PermutationMatrix[Rows]
    type LeftTranspositionsType = Transpositions[Rows]
    type LeftPermutationVectorType = Matrix[Int, Rows, 1]
    type MapLeftPerm = Map[LeftPermutationType]
    type RightPermutationType = PermutationMatrix[Cols]
    type RightTranspositionsType = Transpositions[Cols]
    type RightPermutationVectorType = Matrix[Int, Cols, 1]
    type MapRightPerm = Map[RightPermutationType]

    var rows: Int = m.rows()
    var cols: Int = m.cols()
    var m_original: MatrixType = MatrixType.Random(rows, cols)
    var lv: LeftPermutationVectorType = LeftPermutationVectorType()
    randomPermutationVector(lv, rows)
    var lp: LeftPermutationType = LeftPermutationType(lv)
    var rv: RightPermutationVectorType = RightPermutationVectorType()
    randomPermutationVector(rv, cols)
    var rp: RightPermutationType = RightPermutationType(rv)
    var lt: LeftTranspositionsType = LeftTranspositionsType(lv)
    var rt: RightTranspositionsType = RightTranspositionsType(rv)

    var m_permuted: MatrixType = MatrixType.Random(rows, cols)
    VERIFY_EVALUATION_COUNT(m_permuted = lp * m_original * rp, 1) # 1 temp for sub expression "lp * m_original"

    for i in range(rows):
        for j in range(cols):
            VERIFY_IS_APPROX(m_permuted[lv[i], j], m_original[i, rv[j]])

    var lm: Matrix[Scalar, Rows, Rows] = Matrix[Scalar, Rows, Rows](lp)
    var rm: Matrix[Scalar, Cols, Cols] = Matrix[Scalar, Cols, Cols](rp)
    VERIFY_IS_APPROX(m_permuted, lm * m_original * rm)

    m_permuted = m_original
    VERIFY_EVALUATION_COUNT(m_permuted = lp * m_permuted * rp, 1)
    VERIFY_IS_APPROX(m_permuted, lm * m_original * rm)

    VERIFY_IS_APPROX(lp.inverse() * m_permuted * rp.inverse(), m_original)
    VERIFY_IS_APPROX(lv.asPermutation().inverse() * m_permuted * rv.asPermutation().inverse(), m_original)
    VERIFY_IS_APPROX(MapLeftPerm(lv.data(), lv.size()).inverse() * m_permuted * MapRightPerm(rv.data(), rv.size()).inverse(), m_original)

    VERIFY((lp * lp.inverse()).toDenseMatrix().isIdentity())
    VERIFY((lv.asPermutation() * lv.asPermutation().inverse()).toDenseMatrix().isIdentity())
    VERIFY((MapLeftPerm(lv.data(), lv.size()) * MapLeftPerm(lv.data(), lv.size()).inverse()).toDenseMatrix().isIdentity())

    var lv2: LeftPermutationVectorType = LeftPermutationVectorType()
    randomPermutationVector(lv2, rows)
    var lp2: LeftPermutationType = LeftPermutationType(lv2)
    var lm2: Matrix[Scalar, Rows, Rows] = Matrix[Scalar, Rows, Rows](lp2)
    VERIFY_IS_APPROX((lp * lp2).toDenseMatrix().cast[Scalar](), lm * lm2)
    VERIFY_IS_APPROX((lv.asPermutation() * lv2.asPermutation()).toDenseMatrix().cast[Scalar](), lm * lm2)
    VERIFY_IS_APPROX((MapLeftPerm(lv.data(), lv.size()) * MapLeftPerm(lv2.data(), lv2.size())).toDenseMatrix().cast[Scalar](), lm * lm2)

    var identityp: LeftPermutationType = LeftPermutationType()
    identityp.setIdentity(rows)
    VERIFY_IS_APPROX(m_original, identityp * m_original)

    m_permuted = m_original
    VERIFY_EVALUATION_COUNT(m_permuted.noalias() = lp.inverse() * m_permuted, 1) # 1 temp to allocate the mask
    VERIFY_IS_APPROX(m_permuted, lp.inverse() * m_original)

    m_permuted = m_original
    VERIFY_EVALUATION_COUNT(m_permuted.noalias() = m_permuted * rp.inverse(), 1) # 1 temp to allocate the mask
    VERIFY_IS_APPROX(m_permuted, m_original * rp.inverse())

    m_permuted = m_original
    VERIFY_EVALUATION_COUNT(m_permuted.noalias() = lp * m_permuted, 1) # 1 temp to allocate the mask
    VERIFY_IS_APPROX(m_permuted, lp * m_original)

    m_permuted = m_original
    VERIFY_EVALUATION_COUNT(m_permuted.noalias() = m_permuted * rp, 1) # 1 temp to allocate the mask
    VERIFY_IS_APPROX(m_permuted, m_original * rp)

    if rows > 1 and cols > 1:
        lp2 = lp
        var i: Int = internal.random[Int](0, rows - 1)
        var j: Int
        while True:
            j = internal.random[Int](0, rows - 1)
            if j != i:
                break
        lp2.applyTranspositionOnTheLeft(i, j)
        lm = lp
        lm.row(i).swap(lm.row(j))
        VERIFY_IS_APPROX(lm, lp2.toDenseMatrix().cast[Scalar]())

        var rp2: RightPermutationType = rp
        i = internal.random[Int](0, cols - 1)
        while True:
            j = internal.random[Int](0, cols - 1)
            if j != i:
                break
        rp2.applyTranspositionOnTheRight(i, j)
        rm = rp
        rm.col(i).swap(rm.col(j))
        VERIFY_IS_APPROX(rm, rp2.toDenseMatrix().cast[Scalar]())

    {
        var A: Matrix[Scalar, Cols, Cols] = rp
        var B: Matrix[Scalar, Cols, Cols] = rp.transpose()
        VERIFY_IS_APPROX(A, B.transpose())
    }

    m_permuted = m_original
    lp = lt
    rp = rt
    VERIFY_EVALUATION_COUNT(m_permuted = lt * m_permuted * rt, 1)
    VERIFY_IS_APPROX(m_permuted, lp * m_original * rp.transpose())
    VERIFY_IS_APPROX(lt.inverse() * m_permuted * rt.inverse(), m_original)

def bug890[T: AnyType]() raises:
    type MatrixType = Matrix[T, Dynamic, Dynamic]
    type VectorType = Matrix[T, Dynamic, 1]
    type S = Stride[Dynamic, Dynamic]
    type MapType = Map[MatrixType, Aligned, S]
    type Perm = PermutationMatrix[Dynamic]

    var v1: VectorType = VectorType(2)
    var v2: VectorType = VectorType(2)
    var op: MatrixType = MatrixType(4)
    var rhs: VectorType = VectorType(2)
    v1 << 666, 667
    op << 1, 0, 0, 1
    rhs << 42, 42
    var P: Perm = Perm(2)
    P.indices() << 1, 0
    MapType(v1.data(), 2, 1, S(1, 1)) = P * MapType(rhs.data(), 2, 1, S(1, 1))
    VERIFY_IS_APPROX(v1, (P * rhs).eval())
    MapType(v1.data(), 2, 1, S(1, 1)) = P.inverse() * MapType(rhs.data(), 2, 1, S(1, 1))
    VERIFY_IS_APPROX(v1, (P.inverse() * rhs).eval())

def test_permutationmatrices() raises:
    for i in range(g_repeat):
        CALL_SUBTEST_1(permutationmatrices[Matrix[Float32, 1, 1]](Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_2(permutationmatrices[Matrix3f](Matrix3f()))
        CALL_SUBTEST_3(permutationmatrices[Matrix[Float64, 3, 3, RowMajor]](Matrix[Float64, 3, 3, RowMajor]()))
        CALL_SUBTEST_4(permutationmatrices[Matrix4d](Matrix4d()))
        CALL_SUBTEST_5(permutationmatrices[Matrix[Float64, 40, 60]](Matrix[Float64, 40, 60]()))
        CALL_SUBTEST_6(permutationmatrices[Matrix[Float64, Dynamic, Dynamic, RowMajor]](Matrix[Float64, Dynamic, Dynamic, RowMajor](20, 30)))
        CALL_SUBTEST_7(permutationmatrices[MatrixXcf](MatrixXcf(15, 10)))

    CALL_SUBTEST_5(bug890[Float64]())