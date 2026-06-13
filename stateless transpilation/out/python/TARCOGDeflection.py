# EXTERNAL DEPS (to wire in glue):
# - DeflectionCalculation enum values from TARCOGParams
# - DeflectionRelaxation constant from TARCOGParams
# - maxlay, MaxGap, maxlay2 constants from TARCOGParams
# - Constant.Pi from EnergyPlus
# - LDSumMax, LDSumMean functions from TARCOGCommon

def pow_2(x):
    return x * x

def pow_3(x):
    return x * x * x

def pow_6(x):
    return x ** 6

def PanesDeflection(
    DeflectionStandard,
    W,
    H,
    nlayer,
    Pa,
    Pini,
    Tini,
    PaneThickness,
    NonDeflectedGapWidth,
    DeflectedGapWidthMax,
    DeflectedGapWidthMean,
    PanelTemps,
    YoungsMod,
    PoissonsRat,
    LayerDeflection,
    nperr,
    ErrorMessage,
    deflection_calculation_temperature,
    deflection_calculation_gap_widths,
    maxlay,
    deflection_relaxation,
    ld_sum_max,
    ld_sum_mean,
    pi,
):
    DCoeff = [0.0] * maxlay
    
    for i in range(nlayer):
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

def DeflectionTemperatures(
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
):
    Pi_6 = pow_6(pi)
    
    DPressure = [0.0] * maxlay
    Vini = [0.0] * len(NonDeflectedGapWidth)
    Vgap = [0.0] * len(NonDeflectedGapWidth)
    Pgap = [0.0] * len(NonDeflectedGapWidth)
    Tgap = [0.0] * len(NonDeflectedGapWidth)
    
    for i in range(nlayer - 1):
        Vini[i] = NonDeflectedGapWidth[i] * W * H
    
    MaxLDSum = ld_sum_max(W, H)
    MeanLDSum = ld_sum_mean(W, H)
    Ratio = MeanLDSum / MaxLDSum
    
    W_H_Ratio = W * H * Ratio
    for i in range(nlayer - 1):
        Vgap[i] = Vini[i] + W_H_Ratio * (LayerDeflection[i] - LayerDeflection[i + 1])
    
    for i in range(nlayer - 1):
        j = 2 * (i + 1)
        Tgap[i] = (PanelTemps[j - 1] + PanelTemps[j]) / 2
    
    for i in range(nlayer - 1):
        Pgap[i] = Pini * Vini[i] * Tgap[i] / (Tini * Vgap[i])
    
    DPressure[0] = Pgap[0] - Pa
    if nlayer > 1:
        DPressure[nlayer - 1] = Pa - Pgap[nlayer - 2]
    
    for i in range(1, nlayer - 1):
        DPressure[i] = Pgap[i] - Pgap[i - 1]
    
    deflection_fac = deflection_relaxation * MaxLDSum * 16
    for i in range(nlayer):
        LayerDeflection[i] += deflection_fac * DPressure[i] / (Pi_6 * DCoeff[i])
    
    for i in range(nlayer - 1):
        DeflectedGapWidthMax[i] = NonDeflectedGapWidth[i] + LayerDeflection[i] - LayerDeflection[i + 1]
        if DeflectedGapWidthMax[i] < 0.0:
            nperr[0] = 2001
            ErrorMessage[0] = "Glazing panes collapsed"
    
    for i in range(nlayer - 1):
        DeflectedGapWidthMean[i] = NonDeflectedGapWidth[i] + Ratio * (DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i])

def DeflectionWidths(
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
):
    nominator = 0.0
    for i in range(nlayer - 1):
        SumL = 0.0
        for j in range(i, nlayer - 1):
            SumL += NonDeflectedGapWidth[j] - DeflectedGapWidthMax[j]
        nominator += SumL * DCoeff[i]
    
    denominator = 0.0
    for i in range(nlayer):
        denominator += DCoeff[i]
    
    LayerDeflection[nlayer - 1] = nominator / denominator
    
    for i in range(nlayer - 2, -1, -1):
        LayerDeflection[i] = DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i] + LayerDeflection[i + 1]
    
    MaxLDSum = ld_sum_max(W, H)
    MeanLDSum = ld_sum_mean(W, H)
    Ratio = MeanLDSum / MaxLDSum
    
    for i in range(nlayer - 1):
        DeflectedGapWidthMean[i] = NonDeflectedGapWidth[i] + Ratio * (DeflectedGapWidthMax[i] - NonDeflectedGapWidth[i])
