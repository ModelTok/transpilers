from main import main, g_repeat, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, CALL_SUBTEST_8, CALL_SUBTEST_9, CALL_SUBTEST_10, VERIFY, VERIFY_IS_APPROX
from internal import random

def matrixVisitor[MatrixType: AnyType](p: MatrixType):
    alias Scalar = MatrixType.Scalar
    var rows = p.rows()
    var cols = p.cols()
    var m: MatrixType
    m = MatrixType.Random(rows, cols)
    for i in range(m.size()):
        for i2 in range(i):
            while m[i] == m[i2]:
                m[i] = random[Scalar]()
    var minc = Scalar(1000)
    var maxc = Scalar(-1000)
    var minrow: Index = 0
    var mincol: Index = 0
    var maxrow: Index = 0
    var maxcol: Index = 0
    for j in range(cols):
        for i in range(rows):
            if m[i, j] < minc:
                minc = m[i, j]
                minrow = i
                mincol = j
            if m[i, j] > maxc:
                maxc = m[i, j]
                maxrow = i
                maxcol = j
    var eigen_minrow: Index
    var eigen_mincol: Index
    var eigen_maxrow: Index
    var eigen_maxcol: Index
    var eigen_minc: Scalar
    var eigen_maxc: Scalar
    eigen_minc = m.minCoeff(&eigen_minrow, &eigen_mincol)
    eigen_maxc = m.maxCoeff(&eigen_maxrow, &eigen_maxcol)
    VERIFY(minrow == eigen_minrow)
    VERIFY(maxrow == eigen_maxrow)
    VERIFY(mincol == eigen_mincol)
    VERIFY(maxcol == eigen_maxcol)
    VERIFY_IS_APPROX(minc, eigen_minc)
    VERIFY_IS_APPROX(maxc, eigen_maxc)
    VERIFY_IS_APPROX(minc, m.minCoeff())
    VERIFY_IS_APPROX(maxc, m.maxCoeff())
    eigen_maxc = (m.adjoint() * m).maxCoeff(&eigen_maxrow, &eigen_maxcol)
    eigen_maxc = (m.adjoint() * m).eval().maxCoeff(&maxrow, &maxcol)
    VERIFY(maxrow == eigen_maxrow)
    VERIFY(maxcol == eigen_maxcol)

def vectorVisitor[VectorType: AnyType](w: VectorType):
    alias Scalar = VectorType.Scalar
    var size = w.size()
    var v: VectorType
    v = VectorType.Random(size)
    for i in range(size):
        for i2 in range(i):
            while v[i] == v[i2]:
                v[i] = random[Scalar]()
    var minc = v[0]
    var maxc = v[0]
    var minidx: Index = 0
    var maxidx: Index = 0
    for i in range(size):
        if v[i] < minc:
            minc = v[i]
            minidx = i
        if v[i] > maxc:
            maxc = v[i]
            maxidx = i
    var eigen_minidx: Index
    var eigen_maxidx: Index
    var eigen_minc: Scalar
    var eigen_maxc: Scalar
    eigen_minc = v.minCoeff(&eigen_minidx)
    eigen_maxc = v.maxCoeff(&eigen_maxidx)
    VERIFY(minidx == eigen_minidx)
    VERIFY(maxidx == eigen_maxidx)
    VERIFY_IS_APPROX(minc, eigen_minc)
    VERIFY_IS_APPROX(maxc, eigen_maxc)
    VERIFY_IS_APPROX(minc, v.minCoeff())
    VERIFY_IS_APPROX(maxc, v.maxCoeff())
    var idx0 = random[Index](0, size - 1)
    var idx1 = eigen_minidx
    var idx2 = eigen_maxidx
    var v1 = VectorType(v)
    var v2 = VectorType(v)
    v1[idx0] = v1[idx1]
    v2[idx0] = v2[idx2]
    v1.minCoeff(&eigen_minidx)
    v2.maxCoeff(&eigen_maxidx)
    VERIFY(eigen_minidx == (min)(idx0, idx1))
    VERIFY(eigen_maxidx == (min)(idx0, idx2))

def test_visitor():
    for i in range(g_repeat):
        CALL_SUBTEST_1(matrixVisitor[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(matrixVisitor[Matrix2f]())
        CALL_SUBTEST_3(matrixVisitor[Matrix4d]())
        CALL_SUBTEST_4(matrixVisitor[MatrixXd[8, 12]]())
        CALL_SUBTEST_5(matrixVisitor[Matrix[float64, Dynamic, Dynamic, RowMajor]](20, 20))
        CALL_SUBTEST_6(matrixVisitor[MatrixXi[8, 12]]())
    for i in range(g_repeat):
        CALL_SUBTEST_7(vectorVisitor[Vector4f]())
        CALL_SUBTEST_7(vectorVisitor[Matrix[int32, 12, 1]]())
        CALL_SUBTEST_8(vectorVisitor[VectorXd[10]]())
        CALL_SUBTEST_9(vectorVisitor[RowVectorXd[10]]())
        CALL_SUBTEST_10(vectorVisitor[VectorXf[33]]())