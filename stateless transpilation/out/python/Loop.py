from dataclasses import dataclass, field
from typing import List, Optional, Protocol
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataLoopNodes, dataGlobal attributes
# - Node.FluidType: enum with Blank=0, Water=1, Steam=2
# - DataPlant.LoopSideLocation: enum with Supply=0, Demand=1, Num=2
# - DataPlant.LoadingScheme: enum with Invalid=-1, Optimal=0, OverLoading=1
# - DataPlant.LoopDemandCalcScheme: enum with Invalid=-1, SingleSetPoint=0, DualSetPointDeadBand=1
# - DataPlant.CommonPipeType: enum with No=0, Single=1, TwoWay=2
# - DataPlant.PressSimType: enum with NoPressure=0, Num=1
# - DataPlant.LoopDemandTol: float constant
# - Fluid.GlycolProps: type with getSpecificHeat(state, temp, routine_name) -> float
# - Fluid.RefrigProps: type with getSatEnthalpy(state, temp, quality, routine_name) -> float
# - HalfLoopData: type with NodeNumIn, NodeNumOut, TempSetPoint attributes
# - OperationData: type
# - PlantEquipmentType: enum
# - DataBranchAirLoopPlant.MassFlowTolerance: float constant
# - ShowWarningError(state, msg): function
# - ShowContinueErrorTimeStamp(state, msg): function
# - ShowContinueError(state, msg): function
# - ShowRecurringWarningErrorAtEnd(state, msg, errindex): function
# - state.dataLoopNodes.Node(index): returns node with MassFlowRate, Temp, TempSetPointHi, TempSetPointLo, MassFlowRateMax, NodeID attributes
# - state.dataGlobal.WarmupFlag: boolean
# - format(template, **kwargs): string formatting function

class LoopType(IntEnum):
    Invalid = -1
    Plant = 0
    Condenser = 1
    Both = 2
    Num = 3

class WaterLoopType(IntEnum):
    Invalid = -1
    HotWater = 0
    ChilledWater = 1
    None_ = 2
    Num = 3

LOOP_TYPE_NAMES = ["PlantLoop", "CondenserLoop", "Both"]
WATER_LOOP_TYPE_NAMES = ["HotWater", "ChilledWater", "None"]
WATER_LOOP_TYPE_NAMES_UC = ["HOTWATER", "CHILLEDWATER", "NONE"]

LOOP_SIDE_KEYS = [0, 1]

@dataclass
class PlantCoilData:
    tsDesWaterFlowRate: List[float] = field(default_factory=list)

@dataclass
class HalfLoopData:
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    TempSetPoint: float = 0.0

@dataclass
class HalfLoopContainer:
    data: List[HalfLoopData] = field(default_factory=lambda: [HalfLoopData(), HalfLoopData()])
    
    def __call__(self, ls: int) -> HalfLoopData:
        return self.data[int(ls)]

@dataclass
class OperationData:
    pass

