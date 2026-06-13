from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any
import math

# ===== ENUMS =====

class CurveVars(IntEnum):
    Invalid = -1
    FracChargedLMTD = 0
    FracDischargedLMTD = 1
    LMTDMassFlow = 2
    LMTDFracCharged = 3
    Num = 4

class DetIce(IntEnum):
    Invalid = -1
    InsideMelt = 0
    OutsideMelt = 1
    Num = 2

class ITSType(IntEnum):
    Invalid = -1
    IceOnCoilInternal = 0
    IceOnCoilExternal = 1
    Num = 2

# ===== PROTOCOL STUBS FOR EXTERNAL DEPENDENCIES =====

class Schedule(Protocol):
    def getCurrentVal(self) -> float: ...

class PlantLoop(Protocol):
    LoopDemandCalcScheme: Any
    CommonPipeType: Any
    MaxMassFlowRate: float
    glycol: Any
    plantDesWaterFlowRate: List[float]

class PlantLocationProto(Protocol):
    comp: Any
    loop: PlantLoop
    loopNum: int
    loopSideNum: Any
    branch: Any

class EnergyPlusDataProto(Protocol):
    dataIceThermalStorage: Any
    dataGlobal: Any
    dataLoopNodes: Any
    dataHVACGlobal: Any
    dataInputProcessing: Any
    dataIPShortCut: Any
    dataCurveManager: Any
    dataPlnt: Any
    dataSize: Any

# ===== DATA STRUCTURES =====

@dataclass
class ThermalStorageSizingData:
    name: str = ""
    onPeakStart: float = 0.0
    onPeakEnd: float = 0.0
    sizingFactor: float = 1.0

