from main import *
from Eigen import Matrix, Matrix4d, MatrixXcf, MatrixXf, Dynamic
from internal import random

def compare_corner[MatrixType: AnyRegType](matrix: MatrixType, const_matrix: MatrixType, A: String, B: String) -> None:
    # This is a placeholder; the macro is expanded inline.
    # Not used directly; we expand the macro manually below.

def corners[MatrixType: AnyRegType](m: MatrixType):
    var rows = m.rows()
    var cols = m.cols()
    var r = random[Int](1, rows)
    var c = random[Int](1, cols)
    var matrix = MatrixType.Random(rows, cols)
    var const_matrix = MatrixType.Random(rows, cols)
    VERIFY_IS_EQUAL(matrix.topLeftCorner(r, c), matrix.block(0, 0, r, c))
    VERIFY_IS_EQUAL(const_matrix.topLeftCorner(r, c), const_matrix.block(0, 0, r, c))
    VERIFY_IS_EQUAL(matrix.topRightCorner(r, c), matrix.block(0, cols - c, r, c))
    VERIFY_IS_EQUAL(const_matrix.topRightCorner(r, c), const_matrix.block(0, cols - c, r, c))
    VERIFY_IS_EQUAL(matrix.bottomLeftCorner(r, c), matrix.block(rows - r, 0, r, c))
    VERIFY_IS_EQUAL(const_matrix.bottomLeftCorner(r, c), const_matrix.block(rows - r, 0, r, c))
    VERIFY_IS_EQUAL(matrix.bottomRightCorner(r, c), matrix.block(rows - r, cols - c, r, c))
    VERIFY_IS_EQUAL(const_matrix.bottomRightCorner(r, c), const_matrix.block(rows - r, cols - c, r, c))
    var sr = random[Int](1, rows) - 1
    var nr = random[Int](1, rows - sr)
    var sc = random[Int](1, cols) - 1
    var nc = random[Int](1, cols - sc)
    VERIFY_IS_EQUAL(matrix.topRows(r), matrix.block(0, 0, r, cols))
    VERIFY_IS_EQUAL(const_matrix.topRows(r), const_matrix.block(0, 0, r, cols))
    VERIFY_IS_EQUAL(matrix.middleRows(sr, nr), matrix.block(sr, 0, nr, cols))
    VERIFY_IS_EQUAL(const_matrix.middleRows(sr, nr), const_matrix.block(sr, 0, nr, cols))
    VERIFY_IS_EQUAL(matrix.bottomRows(r), matrix.block(rows - r, 0, r, cols))
    VERIFY_IS_EQUAL(const_matrix.bottomRows(r), const_matrix.block(rows - r, 0, r, cols))
    VERIFY_IS_EQUAL(matrix.leftCols(c), matrix.block(0, 0, rows, c))
    VERIFY_IS_EQUAL(const_matrix.leftCols(c), const_matrix.block(0, 0, rows, c))
    VERIFY_IS_EQUAL(matrix.middleCols(sc, nc), matrix.block(0, sc, rows, nc))
    VERIFY_IS_EQUAL(const_matrix.middleCols(sc, nc), const_matrix.block(0, sc, rows, nc))
    VERIFY_IS_EQUAL(matrix.rightCols(c), matrix.block(0, cols - c, rows, c))
    VERIFY_IS_EQUAL(const_matrix.rightCols(c), const_matrix.block(0, cols - c, rows, c))

