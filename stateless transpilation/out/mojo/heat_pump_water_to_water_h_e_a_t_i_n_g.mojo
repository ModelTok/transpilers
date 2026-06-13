# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (EnergyPlus/Data/EnergyPlusData.hh)
# - PlantComponent: base struct (EnergyPlus/PlantComponent.hh)
# - DataPlant: plant data enums and types (EnergyPlus/Plant/DataPlant.hh)
# - PlantLocation: struct (EnergyPlus/Plant/PlantLocation.hh)
# - Fluid.RefrigProps: refrigerant properties interface (EnergyPlus/FluidProperties.hh)
# - PlantUtilities: utility functions (EnergyPlus/PlantUtilities.hh)
# - Node: node utilities (EnergyPlus/DataLoopNode.hh, EnergyPlus/NodeInputManager.hh)
# - OutputProcessor: output setup (EnergyPlus/OutputProcessor.hh)
# - Constant: units and resources (EnergyPlus constants)
# - ShowFatalError, ShowSevereError, ShowWarningError: error reporting (EnergyPlus/UtilityRoutines.hh)
# - General: general utilities (EnergyPlus/General.hh)

from math import exp, pow, abs, floor

alias Real64 = Float64

struct RefrigProps:
    fn getSatPressure(self, state: EnergyPlusData, temp: Real64, routine_name: StringRef) -> Real64: ...
    fn getSatEnthalpy(self, state: EnergyPlusData, temp: Real64, quality: Real64, routine_name: StringRef) -> Real64: ...
    fn getSupHeatEnthalpy(self, state: EnergyPlusData, temp: Real64, pressure: Real64, routine_name: StringRef) -> Real64: ...
    fn getSatTemperature(self, state: EnergyPlusData, pressure: Real64, routine_name: StringRef) -> Real64: ...
    fn getSupHeatDensity(self, state: EnergyPlusData, temp: Real64, pressure: Real64, routine_name: StringRef) -> Real64: ...

struct PlantLocation:
    loopNum: Int32
    loopSideNum: Int32
    loop: UnsafePointer[AnyType]

struct PlantComponent:
    pass

