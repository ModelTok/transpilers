from memory import Pointer
from utils import List
from WCECommon import (
    IIntegratorStrategy,
    CIntegratorFactory,
    IntegrationType,
    ISeriesPoint,
    CSeriesPoint,
    CSeries,
)

@value
class TestSimpleTrapezoidalIntegration:
    var m_Integrator: Pointer[IIntegratorStrategy]

    def __init__(inout self):
        self.m_Integrator = Pointer[IIntegratorStrategy]()

    def SetUp(inout self):
        var aFactory = CIntegratorFactory()
        self.m_Integrator = aFactory.getIntegrator(IntegrationType.Trapezoidal)

    def getIntegrator(self) -> Pointer[IIntegratorStrategy]:
        return self.m_Integrator

# Test function
@test
def TestTrapezoidal():
    SCOPED_TRACE("Begin Test: Test trapezoidal integrator")
    var testObj = TestSimpleTrapezoidalIntegration()
    testObj.SetUp()
    var aIntegrator = testObj.getIntegrator()
    var input = List[Pointer[ISeriesPoint]]()
    input.append(Pointer(CSeriesPoint(10, 20)))
    input.append(Pointer(CSeriesPoint(15, 30)))
    input.append(Pointer(CSeriesPoint(20, 40)))
    var series = aIntegrator.unsafe_get().integrate(input)[]
    var correctValues = CSeries(List((10.0, 125.0), (15.0, 175.0)))
    assert_equal(correctValues.size(), series.size())
    for i in range(correctValues.size()):
        assert_almost_equal(correctValues[i].x(), series[i].x(), 1e-6)
        assert_almost_equal(correctValues[i].value(), series[i].value(), 1e-6)