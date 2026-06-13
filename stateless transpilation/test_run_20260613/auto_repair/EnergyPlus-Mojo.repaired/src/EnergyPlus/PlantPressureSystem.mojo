from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchAirLoopPlant import PressureCurveType, *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.OutputProcessor import SetupOutputVariable, Constant
from EnergyPlus.Plant.DataPlant import DataPlant, PlantLoop, LoopSideLocation, PressureCall, PressSimType, CommonPipeType, PlantEquipmentTypeIsPump
from EnergyPlus.UtilityRoutines import ShowSevereError, ShowContinueError, ShowWarningError, ShowFatalError
from EnergyPlus.CurveManager import CurveValue, PressureCurveValue
from math import sqrt, abs

# Helper to mimic ObjexxFCL pow_2
def pow_2(x: Float64) -> Float64:
    return x * x

# Base struct for global state (simplified)
struct BaseGlobalStruct:
    def init_constant_state(inout self, inout state: EnergyPlusData): pass
    def init_state(inout self, inout state: EnergyPlusData): pass
    def clear_state(inout self): pass

struct PlantPressureSysData(BaseGlobalStruct):
    var InitPressureDropOneTimeInit: Bool = True
    var LoopInit: List[Bool] = List[Bool]()
    var FullParallelBranchSetFound: List[Bool] = [False, False]
    var CommonPipeErrorEncountered: Bool = False
    var ErrorCounter: Int = 0
    var ZeroKWarningCounter: Int = 0
    var MaxIterWarningCounter: Int = 0

    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self.InitPressureDropOneTimeInit = True
        self.LoopInit.clear()
        self.FullParallelBranchSetFound = [False, False]
        self.CommonPipeErrorEncountered = False
        self.ErrorCounter = 0
        self.ZeroKWarningCounter = 0
        self.MaxIterWarningCounter = 0

# ------------------------------------------------------------------------------
def SimPressureDropSystem(
    inout state: EnergyPlusData,
    LoopNum: Int,
    FirstHVACIteration: Bool,
    CallType: DataPlant.PressureCall,
    LoopSideNum: DataPlant.LoopSideLocation = DataPlant.LoopSideLocation.Invalid,
    BranchNum: Int = -1
):
    if ((state.dataPlnt.PlantLoop[LoopNum-1].PressureSimType == DataPlant.PressSimType.NoPressure) and
        ((CallType == DataPlant.PressureCall.Calc) or (CallType == DataPlant.PressureCall.Update))):
        return
    if CallType == DataPlant.PressureCall.Init:
        InitPressureDrop(state, LoopNum, FirstHVACIteration)
    elif CallType == DataPlant.PressureCall.Calc:
        BranchPressureDrop(state, LoopNum, LoopSideNum, BranchNum)
    elif CallType == DataPlant.PressureCall.Update:
        UpdatePressureDrop(state, LoopNum)
    else:

