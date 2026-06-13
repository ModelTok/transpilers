from dataclasses import dataclass, field
from typing import Optional, Protocol, List
import math

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData (state) - from EnergyPlus simulation state
# DataPlant.FlowMode - enum for flow control modes
# DataPlant.FlowLock - enum for flow lock status
# DataPlant.PlantEquipmentType - enum for equipment types
# DataPlant.LoopDemandCalcScheme - enum for loop demand calculation
# DataPlant.OpScheme - enum for operation scheme
# DataPlant.LoopFlowStatus - enum for loop flow priority
# DataBranchAirLoopPlant.ControlType - enum for control types
# Node.FluidType - enum for fluid types
# Node.ConnectionObjectType - enum for connection types
# Node.ConnectionType - enum (Inlet/Outlet)
# Node.CompFluidStream - enum for component fluid stream
# PlantComponent - base class for plant components
# BaseGlobalStruct - base class for global data structures
# PlantLocation - structure for plant loop locations
# Fluid.RefrigProps - refrigerant properties interface
# Fluid.GlycolProps - glycol properties interface
# PlantUtilities - functions for plant component operations
# Node - node management functions
# GlobalNames - name verification utilities
# InputProcessor - input processing
# OutputProcessor - output variable setup
# EMSManager - energy management system
# FaultsManager - fault simulation
# Constant - unit and temperature constants
# BaseSizer - sizing output reporting
# OutputReportPredefined - predefined report entries
# HVAC - system constants

CALC_CHILLER_ABSORPTION = "CALC Chiller:Absorption "
MODULE_OBJECT_TYPE = "Chiller:Absorption"


@dataclass
class ReportVars:
    PumpingPower: float = 0.0
    QGenerator: float = 0.0
    QEvap: float = 0.0
    QCond: float = 0.0
    PumpingEnergy: float = 0.0
    GeneratorEnergy: float = 0.0
    EvapEnergy: float = 0.0
    CondEnergy: float = 0.0
    CondInletTemp: float = 0.0
    EvapInletTemp: float = 0.0
    CondOutletTemp: float = 0.0
    EvapOutletTemp: float = 0.0
    Evapmdot: float = 0.0
    Condmdot: float = 0.0
    Genmdot: float = 0.0
    SteamMdot: float = 0.0
    ActualCOP: float = 0.0


