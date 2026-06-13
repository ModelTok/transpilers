from EnergyPlus.TARCOGParams import TARCOGLayerType
from EnergyPlus.TarcogShading import updateEffectiveMultipliers
from memory import DynamicVector
from testing import assert_near

# Helper to replicate EXPECT_NEAR (non-fatal, prints on failure)
def expect_near(actual: Float64, expected: Float64, abs_error: Float64) raises:
    if abs(actual - expected) > abs_error:
        print("Expected approx", expected, "but got", actual, "(error", abs(actual - expected), ">", abs_error, ")")
        # Optionally raise to mimic test failure
        raise Error("EXPECT_NEAR failed")

# Test: WindowRoutines_EffectiveOpennessHorizontalVenetianBlind_0_deg
def test_WindowRoutines_EffectiveOpennessHorizontalVenetianBlind_0_deg() raises:
    alias nlayer = 1
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var LayerType = DynamicVector[TARCOGLayerType](nlayer)
    var Atop_eff = DynamicVector[Float64](nlayer, 0.0)
    var Abot_eff = DynamicVector[Float64](nlayer, 0.0)
    var Al_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ar_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ah_eff = DynamicVector[Float64](nlayer, 0.0)

    var Atop = DynamicVector[Float64]([0.1])
    var Abot = DynamicVector[Float64]([0.1])
    var Al = DynamicVector[Float64]([0.0])
    var Ar = DynamicVector[Float64]([0.0])
    var Ah = DynamicVector[Float64]([0.2])

    LayerType[0] = TARCOGLayerType.VENETBLIND_HORIZ
    var SlatAngle = DynamicVector[Float64]([0.0])

    updateEffectiveMultipliers(
        nlayer, width, height,
        Atop, Abot, Al, Ar, Ah,
        Atop_eff, Abot_eff, Al_eff, Ar_eff, Ah_eff,
        LayerType, SlatAngle
    )

    expect_near(Al_eff[0], 0.0, 1e-6)
    expect_near(Ar_eff[0], 0.0, 1e-6)
    expect_near(Atop_eff[0], 0.1, 1e-6)
    expect_near(Abot_eff[0], 0.1, 1e-6)
    expect_near(Ah_eff[0], 0.006818, 1e-6)


# Test: WindowRoutines_EffectiveOpennessVerticalVenetianBlind_0_deg
def test_WindowRoutines_EffectiveOpennessVerticalVenetianBlind_0_deg() raises:
    alias nlayer = 1
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var LayerType = DynamicVector[TARCOGLayerType](nlayer)
    var Atop_eff = DynamicVector[Float64](nlayer, 0.0)
    var Abot_eff = DynamicVector[Float64](nlayer, 0.0)
    var Al_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ar_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ah_eff = DynamicVector[Float64](nlayer, 0.0)

    var Atop = DynamicVector[Float64]([0.1])
    var Abot = DynamicVector[Float64]([0.1])
    var Al = DynamicVector[Float64]([0.0])
    var Ar = DynamicVector[Float64]([0.0])
    var Ah = DynamicVector[Float64]([0.2])

    LayerType[0] = TARCOGLayerType.VENETBLIND_VERT
    var SlatAngle = DynamicVector[Float64]([0.0])

    updateEffectiveMultipliers(
        nlayer, width, height,
        Atop, Abot, Al, Ar, Ah,
        Atop_eff, Abot_eff, Al_eff, Ar_eff, Ah_eff,
        LayerType, SlatAngle
    )

    expect_near(Al_eff[0], 0.0, 1e-6)
    expect_near(Ar_eff[0], 0.0, 1e-6)
    expect_near(Atop_eff[0], 0.1, 1e-6)
    expect_near(Abot_eff[0], 0.1, 1e-6)
    expect_near(Ah_eff[0], 0.026550, 1e-6)


