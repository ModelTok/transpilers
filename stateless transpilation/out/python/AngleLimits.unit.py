# EXTERNAL DEPS (to wire in glue):
# - CAngleLimits: from WCESingleLayerOptics.hpp

import unittest

class TestAngleLimits(unittest.TestCase):
    def setUp(self):
        pass
    
    def test_angle_limits_1(self):
        a_limits = CAngleLimits(-15, 15)
        angle = 350
        is_in_limits = a_limits.isInLimits(angle)
        self.assertEqual(is_in_limits, True)

if __name__ == '__main__':
    unittest.main()
