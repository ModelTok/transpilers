# PlantPressureSystem.py
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
# - math module

from math import sqrt


class PlantPressureSysData:
    """Plant pressure system persistent data."""
    
    def __init__(self):
        self.InitPressureDropOneTimeInit: bool = True
        self.LoopInit: list = []
        self.FullParallelBranchSetFound: list = [False, False]
        self.CommonPipeErrorEncountered: bool = False
        self.ErrorCounter: int = 0
        self.ZeroKWarningCounter: int = 0
        self.MaxIterWarningCounter: int = 0
    
    def clear_state(self):
        self.InitPressureDropOneTimeInit = True
        self.LoopInit.clear()
        self.FullParallelBranchSetFound = [False, False]
        self.CommonPipeErrorEncountered = False
        self.ErrorCounter = 0
        self.ZeroKWarningCounter = 0
        self.MaxIterWarningCounter = 0


def SimPressureDropSystem(state, LoopNum, FirstHVACIteration, CallType, LoopSideNum=None, BranchNum=None):
    """Simulate pressure drop system."""
    if (state.dataPlnt.PlantLoop[LoopNum].PressureSimType == state.DataPlant.PressSimType.NoPressure and
        (CallType == state.DataPlant.PressureCall.Calc or CallType == state.DataPlant.PressureCall.Update)):
        return
    
    if CallType == state.DataPlant.PressureCall.Init:
        InitPressureDrop(state, LoopNum, FirstHVACIteration)
    elif CallType == state.DataPlant.PressureCall.Calc:
        BranchPressureDrop(state, LoopNum, LoopSideNum, BranchNum)
    elif CallType == state.DataPlant.PressureCall.Update:
        UpdatePressureDrop(state, LoopNum)


def InitPressureDrop(state, LoopNum, FirstHVACIteration):
    """Initialize pressure drop data structures and output variables."""
    if state.dataPlantPressureSys.InitPressureDropOneTimeInit:
        state.dataPlantPressureSys.LoopInit = [True] * len(state.dataPlnt.PlantLoop)
        state.dataPlantPressureSys.InitPressureDropOneTimeInit = False
    
    loop = state.dataPlnt.PlantLoop[LoopNum]
    
    if state.dataPlantPressureSys.LoopInit[LoopNum]:
        ErrorsFound = False
        
        for LoopSideNum in state.DataPlant.LoopSideKeys:
            loop_side = loop.LoopSide[LoopSideNum]
            
            for BranchNum in range(len(loop_side.Branch)):
                branch = loop_side.Branch[BranchNum]
                
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
            SeriesPressureComponentFound = False
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
                loop_side = loop.LoopSide[LoopSideNum]
                BranchPressureTally = 0
                NumBranches = len(loop_side.Branch)
                
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
            loop_side = loop.LoopSide[LoopSideNum]
            for BranchNum in range(len(loop_side.Branch)):
                branch = loop_side.Branch[BranchNum]
                for CompNum in range(len(branch.Comp)):
                    component = branch.Comp[CompNum]
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


def BranchPressureDrop(state, LoopNum, LoopSideNum, BranchNum):
    """Calculate pressure drop for a single branch."""
    from EnergyPlus.CurveManager import CurveValue, PressureCurveValue
    
    if not state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].HasPressureComponents:
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureDrop = 0.0
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK = 0.0
        return
    
    InletNodeNum = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumIn
    pressureCurveType = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureCurveType
    PressureCurveIndex = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureCurveIndex
    
    NodeMassFlow = state.dataLoopNodes.Node[InletNodeNum].MassFlowRate
    NodeTemperature = state.dataLoopNodes.Node[InletNodeNum].Temp
    NodeDensity = state.dataPlnt.PlantLoop[LoopNum].glycol.getDensity(state, NodeTemperature, "CalcPlantPressureSystem")
    NodeViscosity = state.dataPlnt.PlantLoop[LoopNum].glycol.getViscosity(state, NodeTemperature, "CalcPlantPressureSystem")
    
    BranchDeltaPress = 0.0
    if pressureCurveType == state.DataBranchAirLoopPlant.PressureCurveType.Pressure:
        BranchDeltaPress = PressureCurveValue(state, PressureCurveIndex, NodeMassFlow, NodeDensity, NodeViscosity)
    elif pressureCurveType == state.DataBranchAirLoopPlant.PressureCurveType.Generic:
        BranchDeltaPress = CurveValue(state, PressureCurveIndex, NodeMassFlow)
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


