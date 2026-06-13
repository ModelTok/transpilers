from memory import shared_ptr, make_shared
from vector import vector
from algorithm import find_if, find, sort
from math import abs, tan, radians
from Geometry2DBeam.hpp import (
    FenestrationCommon_Side as Side,
    CViewSegment2D,
    CGeometry2D,
    CSegment2D,
    CPoint2D,
    BeamViewFactor,
    CDirect2DBeam,
    CDirect2DRay,
    CDirect2DRaysResult,
    CDirect2DRaysResults,
    CDirect2DRays,
    CGeometry2DBeam,
)
from Geometry2D.hpp import CGeometry2D
from ViewSegment2D.hpp import CViewSegment2D, IntersectionStatus, PointPosition
from Segment2D.hpp import CSegment2D
from Point2D.hpp import CPoint2D
from ViewerConstants.hpp import ViewerConstants
from WCECommon.hpp import PointsProfile2DCompare

def BeamViewFactor.__init__(inout self, t_Geometry2DIndex: size_t, t_SegmentIndex: size_t, t_Value: float64, t_PercentHit: float64):
    self.enclosureIndex = t_Geometry2DIndex
    self.segmentIndex = t_SegmentIndex
    self.value = t_Value
    self.percentHit = t_PercentHit

def BeamViewFactor.__eq__(self, other: BeamViewFactor) -> bool:
    return (other.enclosureIndex == self.enclosureIndex) and (other.segmentIndex == self.segmentIndex)

def CDirect2DBeam.__init__(inout self, t_Beam: shared_ptr[CViewSegment2D]):
    self.m_Beam = t_Beam
    if t_Beam is None:
        raise Error("Direct beam must have correct beam assigned.")
    self.m_Segments = make_shared[vector[shared_ptr[CViewSegment2D]]]()

def CDirect2DBeam.checkSegment(inout self, t_Segment: shared_ptr[CViewSegment2D]):
    var aStatus = self.m_Beam.intersectionWithLine(t_Segment)
    if aStatus != IntersectionStatus.No:
        self.m_Segments.push_back(t_Segment)

def CDirect2DBeam.Side(self) -> float64:
    assert(self.m_Beam is not None)
    return self.m_Beam.startPoint().y()

def CDirect2DBeam.getClosestCommonSegment(self, t_Beam: shared_ptr[CDirect2DBeam]) -> shared_ptr[CViewSegment2D]:
    var aSegment: shared_ptr[CViewSegment2D] = None
    for thisSegment in self.m_Segments[]:
        if t_Beam.isSegmentIn(thisSegment):
            if aSegment is None:
                aSegment = thisSegment
            else:
                if aSegment.centerPoint().x() > thisSegment.centerPoint().x():
                    aSegment = thisSegment
    return aSegment

def CDirect2DBeam.cosAngle(self, t_Segment: shared_ptr[CViewSegment2D]) -> float64:
    assert(self.m_Beam is not None)
    return self.m_Beam.dotProduct(t_Segment) / self.m_Beam.length()

def CDirect2DBeam.isSegmentIn(self, t_Segment: shared_ptr[CViewSegment2D]) -> bool:
    var isIn = False
    for thisSegment in self.m_Segments[]:
        if thisSegment == t_Segment:
            isIn = True
            break
    return isIn

def CDirect2DRay.__init__(inout self, t_Beam1: shared_ptr[CDirect2DBeam], t_Beam2: shared_ptr[CDirect2DBeam]):
    self.m_Beam1 = t_Beam1
    self.m_Beam2 = t_Beam2
    if t_Beam1 is None:
        raise Error("Beam number one of the ray is not correctly created.")
    if t_Beam2 is None:
        raise Error("Beam number two of the ray is not correctly created.")