def InitPressureDrop(inout state: EnergyPlusData, LoopNum: Int, FirstHVACIteration: Bool):
    if state.dataPlantPressureSys.InitPressureDropOneTimeInit:
        state.dataPlantPressureSys.LoopInit = [True] * len(state.dataPlnt.PlantLoop)
        state.dataPlantPressureSys.InitPressureDropOneTimeInit = False

    var loop = state.dataPlnt.PlantLoop[LoopNum-1]
    if state.dataPlantPressureSys.LoopInit[LoopNum-1]:
        var ErrorsFound: Bool = False
        for LoopSideNum in [DataPlant.LoopSideLocation.Demand, DataPlant.LoopSideLocation.Supply]:
            var loop_side = loop.LoopSide[LoopSideNum.value]  # Need mapping from enum to index? Assume .value gives 0 or 1
            for BranchNum in range(len(loop_side.Branch)):
                var branch = loop_side.Branch[BranchNum]
                if branch.PressureCurveIndex > 0:
                    branch.HasPressureComponents = True
                    loop_side.HasPressureComponents = True
                    loop.HasPressureComponents = True
                    SetupOutputVariable(
                        state,
                        "Plant Branch Pressure Difference",
                        Constant.Units.Pa,
                        branch.PressureDrop,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        branch.Name
                    )
            if loop_side.HasPressureComponents:
                if LoopSideNum == DataPlant.LoopSideLocation.Demand:
                    SetupOutputVariable(
                        state,
                        "Plant Demand Side Loop Pressure Difference",
                        Constant.Units.Pa,
                        loop_side.PressureDrop,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        loop.Name
                    )
                elif LoopSideNum == DataPlant.LoopSideLocation.Supply:
                    SetupOutputVariable(
                        state,
                        "Plant Supply Side Loop Pressure Difference",
                        Constant.Units.Pa,
                        loop_side.PressureDrop,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        loop.Name
                    )

        if loop.HasPressureComponents:
            var SeriesPressureComponentFound: Bool = False
            state.dataPlantPressureSys.FullParallelBranchSetFound[DataPlant.LoopSideLocation.Demand.value] = False
            state.dataPlantPressureSys.FullParallelBranchSetFound[DataPlant.LoopSideLocation.Supply.value] = False
            SetupOutputVariable(
                state,
                "Plant Loop Pressure Difference",
                Constant.Units.Pa,
                loop.PressureDrop,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                loop.Name
            )
            for LoopSideNum in [DataPlant.LoopSideLocation.Demand, DataPlant.LoopSideLocation.Supply]:
                var loop_side = loop.LoopSide[LoopSideNum.value]
                var BranchPressureTally: Int = 0
                var NumBranches: Int = len(loop_side.Branch)
                if NumBranches > 2:
                    for BranchNum in range(1, NumBranches-1):
                        if loop_side.Branch[BranchNum].HasPressureComponents:
                            loop_side.HasParallelPressComps = True
                            BranchPressureTally += 1
                if BranchPressureTally == 0:

                elif BranchPressureTally == (len(loop_side.Branch) - 2):
                    state.dataPlantPressureSys.FullParallelBranchSetFound[LoopSideNum.value] = True
                else:
                    ShowSevereError(state, f"Pressure drop component configuration error detected on loop: {loop.Name}")
                    ShowContinueError(state, "Pressure drop components must be on ALL or NONE of the parallel branches.")
                    ShowContinueError(state, "Partial distribution is not allowed.")
                    ErrorsFound = True
                if loop_side.Branch[0].HasPressureComponents or loop_side.Branch[NumBranches-1].HasPressureComponents:
                    SeriesPressureComponentFound = True

            if state.dataPlantPressureSys.FullParallelBranchSetFound[DataPlant.LoopSideLocation.Demand.value] or \
               state.dataPlantPressureSys.FullParallelBranchSetFound[DataPlant.LoopSideLocation.Supply.value] or \
               SeriesPressureComponentFound:

            else:
                ShowSevereError(state, f"Pressure drop component configuration error detected on loop: {loop.Name}")
                ShowContinueError(state, "The loop has at least one fluid path which does not encounter a pressure component.")
                ShowContinueError(state, "Either use at least one serial component for pressure drop OR all possible parallel paths")
                ShowContinueError(state, "must be pressure drop components.")
                ErrorsFound = True

        if ErrorsFound:
            ShowFatalError(state, "Preceding errors cause program termination")

        if loop.HasPressureComponents and (loop.PressureSimType == DataPlant.PressSimType.NoPressure):
            ShowWarningError(state, f"Error for pressure simulation on plant loop: {loop.Name}")
            ShowContinueError(state, "Plant loop contains pressure simulation components on the branches,")
            ShowContinueError(state, " yet in the PlantLoop object, there is no pressure simulation specified.")
            ShowContinueError(state, "Simulation continues, ignoring pressure simulation data.")
        elif (not loop.HasPressureComponents) and (loop.PressureSimType != DataPlant.PressSimType.NoPressure):
            ShowWarningError(state, f"Error for pressure simulation on plant loop: {loop.Name}")
            ShowContinueError(state, "Plant loop is requesting a pressure simulation,")
            ShowContinueError(state, " yet there are no pressure simulation components detected on any of the branches in that loop.")
            ShowContinueError(state, "Simulation continues, ignoring pressure simulation data.")

        state.dataPlantPressureSys.LoopInit[LoopNum-1] = False

    if loop.HasPressureComponents and FirstHVACIteration:
        for LoopSideNum in [DataPlant.LoopSideLocation.Demand, DataPlant.LoopSideLocation.Supply]:
            var loop_side = loop.LoopSide[LoopSideNum.value]
            for BranchNum in range(len(loop_side.Branch)):
                var branch = loop_side.Branch[BranchNum]
                for CompNum in range(len(branch.Comp)):
                    var component = branch.Comp[CompNum]
                    state.dataLoopNodes.Node[component.NodeNumIn-1].Press = state.dataEnvrn.StdBaroPress
                    state.dataLoopNodes.Node[component.NodeNumOut-1].Press = state.dataEnvrn.StdBaroPress

    if loop.HasPressureComponents:
        loop.UsePressureForPumpCalcs = not FirstHVACIteration
    else:
        loop.UsePressureForPumpCalcs = False

    if loop.HasPressureComponents:
        if loop.CommonPipeType != DataPlant.CommonPipeType.No:
            if not state.dataPlantPressureSys.CommonPipeErrorEncountered:
                ShowSevereError(state, f"Invalid pressure simulation configuration for Plant Loop={loop.Name}")
                ShowContinueError(state, "Currently pressure simulations cannot be performed for loops with common pipes.")
                ShowContinueError(state, "To repair, either remove the common pipe simulation, or remove the pressure simulation.")
                ShowContinueError(state, "The simulation will continue, but the pump power is not updated with pressure drop data.")
                ShowContinueError(state, "Check all results including node pressures to ensure proper simulation.")
                ShowContinueError(state, "This message is reported once, but may have been encountered in multiple loops.")
                state.dataPlantPressureSys.CommonPipeErrorEncountered = True
            loop.UsePressureForPumpCalcs = False

