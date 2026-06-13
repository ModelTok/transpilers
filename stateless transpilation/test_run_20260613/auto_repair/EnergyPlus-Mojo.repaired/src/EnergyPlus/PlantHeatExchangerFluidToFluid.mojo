from Array1D import Array1D_string, Array1D_bool, Array1D_Float64
from DataGlobals import BeginEnvrnFlag, AnyEnergyManagementSystemInModel, PlantFirstSizesOkayToFinalize, PlantFinalSizesOkayToReport, PlantFirstSizesOkayToReport
from EnergyPlus import EnergyPlusData
from PlantLocation import PlantLocation
from PlantComponent import PlantComponent
from Data.BaseData import BaseGlobalStruct
from Sched import Schedule as SchedSchedule, GetSchedule, GetScheduleAlwaysOn
from OutputProcessor import EndUseCat, SetupOutputVariable, StoreType, TimeStepType, Group
from DataPlant import PlantEquipmentType, LoopSideLocation, LoopDemandCalcScheme, HowMet, FreeCoolControlMode
from DataBranchAirLoopPlant import MassFlowTolerance
from DataEnvironment import OutDryBulbTemp, OutWetBulbTemp
from DataHVACGlobals import TimeStepSysSec, SmallWaterVolFlow, SmallLoad, CtrlVarType
from DataIPShortCuts import cAlphaFieldNames, cNumericFieldNames, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaArgs, rNumericArgs
from DataLoopNode import Node as NodeData, SensedNodeFlagValue
from DataPrecisionGlobals import EXP_UpperLimit, EXP_LowerLimit
from DataSizing import AutoSize, TypeOfPlantLoop, PlantSizData
from EMSManager import CheckIfNodeSetPointManagedByEMS
from FluidProperties import glycol
from General import SolveRoot
from InputProcessing.InputProcessor import InputProcessor as IP, getNumObjectsFound, getObjectDefMaxArgs, getObjectItem
from NodeInputManager import GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
from OutputReportPredefined import PreDefTableEntry, pdchMechType, pdchMechNomCap
from PlantUtilities import InitComponentNodes, SetComponentFlowRate, RegisterPlantCompDesignFlow, ScanPlantLoopsForObject, ScanPlantLoopsForNodeNum, InterConnectTwoPlantLoopSides
from ScheduleManager import GetSchedule
from UtilityRoutines import makeUPPER, ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowSevereItemNotFound, ShowSevereEmptyField, ShowSevereInvalidKey, ShowRecurringWarningErrorAtEnd
from BaseSizer import reportSizerOutput
from ErrorObjectHeader import ErrorObjectHeader
from HVAC import SmallWaterVolFlow, SmallLoad
from Constant import Units, eResource, InitConvTemp, iHoursInDay
from Math import abs, pow, exp, min, max
from String import String
from List import List
from Tuple import Tuple
from Assert import assert

alias ComponentClassName = "HeatExchanger:FluidToFluid"

# Enum definitions
@value
struct FluidHXType:
    var value: Int
    alias Invalid = Self(-1)
    alias CrossFlowBothUnMixed = Self(0)
    alias CrossFlowBothMixed = Self(1)
    alias CrossFlowSupplyLoopMixedDemandLoopUnMixed = Self(2)
    alias CrossFlowSupplyLoopUnMixedDemandLoopMixed = Self(3)
    alias CounterFlow = Self(4)
    alias ParallelFlow = Self(5)
    alias Ideal = Self(6)
    alias Num = Self(7)

@value
struct ControlType:
    var value: Int
    alias Invalid = Self(-1)
    alias UncontrolledOn = Self(0)
    alias OperationSchemeModulated = Self(1)
    alias OperationSchemeOnOff = Self(2)
    alias HeatingSetPointModulated = Self(3)
    alias HeatingSetPointOnOff = Self(4)
    alias CoolingSetPointModulated = Self(5)
    alias CoolingSetPointOnOff = Self(6)
    alias DualDeadBandSetPointModulated = Self(7)
    alias DualDeadBandSetPointOnOff = Self(8)
    alias CoolingDifferentialOnOff = Self(9)
    alias CoolingSetPointOnOffWithComponentOverride = Self(10)
    alias TrackComponentOnOff = Self(11)
    alias Num = Self(12)

@value
struct CtrlTempType:
    var value: Int
    alias Invalid = Self(-1)
    alias WetBulbTemperature = Self(0)
    alias DryBulbTemperature = Self(1)
    alias LoopTemperature = Self(2)
    alias Num = Self(3)

@value
struct HXAction:
    var value: Int
    alias Invalid = Self(-1)
    alias HeatingSupplySideLoop = Self(0)
    alias CoolingSupplySideLoop = Self(1)
    alias Num = Self(2)

# PlantConnectionStruct inherits PlantLocation (simulate with fields)
struct PlantConnectionStruct:
    # PlantLocation fields (assumed)
    var loopNum: Int = 0
    var loopSideNum: Int = 0
    var compNum: Int = 0
    var comp: __magic__? = None
    var loop: __magic__? = None
    # own fields
    var inletNodeNum: Int = 0
    var outletNodeNum: Int = 0
    var MassFlowRateMin: Float64 = 0.0
    var MassFlowRateMax: Float64 = 0.0
    var DesignVolumeFlowRate: Float64 = 0.0
    var DesignVolumeFlowRateWasAutoSized: Bool = False
    var MyLoad: Float64 = 0.0
    var MinLoad: Float64 = 0.0
    var MaxLoad: Float64 = 0.0
    var OptLoad: Float64 = 0.0
    var InletTemp: Float64 = 0.0
    var InletMassFlowRate: Float64 = 0.0
    var OutletTemp: Float64 = 0.0

