# EXTERNAL DEPS (to wire in glue):
# None

import unittest
from typing import List

class SquareMatrix:
    def __init__(self, data: List[List[float]]):
        self.data = data

    def __getitem__(self, index: int) -> List[float]:
        return self.data[index]

class CLinearSolver:
    @staticmethod
    def solveSystem(matrix: SquareMatrix, vector: List[float]) -> List[float]:
        # Placeholder for actual implementation
        pass

class TestLinearSolver1(unittest.TestCase):
    def setUp(self) -> None:
        pass

    def test1(self):
        matrix = SquareMatrix([[2, 1, 3], [2, 6, 8], [6, 8, 18]])
        vector = [1, 3, 5]
        solution = CLinearSolver.solveSystem(matrix, vector)
        self.assertAlmostEqual(3.0 / 10.0, solution[0], places=6)
        self.assertAlmostEqual(2.0 / 5.0, solution[1], places=6)
        self.assertAlmostEqual(0.0, solution[2], places=6)

    def test2(self):
        matrix = SquareMatrix([[32817.2867004354, 1, 0, -32808.3972386696],
                               [1.28054053432588, -1, 0, 0],
                               [0, 0, -1, 1.26433319889839],
                               [32808.3972386696, 0, -1, -32810.4664383299]])
        vector = [3163.241853, -73.479324, -67.913411, -1070.271453]
        solution = CLinearSolver.solveSystem(matrix, vector)
        self.assertAlmostEqual(303.040746, solution[0], places=6)
        self.assertAlmostEqual(461.535283, solution[1], places=6)
        self.assertAlmostEqual(451.057585, solution[2], places=6)
        self.assertAlmostEqual(303.040507, solution[3], places=6)

    def test_solver_exception(self):
        matrix = SquareMatrix([[1, 2, 3], [7, 2, 1], [2, 4, 2]])
        vector = [1, 2]
        with self.assertRaisesRegex(RuntimeError, "Matrix and vector for system of linear equations are not same size."):
            CLinearSolver.solveSystem(matrix, vector)

if __name__ == '__main__':
    unittest.main()
