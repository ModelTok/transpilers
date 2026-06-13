# EXTERNAL DEPS (to wire in glue):
# - IIntegratorStrategy
# - CIntegratorFactory
# - IntegrationType
# - ISeriesPoint
# - CSeriesPoint
# - CSeries

from typing import List, Optional
from abc import ABC, abstractmethod
from math import fmod

class IIntegratorStrategy(ABC):
    @abstractmethod
    def integrate(self, input: List['ISeriesPoint']) -> 'CSeries':
        pass

class CIntegratorFactory:
    def getIntegrator(self, integration_type: 'IntegrationType') -> Optional['IIntegratorStrategy']:
        if integration_type == IntegrationType.TrapezoidalB:
            return SimpleTrapezoidalBIntegrator()
        return None

class IntegrationType:
    TrapezoidalB = 1

class ISeriesPoint(ABC):
    @abstractmethod
    def x(self) -> float:
        pass

    @abstractmethod
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

    def __iter__(self):
        return iter(self._points)

    def __len__(self):
        return len(self._points)

    def __getitem__(self, index: int):
        return self._points[index]

class SimpleTrapezoidalBIntegrator(IIntegratorStrategy):
    def integrate(self, input: List['ISeriesPoint']) -> 'CSeries':
        if len(input) < 2:
            return CSeries([])

        series = []
        for i in range(len(input) - 1):
            x1 = input[i].x()
            y1 = input[i].value()
            x2 = input[i + 1].x()
            y2 = input[i + 1].value()
            mid_x = (x1 + x2) / 2
            mid_y = (y1 + y2) / 2
            series.append((mid_x, mid_y))

        return CSeries(series)

class TestSimpleTrapezoidalBIntegration:
    def setUp(self):
        self.aFactory = CIntegratorFactory()
        self.m_Integrator = self.aFactory.getIntegrator(IntegrationType.TrapezoidalB)

    def getIntegrator(self) -> Optional['IIntegratorStrategy']:
        return self.m_Integrator

def test_trapezoidal_b():
    aIntegrator = TestSimpleTrapezoidalBIntegration().getIntegrator()

    input = [
        CSeriesPoint(10, 20),
        CSeriesPoint(15, 30),
        CSeriesPoint(20, 40)
    ]

    series = aIntegrator.integrate(input)

    correct_values = [(10, 187.5), (15, 262.5)]

    assert len(correct_values) == len(series)

    for i in range(len(correct_values)):
        assert abs(correct_values[i][0] - series[i][0]) < 1e-6
        assert abs(correct_values[i][1] - series[i][1]) < 1e-6
