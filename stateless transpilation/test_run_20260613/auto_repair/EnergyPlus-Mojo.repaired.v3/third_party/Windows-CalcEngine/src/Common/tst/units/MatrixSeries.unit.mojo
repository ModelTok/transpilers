from testing import expect, expect_equal, expect_almost_equal
from ...WCECommon import CMatrixSeries, SquareMatrix, CSeries

struct TestMatrixSeries:
    var m_MatrixSeries: CMatrixSeries

    def SetUp(self):
        var mat = List[SquareMatrix]()
        var wl = List[Float64]()
        mat.append(SquareMatrix([[2.8, 3.4], [3.9, 7.5]]))
        wl.append(0.45)
        mat.append(SquareMatrix([[7.4, 9.6], [7.7, 1.3]]))
        wl.append(0.50)
        mat.append(SquareMatrix([[8.3, 0.1], [2.2, 3.6]]))
        wl.append(0.55)
        mat.append(SquareMatrix([[1.5, 9.3], [9.0, 7.4]]))
        wl.append(0.60)
        self.m_MatrixSeries = CMatrixSeries(2, 2)
        for i in range(wl.size):
            self.m_MatrixSeries.addProperties(wl[i], mat[i])

    def getMatrix(self) -> &CMatrixSeries:
        return self.m_MatrixSeries[]

@test
def Test1() raises:
    SCOPED_TRACE("Begin Test: Test matrix series sum.")
    var fixture = TestMatrixSeries()
    fixture.SetUp()
    var aMat = fixture.getMatrix()
    var minLambda: Float64 = 0.45
    var maxLambda: Float64 = 0.65
    var scaleFactors = List[Float64](1, 1, 1, 1)
    var mat = aMat.getSquaredMatrixSums(minLambda, maxLambda, scaleFactors)
    var correctResults = SquareMatrix([[20., 22.4], [22.8, 19.8]])
    expect_equal(correctResults.size(), mat.size())
    for i in range(mat.size()):
        for j in range(mat.size()):
            expect_almost_equal(correctResults[i, j], mat[i, j], 1e-6)

@test
def Test2() raises:
    SCOPED_TRACE("Begin Test: Test matrix series multiplication.")
    var fixture = TestMatrixSeries()
    fixture.SetUp()
    var mat = CMatrixSeries(fixture.getMatrix())
    var multiplier = CSeries()
    multiplier.addProperty(0.45, 1.6)
    multiplier.addProperty(0.50, 3.8)
    multiplier.addProperty(0.55, 2.4)
    multiplier.addProperty(0.60, 8.3)
    mat.mMult(multiplier)
    var correctResults = List[List[Float64]](
        List[Float64](4.48, 28.12, 19.92, 12.45),
        List[Float64](5.44, 36.48, 0.24, 77.19),
        List[Float64](6.24, 29.26, 5.28, 74.7),
        List[Float64](12., 4.94, 8.64, 61.42),
    )
    var matrixResults = List[CSeries]()
    for i in range(mat.size1()):
        for j in range(mat.size2()):
            var aSeries = mat[i][j]
            matrixResults.append(aSeries)
    for i in range(matrixResults.size):
        for k in range(matrixResults[i].size):
            expect_almost_equal(correctResults[i][k], matrixResults[i][k].value(), 1e-6)