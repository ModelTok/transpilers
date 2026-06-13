# EXTERNAL DEPS (to wire in glue):
# - Table::Table2D<Float64> from WCECommon.hpp
#   Methods: row(index: Int) -> List[Float64], column(index: Int) -> List[Float64]

from collections import List


struct Table2D:
    var dims: Tuple[Int, Int]
    var labels: Tuple[Int, Int]
    var data: List[List[Float64]]
    
    fn __init__(inout self, dims: Tuple[Int, Int], labels: Tuple[Int, Int], data: List[List[Float64]]):
        self.dims = dims
        self.labels = labels
        self.data = data
    
    fn row(self, index: Int) -> List[Float64]:
        return self.data[index]
    
    fn column(self, index: Int) -> List[Float64]:
        var result = List[Float64]()
        for i in range(len(self.data)):
            result.append(self.data[i][index])
        return result


struct TestTableData:
    var table_: Table2D
    
    fn __init__(inout self):
        var data = List[List[Float64]]()
        
        var row0 = List[Float64]()
        row0.append(1.0)
        row0.append(2.0)
        data.append(row0)
        
        var row1 = List[Float64]()
        row1.append(3.0)
        row1.append(4.0)
        data.append(row1)
        
        self.table_ = Table2D((2, 3), (5, 8), data)
    
    fn set_up(inout self):
        pass
    
    fn get_table(self) -> Table2D:
        return self.table_
    
    fn test_access_row(self):
        var tbl = self.get_table()
        var row = tbl.row(0)
        
        var correct = List[Float64]()
        correct.append(1.0)
        correct.append(2.0)
        
        assert len(row) == 2
        for i in range(len(correct)):
            assert abs(row[i] - correct[i]) < 1e-6
    
    fn test_access_column(self):
        var tbl = self.get_table()
        var row = tbl.column(1)
        
        var correct = List[Float64]()
        correct.append(2.0)
        correct.append(4.0)
        
        assert len(row) == 2
        for i in range(len(correct)):
            assert abs(row[i] - correct[i]) < 1e-6
