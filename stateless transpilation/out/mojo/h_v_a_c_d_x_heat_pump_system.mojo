# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from collections import defaultdict

alias MIN_AIR_MASS_FLOW = 0.001

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data access (state.dataHVACDXHeatPumpSys, etc.)
# - HVAC module: CoilType enum, FanOp enum, CompressorOp enum, CtrlVarType enum, TempControlTol
# - Util module: FindItemInList function
# - DXCoils module: SimDXCoil, GetCoilInletNode, GetCoilOutletNode, SetCoilSystemHeatingDXFlag, CalcDXHeatingCoil
# - VariableSpeedCoils module: SimVariableSpeedCoils, GetCoilInletNodeVariableSpeed, GetCoilOutletNodeVariableSpeed
# - Psychrometrics module: PsyHFnTdbW, PsyTdpFnWPb
# - General module: SolveRoot
# - Sched module: GetScheduleAlwaysOn, GetSchedule, Schedule class with getCurrentVal()
# - Node module: SetUpCompSets, TestCompSet
# - Error/warning functions: ShowFatalError, ShowSevereError, ShowWarningError, etc.
# - ValidateComponent, ErrorObjectHeader
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# - EMSManager: CheckIfNodeSetPointManagedByEMS
# - FaultsManager: state.dataFaultsMgr.FaultsCoilSATSensor with CalFaultOffsetAct method


struct DXHeatPumpSystemStruct:
    var DXHeatPumpSystemType: String
    var Name: String
    var availSched: AnyType
    var coilType: Int32
    var HeatPumpCoilName: String
    var HeatPumpCoilIndex: Int32
    var DXHeatPumpCoilInletNodeNum: Int32
    var DXHeatPumpCoilOutletNodeNum: Int32
    var DXSystemControlNodeNum: Int32
    var DesiredOutletTemp: Float64
    var PartLoadFrac: Float64
    var SpeedRatio: Float64
    var CycRatio: Float64
    var fanOp: Int32
    var DXCoilSensPLRIter: Int32
    var DXCoilSensPLRIterIndex: Int32
    var DXCoilSensPLRFail: Int32
    var DXCoilSensPLRFailIndex: Int32
    var OAUnitSetTemp: Float64
    var SpeedNum: Int32
    var FaultyCoilSATFlag: Bool
    var FaultyCoilSATIndex: Int32
    var FaultyCoilSATOffset: Float64
    
    fn __init__(inout self):
        self.DXHeatPumpSystemType = ""
        self.Name = ""
        self.availSched = None
        self.coilType = -1
        self.HeatPumpCoilName = ""
        self.HeatPumpCoilIndex = 0
        self.DXHeatPumpCoilInletNodeNum = 0
        self.DXHeatPumpCoilOutletNodeNum = 0
        self.DXSystemControlNodeNum = 0
        self.DesiredOutletTemp = 0.0
        self.PartLoadFrac = 0.0
        self.SpeedRatio = 0.0
        self.CycRatio = 0.0
        self.fanOp = -1
        self.DXCoilSensPLRIter = 0
        self.DXCoilSensPLRIterIndex = 0
        self.DXCoilSensPLRFail = 0
        self.DXCoilSensPLRFailIndex = 0
        self.OAUnitSetTemp = 0.0
        self.SpeedNum = 0
        self.FaultyCoilSATFlag = False
        self.FaultyCoilSATIndex = 0
        self.FaultyCoilSATOffset = 0.0


struct HVACDXHeatPumpSystemData:
    var NumDXHeatPumpSystems: Int32
    var EconomizerFlag: Bool
    var GetInputFlag: Bool
    var CheckEquipName: DynamicVector[Bool]
    var DXHeatPumpSystem: DynamicVector[DXHeatPumpSystemStruct]
    
    var QZnReq: Float64
    var QLatReq: Float64
    var OnOffAirFlowRatio: Float64
    var ErrorsFound: Bool
    var TotalArgs: Int32
    var MySetPointCheckFlag: Bool
    var SpeedNum: Int32
    var QZnReqr: Float64
    var QLatReqr: Float64
    var OnandOffAirFlowRatio: Float64
    var SpeedRatio: Float64
    var SpeedNumber: Int32
    var QZoneReq: Float64
    var QLatentReq: Float64
    var AirFlowOnOffRatio: Float64
    var SpeedPartLoadRatio: Float64
    
    fn __init__(inout self):
        self.NumDXHeatPumpSystems = 0
        self.EconomizerFlag = False
        self.GetInputFlag = True
        self.CheckEquipName = DynamicVector[Bool]()
        self.DXHeatPumpSystem = DynamicVector[DXHeatPumpSystemStruct]()
        
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
    
    fn clear_state(inout self):
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


fn SimDXHeatPumpSystem(
    state: AnyType,
    DXHeatPumpSystemName: StringLiteral,
    FirstHVACIteration: Bool,
    AirLoopNum: Int32,
    inout CompIndex: Int32,
    OAUnitNum: AnyType = None,
    OAUCoilOutTemp: AnyType = None,
    QTotOut: AnyType = None
) -> None:
    """Manage DXHeatPumpSystem component simulation"""
    pass


fn GetDXHeatPumpSystemInput(state: AnyType) -> None:
    """Get DX Heat Pump System input from data file"""
    pass


fn InitDXHeatPumpSystem(
    state: AnyType,
    DXSystemNum: Int32,
    AirLoopNum: Int32,
    OAUnitNum: AnyType = None,
    OAUCoilOutTemp: AnyType = None
) -> None:
    """Initialize DX Heat Pump System"""
    pass


fn ControlDXHeatingSystem(
    state: AnyType,
    DXSystemNum: Int32,
    FirstHVACIteration: Bool
) -> None:
    """Control DX Heating System"""
    pass


fn VSCoilCyclingResidual(
    state: AnyType,
    PartLoadRatio: Float64,
    CoilIndex: Int32,
    desiredTemp: Float64,
    fanOp: Int32
) -> Float64:
    """Calculate residual for cycling part-load ratio"""
    pass


fn VSCoilSpeedResidual(
    state: AnyType,
    SpeedRatio: Float64,
    CoilIndex: Int32,
    desiredTemp: Float64,
    speedNumber: Int32,
    fanOp: Int32
) -> Float64:
    """Calculate residual for speed ratio"""
    pass


fn GetHeatingCoilInletNodeNum(
    state: AnyType,
    DXHeatCoilSysName: StringLiteral,
    inout InletNodeErrFlag: Bool
) -> Int32:
    """Get inlet node number of heating coil system"""
    pass


fn GetHeatingCoilOutletNodeNum(
    state: AnyType,
    DXHeatCoilSysName: StringLiteral,
    inout OutletNodeErrFlag: Bool
) -> Int32:
    """Get outlet node number of heating coil system"""
    pass
