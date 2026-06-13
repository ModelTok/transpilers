# EXTERNAL DEPS (to wire in glue):
# - linearInterpolation: from WCECommon.hpp

import unittest

def linearInterpolation(x1, x2, y1, y2, x):
    raise NotImplementedError("Wire in linearInterpolation from WCECommon.hpp")

class LinearInterpolationTest(unittest.TestCase):
    def setUp(self):
        pass
    
    def test_1(self):
        """Begin Test: Simple linear interpolation."""
        x1 = 1.0
        x2 = 2.0
        y1 = 10.0
        y2 = 20.0
        x = 1.5
        correct_y = 15.0
        evaluated_y = linearInterpolation(x1, x2, y1, y2, x)
        self.assertAlmostEqual(correct_y, evaluated_y, delta=1e-6)

if __name__ == '__main__':
    unittest.main()
