# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from dataclasses import dataclass, field
from typing import Optional, List, Any
from enum import IntEnum
from collections.abc import Callable

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing global simulation data
# - ControllerOperation, ControllerMode, ControllerAction, ControllerWarmRestart, RootFinderStatus, RootFinderMethod, Slope: enums from DataHVACControllers, DataRootFinder
# - PlantUtilities.SetActuatedBranchFlowRate: plant-side flow setting
# - RootFinder: namespace with InitializeRootFinder, IterateRootFinder, CheckRootFinderCandidate, CheckRootFinderConvergence, SetupRootFinder, WriteRootFinderTraceHeader, WriteRootFinderTrace
# - ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowContinueErrorTimeStamp, ShowRecurringSevereErrorAtEnd: error reporting
# - Util.FindItemInList, Util.SameString: utility functions
# - Node.GetOnlySingleNode, Node.SensedNodeFlagValue, Node.ConnectionObjectType, Node.ConnectionType, Node.CompFluidStream, Node.FluidType, Node.ObjectIsNotParent: node management
# - MixedAir.CheckForControllerWaterCoil: air system controller validation
# - WaterCoils.CheckForSensorAndSetPointNode, WaterCoils.CheckActuatorNode: coil validation
# - SetPointManager: setpoint management utilities
# - EMSManager: EMS integration
# - InputOutputFilePath, InputOutputFile: file I/O
# - Psychrometrics.PsyTdpFnWPb: psychrometric function
# - General.CreateTimeString: time formatting
# - DataPlant.PlantEquipmentType: plant equipment enums
# - DataLoopNode.ConnectionType: connection type info
# - Constant: physical constants
# - DataAirLoop.ControllerKind, DataAirSystems.DefinePrimaryAirSystem: air system types
# - DataConvergParams.HVACEnergyToler, DataConvergParams.HVACTemperatureToler: convergence tolerances
# - DataPrecisionGlobals.constant_zero: precision constant
# - BaseSizer.reportSizerOutput: sizing output
# - HVAC.CtrlVarType, HVAC.SmallWaterVolFlow: HVAC constants
# - DataSizing.AutoSize, DataSizing.SaveNumPlantComps, DataSizing.CompDesWaterFlow: sizing data

class CtrlVarType(IntEnum):
    Invalid = -1
    NoControlVariable = 0
    Temperature = 1
    HumidityRatio = 2
    TemperatureAndHumidityRatio = 3
    Flow = 4
    Num = 5

@dataclass
class SolutionTrackerType:
    DefinedFlag: bool = True
    ActuatedValue: float = 0.0
    Mode: Any = None  # ControllerMode enum value

@dataclass
class ControllerPropsType:
    ControllerName: str = ""
    ControllerType: str = ""
    ControllerType_Num: int = 0
    ControlVar: CtrlVarType = CtrlVarType.NoControlVariable
    ActuatorVar: CtrlVarType = CtrlVarType.NoControlVariable
    Action: Any = None  # ControllerAction enum
    InitFirstPass: bool = True
    NumCalcCalls: int = 0
    Mode: Any = None  # ControllerMode enum
    DoWarmRestartFlag: bool = False
    ReuseIntermediateSolutionFlag: bool = False
    ReusePreviousSolutionFlag: bool = False
    SolutionTrackers: List[SolutionTrackerType] = field(default_factory=lambda: [SolutionTrackerType(), SolutionTrackerType()])
    MaxAvailActuated: float = 0.0
    MaxAvailSensed: float = 0.0
    MinAvailActuated: float = 0.0
    MinAvailSensed: float = 0.0
    MaxVolFlowActuated: float = 0.0
    MinVolFlowActuated: float = 0.0
    MaxActuated: float = 0.0
    MinActuated: float = 0.0
    ActuatedNode: int = 0
    ActuatedValue: float = 0.0
    NextActuatedValue: float = 0.0
    ActuatedNodePlantLoc: Any = None  # PlantLocation
    WaterCoilType: Any = None  # PlantEquipmentType
    SensedNode: int = 0
    IsSetPointDefinedFlag: bool = False
    SetPointValue: float = 0.0
    SensedValue: float = 0.0
    DeltaSensed: float = 0.0
    Offset: float = 0.0
    HumRatCntrlType: Any = None  # HVAC.CtrlVarType
    LimitType: str = ""
    Range: float = 0.0
    Limit: float = 0.0
    TraceFile: Any = None  # SharedFileHandle
    FirstTraceFlag: bool = True
    BadActionErrCount: int = 0
    BadActionErrIndex: int = 0
    FaultyCoilSATFlag: bool = False
    FaultyCoilSATIndex: int = 0
    FaultyCoilSATOffset: float = 0.0
    BypassControllerCalc: bool = False
    AirLoopControllerIndex: int = 0
    HumRatCtrlOverride: bool = False

@dataclass
class ControllerStatsType:
    NumCalls: List[int] = field(default_factory=lambda: [0] * 10)
    TotIterations: List[int] = field(default_factory=lambda: [0] * 10)
    MaxIterations: List[int] = field(default_factory=lambda: [0] * 10)

@dataclass
class AirLoopStatsType:
    TraceFile: Any = None  # SharedFileHandle
    FirstTraceFlag: bool = True
    NumCalls: int = 0
    NumFailedWarmRestarts: int = 0
    NumSuccessfulWarmRestarts: int = 0
    TotSimAirLoopComponents: int = 0
    MaxSimAirLoopComponents: int = 0
    TotIterations: int = 0
    MaxIterations: int = 0
    ControllerStats: List[ControllerStatsType] = field(default_factory=list)

CTRL_VAR_NAMES_UC = ["INVALID-NONE", "TEMPERATURE", "HUMIDITYRATIO", "TEMPERATUREANDHUMIDITYRATIO", "INVALID-FLOW"]
ACTION_NAMES_UC = ["", "REVERSE", "NORMAL"]

def ControlVariableTypes(c: CtrlVarType) -> str:
    if c == CtrlVarType.NoControlVariable:
        return "No control variable"
    elif c == CtrlVarType.Temperature:
        return "Temperature"
    elif c == CtrlVarType.HumidityRatio:
        return "Humidity ratio"
    elif c == CtrlVarType.TemperatureAndHumidityRatio:
        return "Temperature and humidity ratio"
    elif c == CtrlVarType.Flow:
        return "Flow rate"
    else:
        return "no controller type found"

