from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, state
from EnergyPlus.EMSManager import (
    SetupEMSActuator,
    CheckIfAnyEMS,
    GetEMSInput,
    ManageEMS,
    InitEMS,
    EMSCallFrom,
    SetupNodeSetPointsAsActuators,
    SetupWindowShadingControlActuators,
    SetActuatedBranchFlowRate,
    SetComponentFlowRate,
    checkForUnusedActuatorsAtEnd,
    UpdateEMSTrendVariables,
)
from EnergyPlus.UtilityRoutines import FindItemInList
from EnergyPlus.DataRuntimeLanguage import Value, ErlFunc
from EnergyPlus.DataPlant import PlantLocation, LoopSideLocation, PlantEquipmentType
from EnergyPlus.PlantCondLoopOperation import SetupPlantEMSActuators
from EnergyPlus.PlantUtilities import SetPlantLocationLinks
from EnergyPlus.DataSurfaces import WinShadingType, SurfaceClass, ExternalEnvironment
from EnergyPlus.SolarShading import selectActiveWindowShadingControlIndex, WindowShadingManager
from EnergyPlus.SurfaceGeometry import AllocateSurfaceWindows
from EnergyPlus.WeatherManager import Weather
from EnergyPlus.SimulationManager import SimulationManager
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.NodeInputManager import Node
from EnergyPlus.OutAirNodeManager import OutAirNodeManager
from EnergyPlus.OutputProcessor import (
    SetupTimePointers,
    SetupOutputVariable,
    UpdateMeterReporting,
    UpdateDataandReport,
    GetReportVariableInput,
    TimeStepType,
    StoreType,
    VariableType,
)
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.UtilityRoutines import General
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.Constant import Constant as Const
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.DataGlobal import DataGlobal
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from EnergyPlus.DataSurfaces import DataSurfaces
from EnergyPlus.DataHeatBal import DataHeatBal
from EnergyPlus.DataConstruction import DataConstruction
from EnergyPlus.DataDaylighting import DataDaylighting
from EnergyPlus.DataEnvironment import DataEnvironment as DataEnv
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.ConfiguredFunctions import configured_source_directory
from EnergyPlus.RuntimeLanguageProcessor import RuntimeLanguageProcessor
from EnergyPlus.General import OrdinalDay
import "algorithm" as Algo
from memory import rotate
from math import pi
from sys import int as c_int

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def init_state(inout self):
        self.state.init_state(self.state)

    def dataRuntimeLang(self) -> DataRuntimeLanguage:
        return self.state.dataRuntimeLang

    def dataLoopNodes(self) -> DataLoopNode:
        return self.state.dataLoopNodes

    def dataOutAirNodeMgr(self) -> OutAirNodeManager:
        return self.state.dataOutAirNodeMgr

    def dataEMSMgr(self) -> EMSManager:
        return self.state.dataEMSMgr

    def dataPlnt(self) -> DataPlant:
        return self.state.dataPlnt

    def dataSurface(self) -> DataSurfaces:
        return self.state.dataSurface

    def dataConstruction(self) -> DataConstruction:
        return self.state.dataConstruction

    def dataDayltg(self) -> DataDaylighting:
        return self.state.dataDayltg

    def dataHeatBal(self) -> DataHeatBal:
        return self.state.dataHeatBal

    def dataGlobal(self) -> DataGlobal:
        return self.state.dataGlobal

    def dataWeather(self) -> DataEnvironment:
        return self.state.dataWeather

    def dataEnvrn(self) -> DataEnv:
        return self.state.dataEnvrn

    def dataHVACGlobal(self) -> DataHVACGlobal:
        return self.state.dataHVACGlobal

    def dataOutputProcessor(self) -> OutputProcessor:
        return self.state.dataOutputProcessor

    def dataZoneTempPredictorCorrector(self) -> ZoneTempPredictorCorrector:
        return self.state.dataZoneTempPredictorCorrector

    def dataSched(self) -> ScheduleManager:
        return self.state.dataSched

    def dataOutAirNodeMgr(self) -> OutAirNodeManager:
        return self.state.dataOutAirNodeMgr

    def dataRuntimeLang(self) -> DataRuntimeLanguage:
        return self.state.dataRuntimeLang

