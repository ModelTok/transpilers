from DataAirSystems import DefinePrimaryAirSystem
from DataHVACControllers import ControllerAction, ControllerMode, ControllerSimple_Type, iFirstMode, iLastMode
from DataRootFinder import RootFinderDataType
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.Optional import Optional
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from DataAirSystems import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.EnergyPlus import *
from SetPointManager import *
from DataAirSystems import DefinePrimaryAirSystem
from DataHVACControllers import ControllerAction, ControllerMode, ControllerSimple_Type, iFirstMode, iLastMode
from DataRootFinder import RootFinderDataType
from Array.functions import *
from Array2D import Array2D
from Fmath import *
from numerical import *
from string.functions import *
from .Autosizing.Base import *
from .Data.EnergyPlusData import EnergyPlusData
from DataAirSystems import *
from EnergyPlus.DataConvergParams import *
from DataEnvironment import *
from DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataPrecisionGlobals import *
from DataSizing import *
from DataSystemVariables import *
from EMSManager import *
from FaultsManager import *
from FluidProperties import *
from General import *
from IOFiles import *
from .InputProcessing.InputProcessor import *
from MixedAir import *
from NodeInputManager import *
from PlantUtilities import *
from Psychrometrics import *
from RootFinder import *
from SetPointManager import *
from UtilityRoutines import *
from WaterCoils import *
from string import format
from format import format

enum CtrlVarType(Int32):
    Invalid = -1
    NoControlVariable = 0
    Temperature = 1
    HumidityRatio = 2
    TemperatureAndHumidityRatio = 3
    Flow = 4
    Num = 5

@value
struct SolutionTrackerType:
    var DefinedFlag: Bool = True
    var ActuatedValue: Float64 = 0.0
    var Mode: ControllerMode = ControllerMode.None

@value
struct ControllerPropsType:
    var ControllerName: String = ""
    var ControllerType: String = ""
    var ControllerType_Num: Int32 = ControllerSimple_Type
    var ControlVar: CtrlVarType = CtrlVarType.NoControlVariable
    var ActuatorVar: CtrlVarType = CtrlVarType.NoControlVariable
    var Action: ControllerAction = ControllerAction.NoAction
    var InitFirstPass: Bool = True
    var NumCalcCalls: Int32 = 0
    var Mode: ControllerMode = ControllerMode.None
    var DoWarmRestartFlag: Bool = False
    var ReuseIntermediateSolutionFlag: Bool = False
    var ReusePreviousSolutionFlag: Bool = False
    var SolutionTrackers: Array1D[SolutionTrackerType] = Array1D[SolutionTrackerType](2)
    var MaxAvailActuated: Float64 = 0.0
    var MaxAvailSensed: Float64 = 0.0
    var MinAvailActuated: Float64 = 0.0
    var MinAvailSensed: Float64 = 0.0
    var MaxVolFlowActuated: Float64 = 0.0
    var MinVolFlowActuated: Float64 = 0.0
    var MaxActuated: Float64 = 0.0
    var MinActuated: Float64 = 0.0
    var ActuatedNode: Int32 = 0
    var ActuatedValue: Float64 = 0.0
    var NextActuatedValue: Float64 = 0.0
    var ActuatedNodePlantLoc: PlantLocation = PlantLocation()
    var WaterCoilType: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var SensedNode: Int32 = 0
    var IsSetPointDefinedFlag: Bool = False
    var SetPointValue: Float64 = 0.0
    var SensedValue: Float64 = 0.0
    var DeltaSensed: Float64 = 0.0
    var Offset: Float64 = 0.0
    var HumRatCntrlType: HVAC.CtrlVarType = HVAC.CtrlVarType.Invalid
    var LimitType: String = ""
    var Range: Float64 = 0.0
    var Limit: Float64 = 0.0
    var TraceFile: SharedFileHandle = SharedFileHandle()
    var FirstTraceFlag: Bool = True
    var BadActionErrCount: Int32 = 0
    var BadActionErrIndex: Int32 = 0
    var FaultyCoilSATFlag: Bool = False
    var FaultyCoilSATIndex: Int32 = 0
    var FaultyCoilSATOffset: Float64 = 0.0
    var BypassControllerCalc: Bool = False
    var AirLoopControllerIndex: Int32 = 0
    var HumRatCtrlOverride: Bool = False

@value
struct ControllerStatsType:
    var NumCalls: Array1D_int = Array1D_int({iFirstMode, iLastMode}, 0)
    var TotIterations: Array1D_int = Array1D_int({iFirstMode, iLastMode}, 0)
    var MaxIterations: Array1D_int = Array1D_int({iFirstMode, iLastMode}, 0)

