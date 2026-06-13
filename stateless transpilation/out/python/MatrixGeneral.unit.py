# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import SquareMatrix

import unittest

class TestMatrixGeneral(unittest.TestCase):
    def setUp(self):
        pass

    def test_set_diagonal(self):
        a = SquareMatrix([[1, 2], [3, 4]])
        b = [7, 8]

        a.set_diagonal(b)

        self.assertAlmostEqual(7, a(0, 0), places=6)
        self.assertAlmostEqual(0, a(0, 1), places=6)
        self.assertAlmostEqual(0, a(1, 0), places=6)
        self.assertAlmostEqual(8, a(1, 1), places=6)

    def test_set_identity(self):
        a = SquareMatrix([[1, 2], [3, 4]])

        a.set_identity()

        self.assertAlmostEqual(1, a(0, 0), places=6)
        self.assertAlmostEqual(0, a(0, 1), places=6)
        self.assertAlmostEqual(0, a(1, 0), places=6)
        self.assertAlmostEqual(1, a(1, 1), places=6)

    def test_set_diagonal_exception(self):
        a = SquareMatrix([[1, 2], [3, 4]])
        b = [7, 8, 9]

        with self.assertRaises(RuntimeError) as context:
            a.set_diagonal(b)

        self.assertEqual(str(context.exception), "Matrix and vector must be same size.")
