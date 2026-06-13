"""
HVACUnitaryBypassVAV - Changeover-Bypass VAV System Simulation
Ported from EnergyPlus C++ implementation
Mojo version
"""

from utils.vector import DynamicVector
from collections import InlineArray

# EXTERNAL DEPS (to wire in glue):
# - state.dataHVACUnitaryBypassVAV: HVACUnitaryBypassVAVData instance
# - state.dataFans: fans array access
# - state.dataLoopNodes: Node access and manipulation
# - state.dataDXCoils: DX coil data
# - state.dataVariableSpeedCoils: Variable speed coil data
# - state.dataHeatingCoils: Heating coil data
# - state.dataWaterCoils: Water coil data
# - state.dataSteamCoils: Steam coil data
# - state.dataAirLoop: Air loop configuration
# - state.dataAirSystemsData: Primary air systems
# - state.dataEnvrn: Environment (outdoor conditions)
# - state.dataZoneCtrls: Zone controls
# - state.dataZoneEquip: Zone equipment
# - state.dataSize: Sizing data
# - state.dataInputProcessing: Input processor
# - state.dataGlobal: Global simulation state
# - state.dataSetPointManager: Setpoint managers
# - state.dataZoneEnergyDemand: Zone energy demands
# - state.dataCoilCoolingDX: Cooling DX coil data
# - Util.FindItemInList: Utility to find index by name
# - Util.SameString: Case-insensitive string comparison
# - HVAC.SmallMassFlow, HVAC.SmallTempDiff, HVAC.SmallLoad, HVAC.SmallAirVolFlow: Constants
# - HVAC.FanOp, HVAC.FanType, HVAC.FanPlace, HVAC.CoilType, HVAC.CoilMode, HVAC.CompressorOp: Enums
# - Sched.GetScheduleAlwaysOn, Sched.GetSchedule: Schedule functions
# - Node.GetOnlySingleNode, Node.SetUpCompSets, Node.TestCompSet: Node functions
# - MixedAir.GetOAMixerNodeNumbers, MixedAir.SimOAMixer: OA mixer functions
# - DXCoils.GetDXCoilIndex, DXCoils.SimDXCoil, DXCoils.CalcDoe2DXCoil, DXCoils.SimDXCoilMultiMode: DX coil functions
# - VariableSpeedCoils functions
# - HVACHXAssistedCoolingCoil functions
# - WaterCoils functions
# - SteamCoils functions
# - Fans.GetFanIndex: Fan lookup
# - HeatingCoils functions
# - PlantUtilities functions
# - ZonePlenum, MixerComponent: Zone equipment functions
# - Psychrometrics functions
# - SetPointManager functions
# - General.SolveRoot: Root solver
# - HVACDXHeatPumpSystem functions
# - ShowFatalError, ShowSevereError, ShowWarningError, etc.: Error/warning functions

alias CoolingMode = 1
alias HeatingMode = 2


@value
struct DehumidControl:
    """Dehumidification control modes"""
    alias Invalid = -1
    alias None_ = 0
    alias Multimode = 1
    alias CoolReheat = 2
    alias Num = 3


@value
struct PriorityCtrlMode:
    """Priority control mode (prioritized thermostat signal)"""
    alias Invalid = -1
    alias CoolingPriority = 0
    alias HeatingPriority = 1
    alias ZonePriority = 2
    alias LoadPriority = 3
    alias Num = 4


@value
struct AirFlowCtrlMode:
    """Airflow control for constant fan mode"""
    alias Invalid = -1
    alias UseCompressorOnFlow = 0
    alias UseCompressorOffFlow = 1
    alias Num = 2


