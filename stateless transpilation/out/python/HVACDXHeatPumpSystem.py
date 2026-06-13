# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from dataclasses import dataclass, field
from typing import Optional, List, Any, Callable, Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested dataHVACDXHeatPumpSys, dataLoopNodes, dataGlobal, etc.
# - HVAC module: CoilType enum, FanOp enum, CompressorOp enum, CtrlVarType enum, TempControlTol constant
# - Util module: FindItemInList function
# - DXCoils module: SimDXCoil, GetCoilInletNode, GetCoilOutletNode, SetCoilSystemHeatingDXFlag, CalcDXHeatingCoil
# - VariableSpeedCoils module: SimVariableSpeedCoils, GetCoilInletNodeVariableSpeed, GetCoilOutletNodeVariableSpeed, SetCoilSystemHeatingDXFlag
# - Psychrometrics module: PsyHFnTdbW, PsyTdpFnWPb
# - General module: SolveRoot
# - Sched module: GetScheduleAlwaysOn, GetSchedule, Schedule class with getCurrentVal()
# - Node module: SetUpCompSets, TestCompSet
# - Error/warning functions: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowSevereItemNotFound, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd
# - ValidateComponent, ErrorObjectHeader classes
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType constants
# - EMSManager: CheckIfNodeSetPointManagedByEMS
# - FaultsManager: state.dataFaultsMgr.FaultsCoilSATSensor array with CalFaultOffsetAct method

MIN_AIR_MASS_FLOW = 0.001


@dataclass
class DXHeatPumpSystemStruct:
    """Structure for DX Heat Pump System data"""
    DXHeatPumpSystemType: str = ""
    Name: str = ""
    availSched: Optional[Any] = None
    coilType: int = -1  # HVAC.CoilType.Invalid
    HeatPumpCoilName: str = ""
    HeatPumpCoilIndex: int = 0
    DXHeatPumpCoilInletNodeNum: int = 0
    DXHeatPumpCoilOutletNodeNum: int = 0
    DXSystemControlNodeNum: int = 0
    DesiredOutletTemp: float = 0.0
    PartLoadFrac: float = 0.0
    SpeedRatio: float = 0.0
    CycRatio: float = 0.0
    fanOp: int = -1  # HVAC.FanOp.Invalid
    DXCoilSensPLRIter: int = 0
    DXCoilSensPLRIterIndex: int = 0
    DXCoilSensPLRFail: int = 0
    DXCoilSensPLRFailIndex: int = 0
    OAUnitSetTemp: float = 0.0
    SpeedNum: int = 0
    FaultyCoilSATFlag: bool = False
    FaultyCoilSATIndex: int = 0
    FaultyCoilSATOffset: float = 0.0


@dataclass
class HVACDXHeatPumpSystemData:
    """Global data for HVAC DX Heat Pump System module"""
    NumDXHeatPumpSystems: int = 0
    EconomizerFlag: bool = False
    GetInputFlag: bool = True
    CheckEquipName: List[bool] = field(default_factory=list)
    DXHeatPumpSystem: List[DXHeatPumpSystemStruct] = field(default_factory=list)
    
    QZnReq: float = 0.001
    QLatReq: float = 0.0
    OnOffAirFlowRatio: float = 1.0
    ErrorsFound: bool = False
    TotalArgs: int = 0
    MySetPointCheckFlag: bool = True
    SpeedNum: int = 1
    QZnReqr: float = 0.001
    QLatReqr: float = 0.0
    OnandOffAirFlowRatio: float = 1.0
    SpeedRatio: float = 0.0
    SpeedNumber: int = 1
    QZoneReq: float = 0.001
    QLatentReq: float = 0.0
    AirFlowOnOffRatio: float = 1.0
    SpeedPartLoadRatio: float = 1.0

    def clear_state(self) -> None:
        self.GetInputFlag = True
        self.NumDXHeatPumpSystems = 0
        self.EconomizerFlag = False
        self.CheckEquipName.clear()
        self.DXHeatPumpSystem.clear()
        self.QZnReq = 0.001
        self.QLatReq = 0.0
        self.OnOffAirFlowRatio = 1.0
        self.ErrorsFound = False
        self.TotalArgs = 0
        self.MySetPointCheckFlag = True
        self.SpeedNum = 1
        self.QZnReqr = 0.001
        self.QLatReqr = 0.0
        self.OnandOffAirFlowRatio = 1.0
        self.SpeedRatio = 0.0
        self.SpeedNumber = 1
        self.QZoneReq = 0.001
        self.QLatentReq = 0.0
        self.AirFlowOnOffRatio = 1.0
        self.SpeedPartLoadRatio = 1.0


