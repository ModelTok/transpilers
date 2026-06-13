from DataGlobals import *
from .Data.BaseData import *
from  import *
from BranchNodeConnections import *
from DXCoils import *
from .Data.EnergyPlusData import *
from DataAirLoop import *
from DataHVACGlobals import *
from DataLoopNode import *
from EMSManager import *
from FaultsManager import *
from General import *
from GeneralRoutines import *
from .InputProcessing.InputProcessor import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from VariableSpeedCoils import *
from HVACDXHeatPumpSystem import *
from math import *
from ObjexxFCL.Array1D import *
from ObjexxFCL.Optional import *

@value
struct DXHeatPumpSystemStruct:
    var DXHeatPumpSystemType: String
    var Name: String
    var availSched: Optional[Schedule]
    var coilType: HVAC.CoilType
    var HeatPumpCoilName: String
    var HeatPumpCoilIndex: Int
    var DXHeatPumpCoilInletNodeNum: Int
    var DXHeatPumpCoilOutletNodeNum: Int
    var DXSystemControlNodeNum: Int
    var DesiredOutletTemp: Float64
    var PartLoadFrac: Float64
    var SpeedRatio: Float64
    var CycRatio: Float64
    var fanOp: HVAC.FanOp
    var DXCoilSensPLRIter: Int
    var DXCoilSensPLRIterIndex: Int
    var DXCoilSensPLRFail: Int
    var DXCoilSensPLRFailIndex: Int
    var OAUnitSetTemp: Float64
    var SpeedNum: Int
    var FaultyCoilSATFlag: Bool
    var FaultyCoilSATIndex: Int
    var FaultyCoilSATOffset: Float64

    def __init__(inout self):
        self.DXHeatPumpSystemType = ""
        self.Name = ""
        self.availSched = Optional[Schedule]()
        self.coilType = HVAC.CoilType.Invalid
        self.HeatPumpCoilName = ""
        self.HeatPumpCoilIndex = 0
        self.DXHeatPumpCoilInletNodeNum = 0
        self.DXHeatPumpCoilOutletNodeNum = 0
        self.DXSystemControlNodeNum = 0
        self.DesiredOutletTemp = 0.0
        self.PartLoadFrac = 0.0
        self.SpeedRatio = 0.0
        self.CycRatio = 0.0
        self.fanOp = HVAC.FanOp.Invalid
        self.DXCoilSensPLRIter = 0
        self.DXCoilSensPLRIterIndex = 0
        self.DXCoilSensPLRFail = 0
        self.DXCoilSensPLRFailIndex = 0
        self.OAUnitSetTemp = 0.0
        self.SpeedNum = 0
        self.FaultyCoilSATFlag = False
        self.FaultyCoilSATIndex = 0
        self.FaultyCoilSATOffset = 0.0

@value
struct HVACDXHeatPumpSystemData(BaseGlobalStruct):
    var NumDXHeatPumpSystems: Int
    var EconomizerFlag: Bool
    var GetInputFlag: Bool
    var CheckEquipName: Array1D_bool
    var DXHeatPumpSystem: Array1D[DXHeatPumpSystemStruct]
    var QZnReq: Float64
    var QLatReq: Float64
    var OnOffAirFlowRatio: Float64
    var ErrorsFound: Bool
    var TotalArgs: Int
    var MySetPointCheckFlag: Bool
    var SpeedNum: Int
    var QZnReqr: Float64
    var QLatReqr: Float64
    var OnandOffAirFlowRatio: Float64
    var SpeedRatio: Float64
    var SpeedNumber: Int
    var QZoneReq: Float64
    var QLatentReq: Float64
    var AirFlowOnOffRatio: Float64
    var SpeedPartLoadRatio: Float64

    def __init__(inout self):
        self.NumDXHeatPumpSystems = 0
        self.EconomizerFlag = False
        self.GetInputFlag = True
        self.CheckEquipName = Array1D_bool()
        self.DXHeatPumpSystem = Array1D[DXHeatPumpSystemStruct]()
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

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.GetInputFlag = True
        self.NumDXHeatPumpSystems = 0
        self.EconomizerFlag = False
        self.CheckEquipName.deallocate()
        self.DXHeatPumpSystem.deallocate()
        self.QZnReq = 0.001
        self.QLatReq = 0.0
        self.OnOffAirFlowRatio = 1.0
        self.ErrorsFound = False
        self.TotalArgs = 0
        self.MySetPointCheckFlag = True
        self.SpeedNum = 1
        self.QZnReq = 0.001
        self.QLatReq = 0.0
        self.OnOffAirFlowRatio = 1.0
        self.SpeedRatio = 0.0
        self.SpeedNumber = 1
        self.QZoneReq = 0.001
        self.QLatentReq = 0.0
        self.AirFlowOnOffRatio = 1.0
        self.SpeedPartLoadRatio = 1.0