def BranchPressureDrop(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSideNum: DataPlant.LoopSideLocation,
    BranchNum: Int
):
    const alias RoutineName: StringLiteral = "CalcPlantPressureSystem"
    var InletNodeNum: Int
    var pressureCurveType: DataBranchAirLoopPlant.PressureCurveType
    var PressureCurveIndex: Int
    var NodeMassFlow: Float64
    var NodeTemperature: Float64
    var NodeDensity: Float64
    var NodeViscosity: Float64
    var BranchDeltaPress: Float64 = 0.0

    var branch = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum]
    if not branch.HasPressureComponents:
        branch.PressureDrop = 0.0
        branch.PressureEffectiveK = 0.0
        return

    InletNodeNum = branch.NodeNumIn
    pressureCurveType = branch.PressureCurveType
    PressureCurveIndex = branch.PressureCurveIndex
    NodeMassFlow = state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate
    NodeTemperature = state.dataLoopNodes.Node[InletNodeNum-1].Temp
    NodeDensity = state.dataPlnt.PlantLoop[LoopNum-1].glycol.getDensity(state, NodeTemperature, RoutineName)
    NodeViscosity = state.dataPlnt.PlantLoop[LoopNum-1].glycol.getViscosity(state, NodeTemperature, RoutineName)

    if pressureCurveType == DataBranchAirLoopPlant.PressureCurveType.Pressure:
        BranchDeltaPress = PressureCurveValue(state, PressureCurveIndex, NodeMassFlow, NodeDensity, NodeViscosity)
    elif pressureCurveType == DataBranchAirLoopPlant.PressureCurveType.Generic:
        BranchDeltaPress = CurveValue(state, PressureCurveIndex, NodeMassFlow)
    else:
        state.dataPlantPressureSys.ErrorCounter += 1
        if state.dataPlantPressureSys.ErrorCounter == 1:
            ShowSevereError(state, "Plant pressure simulation encountered a branch which contains invalid branch pressure curve type.")
            ShowContinueError(state,
                              f"Occurs for branch: {branch.Name}")
            ShowContinueError(state, "This error will be issued only once, although other branches may encounter the same problem")
            ShowContinueError(state, "For now, pressure drop on this branch will be set to zero.")
            ShowContinueError(state, "Verify all pressure inputs and pressure drop output variables to ensure proper simulation")

    branch.PressureDrop = BranchDeltaPress
    if NodeMassFlow > 0.0:
        branch.PressureEffectiveK = BranchDeltaPress / pow_2(NodeMassFlow)
    else:
        branch.PressureEffectiveK = 0.0

