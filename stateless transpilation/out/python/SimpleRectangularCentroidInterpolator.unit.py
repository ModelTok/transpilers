# EXTERNAL DEPS (to wire in glue):
# - IIntegratorStrategy
# - CIntegratorFactory
# - IntegrationType
# - ISeriesPoint
# - CSeriesPoint
# - CSeries

from typing import List, Optional
import unittest

class IIntegratorStrategy:
    def integrate(self, input: List['ISeriesPoint']) -> 'CSeries':
        pass

class CIntegratorFactory:
    def getIntegrator(self, integration_type: 'IntegrationType') -> IIntegratorStrategy:
        pass

class IntegrationType:
    Rectangular = 0

class ISeriesPoint:
    def x(self) -> float:
        pass

    def value(self) -> float:
        pass

class CSeriesPoint(ISeriesPoint):
    def __init__(self, x: float, value: float):
        self._x = x
        self._value = value

    def x(self) -> float:
        return self._x

    def value(self) -> float:
        return self._value

class CSeries:
    def __init__(self, points: List[tuple]):
        self._points = points

    def __getitem__(self, index: int) -> tuple:
        return self._points[index]

    def size(self) -> int:
        return len(self._points)

class TestSimpleRectangularCentroidIntegration(unittest.TestCase):
    def setUp(self):
        self.aFactory = CIntegratorFactory()
        self.m_Integrator = self.aFactory.getIntegrator(IntegrationType.Rectangular)

    def getIntegrator(self) -> IIntegratorStrategy:
        return self.m_Integrator

    def test_rectangular_centorid(self):
        with self.subTest(msg="Begin Test: Test rectangular integrator"):
            aIntegrator = self.getIntegrator()

            input: List[ISeriesPoint] = []
            input.append(CSeriesPoint(10, 20))
            input.append(CSeriesPoint(15, 30))
            input.append(CSeriesPoint(20, 40))

            series = aIntegrator.integrate(input)

            correctValues = CSeries([(10, 100), (15, 150)])

            self.assertEqual(correctValues.size(), series.size())

            for i in range(correctValues.size()):
                self.assertAlmostEqual(correctValues[i][0], series[i][0], places=6)
                self.assertAlmostEqual(correctValues[i][1], series[i][1], places=6)

if __name__ == '__main__':
    unittest.main()
