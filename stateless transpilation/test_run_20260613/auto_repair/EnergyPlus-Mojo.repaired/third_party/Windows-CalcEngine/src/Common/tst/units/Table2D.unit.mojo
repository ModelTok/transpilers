from testing import Test
from WCECommon import Table

@value
class TestTableData(Test):
    var table_: Table.Table2D[Float64]

    def __init__(inout self):
        self.table_ = Table.Table2D[Float64]({2, 3}, {5, 8}, {{1, 2}, {3, 4}})

    def SetUp(inout self):

    def getTable(self) -> Table.Table2D[Float64]:
        return self.table_

def TestTableData_AccessRow():
    let tbl = TestTableData().getTable()
    let row = tbl.row(0)
    let correct = List[Float64](1, 2)
    assert_eq(2, len(row))
    for i in range(len(correct)):
        assert_approx_eq(row[i], correct[i], 1e-6)

def TestTableData_AccessColumn():
    let tbl = TestTableData().getTable()
    let row = tbl.column(1)
    let correct = List[Float64](2, 4)
    assert_eq(2, len(row))
    for i in range(len(correct)):
        assert_approx_eq(row[i], correct[i], 1e-6)