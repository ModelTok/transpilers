from .Fixtures.EnergyPlusFixture import *
from DataSizing import *
from FluidProperties import *
from PlantUtilities import *
from DataPlant import *
from ObjexxFCL.Array.functions import *

@test
def PlantUtilities_RegisterPlantCompDesignFlowTest1() raises:
    var TestNodeNum1 = 123
    var TestFlowRate1 = 45.6
    state.dataSize.SaveNumPlantComps = 0
    RegisterPlantCompDesignFlow(state, TestNodeNum1, TestFlowRate1)
    assert TestNodeNum1 == state.dataSize.CompDesWaterFlow[0].SupNode
    assert TestFlowRate1 == state.dataSize.CompDesWaterFlow[0].DesVolFlowRate
    var TestNodeNum2 = 234
    var TestFlowRate2 = 56.7
    RegisterPlantCompDesignFlow(state, TestNodeNum2, TestFlowRate2)
    assert TestNodeNum2 == state.dataSize.CompDesWaterFlow[1].SupNode
    assert TestFlowRate2 == state.dataSize.CompDesWaterFlow[1].DesVolFlowRate
    var TestFlowRate3 = 67.8
    RegisterPlantCompDesignFlow(state, TestNodeNum1, TestFlowRate3)
    assert TestFlowRate3 == state.dataSize.CompDesWaterFlow[0].DesVolFlowRate

@test
def TestRegulateCondenserCompFlowReqOp() raises:
    Fluid.GetFluidPropertiesData(state)
    assert 1 == state.dataFluid.refrigs.size()
    assert 1 == state.dataFluid.glycols.size()
    Fluid.GetFluidPropertiesData(state)
    assert 1 == state.dataFluid.refrigs.size()
    assert 1 == state.dataFluid.glycols.size()
    state.dataPlnt.PlantLoop.resize(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.resize(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.resize(1)
    var thisComponent = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0]
    var flowRequest = 3.14
    var returnedFlow: Float64
    thisComponent.ON = False
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.HeatingRB  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.CoolingRB  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.CompSetPtBased  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.Uncontrolled  # NOT meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.ON = True
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.HeatingRB  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.CoolingRB  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.CompSetPtBased  # meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(0.0 - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.CurOpSchemeType = DataPlant.OpScheme.Uncontrolled  # NOT meaningful load
    thisComponent.MyLoad = 0.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.MyLoad = 1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001
    thisComponent.MyLoad = -1000.0
    returnedFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1), flowRequest)
    assert abs(flowRequest - returnedFlow) < 0.00001

@test
def TestAnyPlantSplitterMixerLacksContinuity() raises:
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.resize(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Splitter.Exists = False
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.resize(2)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].NodeNumOut = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].NodeNumOut = 3
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.Exists = True
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.TotalOutletNodes = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.BranchNumOut.resize(2)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.BranchNumOut[0] = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Splitter.BranchNumOut[1] = 2
    state.dataLoopNodes.Node.resize(3)
    state.dataLoopNodes.Node[0].MassFlowRate = 3.0
    state.dataLoopNodes.Node[1].MassFlowRate = 1.0
    state.dataLoopNodes.Node[2].MassFlowRate = 2.0
    assert not PlantUtilities.AnyPlantSplitterMixerLacksContinuity(state)
    state.dataLoopNodes.Node[0].MassFlowRate = 4.0
    state.dataLoopNodes.Node[1].MassFlowRate = 1.0
    state.dataLoopNodes.Node[2].MassFlowRate = 2.0
    assert PlantUtilities.AnyPlantSplitterMixerLacksContinuity(state)
    state.dataLoopNodes.Node[0].MassFlowRate = 1.0
    state.dataLoopNodes.Node[1].MassFlowRate = 2.0
    state.dataLoopNodes.Node[2].MassFlowRate = 3.0
    assert PlantUtilities.AnyPlantSplitterMixerLacksContinuity(state)
    state.dataLoopNodes.Node[0].MassFlowRate = 0.0
    state.dataLoopNodes.Node[1].MassFlowRate = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.0
    assert not PlantUtilities.AnyPlantSplitterMixerLacksContinuity(state)

