# EXTERNAL DEPS (to wire in glue):
# - SquareMatrix: from WCECommon (FenestrationCommon namespace)

import unittest


class SquareMatrix:
    """Stub for SquareMatrix from WCECommon.hpp"""
    
    def __init__(self, data):
        self.data = [list(row) for row in data]
    
    def __call__(self, row, col):
        return self.data[row][col]


class TestMatrixCopyFrom(unittest.TestCase):
    
    def setUp(self):
        pass
    
    def test_1(self):
        """Begin Test: Test matrix addition operation."""
        
        a = SquareMatrix([[1, 2], [3, 4]])
        b = SquareMatrix([[2, 3], [4, 5]])
        
        a = b
        
        self.assertAlmostEqual(2, a(0, 0), places=6)
        self.assertAlmostEqual(3, a(0, 1), places=6)
        self.assertAlmostEqual(4, a(1, 0), places=6)
        self.assertAlmostEqual(5, a(1, 1), places=6)


if __name__ == '__main__':
    unittest.main()