struct PlantLocatorStruct:
    # PlantLocation fields
    var loopNum: Int = 0
    var loopSideNum: Int = 0
    var compNum: Int = 0
    var comp: __magic__? = None
    var loop: __magic__? = None
    var inletNodeNum: Int = 0

struct HeatExchangerStruct(PlantComponent):
    var Name: String = ""
    var availSched: SchedSchedule = None
    var HeatExchangeModelType: FluidHXType = FluidHXType.Invalid
    var UA: Float64 = 0.0
    var UAWasAutoSized: Bool = False
    var controlMode: ControlType = ControlType.Invalid
    var SetPointNodeNum: Int = 0
    var TempControlTol: Float64 = 0.0
    var ControlSignalTemp: CtrlTempType = CtrlTempType.Invalid
    var MinOperationTemp: Float64 = -99999.0
    var MaxOperationTemp: Float64 = 99999.0
    var DemandSideLoop: PlantConnectionStruct = PlantConnectionStruct()
    var SupplySideLoop: PlantConnectionStruct = PlantConnectionStruct()
    var HeatTransferMeteringEndUse: OutputProcessor.EndUseCat = OutputProcessor.EndUseCat.Invalid
    var ComponentUserName: String = ""
    var ComponentType: PlantEquipmentType = PlantEquipmentType.Invalid
    var OtherCompSupplySideLoop: PlantLocatorStruct = PlantLocatorStruct()
    var OtherCompDemandSideLoop: PlantLocatorStruct = PlantLocatorStruct()
    var SizingFactor: Float64 = 1.0
    var HeatTransferRate: Float64 = 0.0
    var HeatTransferEnergy: Float64 = 0.0
    var Effectiveness: Float64 = 0.0
    var OperationStatus: Float64 = 0.0
    var DmdSideModulatSolvNoConvergeErrorCount: Int = 0
    var DmdSideModulatSolvNoConvergeErrorIndex: Int = 0
    var DmdSideModulatSolvFailErrorCount: Int = 0
    var DmdSideModulatSolvFailErrorIndex: Int = 0
    var MyOneTimeFlag: Bool = True
    var MyFlag: Bool = True
    var MyEnvrnFlag: Bool = True

# Static arrays for names
var fluidHXTypeNames: List[String] = List[String](
    "CrossFlowBothUnMixed",
    "CrossFlowBothMixed",
    "CrossFlowSupplyMixedDemandUnMixed",
    "CrossFlowSupplyUnMixedDemandMixed",
    "CounterFlow",
    "ParallelFlow",
    "Ideal"
)
var fluidHXTypeNamesUC: List[String] = List[String](
    "CROSSFLOWBOTHUNMIXED",
    "CROSSFLOWBOTHMIXED",
    "CROSSFLOWSUPPLYMIXEDDEMANDUNMIXED",
    "CROSSFLOWSUPPLYUNMIXEDDEMANDMIXED",
    "COUNTERFLOW",
    "PARALLELFLOW",
    "IDEAL"
)
var controlTypeNames: List[String] = List[String](
    "UncontrolledOn",
    "OperationSchemeModulated",
    "OperationSchemeOnOff",
    "HeatingSetpointModulated",
    "HeatingSetpointOnOff",
    "CoolingSetpointModulated",
    "CoolingSetpointOnOff",
    "DualDeadbandSetpointModulated",
    "DualDeadbandSetpointOnOff",
    "CoolingDifferentialOnOff",
    "CoolingSetpointOnOffWithComponentOverride",
    "TrackComponentOnOff"
)
var controlTypeNamesUC: List[String] = List[String](
    "UNCONTROLLEDON",
    "OPERATIONSCHEMEMODULATED",
    "OPERATIONSCHEMEONOFF",
    "HEATINGSETPOINTMODULATED",
    "HEATINGSETPOINTONOFF",
    "COOLINGSETPOINTMODULATED",
    "COOLINGSETPOINTONOFF",
    "DUALDEADBANDSETPOINTMODULATED",
    "DUALDEADBANDSETPOINTONOFF",
    "COOLINGDIFFERENTIALONOFF",
    "COOLINGSETPOINTONOFFWITHCOMPONENTOVERRIDE",
    "TRACKCOMPONENTONOFF"
)
var ctrlTempTypeNames: List[String] = List[String](
    "WetBulbTemperature",
    "DryBulbTemperature",
    "Loop"
)
var ctrlTempTypeNamesUC: List[String] = List[String](
    "WETBULBTEMPERATURE",
    "DRYBULBTEMPERATURE",
    "LOOP"
)

# Factory function (static method)
def factory(state: EnergyPlusData, objectName: String) -> PlantComponent:
    if state.dataPlantHXFluidToFluid.GetInput:
        GetFluidHeatExchangerInput(state)
        state.dataPlantHXFluidToFluid.GetInput = False
    for obj in state.dataPlantHXFluidToFluid.FluidHX:
        if obj.Name == objectName:
            return obj
    ShowFatalError(state, String.format("LocalPlantFluidHXFactory: Error getting inputs for object named: {}", objectName))
    return None # LCOV_EXCL_LINE

# Member function implementations
def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
    self.initialize(state)

def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Float64, inout MinLoad: Float64, inout OptLoad: Float64):
    if calledFromLocation.loopNum == self.DemandSideLoop.loopNum:
        MinLoad = 0.0
        MaxLoad = self.DemandSideLoop.MaxLoad
        OptLoad = self.DemandSideLoop.MaxLoad * 0.9
    elif calledFromLocation.loopNum == self.SupplySideLoop.loopNum:
        self.size(state)
        MinLoad = 0.0
        MaxLoad = self.SupplySideLoop.MaxLoad
        OptLoad = self.SupplySideLoop.MaxLoad * 0.9