def UpdatePressureDrop(state, LoopNum):
    """Update and propagate pressure drops across the entire plant loop."""
    if not state.dataPlnt.PlantLoop[LoopNum].HasPressureComponents:
        return
    
    FoundAPumpOnBranch = False
    LoopPressureDrop = 0.0
    
    for LoopSideNum in state.DataPlant.LoopSideKeys:
        LoopSidePressureDrop = 0.0
        NumBranches = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch)
        
        if NumBranches == 1:
            BranchNum = 0
            BranchPressureDropValue, PumpFound = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound
        
        elif NumBranches > 1:
            BranchNum = NumBranches - 1
            BranchPressureDropValue, PumpFound = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound
            
            MixerPressure = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumIn].Press
            PassPressureAcrossMixer(state, LoopNum, LoopSideNum, MixerPressure, NumBranches)
            
            ParallelBranchPressureDrops = []
            ParallelBranchInletPressures = []
            
            FoundAPumpOnBranch = False
            for BranchNum in range(NumBranches - 2, 0, -1):
                BranchPressureDropValue, PumpFound = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
                ParallelBranchPressureDrops.append(BranchPressureDropValue)
                ParallelBranchInletPressures.append(
                    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumIn].Press
                )
                FoundAPumpOnBranch = FoundAPumpOnBranch or PumpFound
            
            SplitterInletPressure = max(ParallelBranchInletPressures) if ParallelBranchInletPressures else 0.0
            BranchPressureDropValue = max(ParallelBranchPressureDrops) if ParallelBranchPressureDrops else 0.0
            LoopSidePressureDrop += BranchPressureDropValue
            LoopPressureDrop += BranchPressureDropValue
            
            if FoundAPumpOnBranch:
                if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                    state.ShowSevereError("Pressure system information was found in a demand pump (common pipe) simulation")
                    state.ShowContinueError("Currently the pressure simulation is not set up to handle common pipe simulations")
                    state.ShowContinueError("Either modify simulation to avoid common pipe, or remove pressure curve information")
                    state.ShowFatalError("Pressure configuration mismatch causes program termination")
            
            if not FoundAPumpOnBranch:
                PassPressureAcrossSplitter(state, LoopNum, LoopSideNum, SplitterInletPressure)
                
                BranchNum = 0
                BranchPressureDropValue, PumpFound = DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum)
                LoopSidePressureDrop += BranchPressureDropValue
                LoopPressureDrop += BranchPressureDropValue
                
                if LoopSideNum == state.DataPlant.LoopSideLocation.Demand:
                    PassPressureAcrossInterface(state, LoopNum)
        
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].PressureDrop = LoopSidePressureDrop
    
    state.dataPlnt.PlantLoop[LoopNum].PressureDrop = LoopPressureDrop
    
    EffectiveLoopKValue = 0.0
    
    for LoopSideNum in state.DataPlant.LoopSideKeys:
        EffectiveLoopSideKValue = 0.0
        
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[0].PressureEffectiveK
        
        if len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) == 1:
            continue
        
        TempVal_SumOfOneByRootK = 0.0
        for BranchNum in range(1, len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) - 1):
            if state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK > 0.0:
                TempVal_SumOfOneByRootK += (1.0 / sqrt(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK))
        
        if TempVal_SumOfOneByRootK > 0.0:
            EffectiveLoopSideKValue += (1.0 / (TempVal_SumOfOneByRootK * TempVal_SumOfOneByRootK))
        
        BranchNum = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch) - 1
        EffectiveLoopSideKValue += state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureEffectiveK
        
        state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].PressureEffectiveK = EffectiveLoopSideKValue
        
        EffectiveLoopKValue += EffectiveLoopSideKValue
    
    state.dataPlnt.PlantLoop[LoopNum].PressureEffectiveK = EffectiveLoopKValue


def DistributePressureOnBranch(state, LoopNum, LoopSideNum, BranchNum):
    """Distribute pressure drops on a branch and update node pressures."""
    TempBranchPressureDrop = 0.0
    BranchPressureDrop = 0.0
    NumCompsOnBranch = len(state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp)
    
    if state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].HasPressureComponents:
        TempBranchPressureDrop = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].PressureDrop
    
    LastComponentType = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].Type
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
    
    LastCompNodeNumIn = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].NodeNumIn
    LastCompNodeNumOut = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[NumCompsOnBranch - 1].NodeNumOut
    state.dataLoopNodes.Node[LastCompNodeNumIn].Press = \
        state.dataLoopNodes.Node[LastCompNodeNumOut].Press + BranchPressureDrop
    
    PumpFound = False
    if NumCompsOnBranch > 1:
        for CompNum in range(NumCompsOnBranch - 2, -1, -1):
            ComponentType = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].Type
            if state.DataPlant.PlantEquipmentTypeIsPump[int(ComponentType)]:
                PumpFound = True
                break
            
            CompNodeNumIn = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].NodeNumIn
            CompNodeNumOut = state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].Comp[CompNum].NodeNumOut
            state.dataLoopNodes.Node[CompNodeNumIn].Press = state.dataLoopNodes.Node[CompNodeNumOut].Press
    
    return (BranchPressureDrop, PumpFound)


