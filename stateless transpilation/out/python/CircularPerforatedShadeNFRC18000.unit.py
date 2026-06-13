# EXTERNAL DEPS (to wire in glue):
# - CBSDFLayer (source: WCESingleLayerOptics.hpp) - class with getResults() -> CBSDFIntegrator
# - CBSDFIntegrator (source: WCESingleLayerOptics.hpp) - class with DiffDiff(Side, PropertySimple) -> float, AbsDiffDiff(Side) -> float
# - CBSDFHemisphere (source: WCESingleLayerOptics.hpp) - class with static create(BSDFBasis) -> CBSDFHemisphere
# - BSDFBasis (source: WCESingleLayerOptics.hpp) - enum with Quarter value
# - Material (source: WCESingleLayerOptics.hpp) - class with static singleBandMaterial(Tf, Tb, Rf, Rb, minLambda, maxLambda) -> Material
# - CBSDFLayerMaker (source: WCESingleLayerOptics.hpp) - class with static getCircularPerforatedLayer(material, bsdf, x, y, thickness, radius) -> CBSDFLayer
# - Side (source: WCECommon.hpp) - enum with Front, Back values
# - PropertySimple (source: WCECommon.hpp) - enum with T, R values
# Note: In C++, `Side` is also accessible as `FenestrationCommon::Side::Front` via the
# `using namespace FenestrationCommon;` declaration. Both refer to the same enum.

import unittest
from enum import Enum
from typing import Protocol


# --- Stubs for external types (would be imported from WCE modules in production) ---
class Side(Enum):
    Front = 1
    Back = 2


class PropertySimple(Enum):
    T = 1
    R = 2


class BSDFBasis(Enum):
    Quarter = 1


class CBSDFIntegrator(Protocol):
    def DiffDiff(self, side: Side, prop: PropertySimple) -> float:
        ...

    def AbsDiffDiff(self, side: Side) -> float:
        ...


class CBSDFLayer(Protocol):
    def getResults(self) -> CBSDFIntegrator:
        ...


class CBSDFHemisphere:
    @staticmethod
    def create(basis: BSDFBasis) -> "CBSDFHemisphere":
        ...


class Material:
    @staticmethod
    def singleBandMaterial(
        Tf: float,
        Tb: float,
        Rf: float,
        Rb: float,
        minLambda: float,
        maxLambda: float,
    ) -> "Material":
        ...


class CBSDFLayerMaker:
    @staticmethod
    def getCircularPerforatedLayer(
        material: Material,
        bsdf: CBSDFHemisphere,
        x: float,
        y: float,
        thickness: float,
        radius: float,
    ) -> CBSDFLayer:
        ...


# --- Test fixture (mirrors gtest TestFixture pattern) ---
class TestCircularPerforatedShadeNFRC18000(unittest.TestCase):
    def setUp(self):
        aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)

        # create material
        Tmat = 0.0
        Rfmat = 0.137
        Rbmat = 0.16
        minLambda = 5.0
        maxLambda = 100.0
        aMaterial = Material.singleBandMaterial(
            Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda
        )

        # make cell geometry
        thickness_31111 = 0.00023
        x = 0.00169  # m
        y = 0.00169  # m
        radius = 0.00058  # m

        # Perforated layer is created here
        self.m_Shade = CBSDFLayerMaker.getCircularPerforatedLayer(
            aMaterial, aBSDF, x, y, thickness_31111, radius
        )

    def GetShade(self) -> CBSDFLayer:
        return self.m_Shade


def test_SolarProperties(self):
    # Equivalent of gtest's SCOPED_TRACE
    print("Begin Test: Circular perforated cell - Solar properties.")

    aShade = self.GetShade()
    aResults = aShade.getResults()

    tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    self.assertAlmostEqual(0.257367, tauDiff, delta=1e-6)

    RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    self.assertAlmostEqual(0.101741, RfDiff, delta=1e-6)

    RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
    self.assertAlmostEqual(0.118821, RbDiff, delta=1e-6)

    absfDiff = aResults.AbsDiffDiff(Side.Front)
    self.assertAlmostEqual(0.640892, absfDiff, delta=1e-6)

    absbDiff = aResults.AbsDiffDiff(Side.Back)
    self.assertAlmostEqual(0.623812, absbDiff, delta=1e-6)


# Attach the test method to the class (preserves the original C++ test name)
TestCircularPerforatedShadeNFRC18000.test_SolarProperties = test_SolarProperties


if __name__ == "__main__":
    unittest.main()
