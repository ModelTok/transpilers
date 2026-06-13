// Mojo translation of IceThermalStorage.cc
// 1:1 translation, no refactoring

from DataPlant import (DataPlant, PlantLocation, PlantComponent, DataPlant_OpScheme, DataPlant_LoopDemandCalcScheme, DataPlant_CommonPipeType, DataPlant_LoopFlowStatus, DataPlant_LoopSideLocation, DataPlant_PlantEquipmentType)
from DataGlobals import DataGlobals
from DataHVACGlobals import DataHVACGlobals
from DataLoopNode import Node
from DataSizing import DataSizing
from CurveManager import Curve
from FluidProperties import FluidProperties
from General import Util
from .InputProcessing import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import (SetupOutputVariable, OutputProcessor)
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ScheduleManager import Sched
from UtilityRoutines import (ShowFatalError, ShowWarningError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowSevereError, ShowSevereItemNotFound, ErrorObjectHeader)
from Constant import Constant
from DataBranchAirLoopPlant import DataBranchAirLoopPlant
from DataIPShortCuts import DataIPShortCuts
from .Data.EnergyPlusData import EnergyPlusData
from IceThermalStorageData import IceThermalStorageData
from .Autosizing import BaseSizer
from BaseSizer import BaseSizer
from math import (abs, min, max, log, sqrt)
from memory import (unsafe_new, address_of)

alias cIceStorageSizing = "ThermalStorage:Sizing"
alias cIceStorageSimple = "ThermalStorage:Ice:Simple"
alias cIceStorageDetailed = "ThermalStorage:Ice:Detailed"

let FreezTemp: Float64 = 0.0
let FreezTempIP: Float64 = 32.0
let TimeInterval: Float64 = 3600.0
let EpsLimitForX: Float64 = 0.0
let EpsLimitForDisCharge: Float64 = 0.0
let EpsLimitForCharge: Float64 = 0.0
let DeltaTofMin: Float64 = 0.5
let DeltaTifMin: Float64 = 1.0

def pow_2(x: Float64) -> Float64:
    return x * x

def pow_3(x: Float64) -> Float64:
    return x * x * x

def pow_4(x: Float64) -> Float64:
    return x * x * x * x

def pow_5(x: Float64) -> Float64:
    return x * x * x * x * x

struct CurveVars:
    alias Invalid = -1
    alias FracChargedLMTD = 0
    alias FracDischargedLMTD = 1
    alias LMTDMassFlow = 2
    alias LMTDFracCharged = 3
    alias Num = 4

struct DetIce:
    alias Invalid = -1
    alias InsideMelt = 0
    alias OutsideMelt = 1
    alias Num = 2

struct ITSType:
    alias Invalid = -1
    alias IceOnCoilInternal = 0
    alias IceOnCoilExternal = 1
    alias Num = 2

struct ThermalStorageSizingData:
    var name: String
    var onPeakStart: Float64 = 0.0
    var onPeakEnd: Float64 = 0.0
    var sizingFactor: Float64 = 1.0

trait PlantComponent:
    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool)
    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation)
    def oneTimeInit(inout self, state: EnergyPlusData)
    def initialize(inout self, state: EnergyPlusData)
    def size(inout self, state: EnergyPlusData)
    def setupOutputVars(inout self, state: EnergyPlusData)