@dataclass
class SimpleIceStorageData:
    Name: str = ""
    ITSType: str = ""
    ITSType_Num: ITSType = ITSType.Invalid
    MapNum: int = 0
    UratePtr: int = 0
    ITSNomCap: float = 0.0
    NomCapacityWasAutoSized: bool = False
    PltInletNodeNum: int = 0
    PltOutletNodeNum: int = 0
    plantLoc: Optional[PlantLocationProto] = None
    DesignMassFlowRate: float = 0.0
    FreezeTemp: float = 0.0
    ResetXForITSFlag: bool = False
    MyEnvrnFlag: bool = True
    UAIceCh: float = 0.0
    UAIceDisCh: float = 0.0
    HLoss: float = 0.0
    XCurIceFrac: float = 0.0
    ITSMassFlowRate: float = 0.0
    ITSInletTemp: float = 0.0
    ITSOutletTemp: float = 0.0
    ITSOutletSetPointTemp: float = 0.0
    ITSCoolingRate: float = 0.0
    ITSCoolingEnergy: float = 0.0
    CheckEquipName: bool = True
    MyLoad: float = 0.0
    Urate: float = 0.0
    IceFracRemain: float = 0.0
    ITSChargingRate: float = 0.0
    ITSChargingEnergy: float = 0.0
    ITSmdot: float = 0.0
    ITSCoolingRate_rep: float = 0.0
    ITSCoolingEnergy_rep: float = 0.0
    MyPlantScanFlag: bool = True
    MyEnvrnFlag2: bool = True
    TESSizingIndex: int = 0

    def factory(self, state: EnergyPlusDataProto, objectName: str) -> 'SimpleIceStorageData':
        if state.dataIceThermalStorage.getITSInput:
            GetIceStorageInput(state)
            state.dataIceThermalStorage.getITSInput = False
        for ITS in state.dataIceThermalStorage.SimpleIceStorage:
            if ITS.Name == objectName:
                return ITS
        raise RuntimeError(f"LocalSimpleIceStorageFactory: Error getting inputs for simple ice storage named: {objectName}")

    def simulate(self, state: EnergyPlusDataProto, calledFromLocation: PlantLocationProto, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        RoutineName = "SimpleIceStorageData::simulate"
        if calledFromLocation.comp.CurOpSchemeType == "CompSetPtBased":
            localCurLoad = calledFromLocation.comp.EquipDemand
            if localCurLoad != 0:
                RunFlag = True

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.ResetXForITSFlag = True
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        self.initialize(state)

        TempSetPt = 0.0
        TempIn = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            TempSetPt = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            TempSetPt = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPointHi

        DemandMdot = self.DesignMassFlowRate
        Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, TempIn, RoutineName)
        MyLoad2 = DemandMdot * Cp * (TempIn - TempSetPt)
        MyLoad = MyLoad2

        self.XCurIceFrac = self.IceFracRemain

        if MyLoad2 == 0.0 or DemandMdot == 0.0:
            self.CalcIceStorageDormant(state)
        elif MyLoad2 < 0.0:
            MaxCap, MinCap, OptCap = 0.0, 0.0, 0.0
            self.CalcIceStorageCapacity(state, MaxCap, MinCap, OptCap)
            self.CalcIceStorageCharge(state)
        elif MyLoad2 > 0.0:
            MaxCap, MinCap, OptCap = 0.0, 0.0, 0.0
            self.CalcIceStorageCapacity(state, MaxCap, MinCap, OptCap)
            self.CalcIceStorageDischarge(state, MyLoad, RunFlag, MaxCap)

        self.UpdateNode(state, MyLoad2, RunFlag)
        self.RecordOutput(MyLoad2, RunFlag)

    def onInitLoopEquip(self, state: EnergyPlusDataProto, calledFromLocation: PlantLocationProto) -> None:
        self.oneTimeInit(state)
        self.size(state)

    def oneTimeInit(self, state: EnergyPlusDataProto) -> None:
        if self.MyPlantScanFlag:
            errFlag = False
            PlantUtilities_ScanPlantLoopsForObject(state, self.Name, "TS_IceSimple", self.plantLoc, errFlag)
            if errFlag:
                raise RuntimeError("SimpleIceStorageData:oneTimeInit: Program terminated due to previous condition(s).")
            self.setupOutputVars(state)
            self.MyPlantScanFlag = False

    def initialize(self, state: EnergyPlusDataProto) -> None:
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag2:
            self.DesignMassFlowRate = self.plantLoc.loop.MaxMassFlowRate
            PlantUtilities_InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum)
            if (self.plantLoc.loop.CommonPipeType == "TwoWay" and 
                self.plantLoc.loopSideNum == "Supply"):
                for CompNum in range(1, self.plantLoc.branch.TotalComponents + 1):
                    self.plantLoc.branch.Comp(CompNum).FlowPriority = "NeedyAndTurnsLoopOn"
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

    def size(self, state: EnergyPlusDataProto) -> None:
        TESTankIndex = Util_FindItemInList(self.Name, state.dataIceThermalStorage.SimpleIceStorage, 'Name')
        if TESTankIndex < 0:
            return
        TESSizingIndex = state.dataIceThermalStorage.SimpleIceStorage[TESTankIndex].TESSizingIndex
        if TESSizingIndex == 0:
            return

        tankType = "ThermalStorage:Ice:Simple"
        callingRoutine = "SimpleIceStorageData::size"
        plntLoop = state.dataPlnt.PlantLoop(self.plantLoc.loopNum)
        PltSizNum = plntLoop.PlantSizNum
        plntSizData = state.dataSize.PlantSizData(PltSizNum)

        startPeak = state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).onPeakStart * state.dataGlobal.TimeStepsInHour
        endPeak = state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).onPeakEnd * state.dataGlobal.TimeStepsInHour
        onPeakTimeSteps = endPeak - startPeak
        onPeakHours = onPeakTimeSteps / state.dataGlobal.TimeStepsInHour
        sizingFactor = state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).sizingFactor
        onPeakSumWaterFlow = 0.0
        if plntLoop.plantDesWaterFlowRate:
            for ts in range(24 * state.dataGlobal.TimeStepsInHour):
                if startPeak < ts <= endPeak:
                    onPeakSumWaterFlow += plntLoop.plantDesWaterFlowRate[ts]
            onPeakSumWaterFlow /= onPeakTimeSteps

        Cp = plntLoop.glycol.getSpecificHeat(state, plntSizData.ExitTemp, callingRoutine)
        rho = plntLoop.glycol.getDensity(state, plntSizData.ExitTemp, callingRoutine)
        onPeakEnergy = onPeakSumWaterFlow * rho * Cp * plntSizData.DeltaT * 3600.0 * onPeakHours
        tankCapacity = onPeakEnergy * sizingFactor

        if self.NomCapacityWasAutoSized:
            self.ITSNomCap = max(1.0, tankCapacity)
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if not self.NomCapacityWasAutoSized:
                BaseSizer_reportSizerOutput(state, tankType, self.Name, "User-Specified Capacity [GJ]", self.ITSNomCap / 1.0e9)
            BaseSizer_reportSizerOutput(state, tankType, self.Name, "Design Size Capacity [GJ]", tankCapacity / 1.0e9)

    def setupOutputVars(self, state: EnergyPlusDataProto) -> None:
        SetupOutputVariable(state, "Ice Thermal Storage Requested Load", "W", self.MyLoad, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage End Fraction", "None", self.IceFracRemain, "Zone", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Mass Flow Rate", "kg/s", self.ITSmdot, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Inlet Temperature", "C", self.ITSInletTemp, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Outlet Temperature", "C", self.ITSOutletTemp, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Rate", "W", self.ITSCoolingRate_rep, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Energy", "J", self.ITSCoolingEnergy_rep, "System", "Sum", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Rate", "W", self.ITSChargingRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Energy", "J", self.ITSChargingEnergy, "System", "Sum", self.Name)

    def CalcIceStorageCapacity(self, state: EnergyPlusDataProto, MaxCap: float, MinCap: float, OptCap: float) -> tuple:
        MaxCap = 0.0
        MinCap = 0.0
        OptCap = 0.0

        if self.ResetXForITSFlag:
            self.XCurIceFrac = 1.0
            self.IceFracRemain = 1.0
            self.Urate = 0.0
            self.ResetXForITSFlag = False

        self.CalcUAIce(self.XCurIceFrac)
        QiceMin = self.CalcQiceDischageMax(state)

        EpsLimitForDisCharge = 0.0
        EpsLimitForX = 0.0
        TimeInterval = 3600.0
        Umin = min(max((-(1.0 - EpsLimitForDisCharge) * QiceMin * TimeInterval / self.ITSNomCap), (-self.XCurIceFrac + EpsLimitForX)), 0.0)

        Uact = Umin
        ITSCoolingRateMax = abs(Uact * self.ITSNomCap / TimeInterval)
        ITSCoolingRateOpt = ITSCoolingRateMax
        ITSCoolingRateMin = 0.0

        MaxCap = ITSCoolingRateMax
        OptCap = ITSCoolingRateOpt
        MinCap = ITSCoolingRateMin
        return MaxCap, MinCap, OptCap

    def CalcIceStorageDormant(self, state: EnergyPlusDataProto) -> None:
        self.ITSMassFlowRate = 0.0
        PlantUtilities_SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)
        self.ITSInletTemp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        self.ITSOutletTemp = self.ITSInletTemp
        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPointHi
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.Urate = 0.0

    def CalcIceStorageCharge(self, state: EnergyPlusDataProto) -> None:
        self.ITSMassFlowRate = self.DesignMassFlowRate
        PlantUtilities_SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)
        self.ITSInletTemp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        self.ITSOutletTemp = self.ITSInletTemp
        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPointHi
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.Urate = 0.0

        QiceMaxByChiller = self.CalcQiceChargeMaxByChiller(state)
        chillerOutletTemp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        QiceMaxByITS = self.CalcQiceChargeMaxByITS(chillerOutletTemp)

        QiceMax = min(QiceMaxByChiller, QiceMaxByITS)

        EpsLimitForCharge = 0.0
        EpsLimitForX = 0.0
        TimeInterval = 3600.0
        Umax = max(min(((1.0 - EpsLimitForCharge) * QiceMax * TimeInterval / self.ITSNomCap), (1.0 - self.XCurIceFrac - EpsLimitForX)), 0.0)
        Umax = min(Umax, (1.0 - self.IceFracRemain) / state.dataHVACGlobal.TimeStepSys)

        if Umax == 0.0:
            Uact = 0.0
        else:
            Uact = Umax

        Qice = Uact * self.ITSNomCap / TimeInterval
        FreezTemp = 0.0
        if Qice <= 0.0:
            self.Urate = 0.0
        else:
            if (Qice <= 0.0) or (self.XCurIceFrac >= 1.0):
                self.ITSOutletTemp = self.ITSInletTemp
                Qice = 0.0
                Uact = 0.0
            else:
                DeltaTemp = Qice / Psychrometrics_CPCW(self.ITSInletTemp) / self.ITSMassFlowRate
                self.ITSOutletTemp = self.ITSInletTemp + DeltaTemp
                self.ITSOutletTemp = min(self.ITSOutletTemp, self.ITSOutletSetPointTemp, (FreezTemp - 1))
                self.ITSOutletTemp = max(self.ITSOutletTemp, self.ITSInletTemp)
                DeltaTemp = self.ITSOutletTemp - self.ITSInletTemp
                Qice = DeltaTemp * Psychrometrics_CPCW(self.ITSInletTemp) * self.ITSMassFlowRate
                Uact = Qice / (self.ITSNomCap / TimeInterval)

        self.Urate = Uact
        self.ITSCoolingRate = -Qice
        self.ITSCoolingEnergy = self.ITSCoolingRate * state.dataHVACGlobal.TimeStepSysSec

    def CalcQiceChargeMaxByChiller(self, state: EnergyPlusDataProto) -> float:
        FreezTemp = 0.0
        TchillerOut = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        QiceMaxByChiller = self.UAIceCh * (FreezTemp - TchillerOut)
        if QiceMaxByChiller <= 0.0:
            QiceMaxByChiller = 0.0
        return QiceMaxByChiller

    def CalcQiceChargeMaxByITS(self, chillerOutletTemp: float) -> float:
        FreezTemp = 0.0
        FreezTempIP = 32.0
        Tfr = FreezTempIP
        ChOutletTemp = TempSItoIP(chillerOutletTemp)
        if ChOutletTemp >= Tfr:
            return 0.0
        else:
            ChillerInletTemp = ChOutletTemp + 0.01
            if ChillerInletTemp >= Tfr:
                ChillerInletTemp = ChOutletTemp + (Tfr - ChOutletTemp) / 2
            LogTerm = (Tfr - ChOutletTemp) / (Tfr - ChillerInletTemp)
            if LogTerm <= 0.0:
                return 0.0
            return self.UAIceCh * (TempIPtoSI(ChillerInletTemp) - TempIPtoSI(ChOutletTemp)) / math.log(LogTerm)

    def CalcIceStorageDischarge(self, state: EnergyPlusDataProto, myLoad: float, RunFlag: bool, MaxCap: float) -> None:
        RoutineName = "SimpleIceStorageData::CalcIceStorageDischarge"
        self.ITSMassFlowRate = 0.0
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0

        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            self.ITSOutletSetPointTemp = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPointHi

        self.Urate = 0.0

        if myLoad == 0 or not RunFlag:
            self.ITSMassFlowRate = 0.0
            self.ITSInletTemp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
            self.ITSOutletTemp = self.ITSInletTemp
            self.ITSCoolingRate = 0.0
            self.ITSCoolingEnergy = 0.0
            return

        CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node(self.PltInletNodeNum).Temp, RoutineName)

        TimeInterval = 3600.0
        Umyload = -myLoad * TimeInterval / self.ITSNomCap
        Umax = -self.IceFracRemain / state.dataHVACGlobal.TimeStepSys
        Umin = min(Umyload, 0.0)
        Uact = max(Umin, Umax)

        self.ITSInletTemp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        self.ITSMassFlowRate = self.DesignMassFlowRate
        PlantUtilities_SetComponentFlowRate(state, self.ITSMassFlowRate, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)

        Qice = Uact * self.ITSNomCap / TimeInterval
        Qice = max(Qice, -MaxCap)

        FreezTemp = 0.0
        MassFlowTolerance = 0.001
        if (Qice >= 0.0) or (self.XCurIceFrac <= 0.0) or (self.ITSMassFlowRate < MassFlowTolerance):
            self.ITSOutletTemp = self.ITSInletTemp
            Qice = 0.0
            Uact = 0.0
        else:
            DeltaTemp = Qice / CpFluid / self.ITSMassFlowRate
            self.ITSOutletTemp = self.ITSInletTemp + DeltaTemp
            self.ITSOutletTemp = max(self.ITSOutletTemp, self.ITSOutletSetPointTemp, (FreezTemp + 1))
            self.ITSOutletTemp = min(self.ITSOutletTemp, self.ITSInletTemp)
            DeltaTemp = self.ITSOutletTemp - self.ITSInletTemp
            Qice = DeltaTemp * CpFluid * self.ITSMassFlowRate
            Uact = Qice / (self.ITSNomCap / TimeInterval)

        self.Urate = Uact
        self.ITSCoolingRate = -Qice
        self.ITSCoolingEnergy = self.ITSCoolingRate * state.dataHVACGlobal.TimeStepSysSec

    def CalcQiceDischageMax(self, state: EnergyPlusDataProto) -> float:
        ITSInletTemp_loc = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        ITSOutletTemp_loc = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            ITSOutletTemp_loc = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            ITSOutletTemp_loc = state.dataLoopNodes.Node(self.PltOutletNodeNum).TempSetPointHi

        FreezTemp = 0.0
        LogTerm = (ITSInletTemp_loc - FreezTemp) / (ITSOutletTemp_loc - FreezTemp)

        if LogTerm <= 1:
            return 0.0
        else:
            return self.UAIceDisCh * (ITSInletTemp_loc - ITSOutletTemp_loc) / math.log(LogTerm)

    def CalcUAIce(self, XCurIceFrac_loc: float) -> None:
        TimeInterval = 3600.0
        if self.ITSType_Num == ITSType.IceOnCoilInternal:
            y = XCurIceFrac_loc
            self.UAIceCh = (1.3879 - 7.6333 * y + 26.3423 * y**2 - 47.6084 * y**3 + 41.8498 * y**4 - 14.2948 * y**5) * self.ITSNomCap / TimeInterval / 10.0
            y = 1.0 - XCurIceFrac_loc
            self.UAIceDisCh = (1.3879 - 7.6333 * y + 26.3423 * y**2 - 47.6084 * y**3 + 41.8498 * y**4 - 14.2948 * y**5) * self.ITSNomCap / TimeInterval / 10.0
            self.HLoss = 0.0
        elif self.ITSType_Num == ITSType.IceOnCoilExternal:
            y = XCurIceFrac_loc
            self.UAIceCh = (1.3879 - 7.6333 * y + 26.3423 * y**2 - 47.6084 * y**3 + 41.8498 * y**4 - 14.2948 * y**5) * self.ITSNomCap / TimeInterval / 10.0
            y = 1.0 - XCurIceFrac_loc
            self.UAIceDisCh = (1.1756 - 5.3689 * y + 17.3602 * y**2 - 30.1077 * y**3 + 25.6387 * y**4 - 8.5102 * y**5) * self.ITSNomCap / TimeInterval / 10.0
            self.HLoss = 0.0

    def UpdateNode(self, state: EnergyPlusDataProto, myLoad: float, RunFlag: bool) -> None:
        PlantUtilities_SafeCopyPlantNode(state, self.PltInletNodeNum, self.PltOutletNodeNum)
        if myLoad == 0 or not RunFlag:
            state.dataLoopNodes.Node(self.PltOutletNodeNum).Temp = state.dataLoopNodes.Node(self.PltInletNodeNum).Temp
        else:
            state.dataLoopNodes.Node(self.PltOutletNodeNum).Temp = self.ITSOutletTemp

    def RecordOutput(self, myLoad: float, RunFlag: bool) -> None:
        if myLoad == 0 or not RunFlag:
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

