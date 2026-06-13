# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from sys import exit
from collections import Dict, List

alias CtrlVarTypeEnum = Int32

struct CtrlVarType:
    var val: Int32
    alias Invalid = -1
    alias NoControlVariable = 0
    alias Temperature = 1
    alias HumidityRatio = 2
    alias TemperatureAndHumidityRatio = 3
    alias Flow = 4
    alias Num = 5

struct SolutionTrackerType:
    var DefinedFlag: Bool
    var ActuatedValue: Float64
    var Mode: Int32

    fn __init__(inout self) -> None:
        self.DefinedFlag = True
        self.ActuatedValue = 0.0
        self.Mode = 0

struct ControllerPropsType:
    var ControllerName: String
    var ControllerType: String
    var ControllerType_Num: Int32
    var ControlVar: Int32
    var ActuatorVar: Int32
    var Action: Int32
    var InitFirstPass: Bool
    var NumCalcCalls: Int32
    var Mode: Int32
    var DoWarmRestartFlag: Bool
    var ReuseIntermediateSolutionFlag: Bool
    var ReusePreviousSolutionFlag: Bool
    var SolutionTrackers: List[SolutionTrackerType]
    var MaxAvailActuated: Float64
    var MaxAvailSensed: Float64
    var MinAvailActuated: Float64
    var MinAvailSensed: Float64
    var MaxVolFlowActuated: Float64
    var MinVolFlowActuated: Float64
    var MaxActuated: Float64
    var MinActuated: Float64
    var ActuatedNode: Int32
    var ActuatedValue: Float64
    var NextActuatedValue: Float64
    var ActuatedNodePlantLoc: Int32
    var WaterCoilType: Int32
    var SensedNode: Int32
    var IsSetPointDefinedFlag: Bool
    var SetPointValue: Float64
    var SensedValue: Float64
    var DeltaSensed: Float64
    var Offset: Float64
    var HumRatCntrlType: Int32
    var LimitType: String
    var Range: Float64
    var Limit: Float64
    var TraceFile: Int32
    var FirstTraceFlag: Bool
    var BadActionErrCount: Int32
    var BadActionErrIndex: Int32
    var FaultyCoilSATFlag: Bool
    var FaultyCoilSATIndex: Int32
    var FaultyCoilSATOffset: Float64
    var BypassControllerCalc: Bool
    var AirLoopControllerIndex: Int32
    var HumRatCtrlOverride: Bool

    fn __init__(inout self) -> None:
        self.ControllerName = ""
        self.ControllerType = ""
        self.ControllerType_Num = 0
        self.ControlVar = CtrlVarType.NoControlVariable
        self.ActuatorVar = CtrlVarType.NoControlVariable
        self.Action = 0
        self.InitFirstPass = True
        self.NumCalcCalls = 0
        self.Mode = 0
        self.DoWarmRestartFlag = False
        self.ReuseIntermediateSolutionFlag = False
        self.ReusePreviousSolutionFlag = False
        var trackers = List[SolutionTrackerType]()
        trackers.append(SolutionTrackerType())
        trackers.append(SolutionTrackerType())
        self.SolutionTrackers = trackers
        self.MaxAvailActuated = 0.0
        self.MaxAvailSensed = 0.0
        self.MinAvailActuated = 0.0
        self.MinAvailSensed = 0.0
        self.MaxVolFlowActuated = 0.0
        self.MinVolFlowActuated = 0.0
        self.MaxActuated = 0.0
        self.MinActuated = 0.0
        self.ActuatedNode = 0
        self.ActuatedValue = 0.0
        self.NextActuatedValue = 0.0
        self.ActuatedNodePlantLoc = 0
        self.WaterCoilType = 0
        self.SensedNode = 0
        self.IsSetPointDefinedFlag = False
        self.SetPointValue = 0.0
        self.SensedValue = 0.0
        self.DeltaSensed = 0.0
        self.Offset = 0.0
        self.HumRatCntrlType = 0
        self.LimitType = ""
        self.Range = 0.0
        self.Limit = 0.0
        self.TraceFile = 0
        self.FirstTraceFlag = True
        self.BadActionErrCount = 0
        self.BadActionErrIndex = 0
        self.FaultyCoilSATFlag = False
        self.FaultyCoilSATIndex = 0
        self.FaultyCoilSATOffset = 0.0
        self.BypassControllerCalc = False
        self.AirLoopControllerIndex = 0
        self.HumRatCtrlOverride = False

