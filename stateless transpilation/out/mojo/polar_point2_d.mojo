# EXTERNAL DEPS (to wire in glue):
# - CPoint2D (from Point2D.hpp): base struct with m_x, m_y members and constructor(double, double)
# - radians (from WCECommon.hpp, namespace FenestrationCommon): degrees-to-radians conversion
# - degrees (from WCECommon.hpp, namespace FenestrationCommon): radians-to-degrees conversion
# - WCE_PI (from ConstantsData, namespace FenestrationCommon): pi constant

from math import cos, sin, atan, pi


# Stub for CPoint2D from Point2D.hpp
struct CPoint2D:
    """Base struct stub with m_x, m_y members and constructor(x, y)."""

    var m_x: Float64
    var m_y: Float64

    fn __init__(inout self, x: Float64, y: Float64):
        self.m_x = x
        self.m_y = y


# Stub for WCE_PI from FenestrationCommon::ConstantsData
alias WCE_PI: Float64 = pi


# Stub for radians from FenestrationCommon::WCECommon
fn radians(theta: Float64) -> Float64:
    """Convert degrees to radians."""
    return theta * pi / 180.0


# Stub for degrees from FenestrationCommon::WCECommon
fn degrees(theta: Float64) -> Float64:
    """Convert radians to degrees."""
    return theta * 180.0 / pi


struct CPolarPoint2D(CPoint2D):
    """
    Polar point is used to convert polar to cartesian coordinate system and vice versa.
    Theta angle is measured counter clockwise from x-axis.
    """

    var m_Theta: Float64
    var m_Radius: Float64

    fn __init__(inout self, t_Theta: Float64, t_Radius: Float64):
        # CPoint2D(0, 0) base initialization
        self.m_x = 0.0
        self.m_y = 0.0
        self.m_Theta = t_Theta
        self.m_Radius = t_Radius

        let aTheta = radians(self.m_Theta)
        self.m_x = self.m_Radius * cos(aTheta)
        self.m_y = self.m_Radius * sin(aTheta)

    fn theta(self) -> Float64:
        return self.m_Theta

    fn radius(self) -> Float64:
        return self.m_Radius

    fn setCartesian(inout self, x: Float64, y: Float64):
        self.m_x = x
        self.m_y = y

        if x != 0:
            self.m_Theta = atan(y / x)
        elif x == 0 and y > 0:
            self.m_Theta = WCE_PI / 2
        elif x == 0 and y < 0:
            self.m_Theta = 3 * WCE_PI / 2
        else:
            self.m_Theta = 0

        if sin(self.m_Theta) != 0:
            self.m_Radius = y / sin(self.m_Theta)
        elif cos(self.m_Theta) != 0:
            self.m_Radius = x / cos(self.m_Theta)
        else:
            self.m_Radius = 0

        # always store angles in degrees
        self.m_Theta = degrees(self.m_Theta)

    fn calculatePolarCoordinates(inout self):
        # Calculate polar coordinates from current cartesian coordinates stored in the object
        # Declared in header but not defined in implementation
        pass
