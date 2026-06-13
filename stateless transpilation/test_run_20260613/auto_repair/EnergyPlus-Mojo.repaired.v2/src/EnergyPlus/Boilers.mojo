from Data.BaseData import *
from DataBranchAirLoopPlant import *
from DataGlobalConstants import *
from DataGlobals import *
from EnergyPlus import *
from Plant.DataPlant import *
from PlantComponent import *
from UtilityRoutines import *
from .Autosizing.Base import *
from BranchNodeConnections import *
from CurveManager import *
from .Data.EnergyPlusData import *
from DataHVACGlobals import *
from DataIPShortCuts import *
from DataLoopNode import *
from DataSizing import *
from EMSManager import *
from FaultsManager import *
from FluidProperties import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from Plant.PlantLocation import *
from PlantUtilities import *
from math import *
from memory import *
from string import *
from utils import *
alias Real64 = Float64
enum TempMode(Int32):
    Invalid = -1
    NOTSET = 0
    ENTERINGBOILERTEMP = 1
    LEAVINGBOILERTEMP = 2
    Num = 3
@value
struct BoilerSpecs(PlantComponent):
    var Name: String
    var FuelType: Constant.eFuel = Constant.eFuel.Invalid
    var Type: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var plantLoc: PlantLocation = PlantLocation()
    var Available: Bool = False
    var ON: Bool = False
    var NomCap: Real64 = 0.0
    var NomCapWasAutoSized: Bool = False
    var NomEffic: Real64 = 0.0
    var TempDesBoilerOut: Real64 = 0.0
    var FlowMode: DataPlant.FlowMode = DataPlant.FlowMode.Invalid
    var ModulatedFlowSetToLoop: Bool = False
    var ModulatedFlowErrDone: Bool = False
    var VolFlowRate: Real64 = 0.0
    var VolFlowRateWasAutoSized: Bool = False
    var DesMassFlowRate: Real64 = 0.0
    var MassFlowRate: Real64 = 0.0
    var SizFac: Real64 = 0.0
    var BoilerInletNodeNum: Int32 = 0
    var BoilerOutletNodeNum: Int32 = 0
    var MinPartLoadRat: Real64 = 0.0
    var MaxPartLoadRat: Real64 = 0.0
    var OptPartLoadRat: Real64 = 0.0
    var OperPartLoadRat: Real64 = 0.0
    var CurveTempMode: TempMode = TempMode.NOTSET
    var EfficiencyCurve: Curve.Curve = None
    var TempUpLimitBoilerOut: Real64 = 0.0
    var ParasiticElecLoad: Real64 = 0.0
    var ParasiticFuelConsumption: Real64 = 0.0
    var ParasiticFuelRate: Real64 = 0.0
    var ParasiticFuelCapacity: Real64 = 0.0
    var EffCurveOutputError: Int32 = 0
    var EffCurveOutputIndex: Int32 = 0
    var CalculatedEffError: Int32 = 0
    var CalculatedEffIndex: Int32 = 0
    var IsThisSized: Bool = False
    var FaultyBoilerFoulingFlag: Bool = False
    var FaultyBoilerFoulingIndex: Int32 = 0
    var FaultyBoilerFoulingFactor: Real64 = 1.0
    var EndUseSubcategory: String
    var MyEnvrnFlag: Bool = True
    var MyFlag: Bool = True
    var FuelUsed: Real64 = 0.0
    var ParasiticElecPower: Real64 = 0.0
    var BoilerLoad: Real64 = 0.0
    var BoilerMassFlowRate: Real64 = 0.0
    var BoilerOutletTemp: Real64 = 0.0
    var BoilerPLR: Real64 = 0.0
    var BoilerEff: Real64 = 0.0
    var BoilerEnergy: Real64 = 0.0
    var FuelConsumed: Real64 = 0.0
    var BoilerInletTemp: Real64 = 0.0
    var ParasiticElecConsumption: Real64 = 0.0
    def simulate(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Real64, RunFlag: Bool):
        var sim_component = DataPlant.CompData.getPlantComponent(state, self.plantLoc)
        self.InitBoiler(state)
        self.CalcBoilerModel(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.UpdateBoilerRecords(state, CurLoad, RunFlag)
    def getDesignCapacities(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Real64, inout MinLoad: Real64, inout OptLoad: Real64):
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat
    def getSizingFactor(inout self, inout SizFactor: Real64):
        SizFactor = self.SizFac
    def onInitLoopEquip(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.InitBoiler(state)
        self.SizeBoiler(state)
    def SetupOutputVars(inout self, inout state: EnergyPlusData):
        var sFuelType: String = Constant.eFuelNames[Int32(self.FuelType)]
        SetupOutputVariable(state, "Boiler Heating Rate", Constant.Units.W, self.BoilerLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Heating Energy", Constant.Units.J, self.BoilerEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Boilers)
        SetupOutputVariable(state, "Boiler {} Rate".format(sFuelType), Constant.Units.W, self.FuelUsed, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler {} Energy".format(sFuelType), Constant.Units.J, self.FuelConsumed, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eFuel2eResource[Int32(self.FuelType)], OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating, self.EndUseSubcategory)
        SetupOutputVariable(state, "Boiler Inlet Temperature", Constant.Units.C, self.BoilerInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Outlet Temperature", Constant.Units.C, self.BoilerOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Mass Flow Rate", Constant.Units.kg_s, self.BoilerMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Ancillary Electricity Rate", Constant.Units.W, self.ParasiticElecPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Ancillary Electricity Energy", Constant.Units.J, self.ParasiticElecConsumption, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating, "Boiler Parasitic")
        if self.FuelType != Constant.eFuel.Electricity:
            SetupOutputVariable(state, "Boiler Ancillary {} Rate".format(sFuelType), Constant.Units.W, self.ParasiticFuelRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            SetupOutputVariable(state, "Boiler Ancillary {} Energy".format(sFuelType), Constant.Units.J, self.ParasiticFuelConsumption, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eFuel2eResource[Int32(self.FuelType)], OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating, "Boiler Parasitic")
        SetupOutputVariable(state, "Boiler Part Load Ratio", Constant.Units.None, self.BoilerPLR, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Efficiency", Constant.Units.None, self.BoilerEff, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSInternalVariable(state, "Boiler Nominal Capacity", self.Name, "[W]", self.NomCap)
    def oneTimeInit(inout self, inout state: EnergyPlusData):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Boiler_Simple, self.plantLoc, errFlag, _, self.TempUpLimitBoilerOut, _, _, _)
        if errFlag:
            ShowFatalError(state, "InitBoiler: Program terminated due to previous condition(s).")
        if (self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated) or (self.FlowMode == DataPlant.FlowMode.Constant):
            DataPlant.CompData.getPlantComponent(state, self.plantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn
    def initEachEnvironment(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "BoilerSpecs::initEachEnvironment"
        var rho: Real64 = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
        self.DesMassFlowRate = self.VolFlowRate * rho
        PlantUtilities.InitComponentNodes(state, 0.0, self.DesMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum)
        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
            if (state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPoint == Node.SensedNodeFlagValue) and (state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPointLo == Node.SensedNodeFlagValue):
                if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                    if not self.ModulatedFlowErrDone:
                        ShowWarningError(state, "Missing temperature setpoint for LeavingSetpointModulated mode Boiler named {}".format(self.Name))
                        ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode, use a SetpointManager")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                        self.ModulatedFlowErrDone = True
                else:
                    var FatalError: Bool = False
                    EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.BoilerOutletNodeNum, HVAC.CtrlVarType.Temp, FatalError)
                    state.dataLoopNodes.NodeSetpointCheck(self.BoilerOutletNodeNum).needsSetpointChecking = False
                    if FatalError:
                        if not self.ModulatedFlowErrDone:
                            ShowWarningError(state, "Missing temperature setpoint for LeavingSetpointModulated mode Boiler named {}".format(self.Name))
                            ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode")
                            ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the boiler outlet node ")
                            ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the boiler outlet node ")
                            ShowContinueError(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                            self.ModulatedFlowErrDone = True
                self.ModulatedFlowSetToLoop = True
    def InitBoiler(inout self, inout state: EnergyPlusData):
        if self.MyFlag:
            self.SetupOutputVars(state)
            self.oneTimeInit(state)
            self.MyFlag = False
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        if (self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated) and self.ModulatedFlowSetToLoop:
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPoint = state.dataLoopNodes.Node(self.plantLoc.loop.TempSetPointNodeNum).TempSetPoint
            else:
                state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPointLo = state.dataLoopNodes.Node(self.plantLoc.loop.TempSetPointNodeNum).TempSetPointLo
    def SizeBoiler(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "SizeBoiler"
        var ErrorsFound: Bool = False
        var tmpNomCap: Real64 = self.NomCap
        var tmpBoilerVolFlowRate: Real64 = self.VolFlowRate
        var PltSizNum: Int32 = self.plantLoc.loop.PlantSizNum
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                var rho: Real64 = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                var Cp: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                tmpNomCap = Cp * rho * self.SizFac * state.dataSize.PlantSizData[PltSizNum].DeltaT * state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Design Size Nominal Capacity [W]", tmpNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        var NomCapUser: Real64 = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Design Size Nominal Capacity [W]", tmpNomCap, "User-Specified Nominal Capacity [W]", NomCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpNomCap - NomCapUser) / NomCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, "SizeBoilerHotWater: Potential issue with equipment sizing for {}".format(self.Name))
                                    ShowContinueError(state, "User-Specified Nominal Capacity of {:.2f} [W]".format(NomCapUser))
                                    ShowContinueError(state, "differs from Design Size Nominal Capacity of {:.2f} [W]".format(tmpNomCap))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, "Occurs in Boiler object={}".format(self.Name))
                ErrorsFound = True
            if not self.NomCapWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.NomCap > 0.0):
                BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                tmpBoilerVolFlowRate = state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate * self.SizFac
            else:
                if self.VolFlowRateWasAutoSized:
                    tmpBoilerVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.VolFlowRateWasAutoSized:
                    self.VolFlowRate = tmpBoilerVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Initial Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate)
                else:
                    if self.VolFlowRate > 0.0 and tmpBoilerVolFlowRate > 0.0:
                        var VolFlowRateUser: Real64 = self.VolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate, "User-Specified Design Water Flow Rate [m3/s]", VolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpBoilerVolFlowRate - VolFlowRateUser) / VolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, "SizeBoilerHotWater: Potential issue with equipment sizing for {}".format(self.Name))
                                    ShowContinueError(state, "User-Specified Design Water Flow Rate of {:#G} [m3/s]".format(VolFlowRateUser))
                                    ShowContinueError(state, "differs from Design Size Design Water Flow Rate of {:#G} [m3/s]".format(tmpBoilerVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpBoilerVolFlowRate = VolFlowRateUser
        else:
            if self.VolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler design flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, "Occurs in Boiler object={}".format(self.Name))
                ErrorsFound = True
            if not self.VolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.VolFlowRate > 0.0):
                BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "User-Specified Design Water Flow Rate [m3/s]", self.VolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.BoilerInletNodeNum, tmpBoilerVolFlowRate)
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            var equipName: String = self.Name
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, equipName, "Boiler:HotWater")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, equipName, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, equipName, "Boiler:HotWater")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, equipName, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, equipName, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, equipName, self.plantLoc.loop.Name if self.plantLoc.loop != None else "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, equipName, self.plantLoc.branch.Name if self.plantLoc.loop != None else "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, equipName, self.MinPartLoadRat)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, equipName, Constant.eFuelNames[Int32(self.FuelType)])
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, equipName, self.ParasiticElecLoad)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    def CalcBoilerModel(inout self, inout state: EnergyPlusData, MyLoad: Real64, RunFlag: Bool, EquipFlowCtrl: DataBranchAirLoopPlant.ControlType):
        var RoutineName: String = "CalcBoilerModel"
        self.BoilerLoad = 0.0
        self.ParasiticElecPower = 0.0
        self.BoilerMassFlowRate = 0.0
        var BoilerInletNode: Int32 = self.BoilerInletNodeNum
        var BoilerOutletNode: Int32 = self.BoilerOutletNodeNum
        var BoilerNomCap: Real64 = self.NomCap
        var BoilerMaxPLR: Real64 = self.MaxPartLoadRat
        var BoilerMinPLR: Real64 = self.MinPartLoadRat
        var BoilerNomEff: Real64 = self.NomEffic
        var TempUpLimitBout: Real64 = self.TempUpLimitBoilerOut
        var BoilerMassFlowRateMax: Real64 = self.DesMassFlowRate
        var Cp: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node(BoilerInletNode).Temp, RoutineName)
        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive:
                self.BoilerMassFlowRate = state.dataLoopNodes.Node(BoilerInletNode).MassFlowRate
            return
        if self.FaultyBoilerFoulingFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and (not state.dataGlobal.KickOffSimulation):
            var FaultIndex: Int32 = self.FaultyBoilerFoulingIndex
            var NomCap_ff: Real64 = BoilerNomCap
            var BoilerNomEff_ff: Real64 = BoilerNomEff
            self.FaultyBoilerFoulingFactor = state.dataFaultsMgr.FaultsBoilerFouling[FaultIndex].CalFoulingFactor(state)
            BoilerNomCap = NomCap_ff * self.FaultyBoilerFoulingFactor
            BoilerNomEff = BoilerNomEff_ff * self.FaultyBoilerFoulingFactor
        self.BoilerLoad = MyLoad
        var BoilerDeltaTemp: Real64
        if self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
            if (self.FlowMode == DataPlant.FlowMode.Constant) or (self.FlowMode == DataPlant.FlowMode.NotModulated):
                self.BoilerMassFlowRate = BoilerMassFlowRateMax
                PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)
                if (self.BoilerMassFlowRate != 0.0) and (MyLoad > 0.0):
                    BoilerDeltaTemp = self.BoilerLoad / self.BoilerMassFlowRate / Cp
                else:
                    BoilerDeltaTemp = 0.0
                self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node(BoilerInletNode).Temp
            elif self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
                if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    BoilerDeltaTemp = state.dataLoopNodes.Node(BoilerOutletNode).TempSetPoint - state.dataLoopNodes.Node(BoilerInletNode).Temp
                else:
                    BoilerDeltaTemp = state.dataLoopNodes.Node(BoilerOutletNode).TempSetPointLo - state.dataLoopNodes.Node(BoilerInletNode).Temp
                self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node(BoilerInletNode).Temp
                if (BoilerDeltaTemp > 0.0) and (self.BoilerLoad > 0.0):
                    self.BoilerMassFlowRate = self.BoilerLoad / Cp / BoilerDeltaTemp
                    self.BoilerMassFlowRate = min(BoilerMassFlowRateMax, self.BoilerMassFlowRate)
                else:
                    self.BoilerMassFlowRate = 0.0
                PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)
        else:
            self.BoilerMassFlowRate = state.dataLoopNodes.Node(BoilerInletNode).MassFlowRate
            if (MyLoad > 0.0) and (self.BoilerMassFlowRate > 0.0):
                self.BoilerLoad = MyLoad
                if self.BoilerLoad > BoilerNomCap * BoilerMaxPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMaxPLR
                if self.BoilerLoad < BoilerNomCap * BoilerMinPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMinPLR
                self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp + self.BoilerLoad / (self.BoilerMassFlowRate * Cp)
            else:
                self.BoilerLoad = 0.0
                self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp
        if self.BoilerOutletTemp > TempUpLimitBout:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp
        self.BoilerPLR = self.BoilerLoad / BoilerNomCap
        self.BoilerPLR = min(self.BoilerPLR, BoilerMaxPLR)
        self.BoilerPLR = max(self.BoilerPLR, BoilerMinPLR)
        var TheorFuelUse: Real64 = self.BoilerLoad / BoilerNomEff
        var EffCurveOutput: Real64 = 1.0
        if self.EfficiencyCurve != None:
            if self.EfficiencyCurve.numDims == 2:
                if self.CurveTempMode == TempMode.ENTERINGBOILERTEMP:
                    EffCurveOutput = self.EfficiencyCurve.value(state, self.BoilerPLR, state.dataLoopNodes.Node(BoilerInletNode).Temp)
                elif self.CurveTempMode == TempMode.LEAVINGBOILERTEMP:
                    EffCurveOutput = self.EfficiencyCurve.value(state, self.BoilerPLR, self.BoilerOutletTemp)
            else:
                EffCurveOutput = self.EfficiencyCurve.value(state, self.BoilerPLR)
        BoilerEff = EffCurveOutput * BoilerNomEff
        if not state.dataGlobal.WarmupFlag and EffCurveOutput <= 0.0:
            if self.BoilerLoad > 0.0:
                if self.EffCurveOutputError < 1:
                    self.EffCurveOutputError += 1
                    ShowWarningError(state, "Boiler:HotWater \"{}\"".format(self.Name))
                    ShowContinueError(state, "...Normalized Boiler Efficiency Curve output is less than or equal to 0.")
                    ShowContinueError(state, "...Curve input x value (PLR)     = {:.5f}".format(self.BoilerPLR))
                    if self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == TempMode.ENTERINGBOILERTEMP:
                            ShowContinueError(state, "...Curve input y value (Tinlet) = {:.2f}".format(state.dataLoopNodes.Node(BoilerInletNode).Temp))
                        elif self.CurveTempMode == TempMode.LEAVINGBOILERTEMP:
                            ShowContinueError(state, "...Curve input y value (Toutlet) = {:.2f}".format(self.BoilerOutletTemp))
                    ShowContinueError(state, "...Curve output (normalized eff) = {:.5f}".format(EffCurveOutput))
                    ShowContinueError(state, "...Calculated Boiler efficiency  = {:.5f} (Boiler efficiency = Nominal Thermal Efficiency * Normalized Boiler Efficiency Curve output)".format(BoilerEff))
                    ShowContinueErrorTimeStamp(state, "...Curve output reset to 0.01 and simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, "Boiler:HotWater \"" + self.Name + "\": Boiler Efficiency Curve output is less than or equal to 0 warning continues...", self.EffCurveOutputIndex, EffCurveOutput, EffCurveOutput)
            EffCurveOutput = 0.01
        if not state.dataGlobal.WarmupFlag and BoilerEff > 1.1:
            if self.BoilerLoad > 0.0 and self.EfficiencyCurve != None and NomEffic <= 1.0:
                if self.CalculatedEffError < 1:
                    self.CalculatedEffError += 1
                    ShowWarningError(state, "Boiler:HotWater \"{}\"".format(self.Name))
                    ShowContinueError(state, "...Calculated Boiler Efficiency is greater than 1.1.")
                    ShowContinueError(state, "...Boiler Efficiency calculations shown below.")
                    ShowContinueError(state, "...Curve input x value (PLR)     = {:.5f}".format(self.BoilerPLR))
                    if self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == TempMode.ENTERINGBOILERTEMP:
                            ShowContinueError(state, "...Curve input y value (Tinlet) = {:.2f}".format(state.dataLoopNodes.Node(BoilerInletNode).Temp))
                        elif self.CurveTempMode == TempMode.LEAVINGBOILERTEMP:
                            ShowContinueError(state, "...Curve input y value (Toutlet) = {:.2f}".format(self.BoilerOutletTemp))
                    ShowContinueError(state, "...Curve output (normalized eff) = {:.5f}".format(EffCurveOutput))
                    ShowContinueError(state, "...Calculated Boiler efficiency  = {:.5f} (Boiler efficiency = Nominal Thermal Efficiency * Normalized Boiler Efficiency Curve output)".format(BoilerEff))
                    ShowContinueErrorTimeStamp(state, "...Curve output reset to 1.1 and simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, "Boiler:HotWater \"" + self.Name + "\": Calculated Boiler Efficiency is greater than 1.1 warning continues...", self.CalculatedEffIndex, BoilerEff, BoilerEff)
            EffCurveOutput = 1.1
        self.FuelUsed = TheorFuelUse / EffCurveOutput
        if self.BoilerLoad > 0.0:
            self.ParasiticElecPower = self.ParasiticElecLoad * self.BoilerPLR
        self.ParasiticFuelRate = self.ParasiticFuelCapacity * (1.0 - self.BoilerPLR)
    def UpdateBoilerRecords(inout self, inout state: EnergyPlusData, MyLoad: Real64, RunFlag: Bool):
        var ReportingConstant: Real64 = state.dataHVACGlobal.TimeStepSysSec
        var BoilerInletNode: Int32 = self.BoilerInletNodeNum
        var BoilerOutletNode: Int32 = self.BoilerOutletNodeNum
        if MyLoad <= 0 or not RunFlag:
            PlantUtilities.SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
            state.dataLoopNodes.Node(BoilerOutletNode).Temp = state.dataLoopNodes.Node(BoilerInletNode).Temp
            self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp
            self.BoilerLoad = 0.0
            self.FuelUsed = 0.0
            self.ParasiticElecPower = 0.0
            self.BoilerPLR = 0.0
            self.BoilerEff = 0.0
        else:
            PlantUtilities.SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
            state.dataLoopNodes.Node(BoilerOutletNode).Temp = self.BoilerOutletTemp
        self.BoilerInletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp
        self.BoilerMassFlowRate = state.dataLoopNodes.Node(BoilerOutletNode).MassFlowRate
        self.BoilerEnergy = self.BoilerLoad * ReportingConstant
        self.FuelConsumed = self.FuelUsed * ReportingConstant
        self.ParasiticElecConsumption = self.ParasiticElecPower * ReportingConstant
        self.ParasiticFuelConsumption = self.ParasiticFuelRate * ReportingConstant
    @staticmethod
    def factory(inout state: EnergyPlusData, objectName: String) -> BoilerSpecs:
        if state.dataBoilers.getBoilerInputFlag:
            GetBoilerInput(state)
            state.dataBoilers.getBoilerInputFlag = False
        for boiler in state.dataBoilers.Boiler:
            if boiler.Name == objectName:
                return boiler
        ShowFatalError(state, "LocalBoilerFactory: Error getting inputs for boiler named: {}".format(objectName))
        return None
