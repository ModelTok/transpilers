# Mojo translation of PlantUtilities.cc
# Faithful 1:1 translation, no refactoring

from __future__ import import

from .Data.EnergyPlusData import EnergyPlusData
from .DataBranchAirLoopPlant import MassFlowTolerance, ControlType
from .DataLoopNode import Node
from DataSizing import AutoSize, PlantSizingData
from FluidProperties import getSpecificHeat
from .Plant.DataPlant import (
    CompData, OpScheme, FlowLock, LoopSideLocation, LoopSideKeys, DemandSupplyNames,
    PlantEquipmentType, PlantEquipTypeNames, CriteriaType, CriteriaDelta_MassFlowRate,
    CriteriaDelta_Temperature, CriteriaDelta_HeatTransferRate, ConnectedLoopData,
    PlantCallingOrderInfoStruct, PressSimType, LoopFlowStatus
)
from .PumpEquip import PumpEquip
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowContinueErrorTimeStamp, ShowFatalError, ShowWarningError, ShowRecurringSevereErrorAtEnd, ShowSevereMessage, ShowBranchesOnLoop
from BranchInputManager import AuditBranches
from .Util import SameString, FindItemInList

from Math import abs, max, min
from Memory import allocate, deallocate, redimension, size, isize
from String import format

# Helper functions to replace ObjexxFCL Array1D functionality
def allocate[T](arr: List[T], size: Int):
    arr.reserve(size)
    for i in range(size):
        arr.append(T())  # default init

def deallocate[T](inout arr: List[T]):
    arr.clear()

def redimension[T](inout arr: List[T], new_size: Int):
    if new_size > arr.size:
        arr.reserve(new_size)
        for i in range(arr.size, new_size):
            arr.append(T())
    elif new_size < arr.size:
        arr = arr[0:new_size]

def size[T](arr: List[T]) -> Int:
    return arr.size

def isize[T](arr: List[T]) -> Int:
    return arr.size

# Helper for 1-based indexing: convert to 0-based
def index1_to_0(idx: Int) -> Int:
    return idx - 1

# Helper for rshift1
def rshift1(inout a: List[Float64], a_l: Float64):
    assert a.size > 0
    for i in range(a.size-1, 0, -1):
        a[i] = a[i-1]
    a[0] = a_l

# ---------- Functions ----------

def InitComponentNodes(inout state: EnergyPlusData, MinCompMdot: Float64, MaxCompMdot: Float64, InletNode: Int, OutletNode: Int):
    var tmpMinCompMdot: Float64 = MinCompMdot
    var tmpMaxCompMdot: Float64 = MaxCompMdot
    if tmpMinCompMdot < 0.0:
        tmpMinCompMdot = 0.0
    if tmpMaxCompMdot < 0.0:
        tmpMaxCompMdot = 0.0
    state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = 0.0
    state.dataLoopNodes.Node[InletNode-1].MassFlowRateMin = tmpMinCompMdot
    state.dataLoopNodes.Node[InletNode-1].MassFlowRateMinAvail = tmpMinCompMdot
    state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax = tmpMaxCompMdot
    state.dataLoopNodes.Node[InletNode-1].MassFlowRateMaxAvail = tmpMaxCompMdot
    state.dataLoopNodes.Node[InletNode-1].MassFlowRate = 0.0
    state.dataLoopNodes.Node[InletNode-1].MassFlowRateRequest = 0.0

def SetComponentFlowRate(
    inout state: EnergyPlusData,
    inout CompFlow: Float64,
    InletNode: Int,
    OutletNode: Int,
    plantLoc: PlantLocation
):
    if plantLoc.loopNum == 0:
        if InletNode > 0:
            ShowSevereError(state,
                format("SetComponentFlowRate: trapped plant loop index = 0, check component with inlet node named={}", state.dataLoopNodes.NodeID[InletNode-1]))
        else:
            ShowSevereError(state, "SetComponentFlowRate: trapped plant loop node id = 0")
        return
    var MdotOldRequest: Float64 = state.dataLoopNodes.Node[InletNode-1].MassFlowRateRequest
    if plantLoc.comp.CurOpSchemeType == OpScheme.Demand:
        state.dataLoopNodes.Node[InletNode-1].MassFlowRateRequest = CompFlow
        state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMinAvail = max(
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMinAvail,
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMin)
        state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMaxAvail = min(
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMaxAvail,
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax)
    else:
        state.dataLoopNodes.Node[InletNode-1].MassFlowRateRequest = CompFlow
    state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMinAvail = max(
        state.dataLoopNodes.Node[InletNode-1].MassFlowRateMinAvail,
        state.dataLoopNodes.Node[InletNode-1].MassFlowRateMin)
    if state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax >= 0.0:
        state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMaxAvail = min(
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMaxAvail,
            state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax)
    else:
        if not state.dataGlobal.SysSizingCalc and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if not state.dataLoopNodes.Node[InletNode-1].plantNodeErrorMsgIssued:
                ShowSevereError(state,
                    format("SetComponentFlowRate: check component model implementation for component with inlet node named={}", state.dataLoopNodes.NodeID[InletNode-1]))
                ShowContinueError(state, format("Inlet node MassFlowRatMax = {:.8f}", state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax))
                state.dataLoopNodes.Node[InletNode-1].plantNodeErrorMsgIssued = True
    if plantLoc.side.FlowLock == FlowLock.Unlocked:
        if plantLoc.loop.MaxVolFlowRate == AutoSize:
            state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = CompFlow
            state.dataLoopNodes.Node[InletNode-1].MassFlowRate = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
        else:
            if plantLoc.comp.FlowCtrl == ControlType.SeriesActive:
                var SeriesBranchHighFlowRequest: Float64 = 0.0
                var SeriesBranchHardwareMaxLim: Float64 = state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax
                var SeriesBranchHardwareMinLim: Float64 = 0.0
                var SeriesBranchMaxAvail: Float64 = state.dataLoopNodes.Node[InletNode-1].MassFlowRateMaxAvail
                var SeriesBranchMinAvail: Float64 = 0.0
                var EMSLoadOverride: Bool = False
                for CompNum in range(1, plantLoc.branch.TotalComponents + 1):
                    var thisComp = plantLoc.branch.Comp[CompNum-1]
                    var CompInletNodeNum = thisComp.NodeNumIn
                    var thisInletNode = state.dataLoopNodes.Node[CompInletNodeNum-1]
                    SeriesBranchHighFlowRequest = max(thisInletNode.MassFlowRateRequest, SeriesBranchHighFlowRequest)
                    SeriesBranchHardwareMaxLim = min(thisInletNode.MassFlowRateMax, SeriesBranchHardwareMaxLim)
                    SeriesBranchHardwareMinLim = max(thisInletNode.MassFlowRateMin, SeriesBranchHardwareMinLim)
                    SeriesBranchMaxAvail = min(thisInletNode.MassFlowRateMaxAvail, SeriesBranchMaxAvail)
                    SeriesBranchMinAvail = max(thisInletNode.MassFlowRateMinAvail, SeriesBranchMinAvail)
                    if thisComp.EMSLoadOverrideOn and thisComp.EMSLoadOverrideValue == 0.0:
                        EMSLoadOverride = True
                if EMSLoadOverride:
                    SeriesBranchHardwareMaxLim = 0.0
                CompFlow = max(CompFlow, SeriesBranchHighFlowRequest)
                CompFlow = max(CompFlow, SeriesBranchHardwareMinLim)
                CompFlow = max(CompFlow, SeriesBranchMinAvail)
                CompFlow = min(CompFlow, SeriesBranchHardwareMaxLim)
                CompFlow = min(CompFlow, SeriesBranchMaxAvail)
                if CompFlow < MassFlowTolerance:
                    CompFlow = 0.0
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = CompFlow
                state.dataLoopNodes.Node[InletNode-1].MassFlowRate = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
                for CompNum in range(1, plantLoc.branch.TotalComponents + 1):
                    var thisComp = plantLoc.branch.Comp[CompNum-1]
                    var CompInletNodeNum = thisComp.NodeNumIn
                    var CompOutletNodeNum = thisComp.NodeNumOut
                    state.dataLoopNodes.Node[CompInletNodeNum-1].MassFlowRate = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
                    state.dataLoopNodes.Node[CompOutletNodeNum-1].MassFlowRate = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
            else:
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = max(state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMinAvail, CompFlow)
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = max(state.dataLoopNodes.Node[InletNode-1].MassFlowRateMin, state.dataLoopNodes.Node[OutletNode-1].MassFlowRate)
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = min(state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMaxAvail, state.dataLoopNodes.Node[OutletNode-1].MassFlowRate)
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = min(state.dataLoopNodes.Node[InletNode-1].MassFlowRateMax, state.dataLoopNodes.Node[OutletNode-1].MassFlowRate)
                var EMSLoadOverride: Bool = False
                for CompNum in range(1, plantLoc.branch.TotalComponents + 1):
                    var thisComp = plantLoc.branch.Comp[CompNum-1]
                    if thisComp.EMSLoadOverrideOn and thisComp.EMSLoadOverrideValue == 0.0:
                        EMSLoadOverride = True
                if EMSLoadOverride:
                    state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = 0.0
                if state.dataLoopNodes.Node[OutletNode-1].MassFlowRate < MassFlowTolerance:
                    state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = 0.0
                CompFlow = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
                state.dataLoopNodes.Node[InletNode-1].MassFlowRate = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
    elif plantLoc.side.FlowLock == FlowLock.Locked:
        state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = state.dataLoopNodes.Node[InletNode-1].MassFlowRate
        CompFlow = state.dataLoopNodes.Node[OutletNode-1].MassFlowRate
    else:
        ShowFatalError(state, "SetComponentFlowRate: Flow lock out of range")
    if plantLoc.comp.CurOpSchemeType == OpScheme.Demand:
        if (MdotOldRequest > 0.0) and (CompFlow > 0.0):
            if abs(MdotOldRequest - state.dataLoopNodes.Node[InletNode-1].MassFlowRateRequest) > MassFlowTolerance:
                plantLoc.side.SimLoopSideNeeded = True

