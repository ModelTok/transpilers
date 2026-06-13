# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.CSeries: class with integrate() and sum() methods, from FenestrationCommon
# - IntegrationType.Trapezoidal: enum value, from FenestrationCommon
# - SpectralAveraging.CWavelengthRange: class with minLambda() and maxLambda() methods, from SpectralAveraging
# - WavelengthRange.Solar: enum value, from SpectralAveraging


class CNIRRatio:
    def __init__(self, t_SolarRadiation, lowLambda: float, highLambda: float) -> None:
        integratedSolar = t_SolarRadiation.integrate(IntegrationType.Trapezoidal)
        aSolarRange = CWavelengthRange(WavelengthRange.Solar)
        
        totSolar = integratedSolar.sum(aSolarRange.minLambda(), aSolarRange.maxLambda())
        totVisible = integratedSolar.sum(lowLambda, highLambda)
        self.m_Ratio = totVisible / totSolar
    
    def ratio(self) -> float:
        return self.m_Ratio
