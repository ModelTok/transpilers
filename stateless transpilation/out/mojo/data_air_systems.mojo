# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state object (from EnergyPlus main module)
# SimAirServingZones.CompType - enum
# HVACSystemData - struct/type
# HVAC.AirDuctType - enum
# HVAC.FanType - enum
# HVAC.FanPlace - enum
# DataPlant.SubcomponentData - struct
# OutputProcessor.MeterData - struct
# BaseGlobalStruct - base struct

from collections import InlineArray


@value
struct CompType:
    var value: Int32 = -1
    
    fn __eq__(self, other: CompType) -> Bool:
        return self.value == other.value


@value
struct AirDuctType:
    var value: Int32 = -1
    
    fn __eq__(self, other: AirDuctType) -> Bool:
        return self.value == other.value


@value
struct FanType:
    var value: Int32 = -1
    
    fn __eq__(self, other: FanType) -> Bool:
        return self.value == other.value


@value
struct FanPlace:
    var value: Int32 = -1
    
    fn __eq__(self, other: FanPlace) -> Bool:
        return self.value == other.value


struct SubcomponentData:
    pass


struct MeterData:
    pass


struct HVACSystemData:
    pass


struct BaseGlobalStruct:
    pass


@value
struct AirLoopCompData:
    var TypeOf: String
    var Name: String
    var CompType_Num: CompType
    var CompIndex: Int32
    var compPointer: UnsafePointer[HVACSystemData]
    var FlowCtrl: Int32
    var ON: Bool
    var Parent: Bool
    var NodeNameIn: String
    var NodeNameOut: String
    var NodeNumIn: Int32
    var NodeNumOut: Int32
    var MeteredVarsFound: Bool
    var NumMeteredVars: Int32
    var NumSubComps: Int32
    var EnergyTransComp: Int32
    var Capacity: Float64
    var OpMode: Int32
    var TotPlantSupplyElec: Float64
    var PlantSupplyElecEff: Float64
    var PeakPlantSupplyElecEff: Float64
    var TotPlantSupplyGas: Float64
    var PlantSupplyGasEff: Float64
    var PeakPlantSupplyGasEff: Float64
    var TotPlantSupplyPurch: Float64
    var PlantSupplyPurchEff: Float64
    var PeakPlantSupplyPurchEff: Float64
    var TotPlantSupplyOther: Float64
    var PlantSupplyOtherEff: Float64
    var PeakPlantSupplyOtherEff: Float64
    var AirSysToPlantPtr: Int32
    var MeteredVar: DynamicVector[MeterData]
    var SubComp: DynamicVector[SubcomponentData]

    fn __init__(inout self) -> None:
        self.TypeOf = String()
        self.Name = String()
        self.CompType_Num = CompType()
        self.CompIndex = 0
        self.compPointer = UnsafePointer[HVACSystemData]()
        self.FlowCtrl = 0
        self.ON = True
        self.Parent = False
        self.NodeNameIn = String()
        self.NodeNameOut = String()
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.MeteredVarsFound = False
        self.NumMeteredVars = 0
        self.NumSubComps = 0
        self.EnergyTransComp = 0
        self.Capacity = 0.0
        self.OpMode = 0
        self.TotPlantSupplyElec = 0.0
        self.PlantSupplyElecEff = 0.0
        self.PeakPlantSupplyElecEff = 0.0
        self.TotPlantSupplyGas = 0.0
        self.PlantSupplyGasEff = 0.0
        self.PeakPlantSupplyGasEff = 0.0
        self.TotPlantSupplyPurch = 0.0
        self.PlantSupplyPurchEff = 0.0
        self.PeakPlantSupplyPurchEff = 0.0
        self.TotPlantSupplyOther = 0.0
        self.PlantSupplyOtherEff = 0.0
        self.PeakPlantSupplyOtherEff = 0.0
        self.AirSysToPlantPtr = 0
        self.MeteredVar = DynamicVector[MeterData]()
        self.SubComp = DynamicVector[SubcomponentData]()


@value
struct AirLoopBranchData:
    var Name: String
    var ControlType: String
    var TotalComponents: Int32
    var FirstCompIndex: DynamicVector[Int32]
    var LastCompIndex: DynamicVector[Int32]
    var NodeNumIn: Int32
    var NodeNumOut: Int32
    var DuctType: AirDuctType
    var Comp: DynamicVector[AirLoopCompData]
    var TotalNodes: Int32
    var NodeNum: DynamicVector[Int32]

    fn __init__(inout self) -> None:
        self.Name = String()
        self.ControlType = String()
        self.TotalComponents = 0
        self.FirstCompIndex = DynamicVector[Int32]()
        self.LastCompIndex = DynamicVector[Int32]()
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.DuctType = AirDuctType()
        self.Comp = DynamicVector[AirLoopCompData]()
        self.TotalNodes = 0
        self.NodeNum = DynamicVector[Int32]()