def SimDXHeatPumpSystem(
    state: Any,
    DXHeatPumpSystemName: str,
    FirstHVACIteration: bool,
    AirLoopNum: int,
    CompIndex: int,
    OAUnitNum: Optional[int] = None,
    OAUCoilOutTemp: Optional[float] = None,
    QTotOut: Optional[List[float]] = None
) -> None:
    """Manage DXHeatPumpSystem component simulation"""
    from DXCoils import SimDXCoil
    from VariableSpeedCoils import SimVariableSpeedCoils
    from Util import FindItemInList
    
    CompName: str = ""
    DXSystemNum: int = 0
    AirMassFlow: float = 0.0
    
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    
    NumDXHeatPumpSystems = state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems
    
    if CompIndex == 0:
        DXSystemNum = FindItemInList(DXHeatPumpSystemName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXSystemNum == 0:
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"SimDXHeatPumpSystem: DXUnit not found={DXHeatPumpSystemName}")
        CompIndex = DXSystemNum
    else:
        from UtilityRoutines import ShowFatalError
        DXSystemNum = CompIndex
        if DXSystemNum > NumDXHeatPumpSystems or DXSystemNum < 1:
            ShowFatalError(state,
                          f"SimDXHeatPumpSystem:  Invalid CompIndex passed={DXSystemNum}, "
                          f"Number of DX Units={NumDXHeatPumpSystems}, DX Unit name={DXHeatPumpSystemName}")
        if state.dataHVACDXHeatPumpSys.CheckEquipName[DXSystemNum - 1]:
            dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
            if DXHeatPumpSystemName != dxhpSystem.Name:
                ShowFatalError(state,
                              f"SimDXHeatPumpSystem: Invalid CompIndex passed={DXSystemNum}, "
                              f"DX Unit name={DXHeatPumpSystemName}, "
                              f"stored DX Unit Name for that index={dxhpSystem.Name}")
            state.dataHVACDXHeatPumpSys.CheckEquipName[DXSystemNum - 1] = False
    
    if OAUnitNum is not None:
        InitDXHeatPumpSystem(state, DXSystemNum, AirLoopNum, OAUnitNum, OAUCoilOutTemp)
    else:
        InitDXHeatPumpSystem(state, DXSystemNum, AirLoopNum)
    
    ControlDXHeatingSystem(state, DXSystemNum, FirstHVACIteration)
    
    dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
    CompName = dxhpSystem.HeatPumpCoilName
    
    HVAC_CoilType_HeatingDXSingleSpeed = 1
    HVAC_CoilType_HeatingDXVariableSpeed = 2
    HVAC_CompressorOp_On = 1
    
    if dxhpSystem.coilType == HVAC_CoilType_HeatingDXSingleSpeed:
        SimDXCoil(state, CompName, HVAC_CompressorOp_On, FirstHVACIteration,
                 dxhpSystem.HeatPumpCoilIndex, dxhpSystem.fanOp, dxhpSystem.PartLoadFrac)
    elif dxhpSystem.coilType == HVAC_CoilType_HeatingDXVariableSpeed:
        SimVariableSpeedCoils(state, CompName, dxhpSystem.HeatPumpCoilIndex,
                             dxhpSystem.fanOp, HVAC_CompressorOp_On, dxhpSystem.PartLoadFrac,
                             dxhpSystem.SpeedNum, dxhpSystem.SpeedRatio,
                             state.dataHVACDXHeatPumpSys.QZnReq,
                             state.dataHVACDXHeatPumpSys.QLatReq,
                             state.dataHVACDXHeatPumpSys.OnOffAirFlowRatio)
    else:
        from UtilityRoutines import ShowFatalError
        from HVAC import coilTypeNames
        ShowFatalError(state, f"SimDXCoolingSystem: Invalid DX Heating System/Coil={coilTypeNames[dxhpSystem.coilType]}")
    
    if AirLoopNum != -1:
        if dxhpSystem.PartLoadFrac > 0.0 and state.dataAirLoop.AirLoopControlInfo[AirLoopNum].CanLockoutEconoWithCompressor:
            state.dataAirLoop.AirLoopControlInfo[AirLoopNum].ReqstEconoLockoutWithCompressor = True
        else:
            state.dataAirLoop.AirLoopControlInfo[AirLoopNum].ReqstEconoLockoutWithCompressor = False
    
    if QTotOut is not None:
        InletNodeNum = dxhpSystem.DXHeatPumpCoilInletNodeNum
        OutletNodeNum = dxhpSystem.DXHeatPumpCoilOutletNodeNum
        AirMassFlow = state.dataLoopNodes.Node[OutletNodeNum].MassFlowRate
        QTotOut[0] = AirMassFlow * (state.dataLoopNodes.Node[InletNodeNum].Enthalpy -
                                    state.dataLoopNodes.Node[OutletNodeNum].Enthalpy)


