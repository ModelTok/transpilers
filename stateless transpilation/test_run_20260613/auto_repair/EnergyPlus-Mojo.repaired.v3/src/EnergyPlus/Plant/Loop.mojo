from ..FluidProperties import GlycolProps, RefrigProps
from ..Plant.Enums import LoopSideLocation, LoopDemandCalcScheme, LoadingScheme, CommonPipeType, PressSimType, LoopDemandTol, PlantEquipmentType, OperationData, HalfLoopData
from LoopSide import HalfLoopContainer
from ..Data.EnergyPlusData import EnergyPlusData
from ..DataBranchAirLoopPlant import MassFlowTolerance
from ..General import ShowWarningError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd
from ..UtilityRoutines import *
from ..Data.EnergyPlusData import dataLoopNodes
from ..Node import FluidType
from ..FluidProperties import Fluid
from ..Plant.DataPlant import *
from memory import memset_zero
from math import abs
from string import String
from utils import format

@value
struct PlantCoilData:
    var tsDesWaterFlowRate: List[Float64]

@value
struct PlantLoopData:
    var Name: String
    var FluidName: String
    var FluidType: FluidType
    var FluidIndex: Int
    var glycol: GlycolProps
    var steam: RefrigProps
    var MFErrIndex: Int
    var MFErrIndex1: Int
    var MFErrIndex2: Int
    var TempSetPointNodeNum: Int
    var MaxBranch: Int
    var MinTemp: Float64
    var MaxTemp: Float64
    var MinTempErrIndex: Int
    var MaxTempErrIndex: Int
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
    var NumOpSchemes: Int
    var OpScheme: List[OperationData]
    var LoadDistribution: LoadingScheme
    var PlantSizNum: Int
    var LoopDemandCalcScheme: LoopDemandCalcScheme
    var CommonPipeType: CommonPipeType
    var EconPlantSideSensedNodeNum: Int
    var EconCondSideSensedNodeNum: Int
    var EconPlacement: Int
    var EconBranch: Int
    var EconComp: Int
    var EconControlTempDiff: Float64
    var LoopHasConnectionComp: Bool
    var TypeOfLoop: LoopType
    var TypeOfWaterLoop: WaterLoopType
    var PressureSimType: PressSimType
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
    var LastLoopSideSimulated: Int
    var plantDesWaterFlowRate: List[Float64]
    var plantCoilObjectNames: List[String]
    var compDesWaterFlowRate: List[PlantCoilData]
    var plantCoilObjectTypes: List[PlantEquipmentType]

    def __init__(inout self):
        self.Name = String("")
        self.FluidName = String("")
        self.FluidType = FluidType.Blank
        self.FluidIndex = 0
        self.glycol = GlycolProps()
        self.steam = RefrigProps()
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
        self.OperationScheme = String("")
        self.NumOpSchemes = 0
        self.OpScheme = List[OperationData]()
        self.LoadDistribution = LoadingScheme.Invalid
        self.PlantSizNum = 0
        self.LoopDemandCalcScheme = LoopDemandCalcScheme.Invalid
        self.CommonPipeType = CommonPipeType.No
        self.EconPlantSideSensedNodeNum = 0
        self.EconCondSideSensedNodeNum = 0
        self.EconPlacement = 0
        self.EconBranch = 0
        self.EconComp = 0
        self.EconControlTempDiff = 0.0
        self.LoopHasConnectionComp = False
        self.TypeOfLoop = LoopType.Invalid
        self.PressureSimType = PressSimType.NoPressure
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
        self.plantCoilObjectTypes = List[PlantEquipmentType]()

    def UpdateLoopSideReportVars(inout self, inout state: EnergyPlusData, OtherSideDemand: Float64, LocalRemLoopDemand: Float64):
        self.InletNodeFlowrate = state.dataLoopNodes.Node[self.LoopSide(LoopSideLocation.Supply).NodeNumIn].MassFlowRate
        self.InletNodeTemperature = state.dataLoopNodes.Node[self.LoopSide(LoopSideLocation.Supply).NodeNumIn].Temp
        self.OutletNodeFlowrate = state.dataLoopNodes.Node[self.LoopSide(LoopSideLocation.Supply).NodeNumOut].MassFlowRate
        self.OutletNodeTemperature = state.dataLoopNodes.Node[self.LoopSide(LoopSideLocation.Supply).NodeNumOut].Temp
        if OtherSideDemand < 0.0:
            self.CoolingDemand = abs(OtherSideDemand)
            self.HeatingDemand = 0.0
            self.DemandNotDispatched = -LocalRemLoopDemand
        else:
            self.HeatingDemand = OtherSideDemand
            self.CoolingDemand = 0.0
            self.DemandNotDispatched = LocalRemLoopDemand
        self.CalcUnmetPlantDemand(state)

    def CalcUnmetPlantDemand(inout self, inout state: EnergyPlusData):
        var RoutineName: String = String("PlantLoopSolver::EvaluateLoopSetPointLoad")
        var RoutineNameAlt: String = String("PlantSupplySide:EvaluateLoopSetPointLoad")
        var MassFlowRate: Float64
        var TargetTemp: Float64
        var LoopSetPointTemperature: Float64
        var LoopSetPointTemperatureHi: Float64
        var LoopSetPointTemperatureLo: Float64
        var LoadToHeatingSetPoint: Float64
        var LoadToCoolingSetPoint: Float64
        var DeltaTemp: Float64
        var Cp: Float64
        var EnthalpySteamSatVapor: Float64
        var EnthalpySteamSatLiquid: Float64
        var LatentHeatSteam: Float64
        var LoadToLoopSetPoint: Float64
        LoadToLoopSetPoint = 0.0
        TargetTemp = state.dataLoopNodes.Node[self.TempSetPointNodeNum].Temp
        MassFlowRate = state.dataLoopNodes.Node[self.TempSetPointNodeNum].MassFlowRate
        if self.FluidType == FluidType.Water:
            Cp = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)
            if self.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                LoopSetPointTemperature = self.LoopSide(LoopSideLocation.Supply).TempSetPoint
                DeltaTemp = LoopSetPointTemperature - TargetTemp
                LoadToLoopSetPoint = MassFlowRate * Cp * DeltaTemp
            elif self.LoopDemandCalcScheme == LoopDemandCalcScheme.DualSetPointDeadBand:
                LoopSetPointTemperatureHi = state.dataLoopNodes.Node[self.TempSetPointNodeNum].TempSetPointHi
                LoopSetPointTemperatureLo = state.dataLoopNodes.Node[self.TempSetPointNodeNum].TempSetPointLo
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
        elif self.FluidType == FluidType.Steam:
            Cp = self.glycol.getSpecificHeat(state, TargetTemp, RoutineName)
            if self.LoopDemandCalcScheme == LoopDemandCalcScheme.SingleSetPoint:
                LoopSetPointTemperature = self.LoopSide(LoopSideLocation.Supply).TempSetPoint
                DeltaTemp = LoopSetPointTemperature - TargetTemp
                EnthalpySteamSatVapor = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 1.0, RoutineNameAlt)
                EnthalpySteamSatLiquid = self.steam.getSatEnthalpy(state, LoopSetPointTemperature, 0.0, RoutineNameAlt)
                LatentHeatSteam = EnthalpySteamSatVapor - EnthalpySteamSatLiquid
                LoadToLoopSetPoint = MassFlowRate * (Cp * DeltaTemp + LatentHeatSteam)
        if abs(LoadToLoopSetPoint) < LoopDemandTol:
            LoadToLoopSetPoint = 0.0
        self.UnmetDemand = LoadToLoopSetPoint

    def CheckLoopExitNode(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
        var LoopInlet: Int
        var LoopOutlet: Int
        var Supply = self.LoopSide(LoopSideLocation.Supply)
        LoopInlet = Supply.NodeNumIn
        LoopOutlet = Supply.NodeNumOut
        if not FirstHVACIteration and not state.dataGlobal.WarmupFlag:
            if abs(state.dataLoopNodes.Node[LoopOutlet].MassFlowRate - state.dataLoopNodes.Node[LoopInlet].MassFlowRate) > MassFlowTolerance:
                if self.MFErrIndex == 0:
                    ShowWarningError(state, "PlantSupplySide: PlantLoop=\"" + self.Name + "\", Error (CheckLoopExitNode) -- Mass Flow Rate Calculation. Outlet and Inlet differ by more than tolerance.")
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, format("Loop inlet node={}, flowrate={:.4f} kg/s", state.dataLoopNodes.NodeID(LoopInlet), state.dataLoopNodes.Node[LoopInlet].MassFlowRate))
                    ShowContinueError(state, format("Loop outlet node={}, flowrate={:.4f} kg/s", state.dataLoopNodes.NodeID(LoopOutlet), state.dataLoopNodes.Node[LoopOutlet].MassFlowRate))
                    ShowContinueError(state, "This loop might be helped by a bypass.")
                ShowRecurringWarningErrorAtEnd(state, "PlantSupplySide: PlantLoop=\"" + self.Name + "\", Error -- Mass Flow Rate Calculation -- continues ** ", self.MFErrIndex)
        state.dataLoopNodes.Node[LoopOutlet].MassFlowRateMax = state.dataLoopNodes.Node[LoopInlet].MassFlowRateMax