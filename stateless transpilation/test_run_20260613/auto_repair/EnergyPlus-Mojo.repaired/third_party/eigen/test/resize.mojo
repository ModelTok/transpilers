from main import main, VERIFY, CALL_SUBTEST
from Eigen import MatrixXf, Matrix, VectorXf, RowVectorXf, DenseIndex

def resizeLikeTest[rows: DenseIndex, cols: DenseIndex]():
    var A = MatrixXf(rows, cols)
    var B = MatrixXf()
    var C = Matrix[float64, rows, cols]()
    B.resizeLike(A)
    C.resizeLike(B)  # Shouldn't crash.
    VERIFY(B.rows() == rows and B.cols() == cols)
    var x = VectorXf(rows)
    var y = RowVectorXf()
    y.resizeLike(x)
    VERIFY(y.rows() == 1 and y.cols() == rows)
    y.resize(cols)
    x.resizeLike(y)
    VERIFY(x.rows() == cols and x.cols() == 1)

def resizeLikeTest12():
    resizeLikeTest[1, 2]()

def resizeLikeTest1020():
    resizeLikeTest[10, 20]()

def resizeLikeTest31():
    resizeLikeTest[3, 1]()

def test_resize():
    CALL_SUBTEST(resizeLikeTest12())
    CALL_SUBTEST(resizeLikeTest1020())
    CALL_SUBTEST(resizeLikeTest31())