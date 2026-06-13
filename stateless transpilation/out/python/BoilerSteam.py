# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (state.dataBoilerSteam, state.dataLoopNodes, state.dataSize, state.dataPlnt, state.dataGlobal, state.dataIPShortCut, state.dataInputProcessing, state.dataHVACGlobal, state.dataOutRptPredefined)
# - PlantComponent: base class stub
# - BaseGlobalStruct: base class for BoilerSteamData
# - PlantLocation: struct with loop, branch, side
# - DataPlant: module with CompData, PlantEquipmentType, LoopDemandCalcScheme, FlowLock
# - DataBranchAirLoopPlant: module with ControlType enum, MassFlowTolerance
# - Constant: module with eFuel, eFuelNames, eFuelNamesUC, Units, eResource, eFuel2eResource
# - HVAC: module with SmallWaterVolFlow, CtrlVarType
# - Node: module with GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent, SensedNodeFlagValue
# - Fluid: module with GetSteam, RefrigProps
# - PlantUtilities: module with ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode
# - GlobalNames: module with VerifyUniqueBoilerName
# - InputProcessor: for parsing input
# - OutputProcessor: module with SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
# - OutputReportPredefined: module with PreDefTableEntry
# - BaseSizer: module with reportSizerOutput
# - EMSManager: module with CheckIfNodeSetPointManagedByEMS
# - UtilityRoutines: module with ShowFatalError, ShowSevereError, etc.
# - Util: module with makeUPPER
# - DataSizing: module with AutoSize

from typing import Optional, List, Any, Protocol
from dataclasses import dataclass, field
import math

class PlantComponent:
    pass

class BaseGlobalStruct:
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        pass

