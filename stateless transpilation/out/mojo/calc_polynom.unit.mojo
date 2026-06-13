# EXTERNAL DEPS (to wire in glue):
# - Polynom (from WCECommon.hpp) - polynomial evaluator struct taking DynamicVector[Float64] coefficients and value_at(x: Float64) -> Float64

from testing import assert_almost_equal


struct Polynom:
    var coefficients: DynamicVector[Float64]
    
    fn __init__(inout self, coefficients: DynamicVector[Float64]) -> None:
        self.coefficients = coefficients
    
    fn value_at(self, x: Float64) -> Float64:
        var result: Float64 = 0.0
        var power: Float64 = 1.0
        for i in range(len(self.coefficients)):
            result += self.coefficients[i] * power
            power *= x
        return result


fn test_1() -> None:
    var input_coeffs = DynamicVector[Float64](3)
    input_coeffs.push_back(-6.75)
    input_coeffs.push_back(8.65)
    input_coeffs.push_back(-0.75)
    
    var poly = Polynom(input_coeffs)
    assert_almost_equal(poly.value_at(12), -10.95, atol=1e-6)


fn test_2() -> None:
    var input_coeffs = DynamicVector[Float64](3)
    input_coeffs.push_back(-6.75)
    input_coeffs.push_back(8.65)
    input_coeffs.push_back(-0.75)
    
    var poly = Polynom(input_coeffs)
    assert_almost_equal(poly.value_at(1), 1.15, atol=1e-6)


fn test_3() -> None:
    var input_coeffs = DynamicVector[Float64](7)
    input_coeffs.push_back(-9.27348e-06)
    input_coeffs.push_back(2.288300764)
    input_coeffs.push_back(1.646894009)
    input_coeffs.push_back(-15.39761441)
    input_coeffs.push_back(26.12276881)
    input_coeffs.push_back(-19.1483186)
    input_coeffs.push_back(5.322076488)
    
    var poly = Polynom(input_coeffs)
    assert_almost_equal(poly.value_at(0.7), 0.807353444, atol=1e-6)
