# plant_pressure_system.mojo
# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois
# and other contributors. All rights reserved.

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing:
#   - state.dataPlnt (PlantData)
#   - state.dataPlantPressureSys (PlantPressureSysData)
#   - state.dataLoopNodes (LoopNodeData)
#   - state.dataEnvrn (EnvironmentalData)
# - DataPlant: enum module with PressureCall, LoopSideLocation, PressSimType, CommonPipeType, PlantEquipmentTypeIsPump, LoopSideKeys
# - DataBranchAirLoopPlant: enum module with PressureCurveType
# - CurveManager: CurveValue, PressureCurveValue functions
# - OutputProcessor: SetupOutputVariable function
# - UtilityRoutines: ShowSevereError, ShowContinueError, ShowWarningError, ShowFatalError functions
# - math.sqrt

from math import sqrt
from math import fabs


struct PlantPressureSysData:
    var InitPressureDropOneTimeInit: Bool
    var LoopInit: DynamicVector[Bool]
    var FullParallelBranchSetFound: InlineArray[Bool, 2]
    var CommonPipeErrorEncountered: Bool
    var ErrorCounter: Int
    var ZeroKWarningCounter: Int
    var MaxIterWarningCounter: Int
    
    fn __init__(inout self):
        self.InitPressureDropOneTimeInit = True
        self.LoopInit = DynamicVector[Bool]()
        self.FullParallelBranchSetFound = InlineArray[Bool, 2](False, False)
        self.CommonPipeErrorEncountered = False
        self.ErrorCounter = 0
        self.ZeroKWarningCounter = 0
        self.MaxIterWarningCounter = 0
    
    fn clear_state(inout self):
        self.InitPressureDropOneTimeInit = True
        self.LoopInit.clear()
        self.FullParallelBranchSetFound = InlineArray[Bool, 2](False, False)
        self.CommonPipeErrorEncountered = False
        self.ErrorCounter = 0
        self.ZeroKWarningCounter = 0
        self.MaxIterWarningCounter = 0


fn SimPressureDropSystem(
    state: DynamicObject,
    LoopNum: Int,
    FirstHVACIteration: Bool,
    CallType: Int,
    LoopSideNum: Int = 0,
    BranchNum: Int = 0
) -> None:
    if (state.dataPlnt.PlantLoop[LoopNum].PressureSimType == state.DataPlant.PressSimType.NoPressure and
        (CallType == state.DataPlant.PressureCall.Calc or CallType == state.DataPlant.PressureCall.Update)):
        return
    
    if CallType == state.DataPlant.PressureCall.Init:
        InitPressureDrop(state, LoopNum, FirstHVACIteration)
    elif CallType == state.DataPlant.PressureCall.Calc:
        BranchPressureDrop(state, LoopNum, LoopSideNum, BranchNum)
    elif CallType == state.DataPlant.PressureCall.Update:
        UpdatePressureDrop(state, LoopNum)


