from memory import Pointer
from option import Optional
from math import *
from WCECommon import ConstantsData

struct FrameData:
    var UValue: Float64
    var EdgeUValue: Float64
    var ProjectedFrameDimension: Float64
    var WettedLength: Float64
    var Absorptance: Float64

    def __init__(inout self):
        self.UValue = 0
        self.EdgeUValue = 0
        self.ProjectedFrameDimension = 0
        self.WettedLength = 0
        self.Absorptance = 0

    def __init__(inout self, uValue: Float64, edgeUValue: Float64, projectedFrameDimension: Float64, wettedLength: Float64, absorptance: Float64 = 0.3):
        self.UValue = uValue
        self.EdgeUValue = edgeUValue
        self.ProjectedFrameDimension = projectedFrameDimension
        self.WettedLength = wettedLength
        self.Absorptance = absorptance

    def splitFrameWidth(inout self):
        self.ProjectedFrameDimension = self.ProjectedFrameDimension / 2
        self.WettedLength = self.WettedLength / 2

    def shgc(self, hc: Float64) -> Float64:
        if hc == 0 or self.WettedLength == 0:
            return 0
        return self.Absorptance * self.UValue / hc * self.ProjectedFrameDimension / self.WettedLength

@value
enum FrameSide:
    Left
    Right

@value
enum FrameType:
    Interior
    Exterior

@value
struct Frame:
    var m_Length: Float64
    var m_FrameType: FrameType
    var m_FrameData: FrameData
    var m_Frame: Dict[FrameSide, Optional[Frame]]
    var m_DividerArea: Float64
    var m_NumberOfDividers: Int

    def __init__(inout self, length: Float64, frameType: FrameType = FrameType.Exterior, frameData: FrameData = FrameData()):
        self.m_Length = length
        self.m_FrameType = frameType
        self.m_FrameData = frameData
        self.m_Frame = Dict[FrameSide, Optional[Frame]]()
        self.m_DividerArea = 0
        self.m_NumberOfDividers = 0

    def frameType(self) -> FrameType:
        return self.m_FrameType

    def projectedArea(self) -> Float64:
        var area = self.m_Length * self.m_FrameData.ProjectedFrameDimension
        var scaleFactor = 1.0 if self.m_FrameType == FrameType.Interior else 0.5
        if self.m_Frame.contains(FrameSide.Left) and self.m_Frame[FrameSide.Left].is_some() and self.m_Frame[FrameSide.Left].value().frameType() == FrameType.Exterior:
            area -= self.m_FrameData.ProjectedFrameDimension * self.m_Frame[FrameSide.Left].value().projectedFrameDimension() * scaleFactor
        if self.m_Frame.contains(FrameSide.Right) and self.m_Frame[FrameSide.Right].is_some() and self.m_Frame[FrameSide.Right].value().frameType() == FrameType.Exterior:
            area -= self.m_FrameData.ProjectedFrameDimension * self.m_Frame[FrameSide.Right].value().projectedFrameDimension() * scaleFactor
        return area

    def wettedArea(self) -> Float64:
        var area = self.m_Length * self.m_FrameData.WettedLength
        var scaleFactor = 1.0 if self.m_FrameType == FrameType.Interior else 0.5
        if self.m_Frame.contains(FrameSide.Left) and self.m_Frame[FrameSide.Left].is_some() and self.m_Frame[FrameSide.Left].value().frameType() == FrameType.Exterior:
            area -= self.m_FrameData.WettedLength * self.m_Frame[FrameSide.Left].value().projectedFrameDimension() * scaleFactor
        if self.m_Frame.contains(FrameSide.Right) and self.m_Frame[FrameSide.Right].is_some() and self.m_Frame[FrameSide.Right].value().frameType() == FrameType.Exterior:
            # Note: original C++ had Left here which appears to be a bug; we keep it verbatim
            area -= self.m_FrameData.WettedLength * self.m_Frame[FrameSide.Right].value().projectedFrameDimension() * scaleFactor
        return area

    def setFrameData(inout self, frameData: FrameData):
        self.m_FrameData = frameData

    def frameData(self) -> FrameData:
        return self.m_FrameData

    def edgeOfGlassArea(self) -> Float64:
        var length = self.m_Length
        if self.m_Frame.contains(FrameSide.Left) and self.m_Frame[FrameSide.Left].is_some():
            length -= self.m_Frame[FrameSide.Left].value().projectedFrameDimension()
            if self.m_FrameType == FrameType.Interior:
                length -= ConstantsData.EOGHeight
        if self.m_Frame.contains(FrameSide.Right) and self.m_Frame[FrameSide.Right].is_some():
            length -= self.m_Frame[FrameSide.Right].value().projectedFrameDimension()
            if self.m_FrameType == FrameType.Interior:
                length -= ConstantsData.EOGHeight
        var area = length * ConstantsData.EOGHeight
        if self.m_Frame.contains(FrameSide.Left) and self.m_Frame[FrameSide.Left].is_some() and self.m_Frame[FrameSide.Left].value().frameType() == FrameType.Exterior and self.m_FrameType == FrameType.Exterior:
            area -= ConstantsData.EOGHeight * ConstantsData.EOGHeight / 2
        if self.m_Frame.contains(FrameSide.Right) and self.m_Frame[FrameSide.Right].is_some() and self.m_Frame[FrameSide.Right].value().frameType() == FrameType.Exterior and self.m_FrameType == FrameType.Exterior:
            area -= ConstantsData.EOGHeight * ConstantsData.EOGHeight / 2
        area -= self.m_DividerArea * self.m_NumberOfDividers
        return area

    def projectedFrameDimension(self) -> Float64:
        return self.m_FrameData.ProjectedFrameDimension

    def assignFrame(inout self, frame: Frame, side: FrameSide):
        self.m_Frame[side] = Optional(frame)

    def assignDividerArea(inout self, area: Float64, nDividers: Int):
        self.m_DividerArea = area
        self.m_NumberOfDividers = nDividers

    def setFrameType(inout self, type: FrameType):
        self.m_FrameType = type