struct GshpPeHeatingSpecs(PlantComponent):
    var Name: String
    var WWHPPlantType: AnyType
    var refrig: UnsafePointer[RefrigProps]
    var Available: Bool
    var ON: Bool
    var COP: Real64
    var NomCap: Real64
    var MinPartLoadRat: Real64
    var MaxPartLoadRat: Real64
    var OptPartLoadRat: Real64
    var LoadSideVolFlowRate: Real64
    var LoadSideDesignMassFlow: Real64
    var SourceSideVolFlowRate: Real64
    var SourceSideDesignMassFlow: Real64
    var SourceSideInletNodeNum: Int32
    var SourceSideOutletNodeNum: Int32
    var LoadSideInletNodeNum: Int32
    var LoadSideOutletNodeNum: Int32
    var SourceSideUACoeff: Real64
    var LoadSideUACoeff: Real64
    var CompPistonDisp: Real64
    var CompClearanceFactor: Real64
    var CompSucPressDrop: Real64
    var SuperheatTemp: Real64
    var PowerLosses: Real64
    var LossFactor: Real64
    var HighPressCutoff: Real64
    var LowPressCutoff: Real64
    var IsOn: Bool
    var MustRun: Bool
    var SourcePlantLoc: UnsafePointer[PlantLocation]
    var LoadPlantLoc: UnsafePointer[PlantLocation]
    var CondMassFlowIndex: Int32
    var Power: Real64
    var Energy: Real64
    var QLoad: Real64
    var QLoadEnergy: Real64
    var QSource: Real64
    var QSourceEnergy: Real64
    var LoadSideWaterInletTemp: Real64
    var SourceSideWaterInletTemp: Real64
    var LoadSideWaterOutletTemp: Real64
    var SourceSideWaterOutletTemp: Real64
    var LoadSideWaterMassFlowRate: Real64
    var SourceSideWaterMassFlowRate: Real64
    var Running: Int32
    var plantScanFlag: Bool
    var beginEnvironFlag: Bool

    fn __init__(inout self):
        self.Name = ""
        self.WWHPPlantType = AnyType()
        self.refrig = UnsafePointer[RefrigProps]()
        self.Available = False
        self.ON = False
        self.COP = 0.0
        self.NomCap = 0.0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.LoadSideVolFlowRate = 0.0
        self.LoadSideDesignMassFlow = 0.0
        self.SourceSideVolFlowRate = 0.0
        self.SourceSideDesignMassFlow = 0.0
        self.SourceSideInletNodeNum = 0
        self.SourceSideOutletNodeNum = 0
        self.LoadSideInletNodeNum = 0
        self.LoadSideOutletNodeNum = 0
        self.SourceSideUACoeff = 0.0
        self.LoadSideUACoeff = 0.0
        self.CompPistonDisp = 0.0
        self.CompClearanceFactor = 0.0
        self.CompSucPressDrop = 0.0
        self.SuperheatTemp = 0.0
        self.PowerLosses = 0.0
        self.LossFactor = 0.0
        self.HighPressCutoff = 0.0
        self.LowPressCutoff = 0.0
        self.IsOn = False
        self.MustRun = False
        self.SourcePlantLoc = UnsafePointer[PlantLocation]()
        self.LoadPlantLoc = UnsafePointer[PlantLocation]()
        self.CondMassFlowIndex = 0
        self.Power = 0.0
        self.Energy = 0.0
        self.QLoad = 0.0
        self.QLoadEnergy = 0.0
        self.QSource = 0.0
        self.QSourceEnergy = 0.0
        self.LoadSideWaterInletTemp = 0.0
        self.SourceSideWaterInletTemp = 0.0
        self.LoadSideWaterOutletTemp = 0.0
        self.SourceSideWaterOutletTemp = 0.0
        self.LoadSideWaterMassFlowRate = 0.0
        self.SourceSideWaterMassFlowRate = 0.0
        self.Running = 0
        self.plantScanFlag = True
        self.beginEnvironFlag = True

    @staticmethod
    fn factory(state: EnergyPlusData, objectName: StringRef) -> UnsafePointer[GshpPeHeatingSpecs]:
        if state.dataHPWaterToWaterHtg.GetWWHPHeatingInput:
            GetGshpInput(state)
            state.dataHPWaterToWaterHtg.GetWWHPHeatingInput = False
        
        for i in range(state.dataHPWaterToWaterHtg.GSHP.size()):
            if state.dataHPWaterToWaterHtg.GSHP[i].Name == objectName:
                return UnsafePointer[GshpPeHeatingSpecs](address_of(state.dataHPWaterToWaterHtg.GSHP[i]))
        
        state.ShowFatalError(String("WWHPHeatingFactory: Error getting inputs for heat pump named: ") + String(objectName))
        return UnsafePointer[GshpPeHeatingSpecs]()

    fn simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Real64, RunFlag: Bool):
        if calledFromLocation.loopNum == self.LoadPlantLoc[].loopNum:
            self.initialize(state)
            self.calculate(state, CurLoad)
            self.update(state)
        elif calledFromLocation.loopNum == self.SourcePlantLoc[].loopNum:
            state.PlantUtilities.UpdateChillerComponentCondenserSide(
                state,
                self.SourcePlantLoc[].loopNum,
                self.SourcePlantLoc[].loopSideNum,
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
            state.ShowFatalError(String("SimHPWatertoWaterHEATING:: Invalid loop connection ") + ModuleCompName + String(", Requested Unit=") + self.Name)

    fn getDesignCapacities(self, state: EnergyPlusData, calledFromLocation: PlantLocation) -> Tuple[Real64, Real64, Real64]:
        let MinLoad: Real64 = self.NomCap * self.MinPartLoadRat
        let MaxLoad: Real64 = self.NomCap * self.MaxPartLoadRat
        let OptLoad: Real64 = self.NomCap * self.OptPartLoadRat
        return (MinLoad, MaxLoad, OptLoad)

    fn onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        if self.plantScanFlag:
            var errFlag: Bool = False
            state.PlantUtilities.ScanPlantLoopsForObject(
                state,
                self.Name,
                state.DataPlant.PlantEquipmentType.HPWaterPEHeating,
                self.SourcePlantLoc[],
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
                self.LoadPlantLoc[],
                errFlag,
                None,
                None,
                None,
                self.LoadSideInletNodeNum,
                None
            )
            if errFlag:
                state.ShowFatalError("InitGshp: Program terminated due to previous condition(s).")
            
            state.PlantUtilities.InterConnectTwoPlantLoopSides(state, self.LoadPlantLoc[], self.SourcePlantLoc[], self.WWHPPlantType, True)
            self.plantScanFlag = False

    fn initialize(inout self, state: EnergyPlusData):
        let RoutineName: StringRef = "InitGshp"
        
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
            let rho1: Real64 = self.LoadPlantLoc[].loop[].glycol.getDensity(state, state.Constant.CWInitConvTemp, RoutineName)
            self.LoadSideDesignMassFlow = self.LoadSideVolFlowRate * rho1
            
            state.PlantUtilities.InitComponentNodes(state, 0.0, self.LoadSideDesignMassFlow, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum)
            
            let rho2: Real64 = self.SourcePlantLoc[].loop[].glycol.getDensity(state, state.Constant.CWInitConvTemp, RoutineName)
            self.SourceSideDesignMassFlow = self.SourceSideVolFlowRate * rho2
            
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

    fn calculate(inout self, state: EnergyPlusData, MyLoad: Real64):
        let gamma: Real64 = 1.114
        let HeatBalTol: Real64 = 0.0005
        let RelaxParam: Real64 = 0.6
        let SmallNum: Real64 = 1.0e-20
        let IterationLimit: Int32 = 500
        let RoutineName: StringRef = "CalcGshpModel"
        let RoutineNameLoadSideTemp: StringRef = "CalcGSHPModel:LoadSideTemp"
        let RoutineNameSourceSideTemp: StringRef = "CalcGSHPModel:SourceSideTemp"
        let RoutineNameCompressInletTemp: StringRef = "CalcGSHPModel:CompressInletTemp"
        let RoutineNameSuctionPr: StringRef = "CalcGSHPModel:SuctionPr"
        let RoutineNameCompSuctionTemp: StringRef = "CalcGSHPModel:CompSuctionTemp"
        
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
            state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc[])
            self.SourceSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc[])
            state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc[], self.CondMassFlowIndex, self.SourcePlantLoc[], state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        self.LoadSideWaterMassFlowRate = self.LoadSideDesignMassFlow
        state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc[])
        
        self.SourceSideWaterMassFlowRate = self.SourceSideDesignMassFlow
        state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc[])
        
        if self.LoadSideWaterMassFlowRate < state.DataBranchAirLoopPlant.MassFlowTolerance or self.SourceSideWaterMassFlowRate < state.DataBranchAirLoopPlant.MassFlowTolerance:
            self.LoadSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc[])
            self.SourceSideWaterMassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc[])
            state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc[], self.CondMassFlowIndex, self.SourcePlantLoc[], state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        state.PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc[], self.CondMassFlowIndex, self.SourcePlantLoc[], state.DataPlant.CriteriaType.MassFlowRate, self.SourceSideWaterMassFlowRate)
        
        var initialQSource: Real64 = 0.0
        var initialQLoad: Real64 = 0.0
        var IterationCount: Int32 = 0
        
        let CpSourceSide: Real64 = self.SourcePlantLoc[].loop[].glycol.getSpecificHeat(state, self.SourceSideWaterInletTemp, RoutineName)
        let CpLoadSide: Real64 = self.LoadPlantLoc[].loop[].glycol.getSpecificHeat(state, self.LoadSideWaterInletTemp, RoutineName)
        
        let SourceSideEffect: Real64 = 1.0 - exp(-self.SourceSideUACoeff / (CpSourceSide * self.SourceSideWaterMassFlowRate))
        let LoadSideEffect: Real64 = 1.0 - exp(-self.LoadSideUACoeff / (CpLoadSide * self.LoadSideWaterMassFlowRate))
        
        while True:
            IterationCount += 1
            
            let SourceSideTemp: Real64 = self.SourceSideWaterInletTemp - initialQSource / (SourceSideEffect * CpSourceSide * self.SourceSideWaterMassFlowRate)
            let LoadSideTemp: Real64 = self.LoadSideWaterInletTemp + initialQLoad / (LoadSideEffect * CpLoadSide * self.LoadSideWaterMassFlowRate)
            
            let SourceSidePressure: Real64 = self.refrig[].getSatPressure(state, SourceSideTemp, RoutineNameSourceSideTemp)
            let LoadSidePressure: Real64 = self.refrig[].getSatPressure(state, LoadSideTemp, RoutineNameLoadSideTemp)
            
            if SourceSidePressure < self.LowPressCutoff:
                state.ShowSevereError(String("") + ModuleCompName + String("=\"") + self.Name + String("\" Heating Source Side Pressure Less than the Design Minimum"))
                state.ShowContinueError(String("Source Side Pressure=") + String(SourceSidePressure) + String(" and user specified Design Minimum Pressure=") + String(self.LowPressCutoff))
                state.ShowFatalError("Preceding Conditions cause termination.")
            if LoadSidePressure > self.HighPressCutoff:
                state.ShowSevereError(String("") + ModuleCompName + String("=\"") + self.Name + String("\" Heating Load Side Pressure greater than the Design Maximum"))
                state.ShowContinueError(String("Load Side Pressure=") + String(LoadSidePressure) + String(" and user specified Design Maximum Pressure=") + String(self.HighPressCutoff))
                state.ShowFatalError("Preceding Conditions cause termination.")
            
            let SuctionPr: Real64 = SourceSidePressure - self.CompSucPressDrop
            let DischargePr: Real64 = LoadSidePressure + self.CompSucPressDrop
            
            if SuctionPr < self.LowPressCutoff:
                state.ShowSevereError(String("") + ModuleCompName + String("=\"") + self.Name + String("\" Heating Suction Pressure Less than the Design Minimum"))
                state.ShowContinueError(String("Heating Suction Pressure=") + String(SuctionPr) + String(" and user specified Design Minimum Pressure=") + String(self.LowPressCutoff))
                state.ShowFatalError("Preceding Conditions cause termination.")
            if DischargePr > self.HighPressCutoff:
                state.ShowSevereError(String("") + ModuleCompName + String("=\"") + self.Name + String("\" Heating Discharge Pressure greater than the Design Maximum"))
                state.ShowContinueError(String("Heating Discharge Pressure=") + String(DischargePr) + String(" and user specified Design Maximum Pressure=") + String(self.HighPressCutoff))
                state.ShowFatalError("Preceding Conditions cause termination.")
            
            let qualOne: Real64 = 1.0
            let SourceSideOutletEnth: Real64 = self.refrig[].getSatEnthalpy(state, SourceSideTemp, qualOne, RoutineNameSourceSideTemp)
            
            let qualZero: Real64 = 0.0
            let LoadSideOutletEnth: Real64 = self.refrig[].getSatEnthalpy(state, LoadSideTemp, qualZero, RoutineNameLoadSideTemp)
            
            let CompressInletTemp: Real64 = SourceSideTemp + self.SuperheatTemp
            let SuperHeatEnth: Real64 = self.refrig[].getSupHeatEnthalpy(state, CompressInletTemp, SourceSidePressure, RoutineNameCompressInletTemp)
            
            let CompSuctionSatTemp: Real64 = self.refrig[].getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
            
            var T110: Real64 = CompSuctionSatTemp
            var T111: Real64 = CompSuctionSatTemp + 80
            
            while True:
                var CompSuctionTemp: Real64 = 0.5 * (T110 + T111)
                let CompSuctionEnth: Real64 = self.refrig[].getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
                
                if abs(CompSuctionEnth - SuperHeatEnth) / SuperHeatEnth < 0.0001:
                    break
                
                if CompSuctionEnth < SuperHeatEnth:
                    T110 = CompSuctionTemp
                else:
                    T111 = CompSuctionTemp
            
            let CompSuctionDensity: Real64 = self.refrig[].getSupHeatDensity(state, (T110 + T111) * 0.5, SuctionPr, RoutineNameCompSuctionTemp)
            let MassRef: Real64 = self.CompPistonDisp * CompSuctionDensity * (1.0 + self.CompClearanceFactor - self.CompClearanceFactor * pow(DischargePr / SuctionPr, 1.0 / gamma))
            
            self.QSource = MassRef * (SourceSideOutletEnth - LoadSideOutletEnth)
            
            self.Power = self.PowerLosses + (MassRef * gamma / (gamma - 1) * SuctionPr / CompSuctionDensity / self.LossFactor * (pow(DischargePr / SuctionPr, (gamma - 1) / gamma) - 1))
            
            self.QLoad = self.Power + self.QSource
            
            if abs((self.QLoad - initialQLoad) / (initialQLoad + SmallNum)) < HeatBalTol or IterationCount > IterationLimit:
                if IterationCount > IterationLimit:
                    state.ShowWarningError(String(ModuleCompName) + String(" did not converge"))
                    state.ShowContinueErrorTimeStamp("")
                    state.ShowContinueError(String("Heatpump Name = ") + self.Name)
                    state.ShowContinueError(String("Heat Imbalance (%)             = ") + String(abs(100.0 * (self.QLoad - initialQLoad) / (initialQLoad + SmallNum))))
                    state.ShowContinueError(String("Load-side heat transfer rate   = ") + String(self.QLoad))
                    state.ShowContinueError(String("Source-side heat transfer rate = ") + String(self.QSource))
                    state.ShowContinueError(String("Source-side mass flow rate     = ") + String(self.SourceSideWaterMassFlowRate))
                    state.ShowContinueError(String("Load-side mass flow rate       = ") + String(self.LoadSideWaterMassFlowRate))
                    state.ShowContinueError(String("Source-side inlet temperature  = ") + String(self.SourceSideWaterInletTemp))
                    state.ShowContinueError(String("Load-side inlet temperature    = ") + String(self.LoadSideWaterInletTemp))
                break
            else:
                initialQLoad += RelaxParam * (self.QLoad - initialQLoad)
                initialQSource += RelaxParam * (self.QSource - initialQSource)
        
        if abs(MyLoad) < self.QLoad:
            let DutyFactor: Real64 = abs(MyLoad) / self.QLoad
            self.QLoad = abs(MyLoad)
            self.Power *= DutyFactor
            self.QSource *= DutyFactor
            
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
            return
        
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
        self.Running = 1

    fn update(inout self, state: EnergyPlusData):
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
            
            let ReportingConstant: Real64 = state.dataHVACGlobal.TimeStepSysSec
            
            self.Energy = self.Power * ReportingConstant
            self.QSourceEnergy = self.QSource * ReportingConstant
            self.QLoadEnergy = self.QLoad * ReportingConstant

    fn oneTimeInit(inout self, state: EnergyPlusData):
        pass

    fn oneTimeInit_new(inout self, state: EnergyPlusData):
        pass


