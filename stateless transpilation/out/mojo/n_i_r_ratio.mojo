# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.CSeries: class with integrate() and sum() methods, from FenestrationCommon
# - IntegrationType.Trapezoidal: enum value, from FenestrationCommon
# - SpectralAveraging.CWavelengthRange: class with minLambda() and maxLambda() methods, from SpectralAveraging
# - WavelengthRange.Solar: enum value, from SpectralAveraging


struct CNIRRatio:
    var m_Ratio: Float64
    
    fn __init__(inout self, t_SolarRadiation, lowLambda: Float64, highLambda: Float64):
        var integratedSolar = t_SolarRadiation.integrate(IntegrationType.Trapezoidal)
        var aSolarRange = CWavelengthRange(WavelengthRange.Solar)
        
        var totSolar = integratedSolar.sum(aSolarRange.minLambda(), aSolarRange.maxLambda())
        var totVisible = integratedSolar.sum(lowLambda, highLambda)
        self.m_Ratio = totVisible / totSolar
    
    fn ratio(self) -> Float64:
        return self.m_Ratio