# Helper functions for assertions (gtest equivalents)
def assert_true(cond: Bool, msg: String = ""):
    if not cond:
        print("FAIL: expected true" + (" " + msg if msg else ""))
        abort()

def assert_false(cond: Bool, msg: String = ""):
    if cond:
        print("FAIL: expected false" + (" " + msg if msg else ""))
        abort()

def assert_equal[T: Comparable](expected: T, actual: T, msg: String = ""):
    if expected != actual:
        print("FAIL: expected ", expected, " but got ", actual, (" " + msg if msg else ""))
        abort()

def assert_ne[T: Comparable](expected: T, actual: T, msg: String = ""):
    if expected == actual:
        print("FAIL: expected not equal, but both are ", expected, (" " + msg if msg else ""))
        abort()

def assert_approx_equal(expected: Float64, actual: Float64, tol: Float64, msg: String = ""):
    if abs(expected - actual) > tol:
        print("FAIL: expected ", expected, " but got ", actual, " tolerance ", tol, (" " + msg if msg else ""))
        abort()

def assert_gt[T: Comparable](a: T, b: T, msg: String = ""):
    if not (a > b):
        print("FAIL: expected ", a, " > ", b, (" " + msg if msg else ""))
        abort()

def assert_ge[T: Comparable](a: T, b: T, msg: String = ""):
    if not (a >= b):
        print("FAIL: expected ", a, " >= ", b, (" " + msg if msg else ""))
        abort()

def delimited_string(lines: List[String]) -> String:
    var result: String
    for line in lines:
        result += line + "\n"
    return result

def compare_err_stream_substring(substr: String, check: Bool, also_no: Bool = False) -> Bool:
    # Simulate gtest's compare_err_stream_substring
    # Returns True if substring found in error stream (not implemented)
    return False

# Test body
def EMSManager_TestForUniqueEMSActuators(fixture: EnergyPlusFixture):
    fixture.state.init_state(fixture.state)
    fixture.dataRuntimeLang().EMSActuatorAvailable.allocate(100)
    var componentTypeName1: String = "Chiller1"
    var componentTypeName2: String = "Chiller2"
    var uniqueIDName1: String = "Plant Component Chiller:Electric:ReformulatedEIR"
    var controlTypeName1: String = "On/Off Supervisory"
    var units1: String = "None"
    var EMSActuated1: Bool = True
    var testBoolean1: Bool = True
    var testBoolean2: Bool = True
    var testBoolean3: Bool = True
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName1, units1, EMSActuated1, testBoolean1)
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName1, units1, EMSActuated1, testBoolean2)
    SetupEMSActuator(fixture.state, componentTypeName2, uniqueIDName1, controlTypeName1, units1, EMSActuated1, testBoolean3)
    assert_equal(2, fixture.dataRuntimeLang().numEMSActuatorsAvailable)
    var controlTypeName2: String = "ModeOfSomething"
    var testInt1: Int = 7
    var testInt2: Int = 9
    var testInt3: Int = 11
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName2, units1, EMSActuated1, testInt1)
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName2, units1, EMSActuated1, testInt2)
    SetupEMSActuator(fixture.state, componentTypeName2, uniqueIDName1, controlTypeName2, units1, EMSActuated1, testInt3)
    assert_equal(4, fixture.dataRuntimeLang().numEMSActuatorsAvailable)
    var controlTypeName3: String = "ValueOfResults"
    var testReal1: Float64 = 0.123
    var testReal2: Float64 = 0.456
    var testReal3: Float64 = 0.789
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName3, units1, EMSActuated1, testReal1)
    SetupEMSActuator(fixture.state, componentTypeName1, uniqueIDName1, controlTypeName3, units1, EMSActuated1, testReal2)
    SetupEMSActuator(fixture.state, componentTypeName2, uniqueIDName1, controlTypeName3, units1, EMSActuated1, testReal3)
    assert_equal(6, fixture.dataRuntimeLang().numEMSActuatorsAvailable)
    fixture.dataRuntimeLang().EMSActuatorAvailable.deallocate()

