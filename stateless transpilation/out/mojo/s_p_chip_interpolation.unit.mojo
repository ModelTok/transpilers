# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import IInterpolation2D, CSPChipInterpolation2D

import unittest
from typing import List, Tuple

class TestSPChipInterpolation(unittest.TestCase):
    def setUp(self) -> None:
        aPoints: List[Tuple[float, float]] = [(24, 0.683876),
                                              (34, 0.631739),
                                              (48, 0.532746),
                                              (62, 0.410234),
                                              (75, 0.330733)]

        self.m_Interpolation = CSPChipInterpolation2D(aPoints)

    def getInterpolation(self) -> IInterpolation2D:
        return self.m_Interpolation

    def test_interpolations(self):
        with self.subTest(msg="Begin Test: Interpolation in various ranges."):
            aInterpolation = self.getInterpolation()

            value = 28
            value = aInterpolation.getValue(value)
            self.assertAlmostEqual(value, 0.664845, delta=1e-5)

            value = 40.9106
            value = aInterpolation.getValue(value)
            self.assertAlmostEqual(value, 0.586155, delta=1e-5)

            value = 20
            value = aInterpolation.getValue(value)
            self.assertAlmostEqual(value, 0.683876, delta=1e-5)

            value = 80
            value = aInterpolation.getValue(value)
            self.assertAlmostEqual(value, 0.330733, delta=1e-5)

if __name__ == '__main__':
    unittest.main()
