from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any
from array import array

# EXTERNAL DEPS (to wire in glue):
# state.dataDemandManager: DemandManagerStateData
# state.dataGlobal: GlobalData
# state.dataHVACGlobal: HVACGlobalData
# state.dataOutputProcessor: OutputProcessorData
# state.dataInputProcessing.inputProcessor: InputProcessor
# state.dataIPShortCut: IPShortCutData
# state.dataExteriorEnergyUse: ExteriorEnergyUseData
# state.dataHeatBal: HeatBalanceData
# state.dataZoneCtrls: ZoneControlsData
# state.dataHeatBalFanSys: HeatBalFanSysData
# state.dataEnvrn: EnvironmentData
# Sched.Schedule: Schedule type
# Sched.GetSchedule(): Schedule retrieval function
# Sched.GetScheduleAlwaysOn(): Always-on schedule function
# GetMeterIndex(): Meter index function
# GetInstantMeterValue(): Meter value function
# OutputProcessor: Output processor module
# Util.makeUPPER(): String uppercase function
# Util.FindItemInList(): Item finding function
# GlobalNames.VerifyUniqueInterObjectName(): Name verification function
# MixedAir.GetOAController(): OA controller retrieval
# MixedAir.OAGetFlowRate(): OA flow rate retrieval
# MixedAir.OASetDemandManagerVentilationState(): OA state setter
# MixedAir.OASetDemandManagerVentilationFlow(): OA flow setter
# ShowSevereError(), ShowFatalError(), ShowContinueError(): Error reporting functions
# getEnumValue(): Enum value lookup function
# Constant.Units, Constant.eResource: Constants

class ManagerType(IntEnum):
    Invalid = -1
    ExtLights = 0
    Lights = 1
    ElecEquip = 2
    Thermostats = 3
    Ventilation = 4
    Num = 5

class ManagePriorityType(IntEnum):
    Invalid = -1
    Sequential = 0
    Optimal = 1
    All = 2
    Num = 3

class ManagerLimit(IntEnum):
    Invalid = -1
    Off = 0
    Fixed = 1
    Variable = 2
    ReductionRatio = 3
    Num = 4

class ManagerSelection(IntEnum):
    Invalid = -1
    All = 0
    Many = 1
    One = 2
    Num = 3

class DemandAction(IntEnum):
    Invalid = -1
    CheckCanReduce = 0
    SetLimit = 1
    ClearLimit = 2
    Num = 3

MANAGER_NAMES_UC = [
    "DEMANDMANAGER:EXTERIORLIGHTS",
    "DEMANDMANAGER:LIGHTS",
    "DEMANDMANAGER:ELECTRICEQUIPMENT",
    "DEMANDMANAGER:THERMOSTATS",
    "DEMANDMANAGER:VENTILATION"
]

MANAGE_PRIORITY_NAMES_UC = ["SEQUENTIAL", "OPTIMAL", "ALL"]

MANAGER_LIMIT_NAMES_UC = ["OFF", "FIXED", "VARIABLE", "REDUCTIONRATIO"]

MANAGER_LIMIT_VENT_NAMES_UC = ["OFF", "FIXEDRATE", "VARIABLE", "REDUCTIONRATIO"]

MANAGER_SELECTION_NAMES_UC = ["ALL", "ROTATEMANY", "ROTATEONE"]

@dataclass
class DemandManagerListData:
    Name: str = ""
    Meter: int = 0
    limitSched: Optional[Any] = None
    SafetyFraction: float = 1.0
    billingSched: Optional[Any] = None
    BillingPeriod: float = 0.0
    peakSched: Optional[Any] = None
    AveragingWindow: int = 1
    History: List[float] = field(default_factory=list)
    ManagerPriority: ManagePriorityType = ManagePriorityType.Invalid
    NumOfManager: int = 0
    Manager: List[int] = field(default_factory=list)
    MeterDemand: float = 0.0
    AverageDemand: float = 0.0
    PeakDemand: float = 0.0
    ScheduledLimit: float = 0.0
    DemandLimit: float = 0.0
    AvoidedDemand: float = 0.0
    OverLimit: float = 0.0
    OverLimitDuration: float = 0.0

@dataclass
class DemandManagerData:
    Name: str = ""
    Type: ManagerType = ManagerType.Invalid
    DemandManagerList: int = 0
    CanReduceDemand: bool = False
    availSched: Optional[Any] = None
    Available: bool = False
    Activate: bool = False
    Active: bool = False
    LimitControl: ManagerLimit = ManagerLimit.Invalid
    SelectionControl: ManagerSelection = ManagerSelection.Invalid
    LimitDuration: int = 0
    ElapsedTime: int = 0
    RotationDuration: int = 0
    ElapsedRotationTime: int = 0
    RotatedLoadNum: int = 0
    LowerLimit: float = 0.0
    UpperLimit: float = 0.0
    NumOfLoads: int = 0
    Load: List[int] = field(default_factory=list)
    FixedRate: float = 0.0
    ReductionRatio: float = 0.0