struct ControllerStatsType:
    var NumCalls: List[Int32]
    var TotIterations: List[Int32]
    var MaxIterations: List[Int32]

    fn __init__(inout self) -> None:
        self.NumCalls = List[Int32]()
        self.TotIterations = List[Int32]()
        self.MaxIterations = List[Int32]()
        for _ in range(10):
            self.NumCalls.append(0)
            self.TotIterations.append(0)
            self.MaxIterations.append(0)

struct AirLoopStatsType:
    var TraceFile: Int32
    var FirstTraceFlag: Bool
    var NumCalls: Int32
    var NumFailedWarmRestarts: Int32
    var NumSuccessfulWarmRestarts: Int32
    var TotSimAirLoopComponents: Int32
    var MaxSimAirLoopComponents: Int32
    var TotIterations: Int32
    var MaxIterations: Int32
    var ControllerStats: List[ControllerStatsType]

    fn __init__(inout self) -> None:
        self.TraceFile = 0
        self.FirstTraceFlag = True
        self.NumCalls = 0
        self.NumFailedWarmRestarts = 0
        self.NumSuccessfulWarmRestarts = 0
        self.TotSimAirLoopComponents = 0
        self.MaxSimAirLoopComponents = 0
        self.TotIterations = 0
        self.MaxIterations = 0
        self.ControllerStats = List[ControllerStatsType]()

fn ControlVariableTypes(c: Int32) -> String:
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

fn ManageControllers(inout state: Any, ControllerName: String, inout ControllerIndex: Int32, FirstHVACIteration: Bool,
                    AirLoopNum: Int32, Operation: Int32, inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool,
                    BypassOAController: Bool, AllowWarmRestartFlag: Optional[Pointer[Bool]] = None) -> None:
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False

    if ControllerIndex == 0:
        var ControlNum = FindItemInList(ControllerName, state.dataHVACControllers.ControllerProps)
        if ControlNum == 0:
            var msg = "ManageControllers: Invalid controller=" + ControllerName + ". The only valid controller type for an AirLoopHVAC is Controller:WaterCoil."
            ShowFatalError(state, msg)
        ControllerIndex = ControlNum
    else:
        var ControlNum = ControllerIndex
        if ControlNum > state.dataHVACControllers.NumControllers or ControlNum < 1:
            var msg = "ManageControllers: Invalid ControllerIndex passed=" + str(ControlNum) + ", Number of controllers=" + str(state.dataHVACControllers.NumControllers) + ", Controller name=" + ControllerName
            ShowFatalError(state, msg)

    var controllerProps = state.dataHVACControllers.ControllerProps[ControllerIndex - 1]

    if controllerProps.BypassControllerCalc and BypassOAController:
        IsUpToDateFlag = True
        IsConvergedFlag = True
        if AllowWarmRestartFlag:
            AllowWarmRestartFlag.pointee = True
        return

    if controllerProps.ActuatedNodePlantLoc > 0:
        # Check plant lock status
        pass

    if AllowWarmRestartFlag:
        if controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
            AllowWarmRestartFlag.pointee = False
        else:
            AllowWarmRestartFlag.pointee = True

    if controllerProps.InitFirstPass:
        InitController(state, ControlIndex, IsConvergedFlag)
        controllerProps.InitFirstPass = False

    if Operation == 0:  # ColdStart
        if controllerProps.HumRatCtrlOverride:
            controllerProps.HumRatCtrlOverride = False
        ResetController(state, ControlIndex, False, IsConvergedFlag)
        UpdateController(state, ControlIndex)
    elif Operation == 1:  # WarmRestart
        ResetController(state, ControlIndex, True, IsConvergedFlag)
        UpdateController(state, ControlIndex)
    elif Operation == 2:  # Iterate
        InitController(state, ControlIndex, IsConvergedFlag)
        var ControllerType = controllerProps.ControllerType_Num
        if ControllerType == 0:
            CalcSimpleController(state, ControlIndex, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)
        UpdateController(state, ControlIndex)
        CheckTempAndHumRatCtrl(state, ControlIndex, IsConvergedFlag)
    elif Operation == 3:  # End
        InitController(state, ControlIndex, IsConvergedFlag)
        var ControllerType = controllerProps.ControllerType_Num
        if ControllerType == 0:
            CheckSimpleController(state, ControlIndex, IsConvergedFlag)
            SaveSimpleController(state, ControlIndex, FirstHVACIteration, IsConvergedFlag)

