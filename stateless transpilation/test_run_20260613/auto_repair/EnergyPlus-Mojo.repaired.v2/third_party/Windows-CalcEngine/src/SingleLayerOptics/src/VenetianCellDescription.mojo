from ..CellDescription import ICellDescription
from ..VenetianSlat import CVenetianSlat, SegmentsDirection
from ..BeamDirection import CBeamDirection
from ...FenestrationCommon.src.FenestrationCommon import SquareMatrix, Side
from ...Viewer.Viewer import CGeometry2D, CGeometry2DBeam, CViewSegment2D, BeamViewFactor

struct CVenetianCellDescription(ICellDescription):
    var m_SlatWidth: Float64
    var m_SlatSpacing: Float64
    var m_SlatTiltAngle: Float64
    var m_CurvatureRadius: Float64
    var m_NumOfSegments: Int
    var m_Top: CVenetianSlat
    var m_Bottom: CVenetianSlat
    var m_Geometry: CGeometry2D
    var m_BeamGeometry: CGeometry2DBeam

    def __init__(inout self,
                t_SlatWidth: Float64,
                t_SlatSpacing: Float64,
                t_SlatTiltAngle: Float64,
                t_CurvatureRadius: Float64,
                t_NumOfSlatSegments: Int):
        self.m_SlatWidth = t_SlatWidth
        self.m_SlatSpacing = t_SlatSpacing
        self.m_SlatTiltAngle = t_SlatTiltAngle
        self.m_CurvatureRadius = t_CurvatureRadius
        self.m_NumOfSegments = t_NumOfSlatSegments
        self.m_Top = CVenetianSlat(t_SlatWidth,
                                   t_SlatSpacing,
                                   t_SlatTiltAngle,
                                   t_CurvatureRadius,
                                   t_NumOfSlatSegments,
                                   SegmentsDirection.Positive)
        self.m_Bottom = CVenetianSlat(t_SlatWidth,
                                      0,
                                      t_SlatTiltAngle,
                                      t_CurvatureRadius,
                                      t_NumOfSlatSegments,
                                      SegmentsDirection.Negative)

        var exteriorSegment = CViewSegment2D(self.m_Bottom.geometry().lastPoint(),
                                             self.m_Top.geometry().firstPoint())
        var interiorSegment = CViewSegment2D(self.m_Top.geometry().lastPoint(),
                                             self.m_Bottom.geometry().firstPoint())
        self.m_Geometry.appendSegment(exteriorSegment)
        self.m_Geometry.appendGeometry2D(self.m_Top.geometry())
        self.m_Geometry.appendSegment(interiorSegment)
        self.m_Geometry.appendGeometry2D(self.m_Bottom.geometry())
        self.m_BeamGeometry.appendGeometry2D(self.m_Top.geometry())
        self.m_BeamGeometry.appendGeometry2D(self.m_Bottom.geometry())

    def numberOfSegments(self) -> Int:
        return 2 + self.m_Top.numberOfSegments() + self.m_Bottom.numberOfSegments()

    def segmentLength(self, Index: Int) -> Float64:
        var aSegments = self.m_Geometry.segments()
        if Index > aSegments.size():
            raise Error("Incorrect index for venetian segment.")
        var aSegment = aSegments[Index]
        return aSegment.length()

    def makeBackwardCell(self) -> CVenetianCellDescription:
        var slatWidth = self.m_Top.slatWidth()
        var slatSpacing = self.m_Top.slatSpacing()
        var slatTiltAngle = -self.m_Top.slatTiltAngle()
        var curvatureRadius = self.m_Top.curvatureRadius()
        var m_NumOfSlatSegments = self.m_Top.numberOfSegments()
        var aBackwardCell = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, m_NumOfSlatSegments)
        return aBackwardCell

    def viewFactors(inout self) -> SquareMatrix:
        return self.m_Geometry.viewFactors()

    def beamViewFactors(inout self,
                        t_ProfileAngle: Float64,
                        t_Side: Side) -> List[BeamViewFactor]:
        return self.m_BeamGeometry.beamViewFactors(-t_ProfileAngle, t_Side)

    def T_dir_dir(inout self,
                  t_Side: Side,
                  t_Direction: CBeamDirection) -> Float64:
        var aProfileAngle = t_Direction.profileAngle()
        return self.m_BeamGeometry.directToDirect(-aProfileAngle, t_Side)

    def R_dir_dir(inout self,
                  t_Side: Side,
                  t_Direction: CBeamDirection) -> Float64:
        return 0.0

    def slatWidth(self) -> Float64:
        return self.m_SlatWidth

    def slatSpacing(self) -> Float64:
        return self.m_SlatSpacing

    def slatTiltAngle(self) -> Float64:
        return self.m_SlatTiltAngle

    def curvatureRadius(self) -> Float64:
        return self.m_CurvatureRadius

    def numOfSegments(self) -> Int:
        return self.m_NumOfSegments
<<<FILE>>>