def UpdatePressureDrop(inout state: EnergyPlusData, LoopNum: Int):
    if not state.dataPlnt.PlantLoop[LoopNum-1].HasPressureComponents:
        return

    var BranchNum: Int
    var LoopSidePressureDrop: Float64
    var LoopPressureDrop: Float64
    var ParallelBranchPressureDrops: List[Float64]
    var ParallelBranchInletPressures: List[Float64]
    var ParallelBranchCounter: Int
    var SplitterInletPressure: Float64
    var MixerPressure: Float64
    var FoundAPumpOnBranch: Bool = False
    var EffectiveLoopKValue: Float64
    var EffectiveLoopSideKValue: Float64
    var TempVal_SumOfOneByRootK: Float64

    FoundAPumpOnBranch = False
    LoopPressureDrop = 0.0

    for LoopSideNum in [DataPlant.LoopSideLocation.Demand, DataPlant.LoopSideLocation.Supply]:
        LoopSidePressureDrop = 0.0
        var NumBranches: Int = len(state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch)
        if NumBranches == 1:
            BranchNum = 0
            var BranchPressureDropValue: Float64 = 0.0
            DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum, BranchPressureDropValue, FoundAPumpOnBranch)
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
        elif NumBranches > 1:
            BranchNum = NumBranches - 1
            var BranchPressureDropValue: Float64 = 0.0
            DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum, BranchPressureDropValue, FoundAPumpOnBranch)
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            MixerPressure = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum].NodeNumIn-1].Press
            PassPressureAcrossMixer(state, LoopNum, LoopSideNum, MixerPressure, NumBranches)

            ParallelBranchPressureDrops = List[Float64]()
            ParallelBranchInletPressures = List[Float64]()
            ParallelBranchPressureDrops = [0.0] * (NumBranches - 2)
            ParallelBranchInletPressures = [0.0] * (NumBranches - 2)

            ParallelBranchCounter = 0
            FoundAPumpOnBranch = False
            for BranchNum in range(NumBranches-2, 0, -1):
                ParallelBranchCounter += 1
                var tempBDrop: Float64 = 0.0
                DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum, tempBDrop, FoundAPumpOnBranch)
                ParallelBranchPressureDrops[ParallelBranchCounter-1] = tempBDrop
                ParallelBranchInletPressures[ParallelBranchCounter-1] = \
                    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum].NodeNumIn-1].Press

            SplitterInletPressure = max(ParallelBranchInletPressures)
            BranchPressureDropValue = max(ParallelBranchPressureDrops)
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue

            if FoundAPumpOnBranch:
                if LoopSideNum == DataPlant.LoopSideLocation.Demand:
                    ShowSevereError(state, "Pressure system information was found in a demand pump (common pipe) simulation")
                    ShowContinueError(state, "Currently the pressure simulation is not set up to handle common pipe simulations")
                    ShowContinueError(state, "Either modify simulation to avoid common pipe, or remove pressure curve information")
                    ShowFatalError(state, "Pressure configuration mismatch causes program termination")

            if not FoundAPumpOnBranch:
                PassPressureAcrossSplitter(state, LoopNum, LoopSideNum, SplitterInletPressure)
                BranchNum = 0
                DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum, BranchPressureDropValue, FoundAPumpOnBranch)
                LoopSidePressureDrop += BranchPressureDropValue
                LoopPressureDrop += BranchPressureDropValue
                if LoopSideNum == DataPlant.LoopSideLocation.Demand:
                    PassPressureAcrossInterface(state, LoopNum)

        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].PressureDrop = LoopSidePressureDrop

    state.dataPlnt.PlantLoop[LoopNum-1].PressureDrop = LoopPressureDrop

    EffectiveLoopKValue = 0.0
    for LoopSideNum in [DataPlant.LoopSideLocation.Demand, DataPlant.LoopSideLocation.Supply]:
        EffectiveLoopSideKValue = 0.0
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[0].PressureEffectiveK
        if len(state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch) == 1:
            continue
        TempVal_SumOfOneByRootK = 0.0
        for BranchNum in range(1, len(state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch) - 1):
            var k = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum].PressureEffectiveK
            if k > 0.0:
                TempVal_SumOfOneByRootK += (1.0 / sqrt(k))
        if TempVal_SumOfOneByRootK > 0.0:
            EffectiveLoopSideKValue += (1.0 / pow_2(TempVal_SumOfOneByRootK))
        BranchNum = len(state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch) - 1
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum].PressureEffectiveK
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].PressureEffectiveK = EffectiveLoopSideKValue
        EffectiveLoopKValue += EffectiveLoopSideKValue

    state.dataPlnt.PlantLoop[LoopNum-1].PressureEffectiveK = EffectiveLoopKValue