def SimDXHeatPumpSystem(
    inout state: EnergyPlusData,
    DXHeatPumpSystemName: StringLiteral,
    FirstHVACIteration: Bool,
    AirLoopNum: Int,
    inout CompIndex: Int,
    OAUnitNum: Optional[Int] = Optional[Int](),
    OAUCoilOutTemp: Optional[Float64] = Optional[Float64](),
    inout QTotOut: Optional[Float64] = Optional[Float64]()
):
    using DXCoils.SimDXCoil
    using VariableSpeedCoils.SimVariableSpeedCoils
    var CompName: String
    var DXSystemNum: Int
    var AirMassFlow: Float64
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    var NumDXHeatPumpSystems: Int = state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems
    if CompIndex == 0:
        DXSystemNum = Util.FindItemInList(DXHeatPumpSystemName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXSystemNum == 0:
            ShowFatalError(state, "SimDXHeatPumpSystem: DXUnit not found=" + str(DXHeatPumpSystemName))
        CompIndex = DXSystemNum
    else:
        DXSystemNum = CompIndex
        if DXSystemNum > NumDXHeatPumpSystems or DXSystemNum < 1:
            ShowFatalError(state, "SimDXHeatPumpSystem:  Invalid CompIndex passed=" + str(DXSystemNum) + ", Number of DX Units=" + str(NumDXHeatPumpSystems) + ", DX Unit name=" + str(DXHeatPumpSystemName))
        if state.dataHVACDXHeatPumpSys.CheckEquipName[DXSystemNum - 1]:
            var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
            if DXHeatPumpSystemName != dxhpSystem.Name:
                ShowFatalError(state, "SimDXHeatPumpSystem: Invalid CompIndex passed=" + str(DXSystemNum) + ", DX Unit name=" + str(DXHeatPumpSystemName) + ", stored DX Unit Name for that index=" + str(dxhpSystem.Name))
            state.dataHVACDXHeatPumpSys.CheckEquipName[DXSystemNum - 1] = False
    if OAUnitNum:
        InitDXHeatPumpSystem(state, DXSystemNum, AirLoopNum, OAUnitNum, OAUCoilOutTemp)
    else:
        InitDXHeatPumpSystem(state, DXSystemNum, AirLoopNum)
    ControlDXHeatingSystem(state, DXSystemNum, FirstHVACIteration)
    var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
    CompName = dxhpSystem.HeatPumpCoilName
    if dxhpSystem.coilType == HVAC.CoilType.HeatingDXSingleSpeed:
        SimDXCoil(state, CompName, HVAC.CompressorOp.On, FirstHVACIteration, dxhpSystem.HeatPumpCoilIndex, dxhpSystem.fanOp, dxhpSystem.PartLoadFrac)
    elif dxhpSystem.coilType == HVAC.CoilType.HeatingDXVariableSpeed:
        SimVariableSpeedCoils(state, CompName, dxhpSystem.HeatPumpCoilIndex, dxhpSystem.fanOp, HVAC.CompressorOp.On, dxhpSystem.PartLoadFrac, dxhpSystem.SpeedNum, dxhpSystem.SpeedRatio, state.dataHVACDXHeatPumpSys.QZnReq, state.dataHVACDXHeatPumpSys.QLatReq, state.dataHVACDXHeatPumpSys.OnOffAirFlowRatio)
    else:
        ShowFatalError(state, "SimDXCoolingSystem: Invalid DX Heating System/Coil=" + str(HVAC.coilTypeNames[int(dxhpSystem.coilType)]))
    if AirLoopNum != -1:
        if (dxhpSystem.PartLoadFrac > 0.0) and state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].CanLockoutEconoWithCompressor:
            state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].ReqstEconoLockoutWithCompressor = True
        else:
            state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].ReqstEconoLockoutWithCompressor = False
    if QTotOut:
        var InletNodeNum: Int = dxhpSystem.DXHeatPumpCoilInletNodeNum
        var OutletNodeNum: Int = dxhpSystem.DXHeatPumpCoilOutletNodeNum
        AirMassFlow = state.dataLoopNodes.Node[OutletNodeNum - 1].MassFlowRate
        QTotOut = AirMassFlow * (state.dataLoopNodes.Node[InletNodeNum - 1].Enthalpy - state.dataLoopNodes.Node[OutletNodeNum - 1].Enthalpy)

