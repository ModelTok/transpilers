from CMAInterface import ICMAWindow, Option, EnumOption, CreateBestWorstUFactorOption, CMABestWorstUFactors
from Frame import FrameData
from WholeWindow import IWindow, WindowSingleVision, DualVisionHorizontal, DualVisionVertical
from WholeWindowConfigurations import IGUDimensions
from SimpleIGU import SimpleIGU
from math import log
from memory import Arc

struct BestWorst[T: AnyType]:
    var best: T
    var worst: T
    def __init__(inout self, best: T, worst: T):
        self.best = best
        self.worst = worst
    def value(self, option: Option) -> T:
        if option == Option.Best:
            return self.best
        else:
            return self.worst

struct CMAFrame:
    var m_Frame: Dict[Option, BestWorst[FrameData]]
    def __init__(inout self, bestSpacerBestIGU: FrameData, bestSpacerWorstIGU: FrameData, worstSpacerBestIGU: FrameData, worstSpacerWorstIGU: FrameData):
        self.m_Frame = Dict[Option, BestWorst[FrameData]]()
        self.m_Frame[Option.Best] = BestWorst[FrameData](bestSpacerBestIGU, bestSpacerWorstIGU)
        self.m_Frame[Option.Worst] = BestWorst[FrameData](worstSpacerBestIGU, worstSpacerWorstIGU)
    def getFrame(self, spacerOption: Option, iguOption: Option) -> FrameData:
        return self.m_Frame[spacerOption].value(iguOption)

struct CMAWindow:
    var m_BestWorstIGUUvalues: Dict[Option, CMABestWorstUFactors]
    var m_Spacer: BestWorst[Float64]
    def __init__(inout self, spacerBestKeff: Float64 = 0.01, spacerWorstKeff: Float64 = 10.0, bestUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Best), worstUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Worst)):
        self.m_BestWorstIGUUvalues = Dict[Option, CMABestWorstUFactors]()
        self.m_BestWorstIGUUvalues[Option.Best] = bestUFactor
        self.m_BestWorstIGUUvalues[Option.Worst] = worstUFactor
        self.m_Spacer = BestWorst[Float64](spacerBestKeff, spacerWorstKeff)
    def vt(self, tVis: Float64) -> Float64:
        return self.windowAt(Option.Best, Option.Best).vt(tVis)
    def uValue(self, Ucog: Float64, keffSpacer: Float64) -> Float64:
        let ub = self.Ub(keffSpacer)
        let uw = self.Uw(keffSpacer)
        let ucw = self.m_BestWorstIGUUvalues[Option.Worst].uValue()
        let ucb = self.m_BestWorstIGUUvalues[Option.Best].uValue()
        return ub + (uw - ub) * (Ucog - ucb) / (ucw - ucb)
    def shgc(self, SHGCcog: Float64, keffSpacer: Float64) -> Float64:
        let tSol = 1.0
        return self.SHGCb(keffSpacer, tSol) + (self.SHGCw(keffSpacer, tSol) - self.SHGCb(keffSpacer, tSol)) * SHGCcog
    def getIGUDimensions(self) -> IGUDimensions:
        return self.windowAt(Option.Best, Option.Best).getIGUDimensions()
    def Ub(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).uValue() - self.windowAt(Option.Best, Option.Best).uValue()
        return self.windowAt(Option.Best, Option.Best).uValue() + dU * lnTop / lnBot
    def Uw(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).uValue() - self.windowAt(Option.Best, Option.Worst).uValue()
        return self.windowAt(Option.Best, Option.Worst).uValue() + dU * lnTop / lnBot
    def SHGCb(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).shgc(tSol) - self.windowAt(Option.Best, Option.Best).shgc(tSol)
        return self.windowAt(Option.Best, Option.Best).shgc() + dU * lnTop / lnBot
    def SHGCw(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).shgc(tSol) - self.windowAt(Option.Best, Option.Worst).shgc(tSol)
        return self.windowAt(Option.Best, Option.Worst).shgc() + dU * lnTop / lnBot
    def windowAt(self, spacer: Option, glazing: Option) -> ref IWindow:
        raise Error("windowAt not implemented")

