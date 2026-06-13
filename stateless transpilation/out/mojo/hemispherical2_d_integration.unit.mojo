# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import CHemispherical2DIntegrator, CSeries, IntegrationType

import unittest

class TestHemispherical2DIntegration(unittest.TestCase):
    def setUp(self):
        from fenestration_common import CHemispherical2DIntegrator, CSeries, IntegrationType

        a_series = CSeries()

        normalization = 1

        # example taken from WINDOW 7 double layer (NFRC 102 and NFRC 103) angular dependency for
        # Tsol NOTE: It is not necessary to add angles in accending order. Series will sort out
        # order before performing integration
        a_series.addProperty(0, 0.652)
        a_series.addProperty(10, 0.651)
        a_series.addProperty(20, 0.648)
        a_series.addProperty(30, 0.640)
        a_series.addProperty(40, 0.624)
        a_series.addProperty(50, 0.592)
        a_series.addProperty(60, 0.527)
        a_series.addProperty(70, 0.397)
        a_series.addProperty(80, 0.185)
        a_series.addProperty(90, 0.000)

        self.m_integrator = CHemispherical2DIntegrator(a_series, IntegrationType.Trapezoidal, normalization)

    def test_hemispherical_integration(self):
        import unittest

        unittest.TestCase.maxDiff = None

        a_value = self.m_integrator.value()

        self.assertAlmostEqual(0.552540, a_value, delta=1e-6)
