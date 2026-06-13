from WCECommon import CWavelengthRange, WavelengthRange, IntegrationType
from memory import Pointer
from FenestrationCommon import CSeries

@value
class CNIRRatio:
    var m_Ratio: Float64

    def __init__(inout self, t_SolarRadiation: CSeries, lowLambda: Float64, highLambda: Float64):
        var integratedSolar = t_SolarRadiation.integrate(IntegrationType.Trapezoidal)
        var aSolarRange = CWavelengthRange(WavelengthRange.Solar)
        var totSolar = integratedSolar.sum(aSolarRange.minLambda(), aSolarRange.maxLambda())
        var totVisible = integratedSolar.sum(lowLambda, highLambda)
        self.m_Ratio = totVisible / totSolar

    def ratio(self) -> Float64:
        return self.m_Ratio