def SetActuatedBranchFlowRate(
    inout state: EnergyPlusData,
    inout CompFlow: Float64,
    ActuatedNode: Int,
    plantLoc: PlantLocation,
    ResetMode: Bool
):
    var a_node = state.dataLoopNodes.Node[ActuatedNode-1]
    if plantLoc.loopNum == 0 or plantLoc.loopSideNum == LoopSideLocation.Invalid:
        a_node.MassFlowRate = CompFlow
        return
    var MdotOldRequest: Float64 = a_node.MassFlowRateRequest
    a_node.MassFlowRateRequest = CompFlow
    if plantLoc.loopNum > 0 and plantLoc.loopSideNum != LoopSideLocation.Invalid and not ResetMode:
        if (MdotOldRequest > 0.0) and (CompFlow > 0.0):
            if (abs(MdotOldRequest - a_node.MassFlowRateRequest) > MassFlowTolerance) and (plantLoc.side.FlowLock == FlowLock.Unlocked):
                plantLoc.side.SimLoopSideNeeded = True
    if plantLoc.loopNum > 0 and plantLoc.loopSideNum != LoopSideLocation.Invalid:
        var branch = plantLoc.side.Branch[plantLoc.branchNum - 1]
        if plantLoc.side.FlowLock == FlowLock.Unlocked:
            if plantLoc.loop.MaxVolFlowRate == AutoSize:
                a_node.MassFlowRate = CompFlow
            else:
                a_node.MassFlowRate = max(a_node.MassFlowRateMinAvail, CompFlow)
                a_node.MassFlowRate = max(a_node.MassFlowRateMin, a_node.MassFlowRate)
                var EMSLoadOverride: Bool = False
                for CompNum in range(1, branch.TotalComponents + 1):
                    var comp = branch.Comp[CompNum-1]
                    if comp.EMSLoadOverrideOn and comp.EMSLoadOverrideValue == 0.0:
                        EMSLoadOverride = True
                if EMSLoadOverride:
                    a_node.MassFlowRate = 0.0
                    a_node.MassFlowRateRequest = 0.0
                a_node.MassFlowRate = min(a_node.MassFlowRateMaxAvail, a_node.MassFlowRate)
                a_node.MassFlowRate = min(a_node.MassFlowRateMax, a_node.MassFlowRate)
                if a_node.MassFlowRate < MassFlowTolerance:
                    a_node.MassFlowRate = 0.0
                for CompNum in range(1, branch.TotalComponents + 1):
                    var comp = branch.Comp[CompNum-1]
                    if ActuatedNode == comp.NodeNumIn:
                        var NodeNum = comp.NodeNumOut
                        state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMinAvail = max(a_node.MassFlowRateMinAvail, a_node.MassFlowRateMin)
                        state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMaxAvail = min(a_node.MassFlowRateMaxAvail, a_node.MassFlowRateMax)
                        state.dataLoopNodes.Node[NodeNum-1].MassFlowRate = a_node.MassFlowRate
        elif plantLoc.side.FlowLock == FlowLock.Locked:
            CompFlow = a_node.MassFlowRate
            a_node.MassFlowRateRequest = MdotOldRequest
            if (CompFlow - a_node.MassFlowRateMaxAvail > MassFlowTolerance) or (a_node.MassFlowRateMinAvail - CompFlow > MassFlowTolerance):
                ShowSevereError(state, "SetActuatedBranchFlowRate: Flow rate is out of range")
                ShowContinueErrorTimeStamp(state, "")
                ShowContinueError(state, format("Component flow rate [kg/s] = {:.8f}", CompFlow))
                ShowContinueError(state, format("Node maximum flow rate available [kg/s] = {:.8f}", a_node.MassFlowRateMaxAvail))
                ShowContinueError(state, format("Node minimum flow rate available [kg/s] = {:.8f}", a_node.MassFlowRateMinAvail))
        else:
            ShowFatalError(state,
                format("SetActuatedBranchFlowRate: Flowlock out of range, value={}", int(plantLoc.side.FlowLock)))
        var a_node_MasFlowRate: Float64 = a_node.MassFlowRate
        var a_node_MasFlowRateRequest: Float64 = a_node.MassFlowRateRequest
        for CompNum in range(1, branch.TotalComponents + 1):
            var comp = branch.Comp[CompNum-1]
            var NodeNum = comp.NodeNumIn
            state.dataLoopNodes.Node[NodeNum-1].MassFlowRate = a_node_MasFlowRate
            state.dataLoopNodes.Node[NodeNum-1].MassFlowRateRequest = a_node_MasFlowRateRequest
            NodeNum = comp.NodeNumOut
            state.dataLoopNodes.Node[NodeNum-1].MassFlowRate = a_node_MasFlowRate
            state.dataLoopNodes.Node[NodeNum-1].MassFlowRateRequest = a_node_MasFlowRateRequest

def RegulateCondenserCompFlowReqOp(state: EnergyPlusData, plantLoc: PlantLocation, TentativeFlowRequest: Float64) -> Float64:
    var FlowVal: Float64
    var ZeroLoad: Float64 = 0.0001
    var CompCurLoad: Float64
    var CompRunFlag: Bool
    CompCurLoad = CompData.getPlantComponent(state, plantLoc).MyLoad
    CompRunFlag = CompData.getPlantComponent(state, plantLoc).ON
    var CompOpScheme: OpScheme = CompData.getPlantComponent(state, plantLoc).CurOpSchemeType
    if CompRunFlag:
        if CompOpScheme == OpScheme.HeatingRB or CompOpScheme == OpScheme.CoolingRB or CompOpScheme == OpScheme.CompSetPtBased:
            if abs(CompCurLoad) > ZeroLoad:
                FlowVal = TentativeFlowRequest
            else:
                FlowVal = 0.0
        else:
            FlowVal = TentativeFlowRequest
    else:
        FlowVal = 0.0
    return FlowVal

def AnyPlantSplitterMixerLacksContinuity(state: EnergyPlusData) -> Bool:
    for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        for LoopSide in LoopSideKeys:
            if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Splitter.Exists:
                var SplitterInletNode = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Splitter.NodeNumIn
                var NumSplitterOutlets = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Splitter.TotalOutletNodes
                var SumOutletFlow: Float64 = 0.0
                for OutletNum in range(1, NumSplitterOutlets + 1):
                    var BranchNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Splitter.BranchNumOut[OutletNum-1]
                    var LastNodeOnBranch = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Branch[BranchNum-1].NodeNumOut
                    SumOutletFlow += state.dataLoopNodes.Node[LastNodeOnBranch-1].MassFlowRate
                var AbsDifference = abs(state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate - SumOutletFlow)
                if AbsDifference > CriteriaDelta_MassFlowRate:
                    return True
    return False

