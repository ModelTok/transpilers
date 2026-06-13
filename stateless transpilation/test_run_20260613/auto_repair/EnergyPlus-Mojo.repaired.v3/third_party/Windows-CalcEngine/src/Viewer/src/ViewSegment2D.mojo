from memory import SharedPtr
from Segment2D import CSegment2D
from Point2D import CPoint2D
from ViewerConstants import ViewerConstants

enum Shadowing:
    No = 0
    Partial
    Total

enum PointPosition:
    Visible
    Invisible
    OnLine

class CViewSegment2D(CSegment2D):
    # inherits from enable_shared_from_this<CViewSegment2D> (not directly translatable)

    def __init__(self, t_StartPoint: SharedPtr[CPoint2D], t_EndPoint: SharedPtr[CPoint2D]):
        CSegment2D.__init__(self, t_StartPoint, t_EndPoint)
        self.m_Normal = SharedPtr[CViewSegment2D]()
        self.m_NormalCalculated = False

    def getNormal(self) -> SharedPtr[CViewSegment2D]:
        if not self.m_NormalCalculated:
            self.calculateNormal()
            self.m_NormalCalculated = True
        return self.m_Normal

    def __eq__(self borrowed, rhs: CViewSegment2D borrowed) -> Bool:
        return CSegment2D.__eq__(self, rhs)

    def __ne__(self borrowed, rhs: CViewSegment2D borrowed) -> Bool:
        return not (self == rhs)

    def viewFactorCoefficient(self borrowed, t_Segment: CSegment2D borrowed) -> Float64:
        var r11 = CSegment2D(self.m_StartPoint, t_Segment.endPoint()).length()
        var r22 = CSegment2D(self.m_EndPoint, t_Segment.startPoint()).length()
        var r12 = CSegment2D(self.m_StartPoint, t_Segment.startPoint()).length()
        var r21 = CSegment2D(self.m_EndPoint, t_Segment.endPoint()).length()
        var vFCoeff = r12 + r21 - r22 - r11
        if vFCoeff < ViewerConstants.MIN_VIEW_COEFF:
            vFCoeff = 0
        return vFCoeff

    def selfShadowing(self borrowed, t_Segment: CViewSegment2D borrowed) -> Shadowing:
        var totalShadowing = Shadowing.Partial
        var vThis = self.isInSelfShadow(t_Segment)
        var vOther = t_Segment.isInSelfShadow(self)
        if vThis == Shadowing.Total or vOther == Shadowing.Total:
            totalShadowing = Shadowing.Total
        elif vThis == Shadowing.No and vOther == Shadowing.No:
            totalShadowing = Shadowing.No
        return totalShadowing

    def isInSelfShadow(self borrowed, t_Segment: CViewSegment2D borrowed) -> Shadowing:
        var numOfInvisibles = 0
        var visibilityStart = self.position(t_Segment.startPoint[])
        var visibilityEnd = self.position(t_Segment.endPoint[])
        if visibilityStart == PointPosition.Invisible:
            numOfInvisibles += 1
        if visibilityEnd == PointPosition.Invisible:
            numOfInvisibles += 1
        if numOfInvisibles == 1:
            if visibilityStart == PointPosition.OnLine or visibilityEnd == PointPosition.OnLine:
                numOfInvisibles += 1
        return Shadowing(numOfInvisibles)

    def subSegments(self borrowed, numSegments: Int) -> SharedPtr[List[SharedPtr[CViewSegment2D]]]:
        if numSegments == 0:
            raise Error("Number of subsegments must be greater than zero.")
        var subSegments = SharedPtr[List[SharedPtr[CViewSegment2D]]](List[SharedPtr[CViewSegment2D]]())
        var dX = (self.m_EndPoint[].x() - self.m_StartPoint[].x()) / numSegments
        var dY = (self.m_EndPoint[].y() - self.m_StartPoint[].y()) / numSegments
        var startX = self.m_StartPoint[].x()
        var startY = self.m_StartPoint[].y()
        var sPoint = SharedPtr[CPoint2D](CPoint2D(startX, startY))
        for i in range(1, numSegments + 1):
            var ePoint = SharedPtr[CPoint2D](CPoint2D(startX + i * dX, startY + i * dY))
            var aSegment = SharedPtr[CViewSegment2D](CViewSegment2D(sPoint, ePoint))
            subSegments[].append(aSegment)
            sPoint = ePoint
        return subSegments

    def translate(self, t_x: Float64, t_y: Float64) -> SharedPtr[CViewSegment2D]:
        var aSegment = self.translate(t_x, t_y)  # calls CSegment2D.translate
        return SharedPtr[CViewSegment2D](CViewSegment2D(aSegment.startPoint(), aSegment.endPoint()))

    def position(self borrowed, t_Point: CPoint2D borrowed) -> PointPosition:
        var aPosition = PointPosition.OnLine
        if not (t_Point.sameCoordinates(self.m_StartPoint[]) or t_Point.sameCoordinates(self.m_EndPoint[])):
            var dx = self.m_EndPoint[].x() - self.m_StartPoint[].x()
            var dy = self.m_EndPoint[].y() - self.m_StartPoint[].y()
            var position = dx * (t_Point.y() - self.m_StartPoint[].y()) - dy * (t_Point.x() - self.m_StartPoint[].x())
            if position > ViewerConstants.DISTANCE_TOLERANCE:
                aPosition = PointPosition.Invisible
            elif position < -ViewerConstants.DISTANCE_TOLERANCE:
                aPosition = PointPosition.Visible
        return aPosition

    def calculateNormal(self):
        assert self.length() > 0
        var xn = (self.m_EndPoint[].y() - self.m_StartPoint[].y()) / self.length()
        var yn = (self.m_StartPoint[].x() - self.m_EndPoint[].x()) / self.length()
        var startPoint = SharedPtr[CPoint2D](CPoint2D(0, 0))  # normal always starts from (0, 0)
        var endPoint = SharedPtr[CPoint2D](CPoint2D(xn, yn))
        self.m_Normal = SharedPtr[CViewSegment2D](CViewSegment2D(startPoint, endPoint))

    var m_Normal: SharedPtr[CViewSegment2D]
    var m_NormalCalculated: Bool