def ManageDemand(state: Any) -> None:
    if state.dataDemandManager.GetInput and not state.dataGlobal.DoingSizing:
        GetDemandManagerInput(state)
        GetDemandManagerListInput(state)
        state.dataDemandManager.GetInput = False

    if state.dataDemandManager.NumDemandManagerList > 0:
        if state.dataGlobal.WarmupFlag:
            state.dataDemandManager.BeginDemandSim = True
            if state.dataDemandManager.ClearHistory:
                for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                    state.dataDemandManager.DemandManagerList[ListNum - 1].History = [0.0] * state.dataDemandManager.DemandManagerList[ListNum - 1].AveragingWindow
                    state.dataDemandManager.DemandManagerList[ListNum - 1].MeterDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].AverageDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].PeakDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].ScheduledLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].DemandLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].AvoidedDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].OverLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum - 1].OverLimitDuration = 0.0

                for e in state.dataDemandManager.DemandMgr:
                    e.Active = False
                    e.ElapsedTime = 0
                    e.ElapsedRotationTime = 0
                    e.RotatedLoadNum = 0

            state.dataDemandManager.ClearHistory = False

        if not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing:
            if state.dataDemandManager.BeginDemandSim:
                state.dataDemandManager.BeginDemandSim = False
                state.dataDemandManager.ClearHistory = True

            state.dataDemandManager.DemandManagerExtIterations = 0
            state.dataDemandManager.DemandManagerHBIterations = 0
            state.dataDemandManager.DemandManagerHVACIterations = 0

            state.dataDemandManager.firstTime = True
            state.dataDemandManager.ResimExt = False
            state.dataDemandManager.ResimHB = False
            state.dataDemandManager.ResimHVAC = False

            while (state.dataDemandManager.firstTime or state.dataDemandManager.ResimExt or
                   state.dataDemandManager.ResimHB or state.dataDemandManager.ResimHVAC):
                state.dataDemandManager.firstTime = False

                Resimulate(state, state.dataDemandManager.ResimExt, state.dataDemandManager.ResimHB, state.dataDemandManager.ResimHVAC)
                state.dataDemandManager.ResimExt = False
                state.dataDemandManager.ResimHB = False
                state.dataDemandManager.ResimHVAC = False

                SurveyDemandManagers(state)

                for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                    SimulateDemandManagerList(state, ListNum, state.dataDemandManager.ResimExt,
                                            state.dataDemandManager.ResimHB, state.dataDemandManager.ResimHVAC)

                ActivateDemandManagers(state)

                if (state.dataDemandManager.DemandManagerExtIterations +
                    state.dataDemandManager.DemandManagerHBIterations +
                    state.dataDemandManager.DemandManagerHVACIterations > 500):
                    ShowFatalError(state, "Too many DemandManager iterations. (>500)")
                    break

            for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                ReportDemandManagerList(state, ListNum)

def SimulateDemandManagerList(state: Any, ListNum: int, ResimExt: List[bool], ResimHB: List[bool], ResimHVAC: List[bool]) -> None:
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    demandManagerList = state.dataDemandManager.DemandManagerList[ListNum - 1]
    
    demandManagerList.ScheduledLimit = demandManagerList.limitSched.getCurrentVal()
    demandManagerList.DemandLimit = demandManagerList.ScheduledLimit * demandManagerList.SafetyFraction
    
    demandManagerList.MeterDemand = (
        GetInstantMeterValue(state, demandManagerList.Meter, "Zone") / state.dataGlobal.TimeStepZoneSec +
        GetInstantMeterValue(state, demandManagerList.Meter, "System") / TimeStepSysSec
    )
    
    AverageDemand = (demandManagerList.AverageDemand +
                     (demandManagerList.MeterDemand - demandManagerList.History[0]) / demandManagerList.AveragingWindow)
    
    OnPeak = (demandManagerList.peakSched is None) or (demandManagerList.peakSched.getCurrentVal() == 1)
    
    if OnPeak:
        OverLimit = AverageDemand - demandManagerList.DemandLimit
        
        if OverLimit > 0.0:
            if demandManagerList.ManagerPriority == ManagePriorityType.Sequential:
                for MgrNum in range(1, demandManagerList.NumOfManager + 1):
                    demandMgr = state.dataDemandManager.DemandMgr[demandManagerList.Manager[MgrNum - 1] - 1]
                    
                    if demandMgr.CanReduceDemand:
                        demandMgr.Activate = True
                        
                        if demandMgr.Type == ManagerType.ExtLights:
                            ResimExt[0] = True
                        elif demandMgr.Type in (ManagerType.Lights, ManagerType.ElecEquip):
                            ResimHB[0] = True
                            ResimHVAC[0] = True
                        elif demandMgr.Type in (ManagerType.Thermostats, ManagerType.Ventilation):
                            ResimHVAC[0] = True
                        
                        break
            
            elif demandManagerList.ManagerPriority == ManagePriorityType.Optimal:
                pass
            
            elif demandManagerList.ManagerPriority == ManagePriorityType.All:
                for MgrNum in range(1, demandManagerList.NumOfManager + 1):
                    demandMgr = state.dataDemandManager.DemandMgr[demandManagerList.Manager[MgrNum - 1] - 1]
                    
                    if demandMgr.CanReduceDemand:
                        demandMgr.Activate = True
                        
                        if demandMgr.Type == ManagerType.ExtLights:
                            ResimExt[0] = True
                        elif demandMgr.Type in (ManagerType.Lights, ManagerType.ElecEquip):
                            ResimHB[0] = True
                            ResimHVAC[0] = True
                        elif demandMgr.Type in (ManagerType.Thermostats, ManagerType.Ventilation):
                            ResimHVAC[0] = True