@value
struct CBVAVData:
    """Changeover-Bypass VAV Unit Data"""
    var Name: String
    var UnitType: String
    var availSchedName: String
    var availSched: UnsafePointer[NoneType]
    var MaxCoolAirVolFlow: Float64
    var MaxHeatAirVolFlow: Float64
    var MaxNoCoolHeatAirVolFlow: Float64
    var MaxCoolAirMassFlow: Float64
    var MaxHeatAirMassFlow: Float64
    var MaxNoCoolHeatAirMassFlow: Float64
    var CoolOutAirVolFlow: Float64
    var HeatOutAirVolFlow: Float64
    var NoCoolHeatOutAirVolFlow: Float64
    var CoolOutAirMassFlow: Float64
    var HeatOutAirMassFlow: Float64
    var NoCoolHeatOutAirMassFlow: Float64
    var outAirSched: UnsafePointer[NoneType]
    var AirInNode: Int32
    var AirOutNode: Int32
    var CondenserNodeNum: Int32
    var MixerOutsideAirNode: Int32
    var MixerMixedAirNode: Int32
    var MixerReliefAirNode: Int32
    var MixerInletAirNode: Int32
    var SplitterOutletAirNode: Int32
    var PlenumMixerInletAirNode: Int32
    var OAMixType: String
    var OAMixName: String
    var OAMixIndex: Int32
    var FanName: String
    var fanType: Int32
    var fanPlace: Int32
    var FanIndex: Int32
    var fanOpModeSched: UnsafePointer[NoneType]
    var FanVolFlow: Float64
    var HeatingSpeedRatio: Float64
    var CoolingSpeedRatio: Float64
    var NoHeatCoolSpeedRatio: Float64
    var CheckFanFlow: Bool
    var DXCoolCoilName: String
    var coolCoilType: Int32
    var CoolCoilCompIndex: Int32
    var DXCoolCoilIndexNum: Int32
    var DXHeatCoilIndexNum: Int32
    var HeatCoilName: String
    var heatCoilType: Int32
    var HeatCoilIndex: Int32
    var fanOp: Int32
    var CoilControlNode: Int32
    var CoilOutletNode: Int32
    var plantLoc: UnsafePointer[NoneType]
    var HotWaterCoilMaxIterIndex: Int32
    var HotWaterCoilMaxIterIndex2: Int32
    var MaxHeatCoilFluidFlow: Float64
    var DesignHeatingCapacity: Float64
    var DesignSuppHeatingCapacity: Float64
    var MinOATCompressor: Float64
    var MinLATCooling: Float64
    var MaxLATHeating: Float64
    var TotHeatEnergyRate: Float64
    var TotHeatEnergy: Float64
    var TotCoolEnergyRate: Float64
    var TotCoolEnergy: Float64
    var SensHeatEnergyRate: Float64
    var SensHeatEnergy: Float64
    var SensCoolEnergyRate: Float64
    var SensCoolEnergy: Float64
    var LatHeatEnergyRate: Float64
    var LatHeatEnergy: Float64
    var LatCoolEnergyRate: Float64
    var LatCoolEnergy: Float64
    var ElecPower: Float64
    var ElecConsumption: Float64
    var FanPartLoadRatio: Float64
    var CompPartLoadRatio: Float64
    var LastMode: Int32
    var AirFlowControl: Int32
    var CompPartLoadFrac: Float64
    var AirLoopNumber: Int32
    var NumControlledZones: Int32
    var ControlledZoneNum: DynamicVector[Int32]
    var ControlledZoneNodeNum: DynamicVector[Int32]
    var CBVAVBoxOutletNode: DynamicVector[Int32]
    var ZoneSequenceCoolingNum: DynamicVector[Int32]
    var ZoneSequenceHeatingNum: DynamicVector[Int32]
    var PriorityControl: Int32
    var NumZonesCooled: Int32
    var NumZonesHeated: Int32
    var PLRMaxIter: Int32
    var PLRMaxIterIndex: Int32
    var DXCoilInletNode: Int32
    var DXCoilOutletNode: Int32
    var HeatingCoilInletNode: Int32
    var HeatingCoilOutletNode: Int32
    var FanInletNodeNum: Int32
    var OutletTempSetPoint: Float64
    var CoilTempSetPoint: Float64
    var HeatCoolMode: Int32
    var BypassMassFlowRate: Float64
    var DehumidificationMode: Int32
    var DehumidControlType: Int32
    var HumRatMaxCheck: Bool
    var DXIterationExceeded: Int32
    var DXIterationExceededIndex: Int32
    var DXIterationFailed: Int32
    var DXIterationFailedIndex: Int32
    var DXCyclingIterationExceeded: Int32
    var DXCyclingIterationExceededIndex: Int32
    var DXCyclingIterationFailed: Int32
    var DXCyclingIterationFailedIndex: Int32
    var DXHeatIterationExceeded: Int32
    var DXHeatIterationExceededIndex: Int32
    var DXHeatIterationFailed: Int32
    var DXHeatIterationFailedIndex: Int32
    var DXHeatCyclingIterationExceeded: Int32
    var DXHeatCyclingIterationExceededIndex: Int32
    var DXHeatCyclingIterationFailed: Int32
    var DXHeatCyclingIterationFailedIndex: Int32
    var HXDXIterationExceeded: Int32
    var HXDXIterationExceededIndex: Int32
    var HXDXIterationFailed: Int32
    var HXDXIterationFailedIndex: Int32
    var MMDXIterationExceeded: Int32
    var MMDXIterationExceededIndex: Int32
    var MMDXIterationFailed: Int32
    var MMDXIterationFailedIndex: Int32
    var DMDXIterationExceeded: Int32
    var DMDXIterationExceededIndex: Int32
    var DMDXIterationFailed: Int32
    var DMDXIterationFailedIndex: Int32
    var CRDXIterationExceeded: Int32
    var CRDXIterationExceededIndex: Int32
    var CRDXIterationFailed: Int32
    var CRDXIterationFailedIndex: Int32
    var FirstPass: Bool
    var plenumIndex: Int32
    var mixerIndex: Int32
    var changeOverTimer: Float64
    var minModeChangeTime: Float64
    var OutNodeSPMIndex: Int32
    var modeChanged: Bool

    fn __init__() -> Self:
        return Self(
            Name: String(),
            UnitType: String(),
            availSchedName: String(),
            availSched: UnsafePointer[NoneType](),
            MaxCoolAirVolFlow: 0.0,
            MaxHeatAirVolFlow: 0.0,
            MaxNoCoolHeatAirVolFlow: 0.0,
            MaxCoolAirMassFlow: 0.0,
            MaxHeatAirMassFlow: 0.0,
            MaxNoCoolHeatAirMassFlow: 0.0,
            CoolOutAirVolFlow: 0.0,
            HeatOutAirVolFlow: 0.0,
            NoCoolHeatOutAirVolFlow: 0.0,
            CoolOutAirMassFlow: 0.0,
            HeatOutAirMassFlow: 0.0,
            NoCoolHeatOutAirMassFlow: 0.0,
            outAirSched: UnsafePointer[NoneType](),
            AirInNode: 0,
            AirOutNode: 0,
            CondenserNodeNum: 0,
            MixerOutsideAirNode: 0,
            MixerMixedAirNode: 0,
            MixerReliefAirNode: 0,
            MixerInletAirNode: 0,
            SplitterOutletAirNode: 0,
            PlenumMixerInletAirNode: 0,
            OAMixType: String(),
            OAMixName: String(),
            OAMixIndex: 0,
            FanName: String(),
            fanType: -1,
            fanPlace: -1,
            FanIndex: 0,
            fanOpModeSched: UnsafePointer[NoneType](),
            FanVolFlow: 0.0,
            HeatingSpeedRatio: 1.0,
            CoolingSpeedRatio: 1.0,
            NoHeatCoolSpeedRatio: 1.0,
            CheckFanFlow: True,
            DXCoolCoilName: String(),
            coolCoilType: -1,
            CoolCoilCompIndex: 0,
            DXCoolCoilIndexNum: 0,
            DXHeatCoilIndexNum: 0,
            HeatCoilName: String(),
            heatCoilType: -1,
            HeatCoilIndex: 0,
            fanOp: -1,
            CoilControlNode: 0,
            CoilOutletNode: 0,
            plantLoc: UnsafePointer[NoneType](),
            HotWaterCoilMaxIterIndex: 0,
            HotWaterCoilMaxIterIndex2: 0,
            MaxHeatCoilFluidFlow: 0.0,
            DesignHeatingCapacity: 0.0,
            DesignSuppHeatingCapacity: 0.0,
            MinOATCompressor: 0.0,
            MinLATCooling: 0.0,
            MaxLATHeating: 0.0,
            TotHeatEnergyRate: 0.0,
            TotHeatEnergy: 0.0,
            TotCoolEnergyRate: 0.0,
            TotCoolEnergy: 0.0,
            SensHeatEnergyRate: 0.0,
            SensHeatEnergy: 0.0,
            SensCoolEnergyRate: 0.0,
            SensCoolEnergy: 0.0,
            LatHeatEnergyRate: 0.0,
            LatHeatEnergy: 0.0,
            LatCoolEnergyRate: 0.0,
            LatCoolEnergy: 0.0,
            ElecPower: 0.0,
            ElecConsumption: 0.0,
            FanPartLoadRatio: 0.0,
            CompPartLoadRatio: 0.0,
            LastMode: 0,
            AirFlowControl: -1,
            CompPartLoadFrac: 0.0,
            AirLoopNumber: 0,
            NumControlledZones: 0,
            ControlledZoneNum: DynamicVector[Int32](),
            ControlledZoneNodeNum: DynamicVector[Int32](),
            CBVAVBoxOutletNode: DynamicVector[Int32](),
            ZoneSequenceCoolingNum: DynamicVector[Int32](),
            ZoneSequenceHeatingNum: DynamicVector[Int32](),
            PriorityControl: -1,
            NumZonesCooled: 0,
            NumZonesHeated: 0,
            PLRMaxIter: 0,
            PLRMaxIterIndex: 0,
            DXCoilInletNode: 0,
            DXCoilOutletNode: 0,
            HeatingCoilInletNode: 0,
            HeatingCoilOutletNode: 0,
            FanInletNodeNum: 0,
            OutletTempSetPoint: 0.0,
            CoilTempSetPoint: 0.0,
            HeatCoolMode: 0,
            BypassMassFlowRate: 0.0,
            DehumidificationMode: -1,
            DehumidControlType: 0,
            HumRatMaxCheck: True,
            DXIterationExceeded: 0,
            DXIterationExceededIndex: 0,
            DXIterationFailed: 0,
            DXIterationFailedIndex: 0,
            DXCyclingIterationExceeded: 0,
            DXCyclingIterationExceededIndex: 0,
            DXCyclingIterationFailed: 0,
            DXCyclingIterationFailedIndex: 0,
            DXHeatIterationExceeded: 0,
            DXHeatIterationExceededIndex: 0,
            DXHeatIterationFailed: 0,
            DXHeatIterationFailedIndex: 0,
            DXHeatCyclingIterationExceeded: 0,
            DXHeatCyclingIterationExceededIndex: 0,
            DXHeatCyclingIterationFailed: 0,
            DXHeatCyclingIterationFailedIndex: 0,
            HXDXIterationExceeded: 0,
            HXDXIterationExceededIndex: 0,
            HXDXIterationFailed: 0,
            HXDXIterationFailedIndex: 0,
            MMDXIterationExceeded: 0,
            MMDXIterationExceededIndex: 0,
            MMDXIterationFailed: 0,
            MMDXIterationFailedIndex: 0,
            DMDXIterationExceeded: 0,
            DMDXIterationExceededIndex: 0,
            DMDXIterationFailed: 0,
            DMDXIterationFailedIndex: 0,
            CRDXIterationExceeded: 0,
            CRDXIterationExceededIndex: 0,
            CRDXIterationFailed: 0,
            CRDXIterationFailedIndex: 0,
            FirstPass: True,
            plenumIndex: 0,
            mixerIndex: 0,
            changeOverTimer: -1.0,
            minModeChangeTime: -1.0,
            OutNodeSPMIndex: 0,
            modeChanged: False,
        )