def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, _ RunFlag: Bool):
    self.initialize(state)
    if (self.controlMode.value == ControlType.OperationSchemeModulated.value) or (self.controlMode.value == ControlType.OperationSchemeOnOff.value):
        if calledFromLocation.loopNum == self.SupplySideLoop.loopNum:
            self.control(state, CurLoad, FirstHVACIteration)
    else:
        self.control(state, CurLoad, FirstHVACIteration)
    self.calculate(state,
                    state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).MassFlowRate,
                    state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).MassFlowRate)

def GetFluidHeatExchangerInput(state: EnergyPlusData):
    alias RoutineName = "GetFluidHeatExchangerInput: "
    alias routineName = "GetFluidHeatExchangerInput"
    var ErrorsFound: Bool = False
    var NumAlphas: Int = 0
    var NumNums: Int = 0
    var MaxNumAlphas: Int = 0
    var MaxNumNumbers: Int = 0
    var TotalArgs: Int = 0
    var cAlphaFieldNames: Array1D_string
    var cNumericFieldNames: Array1D_string
    var lNumericFieldBlanks: Array1D_bool
    var lAlphaFieldBlanks: Array1D_bool
    var cAlphaArgs: Array1D_string
    var rNumericArgs: Array1D_Float64
    var cCurrentModuleObject: String = "HeatExchanger:FluidToFluid"
    
    state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs == 0:
        return
    
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNums)
    MaxNumNumbers = NumNums
    MaxNumAlphas = NumAlphas
    cAlphaFieldNames.allocate(MaxNumAlphas)
    cAlphaArgs.allocate(MaxNumAlphas)
    lAlphaFieldBlanks.dimension(MaxNumAlphas, False)
    cNumericFieldNames.allocate(MaxNumNumbers)
    rNumericArgs.dimension(MaxNumNumbers, 0.0)
    lNumericFieldBlanks.dimension(MaxNumNumbers, False)
    
    if state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs > 0:
        state.dataPlantHXFluidToFluid.FluidHX.allocate(state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs)
        var IOStat: Int = 0
        for CompLoop in range(1, state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                     cCurrentModuleObject,
                                                                     CompLoop,
                                                                     cAlphaArgs,
                                                                     NumAlphas,
                                                                     rNumericArgs,
                                                                     NumNums,
                                                                     IOStat,
                                                                     lNumericFieldBlanks,
                                                                     lAlphaFieldBlanks,
                                                                     cAlphaFieldNames,
                                                                     cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1 - 1])  # 1-based to 0-based
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].Name = cAlphaArgs[1 - 1]
            if lAlphaFieldBlanks[2 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].availSched = GetScheduleAlwaysOn(state)
            elif (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].availSched = GetSchedule(state, cAlphaArgs[2 - 1])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[2 - 1], cAlphaArgs[2 - 1])
                ErrorsFound = True
            
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].DemandSideLoop.inletNodeNum = \
                GetOnlySingleNode(state,
                                        cAlphaArgs[3 - 1],
                                        ErrorsFound,
                                        ConnectionObjectType.HeatExchangerFluidToFluid,
                                        cAlphaArgs[1 - 1],
                                        FluidType.Water,
                                        ConnectionType.Inlet,
                                        CompFluidStream.Primary,
                                        ObjectIsNotParent)
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].DemandSideLoop.outletNodeNum = \
                GetOnlySingleNode(state,
                                        cAlphaArgs[4 - 1],
                                        ErrorsFound,
                                        ConnectionObjectType.HeatExchangerFluidToFluid,
                                        cAlphaArgs[1 - 1],
                                        FluidType.Water,
                                        ConnectionType.Outlet,
                                        CompFluidStream.Primary,
                                        ObjectIsNotParent)
            TestCompSet(state, cCurrentModuleObject, cAlphaArgs[1 - 1], cAlphaArgs[3 - 1], cAlphaArgs[4 - 1], "Loop Demand Side Plant Nodes")
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].DemandSideLoop.DesignVolumeFlowRate = rNumericArgs[1 - 1]
            if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].DemandSideLoop.DesignVolumeFlowRate == AutoSize:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].DemandSideLoop.DesignVolumeFlowRateWasAutoSized = True
            
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SupplySideLoop.inletNodeNum = \
                GetOnlySingleNode(state,
                                        cAlphaArgs[5 - 1],
                                        ErrorsFound,
                                        ConnectionObjectType.HeatExchangerFluidToFluid,
                                        cAlphaArgs[1 - 1],
                                        FluidType.Water,
                                        ConnectionType.Inlet,
                                        CompFluidStream.Secondary,
                                        ObjectIsNotParent)
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SupplySideLoop.outletNodeNum = \
                GetOnlySingleNode(state,
                                        cAlphaArgs[6 - 1],
                                        ErrorsFound,
                                        ConnectionObjectType.HeatExchangerFluidToFluid,
                                        cAlphaArgs[1 - 1],
                                        FluidType.Water,
                                        ConnectionType.Outlet,
                                        CompFluidStream.Secondary,
                                        ObjectIsNotParent)
            TestCompSet(state, cCurrentModuleObject, cAlphaArgs[1 - 1], cAlphaArgs[5 - 1], cAlphaArgs[6 - 1], "Loop Supply Side Plant Nodes")
            state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SupplySideLoop.DesignVolumeFlowRate = rNumericArgs[2 - 1]
            if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SupplySideLoop.DesignVolumeFlowRate == AutoSize:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SupplySideLoop.DesignVolumeFlowRateWasAutoSized = True
            
            if lAlphaFieldBlanks[7 - 1]:
                ShowSevereEmptyField(state, eoh, cAlphaFieldNames[7 - 1], cAlphaArgs[7 - 1])
                ErrorsFound = True
            elif (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatExchangeModelType = \
                        FluidHXType(getEnumValue(fluidHXTypeNamesUC, cAlphaArgs[7 - 1]))) == FluidHXType.Invalid:
                ShowSevereInvalidKey(state, eoh, cAlphaFieldNames[7 - 1], cAlphaArgs[7 - 1])
                ErrorsFound = True
            
            if not lNumericFieldBlanks[3 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].UA = rNumericArgs[3 - 1]
                if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].UA == AutoSize:
                    state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].UAWasAutoSized = True
            else:
                if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatExchangeModelType.value != FluidHXType.Ideal.value:
                    ShowSevereError(state, String.format("{}{}=\"{}\", invalid entry.", RoutineName, cCurrentModuleObject, cAlphaArgs[1 - 1]))
                    ShowContinueError(state, String.format("Missing entry for {}", cNumericFieldNames[3 - 1]))
                    ErrorsFound = True
            
            if lAlphaFieldBlanks[8 - 1]:
                ShowSevereEmptyField(state, eoh, cAlphaFieldNames[8 - 1])
                ErrorsFound = True
            elif (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode = \
                        ControlType(getEnumValue(controlTypeNamesUC, cAlphaArgs[8 - 1]))) == ControlType.Invalid:
                ShowSevereInvalidKey(state, eoh, cAlphaFieldNames[8 - 1], cAlphaArgs[8 - 1])
                ErrorsFound = True
            
            if not lAlphaFieldBlanks[9 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum = \
                    GetOnlySingleNode(state,
                                            cAlphaArgs[9 - 1],
                                            ErrorsFound,
                                            ConnectionObjectType.HeatExchangerFluidToFluid,
                                            cAlphaArgs[1 - 1],
                                            FluidType.Water,
                                            ConnectionType.Sensor,
                                            CompFluidStream.Primary,
                                            ObjectIsNotParent)
                if ((state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.HeatingSetPointModulated.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.HeatingSetPointOnOff.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointModulated.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOff.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value)):
                    if state.dataLoopNodes.Node(state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum).TempSetPoint == \
                        SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(state, String.format("{} Missing temperature setpoint for Node::Node = {}", RoutineName, cAlphaArgs[9 - 1]))
                            ShowContinueError(state, String.format("Occurs for {}=\"{}", cCurrentModuleObject, cAlphaArgs[1 - 1]))
                            ShowContinueError(state, " Use a setpoint manager to place a single temperature setpoint on the node")
                            ErrorsFound = True
                        else:
                            var NodeEMSSetPointMissing: Bool = False
                            CheckIfNodeSetPointManagedByEMS(state,
                                                                        state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum,
                                                                        CtrlVarType.Temp,
                                                                        NodeEMSSetPointMissing)
                            if NodeEMSSetPointMissing:
                                ShowSevereError(state, String.format("{} Missing temperature setpoint for node = {}", RoutineName, cAlphaArgs[9 - 1]))
                                ShowContinueError(state, String.format("Occurs for {}=\"{}", cCurrentModuleObject, cAlphaArgs[1 - 1]))
                                ShowContinueError(state, "Use a setpoint manager or EMS actuator to place a single temperature setpoint on the node")
                                ErrorsFound = True
                elif ((state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.DualDeadBandSetPointModulated.value) or
                       (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.DualDeadBandSetPointOnOff.value)):
                    if ((state.dataLoopNodes.Node(state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum).TempSetPointHi == \
                         SensedNodeFlagValue) or
                        (state.dataLoopNodes.Node(state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum).TempSetPointLo == \
                         SensedNodeFlagValue)):
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(state, String.format("{} Missing dual temperature setpoints for node = {}", RoutineName, cAlphaArgs[9 - 1]))
                            ShowContinueError(state, String.format("Occurs for {}=\"{}", cCurrentModuleObject, cAlphaArgs[1 - 1]))
                            ShowContinueError(state, " Use a setpoint manager to place a dual temperature setpoint on the node")
                            ErrorsFound = True
                        else:
                            var NodeEMSSetPointMissing: Bool = False
                            CheckIfNodeSetPointManagedByEMS(state,
                                                                        state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum,
                                                                        CtrlVarType.Temp,
                                                                        NodeEMSSetPointMissing)
                            CheckIfNodeSetPointManagedByEMS(state,
                                                                        state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SetPointNodeNum,
                                                                        CtrlVarType.Temp,
                                                                        NodeEMSSetPointMissing)
                            if NodeEMSSetPointMissing:
                                ShowSevereError(state, String.format("{} Missing temperature setpoint for node = {}", RoutineName, cAlphaArgs[9 - 1]))
                                ShowContinueError(state, String.format("Occurs for {}=\"{}", cCurrentModuleObject, cAlphaArgs[1 - 1]))
                                ShowContinueError(state, "Use a setpoint manager or EMS actuators to place a dual temperature setpoints on the node")
                                ErrorsFound = True
            else:
                if ((state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.HeatingSetPointModulated.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.HeatingSetPointOnOff.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointModulated.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOff.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.DualDeadBandSetPointModulated.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.DualDeadBandSetPointOnOff.value) or
                    (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value)):
                    ShowSevereError(state, String.format("{}{}=\"{}\", invalid entry.", RoutineName, cCurrentModuleObject, cAlphaArgs[1 - 1]))
                    ShowContinueError(state, String.format("Missing entry for {}", cAlphaFieldNames[9 - 1]))
                    ErrorsFound = True
            
            if not lNumericFieldBlanks[4 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].TempControlTol = rNumericArgs[4 - 1]
            else:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].TempControlTol = 0.01
            
            var endUseCat: String = makeUPPER(cAlphaArgs[10 - 1])
            if endUseCat == "FREECOOLING":
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatTransferMeteringEndUse = EndUseCat.FreeCooling
            elif endUseCat == "HEATREJECTION":
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatTransferMeteringEndUse = EndUseCat.HeatRejection
            elif endUseCat == "HEATRECOVERYFORCOOLING":
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatTransferMeteringEndUse = EndUseCat.HeatRecoveryForCooling
            elif endUseCat == "HEATRECOVERYFORHEATING":
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatTransferMeteringEndUse = EndUseCat.HeatRecoveryForHeating
            elif endUseCat == "LOOPTOLOOP":
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].HeatTransferMeteringEndUse = EndUseCat.LoopToLoop
            else:
                ShowWarningError(state,
                    String.format("{} = {}, {} is an invalid value for {}", cCurrentModuleObject, cAlphaArgs[1 - 1], cAlphaArgs[10 - 1], cAlphaFieldNames[10 - 1]))
                ErrorsFound = True
            
            if not lAlphaFieldBlanks[11 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].OtherCompSupplySideLoop.inletNodeNum = \
                    GetOnlySingleNode(state,
                                            cAlphaArgs[11 - 1],
                                            ErrorsFound,
                                            ConnectionObjectType.HeatExchangerFluidToFluid,
                                            cAlphaArgs[1 - 1],
                                            FluidType.Water,
                                            ConnectionType.Actuator,
                                            CompFluidStream.Primary,
                                            ObjectIsNotParent)
            else:
                if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value:
                    ShowSevereError(state, String.format("{}{}=\"{}\", invalid entry.", RoutineName, cCurrentModuleObject, cAlphaArgs[1 - 1]))
                    ShowContinueError(state, String.format("Missing entry for {}", cAlphaFieldNames[11 - 1]))
                    ErrorsFound = True
            
            if not lAlphaFieldBlanks[12 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].OtherCompDemandSideLoop.inletNodeNum = \
                    GetOnlySingleNode(state,
                                            cAlphaArgs[12 - 1],
                                            ErrorsFound,
                                            ConnectionObjectType.HeatExchangerFluidToFluid,
                                            cAlphaArgs[1 - 1],
                                            FluidType.Water,
                                            ConnectionType.Actuator,
                                            CompFluidStream.Primary,
                                            ObjectIsNotParent)
            else:
                if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value:
                    ShowSevereError(state, String.format("{}{}=\"{}\", invalid entry.", RoutineName, cCurrentModuleObject, cAlphaArgs[1 - 1]))
                    ShowContinueError(state, String.format("Missing entry for {}", cAlphaFieldNames[12 - 1]))
                    ErrorsFound = True
            
            if lAlphaFieldBlanks[13 - 1]:
                if state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[13 - 1], cAlphaFieldNames[8 - 1], cAlphaArgs[8 - 1])
                    ErrorsFound = True
            elif (state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].ControlSignalTemp = \
                        CtrlTempType(getEnumValue(ctrlTempTypeNamesUC, cAlphaArgs[13 - 1]))) == CtrlTempType.Invalid:
                ShowSevereInvalidKey(state, eoh, cAlphaFieldNames[13 - 1], cAlphaArgs[13 - 1])
                ErrorsFound = True
            
            if not lNumericFieldBlanks[5 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SizingFactor = rNumericArgs[5 - 1]
            else:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].SizingFactor = 1.0
            
            if not lNumericFieldBlanks[6 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].MinOperationTemp = rNumericArgs[6 - 1]
            else:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].MinOperationTemp = -9999.0
            
            if not lNumericFieldBlanks[7 - 1]:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].MaxOperationTemp = rNumericArgs[7 - 1]
            else:
                state.dataPlantHXFluidToFluid.FluidHX[CompLoop - 1].MaxOperationTemp = 9999.0
    
    if ErrorsFound:
        ShowFatalError(state, String.format("{}Errors found in processing {} input.", RoutineName, cCurrentModuleObject))