@dataclass
class DetailedIceStorageData:
    Name: str = ""
    availSched: Optional[Schedule] = None
    NomCapacity: float = 0.0
    NomCapacityWasAutoSized: bool = False
    PlantInNodeNum: int = 0
    PlantOutNodeNum: int = 0
    plantLoc: Optional[PlantLocationProto] = None
    DesignMassFlowRate: float = 0.0
    MapNum: int = 0
    DischargeCurveName: str = ""
    DischargeCurveNum: int = 0
    DischargeCurveTypeNum: CurveVars = CurveVars.Invalid
    ChargeCurveName: str = ""
    ChargeCurveNum: int = 0
    ChargeCurveTypeNum: CurveVars = CurveVars.Invalid
    CurveFitTimeStep: float = 1.0
    DischargeParaElecLoad: float = 0.0
    ChargeParaElecLoad: float = 0.0
    TankLossCoeff: float = 0.0
    FreezingTemp: float = 0.0
    CompLoad: float = 0.0
    IceFracChange: float = 0.0
    IceFracRemaining: float = 1.0
    ThawProcessIndicator: str = ""
    ThawProcessIndex: DetIce = DetIce.Invalid
    IceFracOnCoil: float = 1.0
    DischargingRate: float = 0.0
    DischargingEnergy: float = 0.0
    ChargingRate: float = 0.0
    ChargingEnergy: float = 0.0
    MassFlowRate: float = 0.0
    BypassMassFlowRate: float = 0.0
    TankMassFlowRate: float = 0.0
    InletTemp: float = 0.0
    OutletTemp: float = 0.0
    TankOutletTemp: float = 0.0
    ParasiticElecRate: float = 0.0
    ParasiticElecEnergy: float = 0.0
    DischargeIterErrors: int = 0
    DischargeErrorCount: int = 0
    ChargeIterErrors: int = 0
    ChargeErrorCount: int = 0
    ResetXForITSFlag: bool = False
    MyEnvrnFlag: bool = True
    CheckEquipName: bool = True
    MyPlantScanFlag: bool = True
    MyEnvrnFlag2: bool = True
    TESSizingIndex: int = 0

    def factory(self, state: EnergyPlusDataProto, objectName: str) -> 'DetailedIceStorageData':
        if state.dataIceThermalStorage.getITSInput:
            GetIceStorageInput(state)
            state.dataIceThermalStorage.getITSInput = False
        for ITS in state.dataIceThermalStorage.DetailedIceStorage:
            if ITS.Name == objectName:
                return ITS
        raise RuntimeError(f"LocalDetailedIceStorageFactory: Error getting inputs for detailed ice storage named: {objectName}")

    def simulate(self, state: EnergyPlusDataProto, calledFromLocation: PlantLocationProto, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.ResetXForITSFlag = True
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        self.initialize(state)
        self.SimDetailedIceStorage(state)
        self.UpdateDetailedIceStorage(state)
        self.ReportDetailedIceStorage(state)

    def onInitLoopEquip(self, state: EnergyPlusDataProto, calledFromLocation: PlantLocationProto) -> None:
        self.oneTimeInit(state)
        self.size(state)

    def oneTimeInit(self, state: EnergyPlusDataProto) -> None:
        if self.MyPlantScanFlag:
            errFlag = False
            PlantUtilities_ScanPlantLoopsForObject(state, self.Name, "TS_IceDetailed", self.plantLoc, errFlag)
            if errFlag:
                raise RuntimeError("DetailedIceStorageData: oneTimeInit: Program terminated due to previous condition(s).")
            self.setupOutputVars(state)
            self.MyPlantScanFlag = False

    def initialize(self, state: EnergyPlusDataProto) -> None:
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
            PlantUtilities_InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.PlantInNodeNum, self.PlantOutNodeNum)
            if (self.plantLoc.loop.CommonPipeType == "TwoWay" and
                self.plantLoc.loopSideNum == "Supply"):
                for CompNum in range(1, self.plantLoc.branch.TotalComponents + 1):
                    self.plantLoc.branch.Comp(CompNum).FlowPriority = "NeedyAndTurnsLoopOn"
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

    def size(self, state: EnergyPlusDataProto) -> None:
        TESTankIndex = Util_FindItemInList(self.Name, state.dataIceThermalStorage.DetailedIceStorage, 'Name')
        if TESTankIndex < 0:
            return
        TESSizingIndex = state.dataIceThermalStorage.DetailedIceStorage[TESTankIndex].TESSizingIndex
        if TESSizingIndex == 0:
            return

        tankType = "ThermalStorage:Ice:Detailed"
        callingRoutine = "DetailedIceStorageData::size"
        plntLoop = state.dataPlnt.PlantLoop(self.plantLoc.loopNum)
        PltSizNum = plntLoop.PlantSizNum
        plntSizData = state.dataSize.PlantSizData(PltSizNum)

        startPeak = int(state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).onPeakStart * state.dataGlobal.TimeStepsInHour)
        endPeak = int(state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).onPeakEnd * state.dataGlobal.TimeStepsInHour)
        onPeakTimeSteps = endPeak - startPeak
        onPeakHours = onPeakTimeSteps / state.dataGlobal.TimeStepsInHour
        sizingFactor = state.dataIceThermalStorage.ThermalStorageSizing(TESSizingIndex).sizingFactor
        onPeakSumWaterFlow = 0.0
        if plntLoop.plantDesWaterFlowRate:
            for ts in range(24 * state.dataGlobal.TimeStepsInHour):
                if startPeak < ts <= endPeak:
                    onPeakSumWaterFlow += plntLoop.plantDesWaterFlowRate[ts]
            onPeakSumWaterFlow /= onPeakTimeSteps

        Cp = plntLoop.glycol.getSpecificHeat(state, plntSizData.ExitTemp, callingRoutine)
        rho = plntLoop.glycol.getDensity(state, plntSizData.ExitTemp, callingRoutine)
        onPeakEnergy = onPeakSumWaterFlow * rho * Cp * plntSizData.DeltaT * 3600.0 * onPeakHours
        tankCapacity = onPeakEnergy * sizingFactor / 3600.0

        if self.NomCapacityWasAutoSized:
            self.NomCapacity = max(1.0, tankCapacity)
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if not self.NomCapacityWasAutoSized:
                BaseSizer_reportSizerOutput(state, tankType, self.Name, "User-Specified Capacity [GJ]", self.NomCapacity * 3600.0 / 1.0e9)
            BaseSizer_reportSizerOutput(state, tankType, self.Name, "Design Size Capacity [GJ]", tankCapacity * 3600.0 / 1.0e9)

    def setupOutputVars(self, state: EnergyPlusDataProto) -> None:
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Rate", "W", self.CompLoad, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Change Fraction", "None", self.IceFracChange, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage End Fraction", "None", self.IceFracRemaining, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage On Coil Fraction", "None", self.IceFracOnCoil, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Mass Flow Rate", "kg/s", self.MassFlowRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Bypass Mass Flow Rate", "kg/s", self.BypassMassFlowRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Tank Mass Flow Rate", "kg/s", self.TankMassFlowRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Fluid Inlet Temperature", "C", self.InletTemp, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Blended Outlet Temperature", "C", self.OutletTemp, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Tank Outlet Temperature", "C", self.TankOutletTemp, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Rate", "W", self.DischargingRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Discharge Energy", "J", self.DischargingEnergy, "System", "Sum", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Rate", "W", self.ChargingRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Cooling Charge Energy", "J", self.ChargingEnergy, "System", "Sum", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Ancillary Electricity Rate", "W", self.ParasiticElecRate, "System", "Average", self.Name)
        SetupOutputVariable(state, "Ice Thermal Storage Ancillary Electricity Energy", "J", self.ParasiticElecEnergy, "System", "Sum", self.Name)

    def SimDetailedIceStorage(self, state: EnergyPlusDataProto) -> None:
        MaxIterNum = 100
        SmallestLoad = 0.1
        TankDischargeToler = 0.001
        TankChargeToler = 0.999
        TemperatureToler = 0.1
        SIEquiv100GPMinMassFlowRate = 6.31
        RoutineName = "DetailedIceStorageData::SimDetailedIceStorage"
        DeltaTofMin = 0.5
        DeltaTifMin = 1.0

        NodeNumIn = self.PlantInNodeNum
        NodeNumOut = self.PlantOutNodeNum
        TempIn = state.dataLoopNodes.Node(NodeNumIn).Temp
        TempSetPt = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == "SingleSetPoint":
            TempSetPt = state.dataLoopNodes.Node(NodeNumOut).TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == "DualSetPointDeadBand":
            TempSetPt = state.dataLoopNodes.Node(NodeNumOut).TempSetPointHi

        IterNum = 0

        self.InletTemp = TempIn
        self.MassFlowRate = state.dataLoopNodes.Node(NodeNumIn).MassFlowRate

        if (self.plantLoc.loop.CommonPipeType == "TwoWay" and
            abs(self.MassFlowRate) < 0.001 and self.IceFracRemaining < TankChargeToler):
            self.MassFlowRate = self.DesignMassFlowRate

        Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, TempIn, RoutineName)
        LocalLoad = self.MassFlowRate * Cp * (TempIn - TempSetPt)

        if (abs(LocalLoad) <= SmallestLoad) or (self.availSched.getCurrentVal() <= 0):
            self.CompLoad = 0.0
            self.OutletTemp = TempIn
            self.TankOutletTemp = TempIn
            mdot = 0.0
            PlantUtilities_SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
            self.BypassMassFlowRate = mdot
            self.TankMassFlowRate = 0.0
            self.MassFlowRate = mdot

        elif LocalLoad < 0.0:
            if ((TempIn > (self.FreezingTemp - DeltaTifMin)) or (self.IceFracRemaining >= TankChargeToler)):
                self.CompLoad = 0.0
                self.OutletTemp = TempIn
                self.TankOutletTemp = TempIn
                mdot = 0.0
                PlantUtilities_SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                self.BypassMassFlowRate = mdot
                self.TankMassFlowRate = 0.0
                self.MassFlowRate = mdot
            else:
                mdot = self.DesignMassFlowRate
                PlantUtilities_SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)

                if TempSetPt > (self.FreezingTemp - DeltaTofMin):
                    TempSetPt = self.FreezingTemp - DeltaTofMin

                ToutOld = TempSetPt
                LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                MassFlowstar = self.MassFlowRate / SIEquiv100GPMinMassFlowRate

                ChargeFrac = LocalLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                if (self.IceFracRemaining + ChargeFrac) > 1.0:
                    ChargeFrac = 1.0 - self.IceFracRemaining

                if self.ThawProcessIndex == DetIce.InsideMelt:
                    AvgFracCharged = self.IceFracOnCoil + (ChargeFrac / 2.0)
                else:
                    AvgFracCharged = self.IceFracRemaining + (ChargeFrac / 2.0)

                Qstar = abs(CalcQstar(state, self.ChargeCurveNum, self.ChargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep

                ToutNew = TempIn + (ActualLoad / (self.MassFlowRate * Cp))
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
                            ShowRecurringWarningErrorAtEnd(state, f"Detailed Ice Storage system [{self.Name}]  charging maximum iteration limit exceeded occurrence continues.", self.ChargeErrorCount)

                    self.OutletTemp = ToutNew
                    self.TankOutletTemp = ToutNew
                    self.BypassMassFlowRate = 0.0
                    self.TankMassFlowRate = self.MassFlowRate
                    self.CompLoad = self.MassFlowRate * Cp * abs(TempIn - ToutNew)

        elif LocalLoad > 0.0:
            if ((self.InletTemp < (self.FreezingTemp + DeltaTifMin)) or (self.IceFracRemaining <= TankDischargeToler)):
                self.CompLoad = 0.0
                self.OutletTemp = self.InletTemp
                self.TankOutletTemp = self.InletTemp
                mdot = 0.0
                PlantUtilities_SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)
                self.BypassMassFlowRate = mdot
                self.TankMassFlowRate = 0.0
                self.MassFlowRate = mdot
            else:
                mdot = self.DesignMassFlowRate
                PlantUtilities_SetComponentFlowRate(state, mdot, self.PlantInNodeNum, self.PlantOutNodeNum, self.plantLoc)

                if TempSetPt < (self.FreezingTemp + DeltaTofMin):
                    TempSetPt = self.FreezingTemp + DeltaTofMin

                ToutOld = TempSetPt
                LMTDstar = CalcDetIceStorLMTDstar(TempIn, ToutOld, self.FreezingTemp)
                MassFlowstar = self.MassFlowRate / SIEquiv100GPMinMassFlowRate

                ChargeFrac = LocalLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                if (self.IceFracRemaining - ChargeFrac) < 0.0:
                    ChargeFrac = self.IceFracRemaining
                AvgFracCharged = self.IceFracRemaining - (ChargeFrac / 2.0)

                Qstar = abs(CalcQstar(state, self.DischargeCurveNum, self.DischargeCurveTypeNum, AvgFracCharged, LMTDstar, MassFlowstar))
                ActualLoad = Qstar * self.NomCapacity / self.CurveFitTimeStep

                ToutNew = TempIn - (ActualLoad / (self.MassFlowRate * Cp))
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

                    if IterNum >= MaxIterNum and not state.dataGlobal.WarmupFlag:
                        self.DischargeIterErrors += 1
                        if self.DischargeIterErrors <= 25:
                            ShowWarningError(state, "Detailed Ice Storage model exceeded its internal discharging maximum iteration limit")
                            ShowContinueError(state, f"Detailed Ice Storage System Name = {self.Name}")
                            ShowContinueErrorTimeStamp(state, "")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, f"Detailed Ice Storage system [{self.Name}]  discharging maximum iteration limit exceeded occurrence continues.", self.DischargeErrorCount)

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
            raise RuntimeError("Detailed Ice Storage systemic code error--contact EnergyPlus support")

    def UpdateDetailedIceStorage(self, state: EnergyPlusDataProto) -> None:
        InNodeNum = self.PlantInNodeNum
        OutNodeNum = self.PlantOutNodeNum
        PlantUtilities_SafeCopyPlantNode(state, InNodeNum, OutNodeNum)
        state.dataLoopNodes.Node(OutNodeNum).Temp = self.OutletTemp

    def ReportDetailedIceStorage(self, state: EnergyPlusDataProto) -> None:
        LowLoadLimit = 0.1

        if self.CompLoad < LowLoadLimit:
            self.IceFracChange = 0.0
            self.DischargingRate = 0.0
            self.DischargingEnergy = 0.0
            self.ChargingRate = 0.0
            self.ChargingEnergy = 0.0
            self.ParasiticElecRate = 0.0
            self.ParasiticElecEnergy = 0.0
        else:
            if self.InletTemp < self.OutletTemp:
                self.ChargingRate = self.CompLoad
                self.ChargingEnergy = self.CompLoad * state.dataHVACGlobal.TimeStepSysSec
                self.IceFracChange = self.CompLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                self.DischargingRate = 0.0
                self.DischargingEnergy = 0.0
                self.ParasiticElecRate = self.ChargeParaElecLoad * self.CompLoad
                self.ParasiticElecEnergy = self.ChargeParaElecLoad * self.ChargingEnergy
            else:
                self.DischargingRate = self.CompLoad
                self.DischargingEnergy = self.CompLoad * state.dataHVACGlobal.TimeStepSysSec
                self.IceFracChange = -self.CompLoad * state.dataHVACGlobal.TimeStepSys / self.NomCapacity
                self.ChargingRate = 0.0
                self.ChargingEnergy = 0.0
                self.ParasiticElecRate = self.DischargeParaElecLoad * self.CompLoad
                self.ParasiticElecEnergy = self.DischargeParaElecLoad * self.ChargingEnergy

