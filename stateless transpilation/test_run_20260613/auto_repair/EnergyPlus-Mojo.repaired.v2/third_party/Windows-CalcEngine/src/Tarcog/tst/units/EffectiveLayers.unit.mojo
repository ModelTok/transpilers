from testing import assert_almost_equal, test
from ......WCETarcog import EffectiveLayers

struct TestEffectiveLayers:
    def SetUp(inout self): pass

@test
def TestVenetianHorizontalEffectiveLayer():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.0  # m
    let height = 1.0  # m
    let materialThickness = 0.0001  # m
    let slatTiltAngle = 0.0
    let slatWidth = 0.0148  # m
    let openness = EffectiveLayers.ShadeOpenness(0.991657018661499, 0, 0, 0, 0)
    let venetian = EffectiveLayers.EffectiveHorizontalVenetian(
        width, height, materialThickness, openness, slatTiltAngle, slatWidth
    )
    let effectiveThickness = venetian.effectiveThickness()
    assert_almost_equal(effectiveThickness, 6.364e-4, 1e-9)
    let effectiveOpenness = venetian.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 1.592911e-2, 1e-8)

@test
def TestVenetianHorizontalEffectiveLayerWithTopAndBotOpenness():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.3  # m
    let height = 1.8  # m
    let materialThickness = 0.0001  # m
    let slatTiltAngle = 0.0
    let slatWidth = 0.0148  # m
    let openness = EffectiveLayers.ShadeOpenness(0.991657045, 0, 0, 0.01, 0.008)
    let venetian = EffectiveLayers.EffectiveHorizontalVenetian(
        width, height, materialThickness, openness, slatTiltAngle, slatWidth
    )
    let effectiveThickness = venetian.effectiveThickness()
    assert_almost_equal(effectiveThickness, 6.364e-4, 1e-9)
    let effectiveOpenness = venetian.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 3.727412206e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Atop, 1.3e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Abot, 1.04e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Al, 0.0, 1e-8)
    assert_almost_equal(effectiveOpenness.Ar, 0.0, 1e-8)

@test
def TestVenetianVerticalEffectiveLayerWithTopAndBotOpenness():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.3  # m
    let height = 1.8  # m
    let materialThickness = 0.0001  # m
    let slatTiltAngle = 0.0
    let slatWidth = 0.0762  # m
    let openness = EffectiveLayers.ShadeOpenness(0.998224968, 0, 0, 0.01, 0.008)
    let venetian = EffectiveLayers.EffectiveVerticalVenentian(
        width, height, materialThickness, openness, slatTiltAngle, slatWidth
    )
    let effectiveThickness = venetian.effectiveThickness()
    assert_almost_equal(effectiveThickness, 9.144e-4, 1e-9)
    let effectiveOpenness = venetian.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 9.589398567e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Atop, 1.3e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Abot, 1.04e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Al, 0.0, 1e-8)
    assert_almost_equal(effectiveOpenness.Ar, 0.0, 1e-8)

@test
def TestVenetianVerticalEffectiveLayerWithTopAndBotOpenness45Deg():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.3  # m
    let height = 1.8  # m
    let materialThickness = 0.0001  # m
    let slatTiltAngle = 45.0
    let slatWidth = 0.0762  # m
    let openness = EffectiveLayers.ShadeOpenness(0.998224966, 0, 0, 0.01, 0.008)
    let venetian = EffectiveLayers.EffectiveVerticalVenentian(
        width, height, materialThickness, openness, slatTiltAngle, slatWidth
    )
    let effectiveThickness = venetian.effectiveThickness()
    assert_almost_equal(effectiveThickness, 6.474269e-4, 1e-9)
    let effectiveOpenness = venetian.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 9.589398567e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Atop, 1.3e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Abot, 1.04e-2, 1e-8)
    assert_almost_equal(effectiveOpenness.Al, 0.0, 1e-8)
    assert_almost_equal(effectiveOpenness.Ar, 0.0, 1e-8)

@test
def TestPerforatedEffectiveOpenness():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.3  # m
    let height = 1.8  # m
    let materialThickness = 0.0006  # m
    let openness = EffectiveLayers.ShadeOpenness(0.087265995, 0.005, 0.004, 0.01, 0.008)
    let perforated = EffectiveLayers.EffectiveLayerPerforated(
        width, height, materialThickness, openness
    )
    let effectiveThickness = perforated.effectiveThickness()
    assert_almost_equal(effectiveThickness, 6e-4, 1e-9)
    let effectiveOpenness = perforated.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 9.779677e-3, 1e-8)
    assert_almost_equal(effectiveOpenness.Atop, 13.0e-3, 1e-8)
    assert_almost_equal(effectiveOpenness.Abot, 10.4e-3, 1e-8)
    assert_almost_equal(effectiveOpenness.Al, 9.0e-3, 1e-8)
    assert_almost_equal(effectiveOpenness.Ar, 7.2e-3, 1e-8)

@test
def TestOtherShadingEffectiveOpenness():
    print("Begin Test: Venetian horizontal effective layer properties.")
    let width = 1.3  # m
    let height = 1.8  # m
    let materialThickness = 0.0006  # m
    let openness = EffectiveLayers.ShadeOpenness(0.087265995, 0.005, 0.004, 0.01, 0.008)
    let perforated = EffectiveLayers.EffectiveLayerOther(
        width, height, materialThickness, openness
    )
    let effectiveThickness = perforated.effectiveThickness()
    assert_almost_equal(effectiveThickness, 6e-4, 1e-9)
    let effectiveOpenness = perforated.getEffectiveOpenness()
    assert_almost_equal(effectiveOpenness.Ah, 0.2042024283, 1e-8)
    assert_almost_equal(effectiveOpenness.Atop, 0.013, 1e-8)
    assert_almost_equal(effectiveOpenness.Abot, 0.0104, 1e-8)
    assert_almost_equal(effectiveOpenness.Al, 0.009, 1e-8)
    assert_almost_equal(effectiveOpenness.Ar, 0.0072, 1e-8)