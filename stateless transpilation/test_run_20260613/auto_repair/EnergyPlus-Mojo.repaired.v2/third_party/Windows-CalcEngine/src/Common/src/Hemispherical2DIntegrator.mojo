from Series import CSeries
from IntegratorStrategy import IntegrationType
from MathFunctions import radians
from math import sin, cos

@value
struct CHemispherical2DIntegrator:
    var m_Value: Float64

    def __init__(inout self, borrowed t_Series: CSeries, t_IntegrationType: IntegrationType, normalizationCoefficient: Float64):
        var aResultValues = CSeries()
        for ser in t_Series:
            var angle = radians(ser.x())
            var value = ser.value()
            var sinCos = sin(angle) * cos(angle)
            aResultValues.addProperty(angle, value * sinCos)
        aResultValues.sort()
        var integrated = aResultValues.integrate(t_IntegrationType, normalizationCoefficient)
        self.m_Value = 2 * integrated.sum()

    def value(self) -> Float64:
        return self.m_Value