def GetDemandManagerListInput(state: Any) -> None:
    s_ip = state.dataInputProcessing.inputProcessor
    cCurrentModuleObject = "DemandManagerAssignmentList"
    
    state.dataDemandManager.NumDemandManagerList = s_ip.getNumObjectsFound(state, cCurrentModuleObject)
    
    if state.dataDemandManager.NumDemandManagerList > 0:
        state.dataDemandManager.DemandManagerList = [DemandManagerListData() for _ in range(state.dataDemandManager.NumDemandManagerList)]
        
        ErrorsFound = False
        s_ipsc = state.dataIPShortCut
        
        for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
            thisDemandMgrList = state.dataDemandManager.DemandManagerList[ListNum - 1]
            
            NumAlphas = 0
            NumNums = 0
            IOStat = 0
            cAlphaArgs = [""] * 20
            rNumericArgs = [0.0] * 10
            lAlphaFieldBlanks = [False] * 20
            cAlphaFieldNames = [""] * 20
            cNumericFieldNames = [""] * 10
            
            s_ip.getObjectItem(state, cCurrentModuleObject, ListNum, cAlphaArgs, NumAlphas,
                             rNumericArgs, NumNums, IOStat)
            
            routineName = "GetDemandManagerListInput"
            
            thisDemandMgrList.Name = cAlphaArgs[0]
            
            thisDemandMgrList.Meter = GetMeterIndex(state, cAlphaArgs[1])
            
            if thisDemandMgrList.Meter == -1:
                ShowSevereError(state, f"Invalid {cAlphaFieldNames[1]} = {cAlphaArgs[1]}")
                ShowContinueError(state, f"Entered in {cCurrentModuleObject} = {thisDemandMgrList.Name}")
                ErrorsFound = True
            else:
                meter_resource = state.dataOutputProcessor.meters[thisDemandMgrList.Meter - 1].resource
                if meter_resource not in (0, 10):
                    ShowSevereError(state,
                        f"{cCurrentModuleObject} = \"{thisDemandMgrList.Name}\" invalid value {cAlphaFieldNames[1]} = \"{cAlphaArgs[1]}\".")
                    ShowContinueError(state, "Only Electricity and ElectricityNet meters are currently allowed.")
                    ErrorsFound = True
            
            if not lAlphaFieldBlanks[2]:
                thisDemandMgrList.limitSched = GetSchedule(state, cAlphaArgs[2])
                if thisDemandMgrList.limitSched is None:
                    ShowSevereError(state, f"Schedule not found: {cAlphaArgs[2]}")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"Blank field: {cAlphaFieldNames[2]}")
                ErrorsFound = True
            
            thisDemandMgrList.SafetyFraction = rNumericArgs[0]
            
            if not lAlphaFieldBlanks[3]:
                thisDemandMgrList.billingSched = GetSchedule(state, cAlphaArgs[3])
                if thisDemandMgrList.billingSched is None:
                    ShowSevereError(state, f"Schedule not found: {cAlphaArgs[3]}")
                    ErrorsFound = True
            
            if not lAlphaFieldBlanks[4]:
                thisDemandMgrList.peakSched = GetSchedule(state, cAlphaArgs[4])
                if thisDemandMgrList.peakSched is None:
                    ShowSevereError(state, f"Schedule not found: {cAlphaArgs[4]}")
                    ErrorsFound = True
            
            thisDemandMgrList.AveragingWindow = max(int(rNumericArgs[1] / state.dataGlobal.MinutesInTimeStep), 1)
            thisDemandMgrList.History = [0.0] * thisDemandMgrList.AveragingWindow
            
            thisDemandMgrList.ManagerPriority = getEnumValue(MANAGE_PRIORITY_NAMES_UC, Util.makeUPPER(cAlphaArgs[5]))
            if thisDemandMgrList.ManagerPriority == ManagePriorityType.Invalid:
                ErrorsFound = True
            
            thisDemandMgrList.NumOfManager = int((NumAlphas - 6) / 2.0)
            
            if thisDemandMgrList.NumOfManager > 0:
                thisDemandMgrList.Manager = [0] * thisDemandMgrList.NumOfManager
                for MgrNum in range(1, thisDemandMgrList.NumOfManager + 1):
                    MgrType = getEnumValue(MANAGER_NAMES_UC, Util.makeUPPER(cAlphaArgs[MgrNum * 2 + 4]))
                    if MgrType != ManagerType.Invalid:
                        thisManager = Util.FindItemInList(cAlphaArgs[MgrNum * 2 + 5], state.dataDemandManager.DemandMgr)
                        if thisManager == 0:
                            ShowSevereError(state,
                                f"{cCurrentModuleObject} = \"{thisDemandMgrList.Name}\" invalid {cAlphaFieldNames[MgrNum * 2 + 5]} = \"{cAlphaArgs[MgrNum * 2 + 5]}\" not found.")
                            ErrorsFound = True
                        else:
                            thisDemandMgrList.Manager[MgrNum - 1] = thisManager
                    else:
                        ShowSevereError(state,
                            f"{cCurrentModuleObject} = \"{thisDemandMgrList.Name}\" invalid value {cAlphaFieldNames[MgrNum * 2 + 4]} = \"{cAlphaArgs[MgrNum * 2 + 4]}\".")
                        ErrorsFound = True
        
        if ErrorsFound:
            ShowFatalError(state, f"Errors found in processing input for {cCurrentModuleObject}.")

