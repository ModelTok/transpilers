from math import pow
from typing import Optional

alias Real64 = Float64

struct PlantComponent:
    pass

struct BaseGlobalStruct:
    fn init_constant_state(inout self, state: Any) -> None:
        pass
    
    fn init_state(inout self, state: Any) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        pass

struct BoilerSpecs(PlantComponent):
    var Name: String
    var FuelType: UInt8
    var Available: Bool
    var ON: Bool
    var MissingSetPointErrDone: Bool
    var UseLoopSetPoint: Bool
    var DesMassFlowRate: Real64
    var MassFlowRate: Real64
    var NomCap: Real64
    var NomCapWasAutoSized: Bool
    var NomEffic: Real64
    var MinPartLoadRat: Real64
    var MaxPartLoadRat: Real64
    var OptPartLoadRat: Real64
    var OperPartLoadRat: Real64
    var TempUpLimitBoilerOut: Real64
    var BoilerMaxOperPress: Real64
    var BoilerPressCheck: Real64
    var SizFac: Real64
    var BoilerInletNodeNum: Int32
    var BoilerOutletNodeNum: Int32
    var FullLoadCoef: InlineArray[Real64, 3]
    var TypeNum: Int32
    var plantLoc: PlantLocation
    var PressErrIndex: Int32
    var fluid: Optional[RefrigProps]
    var EndUseSubcategory: String
    var myFlag: Bool
    var myEnvrnFlag: Bool
    var FuelUsed: Real64
    var BoilerLoad: Real64
    var BoilerEff: Real64
    var BoilerMassFlowRate: Real64
    var BoilerOutletTemp: Real64
    var BoilerEnergy: Real64
    var FuelConsumed: Real64
    var BoilerInletTemp: Real64
    
    fn __init__(inout self):
        self.Name = ""
        self.FuelType = 0
        self.Available = False
        self.ON = False
        self.MissingSetPointErrDone = False
        self.UseLoopSetPoint = False
        self.DesMassFlowRate = 0.0
        self.MassFlowRate = 0.0
        self.NomCap = 0.0
        self.NomCapWasAutoSized = False
        self.NomEffic = 0.0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.OperPartLoadRat = 0.0
        self.TempUpLimitBoilerOut = 0.0
        self.BoilerMaxOperPress = 0.0
        self.BoilerPressCheck = 0.0
        self.SizFac = 0.0
        self.BoilerInletNodeNum = 0
        self.BoilerOutletNodeNum = 0
        self.FullLoadCoef = InlineArray[Real64, 3](fill=0.0)
        self.TypeNum = 0
        self.PressErrIndex = 0
        self.fluid = None
        self.EndUseSubcategory = ""
        self.myFlag = True
        self.myEnvrnFlag = True
        self.FuelUsed = 0.0
        self.BoilerLoad = 0.0
        self.BoilerEff = 0.0
        self.BoilerMassFlowRate = 0.0
        self.BoilerOutletTemp = 0.0
        self.BoilerEnergy = 0.0
        self.FuelConsumed = 0.0
        self.BoilerInletTemp = 0.0
    
    fn initialize(inout self, state: Any) -> None:
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
            var BoilerOutletNode: Int32 = self.BoilerOutletNodeNum
            let scheme = self.plantLoc.loop.LoopDemandCalcScheme
            
            if scheme == LoopDemandCalcScheme.SingleSetPoint:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPoint = \
                    state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPoint
            elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                state.dataLoopNodes.Node[BoilerOutletNode].TempSetPointLo = \
                    state.dataLoopNodes.Node[self.plantLoc.loop.TempSetPointNodeNum].TempSetPointLo
    
    fn setupOutputVars(inout self, state: Any) -> None:
        let sFuelType = eFuelNames[int(self.FuelType)]
        
        SetupOutputVariable(state, "Boiler Heating Rate", Units.W, self.BoilerLoad,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler Heating Energy", Units.J, self.BoilerEnergy,
                          TimeStepType.System, StoreType.Sum, self.Name,
                          eResource.EnergyTransfer, Group.Plant, EndUseCat.Boilers)
        
        SetupOutputVariable(state, "Boiler " + sFuelType + " Rate", Units.W, self.FuelUsed,
                          TimeStepType.System, StoreType.Average, self.Name)
        
        SetupOutputVariable(state, "Boiler " + sFuelType + " Energy", Units.J, self.FuelConsumed,
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
    
    fn autosize(inout self, state: Any) -> None:
        var ErrorsFound: Bool = False
        var tmpNomCap: Real64 = self.NomCap
        let PltSizNum: Int32 = self.plantLoc.loop.PlantSizNum
        
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[int(PltSizNum - 1)].DesVolFlowRate >= SmallWaterVolFlow:
                let SizingTemp: Real64 = self.TempUpLimitBoilerOut
                let SteamDensity: Real64 = self.fluid.value().getSatDensity(state, SizingTemp, 1.0, "SizeBoiler")
                let EnthSteamOutDry: Real64 = self.fluid.value().getSatEnthalpy(state, SizingTemp, 1.0, "SizeBoiler")
                let EnthSteamOutWet: Real64 = self.fluid.value().getSatEnthalpy(state, SizingTemp, 0.0, "SizeBoiler")
                let LatentEnthSteam: Real64 = EnthSteamOutDry - EnthSteamOutWet
                let CpWater: Real64 = self.fluid.value().getSatSpecificHeat(state, SizingTemp, 0.0, "SizeBoiler")
                tmpNomCap = (CpWater * SteamDensity * self.SizFac * 
                            state.dataSize.PlantSizData[int(PltSizNum - 1)].DeltaT *
                            state.dataSize.PlantSizData[int(PltSizNum - 1)].DesVolFlowRate +
                            state.dataSize.PlantSizData[int(PltSizNum - 1)].DesVolFlowRate * SteamDensity * LatentEnthSteam)
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
                        let PlantLoopName: String = self.plantLoc.loop.Name if self.plantLoc.loop else "N/A"
                        let BranchName: String = self.plantLoc.branch.Name if self.plantLoc.branch else "N/A"
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, PlantLoopName)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, BranchName)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name,
                                       eFuelNames[int(self.FuelType)])
                        PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                    
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        reportSizerOutput(state, "Boiler:Steam", self.Name,
                                        "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        let NomCapUser: Real64 = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            reportSizerOutput(state, "Boiler:Steam", self.Name,
                                            "Design Size Nominal Capacity [W]", tmpNomCap,
                                            "User-Specified Nominal Capacity [W]", NomCapUser)
                            
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerType, self.Name, "Boiler:Steam")
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefCap, self.Name, self.NomCap)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRefEff, self.Name, self.NomEffic)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedCap, self.Name, self.NomCap)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerRatedEff, self.Name, self.NomEffic)
                            let PlantLoopName: String = self.plantLoc.loop.Name if self.plantLoc.loop else "N/A"
                            let BranchName: String = self.plantLoc.branch.Name if self.plantLoc.branch else "N/A"
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopName, self.Name, PlantLoopName)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerPlantloopBranchName, self.Name, BranchName)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerMinPLR, self.Name, self.MinPartLoadRat)
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerFuelType, self.Name,
                                           eFuelNames[int(self.FuelType)])
                            PreDefTableEntry(state, state.dataOutRptPredefined.pdchBoilerParaElecLoad, self.Name, "Not Applicable")
                            
                            if state.dataGlobal.DisplayExtraWarnings:
                                if abs(tmpNomCap - NomCapUser) / NomCapUser > state.dataSize.AutoVsHardSizingThreshold:
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
                reportSizerOutput(state, "Boiler:Steam", self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "Boiler:Steam")
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.NomEffic)
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.NomCap)
        
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    
    fn calculate(inout self, state: Any, inout MyLoad: Real64, RunFlag: Bool, EquipFlowCtrl: UInt8) -> None:
        var BoilerDeltaTemp: Real64 = 0.0
        var CpWater: Real64 = 0.0
        
        self.BoilerLoad = 0.0
        self.BoilerMassFlowRate = 0.0
        
        let scheme = self.plantLoc.loop.LoopDemandCalcScheme
        if scheme == LoopDemandCalcScheme.SingleSetPoint:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
        elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
        
        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl == ControlType.SeriesActive:
                self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            return
        
        self.BoilerLoad = MyLoad
        
        self.BoilerPressCheck = self.fluid.value().getSatPressure(state, self.BoilerOutletTemp, "CalcBoilerModel")
        
        if self.BoilerPressCheck > self.BoilerMaxOperPress:
            if self.PressErrIndex == 0:
                ShowSevereError(state, "Boiler:Steam=\"" + self.Name + "\", Saturation Pressure is greater than Maximum Operating Pressure,")
                ShowContinueError(state, "Lower Input Temperature")
                ShowContinueError(state, "Steam temperature=[" + str(self.BoilerOutletTemp) + "] C")
                ShowContinueError(state, "Refrigerant Saturation Pressure =[" + str(self.BoilerPressCheck) + "] Pa")
            ShowRecurringSevereErrorAtEnd(state,
                                        "Boiler:Steam=\"" + self.Name + "\", Saturation Pressure is greater than Maximum Operating Pressure..continues",
                                        self.PressErrIndex,
                                        self.BoilerPressCheck,
                                        self.BoilerPressCheck,
                                        "[Pa]",
                                        "[Pa]")
        
        CpWater = self.fluid.value().getSatSpecificHeat(state, state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp, 0.0, "CalcBoilerModel")
        
        if self.plantLoc.side.FlowLock == FlowLock.Unlocked:
            let inletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            if scheme == LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint - inletTemp)
            else:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo - inletTemp)
            
            self.BoilerOutletTemp = BoilerDeltaTemp + inletTemp
            
            let EnthSteamOutDry = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
            let EnthSteamOutWet = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
            let LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
            self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + (CpWater * BoilerDeltaTemp))
            
            SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                               self.BoilerOutletNodeNum, self.plantLoc)
        else:
            self.BoilerMassFlowRate = state.dataLoopNodes.Node[self.BoilerInletNodeNum].MassFlowRate
            let inletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
            
            if scheme == LoopDemandCalcScheme.SingleSetPoint:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint - inletTemp)
            elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                BoilerDeltaTemp = (state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo - inletTemp)
            
            if BoilerDeltaTemp < 0.0:
                if scheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                let EnthSteamOutDry = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                let EnthSteamOutWet = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                let LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = self.BoilerMassFlowRate * LatentEnthSteam
            else:
                if scheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                let EnthSteamOutDry = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                let EnthSteamOutWet = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                let LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                self.BoilerLoad = (abs(self.BoilerMassFlowRate * LatentEnthSteam) +
                                  abs(self.BoilerMassFlowRate * CpWater * BoilerDeltaTemp))
            
            if self.BoilerLoad > MyLoad:
                self.BoilerLoad = MyLoad
                
                if scheme == LoopDemandCalcScheme.SingleSetPoint:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPoint
                elif scheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerOutletNodeNum].TempSetPointLo
                
                let EnthSteamOutDry = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                let EnthSteamOutWet = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                let LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                BoilerDeltaTemp = self.BoilerOutletTemp - inletTemp
                self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                
                SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                                   self.BoilerOutletNodeNum, self.plantLoc)
            
            if self.BoilerLoad > self.NomCap:
                if self.BoilerMassFlowRate > MassFlowTolerance:
                    self.BoilerLoad = self.NomCap
                    
                    let EnthSteamOutDry = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 1.0, "CalcBoilerModel")
                    let EnthSteamOutWet = self.fluid.value().getSatEnthalpy(state, self.BoilerOutletTemp, 0.0, "CalcBoilerModel")
                    let LatentEnthSteam = EnthSteamOutDry - EnthSteamOutWet
                    BoilerDeltaTemp = self.BoilerOutletTemp - inletTemp
                    self.BoilerMassFlowRate = self.BoilerLoad / (LatentEnthSteam + CpWater * BoilerDeltaTemp)
                    
                    SetComponentFlowRate(state, self.BoilerMassFlowRate, self.BoilerInletNodeNum,
                                       self.BoilerOutletNodeNum, self.plantLoc)
                else:
                    self.BoilerLoad = 0.0
                    self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        
        if self.BoilerOutletTemp > self.TempUpLimitBoilerOut:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = state.dataLoopNodes.Node[self.BoilerInletNodeNum].Temp
        
        var OperPLR: Real64 = self.BoilerLoad / self.NomCap
        OperPLR = min(OperPLR, self.MaxPartLoadRat)
        OperPLR = max(OperPLR, self.MinPartLoadRat)
        let TheorFuelUse: Real64 = self.BoilerLoad / self.NomEffic
        
        self.FuelUsed = TheorFuelUse / (self.FullLoadCoef[0] + self.FullLoadCoef[1] * OperPLR + 
                                        self.FullLoadCoef[2] * OperPLR * OperPLR)
        self.BoilerEff = self.BoilerLoad / self.FuelUsed if self.FuelUsed != 0.0 else 0.0
    
    fn update(inout self, state: Any, MyLoad: Real64, RunFlag: Bool, FirstHVACIteration: Bool) -> None:
        let ReportingConstant: Real64 = state.dataHVACGlobal.TimeStepSysSec
        let BoilerInletNode: Int32 = self.BoilerInletNodeNum
        let BoilerOutletNode: Int32 = self.BoilerOutletNodeNum
        
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
    
    fn simulate(inout self, state: Any, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, 
               inout CurLoad: Real64, RunFlag: Bool) -> None:
        self.initialize(state)
        let sim_component = CompData.getPlantComponent(state, self.plantLoc)
        self.calculate(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.update(state, CurLoad, RunFlag, FirstHVACIteration)
    
    fn getDesignCapacities(self, state: Any, calledFromLocation: PlantLocation) -> (Real64, Real64, Real64):
        let MinLoad: Real64 = self.NomCap * self.MinPartLoadRat
        let MaxLoad: Real64 = self.NomCap * self.MaxPartLoadRat
        let OptLoad: Real64 = self.NomCap * self.OptPartLoadRat
        return MaxLoad, MinLoad, OptLoad
    
    fn getSizingFactor(self) -> Real64:
        return self.SizFac
    
    fn oneTimeInit(inout self, state: Any) -> None:
        var errFlag: Bool = False
        ScanPlantLoopsForObject(state, self.Name, PlantEquipmentType.Boiler_Steam, 
                               self.plantLoc, errFlag)
        if errFlag:
            ShowFatalError(state, "InitBoiler: Program terminated due to previous condition(s).")
    
    fn initEachEnvironment(inout self, state: Any) -> None:
        let BoilerInletNode: Int32 = self.BoilerInletNodeNum
        
        let EnthSteamOutDry: Real64 = self.fluid.value().getSatEnthalpy(state, self.TempUpLimitBoilerOut, 1.0, 
                                                   "BoilerSpecs::initEachEnvironment")
        let EnthSteamOutWet: Real64 = self.fluid.value().getSatEnthalpy(state, self.TempUpLimitBoilerOut, 0.0,
                                                   "BoilerSpecs::initEachEnvironment")
        let LatentEnthSteam: Real64 = EnthSteamOutDry - EnthSteamOutWet
        
        let CpWater: Real64 = self.fluid.value().getSatSpecificHeat(state, self.TempUpLimitBoilerOut, 0.0,
                                               "BoilerSpecs::initEachEnvironment")
        
        self.DesMassFlowRate = (self.NomCap / 
                               (LatentEnthSteam + CpWater * 
                                (self.TempUpLimitBoilerOut - state.dataLoopNodes.Node[int(BoilerInletNode)].Temp)))
        
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
                    ShowWarningError(state, "Missing temperature setpoint for Boiler:Steam = " + self.Name)
                    ShowContinueError(state, " A temperature setpoint is needed at the outlet node of the boiler, use a SetpointManager")
                    ShowContinueError(state, " The overall loop setpoint will be assumed for this boiler. The simulation continues ...")
                    self.MissingSetPointErrDone = True
            else:
                var FatalError: Bool = False
                CheckIfNodeSetPointManagedByEMS(state, self.BoilerOutletNodeNum, CtrlVarType.Temp, FatalError)
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
    
    fn onInitLoopEquip(inout self, state: Any, calledFromLocation: PlantLocation) -> None:
        self.initialize(state)
        self.autosize(state)
    
    @staticmethod
    fn factory(state: Any, objectName: String) -> Optional[BoilerSpecs]:
        if state.dataBoilerSteam.getSteamBoilerInput:
            GetBoilerInput(state)
            state.dataBoilerSteam.getSteamBoilerInput = False
        
        for boiler in state.dataBoilerSteam.Boiler:
            if boiler.Name == objectName:
                return boiler
        
        ShowFatalError(state, "LocalBoilerSteamFactory: Error getting inputs for steam boiler named: " + objectName)
        return None

struct BoilerSteamData(BaseGlobalStruct):
    var getSteamBoilerInput: Bool
    var Boiler: List[BoilerSpecs]
    
    fn __init__(inout self):
        self.getSteamBoilerInput = True
        self.Boiler = List[BoilerSpecs]()
    
    fn init_constant_state(inout self, state: Any) -> None:
        pass
    
    fn init_state(inout self, state: Any) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        self.getSteamBoilerInput = True
        self.Boiler = List[BoilerSpecs]()

@always_inline
fn GetBoilerInput(state: Any) -> None:
    var ErrorsFound: Bool = False
    
    state.dataIPShortCut.cCurrentModuleObject = "Boiler:Steam"
    let inputProcessor = state.dataInputProcessing.inputProcessor
    let numBoilers: Int32 = inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    
    if numBoilers <= 0:
        ShowSevereError(state, "No " + state.dataIPShortCut.cCurrentModuleObject + " equipment specified in input file")
        ErrorsFound = True
    
    if len(state.dataBoilerSteam.Boiler) > 0:
        return
    
    for i in range(numBoilers):
        state.dataBoilerSteam.Boiler.append(BoilerSpecs())
    
    let boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    let boilerObjects = inputProcessor.epJSON.get(state.dataIPShortCut.cCurrentModuleObject, {})
    
    var BoilerNum: Int32 = 0
    for boilerName_orig, boilerFields in boilerObjects.items():
        let boilerName: String = makeUPPER(boilerName_orig)
        let fuelType: String = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
        let waterInletNodeName: String = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "water_inlet_node_name")
        let steamOutletNodeName: String = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "steam_outlet_node_name")
        
        inputProcessor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, boilerName_orig)
        
        VerifyUniqueBoilerName(state, state.dataIPShortCut.cCurrentModuleObject, boilerName, ErrorsFound,
                              state.dataIPShortCut.cCurrentModuleObject + " Name")
        
        var thisBoiler = state.dataBoilerSteam.Boiler[int(BoilerNum)]
        thisBoiler.Name = boilerName
        
        thisBoiler.FuelType = eFuel[fuelType.upper()]
        
        thisBoiler.BoilerMaxOperPress = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_operating_pressure")
        if thisBoiler.BoilerMaxOperPress < 1e5:
            ShowWarningMessage(state, state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\"")
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
            ShowSevereError(state, "GetBoilerInput: " + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
            ShowContinueError(state, " Sum of fuel use curve coefficients = 0.0")
            ErrorsFound = True
        
        if thisBoiler.MinPartLoadRat < 0.0:
            ShowSevereError(state, "GetBoilerInput: " + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
            ShowContinueError(state, "Invalid Minimum Part Load Ratio=" + str(thisBoiler.MinPartLoadRat))
            ErrorsFound = True
        
        if thisBoiler.TempUpLimitBoilerOut == 0.0:
            ShowSevereError(state, "GetBoilerInput: " + state.dataIPShortCut.cCurrentModuleObject + "=\"" + boilerName + "\",")
            ShowContinueError(state, "Invalid Design Outlet Steam Temperature=" + str(thisBoiler.TempUpLimitBoilerOut))
            ErrorsFound = True
        
        thisBoiler.BoilerInletNodeNum = GetOnlySingleNode(state, waterInletNodeName, ErrorsFound,
                                                               ConnectionObjectType.BoilerSteam, boilerName,
                                                               FluidType.Steam, ConnectionType.Inlet,
                                                               CompFluidStream.Primary, ObjectIsNotParent)
        thisBoiler.BoilerOutletNodeNum = GetOnlySingleNode(state, steamOutletNodeName, ErrorsFound,
                                                                ConnectionObjectType.BoilerSteam, boilerName,
                                                                FluidType.Steam, ConnectionType.Outlet,
                                                                CompFluidStream.Primary, ObjectIsNotParent)
        
        TestCompSet(state, state.dataIPShortCut.cCurrentModuleObject, boilerName,
                        waterInletNodeName, steamOutletNodeName, "Hot Steam Nodes")
        
        thisBoiler.fluid = GetSteam(state)
        if thisBoiler.fluid == None and BoilerNum == 0:
            ShowSevereError(state, "Fluid Properties for STEAM not found.")
            ErrorsFound = True
        
        if "end_use_subcategory" in boilerFields:
            thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
        else:
            thisBoiler.EndUseSubcategory = "General"
        
        BoilerNum += 1
    
    if ErrorsFound:
        ShowFatalError(state, "GetBoilerInput: Errors found in processing " + state.dataIPShortCut.cCurrentModuleObject + " input.")

@always_inline
fn SetupOutputVariable(state: Any, *args: Any, **kwargs: Any) -> None:
    pass

@always_inline
fn ShowRecurringSevereErrorAtEnd(state: Any, message: String, errIndex: Int32, *args: Any, **kwargs: Any) -> None:
    pass

# Stub declarations for external dependencies
struct PlantLocation:
    pass

struct RefrigProps:
    fn getSatDensity(self, state: Any, temp: Real64, quality: Real64, routine: String) -> Real64:
        return 0.0
    fn getSatEnthalpy(self, state: Any, temp: Real64, quality: Real64, routine: String) -> Real64:
        return 0.0
    fn getSatSpecificHeat(self, state: Any, temp: Real64, quality: Real64, routine: String) -> Real64:
        return 0.0
    fn getSatPressure(self, state: Any, temp: Real64, routine: String) -> Real64:
        return 0.0

struct CompData:
    @staticmethod
    fn getPlantComponent(state: Any, loc: PlantLocation) -> Any:
        pass

enum LoopDemandCalcScheme:
    SingleSetPoint = 0
    DualSetPointDeadBand = 1

enum ControlType:
    SeriesActive = 0

enum FlowLock:
    Unlocked = 0
    Locked = 1

enum PlantEquipmentType:
    Boiler_Steam = 0

alias SmallWaterVolFlow = 1e-6
alias MassFlowTolerance = 1e-8
alias SensedNodeFlagValue = -999.0

fn SafeCopyPlantNode(state: Any, inlet: Int32, outlet: Int32) -> None:
    pass

fn InitComponentNodes(state: Any, *args: Any) -> None:
    pass

fn SetComponentFlowRate(state: Any, *args: Any) -> None:
    pass

fn ScanPlantLoopsForObject(state: Any, *args: Any) -> None:
    pass

fn VerifyUniqueBoilerName(state: Any, *args: Any) -> None:
    pass

fn GetOnlySingleNode(state: Any, *args: Any) -> Int32:
    return 0

fn TestCompSet(state: Any, *args: Any) -> None:
    pass

fn GetSteam(state: Any) -> Optional[RefrigProps]:
    return None

fn CheckIfNodeSetPointManagedByEMS(state: Any, *args: Any) -> None:
    pass

fn ShowSevereError(state: Any, msg: String) -> None:
    pass

fn ShowWarningMessage(state: Any, msg: String) -> None:
    pass

fn ShowWarningError(state: Any, msg: String) -> None:
    pass

fn ShowContinueError(state: Any, msg: String) -> None:
    pass

fn ShowMessage(state: Any, msg: String) -> None:
    pass

fn ShowFatalError(state: Any, msg: String) -> None:
    pass

fn reportSizerOutput(state: Any, *args: Any) -> None:
    pass

fn PreDefTableEntry(state: Any, *args: Any) -> None:
    pass

fn makeUPPER(s: String) -> String:
    return s.upper()

struct Units:
    pass

struct eResource:
    pass

struct Group:
    pass

struct EndUseCat:
    pass

struct TimeStepType:
    pass

struct StoreType:
    pass

enum CtrlVarType:
    Temp = 0

enum ConnectionObjectType:
    BoilerSteam = 0

enum FluidType:
    Steam = 0

enum ConnectionType:
    Inlet = 0
    Outlet = 1

enum CompFluidStream:
    Primary = 0

enum ObjectIsNotParent:
    value = 0

alias eFuelNames = ["Natural Gas", "Diesel", "Electricity"]
alias eFuel = {"NATURALGAS": 0, "DIESEL": 1, "ELECTRICITY": 2}
alias eFuel2eResource = [0, 1, 2]
alias AutoSize = -999.0
