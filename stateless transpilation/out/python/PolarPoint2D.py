# EXTERNAL DEPS (to wire in glue):
# - CPoint2D (from Point2D.hpp): base class with m_x, m_y members and constructor(double, double)
# - radians (from WCECommon.hpp, namespace FenestrationCommon): degrees-to-radians conversion
# - degrees (from WCECommon.hpp, namespace FenestrationCommon): radians-to-degrees conversion
# - WCE_PI (from ConstantsData, namespace FenestrationCommon): pi constant

import math


# Stub for CPoint2D from Point2D.hpp
class CPoint2D:
    """Base class stub with m_x, m_y members and constructor(x, y)."""

    def __init__(self, x: float, y: float) -> None:
        self.m_x: float = float(x)
        self.m_y: float = float(y)


# Stub for radians from FenestrationCommon::WCECommon
def radians(theta: float) -> float:
    """Convert degrees to radians."""
    return theta * math.pi / 180.0


# Stub for degrees from FenestrationCommon::WCECommon
def degrees(theta: float) -> float:
    """Convert radians to degrees."""
    return theta * 180.0 / math.pi


# Stub for WCE_PI from FenestrationCommon::ConstantsData
WCE_PI: float = math.pi


class CPolarPoint2D(CPoint2D):
    """
    Polar point is used to convert polar to cartesian coordinate system and vice versa.
    Theta angle is measured counter clockwise from x-axis.
    """

    def __init__(self, t_Theta: float, t_Radius: float) -> None:
        # CPoint2D(0, 0)
        super().__init__(0.0, 0.0)

        self.m_Theta: float = t_Theta
        self.m_Radius: float = t_Radius

        aTheta = radians(self.m_Theta)
        self.m_x = self.m_Radius * math.cos(aTheta)
        self.m_y = self.m_Radius * math.sin(aTheta)

    def theta(self) -> float:
        return self.m_Theta

    def radius(self) -> float:
        return self.m_Radius

    def setCartesian(self, x: float, y: float) -> None:
        self.m_x = x
        self.m_y = y

        if x != 0:
            self.m_Theta = math.atan(y / x)
        elif x == 0 and y > 0:
            self.m_Theta = WCE_PI / 2
        elif x == 0 and y < 0:
            self.m_Theta = 3 * WCE_PI / 2
        else:
            self.m_Theta = 0

        if math.sin(self.m_Theta) != 0:
            self.m_Radius = y / math.sin(self.m_Theta)
        elif math.cos(self.m_Theta) != 0:
            self.m_Radius = x / math.cos(self.m_Theta)
        else:
            self.m_Radius = 0

        # always store angles in degrees
        self.m_Theta = degrees(self.m_Theta)

    def _calculatePolarCoordinates(self) -> None:
        # Calculate polar coordinates from current cartesian coordinates stored in the object
        # Declared in header but not defined in implementation
        pass