def GetDemandManagerInput(state: Any) -> None:
    s_ip = state.dataInputProcessing.inputProcessor
    
    MaxAlphas = 0
    MaxNums = 0
    
    CurrentModuleObject = "DemandManager:ExteriorLights"
    NumDemandMgrExtLights = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrExtLights > 0:
        MaxAlphas = max(MaxAlphas, 20)
        MaxNums = max(MaxNums, 10)
    
    CurrentModuleObject = "DemandManager:Lights"
    NumDemandMgrLights = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrLights > 0:
        MaxAlphas = max(MaxAlphas, 20)
        MaxNums = max(MaxNums, 10)
    
    CurrentModuleObject = "DemandManager:ElectricEquipment"
    NumDemandMgrElecEquip = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrElecEquip > 0:
        MaxAlphas = max(MaxAlphas, 20)
        MaxNums = max(MaxNums, 10)
    
    CurrentModuleObject = "DemandManager:Thermostats"
    NumDemandMgrThermostats = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrThermostats > 0:
        MaxAlphas = max(MaxAlphas, 20)
        MaxNums = max(MaxNums, 10)
    
    CurrentModuleObject = "DemandManager:Ventilation"
    NumDemandMgrVentilation = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrVentilation > 0:
        MaxAlphas = max(MaxAlphas, 20)
        MaxNums = max(MaxNums, 10)
    
    state.dataDemandManager.NumDemandMgr = (NumDemandMgrExtLights + NumDemandMgrLights +
                                           NumDemandMgrElecEquip + NumDemandMgrThermostats +
                                           NumDemandMgrVentilation)
    
    if state.dataDemandManager.NumDemandMgr > 0:
        state.dataDemandManager.DemandMgr = [DemandManagerData() for _ in range(state.dataDemandManager.NumDemandMgr)]
        state.dataDemandManager.UniqueDemandMgrNames = {}
        
        s_ipsc = state.dataIPShortCut
        ErrorsFound = False
        
        StartIndex = 0
        EndIndex = NumDemandMgrExtLights
        
        CurrentModuleObject = "DemandManager:ExteriorLights"
        for MgrNum in range(StartIndex + 1, EndIndex + 1):
            demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
            
            AlphArray = [""] * MaxAlphas
            NumArray = [0.0] * MaxNums
            NumAlphas = 0
            NumNums = 0
            
            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex, AlphArray, NumAlphas, NumArray, NumNums, 0)
            
            demandMgr.Name = AlphArray[0]
            demandMgr.Type = ManagerType.ExtLights
            
            demandMgr.availSched = GetScheduleAlwaysOn(state) if not AlphArray[1] else GetSchedule(state, AlphArray[1])
            
            demandMgr.LimitControl = getEnumValue(MANAGER_LIMIT_NAMES_UC, Util.makeUPPER(AlphArray[2]))
            if demandMgr.LimitControl == ManagerLimit.Invalid:
                ErrorsFound = True
            
            demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep if NumArray[0] == 0.0 else int(NumArray[0])
            demandMgr.LowerLimit = NumArray[1]
            
            demandMgr.SelectionControl = getEnumValue(MANAGER_SELECTION_NAMES_UC, Util.makeUPPER(AlphArray[3]))
            if demandMgr.SelectionControl == ManagerSelection.Invalid:
                ErrorsFound = True
            
            demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep if NumArray[3] == 0.0 else int(NumArray[3])
            
            demandMgr.NumOfLoads = NumAlphas - 4
            if demandMgr.NumOfLoads > 0:
                demandMgr.Load = [0] * demandMgr.NumOfLoads
                for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                    LoadPtr = Util.FindItemInList(Util.makeUPPER(AlphArray[LoadNum + 3]), state.dataExteriorEnergyUse.ExteriorLights)
                    if LoadPtr > 0:
                        demandMgr.Load[LoadNum - 1] = LoadPtr
                    else:
                        ShowSevereError(state, f"{}=\"{}\" invalid {}=\"{}\" not found.", CurrentModuleObject, AlphArray[0], f"Load {LoadNum}", AlphArray[LoadNum + 3])
                        ErrorsFound = True
            else:
                ShowSevereError(state, f"{}=\"{}\" invalid value for number of loads.", CurrentModuleObject, AlphArray[0])
                ErrorsFound = True
        
        StartIndex = EndIndex
        EndIndex += NumDemandMgrLights
        
        CurrentModuleObject = "DemandManager:Lights"
        for MgrNum in range(StartIndex + 1, EndIndex + 1):
            demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
            
            AlphArray = [""] * MaxAlphas
            NumArray = [0.0] * MaxNums
            NumAlphas = 0
            NumNums = 0
            
            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex, AlphArray, NumAlphas, NumArray, NumNums, 0)
            
            demandMgr.Name = AlphArray[0]
            demandMgr.Type = ManagerType.Lights
            
            demandMgr.availSched = GetScheduleAlwaysOn(state) if not AlphArray[1] else GetSchedule(state, AlphArray[1])
            
            demandMgr.LimitControl = getEnumValue(MANAGER_LIMIT_NAMES_UC, Util.makeUPPER(AlphArray[2]))
            if demandMgr.LimitControl == ManagerLimit.Invalid:
                ErrorsFound = True
            
            demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep if NumArray[0] == 0.0 else int(NumArray[0])
            demandMgr.LowerLimit = NumArray[1]
            
            demandMgr.SelectionControl = getEnumValue(MANAGER_SELECTION_NAMES_UC, Util.makeUPPER(AlphArray[3]))
            if demandMgr.SelectionControl == ManagerSelection.Invalid:
                ErrorsFound = True
            
            demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep if NumArray[3] == 0.0 else int(NumArray[3])
            
            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 3):
                LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataInternalHeatGains.lightsObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataInternalHeatGains.lightsObjects[LoadPtr - 1].numOfSpaces
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataHeatBal.Lights)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, f"{}=\"{}\" invalid {}=\"{}\" not found.", CurrentModuleObject, AlphArray[0], f"Load {LoadNum}", AlphArray[LoadNum + 3])
                        ErrorsFound = True
            
            if demandMgr.NumOfLoads > 0:
                demandMgr.Load = [0] * demandMgr.NumOfLoads
                LoadNum = 0
                for Item in range(1, NumAlphas - 3):
                    LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataInternalHeatGains.lightsObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataInternalHeatGains.lightsObjects[LoadPtr - 1].numOfSpaces + 1):
                            demandMgr.Load[LoadNum] = state.dataInternalHeatGains.lightsObjects[LoadPtr - 1].spaceStartPtr + Item1 - 2
                            LoadNum += 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataHeatBal.Lights)
                        if LoadPtr > 0:
                            demandMgr.Load[LoadNum] = LoadPtr
                            LoadNum += 1
            else:
                ShowSevereError(state, f"{}=\"{}\" invalid value for number of loads.", CurrentModuleObject, AlphArray[0])
                ErrorsFound = True
        
        StartIndex = EndIndex
        EndIndex += NumDemandMgrElecEquip
        
        CurrentModuleObject = "DemandManager:ElectricEquipment"
        for MgrNum in range(StartIndex + 1, EndIndex + 1):
            demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
            
            AlphArray = [""] * MaxAlphas
            NumArray = [0.0] * MaxNums
            NumAlphas = 0
            NumNums = 0
            
            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex, AlphArray, NumAlphas, NumArray, NumNums, 0)
            
            demandMgr.Name = AlphArray[0]
            demandMgr.Type = ManagerType.ElecEquip
            
            demandMgr.availSched = GetScheduleAlwaysOn(state) if not AlphArray[1] else GetSchedule(state, AlphArray[1])
            
            demandMgr.LimitControl = getEnumValue(MANAGER_LIMIT_NAMES_UC, Util.makeUPPER(AlphArray[2]))
            if demandMgr.LimitControl == ManagerLimit.Invalid:
                ErrorsFound = True
            
            demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep if NumArray[0] == 0.0 else int(NumArray[0])
            demandMgr.LowerLimit = NumArray[1]
            
            demandMgr.SelectionControl = getEnumValue(MANAGER_SELECTION_NAMES_UC, Util.makeUPPER(AlphArray[3]))
            if demandMgr.SelectionControl == ManagerSelection.Invalid:
                ErrorsFound = True
            
            demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep if NumArray[3] == 0.0 else int(NumArray[3])
            
            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 3):
                LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataInternalHeatGains.zoneElectricObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataInternalHeatGains.zoneElectricObjects[LoadPtr - 1].numOfSpaces
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataHeatBal.ZoneElectric)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, f"{}=\"{}\" invalid {}=\"{}\" not found.", CurrentModuleObject, AlphArray[0], f"Load {LoadNum}", AlphArray[LoadNum + 3])
                        ErrorsFound = True
            
            if demandMgr.NumOfLoads > 0:
                demandMgr.Load = [0] * demandMgr.NumOfLoads
                LoadNum = 0
                for Item in range(1, NumAlphas - 3):
                    LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataInternalHeatGains.zoneElectricObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataInternalHeatGains.zoneElectricObjects[LoadPtr - 1].numOfSpaces + 1):
                            demandMgr.Load[LoadNum] = state.dataInternalHeatGains.zoneElectricObjects[LoadPtr - 1].spaceStartPtr + Item1 - 2
                            LoadNum += 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataHeatBal.ZoneElectric)
                        if LoadPtr > 0:
                            demandMgr.Load[LoadNum] = LoadPtr
                            LoadNum += 1
            else:
                ShowSevereError(state, f"{}=\"{}\" invalid value for number of loads.", CurrentModuleObject, AlphArray[0])
                ErrorsFound = True
        
        StartIndex = EndIndex
        EndIndex += NumDemandMgrThermostats
        
        CurrentModuleObject = "DemandManager:Thermostats"
        for MgrNum in range(StartIndex + 1, EndIndex + 1):
            demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
            
            AlphArray = [""] * MaxAlphas
            NumArray = [0.0] * MaxNums
            NumAlphas = 0
            NumNums = 0
            
            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex, AlphArray, NumAlphas, NumArray, NumNums, 0)
            
            demandMgr.Name = AlphArray[0]
            demandMgr.Type = ManagerType.Thermostats
            
            demandMgr.availSched = GetScheduleAlwaysOn(state) if not AlphArray[1] else GetSchedule(state, AlphArray[1])
            
            demandMgr.LimitControl = getEnumValue(MANAGER_LIMIT_NAMES_UC, Util.makeUPPER(AlphArray[2]))
            if demandMgr.LimitControl == ManagerLimit.Invalid:
                ErrorsFound = True
            
            demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep if NumArray[0] == 0.0 else int(NumArray[0])
            demandMgr.LowerLimit = NumArray[1]
            demandMgr.UpperLimit = NumArray[2]
            
            if demandMgr.LowerLimit > demandMgr.UpperLimit:
                ShowSevereError(state, f"Invalid input for {CurrentModuleObject} = {AlphArray[0]}")
                ErrorsFound = True
            
            demandMgr.SelectionControl = getEnumValue(MANAGER_SELECTION_NAMES_UC, Util.makeUPPER(AlphArray[3]))
            if demandMgr.SelectionControl == ManagerSelection.Invalid:
                ErrorsFound = True
            
            demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep if NumArray[4] == 0.0 else int(NumArray[4])
            
            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 3):
                LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataZoneCtrls.TStatObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataZoneCtrls.TStatObjects[LoadPtr - 1].NumOfZones
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 3], state.dataZoneCtrls.TempControlledZone)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, f"{}=\"{}\" invalid {}=\"{}\" not found.", CurrentModuleObject, AlphArray[0], f"Load {LoadNum}", AlphArray[LoadNum + 3])
                        ErrorsFound = True
            
            if demandMgr.NumOfLoads > 0:
                demandMgr.Load = [0] * demandMgr.NumOfLoads
                LoadNum = 0
                for Item in range(1, NumAlphas - 3):
                    LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataZoneCtrls.TStatObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataZoneCtrls.TStatObjects[LoadPtr - 1].NumOfZones + 1):
                            demandMgr.Load[LoadNum] = state.dataZoneCtrls.TStatObjects[LoadPtr - 1].TempControlledZoneStartPtr + Item1 - 2
                            LoadNum += 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 3], state.dataZoneCtrls.TempControlledZone)
                        if LoadPtr > 0:
                            demandMgr.Load[LoadNum] = LoadPtr
                            LoadNum += 1
            else:
                ShowSevereError(state, f"{}=\"{}\" invalid value for number of loads.", CurrentModuleObject, AlphArray[0])
                ErrorsFound = True
        
        StartIndex = EndIndex
        EndIndex += NumDemandMgrVentilation
        
        CurrentModuleObject = "DemandManager:Ventilation"
        for MgrNum in range(StartIndex + 1, EndIndex + 1):
            demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
            
            AlphArray = [""] * MaxAlphas
            NumArray = [0.0] * MaxNums
            NumAlphas = 0
            NumNums = 0
            
            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex, AlphArray, NumAlphas, NumArray, NumNums, 0)
            
            demandMgr.Name = AlphArray[0]
            demandMgr.Type = ManagerType.Ventilation
            
            demandMgr.availSched = GetScheduleAlwaysOn(state) if not AlphArray[1] else GetSchedule(state, AlphArray[1])
            
            demandMgr.LimitControl = getEnumValue(MANAGER_LIMIT_VENT_NAMES_UC, Util.makeUPPER(AlphArray[2]))
            if demandMgr.LimitControl == ManagerLimit.Invalid:
                ErrorsFound = True
            
            demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep if NumArray[0] == 0.0 else int(NumArray[0])
            
            if demandMgr.LimitControl == ManagerLimit.Fixed:
                demandMgr.FixedRate = NumArray[1]
            if demandMgr.LimitControl == ManagerLimit.ReductionRatio:
                demandMgr.ReductionRatio = NumArray[2]
            
            demandMgr.LowerLimit = NumArray[3]
            
            demandMgr.SelectionControl = getEnumValue(MANAGER_SELECTION_NAMES_UC, Util.makeUPPER(AlphArray[3]))
            if demandMgr.SelectionControl == ManagerSelection.Invalid:
                ErrorsFound = True
            
            demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep if NumArray[4] == 0.0 else int(NumArray[4])
            
            AlphaShift = 4
            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - AlphaShift):
                LoadPtr = MixedAir.GetOAController(state, AlphArray[LoadNum + AlphaShift - 1])
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += 1
                else:
                    ShowSevereError(state, f"{}=\"{}\" invalid {}=\"{}\" not found.", CurrentModuleObject, AlphArray[0], f"Load {LoadNum}", AlphArray[LoadNum + AlphaShift - 1])
                    ErrorsFound = True
            
            if demandMgr.NumOfLoads > 0:
                demandMgr.Load = [0] * demandMgr.NumOfLoads
                for LoadNum in range(1, NumAlphas - AlphaShift):
                    LoadPtr = MixedAir.GetOAController(state, AlphArray[LoadNum + AlphaShift - 1])
                    if LoadPtr > 0:
                        demandMgr.Load[LoadNum - 1] = LoadPtr
            else:
                ShowSevereError(state, f"{}=\"{}\" invalid value for number of loads.", CurrentModuleObject, AlphArray[0])
                ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing input for demand managers. Preceding condition causes termination.")

