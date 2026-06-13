# Transpiled from C++: WindowVision.cpp -> WindowVision.mojo
# Header context: WindowVision.hpp included implicitly

from IGUConfigurations import IIGUSystem
from WholeWindowConfigurations import IVision
from EnvironmentConfigurations import System, Environment
from Frame import Frame, FramePosition, FrameType, FrameData, FrameSide
from ConstantsData import EOGHeight

@value
struct WindowVision(IVision):
    var m_IGUSystem: Pointer[IIGUSystem]
    var m_Width: Float64
    var m_Height: Float64
    var m_IGUUvalue: Float64
    var m_VT: Float64
    var m_Tsol: Float64
    var m_HExterior: Float64
    var m_ExteriorSurfaceHeight: Float64
    var m_Frame: Dict[FramePosition, Frame]
    var m_NumOfVerticalDividers: Int
    var m_NumOfHorizontalDividers: Int
    var m_Divider: Optional[FrameData]

    def __init__(self, width: Float64, height: Float64, tvis: Float64, tsol: Float64, iguSystem: Pointer[IIGUSystem]):
        self.m_IGUSystem = iguSystem
        self.m_Width = width
        self.m_Height = height
        self.m_VT = tvis
        self.m_Tsol = tsol
        self.m_ExteriorSurfaceHeight = height
        self.m_Frame = Dict[FramePosition, Frame]()
        self.m_Frame[FramePosition.Top] = Frame(width)
        self.m_Frame[FramePosition.Bottom] = Frame(width)
        self.m_Frame[FramePosition.Left] = Frame(height)
        self.m_Frame[FramePosition.Right] = Frame(height)
        self.m_NumOfVerticalDividers = 0
        self.m_NumOfHorizontalDividers = 0
        self.m_Divider = None
        # Initialization from constructor body:
        self.m_IGUSystem.setWidthAndHeight(width, height)
        self.m_IGUSystem.setInteriorAndExteriorSurfacesHeight(self.m_ExteriorSurfaceHeight)
        self.m_IGUUvalue = self.m_IGUSystem.getUValue()
        self.m_HExterior = self.m_IGUSystem.getH(System.SHGC, Environment.Outdoor)

    def uValue(self) -> Float64:
        var frameWeightedUValue: Float64 = 0.0
        var edgeOfGlassWeightedUValue: Float64 = 0.0
        for key, frame in self.m_Frame.items():
            _ = key  # ignore
            frameWeightedUValue += frame.projectedArea() * frame.frameData().UValue
            edgeOfGlassWeightedUValue += frame.edgeOfGlassArea() * frame.frameData().EdgeUValue
        var COGWeightedUValue: Float64 = self.m_IGUUvalue * (self.area() - self.frameProjectedArea() - self.edgeOfGlassArea() - self.dividerArea() - self.dividerEdgeArea())
        var dividerWeightedUValue: Float64 = 0.0
        var dividerWeightedEdgeUValue: Float64 = 0.0
        if self.m_Divider is not None:
            dividerWeightedUValue += self.dividerArea() * self.m_Divider.value().UValue
            dividerWeightedEdgeUValue += self.dividerEdgeArea() * self.m_Divider.value().EdgeUValue
        return (COGWeightedUValue + frameWeightedUValue + edgeOfGlassWeightedUValue + dividerWeightedUValue + dividerWeightedEdgeUValue) / self.area()

    def shgc(self) -> Float64:
        return self.shgc(self.m_Tsol)

    def shgc(self, tSol: Float64) -> Float64:
        var frameWeightedSHGC: Float64 = 0.0
        for key, frame in self.m_Frame.items():
            _ = key
            frameWeightedSHGC += frame.projectedArea() * frame.frameData().shgc(self.m_HExterior)
        var COGWeightedSHGC: Float64 = self.m_IGUSystem.getSHGC(tSol) * (self.area() - self.frameProjectedArea() - self.dividerArea())
        var dividerWeightedSHGC: Float64 = 0.0
        if self.m_Divider is not None:
            dividerWeightedSHGC += self.dividerArea() * self.m_Divider.value().shgc(self.m_HExterior)
        return (COGWeightedSHGC + frameWeightedSHGC + dividerWeightedSHGC) / self.area()

    def area(self) -> Float64:
        return self.m_Width * self.m_Height

    def vt(self) -> Float64:
        return self.vt(self.m_VT)

    def vt(self, tVis: Float64) -> Float64:
        return self.visionPercentage() * tVis

    def visionPercentage(self) -> Float64:
        return (self.area() - self.frameProjectedArea() - self.dividerArea()) / self.area()

    def hc(self) -> Float64:
        return self.m_HExterior

    def uValueCOG(self) -> Float64:
        return self.m_IGUUvalue

    def shgcCOG(self) -> Float64:
        return self.m_IGUSystem.getSHGC(self.m_Tsol)

    def setHc(self, hc: Float64):
        self.m_HExterior = hc

    def setFrameData(self, position: FramePosition, frameData: FrameData):
        self.m_Frame[position].setFrameData(frameData)
        self.connectFrames()
        self.resizeIGU()

    def setFrameTypes(self, frameTypes: Dict[FramePosition, FrameType]):
        for position, type in frameTypes.items():
            if position in self.m_Frame:
                self.m_Frame[position].setFrameType(type)
        self.connectFrames()

    def setDividers(self, divider: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Divider = divider
        self.m_NumOfHorizontalDividers = nHorizontal
        self.m_NumOfVerticalDividers = nVertical
        var numOfDivs: Dict[FramePosition, Int] = Dict[FramePosition, Int]()
        numOfDivs[FramePosition.Top] = self.m_NumOfVerticalDividers
        numOfDivs[FramePosition.Bottom] = self.m_NumOfVerticalDividers
        numOfDivs[FramePosition.Left] = self.m_NumOfHorizontalDividers
        numOfDivs[FramePosition.Right] = self.m_NumOfHorizontalDividers
        for key, frame in self.m_Frame.items():
            frame.assignDividerArea(self.m_Divider.value().ProjectedFrameDimension * EOGHeight, numOfDivs[key])

    def setInteriorAndExteriorSurfaceHeight(self, height: Float64):
        self.m_ExteriorSurfaceHeight = height
        self.m_IGUSystem.setInteriorAndExteriorSurfacesHeight(self.m_ExteriorSurfaceHeight)
        self.m_IGUUvalue = self.m_IGUSystem.getUValue()
        self.m_HExterior = self.m_IGUSystem.getH(System.SHGC, Environment.Outdoor)

    def getIGUWidth(self) -> Float64:
        return self.m_Width - self.m_Frame[FramePosition.Left].projectedFrameDimension() - self.m_Frame[FramePosition.Right].projectedFrameDimension()

    def getIGUHeight(self) -> Float64:
        return self.m_Height - self.m_Frame[FramePosition.Top].projectedFrameDimension() - self.m_Frame[FramePosition.Bottom].projectedFrameDimension()

    def connectFrames(self):
        self.m_Frame[FramePosition.Top].assignFrame(self.m_Frame[FramePosition.Right], FrameSide.Left)
        self.m_Frame[FramePosition.Top].assignFrame(self.m_Frame[FramePosition.Left], FrameSide.Right)
        self.m_Frame[FramePosition.Bottom].assignFrame(self.m_Frame[FramePosition.Right], FrameSide.Right)
        self.m_Frame[FramePosition.Bottom].assignFrame(self.m_Frame[FramePosition.Left], FrameSide.Left)
        self.m_Frame[FramePosition.Left].assignFrame(self.m_Frame[FramePosition.Top], FrameSide.Left)
        self.m_Frame[FramePosition.Left].assignFrame(self.m_Frame[FramePosition.Bottom], FrameSide.Right)
        self.m_Frame[FramePosition.Right].assignFrame(self.m_Frame[FramePosition.Bottom], FrameSide.Left)
        self.m_Frame[FramePosition.Right].assignFrame(self.m_Frame[FramePosition.Top], FrameSide.Right)

    def resizeIGU(self):
        var width: Float64 = self.m_Width - self.m_Frame[FramePosition.Left].projectedFrameDimension() - self.m_Frame[FramePosition.Right].projectedFrameDimension()
        var height: Float64 = self.m_Height - self.m_Frame[FramePosition.Top].projectedFrameDimension() - self.m_Frame[FramePosition.Bottom].projectedFrameDimension()
        self.m_IGUSystem.setWidthAndHeight(width, height)
        self.m_IGUSystem.setInteriorAndExteriorSurfacesHeight(self.m_ExteriorSurfaceHeight)
        self.m_IGUUvalue = self.m_IGUSystem.getUValue()
        self.m_HExterior = self.m_IGUSystem.getH(System.SHGC, Environment.Outdoor)

    def dividerArea(self) -> Float64:
        var result: Float64 = 0.0
        if self.m_Divider is not None:
            var dividersWidth: Float64 = self.m_Width - self.m_Frame[FramePosition.Left].projectedFrameDimension() - self.m_Frame[FramePosition.Right].projectedFrameDimension()
            var dividersHeight: Float64 = self.m_Height - self.m_Frame[FramePosition.Top].projectedFrameDimension() - self.m_Frame[FramePosition.Bottom].projectedFrameDimension()
            var areaVertical: Float64 = self.m_NumOfVerticalDividers * dividersHeight * self.m_Divider.value().ProjectedFrameDimension
            var areaHorizontal: Float64 = self.m_NumOfHorizontalDividers * dividersWidth * self.m_Divider.value().ProjectedFrameDimension
            var areaDoubleCounted: Float64 = self.m_NumOfHorizontalDividers * self.m_NumOfVerticalDividers * (self.m_Divider.value().ProjectedFrameDimension ** 2)
            result = areaVertical + areaHorizontal - areaDoubleCounted
        return result

    def dividerEdgeArea(self) -> Float64:
        var result: Float64 = 0.0
        if self.m_Divider is not None:
            var eogWidth: Float64 = self.m_Width - self.m_Frame[FramePosition.Left].projectedFrameDimension() - self.m_Frame[FramePosition.Right].projectedFrameDimension() - 2 * EOGHeight
            var eogHeight: Float64 = self.m_Height - self.m_Frame[FramePosition.Top].projectedFrameDimension() - self.m_Frame[FramePosition.Bottom].projectedFrameDimension() - 2 * EOGHeight
            var areaVertical: Float64 = self.m_NumOfVerticalDividers * 2 * EOGHeight * eogHeight
            var areaHorizontal: Float64 = self.m_NumOfHorizontalDividers * 2 * EOGHeight * eogWidth
            var dividerAreaSubtract: Float64 = 4 * self.m_NumOfVerticalDividers * self.m_NumOfHorizontalDividers * self.m_Divider.value().ProjectedFrameDimension * EOGHeight
            var eogAreaSubtract: Float64 = 4 * self.m_NumOfVerticalDividers * self.m_NumOfHorizontalDividers * EOGHeight * EOGHeight
            result = areaVertical + areaHorizontal - dividerAreaSubtract - eogAreaSubtract
        return result

    def frameProjectedArea(self) -> Float64:
        var area: Float64 = 0.0
        for key, system in self.m_Frame.items():
            area += system.projectedArea()
        return area

    def edgeOfGlassArea(self) -> Float64:
        var area: Float64 = 0.0
        for key, frame in self.m_Frame.items():
            _ = key
            area += frame.edgeOfGlassArea()
        return area