fn InitPressureDrop(state: DynamicObject, LoopNum: Int, FirstHVACIteration: Bool) -> None:
    if state.dataPlantPressureSys.InitPressureDropOneTimeInit:
        state.dataPlantPressureSys.LoopInit.resize(len(state.dataPlnt.PlantLoop))
        for i in range(len(state.dataPlantPressureSys.LoopInit)):
            state.dataPlantPressureSys.LoopInit[i] = True
        state.dataPlantPressureSys.InitPressureDropOneTimeInit = False
    
    var loop = state.dataPlnt.PlantLoop[LoopNum]
    
    if state.dataPlantPressureSys.LoopInit[LoopNum]:
        var ErrorsFound: Bool = False
        
        for LoopSideNum in state.DataPlant.LoopSideKeys:
            var loop_side = loop.LoopSide[LoopSideNum]
            
            for BranchNum in range(len(loop_side.Branch)):
                var branch = loop_side.Branch[BranchNum]
                
                if branch.PressureCurveIndex > 0:
                    branch.HasPressureComponents = True
                    loop_side.HasPressureComponents = True
                    loop.HasPressureComponents = True
                    
                    state.SetupOutputVariable(
                        "Plant Branch Pressure Difference",
                        "Pa",
                        branch,
                        "PressureDrop",
                        "System",
                        "Average",
                        branch.Name
                    )
            
            if loop_side.HasPressureComponents:
                if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                    state.SetupOutputVariable(
                        "Plant Demand Side Loop Pressure Difference",
                        "Pa",
                        loop_side,
                        "PressureDrop",
                        "System",
                        "Average",
                        loop.Name
                    )
                elif LoopSideNum == state.DataPlant.LoopSideLocation.Supply:
                    state.SetupOutputVariable(
                        "Plant Supply Side Loop Pressure Difference",
                        "Pa",
                        loop_side,
                        "PressureDrop",
                        "System",
                        "Average",
                        loop.Name
                    )
        
        if loop.HasPressureComponents:
            var SeriesPressureComponentFound: Bool = False
            state.dataPlantPressureSys.FullParallelBranchSetFound[int(state.DataPlant.LoopSideLocation.Demand)] = False
            state.dataPlantPressureSys.FullParallelBranchSetFound[int(state.DataPlant.LoopSideLocation.Supply)] = False
            
            state.SetupOutputVariable(
                "Plant Loop Pressure Difference",
                "Pa",
                loop,
                "PressureDrop",
                "System",
                "Average",
                loop.Name
            )
            
            for LoopSideNum in state.DataPlant.LoopSideKeys:
                var loop_side = loop.LoopSide[LoopSideNum]
                var BranchPressureTally: Int = 0
                var NumBranches: Int = len(loop_side.Branch)
                
                if NumBranches > 2:
                    for BranchNum in range(1, NumBranches - 1):
                        if loop_side.Branch[BranchNum].HasPressureComponents:
                            loop_side.HasParallelPressComps = True
                            BranchPressureTally += 1
                
                if BranchPressureTally == 0:
                    pass
                elif BranchPressureTally == NumBranches - 2:
                    state.dataPlantPressureSys.FullParallelBranchSetFound[int(LoopSideNum)] = True
                else:
                    state.ShowSevereError(f"Pressure drop component configuration error detected on loop: {loop.Name}")
                    state.ShowContinueError("Pressure drop components must be on ALL or NONE of the parallel branches.")
                    state.ShowContinueError("Partial distribution is not allowed.")
                    ErrorsFound = True
                
                if loop_side.Branch[0].HasPressureComponents or loop_side.Branch[NumBranches - 1].HasPressureComponents:
                    SeriesPressureComponentFound = True
            
            if (state.dataPlantPressureSys.FullParallelBranchSetFound[int(state.DataPlant.LoopSideLocation.Demand)] or
                state.dataPlantPressureSys.FullParallelBranchSetFound[int(state.DataPlant.LoopSideLocation.Supply)] or
                SeriesPressureComponentFound):
                pass
            else:
                state.ShowSevereError(f"Pressure drop component configuration error detected on loop: {loop.Name}")
                state.ShowContinueError("The loop has at least one fluid path which does not encounter a pressure component.")
                state.ShowContinueError("Either use at least one serial component for pressure drop OR all possible parallel paths")
                state.ShowContinueError("must be pressure drop components.")
                ErrorsFound = True
        
        if ErrorsFound:
            state.ShowFatalError("Preceding errors cause program termination")
        
        if loop.HasPressureComponents and loop.PressureSimType == state.DataPlant.PressSimType.NoPressure:
            state.ShowWarningError(f"Error for pressure simulation on plant loop: {loop.Name}")
            state.ShowContinueError("Plant loop contains pressure simulation components on the branches,")
            state.ShowContinueError(" yet in the PlantLoop object, there is no pressure simulation specified.")
            state.ShowContinueError("Simulation continues, ignoring pressure simulation data.")
        elif not loop.HasPressureComponents and loop.PressureSimType != state.DataPlant.PressSimType.NoPressure:
            state.ShowWarningError(f"Error for pressure simulation on plant loop: {loop.Name}")
            state.ShowContinueError("Plant loop is requesting a pressure simulation,")
            state.ShowContinueError(" yet there are no pressure simulation components detected on any of the branches in that loop.")
            state.ShowContinueError("Simulation continues, ignoring pressure simulation data.")
        
        state.dataPlantPressureSys.LoopInit[LoopNum] = False
    
    if loop.HasPressureComponents and FirstHVACIteration:
        for LoopSideNum in state.DataPlant.LoopSideKeys:
            var loop_side = loop.LoopSide[LoopSideNum]
            for BranchNum in range(len(loop_side.Branch)):
                var branch = loop_side.Branch[BranchNum]
                for CompNum in range(len(branch.Comp)):
                    var component = branch.Comp[CompNum]
                    state.dataLoopNodes.Node[component.NodeNumIn].Press = state.dataEnvrn.StdBaroPress
                    state.dataLoopNodes.Node[component.NodeNumOut].Press = state.dataEnvrn.StdBaroPress
    
    if loop.HasPressureComponents:
        loop.UsePressureForPumpCalcs = not FirstHVACIteration
    else:
        loop.UsePressureForPumpCalcs = False
    
    if loop.HasPressureComponents:
        if loop.CommonPipeType != state.DataPlant.CommonPipeType.No:
            if not state.dataPlantPressureSys.CommonPipeErrorEncountered:
                state.ShowSevereError(f"Invalid pressure simulation configuration for Plant Loop={loop.Name}")
                state.ShowContinueError("Currently pressure simulations cannot be performed for loops with common pipes.")
                state.ShowContinueError("To repair, either remove the common pipe simulation, or remove the pressure simulation.")
                state.ShowContinueError("The simulation will continue, but the pump power is not updated with pressure drop data.")
                state.ShowContinueError("Check all results including node pressures to ensure proper simulation.")
                state.ShowContinueError("This message is reported once, but may have been encountered in multiple loops.")
                state.dataPlantPressureSys.CommonPipeErrorEncountered = True
            loop.UsePressureForPumpCalcs = False


