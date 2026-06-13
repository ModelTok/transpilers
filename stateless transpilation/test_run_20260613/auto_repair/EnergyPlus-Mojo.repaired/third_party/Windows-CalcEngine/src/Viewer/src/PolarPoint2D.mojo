from math import cos, sin, atan, pi
from Point2D import CPoint2D
from WCECommon import radians, degrees, ConstantsData

@value
struct CPolarPoint2D(CPoint2D):
    var m_Theta: Float64
    var m_Radius: Float64

    def __init__(inout self, t_Theta: Float64, t_Radius: Float64):
        CPoint2D.__init__(self, 0, 0)
        self.m_Theta = t_Theta
        self.m_Radius = t_Radius
        var aTheta = radians(self.m_Theta)
        self.m_x = self.m_Radius * cos(aTheta)
        self.m_y = self.m_Radius * sin(aTheta)

    def theta(self) -> Float64:
        return self.m_Theta

    def radius(self) -> Float64:
        return self.m_Radius

    def setCartesian(inout self, x: Float64, y: Float64):
        using ConstantsData.WCE_PI
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
        self.m_Theta = degrees(self.m_Theta)