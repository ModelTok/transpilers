from typing import *
from energyplus import *

class TestSolidLayer(Case):
    def test_1(self):
        conduction_heat_flow = self.solver.GetLayer().getConvectionConductionFlow()
        self.assertAlmostEqual(5000, conduction_heat_flow, 1e-6)