@value
struct AirLoopStatsType:
    var TraceFile: SharedFileHandle = SharedFileHandle()
    var FirstTraceFlag: Bool = True
    var NumCalls: Int32 = 0
    var NumFailedWarmRestarts: Int32 = 0
    var NumSuccessfulWarmRestarts: Int32 = 0
    var TotSimAirLoopComponents: Int32 = 0
    var MaxSimAirLoopComponents: Int32 = 0
    var TotIterations: Int32 = 0
    var MaxIterations: Int32 = 0
    var ControllerStats: Array1D[ControllerStatsType] = Array1D[ControllerStatsType]()

def ManageControllers(inout state: EnergyPlusData, ControllerName: String, inout ControllerIndex: Int32, FirstHVACIteration: Bool, AirLoopNum: Int32, Operation: DataHVACControllers.ControllerOperation, inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool, BypassOAController: Bool, AllowWarmRestartFlag: Optional[Bool] = Optional[Bool]()):
    var ControlNum: Int32 = 0
    if state.dataHVACControllers.GetControllerInputFlag:
        GetControllerInput(state)
        state.dataHVACControllers.GetControllerInputFlag = False
    if ControllerIndex == 0:
        ControlNum = Util.FindItemInList(ControllerName, state.dataHVACControllers.ControllerProps, ControllerPropsType.ControllerName)
        if ControlNum == 0:
            ShowFatalError(state, format("ManageControllers: Invalid controller={}. The only valid controller type for an AirLoopHVAC is Controller:WaterCoil.", ControllerName))
        ControllerIndex = ControlNum
    else:
        ControlNum = ControllerIndex
        if ControlNum > state.dataHVACControllers.NumControllers or ControlNum < 1:
            ShowFatalError(state, format("ManageControllers: Invalid ControllerIndex passed={}, Number of controllers={}, Controller name={}", ControlNum, state.dataHVACControllers.NumControllers, ControllerName))
        if state.dataHVACControllers.CheckEquipName[ControlNum]:
            if ControllerName != state.dataHVACControllers.ControllerProps[ControlNum].ControllerName:
                ShowFatalError(state, format("ManageControllers: Invalid ControllerIndex passed={}, Controller name={}, stored Controller Name for that index={}", ControlNum, ControllerName, state.dataHVACControllers.ControllerProps[ControlNum].ControllerName))
            state.dataHVACControllers.CheckEquipName[ControlNum] = False
    var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    if controllerProps.BypassControllerCalc and BypassOAController:
        IsUpToDateFlag = True
        IsConvergedFlag = True
        if AllowWarmRestartFlag.present:
            AllowWarmRestartFlag.unwrap = True
        return
    if controllerProps.ActuatedNodePlantLoc.loopNum > 0:
        if state.dataPlnt.PlantLoop[controllerProps.ActuatedNodePlantLoc.loopNum].LoopSide[controllerProps.ActuatedNodePlantLoc.loopSideNum].FlowLock == DataPlant.FlowLock.Locked:
            UpdateController(state, ControlNum)
            IsConvergedFlag = True
            return
    if AllowWarmRestartFlag.present:
        if controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
            AllowWarmRestartFlag.unwrap = False
        else:
            AllowWarmRestartFlag.unwrap = True
    if controllerProps.InitFirstPass:
        InitController(state, ControlNum, IsConvergedFlag)
        controllerProps.InitFirstPass = False
    if Operation == DataHVACControllers.ControllerOperation.ColdStart:
        if controllerProps.HumRatCtrlOverride:
            controllerProps.HumRatCtrlOverride = False
            RootFinder.SetupRootFinder(state, state.dataHVACControllers.RootFinders[ControlNum], DataRootFinder.Slope.Decreasing, DataRootFinder.RootFinderMethod.Brent, DataPrecisionGlobals.constant_zero, 1.0e-6, controllerProps.Offset)
        ResetController(state, ControlNum, False, IsConvergedFlag)
        UpdateController(state, ControlNum)
    elif Operation == DataHVACControllers.ControllerOperation.WarmRestart:
        ResetController(state, ControlNum, True, IsConvergedFlag)
        UpdateController(state, ControlNum)
    elif Operation == DataHVACControllers.ControllerOperation.Iterate:
        InitController(state, ControlNum, IsConvergedFlag)
        var ControllerType: Int32 = controllerProps.ControllerType_Num
        if ControllerType == ControllerSimple_Type:
            CalcSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)
        else:
            ShowFatalError(state, format("Invalid controller type in ManageControllers={}", controllerProps.ControllerType))
        UpdateController(state, ControlNum)
        CheckTempAndHumRatCtrl(state, ControlNum, IsConvergedFlag)
    elif Operation == DataHVACControllers.ControllerOperation.End:
        InitController(state, ControlNum, IsConvergedFlag)
        var ControllerType: Int32 = controllerProps.ControllerType_Num
        if ControllerType == ControllerSimple_Type:
            CheckSimpleController(state, ControlNum, IsConvergedFlag)
            SaveSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag)
        else:
            ShowFatalError(state, format("Invalid controller type in ManageControllers={}", controllerProps.ControllerType))
    else:
        ShowFatalError(state, format("ManageControllers: Invalid Operation passed={}, Controller name={}", Int32(Operation), ControllerName))
    if state.dataSysVars.TraceHVACControllerEnvFlag:
        TraceIndividualController(state, ControlNum, FirstHVACIteration, state.dataAirLoop.AirLoopControlInfo[AirLoopNum].AirLoopPass, Operation, IsConvergedFlag)