def setupOutputVars(inout self, state: EnergyPlusData):
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Heat Transfer Rate",
                        Units.W,
                        self.HeatTransferRate,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Heat Transfer Energy",
                        Units.J,
                        self.HeatTransferEnergy,
                        TimeStepType.System,
                        StoreType.Sum,
                        self.Name,
                        eResource.EnergyTransfer,
                        Group.Plant,
                        self.HeatTransferMeteringEndUse)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Supply Side Mass Flow Rate",
                        Units.kg_s,
                        self.SupplySideLoop.InletMassFlowRate,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Supply Side Inlet Temperature",
                        Units.C,
                        self.SupplySideLoop.InletTemp,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Supply Side Outlet Temperature",
                        Units.C,
                        self.SupplySideLoop.OutletTemp,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Demand Side Mass Flow Rate",
                        Units.kg_s,
                        self.DemandSideLoop.InletMassFlowRate,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Demand Side Inlet Temperature",
                        Units.C,
                        self.DemandSideLoop.InletTemp,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Loop Demand Side Outlet Temperature",
                        Units.C,
                        self.DemandSideLoop.OutletTemp,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Operation Status",
                        Units.None,
                        self.OperationStatus,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)
    SetupOutputVariable(state,
                        "Fluid Heat Exchanger Effectiveness",
                        Units.None,
                        self.Effectiveness,
                        TimeStepType.System,
                        StoreType.Average,
                        self.Name)