def CDirect2DRay.__init__(inout self, t_Ray1: shared_ptr[CViewSegment2D], t_Ray2: shared_ptr[CViewSegment2D]):
    if t_Ray1 is None:
        raise Error("Ray number one of the ray is not correctly created.")
    if t_Ray2 is None:
        raise Error("Ray number two of the ray is not correctly created.")
    self.m_Beam1 = make_shared[CDirect2DBeam](t_Ray1)
    self.m_Beam2 = make_shared[CDirect2DBeam](t_Ray2)

def CDirect2DRay.rayNormalHeight(self) -> float64:
    assert(self.m_Beam1 is not None)
    assert(self.m_Beam2 is not None)
    return self.m_Beam1.Side() - self.m_Beam2.Side()

def CDirect2DRay.checkSegment(inout self, t_Segment: shared_ptr[CViewSegment2D]):
    assert(self.m_Beam1 is not None)
    assert(self.m_Beam2 is not None)
    self.m_Beam1.checkSegment(t_Segment)
    self.m_Beam2.checkSegment(t_Segment)

def CDirect2DRay.closestSegmentHit(self) -> shared_ptr[CViewSegment2D]:
    return self.m_Beam1.getClosestCommonSegment(self.m_Beam2)

def CDirect2DRay.cosAngle(self, t_Segment: shared_ptr[CViewSegment2D]) -> float64:
    assert(self.m_Beam1 is not None)
    return self.m_Beam1.cosAngle(t_Segment)

def CDirect2DRaysResult.__init__(inout self, t_ProfileAngle: float64, t_DirectToDirect: float64, t_BeamViewFactors: shared_ptr[vector[BeamViewFactor]]):
    self.m_ViewFactors = t_BeamViewFactors
    self.m_DirectToDirect = t_DirectToDirect
    self.m_ProfileAngle = t_ProfileAngle

def CDirect2DRaysResult.beamViewFactors(self) -> shared_ptr[vector[BeamViewFactor]]:
    return self.m_ViewFactors

def CDirect2DRaysResult.directToDirect(self) -> float64:
    return self.m_DirectToDirect

def CDirect2DRaysResult.profileAngle(self) -> float64:
    return self.m_ProfileAngle

def CDirect2DRaysResults.__init__(inout self):
    self.m_Results = make_shared[vector[shared_ptr[CDirect2DRaysResult]]]()

def CDirect2DRaysResults.getResult(inout self, t_ProfileAngle: float64) -> shared_ptr[CDirect2DRaysResult]:
    var Result: shared_ptr[CDirect2DRaysResult] = None
    var it = find_if(self.m_Results.begin(), self.m_Results.end(), fn(obj: shared_ptr[CDirect2DRaysResult]) -> bool:
        return abs(obj.profileAngle() - t_ProfileAngle) < 1e-6
    )
    if it != self.m_Results.end():
        Result = *it
    return Result

def CDirect2DRaysResults.append(inout self, t_ProfileAngle: float64, t_DirectToDirect: float64, t_BeamViewFactor: shared_ptr[vector[BeamViewFactor]]) -> shared_ptr[CDirect2DRaysResult]:
    var aResult = make_shared[CDirect2DRaysResult](t_ProfileAngle, t_DirectToDirect, t_BeamViewFactor)
    self.m_Results.push_back(aResult)
    return aResult

def CDirect2DRaysResults.clear(inout self):
    self.m_Results.clear()

def CDirect2DRays.__init__(inout self, t_Side: Side):
    self.m_Side = t_Side
    self.m_LowerRay = None
    self.m_UpperRay = None
    self.m_CurrentResult = None

def CDirect2DRays.appendGeometry2D(inout self, t_Geometry2D: shared_ptr[CGeometry2D]):
    self.m_Geometries2D.push_back(t_Geometry2D)
    self.m_Results.clear()

def CDirect2DRays.beamViewFactors(inout self, t_ProfileAngle: float64) -> shared_ptr[vector[BeamViewFactor]]:
    self.calculateAllProperties(t_ProfileAngle)
    assert(self.m_CurrentResult is not None)
    return self.m_CurrentResult.beamViewFactors()