fn BranchPressureDrop(state: DynamicObject, LoopNum: Int, LoopSideNum: Int, BranchNum: Int) -> None:
    if not state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].HasPressureComponents:
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureDrop = 0.0
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK = 0.0
        return
    
    var InletNodeNum: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumIn
    var pressureCurveType: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureCurveType
    var PressureCurveIndex: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureCurveIndex
    
    var NodeMassFlow: Float64 = state.dataLoopNodes.Node[InletNodeNum].MassFlowRate
    var NodeTemperature: Float64 = state.dataLoopNodes.Node[InletNodeNum].Temp
    var NodeDensity: Float64 = state.dataPlnt.PlantLoop[LoopNum].glycol.getDensity(state, NodeTemperature, "CalcPlantPressureSystem")
    var NodeViscosity: Float64 = state.dataPlnt.PlantLoop[LoopNum].glycol.getViscosity(state, NodeTemperature, "CalcPlantPressureSystem")
    
    var BranchDeltaPress: Float64 = 0.0
    if pressureCurveType == state.DataBranchAirLoopPlant.PressureCurveType.Pressure:
        BranchDeltaPress = state.PressureCurveValue(PressureCurveIndex, NodeMassFlow, NodeDensity, NodeViscosity)
    elif pressureCurveType == state.DataBranchAirLoopPlant.PressureCurveType.Generic:
        BranchDeltaPress = state.CurveValue(PressureCurveIndex, NodeMassFlow)
    else:
        state.dataPlantPressureSys.ErrorCounter += 1
        if state.dataPlantPressureSys.ErrorCounter == 1:
            state.ShowSevereError("Plant pressure simulation encountered a branch which contains invalid branch pressure curve type.")
            state.ShowContinueError(f"Occurs for branch: {state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Name}")
            state.ShowContinueError("This error will be issued only once, although other branches may encounter the same problem")
            state.ShowContinueError("For now, pressure drop on this branch will be set to zero.")
            state.ShowContinueError("Verify all pressure inputs and pressure drop output variables to ensure proper simulation")
    
    state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureDrop = BranchDeltaPress
    
    if NodeMassFlow > 0.0:
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK = BranchDeltaPress / (NodeMassFlow * NodeMassFlow)
    else:
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK = 0.0


