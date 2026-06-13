from typing import *
from wclib.common import *
from wclib.datastructures import *
from wclib.eplus import *

class TestSimpleTrapezoidalBIntegration(CheckpointedTest):
    def setUp(self):
        self.integrator = CIntegratorFactory().getIntegrator(IntegrationType.TrapezoidalB)

    def testTrapezoidalB(self):
        self.checkpoint("Test trapezoidal B integrator", lambda: self.integrator.integrate([
            ISeriesPoint(10, 20),
            ISeriesPoint(15, 30),
            ISeriesPoint(20, 40)
        ]), {
            (10, 175.0), (15, 275.0)
        })
