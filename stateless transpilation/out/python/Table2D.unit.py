# EXTERNAL DEPS (to wire in glue):
# - Table::Table2D<double> from WCECommon.hpp
#   Methods: row(index: int) -> list, column(index: int) -> list

import unittest


class Table2D:
    """Stub for Table::Table2D<double> from WCECommon.hpp"""
    
    def __init__(self, dims, labels, data):
        self.dims = dims
        self.labels = labels
        self.data = data
    
    def row(self, index: int) -> list:
        return self.data[index]
    
    def column(self, index: int) -> list:
        return [row[index] for row in self.data]


class TestTableData(unittest.TestCase):
    """Test fixture for Table2D"""
    
    def setUp(self):
        self.table_ = Table2D((2, 3), (5, 8), [[1, 2], [3, 4]])
    
    def getTable(self) -> Table2D:
        return self.table_
    
    def test_access_row(self):
        tbl = self.getTable()
        row = tbl.row(0)
        
        correct = [1, 2]
        
        self.assertEqual(len(row), 2)
        for i in range(len(correct)):
            self.assertAlmostEqual(row[i], correct[i], places=6)
    
    def test_access_column(self):
        tbl = self.getTable()
        row = tbl.column(1)
        
        correct = [2, 4]
        
        self.assertEqual(len(row), 2)
        for i in range(len(correct)):
            self.assertAlmostEqual(row[i], correct[i], places=6)


if __name__ == '__main__':
    unittest.main()