@dataclass
class IceThermalStorageData:
    getITSInput: bool = True
    NumThermalStorageSizing: int = 0
    NumSimpleIceStorage: int = 0
    NumDetailedIceStorage: int = 0
    TotalNumIceStorage: int = 0
    ThermalStorageSizing: List[ThermalStorageSizingData] = field(default_factory=list)
    SimpleIceStorage: List[SimpleIceStorageData] = field(default_factory=list)
    DetailedIceStorage: List[DetailedIceStorageData] = field(default_factory=list)

# ===== MODULE-LEVEL FUNCTIONS =====

def GetIceStorageInput(state: EnergyPlusDataProto) -> None:
    routineName = "GetIceStorageInput"
    cIceStorageSizing = "ThermalStorage:Sizing"
    cIceStorageSimple = "ThermalStorage:Ice:Simple"
    cIceStorageDetailed = "ThermalStorage:Ice:Detailed"

    ErrorsFound = False

    state.dataIceThermalStorage.NumThermalStorageSizing = InputProcessor_getNumObjectsFound(state, cIceStorageSizing)
    state.dataIceThermalStorage.NumSimpleIceStorage = InputProcessor_getNumObjectsFound(state, cIceStorageSimple)
    state.dataIceThermalStorage.NumDetailedIceStorage = InputProcessor_getNumObjectsFound(state, cIceStorageDetailed)

    state.dataIceThermalStorage.ThermalStorageSizing = [ThermalStorageSizingData() for _ in range(state.dataIceThermalStorage.NumThermalStorageSizing)]

    for sizingNum in range(state.dataIceThermalStorage.NumThermalStorageSizing):
        NumAlphas, NumNums, IOStat, cAlphaArgs, rNumericArgs, cAlphaFieldNames, cNumericFieldNames = InputProcessor_getObjectItem(state, cIceStorageSizing, sizingNum + 1)
        state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].name = cAlphaArgs[0]
        state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakStart = rNumericArgs[0]
        state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakEnd = rNumericArgs[1]
        state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].sizingFactor = rNumericArgs[2]
        if state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakEnd <= state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakStart:
            ShowSevereError(state, f"{routineName}{cIceStorageSizing}=\"{state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].name}\"")
            ShowContinueError(state, f"Invalid start {state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakStart} and end times {state.dataIceThermalStorage.ThermalStorageSizing[sizingNum].onPeakEnd}. End time must be greater than start time.")

    state.dataIceThermalStorage.SimpleIceStorage = [SimpleIceStorageData() for _ in range(state.dataIceThermalStorage.NumSimpleIceStorage)]

    for iceNum in range(state.dataIceThermalStorage.NumSimpleIceStorage):
        NumAlphas, NumNums, IOStat, cAlphaArgs, rNumericArgs, cAlphaFieldNames, cNumericFieldNames = InputProcessor_getObjectItem(state, cIceStorageSimple, iceNum + 1)

        state.dataIceThermalStorage.TotalNumIceStorage += 1
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].MapNum = state.dataIceThermalStorage.TotalNumIceStorage
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].Name = cAlphaArgs[0]
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSType = cAlphaArgs[1]

        if Util_SameString(state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSType, "IceOnCoilInternal"):
            state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSType_Num = ITSType.IceOnCoilInternal
        elif Util_SameString(state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSType, "IceOnCoilExternal"):
            state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSType_Num = ITSType.IceOnCoilExternal
        else:
            ShowSevereError(state, f"{cIceStorageSimple}={cAlphaArgs[0]}")
            ShowContinueError(state, f"Invalid {cAlphaFieldNames[1]}={cAlphaArgs[1]}")
            ErrorsFound = True

        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSNomCap = rNumericArgs[0] * 1.0e9
        if rNumericArgs[0] == -99999:
            state.dataIceThermalStorage.SimpleIceStorage[iceNum].NomCapacityWasAutoSized = True
        elif rNumericArgs[0] == 0.0:
            ShowSevereError(state, f"{cIceStorageSimple}={cAlphaArgs[0]}")
            ShowContinueError(state, f"Invalid {cNumericFieldNames[0]}={rNumericArgs[0]:.2f}")
            ErrorsFound = True

        state.dataIceThermalStorage.SimpleIceStorage[iceNum].PltInletNodeNum = Node_GetOnlySingleNode(state, cAlphaArgs[2], "ThermalStorageIceSimple", cAlphaArgs[0])
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].PltOutletNodeNum = Node_GetOnlySingleNode(state, cAlphaArgs[3], "ThermalStorageIceSimple", cAlphaArgs[0])

        Node_TestCompSet(state, cIceStorageSimple, cAlphaArgs[0], cAlphaArgs[2], cAlphaArgs[3], "Chilled Water Nodes")

        state.dataIceThermalStorage.SimpleIceStorage[iceNum].TESSizingIndex = Util_FindItemInList(cAlphaArgs[4], state.dataIceThermalStorage.ThermalStorageSizing, 'name')
        if state.dataIceThermalStorage.SimpleIceStorage[iceNum].TESSizingIndex == 0 and state.dataIceThermalStorage.SimpleIceStorage[iceNum].NomCapacityWasAutoSized:
            ShowSevereError(state, f"Invalid {cAlphaFieldNames[4]}={cAlphaArgs[4]}")
            ShowContinueError(state, f"Entered in {cIceStorageSimple}={cAlphaArgs[0]}")
            ShowContinueError(state, f"Input field {cAlphaFieldNames[4]} must be entered when input field {cNumericFieldNames[0]} is autosized")
            ErrorsFound = True

        state.dataIceThermalStorage.SimpleIceStorage[iceNum].MyLoad = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].Urate = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].IceFracRemain = 1.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSCoolingRate_rep = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSCoolingEnergy_rep = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSChargingRate = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSChargingEnergy = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSmdot = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSInletTemp = 0.0
        state.dataIceThermalStorage.SimpleIceStorage[iceNum].ITSOutletTemp = 0.0

    if ErrorsFound:
        raise RuntimeError(f"Errors found in processing input for {cIceStorageSimple}")

    ErrorsFound = False

    state.dataIceThermalStorage.DetailedIceStorage = [DetailedIceStorageData() for _ in range(state.dataIceThermalStorage.NumDetailedIceStorage)]

    for iceNum in range(state.dataIceThermalStorage.NumDetailedIceStorage):
        NumAlphas, NumNums, IOStat, cAlphaArgs, rNumericArgs, cAlphaFieldNames, cNumericFieldNames = InputProcessor_getObjectItem(state, cIceStorageDetailed, iceNum + 1)

        state.dataIceThermalStorage.TotalNumIceStorage += 1
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].MapNum = state.dataIceThermalStorage.TotalNumIceStorage
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].Name = cAlphaArgs[0]

        if not cAlphaArgs[1]:
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].availSched = Sched_GetScheduleAlwaysOn(state)
        else:
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].availSched = Sched_GetSchedule(state, cAlphaArgs[1])
            if state.dataIceThermalStorage.DetailedIceStorage[iceNum].availSched is None:
                ShowSevereItemNotFound(state, cAlphaFieldNames[1], cAlphaArgs[1])
                ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].NomCapacity = rNumericArgs[0] * (1.0e9) / 3600.0
        if rNumericArgs[0] == -99999:
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].NomCapacityWasAutoSized = True
        elif rNumericArgs[0] <= 0.0:
            ShowSevereError(state, f"Invalid {cNumericFieldNames[0]}={rNumericArgs[0]:.2f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].PlantInNodeNum = Node_GetOnlySingleNode(state, cAlphaArgs[2], "ThermalStorageIceDetailed", cAlphaArgs[0])
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].PlantOutNodeNum = Node_GetOnlySingleNode(state, cAlphaArgs[3], "ThermalStorageIceDetailed", cAlphaArgs[0])

        Node_TestCompSet(state, cIceStorageDetailed, cAlphaArgs[0], cAlphaArgs[2], cAlphaArgs[3], "Chilled Water Nodes")

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveName = cAlphaArgs[5]
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveNum = Curve_GetCurveIndex(state, cAlphaArgs[5])
        if state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveNum <= 0:
            ShowSevereError(state, f"Invalid {cAlphaFieldNames[5]}={cAlphaArgs[5]}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ErrorsFound = True

        if cAlphaArgs[4] == "FRACTIONCHARGEDLMTD":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveTypeNum = CurveVars.FracChargedLMTD
        elif cAlphaArgs[4] == "FRACTIONDISCHARGEDLMTD":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveTypeNum = CurveVars.FracDischargedLMTD
        elif cAlphaArgs[4] == "LMTDMASSFLOW":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveTypeNum = CurveVars.LMTDMassFlow
        elif cAlphaArgs[4] == "LMTDFRACTIONCHARGED":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeCurveTypeNum = CurveVars.LMTDFracCharged
        else:
            ShowSevereError(state, f"{cIceStorageDetailed}: Discharge curve independent variable options not valid, option={cAlphaArgs[4]}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "The valid options are: FractionChargedLMTD, FractionDischargedLMTD, LMTDMassFlow or LMTDFractionCharged")
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveName = cAlphaArgs[7]
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveNum = Curve_GetCurveIndex(state, cAlphaArgs[7])
        if state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveNum <= 0:
            ShowSevereError(state, f"Invalid {cAlphaFieldNames[7]}={cAlphaArgs[7]}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ErrorsFound = True

        if cAlphaArgs[6] == "FRACTIONCHARGEDLMTD":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveTypeNum = CurveVars.FracChargedLMTD
        elif cAlphaArgs[6] == "FRACTIONDISCHARGEDLMTD":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveTypeNum = CurveVars.FracDischargedLMTD
        elif cAlphaArgs[6] == "LMTDMASSFLOW":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveTypeNum = CurveVars.LMTDMassFlow
        elif cAlphaArgs[6] == "LMTDFRACTIONCHARGED":
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeCurveTypeNum = CurveVars.LMTDFracCharged
        else:
            ShowSevereError(state, f"{cIceStorageDetailed}: Charge curve independent variable options not valid, option={cAlphaArgs[6]}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "The valid options are: FractionChargedLMTD, FractionDischargedLMTD, LMTDMassFlow or LMTDFractionCharged")
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].CurveFitTimeStep = rNumericArgs[1]
        if ((state.dataIceThermalStorage.DetailedIceStorage[iceNum].CurveFitTimeStep <= 0.0) or
            (state.dataIceThermalStorage.DetailedIceStorage[iceNum].CurveFitTimeStep > 1.0)):
            ShowSevereError(state, f"Invalid {cNumericFieldNames[1]}={rNumericArgs[1]:.3f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, f"Curve fit time step invalid, less than zero or greater than 1 for {cAlphaArgs[0]}")
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndicator = cAlphaArgs[8]
        if Util_SameString(state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndicator, "INSIDEMELT"):
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndex = DetIce.InsideMelt
        elif (Util_SameString(state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndicator, "OUTSIDEMELT") or
              not state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndicator):
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndex = DetIce.OutsideMelt
        else:
            ShowSevereError(state, f"Invalid thaw process indicator of {cAlphaArgs[8]} was entered")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, 'Value should either be "InsideMelt" or "OutsideMelt"')
            state.dataIceThermalStorage.DetailedIceStorage[iceNum].ThawProcessIndex = DetIce.InsideMelt
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].TESSizingIndex = Util_FindItemInList(cAlphaArgs[9], state.dataIceThermalStorage.ThermalStorageSizing, 'name')
        if state.dataIceThermalStorage.DetailedIceStorage[iceNum].TESSizingIndex == 0 and state.dataIceThermalStorage.DetailedIceStorage[iceNum].NomCapacityWasAutoSized:
            ShowSevereError(state, f"Invalid {cAlphaFieldNames[9]}={cAlphaArgs[9]}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, f"Input field {cAlphaFieldNames[9]} must be entered when input field {cNumericFieldNames[0]} is autosized")
            ErrorsFound = True

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeParaElecLoad = rNumericArgs[2]
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeParaElecLoad = rNumericArgs[3]
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].TankLossCoeff = rNumericArgs[4]
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].FreezingTemp = rNumericArgs[5]

        if ((state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeParaElecLoad < 0.0) or
            (state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargeParaElecLoad > 1.0)):
            ShowSevereError(state, f"Invalid {cNumericFieldNames[2]}={rNumericArgs[2]:.3f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "Value is either less than/equal to zero or greater than 1")
            ErrorsFound = True

        if ((state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeParaElecLoad < 0.0) or
            (state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargeParaElecLoad > 1.0)):
            ShowSevereError(state, f"Invalid {cNumericFieldNames[3]}={rNumericArgs[3]:.3f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "Value is either less than/equal to zero or greater than 1")
            ErrorsFound = True

        if ((state.dataIceThermalStorage.DetailedIceStorage[iceNum].TankLossCoeff < 0.0) or
            (state.dataIceThermalStorage.DetailedIceStorage[iceNum].TankLossCoeff > 0.1)):
            ShowSevereError(state, f"Invalid {cNumericFieldNames[4]}={rNumericArgs[4]:.3f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "Value is either less than/equal to zero or greater than 0.1 (10%)")
            ErrorsFound = True

        if ((state.dataIceThermalStorage.DetailedIceStorage[iceNum].FreezingTemp < -10.0) or
            (state.dataIceThermalStorage.DetailedIceStorage[iceNum].FreezingTemp > 10.0)):
            ShowWarningError(state, f"Potentially invalid {cNumericFieldNames[5]}={rNumericArgs[5]:.3f}")
            ShowContinueError(state, f"Entered in {cIceStorageDetailed}={cAlphaArgs[0]}")
            ShowContinueError(state, "Value is either less than -10.0C or greater than 10.0C")
            ShowContinueError(state, "This value will be allowed but the user should verify that this temperature is correct")

        state.dataIceThermalStorage.DetailedIceStorage[iceNum].CompLoad = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].IceFracChange = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].IceFracRemaining = 1.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].IceFracOnCoil = 1.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargingRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].DischargingEnergy = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargingRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ChargingEnergy = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].MassFlowRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].BypassMassFlowRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].TankMassFlowRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].InletTemp = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].OutletTemp = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].TankOutletTemp = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ParasiticElecRate = 0.0
        state.dataIceThermalStorage.DetailedIceStorage[iceNum].ParasiticElecEnergy = 0.0

    if ((state.dataIceThermalStorage.NumSimpleIceStorage + state.dataIceThermalStorage.NumDetailedIceStorage) <= 0):
        ShowSevereError(state, "No Ice Storage Equipment found in GetIceStorage")
        ErrorsFound = True

    if ErrorsFound:
        raise RuntimeError(f"Errors found in processing input for {cIceStorageDetailed}")

