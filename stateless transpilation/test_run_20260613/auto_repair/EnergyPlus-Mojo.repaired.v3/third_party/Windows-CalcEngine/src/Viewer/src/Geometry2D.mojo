from WCECommon import SquareMatrix
from ViewSegment2D import CViewSegment2D
from Point2D import CPoint2D
from ViewerConstants import ViewerConstants
from Geometry2D import CGeometry2D
from memory import SharedPtr, make_shared
from vector import Vector, DynamicVector
from utils import ConstSharedPtr

# Standard library equivalents
alias std_vector = DynamicVector
alias std_shared_ptr = SharedPtr
alias std_make_shared = make_shared

struct CGeometry2D:
    var m_Segments: SharedPtr[DynamicVector[SharedPtr[CViewSegment2D]]]
    var m_ViewFactors: SquareMatrix
    var m_ViewFactorsCalculated: Bool

    def __init__(inout self):
        self.m_Segments = make_shared[DynamicVector[SharedPtr[CViewSegment2D]]]()
        self.m_ViewFactorsCalculated = False

    def appendSegment(inout self, t_Segment: SharedPtr[CViewSegment2D]):
        self.m_Segments[].push_back(t_Segment)
        self.m_ViewFactorsCalculated = False

    def appendGeometry2D(inout self, t_Geometry2D: SharedPtr[CGeometry2D]):
        for aSegment in (*(t_Geometry2D[].m_Segments)):
            self.m_Segments[].push_back(aSegment)
        self.m_ViewFactorsCalculated = False

    def viewFactors(inout self) -> SquareMatrix:
        self.checkViewFactors()
        return self.m_ViewFactors

    def Translate(self, t_x: Float64, t_y: Float64) -> SharedPtr[CGeometry2D]:
        var aEnclosure = make_shared[CGeometry2D]()
        for aSegment in (*(self.m_Segments)):
            var newSegment: SharedPtr[CSegment2D] = aSegment[].translate(t_x, t_y)
            var newEnSegment = make_shared[CViewSegment2D](newSegment[].startPoint(), newSegment[].endPoint())
            aEnclosure[].appendSegment(newEnSegment)
        return aEnclosure

    def firstPoint(self) -> SharedPtr[CPoint2D]:
        return self.m_Segments[].front()[].startPoint()

    def lastPoint(self) -> SharedPtr[CPoint2D]:
        return self.m_Segments[].back()[].endPoint()

    def entryPoint(self) -> SharedPtr[CPoint2D]:
        var xStart = self.m_Segments[].front()[].centerPoint()[].x()
        var xEnd = self.m_Segments[].back()[].centerPoint()[].x()
        var aPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        var startPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        var endPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        if xStart <= xEnd:
            startPoint = self.m_Segments[].front()[].startPoint()
            endPoint = self.m_Segments[].front()[].endPoint()
        else:
            startPoint = self.m_Segments[].back()[].startPoint()
            endPoint = self.m_Segments[].back()[].endPoint()
        if startPoint[].x() < endPoint[].x():
            aPoint = startPoint
        else:
            aPoint = endPoint
        return aPoint

    def exitPoint(self) -> SharedPtr[CPoint2D]:
        var xStart = self.m_Segments[].front()[].centerPoint()[].x()
        var xEnd = self.m_Segments[].back()[].centerPoint()[].x()
        var aPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        var startPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        var endPoint: SharedPtr[CPoint2D] = SharedPtr[CPoint2D]()
        if xStart >= xEnd:
            startPoint = self.m_Segments[].front()[].startPoint()
            endPoint = self.m_Segments[].front()[].endPoint()
        else:
            startPoint = self.m_Segments[].back()[].startPoint()
            endPoint = self.m_Segments[].back()[].endPoint()
        if startPoint[].x() > endPoint[].x():
            aPoint = startPoint
        else:
            aPoint = endPoint
        return aPoint

    def segments(self) -> SharedPtr[DynamicVector[SharedPtr[CViewSegment2D]]]:
        return self.m_Segments

    @staticmethod
    def pointInSegmentsView(t_Segment1: CViewSegment2D, t_Segment2: CViewSegment2D, t_Point: CPoint2D) -> Bool:
        var aPolygon: DynamicVector[CViewSegment2D] = DynamicVector[CViewSegment2D]()
        aPolygon.push_back(t_Segment1)
        var point1 = t_Segment1.endPoint()
        var point2 = t_Segment2.startPoint()
        var aSide2 = CViewSegment2D(point1, point2)
        if aSide2.length() > 0:
            aPolygon.push_back(aSide2)
        aPolygon.push_back(t_Segment2)
        var point3 = t_Segment2.endPoint()
        var point4 = t_Segment1.startPoint()
        var aSide4 = CViewSegment2D(point3, point4)
        if aSide4.length() > 0:
            aPolygon.push_back(aSide4)
        var inSide = True
        for aSegment in aPolygon:
            inSide = inSide and (aSegment.position(t_Point) == PointPosition.Visible)
            if not inSide:
                break
        return inSide

    def thirdSurfaceShadowing(self, t_Segment1: CViewSegment2D, t_Segment2: CViewSegment2D) -> Bool:
        var intersection = False
        var intSegments: DynamicVector[SharedPtr[CViewSegment2D]] = DynamicVector[SharedPtr[CViewSegment2D]]()
        var r11 = make_shared[CViewSegment2D](t_Segment1.startPoint(), t_Segment2.endPoint())
        if r11[].length() > 0:
            intSegments.push_back(r11)
        var r22 = make_shared[CViewSegment2D](t_Segment1.endPoint(), t_Segment2.startPoint())
        if r22[].length() > 0:
            intSegments.push_back(r22)
        for aSegment in (*(self.m_Segments)):
            for iSegment in intSegments:
                if (*(aSegment)) != t_Segment1 and (*(aSegment)) != t_Segment2:
                    intersection = intersection or iSegment[].intersectionWithSegment(aSegment)
                    intersection = intersection or CGeometry2D.pointInSegmentsView(t_Segment1, t_Segment2, *(aSegment[].startPoint()))
                    intersection = intersection or CGeometry2D.pointInSegmentsView(t_Segment1, t_Segment2, *(aSegment[].endPoint()))
                    if intersection:
                        return intersection
        return intersection

    def thirdSurfaceShadowingSimple(self, t_Segment1: SharedPtr[CViewSegment2D], t_Segment2: SharedPtr[CViewSegment2D]) -> Bool:
        var intersection = False
        var centerLine = make_shared[CViewSegment2D](t_Segment1[].centerPoint(), t_Segment2[].centerPoint())
        for aSegment in (*(self.m_Segments)):
            if aSegment != t_Segment1 and aSegment != t_Segment2:
                intersection = intersection or centerLine[].intersectionWithSegment(aSegment)
                if intersection:
                    break
        return intersection

    def viewFactorCoeff(self, t_Segment1: SharedPtr[CViewSegment2D], t_Segment2: SharedPtr[CViewSegment2D]) -> Float64:
        var subViewCoeff = 0.0
        var subSeg1 = t_Segment1[].subSegments(ViewerConstants.NUM_OF_SEGMENTS)
        var subSeg2 = t_Segment2[].subSegments(ViewerConstants.NUM_OF_SEGMENTS)
        for sub1 in (*(subSeg1)):
            for sub2 in (*(subSeg2)):
                var selfShadowing = sub1[].selfShadowing(*(sub2))
                var tSurfBlock = self.thirdSurfaceShadowingSimple(sub1, sub2)
                if not tSurfBlock and selfShadowing == Shadowing.No:
                    var cVF = sub1[].viewFactorCoefficient(*(sub2))
                    subViewCoeff += cVF
        if subViewCoeff < ViewerConstants.MIN_VIEW_COEFF:
            subViewCoeff = 0
        return subViewCoeff

    def checkViewFactors(inout self):
        if not self.m_ViewFactorsCalculated:
            var size = self.m_Segments[].size()
            self.m_ViewFactors = SquareMatrix(size)
            for i in range(size):
                for j in range(i, size):
                    if i != j:
                        var selfShadowing = (*(self.m_Segments)[i])[].selfShadowing(*((*(self.m_Segments)[j])[]))
                        if selfShadowing != Shadowing.Total:
                            var shadowedByThirdSurface = self.thirdSurfaceShadowing((*(self.m_Segments)[i])[], (*(self.m_Segments)[j])[])
                            var vfCoeff = 0.0
                            if not shadowedByThirdSurface and (selfShadowing == Shadowing.No):
                                vfCoeff = (*(self.m_Segments)[i])[].viewFactorCoefficient(*((*(self.m_Segments)[j])[]))
                            elif shadowedByThirdSurface or selfShadowing == Shadowing.Partial:
                                vfCoeff = self.viewFactorCoeff((*(self.m_Segments)[i]), (*(self.m_Segments)[j]))
                            self.m_ViewFactors[i, j] = vfCoeff / (2 * (*(self.m_Segments)[i])[].length())
                            self.m_ViewFactors[j, i] = vfCoeff / (2 * (*(self.m_Segments)[j])[].length())
            self.m_ViewFactorsCalculated = True