def initialize(inout self, state: EnergyPlusData):
    alias RoutineNameNoColon = "InitFluidHeatExchanger"
    self.oneTimeInit(state) # plant setup
    if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
        var rho: Float64 = self.DemandSideLoop.loop.glycol.getDensity(state, InitConvTemp, RoutineNameNoColon)
        self.DemandSideLoop.MassFlowRateMax = rho * self.DemandSideLoop.DesignVolumeFlowRate
        InitComponentNodes(state,
                                           self.DemandSideLoop.MassFlowRateMin,
                                           self.DemandSideLoop.MassFlowRateMax,
                                           self.DemandSideLoop.inletNodeNum,
                                           self.DemandSideLoop.outletNodeNum)
        rho = self.SupplySideLoop.loop.glycol.getDensity(state, InitConvTemp, RoutineNameNoColon)
        self.SupplySideLoop.MassFlowRateMax = rho * self.SupplySideLoop.DesignVolumeFlowRate
        InitComponentNodes(state,
                                           self.SupplySideLoop.MassFlowRateMin,
                                           self.SupplySideLoop.MassFlowRateMax,
                                           self.SupplySideLoop.inletNodeNum,
                                           self.SupplySideLoop.outletNodeNum)
        self.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        self.MyEnvrnFlag = True
    self.DemandSideLoop.InletTemp = state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp
    self.SupplySideLoop.InletTemp = state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp
    if self.controlMode.value == ControlType.CoolingSetPointOnOffWithComponentOverride.value:
        self.OtherCompSupplySideLoop.comp.FreeCoolCntrlMinCntrlTemp = \
            state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPoint - self.TempControlTol