def SurveyDemandManagers(state: Any) -> None:
    CanReduceDemand = [False]
    
    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
        
        demandMgr.CanReduceDemand = False
        
        if not demandMgr.Available:
            continue
        if demandMgr.LimitControl == ManagerLimit.Off:
            continue
        if demandMgr.Active:
            continue
        
        for LoadNum in range(1, demandMgr.NumOfLoads + 1):
            LoadPtr = demandMgr.Load[LoadNum - 1]
            
            LoadInterface(state, DemandAction.CheckCanReduce, MgrNum, LoadPtr, CanReduceDemand)
            
            if CanReduceDemand[0]:
                demandMgr.CanReduceDemand = True
                break

def ActivateDemandManagers(state: Any) -> None:
    CanReduceDemand = [False]
    
    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
        
        if demandMgr.Activate:
            demandMgr.Activate = False
            demandMgr.Active = True
            
            if demandMgr.SelectionControl == ManagerSelection.All:
                for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                    LoadPtr = demandMgr.Load[LoadNum - 1]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
            
            elif demandMgr.SelectionControl == ManagerSelection.Many:
                if demandMgr.NumOfLoads > 1:
                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum - 1]
                        LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
                    
                    RotatedLoadNum = demandMgr.RotatedLoadNum + 1
                    if RotatedLoadNum > demandMgr.NumOfLoads:
                        RotatedLoadNum = 1
                    demandMgr.RotatedLoadNum = RotatedLoadNum
                    
                    LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                    LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                else:
                    LoadPtr = demandMgr.Load[0]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
            
            elif demandMgr.SelectionControl == ManagerSelection.One:
                if demandMgr.NumOfLoads > 1:
                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum - 1]
                        LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                    
                    RotatedLoadNum = demandMgr.RotatedLoadNum + 1
                    if RotatedLoadNum > demandMgr.NumOfLoads:
                        RotatedLoadNum = 1
                    demandMgr.RotatedLoadNum = RotatedLoadNum
                    
                    LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
                else:
                    LoadPtr = demandMgr.Load[0]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