def CheckPlantMixerSplitterConsistency(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSideNum: LoopSideLocation,
    FirstHVACIteration: Bool
):
    var AbsDifference: Float64
    var SumOutletFlow: Float64
    if not state.dataPlnt.PlantLoop[LoopNum-1].LoopHasConnectionComp:
        if not state.dataGlobal.DoingSizing and not state.dataGlobal.WarmupFlag and state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Mixer.Exists and not FirstHVACIteration:
            var MixerOutletNode = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Mixer.NodeNumOut
            var SplitterInletNode = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.NodeNumIn
            AbsDifference = abs(state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate - state.dataLoopNodes.Node[MixerOutletNode-1].MassFlowRate)
            if AbsDifference > MassFlowTolerance:
                if state.dataPlnt.PlantLoop[LoopNum-1].MFErrIndex1 == 0:
                    ShowSevereMessage(state, "Plant flows do not resolve -- splitter inlet flow does not match mixer outlet flow ")
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, format("PlantLoop name= {}", state.dataPlnt.PlantLoop[LoopNum-1].Name))
                    ShowContinueError(state, format("Plant Connector:Mixer name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Mixer.Name))
                    ShowContinueError(state, format("Mixer outlet mass flow rate= {:.6f} {{kg/s}}", state.dataLoopNodes.Node[MixerOutletNode-1].MassFlowRate))
                    ShowContinueError(state, format("Plant Connector:Splitter name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.Name))
                    ShowContinueError(state, format("Splitter inlet mass flow rate= {:.6f} {{kg/s}}", state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate))
                    ShowContinueError(state, format("Difference in two mass flow rates= {:.6f} {{kg/s}}", AbsDifference))
                ShowRecurringSevereErrorAtEnd(state,
                    "Plant Flows (Loop=" + state.dataPlnt.PlantLoop[LoopNum-1].Name + ") splitter inlet flow not match mixer outlet flow",
                    state.dataPlnt.PlantLoop[LoopNum-1].MFErrIndex1,
                    AbsDifference,
                    AbsDifference, None, "kg/s", "kg/s")
                if AbsDifference > MassFlowTolerance * 10.0:
                    ShowSevereError(state, "Plant flows do not resolve -- splitter inlet flow does not match mixer outlet flow ")
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, format("PlantLoop name= {}", state.dataPlnt.PlantLoop[LoopNum-1].Name))
                    ShowContinueError(state, format("Plant Connector:Mixer name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Mixer.Name))
                    ShowContinueError(state, format("Mixer outlet mass flow rate= {:.6f} {{kg/s}}", state.dataLoopNodes.Node[MixerOutletNode-1].MassFlowRate))
                    ShowContinueError(state, format("Plant Connector:Splitter name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.Name))
                    ShowContinueError(state, format("Splitter inlet mass flow rate= {:.6f} {{kg/s}}", state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate))
                    ShowContinueError(state, format("Difference in two mass flow rates= {:.6f} {{kg/s}}", AbsDifference))
                    ShowFatalError(state, "CheckPlantMixerSplitterConsistency: Simulation terminated because of problems in plant flow resolver")
            var NumSplitterOutlets = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.TotalOutletNodes
            SumOutletFlow = 0.0
            for OutletNum in range(1, NumSplitterOutlets + 1):
                var BranchNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.BranchNumOut[OutletNum-1]
                var LastNodeOnBranch = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Branch[BranchNum-1].NodeNumOut
                SumOutletFlow += state.dataLoopNodes.Node[LastNodeOnBranch-1].MassFlowRate
            AbsDifference = abs(state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate - SumOutletFlow)
            if AbsDifference > CriteriaDelta_MassFlowRate:
                if state.dataPlnt.PlantLoop[LoopNum-1].MFErrIndex2 == 0:
                    ShowSevereMessage(state, "Plant flows do not resolve -- splitter inlet flow does not match branch outlet flows")
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, format("PlantLoop name= {}", state.dataPlnt.PlantLoop[LoopNum-1].Name))
                    ShowContinueError(state, format("Plant Connector:Mixer name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Mixer.Name))
                    ShowContinueError(state, format("Sum of Branch outlet mass flow rates= {:.6f} {{kg/s}}", SumOutletFlow))
                    ShowContinueError(state, format("Plant Connector:Splitter name= {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].Splitter.Name))
                    ShowContinueError(state, format("Splitter inlet mass flow rate= {:.6f} {{kg/s}}", state.dataLoopNodes.Node[SplitterInletNode-1].MassFlowRate))
                    ShowContinueError(state, format("Difference in two mass flow rates= {:.6f} {{kg/s}}", AbsDifference))
                ShowRecurringSevereErrorAtEnd(state,
                    "Plant Flows (Loop=" + state.dataPlnt.PlantLoop[LoopNum-1].Name + ") splitter inlet flow does not match branch outlet flows",
                    state.dataPlnt.PlantLoop[LoopNum-1].MFErrIndex2,
                    AbsDifference,
                    AbsDifference, None, "kg/s", "kg/s")

def CheckForRunawayPlantTemps(inout state: EnergyPlusData, LoopNum: Int, LoopSideNum: LoopSideLocation):
    var OverShootOffset: Float64 = 5.0
    var UnderShootOffset: Float64 = 5.0
    var FatalOverShootOffset: Float64 = 200.0
    var FatalUnderShootOffset: Float64 = 100.0
    var hotcold: String
    var makefatalerror: Bool
    var LoopCapacity: Float64
    var LoopDemandSideCapacity: Float64
    var LoopSupplySideCapacity: Float64
    var DispatchedCapacity: Float64
    var LoopDemandSideDispatchedCapacity: Float64
    var LoopSupplySideDispatchedCapacity: Float64
    makefatalerror = False
    if state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp > (state.dataPlnt.PlantLoop[LoopNum-1].MaxTemp + OverShootOffset):
        ShowRecurringWarningErrorAtEnd(state,
            "Plant loop exceeding upper temperature limit, PlantLoop=\"" + state.dataPlnt.PlantLoop[LoopNum-1].Name + "\"",
            state.dataPlnt.PlantLoop[LoopNum-1].MaxTempErrIndex,
            state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp)
        if state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp > (state.dataPlnt.PlantLoop[LoopNum-1].MaxTemp + FatalOverShootOffset):
            hotcold = "hot"
            makefatalerror = True
    if state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp < (state.dataPlnt.PlantLoop[LoopNum-1].MinTemp - UnderShootOffset):
        ShowRecurringWarningErrorAtEnd(state,
            "Plant loop falling below lower temperature limit, PlantLoop=\"" + state.dataPlnt.PlantLoop[LoopNum-1].Name + "\"",
            state.dataPlnt.PlantLoop[LoopNum-1].MinTempErrIndex,
            None,
            state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp)
        if state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp < (state.dataPlnt.PlantLoop[LoopNum-1].MinTemp - FatalUnderShootOffset):
            hotcold = "cold"
            makefatalerror = True
    if makefatalerror:
        ShowSevereError(state, format("Plant temperatures are getting far too {}, check controls and relative loads and capacities", hotcold))
        ShowContinueErrorTimeStamp(state, "")
        ShowContinueError(state,
            format("PlantLoop Name ({} Side) = {}", DemandSupplyNames[int(LoopSideNum)], state.dataPlnt.PlantLoop[LoopNum-1].Name))
        ShowContinueError(state,
            format("PlantLoop Setpoint Temperature={:.1f} {{C}}", state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].TempSetPointNodeNum - 1].TempSetPoint))
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Supply].InletNodeSetPt:
            ShowContinueError(state, "PlantLoop Inlet Node (LoopSideLocation::Supply) has a Setpoint.")
        else:
            ShowContinueError(state, "PlantLoop Inlet Node (LoopSideLocation::Supply) does not have a Setpoint.")
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Demand].InletNodeSetPt:
            ShowContinueError(state, "PlantLoop Inlet Node (LoopSideLocation::Demand) has a Setpoint.")
        else:
            ShowContinueError(state, "PlantLoop Inlet Node (LoopSideLocation::Demand) does not have a Setpoint.")
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Supply].OutletNodeSetPt:
            ShowContinueError(state, "PlantLoop Outlet Node (LoopSideLocation::Supply) has a Setpoint.")
        else:
            ShowContinueError(state, "PlantLoop Outlet Node (LoopSideLocation::Supply) does not have a Setpoint.")
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Demand].OutletNodeSetPt:
            ShowContinueError(state, "PlantLoop Outlet Node (LoopSideLocation::Demand) has a Setpoint.")
        else:
            ShowContinueError(state, "PlantLoop Outlet Node (LoopSideLocation::Demand) does not have a Setpoint.")
        ShowContinueError(state,
            format("PlantLoop Outlet Node ({}Side) \"{}\" has temperature={:.1f} {{C}}",
                DemandSupplyNames[int(LoopSideNum)],
                state.dataLoopNodes.NodeID[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1],
                state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].Temp))
        ShowContinueError(state,
            format("PlantLoop Inlet Node ({}Side) \"{}\" has temperature={:.1f} {{C}}",
                DemandSupplyNames[int(LoopSideNum)],
                state.dataLoopNodes.NodeID[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumIn - 1],
                state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumIn - 1].Temp))
        ShowContinueError(state, format("PlantLoop Minimum Temperature={:.1f} {{C}}", state.dataPlnt.PlantLoop[LoopNum-1].MinTemp))
        ShowContinueError(state, format("PlantLoop Maximum Temperature={:.1f} {{C}}", state.dataPlnt.PlantLoop[LoopNum-1].MaxTemp))
        ShowContinueError(state,
            format("PlantLoop Flow Request (LoopSideLocation::Supply)={:.1f} {{kg/s}}",
                state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Supply].FlowRequest))
        ShowContinueError(state,
            format("PlantLoop Flow Request (LoopSideLocation::Demand)={:.1f} {{kg/s}}",
                state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Demand].FlowRequest))
        ShowContinueError(state,
            format("PlantLoop Node ({}Side) \"{}\" has mass flow rate ={:.1f} {{kg/s}}",
                DemandSupplyNames[int(LoopSideNum)],
                state.dataLoopNodes.NodeID[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1],
                state.dataLoopNodes.Node[state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].NodeNumOut - 1].MassFlowRate))
        ShowContinueError(state,
            format("PlantLoop PumpHeat (LoopSideLocation::Supply)={:.1f} {{W}}",
                state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Supply].TotalPumpHeat))
        ShowContinueError(state,
            format("PlantLoop PumpHeat (LoopSideLocation::Demand)={:.1f} {{W}}",
                state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideLocation.Demand].TotalPumpHeat))
        ShowContinueError(state, format("PlantLoop Cooling Demand={:.1f} {{W}}", state.dataPlnt.PlantLoop[LoopNum-1].CoolingDemand))
        ShowContinueError(state, format("PlantLoop Heating Demand={:.1f} {{W}}", state.dataPlnt.PlantLoop[LoopNum-1].HeatingDemand))
        ShowContinueError(state, format("PlantLoop Demand not Dispatched={:.1f} {{W}}", state.dataPlnt.PlantLoop[LoopNum-1].DemandNotDispatched))
        ShowContinueError(state, format("PlantLoop Unmet Demand={:.1f} {{W}}", state.dataPlnt.PlantLoop[LoopNum-1].UnmetDemand))
        LoopCapacity = 0.0
        DispatchedCapacity = 0.0
        for LSN in LoopSideKeys:
            for BrN in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].TotalBranches + 1):
                for CpN in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].TotalComponents + 1):
                    LoopCapacity += state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].Comp[CpN-1].MaxLoad
                    DispatchedCapacity += abs(state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].Comp[CpN-1].MyLoad)
            if LSN == LoopSideLocation.Demand:
                LoopDemandSideCapacity = LoopCapacity
                LoopDemandSideDispatchedCapacity = DispatchedCapacity
            else:
                LoopSupplySideCapacity = LoopCapacity - LoopDemandSideCapacity
                LoopSupplySideDispatchedCapacity = DispatchedCapacity - LoopDemandSideDispatchedCapacity
        ShowContinueError(state, format("PlantLoop Capacity={:.1f} {{W}}", LoopCapacity))
        ShowContinueError(state, format("PlantLoop Capacity (LoopSideLocation::Supply)={:.1f} {{W}}", LoopSupplySideCapacity))
        ShowContinueError(state, format("PlantLoop Capacity (LoopSideLocation::Demand)={:.1f} {{W}}", LoopDemandSideCapacity))
        ShowContinueError(state, format("PlantLoop Operation Scheme={}", state.dataPlnt.PlantLoop[LoopNum-1].OperationScheme))
        ShowContinueError(state, format("PlantLoop Operation Dispatched Load = {:.1f} {{W}}", DispatchedCapacity))
        ShowContinueError(state, format("PlantLoop Operation Dispatched Load (LoopSideLocation::Supply)= {:.1f} {{W}}", LoopSupplySideDispatchedCapacity))
        ShowContinueError(state, format("PlantLoop Operation Dispatched Load (LoopSideLocation::Demand)= {:.1f} {{W}}", LoopDemandSideDispatchedCapacity))
        ShowContinueError(state, "Branches on the Loop.")
        ShowBranchesOnLoop(state, LoopNum)
        ShowContinueError(state, "*************************")
        ShowContinueError(state, "Possible things to look for to correct this problem are:")
        ShowContinueError(state, "  Capacity, Operation Scheme, Mass flow problems, Pump Heat building up over time.")
        ShowContinueError(state, "  Try a shorter runperiod to stop before it fatals and look at")
        ShowContinueError(state, "    lots of node time series data to see what is going wrong.")
        ShowContinueError(state, "  If this is happening during Warmup, you can use Output:Diagnostics,ReportDuringWarmup;")
        ShowContinueError(state, "  This is detected at the loop level, but the typical problems are in the components.")
        ShowFatalError(state,
            format("CheckForRunawayPlantTemps: Simulation terminated because of run away plant temperatures, too {}", hotcold))

