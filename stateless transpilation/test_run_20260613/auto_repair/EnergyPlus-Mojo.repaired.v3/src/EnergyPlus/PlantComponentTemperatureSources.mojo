// ============================================================
// This file is a 1:1 translation of PlantComponentTemperatureSources.cc
// to Mojo, preserving all names, formulas, and structure.
// ObjexxFCL () -> [] 0-based indexing.
// format -> F"..."  string interpolation.
// All cross-module calls are assumed to be imported from the
// same relative path (e.g., "ScheduleManager" -> Sched).
// ============================================================

// ======== Imports (assume all modules are available) ========
from .Data.BaseData import BaseGlobalStruct, EnergyPlusData
from .DataGlobals import BeginEnvrnFlag, DisplayExtraWarnings, AnyEnergyManagementSystemInModel
from DataHVACGlobals import TimeStepSysSec, SmallWaterVolFlow
from .DataIPShortCuts import cCurrentModuleObject, cAlphaArgs, rNumericArgs, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames
from .DataLoopNode import NodeData
from DataSizing import PlantSizData, AutoSize, AutoVsHardSizingThreshold
from EMSManager import SetupEMSActuator
from FluidProperties import FluidProperties
from General import ShowFatalError, ShowSevereError, ShowContinueError, ShowMessage, ShowSevereItemNotFound
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import Node
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
from .Plant.DataPlant import PlantEquipmentType, PlantFirstSizesOkayToFinalize, PlantFirstSizesOkayToReport, PlantFinalSizesOkayToReport, PlantFinalSizesOkayToReport
from .Plant.PlantLocation import PlantLocation
from .PlantComponent import PlantComponent
from PlantUtilities import PlantUtilities
from ScheduleManager import Schedule as Sched  // alias to match C++ usage
from .Autosizing.Base import BaseSizer
from UtilityRoutines import ErrorObjectHeader

// ======== Enum ========
enum TempSpecType: Int32:
    Invalid = -1
    Constant = 0
    Schedule = 1
    Num = 2

// ======== Trait (matching C++ PlantComponent base class) ========
trait PlantComponent:
    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool)
    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64)
    def getSizingFactor(inout self, _SizFac: Float64)
    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation)
    def oneTimeInit(inout self, state: EnergyPlusData)