def ManageControllers(state: Any, ControllerName: str, ControllerIndex_ref: List[int], FirstHVACIteration: bool,
                     AirLoopNum: int, Operation: Any, IsConvergedFlag_ref: List[bool], IsUpToDateFlag_ref: List[bool],
                     BypassOAController: bool, AllowWarmRestartFlag_ref: Optional[List[bool]] = None) -> None:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    if ControllerIndex_ref[0] == 0:
        ControlNum = Util.FindItemInList(ControllerName, state.dataHVACControllers.ControllerProps, lambda x: x.ControllerName)
        if ControlNum == 0:
            ShowFatalError(state, f"ManageControllers: Invalid controller={ControllerName}. The only valid controller type for an AirLoopHVAC is Controller:WaterCoil.")
        ControllerIndex_ref[0] = ControlNum
    else:
        ControlNum = ControllerIndex_ref[0]
        if ControlNum > state.dataHVACControllers.NumControllers or ControlNum < 1:
            ShowFatalError(state, f"ManageControllers: Invalid ControllerIndex passed={ControlNum}, Number of controllers={state.dataHVACControllers.NumControllers}, Controller name={ControllerName}")
        if state.dataHVACControllers.CheckEquipName[ControlNum - 1]:
            if ControllerName != state.dataHVACControllers.ControllerProps[ControlNum - 1].ControllerName:
                ShowFatalError(state, f"ManageControllers: Invalid ControllerIndex passed={ControlNum}, Controller name={ControllerName}, stored Controller Name for that index={state.dataHVACControllers.ControllerProps[ControlNum - 1].ControllerName}")
            state.dataHVACControllers.CheckEquipName[ControlNum - 1] = False

    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if controllerProps.BypassControllerCalc and BypassOAController:
        IsUpToDateFlag_ref[0] = True
        IsConvergedFlag_ref[0] = True
        if AllowWarmRestartFlag_ref is not None:
            AllowWarmRestartFlag_ref[0] = True
        return

    if controllerProps.ActuatedNodePlantLoc.loopNum > 0:
        if state.dataPlnt.PlantLoop[controllerProps.ActuatedNodePlantLoc.loopNum - 1].LoopSide[controllerProps.ActuatedNodePlantLoc.loopSideNum - 1].FlowLock == DataPlant.FlowLock.Locked:
            UpdateController(state, ControlNum)
            IsConvergedFlag_ref[0] = True
            return

    if AllowWarmRestartFlag_ref is not None:
        if controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
            AllowWarmRestartFlag_ref[0] = False
        else:
            AllowWarmRestartFlag_ref[0] = True

    if controllerProps.InitFirstPass:
        InitController(state, ControlNum, IsConvergedFlag_ref)
        controllerProps.InitFirstPass = False

    if Operation == DataHVACControllers.ControllerOperation.ColdStart:
        if controllerProps.HumRatCtrlOverride:
            controllerProps.HumRatCtrlOverride = False
            RootFinder.SetupRootFinder(state, state.dataHVACControllers.RootFinders[ControlNum - 1],
                                      DataRootFinder.Slope.Decreasing, DataRootFinder.RootFinderMethod.Brent,
                                      DataPrecisionGlobals.constant_zero, 1.0e-6, controllerProps.Offset)
        ResetController(state, ControlNum, False, IsConvergedFlag_ref)
        UpdateController(state, ControlNum)
    elif Operation == DataHVACControllers.ControllerOperation.WarmRestart:
        ResetController(state, ControlNum, True, IsConvergedFlag_ref)
        UpdateController(state, ControlNum)
    elif Operation == DataHVACControllers.ControllerOperation.Iterate:
        InitController(state, ControlNum, IsConvergedFlag_ref)
        ControllerType = controllerProps.ControllerType_Num
        if ControllerType == ControllerSimple_Type:
            CalcSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag_ref, IsUpToDateFlag_ref, ControllerName)
        else:
            ShowFatalError(state, f"Invalid controller type in ManageControllers={controllerProps.ControllerType}")
        UpdateController(state, ControlNum)
        CheckTempAndHumRatCtrl(state, ControlNum, IsConvergedFlag_ref)
    elif Operation == DataHVACControllers.ControllerOperation.End:
        InitController(state, ControlNum, IsConvergedFlag_ref)
        ControllerType = controllerProps.ControllerType_Num
        if ControllerType == ControllerSimple_Type:
            CheckSimpleController(state, ControlNum, IsConvergedFlag_ref)
            SaveSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag_ref[0])
        else:
            ShowFatalError(state, f"Invalid controller type in ManageControllers={controllerProps.ControllerType}")
    else:
        ShowFatalError(state, f"ManageControllers: Invalid Operation passed={int(Operation)}, Controller name={ControllerName}")

    if state.dataSysVars.TraceHVACControllerEnvFlag:
        TraceIndividualController(state, ControlNum, FirstHVACIteration, state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].AirLoopPass, Operation, IsConvergedFlag_ref[0])

