from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Protocol, Any, List
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object container from EnergyPlus.Data.EnergyPlusData
# - PlantComponent: base class from EnergyPlus.PlantComponent
# - PlantLocation: struct from EnergyPlus.Plant.PlantLocation
# - DataPlant: enum/constant namespace from EnergyPlus.Plant.DataPlant
# - Constant: enum/constant namespace from EnergyPlus.DataGlobalConstants
# - Curve: namespace/struct from EnergyPlus.CurveManager
# - Node: functions from EnergyPlus.DataLoopNode
# - PlantUtilities: functions from EnergyPlus.PlantUtilities
# - CurveManager: functions from EnergyPlus.CurveManager
# - GlobalNames: functions from EnergyPlus.GlobalNames
# - OutputProcessor: functions/enums from EnergyPlus.OutputProcessor
# - DataBranchAirLoopPlant: enum from EnergyPlus.DataBranchAirLoopPlant
# - InputProcessor: functions from EnergyPlus.InputProcessing.InputProcessor
# - FaultsManager: data from EnergyPlus.FaultsManager
# - EMSManager: functions from EnergyPlus.EMSManager
# - HVAC: constants from EnergyPlus.DataHVACGlobals
# - OutputReportPredefined: functions from EnergyPlus.OutputReportPredefined
# - BaseSizer: functions from EnergyPlus.Autosizing.Base
# - BranchNodeConnections: functions from EnergyPlus.BranchNodeConnections


class TempMode(Enum):
    Invalid = -1
    NOTSET = 0
    ENTERINGBOILERTEMP = 1
    LEAVINGBOILERTEMP = 2
    Num = 3


