from Data.EnergyPlusData import EnergyPlusData
from DataAirSystems import AirSystemsData, DataAirSystems
from Fans import Fans
@value
struct AirLoopCompData:
    var TypeOf: String
    var Name: String
    var CompType_Num: SimAirServingZones.CompType = SimAirServingZones.CompType.Invalid
    var CompIndex: Int = 0
    var compPointer: HVACSystemData? = None
    var FlowCtrl: Int = 0
    var ON: Bool = True
    var Parent: Bool = False
    var NodeNameIn: String
    var NodeNameOut: String
    var NodeNumIn: Int = 0
    var NodeNumOut: Int = 0
    var MeteredVarsFound: Bool = False
    var NumMeteredVars: Int = 0
    var NumSubComps: Int = 0
    var EnergyTransComp: Int = 0
    var Capacity: Float64 = 0.0
    var OpMode: Int = 0
    var TotPlantSupplyElec: Float64 = 0.0
    var PlantSupplyElecEff: Float64 = 0.0
    var PeakPlantSupplyElecEff: Float64 = 0.0
    var TotPlantSupplyGas: Float64 = 0.0
    var PlantSupplyGasEff: Float64 = 0.0
    var PeakPlantSupplyGasEff: Float64 = 0.0
    var TotPlantSupplyPurch: Float64 = 0.0
    var PlantSupplyPurchEff: Float64 = 0.0
    var PeakPlantSupplyPurchEff: Float64 = 0.0
    var TotPlantSupplyOther: Float64 = 0.0
    var PlantSupplyOtherEff: Float64 = 0.0
    var PeakPlantSupplyOtherEff: Float64 = 0.0
    var AirSysToPlantPtr: Int = 0
    var MeteredVar: Array1D[MeterData]
    var SubComp: Array1D[SubcomponentData]
@value
struct AirLoopBranchData:
    var Name: String
    var ControlType: String
    var TotalComponents: Int = 0
    var FirstCompIndex: Array1D_int
    var LastCompIndex: Array1D_int
    var NodeNumIn: Int = 0
    var NodeNumOut: Int = 0
    var DuctType: HVAC.AirDuctType = HVAC.AirDuctType.Invalid
    var Comp: Array1D[AirLoopCompData]
    var TotalNodes: Int = 0
    var NodeNum: Array1D_int
@value
struct AirLoopSplitterData:
    var Exists: Bool = False
    var Name: String
    var NodeNumIn: Int = 0
    var BranchNumIn: Int = 0
    var NodeNameIn: String
    var TotalOutletNodes: Int = 0
    var NodeNumOut: Array1D_int
    var BranchNumOut: Array1D_int
    var NodeNameOut: Array1D_string
@value
struct AirLoopMixerData:
    var Exists: Bool = False
    var Name: String
    var NodeNumOut: Int = 0
    var BranchNumOut: Int = 0
    var NodeNameOut: String
    var TotalInletNodes: Int = 0
    var NodeNumIn: Array1D_int
    var BranchNumIn: Array1D_int
    var NodeNameIn: Array1D_string