def corners_fixedsize[MatrixType: AnyRegType, CRows: Int, CCols: Int, SRows: Int, SCols: Int]():
    var matrix = MatrixType.Random()
    var const_matrix = MatrixType.Random()
    alias rows = MatrixType.RowsAtCompileTime
    alias cols = MatrixType.ColsAtCompileTime
    alias r = CRows
    alias c = CCols
    alias sr = SRows
    alias sc = SCols
    VERIFY_IS_EQUAL((matrix.topLeftCorner[r, c]()), (matrix.block[r, c](0, 0)))
    VERIFY_IS_EQUAL((matrix.topRightCorner[r, c]()), (matrix.block[r, c](0, cols - c)))
    VERIFY_IS_EQUAL((matrix.bottomLeftCorner[r, c]()), (matrix.block[r, c](rows - r, 0)))
    VERIFY_IS_EQUAL((matrix.bottomRightCorner[r, c]()), (matrix.block[r, c](rows - r, cols - c)))
    VERIFY_IS_EQUAL((matrix.topLeftCorner[r, c]()), (matrix.topLeftCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((matrix.topRightCorner[r, c]()), (matrix.topRightCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((matrix.bottomLeftCorner[r, c]()), (matrix.bottomLeftCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((matrix.bottomRightCorner[r, c]()), (matrix.bottomRightCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((matrix.topLeftCorner[r, c]()), (matrix.topLeftCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((matrix.topRightCorner[r, c]()), (matrix.topRightCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((matrix.bottomLeftCorner[r, c]()), (matrix.bottomLeftCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((matrix.bottomRightCorner[r, c]()), (matrix.bottomRightCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((matrix.topRows[r]()), (matrix.block[r, cols](0, 0)))
    VERIFY_IS_EQUAL((matrix.middleRows[r](sr)), (matrix.block[r, cols](sr, 0)))
    VERIFY_IS_EQUAL((matrix.bottomRows[r]()), (matrix.block[r, cols](rows - r, 0)))
    VERIFY_IS_EQUAL((matrix.leftCols[c]()), (matrix.block[rows, c](0, 0)))
    VERIFY_IS_EQUAL((matrix.middleCols[c](sc)), (matrix.block[rows, c](0, sc)))
    VERIFY_IS_EQUAL((matrix.rightCols[c]()), (matrix.block[rows, c](0, cols - c)))
    VERIFY_IS_EQUAL((const_matrix.topLeftCorner[r, c]()), (const_matrix.block[r, c](0, 0)))
    VERIFY_IS_EQUAL((const_matrix.topRightCorner[r, c]()), (const_matrix.block[r, c](0, cols - c)))
    VERIFY_IS_EQUAL((const_matrix.bottomLeftCorner[r, c]()), (const_matrix.block[r, c](rows - r, 0)))
    VERIFY_IS_EQUAL((const_matrix.bottomRightCorner[r, c]()), (const_matrix.block[r, c](rows - r, cols - c)))
    VERIFY_IS_EQUAL((const_matrix.topLeftCorner[r, c]()), (const_matrix.topLeftCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((const_matrix.topRightCorner[r, c]()), (const_matrix.topRightCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((const_matrix.bottomLeftCorner[r, c]()), (const_matrix.bottomLeftCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((const_matrix.bottomRightCorner[r, c]()), (const_matrix.bottomRightCorner[r, Dynamic](r, c)))
    VERIFY_IS_EQUAL((const_matrix.topLeftCorner[r, c]()), (const_matrix.topLeftCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((const_matrix.topRightCorner[r, c]()), (const_matrix.topRightCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((const_matrix.bottomLeftCorner[r, c]()), (const_matrix.bottomLeftCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((const_matrix.bottomRightCorner[r, c]()), (const_matrix.bottomRightCorner[Dynamic, c](r, c)))
    VERIFY_IS_EQUAL((const_matrix.topRows[r]()), (const_matrix.block[r, cols](0, 0)))
    VERIFY_IS_EQUAL((const_matrix.middleRows[r](sr)), (const_matrix.block[r, cols](sr, 0)))
    VERIFY_IS_EQUAL((const_matrix.bottomRows[r]()), (const_matrix.block[r, cols](rows - r, 0)))
    VERIFY_IS_EQUAL((const_matrix.leftCols[c]()), (const_matrix.block[rows, c](0, 0)))
    VERIFY_IS_EQUAL((const_matrix.middleCols[c](sc)), (const_matrix.block[rows, c](0, sc)))
    VERIFY_IS_EQUAL((const_matrix.rightCols[c]()), (const_matrix.block[rows, c](0, cols - c)))

def test_corners():
    for i in range(g_repeat):
        CALL_SUBTEST_1(corners[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(corners[Matrix4d](Matrix4d()))
        CALL_SUBTEST_3(corners[Matrix[int32, 10, 12]](Matrix[int32, 10, 12]()))
        CALL_SUBTEST_4(corners[MatrixXcf](MatrixXcf(5, 7)))
        CALL_SUBTEST_5(corners[MatrixXf](MatrixXf(21, 20)))
        CALL_SUBTEST_1(corners_fixedsize[Matrix[float32, 1, 1], 1, 1, 0, 0]())
        CALL_SUBTEST_2(corners_fixedsize[Matrix4d, 2, 2, 1, 1]())
        CALL_SUBTEST_3(corners_fixedsize[Matrix[int32, 10, 12], 4, 7, 5, 2]())