def GetDXHeatPumpSystemInput(inout state: EnergyPlusData):
    using DXCoils.GetCoilInletNode
    using DXCoils.GetCoilOutletNode
    using DXCoils.SetCoilSystemHeatingDXFlag
    using Node.SetUpCompSets
    using Node.TestCompSet
    using VariableSpeedCoils.GetCoilInletNodeVariableSpeed
    using VariableSpeedCoils.GetCoilOutletNodeVariableSpeed
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var RoutineName: StringLiteral = "GetDXHeatPumpSystemInput: "
    var routineName: StringLiteral = "GetDXHeatPumpSystemInput"
    var IsNotOK: Bool
    var DXHeatSysNum: Int
    var CurrentModuleObject: String
    var Alphas: Array1D_string
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var Numbers: Array1D[Float64]
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    CurrentModuleObject = "CoilSystem:Heating:DX"
    var NumDXHeatPumpSystems: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems = NumDXHeatPumpSystems
    state.dataHVACDXHeatPumpSys.DXHeatPumpSystem.allocate(NumDXHeatPumpSystems)
    state.dataHVACDXHeatPumpSys.CheckEquipName.dimension(NumDXHeatPumpSystems, True)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "CoilSystem:Heating:DX", state.dataHVACDXHeatPumpSys.TotalArgs, NumAlphas, NumNums)
    Alphas.allocate(NumAlphas)
    cAlphaFields.allocate(NumAlphas)
    cNumericFields.allocate(NumNums)
    Numbers.dimension(NumNums, 0.0)
    lAlphaBlanks.dimension(NumAlphas, True)
    lNumericBlanks.dimension(NumNums, True)
    for DXHeatSysNum in range(1, NumDXHeatPumpSystems + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, DXHeatSysNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        var dxhpSys: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1]
        dxhpSys.DXHeatPumpSystemType = CurrentModuleObject
        dxhpSys.Name = Alphas[0]
        if lAlphaBlanks[1]:
            dxhpSys.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            var sched: Optional[Schedule] = Sched.GetSchedule(state, Alphas[1])
            if sched:
                dxhpSys.availSched = sched
            else:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHVACDXHeatPumpSys.ErrorsFound = True
        if Util.SameString(Alphas[2], "Coil:Heating:DX:SingleSpeed"):
            dxhpSys.coilType = HVAC.CoilType.HeatingDXSingleSpeed
            dxhpSys.HeatPumpCoilName = Alphas[3]
        elif Util.SameString(Alphas[2], "Coil:Heating:DX:VariableSpeed"):
            dxhpSys.coilType = HVAC.CoilType.HeatingDXVariableSpeed
            dxhpSys.HeatPumpCoilName = Alphas[3]
        else:
            ShowSevereError(state, "Invalid entry for " + str(cAlphaFields[2]) + " :" + str(Alphas[2]))
            ShowContinueError(state, "In " + str(CurrentModuleObject) + "=\"" + str(dxhpSys.Name) + "\".")
            state.dataHVACDXHeatPumpSys.ErrorsFound = True
        if dxhpSys.coilType == HVAC.CoilType.HeatingDXVariableSpeed:
            dxhpSys.DXHeatPumpCoilInletNodeNum = GetCoilInletNodeVariableSpeed(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, state.dataHVACDXHeatPumpSys.ErrorsFound)
            dxhpSys.DXHeatPumpCoilOutletNodeNum = GetCoilOutletNodeVariableSpeed(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, state.dataHVACDXHeatPumpSys.ErrorsFound)
        else:
            dxhpSys.DXHeatPumpCoilInletNodeNum = GetCoilInletNode(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, state.dataHVACDXHeatPumpSys.ErrorsFound)
            dxhpSys.DXHeatPumpCoilOutletNodeNum = GetCoilOutletNode(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, state.dataHVACDXHeatPumpSys.ErrorsFound)
        dxhpSys.DXSystemControlNodeNum = dxhpSys.DXHeatPumpCoilOutletNodeNum
        TestCompSet(state, CurrentModuleObject, dxhpSys.Name, state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilInletNodeNum - 1], state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilOutletNodeNum - 1], "Air Nodes")
        ValidateComponent(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, IsNotOK, CurrentModuleObject)
        if IsNotOK:
            ShowContinueError(state, "In " + str(CurrentModuleObject) + " = \"" + str(dxhpSys.Name) + "\".")
            state.dataHVACDXHeatPumpSys.ErrorsFound = True
        SetUpCompSets(state, dxhpSys.DXHeatPumpSystemType, dxhpSys.Name, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName, state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilInletNodeNum - 1], state.dataLoopNodes.NodeID[dxhpSys.DXHeatPumpCoilOutletNodeNum - 1])
        dxhpSys.fanOp = HVAC.FanOp.Continuous
        if dxhpSys.coilType != HVAC.CoilType.HeatingDXVariableSpeed:
            DXCoils.SetCoilSystemHeatingDXFlag(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName)
        else:
            VariableSpeedCoils.SetCoilSystemHeatingDXFlag(state, HVAC.coilTypeNames[int(dxhpSys.coilType)], dxhpSys.HeatPumpCoilName)
        state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1] = dxhpSys
    if state.dataHVACDXHeatPumpSys.ErrorsFound:
        ShowFatalError(state, str(RoutineName) + "Errors found in input.  Program terminates.")
    for DXHeatSysNum in range(1, NumDXHeatPumpSystems + 1):
        var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1]
        SetupOutputVariable(state, "Coil System Part Load Ratio", Constant.Units.None, dxhpSystem.PartLoadFrac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dxhpSystem.Name)
    Alphas.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    Numbers.deallocate()
    lAlphaBlanks.deallocate()
    lNumericBlanks.deallocate()

