from ......WCECommon import *
from testing import *
from memory import Pointer, SharedPointer

class TestSimpleTrapezoidalBIntegration(Test):
    var m_Integrator: SharedPointer[IIntegratorStrategy]

    def __init__(inout self):
        self.m_Integrator = SharedPointer[IIntegratorStrategy]()

    def SetUp(inout self):
        var aFactory = CIntegratorFactory()
        self.m_Integrator = aFactory.getIntegrator(IntegrationType.TrapezoidalB)

    def getIntegrator(self) -> Pointer[IIntegratorStrategy]:
        return self.m_Integrator.get()

@test
def TestTrapezoidalB():
    SCOPED_TRACE("Begin Test: Test trapezoidal B integrator")
    var fixture = TestSimpleTrapezoidalBIntegration()
    fixture.SetUp()
    var aIntegrator = fixture.getIntegrator()
    var input = List[Pointer[ISeriesPoint]]()
    input.append(Pointer[CSeriesPoint](CSeriesPoint(10, 20)))
    input.append(Pointer[CSeriesPoint](CSeriesPoint(15, 30)))
    input.append(Pointer[CSeriesPoint](CSeriesPoint(20, 40)))
    var series = aIntegrator.integrate(input)[]
    var correctValues = CSeries( [{10, 187.5}, {15, 262.5}] )
    assert_eq(correctValues.size(), series.size())
    for i in range(correctValues.size()):
        assert_approx_eq(correctValues[i].x(), series[i].x(), 1e-6)
        assert_approx_eq(correctValues[i].value(), series[i].value(), 1e-6)