def GetControllerInput(inout state: EnergyPlusData):
    var NumPrimaryAirSys: Int32 = state.dataHVACGlobal.NumPrimaryAirSys
    var RoutineName: StringLiteral = "HVACControllers: GetControllerInput: "
    var NumAlphas: Int32
    var NumNums: Int32
    var NumArgs: Int32
    var ActuatorNodeNotFound: Bool
    var NumArray: Array1D[Float64]
    var AlphArray: Array1D[String]
    var cAlphaFields: Array1D[String]
    var cNumericFields: Array1D[String]
    var lAlphaBlanks: Array1D[Bool]
    var lNumericBlanks: Array1D[Bool]
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String = "Controller:WaterCoil"
    var NumSimpleControllers: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACControllers.NumControllers = NumSimpleControllers
    if state.dataSysVars.TrackAirLoopEnvFlag or state.dataSysVars.TraceAirLoopEnvFlag or state.dataSysVars.TraceHVACControllerEnvFlag:
        if NumPrimaryAirSys > 0:
            state.dataHVACControllers.NumAirLoopStats = NumPrimaryAirSys
            state.dataHVACControllers.AirLoopStats.allocate(state.dataHVACControllers.NumAirLoopStats)
            for AirLoopNum in range(1, NumPrimaryAirSys + 1):
                state.dataHVACControllers.AirLoopStats[AirLoopNum].ControllerStats.allocate(state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].NumControllers)
    if state.dataHVACControllers.NumControllers == 0:
        return
    state.dataHVACControllers.ControllerProps.allocate(state.dataHVACControllers.NumControllers)
    state.dataHVACControllers.RootFinders.allocate(state.dataHVACControllers.NumControllers)
    state.dataHVACControllers.CheckEquipName.dimension(state.dataHVACControllers.NumControllers, True)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumArgs, NumAlphas, NumNums)
    AlphArray.allocate(NumAlphas)
    cAlphaFields.allocate(NumAlphas)
    cNumericFields.allocate(NumNums)
    NumArray.dimension(NumNums, 0.0)
    lAlphaBlanks.dimension(NumAlphas, True)
    lNumericBlanks.dimension(NumNums, True)
    if NumSimpleControllers > 0:
        var IOStat: Int32
        for Num in range(1, NumSimpleControllers + 1):
            var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[Num]
            state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Num, AlphArray, NumAlphas, NumArray, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
            controllerProps.ControllerName = AlphArray[1]
            controllerProps.ControllerType = CurrentModuleObject
            controllerProps.ControlVar = CtrlVarType(getEnumValue(ctrlVarNamesUC, AlphArray[2]))
            if controllerProps.ControlVar == CtrlVarType.Invalid:
                ShowSevereError(state, format("{}{}=\"{}\".", RoutineName, CurrentModuleObject, AlphArray[1]))
                ShowContinueError(state, format("...Invalid {}=\"{}\", must be Temperature, HumidityRatio, or TemperatureAndHumidityRatio.", cAlphaFields[2], AlphArray[2]))
                ErrorsFound = True
            controllerProps.Action = ControllerAction(getEnumValue(actionNamesUC, AlphArray[3]))
            if controllerProps.Action == ControllerAction.Invalid:
                ShowSevereError(state, format("{}{}=\"{}\".", RoutineName, CurrentModuleObject, AlphArray[1]))
                ShowContinueError(state, format("...Invalid {}=\"{}{}", cAlphaFields[3], AlphArray[3], "\", must be \"Normal\", \"Reverse\" or blank."))
                ErrorsFound = True
            if AlphArray[4] == "FLOW":
                controllerProps.ActuatorVar = CtrlVarType.Flow
            else:
                ShowSevereError(state, format("{}{}=\"{}\".", RoutineName, CurrentModuleObject, AlphArray[1]))
                ShowContinueError(state, format("...Invalid {}=\"{}\", only FLOW is allowed.", cAlphaFields[4], AlphArray[4]))
                ErrorsFound = True
            controllerProps.SensedNode = Node.GetOnlySingleNode(state, AlphArray[5], ErrorsFound, Node.ConnectionObjectType.ControllerWaterCoil, AlphArray[1], Node.FluidType.Blank, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            controllerProps.ActuatedNode = Node.GetOnlySingleNode(state, AlphArray[6], ErrorsFound, Node.ConnectionObjectType.ControllerWaterCoil, AlphArray[1], Node.FluidType.Blank, Node.ConnectionType.Actuator, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            controllerProps.Offset = NumArray[1]
            controllerProps.MaxVolFlowActuated = NumArray[2]
            controllerProps.MinVolFlowActuated = NumArray[3]
            if not MixedAir.CheckForControllerWaterCoil(state, DataAirLoop.ControllerKind.WaterCoil, AlphArray[1]):
                ShowSevereError(state, format("{}{}=\"{}\" not found on any AirLoopHVAC:ControllerList.", RoutineName, CurrentModuleObject, AlphArray[1]))
                ErrorsFound = True
            if controllerProps.SensedNode > 0:
                var NodeNotFound: Bool
                if controllerProps.ControlVar == CtrlVarType.HumidityRatio or controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
                    SetPointManager.ResetHumidityRatioCtrlVarType(state, controllerProps.SensedNode)
                WaterCoils.CheckForSensorAndSetPointNode(state, controllerProps.SensedNode, controllerProps.ControlVar, NodeNotFound)
                if NodeNotFound:
                    ShowWarningError(state, format("{}{}=\"{}\". ", RoutineName, controllerProps.ControllerType, controllerProps.ControllerName))
                    ShowContinueError(state, " ..Sensor node not found on water coil air outlet node.")
                    ShowContinueError(state, " ..The sensor node may have been placed on a node downstream of the coil or on an airloop outlet node.")
                else:
                    var EMSSetPointErrorFlag: Bool = False
                    if controllerProps.ControlVar == CtrlVarType.Temperature:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, controllerProps.SensedNode, HVAC.CtrlVarType.Temp, EMSSetPointErrorFlag)
                        state.dataLoopNodes.NodeSetpointCheck[controllerProps.SensedNode].needsSetpointChecking = False
                        if EMSSetPointErrorFlag:
                            if not SetPointManager.NodeHasSPMCtrlVarType(state, controllerProps.SensedNode, HVAC.CtrlVarType.Temp):
                                ShowContinueError(state, " ..Temperature setpoint not found on coil air outlet node.")
                                ShowContinueError(state, " ..The setpoint may have been placed on a node downstream of the coil or on an airloop outlet node.")
                                ShowContinueError(state, " ..Specify the setpoint and the sensor on the coil air outlet node when possible.")
                    elif controllerProps.ControlVar == CtrlVarType.HumidityRatio:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, controllerProps.SensedNode, HVAC.CtrlVarType.MaxHumRat, EMSSetPointErrorFlag)
                        state.dataLoopNodes.NodeSetpointCheck[controllerProps.SensedNode].needsSetpointChecking = False
                        if EMSSetPointErrorFlag:
                            if not SetPointManager.NodeHasSPMCtrlVarType(state, controllerProps.SensedNode, HVAC.CtrlVarType.MaxHumRat):
                                ShowContinueError(state, " ..Humidity ratio setpoint not found on coil air outlet node.")
                                ShowContinueError(state, " ..The setpoint may have been placed on a node downstream of the coil or on an airloop outlet node.")
                                ShowContinueError(state, " ..Specify the setpoint and the sensor on the coil air outlet node when possible.")
                    elif controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, controllerProps.SensedNode, HVAC.CtrlVarType.Temp, EMSSetPointErrorFlag)
                        state.dataLoopNodes.NodeSetpointCheck[controllerProps.SensedNode].needsSetpointChecking = False
                        if EMSSetPointErrorFlag:
                            if not SetPointManager.NodeHasSPMCtrlVarType(state, controllerProps.SensedNode, HVAC.CtrlVarType.Temp):
                                ShowContinueError(state, " ..Temperature setpoint not found on coil air outlet node.")
                                ShowContinueError(state, " ..The setpoint may have been placed on a node downstream of the coil or on an airloop outlet node.")
                                ShowContinueError(state, " ..Specify the setpoint and the sensor on the coil air outlet node when possible.")
                        EMSSetPointErrorFlag = False
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, controllerProps.SensedNode, HVAC.CtrlVarType.MaxHumRat, EMSSetPointErrorFlag)
                        state.dataLoopNodes.NodeSetpointCheck[controllerProps.SensedNode].needsSetpointChecking = False
                        if EMSSetPointErrorFlag:
                            if not SetPointManager.NodeHasSPMCtrlVarType(state, controllerProps.SensedNode, HVAC.CtrlVarType.MaxHumRat):
                                ShowContinueError(state, " ..Humidity ratio setpoint not found on coil air outlet node.")
                                ShowContinueError(state, " ..The setpoint may have been placed on a node downstream of the coil or on an airloop outlet node.")
                                ShowContinueError(state, " ..Specify the setpoint and the sensor on the coil air outlet node when possible.")
                    else:

    for Num in range(1, NumSimpleControllers + 1):
        var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[Num]
        WaterCoils.CheckActuatorNode(state, controllerProps.ActuatedNode, controllerProps.WaterCoilType, ActuatorNodeNotFound)
        if ActuatorNodeNotFound:
            ErrorsFound = True
            ShowSevereError(state, format("{}{}=\"{}\":", RoutineName, CurrentModuleObject, controllerProps.ControllerName))
            ShowContinueError(state, "...the actuator node must also be a water inlet node of a water coil")
        else:
            if controllerProps.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterCooling or controllerProps.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling:
                if controllerProps.Action == ControllerAction.NoAction:
                    controllerProps.Action = ControllerAction.Reverse
                elif controllerProps.Action == ControllerAction.NormalAction:
                    ShowWarningError(state, format("{}{}=\"{}\":", RoutineName, CurrentModuleObject, controllerProps.ControllerName))
                    ShowContinueError(state, "...Normal action has been specified for a cooling coil - should be Reverse.")
                    ShowContinueError(state, "...overriding user input action with Reverse Action.")
                    controllerProps.Action = ControllerAction.Reverse
            elif controllerProps.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterSimpleHeating:
                if controllerProps.Action == ControllerAction.NoAction:
                    controllerProps.Action = ControllerAction.NormalAction
                elif controllerProps.Action == ControllerAction.Reverse:
                    ShowWarningError(state, format("{}{}=\"{}\":", RoutineName, CurrentModuleObject, controllerProps.ControllerName))
                    ShowContinueError(state, "...Reverse action has been specified for a heating coil - should be Normal.")
                    ShowContinueError(state, "...overriding user input action with Normal Action.")
                    controllerProps.Action = ControllerAction.NormalAction
    AlphArray.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    NumArray.deallocate()
    lAlphaBlanks.deallocate()
    lNumericBlanks.deallocate()
    CheckControllerListOrder(state)
    if ErrorsFound:
        ShowFatalError(state, format("{}Errors found in getting {} input.", RoutineName, CurrentModuleObject))

