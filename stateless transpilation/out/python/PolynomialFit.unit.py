# EXTERNAL DEPS (to wire in glue):
# - PolynomialFit: from WCECommon.hpp (FenestrationCommon namespace) - C++ class for polynomial fitting

import unittest
from typing import List, Tuple
from WCECommon import PolynomialFit


class TestPolynomialFit(unittest.TestCase):
    def setUp(self):
        pass

    def test_Test1(self):
        # SCOPED_TRACE("Begin Test: Polynomial fit test 1.")
        order = 2

        input_data = [(1, 1), (2, 8), (3, 12), (4, 16)]

        poly = PolynomialFit(order)

        res = poly.getCoefficients(input_data)

        correct = [-6.75, 8.65, -0.75]

        self.assertEqual(len(correct), len(res))

        for i in range(len(correct)):
            self.assertAlmostEqual(correct[i], res[i], delta=1e-6)

    def test_Test2(self):
        # SCOPED_TRACE("Begin Test: Polynomial fit test 2.")
        order = 6

        input_data = [
            (1.000000000, 0.833848000),
            (0.984807753, 0.833295072),
            (0.939692621, 0.831346909),
            (0.866025404, 0.826927210),
            (0.766044443, 0.817365310),
            (0.642787610, 0.796259808),
            (0.500000000, 0.748087594),
            (0.342020143, 0.635870414),
            (0.173648178, 0.387186362),
            (0.000000000, 0.000000000),
        ]

        poly = PolynomialFit(order)

        res = poly.getCoefficients(input_data)

        correct = [
            -9.27348e-6, 2.288300, 1.646894, -15.397616, 26.122771, -19.148321, 5.322077,
        ]

        self.assertEqual(len(correct), len(res))

        for i in range(len(correct)):
            self.assertAlmostEqual(correct[i], res[i], delta=1e-6)
