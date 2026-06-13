from testing import Test, expect_eq
from ...WCECommon import Table

struct TestTableInitialization(Test):
    def SetUp(inout self):

def TableInitalization():
    let tbl = Table.Table2D[Float64](
        List[Int](2, 3),
        List[Int](5, 8),
        List[List[Float64]]([1.0, 2.0], [3.0, 4.0])
    )
    let val = tbl[0, 0]
    expect_eq(4.0, val)