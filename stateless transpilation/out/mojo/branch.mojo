# EXTERNAL DEPS (to wire in glue):
# - ControlType: enum from DataBranchAirLoopPlant with Invalid, SeriesActive
# - PressureCurveType: enum from DataBranchAirLoopPlant with Invalid
# - CompData: struct from Plant/Component.hh with NodeNumIn and MyLoad
# - EnergyPlusData: state object with dataLoopNodes.Node access
# - PlantUtilities.BoundValueToNodeMinMaxAvail: function

from math import max, abs

struct ControlType:
    alias Invalid = 0
    alias SeriesActive = 1

struct PressureCurveType:
    alias Invalid = 0

@value
struct CompData:
    var NodeNumIn: Int
    var MyLoad: Float64
    
    fn __init__(inout self):
        self.NodeNumIn = 0
        self.MyLoad = 0.0

struct BranchData:
    var Name: String
    var controlType: Int
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
    var Comp: List[CompData]
    var HasPressureComponents: Bool
    var PressureDrop: Float64
    var PressureCurveType: Int
    var PressureCurveIndex: Int
    var PressureEffectiveK: Float64
    var disableOverrideForCSBranchPumping: Bool
    var lastComponentSimulated: Int
    
    fn __init__(inout self):
        self.Name = ""
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
        self.Comp = List[CompData]()
        self.HasPressureComponents = False
        self.PressureDrop = 0.0
        self.PressureCurveType = PressureCurveType.Invalid
        self.PressureCurveIndex = 0
        self.PressureEffectiveK = 0.0
        self.disableOverrideForCSBranchPumping = False
        self.lastComponentSimulated = 0
    
    fn max_abs_Comp_MyLoad(self) -> Float64:
        var load = 0.0
        for i in range(len(self.Comp)):
            load = max(load, abs(self.Comp[i].MyLoad))
        return load
    
    fn DetermineBranchFlowRequest(inout self, state: EnergyPlusData) -> Float64:
        let BranchInletNodeNum = self.NodeNumIn
        let BranchOutletNodeNum = self.NodeNumOut
        var OverallFlowRequest = 0.0
        
        if self.controlType != ControlType.SeriesActive:
            OverallFlowRequest = state.dataLoopNodes.Node(BranchInletNodeNum).MassFlowRateRequest
        else:
            for CompCounter in range(1, self.TotalComponents + 1):
                let CompInletNode = self.Comp[CompCounter - 1].NodeNumIn
                OverallFlowRequest = max(OverallFlowRequest, state.dataLoopNodes.Node(CompInletNode).MassFlowRateRequest)
        
        OverallFlowRequest = PlantUtilities.BoundValueToNodeMinMaxAvail(state, OverallFlowRequest, BranchOutletNodeNum)
        return OverallFlowRequest

struct EnergyPlusData:
    pass

struct PlantUtilities:
    @staticmethod
    fn BoundValueToNodeMinMaxAvail(state: EnergyPlusData, value: Float64, node_number: Int) -> Float64:
        ...