def UpdateDemandManagers(state: Any) -> None:
    CanReduceDemand = [False]
    
    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
        
        Available = demandMgr.availSched.getCurrentVal() > 0.0
        demandMgr.Available = Available
        
        if Available:
            if demandMgr.Active:
                demandMgr.ElapsedTime += state.dataGlobal.MinutesInTimeStep
                
                if demandMgr.ElapsedTime >= demandMgr.LimitDuration:
                    demandMgr.ElapsedTime = 0
                    demandMgr.ElapsedRotationTime = 0
                    demandMgr.Active = False
                    
                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum - 1]
                        LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                
                else:
                    if demandMgr.SelectionControl == ManagerSelection.All:
                        pass
                    
                    elif demandMgr.SelectionControl == ManagerSelection.Many:
                        demandMgr.ElapsedRotationTime += state.dataGlobal.MinutesInTimeStep
                        
                        if demandMgr.ElapsedRotationTime >= demandMgr.RotationDuration:
                            demandMgr.ElapsedRotationTime = 0
                            
                            if demandMgr.NumOfLoads > 1:
                                RotatedLoadNum = demandMgr.RotatedLoadNum
                                LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                                LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
                                
                                RotatedLoadNum += 1
                                if RotatedLoadNum > demandMgr.NumOfLoads:
                                    RotatedLoadNum = 1
                                demandMgr.RotatedLoadNum = RotatedLoadNum
                                
                                LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                    
                    elif demandMgr.SelectionControl == ManagerSelection.One:
                        demandMgr.ElapsedRotationTime += state.dataGlobal.MinutesInTimeStep
                        
                        if demandMgr.ElapsedRotationTime >= demandMgr.RotationDuration:
                            demandMgr.ElapsedRotationTime = 0
                            
                            if demandMgr.NumOfLoads > 1:
                                RotatedLoadNum = demandMgr.RotatedLoadNum
                                LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                                
                                RotatedLoadNum += 1
                                if RotatedLoadNum > demandMgr.NumOfLoads:
                                    RotatedLoadNum = 1
                                demandMgr.RotatedLoadNum = RotatedLoadNum
                                
                                LoadPtr = demandMgr.Load[RotatedLoadNum - 1]
                                LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
        else:
            demandMgr.Active = False
            
            for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                LoadPtr = demandMgr.Load[LoadNum - 1]
                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