def GetDXHeatPumpSystemInput(state: Any) -> None:
    """Get DX Heat Pump System input from data file"""
    from Util import SameString, FindItemInList
    from Sched import GetScheduleAlwaysOn, GetSchedule
    from DXCoils import GetCoilInletNode, GetCoilOutletNode, SetCoilSystemHeatingDXFlag
    from VariableSpeedCoils import GetCoilInletNodeVariableSpeed, GetCoilOutletNodeVariableSpeed
    from Node import SetUpCompSets, TestCompSet
    from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ValidateComponent, ShowSevereItemNotFound
    from OutputProcessor import SetupOutputVariable
    from InputProcessing import InputProcessor
    from HVAC import coilTypeNames
    
    HVAC_CoilType_HeatingDXSingleSpeed = 1
    HVAC_CoilType_HeatingDXVariableSpeed = 2
    
    CurrentModuleObject = "CoilSystem:Heating:DX"
    RoutineName = "GetDXHeatPumpSystemInput: "
    
    NumDXHeatPumpSystems = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems = NumDXHeatPumpSystems
    
    state.dataHVACDXHeatPumpSys.DXHeatPumpSystem = [DXHeatPumpSystemStruct() for _ in range(NumDXHeatPumpSystems)]
    state.dataHVACDXHeatPumpSys.CheckEquipName = [True] * NumDXHeatPumpSystems
    
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "CoilSystem:Heating:DX")
    
    for DXHeatSysNum in range(NumDXHeatPumpSystems):
        Alphas: List[str] = []
        Numbers: List[float] = []
        IOStat: int = 0
        NumAlphas: int = 0
        NumNums: int = 0
        lNumericBlanks: List[bool] = []
        lAlphaBlanks: List[bool] = []
        cAlphaFields: List[str] = []
        cNumericFields: List[str] = []
        
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject,
                                                               DXHeatSysNum + 1, Alphas, NumAlphas,
                                                               Numbers, NumNums, IOStat,
                                                               lNumericBlanks, lAlphaBlanks,
                                                               cAlphaFields, cNumericFields)
        
        dxhpSys = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum]
        dxhpSys.DXHeatPumpSystemType = CurrentModuleObject
        dxhpSys.Name = Alphas[0] if NumAlphas > 0 else ""
        
        if NumAlphas > 1:
            if lAlphaBlanks[1]:
                dxhpSys.availSched = GetScheduleAlwaysOn(state)
            else:
                sched = GetSchedule(state, Alphas[1])
                if sched is None:
                    eoh = {"routineName": "GetDXHeatPumpSystemInput", "CurrentModuleObject": CurrentModuleObject,
                          "Name": Alphas[0] if NumAlphas > 0 else ""}
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[1] if len(cAlphaFields) > 1 else "Schedule",
                                          Alphas[1] if NumAlphas > 1 else "")
                    state.dataHVACDXHeatPumpSys.ErrorsFound = True
                else:
                    dxhpSys.availSched = sched
        
        if NumAlphas > 2:
            if SameString(Alphas[2], "Coil:Heating:DX:SingleSpeed"):
                dxhpSys.coilType = HVAC_CoilType_HeatingDXSingleSpeed
            elif SameString(Alphas[2], "Coil:Heating:DX:VariableSpeed"):
                dxhpSys.coilType = HVAC_CoilType_HeatingDXVariableSpeed
            else:
                ShowSevereError(state, f"Invalid entry for {cAlphaFields[2] if len(cAlphaFields) > 2 else 'Coil Type'}: {Alphas[2] if NumAlphas > 2 else ''}")
                ShowContinueError(state, f'In {CurrentModuleObject}="{dxhpSys.Name}".')
                state.dataHVACDXHeatPumpSys.ErrorsFound = True
        
        if NumAlphas > 3:
            dxhpSys.HeatPumpCoilName = Alphas[3]
        
        if dxhpSys.coilType == HVAC_CoilType_HeatingDXVariableSpeed:
            dxhpSys.DXHeatPumpCoilInletNodeNum = GetCoilInletNodeVariableSpeed(
                state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName,
                state.dataHVACDXHeatPumpSys.ErrorsFound)
            dxhpSys.DXHeatPumpCoilOutletNodeNum = GetCoilOutletNodeVariableSpeed(
                state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName,
                state.dataHVACDXHeatPumpSys.ErrorsFound)
        else:
            dxhpSys.DXHeatPumpCoilInletNodeNum = GetCoilInletNode(
                state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName,
                state.dataHVACDXHeatPumpSys.ErrorsFound)
            dxhpSys.DXHeatPumpCoilOutletNodeNum = GetCoilOutletNode(
                state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName,
                state.dataHVACDXHeatPumpSys.ErrorsFound)
        
        dxhpSys.DXSystemControlNodeNum = dxhpSys.DXHeatPumpCoilOutletNodeNum
        
        TestCompSet(state, CurrentModuleObject, dxhpSys.Name,
                   state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilInletNodeNum],
                   state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilOutletNodeNum],
                   "Air Nodes")
        
        IsNotOK = False
        ValidateComponent(state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName, IsNotOK, CurrentModuleObject)
        if IsNotOK:
            ShowContinueError(state, f'In {CurrentModuleObject} = "{dxhpSys.Name}".')
            state.dataHVACDXHeatPumpSys.ErrorsFound = True
        
        SetUpCompSets(state, dxhpSys.DXHeatPumpSystemType, dxhpSys.Name,
                     coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName,
                     state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilInletNodeNum],
                     state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilOutletNodeNum])
        
        HVAC_FanOp_Continuous = 1
        dxhpSys.fanOp = HVAC_FanOp_Continuous
        
        if dxhpSys.coilType != HVAC_CoilType_HeatingDXVariableSpeed:
            SetCoilSystemHeatingDXFlag(state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName)
        else:
            from VariableSpeedCoils import SetCoilSystemHeatingDXFlag as SetCoilSystemHeatingDXFlagVS
            SetCoilSystemHeatingDXFlagVS(state, coilTypeNames[dxhpSys.coilType], dxhpSys.HeatPumpCoilName)
    
    if state.dataHVACDXHeatPumpSys.ErrorsFound:
        ShowFatalError(state, f"{RoutineName}Errors found in input.  Program terminates.")
    
    for DXHeatSysNum in range(NumDXHeatPumpSystems):
        dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum]
        SetupOutputVariable(state, "Coil System Part Load Ratio", "None",
                           dxhpSystem.PartLoadFrac, "System",
                           "Average", dxhpSystem.Name)


