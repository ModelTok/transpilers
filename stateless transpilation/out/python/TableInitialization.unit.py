import unittest


class Table2D:
    def __init__(self, dims1, dims2, data):
        self.dims1 = dims1
        self.dims2 = dims2
        self.data = data
    
    def __call__(self, i, j):
        return self.data[i][j]


class TestTableInitialization(unittest.TestCase):
    
    def setUp(self):
        pass
    
    def test_table_initialization(self):
        tbl = Table2D([2, 3], [5, 8], [[1, 2], [3, 4]])
        val = tbl(1, 1)
        self.assertEqual(4.0, val)


if __name__ == '__main__':
    unittest.main()
