from TARCOGParams import DeflectionCalculation, maxlay, MaxGap, maxlay2, DeflectionRelaxation, Constant
from TARCOGCommon import pow_2, pow_3, pow_6, LDSumMax, LDSumMean
from DataGlobals import EP_SIZE_CHECK

def PanesDeflection(
    DeflectionStandard: DeflectionCalculation,
    W: Float64,
    H: Float64,
    nlayer: Int,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    PaneThickness: Array[Float64],
    NonDeflectedGapWidth: Array[Float64],
    DeflectedGapWidthMax: Array[Float64],
    DeflectedGapWidthMean: Array[Float64],
    PanelTemps: Array[Float64],
    YoungsMod: Array[Float64],
    PoissonsRat: Array[Float64],
    LayerDeflection: Array[Float64],
    nperr: Int,
    ErrorMessage: String,
):
    EP_SIZE_CHECK(PaneThickness, maxlay)
    EP_SIZE_CHECK(NonDeflectedGapWidth, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMax, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMean, MaxGap)
    EP_SIZE_CHECK(PanelTemps, maxlay2)
    EP_SIZE_CHECK(YoungsMod, maxlay)
    EP_SIZE_CHECK(PoissonsRat, maxlay)
    EP_SIZE_CHECK(LayerDeflection, maxlay)
    var DCoeff = Array[Float64](maxlay)
    for i in range(1, nlayer + 1):
        DCoeff[i - 1] = YoungsMod[i - 1] * pow_3(PaneThickness[i - 1]) / (12 * (1 - pow_2(PoissonsRat[i - 1])))
    if DeflectionStandard == DeflectionCalculation.TEMPERATURE:
        DeflectionTemperatures(
            nlayer,
            W,
            H,
            Pa,
            Pini,
            Tini,
            NonDeflectedGapWidth,
            DeflectedGapWidthMax,
            DeflectedGapWidthMean,
            PanelTemps,
            DCoeff,
            LayerDeflection,
            nperr,
            ErrorMessage,
        )
    elif DeflectionStandard == DeflectionCalculation.GAP_WIDTHS:
        DeflectionWidths(nlayer, W, H, DCoeff, NonDeflectedGapWidth, DeflectedGapWidthMax, DeflectedGapWidthMean, LayerDeflection)
    else:  # including NO_DEFLECTION_CALCULATION
        return

def DeflectionTemperatures(
    nlayer: Int,
    W: Float64,
    H: Float64,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    NonDeflectedGapWidth: Array[Float64],
    DeflectedGapWidthMax: Array[Float64],
    DeflectedGapWidthMean: Array[Float64],
    PanelTemps: Array[Float64],
    DCoeff: Array[Float64],
    LayerDeflection: Array[Float64],
    nperr: Int,
    ErrorMessage: String,
):
    EP_SIZE_CHECK(NonDeflectedGapWidth, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMax, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMean, MaxGap)
    EP_SIZE_CHECK(PanelTemps, maxlay2)
    EP_SIZE_CHECK(DCoeff, maxlay)
    EP_SIZE_CHECK(LayerDeflection, maxlay)
    var Pi_6: Float64 = pow_6(Constant.Pi)
    var DPressure = Array[Float64](maxlay)  # delta pressure at each glazing layer
    var Vini = Array[Float64](MaxGap)
    var Vgap = Array[Float64](MaxGap)
    var Pgap = Array[Float64](MaxGap)
    var Tgap = Array[Float64](MaxGap)
    var MaxLDSum: Float64
    var MeanLDSum: Float64
    var Ratio: Float64
    for i in range(1, nlayer):
        Vini[i - 1] = NonDeflectedGapWidth[i - 1] * W * H
    MaxLDSum = LDSumMax(W, H)
    MeanLDSum = LDSumMean(W, H)
    Ratio = MeanLDSum / MaxLDSum
    var W_H_Ratio: Float64 = W * H * Ratio
    for i in range(1, nlayer):
        Vgap[i - 1] = Vini[i - 1] + W_H_Ratio * (LayerDeflection[i - 1] - LayerDeflection[i])
    for i in range(1, nlayer):
        var j: Int = 2 * i
        Tgap[i - 1] = (PanelTemps[j - 1] + PanelTemps[j]) / 2
    for i in range(1, nlayer):
        Pgap[i - 1] = Pini * Vini[i - 1] * Tgap[i - 1] / (Tini * Vgap[i - 1])
    DPressure[0] = Pgap[0] - Pa
    if nlayer > 1:
        DPressure[nlayer - 1] = Pa - Pgap[nlayer - 2]
    for i in range(2, nlayer):
        DPressure[i - 1] = Pgap[i - 1] - Pgap[i - 2]
    var deflection_fac: Float64 = DeflectionRelaxation * MaxLDSum * 16
    for i in range(1, nlayer + 1):
        LayerDeflection[i - 1] += deflection_fac * DPressure[i - 1] / (Pi_6 * DCoeff[i - 1])
    for i in range(1, nlayer):
        DeflectedGapWidthMax[i - 1] = NonDeflectedGapWidth[i - 1] + LayerDeflection[i - 1] - LayerDeflection[i]
        if DeflectedGapWidthMax[i - 1] < 0.0:
            nperr = 2001  # glazing panes collapsed
            ErrorMessage = "Glazing panes collapsed"
    for i in range(1, nlayer):
        DeflectedGapWidthMean[i - 1] = NonDeflectedGapWidth[i - 1] + Ratio * (DeflectedGapWidthMax[i - 1] - NonDeflectedGapWidth[i - 1])

def DeflectionWidths(
    nlayer: Int,
    W: Float64,
    H: Float64,
    DCoeff: Array[Float64],
    NonDeflectedGapWidth: Array[Float64],
    DeflectedGapWidthMax: Array[Float64],
    DeflectedGapWidthMean: Array[Float64],
    LayerDeflection: Array[Float64],
):
    EP_SIZE_CHECK(DCoeff, maxlay)
    EP_SIZE_CHECK(NonDeflectedGapWidth, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMax, MaxGap)
    EP_SIZE_CHECK(DeflectedGapWidthMean, MaxGap)
    EP_SIZE_CHECK(LayerDeflection, maxlay)
    var nominator: Float64 = 0.0
    for i in range(1, nlayer):
        var SumL: Float64 = 0.0
        for j in range(i, nlayer):
            SumL += NonDeflectedGapWidth[j - 1] - DeflectedGapWidthMax[j - 1]
        nominator += SumL * DCoeff[i - 1]
    var denominator: Float64 = 0.0
    for i in range(1, nlayer + 1):
        denominator += DCoeff[i - 1]
    LayerDeflection[nlayer - 1] = nominator / denominator
    for i in range(nlayer - 1, 0, -1):
        LayerDeflection[i - 1] = DeflectedGapWidthMax[i - 1] - NonDeflectedGapWidth[i - 1] + LayerDeflection[i]
    var MaxLDSum: Float64 = LDSumMax(W, H)
    var MeanLDSum: Float64 = LDSumMean(W, H)
    var Ratio: Float64 = MeanLDSum / MaxLDSum
    for i in range(1, nlayer):
        DeflectedGapWidthMean[i - 1] = NonDeflectedGapWidth[i - 1] + Ratio * (DeflectedGapWidthMax[i - 1] - NonDeflectedGapWidth[i - 1])