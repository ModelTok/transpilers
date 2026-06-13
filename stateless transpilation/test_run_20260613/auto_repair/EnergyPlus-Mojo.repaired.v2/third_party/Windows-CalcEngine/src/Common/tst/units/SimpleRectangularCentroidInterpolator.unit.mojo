from ......WCECommon import *
from memory import Pointer

struct TestSimpleRectangularCentroidIntegration:
    var m_Integrator: Pointer[IIntegratorStrategy]

    def SetUp(inout self):
        var aFactory = CIntegratorFactory()
        self.m_Integrator = aFactory.getIntegrator(IntegrationType.Rectangular)

    def getIntegrator(self) -> Pointer[IIntegratorStrategy]:
        return self.m_Integrator


def TestSimpleRectangularCentroidIntegration_TestRectangularCentorid_Test():
    # SCOPED_TRACE("Begin Test: Test rectangular integrator")
    var aIntegrator = TestSimpleRectangularCentroidIntegration()
    aIntegrator.SetUp()
    var integrator: Pointer[IIntegratorStrategy] = aIntegrator.getIntegrator()

    var input: List[Pointer[ISeriesPoint]] = List[Pointer[ISeriesPoint]]()
    input.append(make_unique[CSeriesPoint](10, 20))
    input.append(make_unique[CSeriesPoint](15, 30))
    input.append(make_unique[CSeriesPoint](20, 40))

    var series = *integrator.integrate(input)

    var correctValues = CSeries((10, 100), (15, 150))

    if correctValues.size() != series.size():
        print("size mismatch")
    else:
        for i in range(correctValues.size()):
            if abs(correctValues[i].x() - series[i].x()) > 1e-6:
                print("x mismatch at ", i)
            if abs(correctValues[i].value() - series[i].value()) > 1e-6:
                print("value mismatch at ", i)