@test
def TestPullCompInterconnectTrigger() raises:
    state.dataPlnt.PlantLoop.resize(2)
    var plantLoc = PlantLocation(1, DataPlant.LoopSideLocation.Demand, 0, 0)
    PlantUtilities.SetPlantLocationLinks(state, plantLoc)
    var connectedPlantLoc = PlantLocation(2, DataPlant.LoopSideLocation.Demand, 0, 0)
    PlantUtilities.SetPlantLocationLinks(state, connectedPlantLoc)
    var criteriaCheckIndex1 = 0
    var criteriaCheckIndex2 = 0
    var criteriaCheckIndex3 = 0
    var criteriaValue1 = 0.0
    var criteriaValue2 = 0.0
    var criteriaValue3 = 0.0
    var connectedLoopSide = state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand]
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex1, connectedPlantLoc, DataPlant.CriteriaType.MassFlowRate, criteriaValue1)
    assert 1 == criteriaCheckIndex1
    assert connectedLoopSide.SimLoopSideNeeded
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex2, connectedPlantLoc, DataPlant.CriteriaType.Temperature, criteriaValue2)
    assert 2 == criteriaCheckIndex2
    assert connectedLoopSide.SimLoopSideNeeded
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex3, connectedPlantLoc, DataPlant.CriteriaType.HeatTransferRate, criteriaValue3)
    assert 3 == criteriaCheckIndex3
    assert connectedLoopSide.SimLoopSideNeeded
    criteriaValue1 = 2.718
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex1, connectedPlantLoc, DataPlant.CriteriaType.MassFlowRate, criteriaValue1)
    assert connectedLoopSide.SimLoopSideNeeded
    criteriaValue2 = 2.718
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex2, connectedPlantLoc, DataPlant.CriteriaType.Temperature, criteriaValue2)
    assert connectedLoopSide.SimLoopSideNeeded
    criteriaValue3 = 2.718
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex3, connectedPlantLoc, DataPlant.CriteriaType.HeatTransferRate, criteriaValue3)
    assert connectedLoopSide.SimLoopSideNeeded
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex1, connectedPlantLoc, DataPlant.CriteriaType.MassFlowRate, criteriaValue1)
    assert not connectedLoopSide.SimLoopSideNeeded
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex2, connectedPlantLoc, DataPlant.CriteriaType.Temperature, criteriaValue2)
    assert not connectedLoopSide.SimLoopSideNeeded
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex3, connectedPlantLoc, DataPlant.CriteriaType.HeatTransferRate, criteriaValue3)
    assert not connectedLoopSide.SimLoopSideNeeded
    criteriaValue1 += DataPlant.CriteriaDelta_MassFlowRate / 2.0
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex1, connectedPlantLoc, DataPlant.CriteriaType.MassFlowRate, criteriaValue1)
    assert not connectedLoopSide.SimLoopSideNeeded
    criteriaValue2 += DataPlant.CriteriaDelta_Temperature / 2.0
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex2, connectedPlantLoc, DataPlant.CriteriaType.Temperature, criteriaValue2)
    assert not connectedLoopSide.SimLoopSideNeeded
    criteriaValue3 += DataPlant.CriteriaDelta_HeatTransferRate / 2.0
    connectedLoopSide.SimLoopSideNeeded = False
    PlantUtilities.PullCompInterconnectTrigger(
        state, plantLoc, criteriaCheckIndex3, connectedPlantLoc, DataPlant.CriteriaType.HeatTransferRate, criteriaValue3)
    assert not connectedLoopSide.SimLoopSideNeeded