fn GetControllerInput(inout state: Any) -> None:
    var NumPrimaryAirSys = state.dataHVACGlobal.NumPrimaryAirSys
    var CurrentModuleObject = "Controller:WaterCoil"
    var NumSimpleControllers = 0  # state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACControllers.NumControllers = NumSimpleControllers

    if state.dataHVACControllers.NumControllers == 0:
        return

    for _ in range(NumSimpleControllers):
        var props = ControllerPropsType()
        state.dataHVACControllers.ControllerProps.append(props)

fn ResetController(inout state: Any, ControlNum: Int32, DoWarmRestartFlag: Bool, inout IsConvergedFlag: Bool) -> None:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

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
        controllerProps.Mode = 0
        controllerProps.NextActuatedValue = 0.0

    controllerProps.ReusePreviousSolutionFlag = True
    controllerProps.ReuseIntermediateSolutionFlag = False
    IsConvergedFlag = False

fn InitController(inout state: Any, ControlNum: Int32, inout IsConvergedFlag: Bool) -> None:
    var thisController = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if state.dataHVACControllers.InitControllerOneTimeFlag:
        state.dataHVACControllers.InitControllerOneTimeFlag = False

    if not state.dataGlobal.SysSizingCalc and state.dataHVACControllers.InitControllerSetPointCheckFlag:
        pass

    if state.dataHVACControllers.MySizeFlag[ControlNum - 1]:
        SizeController(state, ControlNum)
        state.dataHVACControllers.MySizeFlag[ControlNum - 1] = False

    var ActuatedNode = thisController.ActuatedNode
    var SensedNode = thisController.SensedNode

    if state.dataGlobal.BeginEnvrnFlag and state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1]:
        thisController.MinActuated = 0.0
        thisController.MaxActuated = 0.0
        thisController.ReusePreviousSolutionFlag = False
        state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHVACControllers.MyEnvrnFlag[ControlNum - 1] = True

    IsConvergedFlag = False

    if thisController.ControlVar == CtrlVarType.Temperature:
        thisController.SensedValue = 0.0
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = 0.0
            thisController.IsSetPointDefinedFlag = True
    elif thisController.ControlVar == CtrlVarType.Flow:
        thisController.SensedValue = 0.0
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = 0.0
            thisController.IsSetPointDefinedFlag = True

    if thisController.ActuatorVar == CtrlVarType.Flow:
        thisController.ActuatedValue = 0.0
        if thisController.NumCalcCalls == 0:
            thisController.MinAvailActuated = max(0.0, thisController.MinActuated)
            thisController.MaxAvailActuated = min(0.0, thisController.MaxActuated)

    if thisController.IsSetPointDefinedFlag:
        thisController.DeltaSensed = thisController.SensedValue - thisController.SetPointValue
    else:
        thisController.DeltaSensed = 0.0