def GetControllerInput(state: Any) -> None:
    NumPrimaryAirSys = state.dataHVACGlobal.NumPrimaryAirSys
    RoutineName = "HVACControllers: GetControllerInput: "
    
    CurrentModuleObject = "Controller:WaterCoil"
    NumSimpleControllers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACControllers.NumControllers = NumSimpleControllers

    if state.dataSysVars.TrackAirLoopEnvFlag or state.dataSysVars.TraceAirLoopEnvFlag or state.dataSysVars.TraceHVACControllerEnvFlag:
        if NumPrimaryAirSys > 0:
            state.dataHVACControllers.NumAirLoopStats = NumPrimaryAirSys
            state.dataHVACControllers.AirLoopStats = [AirLoopStatsType() for _ in range(state.dataHVACControllers.NumAirLoopStats)]
            for AirLoopNum in range(NumPrimaryAirSys):
                state.dataHVACControllers.AirLoopStats[AirLoopNum].ControllerStats = [
                    ControllerStatsType() for _ in range(state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].NumControllers)
                ]

    if state.dataHVACControllers.NumControllers == 0:
        return

    state.dataHVACControllers.ControllerProps = [ControllerPropsType() for _ in range(state.dataHVACControllers.NumControllers)]
    state.dataHVACControllers.RootFinders = [RootFinderDataType() for _ in range(state.dataHVACControllers.NumControllers)]
    state.dataHVACControllers.CheckEquipName = [True] * state.dataHVACControllers.NumControllers

    for Num in range(NumSimpleControllers):
        controllerProps = state.dataHVACControllers.ControllerProps[Num]
        AlphArray, NumArray, cAlphaFields, cNumericFields, lNumericBlanks, lAlphaBlanks, IOStat = \
            state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Num + 1)

        controllerProps.ControllerName = AlphArray[0] if len(AlphArray) > 0 else ""
        controllerProps.ControllerType = CurrentModuleObject

        if len(AlphArray) > 1:
            controllerProps.ControlVar = CtrlVarType(getEnumValue(CTRL_VAR_NAMES_UC, AlphArray[1]))
        if controllerProps.ControlVar == CtrlVarType.Invalid:
            ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{AlphArray[0]}\".")
            ShowContinueError(state, f"...Invalid {cAlphaFields[1] if len(cAlphaFields) > 1 else ''}=\"{AlphArray[1] if len(AlphArray) > 1 else ''}\", must be Temperature, HumidityRatio, or TemperatureAndHumidityRatio.")

        if len(AlphArray) > 2:
            controllerProps.Action = getEnumValue(ACTION_NAMES_UC, AlphArray[2])
        
        if len(AlphArray) > 3:
            if AlphArray[3] == "FLOW":
                controllerProps.ActuatorVar = CtrlVarType.Flow

        if len(AlphArray) > 4:
            controllerProps.SensedNode = Node.GetOnlySingleNode(state, AlphArray[4])
        if len(AlphArray) > 5:
            controllerProps.ActuatedNode = Node.GetOnlySingleNode(state, AlphArray[5])
        
        if len(NumArray) > 0:
            controllerProps.Offset = NumArray[0]
        if len(NumArray) > 1:
            controllerProps.MaxVolFlowActuated = NumArray[1]
        if len(NumArray) > 2:
            controllerProps.MinVolFlowActuated = NumArray[2]

def ResetController(state: Any, ControlNum: int, DoWarmRestartFlag: bool, IsConvergedFlag_ref: List[bool]) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    rootFinders = state.dataHVACControllers.RootFinders[ControlNum - 1]

    NoFlowResetValue = 0.0
    PlantUtilities.SetActuatedBranchFlowRate(state, NoFlowResetValue, controllerProps.ActuatedNode, controllerProps.ActuatedNodePlantLoc, True)

    controllerProps.NumCalcCalls = 0
    controllerProps.DeltaSensed = 0.0
    controllerProps.SensedValue = 0.0
    controllerProps.ActuatedValue = 0.0
    controllerProps.SetPointValue = 0.0
    controllerProps.IsSetPointDefinedFlag = False
    controllerProps.MinAvailActuated = 0.0
    controllerProps.MinAvailSensed = 0.0
    controllerProps.MaxAvailActuated = 0.0
    controllerProps.MaxAvailSensed = 0.0

    if DoWarmRestartFlag:
        controllerProps.DoWarmRestartFlag = True
    else:
        controllerProps.DoWarmRestartFlag = False
        controllerProps.Mode = None
        controllerProps.NextActuatedValue = 0.0

    controllerProps.ReusePreviousSolutionFlag = True
    controllerProps.ReuseIntermediateSolutionFlag = False
    IsConvergedFlag_ref[0] = False

    rootFinders.StatusFlag = None
    rootFinders.CurrentMethodType = None
    rootFinders.CurrentPoint.DefinedFlag = False
    rootFinders.CurrentPoint.X = 0.0
    rootFinders.CurrentPoint.Y = 0.0
    rootFinders.MinPoint.DefinedFlag = False
    rootFinders.MaxPoint.DefinedFlag = False
    rootFinders.LowerPoint.DefinedFlag = False
    rootFinders.UpperPoint.DefinedFlag = False

def InitController(state: Any, ControlNum: int, IsConvergedFlag_ref: List[bool]) -> None:
    thisController = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    
    if state.dataHVACControllers.InitControllerOneTimeFlag:
        state.dataHVACControllers.MyEnvrnFlag = [True] * state.dataHVACControllers.NumControllers
        state.dataHVACControllers.MySizeFlag = [True] * state.dataHVACControllers.NumControllers
        state.dataHVACControllers.MyPlantIndexsFlag = [True] * state.dataHVACControllers.NumControllers
        state.dataHVACControllers.InitControllerOneTimeFlag = False

    if not state.dataGlobal.SysSizingCalc and state.dataHVACControllers.InitControllerSetPointCheckFlag and state.dataHVACGlobal.DoSetPointTest:
        for ControllerIndex in range(state.dataHVACControllers.NumControllers):
            controllerProps = state.dataHVACControllers.ControllerProps[ControllerIndex]
            SensedNode = controllerProps.SensedNode
            if controllerProps.ControlVar == CtrlVarType.Temperature:
                if state.dataLoopNodes.Node[SensedNode - 1].TempSetPoint == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, f"HVACControllers: Missing temperature setpoint for controller type={controllerProps.ControllerType} Name=\"{controllerProps.ControllerName}\"")

    if state.dataHVACControllers.MySizeFlag[ControlNum - 1]:
        SizeController(state, ControlNum)
        state.dataHVACControllers.MySizeFlag[ControlNum - 1] = False

    ActuatedNode = thisController.ActuatedNode
    SensedNode = thisController.SensedNode

    if state.dataGlobal.BeginEnvrnFlag and state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1]:
        rho = thisController.ActuatedNodePlantLoc.loop.glycol.getDensity(state, 273.15)
        thisController.MinActuated = rho * thisController.MinVolFlowActuated
        thisController.MaxActuated = rho * thisController.MaxVolFlowActuated
        thisController.ReusePreviousSolutionFlag = False
        for e in thisController.SolutionTrackers:
            e.DefinedFlag = False
            e.Mode = None
            e.ActuatedValue = 0.0
        state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1] = True

    PlantUtilities.SetActuatedBranchFlowRate(state, thisController.NextActuatedValue, ActuatedNode, thisController.ActuatedNodePlantLoc, False)

    IsConvergedFlag_ref[0] = False

    if thisController.ControlVar == CtrlVarType.Temperature:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode - 1].Temp
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].TempSetPoint
            thisController.IsSetPointDefinedFlag = True
            if thisController.FaultyCoilSATFlag and not state.dataGlobal.WarmupFlag:
                FaultIndex = thisController.FaultyCoilSATIndex
                thisController.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[FaultIndex - 1].CalFaultOffsetAct(state)
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].TempSetPoint - thisController.FaultyCoilSATOffset
    elif thisController.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
        if thisController.HumRatCtrlOverride:
            thisController.SensedValue = state.dataLoopNodes.Node[SensedNode - 1].HumRat
        else:
            thisController.SensedValue = state.dataLoopNodes.Node[SensedNode - 1].Temp
        if not thisController.IsSetPointDefinedFlag:
            if thisController.HumRatCtrlOverride:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].HumRatMax
            else:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].TempSetPoint
            thisController.IsSetPointDefinedFlag = True
    elif thisController.ControlVar == CtrlVarType.HumidityRatio:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode - 1].HumRat
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].HumRatMax
            thisController.IsSetPointDefinedFlag = True
    elif thisController.ControlVar == CtrlVarType.Flow:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode - 1].MassFlowRate
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode - 1].MassFlowRateSetPoint
            thisController.IsSetPointDefinedFlag = True

    if thisController.ActuatorVar == CtrlVarType.Flow:
        thisController.ActuatedValue = state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRate
        if thisController.NumCalcCalls == 0:
            thisController.MinAvailActuated = max(state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail, thisController.MinActuated)
            thisController.MaxAvailActuated = min(state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail, thisController.MaxActuated)
            thisController.MinAvailActuated = min(thisController.MinAvailActuated, thisController.MaxAvailActuated)

    if thisController.IsSetPointDefinedFlag:
        thisController.DeltaSensed = thisController.SensedValue - thisController.SetPointValue
    else:
        thisController.DeltaSensed = 0.0