def size(inout self, state: EnergyPlusData):
    alias RoutineName = "SizeFluidHeatExchanger"
    var PltSizNumSupSide: Int = self.SupplySideLoop.loop.PlantSizNum
    var PltSizNumDmdSide: Int = self.DemandSideLoop.loop.PlantSizNum
    var tmpSupSideDesignVolFlowRate: Float64 = self.SupplySideLoop.DesignVolumeFlowRate
    if self.SupplySideLoop.DesignVolumeFlowRateWasAutoSized:
        if PltSizNumSupSide > 0:
            if state.dataSize.PlantSizData[PltSizNumSupSide - 1].DesVolFlowRate >= SmallWaterVolFlow:
                tmpSupSideDesignVolFlowRate = state.dataSize.PlantSizData[PltSizNumSupSide - 1].DesVolFlowRate * self.SizingFactor
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.SupplySideLoop.DesignVolumeFlowRate = tmpSupSideDesignVolFlowRate
            else:
                tmpSupSideDesignVolFlowRate = 0.0
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.SupplySideLoop.DesignVolumeFlowRate = tmpSupSideDesignVolFlowRate
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                reportSizerOutput(state,
                                             "HeatExchanger:FluidToFluid",
                                             self.Name,
                                             "Loop Supply Side Design Fluid Flow Rate [m3/s]",
                                             self.SupplySideLoop.DesignVolumeFlowRate)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                reportSizerOutput(state,
                                             "HeatExchanger:FluidToFluid",
                                             self.Name,
                                             "Initial Loop Supply Side Design Fluid Flow Rate [m3/s]",
                                             self.SupplySideLoop.DesignVolumeFlowRate)
        else:
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "SizeFluidHeatExchanger: Autosizing of requires a loop Sizing:Plant object")
                ShowContinueError(state, String.format("Occurs in heat exchanger object={}", self.Name))
    RegisterPlantCompDesignFlow(state, self.SupplySideLoop.inletNodeNum, tmpSupSideDesignVolFlowRate)
    var tmpDmdSideDesignVolFlowRate: Float64 = self.DemandSideLoop.DesignVolumeFlowRate
    if self.DemandSideLoop.DesignVolumeFlowRateWasAutoSized:
        if tmpSupSideDesignVolFlowRate > SmallWaterVolFlow:
            tmpDmdSideDesignVolFlowRate = tmpSupSideDesignVolFlowRate
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.DemandSideLoop.DesignVolumeFlowRate = tmpDmdSideDesignVolFlowRate
        else:
            tmpDmdSideDesignVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.DemandSideLoop.DesignVolumeFlowRate = tmpDmdSideDesignVolFlowRate
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            reportSizerOutput(state,
                                         "HeatExchanger:FluidToFluid",
                                         self.Name,
                                         "Loop Demand Side Design Fluid Flow Rate [m3/s]",
                                         self.DemandSideLoop.DesignVolumeFlowRate)
        if state.dataPlnt.PlantFirstSizesOkayToReport:
            reportSizerOutput(state,
                                         "HeatExchanger:FluidToFluid",
                                         self.Name,
                                         "Initial Loop Demand Side Design Fluid Flow Rate [m3/s]",
                                         self.DemandSideLoop.DesignVolumeFlowRate)
    RegisterPlantCompDesignFlow(state, self.DemandSideLoop.inletNodeNum, tmpDmdSideDesignVolFlowRate)
    if self.UAWasAutoSized:
        if PltSizNumSupSide > 0 and PltSizNumDmdSide > 0:
            var tmpDeltaTloopToLoop: Float64 = 0.0
            var loopType = state.dataSize.PlantSizData[PltSizNumSupSide - 1].LoopType
            if (loopType == TypeOfPlantLoop.Heating) or (loopType == TypeOfPlantLoop.Steam):
                tmpDeltaTloopToLoop = \
                    abs((state.dataSize.PlantSizData[PltSizNumSupSide - 1].ExitTemp - state.dataSize.PlantSizData[PltSizNumSupSide - 1].DeltaT) -
                             state.dataSize.PlantSizData[PltSizNumDmdSide - 1].ExitTemp)
            elif (loopType == TypeOfPlantLoop.Cooling) or (loopType == TypeOfPlantLoop.Condenser):
                tmpDeltaTloopToLoop = \
                    abs((state.dataSize.PlantSizData[PltSizNumSupSide - 1].ExitTemp + state.dataSize.PlantSizData[PltSizNumSupSide - 1].DeltaT) -
                             state.dataSize.PlantSizData[PltSizNumDmdSide - 1].ExitTemp)
            else:
                assert(False)
            tmpDeltaTloopToLoop = max(2.0, tmpDeltaTloopToLoop)
            var tmpDeltaTSupLoop: Float64 = state.dataSize.PlantSizData[PltSizNumSupSide - 1].DeltaT
            if tmpSupSideDesignVolFlowRate >= SmallWaterVolFlow:
                var Cp: Float64 = self.SupplySideLoop.loop.glycol.getSpecificHeat(state, InitConvTemp, RoutineName)
                var rho: Float64 = self.SupplySideLoop.loop.glycol.getDensity(state, InitConvTemp, RoutineName)
                var tmpDesCap: Float64 = Cp * rho * tmpDeltaTSupLoop * tmpSupSideDesignVolFlowRate
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.UA = tmpDesCap / tmpDeltaTloopToLoop
            else:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.UA = 0.0
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                reportSizerOutput(state, "HeatExchanger:FluidToFluid", self.Name, "Heat Exchanger U-Factor Times Area Value [W/C]", self.UA)
                reportSizerOutput(state,
                                             "HeatExchanger:FluidToFluid",
                                             self.Name,
                                             "Loop-to-loop Temperature Difference Used to Size Heat Exchanger U-Factor Times Area Value [C]",
                                             tmpDeltaTloopToLoop)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                reportSizerOutput(state, "HeatExchanger:FluidToFluid", self.Name, "Initial Heat Exchanger U-Factor Times Area Value [W/C]", self.UA)
                reportSizerOutput(state,
                                             "HeatExchanger:FluidToFluid",
                                             self.Name,
                                             "Initial Loop-to-loop Temperature Difference Used to Size Heat Exchanger U-Factor Times Area Value [C]",
                                             tmpDeltaTloopToLoop)
        else:
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "SizeFluidHeatExchanger: Autosizing of heat Exchanger UA requires a loop Sizing:Plant objects for both loops")
                ShowContinueError(state, String.format("Occurs in heat exchanger object={}", self.Name))
    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
        if PltSizNumSupSide > 0:
            var loopType = state.dataSize.PlantSizData[PltSizNumSupSide - 1].LoopType
            if (loopType == TypeOfPlantLoop.Heating) or (loopType == TypeOfPlantLoop.Steam):
                state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp = \
                    (state.dataSize.PlantSizData[PltSizNumSupSide - 1].ExitTemp - state.dataSize.PlantSizData[PltSizNumSupSide - 1].DeltaT)
            elif (loopType == TypeOfPlantLoop.Cooling) or (loopType == TypeOfPlantLoop.Condenser):
                state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp = \
                    (state.dataSize.PlantSizData[PltSizNumSupSide - 1].ExitTemp + state.dataSize.PlantSizData[PltSizNumSupSide - 1].DeltaT)
            else:

        else:
            if self.SupplySideLoop.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp = \
                    state.dataLoopNodes.Node(self.SupplySideLoop.loop.TempSetPointNodeNum).TempSetPoint
            elif self.SupplySideLoop.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp = \
                    (state.dataLoopNodes.Node(self.SupplySideLoop.loop.TempSetPointNodeNum).TempSetPointHi +
                     state.dataLoopNodes.Node(self.SupplySideLoop.loop.TempSetPointNodeNum).TempSetPointLo) / 2.0
        if PltSizNumDmdSide > 0:
            state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp = state.dataSize.PlantSizData[PltSizNumDmdSide - 1].ExitTemp
        else:
            if self.DemandSideLoop.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp = \
                    state.dataLoopNodes.Node(self.DemandSideLoop.loop.TempSetPointNodeNum).TempSetPoint
            elif self.DemandSideLoop.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp = \
                    (state.dataLoopNodes.Node(self.DemandSideLoop.loop.TempSetPointNodeNum).TempSetPointHi +
                     state.dataLoopNodes.Node(self.DemandSideLoop.loop.TempSetPointNodeNum).TempSetPointLo) / 2.0
        var rho: Float64 = self.SupplySideLoop.loop.glycol.getDensity(state, InitConvTemp, RoutineName)
        var SupSideMdot: Float64 = self.SupplySideLoop.DesignVolumeFlowRate * rho
        rho = self.DemandSideLoop.loop.glycol.getDensity(state, InitConvTemp, RoutineName)
        var DmdSideMdot: Float64 = self.DemandSideLoop.DesignVolumeFlowRate * rho
        self.calculate(state, SupSideMdot, DmdSideMdot)
        self.SupplySideLoop.MaxLoad = abs(self.HeatTransferRate)
    if state.dataPlnt.PlantFinalSizesOkayToReport:
        PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "HeatExchanger:FluidToFluid")
        PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.SupplySideLoop.MaxLoad)
    self.updateCompFlowData(state)