@value
struct AirLoopSplitterData:
    var Exists: Bool
    var Name: String
    var NodeNumIn: Int32
    var BranchNumIn: Int32
    var NodeNameIn: String
    var TotalOutletNodes: Int32
    var NodeNumOut: DynamicVector[Int32]
    var BranchNumOut: DynamicVector[Int32]
    var NodeNameOut: DynamicVector[String]

    fn __init__(inout self) -> None:
        self.Exists = False
        self.Name = String()
        self.NodeNumIn = 0
        self.BranchNumIn = 0
        self.NodeNameIn = String()
        self.TotalOutletNodes = 0
        self.NodeNumOut = DynamicVector[Int32]()
        self.BranchNumOut = DynamicVector[Int32]()
        self.NodeNameOut = DynamicVector[String]()


@value
struct AirLoopMixerData:
    var Exists: Bool
    var Name: String
    var NodeNumOut: Int32
    var BranchNumOut: Int32
    var NodeNameOut: String
    var TotalInletNodes: Int32
    var NodeNumIn: DynamicVector[Int32]
    var BranchNumIn: DynamicVector[Int32]
    var NodeNameIn: DynamicVector[String]

    fn __init__(inout self) -> None:
        self.Exists = False
        self.Name = String()
        self.NodeNumOut = 0
        self.BranchNumOut = 0
        self.NodeNameOut = String()
        self.TotalInletNodes = 0
        self.NodeNumIn = DynamicVector[Int32]()
        self.BranchNumIn = DynamicVector[Int32]()
        self.NodeNameIn = DynamicVector[String]()


@value
struct DefinePrimaryAirSystem:
    var Name: String
    var DesignVolFlowRate: Float64
    var DesignReturnFlowFraction: Float64
    var NumControllers: Int32
    var ControllerName: DynamicVector[String]
    var ControllerType: DynamicVector[String]
    var ControllerIndex: DynamicVector[Int32]
    var CanBeLockedOutByEcono: DynamicVector[Bool]
    var NumBranches: Int32
    var Branch: DynamicVector[AirLoopBranchData]
    var Splitter: AirLoopSplitterData
    var Mixer: AirLoopMixerData
    var ControlConverged: DynamicVector[Bool]
    var NumOutletBranches: Int32
    var OutletBranchNum: InlineArray[Int32, 3]
    var NumInletBranches: Int32
    var InletBranchNum: InlineArray[Int32, 3]
    var CentralHeatCoilExists: Bool
    var CentralCoolCoilExists: Bool
    var OASysExists: Bool
    var isAllOA: Bool
    var OASysInletNodeNum: Int32
    var OASysOutletNodeNum: Int32
    var OAMixOAInNodeNum: Int32
    var RABExists: Bool
    var RABMixInNode: Int32
    var SupMixInNode: Int32
    var MixOutNode: Int32
    var RABSplitOutNode: Int32
    var OtherSplitOutNode: Int32
    var NumOACoolCoils: Int32
    var NumOAHeatCoils: Int32
    var NumOAHXs: Int32
    var SizeAirloopCoil: Bool
    var supFanType: FanType
    var supFanNum: Int32
    var supFanPlace: FanPlace
    var retFanType: FanType
    var retFanNum: Int32
    var FanDesCoolLoad: Float64
    var EconomizerStagingCheckFlag: Bool

    fn __init__(inout self) -> None:
        self.Name = String()
        self.DesignVolFlowRate = 0.0
        self.DesignReturnFlowFraction = 1.0
        self.NumControllers = 0
        self.ControllerName = DynamicVector[String]()
        self.ControllerType = DynamicVector[String]()
        self.ControllerIndex = DynamicVector[Int32]()
        self.CanBeLockedOutByEcono = DynamicVector[Bool]()
        self.NumBranches = 0
        self.Branch = DynamicVector[AirLoopBranchData]()
        self.Splitter = AirLoopSplitterData()
        self.Mixer = AirLoopMixerData()
        self.ControlConverged = DynamicVector[Bool]()
        self.NumOutletBranches = 0
        self.OutletBranchNum = InlineArray[Int32, 3](fill=0)
        self.NumInletBranches = 0
        self.InletBranchNum = InlineArray[Int32, 3](fill=0)
        self.CentralHeatCoilExists = True
        self.CentralCoolCoilExists = True
        self.OASysExists = False
        self.isAllOA = False
        self.OASysInletNodeNum = 0
        self.OASysOutletNodeNum = 0
        self.OAMixOAInNodeNum = 0
        self.RABExists = False
        self.RABMixInNode = 0
        self.SupMixInNode = 0
        self.MixOutNode = 0
        self.RABSplitOutNode = 0
        self.OtherSplitOutNode = 0
        self.NumOACoolCoils = 0
        self.NumOAHeatCoils = 0
        self.NumOAHXs = 0
        self.SizeAirloopCoil = True
        self.supFanType = FanType()
        self.supFanNum = 0
        self.supFanPlace = FanPlace()
        self.retFanType = FanType()
        self.retFanNum = 0
        self.FanDesCoolLoad = 0.0
        self.EconomizerStagingCheckFlag = False


