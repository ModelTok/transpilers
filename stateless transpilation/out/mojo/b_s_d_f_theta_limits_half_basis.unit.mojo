# EXTERNAL DEPS (to wire in glue):
# - CThetaLimits: from WCESingleLayerOptics

from math import isclose
from collections import DynamicVector


fn test_bsdf_theta_limits_half_basis() -> None:
    """Test: Theta limits - half basis."""
    from WCESingleLayerOptics import CThetaLimits

    var theta_angles = DynamicVector[Float64]()
    theta_angles.push_back(0)
    theta_angles.push_back(13)
    theta_angles.push_back(26)
    theta_angles.push_back(39)
    theta_angles.push_back(52)
    theta_angles.push_back(65)
    theta_angles.push_back(80.75)

    let m_thetas = CThetaLimits(theta_angles)
    let results = m_thetas.getThetaLimits()

    var correct_results = DynamicVector[Float64]()
    correct_results.push_back(0)
    correct_results.push_back(6.5)
    correct_results.push_back(19.5)
    correct_results.push_back(32.5)
    correct_results.push_back(45.5)
    correct_results.push_back(58.5)
    correct_results.push_back(71.5)
    correct_results.push_back(90)

    assert len(results) == len(correct_results)

    for i in range(len(results)):
        assert isclose(results[i], correct_results[i], atol=1e-6)


fn main() -> None:
    test_bsdf_theta_limits_half_basis()
    print("Test passed: Theta limits - half basis.")