def ResetController(inout state: EnergyPlusData, ControlNum: Int32, DoWarmRestartFlag: Bool, inout IsConvergedFlag: Bool):
    var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    var rootFinders: RootFinderDataType = state.dataHVACControllers.RootFinders[ControlNum]
    var NoFlowResetValue: Float64 = 0.0
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
        controllerProps.Mode = ControllerMode.None
        controllerProps.NextActuatedValue = 0.0
    controllerProps.ReusePreviousSolutionFlag = True
    controllerProps.ReuseIntermediateSolutionFlag = False
    IsConvergedFlag = False
    rootFinders.StatusFlag = DataRootFinder.RootFinderStatus.None
    rootFinders.CurrentMethodType = DataRootFinder.RootFinderMethod.None
    rootFinders.CurrentPoint.DefinedFlag = False
    rootFinders.CurrentPoint.X = 0.0
    rootFinders.CurrentPoint.Y = 0.0
    rootFinders.MinPoint.DefinedFlag = False
    rootFinders.MaxPoint.DefinedFlag = False
    rootFinders.LowerPoint.DefinedFlag = False
    rootFinders.UpperPoint.DefinedFlag = False

def InitController(inout state: EnergyPlusData, ControlNum: Int32, inout IsConvergedFlag: Bool):
    var RoutineName: StringLiteral = "InitController"
    var thisController: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    var MyEnvrnFlag: Array1D_bool = state.dataHVACControllers.MyEnvrnFlag
    var MySizeFlag: Array1D_bool = state.dataHVACControllers.MySizeFlag
    var MyPlantIndexsFlag: Array1D_bool = state.dataHVACControllers.MyPlantIndexsFlag
    if state.dataHVACControllers.InitControllerOneTimeFlag:
        MyEnvrnFlag.allocate(state.dataHVACControllers.NumControllers)
        MySizeFlag.allocate(state.dataHVACControllers.NumControllers)
        MyPlantIndexsFlag.allocate(state.dataHVACControllers.NumControllers)
        MyEnvrnFlag = True
        MySizeFlag = True
        MyPlantIndexsFlag = True
        state.dataHVACControllers.InitControllerOneTimeFlag = False
    if not state.dataGlobal.SysSizingCalc and state.dataHVACControllers.InitControllerSetPointCheckFlag and state.dataHVACGlobal.DoSetPointTest:
        for ControllerIndex in range(1, state.dataHVACControllers.NumControllers + 1):
            var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControllerIndex]
            var SensedNode: Int32 = controllerProps.SensedNode
            if controllerProps.ControlVar == CtrlVarType.Temperature:
                if state.dataLoopNodes.Node[SensedNode].TempSetPoint == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, format("HVACControllers: Missing temperature setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  use a Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at the controller sensed node.")
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, SensedNode, HVAC.CtrlVarType.Temp, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state, format("HVACControllers: Missing temperature setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                            ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                            ShowContinueError(state, "  use a Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at the controller sensed node.")
                            ShowContinueError(state, "Or add EMS Actuator to provide temperature setpoint at this node")
                else:
                    if state.dataLoopNodes.Node[SensedNode].HumRatMax != Node.SensedNodeFlagValue and controllerProps.Action == ControllerAction.Reverse:
                        ShowWarningError(state, format("HVACControllers: controller type={} Name=\"{}\" has detected a maximum humidity ratio setpoint at the control node.", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node referenced (by controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  set the controller control variable to TemperatureAndHumidityRatio if humidity control is desired.")
            elif controllerProps.ControlVar == CtrlVarType.HumidityRatio:
                controllerProps.HumRatCntrlType = SetPointManager.GetHumidityRatioVariableType(state, SensedNode)
                if (thisController.HumRatCntrlType == HVAC.CtrlVarType.HumRat and state.dataLoopNodes.Node[SensedNode].HumRatSetPoint == Node.SensedNodeFlagValue) or (thisController.HumRatCntrlType == HVAC.CtrlVarType.MaxHumRat and state.dataLoopNodes.Node[SensedNode].HumRatMax == Node.SensedNodeFlagValue):
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, format("HVACControllers: Missing humidity ratio setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node referenced (by controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MaximumHumidityRatio\" to establish a setpoint at the controller sensed node.")
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, SensedNode, HVAC.CtrlVarType.HumRat, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state, format("HVACControllers: Missing humidity ratio setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                            ShowContinueError(state, format("Node referenced (by controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                            ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MaximumHumidityRatio\" to establish a setpoint at the controller sensed node.")
                            ShowContinueError(state, "Or add EMS Actuator to provide Humidity Ratio setpoint at this node")
                elif thisController.HumRatCntrlType == HVAC.CtrlVarType.MinHumRat:
                    ShowSevereError(state, format("HVACControllers: incorrect humidity ratio setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                    ShowContinueError(state, format("Node referenced (by controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                    ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MaximumHumidityRatio\" to establish a setpoint at the controller sensed node.")
                    state.dataHVACGlobal.SetPointErrorFlag = True
            elif controllerProps.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
                if state.dataLoopNodes.Node[SensedNode].TempSetPoint == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, format("HVACControllers: Missing temperature setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  use a Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at the controller sensed node.")
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, SensedNode, HVAC.CtrlVarType.Temp, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state, format("HVACControllers: Missing temperature setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                            ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                            ShowContinueError(state, "  use a Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at the controller sensed node.")
                            ShowContinueError(state, "Or add EMS Actuator to provide temperature setpoint at this node")
                if state.dataLoopNodes.Node[SensedNode].HumRatMax == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, format("HVACControllers: Missing maximum humidity ratio setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MaximumHumidityRatio\" to establish a setpoint at the controller sensed node.")
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, SensedNode, HVAC.CtrlVarType.MaxHumRat, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state, format("HVACControllers: Missing maximum humidity ratio setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                            ShowContinueError(state, format("Node Referenced (by Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                            ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MaximumHumidityRatio\" to establish a setpoint at the controller sensed node.")
                            ShowContinueError(state, "Or add EMS Actuator to provide maximum Humidity Ratio setpoint at this node")
            elif controllerProps.ControlVar == CtrlVarType.Flow:
                if state.dataLoopNodes.Node[SensedNode].MassFlowRateSetPoint == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state, format("HVACControllers: Missing mass flow rate setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                        ShowContinueError(state, format("Node Referenced (in Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                        ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MassFlowRate\" to establish a setpoint at the controller sensed node.")
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, SensedNode, HVAC.CtrlVarType.MassFlowRate, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state, format("HVACControllers: Missing mass flow rate setpoint for controller type={} Name=\"{}\"", controllerProps.ControllerType, controllerProps.ControllerName))
                            ShowContinueError(state, format("Node Referenced (in Controller)={}", state.dataLoopNodes.NodeID[SensedNode]))
                            ShowContinueError(state, "  use a SetpointManager with the field Control Variable = \"MassFlowRate\" to establish a setpoint at the controller sensed node.")
                            ShowContinueError(state, "Or add EMS Actuator to provide Mass Flow Rate setpoint at this node")
            else:

        state.dataHVACControllers.InitControllerSetPointCheckFlag = False
    if allocated(state.dataPlnt.PlantLoop) and MyPlantIndexsFlag[ControlNum]:
        PlantUtilities.ScanPlantLoopsForNodeNum(state, thisController.ControllerName, thisController.ActuatedNode, thisController.ActuatedNodePlantLoc)
        MyPlantIndexsFlag[ControlNum] = False
    if not state.dataGlobal.SysSizingCalc and MySizeFlag[ControlNum]:
        SizeController(state, ControlNum)
        if thisController.MaxVolFlowActuated == 0.0:
            ShowWarningError(state, format("{}: Controller:WaterCoil=\"{}\", Maximum Actuated Flow is zero.", RoutineName, thisController.ControllerName))
            thisController.MinVolFlowActuated = 0.0
        elif thisController.MinVolFlowActuated >= thisController.MaxVolFlowActuated:
            ShowFatalError(state, format("{}: Controller:WaterCoil=\"{}\", Minimum control flow is > or = Maximum control flow.", RoutineName, thisController.ControllerName))
        if thisController.Action == ControllerAction.NormalAction:
            RootFinder.SetupRootFinder(state, state.dataHVACControllers.RootFinders[ControlNum], DataRootFinder.Slope.Increasing, DataRootFinder.RootFinderMethod.Brent, DataPrecisionGlobals.constant_zero, 1.0e-6, thisController.Offset)
        elif thisController.Action == ControllerAction.Reverse:
            RootFinder.SetupRootFinder(state, state.dataHVACControllers.RootFinders[ControlNum], DataRootFinder.Slope.Decreasing, DataRootFinder.RootFinderMethod.Brent, DataPrecisionGlobals.constant_zero, 1.0e-6, thisController.Offset)
        else:
            ShowFatalError(state, "InitController: Invalid controller action. Valid choices are \"Normal\" or \"Reverse\"")
        MySizeFlag[ControlNum] = False
    var ActuatedNode: Int32 = thisController.ActuatedNode
    var SensedNode: Int32 = thisController.SensedNode
    if state.dataGlobal.BeginEnvrnFlag and MyEnvrnFlag[ControlNum]:
        var rho: Float64 = thisController.ActuatedNodePlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
        thisController.MinActuated = rho * thisController.MinVolFlowActuated
        thisController.MaxActuated = rho * thisController.MaxVolFlowActuated
        thisController.ReusePreviousSolutionFlag = False
        for e in thisController.SolutionTrackers:
            e.DefinedFlag = False
            e.Mode = ControllerMode.None
            e.ActuatedValue = 0.0
        MyEnvrnFlag[ControlNum] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        MyEnvrnFlag[ControlNum] = True
    PlantUtilities.SetActuatedBranchFlowRate(state, thisController.NextActuatedValue, ActuatedNode, thisController.ActuatedNodePlantLoc, False)
    IsConvergedFlag = False
    if thisController.ControlVar == CtrlVarType.Temperature:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode].Temp
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].TempSetPoint
            thisController.IsSetPointDefinedFlag = True
            if thisController.FaultyCoilSATFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and (not state.dataGlobal.KickOffSimulation):
                var FaultIndex: Int32 = thisController.FaultyCoilSATIndex
                thisController.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[FaultIndex].CalFaultOffsetAct(state)
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].TempSetPoint - thisController.FaultyCoilSATOffset
    elif thisController.ControlVar == CtrlVarType.TemperatureAndHumidityRatio:
        if thisController.HumRatCtrlOverride:
            thisController.SensedValue = state.dataLoopNodes.Node[SensedNode].HumRat
        else:
            thisController.SensedValue = state.dataLoopNodes.Node[SensedNode].Temp
        if not thisController.IsSetPointDefinedFlag:
            if thisController.HumRatCtrlOverride:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].HumRatMax
            else:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].TempSetPoint
            thisController.IsSetPointDefinedFlag = True
    elif thisController.ControlVar == CtrlVarType.HumidityRatio:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode].HumRat
        if not thisController.IsSetPointDefinedFlag:
            if thisController.HumRatCntrlType == HVAC.CtrlVarType.MaxHumRat:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].HumRatMax
            else:
                thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].HumRatSetPoint
            thisController.IsSetPointDefinedFlag = True
    elif thisController.ControlVar == CtrlVarType.Flow:
        thisController.SensedValue = state.dataLoopNodes.Node[SensedNode].MassFlowRate
        if not thisController.IsSetPointDefinedFlag:
            thisController.SetPointValue = state.dataLoopNodes.Node[SensedNode].MassFlowRateSetPoint
            thisController.IsSetPointDefinedFlag = True
    else:
        ShowFatalError(state, format("Invalid Controller Variable Type={}", ControlVariableTypes(thisController.ControlVar)))
    if thisController.ActuatorVar == CtrlVarType.Flow:
        thisController.ActuatedValue = state.dataLoopNodes.Node[ActuatedNode].MassFlowRate
        if thisController.NumCalcCalls == 0:
            thisController.MinAvailActuated = max(state.dataLoopNodes.Node[ActuatedNode].MassFlowRateMinAvail, thisController.MinActuated)
            thisController.MaxAvailActuated = min(state.dataLoopNodes.Node[ActuatedNode].MassFlowRateMaxAvail, thisController.MaxActuated)
            thisController.MinAvailActuated = min(thisController.MinAvailActuated, thisController.MaxAvailActuated)
    else:
        ShowFatalError(state, format("Invalid Actuator Variable Type={}", ControlVariableTypes(thisController.ActuatorVar)))
    if thisController.IsSetPointDefinedFlag:
        thisController.DeltaSensed = thisController.SensedValue - thisController.SetPointValue
    else:
        thisController.DeltaSensed = 0.0

def SizeController(inout state: EnergyPlusData, ControlNum: Int32):
    var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    if controllerProps.MaxVolFlowActuated == DataSizing.AutoSize:
        for WaterCompNum in range(1, state.dataSize.SaveNumPlantComps + 1):
            if state.dataSize.CompDesWaterFlow[WaterCompNum].SupNode == controllerProps.ActuatedNode:
                controllerProps.MaxVolFlowActuated = state.dataSize.CompDesWaterFlow[WaterCompNum].DesVolFlowRate
        if controllerProps.MaxVolFlowActuated < HVAC.SmallWaterVolFlow:
            controllerProps.MaxVolFlowActuated = 0.0
        BaseSizer.reportSizerOutput(state, controllerProps.ControllerType, controllerProps.ControllerName, "Maximum Actuated Flow [m3/s]", controllerProps.MaxVolFlowActuated)
    if controllerProps.Offset == DataSizing.AutoSize:
        controllerProps.Offset = (0.001 / (2100.0 * max(controllerProps.MaxVolFlowActuated, HVAC.SmallWaterVolFlow))) * (DataConvergParams.HVACEnergyToler / 10.0)
        controllerProps.Offset = min(0.1 * DataConvergParams.HVACTemperatureToler, controllerProps.Offset)
        BaseSizer.reportSizerOutput(state, controllerProps.ControllerType, controllerProps.ControllerName, "Controller Convergence Tolerance", controllerProps.Offset)

def CalcSimpleController(inout state: EnergyPlusData, ControlNum: Int32, FirstHVACIteration: Bool, inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool, ControllerName: String):
    var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    var rootFinders: RootFinderDataType = state.dataHVACControllers.RootFinders[ControlNum]
    controllerProps.NumCalcCalls += 1
    if state.dataLoopNodes.Node[controllerProps.SensedNode].MassFlowRate == 0.0:
        ExitCalcController(state, ControlNum, DataPrecisionGlobals.constant_zero, ControllerMode.Off, IsConvergedFlag, IsUpToDateFlag)
        return
    if controllerProps.NumCalcCalls == 1:
        RootFinder.InitializeRootFinder(state, rootFinders, controllerProps.MinAvailActuated, controllerProps.MaxAvailActuated)
        controllerProps.ReuseIntermediateSolutionFlag = IsUpToDateFlag and controllerProps.IsSetPointDefinedFlag and RootFinder.CheckRootFinderCandidate(rootFinders, controllerProps.ActuatedValue)
        if controllerProps.ReuseIntermediateSolutionFlag:
            FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)
        else:
            controllerProps.NextActuatedValue = rootFinders.MinPoint.X
    else:
        if not controllerProps.IsSetPointDefinedFlag:
            ShowSevereError(state, format("CalcSimpleController: Root finder failed at {}", CreateHVACStepFullString(state)))
            ShowContinueError(state, format(" Controller name=\"{}\"", ControllerName))
            ShowContinueError(state, " Setpoint is not available/defined.")
            ShowFatalError(state, "Preceding error causes program termination.")
        if rootFinders.MinPoint.X != controllerProps.MinAvailActuated:
            ShowSevereError(state, format("CalcSimpleController: Root finder failed at {}", CreateHVACStepFullString(state)))
            ShowContinueError(state, format(" Controller name=\"{}\"", ControllerName))
            ShowContinueError(state, " Minimum bound must remain invariant during successive iterations.")
            ShowContinueError(state, format(" Minimum root finder point={:.15f}", rootFinders.MinPoint.X))
            ShowContinueError(state, format(" Minimum avail actuated={:.15f}", controllerProps.MinAvailActuated))
            ShowFatalError(state, "Preceding error causes program termination.")
        if rootFinders.MaxPoint.X != controllerProps.MaxAvailActuated:
            ShowSevereError(state, format("CalcSimpleController: Root finder failed at {}", CreateHVACStepFullString(state)))
            ShowContinueError(state, format(" Controller name=\"{}\"", ControllerName))
            ShowContinueError(state, " Maximum bound must remain invariant during successive iterations.")
            ShowContinueError(state, format(" Maximum root finder point={:.15f}", rootFinders.MaxPoint.X))
            ShowContinueError(state, format(" Maximum avail actuated={:.15f}", controllerProps.MaxAvailActuated))
            ShowFatalError(state, "Preceding error causes program termination.")
        FindRootSimpleController(state, ControlNum, FirstHVACIteration, IsConvergedFlag, IsUpToDateFlag, ControllerName)

def FindRootSimpleController(inout state: EnergyPlusData, ControlNum: Int32, FirstHVACIteration: Bool, inout IsConvergedFlag: Bool, inout IsUpToDateFlag: Bool, ControllerName: String):
    var IsDoneFlag: Bool
    var PreviousSolutionMode: ControllerMode
    var PreviousSolutionValue: Float64
    var controllerProps: ControllerPropsType = state.dataHVACControllers.ControllerProps[ControlNum]
    var rootFinders: RootFinderDataType = state.dataHVACControllers.RootFinders[ControlNum]
    RootFinder.IterateRootFinder(state, rootFinders, controllerProps.ActuatedValue, controllerProps.DeltaSensed, IsDoneFlag)
    if rootFinders.StatusFlag