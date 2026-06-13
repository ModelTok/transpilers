// Mojo translation of ChillerAbsorption.cc – faithful 1:1, no refactoring.
// Imports: assume all used modules are available at relative path as in EnergyPlus.
from DataPlant import (PlantLocation, PlantComponent, FlowMode, FlowModeNamesUC, 
                         LoopDemandCalcScheme, OpScheme, PlantEquipmentType, CompData, 
                         LoopFlowStatus, DeltaTempTol)
from DataBranchAirLoopPlant import ControlType, MassFlowTolerance
from DataGlobals import KickOffSimulation, WarmupFlag, DoingSizing, BeginEnvrnFlag, 
                         DisplayExtraWarnings, AnyEnergyManagementSystemInModel
from DataHVACGlobals import TimeStepSysSec, SmallWaterVolFlow
from DataSizing import AutoSize, TypeOfPlantLoop, PlantSizData, NumPltSizInput
from DataLoopNode import Node, SensedNodeFlagValue, ConnectionObjectType, ConnectionType, 
                          CompFluidStream, ObjectIsNotParent, FluidType, FluidTypeNames
from DataIPShortCuts import cAlphaArgs, rNumericArgs, lAlphaFieldBlanks, cAlphaFieldNames, 
                             cNumericFieldNames, cCurrentModuleObject
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import GetOnlySingleNode, TestCompSet
from OutputProcessor import SetupOutputVariable, StoreType, TimeStepType,
                             eResource, Group, EndUseCat
from OutputReportPredefined import PreDefTableEntry
from PlantUtilities import (ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate,
                              UpdateChillerComponentCondenserSide, UpdateAbsorberChillerComponentGeneratorSide,
                              InterConnectTwoPlantLoopSides, MyPlantSizingIndex, RegisterPlantCompDesignFlow,
                              SafeCopyPlantNode)
from FluidProperties import RefrigProps, GlycolProps, GetSteam
from GlobalNames import VerifyUniqueChillerName
from BranchNodeConnections import TestCompSet as TestCompSetAlias
from .Autosizing.Base import BaseSizer, reportSizerOutput
from EMSManager import CheckIfNodeSetPointManagedByEMS
from FaultsManager import FaultsChillerSWTSensor
from UtilityRoutines import SameString
from String import format
from Math import abs, min, max, sqrt as sqrt, pow as pow

const calcChillerAbsorption: String = "CALC Chiller:Absorption "
const moduleObjectType: String = "Chiller:Absorption"

struct ReportVars:
    var PumpingPower: Float64 = 0.0
    var QGenerator: Float64 = 0.0
    var QEvap: Float64 = 0.0
    var QCond: Float64 = 0.0
    var PumpingEnergy: Float64 = 0.0
    var GeneratorEnergy: Float64 = 0.0
    var EvapEnergy: Float64 = 0.0
    var CondEnergy: Float64 = 0.0
    var CondInletTemp: Float64 = 0.0
    var EvapInletTemp: Float64 = 0.0
    var CondOutletTemp: Float64 = 0.0
    var EvapOutletTemp: Float64 = 0.0
    var Evapmdot: Float64 = 0.0
    var Condmdot: Float64 = 0.0
    var Genmdot: Float64 = 0.0
    var SteamMdot: Float64 = 0.0
    var ActualCOP: Float64 = 0.0