@dataclass
class BoilerSpecs:
    Name: str = ""
    FuelType: Any = None
    Type: Any = None
    plantLoc: Any = None
    Available: bool = False
    ON: bool = False
    NomCap: float = 0.0
    NomCapWasAutoSized: bool = False
    NomEffic: float = 0.0
    TempDesBoilerOut: float = 0.0
    FlowMode: Any = None
    ModulatedFlowSetToLoop: bool = False
    ModulatedFlowErrDone: bool = False
    VolFlowRate: float = 0.0
    VolFlowRateWasAutoSized: bool = False
    DesMassFlowRate: float = 0.0
    MassFlowRate: float = 0.0
    SizFac: float = 0.0
    BoilerInletNodeNum: int = 0
    BoilerOutletNodeNum: int = 0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    OperPartLoadRat: float = 0.0
    CurveTempMode: TempMode = TempMode.NOTSET
    EfficiencyCurve: Optional[Any] = None
    TempUpLimitBoilerOut: float = 0.0
    ParasiticElecLoad: float = 0.0
    ParasiticFuelConsumption: float = 0.0
    ParasiticFuelRate: float = 0.0
    ParasiticFuelCapacity: float = 0.0
    EffCurveOutputError: int = 0
    EffCurveOutputIndex: int = 0
    CalculatedEffError: int = 0
    CalculatedEffIndex: int = 0
    IsThisSized: bool = False
    FaultyBoilerFoulingFlag: bool = False
    FaultyBoilerFoulingIndex: int = 0
    FaultyBoilerFoulingFactor: float = 1.0
    EndUseSubcategory: str = ""
    MyEnvrnFlag: bool = True
    MyFlag: bool = True
    FuelUsed: float = 0.0
    ParasiticElecPower: float = 0.0
    BoilerLoad: float = 0.0
    BoilerMassFlowRate: float = 0.0
    BoilerOutletTemp: float = 0.0
    BoilerPLR: float = 0.0
    BoilerEff: float = 0.0
    BoilerEnergy: float = 0.0
    FuelConsumed: float = 0.0
    BoilerInletTemp: float = 0.0
    ParasiticElecConsumption: float = 0.0

    def simulate(self, state: Any, calledFromLocation: Any, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        sim_component = DataPlant.CompData.getPlantComponent(state, self.plantLoc)
        self.InitBoiler(state)
        self.CalcBoilerModel(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.UpdateBoilerRecords(state, CurLoad, RunFlag)

    def getDesignCapacities(self, state: Any, calledFromLocation: Any) -> tuple:
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat
        return MaxLoad, MinLoad, OptLoad

    def getSizingFactor(self) -> float:
        return self.SizFac

    def onInitLoopEquip(self, state: Any, calledFromLocation: Any) -> None:
        self.InitBoiler(state)
        self.SizeBoiler(state)

    def SetupOutputVars(self, state: Any) -> None:
        sFuelType = Constant.eFuelNames[int(self.FuelType)]
        OutputProcessor.SetupOutputVariable(state, "Boiler Heating Rate", Constant.Units.W, self.BoilerLoad,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Heating Energy", Constant.Units.J, self.BoilerEnergy,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name,
                                           Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Boilers)
        OutputProcessor.SetupOutputVariable(state, f"Boiler {sFuelType} Rate", Constant.Units.W, self.FuelUsed,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, f"Boiler {sFuelType} Energy", Constant.Units.J, self.FuelConsumed,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name,
                                           Constant.eFuel2eResource[int(self.FuelType)], OutputProcessor.Group.Plant,
                                           OutputProcessor.EndUseCat.Heating, self.EndUseSubcategory)
        OutputProcessor.SetupOutputVariable(state, "Boiler Inlet Temperature", Constant.Units.C, self.BoilerInletTemp,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Outlet Temperature", Constant.Units.C, self.BoilerOutletTemp,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Mass Flow Rate", Constant.Units.kg_s, self.BoilerMassFlowRate,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Ancillary Electricity Rate", Constant.Units.W, self.ParasiticElecPower,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Ancillary Electricity Energy", Constant.Units.J, self.ParasiticElecConsumption,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name,
                                           Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating, "Boiler Parasitic")
        if self.FuelType != Constant.eFuel.Electricity:
            OutputProcessor.SetupOutputVariable(state, f"Boiler Ancillary {sFuelType} Rate", Constant.Units.W, self.ParasiticFuelRate,
                                               OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            OutputProcessor.SetupOutputVariable(state, f"Boiler Ancillary {sFuelType} Energy", Constant.Units.J, self.ParasiticFuelConsumption,
                                               OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name,
                                               Constant.eFuel2eResource[int(self.FuelType)], OutputProcessor.Group.Plant,
                                               OutputProcessor.EndUseCat.Heating, "Boiler Parasitic")
        OutputProcessor.SetupOutputVariable(state, "Boiler Part Load Ratio", Constant.Units.None, self.BoilerPLR,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        OutputProcessor.SetupOutputVariable(state, "Boiler Efficiency", Constant.Units.None, self.BoilerEff,
                                           OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            OutputProcessor.SetupEMSInternalVariable(state, "Boiler Nominal Capacity", self.Name, "[W]", self.NomCap)

    def oneTimeInit(self, state: Any) -> None:
        errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Boiler_Simple,
                                              self.plantLoc, errFlag, self.TempUpLimitBoilerOut)
        if errFlag:
            raise RuntimeError("InitBoiler: Program terminated due to previous condition(s).")

        if self.FlowMode in (DataPlant.FlowMode.LeavingSetpointModulated, DataPlant.FlowMode.Constant):
            DataPlant.CompData.getPlantComponent(state, self.plantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn

    def initEachEnvironment(self, state: Any) -> None:
        rho = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, "BoilerSpecs::initEachEnvironment")
        self.DesMassFlowRate = self.VolFlowRate * rho

        PlantUtilities.InitComponentNodes(state, 0.0, self.DesMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum)

        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
            if (state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPoint == Node.SensedNodeFlagValue and
                state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPointLo == Node.SensedNodeFlagValue):
                if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                    if not self.ModulatedFlowErrDone:
                        from utilities import ShowWarningError, ShowContinueError
                        ShowWarningError(state, f"Missing temperature setpoint for LeavingSetpointModulated mode Boiler named {self.Name}")
                        ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode, use a SetpointManager")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                        self.ModulatedFlowErrDone = True
                else:
                    FatalError = False
                    EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.BoilerOutletNodeNum, HVAC.CtrlVarType.Temp, FatalError)
                    state.dataLoopNodes.NodeSetpointCheck(self.BoilerOutletNodeNum).needsSetpointChecking = False
                    if FatalError:
                        if not self.ModulatedFlowErrDone:
                            from utilities import ShowWarningError, ShowContinueError
                            ShowWarningError(state, f"Missing temperature setpoint for LeavingSetpointModulated mode Boiler named {self.Name}")
                            ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode")
                            ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the boiler outlet node ")
                            ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the boiler outlet node ")
                            ShowContinueError(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                            self.ModulatedFlowErrDone = True
                self.ModulatedFlowSetToLoop = True

    def InitBoiler(self, state: Any) -> None:
        if self.MyFlag:
            self.SetupOutputVars(state)
            self.oneTimeInit(state)
            self.MyFlag = False

        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated and self.ModulatedFlowSetToLoop:
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPoint = \
                    state.dataLoopNodes.Node(self.plantLoc.loop.TempSetPointNodeNum).TempSetPoint
            else:
                state.dataLoopNodes.Node(self.BoilerOutletNodeNum).TempSetPointLo = \
                    state.dataLoopNodes.Node(self.plantLoc.loop.TempSetPointNodeNum).TempSetPointLo

    def SizeBoiler(self, state: Any) -> None:
        from utilities import ShowSevereError, ShowContinueError, ShowMessage, ShowFatalError
        ErrorsFound = False
        tmpNomCap = self.NomCap
        tmpBoilerVolFlowRate = self.VolFlowRate

        PltSizNum = self.plantLoc.loop.PlantSizNum

        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                rho = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, "SizeBoiler")
                Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "SizeBoiler")
                tmpNomCap = (Cp * rho * self.SizFac * state.dataSize.PlantSizData[PltSizNum].DeltaT *
                            state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate)
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
                        NomCapUser = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name,
                                                       "Design Size Nominal Capacity [W]", tmpNomCap,
                                                       "User-Specified Nominal Capacity [W]", NomCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if abs(tmpNomCap - NomCapUser) / NomCapUser > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, f"SizeBoilerHotWater: Potential issue with equipment sizing for {self.Name}")
                                    ShowContinueError(state, f"User-Specified Nominal Capacity of {NomCapUser:.2f} [W]")
                                    ShowContinueError(state, f"differs from Design Size Nominal Capacity of {tmpNomCap:.2f} [W]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, f"Occurs in Boiler object={self.Name}")
                ErrorsFound = True
            if not self.NomCapWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and self.NomCap > 0.0:
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
                        VolFlowRateUser = self.VolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name,
                                                       "Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate,
                                                       "User-Specified Design Water Flow Rate [m3/s]", VolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if abs(tmpBoilerVolFlowRate - VolFlowRateUser) / VolFlowRateUser > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, f"SizeBoilerHotWater: Potential issue with equipment sizing for {self.Name}")
                                    ShowContinueError(state, f"User-Specified Design Water Flow Rate of {VolFlowRateUser:.10g} [m3/s]")
                                    ShowContinueError(state, f"differs from Design Size Design Water Flow Rate of {tmpBoilerVolFlowRate:.10g} [m3/s]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpBoilerVolFlowRate = VolFlowRateUser
        else:
            if self.VolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler design flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, f"Occurs in Boiler object={self.Name}")
                ErrorsFound = True
            if not self.VolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and self.VolFlowRate > 0.0:
                BaseSizer.reportSizerOutput(state, "Boiler:HotWater", self.Name, "User-Specified Design Water Flow Rate [m3/s]", self.VolFlowRate)

        PlantUtilities.RegisterPlantCompDesignFlow(state, self.BoilerInletNodeNum, tmpBoilerVolFlowRate)

        if state.dataPlnt.PlantFinalSizesOkayToReport:
            equipName = self.Name
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, equipName, "Boiler:HotWater")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, equipName, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, equipName, self.NomCap)

            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, equipName, "Boiler:HotWater")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, equipName, self.NomEffic)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, equipName, self.NomCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, equipName, self.NomEffic)
            PlantloopName = self.plantLoc.loop.Name if self.plantLoc.loop is not None else "N/A"
            PlantloopBranchName = self.plantLoc.branch.Name if self.plantLoc.loop is not None else "N/A"
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, equipName, PlantloopName)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, equipName, PlantloopBranchName)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, equipName, self.MinPartLoadRat)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, equipName,
                                                   Constant.eFuelNames[int(self.FuelType)])
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, equipName, self.ParasiticElecLoad)

        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def CalcBoilerModel(self, state: Any, MyLoad: float, RunFlag: bool, EquipFlowCtrl: Any) -> None:
        from utilities import ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd, ShowContinueErrorTimeStamp

        self.BoilerLoad = 0.0
        self.ParasiticElecPower = 0.0
        self.BoilerMassFlowRate = 0.0

        BoilerInletNode = self.BoilerInletNodeNum
        BoilerOutletNode = self.BoilerOutletNodeNum
        BoilerNomCap = self.NomCap
        BoilerMaxPLR = self.MaxPartLoadRat
        BoilerMinPLR = self.MinPartLoadRat
        BoilerNomEff = self.NomEffic
        TempUpLimitBout = self.TempUpLimitBoilerOut
        BoilerMassFlowRateMax = self.DesMassFlowRate

        Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node(BoilerInletNode).Temp, "CalcBoilerModel")

        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive:
                self.BoilerMassFlowRate = state.dataLoopNodes.Node(BoilerInletNode).MassFlowRate
            return

        if (self.FaultyBoilerFoulingFlag and not state.dataGlobal.WarmupFlag and
            not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation):
            FaultIndex = self.FaultyBoilerFoulingIndex
            NomCap_ff = BoilerNomCap
            BoilerNomEff_ff = BoilerNomEff

            self.FaultyBoilerFoulingFactor = state.dataFaultsMgr.FaultsBoilerFouling[FaultIndex].CalFoulingFactor(state)

            BoilerNomCap = NomCap_ff * self.FaultyBoilerFoulingFactor
            BoilerNomEff = BoilerNomEff_ff * self.FaultyBoilerFoulingFactor

        self.BoilerLoad = MyLoad

        if self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
            if self.FlowMode in (DataPlant.FlowMode.Constant, DataPlant.FlowMode.NotModulated):
                self.BoilerMassFlowRate = BoilerMassFlowRateMax
                PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)

                if self.BoilerMassFlowRate != 0.0 and MyLoad > 0.0:
                    BoilerDeltaTemp = self.BoilerLoad / self.BoilerMassFlowRate / Cp
                else:
                    BoilerDeltaTemp = 0.0
                self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node(BoilerInletNode).Temp

            elif self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
                if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    BoilerDeltaTemp = (state.dataLoopNodes.Node(BoilerOutletNode).TempSetPoint -
                                      state.dataLoopNodes.Node(BoilerInletNode).Temp)
                else:
                    BoilerDeltaTemp = (state.dataLoopNodes.Node(BoilerOutletNode).TempSetPointLo -
                                      state.dataLoopNodes.Node(BoilerInletNode).Temp)

                self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node(BoilerInletNode).Temp

                if BoilerDeltaTemp > 0.0 and self.BoilerLoad > 0.0:
                    self.BoilerMassFlowRate = self.BoilerLoad / Cp / BoilerDeltaTemp
                    self.BoilerMassFlowRate = min(BoilerMassFlowRateMax, self.BoilerMassFlowRate)
                else:
                    self.BoilerMassFlowRate = 0.0
                PlantUtilities.SetComponentFlowRate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)

        else:
            self.BoilerMassFlowRate = state.dataLoopNodes.Node(BoilerInletNode).MassFlowRate

            if MyLoad > 0.0 and self.BoilerMassFlowRate > 0.0:
                self.BoilerLoad = MyLoad
                if self.BoilerLoad > BoilerNomCap * BoilerMaxPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMaxPLR
                if self.BoilerLoad < BoilerNomCap * BoilerMinPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMinPLR
                self.BoilerOutletTemp = (state.dataLoopNodes.Node(BoilerInletNode).Temp +
                                        self.BoilerLoad / (self.BoilerMassFlowRate * Cp))
            else:
                self.BoilerLoad = 0.0
                self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp

        if self.BoilerOutletTemp > TempUpLimitBout:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = state.dataLoopNodes.Node(BoilerInletNode).Temp

        self.BoilerPLR = self.BoilerLoad / BoilerNomCap
        self.BoilerPLR = min(self.BoilerPLR, BoilerMaxPLR)
        self.BoilerPLR = max(self.BoilerPLR, BoilerMinPLR)

        TheorFuelUse = self.BoilerLoad / BoilerNomEff
        EffCurveOutput = 1.0

        if self.EfficiencyCurve is not None:
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
                    ShowWarningError(state, f"Boiler:HotWater \"{self.Name}\"")
                    ShowContinueError(state, "...Normalized Boiler Efficiency Curve output is less than or equal to 0.")
                    ShowContinueError(state, f"...Curve input x value (PLR)     = {self.BoilerPLR:.5f}")
                    if self.EfficiencyCurve is not None and self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == TempMode.ENTERINGBOILERTEMP:
                            ShowContinueError(state, f"...Curve input y value (Tinlet) = {state.dataLoopNodes.Node(BoilerInletNode).Temp:.2f}")
                        elif self.CurveTempMode == TempMode.LEAVINGBOILERTEMP:
                            ShowContinueError(state, f"...Curve input y value (Toutlet) = {self.BoilerOutletTemp:.2f}")
                    ShowContinueError(state, f"...Curve output (normalized eff) = {EffCurveOutput:.5f}")
                    ShowContinueError(state,
                                     f"...Calculated Boiler efficiency  = {BoilerEff:.5f} (Boiler efficiency = Nominal Thermal Efficiency * "
                                     f"Normalized Boiler Efficiency Curve output)")
                    ShowContinueErrorTimeStamp(state, "...Curve output reset to 0.01 and simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state,
                                                  f"Boiler:HotWater \"{self.Name}\": Boiler Efficiency Curve output is less than or equal to 0 warning continues...",
                                                  self.EffCurveOutputIndex,
                                                  EffCurveOutput,
                                                  EffCurveOutput)
            EffCurveOutput = 0.01

        if not state.dataGlobal.WarmupFlag and BoilerEff > 1.1:
            if (self.BoilerLoad > 0.0 and self.EfficiencyCurve is not None and
                self.NomEffic <= 1.0):
                if self.CalculatedEffError < 1:
                    self.CalculatedEffError += 1
                    ShowWarningError(state, f"Boiler:HotWater \"{self.Name}\"")
                    ShowContinueError(state, "...Calculated Boiler Efficiency is greater than 1.1.")
                    ShowContinueError(state, "...Boiler Efficiency calculations shown below.")
                    ShowContinueError(state, f"...Curve input x value (PLR)     = {self.BoilerPLR:.5f}")
                    if self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == TempMode.ENTERINGBOILERTEMP:
                            ShowContinueError(state, f"...Curve input y value (Tinlet) = {state.dataLoopNodes.Node(BoilerInletNode).Temp:.2f}")
                        elif self.CurveTempMode == TempMode.LEAVINGBOILERTEMP:
                            ShowContinueError(state, f"...Curve input y value (Toutlet) = {self.BoilerOutletTemp:.2f}")
                    ShowContinueError(state, f"...Curve output (normalized eff) = {EffCurveOutput:.5f}")
                    ShowContinueError(state,
                                     f"...Calculated Boiler efficiency  = {BoilerEff:.5f} (Boiler efficiency = Nominal Thermal Efficiency * "
                                     f"Normalized Boiler Efficiency Curve output)")
                    ShowContinueErrorTimeStamp(state, "...Curve output reset to 1.1 and simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state,
                                                  f"Boiler:HotWater \"{self.Name}\": Calculated Boiler Efficiency is greater than 1.1 warning continues...",
                                                  self.CalculatedEffIndex,
                                                  BoilerEff,
                                                  BoilerEff)
            EffCurveOutput = 1.1

        self.FuelUsed = TheorFuelUse / EffCurveOutput
        if self.BoilerLoad > 0.0:
            self.ParasiticElecPower = self.ParasiticElecLoad * self.BoilerPLR
        self.ParasiticFuelRate = self.ParasiticFuelCapacity * (1.0 - self.BoilerPLR)
        self.BoilerEff = BoilerEff

    def UpdateBoilerRecords(self, state: Any, MyLoad: float, RunFlag: bool) -> None:
        ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
        BoilerInletNode = self.BoilerInletNodeNum
        BoilerOutletNode = self.BoilerOutletNodeNum

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
    def factory(state: Any, objectName: str) -> Optional['BoilerSpecs']:
        if state.dataBoilers.getBoilerInputFlag:
            GetBoilerInput(state)
            state.dataBoilers.getBoilerInputFlag = False

        for boiler in state.dataBoilers.Boiler:
            if boiler.Name == objectName:
                return boiler

        from utilities import ShowFatalError
        ShowFatalError(state, f"LocalBoilerFactory: Error getting inputs for boiler named: {objectName}")
        return None