// ======== WaterSourceSpecs struct ========
struct WaterSourceSpecs(PlantComponent):
    var Name: String
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var DesVolFlowRate: Float64
    var DesVolFlowRateWasAutoSized: Bool
    var MassFlowRateMax: Float64
    var EMSOverrideOnMassFlowRateMax: Bool
    var EMSOverrideValueMassFlowRateMax: Float64
    var MassFlowRate: Float64
    var tempSpecType: TempSpecType
    var tempSpecSched: Optional[Sched.Schedule^]  // pointer to schedule (owned)
    var BoundaryTemp: Float64
    var OutletTemp: Float64
    var InletTemp: Float64
    var HeatRate: Float64
    var HeatEnergy: Float64
    var plantLoc: PlantLocation
    var SizFac: Float64
    var CheckEquipName: Bool
    var MyFlag: Bool
    var MyEnvironFlag: Bool
    var IsThisSized: Bool

    // default constructor matching C++ initializer list
    def __init__(inout self):
        self.Name = ""
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.DesVolFlowRate = 0.0
        self.DesVolFlowRateWasAutoSized = False
        self.MassFlowRateMax = 0.0
        self.EMSOverrideOnMassFlowRateMax = False
        self.EMSOverrideValueMassFlowRateMax = 0.0
        self.MassFlowRate = 0.0
        self.tempSpecType = TempSpecType.Invalid
        self.tempSpecSched = None
        self.BoundaryTemp = 0.0
        self.OutletTemp = 0.0
        self.InletTemp = 0.0
        self.HeatRate = 0.0
        self.HeatEnergy = 0.0
        self.plantLoc = PlantLocation()
        self.SizFac = 0.0
        self.CheckEquipName = True
        self.MyFlag = True
        self.MyEnvironFlag = True
        self.IsThisSized = False

    // static factory
    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> &PlantComponent:
        if state.dataPlantCompTempSrc.getWaterSourceInput:
            GetWaterSourceInput(state)
            state.dataPlantCompTempSrc.getWaterSourceInput = False
        for i in range(len(state.dataPlantCompTempSrc.WaterSource)):
            var waterSource = &state.dataPlantCompTempSrc.WaterSource[i]
            if waterSource[].Name == objectName:
                return waterSource[]
        ShowFatalError(state, F"LocalTemperatureSourceFactory: Error getting inputs for temperature source named: {objectName}")
        return &state.dataPlantCompTempSrc.WaterSource[0]  // unreachable but needed

    def initialize(inout self, state: EnergyPlusData, MyLoad: Float64):
        alias RoutineName = "InitWaterSource"
        self.oneTimeInit(state)
        if self.MyEnvironFlag and state.dataGlobal.BeginEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
            var rho = self.plantLoc.loop.glycol.getDensity(state, 20.0, RoutineName)  // Constant::InitConvTemp ~20.0
            self.MassFlowRateMax = self.DesVolFlowRate * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.MassFlowRateMax, self.InletNodeNum, self.OutletNodeNum)
            self.MyEnvironFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvironFlag = True
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum - 1].Temp
        if self.tempSpecType == TempSpecType.Schedule:
            if let sched = self.tempSpecSched:
                self.BoundaryTemp = sched.getCurrentVal()
        var cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.BoundaryTemp, RoutineName)
        var delta_temp = self.BoundaryTemp - self.InletTemp
        if abs(delta_temp) < 0.001:
            if abs(MyLoad) < 0.001:
                self.MassFlowRate = 0.0
            else:
                self.MassFlowRate = self.MassFlowRateMax
        else:
            self.MassFlowRate = MyLoad / (cp * delta_temp)
        if self.MassFlowRate < 0:
            self.MassFlowRate = 0.0
        else:
            if not self.EMSOverrideOnMassFlowRateMax:
                self.MassFlowRate = min(self.MassFlowRate, self.MassFlowRateMax)
            else:
                self.MassFlowRate = min(self.MassFlowRate, self.EMSOverrideValueMassFlowRateMax)
        PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)

    def setupOutputVars(inout self, state: EnergyPlusData):
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Mass Flow Rate",
                            "kg/s",
                            self.MassFlowRate,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Inlet Temperature",
                            "C",
                            self.InletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Outlet Temperature",
                            "C",
                            self.OutletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Source Temperature",
                            "C",
                            self.BoundaryTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Heat Transfer Rate",
                            "W",
                            self.HeatRate,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Plant Temperature Source Component Heat Transfer Energy",
                            "J",
                            self.HeatEnergy,
                            TimeStepType.System,
                            StoreType.Sum,
                            self.Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state,
                             "PlantComponent:TemperatureSource",
                             self.Name,
                             "Maximum Mass Flow Rate",
                             "[kg/s]",
                             self.EMSOverrideOnMassFlowRateMax,
                             self.EMSOverrideValueMassFlowRateMax)

    def autosize(inout self, state: EnergyPlusData):
        var ErrorsFound: Bool = False
        var DesVolFlowRateUser: Float64 = 0.0
        var tmpVolFlowRate: Float64 = self.DesVolFlowRate
        var PltSizNum = self.plantLoc.loop.PlantSizNum
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                tmpVolFlowRate = state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate
                if not self.DesVolFlowRateWasAutoSized:
                    tmpVolFlowRate = self.DesVolFlowRate
            else:
                if self.DesVolFlowRateWasAutoSized:
                    tmpVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.DesVolFlowRateWasAutoSized:
                    self.DesVolFlowRate = tmpVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "PlantComponent:TemperatureSource", self.Name, "Design Size Design Fluid Flow Rate [m3/s]", tmpVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     "PlantComponent:TemperatureSource",
                                                     self.Name,
                                                     "Initial Design Size Design Fluid Flow Rate [m3/s]",
                                                     tmpVolFlowRate)
                else:
                    if self.DesVolFlowRate > 0.0 and tmpVolFlowRate > 0.0:
                        DesVolFlowRateUser = self.DesVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         "PlantComponent:TemperatureSource",
                                                         self.Name,
                                                         "Design Size Design Fluid Flow Rate [m3/s]",
                                                         tmpVolFlowRate,
                                                         "User-Specified Design Fluid Flow Rate [m3/s]",
                                                         DesVolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpVolFlowRate - DesVolFlowRateUser) / DesVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(
                                        state,
                                        F"SizePlantComponentTemperatureSource: Potential issue with equipment sizing for {self.Name}")
                                    ShowContinueError(state,
                                                      F"User-Specified Design Fluid Flow Rate of {DesVolFlowRateUser:.5f} [m3/s]")
                                    ShowContinueError(
                                        state, F"differs from Design Size Design Fluid Flow Rate of {tmpVolFlowRate:.5f} [m3/s]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpVolFlowRate = DesVolFlowRateUser
        else:
            if self.DesVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of plant component temperature source flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, F"Occurs in PlantComponent:TemperatureSource object={self.Name}")
                ErrorsFound = True
            if not self.DesVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport:
                if self.DesVolFlowRate > 0.0:
                    BaseSizer.reportSizerOutput(
                        state, "PlantComponent:TemperatureSource", self.Name, "User-Specified Design Fluid Flow Rate [m3/s]", self.DesVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, tmpVolFlowRate)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def calculate(inout self, state: EnergyPlusData):
        alias RoutineName = "CalcWaterSource"
        if self.MassFlowRate > 0.0:
            self.OutletTemp = self.BoundaryTemp
            var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.BoundaryTemp, RoutineName)
            self.HeatRate = self.MassFlowRate * Cp * (self.OutletTemp - self.InletTemp)
            self.HeatEnergy = self.HeatRate * state.dataHVACGlobal.TimeStepSysSec
        else:
            self.OutletTemp = self.BoundaryTemp
            self.HeatRate = 0.0
            self.HeatEnergy = 0.0

    def update(inout self, state: EnergyPlusData):
        state.dataLoopNodes.Node[self.OutletNodeNum - 1].Temp = self.OutletTemp

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        self.initialize(state, CurLoad)
        self.calculate(state)
        self.update(state)

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        MaxLoad = 1.0e37  // Constant::BigNumber
        MinLoad = 0.0
        OptLoad = 1.0e37  // Constant::BigNumber

    def getSizingFactor(inout self, _SizFac: Float64):
        _SizFac = self.SizFac

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        var myLoad: Float64 = 0.0
        self.initialize(state, myLoad)
        self.autosize(state)

    def oneTimeInit(inout self, state: EnergyPlusData):
        alias RoutineName = "InitWaterSource"
        if self.MyFlag:
            self.setupOutputVars(state)
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, PlantEquipmentType.WaterSource, self.plantLoc, errFlag, _, _, _, self.InletNodeNum, _)
            if errFlag:
                ShowFatalError(state, F"{RoutineName}: Program terminated due to previous condition(s).")
            self.MyFlag = False