struct BLASTAbsorberSpecs:
    var Name: String = ""
    var Available: Bool = False
    var ON: Bool = False
    var NomCap: Float64 = 0.0
    var NomCapWasAutoSized: Bool = False
    var NomPumpPower: Float64 = 0.0
    var NomPumpPowerWasAutoSized: Bool = False
    var FlowMode: FlowMode = FlowMode.Invalid
    var ModulatedFlowSetToLoop: Bool = False
    var ModulatedFlowErrDone: Bool = False
    var EvapVolFlowRate: Float64 = 0.0
    var EvapVolFlowRateWasAutoSized: Bool = False
    var CondVolFlowRate: Float64 = 0.0
    var CondVolFlowRateWasAutoSized: Bool = False
    var EvapMassFlowRateMax: Float64 = 0.0
    var CondMassFlowRateMax: Float64 = 0.0
    var GenMassFlowRateMax: Float64 = 0.0
    var SizFac: Float64 = 0.0
    var EvapInletNodeNum: Int = 0
    var EvapOutletNodeNum: Int = 0
    var CondInletNodeNum: Int = 0
    var CondOutletNodeNum: Int = 0
    var GeneratorInletNodeNum: Int = 0
    var GeneratorOutletNodeNum: Int = 0
    var MinPartLoadRat: Float64 = 0.0
    var MaxPartLoadRat: Float64 = 0.0
    var OptPartLoadRat: Float64 = 0.0
    var TempDesCondIn: Float64 = 0.0
    var SteamLoadCoef: List[Float64] = [0.0, 0.0, 0.0]
    var PumpPowerCoef: List[Float64] = [0.0, 0.0, 0.0]
    var TempLowLimitEvapOut: Float64 = 0.0
    var ErrCount2: Int = 0
    var GenHeatSourceType: FluidType = FluidType.Blank
    var GeneratorVolFlowRate: Float64 = 0.0
    var GeneratorVolFlowRateWasAutoSized: Bool = False
    var GeneratorSubcool: Float64 = 0.0
    var steam: RefrigProps? = None
    var GeneratorDeltaTemp: Float64 = -99999.0
    var GeneratorDeltaTempWasAutoSized: Bool = True
    var CWPlantLoc: PlantLocation = PlantLocation()
    var CDPlantLoc: PlantLocation = PlantLocation()
    var GenPlantLoc: PlantLocation = PlantLocation()
    var FaultyChillerSWTFlag: Bool = False
    var FaultyChillerSWTIndex: Int = 0
    var FaultyChillerSWTOffset: Float64 = 0.0
    var PossibleSubcooling: Bool = False
    var CondMassFlowRate: Float64 = 0.0
    var EvapMassFlowRate: Float64 = 0.0
    var SteamMassFlowRate: Float64 = 0.0
    var CondOutletTemp: Float64 = 0.0
    var EvapOutletTemp: Float64 = 0.0
    var GenOutletTemp: Float64 = 0.0
    var SteamOutletEnthalpy: Float64 = 0.0
    var PumpingPower: Float64 = 0.0
    var PumpingEnergy: Float64 = 0.0
    var QGenerator: Float64 = 0.0
    var GeneratorEnergy: Float64 = 0.0
    var QEvaporator: Float64 = 0.0
    var EvaporatorEnergy: Float64 = 0.0
    var QCondenser: Float64 = 0.0
    var CondenserEnergy: Float64 = 0.0
    var MyOneTimeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var GenInputOutputNodesUsed: Bool = False
    var Report: ReportVars = ReportVars()
    var EquipFlowCtrl: ControlType = ControlType.Invalid
    var water: GlycolProps? = None

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> BLASTAbsorberSpecs?:
        if state.dataChillerAbsorber.getInput:
            GetBLASTAbsorberInput(state)
            state.dataChillerAbsorber.getInput = False
        var thisAbs: Int = -1
        for i in range(len(state.dataChillerAbsorber.absorptionChillers)):
            if state.dataChillerAbsorber.absorptionChillers[i].Name == objectName:
                thisAbs = i
                break
        if thisAbs != -1:
            return state.dataChillerAbsorber.absorptionChillers[thisAbs]
        ShowFatalError(state, format("LocalBlastAbsorberFactory: Error getting inputs for object named: {}", objectName))
        return None

    def simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        self.EquipFlowCtrl = calledFromLocation.comp.FlowCtrl
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.initialize(state, RunFlag, CurLoad)
            self.calculate(state, CurLoad, RunFlag)
            self.updateRecords(state, CurLoad, RunFlag)
        elif calledFromLocation.loopNum == self.CDPlantLoc.loopNum:
            PlantUtilities.UpdateChillerComponentCondenserSide(state,
                                                                calledFromLocation.loopNum,
                                                                calledFromLocation.loopSideNum,
                                                                PlantEquipmentType.Chiller_Absorption,
                                                                self.CondInletNodeNum,
                                                                self.CondOutletNodeNum,
                                                                self.Report.QCond,
                                                                self.Report.CondInletTemp,
                                                                self.Report.CondOutletTemp,
                                                                self.Report.Condmdot,
                                                                FirstHVACIteration)
        elif calledFromLocation.loopNum == self.GenPlantLoc.loopNum:
            PlantUtilities.UpdateAbsorberChillerComponentGeneratorSide(state,
                                                                        calledFromLocation.loopNum,
                                                                        calledFromLocation.loopSideNum,
                                                                        PlantEquipmentType.Chiller_Absorption,
                                                                        self.GeneratorInletNodeNum,
                                                                        self.GeneratorOutletNodeNum,
                                                                        self.GenHeatSourceType,
                                                                        self.Report.QGenerator,
                                                                        self.Report.SteamMdot,
                                                                        FirstHVACIteration)
        else:
            ShowFatalError(state,
                           format("SimBLASTAbsorber: Invalid LoopNum passed={}, Unit name={}, stored chilled water loop={}, stored condenser water "
                                   "loop={}, stored generator loop={}",
                                   calledFromLocation.loopNum,
                                   self.Name,
                                   self.CWPlantLoc.loopNum,
                                   self.CDPlantLoc.loopNum,
                                   self.GenPlantLoc.loopNum))

    def onInitLoopEquip(self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        var runFlag = True
        var myLoad = 0.0
        self.initialize(state, runFlag, myLoad)
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.sizeChiller(state)

    def getDesignCapacities(self, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.sizeChiller(state)
            MinLoad = self.NomCap * self.MinPartLoadRat
            MaxLoad = self.NomCap * self.MaxPartLoadRat
            OptLoad = self.NomCap * self.OptPartLoadRat
        else:
            MinLoad = 0.0
            MaxLoad = 0.0
            OptLoad = 0.0

    def getSizingFactor(self, sizFac: Float64):
        sizFac = self.SizFac

    def getDesignTemperatures(self, tempDesCondIn: Float64, TempDesEvapOut: Float64):
        tempDesCondIn = self.TempDesCondIn

    def setupOutputVars(self, state: EnergyPlusData):
        SetupOutputVariable(state,
                            "Chiller Electricity Rate",
                            Units.W,
                            self.Report.PumpingPower,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Electricity Energy",
                            Units.J,
                            self.Report.PumpingEnergy,
                            TimeStepType.System,
                            StoreType.Sum,
                            self.Name,
                            eResource.Electricity,
                            Group.Plant,
                            EndUseCat.Cooling)
        SetupOutputVariable(state,
                            "Chiller Evaporator Cooling Rate",
                            Units.W,
                            self.Report.QEvap,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Evaporator Cooling Energy",
                            Units.J,
                            self.Report.EvapEnergy,
                            TimeStepType.System,
                            StoreType.Sum,
                            self.Name,
                            eResource.EnergyTransfer,
                            Group.Plant,
                            EndUseCat.Chillers)
        SetupOutputVariable(state,
                            "Chiller Evaporator Inlet Temperature",
                            Units.C,
                            self.Report.EvapInletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Evaporator Outlet Temperature",
                            Units.C,
                            self.Report.EvapOutletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Evaporator Mass Flow Rate",
                            Units.kg_s,
                            self.Report.Evapmdot,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Condenser Heat Transfer Rate",
                            Units.W,
                            self.Report.QCond,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Condenser Heat Transfer Energy",
                            Units.J,
                            self.Report.CondEnergy,
                            TimeStepType.System,
                            StoreType.Sum,
                            self.Name,
                            eResource.EnergyTransfer,
                            Group.Plant,
                            EndUseCat.HeatRejection)
        SetupOutputVariable(state,
                            "Chiller Condenser Inlet Temperature",
                            Units.C,
                            self.Report.CondInletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Condenser Outlet Temperature",
                            Units.C,
                            self.Report.CondOutletTemp,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Chiller Condenser Mass Flow Rate",
                            Units.kg_s,
                            self.Report.Condmdot,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        if self.GenHeatSourceType == FluidType.Water:
            SetupOutputVariable(state,
                                "Chiller Hot Water Consumption Rate",
                                Units.W,
                                self.Report.QGenerator,
                                TimeStepType.System,
                                StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Chiller Source Hot Water Energy",
                                Units.J,
                                self.Report.GeneratorEnergy,
                                TimeStepType.System,
                                StoreType.Sum,
                                self.Name,
                                eResource.PlantLoopHeatingDemand,
                                Group.Plant,
                                EndUseCat.Chillers)
        else:
            if self.GenInputOutputNodesUsed:
                SetupOutputVariable(state,
                                    "Chiller Source Steam Rate",
                                    Units.W,
                                    self.Report.QGenerator,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    self.Name)
                SetupOutputVariable(state,
                                    "Chiller Source Steam Energy",
                                    Units.J,
                                    self.Report.GeneratorEnergy,
                                    TimeStepType.System,
                                    StoreType.Sum,
                                    self.Name,
                                    eResource.PlantLoopHeatingDemand,
                                    Group.Plant,
                                    EndUseCat.Chillers)
            else:
                SetupOutputVariable(state,
                                    "Chiller Source Steam Rate",
                                    Units.W,
                                    self.Report.QGenerator,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    self.Name)
                SetupOutputVariable(state,
                                    "Chiller Source Steam Energy",
                                    Units.J,
                                    self.Report.GeneratorEnergy,
                                    TimeStepType.System,
                                    StoreType.Sum,
                                    self.Name,
                                    eResource.DistrictHeatingSteam,
                                    Group.Plant,
                                    EndUseCat.Cooling)
        SetupOutputVariable(state,
                            "Chiller COP",
                            Units.W_W,
                            self.Report.ActualCOP,
                            TimeStepType.System,
                            StoreType.Average,
                            self.Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSInternalVariable(state, "Chiller Nominal Capacity", self.Name, "[W]", self.NomCap)

    def oneTimeInit(self, state: EnergyPlusData):
        self.setupOutputVars(state)
        var errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(state,
                                                self.Name,
                                                PlantEquipmentType.Chiller_Absorption,
                                                self.CWPlantLoc,
                                                errFlag,
                                                self.TempLowLimitEvapOut,
                                                _,
                                                _,
                                                self.EvapInletNodeNum,
                                                _)
        if self.CondInletNodeNum > 0:
            PlantUtilities.ScanPlantLoopsForObject(state,
                                                    self.Name,
                                                    PlantEquipmentType.Chiller_Absorption,
                                                    self.CDPlantLoc,
                                                    errFlag, _, _, _, self.CondInletNodeNum, _)
            PlantUtilities.InterConnectTwoPlantLoopSides(state,
                                                          self.CWPlantLoc,
                                                          self.CDPlantLoc,
                                                          PlantEquipmentType.Chiller_Absorption, True)
        if self.GeneratorInletNodeNum > 0:
            PlantUtilities.ScanPlantLoopsForObject(state,
                                                    self.Name,
                                                    PlantEquipmentType.Chiller_Absorption,
                                                    self.GenPlantLoc,
                                                    errFlag, _, _, _, self.GeneratorInletNodeNum, _)
            PlantUtilities.InterConnectTwoPlantLoopSides(state,
                                                          self.CWPlantLoc,
                                                          self.GenPlantLoc,
                                                          PlantEquipmentType.Chiller_Absorption, True)
        if (self.CondInletNodeNum > 0) and (self.GeneratorInletNodeNum > 0):
            PlantUtilities.InterConnectTwoPlantLoopSides(state,
                                                          self.CDPlantLoc,
                                                          self.GenPlantLoc,
                                                          PlantEquipmentType.Chiller_Absorption, False)
        if errFlag:
            ShowFatalError(state, "InitBLASTAbsorberModel: Program terminated due to previous condition(s).")
        if self.FlowMode == FlowMode.Constant:
            CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = LoopFlowStatus.NeedyIfLoopOn
        if self.FlowMode == FlowMode.LeavingSetpointModulated:
            CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = LoopFlowStatus.NeedyIfLoopOn
            if (Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint == SensedNodeFlagValue) and \
               (Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi == SensedNodeFlagValue):
                if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                    if not self.ModulatedFlowErrDone:
                        ShowWarningError(state,
                                         format("Missing temperature setpoint for LeavingSetpointModulated mode chiller named {}", self.Name))
                        ShowContinueError(state,
                                          "  A temperature setpoint is needed at the outlet node of a chiller in variable flow mode, use a SetpointManager")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                        self.ModulatedFlowErrDone = True
                else:
                    var FatalError = False
                    EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.EvapOutletNodeNum, HVAC.CtrlVarType.Temp, FatalError)
                    Node(state.dataLoopNodes, self.EvapOutletNodeNum).needsSetpointChecking = False
                    if FatalError:
                        if not self.ModulatedFlowErrDone:
                            ShowWarningError(state,
                                             format("Missing temperature setpoint for LeavingSetpointModulated mode chiller named {}", self.Name))
                            ShowContinueError(state,
                                              "  A temperature setpoint is needed at the outlet node of a chiller evaporator in variable flow mode")
                            ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the chiller evaporator outlet node ")
                            ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the outlet node ")
                            ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                            self.ModulatedFlowErrDone = True
                self.ModulatedFlowSetToLoop = True
                Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint = \
                    Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
                Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi = \
                    Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi

    def initEachEnvironment(self, state: EnergyPlusData):
        const RoutineName = "BLASTAbsorberSpecs::initEachEnvironment"
        var rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
        self.EvapMassFlowRateMax = self.EvapVolFlowRate * rho
        PlantUtilities.InitComponentNodes(state, 0.0, self.EvapMassFlowRateMax, self.EvapInletNodeNum, self.EvapOutletNodeNum)
        rho = self.CDPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
        self.CondMassFlowRateMax = rho * self.CondVolFlowRate
        PlantUtilities.InitComponentNodes(state, 0.0, self.CondMassFlowRateMax, self.CondInletNodeNum, self.CondOutletNodeNum)
        Node(state.dataLoopNodes, self.CondInletNodeNum).Temp = self.TempDesCondIn
        if self.GeneratorInletNodeNum > 0:
            if self.GenHeatSourceType == FluidType.Water:
                rho = self.GenPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                self.GenMassFlowRateMax = rho * self.GeneratorVolFlowRate
            elif self.GenHeatSourceType == FluidType.Steam:
                self.QGenerator = (self.SteamLoadCoef[0] + self.SteamLoadCoef[1] + self.SteamLoadCoef[2]) * self.NomCap
                var EnthSteamOutDry = self.steam.getSatEnthalpy(state, Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp, 1.0, calcChillerAbsorption + self.Name)
                var EnthSteamOutWet = self.steam.getSatEnthalpy(state, Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp, 0.0, calcChillerAbsorption + self.Name)
                var SteamDeltaT = self.GeneratorSubcool
                var SteamOutletTemp = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp - SteamDeltaT
                var HfgSteam = EnthSteamOutDry - EnthSteamOutWet
                var CpWater = self.water.getDensity(state, SteamOutletTemp, calcChillerAbsorption + self.Name)
                self.GenMassFlowRateMax = self.QGenerator / (HfgSteam + CpWater * SteamDeltaT)
            PlantUtilities.InitComponentNodes(state, 0.0, self.GenMassFlowRateMax, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum)

    def initialize(self, state: EnergyPlusData, RunFlag: Bool, MyLoad: Float64):
        if self.MyOneTimeFlag:
            self.oneTimeInit(state)
            self.MyOneTimeFlag = False
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        if (self.FlowMode == FlowMode.LeavingSetpointModulated) and self.ModulatedFlowSetToLoop:
            Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint = \
                Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
            Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi = \
                Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi
        var mdotEvap = 0.0
        var mdotCond = 0.0
        var mdotGen = 0.0
        if (MyLoad < 0.0) and RunFlag:
            mdotEvap = self.EvapMassFlowRateMax
            mdotCond = self.CondMassFlowRateMax
            mdotGen = self.GenMassFlowRateMax
        PlantUtilities.SetComponentFlowRate(state, mdotEvap, self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
        PlantUtilities.SetComponentFlowRate(state, mdotCond, self.CondInletNodeNum, self.CondOutletNodeNum, self.CDPlantLoc)
        if self.GeneratorInletNodeNum > 0:
            PlantUtilities.SetComponentFlowRate(state, mdotGen, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, self.GenPlantLoc)

    def sizeChiller(self, state: EnergyPlusData):
        const RoutineName = "SizeAbsorpChiller"
        var PltSizSteamNum: Int = 0
        var PltSizHeatingNum: Int = 0
        var ErrorsFound = False
        var LoopErrorsFound = False
        var SteamInputRatNom = self.SteamLoadCoef[0] + self.SteamLoadCoef[1] + self.SteamLoadCoef[2]
        var tmpNomCap = self.NomCap
        var tmpEvapVolFlowRate = self.EvapVolFlowRate
        var tmpCondVolFlowRate = self.CondVolFlowRate
        var tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate
        var PltSizNum = self.CWPlantLoc.loop.PlantSizNum
        var PltSizCondNum = self.CDPlantLoc.loop.PlantSizNum
        if self.GenHeatSourceType == FluidType.Steam:
            if self.GeneratorInletNodeNum > 0 and self.GeneratorOutletNodeNum > 0:
                PltSizSteamNum = PlantUtilities.MyPlantSizingIndex(state, moduleObjectType, self.Name, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, LoopErrorsFound)
            else:
                for PltSizIndex in range(1, state.dataSize.NumPltSizInput + 1):
                    if state.dataSize.PlantSizData[PltSizIndex - 1].LoopType == TypeOfPlantLoop.Steam:
                        PltSizSteamNum = PltSizIndex
        else:
            if self.GeneratorInletNodeNum > 0 and self.GeneratorOutletNodeNum > 0:
                PltSizHeatingNum = PlantUtilities.MyPlantSizingIndex(state, moduleObjectType, self.Name, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, LoopErrorsFound)
            else:
                for PltSizIndex in range(1, state.dataSize.NumPltSizInput + 1):
                    if state.dataSize.PlantSizData[PltSizIndex - 1].LoopType == TypeOfPlantLoop.Heating:
                        PltSizHeatingNum = PltSizIndex
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                var Cp = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
                var rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                tmpNomCap = Cp * rho * state.dataSize.PlantSizData[PltSizNum - 1].DeltaT * state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate * self.SizFac
                if not self.NomCapWasAutoSized:
                    tmpNomCap = self.NomCap
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Nominal Capacity [W]", tmpNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        var NomCapUser = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         moduleObjectType,
                                                         self.Name,
                                                         "Design Size Nominal Capacity [W]",
                                                         tmpNomCap,
                                                         "User-Specified Nominal Capacity [W]",
                                                         NomCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpNomCap - NomCapUser) / NomCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Nominal Capacity of {:.2f} [W]", NomCapUser))
                                    ShowContinueError(state, format("differs from Design Size Nominal Capacity of {:.2f} [W]", tmpNomCap))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpNomCap = NomCapUser
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Absorption Chiller nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, format("Occurs in Chiller:Absorption object={}", self.Name))
                ErrorsFound = True
            if not self.NomCapWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and self.NomCap > 0.0:
                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        var tmpNomPumpPower = 0.0045 * self.NomCap
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if self.NomPumpPowerWasAutoSized:
                self.NomPumpPower = tmpNomPumpPower
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Nominal Pumping Power [W]", tmpNomPumpPower)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Nominal Pumping Power [W]", tmpNomPumpPower)
            else:
                if self.NomPumpPower > 0.0 and tmpNomPumpPower > 0.0:
                    var NomPumpPowerUser = self.NomPumpPower
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     moduleObjectType,
                                                     self.Name,
                                                     "Design Size Nominal Pumping Power [W]",
                                                     tmpNomPumpPower,
                                                     "User-Specified Nominal Pumping Power [W]",
                                                     NomPumpPowerUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(tmpNomPumpPower - NomPumpPowerUser) / NomPumpPowerUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                ShowContinueError(state, format("User-Specified Nominal Pumping Power of {:.2f} [W]", NomPumpPowerUser))
                                ShowContinueError(state, format("differs from Design Size Nominal Pumping Power of {:.2f} [W]", tmpNomPumpPower))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    tmpNomPumpPower = NomPumpPowerUser
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                tmpEvapVolFlowRate = state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate * self.SizFac
                if not self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = self.EvapVolFlowRate
            else:
                if self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.EvapVolFlowRateWasAutoSized:
                    self.EvapVolFlowRate = tmpEvapVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Design Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Design Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate)
                else:
                    if self.EvapVolFlowRate > 0.0 and tmpEvapVolFlowRate > 0.0:
                        var EvapVolFlowRateUser = self.EvapVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         moduleObjectType,
                                                         self.Name,
                                                         "Design Size Design Chilled Water Flow Rate [m3/s]",
                                                         tmpEvapVolFlowRate,
                                                         "User-Specified Design Chilled Water Flow Rate [m3/s]",
                                                         EvapVolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpEvapVolFlowRate - EvapVolFlowRateUser) / EvapVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Design Chilled Water Flow Rate of {:#G} [m3/s]", EvapVolFlowRateUser))
                                    ShowContinueError(state, format("differs from Design Size Design Chilled Water Flow Rate of {:#G} [m3/s]", tmpEvapVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpEvapVolFlowRate = EvapVolFlowRateUser
        else:
            if self.EvapVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Absorption Chiller evap flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, format("Occurs in CHILLER:ABSORPTION object={}", self.Name))
                ErrorsFound = True
            if not self.EvapVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and self.EvapVolFlowRate > 0.0:
                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "User-Specified Design Chilled Water Flow Rate [m3/s]", self.EvapVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.EvapInletNodeNum, tmpEvapVolFlowRate)
        if PltSizCondNum > 0 and PltSizNum > 0:
            if self.EvapVolFlowRate >= SmallWaterVolFlow and tmpNomCap > 0.0:
                var Cp = self.CDPlantLoc.loop.glycol.getSpecificHeat(state, self.TempDesCondIn, RoutineName)
                var rho = self.CDPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                tmpCondVolFlowRate = tmpNomCap * (1.0 + SteamInputRatNom + tmpNomPumpPower / tmpNomCap) / (state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT * Cp * rho)
                if not self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = self.CondVolFlowRate
            else:
                if self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.CondVolFlowRateWasAutoSized:
                    self.CondVolFlowRate = tmpCondVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Design Condenser Water Flow Rate [m3/s]", tmpCondVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Design Condenser Water Flow Rate [m3/s]", tmpCondVolFlowRate)
                else:
                    if self.CondVolFlowRate > 0.0 and tmpCondVolFlowRate > 0.0:
                        var CondVolFlowRateUser = self.CondVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         moduleObjectType,
                                                         self.Name,
                                                         "Design Size Design Condenser Water Flow Rate [m3/s]",
                                                         tmpCondVolFlowRate,
                                                         "User-Specified Design Condenser Water Flow Rate [m3/s]",
                                                         CondVolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpCondVolFlowRate - CondVolFlowRateUser) / CondVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Design Condenser Water Flow Rate of {:#G} [m3/s]", CondVolFlowRateUser))
                                    ShowContinueError(state, format("differs from Design Size Design Condenser Water Flow Rate of {:#G} [m3/s]", tmpCondVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpCondVolFlowRate = CondVolFlowRateUser
        else:
            if self.CondVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Absorption Chiller condenser flow rate requires a condenser")
                ShowContinueError(state, "loop Sizing:Plant object")
                ShowContinueError(state, format("Occurs in CHILLER:ABSORPTION object={}", self.Name))
                ErrorsFound = True
            if not self.CondVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize and (self.CondVolFlowRate > 0.0):
                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "User-Specified Design Condenser Water Flow Rate [m3/s]", self.CondVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.CondInletNodeNum, tmpCondVolFlowRate)
        if (PltSizSteamNum > 0 and self.GenHeatSourceType == FluidType.Steam) or \
           (PltSizHeatingNum > 0 and self.GenHeatSourceType == FluidType.Water):
            if self.EvapVolFlowRate >= SmallWaterVolFlow and tmpNomCap > 0.0:
                if self.GenHeatSourceType == FluidType.Water:
                    var CpWater = self.GenPlantLoc.loop.glycol.getSpecificHeat(state, state.dataSize.PlantSizData[PltSizHeatingNum - 1].ExitTemp, RoutineName)
                    var SteamDeltaT = max(0.5, state.dataSize.PlantSizData[PltSizHeatingNum - 1].DeltaT)
                    var RhoWater = self.GenPlantLoc.loop.glycol.getDensity(state, (state.dataSize.PlantSizData[PltSizHeatingNum - 1].ExitTemp - SteamDeltaT), RoutineName)
                    tmpGeneratorVolFlowRate = (self.NomCap * SteamInputRatNom) / (CpWater * SteamDeltaT * RhoWater)
                    if not self.GeneratorVolFlowRateWasAutoSized:
                        tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if self.GeneratorVolFlowRateWasAutoSized:
                            self.GeneratorVolFlowRate = tmpGeneratorVolFlowRate
                            if state.dataPlnt.PlantFinalSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Design Generator Fluid Flow Rate [m3/s]", tmpGeneratorVolFlowRate)
                            if state.dataPlnt.PlantFirstSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Design Generator Fluid Flow Rate [m3/s]", tmpGeneratorVolFlowRate)
                        else:
                            if self.GeneratorVolFlowRate > 0.0 and tmpGeneratorVolFlowRate > 0.0:
                                var GeneratorVolFlowRateUser = self.GeneratorVolFlowRate
                                if state.dataPlnt.PlantFinalSizesOkayToReport:
                                    BaseSizer.reportSizerOutput(state,
                                                                 moduleObjectType,
                                                                 self.Name,
                                                                 "Design Size Design Generator Fluid Flow Rate [m3/s]",
                                                                 tmpGeneratorVolFlowRate,
                                                                 "User-Specified Design Generator Fluid Flow Rate [m3/s]",
                                                                 GeneratorVolFlowRateUser)
                                    if state.dataGlobal.DisplayExtraWarnings:
                                        if (abs(tmpGeneratorVolFlowRate - GeneratorVolFlowRateUser) / GeneratorVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                            ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                            ShowContinueError(state, format("User-Specified Design Generator Fluid Flow Rate of {:#G} [m3/s]", GeneratorVolFlowRateUser))
                                            ShowContinueError(state, format("differs from Design Size Design Generator Fluid Flow Rate of {:#G} [m3/s]", tmpGeneratorVolFlowRate))
                                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                                tmpGeneratorVolFlowRate = GeneratorVolFlowRateUser
                else:
                    const RoutineNameLong = "SizeAbsorptionChiller"
                    var SteamDensity = self.steam.getSatDensity(state, state.dataSize.PlantSizData[PltSizSteamNum - 1].ExitTemp, 1.0, RoutineNameLong)
                    var SteamDeltaT = state.dataSize.PlantSizData[PltSizSteamNum - 1].DeltaT
                    var GeneratorOutletTemp = state.dataSize.PlantSizData[PltSizSteamNum - 1].ExitTemp - SteamDeltaT
                    var EnthSteamOutDry = self.steam.getSatEnthalpy(state, state.dataSize.PlantSizData[PltSizSteamNum - 1].ExitTemp, 1.0, moduleObjectType + self.Name)
                    var EnthSteamOutWet = self.steam.getSatEnthalpy(state, state.dataSize.PlantSizData[PltSizSteamNum - 1].ExitTemp, 0.0, moduleObjectType + self.Name)
                    var CpWater = self.water.getSpecificHeat(state, GeneratorOutletTemp, RoutineName)
                    var HfgSteam = EnthSteamOutDry - EnthSteamOutWet
                    self.SteamMassFlowRate = (self.NomCap * SteamInputRatNom) / ((HfgSteam) + (SteamDeltaT * CpWater))
                    tmpGeneratorVolFlowRate = self.SteamMassFlowRate / SteamDensity
                    if not self.GeneratorVolFlowRateWasAutoSized:
                        tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if self.GeneratorVolFlowRateWasAutoSized:
                            self.GeneratorVolFlowRate = tmpGeneratorVolFlowRate
                            if state.dataPlnt.PlantFinalSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Design Size Design Generator Fluid Flow Rate [m3/s]", tmpGeneratorVolFlowRate)
                            if state.dataPlnt.PlantFirstSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "Initial Design Size Design Generator Fluid Flow Rate [m3/s]", tmpGeneratorVolFlowRate)
                        else:
                            if self.GeneratorVolFlowRate > 0.0 and tmpGeneratorVolFlowRate > 0.0:
                                var GeneratorVolFlowRateUser = self.GeneratorVolFlowRate
                                if state.dataPlnt.PlantFinalSizesOkayToReport:
                                    BaseSizer.reportSizerOutput(state,
                                                                 moduleObjectType,
                                                                 self.Name,
                                                                 "Design Size Design Generator Fluid Flow Rate [m3/s]",
                                                                 tmpGeneratorVolFlowRate,
                                                                 "User-Specified Design Generator Fluid Flow Rate [m3/s]",
                                                                 GeneratorVolFlowRateUser)
                                    if state.dataGlobal.DisplayExtraWarnings:
                                        if (abs(tmpGeneratorVolFlowRate - GeneratorVolFlowRateUser) / GeneratorVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                            ShowMessage(state, format("SizeChillerAbsorption: Potential issue with equipment sizing for {}", self.Name))
                                            ShowContinueError(state, format("User-Specified Design Generator Fluid Flow Rate of {:#G} [m3/s]", GeneratorVolFlowRateUser))
                                            ShowContinueError(state, format("differs from Design Size Design Generator Fluid Flow Rate of {:#G} [m3/s]", tmpGeneratorVolFlowRate))
                                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                                tmpGeneratorVolFlowRate = GeneratorVolFlowRateUser
            else:
                if self.GeneratorVolFlowRateWasAutoSized:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.GeneratorVolFlowRate = 0.0
                    else:
                        tmpGeneratorVolFlowRate = 0.0
        else:
            if self.GeneratorVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Absorption Chiller generator flow rate requires a loop Sizing:Plant object.")
                ShowContinueError(state, " For steam loops, use a steam Sizing:Plant object.")
                ShowContinueError(state, " For hot water loops, use a heating Sizing:Plant object.")
                ShowContinueError(state, format("Occurs in Chiller:Absorption object={}", self.Name))
                ErrorsFound = True
            if not self.GeneratorVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.GeneratorVolFlowRate > 0.0):
                BaseSizer.reportSizerOutput(state, moduleObjectType, self.Name, "User-Specified Design Generator Fluid Flow Rate [m3/s]", self.GeneratorVolFlowRate)
        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.GeneratorInletNodeNum, self.GeneratorVolFlowRate)
        else:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.GeneratorInletNodeNum, tmpGeneratorVolFlowRate)
        if self.GeneratorDeltaTempWasAutoSized:
            if PltSizHeatingNum > 0 and self.GenHeatSourceType == FluidType.Water:
                self.GeneratorDeltaTemp = max(0.5, state.dataSize.PlantSizData[PltSizHeatingNum - 1].DeltaT)
            elif self.GenHeatSourceType == FluidType.Water:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    var Cp = self.GenPlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                    var rho = self.GenPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                    self.GeneratorDeltaTemp = (SteamInputRatNom * self.NomCap) / (Cp * rho * self.GeneratorVolFlowRate)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            var equipName = self.Name
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, equipName, moduleObjectType)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, equipName, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerType, self.Name, moduleObjectType)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefCap, self.Name, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEff, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedCap, self.Name, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEff, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinSI, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinIP, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerPlantloopName, self.Name,
                                                     self.CWPlantLoc.loop != None ? self.CWPlantLoc.loop.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerPlantloopBranchName, self.Name,
                                                     self.CWPlantLoc.loop != None ? self.CWPlantLoc.branch.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerCondLoopName, self.Name,
                                                     self.CDPlantLoc.loop != None ? self.CDPlantLoc.loop.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerCondLoopBranchName, self.Name,
                                                     self.CDPlantLoc.loop != None ? self.CDPlantLoc.branch.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerMinPLR, self.Name, self.MinPartLoadRat)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerFuelType, self.Name,
                                                     FluidTypeNames[Int(self.GenHeatSourceType)])
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEntCondTemp, self.Name, self.TempDesCondIn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedLevEvapTemp, self.Name, self.TempLowLimitEvapOut)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEntCondTemp, self.Name, self.TempDesCondIn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefLevEvapTemp, self.Name, self.TempLowLimitEvapOut)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCHWFlowRate, self.Name, self.EvapMassFlowRateMax)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCondFluidFlowRate, self.Name, self.CondMassFlowRateMax)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopName, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopBranchName, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRecRelCapFrac, self.Name, "N/A")

    def calculate(self, state: EnergyPlusData, MyLoad: Float64, RunFlag: Bool):
        const RoutineName = "CalcBLASTAbsorberModel"
        var EvapDeltaTemp = 0.0
        if MyLoad >= 0.0 or not RunFlag:
            if self.EquipFlowCtrl == ControlType.SeriesActive:
                self.EvapMassFlowRate = Node(state.dataLoopNodes, self.EvapInletNodeNum).MassFlowRate
            return
        self.CondMassFlowRate = Node(state.dataLoopNodes, self.CondInletNodeNum).MassFlowRate
        var TempEvapOut = Node(state.dataLoopNodes, self.EvapOutletNodeNum).Temp
        var CpFluid = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp, RoutineName)
        if self.FaultyChillerSWTFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and (not state.dataGlobal.KickOffSimulation):
            var FaultIndex = self.FaultyChillerSWTIndex
            var EvapOutletTemp_ff = TempEvapOut
            self.FaultyChillerSWTOffset = state.dataFaultsMgr.FaultsChillerSWTSensor[FaultIndex].CalFaultOffsetAct(state)
            TempEvapOut = max(self.TempLowLimitEvapOut,
                              min(Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp, EvapOutletTemp_ff - self.FaultyChillerSWTOffset))
            self.FaultyChillerSWTOffset = EvapOutletTemp_ff - TempEvapOut
        if self.CWPlantLoc.side.FlowLock == FlowLock.Unlocked:
            self.PossibleSubcooling = False
            self.QEvaporator = abs(MyLoad)
            self.QEvaporator = min(self.QEvaporator, (self.MaxPartLoadRat * self.NomCap))
            if (self.FlowMode == FlowMode.Constant) or (self.FlowMode == FlowMode.NotModulated):
                self.EvapMassFlowRate = Node(state.dataLoopNodes, self.EvapInletNodeNum).MassFlowRate
                if self.EvapMassFlowRate != 0.0:
                    EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                else:
                    EvapDeltaTemp = 0.0
                self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - EvapDeltaTemp
            elif self.FlowMode == FlowMode.LeavingSetpointModulated:
                match self.CWPlantLoc.loop.LoopDemandCalcScheme:
                    case LoopDemandCalcScheme.SingleSetPoint:
                        EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint
                    case LoopDemandCalcScheme.DualSetPointDeadBand:
                        EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi
                    case _:
                        assert(False)
                if EvapDeltaTemp != 0:
                    self.EvapMassFlowRate = abs(self.QEvaporator / CpFluid / EvapDeltaTemp)
                    if (self.EvapMassFlowRate - self.EvapMassFlowRateMax) > MassFlowTolerance:
                        self.PossibleSubcooling = True
                    self.EvapMassFlowRate = min(self.EvapMassFlowRateMax, self.EvapMassFlowRate)
                    PlantUtilities.SetComponentFlowRate(state, self.EvapMassFlowRate, self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
                    match self.CWPlantLoc.loop.LoopDemandCalcScheme:
                        case LoopDemandCalcScheme.SingleSetPoint:
                            self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint
                        case LoopDemandCalcScheme.DualSetPointDeadBand:
                            self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi
                        case _:

                else:
                    self.EvapMassFlowRate = 0.0
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp
                    ShowRecurringWarningErrorAtEnd(state,
                                                   "CalcBLASTAbsorberModel: Name=\"" + self.Name +
                                                       "\" Evaporative Condenser Delta Temperature = 0 in mass flow calculation.",
                                                   self.ErrCount2)
            if self.FaultyChillerSWTFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and \
               (not state.dataGlobal.KickOffSimulation) and (self.EvapMassFlowRate > 0):
                var FaultIndex = self.FaultyChillerSWTIndex
                var VarFlowFlag = (self.FlowMode == FlowMode.LeavingSetpointModulated)
                state.dataFaultsMgr.FaultsChillerSWTSensor[FaultIndex].CalFaultChillerSWT(VarFlowFlag,
                                                                                           self.FaultyChillerSWTOffset,
                                                                                           CpFluid,
                                                                                           Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp,
                                                                                           self.EvapOutletTemp,
                                                                                           self.EvapMassFlowRate,
                                                                                           self.QEvaporator)
        else:
            self.EvapMassFlowRate = Node(state.dataLoopNodes, self.EvapInletNodeNum).MassFlowRate
            if self.PossibleSubcooling:
                self.QEvaporator = abs(MyLoad)
                EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - EvapDeltaTemp
            else:
                var TempEvapOutSetPoint: Float64 = 0
                match self.CWPlantLoc.loop.LoopDemandCalcScheme:
                    case LoopDemandCalcScheme.SingleSetPoint:
                        if (self.FlowMode == FlowMode.LeavingSetpointModulated) or \
                           (CompData.getPlantComponent(state, self.CWPlantLoc).CurOpSchemeType == OpScheme.CompSetPtBased) or \
                           (Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint != SensedNodeFlagValue):
                            TempEvapOutSetPoint = Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPoint
                        else:
                            TempEvapOutSetPoint = Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
                    case LoopDemandCalcScheme.DualSetPointDeadBand:
                        if (self.FlowMode == FlowMode.LeavingSetpointModulated) or \
                           (CompData.getPlantComponent(state, self.CWPlantLoc).CurOpSchemeType == OpScheme.CompSetPtBased) or \
                           (Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi != SensedNodeFlagValue):
                            TempEvapOutSetPoint = Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempSetPointHi
                        else:
                            TempEvapOutSetPoint = Node(state.dataLoopNodes, self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi
                    case _:
                        assert(False)
                EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - TempEvapOutSetPoint
                self.QEvaporator = abs(self.EvapMassFlowRate * CpFluid * EvapDeltaTemp)
                self.EvapOutletTemp = TempEvapOutSetPoint
            if self.EvapOutletTemp < self.TempLowLimitEvapOut:
                if (Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - self.TempLowLimitEvapOut) > DeltaTempTol:
                    self.EvapOutletTemp = self.TempLowLimitEvapOut
                    EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
                else:
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp
                    EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
            if self.EvapOutletTemp < Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempMin:
                if (Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempMin) > DeltaTempTol:
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapOutletNodeNum).TempMin
                    EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
                else:
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp
                    EvapDeltaTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
            if self.QEvaporator > abs(MyLoad):
                if self.EvapMassFlowRate > MassFlowTolerance:
                    self.QEvaporator = abs(MyLoad)
                    EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp - EvapDeltaTemp
                else:
                    self.QEvaporator = 0.0
                    self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp
            if self.FaultyChillerSWTFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and \
               (not state.dataGlobal.KickOffSimulation) and (self.EvapMassFlowRate > 0):
                var FaultIndex = self.FaultyChillerSWTIndex
                var VarFlowFlag = False
                state.dataFaultsMgr.FaultsChillerSWTSensor[FaultIndex].CalFaultChillerSWT(VarFlowFlag,
                                                                                           self.FaultyChillerSWTOffset,
                                                                                           CpFluid,
                                                                                           Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp,
                                                                                           self.EvapOutletTemp,
                                                                                           self.EvapMassFlowRate,
                                                                                           self.QEvaporator)
        var PartLoadRat = max(self.MinPartLoadRat, min(self.QEvaporator / self.NomCap, self.MaxPartLoadRat))
        var OperPartLoadRat = self.QEvaporator / self.NomCap
        var FRAC = 1.0
        if OperPartLoadRat < PartLoadRat:
            FRAC = min(1.0, OperPartLoadRat / self.MinPartLoadRat)
        var SteamInputRat = self.SteamLoadCoef[0] / PartLoadRat + self.SteamLoadCoef[1] + self.SteamLoadCoef[2] * PartLoadRat
        var ElectricInputRat = self.PumpPowerCoef[0] + self.PumpPowerCoef[1] * PartLoadRat + self.PumpPowerCoef[2] * (PartLoadRat * PartLoadRat)
        self.PumpingPower = ElectricInputRat * self.NomPumpPower * FRAC
        self.QGenerator = SteamInputRat * self.QEvaporator * FRAC
        if self.EvapMassFlowRate == 0.0:
            self.QGenerator = 0.0
            self.EvapOutletTemp = Node(state.dataLoopNodes, self.EvapInletNodeNum).Temp
            self.PumpingPower = 0.0
        self.QCondenser = self.QEvaporator + self.QGenerator + self.PumpingPower
        CpFluid = self.CDPlantLoc.loop.glycol.getSpecificHeat(state, Node(state.dataLoopNodes, self.CondInletNodeNum).Temp, RoutineName)
        if self.CondMassFlowRate > MassFlowTolerance:
            self.CondOutletTemp = self.QCondenser / self.CondMassFlowRate / CpFluid + Node(state.dataLoopNodes, self.CondInletNodeNum).Temp
        else:
            self.CondOutletTemp = Node(state.dataLoopNodes, self.CondInletNodeNum).Temp
            self.CondMassFlowRate = 0.0
            self.QCondenser = 0.0
            MyLoad = 0.0
            self.EvapMassFlowRate = 0.0
            PlantUtilities.SetComponentFlowRate(state, self.EvapMassFlowRate, self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
            return
        if self.GeneratorInletNodeNum > 0:
            if self.GenHeatSourceType == FluidType.Water:
                var GenMassFlowRate = 0.0
                CpFluid = self.GenPlantLoc.loop.glycol.getSpecificHeat(state, Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp, RoutineName)
                if self.GenPlantLoc.side.FlowLock == FlowLock.Unlocked:
                    if (self.FlowMode == FlowMode.Constant) or (self.FlowMode == FlowMode.NotModulated):
                        GenMassFlowRate = self.GenMassFlowRateMax
                    else:
                        var GenFlowRatio = self.EvapMassFlowRate / self.EvapMassFlowRateMax
                        GenMassFlowRate = min(self.GenMassFlowRateMax, GenFlowRatio * self.GenMassFlowRateMax)
                else:
                    GenMassFlowRate = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).MassFlowRate
                PlantUtilities.SetComponentFlowRate(state, GenMassFlowRate, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, self.GenPlantLoc)
                if GenMassFlowRate <= 0.0:
                    self.GenOutletTemp = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp
                    self.SteamOutletEnthalpy = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Enthalpy
                else:
                    self.GenOutletTemp = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp - self.QGenerator / (CpFluid * GenMassFlowRate)
                    self.SteamOutletEnthalpy = Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Enthalpy - self.QGenerator / GenMassFlowRate
                Node(state.dataLoopNodes, self.GeneratorOutletNodeNum).Temp = self.GenOutletTemp
                Node(state.dataLoopNodes, self.GeneratorOutletNodeNum).Enthalpy = self.SteamOutletEnthalpy
                Node(state.dataLoopNodes, self.GeneratorOutletNodeNum).MassFlowRate = GenMassFlowRate
            else:
                var EnthSteamOutDry = self.steam.getSatEnthalpy(state, Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp, 1.0, calcChillerAbsorption + self.Name)
                var EnthSteamOutWet = self.steam.getSatEnthalpy(state, Node(state.dataLoopNodes, self.GeneratorInletNodeNum).Temp, 0.0,