let ModuleCompName: String = "HeatPump:WaterToWater:ParameterEstimation:Heating"
let ModuleCompNameUC: String = "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:HEATING"
let GSHPRefrigerant: String = "R22"


fn GetGshpInput(inout state: EnergyPlusData):
    let routineName: StringRef = "GetGshpInput"
    
    state.dataHPWaterToWaterHtg.NumGSHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ModuleCompName)
    
    var ErrorsFound: Bool = False
    
    if state.dataHPWaterToWaterHtg.NumGSHPs <= 0:
        state.ShowSevereError(String(ModuleCompName) + String(": No Equipment found"))
        ErrorsFound = True
    
    var AlphArray: InlineArray[String, 5] = InlineArray[String, 5]()
    var NumArray: InlineArray[Real64, 23] = InlineArray[Real64, 23]()
    var NumAlphas: Int32 = 0
    var NumNums: Int32 = 0
    var IOStat: Int32 = 0
    
    for GSHPNum in range(state.dataHPWaterToWaterHtg.NumGSHPs):
        var thisGSHP: GshpPeHeatingSpecs = GshpPeHeatingSpecs()
        
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ModuleCompNameUC, GSHPNum + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat)
        
        thisGSHP.Name = AlphArray[0]
        thisGSHP.WWHPPlantType = state.DataPlant.PlantEquipmentType.HPWaterPEHeating
        
        thisGSHP.COP = NumArray[0]
        if NumArray[0] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":COP = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.NomCap = NumArray[1]
        thisGSHP.MinPartLoadRat = NumArray[2]
        thisGSHP.MaxPartLoadRat = NumArray[3]
        thisGSHP.OptPartLoadRat = NumArray[4]
        thisGSHP.LoadSideVolFlowRate = NumArray[5]
        
        if NumArray[5] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Load Side Flow Rate = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.SourceSideVolFlowRate = NumArray[6]
        if NumArray[6] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Source Side Flow Rate = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.LoadSideUACoeff = NumArray[7]
        if NumArray[7] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Load Side Heat Transfer Coefficient = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.SourceSideUACoeff = NumArray[8]
        if NumArray[8] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Source Side Heat Transfer Coefficient = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.CompPistonDisp = NumArray[9]
        if NumArray[9] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Compressor Piston displacement/Storke = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.CompClearanceFactor = NumArray[10]
        if NumArray[10] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Compressor Clearance Factor = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.CompSucPressDrop = NumArray[11]
        if NumArray[11] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(": Pressure Drop = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.SuperheatTemp = NumArray[12]
        if NumArray[12] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Source Side SuperHeat = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.PowerLosses = NumArray[13]
        if NumArray[13] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Compressor Power Loss = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.LossFactor = NumArray[14]
        if NumArray[14] == 0.0:
            state.ShowSevereError(String(ModuleCompName) + String(":Efficiency = 0.0, Heatpump=") + thisGSHP.Name)
            ErrorsFound = True
        
        thisGSHP.HighPressCutoff = NumArray[15]
        if NumArray[15] == 0.0:
            thisGSHP.HighPressCutoff = 500000000.0
        
        thisGSHP.LowPressCutoff = NumArray[16]
        if NumArray[16] == 0.0:
            thisGSHP.LowPressCutoff = 0.0
        
        thisGSHP.SourceSideInletNodeNum = state.GetOnlySingleNode(state, AlphArray[1], ErrorsFound, state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating, thisGSHP.Name, state.Node.FluidType.Water, state.Node.ConnectionType.Inlet, state.Node.CompFluidStream.Primary, state.Node.ObjectIsNotParent)
        
        thisGSHP.SourceSideOutletNodeNum = state.GetOnlySingleNode(state, AlphArray[2], ErrorsFound, state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating, thisGSHP.Name, state.Node.FluidType.Water, state.Node.ConnectionType.Outlet, state.Node.CompFluidStream.Primary, state.Node.ObjectIsNotParent)
        
        thisGSHP.LoadSideInletNodeNum = state.GetOnlySingleNode(state, AlphArray[3], ErrorsFound, state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating, thisGSHP.Name, state.Node.FluidType.Water, state.Node.ConnectionType.Inlet, state.Node.CompFluidStream.Secondary, state.Node.ObjectIsNotParent)
        
        thisGSHP.LoadSideOutletNodeNum = state.GetOnlySingleNode(state, AlphArray[4], ErrorsFound, state.Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating, thisGSHP.Name, state.Node.FluidType.Water, state.Node.ConnectionType.Outlet, state.Node.CompFluidStream.Secondary, state.Node.ObjectIsNotParent)
        
        state.Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[1], AlphArray[2], "Condenser Water Nodes")
        state.Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[3], AlphArray[4], "Hot Water Nodes")
        
        state.PlantUtilities.RegisterPlantCompDesignFlow(state, thisGSHP.SourceSideInletNodeNum, 0.5 * thisGSHP.SourceSideVolFlowRate)
        
        thisGSHP.refrig = state.Fluid.GetRefrig(state, GSHPRefrigerant)
        if thisGSHP.refrig == UnsafePointer[RefrigProps]():
            state.ShowSevereItemNotFound(state, routineName, ModuleCompNameUC, AlphArray[0], "Refrigerant", GSHPRefrigerant)
            ErrorsFound = True
        
        state.dataHPWaterToWaterHtg.GSHP.append(thisGSHP)
    
    if ErrorsFound:
        state.ShowFatalError(String("Errors Found in getting ") + ModuleCompNameUC + String(" Input"))
    
    for GSHPNum in range(state.dataHPWaterToWaterHtg.NumGSHPs):
        let thisGSHP: GshpPeHeatingSpecs = state.dataHPWaterToWaterHtg.GSHP[GSHPNum]
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


struct HeatPumpWaterToWaterHEATINGData:
    var NumGSHPs: Int32
    var GetWWHPHeatingInput: Bool
    var GSHP: DynamicVector[GshpPeHeatingSpecs]

    fn __init__(inout self):
        self.NumGSHPs = 0
        self.GetWWHPHeatingInput = True
        self.GSHP = DynamicVector[GshpPeHeatingSpecs]()

    fn init_constant_state(inout self, state: EnergyPlusData):
        pass

    fn init_state(inout self, state: EnergyPlusData):
        pass

    fn clear_state(inout self):
        self.NumGSHPs = 0
        self.GetWWHPHeatingInput = True
        self.GSHP = DynamicVector[GshpPeHeatingSpecs]()