def DistributePressureOnBranch(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSideNum: DataPlant.LoopSideLocation,
    BranchNum: Int,
    inout BranchPressureDrop: Float64,
    inout PumpFound: Bool
):
    var TempBranchPressureDrop: Float64 = 0.0
    BranchPressureDrop = 0.0
    var branch = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum]
    var NumCompsOnBranch: Int = len(branch.Comp)
    if branch.HasPressureComponents:
        TempBranchPressureDrop = branch.PressureDrop

    if DataPlant.PlantEquipmentTypeIsPump[branch.Comp[NumCompsOnBranch-1].Type.value]:
        PumpFound = True
        if TempBranchPressureDrop != 0.0:
            ShowSevereError(state, f"Error in plant pressure simulation for plant loop: {state.dataPlnt.PlantLoop[LoopNum-1].Name}")
            if LoopSideNum == DataPlant.LoopSideLocation.Demand:
                ShowContinueError(state,
                                  f"Occurs for demand side, branch: {branch.Name}")
            elif LoopSideNum == DataPlant.LoopSideLocation.Supply:
                ShowContinueError(state,
                                  f"Occurs for supply side, branch: {branch.Name}")
            ShowContinueError(state, "Branch contains only a single pump component, yet also a pressure drop component.")
            ShowContinueError(state, "Either add a second component to this branch after the pump, or move pressure drop data.")
            ShowFatalError(state, "Preceding pressure drop error causes program termination")
        return

    if branch.HasPressureComponents:
        BranchPressureDrop = TempBranchPressureDrop

    state.dataLoopNodes.Node[branch.Comp[NumCompsOnBranch-1].NodeNumIn-1].Press = \
        state.dataLoopNodes.Node[branch.Comp[NumCompsOnBranch-1].NodeNumOut-1].Press + BranchPressureDrop

    if NumCompsOnBranch > 1:
        for CompNum in range(NumCompsOnBranch-1, 0, -1):
            if DataPlant.PlantEquipmentTypeIsPump[branch.Comp[CompNum-1].Type.value]:
                PumpFound = True
                break
            state.dataLoopNodes.Node[branch.Comp[CompNum-1].NodeNumIn-1].Press = \
                state.dataLoopNodes.Node[branch.Comp[CompNum-1].NodeNumOut-1].Press

def PassPressureAcrossMixer(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSideNum: DataPlant.LoopSideLocation,
    MixerPressure: Float64,
    NumBranchesOnLoopSide: Int
):
    for BranchNum in range(1, NumBranchesOnLoopSide - 1):
        state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[BranchNum].NodeNumOut-1].Press = MixerPressure

def PassPressureAcrossSplitter(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSideNum: DataPlant.LoopSideLocation,
    SplitterInletPressure: Float64
):
    const InletBranchNum: Int = 0
    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum.value].Branch[InletBranchNum].NodeNumOut-1].Press = \
        SplitterInletPressure

def PassPressureAcrossInterface(
    inout state: EnergyPlusData,
    LoopNum: Int
):
    var DemandInletNodeNum: Int
    var SupplyOutletNodeNum: Int
    DemandInletNodeNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[DataPlant.LoopSideLocation.Demand.value].NodeNumIn
    SupplyOutletNodeNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[DataPlant.LoopSideLocation.Supply.value].NodeNumOut
    state.dataLoopNodes.Node[SupplyOutletNodeNum-1].Press = state.dataLoopNodes.Node[DemandInletNodeNum-1].Press