@dataclass
class BoilerSpecs(PlantComponent):
    Name: str = ""
    FuelType: Any = None
    Available: bool = False
    ON: bool = False
    MissingSetPointErrDone: bool = False
    UseLoopSetPoint: bool = False
    DesMassFlowRate: float = 0.0
    MassFlowRate: float = 0.0
    NomCap: float = 0.0
    NomCapWasAutoSized: bool = False
    NomEffic: float = 0.0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    OperPartLoadRat: float = 0.0
    TempUpLimitBoilerOut: float = 0.0
    BoilerMaxOperPress: float = 0.0
    BoilerPressCheck: float = 0.0
    SizFac: float = 0.0
    BoilerInletNodeNum: int = 0
    BoilerOutletNodeNum: int = 0
    FullLoadCoef: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    TypeNum: int = 0
    plantLoc: Any = None
    PressErrIndex: int = 0
    fluid: Optional[Any] = None
    EndUseSubcategory: str = ""
    myFlag: bool = True
    myEnvrnFlag: bool = True
    FuelUsed: float = 0.0
    BoilerLoad: float = 0.0
    BoilerEff: float = 0.0
    BoilerMassFlowRate: float = 0.0
    BoilerOutletTemp: float = 0.0
    BoilerEnergy: float = 0.0
    FuelConsumed: float = 0.0
    BoilerInletTemp: float = 0.0
    
    def initialize(self, state: Any) -> None:
        if self.myFlag:
            self.setupOutputVars(state)
            self.oneTimeInit(state)
            self.myFlag = False
        
        if (state.dataGlobal.BeginEnvrnFlag and self.myEnvrnFlag and 
            state.dataPlnt.PlantFirstSizesOkayToFinalize):
            self.initEachEnvironment(state)
            self.myEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True
        
        if self.UseLoopSetPoint:
            BoilerOutletNode = self.BoilerOutletNodeNum
            from DataPlant import LoopDemandCalcScheme
            
            if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPoint = \
                    state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPoint
            elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPointLo = \
                    state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPointLo
    
    def setupOutputVars(self, state: Any) -> None:
        from Constant import eFuelNames, eResource, Units
        from OutputProcessor import TimeStepType, StoreType, Group, EndUseCat
        
        sFuelType = eFuelNames[int(self.FuelType)]
        
        SetupOutputVariable(state, "Boiler Heating Rate", Units.W, self.BoilerLoad,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler Heating Energy", Units.J, self.BoilerEnergy,
                          TimeStepType.System, StoreType.Sum, self.Name,
                          eResource.EnergyTransfer, Group.Plant, EndUseCat.Boilers)
        
        SetupOutputVariable(state, f"Boiler {sFuelType} Rate", Units.W, self.FuelUsed,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        from Constant import eFuel2eResource
        SetupOutputVariable(state, f"Boiler {sFuelType} Energy", Units.J, self.FuelConsumed,
                          TimeStepType.System, StoreType.Sum, self.Name,
                          eFuel2eResource[int(self.FuelType)], Group.Plant, EndUseCat.Heating,
                          self.EndUseSubcategory)
        
        SetupOutputVariable(state, "Boiler Steam Efficiency", Units.None, self.BoilerEff,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler Steam Inlet Temperature", Units.C, self.BoilerInletTemp,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler Steam Outlet Temperature", Units.C, self.BoilerOutletTemp,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler Steam Mass Flow Rate", Units.kg_s, self.BoilerMassFlowRate,
                          TimeStepType.System, StoreType.Average, self.Name)
    
    def autosize(self, state: Any) -> None:
        from DataPlant import PlantFirstSizesOkayToFinalize, PlantFinalSizesOkayToReport, PlantFirstSizesOkayToReport
        from BaseSizer import reportSizerOutput
        from OutputReportPredefined import PreDefTableEntry
        from UtilityRoutines import ShowSevereError, ShowFatalError, ShowContinueError, ShowMessage
        from HVAC import SmallWaterVolFlow
        from DataSizing import AutoSize
        
        ErrorsFound = False
        tmpNomCap = self.NomCap
        PltSizNum = self.plantLoc.loop.PlantSizNum
        
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                SizingTemp = self.TempUpLimitBoilerOut
                SteamDensity = self.fluid.getSatDensity(state, SizingTemp, 1.0, "SizeBoiler")
                EnthSteamOutDry = self.fluid.getSatEnthalpy(state, SizingTemp, 1.0, "SizeBoiler")
                EnthSteamOutWet = self.fluid.getSatEnthalpy(state, SizingTemp, 0.0, "SizeBoiler")
                LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                CpWater = self.fluid.getSatSpecificHeat(state, SizingTemp, 0.0, "SizeBoiler")
                tmpNomCap = (CpWater * SteamDensity * self.SizFac * 
                            state.dataSize.PlantSizData[PltSizNum - 1].DeltaT *
                            state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate +
                            state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate * SteamDensity * LatentEnthSteam)
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        reportSizerOutput(state, "Boiler:Steam", self.Name, 
                                        "Design Size Nominal Capacity [W]", tmpNomCap)
                        
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, self.Name, "Boiler:Steam")
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, self.Name, self.NomCap)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, self.Name, self.NomEffic)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, self.Name, self.NomCap)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, self.Name, self.NomEffic)
                        PlantLoopName = self.plantLoc.loop.Name if self.plantLoc.loop else "N/A"
                        BranchName = self.plantLoc.branch.Name if self.plantLoc.branch else "N/A"
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, PlantLoopName)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, BranchName)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                        from Constant import eFuelNames
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name,
                                       eFuelNames[int(self.FuelType)])
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                    
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        reportSizerOutput(state, "Boiler:Steam", self.Name,
                                        "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        NomCapUser = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            reportSizerOutput(state, "Boiler:Steam", self.Name,
                                            "Design Size Nominal Capacity [W]", tmpNomCap,
                                            "User-Specified Nominal Capacity [W]", NomCapUser)
                            
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, self.Name, "Boiler:Steam")
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, self.Name, self.NomCap)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, self.Name, self.NomEffic)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, self.Name, self.NomCap)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, self.Name, self.NomEffic)
                            PlantLoopName = self.plantLoc.loop.Name if self.plantLoc.loop else "N/A"
                            BranchName = self.plantLoc.branch.Name if self.plantLoc.branch else "N/A"
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, PlantLoopName)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, BranchName)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                            from Constant import eFuelNames
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name,
                                           eFuelNames[int(self.FuelType)])
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                            
                            if state.dataGlobal.DisplayExtraWarnings:
                                if abs(tmpNomCap - NomCapUser) / NomCapUser > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, f"SizePump: Potential issue with equipment sizing for {self.Name}")
                                    ShowContinueError(state, f"User-Specified Nominal Capacity of {NomCapUser:.2f} [W]")
                                    ShowContinueError(state, f"differs from Design Size Nominal Capacity of {tmpNomCap:.2f} [W]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Boiler nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, f"Occurs in Boiler:Steam object={self.Name}")
                ErrorsFound = True
            if not self.NomCapWasAutoSized and self.NomCap > 0.0 and state.dataPlnt.PlantFinalSizesOkayToReport:
                reportSizerOutput(state, "Boiler:Steam", self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "Boiler:Steam")
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.NomEffic)
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.NomCap)
        
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    
    def calculate(self, state: Any, MyLoad: float, RunFlag: bool, EquipFlowCtrl: Any) -> None:
        from DataPlant import LoopDemandCalcScheme, FlowLock
        from DataBranchAirLoopPlant import MassFlowTolerance
        from PlantUtilities import SetComponentFlowRate
        from UtilityRoutines import ShowSevereError, ShowContinueError, ShowRecurringSevereErrorAtEnd
        
        BoilerDeltaTemp = 0.0
        CpWater = 0.0
        
        self.BoilerLoad = 0.0
        self.BoilerMassFlowRate = 0.0
        
        if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
        
        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl.SeriesActive:
                self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            return
        
        self.BoilerLoad = MyLoad
        
        self.BoilerPressCheck = self.fluid.getSatPressure(state, self.BoilerOutletTemp, "CalcBoilerModel")
        
        if self.BoilerPressCheck > self.BoilerMaxOperPress:
            if self.PressErrIndex == 0:
                ShowSevereError(state, f"Boiler:Steam=\"{self.Name}\", Saturation Pressure is greater than Maximum Operating Pressure,")
                ShowContinueError(state, "Lower Input Temperature")
                ShowContinueError(state, f"Steam temperature=[{self.BoilerOutletTemp:.2f}] C")
                ShowContinueError(state, f"Refrigerant Saturation Pressure =[{self.BoilerPressCheck:.0f}] Pa")
            ShowRecurringSevereErrorAtEnd(state,
                                        f"Boiler:Steam=\"{self.Name}\", Saturation Pressure is greater than Maximum Operating Pressure..continues",
                                        self.PressErrIndex,
                                        self.BoilerPressCheck,
                                        self.BoilerPressCheck,
                                        None,
                                        "[Pa]",
                                        "[Pa]")
        
        CpWater = self.fluid.getSatSpecificHeat(state, state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp, 0.0, "CalcBoilerModel")
        
        if self.plantLoc.side.FlowLock == FlowLock.Unlocked:
            if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint -
                                  state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp)
            else:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo -
                                  state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp)
            
            self.BoilerOutletTemp = BoilerDeltaTemp + state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            
            EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
            EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
            LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
            self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + (CpWater * BoilerDeltaTemp))
            
            SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                               self.BoilerOutletNodeNum, self.plantLoc)
        else:
            self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            
            if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint -
                                  state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp)
            elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo -
                                  state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp)
            
            if BoilerDeltaTemp < 0.0:
                if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = self.BoilerMassFlowRate * LatentEnthSteam
            else:
                if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = (abs(self.BoilerMassFlowRate * LatentEnthSteam) +
                                  abs(self.BoilerMassFlowRate * CpWater * BoilerDeltaTemp))
            
            if self.BoilerLoad > MyLoad:
                self.BoilerLoad = MyLoad
                
                if self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif self.plantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                BoilerDeltaTemp = self.BoilerOutletTemp - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
                self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                
                SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                                   self.BoilerOutletNodeNum, self.plantLoc)
            
            if self.BoilerLoad > self.NomCap:
                if self.BoilerMassFlowRate > MassFlowTolerance:
                    self.BoilerLoad = self.NomCap
                    
                    EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                    EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                    LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                    BoilerDeltaTemp = self.BoilerOutletTemp - state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
                    self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                    
                    SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                                       self.BoilerOutletNodeNum, self.plantLoc)
                else:
                    self.BoilerLoad = 0.0
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        
        if self.BoilerOutletTemp > self.TempUpLimitBoilerOut:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        
        OperPLR = self.BoilerLoad / self.NomCap
        OperPLR = min(OperPLR, self.MaxPartLoadRat)
        OperPLR = max(OperPLR, self.MinPartLoadRat)
        TheorFuelUse = self.BoilerLoad / self.NomEffic
        
        self.FuelUsed = TheorFuelUse / (self.FullLoadCoef[0] + self.FullLoadCoef[1] * OperPLR + 
                                        self.FullLoadCoef[2] * OperPLR * OperPLR)
        self.BoilerEff = self.BoilerLoad / self.FuelUsed if self.FuelUsed != 0.0 else 0.0
    
    def update(self, state: Any, MyLoad: float, RunFlag: bool, FirstHVACIteration: bool) -> None:
        from PlantUtilities import SafeCopyPlantNode
        
        ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
        BoilerInletNode = self.BoilerInletNodeNum
        BoilerOutletNode = self.BoilerOutletNodeNum
        
        if MyLoad <= 0.0 or not RunFlag:
            SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
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
            SafeCopyPlantNode(state, BoilerInletNode, BoilerOutletNode)
            state.dataLoopNodes.Node[BoilerOutletNode].Temp = self.BoilerOutletTemp
            state.dataLoopNodes.Node[BoilerInletNode].Press = self.BoilerPressCheck
            state.dataLoopNodes.Node[BoilerOutletNode].Press = state.dataLoopNodes.Node[BoilerInletNode].Press
            state.dataLoopNodes.Node[BoilerOutletNode].Quality = 1.0
        
        self.BoilerInletTemp = state.dataLoopNodes.Node[BoilerInletNode].Temp
        self.BoilerMassFlowRate = state.dataLoopNodes.Node[BoilerOutletNode].MassFlowRate
        self.BoilerEnergy = self.BoilerLoad * ReportingConstant
        self.FuelConsumed = self.FuelUsed * ReportingConstant
    
    def simulate(self, state: Any, calledFromLocation: Any, FirstHVACIteration: bool, 
                CurLoad: float, RunFlag: bool) -> None:
        from DataPlant import CompData
        
        self.initialize(state)
        sim_component = CompData.getPlantComponent(state, self.plantLoc)
        self.calculate(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.update(state, CurLoad, RunFlag, FirstHVACIteration)
    
    def getDesignCapacities(self, state: Any, calledFromLocation: Any) -> tuple:
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat
        return MaxLoad, MinLoad, OptLoad
    
    def getSizingFactor(self) -> float:
        return self.SizFac
    
    def oneTimeInit(self, state: Any) -> None:
        from PlantUtilities import ScanPlantLoopsForObject
        from DataPlant import PlantEquipmentType
        from UtilityRoutines import ShowFatalError
        
        errFlag = False
        ScanPlantLoopsForObject(state, self.Name, PlantEquipmentType.Boiler_Steam, 
                               self.plantLoc, errFlag)
        if errFlag:
            ShowFatalError(state, "InitBoiler: Program terminated due to previous condition(s).")
    
    def initEachEnvironment(self, state: Any) -> None:
        from Node import SensedNodeFlagValue
        from EMSManager import CheckIfNodeSetPointManagedByEMS
        from HVAC import CtrlVarType
        from UtilityRoutines import ShowWarningError, ShowContinueError
        
        BoilerInletNode = self.BoilerInletNodeNum
        
        EnthSteamOutDry = self.fluid.getSatEnthalpy(state, self.TempUpLimitBoilerOut, 1.0, 
                                                   "BoilerSpecs::initEachEnvironment")
        EnthSteamOutWet = self.fluid.getSatEnthalpy(state, self.TempUpLimitBoilerOut, 0.0,
                                                   "BoilerSpecs::initEachEnvironment")
        LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
        
        CpWater = self.fluid.getSatSpecificHeat(state, self.TempUpLimitBoilerOut, 0.0,
                                               "BoilerSpecs::initEachEnvironment")
        
        self.DesMassFlowRate = (self.NomCap / 
                               (LatentEnthSteam + CpWater * 
                                (self.TempUpLimitBoilerOut - state.dataLoopNodes.Node[BoilerInletNode].Temp)))
        
        from PlantUtilities import InitComponentNodes
        InitComponentNodes(state, 0.0, self.DesMassFlowRate, self.BoilerInletNodeNum,
                          self.BoilerOutletNodeNum)
        
        self.BoilerPressCheck = 0.0
        self.FuelUsed = 0.0
        self.BoilerLoad = 0.0
        self.BoilerEff = 0.0
        self.BoilerOutletTemp = 0.0
        
        if ((state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint == SensedNodeFlagValue) and
            (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo == SensedNodeFlagValue)):
            
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.MissingSetPointErrDone:
                    ShowWarningError(state, f"Missing temperature setpoint for Boiler:Steam = {self.Name}")
                    ShowContinueError(state, " A temperature setpoint is needed at the outlet node of the boiler, use a SetpointManager")
                    ShowContinueError(state, " The overall loop setpoint will be assumed for this boiler. The simulation continues ...")
                    self.MissingSetPointErrDone = True
            else:
                FatalError = False
                CheckIfNodeSetPointManagedByEMS(state, self.BoilerOutletNodeNum, CtrlVarType.Temp, FatalError)
                state.dataLoopNodes.NodeSetpointCheck[self.BoilerOutletNodeNum].needsSetpointChecking = False
                if FatalError:
                    if not self.MissingSetPointErrDone:
                        ShowWarningError(state, f"Missing temperature setpoint for LeavingSetpointModulated mode Boiler named {self.Name}")
                        ShowContinueError(state, " A temperature setpoint is needed at the outlet node of the boiler.")
                        ShowContinueError(state, " Use a Setpoint Manager to establish a setpoint at the boiler outlet node ")
                        ShowContinueError(state, " or use an EMS actuator to establish a setpoint at the boiler outlet node.")
                        ShowContinueError(state, " The overall loop setpoint will be assumed for this boiler. The simulation continues...")
                        self.MissingSetPointErrDone = True
            
            self.UseLoopSetPoint = True
    
    def onInitLoopEquip(self, state: Any, calledFromLocation: Any) -> None:
        self.initialize(state)
        self.autosize(state)
    
    @staticmethod
    def factory(state: Any, objectName: str) -> Optional['BoilerSpecs']:
        if state.dataBoilerSteam.getSteamBoilerInput:
            GetBoilerInput(state)
            state.dataBoilerSteam.getSteamBoilerInput = False
        
        for boiler in state.dataBoilerSteam.Boiler:
            if boiler.Name == objectName:
                return boiler
        
        from UtilityRoutines import ShowFatalError
        ShowFatalError(state, f"LocalBoilerSteamFactory: Error getting inputs for steam boiler named: {objectName}")
        return None

@dataclass
class BoilerSteamData(BaseGlobalStruct):
    getSteamBoilerInput: bool = True
    Boiler: List[BoilerSpecs] = field(default_factory=list)
    
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        self.__init__()

def GetBoilerInput(state: Any) -> None:
    from UtilityRoutines import ShowSevereError, ShowWarningMessage, ShowContinueError, ShowFatalError
    from GlobalNames import VerifyUniqueBoilerName
    from Constant import eFuelNamesUC, eFuel
    from Node import GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
    from Fluid import GetSteam
    from DataSizing import AutoSize
    from Util import makeUPPER
    
    ErrorsFound = False
    
    state.dataIPShortCut.cCurrentModuleObject = "Boiler:Steam"
    inputProcessor = state.dataInputProcessing.inputProcessor
    numBoilers = inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    
    if numBoilers <= 0:
        ShowSevereError(state, f"No {state.dataIPShortCut.cCurrentModuleObject} equipment specified in input file")
        ErrorsFound = True
    
    if len(state.dataBoilerSteam.Boiler) > 0:
        return
    
    state.dataBoilerSteam.Boiler = [BoilerSpecs() for _ in range(numBoilers)]
    
    boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    boilerObjects = inputProcessor.epJSON.get(state.dataIPShortCut.cCurrentModuleObject, {})
    
    BoilerNum = 0
    for boilerName_orig, boilerFields in boilerObjects.items():
        boilerName = makeUPPER(boilerName_orig)
        fuelType = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
        waterInletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "water_inlet_node_name")
        steamOutletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "steam_outlet_node_name")
        
        inputProcessor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, boilerName_orig)
        
        VerifyUniqueBoilerName(state, state.dataIPShortCut.cCurrentModuleObject, boilerName, ErrorsFound,
                              state.dataIPShortCut.cCurrentModuleObject + " Name")
        
        thisBoiler = state.dataBoilerSteam.Boiler[BoilerNum]
        thisBoiler.Name = boilerName
        
        thisBoiler.FuelType = eFuel[fuelType.upper()]
        
        thisBoiler.BoilerMaxOperPress = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_operating_pressure")
        if thisBoiler.BoilerMaxOperPress < 1e5:
            ShowWarningMessage(state, f"{state.dataIPShortCut.cCurrentModuleObject}=\"{boilerName}\"")
            ShowContinueError(state, "Field: Maximum Operation Pressure units are Pa. Verify units.")
        
        thisBoiler.NomEffic = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "theoretical_efficiency")
        thisBoiler.TempUpLimitBoilerOut = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "design_outlet_steam_temperature")
        thisBoiler.NomCap = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_capacity")
        if thisBoiler.NomCap == AutoSize:
            thisBoiler.NomCapWasAutoSized = True
        
        thisBoiler.MinPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "minimum_part_load_ratio")
        thisBoiler.MaxPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_part_load_ratio")
        thisBoiler.OptPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "optimum_part_load_ratio")
        thisBoiler.FullLoadCoef[0] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, 
                                                                      "coefficient_1_of_fuel_use_function_of_part_load_ratio_curve")
        thisBoiler.FullLoadCoef[1] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps,
                                                                      "coefficient_2_of_fuel_use_function_of_part_load_ratio_curve")
        thisBoiler.FullLoadCoef[2] = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps,
                                                                      "coefficient_3_of_fuel_use_function_of_part_load_ratio_curve")
        thisBoiler.SizFac = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "sizing_factor")
        if thisBoiler.SizFac <= 0.0:
            thisBoiler.SizFac = 1.0
        
        if (thisBoiler.FullLoadCoef[0] + thisBoiler.FullLoadCoef[1] + thisBoiler.FullLoadCoef[2]) == 0.0:
            ShowSevereError(state, f"GetBoilerInput: {state.dataIPShortCut.cCurrentModuleObject}=\"{boilerName}\",")
            ShowContinueError(state, " Sum of fuel use curve coefficients = 0.0")
            ErrorsFound = True
        
        if thisBoiler.MinPartLoadRat < 0.0:
            ShowSevereError(state, f"GetBoilerInput: {state.dataIPShortCut.cCurrentModuleObject}=\"{boilerName}\",")
            ShowContinueError(state, f"Invalid Minimum Part Load Ratio={thisBoiler.MinPartLoadRat:.3f}")
            ErrorsFound = True
        
        if thisBoiler.TempUpLimitBoilerOut == 0.0:
            ShowSevereError(state, f"GetBoilerInput: {state.dataIPShortCut.cCurrentModuleObject}=\"{boilerName}\",")
            ShowContinueError(state, f"Invalid Design Outlet Steam Temperature={thisBoiler.TempUpLimitBoilerOut:.3f}")
            ErrorsFound = True
        
        thisBoiler.BoilerInletNodeNum = Node.GetOnlySingleNode(state, waterInletNodeName, ErrorsFound,
                                                               ConnectionObjectType.BoilerSteam, boilerName,
                                                               FluidType.Steam, ConnectionType.Inlet,
                                                               CompFluidStream.Primary, ObjectIsNotParent)
        thisBoiler.BoilerOutletNodeNum = Node.GetOnlySingleNode(state, steamOutletNodeName, ErrorsFound,
                                                                ConnectionObjectType.BoilerSteam, boilerName,
                                                                FluidType.Steam, ConnectionType.Outlet,
                                                                CompFluidStream.Primary, ObjectIsNotParent)
        
        Node.TestCompSet(state, state.dataIPShortCut.cCurrentModuleObject, boilerName,
                        waterInletNodeName, steamOutletNodeName, "Hot Steam Nodes")
        
        thisBoiler.fluid = GetSteam(state)
        if thisBoiler.fluid is None and BoilerNum == 0:
            ShowSevereError(state, "Fluid Properties for STEAM not found.")
            ErrorsFound = True
        
        if "end_use_subcategory" in boilerFields:
            thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
        else:
            thisBoiler.EndUseSubcategory = "General"
        
        BoilerNum += 1
    
    if ErrorsFound:
        ShowFatalError(state, f"GetBoilerInput: Errors found in processing {state.dataIPShortCut.cCurrentModuleObject} input.")

def SetupOutputVariable(state: Any, *args, **kwargs) -> None:
    pass

def ShowRecurringSevereErrorAtEnd(state: Any, message: str, errIndex: int, *args, **kwargs) -> None:
    pass
