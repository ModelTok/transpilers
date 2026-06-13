# EXTERNAL DEPS (to wire in glue):
# - IIntegratorStrategy
# - CIntegratorFactory
# - IntegrationType
# - ISeriesPoint
# - CSeriesPoint
# - CSeries

import unittest

struct IIntegratorStrategy {
    fn integrate(self, input: List[ISeriesPoint]) -> CSeries
}

struct CIntegratorFactory {
    fn getIntegrator(self, integration_type: IntegrationType) -> IIntegratorStrategy
}

enum IntegrationType {
    Rectangular = 0
}

struct ISeriesPoint {
    fn x(self) -> Float64
    fn value(self) -> Float64
}

struct CSeriesPoint: ISeriesPoint {
    var _x: Float64
    var _value: Float64

    fn __init__(self, x: Float64, value: Float64) {
        self._x = x
        self._value = value
    }

    fn x(self) -> Float64 {
        return self._x
    }

    fn value(self) -> Float64 {
        return self._value
    }
}

struct CSeries {
    var _points: List[Tuple[Float64, Float64]]

    fn __init__(self, points: List[Tuple[Float64, Float64]]) {
        self._points = points
    }

    fn __getitem__(self, index: Int32) -> Tuple[Float64, Float64] {
        return self._points[index]
    }

    fn size(self) -> Int32 {
        return len(self._points)
    }
}

class TestSimpleRectangularCentroidIntegration(unittest.TestCase):
    var aFactory: CIntegratorFactory
    var m_Integrator: IIntegratorStrategy

    fn setUp(self) {
        self.aFactory = CIntegratorFactory()
        self.m_Integrator = self.aFactory.getIntegrator(IntegrationType.Rectangular)
    }

    fn getIntegrator(self) -> IIntegratorStrategy {
        return self.m_Integrator
    }

    fn test_rectangular_centorid(self) {
        with self.subTest(msg="Begin Test: Test rectangular integrator"):
            aIntegrator = self.getIntegrator()

            var input: List[ISeriesPoint] = []
            input.append(CSeriesPoint(10.0, 20.0))
            input.append(CSeriesPoint(15.0, 30.0))
            input.append(CSeriesPoint(20.0, 40.0))

            var series = aIntegrator.integrate(input)

            var correctValues = CSeries([(10.0, 100.0), (15.0, 150.0)])

            self.assertEqual(correctValues.size(), series.size())

            for i in range(correctValues.size()):
                self.assertAlmostEqual(correctValues[i][0], series[i][0], places=6)
                self.assertAlmostEqual(correctValues[i][1], series[i][1], places=6)
    }
}

if __name__ == '__main__':
    unittest.main()