def Dual_NodeTempSetpoints(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpointLo,          !- Name",
        "Test node,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Minimum Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpointHi,          !- Name",
        "Test node,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Maximum Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Dual Setpoint Test Manager,  !- Name",
        "BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
        "DualSetpointTestControl;  !- Program Name 1",
        "EnergyManagementSystem:Program,",
        "DualSetpointTestControl,",
        "Set TempSetpointLo = 16.0,",
        "Set TempSetpointHi  = 20.0;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_approx_equal(20.0, fixture.dataLoopNodes().Node[1].TempSetPointHi, 0.000001)
    assert_approx_equal(16.0, fixture.dataLoopNodes().Node[1].TempSetPointLo, 0.000001)

def CheckActuatorInit(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpointLo,          !- Name",
        "Test node,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Minimum Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Dual Setpoint Test Manager,  !- Name",
        "EndOfSystemTimestepBeforeHVACReporting,  !- EnergyPlus Model Calling Point",
        "DualSetpointTestControl;  !- Program Name 1",
        "EnergyManagementSystem:Program,",
        "DualSetpointTestControl,",
        "Set TempSetpointLo = 16.0;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    EMSManager.GetEMSInput(fixture.state)
    # EXPECT_ENUM_EQ(state->dataRuntimeLang->ErlVariable(1).Value.Type, DataRuntimeLanguage::Value::Null)
    var varType = fixture.dataRuntimeLang().ErlVariable[1].Value.Type
    # In C++: Value::Null is an enum. We'll compare ints.
    assert_equal(Value.Null, varType)

def SupervisoryControl_PlantComponent_SetActuatedBranchFlowRate(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        " EnergyManagementSystem:Actuator,",
        "  CoilActuator,          !- Name",
        "  Zone1FanCoilHeatingCoil,  !- Actuated Component Unique Name",
        "  Plant Component Coil:Heating:Water,    !- Actuated Component Type",
        "  On/Off Supervisory;    !- Actuated Component Control Type",
        " EnergyManagementSystem:ProgramCallingManager,",
        "  Supervisory Control Manager,  !- Name",
        "  BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "  HeatCoilController;  !- Program Name 1",
        " EnergyManagementSystem:Program,",
        "  HeatCoilController,",
        "  Set CoilActuator = 0.0;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    fixture.dataPlnt().TotNumLoops = 1
    fixture.dataPlnt().PlantLoop.allocate(1)
    fixture.dataPlnt().PlantLoop[0].Name = "MyPlant"  # 0-based: index 0 corresponds to original 1
    for l in range(1, fixture.dataPlnt().TotNumLoops + 1):
        var idx = l - 1
        var loopside = fixture.dataPlnt().PlantLoop[idx].LoopSide[LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = loopside.Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    # Adjust: plant loop 1, Demand side, Branch 1 (index 0) -> TotalComponents = 2, Comp allocate 2
    var plIdx = 0
    var ls = LoopSideLocation.Demand
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].TotalComponents = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp.allocate(2)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].Type = PlantEquipmentType.CoilWaterSimpleHeating
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].Name = "Zone1FanCoilHeatingCoil"
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].NodeNumIn = 1
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].NodeNumOut = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].Type = PlantEquipmentType.Pipe
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].Name = "Pipe"
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].NodeNumIn = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].NodeNumOut = 3
    PlantCondLoopOperation.SetupPlantEMSActuators(fixture.state)
    fixture.dataLoopNodes().Node.allocate(3)
    var NodeMdot: Float64 = 1.5
    fixture.dataLoopNodes().Node[0].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateRequest = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateRequest = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateRequest = NodeMdot
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue = 1.0
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_false(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(0.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    var plantLoc0: PlantLocation = PlantLocation(1, LoopSideLocation.Demand, 1, 0)
    PlantUtilities.SetPlantLocationLinks(fixture.state, plantLoc0)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 1, plantLoc0, False)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 2, plantLoc0, False)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue = 1.0
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironmentAfterWarmUp, anyRan, None)
    assert_false(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(1.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 1, plantLoc0, False)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 2, plantLoc0, False)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginTimestepBeforePredictor, anyRan, None)
    assert_true(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(0.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 1, plantLoc0, False)
    assert_equal(0.0, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(0.0, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    SetActuatedBranchFlowRate(fixture.state, NodeMdot, 2, plantLoc0, False)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(0.0, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(0.0, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)

def SupervisoryControl_PlantComponent_SetComponentFlowRate(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        " EnergyManagementSystem:Actuator,",
        "  CoilActuator,          !- Name",
        "  Zone1FanCoilHeatingCoil,  !- Actuated Component Unique Name",
        "  Plant Component Coil:Heating:Water,    !- Actuated Component Type",
        "  On/Off Supervisory;    !- Actuated Component Control Type",
        " EnergyManagementSystem:ProgramCallingManager,",
        "  Supervisory Control Manager,  !- Name",
        "  BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "  HeatCoilController;  !- Program Name 1",
        " EnergyManagementSystem:Program,",
        "  HeatCoilController,",
        "  Set CoilActuator = 0.0;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    fixture.dataPlnt().TotNumLoops = 1
    fixture.dataPlnt().PlantLoop.allocate(1)
    fixture.dataPlnt().PlantLoop[0].Name = "MyPlant"
    for l in range(1, fixture.dataPlnt().TotNumLoops + 1):
        var idx = l - 1
        var loopside = fixture.dataPlnt().PlantLoop[idx].LoopSide[LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = loopside.Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    var plIdx = 0
    var ls = LoopSideLocation.Demand
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].TotalComponents = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp.allocate(2)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].Type = PlantEquipmentType.CoilWaterSimpleHeating
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].Name = "Zone1FanCoilHeatingCoil"
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].NodeNumIn = 1
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].NodeNumOut = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].Type = PlantEquipmentType.Pipe
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].Name = "Pipe"
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].NodeNumIn = 2
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[1].NodeNumOut = 3
    PlantCondLoopOperation.SetupPlantEMSActuators(fixture.state)
    fixture.dataLoopNodes().Node.allocate(3)
    var NodeMdot: Float64 = 1.5
    fixture.dataLoopNodes().Node[0].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[0].MassFlowRateRequest = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[1].MassFlowRateRequest = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRate = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateMax = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail = NodeMdot
    fixture.dataLoopNodes().Node[2].MassFlowRateRequest = NodeMdot
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue = 1.0
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_false(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(0.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    var plantLoc1: PlantLocation = PlantLocation(1, LoopSideLocation.Demand, 1, 1)
    PlantUtilities.SetPlantLocationLinks(fixture.state, plantLoc1)
    SetComponentFlowRate(fixture.state, NodeMdot, 1, 2, plantLoc1)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    SetComponentFlowRate(fixture.state, NodeMdot, 2, 3, plantLoc1)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)
    fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue = 1.0
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironmentAfterWarmUp, anyRan, None)
    assert_false(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(1.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    SetComponentFlowRate(fixture.state, NodeMdot, 1, 2, plantLoc1)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    SetComponentFlowRate(fixture.state, NodeMdot, 2, 3, plantLoc1)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginTimestepBeforePredictor, anyRan, None)
    assert_true(fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideOn)
    assert_approx_equal(0.0, fixture.dataPlnt().PlantLoop[plIdx].LoopSide[ls].Branch[0].Comp[0].EMSLoadOverrideValue, 0.000001)
    var tempNodeMdot: Float64 = NodeMdot
    SetComponentFlowRate(fixture.state, tempNodeMdot, 1, 2, plantLoc1)
    assert_equal(0.0, fixture.dataLoopNodes().Node[0].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[0].MassFlowRateRequest)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    tempNodeMdot = NodeMdot
    SetComponentFlowRate(fixture.state, tempNodeMdot, 2, 3, plantLoc1)
    assert_equal(0.0, fixture.dataLoopNodes().Node[1].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[1].MassFlowRateRequest)
    assert_equal(0.0, fixture.dataLoopNodes().Node[2].MassFlowRate)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMax)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateMaxAvail)
    assert_equal(NodeMdot, fixture.dataLoopNodes().Node[2].MassFlowRateRequest)