@value
struct HVACUnitaryBypassVAVData:
    """Global data for HVACUnitaryBypassVAV module"""
    var NumCBVAV: Int32
    var CompOnMassFlow: Float64
    var OACompOnMassFlow: Float64
    var CompOffMassFlow: Float64
    var OACompOffMassFlow: Float64
    var CompOnFlowRatio: Float64
    var CompOffFlowRatio: Float64
    var FanSpeedRatio: Float64
    var BypassDuctFlowFraction: Float64
    var PartLoadFrac: Float64
    var SaveCompressorPLR: Float64
    var TempSteamIn: Float64
    var CheckEquipName: DynamicVector[Bool]
    var CBVAV: DynamicVector[CBVAVData]
    var GetInputFlag: Bool
    var MyOneTimeFlag: Bool
    var MyEnvrnFlag: DynamicVector[Bool]
    var MySizeFlag: DynamicVector[Bool]
    var MyPlantScanFlag: DynamicVector[Bool]

    fn __init__() -> Self:
        return Self(
            NumCBVAV: 0,
            CompOnMassFlow: 0.0,
            OACompOnMassFlow: 0.0,
            CompOffMassFlow: 0.0,
            OACompOffMassFlow: 0.0,
            CompOnFlowRatio: 0.0,
            CompOffFlowRatio: 0.0,
            FanSpeedRatio: 0.0,
            BypassDuctFlowFraction: 0.0,
            PartLoadFrac: 0.0,
            SaveCompressorPLR: 0.0,
            TempSteamIn: 100.0,
            CheckEquipName: DynamicVector[Bool](),
            CBVAV: DynamicVector[CBVAVData](),
            GetInputFlag: True,
            MyOneTimeFlag: True,
            MyEnvrnFlag: DynamicVector[Bool](),
            MySizeFlag: DynamicVector[Bool](),
            MyPlantScanFlag: DynamicVector[Bool](),
        )


