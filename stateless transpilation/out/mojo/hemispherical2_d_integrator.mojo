from math import radians, sin, cos

# EXTERNAL DEPS (to wire in glue):
# - CSeries: from FenestrationCommon.Series
# - IntegrationType: from FenestrationCommon.IntegratorStrategy


struct CHemispherical2DIntegrator:
    var _value: Float64
    
    fn __init__(inout self,
                t_angular_properties,
                t_integration_type,
                normalization_coefficient: Float64):
        var a_result_values = CSeries()
        
        for ser in t_angular_properties:
            let angle = radians(ser.x())
            let value = ser.value()
            let sin_cos = sin(angle) * cos(angle)
            a_result_values.addProperty(angle, value * sin_cos)
        
        a_result_values.sort()
        
        let integrated = a_result_values.integrate(t_integration_type, normalization_coefficient)
        self._value = 2 * integrated.sum()
    
    fn value(self) -> Float64:
        return self._value
