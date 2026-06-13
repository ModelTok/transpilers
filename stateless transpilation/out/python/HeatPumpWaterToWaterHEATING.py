# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (EnergyPlus/Data/EnergyPlusData.hh)
# - PlantComponent: base class (EnergyPlus/PlantComponent.hh)
# - DataPlant: plant data enums and types (EnergyPlus/Plant/DataPlant.hh)
# - PlantLocation: struct (EnergyPlus/Plant/PlantLocation.hh)
# - Fluid.RefrigProps: refrigerant properties interface (EnergyPlus/FluidProperties.hh)
# - PlantUtilities: utility functions (EnergyPlus/PlantUtilities.hh)
# - Node: node utilities (EnergyPlus/DataLoopNode.hh, EnergyPlus/NodeInputManager.hh)
# - OutputProcessor: output setup (EnergyPlus/OutputProcessor.hh)
# - Constant: units and resources (EnergyPlus constants)
# - ShowFatalError, ShowSevereError, ShowWarningError: error reporting (EnergyPlus/UtilityRoutines.hh)
# - General: general utilities (EnergyPlus/General.hh)

from typing import Optional, List, Any, Protocol
import math

Real64 = float

class RefrigProps(Protocol):
    def getSatPressure(self, state: Any, temp: float, routine_name: str) -> float: ...
    def getSatEnthalpy(self, state: Any, temp: float, quality: float, routine_name: str) -> float: ...
    def getSupHeatEnthalpy(self, state: Any, temp: float, pressure: float, routine_name: str) -> float: ...
    def getSatTemperature(self, state: Any, pressure: float, routine_name: str) -> float: ...
    def getSupHeatDensity(self, state: Any, temp: float, pressure: float, routine_name: str) -> float: ...

class PlantLocation(Protocol):
    loopNum: int
    loopSideNum: int
    loop: Any

class PlantComponent:
    pass