fn UpdatePressureDrop(state: DynamicObject, LoopNum: Int) -> None:
    if not state.dataPlnt.PlantLoop[LoopNum].HasPressureComponents:
        return
    
    var FoundAPumpOnBranch: Bool = False
    var LoopPressureDrop: Float64 = 0.0
    
    for LoopSideNum in state.DataPlant.LoopSideKeys:
        var LoopSidePressureDrop: Float64 = 0.0
        var NumBranches: Int = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch)
        
        if NumBranches == 1:
            var BranchNum: Int = 0
            var result_tuple = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
            var BranchPressureDropValue: Float64 = result_tuple[0]
            var PumpFound: Bool = result_tuple[1]
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound
        
        elif NumBranches > 1:
            var BranchNum: Int = NumBranches - 1
            var result_tuple = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
            var BranchPressureDropValue: Float64 = result_tuple[0]
            var PumpFound: Bool = result_tuple[1]
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound
            
            var MixerPressure: Float64 = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumIn].Press
            PassPressureAcrossMixer(state, LoopNum, LoopSideNum, MixerPressure, NumBranches)
            
            var ParallelBranchPressureDrops = DynamicVector[Float64]()
            var ParallelBranchInletPressures = DynamicVector[Float64]()
            
            FoundAPumpOnBranch = False
            for BranchNum_par in range(NumBranches - 2, 0, -1):
                var result_tuple_par = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum_par)
                var BranchPressureDropValue_par: Float64 = result_tuple_par[0]
                var PumpFound_par: Bool = result_tuple_par[1]
                ParallelBranchPressureDrops.push_back(BranchPressureDropValue_par)
                ParallelBranchInletPressures.push_back(
                    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum_par].NodeNumIn].Press
                )
                FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound_par
            
            var SplitterInletPressure: Float64 = 0.0
            var BranchPressureDropValue_max: Float64 = 0.0
            if len(ParallelBranchInletPressures) > 0:
                SplitterInletPressure = _max_of_vector(ParallelBranchInletPressures)
                BranchPressureDropValue_max = _max_of_vector(ParallelBranchPressureDrops)
            
            LoopSidePressureDrop += BranchPressureDropValue_max
            LoopPressureDrop += BranchPressureDropValue_max
            
            if FoundAPumpOnBranch:
                if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                    state.ShowSevereError("Pressure system information was found in a demand pump (common pipe) simulation")
                    state.ShowContinueError("Currently the pressure simulation is not set up to handle common pipe simulations")
                    state.ShowContinueError("Either modify simulation to avoid common pipe, or remove pressure curve information")
                    state.ShowFatalError("Pressure configuration mismatch causes program termination")
            
            if not FoundAPumpOnBranch:
                PassPressureAcrossSplitter(state, LoopNum, LoopSideNum, SplitterInletPressure)
                
                BranchNum = 0
                var result_tuple_inlet = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
                BranchPressureDropValue = result_tuple_inlet[0]
                PumpFound = result_tuple_inlet[1]
                LoopSidePressureDrop += BranchPressureDropValue
                LoopPressureDrop += BranchPressureDropValue
                
                if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                    PassPressureAcrossInterface(state, LoopNum)
        
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].PressureDrop = LoopSidePressureDrop
    
    state.dataPlnt.PlantLoop[LoopNum].PressureDrop = LoopPressureDrop
    
    var EffectiveLoopKValue: Float64 = 0.0
    
    for LoopSideNum in state.DataPlant.LoopSideKeys:
        var EffectiveLoopSideKValue: Float64 = 0.0
        
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[0].PressureEffectiveK
        
        if len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) == 1:
            continue
        
        var TempVal_SumOfOneByRootK: Float64 = 0.0
        for BranchNum in range(1, len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) - 1):
            if state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK > 0.0:
                TempVal_SumOfOneByRootK += (1.0 / sqrt(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK))
        
        if TempVal_SumOfOneByRootK > 0.0:
            EffectiveLoopSideKValue += (1.0 / (TempVal_SumOfOneByRootK * TempVal_SumOfOneByRootK))
        
        var BranchNum: Int = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) - 1
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK
        
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].PressureEffectiveK = EffectiveLoopSideKValue
        
        EffectiveLoopKValue += EffectiveLoopSideKValue
    
    state.dataPlnt.PlantLoop[LoopNum].PressureEffectiveK = EffectiveLoopKValue