def InitDXHeatPumpSystem(
    state: Any,
    DXSystemNum: int,
    AirLoopNum: int,
    OAUnitNum: Optional[int] = None,
    OAUCoilOutTemp: Optional[float] = None
) -> None:
    """Initialize DX Heat Pump System"""
    from UtilityRoutines import ShowSevereError, ShowContinueError
    from EMSManager import CheckIfNodeSetPointManagedByEMS
    
    ControlNode: int = 0
    OAUCoilOutletTemp: float = 0.0
    
    NumDXHeatPumpSystems = state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems
    
    if OAUnitNum is not None:
        OAUCoilOutletTemp = OAUCoilOutTemp if OAUCoilOutTemp is not None else 0.0
    
    DoSetPointTest = state.dataHVACGlobal.DoSetPointTest
    
    if not state.dataGlobal.SysSizingCalc and state.dataHVACDXHeatPumpSys.MySetPointCheckFlag and DoSetPointTest:
        for DXSysIndex in range(NumDXHeatPumpSystems):
            DXHeatPumpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSysIndex]
            ControlNode = DXHeatPumpSystem.DXSystemControlNodeNum
            if ControlNode > 0:
                if AirLoopNum == -1:
                    state.dataLoopNodes.Node[ControlNode].TempSetPoint = OAUCoilOutletTemp
                else:
                    Node_SensedNodeFlagValue = -999999.0
                    if state.dataLoopNodes.Node[ControlNode].TempSetPoint == Node_SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(state,
                                          f"{DXHeatPumpSystem.DXHeatPumpSystemType}: Missing temperature setpoint for DX unit= {DXHeatPumpSystem.Name}")
                            ShowContinueError(state, "  use a Set Point Manager to establish a setpoint at the unit control node.")
                            state.dataHVACGlobal.SetPointErrorFlag = True
                        else:
                            HVAC_CtrlVarType_Temp = 1
                            CheckIfNodeSetPointManagedByEMS(state, ControlNode, HVAC_CtrlVarType_Temp, state.dataHVACGlobal.SetPointErrorFlag)
                            if state.dataHVACGlobal.SetPointErrorFlag:
                                ShowSevereError(state,
                                              f"{DXHeatPumpSystem.DXHeatPumpSystemType}: Missing temperature setpoint for DX unit= {DXHeatPumpSystem.Name}")
                                ShowContinueError(state, "  use a Set Point Manager to establish a setpoint at the unit control node.")
                                ShowContinueError(state,
                                                "  or use an EMS actuator to establish a temperature setpoint at the unit control node.")
        state.dataHVACDXHeatPumpSys.MySetPointCheckFlag = False
    
    dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
    
    if AirLoopNum == -1:
        dxhpSystem.DesiredOutletTemp = OAUCoilOutletTemp if OAUCoilOutTemp is not None else 0.0
    else:
        ControlNode = dxhpSystem.DXSystemControlNodeNum
        state.dataHVACDXHeatPumpSys.EconomizerFlag = state.dataAirLoop.AirLoopControlInfo[AirLoopNum].EconoActive
        dxhpSystem.DesiredOutletTemp = state.dataLoopNodes.Node[ControlNode].TempSetPoint


