from DataBranchAirLoopPlant import ControlType, PressureCurveType
from Component import CompData
from DataLoopNode import Node
from PlantUtilities import BoundValueToNodeMinMaxAvail
from EnergyPlusData import EnergyPlusData

struct BranchData:
    var Name: String
    var controlType: ControlType
    var RequestedMassFlow: Float64
    var HasConstantSpeedBranchPump: Bool
    var ConstantSpeedBranchMassFlow: Float64
    var BranchLevel: Int
    var FlowErrCount: Int
    var FlowErrIndex: Int
    var TotalComponents: Int
    var NodeNumIn: Int
    var NodeNumOut: Int
    var IsBypass: Bool
    var PumpIndex: Int
    var PumpSizFac: Float64
    var EMSCtrlOverrideOn: Bool
    var EMSCtrlOverrideValue: Float64
    var Comp: DynamicVector[CompData]
    var HasPressureComponents: Bool
    var PressureDrop: Float64
    var PressureCurveType: PressureCurveType
    var PressureCurveIndex: Int
    var PressureEffectiveK: Float64
    var disableOverrideForCSBranchPumping: Bool
    var lastComponentSimulated: Int

    def __init__(inout self):
        self.Name = String("")
        self.controlType = ControlType.Invalid
        self.RequestedMassFlow = 0.0
        self.HasConstantSpeedBranchPump = False
        self.ConstantSpeedBranchMassFlow = 0.0
        self.BranchLevel = 0
        self.FlowErrCount = 0
        self.FlowErrIndex = 0
        self.TotalComponents = 0
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.IsBypass = False
        self.PumpIndex = 0
        self.PumpSizFac = 1.0
        self.EMSCtrlOverrideOn = False
        self.EMSCtrlOverrideValue = 0.0
        self.Comp = DynamicVector[CompData]()
        self.HasPressureComponents = False
        self.PressureDrop = 0.0
        self.PressureCurveType = PressureCurveType.Invalid
        self.PressureCurveIndex = 0
        self.PressureEffectiveK = 0.0
        self.disableOverrideForCSBranchPumping = False
        self.lastComponentSimulated = 0

    def max_abs_Comp_MyLoad(self) -> Float64:
        var load: Float64 = 0.0
        for i in range(0, self.Comp.size):
            load = max(load, abs(self.Comp[i].MyLoad))
        return load

    def DetermineBranchFlowRequest(inout self, state: EnergyPlusData) -> Float64:
        var BranchInletNodeNum: Int = self.NodeNumIn
        var BranchOutletNodeNum: Int = self.NodeNumOut
        var OverallFlowRequest: Float64 = 0.0
        if self.controlType != ControlType.SeriesActive:
            OverallFlowRequest = state.dataLoopNodes.Node[BranchInletNodeNum].MassFlowRateRequest
        else:
            for CompCounter in range(1, self.TotalComponents + 1):
                var CompInletNode: Int = self.Comp[CompCounter - 1].NodeNumIn
                OverallFlowRequest = max(OverallFlowRequest, state.dataLoopNodes.Node[CompInletNode].MassFlowRateRequest)
        OverallFlowRequest = BoundValueToNodeMinMaxAvail(state, OverallFlowRequest, BranchOutletNodeNum)
        return OverallFlowRequest