def SetAllFlowLocks(inout state: EnergyPlusData, Value: FlowLock):
    for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        for LoopSideNum in LoopSideKeys:
            state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSideNum].FlowLock = Value

def ResetAllPlantInterConnectFlags(inout state: EnergyPlusData):
    for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        for e in state.dataPlnt.PlantLoop[LoopNum-1].LoopSide:
            e.SimAirLoopsNeeded = False
            e.SimZoneEquipNeeded = False
            e.SimNonZoneEquipNeeded = False
            e.SimElectLoadCentrNeeded = False

def PullCompInterconnectTrigger(
    inout state: EnergyPlusData,
    plantLoc: PlantLocation,
    inout UniqueCriteriaCheckIndex: Int,
    ConnectedPlantLoc: PlantLocation,
    CriteriaType: CriteriaType,
    CriteriaValue: Float64
):
    if UniqueCriteriaCheckIndex <= 0:
        var CurrentNumChecksStored: Int = state.dataPlantUtilities.CriteriaChecks.size + 1
        state.dataPlantUtilities.CriteriaChecks.redimension(CurrentNumChecksStored)
        state.dataPlantUtilities.CriteriaChecks[CurrentNumChecksStored-1].CallingCompLoopNum = plantLoc.loopNum
        state.dataPlantUtilities.CriteriaChecks[CurrentNumChecksStored-1].CallingCompLoopSideNum = plantLoc.loopSideNum
        if plantLoc.loopNum == 0 or plantLoc.loopSideNum == LoopSideLocation.Invalid:
            assert(False)
        ConnectedPlantLoc.side.SimLoopSideNeeded = True
        UniqueCriteriaCheckIndex = CurrentNumChecksStored
    else:
        var CurCriteria: CriteriaData = state.dataPlantUtilities.CriteriaChecks[UniqueCriteriaCheckIndex-1]
        if CriteriaType == CriteriaType.MassFlowRate:
            if abs(CurCriteria.ThisCriteriaCheckValue - CriteriaValue) > CriteriaDelta_MassFlowRate:
                ConnectedPlantLoc.side.SimLoopSideNeeded = True
        elif CriteriaType == CriteriaType.Temperature:
            if abs(CurCriteria.ThisCriteriaCheckValue - CriteriaValue) > CriteriaDelta_Temperature:
                ConnectedPlantLoc.side.SimLoopSideNeeded = True
        elif CriteriaType == CriteriaType.HeatTransferRate:
            if abs(CurCriteria.ThisCriteriaCheckValue - CriteriaValue) > CriteriaDelta_HeatTransferRate:
                ConnectedPlantLoc.side.SimLoopSideNeeded = True
        else:
            assert(False)
    state.dataPlantUtilities.CriteriaChecks[UniqueCriteriaCheckIndex-1].ThisCriteriaCheckValue = CriteriaValue