def ControlDXHeatingSystem(
    state: Any,
    DXSystemNum: int,
    FirstHVACIteration: bool
) -> None:
    """Control DX Heating System"""
    from DXCoils import SimDXCoil, CalcDXHeatingCoil
    from VariableSpeedCoils import SimVariableSpeedCoils
    from Psychrometrics import PsyHFnTdbW, PsyTdpFnWPb
    from General import SolveRoot
    from UtilityRoutines import ShowWarningError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowFatalError
    from HVAC import TempControlTol, coilTypeNames
    
    MaxIte = 500
    Acc = 1.0e-3
    
    HVAC_CoilType_HeatingDXSingleSpeed = 1
    HVAC_CoilType_HeatingDXVariableSpeed = 2
    HVAC_CompressorOp_On = 1
    
    OutletNode: int = 0
    InletNode: int = 0
    ControlNode: int = 0
    PartLoadFrac: float = 0.0
    DesOutTemp: float = 0.0
    OutletTempDXCoil: float = 0.0
    SensibleLoad: bool = False
    fanOp: int = 0
    SpeedNum: int = 1
    QZnReq: float = 0.0
    QLatReq: float = 0.0
    OnOffAirFlowRatio: float = 1.0
    TempSpeedOut: float = 0.0
    TempSpeedReqst: float = 0.0
    NumOfSpeeds: int = 0
    VSCoilIndex: int = 0
    I: int = 1
    SpeedRatio: float = 0.0
    
    dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
    
    OutletNode = dxhpSystem.DXHeatPumpCoilOutletNodeNum
    InletNode = dxhpSystem.DXHeatPumpCoilInletNodeNum
    ControlNode = dxhpSystem.DXSystemControlNodeNum
    DesOutTemp = dxhpSystem.DesiredOutletTemp
    CompName = dxhpSystem.HeatPumpCoilName
    fanOp = dxhpSystem.fanOp
    
    PartLoadFrac = 0.0
    SensibleLoad = False
    SpeedNum = 1
    QZnReq = 0.0
    QLatReq = 0.0
    OnOffAirFlowRatio = 1.0
    TempSpeedOut = 0.0
    TempSpeedReqst = 0.0
    NumOfSpeeds = 0
    VSCoilIndex = 0
    I = 1
    SpeedRatio = 0.0
    
    if dxhpSystem.FaultyCoilSATFlag and not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation:
        FaultIndex = dxhpSystem.FaultyCoilSATIndex
        dxhpSystem.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[FaultIndex].CalFaultOffsetAct(state)
        DesOutTemp -= dxhpSystem.FaultyCoilSATOffset
    
    if (dxhpSystem.availSched.getCurrentVal() > 0.0) and (state.dataLoopNodes.Node[InletNode].MassFlowRate > MIN_AIR_MASS_FLOW):
        if ((state.dataLoopNodes.Node[InletNode].Temp < state.dataLoopNodes.Node[ControlNode].TempSetPoint) and
            (state.dataLoopNodes.Node[InletNode].Temp < DesOutTemp) and
            (abs(state.dataLoopNodes.Node[InletNode].Temp - DesOutTemp) > TempControlTol)):
            SensibleLoad = True
        
        if SensibleLoad:
            TempOut1: float = 0.0
            
            if dxhpSystem.coilType == HVAC_CoilType_HeatingDXSingleSpeed:
                PartLoadFrac = 0.0
                SimDXCoil(state, CompName, HVAC_CompressorOp_On, FirstHVACIteration,
                         dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                NoOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                           (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp,
                                      state.dataLoopNodes.Node[OutletNode].HumRat) -
                            PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                      state.dataLoopNodes.Node[OutletNode].HumRat)))
                
                PartLoadFrac = 1.0
                SimDXCoil(state, CompName, HVAC_CompressorOp_On, FirstHVACIteration,
                         dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                FullOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                             (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp,
                                        state.dataLoopNodes.Node[InletNode].HumRat) -
                              PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                        state.dataLoopNodes.Node[InletNode].HumRat)))
                
                ReqOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                            (PsyHFnTdbW(DesOutTemp, state.dataLoopNodes.Node[InletNode].HumRat) -
                             PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                       state.dataLoopNodes.Node[InletNode].HumRat)))
                TempOut1 = state.dataLoopNodes.Node[OutletNode].Temp
                
                if (NoOutput - ReqOutput) > Acc:
                    PartLoadFrac = 0.0
                elif (FullOutput - ReqOutput) < Acc:
                    PartLoadFrac = 1.0
                else:
                    OutletTempDXCoil = state.dataDXCoils.DXCoilOutletTemp[dxhpSystem.HeatPumpCoilIndex]
                    if OutletTempDXCoil < DesOutTemp:
                        PartLoadFrac = 1.0
                    else:
                        if state.dataGlobal.DoCoilDirectSolutions:
                            PartLoadFrac = ((DesOutTemp - state.dataLoopNodes.Node[InletNode].Temp) /
                                          (TempOut1 - state.dataLoopNodes.Node[InletNode].Temp))
                            SimDXCoil(state, CompName, HVAC_CompressorOp_On, FirstHVACIteration,
                                     dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                        else:
                            coilIndex = dxhpSystem.HeatPumpCoilIndex
                            def f(PLF: float) -> float:
                                CalcDXHeatingCoil(state, coilIndex, PLF, fanOp, 1.0)
                                OutletAirTemp = state.dataDXCoils.DXCoilOutletTemp[coilIndex]
                                return DesOutTemp - OutletAirTemp
                            
                            SolFla = 0
                            PartLoadFrac = 0.5
                            SolveRoot(state, Acc, MaxIte, SolFla, PartLoadFrac, f, 0.0, 1.0)
                            
                            if SolFla == -1:
                                if not state.dataGlobal.WarmupFlag:
                                    if dxhpSystem.DXCoilSensPLRIter < 1:
                                        dxhpSystem.DXCoilSensPLRIter += 1
                                        ShowWarningError(state,
                                                       f"{dxhpSystem.DXHeatPumpSystemType} - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = {dxhpSystem.Name}")
                                        ShowContinueError(state, f"Estimated part-load ratio  = {ReqOutput / FullOutput:.3f}")
                                        ShowContinueError(state, f"Calculated part-load ratio = {PartLoadFrac:.3f}")
                                        ShowContinueErrorTimeStamp(state,
                                                                  "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                    else:
                                        ShowRecurringWarningErrorAtEnd(state,
                                                                       dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                       "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.",
                                                                       dxhpSystem.DXCoilSensPLRIterIndex,
                                                                       PartLoadFrac, PartLoadFrac)
                            elif SolFla == -2:
                                PartLoadFrac = ReqOutput / FullOutput
                                if not state.dataGlobal.WarmupFlag:
                                    if dxhpSystem.DXCoilSensPLRFail < 1:
                                        dxhpSystem.DXCoilSensPLRFail += 1
                                        ShowWarningError(state,
                                                       f"{dxhpSystem.DXHeatPumpSystemType} - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = {dxhpSystem.Name}")
                                        ShowContinueError(state, f"Estimated part-load ratio = {PartLoadFrac:.3f}")
                                        ShowContinueErrorTimeStamp(state,
                                                                  "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                    else:
                                        ShowRecurringWarningErrorAtEnd(state,
                                                                       dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                       "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.",
                                                                       dxhpSystem.DXCoilSensPLRFailIndex,
                                                                       PartLoadFrac, PartLoadFrac)
                
                if PartLoadFrac > 1.0:
                    PartLoadFrac = 1.0
                elif PartLoadFrac < 0.0:
                    PartLoadFrac = 0.0
            
            elif dxhpSystem.coilType == HVAC_CoilType_HeatingDXVariableSpeed:
                PartLoadFrac = 0.0
                SpeedNum = 1
                QZnReq = 0.0
                QLatReq = 0.0
                OnOffAirFlowRatio = 1.0
                SpeedRatio = 0.0
                
                SimVariableSpeedCoils(state, CompName, dxhpSystem.HeatPumpCoilIndex,
                                     fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                     SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                
                VSCoilIndex = dxhpSystem.HeatPumpCoilIndex
                NumOfSpeeds = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex].NumOfSpeeds
                
                NoOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                           (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp,
                                      state.dataLoopNodes.Node[OutletNode].HumRat) -
                            PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                      state.dataLoopNodes.Node[OutletNode].HumRat)))
                
                PartLoadFrac = 1.0
                SpeedNum = NumOfSpeeds
                SpeedRatio = 1.0
                QZnReq = 0.001
                SimVariableSpeedCoils(state, CompName, VSCoilIndex,
                                     fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                     SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                
                FullOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                             (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp,
                                        state.dataLoopNodes.Node[InletNode].HumRat) -
                              PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                        state.dataLoopNodes.Node[InletNode].HumRat)))
                
                ReqOutput = (state.dataLoopNodes.Node[InletNode].MassFlowRate *
                            (PsyHFnTdbW(DesOutTemp, state.dataLoopNodes.Node[InletNode].HumRat) -
                             PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp,
                                       state.dataLoopNodes.Node[InletNode].HumRat)))
                
                if (NoOutput - ReqOutput) > Acc:
                    PartLoadFrac = 0.0
                    SpeedNum = 1
                    SpeedRatio = 0.0
                elif (FullOutput - ReqOutput) < Acc:
                    PartLoadFrac = 1.0
                    SpeedNum = NumOfSpeeds
                    SpeedRatio = 1.0
                else:
                    OutletTempDXCoil = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex].OutletAirDBTemp
                    if OutletTempDXCoil < DesOutTemp:
                        PartLoadFrac = 1.0
                        SpeedNum = NumOfSpeeds
                        SpeedRatio = 1.0
                    else:
                        PartLoadFrac = 1.0
                        SpeedNum = 1
                        SpeedRatio = 1.0
                        QZnReq = 0.001
                        SimVariableSpeedCoils(state, CompName, VSCoilIndex,
                                             fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                             SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                        
                        TempSpeedOut = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex].OutletAirDBTemp
                        
                        if (TempSpeedOut - DesOutTemp) < Acc:
                            PartLoadFrac = 1.0
                            SpeedRatio = 1.0
                            TempOut1 = TempSpeedOut
                            for I in range(2, NumOfSpeeds + 1):
                                SpeedNum = I
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex,
                                                     fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                                     SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                                
                                TempSpeedOut = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex].OutletAirDBTemp
                                
                                if (TempSpeedOut - DesOutTemp) > Acc:
                                    SpeedNum = I
                                    break
                                TempOut1 = TempSpeedOut
                            
                            if state.dataGlobal.DoCoilDirectSolutions:
                                SpeedRatio = (DesOutTemp - TempOut1) / (TempSpeedOut - TempOut1)
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex,
                                                     fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                                     SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                            else:
                                def f_speed(x: float) -> float:
                                    return VSCoilSpeedResidual(state, x, VSCoilIndex, DesOutTemp, SpeedNum, fanOp)
                                
                                SolFla = 0
                                SpeedRatio = 0.5
                                SolveRoot(state, Acc, MaxIte, SolFla, SpeedRatio, f_speed, 1.0e-10, 1.0)
                                
                                if SolFla == -1:
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRIter < 1:
                                            dxhpSystem.DXCoilSensPLRIter += 1
                                            ShowWarningError(state,
                                                           f"{dxhpSystem.DXHeatPumpSystemType} - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = {dxhpSystem.Name}")
                                            ShowContinueError(state, f"Estimated part-load ratio  = {ReqOutput / FullOutput:.3f}")
                                            ShowContinueError(state, f"Calculated part-load ratio = {PartLoadFrac:.3f}")
                                            ShowContinueErrorTimeStamp(state,
                                                                      "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state,
                                                                           dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                           "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.",
                                                                           dxhpSystem.DXCoilSensPLRIterIndex,
                                                                           PartLoadFrac, PartLoadFrac)
                                elif SolFla == -2:
                                    PartLoadFrac = ReqOutput / FullOutput
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRFail < 1:
                                            dxhpSystem.DXCoilSensPLRFail += 1
                                            ShowWarningError(state,
                                                           f"{dxhpSystem.DXHeatPumpSystemType} - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = {dxhpSystem.Name}")
                                            ShowContinueError(state, f"Estimated part-load ratio = {PartLoadFrac:.3f}")
                                            ShowContinueErrorTimeStamp(state,
                                                                      "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state,
                                                                           dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                           "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.",
                                                                           dxhpSystem.DXCoilSensPLRFailIndex,
                                                                           PartLoadFrac, PartLoadFrac)
                        else:
                            if state.dataGlobal.DoCoilDirectSolutions:
                                PartLoadFrac = ((DesOutTemp - state.dataLoopNodes.Node[InletNode].Temp) /
                                              (TempSpeedOut - state.dataLoopNodes.Node[InletNode].Temp))
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex,
                                                     fanOp, HVAC_CompressorOp_On, PartLoadFrac,
                                                     SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                            else:
                                def f_cycle(x: float) -> float:
                                    return VSCoilCyclingResidual(state, x, VSCoilIndex, DesOutTemp, fanOp)
                                
                                SolFla = 0
                                PartLoadFrac = 0.5
                                SolveRoot(state, Acc, MaxIte, SolFla, PartLoadFrac, f_cycle, 1.0e-10, 1.0)
                                
                                if SolFla == -1:
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRIter < 1:
                                            dxhpSystem.DXCoilSensPLRIter += 1
                                            ShowWarningError(state,
                                                           f"{dxhpSystem.DXHeatPumpSystemType} - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = {dxhpSystem.Name}")
                                            ShowContinueError(state, f"Estimated part-load ratio  = {ReqOutput / FullOutput:.3f}")
                                            ShowContinueError(state, f"Calculated part-load ratio = {PartLoadFrac:.3f}")
                                            ShowContinueErrorTimeStamp(state,
                                                                      "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state,
                                                                           dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                           "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.",
                                                                           dxhpSystem.DXCoilSensPLRIterIndex,
                                                                           PartLoadFrac, PartLoadFrac)
                                elif SolFla == -2:
                                    PartLoadFrac = ReqOutput / FullOutput
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRFail < 1:
                                            dxhpSystem.DXCoilSensPLRFail += 1
                                            ShowWarningError(state,
                                                           f"{dxhpSystem.DXHeatPumpSystemType} - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = {dxhpSystem.Name}")
                                            ShowContinueError(state, f"Estimated part-load ratio = {PartLoadFrac:.3f}")
                                            ShowContinueErrorTimeStamp(state,
                                                                      "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state,
                                                                           dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name +
                                                                           "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.",
                                                                           dxhpSystem.DXCoilSensPLRFailIndex,
                                                                           PartLoadFrac, PartLoadFrac)
                
                if PartLoadFrac > 1.0:
                    PartLoadFrac = 1.0
                elif PartLoadFrac < 0.0:
                    PartLoadFrac = 0.0
            
            else:
                ShowFatalError(state,
                              f"ControlDXHeatingSystem: Invalid DXHeatPumpSystem coil type = {coilTypeNames[dxhpSystem.coilType]}")
    
    dxhpSystem.PartLoadFrac = PartLoadFrac
    dxhpSystem.SpeedRatio = SpeedRatio
    dxhpSystem.SpeedNum = SpeedNum