def Test_EMSLogic(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node 1;",
        "OutdoorAir:Node, Test node 2;",
        "OutdoorAir:Node, Test node 3;",
        "OutdoorAir:Node, Test node 4;",
        "OutdoorAir:Node, Test node 5;",
        "OutdoorAir:Node, Test node 6;",
        "OutdoorAir:Node, Test node 7;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint1,          !- Name",
        "Test node 1,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint2,          !- Name",
        "Test node 2,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint3,          !- Name",
        "Test node 3,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint4,          !- Name",
        "Test node 4,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint5,          !- Name",
        "Test node 5,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint6,          !- Name",
        "Test node 6,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint7,          !- Name",
        "Test node 7,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Logic Manager 1,  !- Name",
        "BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
        "LogicTest1;  !- Program Name 1",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Logic Manager 2,  !- Name",
        "BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "LogicTest2;  !- Program Name 1",
        "EnergyManagementSystem:Program,",
        "LogicTest1,",
        "Set MyVar1 = 10,",
        "Set MyVar2 = -10,",
        "Set MyVar3 = -10+3-1-2,",
        "Set MyVar4 = 10,",
        "Set MyVar5 = -PI,",
        "Set MyVar6 = ( 10 - ( ( @MOD 15.5 3 ) * 40 ) ),",
        "Set MyVar7 = ( 9.9 - ( @MOD 15.5 3 ) * 20 ),",
        "IF MyVar1 == 10,",
        "  Set TempSetpoint1 = 11.0,",
        "ELSE,",
        "  Set TempSetpoint1 = 21.0,",
        "ENDIF,",
        "IF MyVar2 == -10,",
        "  Set TempSetpoint2 = 12.0,",
        "ELSE,",
        "  Set TempSetpoint2 = 22.0,",
        "ENDIF,",
        "IF -10 == MyVar3,",
        "  Set TempSetpoint3 = 13.0,",
        "ELSE,",
        "  Set TempSetpoint3 = 23.0,",
        "ENDIF,",
        "IF MyVar4 == -20+30,",
        "  Set TempSetpoint4 = 14.0,",
        "ELSE,",
        "  Set TempSetpoint4 = 24.0,",
        "ENDIF,",
        "IF MyVar5 == -PI,",
        "  Set TempSetpoint5 = 15.0,",
        "ELSE,",
        "  Set TempSetpoint5 = 25.0,",
        "ENDIF,",
        "IF MyVar6 == -10,",
        "  Set TempSetpoint6 = 16.0,",
        "ELSE,",
        "  Set TempSetpoint6 = 26.0,",
        "ENDIF,",
        "IF MyVar7 > -11.0+3-1+8.89,",
        "  Set TempSetpoint7 = 17.0,",
        "ELSE,",
        "  Set TempSetpoint7 = 27.0,",
        "ENDIF;",
        "EnergyManagementSystem:Program,",
        "LogicTest2,",
        "Set MyVar1 = 10,",
        "Set MyVar2 = -10,",
        "Set MyVar3 = -10 + 3 - 1 - 2,",
        "Set MyVar4 = 10,",
        "Set MyVar5 = -PI,",
        "Set MyVar6 = ( 10 - ( ( @MOD 15.5 3 ) * 40 ) ),",
        "Set MyVar7 = ( 9.9 - ( @MOD 15.5 3 ) * 20 ),",
        "IF ( MyVar1 <> 10 ),",
        "  Set TempSetpoint1 = 11.0,",
        "ELSE,",
        "  Set TempSetpoint1 = 21.0,",
        "ENDIF,",
        "IF ( MyVar2 <> -10 ),",
        "  Set TempSetpoint2 = 12.0,",
        "ELSE,",
        "  Set TempSetpoint2 = 22.0,",
        "ENDIF,",
        "IF ( -10 <> MyVar3 ),",
        "  Set TempSetpoint3 = 13.0,",
        "ELSE,",
        "  Set TempSetpoint3 = 23.0,",
        "ENDIF,",
        "IF ( MyVar4 <> ( -20+30 ) ),",
        "  Set TempSetpoint4 = 14.0,",
        "ELSE,",
        "  Set TempSetpoint4 = 24.0,",
        "ENDIF,",
        "IF ( MyVar5 <> -PI ),",
        "  Set TempSetpoint5 = 15.0,",
        "ELSE,",
        "  Set TempSetpoint5 = 25.0,",
        "ENDIF,",
        "IF ( MyVar6 <> -10 ),",
        "  Set TempSetpoint6 = 16.0,",
        "ELSE,",
        "  Set TempSetpoint6 = 26.0,",
        "ENDIF,",
        "IF ( MyVar7 == -0.1 ),",
        "  Set TempSetpoint7 = 17.0,",
        "ELSE,",
        "  Set TempSetpoint7 = 27.0,",
        "ENDIF;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_approx_equal(11.0, fixture.dataLoopNodes().Node[0].TempSetPoint, 0.0000001)
    assert_approx_equal(12.0, fixture.dataLoopNodes().Node[1].TempSetPoint, 0.0000001)
    assert_approx_equal(13.0, fixture.dataLoopNodes().Node[2].TempSetPoint, 0.0000001)
    assert_approx_equal(14.0, fixture.dataLoopNodes().Node[3].TempSetPoint, 0.0000001)
    assert_approx_equal(15.0, fixture.dataLoopNodes().Node[4].TempSetPoint, 0.0000001)
    assert_approx_equal(16.0, fixture.dataLoopNodes().Node[5].TempSetPoint, 0.0000001)
    assert_approx_equal(17.0, fixture.dataLoopNodes().Node[6].TempSetPoint, 0.0000001)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginTimestepBeforePredictor, anyRan, None)
    assert_approx_equal(21.0, fixture.dataLoopNodes().Node[0].TempSetPoint, 0.0000001)
    assert_approx_equal(22.0, fixture.dataLoopNodes().Node[1].TempSetPoint, 0.0000001)
    assert_approx_equal(23.0, fixture.dataLoopNodes().Node[2].TempSetPoint, 0.0000001)
    assert_approx_equal(24.0, fixture.dataLoopNodes().Node[3].TempSetPoint, 0.0000001)
    assert_approx_equal(25.0, fixture.dataLoopNodes().Node[4].TempSetPoint, 0.0000001)
    assert_approx_equal(26.0, fixture.dataLoopNodes().Node[5].TempSetPoint, 0.0000001)
    assert_approx_equal(27.0, fixture.dataLoopNodes().Node[6].TempSetPoint, 0.0000001)

