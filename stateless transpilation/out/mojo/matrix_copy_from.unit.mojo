# EXTERNAL DEPS (to wire in glue):
# - SquareMatrix: from WCECommon (FenestrationCommon namespace)

from math import abs


struct SquareMatrix:
    """Stub for SquareMatrix from WCECommon.hpp"""
    var row0: InlineArray[Float64, 2]
    var row1: InlineArray[Float64, 2]
    
    fn __init__(inout self, row0: InlineArray[Float64, 2], row1: InlineArray[Float64, 2]):
        self.row0 = row0
        self.row1 = row1
    
    fn __call__(self, row: Int, col: Int) -> Float64:
        if row == 0:
            return self.row0[col]
        else:
            return self.row1[col]


fn assert_near(expected: Float64, actual: Float64, tolerance: Float64):
    let diff = abs(expected - actual)
    assert diff <= tolerance


struct TestMatrixCopyFrom:
    
    fn setUp(inout self):
        pass
    
    fn test_1(self):
        """Begin Test: Test matrix addition operation."""
        
        var a = SquareMatrix(InlineArray[Float64, 2](1.0, 2.0), InlineArray[Float64, 2](3.0, 4.0))
        var b = SquareMatrix(InlineArray[Float64, 2](2.0, 3.0), InlineArray[Float64, 2](4.0, 5.0))
        
        a = b
        
        assert_near(2.0, a(0, 0), 1e-6)
        assert_near(3.0, a(0, 1), 1e-6)
        assert_near(4.0, a(1, 0), 1e-6)
        assert_near(5.0, a(1, 1), 1e-6)


fn main():
    var test = TestMatrixCopyFrom()
    test.setUp()
    test.test_1()