def CDirect2DRays.directToDirect(inout self, t_ProfileAngle: float64) -> float64:
    self.calculateAllProperties(t_ProfileAngle)
    assert(self.m_CurrentResult is not None)
    return self.m_CurrentResult.directToDirect()

def CDirect2DRays.calculateAllProperties(inout self, t_ProfileAngle: float64):
    if self.m_CurrentResult is not None and self.m_CurrentResult.profileAngle() != t_ProfileAngle:
        self.m_CurrentResult = self.m_Results.getResult(t_ProfileAngle)
    if self.m_CurrentResult is None:
        self.findRayBoundaries(t_ProfileAngle)
        self.findInBetweenRays(t_ProfileAngle)
        self.calculateBeamProperties(t_ProfileAngle)

def CDirect2DRays.findRayBoundaries(inout self, t_ProfileAngle: float64):
    var entryRay: shared_ptr[CViewSegment2D] = None
    for aGeometry in self.m_Geometries2D:
        var aPoint: shared_ptr[CPoint2D] = None
        if self.m_Side == Side.Front:
            aPoint = aGeometry.entryPoint()
        elif self.m_Side == Side.Back:
            aPoint = aGeometry.exitPoint()
        else:
            assert(False, "Incorrect assignement of ray position.")
        entryRay = self.createSubBeam(*aPoint, t_ProfileAngle)
        if aGeometry == self.m_Geometries2D[0]:
            self.m_LowerRay = entryRay
            self.m_UpperRay = entryRay
        else:
            var aProfilePoint = PointsProfile2DCompare(t_ProfileAngle)
            if aProfilePoint(self.m_LowerRay.startPoint(), entryRay.startPoint()):
                self.m_LowerRay = entryRay
            if not aProfilePoint(self.m_UpperRay.startPoint(), entryRay.startPoint()):
                self.m_UpperRay = entryRay

def CDirect2DRays.findInBetweenRays(inout self, t_ProfileAngle: float64):
    var inBetweenPoints = vector[shared_ptr[CPoint2D]]()
    for aEnclosure in self.m_Geometries2D:
        var aSegments = aEnclosure.segments()
        if self.isInRay(*(*aSegments)[0].startPoint()):
            inBetweenPoints.push_back((*aSegments)[0].startPoint())
        for aSegment in *aSegments:
            var endPoint = aSegment.endPoint()
            if self.m_UpperRay.position(*endPoint) == PointPosition.Visible and self.m_LowerRay.position(*endPoint) == PointPosition.Invisible:
                inBetweenPoints.push_back(endPoint)
    self.m_Rays.clear()
    sort(inBetweenPoints.begin(), inBetweenPoints.end(), PointsProfile2DCompare(t_ProfileAngle))
    var firstBeam = self.m_UpperRay
    var secondBeam: shared_ptr[CViewSegment2D] = None
    for aPoint in inBetweenPoints:
        secondBeam = self.createSubBeam(*aPoint, t_ProfileAngle)
        var aRay = make_shared[CDirect2DRay](firstBeam, secondBeam)
        if aRay.rayNormalHeight() > ViewerConstants.DISTANCE_TOLERANCE:
            self.m_Rays.push_back(aRay)
        firstBeam = secondBeam
    var aRay = make_shared[CDirect2DRay](firstBeam, self.m_LowerRay)
    self.m_Rays.push_back(aRay)