fn SizeController(inout state: Any, ControlNum: Int32) -> None:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if controllerProps.MaxVolFlowActuated <= 0.0:
        controllerProps.MaxVolFlowActuated = 0.0

    if controllerProps.Offset <= 0.0:
        controllerProps.Offset = (0.001 / (2100.0 * max(controllerProps.MaxVolFlowActuated, 0.00001))) * (100.0 / 10.0)

fn CalcSimpleController(inout state: Any, ControlNum: Int32, FirstHVACIteration: Bool,
                       inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool, ControllerName: String) -> None:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    controllerProps.NumCalcCalls += 1

    if controllerProps.NumCalcCalls == 1:
        if not controllerProps.IsSetPointDefinedFlag:
            ShowSevereError(state, "CalcSimpleController: Setpoint not defined")

    if controllerProps.ReuseIntermediateSolutionFlag:
        FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)
    else:
        FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)

fn FindRootSimpleController(inout state: Any, ControlNum: Int32, FirstHVACIteration: Bool,
                           inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool, ControllerName: String) -> None:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    controllerProps.NextActuatedValue = controllerProps.ActuatedValue
    IsConvergedFlag = True

fn CheckSimpleController(inout state: Any, ControlNum: Int32, inout IsConvergedFlag: Bool) -> None:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    IsConvergedFlag = False

    if controllerProps.Mode == 0:
        if controllerProps.ActuatedValue == 0.0:
            IsConvergedFlag = True

fn CheckMinActiveController(inout state: Any, ControlNum: Int32) -> Bool:
    var controllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if controllerProps.ActuatedValue != controllerProps.MinAvailActuated:
        return False

    if controllerProps.Action == 1:
        if controllerProps.SetPointValue <= controllerProps.SensedValue:
            return True
    elif controllerProps.Action == 2:
        if controllerProps.SetPointValue >= controllerProps.SensedValue:
            return True

    return False

fn CheckMaxActiveController(inout state: Any, ControlNum: Int32) -> Bool:
    var ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if ControllerProps.ActuatedValue != ControllerProps.MaxAvailActuated:
        return False

    if ControllerProps.Action == 1:
        if ControllerProps.SetPointValue >= ControllerProps.SensedValue:
            return True
    elif ControllerProps.Action == 2:
        if ControllerProps.SetPointValue <= ControllerProps.SensedValue:
            return True

    return False

fn CheckTempAndHumRatCtrl(inout state: Any, ControlNum: Int32, inout IsConvergedFlag: Bool) -> None:
    var thisController = state.dataHVACControllers.ControllerProps[ControlNum - 1]
    if IsConvergedFlag:
        if thisController.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
            if not thisController.HumRatCtrlOverride:
                IsConvergedFlag = False
                thisController.HumRatCtrlOverride = True
                ResetController(state, ControlNum, False, IsConvergedFlag)

fn SaveSimpleController(inout state: Any, ControlNum: Int32, FirstHVACIteration: Bool, IsConvergedFlag: Bool) -> None:
    var ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if IsConvergedFlag:
        var PreviousSolutionIndex = 0 if FirstHVACIteration else 1
        if ControllerProps.Mode == 1:
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].DefinedFlag = True
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].Mode = ControllerProps.Mode
            ControllerProps.SolutionTrackers[PreviousSolutionIndex].ActuatedValue = ControllerProps.NextActuatedValue

fn UpdateController(inout state: Any, ControlNum: Int32) -> None:
    var ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    if ControllerProps.ActuatorVar == CtrlVarType.Flow:
        pass

fn ExitCalcController(inout state: Any, ControlNum: Int32, NextActuatedValue: Float64, Mode: Int32,
                     inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool) -> None:
    var ControllerProps = state.dataHVACControllers.ControllerProps[ControlNum - 1]

    ControllerProps.NextActuatedValue = NextActuatedValue
    ControllerProps.Mode = Mode
    IsConvergedFlag = True

    if ControllerProps.ActuatedValue != ControllerProps.NextActuatedValue:
        IsUpToDateFlag = False
    else:
        IsUpToDateFlag = True