def CalcDetIceStorLMTDstar(Tin: float, Tout: float, Tfr: float) -> float:
    Tnom = 10.0
    DeltaTofMin = 0.5
    DeltaTifMin = 1.0

    DeltaTio = abs(Tin - Tout)
    DeltaTif = abs(Tin - Tfr)
    DeltaTof = abs(Tout - Tfr)

    if DeltaTif < DeltaTifMin:
        DeltaTif = DeltaTifMin
    if DeltaTof < DeltaTofMin:
        DeltaTof = DeltaTofMin

    return (DeltaTio / math.log(DeltaTif / DeltaTof)) / Tnom

def CalcQstar(state: EnergyPlusDataProto, CurveIndex: int, CurveIndVarType: CurveVars, FracCharged: float, LMTDstar: float, MassFlowstar: float) -> float:
    if CurveIndVarType == CurveVars.FracChargedLMTD:
        return abs(Curve_CurveValue(state, CurveIndex, FracCharged, LMTDstar))
    elif CurveIndVarType == CurveVars.FracDischargedLMTD:
        return abs(Curve_CurveValue(state, CurveIndex, (1.0 - FracCharged), LMTDstar))
    elif CurveIndVarType == CurveVars.LMTDMassFlow:
        return abs(Curve_CurveValue(state, CurveIndex, LMTDstar, MassFlowstar))
    elif CurveIndVarType == CurveVars.LMTDFracCharged:
        return abs(Curve_CurveValue(state, CurveIndex, LMTDstar, FracCharged))
    else:
        return 0.0

