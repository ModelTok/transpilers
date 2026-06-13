# EXTERNAL DEPS (to wire in glue):
# - CAngleLimits: from WCESingleLayerOptics.hpp

fn test_angle_limits_1():
    var a_limits = CAngleLimits(-15, 15)
    var angle = 350
    var is_in_limits = a_limits.isInLimits(angle)
    assert is_in_limits == True, "test_angle_limits_1 failed"

fn main():
    test_angle_limits_1()
