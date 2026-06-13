from WCEViewer import CGeometry2D, CPolarPoint2D, CViewSegment2D, CPoint2D
from WCECommon import WCE_PI, radians, degrees

enum SegmentsDirection:
    Positive
    Negative

@value
struct CVenetianSlat:
    var m_SlatWidth: Float64
    var m_SlatSpacing: Float64
    var m_SlatTiltAngle: Float64
    var m_CurvatureRadius: Float64
    var m_NumOfSlatSegments: Int
    var m_Direction: SegmentsDirection
    var m_Geometry: Rc[CGeometry2D]

    def __init__(inout self, t_SlatWidth: Float64, t_SlatSpacing: Float64, t_SlatTiltAngle: Float64,
                t_CurvatureRadius: Float64, t_NumOfSegments: Int, t_Direction: SegmentsDirection):
        self.m_SlatWidth = t_SlatWidth
        self.m_SlatSpacing = t_SlatSpacing
        self.m_SlatTiltAngle = t_SlatTiltAngle
        self.m_CurvatureRadius = t_CurvatureRadius
        self.m_NumOfSlatSegments = t_NumOfSegments
        self.m_Direction = t_Direction
        self.m_Geometry = Rc::new(CGeometry2D())
        self.buildSlat()

    def geometry(self) -> Rc[CGeometry2D]:
        return self.m_Geometry

    def slatWidth(self) -> Float64:
        return self.m_SlatWidth

    def slatSpacing(self) -> Float64:
        return self.m_SlatSpacing

    def slatTiltAngle(self) -> Float64:
        return self.m_SlatTiltAngle

    def curvatureRadius(self) -> Float64:
        return self.m_CurvatureRadius

    def numberOfSegments(self) -> Int:
        return self.m_NumOfSlatSegments

    def buildSlat(inout self):
        if self.m_SlatTiltAngle >= 90:
            self.m_SlatTiltAngle = 89.99999
        if self.m_SlatTiltAngle <= -90:
            self.m_SlatTiltAngle = -89.99999

        var radius: Float64 = abs(self.m_CurvatureRadius)
        var translateX: Float64 = 0
        var translateY: Float64 = 0

        if radius > (self.m_SlatWidth / 2):
            # set properties in polar coordinate system
            var theta: Float64 = 2 * asin(self.m_SlatWidth / (2 * radius))
            var theta1: Float64 = 0
            var theta2: Float64 = 0
            var alpha: Float64 = radians(self.m_SlatTiltAngle)
            if self.m_CurvatureRadius > 0:
                theta1 = degrees(WCE_PI / 2 + alpha - theta / 2)
                theta2 = degrees(WCE_PI / 2 + alpha + theta / 2)
            else:
                theta1 = degrees(-WCE_PI / 2 + alpha + theta / 2)
                theta2 = degrees(-WCE_PI / 2 + alpha - theta / 2)

            var dTheta: Float64 = (theta2 - theta1) / self.m_NumOfSlatSegments
            var startTheta: Float64 = 0
            if self.m_Direction == SegmentsDirection.Positive:
                startTheta = theta2
            elif self.m_Direction == SegmentsDirection.Negative:
                startTheta = theta1
            else:
                assert(True, "Incorrect selection for slat segments directions.")

            var startPoint: Rc[CPolarPoint2D] = Rc::new(CPolarPoint2D(startTheta, radius))
            for i in range(1, self.m_NumOfSlatSegments + 1):
                var nextTheta: Float64 = 0
                if self.m_Direction == SegmentsDirection.Positive:
                    nextTheta = startTheta - dTheta * i
                elif self.m_Direction == SegmentsDirection.Negative:
                    nextTheta = startTheta + dTheta * i

                var endPoint: Rc[CPolarPoint2D] = Rc::new(CPolarPoint2D(nextTheta, radius))
                var aSegment: Rc[CViewSegment2D] = Rc::new(CViewSegment2D(startPoint, endPoint))
                self.m_Geometry.appendSegment(aSegment)
                startPoint = endPoint

        elif radius == 0:
            var dWidth: Float64 = self.m_SlatWidth / self.m_NumOfSlatSegments
            var startRadius: Float64 = 0
            if self.m_Direction == SegmentsDirection.Positive:
                startRadius = 0
            elif self.m_Direction == SegmentsDirection.Negative:
                startRadius = dWidth * self.m_NumOfSlatSegments
            else:
                assert(True, "Incorrect selection for slat segments directions.")

            var startPoint: Rc[CPolarPoint2D] = Rc::new(CPolarPoint2D(self.m_SlatTiltAngle, startRadius))
            for i in range(1, self.m_NumOfSlatSegments + 1):
                var nextRadius: Float64 = 0
                if self.m_Direction == SegmentsDirection.Positive:
                    nextRadius = i * dWidth
                elif self.m_Direction == SegmentsDirection.Negative:
                    nextRadius = self.m_SlatWidth - i * dWidth

                var endPoint: Rc[CPolarPoint2D] = Rc::new(CPolarPoint2D(self.m_SlatTiltAngle, nextRadius))
                var aSegment: Rc[CViewSegment2D] = Rc::new(CViewSegment2D(startPoint, endPoint))
                self.m_Geometry.appendSegment(aSegment)
                startPoint = endPoint

        else:
            raise Error("Cannot create slat.")

        var aPoint: Rc[CPoint2D] = None
        if self.m_Direction == SegmentsDirection.Positive:
            aPoint = self.m_Geometry.firstPoint()
        elif self.m_Direction == SegmentsDirection.Negative:
            aPoint = self.m_Geometry.lastPoint()

        translateX = -aPoint.x()
        translateY = -aPoint.y()
        self.m_Geometry = self.m_Geometry.Translate(translateX, translateY + self.m_SlatSpacing)