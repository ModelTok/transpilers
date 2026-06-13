struct CThetaLimits:
    var m_theta_limits: List[Float64]
    
    fn __init__(inout self, t_theta_angles: List[Float64]):
        if len(t_theta_angles) == 0:
            raise Error("Error in definition of theta angles. Cannot form theta definitions.")
        self.m_theta_limits = List[Float64]()
        self._create_limits(t_theta_angles)
    
    fn get_theta_limits(self) -> List[Float64]:
        return self.m_theta_limits
    
    fn _create_limits(inout self, t_theta_angles: List[Float64]):
        var previous_angle: Float64 = 90.0
        self.m_theta_limits.append(previous_angle)
        
        var i = len(t_theta_angles) - 1
        while i >= 0:
            var current_angle = t_theta_angles[i]
            var delta = 2.0 * (previous_angle - current_angle)
            var limit = previous_angle - delta
            if limit < 0:
                limit = 0
            self.m_theta_limits.insert(0, limit)
            previous_angle = limit
            i -= 1
