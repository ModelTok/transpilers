from WholeWindowConfigurations import FrameData, FramePosition, FrameType, IGUDimensions
from WindowVision import WindowVision
from IWindow import IWindow
from IIGUSystem import IIGUSystem
from memory import Pointer
from utils import String

@value
struct WindowSingleVision(IWindow):
    var vision: WindowVision

    def __init__(inout self):

    def __init__(inout self, width: Float64, height: Float64, tvis: Float64, tsol: Float64, iguSystem: Pointer[IIGUSystem]):
        self.vision = WindowVision(width, height, tvis, tsol, iguSystem)

    def area(self) -> Float64:
        return self.vision.area()

    def uValue(self) -> Float64:
        return self.vision.uValue()

    def shgc(self) -> Float64:
        return self.vision.shgc()

    def shgc(self, tSol: Float64) -> Float64:
        return self.vision.shgc(tSol)

    def vt(self) -> Float64:
        return self.vision.vt()

    def vt(self, tVis: Float64) -> Float64:
        return self.vision.vt(tVis)

    def uValueCOG(self) -> Float64:
        return self.vision.uValueCOG()

    def shgcCOG(self) -> Float64:
        return self.vision.shgcCOG()

    def uValueCOGAverage(self) -> Float64:
        return self.vision.uValueCOG()

    def shgcCOGAverage(self) -> Float64:
        return self.vision.shgcCOG()

    def setFrameTop(inout self, frameData: FrameData):
        self.vision.setFrameData(FramePosition.Top, frameData)

    def setFrameBottom(inout self, frameData: FrameData):
        self.vision.setFrameData(FramePosition.Bottom, frameData)

    def setFrameLeft(inout self, frameData: FrameData):
        self.vision.setFrameData(FramePosition.Left, frameData)

    def setFrameRight(inout self, frameData: FrameData):
        self.vision.setFrameData(FramePosition.Right, frameData)

    def setDividers(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.vision.setDividers(frameData, nHorizontal, nVertical)

    def getIGUDimensions(self) -> IGUDimensions:
        return IGUDimensions(self.vision.getIGUWidth(), self.vision.getIGUHeight())

    def visionPercentage(self) -> Float64:
        return self.vision.visionPercentage()

@value
struct WindowDualVision(IWindow):
    var m_Vision1: WindowVision
    var m_Vision2: WindowVision

    def __init__(inout self):

    def __init__(inout self, width: Float64, height: Float64, tvis1: Float64, tsol1: Float64, iguSystem1: Pointer[IIGUSystem], tvis2: Float64, tsol2: Float64, iguSystem2: Pointer[IIGUSystem]):
        self.m_Vision1 = WindowVision(width, height, tvis1, tsol1, iguSystem1)
        self.m_Vision2 = WindowVision(width, height, tvis2, tsol2, iguSystem2)
        self.averageHc()

    def area(self) -> Float64:
        return self.m_Vision1.area() + self.m_Vision2.area()

    def uValue(self) -> Float64:
        return (self.m_Vision1.uValue() * self.m_Vision1.area() + self.m_Vision2.uValue() * self.m_Vision2.area()) / self.area()

    def shgc(self) -> Float64:
        return (self.m_Vision1.shgc() * self.m_Vision1.area() + self.m_Vision2.shgc() * self.m_Vision2.area()) / self.area()

    def shgc(self, tSol1: Float64, tSol2: Float64) -> Float64:
        return (self.m_Vision1.shgc(tSol1) * self.m_Vision1.area() + self.m_Vision2.shgc(tSol2) * self.m_Vision2.area()) / self.area()

    def shgc(self, tSol: Float64) -> Float64:
        return self.shgc(tSol, tSol)

    def vt(self) -> Float64:
        return (self.m_Vision1.vt() * self.m_Vision1.area() + self.m_Vision2.vt() * self.m_Vision2.area()) / self.area()

    def vt(self, tVis1: Float64, tVis2: Float64) -> Float64:
        return (self.m_Vision1.vt(tVis1) * self.m_Vision1.area() + self.m_Vision2.vt(tVis2) * self.m_Vision2.area()) / self.area()

    def vt(self, tVis: Float64) -> Float64:
        return self.vt(tVis, tVis)

    def uValueCOGAverage(self) -> Float64:
        return (self.m_Vision1.uValueCOG() * self.m_Vision1.area() + self.m_Vision2.uValueCOG() * self.m_Vision2.area()) / self.area()

    def shgcCOGAverage(self) -> Float64:
        return (self.m_Vision1.shgcCOG() * self.m_Vision1.area() + self.m_Vision2.shgcCOG() * self.m_Vision2.area()) / self.area()

    def getIGUDimensions(self) -> IGUDimensions:
        return IGUDimensions(self.m_Vision1.getIGUWidth(), self.m_Vision1.getIGUHeight())

    def visionPercentage(self) -> Float64:
        return (self.m_Vision1.visionPercentage() * self.m_Vision1.area() + self.m_Vision2.visionPercentage() * self.m_Vision2.area()) / self.area()

    def uValueCOG1(self) -> Float64:
        return self.m_Vision1.uValueCOG()

    def uValueCOG2(self) -> Float64:
        return self.m_Vision2.uValueCOG()

    def shgcCOG1(self) -> Float64:
        return self.m_Vision1.shgcCOG()

    def shgcCOG2(self) -> Float64:
        return self.m_Vision2.shgcCOG()

    def averageHc(inout self):
        let hc1 = self.m_Vision1.hc()
        let hc2 = self.m_Vision2.hc()
        let hcavg = (hc1 + hc2) / 2
        self.m_Vision1.setHc(hcavg)
        self.m_Vision2.setHc(hcavg)

@value
struct DualVisionHorizontal(WindowDualVision):
    def __init__(inout self):

    def __init__(inout self, width: Float64, height: Float64, tvis1: Float64, tsol1: Float64, iguSystem1: Pointer[IIGUSystem], tvis2: Float64, tsol2: Float64, iguSystem2: Pointer[IIGUSystem]):
        super().__init__(width / 2, height, tvis1, tsol1, iguSystem1, tvis2, tsol2, iguSystem2)
        let leftVisionFrameTypes = Dict[FramePosition, FrameType]()
        leftVisionFrameTypes[FramePosition.Top] = FrameType.Exterior
        leftVisionFrameTypes[FramePosition.Bottom] = FrameType.Exterior
        leftVisionFrameTypes[FramePosition.Left] = FrameType.Exterior
        leftVisionFrameTypes[FramePosition.Right] = FrameType.Interior
        self.m_Vision1.setFrameTypes(leftVisionFrameTypes)
        let rightVisionFrameTypes = Dict[FramePosition, FrameType]()
        rightVisionFrameTypes[FramePosition.Top] = FrameType.Exterior
        rightVisionFrameTypes[FramePosition.Bottom] = FrameType.Exterior
        rightVisionFrameTypes[FramePosition.Left] = FrameType.Interior
        rightVisionFrameTypes[FramePosition.Right] = FrameType.Exterior
        self.m_Vision2.setFrameTypes(rightVisionFrameTypes)

    def uValueCOGLeft(self) -> Float64:
        return self.uValueCOG1()

    def uValueCOGRight(self) -> Float64:
        return self.uValueCOG2()

    def shgcCOGLeft(self) -> Float64:
        return self.shgcCOG1()

    def shgcCOGRight(self) -> Float64:
        return self.shgcCOG2()

    def setFrameTopLeft(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Top, frameData)

    def setFrameTopRight(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Top, frameData)

    def setFrameBottomLeft(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Bottom, frameData)

    def setFrameBottomRight(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Bottom, frameData)

    def setFrameLeft(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Left, frameData)

    def setFrameRight(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Right, frameData)

    def setFrameMeetingRail(inout self, frameData: FrameData):
        frameData.splitFrameWidth()
        self.m_Vision1.setFrameData(FramePosition.Right, frameData)
        self.m_Vision2.setFrameData(FramePosition.Left, frameData)

    def setDividers(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision1.setDividers(frameData, nHorizontal, nVertical)
        self.m_Vision2.setDividers(frameData, nHorizontal, nVertical)

    def setDividersLeftVision(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision1.setDividers(frameData, nHorizontal, nVertical)

    def setDividersRightVision(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision2.setDividers(frameData, nHorizontal, nVertical)

@value
struct DualVisionVertical(WindowDualVision):
    def __init__(inout self):

    def __init__(inout self, width: Float64, height: Float64, tvis1: Float64, tsol1: Float64, iguSystem1: Pointer[IIGUSystem], tvis2: Float64, tsol2: Float64, iguSystem2: Pointer[IIGUSystem]):
        super().__init__(width, height / 2, tvis1, tsol1, iguSystem1, tvis2, tsol2, iguSystem2)
        let topVisionFrameTypes = Dict[FramePosition, FrameType]()
        topVisionFrameTypes[FramePosition.Top] = FrameType.Exterior
        topVisionFrameTypes[FramePosition.Bottom] = FrameType.Interior
        topVisionFrameTypes[FramePosition.Left] = FrameType.Exterior
        topVisionFrameTypes[FramePosition.Right] = FrameType.Exterior
        self.m_Vision1.setFrameTypes(topVisionFrameTypes)
        let bottomVisionFrameTypes = Dict[FramePosition, FrameType]()
        bottomVisionFrameTypes[FramePosition.Top] = FrameType.Interior
        bottomVisionFrameTypes[FramePosition.Bottom] = FrameType.Exterior
        bottomVisionFrameTypes[FramePosition.Left] = FrameType.Exterior
        bottomVisionFrameTypes[FramePosition.Right] = FrameType.Exterior
        self.m_Vision2.setFrameTypes(bottomVisionFrameTypes)
        self.m_Vision1.setInteriorAndExteriorSurfaceHeight(height)
        self.m_Vision2.setInteriorAndExteriorSurfaceHeight(height)

    def uValueCOGTop(self) -> Float64:
        return self.uValueCOG1()

    def uValueCOGBottom(self) -> Float64:
        return self.uValueCOG2()

    def shgcCOGTop(self) -> Float64:
        return self.shgcCOG1()

    def shgcCOGBottom(self) -> Float64:
        return self.shgcCOG2()

    def setFrameMeetingRail(inout self, frameData: FrameData):
        frameData.splitFrameWidth()
        self.m_Vision1.setFrameData(FramePosition.Bottom, frameData)
        self.m_Vision2.setFrameData(FramePosition.Top, frameData)

    def setDividers(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision1.setDividers(frameData, nHorizontal, nVertical)
        self.m_Vision2.setDividers(frameData, nHorizontal, nVertical)

    def setDividersTopVision(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision1.setDividers(frameData, nHorizontal, nVertical)

    def setDividersBottomVision(inout self, frameData: FrameData, nHorizontal: Int, nVertical: Int):
        self.m_Vision2.setDividers(frameData, nHorizontal, nVertical)

    def setFrameBottomRight(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Right, frameData)

    def setFrameBottomLeft(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Left, frameData)

    def setFrameTopRight(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Right, frameData)

    def setFrameTopLeft(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Left, frameData)

    def setFrameBottom(inout self, frameData: FrameData):
        self.m_Vision2.setFrameData(FramePosition.Bottom, frameData)

    def setFrameTop(inout self, frameData: FrameData):
        self.m_Vision1.setFrameData(FramePosition.Top, frameData)