def UpdateChillerComponentCondenserSide(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSide: LoopSideLocation,
    Type: PlantEquipmentType,
    InletNodeNum: Int,
    OutletNodeNum: Int,
    ModelCondenserHeatRate: Float64,
    ModelInletTemp: Float64,
    ModelOutletTemp: Float64,
    ModelMassFlowRate: Float64,
    FirstHVACIteration: Bool
):
    var RoutineName: StringLiteral = "UpdateChillerComponentCondenserSide"
    var DidAnythingChange: Bool = False
    var OtherLoopSide: LoopSideLocation
    var Cp: Float64
    if state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate != ModelMassFlowRate:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRate != ModelMassFlowRate:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[InletNodeNum-1].Temp != ModelInletTemp:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[OutletNodeNum-1].Temp != ModelOutletTemp:
        DidAnythingChange = True
    elif (state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate == 0.0) and (abs(ModelCondenserHeatRate) > 0.0):
        DidAnythingChange = True
    if DidAnythingChange or FirstHVACIteration:
        if state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate > MassFlowTolerance:
            Cp = state.dataPlnt.PlantLoop[LoopNum-1].glycol.getSpecificHeat(state, ModelInletTemp, RoutineName)
            state.dataLoopNodes.Node[OutletNodeNum-1].Temp = state.dataLoopNodes.Node[InletNodeNum-1].Temp + ModelCondenserHeatRate / (state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate * Cp)
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = True
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected > 0:
            for ConnectLoopNum in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected + 1):
                if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopDemandsOnRemote:
                    var OtherLoopNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopNum
                    OtherLoopSide = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopSideNum
                    state.dataPlnt.PlantLoop[OtherLoopNum-1].LoopSide[OtherLoopSide].SimLoopSideNeeded = True
    else:
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = False

def UpdateComponentHeatRecoverySide(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSide: LoopSideLocation,
    Type: PlantEquipmentType,
    InletNodeNum: Int,
    OutletNodeNum: Int,
    ModelRecoveryHeatRate: Float64,
    ModelInletTemp: Float64,
    ModelOutletTemp: Float64,
    ModelMassFlowRate: Float64,
    FirstHVACIteration: Bool
):
    var RoutineName: StringLiteral = "UpdateComponentHeatRecoverySide"
    var DidAnythingChange: Bool = False
    var OtherLoopSide: LoopSideLocation
    var Cp: Float64
    if state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate != ModelMassFlowRate:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRate != ModelMassFlowRate:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[InletNodeNum-1].Temp != ModelInletTemp:
        DidAnythingChange = True
    elif state.dataLoopNodes.Node[OutletNodeNum-1].Temp != ModelOutletTemp:
        DidAnythingChange = True
    elif (state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate == 0.0) and (ModelRecoveryHeatRate > 0.0):
        DidAnythingChange = True
    if DidAnythingChange or FirstHVACIteration:
        if state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate > MassFlowTolerance:
            Cp = state.dataPlnt.PlantLoop[LoopNum-1].glycol.getSpecificHeat(state, ModelInletTemp, RoutineName)
            state.dataLoopNodes.Node[OutletNodeNum-1].Temp = state.dataLoopNodes.Node[InletNodeNum-1].Temp + ModelRecoveryHeatRate / (state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate * Cp)
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = True
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected > 0:
            for ConnectLoopNum in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected + 1):
                if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopDemandsOnRemote:
                    var OtherLoopNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopNum
                    OtherLoopSide = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopSideNum
                    state.dataPlnt.PlantLoop[OtherLoopNum-1].LoopSide[OtherLoopSide].SimLoopSideNeeded = True
    else:
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = False

def UpdateAbsorberChillerComponentGeneratorSide(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSide: LoopSideLocation,
    Type: PlantEquipmentType,
    InletNodeNum: Int,
    OutletNodeNum: Int,
    HeatSourceType: FluidType,
    ModelGeneratorHeatRate: Float64,
    ModelMassFlowRate: Float64,
    FirstHVACIteration: Bool
):
    var DidAnythingChange: Bool = False
    var OtherLoopSide: LoopSideLocation
    if state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate != ModelMassFlowRate:
        DidAnythingChange = True
    elif (state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate == 0.0) and (ModelGeneratorHeatRate > 0.0):
        DidAnythingChange = True
    if DidAnythingChange or FirstHVACIteration:
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = True
        if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected > 0:
            for ConnectLoopNum in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].TotalConnected + 1):
                if state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopDemandsOnRemote:
                    var OtherLoopNum = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopNum
                    OtherLoopSide = state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].Connected[ConnectLoopNum-1].LoopSideNum
                    state.dataPlnt.PlantLoop[OtherLoopNum-1].LoopSide[OtherLoopSide].SimLoopSideNeeded = True
    else:
        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LoopSide].SimLoopSideNeeded = False

def InterConnectTwoPlantLoopSides(
    state: EnergyPlusData,
    Loop1PlantLoc: PlantLocation,
    Loop2PlantLoc: PlantLocation,
    ComponentType: PlantEquipmentType,
    Loop1DemandsOnLoop2: Bool
):
    if Loop1PlantLoc.loopNum == 0 or Loop1PlantLoc.loopSideNum == LoopSideLocation.Invalid or Loop2PlantLoc.loopNum == 0 or Loop2PlantLoc.loopSideNum == LoopSideLocation.Invalid:
        return
    var Loop2DemandsOnLoop1: Bool = not Loop1DemandsOnLoop2
    var TotalConnected: Int
    var connected_1 = Loop1PlantLoc.side.Connected
    if connected_1.size > 0 and connected_1[0] is not None:  # allocated check
        TotalConnected = Loop1PlantLoc.side.TotalConnected + 1
        Loop1PlantLoc.side.TotalConnected = TotalConnected
        connected_1.redimension(TotalConnected)
    else:
        TotalConnected = 1
        Loop1PlantLoc.side.TotalConnected = TotalConnected
        connected_1.allocate(1)
    connected_1[TotalConnected-1].LoopNum = Loop2PlantLoc.loopNum
    connected_1[TotalConnected-1].LoopSideNum = Loop2PlantLoc.loopSideNum
    connected_1[TotalConnected-1].ConnectorTypeOf_Num = int(ComponentType)
    connected_1[TotalConnected-1].LoopDemandsOnRemote = Loop1DemandsOnLoop2
    var connected_2 = Loop2PlantLoc.side.Connected
    if connected_2.size > 0 and connected_2[0] is not None:
        TotalConnected = Loop2PlantLoc.side.TotalConnected + 1
        Loop2PlantLoc.side.TotalConnected = TotalConnected
        connected_2.redimension(TotalConnected)
    else:
        TotalConnected = 1
        Loop2PlantLoc.side.TotalConnected = TotalConnected
        connected_2.allocate(1)
    connected_2[TotalConnected-1].LoopNum = Loop1PlantLoc.loopNum
    connected_2[TotalConnected-1].LoopSideNum = Loop1PlantLoc.loopSideNum
    connected_2[TotalConnected-1].ConnectorTypeOf_Num = int(ComponentType)
    connected_2[TotalConnected-1].LoopDemandsOnRemote = Loop2DemandsOnLoop1