def TempSItoIP(Temp: float) -> float:
    return (Temp * 9.0 / 5.0) + 32.0

def TempIPtoSI(Temp: float) -> float:
    return (Temp - 32.0) * 5.0 / 9.0

def UpdateIceFractions(state: EnergyPlusDataProto) -> None:
    for thisITS in state.dataIceThermalStorage.SimpleIceStorage:
        thisITS.IceFracRemain += thisITS.Urate * state.dataHVACGlobal.TimeStepSys
        if thisITS.IceFracRemain <= 0.001:
            thisITS.IceFracRemain = 0.0
        if thisITS.IceFracRemain > 1.0:
            thisITS.IceFracRemain = 1.0

    for thisITS in state.dataIceThermalStorage.DetailedIceStorage:
        thisITS.IceFracRemaining += thisITS.IceFracChange - (thisITS.TankLossCoeff * state.dataHVACGlobal.TimeStepSys)
        if thisITS.IceFracRemaining < 0.001:
            thisITS.IceFracRemaining = 0.0
        if thisITS.IceFracRemaining > 1.000:
            thisITS.IceFracRemaining = 1.0
        if thisITS.ThawProcessIndex == DetIce.InsideMelt:
            if thisITS.IceFracChange < 0.0:
                thisITS.IceFracOnCoil = 0.0
            else:
                thisITS.IceFracOnCoil += thisITS.IceFracChange
                if thisITS.IceFracOnCoil > thisITS.IceFracRemaining:
                    thisITS.IceFracOnCoil = thisITS.IceFracRemaining
        else:
            thisITS.IceFracOnCoil = thisITS.IceFracRemaining

