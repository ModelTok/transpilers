from WCECommon import SquareMatrix, CLinearSolver
from testing import assert_approx_equal, assert_equal, test

@value
struct TestLinearSolver1:
    def SetUp(self):

@test
def TestLinearSolver1_Test1():
    # SCOPED_TRACE("Begin Test: Test Linear Solver (1) - Solving simple matrix.")
    var aMatrix = SquareMatrix(List[List[Float64]](List[Float64](2, 1, 3), List[Float64](2, 6, 8), List[Float64](6, 8, 18)))
    var aVector = List[Float64](1, 3, 5)
    var aSolution = CLinearSolver.solveSystem(aMatrix, aVector)
    assert_approx_equal(3.0 / 10.0, aSolution[0], 1e-6)
    assert_approx_equal(2.0 / 5.0, aSolution[1], 1e-6)
    assert_approx_equal(0.0, aSolution[2], 1e-6)

@test
def TestLinearSolver1_Test2():
    # SCOPED_TRACE("Begin Test: Test Linear Solver (2) - Solving simple matrix.")
    var aMatrix = SquareMatrix(List[List[Float64]](
        List[Float64](32817.2867004354, 1, 0, -32808.3972386696),
        List[Float64](1.28054053432588, -1, 0, 0),
        List[Float64](0, 0, -1, 1.26433319889839),
        List[Float64](32808.3972386696, 0, -1, -32810.4664383299)
    ))
    var aVector = List[Float64](3163.241853, -73.479324, -67.913411, -1070.271453)
    var aSolution = CLinearSolver.solveSystem(aMatrix, aVector)
    assert_approx_equal(303.040746, aSolution[0], 1e-6)
    assert_approx_equal(461.535283, aSolution[1], 1e-6)
    assert_approx_equal(451.057585, aSolution[2], 1e-6)
    assert_approx_equal(303.040507, aSolution[3], 1e-6)

@test
def TestLinearSolver1_TestSolverException():
    # SCOPED_TRACE("Begin Test: Test Linear Solver - Test exception.")
    var aMatrix = SquareMatrix(List[List[Float64]](List[Float64](1, 2, 3), List[Float64](7, 2, 1), List[Float64](2, 4, 2)))
    var aVector = List[Float64](1, 2)
    try:
        var aSolution = CLinearSolver.solveSystem(aMatrix, aVector)
    except Error as err:
        assert_equal(err.message, "Matrix and vector for system of linear equations are not same size.")