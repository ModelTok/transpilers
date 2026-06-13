# EXTERNAL DEPS (to wire in glue):
# - ControlType: enum from DataBranchAirLoopPlant with Invalid, SeriesActive
# - PressureCurveType: enum from DataBranchAirLoopPlant with Invalid
# - CompData: struct from Plant/Component.hh with NodeNumIn and MyLoad
# - EnergyPlusData: state object with dataLoopNodes.Node access
# - PlantUtilities.BoundValueToNodeMinMaxAvail: function

from dataclasses import dataclass, field
from typing import List, Any

class ControlType:
    Invalid = 0
    SeriesActive = 1

class PressureCurveType:
    Invalid = 0

@dataclass
class CompData:
    NodeNumIn: int = 0
    MyLoad: float = 0.0

class PlantUtilities:
    @staticmethod
    def BoundValueToNodeMinMaxAvail(state: Any, value: float, node_number: int) -> float:
        ...

@dataclass
class BranchData:
    Name: str = ""
    controlType: int = ControlType.Invalid
    RequestedMassFlow: float = 0.0
    HasConstantSpeedBranchPump: bool = False
    ConstantSpeedBranchMassFlow: float = 0.0
    BranchLevel: int = 0
    FlowErrCount: int = 0
    FlowErrIndex: int = 0
    TotalComponents: int = 0
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    IsBypass: bool = False
    PumpIndex: int = 0
    PumpSizFac: float = 1.0
    EMSCtrlOverrideOn: bool = False
    EMSCtrlOverrideValue: float = 0.0
    Comp: List[CompData] = field(default_factory=list)
    HasPressureComponents: bool = False
    PressureDrop: float = 0.0
    PressureCurveType: int = PressureCurveType.Invalid
    PressureCurveIndex: int = 0
    PressureEffectiveK: float = 0.0
    disableOverrideForCSBranchPumping: bool = False
    lastComponentSimulated: int = 0

    def max_abs_Comp_MyLoad(self) -> float:
        load = 0.0
        for comp in self.Comp:
            load = max(load, abs(comp.MyLoad))
        return load

    def DetermineBranchFlowRequest(self, state: Any) -> float:
        BranchInletNodeNum = self.NodeNumIn
        BranchOutletNodeNum = self.NodeNumOut
        OverallFlowRequest = 0.0

        if self.controlType != ControlType.SeriesActive:
            OverallFlowRequest = state.dataLoopNodes.Node(BranchInletNodeNum).MassFlowRateRequest
        else:
            for CompCounter in range(1, self.TotalComponents + 1):
                CompInletNode = self.Comp[CompCounter - 1].NodeNumIn
                OverallFlowRequest = max(OverallFlowRequest, state.dataLoopNodes.Node(CompInletNode).MassFlowRateRequest)

        OverallFlowRequest = PlantUtilities.BoundValueToNodeMinMaxAvail(state, OverallFlowRequest, BranchOutletNodeNum)
        return OverallFlowRequest