def SizeController(state: Any, ControlNum: int) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if controllerProps.MaxVolFlowActuated == DataSizing.AutoSize:
        for WaterCompNum in range(state.dataSize.SaveNumPlantComps):
            if state.dataSize.CompDesWaterFlow[WaterCompNum].SupNode == controllerProps.ActuatedNode:
                controllerProps.MaxVolFlowActuated = state.dataSize.CompDesWaterFlow[WaterCompNum].DesVolFlowRate
        if controllerProps.MaxVolFlowActuated < HVAC.SmallWaterVolFlow:
            controllerProps.MaxVolFlowActuated = 0.0
        BaseSizer.reportSizerOutput(state, controllerProps.ControllerType, controllerProps.ControllerName,
                                   "Maximum Actuated Flow [m3/s]", controllerProps.MaxVolFlowActuated)

    if controllerProps.Offset == DataSizing.AutoSize:
        controllerProps.Offset = (0.001 / (2100.0 * max(controllerProps.MaxVolFlowActuated, HVAC.SmallWaterVolFlow))) * (DataConvergParams.HVACEnergyToler / 10.0)
        controllerProps.Offset = min(0.1 * DataConvergParams.HVACTemperatureToler, controllerProps.Offset)
        BaseSizer.reportSizerOutput(state, controllerProps.ControllerType, controllerProps.ControllerName, "Controller Convergence Tolerance", controllerProps.Offset)

def CalcSimpleController(state: Any, ControlNum: int, FirstHVACIteration: bool, IsConvergedFlag_ref: List[bool],
                        IsUpToDateFlag_ref: List[bool], ControllerName: str) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    rootFinders = state.dataHVACControllers.RootFinders[ControlNum - 1]

    controllerProps.NumCalcCalls += 1

    if state.dataLoopNodes.Node[controllerProps.SensedNode - 1].MassFlowRate == 0.0:
        ExitCalcController(state, ControlNum, DataPrecisionGlobals.constant_zero, ControllerMode.Off, IsConvergedFlag_ref, IsUpToDateFlag_ref)
        return

    if controllerProps.NumCalcCalls == 1:
        RootFinder.InitializeRootFinder(state, rootFinders, controllerProps.MinAvailActuated, controllerProps.MaxAvailActuated)
        controllerProps.ReuseIntermediateSolutionFlag = IsUpToDateFlag_ref[0] and controllerProps.IsSetPointDefinedFlag and \
            RootFinder.CheckRootFinderCandidate(rootFinders, controllerProps.ActuatedValue)

        if controllerProps.ReuseIntermediateSolutionFlag:
            FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag_ref, IsUpToDateFlag_ref, ControllerName)
        else:
            controllerProps.NextActuatedValue = rootFinders.MinPoint.X
    else:
        if not controllerProps.IsSetPointDefinedFlag:
            ShowSevereError(state, f"CalcSimpleController: Root finder failed at {CreateHVACStepFullString(state)}")
            ShowContinueError(state, f" Controller name=\"{ControllerName}\"")
            ShowFatalError(state, "Preceding error causes program termination.")

        FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag_ref, IsUpToDateFlag_ref, ControllerName)