class GshpPeHeatingSpecs(PlantComponent):
    def __init__(self):
        self.Name: str = ""
        self.WWHPPlantType: Any = None
        self.refrig: Optional[RefrigProps] = None
        self.Available: bool = False
        self.ON: bool = False
        self.COP: Real64 = 0.0
        self.NomCap: Real64 = 0.0
        self.MinPartLoadRat: Real64 = 0.0
        self.MaxPartLoadRat: Real64 = 0.0
        self.OptPartLoadRat: Real64 = 0.0
        self.LoadSideVolFlowRate: Real64 = 0.0
        self.LoadSideDesignMassFlow: Real64 = 0.0
        self.SourceSideVolFlowRate: Real64 = 0.0
        self.SourceSideDesignMassFlow: Real64 = 0.0
        self.SourceSideInletNodeNum: int = 0
        self.SourceSideOutletNodeNum: int = 0
        self.LoadSideInletNodeNum: int = 0
        self.LoadSideOutletNodeNum: int = 0
        self.SourceSideUACoeff: Real64 = 0.0
        self.LoadSideUACoeff: Real64 = 0.0
        self.CompPistonDisp: Real64 = 0.0
        self.CompClearanceFactor: Real64 = 0.0
        self.CompSucPressDrop: Real64 = 0.0
        self.SuperheatTemp: Real64 = 0.0
        self.PowerLosses: Real64 = 0.0
        self.LossFactor: Real64 = 0.0
        self.HighPressCutoff: Real64 = 0.0
        self.LowPressCutoff: Real64 = 0.0
        self.IsOn: bool = False
        self.MustRun: bool = False
        self.SourcePlantLoc: Optional[PlantLocation] = None
        self.LoadPlantLoc: Optional[PlantLocation] = None
        self.CondMassFlowIndex: int = 0
        self.Power: Real64 = 0.0
        self.Energy: Real64 = 0.0
        self.QLoad: Real64 = 0.0
        self.QLoadEnergy: Real64 = 0.0
        self.QSource: Real64 = 0.0
        self.QSourceEnergy: Real64 = 0.0
        self.LoadSideWaterInletTemp: Real64 = 0.0
        self.SourceSideWaterInletTemp: Real64 = 0.0
        self.LoadSideWaterOutletTemp: Real64 = 0.0
        self.SourceSideWaterOutletTemp: Real64 = 0.0
        self.LoadSideWaterMassFlowRate: Real64 = 0.0
        self.SourceSideWaterMassFlowRate: Real64 = 0.0
        self.Running: int = 0
        self.plantScanFlag: bool = True
        self.beginEnvironFlag: bool = True

    @staticmethod
    def factory(state: Any, objectName: str) -> Optional['GshpPeHeatingSpecs']:
        if state.dataHPWaterToWaterHtg.GetWWHPHeatingInput:
            GetGshpInput(state)
            state.dataHPWaterToWaterHtg.GetWWHPHeatingInput = False
        
        for gshp in state.dataHPWaterToWaterHtg.GSHP:
            if gshp.Name == objectName:
                return gshp
        
        state.ShowFatalError(f"WWHPHeatingFactory: Error getting inputs for heat pump named: {objectName}")
        return None

    def simulate(self, state: Any, calledFromLocation: PlantLocation, FirstHVACIteration: bool, CurLoad: Real64, RunFlag: bool) -> None:
        if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:
            self.initialize(state)
            self.calculate(state, CurLoad)
            self.update(state)
        elif calledFromLocation.loopNum == self.SourcePlantLoc.loopNum:
            state.PlantUtilities.UpdateChillerComponentCondenserSide(
                state,
                self.SourcePlantLoc.loopNum,
                self.SourcePlantLoc.loopSideNum,
                state.DataPlant.PlantEquipmentType.HPWaterEFHeating,
                self.SourceSideInletNodeNum,
                self.SourceSideOutletNodeNum,
                -self.QSource,
                self.SourceSideWaterInletTemp,
                self.SourceSideWaterOutletTemp,
                self.SourceSideWaterMassFlowRate,
                FirstHVACIteration
            )
        else:
            state.ShowFatalError(f"SimHPWatertoWaterHEATING:: Invalid loop connection {ModuleCompName}, Requested Unit={self.Name}")

    def getDesignCapacities(self, state: Any, calledFromLocation: PlantLocation) -> tuple[Real64, Real64, Real64]:
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat
        return MinLoad, MaxLoad, OptLoad

    def onInitLoopEquip(self, state: Any, calledFromLocation: PlantLocation) -> None:
        if self.plantScanFlag:
            errFlag = False
            state.PlantUtilities.ScanPlantLoopsForObject(
                state,
                self.Name,
                state.DataPlant.PlantEquipmentType.HPWaterPEHeating,
                self.SourcePlantLoc,
                errFlag,
                None,
                None,
                None,
                self.SourceSideInletNodeNum,
                None
            )
            state.PlantUtilities.ScanPlantLoopsForObject(
                state,
                self.Name,
                state.DataPlant.PlantEquipmentType.HPWaterPEHeating,
                self.LoadPlantLoc,
                errFlag,
                None,
                None,
                None,
                self.LoadSideInletNodeNum,
                None
            )
            if errFlag:
                state.ShowFatalError("InitGshp: Program terminated due to previous condition(s).")
            
            state.PlantUtilities.InterConnectTwoPlantLoopSides(state, self.LoadPlantLoc, self.SourcePlantLoc, self.WWHPPlantType, True)
            self.plantScanFlag = False

    def initialize(self, state: Any) -> None:
        RoutineName = "InitGshp"
        
        if state.dataGlobal.BeginEnvrnFlag and self.beginEnvironFlag:
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.QLoadEnergy = 0.0
            self.QSourceEnergy = 0.0
            self.Energy = 0.0
            self.LoadSideWaterInletTemp = 0.0
            self.SourceSideWaterInletTemp = 0.0
            self.LoadSideWaterOutletTemp = 0.0
            self.SourceSideWaterOutletTemp = 0.0
            self.SourceSideWaterMassFlowRate = 0.0
            self.LoadSideWaterMassFlowRate = 0.0
            self.IsOn = False
            self.MustRun = True
            
            self.beginEnvironFlag = False
            rho = self.LoadPlantLoc.loop.glycol.getDensity(state, state.Constant.CWInitConvTemp, RoutineName)
            self.LoadSideDesignMassFlow = self.LoadSideVolFlowRate * rho
            
            state.PlantUtilities.InitComponentNodes(state, 0.0, self.LoadSideDesignMassFlow, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum)
            
            rho = self.SourcePlantLoc.loop.glycol.getDensity(state, state.Constant.CWInitConvTemp, RoutineName)
            self.SourceSideDesignMassFlow = self.SourceSideVolFlowRate * rho
            
            state.PlantUtilities.InitComponentNodes(state, 0.0, self.SourceSideDesignMassFlow, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum)
            if state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint == state.Node.SensedNodeFlagValue:
                state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint = 0.0
            state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp = state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint + 30.0
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.beginEnvironFlag = True
        
        self.Running = 0
        self.MustRun = True
        self.LoadSideWaterMassFlowRate = 0.0
        self.SourceSideWaterMassFlowRate = 0.0
        self.Power = 0.0
        self.QLoad = 0.0
        self.QSource = 0.0

    def calculate(self, state: Any, MyLoad: Real64) -> None:
        gamma = 1.114
        HeatBalTol = 0.0005
        RelaxParam = 0.6
        SmallNum = 1.0e-20
        IterationLimit = 500
        RoutineName = "CalcGshpModel"
        RoutineNameLoadSideTemp = "CalcGSHPModel:LoadSideTemp"
        RoutineNameSourceSideTemp = "CalcGSHPModel:SourceSideTemp"
        RoutineNameCompressInletTemp = "CalcGSHPModel:CompressInletTemp"
        RoutineNameSuctionPr = "CalcGSHPModel:SuctionPr"
        RoutineNameCompSuctionTemp = "CalcGSHPModel:CompSuctionTemp"
        
        if MyLoad > 0.0:
            self.MustRun = True
            self.IsOn = True
        else:
            self.MustRun = False
            self.IsOn = False
        
        self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
        self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
        
        if not self.MustRun:
            self.LoadSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
            self.SourceSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
            state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        self.LoadSideWaterMassFlowRate = self.LoadSideDesignMassFlow
        state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
        
        self.SourceSideWaterMassFlowRate = self.SourceSideDesignMassFlow
        state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
        
        if self.LoadSideWaterMassFlowRate < state.DataBranchAirLoopPlant.MassFlowTolerance or self.SourceSideWaterMassFlowRate < state.DataBranchAirLoopPlant.MassFlowTolerance:
            self.LoadSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
            self.SourceSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
            state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
        
        initialQSource = 0.0
        initialQLoad = 0.0
        IterationCount = 0
        
        CpSourceSide = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, self.SourceSideWaterInletTemp, RoutineName)
        CpLoadSide = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, self.LoadSideWaterInletTemp, RoutineName)
        
        SourceSideEffect = 1.0 - math.exp(-self.SourceSideUACoeff / (CpSourceSide * self.SourceSideWaterMassFlowRate))
        LoadSideEffect = 1.0 - math.exp(-self.LoadSideUACoeff / (CpLoadSide * self.LoadSideWaterMassFlowRate))
        
        while True:
            IterationCount += 1
            
            SourceSideTemp = self.SourceSideWaterInletTemp - initialQSource / (SourceSideEffect * CpSourceSide * self.SourceSideWaterMassFlowRate)
            LoadSideTemp = self.LoadSideWaterInletTemp + initialQLoad / (LoadSideEffect * CpLoadSide * self.LoadSideWaterMassFlowRate)
            
            SourceSidePressure = self.refrig.getSatPressure(state, SourceSideTemp, RoutineNameSourceSideTemp)
            LoadSidePressure = self.refrig.getSatPressure(state, LoadSideTemp, RoutineNameLoadSideTemp)
            
            if SourceSidePressure < self.LowPressCutoff:
                state.ShowSevereError(f"{ModuleCompName}=\"{self.Name}\" Heating Source Side Pressure Less than the Design Minimum")
                state.ShowContinueError(f"Source Side Pressure={SourceSidePressure:.2f} and user specified Design Minimum Pressure={self.LowPressCutoff:.2f}")
                state.ShowFatalError("Preceding Conditions cause termination.")
            if LoadSidePressure > self.HighPressCutoff:
                state.ShowSevereError(f"{ModuleCompName}=\"{self.Name}\" Heating Load Side Pressure greater than the Design Maximum")
                state.ShowContinueError(f"Load Side Pressure={LoadSidePressure:.2f} and user specified Design Maximum Pressure={self.HighPressCutoff:.2f}")
                state.ShowFatalError("Preceding Conditions cause termination.")
            
            SuctionPr = SourceSidePressure - self.CompSucPressDrop
            DischargePr = LoadSidePressure + self.CompSucPressDrop
            
            if SuctionPr < self.LowPressCutoff:
                state.ShowSevereError(f"{ModuleCompName}=\"{self.Name}\" Heating Suction Pressure Less than the Design Minimum")
                state.ShowContinueError(f"Heating Suction Pressure={SuctionPr:.2f} and user specified Design Minimum Pressure={self.LowPressCutoff:.2f}")
                state.ShowFatalError("Preceding Conditions cause termination.")
            if DischargePr > self.HighPressCutoff:
                state.ShowSevereError(f"{ModuleCompName}=\"{self.Name}\" Heating Discharge Pressure greater than the Design Maximum")
                state.ShowContinueError(f"Heating Discharge Pressure={DischargePr:.2f} and user specified Design Maximum Pressure={self.HighPressCutoff:.2f}")
                state.ShowFatalError("Preceding Conditions cause termination.")
            
            qualOne = 1.0
            SourceSideOutletEnth = self.refrig.getSatEnthalpy(state, SourceSideTemp, qualOne, RoutineNameSourceSideTemp)
            
            qualZero = 0.0
            LoadSideOutletEnth = self.refrig.getSatEnthalpy(state, LoadSideTemp, qualZero, RoutineNameLoadSideTemp)
            
            CompressInletTemp = SourceSideTemp + self.SuperheatTemp
            SuperHeatEnth = self.refrig.getSupHeatEnthalpy(state, CompressInletTemp, SourceSidePressure, RoutineNameCompressInletTemp)
            
            CompSuctionSatTemp = self.refrig.getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
            
            T110 = CompSuctionSatTemp
            T111 = CompSuctionSatTemp + 80
            
            while True:
                CompSuctionTemp = 0.5 * (T110 + T111)
                CompSuctionEnth = self.refrig.getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
                
                if abs(CompSuctionEnth - SuperHeatEnth) / SuperHeatEnth < 0.0001:
                    break
                
                if CompSuctionEnth < SuperHeatEnth:
                    T110 = CompSuctionTemp
                else:
                    T111 = CompSuctionTemp
            
            CompSuctionDensity = self.refrig.getSupHeatDensity(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
            MassRef = self.CompPistonDisp * CompSuctionDensity * (1.0 + self.CompClearanceFactor - self.CompClearanceFactor * math.pow(DischargePr / SuctionPr, 1.0 / gamma))
            
            self.QSource = MassRef * (SourceSideOutletEnth - LoadSideOutletEnth)
            
            self.Power = self.PowerLosses + (MassRef * gamma / (gamma - 1) * SuctionPr / CompSuctionDensity / self.LossFactor * (math.pow(DischargePr / SuctionPr, (gamma - 1) / gamma) - 1))
            
            self.QLoad = self.Power + self.QSource
            
            if abs((self.QLoad - initialQLoad) / (initialQLoad + SmallNum)) < HeatBalTol or IterationCount > IterationLimit:
                if IterationCount > IterationLimit:
                    state.ShowWarningError(f"{ModuleCompName} did not converge")
                    state.ShowContinueErrorTimeStamp("")
                    state.ShowContinueError(f"Heatpump Name = {self.Name}")
                    state.ShowContinueError(f"Heat Imbalance (%)             = {abs(100.0 * (self.QLoad - initialQLoad) / (initialQLoad + SmallNum)):G}")
                    state.ShowContinueError(f"Load-side heat transfer rate   = {self.QLoad:G}")
                    state.ShowContinueError(f"Source-side heat transfer rate = {self.QSource:G}")
                    state.ShowContinueError(f"Source-side mass flow rate     = {self.SourceSideWaterMassFlowRate:G}")
                    state.ShowContinueError(f"Load-side mass flow rate       = {self.LoadSideWaterMassFlowRate:G}")
                    state.ShowContinueError(f"Source-side inlet temperature  = {self.SourceSideWaterInletTemp:G}")
                    state.ShowContinueError(f"Load-side inlet temperature    = {self.LoadSideWaterInletTemp:G}")
                break
            else:
                initialQLoad += RelaxParam * (self.QLoad - initialQLoad)
                initialQSource += RelaxParam * (self.QSource - initialQSource)
        
        if abs(MyLoad) < self.QLoad:
            DutyFactor = abs(MyLoad) / self.QLoad
            self.QLoad = abs(MyLoad)
            self.Power *= DutyFactor
            self.QSource *= DutyFactor
            
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
            return
        
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
        self.Running = 1

    def update(self, state: Any) -> None:
        if not self.MustRun:
            state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.Power = 0.0
            self.Energy = 0.0
            self.QSource = 0.0
            self.QLoad = 0.0
            self.QSourceEnergy = 0.0
            self.QLoadEnergy = 0.0
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp = self.LoadSideWaterOutletTemp
            state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp = self.SourceSideWaterOutletTemp
            
            ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
            
            self.Energy = self.Power * ReportingConstant
            self.QSourceEnergy = self.QSource * ReportingConstant
            self.QLoadEnergy = self.QLoad * ReportingConstant

    def oneTimeInit(self, state: Any) -> None:
        pass

    def oneTimeInit_new(self, state: Any) -> None:
        pass


ModuleCompName = "HeatPump:WaterToWater:ParameterEstimation:Heating"
ModuleCompNameUC = "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:HEATING"
GSHPRefrigerant = "R22"


def GetGshpInput(state: Any) -> None:
    routineName = "GetGshpInput"
    
    state.dataHPWaterToWaterHtg.NumGSHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ModuleCompName)
    
    if state.dataHPWaterToWaterHtg.NumGSHPs <= 0:
        state.ShowSevereError(f"{ModuleCompName}: No Equipment found")
        ErrorsFound = True
    else:
        ErrorsFound = False
    
    state.dataHPWaterToWaterHtg.GSHP = [GshpPeHeatingSpecs() for _ in range(state.dataHPWaterToWaterHtg.NumGSHPs)]
    
    for GSHPNum in range(state.dataHPWaterToWaterHtg.NumGSHPs):
        thisGSHP = state.dataHPWaterToWaterHtg.GSHP[GSHPNum]
        AlphArray = [None] * 5
        NumArray = [None] * 23
        NumAlphas = 0
        NumNums = 0
        IOStat = 0
        
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ModuleCompNameUC, GSHPNum + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat)
        
        thisGSHP.Name = AlphArray[0]
        thisGSHP.WWHPPlantType = state.DataPlant.PlantEquipmentType.HPWaterPEHeating
        
        thisGSHP.COP = NumArray[0]
        if NumArray[0] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:COP = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.NomCap = NumArray[1]
        thisGSHP.MinPartLoadRat = NumArray[2]
        thisGSHP.MaxPartLoadRat = NumArray[3]
        thisGSHP.OptPartLoadRat = NumArray[4]
        thisGSHP.LoadSideVolFlowRate = NumArray[5]
        
        if NumArray[5] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Load Side Flow Rate = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.SourceSideVolFlowRate = NumArray[6]
        if NumArray[6] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Source Side Flow Rate = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.LoadSideUACoeff = NumArray[7]
        if NumArray[7] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Load Side Heat Transfer Coefficient = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.SourceSideUACoeff = NumArray[8]
        if NumArray[8] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Source Side Heat Transfer Coefficient = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.CompPistonDisp = NumArray[9]
        if NumArray[9] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Compressor Piston displacement/Storke = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.CompClearanceFactor = NumArray[10]
        if NumArray[10] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Compressor Clearance Factor = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.CompSucPressDrop = NumArray[11]
        if NumArray[11] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}: Pressure Drop = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.SuperheatTemp = NumArray[12]
        if NumArray[12] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Source Side SuperHeat = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.PowerLosses = NumArray[13]
        if NumArray[13] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Compressor Power Loss = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.LossFactor = NumArray[14]
        if NumArray[14] == 0.0:
            state.ShowSevereError(f"{ModuleCompName}:Efficiency = 0.0, Heatpump={thisGSHP.Name}")
            ErrorsFound = True
        
        thisGSHP.HighPressCutoff = NumArray[15]
        if NumArray[15] == 0.0:
            thisGSHP.HighPressCutoff = 500000000.0
        
        thisGSHP.LowPressCutoff = NumArray[16]
        if NumArray[16] == 0.0:
            thisGSHP.LowPressCutoff = 0.0
        
        thisGSHP.SourceSideInletNodeNum = state.GetOnlySingleNode(
            state, AlphArray[1], ErrorsFound,
            state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
            thisGSHP.Name, state.Node.FluidType.Water,
            state.Node.ConnectionType.Inlet,
            state.Node.CompFluidStream.Primary,
            state.Node.ObjectIsNotParent
        )
        
        thisGSHP.SourceSideOutletNodeNum = state.GetOnlySingleNode(
            state, AlphArray[2], ErrorsFound,
            state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
            thisGSHP.Name, state.Node.FluidType.Water,
            state.Node.ConnectionType.Outlet,
            state.Node.CompFluidStream.Primary,
            state.Node.ObjectIsNotParent
        )
        
        thisGSHP.LoadSideInletNodeNum = state.GetOnlySingleNode(
            state, AlphArray[3], ErrorsFound,
            state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
            thisGSHP.Name, state.Node.FluidType.Water,
            state.Node.ConnectionType.Inlet,
            state.Node.CompFluidStream.Secondary,
            state.Node.ObjectIsNotParent
        )
        
        thisGSHP.LoadSideOutletNodeNum = state.GetOnlySingleNode(
            state, AlphArray[4], ErrorsFound,
            state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
            thisGSHP.Name, state.Node.FluidType.Water,
            state.Node.ConnectionType.Outlet,
            state.Node.CompFluidStream.Secondary,
            state.Node.ObjectIsNotParent
        )
        
        state.Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[1], AlphArray[2], "Condenser Water Nodes")
        state.Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[3], AlphArray[4], "Hot Water Nodes")
        
        state.PlantUtilities.RegisterPlantCompDesignFlow(state, thisGSHP.SourceSideInletNodeNum, 0.5 * thisGSHP.SourceSideVolFlowRate)
        
        thisGSHP.refrig = state.Fluid.GetRefrig(state, GSHPRefrigerant)
        if thisGSHP.refrig is None:
            state.ShowSevereItemNotFound(state, routineName, ModuleCompNameUC, AlphArray[0], "Refrigerant", GSHPRefrigerant)
            ErrorsFound = True
    
    if ErrorsFound:
        state.ShowFatalError(f"Errors Found in getting {ModuleCompNameUC} Input")
    
    for GSHPNum in range(state.dataHPWaterToWaterHtg.NumGSHPs):
        thisGSHP = state.dataHPWaterToWaterHtg.GSHP[GSHPNum]
        state.SetupOutputVariable(state, "Heat Pump Electricity Rate", state.Constant.Units.W, thisGSHP.Power, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Electricity Energy", state.Constant.Units.J, thisGSHP.Energy, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Sum, thisGSHP.Name, state.Constant.eResource.Electricity, state.OutputProcessor.Group.Plant, state.OutputProcessor.EndUseCat.Heating)
        state.SetupOutputVariable(state, "Heat Pump Load Side Heat Transfer Rate", state.Constant.Units.W, thisGSHP.QLoad, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Load Side Heat Transfer Energy", state.Constant.Units.J, thisGSHP.QLoadEnergy, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Sum, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Source Side Heat Transfer Rate", state.Constant.Units.W, thisGSHP.QSource, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Source Side Heat Transfer Energy", state.Constant.Units.J, thisGSHP.QSourceEnergy, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Sum, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Load Side Outlet Temperature", state.Constant.Units.C, thisGSHP.LoadSideWaterOutletTemp, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Load Side Inlet Temperature", state.Constant.Units.C, thisGSHP.LoadSideWaterInletTemp, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Source Side Outlet Temperature", state.Constant.Units.C, thisGSHP.SourceSideWaterOutletTemp, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Source Side Inlet Temperature", state.Constant.Units.C, thisGSHP.SourceSideWaterInletTemp, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Load Side Mass Flow Rate", state.Constant.Units.kg_s, thisGSHP.LoadSideWaterMassFlowRate, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)
        state.SetupOutputVariable(state, "Heat Pump Source Side Mass Flow Rate", state.Constant.Units.kg_s, thisGSHP.SourceSideWaterMassFlowRate, state.OutputProcessor.TimeStepType.System, state.OutputProcessor.StoreType.Average, thisGSHP.Name)


class HeatPumpWaterToWaterHEATINGData:
    def __init__(self):
        self.NumGSHPs: int = 0
        self.GetWWHPHeatingInput: bool = True
        self.GSHP: List[GshpPeHeatingSpecs] = []

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.NumGSHPs = 0
        self.GetWWHPHeatingInput = True
        self.GSHP = []