# ===== STUB FUNCTIONS FOR EXTERNAL DEPENDENCIES =====

def PlantUtilities_SetComponentFlowRate(state: EnergyPlusDataProto, mdot: float, inlet_node: int, outlet_node: int, plantLoc: PlantLocationProto) -> None:
    pass

def PlantUtilities_InitComponentNodes(state: EnergyPlusDataProto, min_flow: float, max_flow: float, inlet_node: int, outlet_node: int) -> None:
    pass

def PlantUtilities_ScanPlantLoopsForObject(state: EnergyPlusDataProto, name: str, obj_type: str, plantLoc: PlantLocationProto, errFlag: bool) -> None:
    pass

def PlantUtilities_SafeCopyPlantNode(state: EnergyPlusDataProto, inlet_node: int, outlet_node: int) -> None:
    pass

def Psychrometrics_CPCW(temp: float) -> float:
    return 4180.0

def Curve_GetCurveIndex(state: EnergyPlusDataProto, name: str) -> int:
    return 0

def Curve_CurveValue(state: EnergyPlusDataProto, index: int, x: float, y: float) -> float:
    return 0.0

def Node_GetOnlySingleNode(state: EnergyPlusDataProto, name: str, obj_type: str, obj_name: str) -> int:
    return 0

def Node_TestCompSet(state: EnergyPlusDataProto, obj_type: str, obj_name: str, inlet: str, outlet: str, desc: str) -> None:
    pass