fn DistributePressureOnBranch(state: DynamicObject, LoopNum: Int, LoopSideNum: Int, BranchNum: Int) -> Tuple[Float64, Bool]:
    var TempBranchPressureDrop: Float64 = 0.0
    var BranchPressureDrop: Float64 = 0.0
    var NumCompsOnBranch: Int = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp)
    
    if state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].HasPressureComponents:
        TempBranchPressureDrop = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureDrop
    
    var LastComponentType: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].Type
    if state.DataPlant.PlantEquipmentTypeIsPump[int(LastComponentType)]:
        if TempBranchPressureDrop != 0.0:
            state.ShowSevereError(f"Error in plant pressure simulation for plant loop: {state.dataPlnt.PlantLoop[LoopNum].Name}")
            if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                state.ShowContinueError(f"Occurs for demand side, branch: {state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Name}")
            elif LoopSideNum == state.DataPlant.LoopSideLocation.Supply:
                state.ShowContinueError(f"Occurs for supply side, branch: {state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Name}")
            state.ShowContinueError("Branch contains only a single pump component, yet also a pressure drop component.")
            state.ShowContinueError("Either add a second component to this branch after the pump, or move pressure drop data.")
            state.ShowFatalError("Preceding pressure drop error causes program termination")
        return (0.0, True)
    
    if state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].HasPressureComponents:
        BranchPressureDrop = TempBranchPressureDrop
    
    var LastCompNodeNumIn: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].NodeNumIn
    var LastCompNodeNumOut: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].NodeNumOut
    state.dataLoopNodes.Node[LastCompNodeNumIn].Press = \
        state.dataLoopNodes.Node[LastCompNodeNumOut].Press + BranchPressureDrop
    
    var PumpFound: Bool = False
    if NumCompsOnBranch > 1:
        for CompNum in range(NumCompsOnBranch - 2, -1, -1):
            var ComponentType: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].Type
            if state.DataPlant.PlantEquipmentTypeIsPump[int(ComponentType)]:
                PumpFound = True
                break
            
            var CompNodeNumIn: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].NodeNumIn
            var CompNodeNumOut: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].NodeNumOut
            state.dataLoopNodes.Node[CompNodeNumIn].Press = state.dataLoopNodes.Node[CompNodeNumOut].Press
    
    return (BranchPressureDrop, PumpFound)


fn PassPressureAcrossMixer(state: DynamicObject, LoopNum: Int, LoopSideNum: Int, MixerPressure: Float64, NumBranchesOnLoopSide: Int) -> None:
    for BranchNum in range(1, NumBranchesOnLoopSide - 1):
        state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumOut].Press = MixerPressure


fn PassPressureAcrossSplitter(state: DynamicObject, LoopNum: Int, LoopSideNum: Int, SplitterInletPressure: Float64) -> None:
    var InletBranchNum: Int = 0
    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[InletBranchNum].NodeNumOut].Press = SplitterInletPressure


fn PassPressureAcrossInterface(state: DynamicObject, LoopNum: Int) -> None:
    var DemandInletNodeNum: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Demand].NodeNumIn
    var SupplyOutletNodeNum: Int = state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumOut
    
    state.dataLoopNodes.Node[SupplyOutletNodeNum].Press = state.dataLoopNodes.Node[DemandInletNodeNum].Press


