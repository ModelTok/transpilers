# EXTERNAL DEPS (to wire in glue):
# - linearInterpolation: from WCECommon.hpp

fn linearInterpolation(x1: Float64, x2: Float64, y1: Float64, y2: Float64, x: Float64) -> Float64:
    raise Error("Wire in linearInterpolation from WCECommon.hpp")

struct LinearInterpolationTest:
    fn setUp(inout self):
        pass
    
    fn test_1(self):
        # Begin Test: Simple linear interpolation.
        let x1: Float64 = 1.0
        let x2: Float64 = 2.0
        let y1: Float64 = 10.0
        let y2: Float64 = 20.0
        let x: Float64 = 1.5
        let correct_y: Float64 = 15.0
        let evaluated_y: Float64 = linearInterpolation(x1, x2, y1, y2, x)
        
        let diff = abs(correct_y - evaluated_y)
        assert diff < 1e-6, "linearInterpolation test failed"

fn main():
    var test = LinearInterpolationTest()
    test.setUp()
    test.test_1()
    print("All tests passed!")
