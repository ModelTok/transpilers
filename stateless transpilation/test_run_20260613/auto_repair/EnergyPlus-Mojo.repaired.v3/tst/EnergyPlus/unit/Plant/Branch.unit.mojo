from testing import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.Plant.Branch import BranchData
from EnergyPlus.Plant.Component import Component
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture

@fixture
def EnergyPlusFixture():
    return EnergyPlusFixture()

def test_Plant_Topology_Branch_MaxAbsLoad():
    b = EnergyPlus.DataPlant.BranchData()
    b.Comp.allocate(3)
    b.Comp[0].MyLoad = 20000
    b.Comp[1].MyLoad = 21000
    b.Comp[2].MyLoad = 22000
    maxLoad = b.max_abs_Comp_MyLoad()
    assert abs(22000 - maxLoad) < 0.001
    b.Comp[0].MyLoad = 22000
    b.Comp[1].MyLoad = 21000
    b.Comp[2].MyLoad = 20000
    maxLoad = b.max_abs_Comp_MyLoad()
    assert abs(22000 - maxLoad) < 0.001
    b.Comp[0].MyLoad = 0
    b.Comp[1].MyLoad = -21000
    b.Comp[2].MyLoad = 22000
    maxLoad = b.max_abs_Comp_MyLoad()
    assert abs(22000 - maxLoad) < 0.001
    b.Comp[0].MyLoad = 0
    b.Comp[1].MyLoad = 0
    b.Comp[2].MyLoad = -22000
    maxLoad = b.max_abs_Comp_MyLoad()
    assert abs(22000 - maxLoad) < 0.001
    b.Comp[0].MyLoad = 0
    b.Comp[1].MyLoad = 21000
    b.Comp[2].MyLoad = -22000
    maxLoad = b.max_abs_Comp_MyLoad()
    assert abs(22000 - maxLoad) < 0.001

def test_TestDetermineBranchFlowRequest():
    b = DataPlant.BranchData()
    b.NodeNumIn = 1
    b.NodeNumOut = 3
    state.dataLoopNodes.Node.allocate(3)
    nodeIn = state.dataLoopNodes.Node(1)
    nodeMiddle = state.dataLoopNodes.Node(2)
    nodeOut = state.dataLoopNodes.Node(3)
    b.TotalComponents = 2
    b.Comp.allocate(2)
    b.Comp(1).NodeNumIn = 1
    b.Comp(2).NodeNumIn = 2
    nodeIn.MassFlowRateRequest = 1.0
    nodeIn.MassFlowRateMaxAvail = 5.0
    nodeMiddle.MassFlowRateRequest = 2.0
    nodeMiddle.MassFlowRateMaxAvail = 5.0
    nodeOut.MassFlowRateRequest = 3.0
    nodeOut.MassFlowRateMaxAvail = 5.0
    b.controlType = DataBranchAirLoopPlant.ControlType.Active
    flowRequest = b.DetermineBranchFlowRequest(state)
    assert abs(1.0 - flowRequest) < 0.001
    b.controlType = DataBranchAirLoopPlant.ControlType.SeriesActive
    flowRequest = b.DetermineBranchFlowRequest(state)
    assert abs(2.0 - flowRequest) < 0.001