@dataclass
class PlantLoopData:
    Name: str = ""
    FluidName: str = ""
    FluidType: int = 0
    FluidIndex: int = 0
    glycol: Optional[object] = None
    steam: Optional[object] = None
    MFErrIndex: int = 0
    MFErrIndex1: int = 0
    MFErrIndex2: int = 0
    TempSetPointNodeNum: int = 0
    MaxBranch: int = 0
    MinTemp: float = 0.0
    MaxTemp: float = 0.0
    MinTempErrIndex: int = 0
    MaxTempErrIndex: int = 0
    MinVolFlowRate: float = 0.0
    MaxVolFlowRate: float = 0.0
    MaxVolFlowRateWasAutoSized: bool = False
    MinMassFlowRate: float = 0.0
    MaxMassFlowRate: float = 0.0
    Volume: float = 0.0
    VolumeWasAutoSized: bool = False
    CirculationTime: float = 2.0
    Mass: float = 0.0
    EMSCtrl: bool = False
    EMSValue: float = 0.0
    LoopSide: HalfLoopContainer = field(default_factory=HalfLoopContainer)
    OperationScheme: str = ""
    NumOpSchemes: int = 0
    OpScheme: List[OperationData] = field(default_factory=list)
    LoadDistribution: int = -1
    PlantSizNum: int = 0
    LoopDemandCalcScheme: int = -1
    CommonPipeType: int = 0
    EconPlantSideSensedNodeNum: int = 0
    EconCondSideSensedNodeNum: int = 0
    EconPlacement: int = 0
    EconBranch: int = 0
    EconComp: int = 0
    EconControlTempDiff: float = 0.0
    LoopHasConnectionComp: bool = False
    TypeOfLoop: int = -1
    TypeOfWaterLoop: int = -1
    PressureSimType: int = 0
    HasPressureComponents: bool = False
    PressureDrop: float = 0.0
    UsePressureForPumpCalcs: bool = False
    PressureEffectiveK: float = 0.0
    CoolingDemand: float = 0.0
    HeatingDemand: float = 0.0
    DemandNotDispatched: float = 0.0
    UnmetDemand: float = 0.0
    BypassFrac: float = 0.0
    InletNodeFlowrate: float = 0.0
    InletNodeTemperature: float = 0.0
    OutletNodeFlowrate: float = 0.0
    OutletNodeTemperature: float = 0.0
    LastLoopSideSimulated: int = 0
    plantDesWaterFlowRate: List[float] = field(default_factory=list)
    plantCoilObjectNames: List[str] = field(default_factory=list)
    compDesWaterFlowRate: List[PlantCoilData] = field(default_factory=list)
    plantCoilObjectTypes: List[int] = field(default_factory=list)

    def UpdateLoopSideReportVars(self, state, OtherSideDemand: float, LocalRemLoopDemand: float) -> None:
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

    def CalcUnmetPlantDemand(self, state) -> None:
        RoutineName = "PlantLoopSolver::EvaluateLoopSetPointLoad"
        RoutineNameAlt = "PlantSupplySide:EvaluateLoopSetPointLoad"

        LoadToLoopSetPoint = 0.0

        TargetTemp = state.dataLoopNodes.Node(self.TempSetPointNodeNum).Temp
        MassFlowRate = state.dataLoopNodes.Node(self.TempSetPointNodeNum).MassFlowRate

        if self.FluidType == 1:
            Cp = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)

            if self.LoopDemandCalcScheme == 0:
                LoopSetPointTemperature = self.LoopSide(0).TempSetPoint
                DeltaTemp = LoopSetPointTemperature - TargetTemp
                LoadToLoopSetPoint = MassFlowRate * Cp * DeltaTemp
            elif self.LoopDemandCalcScheme == 1:
                LoopSetPointTemperatureHi = state.dataLoopNodes.Node(self.TempSetPointNodeNum).TempSetPointHi
                LoopSetPointTemperatureLo = state.dataLoopNodes.Node(self.TempSetPointNodeNum).TempSetPointLo

                if MassFlowRate > 0.0:
                    LoadToHeatingSetPoint = MassFlowRate * Cp * (LoopSetPointTemperatureLo - TargetTemp)
                    LoadToCoolingSetPoint = MassFlowRate * Cp * (LoopSetPointTemperatureHi - TargetTemp)
                    if LoadToHeatingSetPoint > 0.0 and LoadToCoolingSetPoint > 0.0:
                        LoadToLoopSetPoint = LoadToHeatingSetPoint
                    elif LoadToHeatingSetPoint < 0.0 and LoadToCoolingSetPoint < 0.0:
                        LoadToLoopSetPoint = LoadToCoolingSetPoint
                    elif LoadToHeatingSetPoint <= 0.0 and LoadToCoolingSetPoint >= 0.0:
                        LoadToLoopSetPoint = 0.0
                else:
                    LoadToLoopSetPoint = 0.0

        elif self.FluidType == 2:
            Cp = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)

            if self.LoopDemandCalcScheme == 0:
                LoopSetPointTemperature = self.LoopSide(0).TempSetPoint
                DeltaTemp = LoopSetPointTemperature - TargetTemp

                EnthalpySteamSatVapor = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 1.0, RoutineNameAlt)
                EnthalpySteamSatLiquid = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 0.0, RoutineNameAlt)
                LatentHeatSteam = EnthalpySteamSatVapor - EnthalpySteamSatLiquid

                LoadToLoopSetPoint = MassFlowRate * (Cp * DeltaTemp + LatentHeatSteam)

        LoopDemandTol = 0.001
        if abs(LoadToLoopSetPoint) < LoopDemandTol:
            LoadToLoopSetPoint = 0.0

        self.UnmetDemand = LoadToLoopSetPoint

    def CheckLoopExitNode(self, state, FirstHVACIteration: bool) -> None:
        Supply = self.LoopSide(0)
        LoopInlet = Supply.NodeNumIn
        LoopOutlet = Supply.NodeNumOut

        if not FirstHVACIteration and not state.dataGlobal.WarmupFlag:
            MassFlowTolerance = 0.001
            if abs(state.dataLoopNodes.Node(LoopOutlet).MassFlowRate - state.dataLoopNodes.Node(LoopInlet).MassFlowRate) > MassFlowTolerance:
                if self.MFErrIndex == 0:
                    from_import_format = state.format
                    from_ShowWarningError = state.ShowWarningError
                    from_ShowContinueErrorTimeStamp = state.ShowContinueErrorTimeStamp
                    from_ShowContinueError = state.ShowContinueError

                    from_ShowWarningError(state,
                                         "PlantSupplySide: PlantLoop=\"" + self.Name +
                                         "\", Error (CheckLoopExitNode) -- Mass Flow Rate Calculation. Outlet and Inlet differ by more than tolerance.")
                    from_ShowContinueErrorTimeStamp(state, "")
                    from_ShowContinueError(state,
                                          from_import_format("Loop inlet node={}, flowrate={:.4R} kg/s",
                                                             state.dataLoopNodes.NodeID(LoopInlet),
                                                             state.dataLoopNodes.Node(LoopInlet).MassFlowRate))
                    from_ShowContinueError(state,
                                          from_import_format("Loop outlet node={}, flowrate={:.4R} kg/s",
                                                             state.dataLoopNodes.NodeID(LoopOutlet),
                                                             state.dataLoopNodes.Node(LoopOutlet).MassFlowRate))
                    from_ShowContinueError(state, "This loop might be helped by a bypass.")

                from_ShowRecurringWarningErrorAtEnd = state.ShowRecurringWarningErrorAtEnd
                from_ShowRecurringWarningErrorAtEnd(
                    state, "PlantSupplySide: PlantLoop=\"" + self.Name + "\", Error -- Mass Flow Rate Calculation -- continues ** ", self.MFErrIndex)

        state.dataLoopNodes.Node(LoopOutlet).MassFlowRateMax = state.dataLoopNodes.Node(LoopInlet).MassFlowRateMax
