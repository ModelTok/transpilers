from ObjexxFCL.Array1D import Array1D
from .Data.BaseData import BaseGlobalStruct
from .DataBranchAirLoopPlant import DataBranchAirLoopPlant
from .DataGlobalConstants import Constant
from .DataGlobals import DataGlobals
from .EnergyPlus import EnergyPlus
from FluidProperties import Fluid
from .Plant.Enums import Plant
from .Plant.PlantLocation import PlantLocation
from .PlantComponent import PlantComponent
from UtilityRoutines import UtilityRoutines
from math import abs, min, max, pow
from ObjexxFCL.Array.functions import allocated
from .Autosizing.Base import BaseSizer
from BranchNodeConnections import Node
from .Data.EnergyPlusData import EnergyPlusData
from .DataBranchAirLoopPlant import DataBranchAirLoopPlant
from .DataGlobalConstants import Constant
from DataHVACGlobals import DataHVACGlobals
from .DataIPShortCuts import DataIPShortCuts
from .DataLoopNode import DataLoopNode
from DataSizing import DataSizing
from EMSManager import EMSManager
from FluidProperties import Fluid
from GlobalNames import GlobalNames
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor
from OutputReportPredefined import OutputReportPredefined
from .Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from UtilityRoutines import UtilityRoutines
struct BoilerSpecs(PlantComponent):
    var Name: String
    var FuelType: Constant.eFuel = Constant.eFuel.Invalid
    var Available: Bool = False
    var ON: Bool = False
    var MissingSetPointErrDone: Bool = False
    var UseLoopSetPoint: Bool = False
    var DesMassFlowRate: Float64 = 0.0
    var MassFlowRate: Float64 = 0.0
    var NomCap: Float64 = 0.0
    var NomCapWasAutoSized: Bool = False
    var NomEffic: Float64 = 0.0
    var MinPartLoadRat: Float64 = 0.0
    var MaxPartLoadRat: Float64 = 0.0
    var OptPartLoadRat: Float64 = 0.0
    var OperPartLoadRat: Float64 = 0.0
    var TempUpLimitBoilerOut: Float64 = 0.0
    var BoilerMaxOperPress: Float64 = 0.0
    var BoilerPressCheck: Float64 = 0.0
    var SizFac: Float64 = 0.0
    var BoilerInletNodeNum: Int = 0
    var BoilerOutletNodeNum: Int = 0
    var FullLoadCoef: StaticTuple[Float64, 3] = StaticTuple[Float64, 3](0.0, 0.0, 0.0)
    var TypeNum: Int = 0
    var plantLoc: PlantLocation
    var PressErrIndex: Int = 0
    var fluid: Fluid.RefrigProps = None
    var EndUseSubcategory: String
    var myFlag: Bool = True
    var myEnvrnFlag: Bool = True
    var FuelUsed: Float64 = 0.0
    var BoilerLoad: Float64 = 0.0
    var BoilerEff: Float64 = 0.0
    var BoilerMassFlowRate: Float64 = 0.0
    var BoilerOutletTemp: Float64 = 0.0
    var BoilerEnergy: Float64 = 0.0
    var FuelConsumed: Float64 = 0.0
    var BoilerInletTemp: Float64 = 0.0
    def __init__(inout self):

    def initialize(inout self, inout state: EnergyPlusData):
        if self.myFlag:
            self.setupOutputVars(state)
            self.oneTimeInit(state)
            self.myFlag = False
        if state.dataGlobal.BeginEnvrnFlag and self.myEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
            self.initEachEnvironment(state)
            self.myEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True
        if self.UseLoopSetPoint:
            var BoilerOutletNode: Int = self.BoilerOutletNodeNum
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPoint = state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPoint
            elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPointLo = state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPointLo
    def setupOutputVars(inout self, inout state: EnergyPlusData):
        var sFuelType: String = Constant.eFuelNames[Int(self.FuelType)]
        SetupOutputVariable(state, "Boiler Heating Rate", Constant.Units.W, self.BoilerLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Heating Energy", Constant.Units.J, self.BoilerEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Boilers)
        SetupOutputVariable(state, "Boiler " + sFuelType + " Rate", Constant.Units.W, self.FuelUsed, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler " + sFuelType + " Energy", Constant.Units.J, self.FuelConsumed, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eFuel2eResource[Int(self.FuelType)], OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating, self.EndUseSubcategory)
        SetupOutputVariable(state, "Boiler Steam Efficiency", Constant.Units.None, self.BoilerEff, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Steam Inlet Temperature", Constant.Units.C, self.BoilerInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Steam Outlet Temperature", Constant.Units.C, self.BoilerOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Boiler Steam Mass Flow Rate", Constant.Units.kg_s, self.BoilerMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    def autosize(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "SizeBoiler"
        var ErrorsFound: Bool = False
        var tmpNomCap: Float64 = self.NomCap
        var PltSizNum: Int = self.plantLoc.loop.PlantSizNum
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                var SizingTemp: Float64 = self.TempUpLimitBoilerOut
                var SteamDensity: Float64 = self.fluid.getSatDensity(state, SizingTemp, 1.0, RoutineName)
                var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, SizingTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, SizingTemp, 0.0, RoutineName)
                var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
                var CpWater: Float64 = self.fluid.getSatSpecificHeat(state, SizingTemp, 0.0, RoutineName)
                tmpNomCap = (CpWater * SteamDensity * self.SizFac * state.dataSize.PlantSizData[PltSizNum].DeltaT * state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate + state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate * SteamDensity * LatentEnthSteam)
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:Steam", self.Name, "Design Size Nominal Capacity [W]", tmpNomCap)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, self.Name, "Boiler:Steam")
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, self.Name, self.NomCap)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, self.Name, self.NomEffic)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, self.Name, self.NomCap)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, self.Name, self.NomEffic)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, (self.plantLoc.loop != None) ? self.plantLoc.loop.Name : "N/A")
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, (self.plantLoc.branch != None) ? self.plantLoc.branch.Name : "N/A")
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name, Constant.eFuelNames[Int(self.FuelType)])
                        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Boiler:Steam", self.Name, "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        var NomCapUser: Float64 = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "Boiler:Steam", self.Name, "Design Size Nominal Capacity [W]", tmpNomCap, "User-Specified Nominal Capacity [W]", NomCapUser)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, self.Name, "Boiler:Steam")
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, self.Name, self.NomCap)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, self.Name, self.NomEffic)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, self.Name, self.NomCap)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, self.Name, self.NomEffic)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, (self.plantLoc.loop != None) ? self.plantLoc.loop.Name : "N/A")
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, (self.plantLoc.branch != None) ? self.plantLoc.branch.Name : "N/A")
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name, Constant.eFuelNames[Int(self.FuelType)])
                            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpNomCap - NomCapUser) / NomCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, "SizePump: Potential issue with equipment sizing for " + self.Name)
                                    ShowContinueError(state, "User-Specified Nominal Capacity of " + str(NomCapUser) + " [W]")
                                    ShowContinueError(state, "differs from Design Size Nominal Capacity of " + str(tmpNomCap) + " [W]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, "Occurs in Boiler:Steam object=" + self.Name)
                ErrorsFound = True
            if not self.NomCapWasAutoSized and self.NomCap > 0.0 and state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, "Boiler:Steam", self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "Boiler:Steam")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.NomCap)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    def calculate(inout self, inout state: EnergyPlusData, inout MyLoad: Float64, RunFlag: Bool, EquipFlowCtrl: DataBranchAirLoopPlant.ControlType):
        var RoutineName: String = "CalcBoilerModel"
        var BoilerDeltaTemp: Float64 = 0.0
        var CpWater: Float64
        self.BoilerLoad = 0.0
        self.BoilerMassFlowRate = 0.0
        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive:
                self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            return
        self.BoilerLoad = MyLoad
        self.BoilerPressCheck = self.fluid.getSatPressure(state, self.BoilerOutletTemp, RoutineName)
        if (self.BoilerPressCheck) > self.BoilerMaxOperPress:
            if self.PressErrIndex == 0:
                ShowSevereError(state, "Boiler:Steam=\"" + self.Name + "\", Saturation Pressure is greater than Maximum Operating Pressure,")
                ShowContinueError(state, "Lower Input Temperature")
                ShowContinueError(state, "Steam temperature=[" + str(self.BoilerOutletTemp) + "] C")
                ShowContinueError(state, "Refrigerant Saturation Pressure =[" + str(self.BoilerPressCheck) + "] Pa")
            ShowRecurringSevereErrorAtEnd(state, "Boiler:Steam=\"" + self.Name + "\", Saturation Pressure is greater than Maximum Operating Pressure..continues", self.PressErrIndex, self.BoilerPressCheck, self.BoilerPressCheck, _, "[Pa]", "[Pa]")
        CpWater = self.fluid.getSatSpecificHeat(state, state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp, 0.0, RoutineName)
        if self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            else:
                BoilerDeltaTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, RoutineName)
            var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, RoutineName)
            var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
            self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + (CpWater * BoilerDeltaTemp))
            PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum, self.plantLoc)
        else:
            self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                BoilerDeltaTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            if BoilerDeltaTemp < 0.0:
                if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, RoutineName)
                var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = (self.BoilerMassFlowRate * LatentEnthSteam)
            else:
                if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, RoutineName)
                var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = abs(self.BoilerMassFlowRate * LatentEnthSteam) + abs(self.BoilerMassFlowRate * CpWater * BoilerDeltaTemp)
            if self.BoilerLoad > MyLoad:
                self.BoilerLoad = MyLoad
                if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, RoutineName)
                var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
                BoilerDeltaTemp = self.BoilerOutletTemp - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
                self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum, self.plantLoc)
            if self.BoilerLoad > self.NomCap:
                if self.BoilerMassFlowRate > DataBranchAirLoopPlant.MassFlowTolerance:
                    self.BoilerLoad = self.NomCap
                    var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, RoutineName)
                    var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, RoutineName)
                    var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
                    BoilerDeltaTemp = self.BoilerOutletTemp - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
                    self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                    PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum, self.plantLoc)
                else:
                    self.BoilerLoad = 0.0
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        if self.BoilerOutletTemp > self.TempUpLimitBoilerOut:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        var OperPLR: Float64 = self.BoilerLoad / self.NomCap
        OperPLR = min(OperPLR, self.MaxPartLoadRat)
        OperPLR = max(OperPLR, self.MinPartLoadRat)
        var TheorFuelUse: Float64 = self.BoilerLoad / self.NomEffic
        self.FuelUsed = TheorFuelUse / (self.FullLoadCoef[0] + self.FullLoadCoef[1] * OperPLR + self.FullLoadCoef[2] * pow(OperPLR, 2))
        self.BoilerEff = self.BoilerLoad / self.FuelUsed
    def update(inout self, inout state: EnergyPlusData, MyLoad: Float64, RunFlag: Bool, FirstHVACIteration: Bool):
        var ReportingConstant: Float64 = state.dataHVACGlobal.TimeStepSysSec
        var BoilerInletNode: Int = self.BoilerInletNodeNum
        var BoilerOutletNode: Int = self.BoilerOutletNodeNum
        if MyLoad <= 0.0 or not RunFlag:
            PlantUtilities.SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
            state.dataLoopNodes.Node[BoilerOutletNode].Temp = state.dataLoopNodes.Node[BoilerInletNode].Temp
            self.BoilerOutletTemp = state.dataLoopNodes.Node[BoilerInletNode].Temp
            self.BoilerLoad = 0.0
            self.FuelUsed = 0.0
            self.BoilerEff = 0.0
            state.dataLoopNodes.Node[BoilerInletNode].Press = self.BoilerPressCheck
            state.dataLoopNodes.Node[BoilerOutletNode].Press = state.dataLoopNodes.Node[BoilerInletNode].Press
            state.dataLoopNodes.Node[BoilerInletNode].Quality = 0.0
            state.dataLoopNodes.Node[BoilerOutletNode].Quality = state.dataLoopNodes.Node[BoilerInletNode].Quality
        else:
            PlantUtilities.SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
            state.dataLoopNodes.Node[BoilerOutletNode].Temp = self.BoilerOutletTemp
            state.dataLoopNodes.Node[BoilerInletNode].Press = self.BoilerPressCheck
            state.dataLoopNodes.Node[BoilerOutletNode].Press = state.dataLoopNodes.Node[BoilerInletNode].Press
            state.dataLoopNodes.Node[BoilerOutletNode].Quality = 1.0
        self.BoilerInletTemp = state.dataLoopNodes.Node[BoilerInletNode].Temp
        self.BoilerMassFlowRate = state.dataLoopNodes.Node[BoilerOutletNode].MassFlowRate
        self.BoilerEnergy = self.BoilerLoad * ReportingConstant
        self.FuelConsumed = self.FuelUsed * ReportingConstant
    def simulate(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        self.initialize(state)
        var sim_component = DataPlant.CompData.getPlantComponent(state, self.plantLoc)
        self.calculate(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.update(state, CurLoad, RunFlag, FirstHVACIteration)
    def getDesignCapacities(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Float64, inout MinLoad: Float64, inout OptLoad: Float64):
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat
    def getSizingFactor(inout self, inout sizFac: Float64):
        sizFac = self.SizFac
    def oneTimeInit(inout self, inout state: EnergyPlusData):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Boiler_Steam, self.plantLoc, errFlag, _, _, _, _, _)
        if errFlag:
            ShowFatalError(state, "InitBoiler: Program terminated due to previous condition(s).")
    def initEachEnvironment(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "BoilerSpecs::initEachEnvironment"
        var BoilerInletNode: Int = self.BoilerInletNodeNum
        var EnthSteamOutDry: Float64 = self.fluid.getSatEnthalpy(state, self.TempUpLimitBoilerOut, 1.0, RoutineName)
        var EnthSteamOutWet: Float64 = self.fluid.getSatEnthalpy(state, self.TempUpLimitBoilerOut, 0.0, RoutineName)
        var LatentEnthSteam: Float64 = EnthSteamOutDry - EnthSteamOutWet
        var CpWater: Float64 = self.fluid.getSatSpecificHeat(state, self.TempUpLimitBoilerOut, 0.0, RoutineName)
        self.DesMassFlowRate = self.NomCap / (LatentEnthSteam + CpWater * (self.TempUpLimitBoilerOut - state.dataLoopNodes.Node[BoilerInletNode].Temp))
        PlantUtilities.InitComponentNodes(state, 0.0, self.DesMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum)
        self.BoilerPressCheck = 0.0
        self.FuelUsed = 0.0
        self.BoilerLoad = 0.0
        self.BoilerEff = 0.0
        self.BoilerOutletTemp = 0.0
        if (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint == Node.SensedNodeFlagValue) and (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo == Node.SensedNodeFlagValue):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.MissingSetPointErrDone:
                    ShowWarningError(state, "Missing temperature setpoint for Boiler:Steam = " + self.Name)
                    ShowContinueError(state, " A temperature setpoint is needed at the outlet node of the boiler, use a SetpointManager")
                    ShowContinueError(state, " The overall loop setpoint will be assumed for this boiler. The simulation continues ...")
                    self.MissingSetPointErrDone = True
            else:
                var FatalError: Bool = False
                EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.BoilerOutletNodeNum, HVAC.CtrlVarType.Temp, FatalError)
                state.dataLoopNodes.NodeSetpointCheck[self.BoilerOutletNodeNum].needsSetpointChecking = False
                if FatalError:
                    if not self.MissingSetPointErrDone:
                        ShowWarningError(state, "Missing temperature setpoint for LeavingSetpointModulated mode Boiler named " + self.Name)
                        ShowContinueError(state, " A temperature setpoint is needed at the outlet node of the boiler.")
                        ShowContinueError(state, " Use a Setpoint Manager to establish a setpoint at the boiler outlet node ")
                        ShowContinueError(state, " or use an EMS actuator to establish a setpoint at the boiler outlet node.")
                        ShowContinueError(state, " The overall loop setpoint will be assumed for this boiler. The simulation continues...")
                        self.MissingSetPointErrDone = True
            self.UseLoopSetPoint = True
    def onInitLoopEquip(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.initialize(state)
        self.autosize(state)
    @staticmethod
    def factory(inout state: EnergyPlusData, objectName: String) -> BoilerSpecs:
        if state.dataBoilerSteam.getSteamBoilerInput:
            GetBoilerInput(state)
            state.dataBoilerSteam.getSteamBoilerInput = False
        for boiler in state.dataBoilerSteam.Boiler:
            if boiler.Name == objectName:
                return boiler
        ShowFatalError(state, "LocalBoilerSteamFactory: Error getting inputs for steam boiler named: " + objectName)
        return None
def GetBoilerInput(inout state: EnergyPlusData):
    var RoutineName: String = "GetBoilerInput: "
    var ErrorsFound: Bool = False
    state.dataIPShortCut.cCurrentModuleObject = "Boiler:Steam"
    var inputProcessor = state.dataInputProcessing.inputProcessor.get()
    var numBoilers: Int = inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if numBoilers <= 0:
        ShowSevereError(state, "No " + state.dataIPShortCut.cCurrentModuleObject + " equipment specified in input file")
        ErrorsFound = True
    if allocated(state.dataBoilerSteam.Boiler):
        return
    state.dataBoilerSteam.Boiler.allocate(numBoilers)
    var boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    var boilerObjects = inputProcessor.epJSON.find(state.dataIPShortCut.cCurrentModuleObject)
    if boilerObjects != inputProcessor.epJSON.end():
        var BoilerNum: Int = 1
        for boilerInstance in boilerObjects.value().items():
            var boilerFields = boilerInstance.value()
            var boilerName = Util.makeUPPER(boilerInstance.key())
            var fuelType = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
            var waterInletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "water_inlet_node_name")
            var steamOutletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "steam_outlet_node_name")
            inputProcessor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, boilerInstance.key())
            GlobalNames.VerifyUniqueBoilerName(state, state.dataIPShortCut.cCurrentModuleObject, boilerName, ErrorsFound, state.dataIPShortCut.cCurrentModuleObject + " Name")
            var thisBoiler = state.dataBoilerSteam.Boiler[BoilerNum]
            thisBoiler.Name = boilerName
            thisBoiler.FuelType = Constant.eFuel(getEnumValue(Constant.eFuelNamesUC, fuelType))
            thisBoiler.BoilerMaxOperPress = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_operating_pressure")
            if thisBoiler.BoilerMaxOperPress < 1e5:
                ShowWarningMessage(state, state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\"")
                ShowContinueError(state, "Field: Maximum Operation Pressure units are Pa. Verify units.")
            thisBoiler.NomEffic = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "theoretical_efficiency")
            thisBoiler.TempUpLimitBoilerOut = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "design_outlet_steam_temperature")
            thisBoiler.NomCap = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_capacity")
            if thisBoiler.NomCap == DataSizing.AutoSize:
                thisBoiler.NomCapWasAutoSized = True
            thisBoiler.MinPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "minimum_part_load_ratio")
            thisBoiler.MaxPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_part_load_ratio")
            thisBoiler.OptPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "optimum_part_load_ratio")
            thisBoiler.FullLoadCoef[0] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "coefficient_1_of_fuel_use_function_of_part_load_ratio_curve")
            thisBoiler.FullLoadCoef[1] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "coefficient_2_of_fuel_use_function_of_part_load_ratio_curve")
            thisBoiler.FullLoadCoef[2] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "coefficient_3_of_fuel_use_function_of_part_load_ratio_curve")
            thisBoiler.SizFac = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "sizing_factor")
            if thisBoiler.SizFac <= 0.0:
                thisBoiler.SizFac = 1.0
            if (thisBoiler.FullLoadCoef[0] + thisBoiler.FullLoadCoef[1] + thisBoiler.FullLoadCoef[2]) == 0.0:
                ShowSevereError(state, RoutineName + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
                ShowContinueError(state, " Sum of fuel use curve coefficients = 0.0")
                ErrorsFound = True
            if thisBoiler.MinPartLoadRat < 0.0:
                ShowSevereError(state, RoutineName + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
                ShowContinueError(state, "Invalid " + "Minimum Part Load Ratio" + "=" + str(thisBoiler.MinPartLoadRat))
                ErrorsFound = True
            if thisBoiler.TempUpLimitBoilerOut == 0.0:
                ShowSevereError(state, RoutineName + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
                ShowContinueError(state, "Invalid " + "Design Outlet Steam Temperature" + "=" + str(thisBoiler.TempUpLimitBoilerOut))
                ErrorsFound = True
            thisBoiler.BoilerInletNodeNum = Node.GetOnlySingleNode(state, waterInletNodeName, ErrorsFound, Node.ConnectionObjectType.BoilerSteam, boilerName, Node.FluidType.Steam, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            thisBoiler.BoilerOutletNodeNum = Node.GetOnlySingleNode(state, steamOutletNodeName, ErrorsFound, Node.ConnectionObjectType.BoilerSteam, boilerName, Node.FluidType.Steam, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            Node.TestCompSet(state, state.dataIPShortCut.cCurrentModuleObject, boilerName, waterInletNodeName, steamOutletNodeName, "Hot Steam Nodes")
            thisBoiler.fluid = Fluid.GetSteam(state)
            if thisBoiler.fluid == None and BoilerNum == 1:
                ShowSevereError(state, "Fluid Properties for STEAM not found.")
                ErrorsFound = True
            if boilerFields.find("end_use_subcategory") != boilerFields.end():
                thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
            else:
                thisBoiler.EndUseSubcategory = "General"
            BoilerNum += 1
    if ErrorsFound:
        ShowFatalError(state, RoutineName + "Errors found in processing " + state.dataIPShortCut.cCurrentModuleObject + " input.")
struct BoilerSteamData(BaseGlobalStruct):
    var getSteamBoilerInput: Bool = True
    var Boiler: Array1D[BoilerSpecs]
    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self = BoilerSteamData()