def ReportDemandManagerList(state: Any, ListNum: int) -> None:
    demandManagerList = state.dataDemandManager.DemandManagerList[ListNum - 1]
    
    BillingPeriod = state.dataEnvrn.Month if demandManagerList.billingSched is None else demandManagerList.billingSched.getCurrentVal()
    
    if demandManagerList.BillingPeriod != BillingPeriod:
        demandManagerList.PeakDemand = 0.0
        demandManagerList.OverLimitDuration = 0.0
        demandManagerList.BillingPeriod = BillingPeriod
    
    AveragingWindow = demandManagerList.AveragingWindow
    demandManagerList.AverageDemand += (demandManagerList.MeterDemand - demandManagerList.History[0]) / AveragingWindow
    
    for Item in range(AveragingWindow - 1):
        demandManagerList.History[Item] = demandManagerList.History[Item + 1]
    demandManagerList.History[AveragingWindow - 1] = demandManagerList.MeterDemand
    
    OnPeak = (demandManagerList.peakSched is None) or (demandManagerList.peakSched.getCurrentVal() == 1)
    
    if OnPeak:
        demandManagerList.PeakDemand = max(demandManagerList.AverageDemand, demandManagerList.PeakDemand)
        
        OverLimit = demandManagerList.AverageDemand - demandManagerList.ScheduledLimit
        if OverLimit > 0.0:
            demandManagerList.OverLimit = OverLimit
            demandManagerList.OverLimitDuration += (state.dataGlobal.MinutesInTimeStep / 60.0)
        else:
            demandManagerList.OverLimit = 0.0
    else:
        demandManagerList.OverLimit = 0.0