def ResolveLoopFlowVsPressure(
    inout state: EnergyPlusData,
    LoopNum: Int,
    SystemMassFlow: Float64,
    PumpCurveNum: Int,
    PumpSpeed: Float64,
    PumpImpellerDia: Float64,
    MinPhi: Float64,
    MaxPhi: Float64
) -> Float64:
    const alias RoutineName: StringLiteral = "ResolvedLoopMassFlowRate: "
    const MaxIters: Int = 100
    const PressureConvergeCriteria: Float64 = 0.1
    const ZeroTolerance: Float64 = 0.0001

    var ResolvedLoopMassFlowRate: Float64
    var PumpPressureRise: Float64
    var NodeTemperature: Float64
    var NodeDensity: Float64
    var SystemPressureDrop: Float64
    var PhiPump: Float64
    var PhiSystem: Float64
    var PsiPump: Float64
    var Iteration: Int
    var LocalSystemMassFlow: Float64
    var LoopEffectiveK: Float64
    var Converged: Bool
    var MassFlowIterativeHistory: List[Float64] = [0.0, 0.0, 0.0]
    var MdotDeltaLatest: Float64
    var MdotDeltaPrevious: Float64
    var DampingFactor: Float64

    LoopEffectiveK = state.dataPlnt.PlantLoop[LoopNum-1].PressureEffectiveK
    SystemPressureDrop = LoopEffectiveK * pow_2(SystemMassFlow)
    NodeTemperature = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[DataPlant.LoopSideLocation.Supply.value].NodeNumIn-1].Temp
    NodeDensity = state.dataPlnt.PlantLoop[LoopNum-1].glycol.getDensity(state, NodeTemperature, RoutineName)
    LocalSystemMassFlow = SystemMassFlow

    if LoopEffectiveK <= ZeroTolerance:
        state.dataPlantPressureSys.ZeroKWarningCounter += 1
        if state.dataPlantPressureSys.ZeroKWarningCounter == 1:
            ShowWarningError(state, "Pump pressure-flow resolution attempted, but invalid loop conditions encountered.")
            ShowContinueError(state, f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum-1].Name}")
            ShowContinueError(state, "An invalid pressure/flow condition existed which resulted in the approximation of")
            ShowContinueError(state, "the pressure coefficient K to be zero.  The pressure simulation will use the requested (design)")
            ShowContinueError(state, "pump flow in order to proceed with the simulation.  This warning is only issued once.")
        ResolvedLoopMassFlowRate = SystemMassFlow
        return ResolvedLoopMassFlowRate

    Converged = False
    MassFlowIterativeHistory = [LocalSystemMassFlow, LocalSystemMassFlow, LocalSystemMassFlow]
    DampingFactor = 0.9

    for Iteration in range(1, MaxIters+1):
        LocalSystemMassFlow = sqrt(SystemPressureDrop / LoopEffectiveK)
        # eoshift: shift left and append new value
        MassFlowIterativeHistory = MassFlowIterativeHistory[1:] + [LocalSystemMassFlow]
        PhiSystem = LocalSystemMassFlow / (NodeDensity * PumpSpeed * PumpImpellerDia)
        PhiPump = PhiSystem
        PhiPump = max(PhiPump, MinPhi)
        PhiPump = min(PhiPump, MaxPhi)
        PsiPump = CurveValue(state, PumpCurveNum, PhiPump)
        PumpPressureRise = PsiPump * NodeDensity * pow_2(PumpSpeed) * pow_2(PumpImpellerDia)

        if abs(SystemPressureDrop - PumpPressureRise) < PressureConvergeCriteria:
            ResolvedLoopMassFlowRate = LocalSystemMassFlow
            Converged = True
            break

        if Iteration >= 2:
            MdotDeltaLatest = abs(MassFlowIterativeHistory[0] - MassFlowIterativeHistory[1])
            MdotDeltaPrevious = abs(MassFlowIterativeHistory[1] - MassFlowIterativeHistory[2])
            if MdotDeltaLatest >= MdotDeltaPrevious:
                DampingFactor *= 0.9
        SystemPressureDrop = DampingFactor * PumpPressureRise + (1.0 - DampingFactor) * SystemPressureDrop

    if not Converged:
        state.dataPlantPressureSys.MaxIterWarningCounter += 1
        if state.dataPlantPressureSys.MaxIterWarningCounter == 1:
            ShowWarningError(state, "Pump pressure-flow resolution attempted, but iteration loop did not converge.")
            ShowContinueError(state, f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum-1].Name}")
            ShowContinueError(state, "A mismatch between the pump curve entered and the pressure drop components")
            ShowContinueError(state, "on the loop may be the cause.  The pressure simulation will use the requested (design)")
            ShowContinueError(state, "pump flow in order to proceed with the simulation.  This warning is only issued once.")
        ResolvedLoopMassFlowRate = SystemMassFlow
        return ResolvedLoopMassFlowRate

    return ResolvedLoopMassFlowRate