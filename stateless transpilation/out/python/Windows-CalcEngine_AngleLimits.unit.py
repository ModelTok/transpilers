from typing import *
from energyplus import *

class TestAngleLimits(unittest.TestCase):
    def test_angle_limits_1(self):
        aLimits = CAngleLimits(-15, 15)
        angle = 350
        isInLimits = aLimits.isInLimits(angle)
        self.assertTrue(isInLimits)
