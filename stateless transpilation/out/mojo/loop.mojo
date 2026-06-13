from math import abs as math_abs

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataLoopNodes, dataGlobal attributes
# - Node.FluidType: enum with Blank=0, Water=1, Steam=2
# - DataPlant.LoopSideLocation: enum with Supply=0, Demand=1, Num=2
# - DataPlant.LoadingScheme: enum with Invalid=-1, Optimal=0, OverLoading=1
# - DataPlant.LoopDemandCalcScheme: enum with Invalid=-1, SingleSetPoint=0, DualSetPointDeadBand=1
# - DataPlant.CommonPipeType: enum with No=0, Single=1, TwoWay=2
# - DataPlant.PressSimType: enum with NoPressure=0, Num=1
# - DataPlant.LoopDemandTol: Float64 constant
# - Fluid.GlycolProps: type with getSpecificHeat(state, temp, routine_name) -> Float64
# - Fluid.RefrigProps: type with getSatEnthalpy(state, temp, quality, routine_name) -> Float64
# - HalfLoopData: type with NodeNumIn, NodeNumOut, TempSetPoint attributes
# - OperationData: type
# - PlantEquipmentType: enum
# - DataBranchAirLoopPlant.MassFlowTolerance: Float64 constant
# - ShowWarningError(state, msg): function
# - ShowContinueErrorTimeStamp(state, msg): function
# - ShowContinueError(state, msg): function
# - ShowRecurringWarningErrorAtEnd(state, msg, errindex): function
# - state.dataLoopNodes.Node(index): returns node with MassFlowRate, Temp, TempSetPointHi, TempSetPointLo, MassFlowRateMax, NodeID attributes
# - state.dataGlobal.WarmupFlag: boolean
# - format(template, **kwargs): string formatting function

alias LoopType = Int32

alias LoopType_Invalid = Int32(-1)
alias LoopType_Plant = Int32(0)
alias LoopType_Condenser = Int32(1)
alias LoopType_Both = Int32(2)
alias LoopType_Num = Int32(3)

alias WaterLoopType = Int32

alias WaterLoopType_Invalid = Int32(-1)
alias WaterLoopType_HotWater = Int32(0)
alias WaterLoopType_ChilledWater = Int32(1)
alias WaterLoopType_None = Int32(2)
alias WaterLoopType_Num = Int32(3)

fn get_loop_type_names() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("PlantLoop")
    names.append("CondenserLoop")
    names.append("Both")
    return names

fn get_water_loop_type_names() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("HotWater")
    names.append("ChilledWater")
    names.append("None")
    return names

fn get_water_loop_type_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("HOTWATER")
    names.append("CHILLEDWATER")
    names.append("NONE")
    return names

fn get_loop_side_keys() -> List[Int32]:
    var keys = List[Int32]()
    keys.append(0)
    keys.append(1)
    return keys

@value
struct PlantCoilData:
    var tsDesWaterFlowRate: List[Float64]

    fn __init__(inout self):
        self.tsDesWaterFlowRate = List[Float64]()

@value
struct HalfLoopData:
    var NodeNumIn: Int32
    var NodeNumOut: Int32
    var TempSetPoint: Float64

    fn __init__(inout self):
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.TempSetPoint = 0.0

@value
struct HalfLoopContainer:
    var data: List[HalfLoopData]

    fn __init__(inout self):
        self.data = List[HalfLoopData]()
        self.data.append(HalfLoopData())
        self.data.append(HalfLoopData())

    fn __call__(self, ls: Int32) -> ref [self.data.__lifetime__] HalfLoopData:
        return self.data[int(ls)]

@value
struct OperationData:
    pass

