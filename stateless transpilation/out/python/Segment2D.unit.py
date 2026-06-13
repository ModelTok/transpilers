# EXTERNAL DEPS (to wire in glue):
# - CPoint2D: class from WCEViewer.hpp
# - CSegment2D: class from WCEViewer.hpp

import unittest
import math


class CPoint2D:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y


class CSegment2D:
    def __init__(self, start: CPoint2D, end: CPoint2D):
        self.start = start
        self.end = end
    
    def length(self) -> float:
        dx = self.end.x - self.start.x
        dy = self.end.y - self.start.y
        return math.sqrt(dx * dx + dy * dy)


class TestSegment2D(unittest.TestCase):
    def setUp(self):
        pass
    
    def test_segment_2d_test1(self):
        a_start_point = CPoint2D(0, 0)
        a_end_point = CPoint2D(10, 0)
        
        a_segment = CSegment2D(a_start_point, a_end_point)
        length = a_segment.length()
        
        self.assertAlmostEqual(10, length, places=6)
    
    def test_segment_2d_test2(self):
        a_start_point = CPoint2D(0, 0)
        a_end_point = CPoint2D(10, 10)
        
        a_segment = CSegment2D(a_start_point, a_end_point)
        length = a_segment.length()
        
        self.assertAlmostEqual(14.14213562, length, places=6)


if __name__ == '__main__':
    unittest.main()