def ShiftPlantLoopSideCallingOrder(inout state: EnergyPlusData, OldIndex: Int, NewIndex: Int):
    var RecordToMoveInPlantCallingOrderInfo: PlantCallingOrderInfoStruct
    if OldIndex == 0:
        ShowSevereError(state, "ShiftPlantLoopSideCallingOrder: developer error notice of invalid index, Old Index=0")
    if NewIndex == 0:
        ShowSevereError(state, "ShiftPlantLoopSideCallingOrder: developer error notice of invalid index, New Index=1")
    if (OldIndex == 0) or (NewIndex == 0):
        return
    var TempPlantCallingOrderInfo: List[PlantCallingOrderInfoStruct] = state.dataPlnt.PlantCallingOrderInfo.copy()
    RecordToMoveInPlantCallingOrderInfo = state.dataPlnt.PlantCallingOrderInfo[OldIndex-1]
    if OldIndex == NewIndex:

    elif (OldIndex == 1) and (NewIndex > OldIndex) and (NewIndex < state.dataPlnt.TotNumHalfLoops):
        state.dataPlnt.PlantCallingOrderInfo[0:NewIndex-1] = TempPlantCallingOrderInfo[1:NewIndex]
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
        state.dataPlnt.PlantCallingOrderInfo[NewIndex:state.dataPlnt.TotNumHalfLoops] = TempPlantCallingOrderInfo[NewIndex:state.dataPlnt.TotNumHalfLoops]
    elif (OldIndex == 1) and (NewIndex > OldIndex) and (NewIndex == state.dataPlnt.TotNumHalfLoops):
        state.dataPlnt.PlantCallingOrderInfo[0:NewIndex-1] = TempPlantCallingOrderInfo[1:NewIndex]
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
    elif (OldIndex > 1) and (NewIndex > OldIndex) and (NewIndex < state.dataPlnt.TotNumHalfLoops):
        state.dataPlnt.PlantCallingOrderInfo[0:OldIndex-1] = TempPlantCallingOrderInfo[0:OldIndex-1]
        state.dataPlnt.PlantCallingOrderInfo[OldIndex-1:NewIndex-1] = TempPlantCallingOrderInfo[OldIndex:NewIndex]
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
        state.dataPlnt.PlantCallingOrderInfo[NewIndex:state.dataPlnt.TotNumHalfLoops] = TempPlantCallingOrderInfo[NewIndex:state.dataPlnt.TotNumHalfLoops]
    elif (OldIndex > 1) and (NewIndex > OldIndex) and (NewIndex == state.dataPlnt.TotNumHalfLoops):
        state.dataPlnt.PlantCallingOrderInfo[0:OldIndex-1] = TempPlantCallingOrderInfo[0:OldIndex-1]
        state.dataPlnt.PlantCallingOrderInfo[OldIndex-1:NewIndex-1] = TempPlantCallingOrderInfo[OldIndex:NewIndex]
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
    elif (OldIndex > 1) and (NewIndex < OldIndex) and (NewIndex == 1):
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
        state.dataPlnt.PlantCallingOrderInfo[NewIndex:OldIndex] = TempPlantCallingOrderInfo[0:OldIndex-1]
        state.dataPlnt.PlantCallingOrderInfo[OldIndex:state.dataPlnt.TotNumHalfLoops] = TempPlantCallingOrderInfo[OldIndex:state.dataPlnt.TotNumHalfLoops]
    elif (OldIndex > 1) and (NewIndex < OldIndex) and (NewIndex > 1):
        state.dataPlnt.PlantCallingOrderInfo[0:NewIndex-1] = TempPlantCallingOrderInfo[0:NewIndex-1]
        state.dataPlnt.PlantCallingOrderInfo[NewIndex-1] = RecordToMoveInPlantCallingOrderInfo
        state.dataPlnt.PlantCallingOrderInfo[NewIndex:OldIndex] = TempPlantCallingOrderInfo[NewIndex-1:NewIndex + (OldIndex - NewIndex) - 1]
        state.dataPlnt.PlantCallingOrderInfo[OldIndex:state.dataPlnt.TotNumHalfLoops] = TempPlantCallingOrderInfo[OldIndex:state.dataPlnt.TotNumHalfLoops]
    else:
        ShowSevereError(state,
            "ShiftPlantLoopSideCallingOrder: developer error notice, caught unexpected logical case in ShiftPlantLoopSideCallingOrder PlantUtilities")

def RegisterPlantCompDesignFlow(inout state: EnergyPlusData, ComponentInletNodeNum: Int, DesPlantFlow: Float64):
    var NumPlantComps: Int
    var PlantCompNum: Int
    var Found: Bool
    var thisCallNodeIndex: Int
    NumPlantComps = state.dataSize.SaveNumPlantComps
    if NumPlantComps == 0:
        NumPlantComps = 1
        state.dataSize.CompDesWaterFlow.allocate(NumPlantComps)
        state.dataSize.CompDesWaterFlow[NumPlantComps-1].SupNode = ComponentInletNodeNum
        state.dataSize.CompDesWaterFlow[NumPlantComps-1].DesVolFlowRate = DesPlantFlow
        state.dataSize.SaveNumPlantComps = NumPlantComps
        return
    Found = False
    for PlantCompNum in range(1, NumPlantComps + 1):
        if ComponentInletNodeNum == state.dataSize.CompDesWaterFlow[PlantCompNum-1].SupNode:
            Found = True
            thisCallNodeIndex = PlantCompNum
        if Found:
            break
    if not Found:
        NumPlantComps += 1
        state.dataSize.CompDesWaterFlow.emplace_back(ComponentInletNodeNum, DesPlantFlow)
        state.dataSize.SaveNumPlantComps = NumPlantComps
    else:
        state.dataSize.CompDesWaterFlow[thisCallNodeIndex-1].SupNode = ComponentInletNodeNum
        state.dataSize.CompDesWaterFlow[thisCallNodeIndex-1].DesVolFlowRate = DesPlantFlow

def SafeCopyPlantNode(
    inout state: EnergyPlusData,
    InletNodeNum: Int,
    OutletNodeNum: Int,
    LoopNum: Int? = None,
    OutletTemp: Float64? = None
):
    state.dataLoopNodes.Node[OutletNodeNum-1].fluidType = state.dataLoopNodes.Node[InletNodeNum-1].fluidType
    state.dataLoopNodes.Node[OutletNodeNum-1].Temp = state.dataLoopNodes.Node[InletNodeNum-1].Temp
    state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRate = state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate
    state.dataLoopNodes.Node[OutletNodeNum-1].Quality = state.dataLoopNodes.Node[InletNodeNum-1].Quality
    state.dataLoopNodes.Node[OutletNodeNum-1].Enthalpy = state.dataLoopNodes.Node[InletNodeNum-1].Enthalpy
    state.dataLoopNodes.Node[OutletNodeNum-1].TempMin = state.dataLoopNodes.Node[InletNodeNum-1].TempMin
    state.dataLoopNodes.Node[OutletNodeNum-1].TempMax = state.dataLoopNodes.Node[InletNodeNum-1].TempMax
    state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRateMinAvail = max(
        state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRateMin,
        state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRateMinAvail)
    state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRateMaxAvail = min(
        state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRateMax,
        state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRateMaxAvail)
    state.dataLoopNodes.Node[OutletNodeNum-1].HumRat = state.dataLoopNodes.Node[InletNodeNum-1].HumRat
    if LoopNum is not None:
        if state.dataPlnt.PlantLoop[LoopNum-1].PressureSimType == PressSimType.NoPressure:
            state.dataLoopNodes.Node[OutletNodeNum-1].Press = state.dataLoopNodes.Node[InletNodeNum-1].Press

def BoundValueToNodeMinMaxAvail(state: EnergyPlusData, ValueToBound: Float64, NodeNumToBoundWith: Int) -> Float64:
    var BoundedValue: Float64 = ValueToBound
    BoundedValue = max(BoundedValue, state.dataLoopNodes.Node[NodeNumToBoundWith-1].MassFlowRateMinAvail)
    BoundedValue = min(BoundedValue, state.dataLoopNodes.Node[NodeNumToBoundWith-1].MassFlowRateMaxAvail)
    return BoundedValue

def TightenNodeMinMaxAvails(inout state: EnergyPlusData, NodeNum: Int, NewMinAvail: Float64, NewMaxAvail: Float64):
    var OldMinAvail: Float64 = state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMinAvail
    var OldMaxAvail: Float64 = state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMaxAvail
    if (NewMinAvail > OldMinAvail) and (NewMinAvail <= OldMaxAvail):
        state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMinAvail = NewMinAvail
    if (NewMaxAvail < OldMaxAvail) and (NewMaxAvail >= OldMinAvail):
        state.dataLoopNodes.Node[NodeNum-1].MassFlowRateMaxAvail = NewMaxAvail

def BoundValueToWithinTwoValues(ValueToBound: Float64, LowerBound: Float64, UpperBound: Float64) -> Float64:
    var BoundedValue: Float64 = ValueToBound
    BoundedValue = max(BoundedValue, LowerBound)
    BoundedValue = min(BoundedValue, UpperBound)
    return BoundedValue

def IntegerIsWithinTwoValues(ValueToCheck: Int, LowerBound: Int, UpperBound: Int) -> Bool:
    return (ValueToCheck >= LowerBound) and (ValueToCheck <= UpperBound)