def InitDXHeatPumpSystem(
    inout state: EnergyPlusData,
    DXSystemNum: Int,
    AirLoopNum: Int,
    OAUnitNum: Optional[Int] = Optional[Int](),
    OAUCoilOutTemp: Optional[Float64] = Optional[Float64]()
):
    var DoSetPointTest: Bool = state.dataHVACGlobal.DoSetPointTest
    using EMSManager.CheckIfNodeSetPointManagedByEMS
    var ControlNode: Int
    var OAUCoilOutletTemp: Float64 = 0.0
    var NumDXHeatPumpSystems: Int = state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems
    if OAUnitNum:
        OAUCoilOutletTemp = OAUCoilOutTemp
    if not state.dataGlobal.SysSizingCalc and state.dataHVACDXHeatPumpSys.MySetPointCheckFlag and DoSetPointTest:
        for DXSysIndex in range(1, NumDXHeatPumpSystems + 1):
            var DXHeatPumpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSysIndex - 1]
            ControlNode = DXHeatPumpSystem.DXSystemControlNodeNum
            if ControlNode > 0:
                if AirLoopNum == -1:
                    state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint = OAUCoilOutletTemp
                else:
                    if state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint == Node.SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(state, str(DXHeatPumpSystem.DXHeatPumpSystemType) + ": Missing temperature setpoint for DX unit= " + str(DXHeatPumpSystem.Name))
                            ShowContinueError(state, "  use a Set Point Manager to establish a setpoint at the unit control node.")
                            state.dataHVACGlobal.SetPointErrorFlag = True
                        else:
                            CheckIfNodeSetPointManagedByEMS(state, ControlNode, HVAC.CtrlVarType.Temp, state.dataHVACGlobal.SetPointErrorFlag)
                            if state.dataHVACGlobal.SetPointErrorFlag:
                                ShowSevereError(state, str(DXHeatPumpSystem.DXHeatPumpSystemType) + ": Missing temperature setpoint for DX unit= " + str(DXHeatPumpSystem.Name))
                                ShowContinueError(state, "  use a Set Point Manager to establish a setpoint at the unit control node.")
                                ShowContinueError(state, "  or use an EMS actuator to establish a temperature setpoint at the unit control node.")
        state.dataHVACDXHeatPumpSys.MySetPointCheckFlag = False
    var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
    if AirLoopNum == -1:
        dxhpSystem.DesiredOutletTemp = OAUCoilOutletTemp
    else:
        ControlNode = dxhpSystem.DXSystemControlNodeNum
        state.dataHVACDXHeatPumpSys.EconomizerFlag = state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].EconoActive
        dxhpSystem.DesiredOutletTemp = state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint
    state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1] = dxhpSystem