fn SimUnitaryBypassVAV(
    state: UnsafePointer[AnyType],
    CompName: StringRef,
    FirstHVACIteration: Bool,
    AirLoopNum: Int32
) -> Tuple[Int32, Float64]:
    """Manages the simulation of a changeover-bypass VAV system"""
    var CBVAVNum: Int32 = 0
    var QUnitOut: Float64 = 0.0
    var CompIndex: Int32 = 0

    # ... (main simulation code)

    return Tuple[Int32, Float64](CompIndex, QUnitOut)


fn SimCBVAV(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    FirstHVACIteration: Bool,
    OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool
) -> Float64:
    """Simulate a changeover-bypass VAV system"""
    var QSensUnitOut: Float64 = 0.0

    # ... (simulation code)

    return QSensUnitOut


fn GetCBVAV(state: UnsafePointer[AnyType]) -> None:
    """Obtains input data for changeover-bypass VAV systems"""
    # ... (input processing)
    pass


fn InitCBVAV(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    FirstHVACIteration: Bool,
    AirLoopNum: Int32,
    OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool
) -> None:
    """Initializations of the changeover-bypass VAV system"""
    # ... (initialization code)
    pass


fn SizeCBVAV(state: UnsafePointer[AnyType], CBVAVNum: Int32) -> None:
    """Sizing of changeover-bypass VAV components"""
    # ... (sizing code)
    pass