@dataclass
class BLASTAbsorberSpecs:
    Name: str = ""
    Available: bool = False
    ON: bool = False
    NomCap: float = 0.0
    NomCapWasAutoSized: bool = False
    NomPumpPower: float = 0.0
    NomPumpPowerWasAutoSized: bool = False
    FlowMode: int = 0
    ModulatedFlowSetToLoop: bool = False
    ModulatedFlowErrDone: bool = False
    EvapVolFlowRate: float = 0.0
    EvapVolFlowRateWasAutoSized: bool = False
    CondVolFlowRate: float = 0.0
    CondVolFlowRateWasAutoSized: bool = False
    EvapMassFlowRateMax: float = 0.0
    CondMassFlowRateMax: float = 0.0
    GenMassFlowRateMax: float = 0.0
    SizFac: float = 0.0
    EvapInletNodeNum: int = 0
    EvapOutletNodeNum: int = 0
    CondInletNodeNum: int = 0
    CondOutletNodeNum: int = 0
    GeneratorInletNodeNum: int = 0
    GeneratorOutletNodeNum: int = 0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    TempDesCondIn: float = 0.0
    SteamLoadCoef: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    PumpPowerCoef: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    TempLowLimitEvapOut: float = 0.0
    ErrCount2: int = 0
    GenHeatSourceType: int = 0
    GeneratorVolFlowRate: float = 0.0
    GeneratorVolFlowRateWasAutoSized: bool = False
    GeneratorSubcool: float = 0.0
    steam: Optional[object] = None
    GeneratorDeltaTemp: float = -99999.0
    GeneratorDeltaTempWasAutoSized: bool = True
    CWPlantLoc: Optional[object] = None
    CDPlantLoc: Optional[object] = None
    GenPlantLoc: Optional[object] = None
    FaultyChillerSWTFlag: bool = False
    FaultyChillerSWTIndex: int = 0
    FaultyChillerSWTOffset: float = 0.0
    PossibleSubcooling: bool = False
    CondMassFlowRate: float = 0.0
    EvapMassFlowRate: float = 0.0
    SteamMassFlowRate: float = 0.0
    CondOutletTemp: float = 0.0
    EvapOutletTemp: float = 0.0
    GenOutletTemp: float = 0.0
    SteamOutletEnthalpy: float = 0.0
    PumpingPower: float = 0.0
    PumpingEnergy: float = 0.0
    QGenerator: float = 0.0
    GeneratorEnergy: float = 0.0
    QEvaporator: float = 0.0
    EvaporatorEnergy: float = 0.0
    QCondenser: float = 0.0
    CondenserEnergy: float = 0.0
    MyOneTimeFlag: bool = True
    MyEnvrnFlag: bool = True
    GenInputOutputNodesUsed: bool = False
    Report: ReportVars = field(default_factory=ReportVars)
    EquipFlowCtrl: int = 0
    water: Optional[object] = None

    @staticmethod
    def factory(state, objectName: str):
        if state.dataChillerAbsorber.getInput:
            GetBLASTAbsorberInput(state)
            state.dataChillerAbsorber.getInput = False
        
        for chiller in state.dataChillerAbsorber.absorptionChillers:
            if chiller.Name == objectName:
                return chiller
        
        raise RuntimeError(f"LocalBlastAbsorberFactory: Error getting inputs for object named: {objectName}")

    def simulate(self, state, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag):
        self.EquipFlowCtrl = calledFromLocation.comp.FlowCtrl

        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.initialize(state, RunFlag, CurLoad)
            self.calculate(state, CurLoad, RunFlag)
            self.updateRecords(state, CurLoad, RunFlag)

        elif calledFromLocation.loopNum == self.CDPlantLoc.loopNum:
            PlantUtilities.UpdateChillerComponentCondenserSide(
                state,
                calledFromLocation.loopNum,
                calledFromLocation.loopSideNum,
                DataPlant.PlantEquipmentType.Chiller_Absorption,
                self.CondInletNodeNum,
                self.CondOutletNodeNum,
                self.Report.QCond,
                self.Report.CondInletTemp,
                self.Report.CondOutletTemp,
                self.Report.Condmdot,
                FirstHVACIteration,
            )

        elif calledFromLocation.loopNum == self.GenPlantLoc.loopNum:
            PlantUtilities.UpdateAbsorberChillerComponentGeneratorSide(
                state,
                calledFromLocation.loopNum,
                calledFromLocation.loopSideNum,
                DataPlant.PlantEquipmentType.Chiller_Absorption,
                self.GeneratorInletNodeNum,
                self.GeneratorOutletNodeNum,
                self.GenHeatSourceType,
                self.Report.QGenerator,
                self.Report.SteamMdot,
                FirstHVACIteration,
            )
        else:
            raise RuntimeError(
                f"SimBLASTAbsorber: Invalid LoopNum passed={calledFromLocation.loopNum}, "
                f"Unit name={self.Name}, stored chilled water loop={self.CWPlantLoc.loopNum}, "
                f"stored condenser water loop={self.CDPlantLoc.loopNum}, "
                f"stored generator loop={self.GenPlantLoc.loopNum}"
            )

    def onInitLoopEquip(self, state, calledFromLocation):
        runFlag = True
        myLoad = 0.0
        self.initialize(state, runFlag, myLoad)
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.sizeChiller(state)

    def getDesignCapacities(self, state, calledFromLocation):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.sizeChiller(state)
            MinLoad = self.NomCap * self.MinPartLoadRat
            MaxLoad = self.NomCap * self.MaxPartLoadRat
            OptLoad = self.NomCap * self.OptPartLoadRat
            return MinLoad, MaxLoad, OptLoad
        else:
            return 0.0, 0.0, 0.0

    def getSizingFactor(self):
        return self.SizFac

    def getDesignTemperatures(self):
        return self.TempDesCondIn

    def setupOutputVars(self, state):
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Electricity Rate", Constant.Units.W,
            self.Report.PumpingPower, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Electricity Energy", Constant.Units.J,
            self.Report.PumpingEnergy, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum, self.Name,
            Constant.eResource.Electricity, OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Cooling
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Evaporator Cooling Rate", Constant.Units.W,
            self.Report.QEvap, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Evaporator Cooling Energy", Constant.Units.J,
            self.Report.EvapEnergy, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum, self.Name,
            Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Chillers
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Evaporator Inlet Temperature", Constant.Units.C,
            self.Report.EvapInletTemp, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Evaporator Outlet Temperature", Constant.Units.C,
            self.Report.EvapOutletTemp, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Evaporator Mass Flow Rate", Constant.Units.kg_s,
            self.Report.Evapmdot, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Condenser Heat Transfer Rate", Constant.Units.W,
            self.Report.QCond, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Condenser Heat Transfer Energy", Constant.Units.J,
            self.Report.CondEnergy, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum, self.Name,
            Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.HeatRejection
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Condenser Inlet Temperature", Constant.Units.C,
            self.Report.CondInletTemp, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Condenser Outlet Temperature", Constant.Units.C,
            self.Report.CondOutletTemp, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.SetupOutputVariable(
            state, "Chiller Condenser Mass Flow Rate", Constant.Units.kg_s,
            self.Report.Condmdot, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )

        if self.GenHeatSourceType == Node.FluidType.Water:
            OutputProcessor.SetupOutputVariable(
                state, "Chiller Hot Water Consumption Rate", Constant.Units.W,
                self.Report.QGenerator, OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average, self.Name
            )
            OutputProcessor.SetupOutputVariable(
                state, "Chiller Source Hot Water Energy", Constant.Units.J,
                self.Report.GeneratorEnergy, OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum, self.Name,
                Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.Plant,
                OutputProcessor.EndUseCat.Chillers
            )
        else:
            if self.GenInputOutputNodesUsed:
                OutputProcessor.SetupOutputVariable(
                    state, "Chiller Source Steam Rate", Constant.Units.W,
                    self.Report.QGenerator, OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Average, self.Name
                )
                OutputProcessor.SetupOutputVariable(
                    state, "Chiller Source Steam Energy", Constant.Units.J,
                    self.Report.GeneratorEnergy, OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Sum, self.Name,
                    Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.Plant,
                    OutputProcessor.EndUseCat.Chillers
                )
            else:
                OutputProcessor.SetupOutputVariable(
                    state, "Chiller Source Steam Rate", Constant.Units.W,
                    self.Report.QGenerator, OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Average, self.Name
                )
                OutputProcessor.SetupOutputVariable(
                    state, "Chiller Source Steam Energy", Constant.Units.J,
                    self.Report.GeneratorEnergy, OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Sum, self.Name,
                    Constant.eResource.DistrictHeatingSteam, OutputProcessor.Group.Plant,
                    OutputProcessor.EndUseCat.Cooling
                )

        OutputProcessor.SetupOutputVariable(
            state, "Chiller COP", Constant.Units.W_W,
            self.Report.ActualCOP, OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average, self.Name
        )

        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            OutputProcessor.SetupEMSInternalVariable(
                state, "Chiller Nominal Capacity", self.Name, "[W]", self.NomCap
            )

    def oneTimeInit(self, state):
        self.setupOutputVars(state)

        errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(
            state, self.Name, DataPlant.PlantEquipmentType.Chiller_Absorption,
            self.CWPlantLoc, errFlag, self.TempLowLimitEvapOut, None, None,
            self.EvapInletNodeNum, None
        )
        
        if self.CondInletNodeNum > 0:
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.Chiller_Absorption,
                self.CDPlantLoc, errFlag, None, None, None, self.CondInletNodeNum, None
            )
            PlantUtilities.InterConnectTwoPlantLoopSides(
                state, self.CWPlantLoc, self.CDPlantLoc,
                DataPlant.PlantEquipmentType.Chiller_Absorption, True
            )
        
        if self.GeneratorInletNodeNum > 0:
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.Chiller_Absorption,
                self.GenPlantLoc, errFlag, None, None, None,
                self.GeneratorInletNodeNum, None
            )
            PlantUtilities.InterConnectTwoPlantLoopSides(
                state, self.CWPlantLoc, self.GenPlantLoc,
                DataPlant.PlantEquipmentType.Chiller_Absorption, True
            )

        if self.CondInletNodeNum > 0 and self.GeneratorInletNodeNum > 0:
            PlantUtilities.InterConnectTwoPlantLoopSides(
                state, self.CDPlantLoc, self.GenPlantLoc,
                DataPlant.PlantEquipmentType.Chiller_Absorption, False
            )

        if errFlag:
            raise RuntimeError("InitBLASTAbsorberModel: Program terminated due to previous condition(s).")

        if self.FlowMode == DataPlant.FlowMode.Constant:
            DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn

        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
            DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn

            if (state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint == Node.SensedNodeFlagValue and
                state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi == Node.SensedNodeFlagValue):
                
                if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                    if not self.ModulatedFlowErrDone:
                        raise RuntimeError(
                            f"Missing temperature setpoint for LeavingSetpointModulated mode chiller named {self.Name}"
                        )
                else:
                    FatalError = False
                    EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.EvapOutletNodeNum, HVAC.CtrlVarType.Temp, FatalError)
                    state.dataLoopNodes.NodeSetpointCheck(self.EvapOutletNodeNum).needsSetpointChecking = False
                    if FatalError:
                        if not self.ModulatedFlowErrDone:
                            self.ModulatedFlowErrDone = True

                self.ModulatedFlowSetToLoop = True
                state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint = \
                    state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
                state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi = \
                    state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi

    def initEachEnvironment(self, state):
        rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "BLASTAbsorberSpecs::initEachEnvironment")
        self.EvapMassFlowRateMax = self.EvapVolFlowRate * rho

        PlantUtilities.InitComponentNodes(state, 0.0, self.EvapMassFlowRateMax, 
                                         self.EvapInletNodeNum, self.EvapOutletNodeNum)

        rho = self.CDPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "BLASTAbsorberSpecs::initEachEnvironment")
        self.CondMassFlowRateMax = rho * self.CondVolFlowRate

        PlantUtilities.InitComponentNodes(state, 0.0, self.CondMassFlowRateMax,
                                         self.CondInletNodeNum, self.CondOutletNodeNum)
        state.dataLoopNodes.Node(self.CondInletNodeNum).Temp = self.TempDesCondIn

        if self.GeneratorInletNodeNum > 0:
            if self.GenHeatSourceType == Node.FluidType.Water:
                rho = self.GenPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, "BLASTAbsorberSpecs::initEachEnvironment")
                self.GenMassFlowRateMax = rho * self.GeneratorVolFlowRate
            elif self.GenHeatSourceType == Node.FluidType.Steam:
                self.QGenerator = (self.SteamLoadCoef[0] + self.SteamLoadCoef[1] + self.SteamLoadCoef[2]) * self.NomCap

                EnthSteamOutDry = self.steam.getSatEnthalpy(
                    state, state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp, 1.0,
                    CALC_CHILLER_ABSORPTION + self.Name
                )
                EnthSteamOutWet = self.steam.getSatEnthalpy(
                    state, state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp, 0.0,
                    CALC_CHILLER_ABSORPTION + self.Name
                )
                SteamDeltaT = self.GeneratorSubcool
                SteamOutletTemp = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp - SteamDeltaT
                HfgSteam = EnthSteamOutDry - EnthSteamOutWet
                CpWater = self.water.getDensity(state, SteamOutletTemp, CALC_CHILLER_ABSORPTION + self.Name)
                self.GenMassFlowRateMax = self.QGenerator / (HfgSteam + CpWater * SteamDeltaT)

            PlantUtilities.InitComponentNodes(state, 0.0, self.GenMassFlowRateMax,
                                             self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum)

    def initialize(self, state, RunFlag, MyLoad):
        if self.MyOneTimeFlag:
            self.oneTimeInit(state)
            self.MyOneTimeFlag = False

        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated and self.ModulatedFlowSetToLoop:
            state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint = \
                state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
            state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi = \
                state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi

        mdotEvap = 0.0
        mdotCond = 0.0
        mdotGen = 0.0

        if MyLoad < 0.0 and RunFlag:
            mdotEvap = self.EvapMassFlowRateMax
            mdotCond = self.CondMassFlowRateMax
            mdotGen = self.GenMassFlowRateMax

        PlantUtilities.SetComponentFlowRate(state, mdotEvap, self.EvapInletNodeNum,
                                           self.EvapOutletNodeNum, self.CWPlantLoc)
        PlantUtilities.SetComponentFlowRate(state, mdotCond, self.CondInletNodeNum,
                                           self.CondOutletNodeNum, self.CDPlantLoc)

        if self.GeneratorInletNodeNum > 0:
            PlantUtilities.SetComponentFlowRate(state, mdotGen, self.GeneratorInletNodeNum,
                                               self.GeneratorOutletNodeNum, self.GenPlantLoc)

    def sizeChiller(self, state):
        # Complex sizing function with many branches
        SteamInputRatNom = self.SteamLoadCoef[0] + self.SteamLoadCoef[1] + self.SteamLoadCoef[2]
        
        tmpNomCap = self.NomCap
        tmpEvapVolFlowRate = self.EvapVolFlowRate
        tmpCondVolFlowRate = self.CondVolFlowRate
        tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate

        PltSizNum = self.CWPlantLoc.loop.PlantSizNum if self.CWPlantLoc.loop else 0
        PltSizCondNum = self.CDPlantLoc.loop.PlantSizNum if self.CDPlantLoc.loop else 0

        PltSizSteamNum = 0
        PltSizHeatingNum = 0
        ErrorsFound = False
        LoopErrorsFound = False

        if self.GenHeatSourceType == Node.FluidType.Steam:
            if self.GeneratorInletNodeNum > 0 and self.GeneratorOutletNodeNum > 0:
                PltSizSteamNum = PlantUtilities.MyPlantSizingIndex(
                    state, MODULE_OBJECT_TYPE, self.Name, 
                    self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, LoopErrorsFound
                )
            else:
                for PltSizIndex in range(len(state.dataSize.PlantSizData)):
                    if state.dataSize.PlantSizData[PltSizIndex].LoopType == DataSizing.TypeOfPlantLoop.Steam:
                        PltSizSteamNum = PltSizIndex
        else:
            if self.GeneratorInletNodeNum > 0 and self.GeneratorOutletNodeNum > 0:
                PltSizHeatingNum = PlantUtilities.MyPlantSizingIndex(
                    state, MODULE_OBJECT_TYPE, self.Name,
                    self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, LoopErrorsFound
                )
            else:
                for PltSizIndex in range(len(state.dataSize.PlantSizData)):
                    if state.dataSize.PlantSizData[PltSizIndex].LoopType == DataSizing.TypeOfPlantLoop.Heating:
                        PltSizHeatingNum = PltSizIndex

        # NomCap sizing
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                Cp = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "SizeAbsorpChiller")
                rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "SizeAbsorpChiller")
                tmpNomCap = (Cp * rho * state.dataSize.PlantSizData[PltSizNum].DeltaT *
                            state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate * self.SizFac)
                if not self.NomCapWasAutoSized:
                    tmpNomCap = self.NomCap
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                   "Design Size Nominal Capacity [W]", tmpNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                   "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        NomCapUser = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                       "Design Size Nominal Capacity [W]", tmpNomCap,
                                                       "User-Specified Nominal Capacity [W]", NomCapUser)
                        tmpNomCap = NomCapUser
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                raise RuntimeError(f"Autosizing of Absorption Chiller nominal capacity requires a loop Sizing:Plant object. Occurs in Chiller:Absorption object={self.Name}")
            if not self.NomCapWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and self.NomCap > 0.0:
                BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                           "User-Specified Nominal Capacity [W]", self.NomCap)

        # NomPumpPower sizing
        tmpNomPumpPower = 0.0045 * self.NomCap

        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if self.NomPumpPowerWasAutoSized:
                self.NomPumpPower = tmpNomPumpPower
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                               "Design Size Nominal Pumping Power [W]", tmpNomPumpPower)
            else:
                if self.NomPumpPower > 0.0 and tmpNomPumpPower > 0.0:
                    NomPumpPowerUser = self.NomPumpPower
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                   "Design Size Nominal Pumping Power [W]", tmpNomPumpPower,
                                                   "User-Specified Nominal Pumping Power [W]", NomPumpPowerUser)
                    tmpNomPumpPower = NomPumpPowerUser

        # EvapVolFlowRate sizing
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                tmpEvapVolFlowRate = state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate * self.SizFac
                if not self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = self.EvapVolFlowRate
            else:
                if self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.EvapVolFlowRateWasAutoSized:
                    self.EvapVolFlowRate = tmpEvapVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                   "Design Size Design Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate)

        PlantUtilities.RegisterPlantCompDesignFlow(state, self.EvapInletNodeNum, tmpEvapVolFlowRate)

        # CondVolFlowRate sizing
        if PltSizCondNum > 0 and PltSizNum > 0:
            if self.EvapVolFlowRate >= HVAC.SmallWaterVolFlow and tmpNomCap > 0.0:
                Cp = self.CDPlantLoc.loop.glycol.getSpecificHeat(state, self.TempDesCondIn, "SizeAbsorpChiller")
                rho = self.CDPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "SizeAbsorpChiller")
                tmpCondVolFlowRate = (tmpNomCap * (1.0 + SteamInputRatNom + tmpNomPumpPower / tmpNomCap) /
                                     (state.dataSize.PlantSizData[PltSizCondNum].DeltaT * Cp * rho))
                if not self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = self.CondVolFlowRate
            else:
                if self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.CondVolFlowRateWasAutoSized:
                    self.CondVolFlowRate = tmpCondVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, MODULE_OBJECT_TYPE, self.Name,
                                                   "Design Size Design Condenser Water Flow Rate [m3/s]", tmpCondVolFlowRate)

        PlantUtilities.RegisterPlantCompDesignFlow(state, self.CondInletNodeNum, tmpCondVolFlowRate)

        # GeneratorVolFlowRate sizing
        if ((PltSizSteamNum > 0 and self.GenHeatSourceType == Node.FluidType.Steam) or
            (PltSizHeatingNum > 0 and self.GenHeatSourceType == Node.FluidType.Water)):
            if self.EvapVolFlowRate >= HVAC.SmallWaterVolFlow and tmpNomCap > 0.0:
                if self.GenHeatSourceType == Node.FluidType.Water:
                    CpWater = self.GenPlantLoc.loop.glycol.getSpecificHeat(
                        state, state.dataSize.PlantSizData[PltSizHeatingNum].ExitTemp, "SizeAbsorpChiller"
                    )
                    SteamDeltaT = max(0.5, state.dataSize.PlantSizData[PltSizHeatingNum].DeltaT)
                    RhoWater = self.GenPlantLoc.loop.glycol.getDensity(
                        state, state.dataSize.PlantSizData[PltSizHeatingNum].ExitTemp - SteamDeltaT, "SizeAbsorpChiller"
                    )
                    tmpGeneratorVolFlowRate = (self.NomCap * SteamInputRatNom) / (CpWater * SteamDeltaT * RhoWater)
                    if not self.GeneratorVolFlowRateWasAutoSized:
                        tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate
                else:
                    SteamDensity = self.steam.getSatDensity(
                        state, state.dataSize.PlantSizData[PltSizSteamNum].ExitTemp, 1.0, "SizeAbsorptionChiller"
                    )
                    SteamDeltaT = state.dataSize.PlantSizData[PltSizSteamNum].DeltaT
                    GeneratorOutletTemp = state.dataSize.PlantSizData[PltSizSteamNum].ExitTemp - SteamDeltaT
                    
                    EnthSteamOutDry = self.steam.getSatEnthalpy(
                        state, state.dataSize.PlantSizData[PltSizSteamNum].ExitTemp, 1.0, MODULE_OBJECT_TYPE + self.Name
                    )
                    EnthSteamOutWet = self.steam.getSatEnthalpy(
                        state, state.dataSize.PlantSizData[PltSizSteamNum].ExitTemp, 0.0, MODULE_OBJECT_TYPE + self.Name
                    )
                    CpWater = self.water.getSpecificHeat(state, GeneratorOutletTemp, "SizeAbsorpChiller")
                    HfgSteam = EnthSteamOutDry - EnthSteamOutWet
                    self.SteamMassFlowRate = (self.NomCap * SteamInputRatNom) / (HfgSteam + SteamDeltaT * CpWater)
                    tmpGeneratorVolFlowRate = self.SteamMassFlowRate / SteamDensity
                    
                    if not self.GeneratorVolFlowRateWasAutoSized:
                        tmpGeneratorVolFlowRate = self.GeneratorVolFlowRate

        if self.GeneratorDeltaTempWasAutoSized:
            if PltSizHeatingNum > 0 and self.GenHeatSourceType == Node.FluidType.Water:
                self.GeneratorDeltaTemp = max(0.5, state.dataSize.PlantSizData[PltSizHeatingNum].DeltaT)
            elif self.GenHeatSourceType == Node.FluidType.Water:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    Cp = self.GenPlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "SizeAbsorpChiller")
                    rho = self.GenPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, "SizeAbsorpChiller")
                    self.GeneratorDeltaTemp = (SteamInputRatNom * self.NomCap) / (Cp * rho * self.GeneratorVolFlowRate)

        if ErrorsFound:
            raise RuntimeError("Preceding sizing errors cause program termination")

        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
            PlantUtilities.RegisterPlantCompDesignFlow(
                state, self.GeneratorInletNodeNum, self.GeneratorVolFlowRate
            )
        else:
            PlantUtilities.RegisterPlantCompDesignFlow(
                state, self.GeneratorInletNodeNum, tmpGeneratorVolFlowRate
            )

    def calculate(self, state, MyLoad, RunFlag):
        if MyLoad >= 0.0 or not RunFlag:
            if self.EquipFlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive:
                self.EvapMassFlowRate = state.dataLoopNodes.Node(self.EvapInletNodeNum).MassFlowRate
            return

        self.CondMassFlowRate = state.dataLoopNodes.Node(self.CondInletNodeNum).MassFlowRate
        TempEvapOut = state.dataLoopNodes.Node(self.EvapOutletNodeNum).Temp
        
        CpFluid = self.CWPlantLoc.loop.glycol.getSpecificHeat(
            state, state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp, "CalcBLASTAbsorberModel"
        )

        if self.FaultyChillerSWTFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing):
            FaultIndex = self.FaultyChillerSWTIndex
            EvapOutletTemp_ff = TempEvapOut
            self.FaultyChillerSWTOffset = state.dataFaultsMgr.FaultsChillerSWTSensor(FaultIndex).CalFaultOffsetAct(state)
            TempEvapOut = max(self.TempLowLimitEvapOut,
                            min(state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp,
                                EvapOutletTemp_ff - self.FaultyChillerSWTOffset))
            self.FaultyChillerSWTOffset = EvapOutletTemp_ff - TempEvapOut

        if self.CWPlantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
            self.PossibleSubcooling = False
            self.QEvaporator = abs(MyLoad)
            self.QEvaporator = min(self.QEvaporator, self.MaxPartLoadRat * self.NomCap)

            if self.FlowMode == DataPlant.FlowMode.Constant or self.FlowMode == DataPlant.FlowMode.NotModulated:
                self.EvapMassFlowRate = state.dataLoopNodes.Node(self.EvapInletNodeNum).MassFlowRate
                if self.EvapMassFlowRate != 0.0:
                    EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                else:
                    EvapDeltaTemp = 0.0
                self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - EvapDeltaTemp

            elif self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
                if self.CWPlantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    EvapDeltaTemp = (state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp -
                                    state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint)
                else:
                    EvapDeltaTemp = (state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp -
                                    state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi)

                if EvapDeltaTemp != 0:
                    self.EvapMassFlowRate = abs(self.QEvaporator / CpFluid / EvapDeltaTemp)
                    if self.EvapMassFlowRate - self.EvapMassFlowRateMax > DataBranchAirLoopPlant.MassFlowTolerance:
                        self.PossibleSubcooling = True
                    self.EvapMassFlowRate = min(self.EvapMassFlowRateMax, self.EvapMassFlowRate)
                    PlantUtilities.SetComponentFlowRate(state, self.EvapMassFlowRate,
                                                       self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
                    
                    if self.CWPlantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                        self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint
                    else:
                        self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi
                else:
                    self.EvapMassFlowRate = 0.0
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp

        else:
            self.EvapMassFlowRate = state.dataLoopNodes.Node(self.EvapInletNodeNum).MassFlowRate
            if self.PossibleSubcooling:
                self.QEvaporator = abs(MyLoad)
                EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - EvapDeltaTemp
            else:
                if self.CWPlantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    if (self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated or
                        DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).CurOpSchemeType == DataPlant.OpScheme.CompSetPtBased or
                        state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint != Node.SensedNodeFlagValue):
                        TempEvapOutSetPoint = state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPoint
                    else:
                        TempEvapOutSetPoint = state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPoint
                else:
                    if (self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated or
                        DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).CurOpSchemeType == DataPlant.OpScheme.CompSetPtBased or
                        state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi != Node.SensedNodeFlagValue):
                        TempEvapOutSetPoint = state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempSetPointHi
                    else:
                        TempEvapOutSetPoint = state.dataLoopNodes.Node(self.CWPlantLoc.loop.TempSetPointNodeNum).TempSetPointHi

                EvapDeltaTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - TempEvapOutSetPoint
                self.QEvaporator = abs(self.EvapMassFlowRate * CpFluid * EvapDeltaTemp)
                self.EvapOutletTemp = TempEvapOutSetPoint

            if self.EvapOutletTemp < self.TempLowLimitEvapOut:
                if (state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - self.TempLowLimitEvapOut) > DataPlant.DeltaTempTol:
                    self.EvapOutletTemp = self.TempLowLimitEvapOut
                    EvapDeltaTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
                else:
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp
                    EvapDeltaTemp = 0.0
                    self.QEvaporator = 0.0

            if self.EvapOutletTemp < state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempMin:
                if (state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp -
                    state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempMin) > DataPlant.DeltaTempTol:
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapOutletNodeNum).TempMin
                    EvapDeltaTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - self.EvapOutletTemp
                    self.QEvaporator = self.EvapMassFlowRate * CpFluid * EvapDeltaTemp
                else:
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp
                    EvapDeltaTemp = 0.0
                    self.QEvaporator = 0.0

            if self.QEvaporator > abs(MyLoad):
                if self.EvapMassFlowRate > DataBranchAirLoopPlant.MassFlowTolerance:
                    self.QEvaporator = abs(MyLoad)
                    EvapDeltaTemp = self.QEvaporator / self.EvapMassFlowRate / CpFluid
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp - EvapDeltaTemp
                else:
                    self.QEvaporator = 0.0
                    self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp

        PartLoadRat = max(self.MinPartLoadRat, min(self.QEvaporator / self.NomCap, self.MaxPartLoadRat))
        OperPartLoadRat = self.QEvaporator / self.NomCap
        FRAC = 1.0
        if OperPartLoadRat < PartLoadRat:
            FRAC = min(1.0, OperPartLoadRat / self.MinPartLoadRat)

        SteamInputRat = self.SteamLoadCoef[0] / PartLoadRat + self.SteamLoadCoef[1] + self.SteamLoadCoef[2] * PartLoadRat
        ElectricInputRat = (self.PumpPowerCoef[0] + self.PumpPowerCoef[1] * PartLoadRat +
                           self.PumpPowerCoef[2] * PartLoadRat * PartLoadRat)

        self.PumpingPower = ElectricInputRat * self.NomPumpPower * FRAC
        self.QGenerator = SteamInputRat * self.QEvaporator * FRAC

        if self.EvapMassFlowRate == 0.0:
            self.QGenerator = 0.0
            self.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp
            self.PumpingPower = 0.0

        self.QCondenser = self.QEvaporator + self.QGenerator + self.PumpingPower

        CpFluid = self.CDPlantLoc.loop.glycol.getSpecificHeat(
            state, state.dataLoopNodes.Node(self.CondInletNodeNum).Temp, "CalcBLASTAbsorberModel"
        )

        if self.CondMassFlowRate > DataBranchAirLoopPlant.MassFlowTolerance:
            self.CondOutletTemp = (self.QCondenser / self.CondMassFlowRate / CpFluid +
                                  state.dataLoopNodes.Node(self.CondInletNodeNum).Temp)
        else:
            self.CondOutletTemp = state.dataLoopNodes.Node(self.CondInletNodeNum).Temp
            self.CondMassFlowRate = 0.0
            self.QCondenser = 0.0
            self.EvapMassFlowRate = 0.0
            PlantUtilities.SetComponentFlowRate(state, self.EvapMassFlowRate,
                                               self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
            return

        if self.GeneratorInletNodeNum > 0:
            if self.GenHeatSourceType == Node.FluidType.Water:
                GenMassFlowRate = 0.0
                CpFluid = self.GenPlantLoc.loop.glycol.getSpecificHeat(
                    state, state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp, "CalcBLASTAbsorberModel"
                )

                if self.GenPlantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
                    if self.FlowMode == DataPlant.FlowMode.Constant or self.FlowMode == DataPlant.FlowMode.NotModulated:
                        GenMassFlowRate = self.GenMassFlowRateMax
                    else:
                        GenFlowRatio = self.EvapMassFlowRate / self.EvapMassFlowRateMax if self.EvapMassFlowRateMax > 0 else 0
                        GenMassFlowRate = min(self.GenMassFlowRateMax, GenFlowRatio * self.GenMassFlowRateMax)
                else:
                    GenMassFlowRate = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).MassFlowRate

                PlantUtilities.SetComponentFlowRate(state, GenMassFlowRate,
                                                   self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, self.GenPlantLoc)

                if GenMassFlowRate <= 0.0:
                    self.GenOutletTemp = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp
                    self.SteamOutletEnthalpy = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Enthalpy
                else:
                    self.GenOutletTemp = (state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp -
                                         self.QGenerator / (CpFluid * GenMassFlowRate))
                    self.SteamOutletEnthalpy = (state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Enthalpy -
                                               self.QGenerator / GenMassFlowRate)

                state.dataLoopNodes.Node(self.GeneratorOutletNodeNum).Temp = self.GenOutletTemp
                state.dataLoopNodes.Node(self.GeneratorOutletNodeNum).Enthalpy = self.SteamOutletEnthalpy
                state.dataLoopNodes.Node(self.GeneratorOutletNodeNum).MassFlowRate = GenMassFlowRate

            else:
                EnthSteamOutDry = self.steam.getSatEnthalpy(
                    state, state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp, 1.0,
                    CALC_CHILLER_ABSORPTION + self.Name
                )
                EnthSteamOutWet = self.steam.getSatEnthalpy(
                    state, state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp, 0.0,
                    CALC_CHILLER_ABSORPTION + self.Name
                )
                SteamDeltaT = self.GeneratorSubcool
                SteamOutletTemp = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp - SteamDeltaT
                HfgSteam = EnthSteamOutDry - EnthSteamOutWet
                CpFluid = self.water.getSpecificHeat(state, SteamOutletTemp, CALC_CHILLER_ABSORPTION + self.Name)
                self.SteamMassFlowRate = self.QGenerator / (HfgSteam + CpFluid * SteamDeltaT)
                PlantUtilities.SetComponentFlowRate(state, self.SteamMassFlowRate,
                                                   self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum, self.GenPlantLoc)

                if self.SteamMassFlowRate <= 0.0:
                    self.GenOutletTemp = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp
                    self.SteamOutletEnthalpy = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Enthalpy
                else:
                    self.GenOutletTemp = state.dataLoopNodes.Node(self.GeneratorInletNodeNum).Temp - SteamDeltaT
                    self.SteamOutletEnthalpy = self.steam.getSatEnthalpy(state, self.GenOutletTemp, 0.0,
                                                                        MODULE_OBJECT_TYPE + self.Name)
                    self.SteamOutletEnthalpy -= CpFluid * SteamDeltaT

        self.GeneratorEnergy = self.QGenerator * state.dataHVACGlobal.TimeStepSysSec
        self.EvaporatorEnergy = self.QEvaporator * state.dataHVACGlobal.TimeStepSysSec
        self.CondenserEnergy = self.QCondenser * state.dataHVACGlobal.TimeStepSysSec
        self.PumpingEnergy = self.PumpingPower * state.dataHVACGlobal.TimeStepSysSec

    def updateRecords(self, state, MyLoad, RunFlag):
        if MyLoad >= 0 or not RunFlag:
            PlantUtilities.SafeCopyPlantNode(state, self.EvapInletNodeNum, self.EvapOutletNodeNum)
            PlantUtilities.SafeCopyPlantNode(state, self.CondInletNodeNum, self.CondOutletNodeNum)

            self.Report.PumpingPower = 0.0
            self.Report.QEvap = 0.0
            self.Report.QCond = 0.0
            self.Report.QGenerator = 0.0
            self.Report.PumpingEnergy = 0.0
            self.Report.EvapEnergy = 0.0
            self.Report.CondEnergy = 0.0
            self.Report.GeneratorEnergy = 0.0
            self.Report.EvapInletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp
            self.Report.CondInletTemp = state.dataLoopNodes.Node(self.CondInletNodeNum).Temp
            self.Report.CondOutletTemp = state.dataLoopNodes.Node(self.CondOutletNodeNum).Temp
            self.Report.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapOutletNodeNum).Temp
            self.Report.Evapmdot = 0.0
            self.Report.Condmdot = 0.0
            self.Report.Genmdot = 0.0
            self.Report.ActualCOP = 0.0

            if self.GeneratorInletNodeNum > 0:
                PlantUtilities.SafeCopyPlantNode(state, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum)

        else:
            PlantUtilities.SafeCopyPlantNode(state, self.EvapInletNodeNum, self.EvapOutletNodeNum)
            PlantUtilities.SafeCopyPlantNode(state, self.CondInletNodeNum, self.CondOutletNodeNum)
            state.dataLoopNodes.Node(self.EvapOutletNodeNum).Temp = self.EvapOutletTemp
            state.dataLoopNodes.Node(self.CondOutletNodeNum).Temp = self.CondOutletTemp

            self.Report.PumpingPower = self.PumpingPower
            self.Report.QEvap = self.QEvaporator
            self.Report.QCond = self.QCondenser
            self.Report.QGenerator = self.QGenerator
            self.Report.PumpingEnergy = self.PumpingEnergy
            self.Report.EvapEnergy = self.EvaporatorEnergy
            self.Report.CondEnergy = self.CondenserEnergy
            self.Report.GeneratorEnergy = self.GeneratorEnergy
            self.Report.EvapInletTemp = state.dataLoopNodes.Node(self.EvapInletNodeNum).Temp
            self.Report.CondInletTemp = state.dataLoopNodes.Node(self.CondInletNodeNum).Temp
            self.Report.CondOutletTemp = state.dataLoopNodes.Node(self.CondOutletNodeNum).Temp
            self.Report.EvapOutletTemp = state.dataLoopNodes.Node(self.EvapOutletNodeNum).Temp
            self.Report.Evapmdot = self.EvapMassFlowRate
            self.Report.Condmdot = self.CondMassFlowRate
            self.Report.Genmdot = self.SteamMassFlowRate
            if self.QGenerator != 0.0:
                self.Report.ActualCOP = self.QEvaporator / self.QGenerator
            else:
                self.Report.ActualCOP = 0.0

            if self.GeneratorInletNodeNum > 0:
                PlantUtilities.SafeCopyPlantNode(state, self.GeneratorInletNodeNum, self.GeneratorOutletNodeNum)
                state.dataLoopNodes.Node(self.GeneratorOutletNodeNum).Temp = self.GenOutletTemp