def VSCoilCyclingResidual(
    state: Any,
    PartLoadRatio: float,
    CoilIndex: int,
    desiredTemp: float,
    fanOp: int
) -> float:
    """Calculate residual for cycling part-load ratio"""
    from VariableSpeedCoils import SimVariableSpeedCoils
    from HVAC import CompressorOp
    
    HVAC_CompressorOp_On = 1
    
    SimVariableSpeedCoils(state, "", CoilIndex, fanOp, HVAC_CompressorOp_On,
                         PartLoadRatio, state.dataHVACDXHeatPumpSys.SpeedNum,
                         state.dataHVACDXHeatPumpSys.SpeedRatio,
                         state.dataHVACDXHeatPumpSys.QZnReqr,
                         state.dataHVACDXHeatPumpSys.QLatReqr,
                         state.dataHVACDXHeatPumpSys.OnandOffAirFlowRatio)
    
    OutletAirTemp = state.dataVariableSpeedCoils.VarSpeedCoil[CoilIndex].OutletAirDBTemp
    return desiredTemp - OutletAirTemp


def VSCoilSpeedResidual(
    state: Any,
    SpeedRatio: float,
    CoilIndex: int,
    desiredTemp: float,
    speedNumber: int,
    fanOp: int
) -> float:
    """Calculate residual for speed ratio"""
    from VariableSpeedCoils import SimVariableSpeedCoils
    from HVAC import CompressorOp
    
    HVAC_CompressorOp_On = 1
    
    state.dataHVACDXHeatPumpSys.SpeedNumber = speedNumber
    SimVariableSpeedCoils(state, "", CoilIndex, fanOp, HVAC_CompressorOp_On,
                         state.dataHVACDXHeatPumpSys.SpeedPartLoadRatio,
                         state.dataHVACDXHeatPumpSys.SpeedNumber,
                         SpeedRatio,
                         state.dataHVACDXHeatPumpSys.QZoneReq,
                         state.dataHVACDXHeatPumpSys.QLatentReq,
                         state.dataHVACDXHeatPumpSys.AirFlowOnOffRatio)
    
    OutletAirTemp = state.dataVariableSpeedCoils.VarSpeedCoil[CoilIndex].OutletAirDBTemp
    return desiredTemp - OutletAirTemp