def LogPlantConvergencePoints(inout state: EnergyPlusData, FirstHVACIteration: Bool):
    for ThisLoopNum in range(1, isize(state.dataPlnt.PlantLoop) + 1):
        var loop = state.dataPlnt.PlantLoop[ThisLoopNum-1]
        for ThisLoopSide in LoopSideKeys:
            var loop_side = loop.LoopSide[ThisLoopSide]
            if FirstHVACIteration:
                loop_side.InletNode.TemperatureHistory = 0.0
                loop_side.InletNode.MassFlowRateHistory = 0.0
                loop_side.OutletNode.TemperatureHistory = 0.0
                loop_side.OutletNode.MassFlowRateHistory = 0.0
            var InletNodeNum = loop_side.NodeNumIn
            var InletNodeTemp = state.dataLoopNodes.Node[InletNodeNum-1].Temp
            var InletNodeMdot = state.dataLoopNodes.Node[InletNodeNum-1].MassFlowRate
            var OutletNodeNum = loop_side.NodeNumOut
            var OutletNodeTemp = state.dataLoopNodes.Node[OutletNodeNum-1].Temp
            var OutletNodeMdot = state.dataLoopNodes.Node[OutletNodeNum-1].MassFlowRate
            rshift1(loop_side.InletNode.TemperatureHistory, InletNodeTemp)
            rshift1(loop_side.InletNode.MassFlowRateHistory, InletNodeMdot)
            rshift1(loop_side.OutletNode.TemperatureHistory, OutletNodeTemp)
            rshift1(loop_side.OutletNode.MassFlowRateHistory, OutletNodeMdot)

def ScanPlantLoopsForObject(
    inout state: EnergyPlusData,
    CompName: String,
    CompType: PlantEquipmentType,
    inout plantLoc: PlantLocation,
    inout errFlag: Bool,
    LowLimitTemp: Float64? = None,
    HighLimitTemp: Float64? = None,
    CountMatchPlantLoops: Int? = None,
    InletNodeNumber: Int? = None,
    SingleLoopSearch: Int? = None,
    suppressErrors: Bool? = None
):
    var LoopCtr: Int
    var BranchCtr: Int
    var CompCtr: Int
    var FoundComponent: Bool
    var FoundCount: Int
    var FoundCompName: Bool
    var StartingLoopNum: Int
    var EndingLoopNum: Int
    FoundCount = 0
    FoundComponent = False
    FoundCompName = False
    StartingLoopNum = 1
    EndingLoopNum = state.dataPlnt.TotNumLoops
    if SingleLoopSearch is not None:
        StartingLoopNum = SingleLoopSearch
        EndingLoopNum = SingleLoopSearch
    for LoopCtr in range(StartingLoopNum, EndingLoopNum + 1):
        var this_loop = state.dataPlnt.PlantLoop[LoopCtr-1]
        for LoopSideCtr in LoopSideKeys:
            var this_loop_side = this_loop.LoopSide[LoopSideCtr]
            for BranchCtr in range(1, this_loop_side.TotalBranches + 1):
                var this_branch = this_loop_side.Branch[BranchCtr-1]
                for CompCtr in range(1, this_branch.TotalComponents + 1):
                    var this_component = this_branch.Comp[CompCtr-1]
                    if this_component.Type == CompType:
                        if SameString(CompName, this_component.Name):
                            FoundCompName = True
                            if InletNodeNumber is not None:
                                if InletNodeNumber > 0:
                                    if InletNodeNumber == this_component.NodeNumIn:
                                        FoundComponent = True
                                        FoundCount += 1
                                        plantLoc.loopNum = LoopCtr
                                        plantLoc.loopSideNum = LoopSideCtr
                                        plantLoc.branchNum = BranchCtr
                                        plantLoc.compNum = CompCtr
                                        plantLoc.loop = address_of(this_loop)
                                        plantLoc.side = address_of(this_loop_side)
                                        plantLoc.branch = address_of(this_branch)
                                        plantLoc.comp = address_of(this_component)
                            else:
                                FoundComponent = True
                                FoundCount += 1
                                plantLoc.loopNum = LoopCtr
                                plantLoc.loopSideNum = LoopSideCtr
                                plantLoc.branchNum = BranchCtr
                                plantLoc.compNum = CompCtr
                                plantLoc.loop = address_of(this_loop)
                                plantLoc.side = address_of(this_loop_side)
                                plantLoc.branch = address_of(this_branch)
                                plantLoc.comp = address_of(this_component)
                            if LowLimitTemp is not None:
                                this_component.MinOutletTemp = LowLimitTemp
                            if HighLimitTemp is not None:
                                this_component.MaxOutletTemp = HighLimitTemp
    var skipErrors: Bool = False
    if suppressErrors is not None:
        skipErrors = suppressErrors
    if not FoundComponent and not skipErrors:
        if CompType != PlantEquipmentType.Invalid and CompType != PlantEquipmentType.Num:
            if SingleLoopSearch is None:
                ShowSevereError(state,
                    format("Plant Component {} called \"{}\" was not found on any plant loops.",
                        PlantEquipTypeNames[int(CompType)],
                        CompName))
                AuditBranches(state, True, PlantEquipTypeNames[int(CompType)], CompName)
            else:
                ShowSevereError(state,
                    format("Plant Component {} called \"{}\" was not found on plant loop=\"{}\".",
                        PlantEquipTypeNames[int(CompType)],
                        CompName,
                        state.dataPlnt.PlantLoop[SingleLoopSearch-1].Name))
            if InletNodeNumber is not None:
                if FoundCompName:
                    ShowContinueError(state, format("Looking for matching inlet Node=\"{}\".", state.dataLoopNodes.NodeID[InletNodeNumber-1]))
            if SingleLoopSearch is not None:
                ShowContinueError(state,
                    format("Look at Operation Scheme=\"{}\".", state.dataPlnt.PlantLoop[SingleLoopSearch-1].OperationScheme))
                ShowContinueError(state, "Look at Branches and Components on the Loop.")
                ShowBranchesOnLoop(state, SingleLoopSearch)
            errFlag = True
        else:
            ShowSevereError(state,
                format("ScanPlantLoopsForObject: Invalid CompType passed [{}], Name={}", int(CompType), CompName))
            ShowContinueError(state, format("Valid CompTypes are in the range [0 - {}].", int(PlantEquipmentType.Num)))
            ShowFatalError(state, "Previous error causes program termination")
    if CountMatchPlantLoops is not None:
        CountMatchPlantLoops = FoundCount

def ScanPlantLoopsForNodeNum(
    inout state: EnergyPlusData,
    CallerName: String,
    NodeNum: Int,
    inout plantLoc: PlantLocation,
    inout CompNum: Int,
    reportError: Bool = True
):
    var LoopCtr: Int
    var BranchCtr: Int
    var CompCtr: Int
    var FoundNode: Bool
    var inFoundCount: Int
    var outFoundCount: Int
    inFoundCount = 0
    outFoundCount = 0
    CompNum = 0
    FoundNode = False
    for LoopCtr in range(1, state.dataPlnt.TotNumLoops + 1):
        var this_loop = state.dataPlnt.PlantLoop[LoopCtr-1]
        for LoopSideCtr in LoopSideKeys:
            var this_loop_side = this_loop.LoopSide[LoopSideCtr]
            for BranchCtr in range(1, this_loop_side.TotalBranches + 1):
                var this_branch = this_loop_side.Branch[BranchCtr-1]
                for CompCtr in range(1, this_branch.TotalComponents + 1):
                    var this_comp = this_branch.Comp[CompCtr-1]
                    if NodeNum == this_comp.NodeNumIn:
                        FoundNode = True
                        inFoundCount += 1
                        plantLoc.loopNum = LoopCtr
                        plantLoc.loopSideNum = LoopSideCtr
                        plantLoc.branchNum = BranchCtr
                        CompNum = CompCtr
                        plantLoc.loop = address_of(this_loop)
                        plantLoc.side = address_of(this_loop_side)
                        plantLoc.branch = address_of(this_branch)
                        plantLoc.comp = address_of(this_comp)
                    if NodeNum == this_comp.NodeNumOut:
                        outFoundCount += 1
                        plantLoc.loopNum = LoopCtr
                        plantLoc.loopSideNum = LoopSideCtr
                        plantLoc.branchNum = BranchCtr
                        plantLoc.loop = address_of(this_loop)
                        plantLoc.side = address_of(this_loop_side)
                        plantLoc.branch = address_of(this_branch)
                        plantLoc.comp = address_of(this_comp)
    if not FoundNode and reportError:
        ShowSevereError(state, "ScanPlantLoopsForNodeNum: Plant Node was not found as inlet node (for component) on any plant loops")
        ShowContinueError(state, format("Node Name=\"{}\"", state.dataLoopNodes.NodeID[NodeNum-1]))
        if not state.dataGlobal.DoingSizing:
            ShowContinueError(state, format("called by {}", CallerName))
        else:
            ShowContinueError(state, format("during sizing: called by {}", CallerName))
        if outFoundCount > 0:
            ShowContinueError(state, format("Node was found as outlet node (for component) {} time(s).", outFoundCount))
        ShowContinueError(state, "Possible error in Branch inputs.  For more information, look for other error messages related to this node name.")