def GetBLASTAbsorberInput(state):
    numAbsorbers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, MODULE_OBJECT_TYPE)

    if numAbsorbers <= 0:
        raise RuntimeError(f"No {MODULE_OBJECT_TYPE} equipment specified in input file")

    if state.dataChillerAbsorber.absorptionChillers:
        return

    state.dataChillerAbsorber.absorptionChillers = []

    for AbsorberNum in range(numAbsorbers):
        thisChiller = BLASTAbsorberSpecs()

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, MODULE_OBJECT_TYPE, AbsorberNum,
            state.dataIPShortCut.cAlphaArgs, state.dataIPShortCut.rNumericArgs,
            state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames
        )

        thisChiller.Name = state.dataIPShortCut.cAlphaArgs[0]
        thisChiller.NomCap = state.dataIPShortCut.rNumericArgs[0]
        if thisChiller.NomCap == DataSizing.AutoSize:
            thisChiller.NomCapWasAutoSized = True

        thisChiller.NomPumpPower = state.dataIPShortCut.rNumericArgs[1]
        if thisChiller.NomPumpPower == DataSizing.AutoSize:
            thisChiller.NomPumpPowerWasAutoSized = True

        thisChiller.EvapInletNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[1], Node.FluidType.Water,
            Node.ConnectionType.Inlet, Node.CompFluidStream.Primary
        )
        thisChiller.EvapOutletNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[2], Node.FluidType.Water,
            Node.ConnectionType.Outlet, Node.CompFluidStream.Primary
        )

        thisChiller.CondInletNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[3], Node.FluidType.Water,
            Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary
        )
        thisChiller.CondOutletNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[4], Node.FluidType.Water,
            Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary
        )

        if len(state.dataIPShortCut.cAlphaArgs) > 8:
            if state.dataIPShortCut.cAlphaArgs[8].upper() in ["HOTWATER", "HOTWATER"]:
                thisChiller.GenHeatSourceType = Node.FluidType.Water
            elif state.dataIPShortCut.cAlphaArgs[8].upper() in ["STEAM", ""]:
                thisChiller.GenHeatSourceType = Node.FluidType.Steam
        else:
            thisChiller.GenHeatSourceType = Node.FluidType.Steam

        if (not state.dataIPShortCut.lAlphaFieldBlanks[5] and
            not state.dataIPShortCut.lAlphaFieldBlanks[6]):
            thisChiller.GenInputOutputNodesUsed = True
            if thisChiller.GenHeatSourceType == Node.FluidType.Water:
                thisChiller.GeneratorInletNodeNum = Node.GetOnlySingleNode(
                    state, state.dataIPShortCut.cAlphaArgs[5], Node.FluidType.Water,
                    Node.ConnectionType.Inlet, Node.CompFluidStream.Tertiary
                )
                thisChiller.GeneratorOutletNodeNum = Node.GetOnlySingleNode(
                    state, state.dataIPShortCut.cAlphaArgs[6], Node.FluidType.Water,
                    Node.ConnectionType.Outlet, Node.CompFluidStream.Tertiary
                )
            else:
                thisChiller.steam = Fluid.GetSteam(state)
                thisChiller.GeneratorInletNodeNum = Node.GetOnlySingleNode(
                    state, state.dataIPShortCut.cAlphaArgs[5], Node.FluidType.Steam,
                    Node.ConnectionType.Inlet, Node.CompFluidStream.Tertiary
                )
                thisChiller.GeneratorOutletNodeNum = Node.GetOnlySingleNode(
                    state, state.dataIPShortCut.cAlphaArgs[6], Node.FluidType.Steam,
                    Node.ConnectionType.Outlet, Node.CompFluidStream.Tertiary
                )

        thisChiller.MinPartLoadRat = state.dataIPShortCut.rNumericArgs[2]
        thisChiller.MaxPartLoadRat = state.dataIPShortCut.rNumericArgs[3]
        thisChiller.OptPartLoadRat = state.dataIPShortCut.rNumericArgs[4]
        thisChiller.TempDesCondIn = state.dataIPShortCut.rNumericArgs[5]
        thisChiller.EvapVolFlowRate = state.dataIPShortCut.rNumericArgs[6]
        if thisChiller.EvapVolFlowRate == DataSizing.AutoSize:
            thisChiller.EvapVolFlowRateWasAutoSized = True

        thisChiller.CondVolFlowRate = state.dataIPShortCut.rNumericArgs[7]
        if thisChiller.CondVolFlowRate == DataSizing.AutoSize:
            thisChiller.CondVolFlowRateWasAutoSized = True

        thisChiller.SteamLoadCoef[0] = state.dataIPShortCut.rNumericArgs[8]
        thisChiller.SteamLoadCoef[1] = state.dataIPShortCut.rNumericArgs[9]
        thisChiller.SteamLoadCoef[2] = state.dataIPShortCut.rNumericArgs[10]
        thisChiller.PumpPowerCoef[0] = state.dataIPShortCut.rNumericArgs[11]
        thisChiller.PumpPowerCoef[1] = state.dataIPShortCut.rNumericArgs[12]
        thisChiller.PumpPowerCoef[2] = state.dataIPShortCut.rNumericArgs[13]
        thisChiller.TempLowLimitEvapOut = state.dataIPShortCut.rNumericArgs[14]

        thisChiller.FlowMode = state.dataIPShortCut.cAlphaArgs[7]

        if len(state.dataIPShortCut.rNumericArgs) > 15:
            thisChiller.GeneratorVolFlowRate = state.dataIPShortCut.rNumericArgs[15]
            if thisChiller.GeneratorVolFlowRate == DataSizing.AutoSize:
                thisChiller.GeneratorVolFlowRateWasAutoSized = True

        if len(state.dataIPShortCut.rNumericArgs) > 16:
            thisChiller.GeneratorSubcool = state.dataIPShortCut.rNumericArgs[16]
        else:
            thisChiller.GeneratorSubcool = 1.0

        if len(state.dataIPShortCut.rNumericArgs) > 17:
            thisChiller.SizFac = state.dataIPShortCut.rNumericArgs[17]
        else:
            thisChiller.SizFac = 1.0

        state.dataChillerAbsorber.absorptionChillers.append(thisChiller)


@dataclass
class ChillerAbsorberData:
    getInput: bool = True
    absorptionChillers: List[BLASTAbsorberSpecs] = field(default_factory=list)

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.getInput = True
        self.absorptionChillers = []