fn ResolveLoopFlowVsPressure(
    state: DynamicObject,
    LoopNum: Int,
    SystemMassFlow: Float64,
    PumpCurveNum: Int,
    PumpSpeed: Float64,
    PumpImpellerDia: Float64,
    MinPhi: Float64,
    MaxPhi: Float64
) -> Float64:
    var MaxIters: Int = 100
    var PressureConvergeCriteria: Float64 = 0.1
    var ZeroTolerance: Float64 = 0.0001
    
    var LoopEffectiveK: Float64 = state.dataPlnt.PlantLoop[LoopNum].PressureEffectiveK
    var SystemPressureDrop: Float64 = LoopEffectiveK * SystemMassFlow * SystemMassFlow
    
    var NodeTemperature: Float64 = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumIn].Temp
    var NodeDensity: Float64 = state.dataPlnt.PlantLoop[LoopNum].glycol.getDensity(state, NodeTemperature, "ResolvedLoopMassFlowRate: ")
    
    var LocalSystemMassFlow: Float64 = SystemMassFlow
    
    if LoopEffectiveK <= ZeroTolerance:
        state.dataPlantPressureSys.ZeroKWarningCounter += 1
        if state.dataPlantPressureSys.ZeroKWarningCounter == 1:
            state.ShowWarningError("Pump pressure-flow resolution attempted, but invalid loop conditions encountered.")
            state.ShowContinueError(f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum].Name}")
            state.ShowContinueError("An invalid pressure/flow condition existed which resulted in the approximation of")
            state.ShowContinueError("the pressure coefficient K to be zero.  The pressure simulation will use the requested (design)")
            state.ShowContinueError("pump flow in order to proceed with the simulation.  This warning is only issued once.")
        return SystemMassFlow
    
    var Converged: Bool = False
    
    var MassFlowIterativeHistory = DynamicVector[Float64]()
    MassFlowIterativeHistory.push_back(LocalSystemMassFlow)
    MassFlowIterativeHistory.push_back(LocalSystemMassFlow)
    MassFlowIterativeHistory.push_back(LocalSystemMassFlow)
    var DampingFactor: Float64 = 0.9
    
    for Iteration in range(1, MaxIters + 1):
        LocalSystemMassFlow = sqrt(SystemPressureDrop / LoopEffectiveK)
        
        MassFlowIterativeHistory[0] = MassFlowIterativeHistory[1]
        MassFlowIterativeHistory[1] = MassFlowIterativeHistory[2]
        MassFlowIterativeHistory[2] = LocalSystemMassFlow
        
        var PhiSystem: Float64 = LocalSystemMassFlow / (NodeDensity * PumpSpeed * PumpImpellerDia)
        
        var PhiPump: Float64 = PhiSystem
        
        PhiPump = max(PhiPump, MinPhi)
        PhiPump = min(PhiPump, MaxPhi)
        
        var PsiPump: Float64 = state.CurveValue(PumpCurveNum, PhiPump)
        
        var PumpPressureRise: Float64 = PsiPump * NodeDensity * PumpSpeed * PumpSpeed * PumpImpellerDia * PumpImpellerDia
        
        if fabs(SystemPressureDrop - PumpPressureRise) < PressureConvergeCriteria:
            var ResolvedLoopMassFlowRate: Float64 = LocalSystemMassFlow
            Converged = True
            break
        
        if Iteration >= 2:
            var MdotDeltaLatest: Float64 = fabs(MassFlowIterativeHistory[0] - MassFlowIterativeHistory[1])
            var MdotDeltaPrevious: Float64 = fabs(MassFlowIterativeHistory[1] - MassFlowIterativeHistory[2])
            if MdotDeltaLatest >= MdotDeltaPrevious:
                DampingFactor *= 0.9
        
        SystemPressureDrop = DampingFactor * PumpPressureRise + (1.0 - DampingFactor) * SystemPressureDrop
    
    if not Converged:
        state.dataPlantPressureSys.MaxIterWarningCounter += 1
        if state.dataPlantPressureSys.MaxIterWarningCounter == 1:
            state.ShowWarningError("Pump pressure-flow resolution attempted, but iteration loop did not converge.")
            state.ShowContinueError(f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum].Name}")
            state.ShowContinueError("A mismatch between the pump curve entered and the pressure drop components")
            state.ShowContinueError("on the loop may be the cause.  The pressure simulation will use the requested (design)")
            state.ShowContinueError("pump flow in order to proceed with the simulation.  This warning is only issued once.")
        return SystemMassFlow
    
    return LocalSystemMassFlow


@always_inline
fn _max_of_vector(vec: DynamicVector[Float64]) -> Float64:
    var result: Float64 = 0.0
    if len(vec) > 0:
        result = vec[0]
        for i in range(1, len(vec)):
            if vec[i] > result:
                result = vec[i]
    return result
