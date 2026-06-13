class CThetaLimits:
    def __init__(self, t_theta_angles: list[float]) -> None:
        if len(t_theta_angles) == 0:
            raise RuntimeError(
                "Error in definition of theta angles. Cannot form theta definitions."
            )
        self.m_theta_limits: list[float] = []
        self._create_limits(t_theta_angles)
    
    def get_theta_limits(self) -> list[float]:
        return self.m_theta_limits
    
    def _create_limits(self, t_theta_angles: list[float]) -> None:
        previous_angle = 90.0
        self.m_theta_limits.append(previous_angle)
        
        for current_angle in reversed(t_theta_angles):
            delta = 2 * (previous_angle - current_angle)
            limit = previous_angle - delta
            if limit < 0:
                limit = 0
            self.m_theta_limits.insert(0, limit)
            previous_angle = limit