def FindRootSimpleController(state: Any, ControlNum: int, FirstHVACIteration: bool, IsConvergedFlag_ref: List[bool],
                            IsUpToDateFlag_ref: List[bool], ControllerName: str) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    rootFinders = state.dataHVACControllers.RootFinders[ControlNum - 1]

    IsDoneFlag = False
    RootFinder.IterateRootFinder(state, rootFinders, controllerProps.ActuatedValue, controllerProps.DeltaSensed, IsDoneFlag)

    if rootFinders.StatusFlag in [None, RootFinderStatus.WarningNonMonotonic, RootFinderStatus.WarningSingular]:
        IsConvergedFlag_ref[0] = False
        PreviousSolutionIndex = 0 if FirstHVACIteration else 1
        PreviousSolutionDefinedFlag = controllerProps.SolutionTrackers[PreviousSolutionIndex].DefinedFlag
        PreviousSolutionMode = controllerProps.SolutionTrackers[PreviousSolutionIndex].Mode
        PreviousSolutionValue = controllerProps.SolutionTrackers[PreviousSolutionIndex].ActuatedValue
        ReusePreviousSolutionFlag = controllerProps.ReusePreviousSolutionFlag and \
            (rootFinders.CurrentMethodType == RootFinderMethod.Bracket) and \
            PreviousSolutionDefinedFlag and (PreviousSolutionMode == ControllerMode.Active) and \
            RootFinder.CheckRootFinderCandidate(rootFinders, PreviousSolutionValue)

        if ReusePreviousSolutionFlag:
            controllerProps.NextActuatedValue = PreviousSolutionValue
            controllerProps.ReusePreviousSolutionFlag = False
        else:
            controllerProps.NextActuatedValue = rootFinders.XCandidate
    elif rootFinders.StatusFlag in [RootFinderStatus.OK, RootFinderStatus.OKRoundOff]:
        ExitCalcController(state, ControlNum, rootFinders.XCandidate, ControllerMode.Active, IsConvergedFlag_ref, IsUpToDateFlag_ref)
    elif rootFinders.StatusFlag == RootFinderStatus.OKMin:
        ExitCalcController(state, ControlNum, rootFinders.MinPoint.X, ControllerMode.MinActive, IsConvergedFlag_ref, IsUpToDateFlag_ref)
    elif rootFinders.StatusFlag == RootFinderStatus.OKMax:
        ExitCalcController(state, ControlNum, rootFinders.MaxPoint.X, ControllerMode.MaxActive, IsConvergedFlag_ref, IsUpToDateFlag_ref)
    elif rootFinders.StatusFlag == RootFinderStatus.ErrorSingular:
        ExitCalcController(state, ControlNum, rootFinders.MinPoint.X, ControllerMode.Inactive, IsConvergedFlag_ref, IsUpToDateFlag_ref)

def CheckSimpleController(state: Any, ControlNum: int, IsConvergedFlag_ref: List[bool]) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    rootFinders = state.dataHVACControllers.RootFinders[ControlNum - 1]

    IsConvergedFlag_ref[0] = False

    if controllerProps.Mode == ControllerMode.Off:
        if state.dataLoopNodes.Node[controllerProps.SensedNode - 1].MassFlowRate == 0.0:
            if controllerProps.ActuatedValue == 0.0:
                IsConvergedFlag_ref[0] = True
    elif controllerProps.Mode == ControllerMode.Inactive:
        if controllerProps.ActuatedValue == controllerProps.MinAvailActuated:
            IsConvergedFlag_ref[0] = True
    elif controllerProps.Mode == ControllerMode.MinActive:
        if CheckMinActiveController(state, ControlNum):
            IsConvergedFlag_ref[0] = True
        elif RootFinder.CheckRootFinderConvergence(rootFinders, controllerProps.DeltaSensed):
            IsConvergedFlag_ref[0] = True
    elif controllerProps.Mode == ControllerMode.MaxActive:
        if CheckMaxActiveController(state, ControlNum):
            IsConvergedFlag_ref[0] = True
        elif RootFinder.CheckRootFinderConvergence(rootFinders, controllerProps.DeltaSensed):
            IsConvergedFlag_ref[0] = True
    elif controllerProps.Mode == ControllerMode.Active:
        if controllerProps.ActuatedValue < controllerProps.MinAvailActuated or controllerProps.ActuatedValue > controllerProps.MaxAvailActuated:
            IsConvergedFlag_ref[0] = False
        elif RootFinder.CheckRootFinderConvergence(rootFinders, controllerProps.DeltaSensed):
            IsConvergedFlag_ref[0] = True
        elif CheckMinActiveController(state, ControlNum):
            IsConvergedFlag_ref[0] = True
        elif CheckMaxActiveController(state, ControlNum):
            IsConvergedFlag_ref[0] = True

def CheckMinActiveController(state: Any, ControlNum: int) -> bool:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if controllerProps.ActuatedValue != controllerProps.MinAvailActuated:
        return False

    if controllerProps.Action == ControllerAction.NormalAction:
        if controllerProps.SetPointValue <= controllerProps.SensedValue:
            return True
    elif controllerProps.Action == ControllerAction.Reverse:
        if controllerProps.SetPointValue >= controllerProps.SensedValue:
            return True

    return False

def CheckMaxActiveController(state: Any, ControlNum: int) -> bool:
    ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if ControllerProps.ActuatedValue != ControllerProps.MaxAvailActuated:
        return False

    if ControllerProps.Action == ControllerAction.NormalAction:
        if ControllerProps.SetPointValue >= ControllerProps.SensedValue:
            return True
    elif ControllerProps.Action == ControllerAction.Reverse:
        if ControllerProps.SetPointValue <= ControllerProps.SensedValue:
            return True

    return False

def CheckTempAndHumRatCtrl(state: Any, ControlNum: int, IsConvergedFlag_ref: List[bool]) -> None:
    thisController = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    if IsConvergedFlag_ref[0]:
        if thisController.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
            if not thisController.HumRatCtrlOverride:
                if state.dataLoopNodes.Node[thisController.SensedNode - 1].HumRat > (state.dataLoopNodes.Node[thisController.SensedNode - 1].HumRatMax + 1.0e-5):
                    IsConvergedFlag_ref[0] = False
                    thisController.HumRatCtrlOverride = True
                    if thisController.Action == ControllerAction.Reverse:
                        RootFinder.SetupRootFinder(state, state.dataHVACControllers.RootFinders[ControlNum - 1],
                                                  DataRootFinder.Slope.Decreasing, DataRootFinder.RootFinderMethod.FalsePosition,
                                                  DataPrecisionGlobals.constant_zero, 1.0e-6, 1.0e-5)
                    ResetController(state, ControlNum, False, IsConvergedFlag_ref)

def SaveSimpleController(state: Any, ControlNum: int, FirstHVACIteration: bool, IsConvergedFlag: bool) -> None:
    ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if IsConvergedFlag:
        PreviousSolutionIndex = 0 if FirstHVACIteration else 1
        if ControllerProps.Mode == ControllerMode.Active:
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].DefinedFlag = True
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].Mode = ControllerProps.Mode
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].ActuatedValue = ControllerProps.NextActuatedValue
        else:
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].DefinedFlag = False
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].Mode = ControllerProps.Mode
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].ActuatedValue = ControllerProps.NextActuatedValue

def UpdateController(state: Any, ControlNum: int) -> None:
    ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if ControllerProps.ActuatorVar == CtrlVarType.Flow:
        PlantUtilities.SetActuatedBranchFlowRate(state, ControllerProps.NextActuatedValue, ControllerProps.ActuatedNode, ControllerProps.ActuatedNodePlantLoc, False)