@dataclass
class BoilersData:
    getBoilerInputFlag: bool = True
    Boiler: List[BoilerSpecs] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.getBoilerInputFlag = True
        self.Boiler = []


def GetBoilerInput(state: Any) -> None:
    from utilities import ShowSevereError, ShowContinueError, ShowWarningError, ShowFatalError, ShowSevereItemNotFound

    s_ipsc = state.dataIPShortCut
    ErrorsFound = False

    s_ipsc.cCurrentModuleObject = "Boiler:HotWater"
    numBoilers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)

    if numBoilers <= 0:
        ShowSevereError(state, f"No {s_ipsc.cCurrentModuleObject} Equipment specified in input file")
        ErrorsFound = True

    if state.dataBoilers.Boiler:
        return

    inputProcessor = state.dataInputProcessing.inputProcessor
    boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, s_ipsc.cCurrentModuleObject)
    boilerObjects = inputProcessor.epJSON.get(s_ipsc.cCurrentModuleObject, {}).items()

    for boilerInstance in boilerObjects:
        boilerFields = boilerInstance[1]
        boilerName = boilerInstance[0].upper()
        fuelType = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
        efficiencyCurveTempEvalVar = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "efficiency_curve_temperature_evaluation_variable")
        normalizedBoilerEfficiencyCurveName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "normalized_boiler_efficiency_curve_name")
        boilerWaterInletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_inlet_node_name")
        boilerWaterOutletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_outlet_node_name")
        boilerFlowMode = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_flow_mode")

        inputProcessor.markObjectAsUsed(s_ipsc.cCurrentModuleObject, boilerInstance[0])

        GlobalNames.VerifyUniqueBoilerName(state, s_ipsc.cCurrentModuleObject, boilerName, ErrorsFound, s_ipsc.cCurrentModuleObject + " Name")
        
        thisBoiler = BoilerSpecs()
        state.dataBoilers.Boiler.append(thisBoiler)
        thisBoiler.Name = boilerName
        thisBoiler.Type = DataPlant.PlantEquipmentType.Boiler_Simple

        thisBoiler.FuelType = Constant.eFuelNamesUC.get(fuelType, Constant.eFuel.Invalid)

        thisBoiler.NomCap = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_capacity")
        if thisBoiler.NomCap == 0.0:
            ShowSevereError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\",")
            ShowContinueError(state, f"Invalid Nominal Capacity={thisBoiler.NomCap:.2f}")
            ShowContinueError(state, "...Nominal Capacity must be greater than 0.0")
            ErrorsFound = True
        if thisBoiler.NomCap == DataSizing.AutoSize:
            thisBoiler.NomCapWasAutoSized = True

        thisBoiler.NomEffic = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_thermal_efficiency")
        if thisBoiler.NomEffic == 0.0:
            ShowSevereError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\",")
            ShowContinueError(state, f"Invalid Nominal Thermal Efficiency={thisBoiler.NomEffic:.3f}")
            ShowContinueError(state, "...Nominal Thermal Efficiency must be greater than 0.0")
            ErrorsFound = True
        elif thisBoiler.NomEffic > 1.0:
            ShowWarningError(state, f"Boiler:HotWater = {boilerName}: Nominal Thermal Efficiency={thisBoiler.NomEffic} should not typically be greater than 1.")

        if efficiencyCurveTempEvalVar == "ENTERINGBOILER":
            thisBoiler.CurveTempMode = TempMode.ENTERINGBOILERTEMP
        elif efficiencyCurveTempEvalVar == "LEAVINGBOILER":
            thisBoiler.CurveTempMode = TempMode.LEAVINGBOILERTEMP
        else:
            thisBoiler.CurveTempMode = TempMode.NOTSET

        if not normalizedBoilerEfficiencyCurveName:
            pass
        else:
            thisBoiler.EfficiencyCurve = CurveManager.GetCurve(state, normalizedBoilerEfficiencyCurveName)
            if thisBoiler.EfficiencyCurve is None:
                ShowSevereItemNotFound(state, "Boiler:HotWater", boilerName, "Normalized Boiler Efficiency Curve Name", normalizedBoilerEfficiencyCurveName)
                ErrorsFound = True
            elif thisBoiler.EfficiencyCurve.numDims not in (1, 2):
                Curve.ShowSevereCurveDims(state, "Boiler:HotWater", boilerName, "Normalized Boiler Efficiency Curve Name",
                                         normalizedBoilerEfficiencyCurveName, "1 or 2", thisBoiler.EfficiencyCurve.numDims)
                ErrorsFound = True
            elif thisBoiler.EfficiencyCurve.numDims == 2:
                if thisBoiler.CurveTempMode == TempMode.NOTSET:
                    if efficiencyCurveTempEvalVar:
                        ShowSevereError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\"")
                        ShowContinueError(state, f"Invalid Efficiency Curve Temperature Evaluation Variable={efficiencyCurveTempEvalVar}")
                        ShowContinueError(state, f"boilers.Boiler using curve type of {Curve.objectNames[int(thisBoiler.EfficiencyCurve.curveType)]} must specify Efficiency Curve Temperature Evaluation Variable")
                        ShowContinueError(state, "Available choices are EnteringBoiler or LeavingBoiler")
                    else:
                        ShowSevereError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\"")
                        ShowContinueError(state, "Field Efficiency Curve Temperature Evaluation Variable is blank")
                        ShowContinueError(state, f"boilers.Boiler using curve type of {Curve.objectNames[int(thisBoiler.EfficiencyCurve.curveType)]} must specify either EnteringBoiler or LeavingBoiler")
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

        def getOptionalNumericField(fieldName, defaultValue=0.0):
            if fieldName not in boilerFields:
                return defaultValue
            fieldValue = boilerFields[fieldName]
            if isinstance(fieldValue, (int, float)):
                return float(fieldValue)
            if isinstance(fieldValue, str) and not fieldValue:
                return defaultValue
            return defaultValue

        thisBoiler.ParasiticElecLoad = getOptionalNumericField("on_cycle_parasitic_electric_load")
        if thisBoiler.ParasiticElecLoad == 0.0:
            thisBoiler.ParasiticElecLoad = getOptionalNumericField("parasitic_electric_load")

        thisBoiler.ParasiticFuelCapacity = getOptionalNumericField("off_cycle_parasitic_fuel_load")
        if thisBoiler.FuelType == Constant.eFuel.Electricity and thisBoiler.ParasiticFuelCapacity > 0:
            ShowWarningError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\"")
            ShowContinueError(state, "Parasitic Fuel Capacity should be zero when the fuel type is electricity.")
            ShowContinueError(state, "It will be ignored and the simulation continues.")
            thisBoiler.ParasiticFuelCapacity = 0.0

        thisBoiler.SizFac = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "sizing_factor")
        if thisBoiler.SizFac == 0.0:
            thisBoiler.SizFac = 1.0

        thisBoiler.BoilerInletNodeNum = Node.GetOnlySingleNode(state, boilerWaterInletNodeName, ErrorsFound,
                                                              Node.ConnectionObjectType.BoilerHotWater, boilerName,
                                                              Node.FluidType.Water, Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        thisBoiler.BoilerOutletNodeNum = Node.GetOnlySingleNode(state, boilerWaterOutletNodeName, ErrorsFound,
                                                               Node.ConnectionObjectType.BoilerHotWater, boilerName,
                                                               Node.FluidType.Water, Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        Node.TestCompSet(state, s_ipsc.cCurrentModuleObject, boilerName, boilerWaterInletNodeName, boilerWaterOutletNodeName, "Hot Water Nodes")

        if boilerFlowMode == "CONSTANTFLOW":
            thisBoiler.FlowMode = DataPlant.FlowMode.Constant
        elif boilerFlowMode == "LEAVINGSETPOINTMODULATED":
            thisBoiler.FlowMode = DataPlant.FlowMode.LeavingSetpointModulated
        elif boilerFlowMode == "NOTMODULATED" or not boilerFlowMode:
            thisBoiler.FlowMode = DataPlant.FlowMode.NotModulated
        else:
            ShowSevereError(state, f"GetBoilerInput: Boiler:HotWater=\"{boilerName}\"")
            ShowContinueError(state, f"Invalid Boiler Flow Mode={boilerFlowMode}")
            ShowContinueError(state, "Available choices are ConstantFlow, NotModulated, or LeavingSetpointModulated")
            ShowContinueError(state, "Flow mode NotModulated is assumed and the simulation continues.")
            thisBoiler.FlowMode = DataPlant.FlowMode.NotModulated

        if "end_use_subcategory" in boilerFields:
            thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
        else:
            thisBoiler.EndUseSubcategory = "Boiler"

    if ErrorsFound:
        ShowFatalError(state, f"GetBoilerInput: Errors found in processing {s_ipsc.cCurrentModuleObject} input.")