@value
struct PlantLoopData:
    var Name: String
    var FluidName: String
    var FluidType: Int32
    var FluidIndex: Int32
    var glycol: UnsafePointer[NoneType]
    var steam: UnsafePointer[NoneType]
    var MFErrIndex: Int32
    var MFErrIndex1: Int32
    var MFErrIndex2: Int32
    var TempSetPointNodeNum: Int32
    var MaxBranch: Int32
    var MinTemp: Float64
    var MaxTemp: Float64
    var MinTempErrIndex: Int32
    var MaxTempErrIndex: Int32
    var MinVolFlowRate: Float64
    var MaxVolFlowRate: Float64
    var MaxVolFlowRateWasAutoSized: Bool
    var MinMassFlowRate: Float64
    var MaxMassFlowRate: Float64
    var Volume: Float64
    var VolumeWasAutoSized: Bool
    var CirculationTime: Float64
    var Mass: Float64
    var EMSCtrl: Bool
    var EMSValue: Float64
    var LoopSide: HalfLoopContainer
    var OperationScheme: String
    var NumOpSchemes: Int32
    var OpScheme: List[OperationData]
    var LoadDistribution: Int32
    var PlantSizNum: Int32
    var LoopDemandCalcScheme: Int32
    var CommonPipeType: Int32
    var EconPlantSideSensedNodeNum: Int32
    var EconCondSideSensedNodeNum: Int32
    var EconPlacement: Int32
    var EconBranch: Int32
    var EconComp: Int32
    var EconControlTempDiff: Float64
    var LoopHasConnectionComp: Bool
    var TypeOfLoop: Int32
    var TypeOfWaterLoop: Int32
    var PressureSimType: Int32
    var HasPressureComponents: Bool
    var PressureDrop: Float64
    var UsePressureForPumpCalcs: Bool
    var PressureEffectiveK: Float64
    var CoolingDemand: Float64
    var HeatingDemand: Float64
    var DemandNotDispatched: Float64
    var UnmetDemand: Float64
    var BypassFrac: Float64
    var InletNodeFlowrate: Float64
    var InletNodeTemperature: Float64
    var OutletNodeFlowrate: Float64
    var OutletNodeTemperature: Float64
    var LastLoopSideSimulated: Int32
    var plantDesWaterFlowRate: List[Float64]
    var plantCoilObjectNames: List[String]
    var compDesWaterFlowRate: List[PlantCoilData]
    var plantCoilObjectTypes: List[Int32]

    fn __init__(inout self):
        self.Name = String()
        self.FluidName = String()
        self.FluidType = 0
        self.FluidIndex = 0
        self.glycol = UnsafePointer[NoneType]()
        self.steam = UnsafePointer[NoneType]()
        self.MFErrIndex = 0
        self.MFErrIndex1 = 0
        self.MFErrIndex2 = 0
        self.TempSetPointNodeNum = 0
        self.MaxBranch = 0
        self.MinTemp = 0.0
        self.MaxTemp = 0.0
        self.MinTempErrIndex = 0
        self.MaxTempErrIndex = 0
        self.MinVolFlowRate = 0.0
        self.MaxVolFlowRate = 0.0
        self.MaxVolFlowRateWasAutoSized = False
        self.MinMassFlowRate = 0.0
        self.MaxMassFlowRate = 0.0
        self.Volume = 0.0
        self.VolumeWasAutoSized = False
        self.CirculationTime = 2.0
        self.Mass = 0.0
        self.EMSCtrl = False
        self.EMSValue = 0.0
        self.LoopSide = HalfLoopContainer()
        self.OperationScheme = String()
        self.NumOpSchemes = 0
        self.OpScheme = List[OperationData]()
        self.LoadDistribution = -1
        self.PlantSizNum = 0
        self.LoopDemandCalcScheme = -1
        self.CommonPipeType = 0
        self.EconPlantSideSensedNodeNum = 0
        self.EconCondSideSensedNodeNum = 0
        self.EconPlacement = 0
        self.EconBranch = 0
        self.EconComp = 0
        self.EconControlTempDiff = 0.0
        self.LoopHasConnectionComp = False
        self.TypeOfLoop = -1
        self.TypeOfWaterLoop = -1
        self.PressureSimType = 0
        self.HasPressureComponents = False
        self.PressureDrop = 0.0
        self.UsePressureForPumpCalcs = False
        self.PressureEffectiveK = 0.0
        self.CoolingDemand = 0.0
        self.HeatingDemand = 0.0
        self.DemandNotDispatched = 0.0
        self.UnmetDemand = 0.0
        self.BypassFrac = 0.0
        self.InletNodeFlowrate = 0.0
        self.InletNodeTemperature = 0.0
        self.OutletNodeFlowrate = 0.0
        self.OutletNodeTemperature = 0.0
        self.LastLoopSideSimulated = 0
        self.plantDesWaterFlowRate = List[Float64]()
        self.plantCoilObjectNames = List[String]()
        self.compDesWaterFlowRate = List[PlantCoilData]()
        self.plantCoilObjectTypes = List[Int32]()

    fn UpdateLoopSideReportVars(inout self, state: UnsafePointer[NoneType], OtherSideDemand: Float64, LocalRemLoopDemand: Float64):
        self.InletNodeFlowrate = state.dataLoopNodes.Node(self.LoopSide(0).NodeNumIn).MassFlowRate
        self.InletNodeTemperature = state.dataLoopNodes.Node(self.LoopSide(0).NodeNumIn).Temp
        self.OutletNodeFlowrate = state.dataLoopNodes.Node(self.LoopSide(0).NodeNumOut).MassFlowRate
        self.OutletNodeTemperature = state.dataLoopNodes.Node(self.LoopSide(0).NodeNumOut).Temp

        if OtherSideDemand < 0.0:
            self.CoolingDemand = abs(OtherSideDemand)
            self.HeatingDemand = 0.0
            self.DemandNotDispatched = -LocalRemLoopDemand
        else:
            self.HeatingDemand = OtherSideDemand
            self.CoolingDemand = 0.0
            self.DemandNotDispatched = LocalRemLoopDemand

        self.CalcUnmetPlantDemand(state)

    fn CalcUnmetPlantDemand(inout self, state: UnsafePointer[NoneType]):
        var RoutineName: String = String("PlantLoopSolver::EvaluateLoopSetPointLoad")
        var RoutineNameAlt: String = String("PlantSupplySide:EvaluateLoopSetPointLoad")

        var LoadToLoopSetPoint: Float64 = 0.0

        var TargetTemp: Float64 = state.dataLoopNodes.Node(self.TempSetPointNodeNum).Temp
        var MassFlowRate: Float64 = state.dataLoopNodes.Node(self.TempSetPointNodeNum).MassFlowRate

        if self.FluidType == 1:
            var Cp: Float64 = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)

            if self.LoopDemandCalcScheme == 0:
                var LoopSetPointTemperature: Float64 = self.LoopSide(0).TempSetPoint
                var DeltaTemp: Float64 = LoopSetPointTemperature - TargetTemp
                LoadToLoopSetPoint = MassFlowRate * Cp * DeltaTemp
            elif self.LoopDemandCalcScheme == 1:
                var LoopSetPointTemperatureHi: Float64 = state.dataLoopNodes.Node(self.TempSetPointNodeNum).TempSetPointHi
                var LoopSetPointTemperatureLo: Float64 = state.dataLoopNodes.Node(self.TempSetPointNodeNum).TempSetPointLo

                if MassFlowRate > 0.0:
                    var LoadToHeatingSetPoint: Float64 = MassFlowRate * Cp * (LoopSetPointTemperatureLo - TargetTemp)
                    var LoadToCoolingSetPoint: Float64 = MassFlowRate * Cp * (LoopSetPointTemperatureHi - TargetTemp)
                    if LoadToHeatingSetPoint > 0.0 and LoadToCoolingSetPoint > 0.0:
                        LoadToLoopSetPoint = LoadToHeatingSetPoint
                    elif LoadToHeatingSetPoint < 0.0 and LoadToCoolingSetPoint < 0.0:
                        LoadToLoopSetPoint = LoadToCoolingSetPoint
                    elif LoadToHeatingSetPoint <= 0.0 and LoadToCoolingSetPoint >= 0.0:
                        LoadToLoopSetPoint = 0.0
                else:
                    LoadToLoopSetPoint = 0.0

        elif self.FluidType == 2:
            var Cp: Float64 = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)

            if self.LoopDemandCalcScheme == 0:
                var LoopSetPointTemperature: Float64 = self.LoopSide(0).TempSetPoint
                var DeltaTemp: Float64 = LoopSetPointTemperature - TargetTemp

                var EnthalpySteamSatVapor: Float64 = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 1.0, RoutineNameAlt)
                var EnthalpySteamSatLiquid: Float64 = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 0.0, RoutineNameAlt)
                var LatentHeatSteam: Float64 = EnthalpySteamSatVapor - EnthalpySteamSatLiquid

                LoadToLoopSetPoint = MassFlowRate * (Cp * DeltaTemp + LatentHeatSteam)

        var LoopDemandTol: Float64 = 0.001
        if abs(LoadToLoopSetPoint) < LoopDemandTol:
            LoadToLoopSetPoint = 0.0

        self.UnmetDemand = LoadToLoopSetPoint

    fn CheckLoopExitNode(inout self, state: UnsafePointer[NoneType], FirstHVACIteration: Bool):
        var Supply: HalfLoopData = self.LoopSide(0)
        var LoopInlet: Int32 = Supply.NodeNumIn
        var LoopOutlet: Int32 = Supply.NodeNumOut

        if not FirstHVACIteration and not state.dataGlobal.WarmupFlag:
            var MassFlowTolerance: Float64 = 0.001
            if abs(state.dataLoopNodes.Node(LoopOutlet).MassFlowRate - state.dataLoopNodes.Node(LoopInlet).MassFlowRate) > MassFlowTolerance:
                if self.MFErrIndex == 0:
                    state.ShowWarningError(state,
                                         "PlantSupplySide: PlantLoop=\"" + self.Name +
                                         "\", Error (CheckLoopExitNode) -- Mass Flow Rate Calculation. Outlet and Inlet differ by more than tolerance.")
                    state.ShowContinueErrorTimeStamp(state, "")
                    state.ShowContinueError(state,
                                          state.format("Loop inlet node={}, flowrate={:.4R} kg/s",
                                                             state.dataLoopNodes.NodeID(LoopInlet),
                                                             state.dataLoopNodes.Node(LoopInlet).MassFlowRate))
                    state.ShowContinueError(state,
                                          state.format("Loop outlet node={}, flowrate={:.4R} kg/s",
                                                             state.dataLoopNodes.NodeID(LoopOutlet),
                                                             state.dataLoopNodes.Node(LoopOutlet).MassFlowRate))
                    state.ShowContinueError(state, "This loop might be helped by a bypass.")

                state.ShowRecurringWarningErrorAtEnd(
                    state, "PlantSupplySide: PlantLoop=\"" + self.Name + "\", Error -- Mass Flow Rate Calculation -- continues ** ", self.MFErrIndex)

        state.dataLoopNodes.Node(LoopOutlet).MassFlowRateMax = state.dataLoopNodes.Node(LoopInlet).MassFlowRateMax