def ExitCalcController(state: Any, ControlNum: int, NextActuatedValue: float, Mode: Any,
                      IsConvergedFlag_ref: List[bool], IsUpToDateFlag_ref: List[bool]) -> None:
    ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    ControllerProps.NextActuatedValue = NextActuatedValue
    ControllerProps.Mode = Mode
    IsConvergedFlag_ref[0] = True

    if ControllerProps.ActuatedValue != ControllerProps.NextActuatedValue:
        IsUpToDateFlag_ref[0] = False
    else:
        IsUpToDateFlag_ref[0] = True

def TrackAirLoopControllers(state: Any, AirLoopNum: int, WarmRestartStatus: Any, AirLoopIterMax: int,
                           AirLoopIterTot: int, AirLoopNumCalls: int) -> None:
    airLoopStats = state.dataHVACControllers.AirLoopStats[AirLoopNum - 1]

    if state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers == 0:
        return
    if state.dataHVACControllers.NumAirLoopStats == 0:
        return

    airLoopStats.NumCalls += 1

    if WarmRestartStatus == ControllerWarmRestart.Success:
        airLoopStats.NumSuccessfulWarmRestarts += 1
    elif WarmRestartStatus == ControllerWarmRestart.Fail:
        airLoopStats.NumFailedWarmRestarts += 1

    airLoopStats.TotSimAirLoopComponents += AirLoopNumCalls
    airLoopStats.MaxSimAirLoopComponents = max(airLoopStats.MaxSimAirLoopComponents, AirLoopNumCalls)
    airLoopStats.TotIterations += AirLoopIterTot
    airLoopStats.MaxIterations = max(airLoopStats.MaxIterations, AirLoopIterMax)

    for ControllerNum in range(state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers):
        TrackAirLoopController(state, AirLoopNum, ControllerNum + 1)

def TrackAirLoopController(state: Any, AirLoopNum: int, AirLoopControlNum: int) -> None:
    airLoopStats = state.dataHVACControllers.AirLoopStats[AirLoopNum - 1]
    ControlIndex = state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].ControllerIndex[AirLoopControlNum - 1]
    controllerProps = state.dataHVACControllers.ControllerProps[ControlIndex - 1]

    IterationCount = controllerProps.NumCalcCalls
    Mode = controllerProps.Mode

    if Mode is not None:
        mode_index = int(Mode)
        airLoopStats.ControllerStats[AirLoopControlNum - 1].NumCalls[mode_index] += 1
        airLoopStats.ControllerStats[AirLoopControlNum - 1].TotIterations[mode_index] += IterationCount
        airLoopStats.ControllerStats[AirLoopControlNum - 1].MaxIterations[mode_index] = \
            max(airLoopStats.ControllerStats[AirLoopControlNum - 1].MaxIterations[mode_index], IterationCount)

def DumpAirLoopStatistics(state: Any) -> None:
    if not state.dataSysVars.TrackAirLoopEnvFlag:
        return

    StatisticsFilePath = "statistics.HVACControllers.csv"
    statisticsFile = InputOutputFile(StatisticsFilePath)

    for AirLoopNum in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
        WriteAirLoopStatistics(state, statisticsFile, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1],
                             state.dataHVACControllers.AirLoopStats[AirLoopNum - 1])

def WriteAirLoopStatistics(state: Any, statisticsFile: Any, ThisPrimaryAirSystem: Any, ThisAirLoopStats: AirLoopStatsType) -> None:
    WarmRestartSuccessRatio = 0.0
    AvgIterations = 0.0

    statisticsFile.write(f"{ThisPrimaryAirSystem.Name},\n")
    statisticsFile.write(f"NumCalls,{ThisAirLoopStats.NumCalls}\n")

    NumWarmRestarts = ThisAirLoopStats.NumSuccessfulWarmRestarts + ThisAirLoopStats.NumFailedWarmRestarts
    if NumWarmRestarts > 0:
        WarmRestartSuccessRatio = float(ThisAirLoopStats.NumSuccessfulWarmRestarts) / float(NumWarmRestarts)

    statisticsFile.write(f"NumWarmRestarts,{NumWarmRestarts}\n")
    statisticsFile.write(f"NumSuccessfulWarmRestarts,{ThisAirLoopStats.NumSuccessfulWarmRestarts}\n")
    statisticsFile.write(f"NumFailedWarmRestarts,{ThisAirLoopStats.NumFailedWarmRestarts}\n")
    statisticsFile.write(f"WarmRestartSuccessRatio,{WarmRestartSuccessRatio:.10f}\n")
    statisticsFile.write(f"TotSimAirLoopComponents,{ThisAirLoopStats.TotSimAirLoopComponents}\n")
    statisticsFile.write(f"MaxSimAirLoopComponents,{ThisAirLoopStats.MaxSimAirLoopComponents}\n")
    statisticsFile.write(f"TotIterations,{ThisAirLoopStats.TotIterations}\n")
    statisticsFile.write(f"MaxIterations,{ThisAirLoopStats.MaxIterations}\n")

    if ThisAirLoopStats.NumCalls == 0:
        AvgIterations = 0.0
    else:
        AvgIterations = float(ThisAirLoopStats.TotIterations) / float(ThisAirLoopStats.NumCalls)

    statisticsFile.write(f"AvgIterations,{AvgIterations:.10f}\n")

def SetupAirLoopControllersTracer(state: Any, AirLoopNum: int) -> None:
    TraceFilePath = f"controller.{state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].Name}.csv"
    airLoopStats = state.dataHVACControllers.AirLoopStats[AirLoopNum - 1]
    airLoopStats.TraceFile.filePath = TraceFilePath
    airLoopStats.TraceFile.open()

    if not airLoopStats.TraceFile.good():
        ShowFatalError(state, f"SetupAirLoopControllersTracer: Failed to open air loop trace file \"{TraceFilePath}\" for output (write).")

    TraceFile = airLoopStats.TraceFile
    TraceFile.write("Num,Name,\n")

    for ControllerNum in range(1, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers + 1):
        TraceFile.write(f"{ControllerNum},{state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].ControllerName[ControllerNum - 1]},\n")

    TraceFile.write("\n\n\n")
    TraceFile.write("ZoneSizingCalc,SysSizingCalc,EnvironmentNum,WarmupFlag,SysTimeStamp,SysTimeInterval,BeginTimeStepFlag,FirstTimeStepSysFlag,"
                   "FirstHVACIteration,AirLoopPass,AirLoopNumCallsTot,AirLoopConverged,")

    for ControllerNum in range(1, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers + 1):
        TraceFile.write(f"Mode{ControllerNum},IterMax{ControllerNum},XRoot{ControllerNum},YRoot{ControllerNum},YSetPoint{ControllerNum},\n")

    TraceFile.write("\n")

