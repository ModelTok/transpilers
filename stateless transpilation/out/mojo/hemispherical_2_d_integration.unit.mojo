# EXTERNAL DEPS (to wire in glue):
# - CSeries: from FenestrationCommon (WCECommon.hpp)
# - CHemispherical2DIntegrator: from FenestrationCommon (WCECommon.hpp)
# - IntegrationType: from FenestrationCommon (WCECommon.hpp)

struct IntegrationType:
    alias Trapezoidal = 0

struct CSeries:
    fn add_property(inout self, angle: Float64, value: Float64) -> None:
        pass

struct CHemispherical2DIntegrator:
    var integration_type: Int
    var normalization: Float64
    
    fn __init__(inout self, borrowed series: CSeries, integration_type: Int, normalization: Float64):
        self.integration_type = integration_type
        self.normalization = normalization
    
    fn value(self) -> Float64:
        return 0.0

struct TestHemispherical2DIntegration:
    var m_integrator: CHemispherical2DIntegrator
    
    fn __init__(inout self):
        var a_series = CSeries()
        var normalization: Float64 = 1.0
        
        # example taken from WINDOW 7 double layer (NFRC 102 and NFRC 103) angular dependency for
        # Tsol NOTE: It is not necessary to add angles in accending order. Series will sort out
        # order before performing integration
        a_series.add_property(0, 0.652)
        a_series.add_property(10, 0.651)
        a_series.add_property(20, 0.648)
        a_series.add_property(30, 0.640)
        a_series.add_property(40, 0.624)
        a_series.add_property(50, 0.592)
        a_series.add_property(60, 0.527)
        a_series.add_property(70, 0.397)
        a_series.add_property(80, 0.185)
        a_series.add_property(90, 0.000)
        
        self.m_integrator = CHemispherical2DIntegrator(
            a_series, IntegrationType.Trapezoidal, normalization)
    
    fn test_hemispherical_integration(self) -> None:
        # Begin Test: Test for 2D hemispherical integrator.
        var a_value = self.m_integrator.value()
        var tolerance: Float64 = 1e-6
        assert abs(0.552540 - a_value) < tolerance

fn main():
    var test = TestHemispherical2DIntegration()
    test.test_hemispherical_integration()