@value
struct ConnectionPoint:
    var LoopType: Int32
    var LoopNum: Int32
    var BranchNum: Int32
    var CompNum: Int32

    fn __init__(inout self) -> None:
        self.LoopType = 0
        self.LoopNum = 0
        self.BranchNum = 0
        self.CompNum = 0


@value
struct ConnectZoneComp:
    var ZoneEqListNum: Int32
    var ZoneEqCompNum: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.ZoneEqListNum = 0
        self.ZoneEqCompNum = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


@value
struct ConnectZoneSubComp:
    var ZoneEqListNum: Int32
    var ZoneEqCompNum: Int32
    var ZoneEqSubCompNum: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.ZoneEqListNum = 0
        self.ZoneEqCompNum = 0
        self.ZoneEqSubCompNum = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


@value
struct ConnectZoneSubSubComp:
    var ZoneEqListNum: Int32
    var ZoneEqCompNum: Int32
    var ZoneEqSubCompNum: Int32
    var ZoneEqSubSubCompNum: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.ZoneEqListNum = 0
        self.ZoneEqCompNum = 0
        self.ZoneEqSubCompNum = 0
        self.ZoneEqSubSubCompNum = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


@value
struct ConnectAirSysComp:
    var AirLoopNum: Int32
    var AirLoopBranch: Int32
    var AirLoopComp: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.AirLoopNum = 0
        self.AirLoopBranch = 0
        self.AirLoopComp = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


@value
struct ConnectAirSysSubComp:
    var AirLoopNum: Int32
    var AirLoopBranch: Int32
    var AirLoopComp: Int32
    var AirLoopSubComp: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.AirLoopNum = 0
        self.AirLoopBranch = 0
        self.AirLoopComp = 0
        self.AirLoopSubComp = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


@value
struct ConnectAirSysSubSubComp:
    var AirLoopNum: Int32
    var AirLoopBranch: Int32
    var AirLoopComp: Int32
    var AirLoopSubComp: Int32
    var AirLoopSubSubComp: Int32
    var PlantLoopType: Int32
    var PlantLoopNum: Int32
    var PlantLoopBranch: Int32
    var PlantLoopComp: Int32
    var FirstDemandSidePtr: Int32
    var LastDemandSidePtr: Int32

    fn __init__(inout self) -> None:
        self.AirLoopNum = 0
        self.AirLoopBranch = 0
        self.AirLoopComp = 0
        self.AirLoopSubComp = 0
        self.AirLoopSubSubComp = 0
        self.PlantLoopType = 0
        self.PlantLoopNum = 0
        self.PlantLoopBranch = 0
        self.PlantLoopComp = 0
        self.FirstDemandSidePtr = 0
        self.LastDemandSidePtr = 0


fn calc_fan_design_heat_gain(state: UnsafePointer[BaseGlobalStruct], data_fan_index: Int32, des_vol_flow: Float64) -> Float64:
    if data_fan_index <= 0 or des_vol_flow == 0.0:
        return 0.0
    
    return state.pointee.dataFans.fans[Int(data_fan_index - 1)].getDesignHeatGain(state, des_vol_flow)


@value
struct AirSystemsData(BaseGlobalStruct):
    var PrimaryAirSystems: DynamicVector[DefinePrimaryAirSystem]
    var DemandSideConnect: DynamicVector[ConnectionPoint]
    var ZoneCompToPlant: DynamicVector[ConnectZoneComp]
    var ZoneSubCompToPlant: DynamicVector[ConnectZoneSubComp]
    var ZoneSubSubCompToPlant: DynamicVector[ConnectZoneSubSubComp]
    var AirSysCompToPlant: DynamicVector[ConnectAirSysComp]
    var AirSysSubCompToPlant: DynamicVector[ConnectAirSysSubComp]
    var AirSysSubSubCompToPlant: DynamicVector[ConnectAirSysSubSubComp]

    fn __init__(inout self) -> None:
        self.PrimaryAirSystems = DynamicVector[DefinePrimaryAirSystem]()
        self.DemandSideConnect = DynamicVector[ConnectionPoint]()
        self.ZoneCompToPlant = DynamicVector[ConnectZoneComp]()
        self.ZoneSubCompToPlant = DynamicVector[ConnectZoneSubComp]()
        self.ZoneSubSubCompToPlant = DynamicVector[ConnectZoneSubSubComp]()
        self.AirSysCompToPlant = DynamicVector[ConnectAirSysComp]()
        self.AirSysSubCompToPlant = DynamicVector[ConnectAirSysSubComp]()
        self.AirSysSubSubCompToPlant = DynamicVector[ConnectAirSysSubSubComp]()

    fn init_constant_state(inout self, state: UnsafePointer[BaseGlobalStruct]) -> None:
        pass

    fn init_state(inout self, state: UnsafePointer[BaseGlobalStruct]) -> None:
        pass

    fn clear_state(inout self) -> None:
        self = AirSystemsData()