def TraceAirLoopControllers(state: Any, FirstHVACIteration: bool, AirLoopNum: int, AirLoopPass: int,
                           AirLoopConverged: bool, AirLoopNumCalls: int) -> None:
    airLoopStats = state.dataHVACControllers.AirLoopStats[AirLoopNum - 1]

    if state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers == 0:
        return
    if state.dataHVACControllers.NumAirLoopStats == 0:
        return

    if airLoopStats.FirstTraceFlag:
        SetupAirLoopControllersTracer(state, AirLoopNum)
        airLoopStats.FirstTraceFlag = False

    TraceFile = airLoopStats.TraceFile

    if not TraceFile.good():
        return

    TraceIterationStamp(state, TraceFile, FirstHVACIteration, AirLoopPass, AirLoopConverged, AirLoopNumCalls)

    for ControllerNum in range(1, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumControllers + 1):
        TraceAirLoopController(state, TraceFile, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].ControllerIndex[ControllerNum - 1])

    TraceFile.write("\n")

def TraceIterationStamp(state: Any, TraceFile: Any, FirstHVACIteration: bool, AirLoopPass: int,
                       AirLoopConverged: bool, AirLoopNumCalls: int) -> None:
    TraceFile.write(f"{int(state.dataGlobal.ZoneSizingCalc)},{int(state.dataGlobal.SysSizingCalc)},{state.dataEnvrn.CurEnvirNum},"
                   f"{int(state.dataGlobal.WarmupFlag)},{CreateHVACTimeString(state)},{MakeHVACTimeIntervalString(state)},"
                   f"{int(state.dataGlobal.BeginTimeStepFlag)},{int(state.dataHVACGlobal.FirstTimeStepSysFlag)},{int(FirstHVACIteration)},"
                   f"{AirLoopPass},{AirLoopNumCalls},{int(AirLoopConverged)},")

def TraceAirLoopController(state: Any, TraceFile: Any, ControlNum: int) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    TraceFile.write(f"{controllerProps.Mode},{controllerProps.NumCalcCalls},{state.dataLoopNodes.Node[controllerProps.ActuatedNode - 1].MassFlowRate:.10f},"
                   f"{state.dataLoopNodes.Node[controllerProps.SensedNode - 1].Temp:.10f},{state.dataLoopNodes.Node[controllerProps.SensedNode - 1].TempSetPoint:.10f},")

def SetupIndividualControllerTracer(state: Any, ControlNum: int) -> None:
    controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    TraceFilePath = f"controller.{controllerProps.ControllerName}.csv"
    TraceFile = controllerProps.TraceFile
    TraceFile.filePath = TraceFilePath
    TraceFile.open()

    if not TraceFile.good():
        ShowFatalError(state, f"SetupIndividualControllerTracer: Failed to open controller trace file \"{TraceFilePath}\" for output (write).")

    TraceFile.write("EnvironmentNum,WarmupFlag,SysTimeStamp,SysTimeInterval,AirLoopPass,FirstHVACIteration,Operation,NumCalcCalls,SensedNode%MassFlowRate,"
                   "ActuatedNode%MassFlowRateMinAvail,ActuatedNode%MassFlowRateMaxAvail,X,Y,Setpoint,DeltaSensed,Offset,Mode,IsConvergedFlag,"
                   "NextActuatedValue")
    RootFinder.WriteRootFinderTraceHeader(TraceFile)
    TraceFile.write("\n")

def TraceIndividualController(state: Any, ControlNum: int, FirstHVACIteration: bool, AirLoopPass: int,
                             Operation: Any, IsConvergedFlag: bool) -> None:
    ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if ControllerProps.FirstTraceFlag:
        SetupIndividualControllerTracer(state, ControlNum)
        ControllerProps.FirstTraceFlag = False
        SkipLineFlag = False
    else:
        SkipLineFlag = FirstHVACIteration and (ControllerProps.NumCalcCalls == 0)

    TraceFile = ControllerProps.TraceFile

    if not TraceFile.good():
        return

    if SkipLineFlag:
        TraceFile.write("\n")

    ActuatedNode = ControllerProps.ActuatedNode
    SensedNode = ControllerProps.SensedNode

    TraceFile.write(f"{state.dataEnvrn.CurEnvirNum},{int(state.dataGlobal.WarmupFlag)},{CreateHVACTimeString(state)},"
                   f"{MakeHVACTimeIntervalString(state)},{AirLoopPass},{int(FirstHVACIteration)},{int(Operation)},{ControllerProps.NumCalcCalls},")

    if Operation in [ControllerOperation.ColdStart, ControllerOperation.WarmRestart]:
        TraceFile.write(f"{state.dataLoopNodes.Node[SensedNode - 1].MassFlowRate:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail:.10f},"
                       f"{ControllerProps.ActuatedValue:.10f},"
                       f"{state.dataLoopNodes.Node[SensedNode - 1].Temp:.10f},"
                       f"{ControllerProps.SetPointValue:.10f}, , ,"
                       f"{ControllerProps.Mode},{int(IsConvergedFlag)},{ControllerProps.NextActuatedValue:.10f},\n")
    elif Operation == ControllerOperation.Iterate:
        TraceFile.write(f"{state.dataLoopNodes.Node[SensedNode - 1].MassFlowRate:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail:.10f},"
                       f"{ControllerProps.ActuatedValue:.10f},"
                       f"{state.dataLoopNodes.Node[SensedNode - 1].Temp:.10f},"
                       f"{ControllerProps.SetPointValue:.10f},"
                       f"{ControllerProps.DeltaSensed:.10f},"
                       f"{ControllerProps.Offset:.10f},"
                       f"{ControllerProps.Mode},{int(IsConvergedFlag)},{ControllerProps.NextActuatedValue:.10f},")
        RootFinder.WriteRootFinderTrace(TraceFile, state.dataHVACControllers.RootFinders[ControlNum - 1])
        TraceFile.write("\n")
    elif Operation == ControllerOperation.End:
        TraceFile.write(f"{state.dataLoopNodes.Node[SensedNode - 1].MassFlowRate:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail:.10f},"
                       f"{state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail:.10f},"
                       f"{ControllerProps.ActuatedValue:.10f},"
                       f"{state.dataLoopNodes.Node[SensedNode - 1].Temp:.10f},"
                       f"{ControllerProps.SetPointValue:.10f},"
                       f"{ControllerProps.DeltaSensed:.10f},"
                       f"{ControllerProps.Offset:.10f},"
                       f"{ControllerProps.Mode},{int(IsConvergedFlag)},{ControllerProps.NextActuatedValue:.10f},\n\n")

    TraceFile.flush()