struct CMAWindowSingleVision:
    var m_BestWorstIGUUvalues: Dict[Option, CMABestWorstUFactors]
    var m_Spacer: BestWorst[Float64]
    var m_Window: Dict[Option, Dict[Option, WindowSingleVision]]
    def __init__(inout self, width: Float64, height: Float64, spacerBestKeff: Float64 = 0.01, spacerWorstKeff: Float64 = 10.0, bestUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Best), worstUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Worst)):
        self.m_BestWorstIGUUvalues = Dict[Option, CMABestWorstUFactors]()
        self.m_BestWorstIGUUvalues[Option.Best] = bestUFactor
        self.m_BestWorstIGUUvalues[Option.Worst] = worstUFactor
        self.m_Spacer = BestWorst[Float64](spacerBestKeff, spacerWorstKeff)
        self.m_Window = self.createBestWorstWindows(width, height, 0.0, 0.0, bestUFactor, worstUFactor)
    def vt(self, tVis: Float64) -> Float64:
        return self.windowAt(Option.Best, Option.Best).vt(tVis)
    def uValue(self, Ucog: Float64, keffSpacer: Float64) -> Float64:
        let ub = self.Ub(keffSpacer)
        let uw = self.Uw(keffSpacer)
        let ucw = self.m_BestWorstIGUUvalues[Option.Worst].uValue()
        let ucb = self.m_BestWorstIGUUvalues[Option.Best].uValue()
        return ub + (uw - ub) * (Ucog - ucb) / (ucw - ucb)
    def shgc(self, SHGCcog: Float64, keffSpacer: Float64) -> Float64:
        let tSol = 1.0
        return self.SHGCb(keffSpacer, tSol) + (self.SHGCw(keffSpacer, tSol) - self.SHGCb(keffSpacer, tSol)) * SHGCcog
    def getIGUDimensions(self) -> IGUDimensions:
        return self.windowAt(Option.Best, Option.Best).getIGUDimensions()
    def Ub(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).uValue() - self.windowAt(Option.Best, Option.Best).uValue()
        return self.windowAt(Option.Best, Option.Best).uValue() + dU * lnTop / lnBot
    def Uw(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).uValue() - self.windowAt(Option.Best, Option.Worst).uValue()
        return self.windowAt(Option.Best, Option.Worst).uValue() + dU * lnTop / lnBot
    def SHGCb(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).shgc(tSol) - self.windowAt(Option.Best, Option.Best).shgc(tSol)
        return self.windowAt(Option.Best, Option.Best).shgc() + dU * lnTop / lnBot
    def SHGCw(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).shgc(tSol) - self.windowAt(Option.Best, Option.Worst).shgc(tSol)
        return self.windowAt(Option.Best, Option.Worst).shgc() + dU * lnTop / lnBot
    def windowAt(self, spacer: Option, glazing: Option) -> ref IWindow:
        return self.m_Window[spacer][glazing]
    def setFrameTop(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTop(frameData)
    def setFrameBottom(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottom(frameData)
    def setFrameLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameLeft(frameData)
    def setFrameRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameRight(frameData)
    def setDividers(inout self, cmaFrameData: CMAFrame, nHorizontal: Int, nVertical: Int):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setDividers(frameData, nHorizontal, nVertical)
    def createBestWorstWindows(width: Float64, height: Float64, tvis: Float64, tsol: Float64, bestUFactor: CMABestWorstUFactors, worstUFactor: CMABestWorstUFactors) -> Dict[Option, Dict[Option, WindowSingleVision]]:
        let bestSHGC = 0.0
        let worstSHGC = 1.0
        let bestHC = bestUFactor.hcout()
        let worstHC = worstUFactor.hcout()
        var winMap = Dict[Option, Dict[Option, WindowSingleVision]]()
        winMap[Option.Best] = Dict[Option, WindowSingleVision]()
        winMap[Option.Best][Option.Best] = WindowSingleVision(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Best][Option.Worst] = WindowSingleVision(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        winMap[Option.Worst] = Dict[Option, WindowSingleVision]()
        winMap[Option.Worst][Option.Best] = WindowSingleVision(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Worst][Option.Worst] = WindowSingleVision(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        return winMap

struct CMAWindowDualVisionHorizontal:
    var m_BestWorstIGUUvalues: Dict[Option, CMABestWorstUFactors]
    var m_Spacer: BestWorst[Float64]
    var m_Window: Dict[Option, Dict[Option, DualVisionHorizontal]]
    def __init__(inout self, width: Float64, height: Float64, spacerBestKeff: Float64 = 0.01, spacerWorstKeff: Float64 = 10.0, bestUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Best), worstUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Worst)):
        self.m_BestWorstIGUUvalues = Dict[Option, CMABestWorstUFactors]()
        self.m_BestWorstIGUUvalues[Option.Best] = bestUFactor
        self.m_BestWorstIGUUvalues[Option.Worst] = worstUFactor
        self.m_Spacer = BestWorst[Float64](spacerBestKeff, spacerWorstKeff)
        self.m_Window = self.createBestWorstWindows(width, height, 0.0, 0.0, bestUFactor, worstUFactor)
    def vt(self, tVis: Float64) -> Float64:
        return self.windowAt(Option.Best, Option.Best).vt(tVis)
    def uValue(self, Ucog: Float64, keffSpacer: Float64) -> Float64:
        let ub = self.Ub(keffSpacer)
        let uw = self.Uw(keffSpacer)
        let ucw = self.m_BestWorstIGUUvalues[Option.Worst].uValue()
        let ucb = self.m_BestWorstIGUUvalues[Option.Best].uValue()
        return ub + (uw - ub) * (Ucog - ucb) / (ucw - ucb)
    def shgc(self, SHGCcog: Float64, keffSpacer: Float64) -> Float64:
        let tSol = 1.0
        return self.SHGCb(keffSpacer, tSol) + (self.SHGCw(keffSpacer, tSol) - self.SHGCb(keffSpacer, tSol)) * SHGCcog
    def getIGUDimensions(self) -> IGUDimensions:
        return self.windowAt(Option.Best, Option.Best).getIGUDimensions()
    def Ub(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).uValue() - self.windowAt(Option.Best, Option.Best).uValue()
        return self.windowAt(Option.Best, Option.Best).uValue() + dU * lnTop / lnBot
    def Uw(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).uValue() - self.windowAt(Option.Best, Option.Worst).uValue()
        return self.windowAt(Option.Best, Option.Worst).uValue() + dU * lnTop / lnBot
    def SHGCb(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).shgc(tSol) - self.windowAt(Option.Best, Option.Best).shgc(tSol)
        return self.windowAt(Option.Best, Option.Best).shgc() + dU * lnTop / lnBot
    def SHGCw(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).shgc(tSol) - self.windowAt(Option.Best, Option.Worst).shgc(tSol)
        return self.windowAt(Option.Best, Option.Worst).shgc() + dU * lnTop / lnBot
    def windowAt(self, spacer: Option, glazing: Option) -> ref IWindow:
        return self.m_Window[spacer][glazing]
    def setFrameTopLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTopLeft(frameData)
    def setFrameTopRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTopRight(frameData)
    def setFrameBottomLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottomLeft(frameData)
    def setFrameBottomRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottomRight(frameData)
    def setFrameLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameLeft(frameData)
    def setFrameRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameRight(frameData)
    def setFrameMeetingRail(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameMeetingRail(frameData)
    def setDividers(inout self, cmaFrameData: CMAFrame, nHorizontal: Int, nVertical: Int):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setDividers(frameData, nHorizontal, nVertical)
    def createBestWorstWindows(self, width: Float64, height: Float64, tvis: Float64, tsol: Float64, bestUFactor: CMABestWorstUFactors, worstUFactor: CMABestWorstUFactors) -> Dict[Option, Dict[Option, DualVisionHorizontal]]:
        let bestSHGC = 0.0
        let worstSHGC = 1.0
        let bestHC = bestUFactor.hcout()
        let worstHC = worstUFactor.hcout()
        var winMap = Dict[Option, Dict[Option, DualVisionHorizontal]]()
        winMap[Option.Best] = Dict[Option, DualVisionHorizontal]()
        winMap[Option.Best][Option.Best] = DualVisionHorizontal(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Best][Option.Worst] = DualVisionHorizontal(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        winMap[Option.Worst] = Dict[Option, DualVisionHorizontal]()
        winMap[Option.Worst][Option.Best] = DualVisionHorizontal(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Worst][Option.Worst] = DualVisionHorizontal(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        return winMap

struct CMAWindowDualVisionVertical:
    var m_BestWorstIGUUvalues: Dict[Option, CMABestWorstUFactors]
    var m_Spacer: BestWorst[Float64]
    var m_Window: Dict[Option, Dict[Option, DualVisionVertical]]
    def __init__(inout self, width: Float64, height: Float64, spacerBestKeff: Float64 = 0.01, spacerWorstKeff: Float64 = 10.0, bestUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Best), worstUFactor: CMABestWorstUFactors = CreateBestWorstUFactorOption(Option.Worst)):
        self.m_BestWorstIGUUvalues = Dict[Option, CMABestWorstUFactors]()
        self.m_BestWorstIGUUvalues[Option.Best] = bestUFactor
        self.m_BestWorstIGUUvalues[Option.Worst] = worstUFactor
        self.m_Spacer = BestWorst[Float64](spacerBestKeff, spacerWorstKeff)
        self.m_Window = self.createBestWorstWindows(width, height, 0.0, 0.0, bestUFactor, worstUFactor)
    def vt(self, tVis: Float64) -> Float64:
        return self.windowAt(Option.Best, Option.Best).vt(tVis)
    def uValue(self, Ucog: Float64, keffSpacer: Float64) -> Float64:
        let ub = self.Ub(keffSpacer)
        let uw = self.Uw(keffSpacer)
        let ucw = self.m_BestWorstIGUUvalues[Option.Worst].uValue()
        let ucb = self.m_BestWorstIGUUvalues[Option.Best].uValue()
        return ub + (uw - ub) * (Ucog - ucb) / (ucw - ucb)
    def shgc(self, SHGCcog: Float64, keffSpacer: Float64) -> Float64:
        let tSol = 1.0
        return self.SHGCb(keffSpacer, tSol) + (self.SHGCw(keffSpacer, tSol) - self.SHGCb(keffSpacer, tSol)) * SHGCcog
    def getIGUDimensions(self) -> IGUDimensions:
        return self.windowAt(Option.Best, Option.Best).getIGUDimensions()
    def Ub(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).uValue() - self.windowAt(Option.Best, Option.Best).uValue()
        return self.windowAt(Option.Best, Option.Best).uValue() + dU * lnTop / lnBot
    def Uw(self, spacerKeff: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).uValue() - self.windowAt(Option.Best, Option.Worst).uValue()
        return self.windowAt(Option.Best, Option.Worst).uValue() + dU * lnTop / lnBot
    def SHGCb(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Best).shgc(tSol) - self.windowAt(Option.Best, Option.Best).shgc(tSol)
        return self.windowAt(Option.Best, Option.Best).shgc() + dU * lnTop / lnBot
    def SHGCw(self, spacerKeff: Float64, tSol: Float64) -> Float64:
        let lnTop = log(spacerKeff) - log(self.m_Spacer.value(Option.Best))
        let lnBot = log(self.m_Spacer.value(Option.Worst)) - log(self.m_Spacer.value(Option.Best))
        let dU = self.windowAt(Option.Worst, Option.Worst).shgc(tSol) - self.windowAt(Option.Best, Option.Worst).shgc(tSol)
        return self.windowAt(Option.Best, Option.Worst).shgc() + dU * lnTop / lnBot
    def windowAt(self, spacer: Option, glazing: Option) -> ref IWindow:
        return self.m_Window[spacer][glazing]
    def setFrameTop(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTop(frameData)
    def setFrameBottom(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottom(frameData)
    def setFrameTopLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTopLeft(frameData)
    def setFrameTopRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameTopRight(frameData)
    def setFrameBottomLeft(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottomLeft(frameData)
    def setFrameBottomRight(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameBottomRight(frameData)
    def setFrameMeetingRail(inout self, cmaFrameData: CMAFrame):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setFrameMeetingRail(frameData)
    def setDividers(inout self, cmaFrameData: CMAFrame, nHorizontal: Int, nVertical: Int):
        for spacerOption in EnumOption():
            for glazingOption in EnumOption():
                let frameData = cmaFrameData.getFrame(spacerOption, glazingOption)
                self.m_Window[spacerOption][glazingOption].setDividers(frameData, nHorizontal, nVertical)
    def createBestWorstWindows(self, width: Float64, height: Float64, tvis: Float64, tsol: Float64, bestUFactor: CMABestWorstUFactors, worstUFactor: CMABestWorstUFactors) -> Dict[Option, Dict[Option, DualVisionVertical]]:
        let bestSHGC = 0.0
        let worstSHGC = 1.0
        let bestHC = bestUFactor.hcout()
        let worstHC = worstUFactor.hcout()
        var winMap = Dict[Option, Dict[Option, DualVisionVertical]]()
        winMap[Option.Best] = Dict[Option, DualVisionVertical]()
        winMap[Option.Best][Option.Best] = DualVisionVertical(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Best][Option.Worst] = DualVisionVertical(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        winMap[Option.Worst] = Dict[Option, DualVisionVertical]()
        winMap[Option.Worst][Option.Best] = DualVisionVertical(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(bestUFactor.uValue(), bestSHGC, bestHC)))
        winMap[Option.Worst][Option.Worst] = DualVisionVertical(width, height, tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)), tvis, tsol, Arc[SimpleIGU](SimpleIGU(worstUFactor.uValue(), worstSHGC, worstHC)))
        return winMap