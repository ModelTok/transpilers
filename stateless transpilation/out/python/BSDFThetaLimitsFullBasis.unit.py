from typing import List, Protocol, Optional
import unittest

# EXTERNAL DEPS (to wire in glue):
# - CThetaLimits: from WCESingleLayerOptics
#   Constructor: CThetaLimits(theta_angles: List[float])
#   Method: getThetaLimits() -> List[float]

class CThetaLimitsProtocol(Protocol):
    """Protocol for CThetaLimits interface."""
    def getThetaLimits(self) -> List[float]:
        ...

class TestBSDFThetaLimitsFullBasis(unittest.TestCase):
    """Test fixture for BSDF Theta Limits Full Basis."""
    
    m_thetas: Optional[CThetaLimitsProtocol]
    
    def setUp(self) -> None:
        """Initialize test fixture."""
        theta_angles: List[float] = [0, 10, 20, 30, 40, 50, 60, 70, 82.5]
        # Binding: self.m_thetas = CThetaLimits(theta_angles)
        self.m_thetas = None
    
    def get_limits(self) -> CThetaLimitsProtocol:
        """Get limits reference."""
        return self.m_thetas
    
    def test_full_basis(self) -> None:
        """Begin Test: Theta limits - full basis."""
        a_limits: CThetaLimitsProtocol = self.get_limits()
        results: List[float] = a_limits.getThetaLimits()
        correct_results: List[float] = [0, 5, 15, 25, 35, 45, 55, 65, 75, 90]
        
        self.assertEqual(len(results), len(correct_results))
        
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)


if __name__ == '__main__':
    unittest.main()
