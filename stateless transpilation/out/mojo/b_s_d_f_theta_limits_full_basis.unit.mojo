from typing import Optional, List

# EXTERNAL DEPS (to wire in glue):
# - CThetaLimits: from WCESingleLayerOptics
#   Constructor: CThetaLimits(theta_angles: List[Float64])
#   Method: getThetaLimits() -> List[Float64]

trait CThetaLimitsTrait:
    fn getThetaLimits(self) -> List[Float64]:
        ...

struct TestBSDFThetaLimitsFullBasis:
    var m_thetas: Optional[CThetaLimitsTrait]
    
    fn __init__(inout self):
        self.m_thetas = None
    
    fn setUp(inout self):
        var theta_angles = List[Float64]()
        theta_angles.append(0)
        theta_angles.append(10)
        theta_angles.append(20)
        theta_angles.append(30)
        theta_angles.append(40)
        theta_angles.append(50)
        theta_angles.append(60)
        theta_angles.append(70)
        theta_angles.append(82.5)
        # Binding: self.m_thetas = CThetaLimits(theta_angles)
    
    fn get_limits(self) -> CThetaLimitsTrait:
        return self.m_thetas.value()
    
    fn test_full_basis(self):
        var a_limits = self.get_limits()
        var results = a_limits.getThetaLimits()
        var correct_results = List[Float64]()
        correct_results.append(0)
        correct_results.append(5)
        correct_results.append(15)
        correct_results.append(25)
        correct_results.append(35)
        correct_results.append(45)
        correct_results.append(55)
        correct_results.append(65)
        correct_results.append(75)
        correct_results.append(90)
        
        debug_assert(len(results) == len(correct_results))
        
        for i in range(len(results)):
            debug_assert(abs(results[i] - correct_results[i]) < 1e-6)
