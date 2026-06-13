from memory import *
from gtest import *
from WCETarcog import *

class TestPermeabilityFactors(Test):
    def SetUp(self):

def TestVenetianPermeability():
    SCOPED_TRACE("Begin Test: Venetian layer thermal permeability.")
    const matThickness = 0.0001   # m
    const slatWidth = 0.0148      # m
    const slatSpacing = 0.0127    # m
    const slatTiltAngle = 0.0
    const curvatureRadius = 0.03313057   # m
    const permeabilityOpenness = ThermalPermeability.Venetian.openness(
      slatTiltAngle, slatSpacing, matThickness, curvatureRadius, slatWidth)
    EXPECT_NEAR(0.9921875, permeabilityOpenness, 1e-6)

def TestPerforatedCircularPermeability():
    SCOPED_TRACE("Begin Test: Circular perforated layer thermal permeability.")
    const perforatedType = ThermalPermeability.Perforated.Geometry.Circular
    const diameter = 0.00635   # m
    const xSpacing = 0.01905   # m
    const ySpacing = 0.01905   # m
    const CellDimension = ThermalPermeability.Perforated.diameterToXYDimension(diameter)
    EXPECT_NEAR(0.00635, CellDimension.x, 1e-6)
    EXPECT_NEAR(0.00635, CellDimension.y, 1e-6)
    const permeabilityOpenness = ThermalPermeability.Perforated.openness(
      perforatedType, xSpacing, ySpacing, CellDimension.x, CellDimension.y)
    EXPECT_NEAR(0.087266, permeabilityOpenness, 1e-6)

def TestPerforatedRectangularPermeability():
    SCOPED_TRACE("Begin Test: Rectangular perforated layer thermal permeability.")
    const perforatedType = ThermalPermeability.Perforated.Geometry.Rectangular
    const width = 0.00635      # m
    const height = 0.00635     # m
    const xSpacing = 0.01905   # m
    const ySpacing = 0.01905   # m
    const permeabilityOpenness = ThermalPermeability.Perforated.openness(perforatedType, xSpacing, ySpacing, width, height)
    EXPECT_NEAR(0.111111, permeabilityOpenness, 1e-6)

def TestPerforatedSquarePermeability():
    SCOPED_TRACE("Begin Test: Square perforated layer thermal permeability.")
    const perforatedType = ThermalPermeability.Perforated.Geometry.Square
    const width = 0.00635      # m
    const xSpacing = 0.01905   # m
    const ySpacing = 0.01905   # m
    const permeabilityOpenness = ThermalPermeability.Perforated.openness(perforatedType, xSpacing, ySpacing, width, width)
    EXPECT_NEAR(0.111111, permeabilityOpenness, 1e-6)

def TestWovenPermeability():
    SCOPED_TRACE("Begin Test: Woven layer thermal permeability.")
    const diameter = 0.001   # m
    const spacing = 0.002    # m
    const permeabilityOpenness = ThermalPermeability.Woven.openness(diameter, spacing)
    EXPECT_NEAR(0.25, permeabilityOpenness, 1e-6)