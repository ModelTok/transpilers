from ViewerConstants import DISTANCE_TOLERANCE
from WCECommon import radians
from math import abs, tan
from std.rc import RC

struct CPoint2D:
    var m_x: Float64
    var m_y: Float64

    def __init__(self, x: Float64, y: Float64):
        self.m_x = x
        self.m_y = y

    def x(self) -> Float64:
        return self.m_x

    def y(self) -> Float64:
        return self.m_y

    def sameCoordinates(self, t_Point: CPoint2D) -> Bool:
        return (abs(t_Point.x() - self.m_x) < DISTANCE_TOLERANCE) and (abs(t_Point.y() - self.m_y) < DISTANCE_TOLERANCE)

    def dotProduct(self, t_Point: CPoint2D) -> Float64:
        return self.m_x * t_Point.x() + self.m_y * t_Point.y()

    def __eq__(self, rhs: CPoint2D) -> Bool:
        return self.m_x == rhs.m_x and self.m_y == rhs.m_y

    def __ne__(self, rhs: CPoint2D) -> Bool:
        return not (self == rhs)

    def isLeft(self, t_Point: CPoint2D) -> Bool:
        return self.m_x < t_Point.x()

    def translate(self, t_x: Float64, t_y: Float64) -> RC[CPoint2D]:
        let aPoint = RC.make[CPoint2D](self.m_x + t_x, self.m_y + t_y)
        return aPoint

struct PointsProfile2DCompare:
    var m_ProfileAngle: Float64

    def __init__(self, t_ProfileAngle: Float64):
        self.m_ProfileAngle = t_ProfileAngle

    def __call__(self, t_Point1: RC[CPoint2D], t_Point2: RC[CPoint2D]) -> Bool:
        var isHigher: Bool = False
        if self.m_ProfileAngle != 0:
            let tanPhi = tan(radians(self.m_ProfileAngle))
            if tanPhi > 0:
                isHigher = (t_Point1.x() - t_Point1.y() / tanPhi) < (t_Point2.x() - t_Point2.y() / tanPhi)
            else:
                isHigher = (t_Point1.x() - t_Point1.y() / tanPhi) > (t_Point2.x() - t_Point2.y() / tanPhi)
        else:
            isHigher = t_Point1.y() > t_Point2.y()
        return isHigher
<<<FILE>>>