struct SimpleIceStorageData:
    var Name: String
    var ITSType: String
    var ITSType_Num: Int  # ITSType enum
    var MapNum: Int
    var UratePtr: Int
    var ITSNomCap: Float64
    var NomCapacityWasAutoSized: Bool = False
    var PltInletNodeNum: Int
    var PltOutletNodeNum: Int
    var plantLoc: PlantLocation
    var DesignMassFlowRate: Float64
    var FreezeTemp: Float64
    var ResetXForITSFlag: Bool
    var MyEnvrnFlag: Bool
    var UAIceCh: Float64
    var UAIceDisCh: Float64
    var HLoss: Float64
    var XCurIceFrac: Float64
    var ITSMassFlowRate: Float64
    var ITSInletTemp: Float64
    var ITSOutletTemp: Float64
    var ITSOutletSetPointTemp: Float64
    var ITSCoolingRate: Float64
    var ITSCoolingEnergy: Float64
    var CheckEquipName: Bool
    var MyLoad: Float64
    var Urate: Float64
    var IceFracRemain: Float64
    var ITSChargingRate: Float64
    var ITSChargingEnergy: Float64
    var ITSmdot: Float64
    var ITSCoolingRate_rep: Float64
    var ITSCoolingEnergy_rep: Float64
    var MyPlantScanFlag: Bool
    var MyEnvrnFlag2: Bool
    var TESSizingIndex: Int = 0

    def __init__(inout self):
        self.MapNum = 0
        self.UratePtr = 0
        self.ITSNomCap = 0.0
        self.PltInletNodeNum = 0
        self.PltOutletNodeNum = 0
        self.plantLoc = PlantLocation()
        self.DesignMassFlowRate = 0.0
        self.FreezeTemp = 0.0
        self.ResetXForITSFlag = False
        self.MyEnvrnFlag = True
        self.UAIceCh = 0.0
        self.UAIceDisCh = 0.0
        self.HLoss = 0.0
        self.XCurIceFrac = 0.0
        self.ITSMassFlowRate = 0.0
        self.ITSInletTemp = 0.0
        self.ITSOutletTemp = 0.0
        self.ITSOutletSetPointTemp = 0.0
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.CheckEquipName = True
        self.MyLoad = 0.0
        self.Urate = 0.0
        self.IceFracRemain = 0.0
        self.ITSChargingRate = 0.0
        self.ITSChargingEnergy = 0.0
        self.ITSmdot = 0.0
        self.ITSCoolingRate_rep = 0.0
        self.ITSCoolingEnergy_rep = 0.0
        self.MyPlantScanFlag = True
        self.MyEnvrnFlag2 = True

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> PlantComponent:
        if state.dataIceThermalStorage.getITSInput:
            GetIceStorageInput(state)
            state.dataIceThermalStorage.getITSInput = False
        for idx in range(len(state.dataIceThermalStorage.SimpleIceStorage)):
            var ITS = state.dataIceThermalStorage.SimpleIceStorage[idx]
            if ITS.Name == objectName:
                return address_of(ITS)
        ShowFatalError(state, f"LocalSimpleIceStorageFactory: Error getting inputs for simple ice storage named: {objectName}")
        return None

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        let RoutineName: String = "SimpleIceStorageData::simulate"
        if calledFromLocation.comp.CurOpSchemeType == DataPlant_OpScheme.CompSetPtBased:
            var localCurLoad = calledFromLocation.comp.EquipDemand
            if localCurLoad != 0.0:
                RunFlag = True
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.ResetXForITSFlag = True
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.initialize(state)
        var TempSetPt: Float64 = 0.0
        var TempIn = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            TempSetPt = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            TempSetPt = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPointHi
        else:
            assert(False)
        var DemandMdot = self.DesignMassFlowRate
        var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, TempIn, RoutineName)
        var MyLoad2 = DemandMdot * Cp * (TempIn - TempSetPt)
        self.MyLoad = MyLoad2
        self.XCurIceFrac = self.IceFracRemain
        if (MyLoad2 == 0.0) or (DemandMdot == 0.0):
            self.CalcIceStorageDormant(state)
        elif MyLoad2 < 0.0:
            var MaxCap: Float64
            var MinCap: Float64
            var OptCap: Float64
            self.CalcIceStorageCapacity(state, MaxCap, MinCap, OptCap)
            self.CalcIceStorageCharge(state)
        elif MyLoad2 > 0.0:
            var MaxCap: Float64
            var MinCap: Float64
            var OptCap: Float64
            self.CalcIceStorageCapacity(state, MaxCap, MinCap, OptCap)
            self.CalcIceStorageDischarge(state, self.MyLoad, RunFlag, MaxCap)
        self.UpdateNode(state, MyLoad2, RunFlag)
        self.RecordOutput(MyLoad2, RunFlag)

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.oneTimeInit(state)
        self.size(state)

    def oneTimeInit(inout self, state: EnergyPlusData):
        if self.MyPlantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant_PlantEquipmentType.TS_IceSimple, self.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "SimpleIceStorageData:oneTimeInit: Program terminated due to previous condition(s).")
            self.setupOutputVars(state)
            self.MyPlantScanFlag = False

    def initialize(inout self, state: EnergyPlusData):
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag2:
            self.DesignMassFlowRate = self.plantLoc.loop.MaxMassFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum)
            if (self.plantLoc.loop.CommonPipeType == DataPlant_CommonPipeType.TwoWay) and (self.plantLoc.loopSideNum == DataPlant_LoopSideLocation.Supply):
                for compNum in range(1, self.plantLoc.branch.TotalComponents+1):
                    self.plantLoc.branch.Comp[compNum].FlowPriority = DataPlant_LoopFlowStatus.NeedyAndTurnsLoopOn
            self.MyLoad = 0.0
            self.Urate = 0.0
            self.IceFracRemain = 1.0
            self.ITSCoolingRate = 0.0
            self.ITSCoolingEnergy_rep = 0.0
            self.ITSChargingRate = 0.0
            self.ITSChargingEnergy = 0.0
            self.ITSmdot = 0.0
            self.ITSInletTemp = 0.0
            self.ITSOutletTemp = 0.0
            self.MyEnvrnFlag2 = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag2 = True

    def size(inout self, state: EnergyPlusData):
        let TESTankIndex = Util.FindItemInList(self.Name, state.dataIceThermalStorage.SimpleIceStorage, &SimpleIceStorageData.Name)
        let TESSizingIndex = state.dataIceThermalStorage.SimpleIceStorage[TESTankIndex].TESSizingIndex
        if TESSizingIndex == 0:
            return
        let tankType: String = "ThermalStorage:Ice:Simple"
        let callingRoutine: String = "SimpleIceStorageData::size"
        var plntLoop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]
        var PltSizNum = plntLoop.PlantSizNum
        var plntSizData = state.dataSize.PlantSizData[PltSizNum]
        var startPeak = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].onPeakStart * state.dataGlobal.TimeStepsInHour
        var endPeak = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].onPeakEnd * state.dataGlobal.TimeStepsInHour
        var onPeakTimeSteps = endPeak - startPeak
        var onPeakHours = onPeakTimeSteps / state.dataGlobal.TimeStepsInHour
        var sizingFactor = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].sizingFactor
        var onPeakSumWaterFlow = 0.0
        if not plntLoop.plantDesWaterFlowRate.empty():
            for ts in range(0, 24 * state.dataGlobal.TimeStepsInHour):
                if (ts > startPeak) and (ts <= endPeak):
                    onPeakSumWaterFlow += plntLoop.plantDesWaterFlowRate[ts]
            onPeakSumWaterFlow /= onPeakTimeSteps
        var Cp = plntLoop.glycol.getSpecificHeat(state, plntSizData.ExitTemp, callingRoutine)
        var rho = plntLoop.glycol.getDensity(state, plntSizData.ExitTemp, callingRoutine)
        var onPeakEnergy = onPeakSumWaterFlow * rho * Cp * plntSizData.DeltaT * Constant.rSecsInHour * onPeakHours
        var tankCapacity = onPeakEnergy * sizingFactor
        if self.NomCapacityWasAutoSized:
            self.ITSNomCap = max(1.0, tankCapacity)
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if not self.NomCapacityWasAutoSized:
                BaseSizer.reportSizerOutput(state, tankType, self.Name, "User-Specified Capacity [GJ]", self.ITSNomCap / 1.0E9)
            BaseSizer.reportSizerOutput(state, tankType, self.Name, "Design Size Capacity [GJ]", tankCapacity / 1.0E9)

    def CalcIceStorageCapacity(inout self, state: EnergyPlusData, inout MaxCap: Float64, inout MinCap: Float64, inout OptCap: Float64):
        MaxCap = 0.0
        MinCap = 0.0
        OptCap = 0.0
        if self.ResetXForITSFlag:
            self.XCurIceFrac = 1.0
            self.IceFracRemain = 1.0
            self.Urate = 0.0
            self.ResetXForITSFlag = False
        self.CalcUAIce(self.XCurIceFrac, self.UAIceCh, self.UAIceDisCh, self.HLoss)
        var QiceMin: Float64
        self.CalcQiceDischageMax(state, QiceMin)
        var Umin = min(max((-(1.0 - EpsLimitForDisCharge) * QiceMin * TimeInterval / self.ITSNomCap), (-self.XCurIceFrac + EpsLimitForX)), 0.0)
        var Uact = Umin
        var ITSCoolingRateMax = abs(Uact * self.ITSNomCap / TimeInterval)
        var ITSCoolingRateOpt = ITSCoolingRateMax
        var ITSCoolingRateMin = 0.0
        MaxCap = ITSCoolingRateMax
        OptCap = ITSCoolingRateOpt
        MinCap = ITSCoolingRateMin

    def CalcIceStorageDormant(inout self, state: EnergyPlusData):
        self.ITSMassFlowRate = 0.0
        PlantUtilities.SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)
        self.ITSInletTemp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        self.ITSOutletTemp = self.ITSInletTemp
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPointHi
        else:

        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.Urate = 0.0

    def CalcIceStorageCharge(inout self, state: EnergyPlusData):
        self.ITSMassFlowRate = self.DesignMassFlowRate
        PlantUtilities.SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)
        self.ITSInletTemp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        self.ITSOutletTemp = self.ITSInletTemp
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPointHi
        else:

        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.Urate = 0.0
        var QiceMaxByChiller: Float64
        self.CalcQiceChargeMaxByChiller(state, QiceMaxByChiller)
        var chillerOutletTemp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        var QiceMaxByITS: Float64
        self.CalcQiceChargeMaxByITS(chillerOutletTemp, QiceMaxByITS)
        var QiceMax = min(QiceMaxByChiller, QiceMaxByITS)
        var Umax = max(min(((1.0 - EpsLimitForCharge) * QiceMax * TimeInterval / self.ITSNomCap), (1.0 - self.XCurIceFrac - EpsLimitForX)), 0.0)
        Umax = min(Umax, (1.0 - self.IceFracRemain) / state.dataHVACGlobal.TimeStepSys)
        var Uact: Float64
        if Umax == 0.0:
            Uact = 0.0
        else:
            Uact = Umax
        var Qice = Uact * self.ITSNomCap / TimeInterval
        if Qice <= 0.0:
            self.Urate = 0.0
        if (Qice <= 0.0) or (self.XCurIceFrac >= 1.0):
            self.ITSOutletTemp = self.ITSInletTemp
            Qice = 0.0
            Uact = 0.0
        else:
            var DeltaTemp = Qice / Psychrometrics.CPCW(self.ITSInletTemp) / self.ITSMassFlowRate
            self.ITSOutletTemp = self.ITSInletTemp + DeltaTemp
            self.ITSOutletTemp = min(self.ITSOutletTemp, self.ITSOutletSetPointTemp, (FreezTemp - 1))
            self.ITSOutletTemp = max(self.ITSOutletTemp, self.ITSInletTemp)
            DeltaTemp = self.ITSOutletTemp - self.ITSInletTemp
            Qice = DeltaTemp * Psychrometrics.CPCW(self.ITSInletTemp) * self.ITSMassFlowRate
            Uact = Qice / (self.ITSNomCap / TimeInterval)
        self.Urate = Uact
        self.ITSCoolingRate = -Qice
        self.ITSCoolingEnergy = self.ITSCoolingRate * state.dataHVACGlobal.TimeStepSysSec

    def CalcQiceChargeMaxByChiller(inout self, state: EnergyPlusData, inout QiceMaxByChiller: Float64):
        var TchillerOut = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        QiceMaxByChiller = self.UAIceCh * (FreezTemp - TchillerOut)
        if QiceMaxByChiller <= 0.0:
            QiceMaxByChiller = 0.0

    def CalcQiceChargeMaxByITS(inout self, chillerOutletTemp: Float64, inout QiceMaxByITS: Float64):
        var Tfr = FreezTempIP
        var ChOutletTemp = TempSItoIP(chillerOutletTemp)
        if ChOutletTemp >= Tfr:
            QiceMaxByITS = 0.0
        else:
            var ChillerInletTemp = ChOutletTemp + 0.01
            if ChillerInletTemp >= Tfr:
                ChillerInletTemp = ChOutletTemp + (Tfr - ChOutletTemp) / 2.0
            var LogTerm = (Tfr - ChOutletTemp) / (Tfr - ChillerInletTemp)
            if LogTerm <= 0.0:
                ChillerInletTemp = ChOutletTemp
                QiceMaxByITS = 0.0
            QiceMaxByITS = self.UAIceCh * (TempIPtoSI(ChillerInletTemp) - TempIPtoSI(ChOutletTemp)) / log(LogTerm)

    def CalcIceStorageDischarge(inout self, state: EnergyPlusData, myLoad: Float64, RunFlag: Bool, MaxCap: Float64):
        let RoutineName: String = "SimpleIceStorageData::CalcIceStorageDischarge"
        self.ITSMassFlowRate = 0.0
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPointHi
        else:

        self.Urate = 0.0
        if (myLoad == 0.0) or (not RunFlag):
            self.ITSMassFlowRate = 0.0
            self.ITSInletTemp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
            self.ITSOutletTemp = self.ITSInletTemp
            self.ITSCoolingRate = 0.0
            self.ITSCoolingEnergy = 0.0
            return
        var CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[self.PltInletNodeNum].Temp, RoutineName)
        var Umyload = -myLoad * TimeInterval / self.ITSNomCap
        var Umax = -self.IceFracRemain / state.dataHVACGlobal.TimeStepSys
        var Umin = min(Umyload, 0.0)
        var Uact = max(Umin, Umax)
        self.ITSInletTemp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        self.ITSMassFlowRate = self.DesignMassFlowRate
        PlantUtilities.SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)
        var Qice = Uact * self.ITSNomCap / TimeInterval
        Qice = max(Qice, -MaxCap)
        if (Qice >= 0.0) or (self.XCurIceFrac <= 0.0) or (self.ITSMassFlowRate < DataBranchAirLoopPlant.MassFlowTolerance):
            self.ITSOutletTemp = self.ITSInletTemp
            Qice = 0.0
            Uact = 0.0
        else:
            var DeltaTemp = Qice / CpFluid / self.ITSMassFlowRate
            self.ITSOutletTemp = self.ITSInletTemp + DeltaTemp
            self.ITSOutletTemp = max(self.ITSOutletTemp, self.ITSOutletSetPointTemp, (FreezTemp + 1))
            self.ITSOutletTemp = min(self.ITSOutletTemp, self.ITSInletTemp)
            DeltaTemp = self.ITSOutletTemp - self.ITSInletTemp
            Qice = DeltaTemp * CpFluid * self.ITSMassFlowRate
            Uact = Qice / (self.ITSNomCap / TimeInterval)
        self.Urate = Uact
        self.ITSCoolingRate = -Qice
        self.ITSCoolingEnergy = self.ITSCoolingRate * state.dataHVACGlobal.TimeStepSysSec

    def CalcQiceDischageMax(inout self, state: EnergyPlusData, inout QiceMin: Float64):
        var ITSInletTemp_loc = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        var ITSOutletTemp_loc: Float64 = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            ITSOutletTemp_loc = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            ITSOutletTemp_loc = state.dataLoopNodes.Node[self.PltOutletNodeNum].TempSetPointHi
        else:
            assert(False)
        var LogTerm = (ITSInletTemp_loc - FreezTemp) / (ITSOutletTemp_loc - FreezTemp)
        if LogTerm <= 1.0:
            QiceMin = 0.0
        else:
            QiceMin = self.UAIceDisCh * (ITSInletTemp_loc - ITSOutletTemp_loc) / log(LogTerm)

    def CalcUAIce(inout self, XCurIceFrac_loc: Float64, inout UAIceCh_loc: Float64, inout UAIceDisCh_loc: Float64, inout HLoss_loc: Float64):
        if self.ITSType_Num == ITSType.IceOnCoilInternal:
            var y = XCurIceFrac_loc
            UAIceCh_loc = (1.3879 - 7.6333 * y + 26.3423 * pow_2(y) - 47.6084 * pow_3(y) + 41.8498 * pow_4(y) - 14.2948 * pow_5(y)) * self.ITSNomCap / TimeInterval / 10.0
            y = 1.0 - XCurIceFrac_loc
            UAIceDisCh_loc = (1.3879 - 7.6333 * y + 26.3423 * pow_2(y) - 47.6084 * pow_3(y) + 41.8498 * pow_4(y) - 14.2948 * pow_5(y)) * self.ITSNomCap / TimeInterval / 10.0
            HLoss_loc = 0.0
        elif self.ITSType_Num == ITSType.IceOnCoilExternal:
            var y = XCurIceFrac_loc
            UAIceCh_loc = (1.3879 - 7.6333 * y + 26.3423 * pow_2(y) - 47.6084 * pow_3(y) + 41.8498 * pow_4(y) - 14.2948 * pow_5(y)) * self.ITSNomCap / TimeInterval / 10.0
            y = 1.0 - XCurIceFrac_loc
            UAIceDisCh_loc = (1.1756 - 5.3689 * y + 17.3602 * pow_2(y) - 30.1077 * pow_3(y) + 25.6387 * pow_4(y) - 8.5102 * pow_5(y)) * self.ITSNomCap / TimeInterval / 10.0
            HLoss_loc = 0.0
        else:

    def UpdateNode(inout self, state: EnergyPlusData, myLoad: Float64, RunFlag: Bool):
        PlantUtilities.SafeCopyPlantNode(state, self.PltInletNodeNum, self.PltOutletNodeNum)
        if (myLoad == 0.0) or (not RunFlag):
            state.dataLoopNodes.Node[self.PltOutletNodeNum].Temp = state.dataLoopNodes.Node[self.PltInletNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.PltOutletNodeNum].Temp = self.ITSOutletTemp

    def RecordOutput(inout self, myLoad: Float64, RunFlag: Bool):
        if (myLoad == 0.0) or (not RunFlag):
            self.MyLoad = myLoad
            self.ITSCoolingRate_rep = 0.0
            self.ITSCoolingEnergy_rep = 0.0
            self.ITSChargingRate = 0.0
            self.ITSChargingEnergy = 0.0
            self.ITSmdot = 0.0
        else:
            self.MyLoad = myLoad
            if self.ITSCoolingRate > 0.0:
                self.ITSCoolingRate_rep = self.ITSCoolingRate
                self.ITSCoolingEnergy_rep = self.ITSCoolingEnergy
                self.ITSChargingRate = 0.0
                self.ITSChargingEnergy = 0.0
            else:
                self.ITSCoolingRate_rep = 0.0
                self.ITSCoolingEnergy_rep = 0.0
                self.ITSChargingRate = -self.ITSCoolingRate
                self.ITSChargingEnergy = -self.ITSCoolingEnergy
            self.ITSmdot = self.ITSMassFlowRate

    def setupOutputVars(inout self, state: EnergyPlusData):
        SetupOutputVariable(state, "Ice Thermal Storage Requested Load", Constant.Units.W, self.MyLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage End Fraction", Constant.Units.None, self.IceFracRemain, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Mass Flow Rate", Constant.Units.kg_s, self.ITSmdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Inlet Temperature", Constant.Units.C, self.ITSInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Outlet Temperature", Constant.Units.C, self.ITSOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Rate", Constant.Units.W, self.ITSCoolingRate_rep, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Energy", Constant.Units.J, self.ITSCoolingEnergy_rep, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Rate", Constant.Units.W, self.ITSChargingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Energy", Constant.Units.J, self.ITSChargingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)