@test
def TestIntegerIsWithinTwoValues() raises:
    assert PlantUtilities.IntegerIsWithinTwoValues(1, 0, 2)
    assert PlantUtilities.IntegerIsWithinTwoValues(0, -1, 1)
    assert not PlantUtilities.IntegerIsWithinTwoValues(0, 1, 2)
    assert not PlantUtilities.IntegerIsWithinTwoValues(-1, 0, 1)
    assert not PlantUtilities.IntegerIsWithinTwoValues(1, 2, 0)

@test
def TestCheckPlantConvergence() raises:
    state.dataPlnt.PlantLoop.resize(1)
    state.dataLoopNodes.Node.resize(2)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumOut = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].NodeNumIn = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].NodeNumOut = 1
    var inNode = state.dataLoopNodes.Node[0]
    var outNode = state.dataLoopNodes.Node[1]
    const roomTemp = 25.0
    const nonZeroFlow = 3.14
    assert 5 == state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].InletNode.TemperatureHistory.size()
    assert 5 == state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].OutletNode.TemperatureHistory.size()
    assert 5 == state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].InletNode.MassFlowRateHistory.size()
    assert 5 == state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].OutletNode.MassFlowRateHistory.size()
    assert abs(0.0 - sum(state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].InletNode.TemperatureHistory)) < 0.001
    assert abs(0.0 - sum(state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].OutletNode.TemperatureHistory)) < 0.001
    assert abs(0.0 - sum(state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].InletNode.MassFlowRateHistory)) < 0.001
    assert abs(0.0 - sum(state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].OutletNode.MassFlowRateHistory)) < 0.001
    assert not state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(True)
    assert state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    inNode.Temp = roomTemp
    PlantUtilities.LogPlantConvergencePoints(state, False)
    assert not state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    for i in range(1, 5):
        PlantUtilities.LogPlantConvergencePoints(state, False)
    assert state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    outNode.Temp = roomTemp
    PlantUtilities.LogPlantConvergencePoints(state, False)
    assert not state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    for i in range(1, 5):
        PlantUtilities.LogPlantConvergencePoints(state, False)
    assert state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    inNode.MassFlowRate = nonZeroFlow
    PlantUtilities.LogPlantConvergencePoints(state, False)
    assert not state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    for i in range(1, 5):
        PlantUtilities.LogPlantConvergencePoints(state, False)
    assert state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    outNode.MassFlowRate = nonZeroFlow
    PlantUtilities.LogPlantConvergencePoints(state, False)
    assert not state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)
    for i in range(1, 5):
        PlantUtilities.LogPlantConvergencePoints(state, False)
    assert state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].CheckPlantConvergence(False)

@test
def TestScanPlantLoopsErrorFlagReturnType() raises:
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.resize(1)
    state.dataLoopNodes.Node.resize(2)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumOut = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.resize(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.resize(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = "comp_name"
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Boiler_Simple
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 0  # just skip the supply side search
    var plantLoc = PlantLocation(0, DataPlant.LoopSideLocation.Invalid, 0, 0)
    var errorFlag = False
    PlantUtilities.ScanPlantLoopsForObject(state, "comp_name", DataPlant.PlantEquipmentType.Boiler_Simple, plantLoc, errorFlag)
    assert 1 == plantLoc.loopNum
    assert DataPlant.LoopSideLocation.Demand == plantLoc.loopSideNum
    assert 1 == plantLoc.branchNum
    assert 1 == plantLoc.compNum
    assert &state.dataPlnt.PlantLoop[plantLoc.loopNum] == plantLoc.loop
    assert &plantLoc.loop.LoopSide(plantLoc.loopSideNum) == plantLoc.side
    assert &plantLoc.side.Branch(plantLoc.branchNum) == plantLoc.branch
    assert &plantLoc.branch.Comp(plantLoc.compNum) == plantLoc.comp
    assert not errorFlag
    PlantUtilities.ScanPlantLoopsForObject(state, "comp_name_not_here", DataPlant.PlantEquipmentType.Boiler_Simple, plantLoc, errorFlag)
    assert errorFlag