# EXTERNAL DEPS (to wire in glue):
# - CThetaLimits from WCESingleLayerOptics.unit.mojo

from collections.vector import DynamicVector

struct TestBSDFThetaLimitsQuarterBasis:
    var m_thetas: Optional[CThetaLimits]
    
    fn __init__(inout self):
        self.m_thetas = None
    
    fn set_up(inout self):
        var theta_angles = DynamicVector[Float64]()
        theta_angles.push_back(0)
        theta_angles.push_back(18)
        theta_angles.push_back(36)
        theta_angles.push_back(54)
        theta_angles.push_back(76.5)
        
        self.m_thetas = CThetaLimits(theta_angles)
    
    fn get_limits(self) -> CThetaLimits:
        return self.m_thetas.value()
    
    fn test_quarter_basis(inout self):
        self.set_up()
        
        var a_limits = self.get_limits()
        var results = a_limits.getThetaLimits()
        
        var correct_results = DynamicVector[Float64]()
        correct_results.push_back(0)
        correct_results.push_back(9)
        correct_results.push_back(27)
        correct_results.push_back(45)
        correct_results.push_back(63)
        correct_results.push_back(90)
        
        assert len(results) == len(correct_results)
        
        for i in range(len(results)):
            assert abs(results[i] - correct_results[i]) < 1e-6
