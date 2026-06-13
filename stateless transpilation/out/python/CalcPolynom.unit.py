# EXTERNAL DEPS (to wire in glue):
# - Polynom (from WCECommon.hpp) - polynomial evaluator class taking List[float] coefficients and valueAt(x: float) -> float

import unittest
from typing import List


class Polynom:
    def __init__(self, coefficients: List[float]) -> None:
        self.coefficients = coefficients
    
    def value_at(self, x: float) -> float:
        result = 0.0
        power = 1.0
        for coeff in self.coefficients:
            result += coeff * power
            power *= x
        return result


class TestCalcPolynom(unittest.TestCase):
    def setUp(self) -> None:
        pass
    
    def test_1(self) -> None:
        input_coeffs = [-6.75, 8.65, -0.75]
        poly = Polynom(input_coeffs)
        self.assertAlmostEqual(-10.95, poly.value_at(12), places=6)
    
    def test_2(self) -> None:
        input_coeffs = [-6.75, 8.65, -0.75]
        poly = Polynom(input_coeffs)
        self.assertAlmostEqual(1.15, poly.value_at(1), places=6)
    
    def test_3(self) -> None:
        input_coeffs = [
            -9.27348e-06, 2.288300764, 1.646894009, -15.39761441,
            26.12276881, -19.1483186, 5.322076488
        ]
        poly = Polynom(input_coeffs)
        self.assertAlmostEqual(0.807353444, poly.value_at(0.7), places=6)


if __name__ == '__main__':
    unittest.main()
