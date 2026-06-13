from builtin import print
from memory import List, Pointer
from math import abs
from WCECommon import (
    IIntegratorStrategy,
    CIntegratorFactory,
    IntegrationType,
    ISeriesPoint,
    CSeriesPoint,
    CSeries,
    make_unique,
)

struct TestSimpleRectangularIntegration:
    var m_Integrator: Pointer[IIntegratorStrategy]

    def SetUp(inout self):
        let aFactory = CIntegratorFactory()
        self.m_Integrator = aFactory.getIntegrator(IntegrationType.Rectangular)

    def getIntegrator(self) -> Pointer[IIntegratorStrategy]:
        return self.m_Integrator

def test_TestRectangular():
    print("Begin Test: Test rectangular integrator")
    var testObj = TestSimpleRectangularIntegration()
    testObj.SetUp()
    let aIntegrator = testObj.getIntegrator()
    var input = List[Pointer[ISeriesPoint]]()
    input.append(make_unique[CSeriesPoint](10, 20))
    input.append(make_unique[CSeriesPoint](15, 30))
    input.append(make_unique[CSeriesPoint](20, 40))
    let series = aIntegrator[].integrate(input)[]
    let correctValues = CSeries([(10, 100), (15, 150)])
    assert(correctValues.size() == series.size(), "Size mismatch")
    for i in range(0, correctValues.size()):
        assert(abs(correctValues[i].x() - series[i].x()) < 1e-6, "x mismatch")
        assert(abs(correctValues[i].value() - series[i].value()) < 1e-6, "value mismatch")

test_TestRectangular()