# EXTERNAL DEPS (to wire in glue):
# - DeflectionCalculation enum values from TARCOGParams
# - DeflectionRelaxation constant from TARCOGParams
# - maxlay, MaxGap, maxlay2 constants from TARCOGParams
# - Constant.Pi from EnergyPlus
# - LDSumMax, LDSumMean functions from TARCOGCommon

fn pow_2(x: Float64) -> Float64:
    return x * x

fn pow_3(x: Float64) -> Float64:
    return x * x * x

fn pow_6(x: Float64) -> Float64:
    return x ** 6

fn PanesDeflection(
    DeflectionStandard: Int32,
    W: Float64,
    H: Float64,
    nlayer: Int32,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    PaneThickness: List[Float64],
    NonDeflectedGapWidth: List[Float64],
    DeflectedGapWidthMax: List[Float64],
    DeflectedGapWidthMean: List[Float64],
    PanelTemps: List[Float64],
    YoungsMod: List[Float64],
    PoissonsRat: List[Float64],
    LayerDeflection: List[Float64],
    nperr: List[Int32],
    ErrorMessage: List[String],
    deflection_calculation_temperature: Int32,
    deflection_calculation_gap_widths: Int32,
    maxlay: Int32,
    deflection_relaxation: Float64,
    ld_sum_max: fn(Float64, Float64) -> Float64,
    ld_sum_mean: fn(Float64, Float64) -> Float64,
    pi: Float64,
) -> None:
    var DCoeff = List[Float64](int(maxlay))
    
    for i in range(int(nlayer)):
        DCoeff[i] = YoungsMod[i] * pow_3(PaneThickness[i]) / (12 * (1 - pow_2(PoissonsRat[i])))
    
    if DeflectionStandard == deflection_calculation_temperature:
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
            maxlay,
            deflection_relaxation,
            ld_sum_max,
            ld_sum_mean,
            pi,
        )
    elif DeflectionStandard == deflection_calculation_gap_widths:
        DeflectionWidths(
            nlayer,
            W,
            H,
            DCoeff,
            NonDeflectedGapWidth,
            DeflectedGapWidthMax,
            DeflectedGapWidthMean,
            LayerDeflection,
            maxlay,
            ld_sum_max,
            ld_sum_mean,
        )
    else:
        return

fn DeflectionTemperatures(
    nlayer: Int32,
    W: Float64,
    H: Float64,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    NonDeflectedGapWidth: List[Float64],
    DeflectedGapWidthMax: List[Float64],
    DeflectedGapWidthMean: List[Float64],
    PanelTemps: List[Float64],
    DCoeff: List[Float64],
    LayerDeflection: List[Float64],
    nperr: List[Int32],
    ErrorMessage: List[String],
    maxlay: Int32,
    deflection_relaxation: Float64,
    ld_sum_max: fn(Float64, Float64) -> Float64,
    ld_sum_mean: fn(Float64, Float64) -> Float64,
    pi: Float64,
) -> None:
    var Pi_6 = pow_6(pi)
    
    var DPressure = List[Float64](int(maxlay))
    var Vini = List[Float64](len(NonDeflectedGapWidth))
    var Vgap = List[Float64](len(NonDeflectedGapWidth))
    var Pgap = List[Float64](len(NonDeflectedGapWidth))
    var Tgap = List[Float64](len(NonDeflectedGapWidth))
    
    for i in range(int(nlayer) - 1):
        Vini[i] = NonDeflectedGapWidth[i] * W * H
    
    var MaxLDSum = ld_sum_max(W, H)
    var MeanLDSum = ld_sum_mean(W, H)
    var Ratio = MeanLDSum / MaxLDSum
    
    var W_H_Ratio = W * H * Ratio
    for i in range(int(nlayer) - 1):
        Vgap[i] = Vini[i] + W_H_Ratio * (LayerDeflection[i] - LayerDeflection[i + 1])
    
    for i in range(int(nlayer) - 1):
        var j = 2 * (i + 1)
        Tgap[i] = (PanelTemps[j - 1] + PanelTemps[j]) / 2
    
    for i in range(int(nlayer) - 1):
        Pgap[i] = Pini * Vini[i] * Tgap[i] / (Tini * Vgap[i])
    
    DPressure[0] = Pgap[0] - Pa
    if int(nlayer) > 1:
        DPressure[int(nlayer) - 1] = Pa - Pgap[int(nlayer) - 2]
    
    for i in range(1, int(nlayer) - 1):
        DPressure[i] = Pgap[i] - Pgap[i - 1]
    
    var deflection_fac = deflection_relaxation * MaxLDSum * 16
    for i in range(int(nlayer)):
        LayerDeflection[i] += deflection_fac * DPressure[i] / (Pi_6 * DCoeff[i])
    
    for i in range(int(nlayer) - 1):
        DeflectedGapWidthMax[i] = NonDeflectedGapWidth[i] + LayerDeflection[i] - LayerDeflection[i + 1]
        if DeflectedGapWidthMax[i] < 0.0:
            nperr[0] = 2001
            ErrorMessage[0] = "Glazing panes collapsed"
    
    for i in range(int(nlayer) - 1):
        DeflectedGapWidthMean[i] = NonDeflectedGapWidth[i] + Ratio * (DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i])

fn DeflectionWidths(
    nlayer: Int32,
    W: Float64,
    H: Float64,
    DCoeff: List[Float64],
    NonDeflectedGapWidth: List[Float64],
    DeflectedGapWidthMax: List[Float64],
    DeflectedGapWidthMean: List[Float64],
    LayerDeflection: List[Float64],
    maxlay: Int32,
    ld_sum_max: fn(Float64, Float64) -> Float64,
    ld_sum_mean: fn(Float64, Float64) -> Float64,
) -> None:
    var nominator = 0.0
    for i in range(int(nlayer) - 1):
        var SumL = 0.0
        for j in range(i, int(nlayer) - 1):
            SumL += NonDeflectedGapWidth[j] - DeflectedGapWidthMax[j]
        nominator += SumL * DCoeff[i]
    
    var denominator = 0.0
    for i in range(int(nlayer)):
        denominator += DCoeff[i]
    
    LayerDeflection[int(nlayer) - 1] = nominator / denominator
    
    for i in range(int(nlayer) - 2, -1, -1):
        LayerDeflection[i] = DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i] + LayerDeflection[i + 1]
    
    var MaxLDSum = ld_sum_max(W, H)
    var MeanLDSum = ld_sum_mean(W, H)
    var Ratio = MeanLDSum / MaxLDSum
    
    for i in range(int(nlayer) - 1):
        DeflectedGapWidthMean[i] = NonDeflectedGapWidth[i] + Ratio * (DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i])