struct DetailedIceStorageData:
    var Name: String
    var availSched: Sched.Schedule
    var NomCapacity: Float64
    var NomCapacityWasAutoSized: Bool = False
    var PlantInNodeNum: Int
    var PlantOutNodeNum: Int
    var plantLoc: PlantLocation
    var DesignMassFlowRate: Float64
    var MapNum: Int
    var DischargeCurveName: String
    var DischargeCurveNum: Int
    var DischargeCurveTypeNum: Int  # CurveVars enum
    var ChargeCurveName: String
    var ChargeCurveNum: Int
    var ChargeCurveTypeNum: Int    # CurveVars enum
    var CurveFitTimeStep: Float64
    var DischargeParaElecLoad: Float64
    var ChargeParaElecLoad: Float64
    var TankLossCoeff: Float64
    var FreezingTemp: Float64
    var CompLoad: Float64
    var IceFracChange: Float64
    var IceFracRemaining: Float64
    var ThawProcessIndicator: String
    var ThawProcessIndex: Int       # DetIce enum
    var IceFracOnCoil: Float64
    var DischargingRate: Float64
    var DischargingEnergy: Float64
    var ChargingRate: Float64
    var ChargingEnergy: Float64
    var MassFlowRate: Float64
    var BypassMassFlowRate: Float64
    var TankMassFlowRate: Float64
    var InletTemp: Float64
    var OutletTemp: Float64
    var TankOutletTemp: Float64
    var ParasiticElecRate: Float64
    var ParasiticElecEnergy: Float64
    var DischargeIterErrors: Int
    var DischargeErrorCount: Int
    var ChargeIterErrors: Int
    var ChargeErrorCount: Int
    var ResetXForITSFlag: Bool
    var MyEnvrnFlag: Bool
    var CheckEquipName: Bool
    var MyPlantScanFlag: Bool
    var MyEnvrnFlag2: Bool
    var TESSizingIndex: Int = 0

    def __init__(inout self):
        self.NomCapacity = 0.0
        self.PlantInNodeNum = 0
        self.PlantOutNodeNum = 0
        self.plantLoc = PlantLocation()
        self.DesignMassFlowRate = 0.0
        self.MapNum = 0
        self.DischargeCurveNum = 0
        self.ChargeCurveNum = 0
        self.CurveFitTimeStep = 1.0
        self.DischargeParaElecLoad = 0.0
        self.ChargeParaElecLoad = 0.0
        self.TankLossCoeff = 0.0
        self.FreezingTemp = 0.0
        self.CompLoad = 0.0
        self.IceFracChange = 0.0
        self.IceFracRemaining = 1.0
        self.IceFracOnCoil = 1.0
        self.DischargingRate = 0.0
        self.DischargingEnergy = 0.0
        self.ChargingRate = 0.0
        self.ChargingEnergy = 0.0
        self.MassFlowRate = 0.0
        self.BypassMassFlowRate = 0.0
        self.TankMassFlowRate = 0.0
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.TankOutletTemp = 0.0
        self.ParasiticElecRate = 0.0
        self.ParasiticElecEnergy = 0.0
        self.DischargeIterErrors = 0
        self.DischargeErrorCount = 0
        self.ChargeIterErrors = 0
        self.ChargeErrorCount = 0
        self.ResetXForITSFlag = False
        self.MyEnvrnFlag = True
        self.CheckEquipName = True
        self.MyPlantScanFlag = True
        self.MyEnvrnFlag2 = True

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> PlantComponent:
        if state.dataIceThermalStorage.getITSInput:
            GetIceStorageInput(state)
            state.dataIceThermalStorage.getITSInput = False
        for idx in range(len(state.dataIceThermalStorage.DetailedIceStorage)):
            var ITS = state.dataIceThermalStorage.DetailedIceStorage[idx]
            if ITS.Name == objectName:
                return address_of(ITS)
        ShowFatalError(state, f"LocalDetailedIceStorageFactory: Error getting inputs for detailed ice storage named: {objectName}")
        return None

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.ResetXForITSFlag = True
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.initialize(state)
        self.SimDetailedIceStorage(state)
        self.UpdateDetailedIceStorage(state)
        self.ReportDetailedIceStorage(state)

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.oneTimeInit(state)
        self.size(state)

    def oneTimeInit(inout self, state: EnergyPlusData):
        if self.MyPlantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant_PlantEquipmentType.TS_IceDetailed, self.plantLoc, errFlag)
            if errFlag:
                ShowFatalError(state, "DetailedIceStorageData: oneTimeInit: Program terminated due to previous condition(s).")
            self.setupOutputVars(state)
            self.MyPlantScanFlag = False

    def initialize(inout self, state: EnergyPlusData):
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag2:
            self.IceFracChange = 0.0
            self.IceFracRemaining = 1.0
            self.IceFracOnCoil = 1.0
            self.InletTemp = 0.0
            self.OutletTemp = 0.0
            self.TankOutletTemp = 0.0
            self.DischargeIterErrors = 0
            self.ChargeIterErrors = 0
            self.DesignMassFlowRate = self.plantLoc.loop.MaxMassFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.PlantInNodeNum, self.PlantOutNodeNum)
            if (self.plantLoc.loop.CommonPipeType == DataPlant_CommonPipeType.TwoWay) and (self.plantLoc.loopSideNum == DataPlant_LoopSideLocation.Supply):
                for CompNum in range(1, self.plantLoc.branch.TotalComponents+1):
                    self.plantLoc.branch.Comp[CompNum].FlowPriority = DataPlant_LoopFlowStatus.NeedyAndTurnsLoopOn
            self.MyEnvrnFlag2 = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag2 = True
        self.CompLoad = 0.0
        self.IceFracChange = 0.0
        self.DischargingRate = 0.0
        self.DischargingEnergy = 0.0
        self.ChargingRate = 0.0
        self.ChargingEnergy = 0.0
        self.MassFlowRate = 0.0
        self.BypassMassFlowRate = 0.0
        self.TankMassFlowRate = 0.0
        self.ParasiticElecRate = 0.0
        self.ParasiticElecEnergy = 0.0

    def size(inout self, state: EnergyPlusData):
        let TESTankIndex = Util.FindItemInList(self.Name, state.dataIceThermalStorage.DetailedIceStorage, &DetailedIceStorageData.Name)
        let TESSizingIndex = state.dataIceThermalStorage.DetailedIceStorage[TESTankIndex].TESSizingIndex
        if TESSizingIndex == 0:
            return
        let tankType: String = "ThermalStorage:Ice:Detailed"
        let callingRoutine: String = "DetailedIceStorageData::size"
        var plntLoop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]
        var PltSizNum = plntLoop.PlantSizNum
        var plntSizData = state.dataSize.PlantSizData[PltSizNum]
        var startPeak = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].onPeakStart * state.dataGlobal.TimeStepsInHour
        var endPeak = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].onPeakEnd * state.dataGlobal.TimeStepsInHour
        var onPeakTimeSteps = endPeak - startPeak
        var onPeakHours = onPeakTimeSteps / state.dataGlobal.TimeStepsInHour
        var sizingFactor = state.dataIceThermalStorage.ThermalStorageSizing[TESSizingIndex].sizingFactor
        var onPeakSumWaterFlow = 0.0
        if not plntLoop.plantDesWaterFlowRate.empty():
            for ts in range(0, 24 * state.dataGlobal.TimeStepsInHour):
                if (ts > startPeak) and (ts <= endPeak):
                    onPeakSumWaterFlow += plntLoop.plantDesWaterFlowRate[ts]
            onPeakSumWaterFlow /= onPeakTimeSteps
        var Cp = plntLoop.glycol.getSpecificHeat(state, plntSizData.ExitTemp, callingRoutine)
        var rho = plntLoop.glycol.getDensity(state, plntSizData.ExitTemp, callingRoutine)
        var onPeakEnergy = onPeakSumWaterFlow * rho * Cp * plntSizData.DeltaT * Constant.rSecsInHour * onPeakHours
        var tankCapacity = onPeakEnergy * sizingFactor / Constant.rSecsInHour
        if self.NomCapacityWasAutoSized:
            self.NomCapacity = max(1.0, tankCapacity)
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if not self.NomCapacityWasAutoSized:
                BaseSizer.reportSizerOutput(state, tankType, self.Name, "User-Specified Capacity [GJ]", self.NomCapacity * Constant.rSecsInHour / 1.0E9)
            BaseSizer.reportSizerOutput(state, tankType, self.Name, "Design Size Capacity [GJ]", tankCapacity * Constant.rSecsInHour / 1.0E9)

    def SimDetailedIceStorage(inout self, state: EnergyPlusData):
        let MaxIterNum: Int = 100
        let SmallestLoad: Float64 = 0.1
        let TankDischargeToler: Float64 = 0.001
        let TankChargeToler: Float64 = 0.999
        let TemperatureToler: Float64 = 0.1
        let SIEquiv100GPMinMassFlowRate: Float64 = 6.31
        let RoutineName: String = "DetailedIceStorageData::SimDetailedIceStorage"
        var NodeNumIn = self.PlantInNodeNum
        var NodeNumOut = self.PlantOutNodeNum
        var TempIn = state.dataLoopNodes.Node[NodeNumIn].Temp
        var TempSetPt: Float64 = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.SingleSetPoint:
            TempSetPt = state.dataLoopNodes.Node[NodeNumOut].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant_LoopDemandCalcScheme.DualSetPointDeadBand:
            TempSetPt = state.dataLoopNodes.Node[NodeNumOut].TempSetPointHi
        else:
            assert(False)
        var IterNum = 0
        self.InletTemp = TempIn
        self.MassFlowRate = state.dataLoopNodes.Node[NodeNumIn].MassFlowRate
        if (self.plantLoc.loop.CommonPipeType == DataPlant_CommonPipeType.TwoWay) and (abs(self.MassFlowRate) < DataBranchAirLoopPlant.MassFlowTolerance) and (self.IceFracRemaining < TankChargeToler):
            self.MassFlowRate = self.DesignMassFlowRate
        var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, TempIn, RoutineName)
        var LocalLoad = self.MassFlowRate * Cp * (TempIn - TempSetPt)
        if (abs(LocalLoad) <= SmallestLoad) or (self.availSched.getCurrentVal() <= 0):
            self.CompLoad = 0.0
            self.OutletTemp = TempIn
            self.TankOutletTemp = TempIn
            var mdot = 0.0
            PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
            self.BypassMassFlowRate = mdot
            self.TankMassFlowRate = 0.0
            self.MassFlowRate = mdot
        elif LocalLoad < 0.0:
            if (TempIn > (self.FreezingTemp - DeltaTifMin)) or (self.IceFracRemaining >= TankChargeToler):
                self.CompLoad = 0.0
                self.OutletTemp = TempIn
                self.TankOutletTemp = TempIn
                var mdot = 0.0
                PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                self.BypassMassFlowRate = mdot
                self.TankMassFlowRate = 0.0
                self.MassFlowRate = mdot
            else:
                var mdot = self.DesignMassFlowRate
                PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                if TempSetPt > (self.FreezingTemp - DeltaTofMin):
                    TempSetPt = self.FreezingTemp - DeltaTofMin
                var ToutOld = TempSetPt
                var LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                var MassFlowstar = self.MassFlowRate / SIEquiv100GPMinMassFlowRate
                var ChargeFrac = LocalLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                if (self.IceFracRemaining + ChargeFrac) > 1.0:
                    ChargeFrac = 1.0 - self.IceFracRemaining
                var AvgFracCharged: Float64
                if self.ThawProcessIndex == DetIce.InsideMelt:
                    AvgFracCharged = self.IceFracOnCoil + (ChargeFrac / 2.0)
                else:
                    AvgFracCharged = self.IceFracRemaining + (ChargeFrac / 2.0)
                var Qstar = abs(CalcQstar(state, self.ChargeCurveNum, self.ChargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                var ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep
                var ToutNew = TempIn + (ActualLoad / (self.MassFlowRate * Cp))
                if ToutNew > (self.FreezingTemp - DeltaTofMin):
                    ToutNew = self.FreezingTemp - DeltaTofMin
                if ActualLoad > abs(LocalLoad):
                    self.OutletTemp = TempSetPt
                    self.TankOutletTemp = ToutNew
                    self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - TempSetPt)
                    self.TankMassFlowRate = self.CompLoad / Cp / abs(TempIn - ToutNew)
                    self.BypassMassFlowRate = self.MassFlowRate - self.TankMassFlowRate
                else:
                    while IterNum < MaxIterNum:
                        if abs(ToutOld - ToutNew) > TemperatureToler:
                            ToutOld = ToutNew
                            LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                            MassFlowstar = self.MassFlowRate / SIEquiv100GPMinMassFlowRate
                            Qstar = abs(CalcQstar(state, self.ChargeCurveNum, self.ChargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                            ChargeFrac = Qstar * (state.dataHVACGlobal.TimeStepSys / self.CurveFitTimeStep)
                            if (self.IceFracRemaining + ChargeFrac) > 1.0:
                                ChargeFrac = 1.0 - self.IceFracRemaining
                                Qstar = ChargeFrac
                            if self.ThawProcessIndex == DetIce.InsideMelt:
                                AvgFracCharged = self.IceFracOnCoil + (ChargeFrac / 2.0)
                            else:
                                AvgFracCharged = self.IceFracRemaining + (ChargeFrac / 2.0)
                            ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep
                            ToutNew = TempIn + (ActualLoad / (self.MassFlowRate * Cp))
                            if ToutNew < (self.FreezingTemp - DeltaTofMin):
                                ToutNew = self.FreezingTemp - DeltaTofMin
                            IterNum += 1
                        else:
                            break
                    if IterNum >= MaxIterNum:
                        self.ChargeIterErrors += 1
                        if self.ChargeIterErrors <= 25:
                            ShowWarningError(state, "Detailed Ice Storage model exceeded its internal charging maximum iteration limit")
                            ShowContinueError(state, f"Detailed Ice Storage System Name = {self.Name}")
                            ShowContinueErrorTimeStamp(state, "")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, "Detailed Ice Storage system [" + self.Name + "]  charging maximum iteration limit exceeded occurrence continues.", self.ChargeErrorCount)
                    self.OutletTemp = ToutNew
                    self.TankOutletTemp = ToutNew
                    self.BypassMassFlowRate = 0.0
                    self.TankMassFlowRate = self.MassFlowRate
                    self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - ToutNew)
        elif LocalLoad > 0.0:
            if (self.InletTemp < (self.FreezingTemp + DeltaTifMin)) or (self.IceFracRemaining <= TankDischargeToler):
                self.CompLoad = 0.0
                self.OutletTemp = self.InletTemp
                self.TankOutletTemp = self.InletTemp
                var mdot = 0.0
                PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                self.BypassMassFlowRate = mdot
                self.TankMassFlowRate = 0.0
                self.MassFlowRate = mdot
            else:
                var mdot = self.DesignMassFlowRate
                PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                if TempSetPt < (self.FreezingTemp + DeltaTofMin):
                    TempSetPt = self.FreezingTemp + DeltaTofMin
                var ToutOld = TempSetPt
                var LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                var MassFlowstar = self.MassFlowRate / SIEquiv100GPMinMassFlowRate
                var ChargeFrac = LocalLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                if (self.IceFracRemaining - ChargeFrac) < 0.0:
                    ChargeFrac = self.IceFracRemaining
                var AvgFracCharged = self.IceFracRemaining - (ChargeFrac / 2.0)
                var Qstar = abs(CalcQstar(state, self.DischargeCurveNum, self.DischargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                var ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep
                var ToutNew = TempIn - (ActualLoad / (self.MassFlowRate * Cp))
                if ToutNew < (self.FreezingTemp + DeltaTofMin):
                    ToutNew = self.FreezingTemp + DeltaTofMin
                if ActualLoad > LocalLoad:
                    self.OutletTemp = TempSetPt
                    self.TankOutletTemp = ToutNew
                    self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - TempSetPt)
                    self.TankMassFlowRate = self.CompLoad / Cp / abs(TempIn - ToutNew)
                    self.BypassMassFlowRate = self.MassFlowRate - self.TankMassFlowRate
                else:
                    while IterNum < MaxIterNum:
                        if abs(ToutOld - ToutNew) > TemperatureToler:
                            ToutOld = ToutNew
                            LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                            Qstar = abs(CalcQstar(state, self.DischargeCurveNum, self.DischargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                            ChargeFrac = Qstar * (state.dataHVACGlobal.TimeStepSys / self.CurveFitTimeStep)
                            if (self.IceFracRemaining - ChargeFrac) < 0.0:
                                ChargeFrac = self.IceFracRemaining
                                Qstar = ChargeFrac
                            AvgFracCharged = self.IceFracRemaining - (ChargeFrac / 2.0)
                            ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep
                            ToutNew = TempIn - (ActualLoad / (self.MassFlowRate * Cp))
                            if ToutNew < (self.FreezingTemp + DeltaTofMin):
                                ToutNew = self.FreezingTemp + DeltaTofMin
                            IterNum += 1
                        else:
                            break
                    if (IterNum >= MaxIterNum) and (not state.dataGlobal.WarmupFlag):
                        self.DischargeIterErrors += 1
                        if self.DischargeIterErrors <= 25:
                            ShowWarningError(state, "Detailed Ice Storage model exceeded its internal discharging maximum iteration limit")
                            ShowContinueError(state, f"Detailed Ice Storage System Name = {self.Name}")
                            ShowContinueErrorTimeStamp(state, "")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, "Detailed Ice Storage system [" + self.Name + "]  discharging maximum iteration limit exceeded occurrence continues.", self.DischargeErrorCount)
                    if ToutNew >= TempSetPt:
                        self.OutletTemp = ToutNew
                        self.TankOutletTemp = ToutNew
                        self.BypassMassFlowRate = 0.0
                        self.TankMassFlowRate = self.MassFlowRate
                        self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - ToutNew)
                    else:
                        self.OutletTemp = TempSetPt
                        self.TankOutletTemp = ToutNew
                        self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - TempSetPt)
                        self.TankMassFlowRate = self.CompLoad / (Cp * abs(TempIn - ToutNew))
                        self.BypassMassFlowRate = self.MassFlowRate - self.TankMassFlowRate
        else:
            ShowFatalError(state, "Detailed Ice Storage systemic code error--contact EnergyPlus support")

    def UpdateDetailedIceStorage(inout self, state: EnergyPlusData):
        var InNodeNum = self.PlantInNodeNum
        var OutNodeNum = self.PlantOutNodeNum
        PlantUtilities.SafeCopyPlantNode(state, InNodeNum, OutNodeNum)
        state.dataLoopNodes.Node[OutNodeNum].Temp = self.OutletTemp

    def ReportDetailedIceStorage(inout self, state: EnergyPlusData):
        let LowLoadLimit: Float64 = 0.1
        if self.CompLoad < LowLoadLimit:
            self.IceFracChange = 0.0
            self.D