def GetCurrentHVACTime(state: Any) -> float:
    CurrentHVACTime = (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone) + state.dataHVACGlobal.SysTimeElapsed + state.dataHVACGlobal.TimeStepSys
    return CurrentHVACTime * 3600.0

def GetPreviousHVACTime(state: Any) -> float:
    PreviousHVACTime = (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone) + state.dataHVACGlobal.SysTimeElapsed
    return PreviousHVACTime * 3600.0

def CreateHVACTimeString(state: Any) -> str:
    Buffer = General.CreateTimeString(GetCurrentHVACTime(state))
    return state.dataEnvrn.CurMnDy + ' ' + Buffer.strip()

def CreateHVACStepFullString(state: Any) -> str:
    return state.dataEnvrn.EnvironmentName + ", " + MakeHVACTimeIntervalString(state)

def MakeHVACTimeIntervalString(state: Any) -> str:
    return f"{General.CreateTimeString(GetPreviousHVACTime(state))} - {General.CreateTimeString(GetCurrentHVACTime(state))}"

def CheckControllerListOrder(state: Any) -> None:
    for AirSysNum in range(state.dataHVACGlobal.NumPrimaryAirSys):
        if state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].NumControllers > 1:
            WaterCoilContrlCount = 0
            for ContrlNum in range(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].NumControllers):
                if Util.SameString(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].ControllerType[ContrlNum], "CONTROLLER:WATERCOIL"):
                    WaterCoilContrlCount += 1

            if WaterCoilContrlCount > 1:
                ContrlSensedNodeNums = [[0, 0, 0] for _ in range(WaterCoilContrlCount)]
                SensedNodeIndex = 0
                for ContrlNum in range(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].NumControllers):
                    if Util.SameString(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].ControllerType[ContrlNum], "CONTROLLER:WATERCOIL"):
                        foundControl = Util.FindItemInList(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].ControllerName[ContrlNum],
                                                          state.dataHVACControllers.ControllerProps, lambda x: x.ControllerName)
                        if foundControl > 0:
                            ContrlSensedNodeNums[SensedNodeIndex][0] = state.dataHVACControllers.ControllerProps[foundControl - 1].SensedNode
                        SensedNodeIndex += 1

                for BranchNum in range(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].NumBranches):
                    for SensedNodeIndex in range(WaterCoilContrlCount):
                        for BranchNodeIndex in range(state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].Branch[BranchNum].TotalNodes):
                            if ContrlSensedNodeNums[SensedNodeIndex][0] == state.dataAirSystemsData.PrimaryAirSystems[AirSysNum].Branch[BranchNum].NodeNum[BranchNodeIndex]:
                                ContrlSensedNodeNums[SensedNodeIndex][1] = BranchNodeIndex + 1
                                ContrlSensedNodeNums[SensedNodeIndex][2] = BranchNum + 1

                for SensedNodeIndex in range(1, WaterCoilContrlCount):
                    if ContrlSensedNodeNums[SensedNodeIndex][1] < ContrlSensedNodeNums[SensedNodeIndex - 1][1]:
                        if ContrlSensedNodeNums[SensedNodeIndex][2] == ContrlSensedNodeNums[SensedNodeIndex - 1][2]:
                            ShowSevereError(state, "CheckControllerListOrder: A water coil controller list has the wrong order")

def CheckCoilWaterInletNode(state: Any, WaterInletNodeNum: int, NodeNotFound_ref: List[bool]) -> None:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    NodeNotFound_ref[0] = True
    for ControllerProps in state.dataHVACControllers.ControllerProps:
        if ControllerProps.ActuatedNode == WaterInletNodeNum:
            NodeNotFound_ref[0] = False

def GetControllerNameAndIndex(state: Any, WaterInletNodeNum: int, ControllerName_ref: List[str],
                             ControllerIndex_ref: List[int], ErrorsFound_ref: List[bool]) -> None:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    ControllerName_ref[0] = " "
    ControllerIndex_ref[0] = 0
    for ControlNum in range(state.dataHVACControllers.NumControllers):
        if state.dataHVACControllers.ControllerProps[ControlNum].ActuatedNode == WaterInletNodeNum:
            ControllerIndex_ref[0] = ControlNum + 1
            ControllerName_ref[0] = state.dataHVACControllers.ControllerProps[ControlNum].ControllerName
            break

    if ControllerIndex_ref[0] == 0:
        ErrorsFound_ref[0] = True

def GetControllerActuatorNodeNum(state: Any, ControllerName: str, WaterInletNodeNum_ref: List[int],
                                NodeNotFound_ref: List[bool]) -> None:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    NodeNotFound_ref[0] = True
    ControlNum = Util.FindItemInList(ControllerName, state.dataHVACControllers.ControllerProps, lambda x: x.ControllerName)
    if ControlNum > 0 and ControlNum <= state.dataHVACControllers.NumControllers:
        WaterInletNodeNum_ref[0] = state.dataHVACControllers.ControllerProps[ControlNum - 1].ActuatedNode
        NodeNotFound_ref[0] = False

def GetControllerIndex(state: Any, ControllerName: str) -> int:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    ControllerIndex = Util.FindItemInList(ControllerName, state.dataHVACControllers.ControllerProps, lambda x: x.ControllerName)
    if ControllerIndex == 0:
        ShowFatalError(state, f"ManageControllers: Invalid controller={ControllerName}. The only valid controller type for an AirLoopHVAC is Controller:WaterCoil.")

    return ControllerIndex