// ======== Free function ========
def GetWaterSourceInput(state: EnergyPlusData):
    alias routineName = "GetWaterSourceInput"
    var NumAlphas: Int32
    var NumNums: Int32
    var IOStat: Int32
    var ErrorsFound: Bool = False
    var cCurrentModuleObject = "PlantComponent:TemperatureSource"
    state.dataPlantCompTempSrc.NumSources = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if state.dataPlantCompTempSrc.NumSources <= 0:
        ShowSevereError(state, F"No {cCurrentModuleObject} equipment specified in input file")
        ErrorsFound = True
    // if already allocated, return (skip reallocation)
    if len(state.dataPlantCompTempSrc.WaterSource) > 0:
        return
    // allocate list with appropriate size using default-constructed elements
    state.dataPlantCompTempSrc.WaterSource = List[WaterSourceSpecs]()
    state.dataPlantCompTempSrc.WaterSource.reserve(state.dataPlantCompTempSrc.NumSources)
    for _ in range(state.dataPlantCompTempSrc.NumSources):
        state.dataPlantCompTempSrc.WaterSource.append(WaterSourceSpecs())
    for SourceNum in range(1, state.dataPlantCompTempSrc.NumSources + 1):
        var idx = SourceNum - 1
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 SourceNum,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNums,
                                                                 IOStat,
                                                                 _,
                                                                 state.dataIPShortCut.lAlphaFieldBlanks,
                                                                 state.dataIPShortCut.cAlphaFieldNames,
                                                                 state.dataIPShortCut.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
        state.dataPlantCompTempSrc.WaterSource[idx].Name = state.dataIPShortCut.cAlphaArgs[0]
        state.dataPlantCompTempSrc.WaterSource[idx].InletNodeNum =
            Node.GetOnlySingleNode(state,
                                    state.dataIPShortCut.cAlphaArgs[1],
                                    ErrorsFound,
                                    "PlantComponentTemperatureSource",  // Node::ConnectionObjectType
                                    state.dataIPShortCut.cAlphaArgs[0],
                                    Node.FluidType.Water,
                                    Node.ConnectionType.Inlet,
                                    Node.CompFluidStream.Primary,
                                    Node.ObjectIsNotParent)
        state.dataPlantCompTempSrc.WaterSource[idx].OutletNodeNum =
            Node.GetOnlySingleNode(state,
                                    state.dataIPShortCut.cAlphaArgs[2],
                                    ErrorsFound,
                                    "PlantComponentTemperatureSource",  // Node::ConnectionObjectType
                                    state.dataIPShortCut.cAlphaArgs[0],
                                    Node.FluidType.Water,
                                    Node.ConnectionType.Outlet,
                                    Node.CompFluidStream.Primary,
                                    Node.ObjectIsNotParent)
        Node.TestCompSet(state,
                          cCurrentModuleObject,
                          state.dataIPShortCut.cAlphaArgs[0],
                          state.dataIPShortCut.cAlphaArgs[1],
                          state.dataIPShortCut.cAlphaArgs[2],
                          "Chilled Water Nodes")
        state.dataPlantCompTempSrc.WaterSource[idx].DesVolFlowRate = state.dataIPShortCut.rNumericArgs[0]
        if state.dataPlantCompTempSrc.WaterSource[idx].DesVolFlowRate == AutoSize:
            state.dataPlantCompTempSrc.WaterSource[idx].DesVolFlowRateWasAutoSized = True
        if state.dataIPShortCut.cAlphaArgs[3] == "CONSTANT":
            state.dataPlantCompTempSrc.WaterSource[idx].tempSpecType = TempSpecType.Constant
            state.dataPlantCompTempSrc.WaterSource[idx].BoundaryTemp = state.dataIPShortCut.rNumericArgs[1]
        elif state.dataIPShortCut.cAlphaArgs[3] == "SCHEDULED":
            state.dataPlantCompTempSrc.WaterSource[idx].tempSpecType = TempSpecType.Schedule
            var schedResult = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[4])
            if schedResult is None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[4], state.dataIPShortCut.cAlphaArgs[4])
                ErrorsFound = True
            else:
                state.dataPlantCompTempSrc.WaterSource[idx].tempSpecSched = schedResult
        else:
            ShowSevereError(state, F"Input error for {cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state,
                              F"Invalid temperature specification type.  Expected either \"Constant\" or \"Scheduled\". Encountered {state.dataIPShortCut.cAlphaArgs[3]}")
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, F"Errors found in processing input for {cCurrentModuleObject}")

// ======== PlantCompTempSrcData struct (from header) ========
struct PlantCompTempSrcData(BaseGlobalStruct):
    var NumSources: Int32 = 0
    var getWaterSourceInput: Bool = True
    var WaterSource: List[WaterSourceSpecs] = List[WaterSourceSpecs]()
    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumSources = 0
        self.getWaterSourceInput = True
        self.WaterSource = List[WaterSourceSpecs]()