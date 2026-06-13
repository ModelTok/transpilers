from testing import assert_almost_equal
from WCECommon import CSeries, CHemispherical2DIntegrator, IntegrationType

struct TestHemispherical2DIntegration:
    var m_Integrator: CHemispherical2DIntegrator

    def SetUp(inout self):
        var aSeries = CSeries()
        const normalization: Float64 = 1
        aSeries.addProperty(0, 0.652)
        aSeries.addProperty(10, 0.651)
        aSeries.addProperty(20, 0.648)
        aSeries.addProperty(30, 0.640)
        aSeries.addProperty(40, 0.624)
        aSeries.addProperty(50, 0.592)
        aSeries.addProperty(60, 0.527)
        aSeries.addProperty(70, 0.397)
        aSeries.addProperty(80, 0.185)
        aSeries.addProperty(90, 0.000)
        self.m_Integrator = CHemispherical2DIntegrator(
            aSeries, IntegrationType.Trapezoidal, normalization)

@test
def TestHemisphericalIntegration():
    var fixture = TestHemispherical2DIntegration()
    fixture.SetUp()
    var aValue = fixture.m_Integrator.value()
    assert_almost_equal(0.552540, aValue, abs_tol=1e-6)