def GetBoilerInput(inout state: EnergyPlusData):
    var RoutineName: String = "GetBoilerInput: "
    var routineName: String = "GetBoilerInput"
    var s_ipsc = state.dataIPShortCut
    var ErrorsFound: Bool = False
    s_ipsc.cCurrentModuleObject = "Boiler:HotWater"
    var numBoilers: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
    if numBoilers <= 0:
        ShowSevereError(state, "No {} Equipment specified in input file".format(s_ipsc.cCurrentModuleObject))
        ErrorsFound = True
    if not state.dataBoilers.Boiler.empty():
        return
    var inputProcessor = state.dataInputProcessing.inputProcessor
    var boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, s_ipsc.cCurrentModuleObject)
    var boilerObjects = inputProcessor.epJSON.find(s_ipsc.cCurrentModuleObject)
    for boilerInstance in boilerObjects.value().items():
        var boilerFields = boilerInstance.value()
        var boilerName = Util.makeUPPER(boilerInstance.key())
        var fuelType = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
        var efficiencyCurveTempEvalVar = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "efficiency_curve_temperature_evaluation_variable")
        var normalizedBoilerEfficiencyCurveName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "normalized_boiler_efficiency_curve_name")
        var boilerWaterInletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_inlet_node_name")
        var boilerWaterOutletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_outlet_node_name")
        var boilerFlowMode = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_flow_mode")
        inputProcessor.markObjectAsUsed(s_ipsc.cCurrentModuleObject, boilerInstance.key())
        var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, boilerName)
        GlobalNames.VerifyUniqueBoilerName(state, s_ipsc.cCurrentModuleObject, boilerName, ErrorsFound, s_ipsc.cCurrentModuleObject + " Name")
        state.dataBoilers.Boiler.append(BoilerSpecs())
        var thisBoiler = state.dataBoilers.Boiler[-1]
        thisBoiler.Name = boilerName
        thisBoiler.Type = DataPlant.PlantEquipmentType.Boiler_Simple
        thisBoiler.FuelType = Constant.eFuel(getEnumValue(Constant.eFuelNamesUC, fuelType))
        thisBoiler.NomCap = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_capacity")
        if thisBoiler.NomCap == 0.0:
            ShowSevereError(state, "{}{}=\"{}\",".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
            ShowContinueError(state, "Invalid {}={:.2f}".format("Nominal Capacity", thisBoiler.NomCap))
            ShowContinueError(state, "...Nominal Capacity must be greater than 0.0")
            ErrorsFound = True
        if thisBoiler.NomCap == DataSizing.AutoSize:
            thisBoiler.NomCapWasAutoSized = True
        thisBoiler.NomEffic = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_thermal_efficiency")
        if thisBoiler.NomEffic == 0.0:
            ShowSevereError(state, "{}{}=\"{}\",".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
            ShowContinueError(state, "Invalid {}={:.3f}".format("Nominal Thermal Efficiency", thisBoiler.NomEffic))
            ShowContinueError(state, "...Nominal Thermal Efficiency must be greater than 0.0")
            ErrorsFound = True
        elif thisBoiler.NomEffic > 1.0:
            ShowWarningError(state, "{} = {}: {}={} should not typically be greater than 1.".format(s_ipsc.cCurrentModuleObject, boilerName, "Nominal Thermal Efficiency", thisBoiler.NomEffic))
        if efficiencyCurveTempEvalVar == "ENTERINGBOILER":
            thisBoiler.CurveTempMode = TempMode.ENTERINGBOILERTEMP
        elif efficiencyCurveTempEvalVar == "LEAVINGBOILER":
            thisBoiler.CurveTempMode = TempMode.LEAVINGBOILERTEMP
        else:
            thisBoiler.CurveTempMode = TempMode.NOTSET
        if normalizedBoilerEfficiencyCurveName.empty():

        elif (thisBoiler.EfficiencyCurve = Curve.GetCurve(state, normalizedBoilerEfficiencyCurveName)) == None:
            ShowSevereItemNotFound(state, eoh, "Normalized Boiler Efficiency Curve Name", normalizedBoilerEfficiencyCurveName)
            ErrorsFound = True
        elif thisBoiler.EfficiencyCurve.numDims != 1 and thisBoiler.EfficiencyCurve.numDims != 2:
            Curve.ShowSevereCurveDims(state, eoh, "Normalized Boiler Efficiency Curve Name", normalizedBoilerEfficiencyCurveName, "1 or 2", thisBoiler.EfficiencyCurve.numDims)
            ErrorsFound = True
        elif thisBoiler.EfficiencyCurve.numDims == 2:
            if thisBoiler.CurveTempMode == TempMode.NOTSET:
                if not efficiencyCurveTempEvalVar.empty():
                    ShowSevereError(state, "{}{}=\"{}\"".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
                    ShowContinueError(state, "Invalid {}={}".format("Efficiency Curve Temperature Evaluation Variable", efficiencyCurveTempEvalVar))
                    ShowContinueError(state, "boilers.Boiler using curve type of {} must specify {}".format(Curve.objectNames[Int32(thisBoiler.EfficiencyCurve.curveType)], "Efficiency Curve Temperature Evaluation Variable"))
                    ShowContinueError(state, "Available choices are EnteringBoiler or LeavingBoiler")
                else:
                    ShowSevereError(state, "{}{}=\"{}\"".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
                    ShowContinueError(state, "Field {} is blank".format("Efficiency Curve Temperature Evaluation Variable"))
                    ShowContinueError(state, "boilers.Boiler using curve type of {} must specify either EnteringBoiler or LeavingBoiler".format(Curve.objectNames[Int32(thisBoiler.EfficiencyCurve.curveType)]))
                ErrorsFound = True
        thisBoiler.VolFlowRate = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "design_water_flow_rate")
        if thisBoiler.VolFlowRate == DataSizing.AutoSize:
            thisBoiler.VolFlowRateWasAutoSized = True
        thisBoiler.MinPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "minimum_part_load_ratio")
        thisBoiler.MaxPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_part_load_ratio")
        thisBoiler.OptPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "optimum_part_load_ratio")
        thisBoiler.TempUpLimitBoilerOut = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "water_outlet_upper_temperature_limit")
        if thisBoiler.TempUpLimitBoilerOut <= 0.0:
            thisBoiler.TempUpLimitBoilerOut = 99.9
        var getOptionalNumericField = fn(boilerFields: Dict[String, Any], fieldName: String, defaultValue: Real64 = 0.0) -> Real64:
            if fieldName not in boilerFields:
                return defaultValue
            var fieldValue = boilerFields[fieldName]
            if fieldValue is Int64:
                return Real64(fieldValue)
            if fieldValue is Real64:
                return fieldValue
            if fieldValue is String and fieldValue == "":
                return defaultValue
            return defaultValue
        thisBoiler.ParasiticElecLoad = getOptionalNumericField(boilerFields, "on_cycle_parasitic_electric_load")
        if thisBoiler.ParasiticElecLoad == 0.0:
            thisBoiler.ParasiticElecLoad = getOptionalNumericField(boilerFields, "parasitic_electric_load")
        thisBoiler.ParasiticFuelCapacity = getOptionalNumericField(boilerFields, "off_cycle_parasitic_fuel_load")
        if thisBoiler.FuelType == Constant.eFuel.Electricity and thisBoiler.ParasiticFuelCapacity > 0:
            ShowWarningError(state, "{}{}=\"{}\"".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
            ShowContinueError(state, "{} should be zero when the fuel type is electricity.".format("Parasitic Fuel Capacity"))
            ShowContinueError(state, "It will be ignored and the simulation continues.")
            thisBoiler.ParasiticFuelCapacity = 0.0
        thisBoiler.SizFac = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "sizing_factor")
        if thisBoiler.SizFac == 0.0:
            thisBoiler.SizFac = 1.0
        thisBoiler.BoilerInletNodeNum = Node.GetOnlySingleNode(state, boilerWaterInletNodeName, ErrorsFound, Node.ConnectionObjectType.BoilerHotWater, boilerName, Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        thisBoiler.BoilerOutletNodeNum = Node.GetOnlySingleNode(state, boilerWaterOutletNodeName, ErrorsFound, Node.ConnectionObjectType.BoilerHotWater, boilerName, Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        Node.TestCompSet(state, s_ipsc.cCurrentModuleObject, boilerName, boilerWaterInletNodeName, boilerWaterOutletNodeName, "Hot Water Nodes")
        if boilerFlowMode == "CONSTANTFLOW":
            thisBoiler.FlowMode = DataPlant.FlowMode.Constant
        elif boilerFlowMode == "LEAVINGSETPOINTMODULATED":
            thisBoiler.FlowMode = DataPlant.FlowMode.LeavingSetpointModulated
        elif boilerFlowMode == "NOTMODULATED" or boilerFlowMode.empty():
            thisBoiler.FlowMode = DataPlant.FlowMode.NotModulated
        else:
            ShowSevereError(state, "{}{}=\"{}\"".format(RoutineName, s_ipsc.cCurrentModuleObject, boilerName))
            ShowContinueError(state, "Invalid {}={}".format("Boiler Flow Mode", boilerFlowMode))
            ShowContinueError(state, "Available choices are ConstantFlow, NotModulated, or LeavingSetpointModulated")
            ShowContinueError(state, "Flow mode NotModulated is assumed and the simulation continues.")
            thisBoiler.FlowMode = DataPlant.FlowMode.NotModulated
        if "end_use_subcategory" in boilerFields:
            thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
        else:
            thisBoiler.EndUseSubcategory = "Boiler"
    if ErrorsFound:
        ShowFatalError(state, "{}{}".format(RoutineName, "Errors found in processing " + s_ipsc.cCurrentModuleObject + " input."))
struct BoilersData(BaseGlobalStruct):
    var getBoilerInputFlag: Bool = True
    var Boiler: List[Boilers.BoilerSpecs] = List[Boilers.BoilerSpecs]()
    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self = BoilersData()