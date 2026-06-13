# EXTERNAL DEPS (to wire in glue):
# - CBSDFLayer (source: WCESingleLayerOptics.hpp) - struct with getResults() -> CBSDFIntegrator
# - CBSDFIntegrator (source: WCESingleLayerOptics.hpp) - struct with DiffDiff(Side, PropertySimple) -> Float64, AbsDiffDiff(Side) -> Float64
# - CBSDFHemisphere (source: WCESingleLayerOptics.hpp) - struct with static create(BSDFBasis) -> CBSDFHemisphere
# - BSDFBasis (source: WCESingleLayerOptics.hpp) - enum with Quarter value
# - Material (source: WCESingleLayerOptics.hpp) - struct with static singleBandMaterial(Tf, Tb, Rf, Rb, minLambda, maxLambda) -> Material
# - CBSDFLayerMaker (source: WCESingleLayerOptics.hpp) - struct with static getCircularPerforatedLayer(material, bsdf, x, y, thickness, radius) -> CBSDFLayer
# - Side (source: WCECommon.hpp) - enum with Front, Back values
# - PropertySimple (source: WCECommon.hpp) - enum with T, R values
# Note: In C++, `Side` is also accessible as `FenestrationCommon::Side::Front` via the
# `using namespace FenestrationCommon;` declaration. Both refer to the same enum.

from testing import TestSuite, assert_almost_equal


# --- Stubs for external types (would be imported from WCE modules in production) ---
enum Side:
    Front
    Back


enum PropertySimple:
    T
    R


enum BSDFBasis:
    Quarter


struct CBSDFIntegrator:
    fn DiffDiff(self, side: Side, prop: PropertySimple) raises -> Float64:
        ...

    fn AbsDiffDiff(self, side: Side) raises -> Float64:
        ...


struct CBSDFLayer:
    fn getResults(self) raises -> CBSDFIntegrator:
        ...


struct CBSDFHemisphere:
    @staticmethod
    fn create(basis: BSDFBasis) raises -> CBSDFHemisphere:
        ...


struct Material:
    @staticmethod
    fn singleBandMaterial(
        Tf: Float64,
        Tb: Float64,
        Rf: Float64,
        Rb: Float64,
        minLambda: Float64,
        maxLambda: Float64,
    ) raises -> Material:
        ...


struct CBSDFLayerMaker:
    @staticmethod
    fn getCircularPerforatedLayer(
        material: Material,
        bsdf: CBSDFHemisphere,
        x: Float64,
        y: Float64,
        thickness: Float64,
        radius: Float64,
    ) raises -> CBSDFLayer:
        ...


# --- Test fixture (mirrors gtest TestFixture pattern) ---
struct TestCircularPerforatedShadeNFRC18000(TestSuite):
    var m_Shade: CBSDFLayer

    fn __init__(out self):
        self.m_Shade = CBSDFLayer()

    fn set_up(mut self) raises:
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)

        # create material
        let Tmat: Float64 = 0.0
        let Rfmat: Float64 = 0.137
        let Rbmat: Float64 = 0.16
        let minLambda: Float64 = 5.0
        let maxLambda: Float64 = 100.0
        let aMaterial = Material.singleBandMaterial(
            Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda
        )

        # make cell geometry
        let thickness_31111: Float64 = 0.00023
        let x: Float64 = 0.00169  # m
        let y: Float64 = 0.00169  # m
        let radius: Float64 = 0.00058  # m

        # Perforated layer is created here
        self.m_Shade = CBSDFLayerMaker.getCircularPerforatedLayer(
            aMaterial, aBSDF, x, y, thickness_31111, radius
        )

    fn GetShade(self) -> CBSDFLayer:
        return self.m_Shade

    fn test_SolarProperties(mut self) raises:
        # Equivalent of gtest's SCOPED_TRACE
        print("Begin Test: Circular perforated cell - Solar properties.")

        let aShade = self.GetShade()
        let aResults = aShade.getResults()

        let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
        assert_almost_equal(0.257367, tauDiff, atol=1e-6)

        let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
        assert_almost_equal(0.101741, RfDiff, atol=1e-6)

        let RbDiff = aResults.DiffDiff(Side.Back, PropertySimple.R)
        assert_almost_equal(0.118821, RbDiff, atol=1e-6)

        let absfDiff = aResults.AbsDiffDiff(Side.Front)
        assert_almost_equal(0.640892, absfDiff, atol=1e-6)

        let absbDiff = aResults.AbsDiffDiff(Side.Back)
        assert_almost_equal(0.623812, absbDiff, atol=1e-6)


fn main() raises:
    var suite = TestCircularPerforatedShadeNFRC18000()
    suite.set_up()
    suite.test_SolarProperties()
    print("All tests passed!")