def Debug_EMSLogic(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node 1;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint1,          !- Name",
        "Test node 1,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Logic Manager 1,  !- Name",
        "BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
        "LogicTest1;  !- Program Name 1",
        "EnergyManagementSystem:Program,",
        "LogicTest1,",
        "Set MyVar1 = ( -2 ),",
        "Set MyVar2 = ( -2 ),",
        "Set TempSetpoint1 = MyVar1 / MyVar2;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_approx_equal(1.0, fixture.dataLoopNodes().Node[0].TempSetPoint, 0.0000001)

def TestAnyRanArgument(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node;",
        "EnergyManagementSystem:Sensor,",
        "Node_mdot,",
        "Test node,",
        "System Node Mass Flow Rate;",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test inside HVAC system iteration Loop,",
        "InsideHVACSystemIterationLoop,",
        "Test_InsideHVACSystemIterationLoop;",
        "EnergyManagementSystem:Program,",
        "Test_InsideHVACSystemIterationLoop,",
        "set dumm1 = Node_mdot;",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    Node.SetupNodeVarsForReporting(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    assert_false(anyRan)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_false(anyRan)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.HVACIterationLoop, anyRan, None)
    assert_true(anyRan)

def TestUnInitializedEMSVariable1(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "EnergyManagementSystem:GlobalVariable,",
        "TempSetpoint1;          !- Name",
        "EnergyManagementSystem:Program,",
        "InitVariableTest,",
        "Set TempSetpoint1 = 21.0;"
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test Program Manager 1,  !- Name",
        "BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
        "InitVariableTest;  !- Program Name 1",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    var internalVarNum: Int = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "TempSetpoint1", 0)
    assert_gt(internalVarNum, 0)
    assert_false(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    assert_approx_equal(21.0, fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.Number, 0.0000001)
    assert_true(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)

def TestUnInitializedEMSVariable2(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "OutdoorAir:Node, Test node 1;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpoint1,          !- Name",
        "Test node 1,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Setpoint;    !- Actuated Component Control Type",
        "EnergyManagementSystem:Program,",
        "SetNodeSetpointTest,",
        "Set TempSetpoint1 = testGlobalVar;"
        "EnergyManagementSystem:Program,",
        "SetGlobalValue,",
        "SET testGlobalVar = 21.0;"
        "EnergyManagementSystem:GlobalVariable, ",
        "testGlobalVar;"
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test Program Manager 1,  !- Name",
        "BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
        "SetNodeSetpointTest;  !- Program Name 1",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test Program Manager 2,  !- Name",
        "BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "SetGlobalValue;  !- Program Name 1",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    OutAirNodeManager.SetOutAirNodes(fixture.state)
    EMSManager.CheckIfAnyEMS(fixture.state)
    fixture.dataEMSMgr().FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    var ReturnValue: ErlValueType
    var seriousErrorFound: Bool = False
    fixture.dataEMSMgr().FinishProcessingUserInput = False
    # Note: ErlStack indexing: in C++, ErlStack(1) corresponds to index 0 in Mojo
    var stackIdx = Util.FindItemInList("SETNODESETPOINTTEST", fixture.dataRuntimeLang().ErlStack)
    ReturnValue = RuntimeLanguageProcessor.EvaluateExpression(
        fixture.state,
        fixture.dataRuntimeLang().ErlStack[stackIdx].Instruction[1].Argument2,
        seriousErrorFound)
    assert_true(seriousErrorFound)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginTimestepBeforePredictor, anyRan, None)
    seriousErrorFound = False
    ReturnValue = RuntimeLanguageProcessor.EvaluateExpression(
        fixture.state,
        fixture.dataRuntimeLang().ErlStack[stackIdx].Instruction[1].Argument2,
        seriousErrorFound)
    assert_false(seriousErrorFound)

def TestEMSVariableInitAfterRef1(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "EnergyManagementSystem:Program,",
        "    ev_discharge_program,                          !- Name",
        "    Set power_mult = site_temp_adj,                !- Program Line 1",
        "    Set site_temp_adj = 0.1;                       !- Program Line 2",
        "EnergyManagementSystem:ProgramCallingManager,",
        "    ev_discharge_pcm,              !- Name",
        "    BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "    ev_discharge_program;          !- Program Name 1",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    fixture.dataGlobal().SetupFlag = True
    fixture.dataGlobal().WarmupFlag = True
    var internalVarNum: Int = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_equal(0, internalVarNum)
    var anyRan: Bool
    assert_true(fixture.dataEMSMgr().GetEMSUserInput)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.SetupSimulation, anyRan, None)
    internalVarNum = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_gt(internalVarNum, 0)
    assert_false(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)
    assert_false(fixture.dataEMSMgr().GetEMSUserInput)
    EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginNewEnvironment, anyRan, None)
    internalVarNum = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_gt(internalVarNum, 0)
    assert_false(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)
    assert_false(fixture.dataEMSMgr().GetEMSUserInput)
    # ASSERT_THROW expects FatalError
    try:
        EMSManager.ManageEMS(fixture.state, EMSCallFrom.BeginTimestepBeforePredictor, anyRan, None)
        assert_true(False)  # should have thrown
    except FatalError:

    internalVarNum = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_gt(internalVarNum, 0)
    assert_false(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)
    seriousErrorFound = False
    var ReturnValue: ErlValueType = RuntimeLanguageProcessor.EvaluateExpression(
        fixture.state,
        fixture.dataRuntimeLang().ErlStack[Util.FindItemInList("EV_DISCHARGE_PROGRAM", fixture.dataRuntimeLang().ErlStack)].Instruction[1].Argument2,
        seriousErrorFound)
    assert_true(seriousErrorFound)
    var expected_error: String = delimited_string([
        "   ** Severe  ** Problem found in EMS EnergyPlus Runtime Language.",
        "   **   ~~~   ** Erl program name: EV_DISCHARGE_PROGRAM",
        "   **   ~~~   ** Erl program line number: 1",
        "   **   ~~~   ** Erl program line text: SET POWER_MULT = SITE_TEMP_ADJ",
        "   **   ~~~   ** Error message:  *** Error: EvaluateExpression: Variable = 'SITE_TEMP_ADJ' used in expression has not been initialized! *** ",
        "   **   ~~~   **  During Setup, Environment=, at Simulation time= 00:-15 - 00:00",
        "   **  Fatal  ** Previous EMS error caused program termination.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=Problem found in EMS EnergyPlus Runtime Language.",
    ])
    compare_err_stream_substring(expected_error)

def TestEMSVariableInitAfterRef2(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Version," + DataStringGlobals.MatchVersion + ";",
        "RunPeriod,",
        "    Run Period 1,            !- Name",
        "    1,                       !- Begin Month",
        "    1,                       !- Begin Day of Month",
        "    2007,                    !- Begin Year",
        "    1,                       !- End Month",
        "    1,                       !- End Day of Month",
        "    2007,                    !- End Year",
        "    Monday,                  !- Day of Week for Start Day",
        "    No,                      !- Use Weather File Holidays and Special Days",
        "    No,                      !- Use Weather File Daylight Saving Period",
        "    No,                      !- Apply Weekend Holiday Rule",
        "    Yes,                     !- Use Weather File Rain Indicators",
        "    Yes;                     !- Use Weather File Snow Indicators",
        "SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    No,                      !- Do Plant Sizing Calculation",
        "    No,                      !- Run Simulation for Sizing Periods",
        "    Yes,                     !- Run Simulation for Weather File Run Periods",
        "    ,                        !- Do HVAC Sizing Simulation for Sizing Periods",
        "    ;                        !- Maximum Number of HVAC Sizing Simulation Passes",
        "Site:Location,",
        "    Denver Stapleton Intl Arpt CO USA WMO=724690,  !- Name",
        "    39.77,                   !- Latitude {deg}",
        "    -104.87,                 !- Longitude {deg}",
        "    -7.00,                   !- Time Zone {hr}",
        "    1611.00;                 !- Elevation {m}",
        "Material,",
        "    Concrete Block,          !- Name",
        "    MediumRough,             !- Roughness",
        "    0.1014984,               !- Thickness {m}",
        "    0.3805070,               !- Conductivity {W/m-K}",
        "    608.7016,                !- Density {kg/m3}",
        "    836.8000;                !- Specific Heat {J/kg-K}",
        "Construction,",
        "    ConcConstruction,        !- Name",
        "    Concrete Block;          !- Outside Layer",
        "BuildingSurface:Detailed,"
        "    Wall,                    !- Name",
        "    Wall,                    !- Surface Type",
        "    ConcConstruction,        !- Construction Name",
        "    Zone,                    !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.000000,0.000000,10.00000,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0.000000,0.000000,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    10.00000,0.000000,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    10.00000,0.000000,10.00000;  !- X,Y,Z ==> Vertex 4 {m}",
        "Zone,"
        "    Zone,                    !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    6.000000,                !- X Origin {m}",
        "    6.000000,                !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        "EnergyManagementSystem:Program,",
        "    ev_discharge_program,                          !- Name",
        "    Set power_mult = site_temp_adj,                !- Program Line 1",
        "    Set site_temp_adj = 0.1;                       !- Program Line 2",
        "EnergyManagementSystem:ProgramCallingManager,",
        "    ev_discharge_pcm,              !- Name",
        "    BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point",
        "    ev_discharge_program;          !- Program Name 1",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    fixture.dataWeather().WeatherFileExists = True
    fixture.state.files.inputWeatherFilePath.filePath = configured_source_directory() / "weather/USA_CO_Golden-NREL.724666_TMY3.epw"
    var internalVarNum: Int = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_equal(0, internalVarNum)
    assert_true(fixture.dataEMSMgr().GetEMSUserInput)
    try:
        SimulationManager.ManageSimulation(fixture.state)
        assert_true(False)  # should throw
    except FatalError:

    internalVarNum = RuntimeLanguageProcessor.FindEMSVariable(fixture.state, "site_temp_adj", 1)
    assert_gt(internalVarNum, 0)
    assert_false(fixture.dataRuntimeLang().ErlVariable[internalVarNum].Value.initialized)

def EMSManager_CheckIfAnyEMS_OutEMS(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  Output:EnergyManagementSystem,                                                                ",
        "    Verbose,                 !- Actuator Availability Dictionary Reporting                      ",
        "    Verbose,                 !- Internal Variable Availability Dictionary Reporting             ",
        "    Verbose;                 !- EMS Runtime Language Debug Output Level                         ",
    ])
    assert_true(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    CheckIfAnyEMS(fixture.state)
    assert_true(fixture.dataGlobal().AnyEnergyManagementSystemInModel)

def EMSManager_TestFuntionCall(fixture: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Curve:Quadratic,",
        "  TestCurve,       !- Name",
        "  0.8,             !- Coefficient1 Constant",
        "  0.2,             !- Coefficient2 x",
        "  0.0,             !- Coefficient3 x**2",
        "  0.5,             !- Minimum Value of x",
        "  1.5;             !- Maximum Value of x",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test inside HVAC system iteration Loop,",
        "InsideHVACSystemIterationLoop,",
        "Test_InsideHVACSystemIterationLoop;",
        "EnergyManagementSystem:Program,",
        "Test_InsideHVACSystemIterationLoop,",