def CDirect2DRays.calculateBeamProperties(inout self, t_ProfileAngle: float64):
    var totalHeight = 0.0
    for beamRay in self.m_Rays:
        totalHeight += beamRay.rayNormalHeight()
        for aEnclosure in self.m_Geometries2D:
            for aSegment in (*aEnclosure.segments()):
                beamRay.checkSegment(aSegment)
    var aViewFactors = make_shared[vector[BeamViewFactor]]()
    var aDirectToDirect = 0.0
    var sPoint = make_shared[CPoint2D](0, 0)
    var ePoint = make_shared[CPoint2D](1, 0)
    var aNormalBeamDirection = make_shared[CViewSegment2D](sPoint, ePoint)
    for beamRay in self.m_Rays:
        var currentHeight = beamRay.rayNormalHeight()
        var projectedBeamHeight = beamRay.cosAngle(aNormalBeamDirection)
        var viewFactor = 0.0
        var percentHit = 0.0
        var closestSegment = beamRay.closestSegmentHit()
        for e in range(len(self.m_Geometries2D)):
            for s in range(len(self.m_Geometries2D[e].segments()[])):
                var currentSegment = self.m_Geometries2D[e].segments()[][s]
                if currentSegment == beamRay.closestSegmentHit():
                    viewFactor = currentHeight / totalHeight
                    projectedBeamHeight = projectedBeamHeight * currentHeight
                    var segmentHitLength = projectedBeamHeight / abs(beamRay.cosAngle(currentSegment.getNormal()))
                    percentHit = segmentHitLength / currentSegment.length()
                    var aTest = find(aViewFactors.begin(), aViewFactors.end(), BeamViewFactor(e, s, 0, 0))
                    if aTest != aViewFactors.end():
                        var aVF = *aTest
                        aVF.value += viewFactor
                        aVF.percentHit += percentHit
                    else:
                        var aVF = BeamViewFactor(e, s, viewFactor, percentHit)
                        aViewFactors.push_back(aVF)
        if viewFactor == 0:
            aDirectToDirect += currentHeight / totalHeight
    self.m_CurrentResult = self.m_Results.append(t_ProfileAngle, aDirectToDirect, aViewFactors)

def CDirect2DRays.isInRay(self, t_Point: CPoint2D) -> bool:
    assert(self.m_UpperRay is not None)
    assert(self.m_LowerRay is not None)
    return self.m_UpperRay.position(t_Point) == PointPosition.Visible and self.m_LowerRay.position(t_Point) == PointPosition.Invisible

def CDirect2DRays.createSubBeam(self, t_Point: CPoint2D, t_ProfileAngle: float64) -> shared_ptr[CViewSegment2D]:
    var subSegment: shared_ptr[CViewSegment2D] = None
    var deltaX = 10.0
    var tanPhi = tan(radians(t_ProfileAngle))
    var yStart = t_Point.y() - t_Point.x() * tanPhi
    var yEnd = yStart + deltaX * tanPhi
    var startPoint = make_shared[CPoint2D](0, yStart)
    var endPoint = make_shared[CPoint2D](deltaX, yEnd)
    return make_shared[CViewSegment2D](startPoint, endPoint)

def CGeometry2DBeam.__init__(inout self):
    self.m_Incoming = CDirect2DRays(Side.Front)
    self.m_Outgoing = CDirect2DRays(Side.Back)

def CGeometry2DBeam.appendGeometry2D(inout self, t_Geometry2D: shared_ptr[CGeometry2D]):
    self.m_Incoming.appendGeometry2D(t_Geometry2D)
    self.m_Outgoing.appendGeometry2D(t_Geometry2D)

def CGeometry2DBeam.beamViewFactors(inout self, t_ProfileAngle: float64, t_Side: Side) -> shared_ptr[vector[BeamViewFactor]]:
    var aRay = self.getRay(t_Side)
    return aRay.beamViewFactors(t_ProfileAngle)

def CGeometry2DBeam.directToDirect(inout self, t_ProfileAngle: float64, t_Side: Side) -> float64:
    var aRay = self.getRay(t_Side)
    return aRay.directToDirect(t_ProfileAngle)

def CGeometry2DBeam.getRay(inout self, t_Side: Side) -> CDirect2DRays:
    var aRay: CDirect2DRays
    if t_Side == Side.Front:
        aRay = self.m_Incoming
        return aRay
    elif t_Side == Side.Back:
        aRay = self.m_Outgoing
        return aRay
    else:
        assert(False, "Incorrect assignement of ray position.")
    return aRay