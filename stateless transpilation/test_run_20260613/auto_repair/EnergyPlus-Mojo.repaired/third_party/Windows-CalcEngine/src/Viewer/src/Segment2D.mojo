from math import sqrt, abs, max, min
from Point2D import CPoint2D
from ViewerConstants import DISTANCE_TOLERANCE

enum IntersectionStatus: Int32:
    No = 0
    Point = 1
    Segment = 2

@value
struct CSegment2D:
    var m_StartPoint: CPoint2D*
    var m_EndPoint: CPoint2D*
    var m_CenterPoint: CPoint2D*
    var m_Length: Float64

    def __init__(inout self, t_StartPoint: CPoint2D*, t_EndPoint: CPoint2D*):
        self.m_StartPoint = t_StartPoint
        self.m_EndPoint = t_EndPoint
        self.calculateLength()
        self.calculateCenter()

    def startPoint(self) -> CPoint2D*:
        return self.m_StartPoint

    def endPoint(self) -> CPoint2D*:
        return self.m_EndPoint

    def centerPoint(self) -> CPoint2D*:
        return self.m_CenterPoint

    def __eq__(self, rhs: CSegment2D) -> Bool:
        return self.m_StartPoint == rhs.m_StartPoint and self.m_EndPoint == rhs.m_EndPoint

    def __ne__(self, rhs: CSegment2D) -> Bool:
        return not (self == rhs)

    def length(self) -> Float64:
        return self.m_Length

    def intersectionWithSegment(self, t_Segment: CSegment2D*) -> Bool:
        var aInt: Bool = False
        if self.length() != 0:
            var aPoint = self.intersection(t_Segment)
            if aPoint != None:
                aInt = self.isInRectangleRange(aPoint) and t_Segment.isInRectangleRange(aPoint)
        return aInt

    def intersectionWithLine(self, t_Segment: CSegment2D*) -> IntersectionStatus:
        var status: IntersectionStatus = IntersectionStatus.No
        if self.length() != 0:
            var aPoint = self.intersection(t_Segment)
            if aPoint != None:
                var aInt: Bool = t_Segment.isInRectangleRange(aPoint)
                if aInt:
                    status = IntersectionStatus.Segment
                if t_Segment.startPoint().sameCoordinates(*aPoint) or t_Segment.endPoint().sameCoordinates(*aPoint):
                    status = IntersectionStatus.Point
        return status

    def dotProduct(self, t_Segment: CSegment2D*) -> Float64:
        var p1 = self.intensity()
        var p2 = *t_Segment.intensity()
        return p1.dotProduct(p2)

    def translate(self, t_x: Float64, t_y: Float64) -> CSegment2D*:
        var startPoint = new CPoint2D(self.m_StartPoint.x() + t_x, self.m_StartPoint.y() + t_y)
        var endPoint = new CPoint2D(self.m_EndPoint.x() + t_x, self.m_EndPoint.y() + t_y)
        var aSegment = new CSegment2D(startPoint, endPoint)
        return aSegment

    def intensity(self) -> CPoint2D*:
        var x = self.m_EndPoint.x() - self.m_StartPoint.x()
        var y = self.m_EndPoint.y() - self.m_StartPoint.y()
        var aPoint = new CPoint2D(x, y)
        return aPoint

    def calculateLength(self):
        var deltaX = self.m_EndPoint.x() - self.m_StartPoint.x()
        var deltaY = self.m_EndPoint.y() - self.m_StartPoint.y()
        self.m_Length = sqrt(deltaX * deltaX + deltaY * deltaY)

    def calculateCenter(self):
        var x = (self.m_EndPoint.x() + self.m_StartPoint.x()) / 2
        var y = (self.m_EndPoint.y() + self.m_StartPoint.y()) / 2
        self.m_CenterPoint = new CPoint2D(x, y)

    def intersection(self, t_Segment: CSegment2D*) -> CPoint2D*:
        if t_Segment == None:
            raise Error("Segment for intersection must be provided. Cannot operate with null segment.")
        var intersectionPoint: CPoint2D* = None
        var A1 = self.coeffA()
        var A2 = t_Segment.coeffA()
        var B1 = self.coeffB()
        var B2 = t_Segment.coeffB()
        var C1 = self.coeffC()
        var C2 = t_Segment.coeffC()
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        if abs(A1) > DISTANCE_TOLERANCE:
            var t1 = C2 - C1 * A2 / A1
            var t2 = B2 - B1 * A2 / A1
            if abs(t2) > DISTANCE_TOLERANCE:
                y = t1 / t2
                x = (C1 - B1 * y) / A1
            else:
                return intersectionPoint
        else:
            y = C1 / B1
            x = (C2 - B2 * y) / A2
        intersectionPoint = new CPoint2D(x, y)
        return intersectionPoint

    def isInRectangleRange(self, t_Point: CPoint2D*) -> Bool:
        var inXRange: Bool = False
        var inYRange: Bool = False
        var const maxX = max(self.m_EndPoint.x(), self.m_StartPoint.x())
        var const minX = min(self.m_EndPoint.x(), self.m_StartPoint.x())
        if abs(maxX - minX) > DISTANCE_TOLERANCE:
            if t_Point.x() < (maxX - DISTANCE_TOLERANCE) and t_Point.x() > (minX + DISTANCE_TOLERANCE):
                inXRange = True
        else:
            if abs(t_Point.x() - maxX) < DISTANCE_TOLERANCE:
                inXRange = True
        var const maxY = max(self.m_EndPoint.y(), self.m_StartPoint.y())
        var const minY = min(self.m_EndPoint.y(), self.m_StartPoint.y())
        if abs(maxY - minY) > DISTANCE_TOLERANCE:
            if t_Point.y() < (maxY - DISTANCE_TOLERANCE) and t_Point.y() > (minY + DISTANCE_TOLERANCE):
                inYRange = True
        else:
            if abs(t_Point.y() - maxY) < DISTANCE_TOLERANCE:
                inYRange = True
        return inXRange and inYRange

    def coeffA(self) -> Float64:
        return self.m_StartPoint.y() - self.m_EndPoint.y()

    def coeffB(self) -> Float64:
        return self.m_EndPoint.x() - self.m_StartPoint.x()

    def coeffC(self) -> Float64:
        return self.coeffB() * self.m_StartPoint.y() + self.coeffA() * self.m_StartPoint.x()