def ControlDXHeatingSystem(
    inout state: EnergyPlusData,
    DXSystemNum: Int,
    FirstHVACIteration: Bool
):
    using DXCoils.SimDXCoil
    using HVAC.TempControlTol
    using General.SolveRoot
    using Psychrometrics.PsyHFnTdbW
    using Psychrometrics.PsyTdpFnWPb
    using VariableSpeedCoils.SimVariableSpeedCoils
    var MaxIte: Int = 500
    var Acc: Float64 = 1.0e-3
    var CompName: String
    var NoOutput: Float64
    var FullOutput: Float64
    var ReqOutput: Float64
    var InletNode: Int
    var OutletNode: Int
    var ControlNode: Int
    var PartLoadFrac: Float64
    var DesOutTemp: Float64
    var OutletTempDXCoil: Float64
    var SensibleLoad: Bool
    var fanOp: HVAC.FanOp
    var SpeedNum: Int
    var QZnReq: Float64
    var QLatReq: Float64
    var OnOffAirFlowRatio: Float64
    var TempSpeedOut: Float64
    var TempSpeedReqst: Float64
    var NumOfSpeeds: Int
    var VSCoilIndex: Int
    var I: Int
    var SpeedRatio: Float64
    var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1]
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
    if dxhpSystem.FaultyCoilSATFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and (not state.dataGlobal.KickOffSimulation):
        var FaultIndex: Int = dxhpSystem.FaultyCoilSATIndex
        dxhpSystem.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[FaultIndex - 1].CalFaultOffsetAct(state)
        DesOutTemp -= dxhpSystem.FaultyCoilSATOffset
    if (dxhpSystem.availSched.getCurrentVal() > 0.0) and (state.dataLoopNodes.Node[InletNode - 1].MassFlowRate > MinAirMassFlow):
        if (state.dataLoopNodes.Node[InletNode - 1].Temp < state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint) and (state.dataLoopNodes.Node[InletNode - 1].Temp < DesOutTemp) and (abs(state.dataLoopNodes.Node[InletNode - 1].Temp - DesOutTemp) > TempControlTol):
            SensibleLoad = True
        if SensibleLoad:
            var TempOut1: Float64
            if dxhpSystem.coilType == HVAC.CoilType.HeatingDXSingleSpeed:
                PartLoadFrac = 0.0
                SimDXCoil(state, CompName, HVAC.CompressorOp.On, FirstHVACIteration, dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                NoOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode - 1].Temp, state.dataLoopNodes.Node[OutletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[OutletNode - 1].HumRat))
                PartLoadFrac = 1.0
                SimDXCoil(state, CompName, HVAC.CompressorOp.On, FirstHVACIteration, dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                FullOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat))
                ReqOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(DesOutTemp, state.dataLoopNodes.Node[InletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat))
                TempOut1 = state.dataLoopNodes.Node[OutletNode - 1].Temp
                if (NoOutput - ReqOutput) > Acc:
                    PartLoadFrac = 0.0
                elif (FullOutput - ReqOutput) < Acc:
                    PartLoadFrac = 1.0
                else:
                    OutletTempDXCoil = state.dataDXCoils.DXCoilOutletTemp[dxhpSystem.HeatPumpCoilIndex - 1]
                    if OutletTempDXCoil < DesOutTemp:
                        PartLoadFrac = 1.0
                    else:
                        if state.dataGlobal.DoCoilDirectSolutions:
                            PartLoadFrac = (DesOutTemp - state.dataLoopNodes.Node[InletNode - 1].Temp) / (TempOut1 - state.dataLoopNodes.Node[InletNode - 1].Temp)
                            SimDXCoil(state, CompName, HVAC.CompressorOp.On, FirstHVACIteration, dxhpSystem.HeatPumpCoilIndex, fanOp, PartLoadFrac)
                        else:
                            var coilIndex: Int = dxhpSystem.HeatPumpCoilIndex
                            var f: fn(Float64) -> Float64 = lambda x: (
                                DXCoils.CalcDXHeatingCoil(state, coilIndex, x, HVAC.FanOp.Continuous, 1.0),
                                var OutletAirTemp: Float64 = state.dataDXCoils.DXCoilOutletTemp[coilIndex - 1],
                                DesOutTemp - OutletAirTemp
                            )
                            var SolFla: Int = 0
                            SolveRoot(state, Acc, MaxIte, SolFla, PartLoadFrac, f, 0.0, 1.0)
                            if SolFla == -1:
                                if not state.dataGlobal.WarmupFlag:
                                    if dxhpSystem.DXCoilSensPLRIter < 1:
                                        dxhpSystem.DXCoilSensPLRIter += 1
                                        ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = " + str(dxhpSystem.Name))
                                        ShowContinueError(state, "Estimated part-load ratio  = {:.3f}".format(ReqOutput / FullOutput))
                                        ShowContinueError(state, "Calculated part-load ratio = {:.3f}".format(PartLoadFrac))
                                        ShowContinueErrorTimeStamp(state, "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                    else:
                                        ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRIterIndex, PartLoadFrac, PartLoadFrac)
                            elif SolFla == -2:
                                PartLoadFrac = ReqOutput / FullOutput
                                if not state.dataGlobal.WarmupFlag:
                                    if dxhpSystem.DXCoilSensPLRFail < 1:
                                        dxhpSystem.DXCoilSensPLRFail += 1
                                        ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = " + str(dxhpSystem.Name))
                                        ShowContinueError(state, "Estimated part-load ratio = {:.3f}".format(PartLoadFrac))
                                        ShowContinueErrorTimeStamp(state, "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                    else:
                                        ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRFailIndex, PartLoadFrac, PartLoadFrac)
                if PartLoadFrac > 1.0:
                    PartLoadFrac = 1.0
                elif PartLoadFrac < 0.0:
                    PartLoadFrac = 0.0
            elif dxhpSystem.coilType == HVAC.CoilType.HeatingDXVariableSpeed:
                PartLoadFrac = 0.0
                SpeedNum = 1
                QZnReq = 0.0
                QLatReq = 0.0
                OnOffAirFlowRatio = 1.0
                SpeedRatio = 0.0
                SimVariableSpeedCoils(state, CompName, dxhpSystem.HeatPumpCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                VSCoilIndex = dxhpSystem.HeatPumpCoilIndex
                NumOfSpeeds = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex - 1].NumOfSpeeds
                NoOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode - 1].Temp, state.dataLoopNodes.Node[OutletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[OutletNode - 1].HumRat))
                PartLoadFrac = 1.0
                SpeedNum = NumOfSpeeds
                SpeedRatio = 1.0
                QZnReq = 0.001
                SimVariableSpeedCoils(state, CompName, VSCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                FullOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat))
                ReqOutput = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate * (PsyHFnTdbW(DesOutTemp, state.dataLoopNodes.Node[InletNode - 1].HumRat) - PsyHFnTdbW(state.dataLoopNodes.Node[InletNode - 1].Temp, state.dataLoopNodes.Node[InletNode - 1].HumRat))
                if (NoOutput - ReqOutput) > Acc:
                    PartLoadFrac = 0.0
                    SpeedNum = 1
                    SpeedRatio = 0.0
                elif (FullOutput - ReqOutput) < Acc:
                    PartLoadFrac = 1.0
                    SpeedNum = NumOfSpeeds
                    SpeedRatio = 1.0
                else:
                    OutletTempDXCoil = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex - 1].OutletAirDBTemp
                    if OutletTempDXCoil < DesOutTemp:
                        PartLoadFrac = 1.0
                        SpeedNum = NumOfSpeeds
                        SpeedRatio = 1.0
                    else:
                        PartLoadFrac = 1.0
                        SpeedNum = 1
                        SpeedRatio = 1.0
                        QZnReq = 0.001
                        SimVariableSpeedCoils(state, CompName, VSCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                        TempSpeedOut = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex - 1].OutletAirDBTemp
                        if (TempSpeedOut - DesOutTemp) < Acc:
                            PartLoadFrac = 1.0
                            SpeedRatio = 1.0
                            TempOut1 = TempSpeedOut
                            for I in range(2, NumOfSpeeds + 1):
                                SpeedNum = I
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                                TempSpeedOut = state.dataVariableSpeedCoils.VarSpeedCoil[VSCoilIndex - 1].OutletAirDBTemp
                                if (TempSpeedOut - DesOutTemp) > Acc:
                                    SpeedNum = I
                                    break
                                TempOut1 = TempSpeedOut
                            if state.dataGlobal.DoCoilDirectSolutions:
                                SpeedRatio = (DesOutTemp - TempOut1) / (TempSpeedOut - TempOut1)
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                            else:
                                var f: fn(Float64) -> Float64 = lambda x: VSCoilSpeedResidual(state, x, VSCoilIndex, DesOutTemp, SpeedNum, fanOp)
                                var SolFla: Int = 0
                                General.SolveRoot(state, Acc, MaxIte, SolFla, SpeedRatio, f, 1.0e-10, 1.0)
                                if SolFla == -1:
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRIter < 1:
                                            dxhpSystem.DXCoilSensPLRIter += 1
                                            ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = " + str(dxhpSystem.Name))
                                            ShowContinueError(state, "Estimated part-load ratio  = {:.3f}".format(ReqOutput / FullOutput))
                                            ShowContinueError(state, "Calculated part-load ratio = {:.3f}".format(PartLoadFrac))
                                            ShowContinueErrorTimeStamp(state, "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRIterIndex, PartLoadFrac, PartLoadFrac)
                                elif SolFla == -2:
                                    PartLoadFrac = ReqOutput / FullOutput
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRFail < 1:
                                            dxhpSystem.DXCoilSensPLRFail += 1
                                            ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = " + str(dxhpSystem.Name))
                                            ShowContinueError(state, "Estimated part-load ratio = {:.3f}".format(PartLoadFrac))
                                            ShowContinueErrorTimeStamp(state, "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRFailIndex, PartLoadFrac, PartLoadFrac)
                        else:
                            if state.dataGlobal.DoCoilDirectSolutions:
                                PartLoadFrac = (DesOutTemp - state.dataLoopNodes.Node[InletNode - 1].Temp) / (TempSpeedOut - state.dataLoopNodes.Node[InletNode - 1].Temp)
                                SimVariableSpeedCoils(state, CompName, VSCoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadFrac, SpeedNum, SpeedRatio, QZnReq, QLatReq, OnOffAirFlowRatio)
                            else:
                                var f: fn(Float64) -> Float64 = lambda x: VSCoilCyclingResidual(state, x, VSCoilIndex, DesOutTemp, fanOp)
                                var SolFla: Int = 0
                                General.SolveRoot(state, Acc, MaxIte, SolFla, PartLoadFrac, f, 1.0e-10, 1.0)
                                if SolFla == -1:
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRIter < 1:
                                            dxhpSystem.DXCoilSensPLRIter += 1
                                            ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - Iteration limit exceeded calculating DX unit sensible part-load ratio for unit = " + str(dxhpSystem.Name))
                                            ShowContinueError(state, "Estimated part-load ratio  = {:.3f}".format(ReqOutput / FullOutput))
                                            ShowContinueError(state, "Calculated part-load ratio = {:.3f}".format(PartLoadFrac))
                                            ShowContinueErrorTimeStamp(state, "The calculated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - Iteration limit exceeded calculating sensible part-load ratio error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRIterIndex, PartLoadFrac, PartLoadFrac)
                                elif SolFla == -2:
                                    PartLoadFrac = ReqOutput / FullOutput
                                    if not state.dataGlobal.WarmupFlag:
                                        if dxhpSystem.DXCoilSensPLRFail < 1:
                                            dxhpSystem.DXCoilSensPLRFail += 1
                                            ShowWarningError(state, str(dxhpSystem.DXHeatPumpSystemType) + " - DX unit sensible part-load ratio calculation failed: part-load ratio limits exceeded, for unit = " + str(dxhpSystem.Name))
                                            ShowContinueError(state, "Estimated part-load ratio = {:.3f}".format(PartLoadFrac))
                                            ShowContinueErrorTimeStamp(state, "The estimated part-load ratio will be used and the simulation continues. Occurrence info:")
                                        else:
                                            ShowRecurringWarningErrorAtEnd(state, dxhpSystem.DXHeatPumpSystemType + " \"" + dxhpSystem.Name + "\" - DX unit sensible part-load ratio calculation failed error continues. Sensible PLR statistics follow.", dxhpSystem.DXCoilSensPLRFailIndex, PartLoadFrac, PartLoadFrac)
                if PartLoadFrac > 1.0:
                    PartLoadFrac = 1.0
                elif PartLoadFrac < 0.0:
                    PartLoadFrac = 0.0
            else:
                ShowFatalError(state, "ControlDXHeatingSystem: Invalid DXHeatPumpSystem coil type = " + str(HVAC.coilTypeNames[int(dxhpSystem.coilType)]))
    dxhpSystem.PartLoadFrac = PartLoadFrac
    dxhpSystem.SpeedRatio = SpeedRatio
    dxhpSystem.SpeedNum = SpeedNum
    state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXSystemNum - 1] = dxhpSystem

def VSCoilCyclingResidual(
    inout state: EnergyPlusData,
    PartLoadRatio: Float64,
    CoilIndex: Int,
    desiredTemp: Float64,
    fanOp: HVAC.FanOp
) -> Float64:
    VariableSpeedCoils.SimVariableSpeedCoils(state, "", CoilIndex, fanOp, HVAC.CompressorOp.On, PartLoadRatio, state.dataHVACDXHeatPumpSys.SpeedNum, state.dataHVACDXHeatPumpSys.SpeedRatio, state.dataHVACDXHeatPumpSys.QZnReqr, state.dataHVACDXHeatPumpSys.QLatReqr, state.dataHVACDXHeatPumpSys.OnandOffAirFlowRatio)
    var OutletAirTemp: Float64 = state.dataVariableSpeedCoils.VarSpeedCoil[CoilIndex - 1].OutletAirDBTemp
    return desiredTemp - OutletAirTemp

def VSCoilSpeedResidual(
    inout state: EnergyPlusData,
    SpeedRatio: Float64,
    CoilIndex: Int,
    desiredTemp: Float64,
    speedNumber: Int,
    fanOp: HVAC.FanOp
) -> Float64:
    state.dataHVACDXHeatPumpSys.SpeedNumber = speedNumber
    VariableSpeedCoils.SimVariableSpeedCoils(state, "", CoilIndex, fanOp, HVAC.CompressorOp.On, state.dataHVACDXHeatPumpSys.SpeedPartLoadRatio, state.dataHVACDXHeatPumpSys.SpeedNumber, SpeedRatio, state.dataHVACDXHeatPumpSys.QZoneReq, state.dataHVACDXHeatPumpSys.QLatentReq, state.dataHVACDXHeatPumpSys.AirFlowOnOffRatio)
    var OutletAirTemp: Float64 = state.dataVariableSpeedCoils.VarSpeedCoil[CoilIndex - 1].OutletAirDBTemp
    return desiredTemp - OutletAirTemp

def GetHeatingCoilInletNodeNum(
    inout state: EnergyPlusData,
    DXHeatCoilSysName: String,
    inout InletNodeErrFlag: Bool
) -> Int:
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    var NodeNum: Int = 0
    if state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems > 0:
        var DXHeatSysNum: Int = Util.FindItemInList(DXHeatCoilSysName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXHeatSysNum > 0 and DXHeatSysNum <= state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems:
            var dxhpSystem: DXHeatPumpSystemStruct = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1]
            NodeNum = dxhpSystem.DXHeatPumpCoilInletNodeNum
    if NodeNum == 0:
        InletNodeErrFlag = True
    return NodeNum

def GetHeatingCoilOutletNodeNum(
    inout state: EnergyPlusData,
    DXHeatCoilSysName: String,
    inout OutletNodeErrFlag: Bool
) -> Int:
    if state.dataHVACDXHeatPumpSys.GetInputFlag:
        GetDXHeatPumpSystemInput(state)
        state.dataHVACDXHeatPumpSys.GetInputFlag = False
    var NodeNum: Int = 0
    if state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems > 0:
        var DXHeatSysNum: Int = Util.FindItemInList(DXHeatCoilSysName, state.dataHVACDXHeatPumpSys.DXHeatPumpSystem)
        if DXHeatSysNum > 0 and DXHeatSysNum <= state.dataHVACDXHeatPumpSys.NumDXHeatPumpSystems:
            NodeNum = state.dataHVACDXHeatPumpSys.DXHeatPumpSystem[DXHeatSysNum - 1].DXHeatPumpCoilOutletNodeNum
    if NodeNum == 0:
        OutletNodeErrFlag = True
    return NodeNum