def control(inout self, state: EnergyPlusData, MyLoad: Float64, FirstHVACIteration: Bool):
    alias RoutineName = "ControlFluidHeatExchanger"
    var mdotSupSide: Float64
    var mdotDmdSide: Float64
    var ScheduledOff: Bool
    var AvailSchedValue: Float64 = self.availSched.getCurrentVal()
    if AvailSchedValue <= 0:
        ScheduledOff = True
    else:
        ScheduledOff = False
    var LimitTrippedOff: Bool = False
    if (state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp < self.MinOperationTemp) or \
        (state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp < self.MinOperationTemp):
        LimitTrippedOff = True
    if (state.dataLoopNodes.Node(self.SupplySideLoop.inletNodeNum).Temp > self.MaxOperationTemp) or \
        (state.dataLoopNodes.Node(self.DemandSideLoop.inletNodeNum).Temp > self.MaxOperationTemp):
        LimitTrippedOff = True
    if not ScheduledOff and not LimitTrippedOff:
        if self.controlMode.value == ControlType.UncontrolledOn.value:
            mdotSupSide = self.SupplySideLoop.MassFlowRateMax
            SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
            if mdotSupSide > MassFlowTolerance:
                mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
            else:
                mdotDmdSide = 0.0
            SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.OperationSchemeModulated.value:
            if abs(MyLoad) > SmallLoad:
                if MyLoad < -1.0 * SmallLoad: # requesting cooling
                    var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
                    if DeltaTCooling > self.TempControlTol:
                        mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if mdotSupSide > MassFlowTolerance:
                            var cp: Float64 = self.SupplySideLoop.loop.glycol.getSpecificHeat(state, self.SupplySideLoop.InletTemp, RoutineName)
                            var TargetLeavingTemp: Float64 = self.SupplySideLoop.InletTemp - abs(MyLoad) / (cp * mdotSupSide)
                            self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.CoolingSupplySideLoop)
                        else:
                            mdotDmdSide = 0.0
                            SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                    else:
                        mdotSupSide = 0.0
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if FirstHVACIteration:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                else: # requesting heating
                    var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
                    if DeltaTHeating > self.TempControlTol:
                        mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if mdotSupSide > MassFlowTolerance:
                            var cp: Float64 = self.SupplySideLoop.loop.glycol.getSpecificHeat(state, self.SupplySideLoop.InletTemp, RoutineName)
                            var TargetLeavingTemp: Float64 = self.SupplySideLoop.InletTemp + abs(MyLoad) / (cp * mdotSupSide)
                            self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.HeatingSupplySideLoop)
                        else:
                            mdotDmdSide = 0.0
                            SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                    else:
                        mdotSupSide = 0.0
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if FirstHVACIteration:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else: # no load
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.OperationSchemeOnOff.value:
            if abs(MyLoad) > SmallLoad:
                if MyLoad < SmallLoad: # requesting cooling
                    var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
                    if DeltaTCooling > self.TempControlTol:
                        mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if mdotSupSide > MassFlowTolerance:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                    else:
                        mdotSupSide = 0.0
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if FirstHVACIteration:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                else: # requesting heating
                    var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
                    if DeltaTHeating > self.TempControlTol:
                        mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if mdotSupSide > MassFlowTolerance:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
                    else:
                        mdotSupSide = 0.0
                        SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                        if FirstHVACIteration:
                            mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                        else:
                            mdotDmdSide = 0.0
                        SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else: # no load
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.HeatingSetPointModulated.value:
            var SetPointTemp: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPoint
            var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
            if (DeltaTHeating > self.TempControlTol) and (SetPointTemp > self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    var TargetLeavingTemp: Float64 = SetPointTemp
                    self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.HeatingSupplySideLoop)
                else:
                    mdotDmdSide = 0.0
                    SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else:
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if FirstHVACIteration:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.HeatingSetPointOnOff.value:
            var SetPointTemp: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPoint
            var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
            if (DeltaTHeating > self.TempControlTol) and (SetPointTemp > self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else:
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if FirstHVACIteration:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.CoolingSetPointModulated.value:
            var SetPointTemp: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPoint
            var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
            if (DeltaTCooling > self.TempControlTol) and (SetPointTemp < self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    var TargetLeavingTemp: Float64 = SetPointTemp
                    self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.CoolingSupplySideLoop)
                else:
                    mdotDmdSide = 0.0
                    SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else:
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if FirstHVACIteration:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.CoolingSetPointOnOff.value:
            var SetPointTemp: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPoint
            var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
            if (DeltaTCooling > self.TempControlTol) and (SetPointTemp < self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else:
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if FirstHVACIteration:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.DualDeadBandSetPointModulated.value:
            var SetPointTempLo: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPointLo
            var SetPointTempHi: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPointHi
            var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
            var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
            if (DeltaTCooling > self.TempControlTol) and (SetPointTempHi < self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    var TargetLeavingTemp: Float64 = SetPointTempHi
                    self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.CoolingSupplySideLoop)
                else:
                    mdotDmdSide = 0.0
                    SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            elif (DeltaTHeating > self.TempControlTol) and (SetPointTempLo > self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if mdotSupSide > MassFlowTolerance:
                    var TargetLeavingTemp: Float64 = SetPointTempLo
                    self.findDemandSideLoopFlow(state, TargetLeavingTemp, HXAction.HeatingSupplySideLoop)
                else:
                    mdotDmdSide = 0.0
                    SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
            else:
                mdotSupSide = 0.0
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.inletNodeNum, self.SupplySideLoop.outletNodeNum, self.SupplySideLoop)
                if FirstHVACIteration:
                    mdotDmdSide = self.DemandSideLoop.MassFlowRateMax
                else:
                    mdotDmdSide = 0.0
                SetComponentFlowRate(state, mdotDmdSide, self.DemandSideLoop.inletNodeNum, self.DemandSideLoop.outletNodeNum, self.DemandSideLoop)
        elif self.controlMode.value == ControlType.DualDeadBandSetPointOnOff.value:
            var SetPointTempLo: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPointLo
            var SetPointTempHi: Float64 = state.dataLoopNodes.Node(self.SetPointNodeNum).TempSetPointHi
            var DeltaTCooling: Float64 = self.SupplySideLoop.InletTemp - self.DemandSideLoop.InletTemp
            var DeltaTHeating: Float64 = self.DemandSideLoop.InletTemp - self.SupplySideLoop.InletTemp
            if (DeltaTCooling > self.TempControlTol) and (SetPointTempHi < self.SupplySideLoop.InletTemp):
                mdotSupSide = self.SupplySideLoop.MassFlowRateMax
                SetComponentFlowRate(state, mdotSupSide, self.SupplySideLoop.in