def GetHeatingCoilInletNodeNum(
    state: Any,
    DXHeatCoilSysName: str,
    InletNodeErrFlag: List[bool]
) -> int:
    """Get inlet node number of heating coil system"""
    from Util import FindItemInList
    
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    
    NodeNum = 0
    if state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems > 0:
        DXHeatSysNum = FindItemInList(DXHeatCoilSysName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXHeatSysNum > 0 and DXHeatSysNum <= state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems:
            dxhpSystem = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1]
            NodeNum = dxhpSystem.DXHeatPumpCoilInletNodeNum
    
    if NodeNum == 0:
        InletNodeErrFlag[0] = True
    
    return NodeNum


def GetHeatingCoilOutletNodeNum(
    state: Any,
    DXHeatCoilSysName: str,
    OutletNodeErrFlag: List[bool]
) -> int:
    """Get outlet node number of heating coil system"""
    from Util import FindItemInList
    
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    
    NodeNum = 0
    if state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems > 0:
        DXHeatSysNum = FindItemInList(DXHeatCoilSysName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXHeatSysNum > 0 and DXHeatSysNum <= state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems:
            NodeNum = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1].DXHeatPumpCoilOutletNodeNum
    
    if NodeNum == 0:
        OutletNodeErrFlag[0] = True
    
    return NodeNum