def Util_SameString(str1: str, str2: str) -> bool:
    return str1.upper() == str2.upper()

def Util_FindItemInList(name: str, list_obj: list, attr_name: str) -> int:
    for i, item in enumerate(list_obj):
        if hasattr(item, attr_name) and getattr(item, attr_name) == name:
            return i
    return 0

def SetupOutputVariable(state: EnergyPlusDataProto, var_name: str, unit: str, var_ptr: float, freq: str, store_type: str, obj_name: str) -> None:
    pass

def ShowFatalError(state: EnergyPlusDataProto, msg: str) -> None:
    raise RuntimeError(msg)

def ShowSevereError(state: EnergyPlusDataProto, msg: str) -> None:
    pass

def ShowWarningError(state: EnergyPlusDataProto, msg: str) -> None:
    pass

def ShowContinueError(state: EnergyPlusDataProto, msg: str) -> None:
    pass

def ShowContinueErrorTimeStamp(state: EnergyPlusDataProto, msg: str) -> None:
    pass

def ShowRecurringWarningErrorAtEnd(state: EnergyPlusDataProto, msg: str, err_count: int) -> None:
    pass

def ShowSevereItemNotFound(state: EnergyPlusDataProto, field_name: str, field_value: str) -> None:
    pass

def BaseSizer_reportSizerOutput(state: EnergyPlusDataProto, tank_type: str, tank_name: str, label: str, value: float) -> None:
    pass

def InputProcessor_getNumObjectsFound(state: EnergyPlusDataProto, obj_type: str) -> int:
    return 0

def InputProcessor_getObjectItem(state: EnergyPlusDataProto, obj_type: str, item_num: int) -> tuple:
    return (0, 0, 0, [], [], [], [])

def Sched_GetScheduleAlwaysOn(state: EnergyPlusDataProto) -> Optional[Schedule]:
    return None

def Sched_GetSchedule(state: EnergyPlusDataProto, name: str) -> Optional[Schedule]:
    return None