def PassPressureAcrossMixer(state, LoopNum, LoopSideNum, MixerPressure, NumBranchesOnLoopSide):
    """Set mixer inlet branch outlet pressures."""
    for BranchNum in range(1, NumBranchesOnLoopSide - 1):
        state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[BranchNum].NodeNumOut].Press = MixerPressure


def PassPressureAcrossSplitter(state, LoopNum, LoopSideNum, SplitterInletPressure):
    """Set splitter inlet pressure."""
    InletBranchNum = 0
    state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[LoopSideNum].Branch[InletBranchNum].NodeNumOut].Press = SplitterInletPressure


def PassPressureAcrossInterface(state, LoopNum):
    """Pass pressure across demand inlet/supply outlet interface."""
    DemandInletNodeNum = state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Demand].NodeNumIn
    SupplyOutletNodeNum = state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumOut
    
    state.dataLoopNodes.Node[SupplyOutletNodeNum].Press = state.dataLoopNodes.Node[DemandInletNodeNum].Press


def ResolveLoopFlowVsPressure(state, LoopNum, SystemMassFlow, PumpCurveNum, PumpSpeed, PumpImpellerDia, MinPhi, MaxPhi):
    """Resolve plant loop flow rate against pump curve and system pressure drop."""
    from EnergyPlus.CurveManager import CurveValue
    
    MaxIters = 100
    PressureConvergeCriteria = 0.1
    ZeroTolerance = 0.0001
    
    LoopEffectiveK = state.dataPlnt.PlantLoop[LoopNum].PressureEffectiveK
    SystemPressureDrop = LoopEffectiveK * SystemMassFlow * SystemMassFlow
    
    NodeTemperature = state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumIn].Temp
    NodeDensity = state.dataPlnt.PlantLoop[LoopNum].glycol.getDensity(state, NodeTemperature, "ResolvedLoopMassFlowRate: ")
    
    LocalSystemMassFlow = SystemMassFlow
    
    if LoopEffectiveK <= ZeroTolerance:
        state.dataPlantPressureSys.ZeroKWarningCounter += 1
        if state.dataPlantPressureSys.ZeroKWarningCounter == 1:
            state.ShowWarningError("Pump pressure-flow resolution attempted, but invalid loop conditions encountered.")
            state.ShowContinueError(f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum].Name}")
            state.ShowContinueError("An invalid pressure/flow condition existed which resulted in the approximation of")
            state.ShowContinueError("the pressure coefficient K to be zero.  The pressure simulation will use the requested (design)")
            state.ShowContinueError("pump flow in order to proceed with the simulation.  This warning is only issued once.")
        return SystemMassFlow
    
    Converged = False
    
    MassFlowIterativeHistory = [LocalSystemMassFlow] * 3
    DampingFactor = 0.9
    
    for Iteration in range(1, MaxIters + 1):
        LocalSystemMassFlow = sqrt(SystemPressureDrop / LoopEffectiveK)
        
        MassFlowIterativeHistory = MassFlowIterativeHistory[1:] + [LocalSystemMassFlow]
        
        PhiSystem = LocalSystemMassFlow / (NodeDensity * PumpSpeed * PumpImpellerDia)
        
        PhiPump = PhiSystem
        
        PhiPump = max(PhiPump, MinPhi)
        PhiPump = min(PhiPump, MaxPhi)
        
        PsiPump = CurveValue(state, PumpCurveNum, PhiPump)
        
        PumpPressureRise = PsiPump * NodeDensity * PumpSpeed * PumpSpeed * PumpImpellerDia * PumpImpellerDia
        
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
            state.ShowWarningError("Pump pressure-flow resolution attempted, but iteration loop did not converge.")
            state.ShowContinueError(f"Loop being calculated: {state.dataPlnt.PlantLoop[LoopNum].Name}")
            state.ShowContinueError("A mismatch between the pump curve entered and the pressure drop components")
            state.ShowContinueError("on the loop may be the cause.  The pressure simulation will use the requested (design)")
            state.ShowContinueError("pump flow in order to proceed with the simulation.  This warning is only issued once.")
        return SystemMassFlow
    
    return ResolvedLoopMassFlowRate