fn ControlCBVAVOutput(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    FirstHVACIteration: Bool,
    PartLoadFrac: Float64,
    OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool
) -> None:
    """Determine the part load fraction of the CBVAV system"""
    # ... (control code)
    pass


fn CalcCBVAV(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    FirstHVACIteration: Bool,
    PartLoadFrac: Float64,
    LoadMet: Float64,
    OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool
) -> None:
    """Simulate the components making up the changeover-bypass VAV system"""
    # ... (calculation code)
    pass


fn GetZoneLoads(state: UnsafePointer[AnyType], CBVAVNum: Int32) -> None:
    """Poll thermostats in each zone to determine mode of operation"""
    # ... (zone load calculation)
    pass


fn CalcSetPointTempTarget(state: UnsafePointer[AnyType], CBVAVNumber: Int32) -> Float64:
    """Calculate outlet air node temperature setpoint"""
    # ... (setpoint calculation)
    return 0.0


fn SetAverageAirFlow(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    OnOffAirFlowRatio: Float64
) -> None:
    """Set the average air mass flow rates for this time step"""
    # ... (flow calculation)
    pass


fn ReportCBVAV(state: UnsafePointer[AnyType], CBVAVNum: Int32) -> None:
    """Report the results of the CBVAV system simulation"""
    # ... (reporting code)
    pass


fn CalcNonDXHeatingCoils(
    state: UnsafePointer[AnyType],
    CBVAVNum: Int32,
    FirstHVACIteration: Bool,
    HeatCoilLoad: Float64,
    fanOp: Int32,
    HeatCoilLoadmet: Float64
) -> None:
    """Simulate the four non-dx heating coil types: Gas, Electric, hot water and steam"""
    # ... (heating coil simulation code)
    pass
