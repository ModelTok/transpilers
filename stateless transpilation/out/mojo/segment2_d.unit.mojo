# EXTERNAL DEPS (to wire in glue):
# - CPoint2D: struct from WCEViewer.hpp
# - CSegment2D: struct from WCEViewer.hpp

from math import sqrt, fabs


struct CPoint2D:
    var x: Float64
    var y: Float64
    
    fn __init__(inout self, x: Float64, y: Float64):
        self.x = x
        self.y = y


struct CSegment2D:
    var start: CPoint2D
    var end: CPoint2D
    
    fn __init__(inout self, start: CPoint2D, end: CPoint2D):
        self.start = start
        self.end = end
    
    fn length(self) -> Float64:
        let dx = self.end.x - self.start.x
        let dy = self.end.y - self.start.y
        return sqrt(dx * dx + dy * dy)


struct TestSegment2D:
    fn setUp(inout self):
        pass
    
    fn segment_2d_test1(self):
        let a_start_point = CPoint2D(0.0, 0.0)
        let a_end_point = CPoint2D(10.0, 0.0)
        
        let a_segment = CSegment2D(a_start_point, a_end_point)
        let length = a_segment.length()
        
        assert fabs(10.0 - length) < 1e-6
    
    fn segment_2d_test2(self):
        let a_start_point = CPoint2D(0.0, 0.0)
        let a_end_point = CPoint2D(10.0, 10.0)
        
        let a_segment = CSegment2D(a_start_point, a_end_point)
        let length = a_segment.length()
        
        assert fabs(14.14213562 - length) < 1e-6


fn main():
    var test = TestSegment2D()
    test.setUp()
    test.segment_2d_test1()
    test.segment_2d_test2()
