from WCECommon import (
    CIntegratorFactory,
    CSeries,
    CSeriesPoint,
    IIntegratorStrategy,
    IntegrationType,
    ISeriesPoint,
    wce,
)
from memory import Pointer
from testing import (
    assert_equal,
    assert_approx_equal,
    check,
)
from utils import SCOPED_TRACE

@value
struct TestSimpleTrapezoidalAIntegration:
    var m_Integrator: Pointer[IIntegratorStrategy]

    def __init__(inout self):
        self.m_Integrator = Pointer[IIntegratorStrategy]()

    def SetUp(inout self):
        var aFactory = CIntegratorFactory()
        self.m_Integrator = aFactory.getIntegrator(IntegrationType.TrapezoidalA)

    def getIntegrator(self) -> Pointer[IIntegratorStrategy]:
        return self.m_Integrator

def test_trapezoidalA() raises:
    SCOPED_TRACE("Begin Test: Test trapezoidal A integrator")
    var fixture = TestSimpleTrapezoidalAIntegration()
    fixture.SetUp()
    var aIntegrator = fixture.getIntegrator()
    var input = List[Pointer[ISeriesPoint]]()
    input.append(wce.make_unique(CSeriesPoint(10, 20)))
    input.append(wce.make_unique(CSeriesPoint(15, 30)))
    input.append(wce.make_unique(CSeriesPoint(20, 40)))
    var series = *aIntegrator.integrate(input)
    var correctValues = CSeries(10, 175) @ CSeries(15, 275)
    check(correctValues.size() == series.size())
    for i in range(0, correctValues.size()):
        check(approx_equal(correctValues[i].x(), series[i].x(), 1e-6))
        check(approx_equal(correctValues[i].value(), series[i].value(), 1e-6))

def approx_equal(a: Float64, b: Float64, tol: Float64) -> Bool:
    return abs(a - b) < tol