def ScanPlantLoopsForNodeNum(
    inout state: EnergyPlusData,
    CallerName: String,
    NodeNum: Int,
    inout plantLoc: PlantLocation,
    reportError: Bool = True
):
    var dummy: Int = 0
    ScanPlantLoopsForNodeNum(state, CallerName, NodeNum, plantLoc, dummy, reportError)

def SetPlantLocationLinks(inout state: EnergyPlusData, inout plantLoc: PlantLocation):
    if plantLoc.loopNum == 0:
        return
    plantLoc.loop = address_of(state.dataPlnt.PlantLoop[plantLoc.loopNum-1])
    if plantLoc.loopSideNum == LoopSideLocation.Invalid:
        return
    plantLoc.side = address_of(plantLoc.loop.LoopSide[plantLoc.loopSideNum])
    if plantLoc.branchNum == 0:
        return
    plantLoc.branch = address_of(plantLoc.side.Branch[plantLoc.branchNum-1])
    if plantLoc.compNum == 0:
        return
    plantLoc.comp = address_of(plantLoc.branch.Comp[plantLoc.compNum-1])

def AnyPlantLoopSidesNeedSim(state: EnergyPlusData) -> Bool:
    var AnyPlantLoopSidesNeedSim: Bool = False
    for LoopCtr in range(1, state.dataPlnt.TotNumLoops + 1):
        for LoopSideCtr in LoopSideKeys:
            if state.dataPlnt.PlantLoop[LoopCtr-1].LoopSide[LoopSideCtr].SimLoopSideNeeded:
                AnyPlantLoopSidesNeedSim = True
                return AnyPlantLoopSidesNeedSim
    return AnyPlantLoopSidesNeedSim

def SetAllPlantSimFlagsToValue(inout state: EnergyPlusData, Value: Bool):
    for LoopCtr in range(1, state.dataPlnt.TotNumLoops + 1):
        var this_loop = state.dataPlnt.PlantLoop[LoopCtr-1]
        this_loop.LoopSide[LoopSideLocation.Demand].SimLoopSideNeeded = Value
        this_loop.LoopSide[LoopSideLocation.Supply].SimLoopSideNeeded = Value

def ShowBranchesOnLoop(inout state: EnergyPlusData, LoopNum: Int):
    for LSN in LoopSideKeys:
        ShowContinueError(state, format("{} Branches:", DemandSupplyNames[int(LSN)]))
        for BrN in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].TotalBranches + 1):
            ShowContinueError(state, format("  {}", state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].Name))
            ShowContinueError(state, "    Components on Branch:")
            for CpN in range(1, state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].TotalComponents + 1):
                ShowContinueError(state,
                    format("      {}:{}",
                        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].Comp[CpN-1].TypeOf,
                        state.dataPlnt.PlantLoop[LoopNum-1].LoopSide[LSN].Branch[BrN-1].Comp[CpN-1].Name))

def MyPlantSizingIndex(
    inout state: EnergyPlusData,
    CompType: String,
    CompName: String,
    NodeNumIn: Int,
    NodeNumOut: Int,
    inout ErrorsFound: Bool,
    PrintErrorFlag: Bool = True
) -> Int:
    var MyPltSizNum: Int = 0
    var MyPltLoopNum: Int = 0
    var DummyPlantLoc: PlantLocation = PlantLocation()
    ScanPlantLoopsForNodeNum(state, "MyPlantSizingIndex", NodeNumIn, DummyPlantLoc)
    if DummyPlantLoc.loopNum > 0:
        MyPltLoopNum = DummyPlantLoc.loopNum
    else:
        MyPltLoopNum = 0
    if MyPltLoopNum > 0:
        if state.dataSize.NumPltSizInput > 0:
            MyPltSizNum = FindItemInList(state.dataPlnt.PlantLoop[MyPltLoopNum-1].Name, state.dataSize.PlantSizData, PlantSizingData.PlantLoopName)
        if MyPltSizNum == 0:
            if PrintErrorFlag:
                ShowSevereError(state,
                    format("MyPlantSizingIndex: Could not find {} in Sizing:Plant objects.", state.dataPlnt.PlantLoop[MyPltLoopNum-1].Name))
                ShowContinueError(state, format("...reference Component Type=\"{}\", Name=\"{}\".", CompType, CompName))
            ErrorsFound = True
    else:
        if PrintErrorFlag:
            ShowWarningError(state, format("MyPlantSizingIndex: Could not find {} with name {} on any plant loop", CompType, CompName))
        ErrorsFound = True
    return MyPltSizNum

def verifyTwoNodeNumsOnSamePlantLoop(state: EnergyPlusData, nodeIndexA: Int, nodeIndexB: Int) -> Bool:
    var matchedIndexA: Int = 0
    var matchedIndexB: Int = 0
    for loopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        for loopSide in state.dataPlnt.PlantLoop[loopNum-1].LoopSide:
            for branch in loopSide.Branch:
                for comp in branch.Comp:
                    if comp.NodeNumIn == nodeIndexA or comp.NodeNumOut == nodeIndexA:
                        matchedIndexA = loopNum
                    if comp.NodeNumIn == nodeIndexB or comp.NodeNumOut == nodeIndexB:
                        matchedIndexB = loopNum
    return (matchedIndexA == matchedIndexB) and (matchedIndexA != 0)

def MinFlowIfBranchHasVSPump(
    state: EnergyPlusData,
    plantLoc: PlantLocation,
    inout foundBranchPump: Bool,
    inout foundLoopPump: Bool,
    setFlowStatus: Bool
) -> Float64:
    var branchPumpMinFlowLimit: Float64 = 0.0
    var NumCompsOnThisBranch: Int = plantLoc.branch.TotalComponents
    for CompCounter in range(1, NumCompsOnThisBranch + 1):
        var component = plantLoc.branch.Comp[CompCounter-1]
        if component.Type == PlantEquipmentType.PumpVariableSpeed or component.Type == PlantEquipmentType.PumpBankVariableSpeed:
            foundBranchPump = True
            if component.CompNum > 0:
                branchPumpMinFlowLimit = state.dataPumps.PumpEquip[component.CompNum-1].MassFlowRateMin
            break
    if not foundBranchPump:
        if plantLoc.loop.LoopSide[LoopSideLocation.Supply].TotalBranches > 1:
            var NumCompsOnInletBranch = plantLoc.loop.LoopSide[LoopSideLocation.Supply].Branch[0].TotalComponents
            for CompCounter in range(1, NumCompsOnInletBranch + 1):
                var component = plantLoc.loop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[CompCounter-1]
                if component.Type == PlantEquipmentType.PumpVariableSpeed or component.Type == PlantEquipmentType.PumpBankVariableSpeed:
                    foundLoopPump = True
                    if component.CompNum > 0:
                        branchPumpMinFlowLimit = state.dataPumps.PumpEquip[component.CompNum-1].MassFlowRateMin
                    break
    if setFlowStatus:
        if branchPumpMinFlowLimit > 0.0 and foundBranchPump:
            plantLoc.comp.FlowPriority = LoopFlowStatus.NeedyIfLoopOn
        else:
            plantLoc.comp.FlowPriority = LoopFlowStatus.TakesWhatGets
    return branchPumpMinFlowLimit

# ---------- Data types ----------

struct CriteriaData:
    var CallingCompLoopNum: Int = 0
    var CallingCompLoopSideNum: LoopSideLocation = LoopSideLocation.Invalid
    var ThisCriteriaCheckValue: Float64 = 0.0

struct PlantLocation:
    var loopNum: Int = 0
    var loopSideNum: LoopSideLocation = LoopSideLocation.Invalid
    var branchNum: Int = 0
    var compNum: Int = 0
    var loop: pointer[PlantLoop] = null
    var side: pointer[LoopSide] = null
    var branch: pointer[Branch] = null
    var comp: pointer[CompData] = null

# Note: This file is incomplete as it requires many supporting types from other modules.
# It is a direct translation of the C++ source for PlantUtilities.cc.