@value
struct DefinePrimaryAirSystem:
    var Name: String
    var DesignVolFlowRate: Float64
    var DesignReturnFlowFraction: Float64 = 1.0
    var NumControllers: Int = 0
    var ControllerName: Array1D_string
    var ControllerType: Array1D_string
    var ControllerIndex: Array1D_int
    var CanBeLockedOutByEcono: Array1D_bool
    var NumBranches: Int = 0
    var Branch: Array1D[AirLoopBranchData]
    var Splitter: AirLoopSplitterData
    var Mixer: AirLoopMixerData
    var ControlConverged: Array1D_bool
    var NumOutletBranches: Int = 0
    var OutletBranchNum: StaticArray[Int, 3] = StaticArray[Int, 3](0, 0, 0)
    var NumInletBranches: Int = 0
    var InletBranchNum: StaticArray[Int, 3] = StaticArray[Int, 3](0, 0, 0)
    var CentralHeatCoilExists: Bool = True
    var CentralCoolCoilExists: Bool = True
    var OASysExists: Bool = False
    var isAllOA: Bool = False
    var OASysInletNodeNum: Int = 0
    var OASysOutletNodeNum: Int = 0
    var OAMixOAInNodeNum: Int = 0
    var RABExists: Bool = False
    var RABMixInNode: Int = 0
    var SupMixInNode: Int = 0
    var MixOutNode: Int = 0
    var RABSplitOutNode: Int = 0
    var OtherSplitOutNode: Int = 0
    var NumOACoolCoils: Int = 0
    var NumOAHeatCoils: Int = 0
    var NumOAHXs: Int = 0
    var SizeAirloopCoil: Bool = True
    var supFanType: HVAC.FanType = HVAC.FanType.Invalid
    var supFanNum: Int = 0
    var supFanPlace: HVAC.FanPlace = HVAC.FanPlace.Invalid
    var retFanType: HVAC.FanType = HVAC.FanType.Invalid
    var retFanNum: Int = 0
    var FanDesCoolLoad: Float64 = 0.0
    var EconomizerStagingCheckFlag: Bool = False
@value
struct ConnectionPoint:
    var LoopType: Int = 0
    var LoopNum: Int = 0
    var BranchNum: Int = 0
    var CompNum: Int = 0
@value
struct ConnectZoneComp:
    var ZoneEqListNum: Int = 0
    var ZoneEqCompNum: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
@value
struct ConnectZoneSubComp:
    var ZoneEqListNum: Int = 0
    var ZoneEqCompNum: Int = 0
    var ZoneEqSubCompNum: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
@value
struct ConnectZoneSubSubComp:
    var ZoneEqListNum: Int = 0
    var ZoneEqCompNum: Int = 0
    var ZoneEqSubCompNum: Int = 0
    var ZoneEqSubSubCompNum: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
@value
struct ConnectAirSysComp:
    var AirLoopNum: Int = 0
    var AirLoopBranch: Int = 0
    var AirLoopComp: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
@value
struct ConnectAirSysSubComp:
    var AirLoopNum: Int = 0
    var AirLoopBranch: Int = 0
    var AirLoopComp: Int = 0
    var AirLoopSubComp: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
@value
struct ConnectAirSysSubSubComp:
    var AirLoopNum: Int = 0
    var AirLoopBranch: Int = 0
    var AirLoopComp: Int = 0
    var AirLoopSubComp: Int = 0
    var AirLoopSubSubComp: Int = 0
    var PlantLoopType: Int = 0
    var PlantLoopNum: Int = 0
    var PlantLoopBranch: Int = 0
    var PlantLoopComp: Int = 0
    var FirstDemandSidePtr: Int = 0
    var LastDemandSidePtr: Int = 0
def calcFanDesignHeatGain(state: EnergyPlusData, dataFanIndex: Int, desVolFlow: Float64) -> Float64:
    if dataFanIndex <= 0 or desVolFlow == 0.0:
        return 0.0
    return state.dataFans.fans[dataFanIndex].getDesignHeatGain(state, desVolFlow)
struct AirSystemsData(BaseGlobalStruct):
    var PrimaryAirSystems: EPVector[DefinePrimaryAirSystem]
    var DemandSideConnect: Array1D[ConnectionPoint]
    var ZoneCompToPlant: Array1D[ConnectZoneComp]
    var ZoneSubCompToPlant: Array1D[ConnectZoneSubComp]
    var ZoneSubSubCompToPlant: Array1D[ConnectZoneSubSubComp]
    var AirSysCompToPlant: Array1D[ConnectAirSysComp]
    var AirSysSubCompToPlant: Array1D[ConnectAirSysSubComp]
    var AirSysSubSubCompToPlant: Array1D[ConnectAirSysSubSubComp]
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = AirSystemsData()