fn TrackAirLoopControllers(inout state: Any, AirLoopNum: Int32, WarmRestartStatus: Int32,
                          AirLoopIterMax: Int32, AirLoopIterTot: Int32, AirLoopNumCalls: Int32) -> None:
    pass

fn TrackAirLoopController(inout state: Any, AirLoopNum: Int32, AirLoopControlNum: Int32) -> None:
    pass

fn DumpAirLoopStatistics(inout state: Any) -> None:
    pass

fn WriteAirLoopStatistics(inout state: Any, statisticsFile: Any, ThisPrimaryAirSystem: Any, ThisAirLoopStats: AirLoopStatsType) -> None:
    pass

fn SetupAirLoopControllersTracer(inout state: Any, AirLoopNum: Int32) -> None:
    pass

fn TraceAirLoopControllers(inout state: Any, FirstHVACIteration: Bool, AirLoopNum: Int32, AirLoopPass: Int32,
                          AirLoopConverged: Bool, AirLoopNumCalls: Int32) -> None:
    pass

fn TraceIterationStamp(inout state: Any, TraceFile: Any, FirstHVACIteration: Bool, AirLoopPass: Int32,
                      AirLoopConverged: Bool, AirLoopNumCalls: Int32) -> None:
    pass

fn TraceAirLoopController(inout state: Any, TraceFile: Any, ControlNum: Int32) -> None:
    pass

fn SetupIndividualControllerTracer(inout state: Any, ControlNum: Int32) -> None:
    pass

fn TraceIndividualController(inout state: Any, ControlNum: Int32, FirstHVACIteration: Bool, AirLoopPass: Int32,
                            Operation: Int32, IsConvergedFlag: Bool) -> None:
    pass

fn GetCurrentHVACTime(state: Any) -> Float64:
    return (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed + state.dataHVACGlobal.TimeStepSys) * 3600.0

fn GetPreviousHVACTime(state: Any) -> Float64:
    return (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed) * 3600.0

fn CreateHVACTimeString(state: Any) -> String:
    return state.dataEnvrn.CurMnDy

fn CreateHVACStepFullString(state: Any) -> String:
    return state.dataEnvrn.EnvironmentName

fn MakeHVACTimeIntervalString(state: Any) -> String:
    return ""

fn CheckControllerListOrder(inout state: Any) -> None:
    pass

fn CheckCoilWaterInletNode(inout state: Any, WaterInletNodeNum: Int32, inout NodeNotFound: Bool) -> None:
    NodeNotFound = True

fn GetControllerNameAndIndex(inout state: Any, WaterInletNodeNum: Int32, inout ControllerName: String,
                            inout ControllerIndex: Int32, inout ErrorsFound: Bool) -> None:
    ControllerName = ""
    ControllerIndex = 0
    ErrorsFound = False

fn GetControllerActuatorNodeNum(inout state: Any, ControllerName: String, inout WaterInletNodeNum: Int32,
                               inout NodeNotFound: Bool) -> None:
    NodeNotFound = True

fn GetControllerIndex(inout state: Any, ControllerName: String) -> Int32:
    return 0

fn FindItemInList(name: String, props: List[ControllerPropsType]) -> Int32:
    return 0

fn ShowFatalError(inout state: Any, msg: String) -> None:
    print("FATAL ERROR:", msg)
    exit(1)

fn ShowSevereError(inout state: Any, msg: String) -> None:
    print("SEVERE ERROR:", msg)

fn ShowContinueError(inout state: Any, msg: String) -> None:
    print("  ", msg)

fn ShowWarningError(inout state: Any, msg: String) -> None:
    print("WARNING:", msg)

fn ShowContinueErrorTimeStamp(inout state: Any, msg: String) -> None:
    print("  (Time:", msg, ")")

fn ShowRecurringSevereErrorAtEnd(inout state: Any, msg: String, inout index: Int32) -> None:
    print("RECURRING SEVERE ERROR:", msg)
