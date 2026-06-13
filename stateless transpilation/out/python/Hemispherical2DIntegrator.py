from math import radians, sin, cos

# EXTERNAL DEPS (to wire in glue):
# - CSeries: from FenestrationCommon.Series
# - IntegrationType: from FenestrationCommon.IntegratorStrategy


class CHemispherical2DIntegrator:
    """Used to calculated hemispherical values in 2D. If for example some optical property is
    calculated for different incident angles, then this integrator will calculate hemispherical
    to hemispherical value"""
    
    def __init__(self, t_angular_properties, t_integration_type, normalization_coefficient):
        from FenestrationCommon.Series import CSeries
        
        a_result_values = CSeries()
        for ser in t_angular_properties:
            angle = radians(ser.x())
            value = ser.value()
            sin_cos = sin(angle) * cos(angle)
            a_result_values.addProperty(angle, value * sin_cos)
        
        a_result_values.sort()
        
        integrated = a_result_values.integrate(t_integration_type, normalization_coefficient)
        self._value = 2 * integrated.sum()
    
    def value(self):
        return self._value