# Test: WindowRoutines_EffectiveOpennessHorizontalVenetianBlind_45_deg
def test_WindowRoutines_EffectiveOpennessHorizontalVenetianBlind_45_deg() raises:
    alias nlayer = 1
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var LayerType = DynamicVector[TARCOGLayerType](nlayer)
    var Atop_eff = DynamicVector[Float64](nlayer, 0.0)
    var Abot_eff = DynamicVector[Float64](nlayer, 0.0)
    var Al_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ar_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ah_eff = DynamicVector[Float64](nlayer, 0.0)

    var Atop = DynamicVector[Float64]([0.1])
    var Abot = DynamicVector[Float64]([0.1])
    var Al = DynamicVector[Float64]([0.0])
    var Ar = DynamicVector[Float64]([0.0])
    var Ah = DynamicVector[Float64]([0.2])

    LayerType[0] = TARCOGLayerType.VENETBLIND_HORIZ
    var SlatAngle = DynamicVector[Float64]([45.0])

    updateEffectiveMultipliers(
        nlayer, width, height,
        Atop, Abot, Al, Ar, Ah,
        Atop_eff, Abot_eff, Al_eff, Ar_eff, Ah_eff,
        LayerType, SlatAngle
    )

    expect_near(Al_eff[0], 0.0, 1e-6)
    expect_near(Ar_eff[0], 0.0, 1e-6)
    expect_near(Atop_eff[0], 0.1, 1e-6)
    expect_near(Abot_eff[0], 0.1, 1e-6)
    expect_near(Ah_eff[0], 0.007655, 1e-6)


# Test: WindowRoutines_EffectiveOpennessVerticalVenetianBlind_45_deg
def test_WindowRoutines_EffectiveOpennessVerticalVenetianBlind_45_deg() raises:
    alias nlayer = 1
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var LayerType = DynamicVector[TARCOGLayerType](nlayer)
    var Atop_eff = DynamicVector[Float64](nlayer, 0.0)
    var Abot_eff = DynamicVector[Float64](nlayer, 0.0)
    var Al_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ar_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ah_eff = DynamicVector[Float64](nlayer, 0.0)

    var Atop = DynamicVector[Float64]([0.1])
    var Abot = DynamicVector[Float64]([0.1])
    var Al = DynamicVector[Float64]([0.0])
    var Ar = DynamicVector[Float64]([0.0])
    var Ah = DynamicVector[Float64]([0.2])

    LayerType[0] = TARCOGLayerType.VENETBLIND_VERT
    var SlatAngle = DynamicVector[Float64]([45.0])

    updateEffectiveMultipliers(
        nlayer, width, height,
        Atop, Abot, Al, Ar, Ah,
        Atop_eff, Abot_eff, Al_eff, Ar_eff, Ah_eff,
        LayerType, SlatAngle
    )

    expect_near(Al_eff[0], 0.0, 1e-6)
    expect_near(Ar_eff[0], 0.0, 1e-6)
    expect_near(Atop_eff[0], 0.1, 1e-6)
    expect_near(Abot_eff[0], 0.1, 1e-6)
    expect_near(Ah_eff[0], 0.026550, 1e-6)


# Test: WindowRoutines_EffectiveOpennessOtherShades
def test_WindowRoutines_EffectiveOpennessOtherShades() raises:
    alias nlayer = 1
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var LayerType = DynamicVector[TARCOGLayerType](nlayer)
    var Atop_eff = DynamicVector[Float64](nlayer, 0.0)
    var Abot_eff = DynamicVector[Float64](nlayer, 0.0)
    var Al_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ar_eff = DynamicVector[Float64](nlayer, 0.0)
    var Ah_eff = DynamicVector[Float64](nlayer, 0.0)

    var Atop = DynamicVector[Float64]([0.1])
    var Abot = DynamicVector[Float64]([0.1])
    var Al = DynamicVector[Float64]([0.0])
    var Ar = DynamicVector[Float64]([0.0])
    var Ah = DynamicVector[Float64]([0.2])

    LayerType[0] = TARCOGLayerType.DIFFSHADE
    var SlatAngle = DynamicVector[Float64]([0.0])

    updateEffectiveMultipliers(
        nlayer, width, height,
        Atop, Abot, Al, Ar, Ah,
        Atop_eff, Abot_eff, Al_eff, Ar_eff, Ah_eff,
        LayerType, SlatAngle
    )

    expect_near(Al_eff[0], 0.0, 1e-6)
    expect_near(Ar_eff[0], 0.0, 1e-6)
    expect_near(Atop_eff[0], 0.1, 1e-6)
    expect_near(Abot_eff[0], 0.1, 1e-6)
    expect_near(Ah_eff[0], 0.011307, 1e-6)