def LoadInterface(state: Any, Action: DemandAction, MgrNum: int, LoadPtr: int, CanReduceDemand: List[bool]) -> None:
    demandMgr = state.dataDemandManager.DemandMgr[MgrNum - 1]
    
    CanReduceDemand[0] = False
    
    if demandMgr.Type == ManagerType.ExtLights:
        LowestPower = state.dataExteriorEnergyUse.ExteriorLights[LoadPtr - 1].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataExteriorEnergyUse.ExteriorLights[LoadPtr - 1].Power > LowestPower:
                CanReduceDemand[0] = True
        elif Action == DemandAction.SetLimit:
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr - 1].ManageDemand = True
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr - 1].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr - 1].ManageDemand = False
    
    elif demandMgr.Type == ManagerType.Lights:
        LowestPower = state.dataHeatBal.Lights[LoadPtr - 1].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataHeatBal.Lights[LoadPtr - 1].Power > LowestPower:
                CanReduceDemand[0] = True
        elif Action == DemandAction.SetLimit:
            state.dataHeatBal.Lights[LoadPtr - 1].ManageDemand = True
            state.dataHeatBal.Lights[LoadPtr - 1].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataHeatBal.Lights[LoadPtr - 1].ManageDemand = False
    
    elif demandMgr.Type == ManagerType.ElecEquip:
        LowestPower = state.dataHeatBal.ZoneElectric[LoadPtr - 1].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataHeatBal.ZoneElectric[LoadPtr - 1].Power > LowestPower:
                CanReduceDemand[0] = True
        elif Action == DemandAction.SetLimit:
            state.dataHeatBal.ZoneElectric[LoadPtr - 1].ManageDemand = True
            state.dataHeatBal.ZoneElectric[LoadPtr - 1].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataHeatBal.ZoneElectric[LoadPtr - 1].ManageDemand = False
    
    elif demandMgr.Type == ManagerType.Thermostats:
        tempZone = state.dataZoneCtrls.TempControlledZone[LoadPtr - 1]
        zoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[tempZone.ActualZoneNum - 1]
        if Action == DemandAction.CheckCanReduce:
            if zoneTstatSetpt.setptLo > demandMgr.LowerLimit or zoneTstatSetpt.setptHi < demandMgr.UpperLimit:
                CanReduceDemand[0] = True
        elif Action == DemandAction.SetLimit:
            tempZone.ManageDemand = True
            tempZone.HeatingResetLimit = demandMgr.LowerLimit
            tempZone.CoolingResetLimit = demandMgr.UpperLimit
        elif Action == DemandAction.ClearLimit:
            tempZone.ManageDemand = False
        
        if state.dataZoneCtrls.NumComfortControlledZones > 0:
            comfortZone = state.dataZoneCtrls.ComfortControlledZone[LoadPtr - 1]
            if state.dataHeatBalFanSys.ComfortControlType[comfortZone.ActualZoneNum - 1] != 0:
                cmftzoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[comfortZone.ActualZoneNum - 1]
                if Action == DemandAction.CheckCanReduce:
                    if cmftzoneTstatSetpt.setptLo > demandMgr.LowerLimit or cmftzoneTstatSetpt.setptHi < demandMgr.UpperLimit:
                        CanReduceDemand[0] = True
                elif Action == DemandAction.SetLimit:
                    comfortZone.ManageDemand = True
                    comfortZone.HeatingResetLimit = demandMgr.LowerLimit
                    comfortZone.CoolingResetLimit = demandMgr.UpperLimit
                elif Action == DemandAction.ClearLimit:
                    comfortZone.ManageDemand = False
    
    elif demandMgr.Type == ManagerType.Ventilation:
        FlowRate = MixedAir.OAGetFlowRate(state, LoadPtr)
        if Action == DemandAction.CheckCanReduce:
            CanReduceDemand[0] = True
        elif Action == DemandAction.SetLimit:
            MixedAir.OASetDemandManagerVentilationState(state, LoadPtr, True)
            if demandMgr.LimitControl == ManagerLimit.Fixed:
                MixedAir.OASetDemandManagerVentilationFlow(state, LoadPtr, demandMgr.FixedRate)
            elif demandMgr.LimitControl == ManagerLimit.ReductionRatio:
                DemandRate = FlowRate * demandMgr.ReductionRatio
                MixedAir.OASetDemandManagerVentilationFlow(state, LoadPtr, DemandRate)
        elif Action == DemandAction.ClearLimit:
            MixedAir.OASetDemandManagerVentilationState(state, LoadPtr, False)

def InitDemandManagers(state: Any) -> None:
    if state.dataDemandManager.GetInput:
        GetDemandManagerInput(state)
        GetDemandManagerListInput(state)
        state.dataDemandManager.GetInput = False

def Resimulate(state: Any, ResimExt: Any, ResimHB: Any, ResimHVAC: Any) -> None:
    pass

def GetMeterIndex(state: Any, MeterName: str) -> int:
    return -1

def GetInstantMeterValue(state: Any, MeterNum: int, TimeStepType: str) -> float:
    return 0.0

def GetSchedule(state: Any, ScheduleName: str) -> Optional[Any]:
    return None

def GetScheduleAlwaysOn(state: Any) -> Optional[Any]:
    return None

def getEnumValue(names: List[str], value: str) -> int:
    for i, name in enumerate(names):
        if name == value:
            return i
    return -1

def ShowSevereError(state: Any, msg: str) -> None:
    pass

def ShowFatalError(state: Any, msg: str) -> None:
    pass

def ShowContinueError(state: Any, msg: str) -> None:
    pass

class Util:
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()
    
    @staticmethod
    def FindItemInList(Name: str, List: Any) -> int:
        return 0

class MixedAir:
    @staticmethod
    def GetOAController(state: Any, ControllerName: str) -> int:
        return 0
    
    @staticmethod
    def OAGetFlowRate(state: Any, ControllerNum: int) -> float:
        return 0.0
    
    @staticmethod
    def OASetDemandManagerVentilationState(state: Any, ControllerNum: int, OnOff: bool) -> None:
        pass
    
    @staticmethod
    def OASetDemandManagerVentilationFlow(state: Any, ControllerNum: int, FlowRate: float) -> None:
        pass
