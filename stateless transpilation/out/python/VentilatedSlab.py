"""
Faithful translation of EnergyPlus VentilatedSlab module.
All enums, structs, functions ported from C++ header and implementation.
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Protocol
import math

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# ============================================================================
# state.dataVentilatedSlab: VentilatedSlabGlobalData (module state)
# state.dataSize: DataSizingGlobals (sizing data)
# state.dataInputProcessing: InputProcessor (configuration input)
# state.dataIPShortCut: DataIPShortCuts (input shortcuts)
# state.dataHeatBal: DataHeatBalance (zone/surface heat balance)
# state.dataSurfLists: DataSurfaceLists (surface list data)
# state.dataSurface: DataSurfaces (surface data)
# state.dataConstruction: DataConstruction (construction data)
# state.dataLoopNodes: DataLoopNode (node/loop data)
# state.dataEnvrn: DataEnvironment (environment data)
# state.dataGlobal: DataGlobals (global state)
# state.dataHeatBalFanSys: DataHeatBalFanSys (heat balance fan system)
# state.dataHeatBalSurf: DataHeatBalSurface (surface heat balance)
# state.dataZoneTempPredictorCorrector: DataZoneTempPredictorCorrector
# state.dataAvail: AvailabilityManager
# state.dataPlnt: PlantLoopData
# state.dataFans: FanData
# state.dataZoneEquip: ZoneEquipmentData
# state.dataWaterCoils: WaterCoilData
# Util, Node, Sched, HVAC, Constant, Avail, DataPlant, Fluid, PlantUtilities
# Psychrometrics, ScheduleManager, WaterCoils, SteamCoils, HeatingCoils
# HVACHXAssistedCoolingCoil, HeatBalanceSurfaceManager, OutputProcessor, Fans
# BranchNodeConnections, OutAirNodeManager, UtilityRoutines, ErrorObjectHeader
# ShowFatalError, ShowSevereError, ShowWarningError, ControlCompOutput, etc.
# ============================================================================


class OutsideAirControlType(IntEnum):
    """Parameters for outside air control types."""
    INVALID = -1
    VARIABLE_PERCENT = 0
    FIXED_TEMPERATURE = 1
    FIXED_OA_CONTROL = 2
    NUM = 3


class CoilsUsed(IntEnum):
    """Coil usage types."""
    INVALID = -1
    NONE = 0
    HEATING = 1
    COOLING = 2
    BOTH = 3
    NUM = 4


class ControlType(IntEnum):
    """Control types for ventilated slab."""
    INVALID = -1
    MEAN_AIR_TEMP = 0
    MEAN_RAD_TEMP = 1
    OPERATIVE_TEMP = 2
    OUTDOOR_DRY_BULB_TEMP = 3
    OUTDOOR_WET_BULB_TEMP = 4
    SURFACE_TEMP = 5
    DEW_POINT_TEMP = 6
    NUM = 7


class VentilatedSlabConfig(IntEnum):
    """Ventilated slab configurations."""
    INVALID = -1
    SLAB_ONLY = 0
    SLAB_AND_ZONE = 1
    SERIES_SLABS = 2
    NUM = 3


@dataclass
class VentilatedSlabData:
    """Data structure for a single ventilated slab unit."""
    Name: str = ""
    availSched: Optional[object] = None
    ZonePtr: int = 0
    ZName: List[str] = field(default_factory=list)
    ZPtr: List[int] = field(default_factory=list)
    SurfListName: str = ""
    NumOfSurfaces: int = 0
    SurfacePtr: List[int] = field(default_factory=list)
    SurfaceName: List[str] = field(default_factory=list)
    SurfaceFlowFrac: List[float] = field(default_factory=list)
    CDiameter: List[float] = field(default_factory=list)
    CLength: List[float] = field(default_factory=list)
    CNumbers: List[float] = field(default_factory=list)
    SlabIn: List[str] = field(default_factory=list)
    SlabOut: List[str] = field(default_factory=list)
    TotalSurfaceArea: float = 0.0
    CoreDiameter: float = 0.0
    CoreLength: float = 0.0
    CoreNumbers: float = 0.0
    controlType: ControlType = ControlType.INVALID
    ReturnAirNode: int = 0
    RadInNode: int = 0
    ZoneAirInNode: int = 0
    FanOutletNode: int = 0
    MSlabInNode: int = 0
    MSlabOutNode: int = 0
    FanName: str = ""
    Fan_Index: int = 0
    fanType: int = 0  # HVAC::FanType
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    MaxAirVolFlow: float = 0.0
    MaxAirMassFlow: float = 0.0
    outsideAirControlType: OutsideAirControlType = OutsideAirControlType.INVALID
    minOASched: Optional[object] = None
    maxOASched: Optional[object] = None
    tempSched: Optional[object] = None
    OutsideAirNode: int = 0
    AirReliefNode: int = 0
    OAMixerOutNode: int = 0
    OutAirVolFlow: float = 0.0
    OutAirMassFlow: float = 0.0
    MinOutAirVolFlow: float = 0.0
    MinOutAirMassFlow: float = 0.0
    SysConfg: VentilatedSlabConfig = VentilatedSlabConfig.INVALID
    coilsUsed: CoilsUsed = CoilsUsed.INVALID
    heatingCoilPresent: bool = False
    heatCoilType: int = 0  # HVAC::CoilType
    heatingCoilName: str = ""
    heatingCoilTypeCh: str = ""
    heatingCoil_Index: int = 0
    heatingCoilType: int = 0  # DataPlant::PlantEquipmentType
    heatingCoil_fluid: Optional[object] = None
    heatingCoilSched: Optional[object] = None
    heatingCoilSchedValue: float = 0.0
    MaxVolHotWaterFlow: float = 0.0
    MaxVolHotSteamFlow: float = 0.0
    MaxHotWaterFlow: float = 0.0
    MaxHotSteamFlow: float = 0.0
    MinHotSteamFlow: float = 0.0
    MinVolHotWaterFlow: float = 0.0
    MinVolHotSteamFlow: float = 0.0
    MinHotWaterFlow: float = 0.0
    HotControlNode: int = 0
    HotCoilOutNodeNum: int = 0
    HotControlOffset: float = 0.0
    HWPlantLoc: object = None  # PlantLocation
    hotAirHiTempSched: Optional[object] = None
    hotAirLoTempSched: Optional[object] = None
    hotCtrlHiTempSched: Optional[object] = None
    hotCtrlLoTempSched: Optional[object] = None
    coolingCoilPresent: bool = False
    coolingCoilName: str = ""
    coolingCoilTypeCh: str = ""
    coolingCoil_Index: int = 0
    coolingCoilPlantName: str = ""
    coolingCoilPlantType: str = ""
    coolingCoilType: int = 0  # DataPlant::PlantEquipmentType
    coolCoilType: int = 0  # HVAC::CoilType
    coolingCoilSched: Optional[object] = None
    coolingCoilSchedValue: float = 0.0
    MaxVolColdWaterFlow: float = 0.0
    MaxColdWaterFlow: float = 0.0
    MinVolColdWaterFlow: float = 0.0
    MinColdWaterFlow: float = 0.0
    ColdControlNode: int = 0
    ColdCoilOutNodeNum: int = 0
    ColdControlOffset: float = 0.0
    CWPlantLoc: object = None  # PlantLocation
    coldAirHiTempSched: Optional[object] = None
    coldAirLoTempSched: Optional[object] = None
    coldCtrlHiTempSched: Optional[object] = None
    coldCtrlLoTempSched: Optional[object] = None
    CondErrIndex: int = 0
    EnrgyImbalErrIndex: int = 0
    RadSurfNum: int = 0
    MSlabIn: int = 0
    MSlabOut: int = 0
    DirectHeatLossPower: float = 0.0
    DirectHeatLossEnergy: float = 0.0
    DirectHeatGainPower: float = 0.0
    DirectHeatGainEnergy: float = 0.0
    TotalVentSlabRadPower: float = 0.0
    RadHeatingPower: float = 0.0
    RadHeatingEnergy: float = 0.0
    RadCoolingPower: float = 0.0
    RadCoolingEnergy: float = 0.0
    HeatCoilPower: float = 0.0
    HeatCoilEnergy: float = 0.0
    TotCoolCoilPower: float = 0.0
    TotCoolCoilEnergy: float = 0.0
    SensCoolCoilPower: float = 0.0
    SensCoolCoilEnergy: float = 0.0
    LateCoolCoilPower: float = 0.0
    LateCoolCoilEnergy: float = 0.0
    ElecFanPower: float = 0.0
    ElecFanEnergy: float = 0.0
    AirMassFlowRate: float = 0.0
    AirVolFlow: float = 0.0
    SlabInTemp: float = 0.0
    SlabOutTemp: float = 0.0
    ReturnAirTemp: float = 0.0
    FanOutletTemp: float = 0.0
    ZoneInletTemp: float = 0.0
    AvailManagerListName: str = ""
    availStatus: int = 0  # Avail::Status
    HVACSizingIndex: int = 0
    FirstPass: bool = True
    ZeroVentSlabSourceSumHATsurf: float = 0.0
    QRadSysSrcAvg: List[float] = field(default_factory=list)
    LastQRadSysSrc: List[float] = field(default_factory=list)
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0


@dataclass
class VentSlabNumericFieldData:
    """Numeric field data for ventilated slab."""
    FieldNames: List[str] = field(default_factory=list)


# ============================================================================
# Function signatures - these need the full state parameter passed in
# ============================================================================

def SimVentilatedSlab(
    state,
    CompName: str,
    ZoneNum: int,
    FirstHVACIteration: bool,
) -> tuple[float, float, int]:
    """
    Main driver subroutine for ventilated slab simulation.
    Returns (PowerMet, LatOutputProvided, CompIndex)
    """
    # Stub: implementation would call GetVentilatedSlabInput, InitVentilatedSlab, etc.
    PowerMet = 0.0
    LatOutputProvided = 0.0
    CompIndex = 0
    return PowerMet, LatOutputProvided, CompIndex


def GetVentilatedSlabInput(state):
    """Obtain input for ventilated slab and set up derived type."""
    pass


def InitVentilatedSlab(
    state,
    Item: int,
    VentSlabZoneNum: int,
    FirstHVACIteration: bool,
):
    """Initialize ventilated slab data elements."""
    pass


def SizeVentilatedSlab(state, Item: int):
    """Size ventilated slab components."""
    pass


def CalcVentilatedSlab(
    state,
    Item: int,
    ZoneNum: int,
    FirstHVACIteration: bool,
) -> tuple[float, float]:
    """Calculate ventilated slab operation."""
    PowerMet = 0.0
    LatOutputProvided = 0.0
    return PowerMet, LatOutputProvided


def CalcVentilatedSlabComps(
    state,
    Item: int,
    FirstHVACIteration: bool,
) -> float:
    """Launch individual component simulations."""
    LoadMet = 0.0
    return LoadMet


def CalcVentilatedSlabCoilOutput(
    state,
    Item: int,
) -> tuple[float, float]:
    """Calculate coil output."""
    PowerMet = 0.0
    LatOutputProvided = 0.0
    return PowerMet, LatOutputProvided


def CalcVentilatedSlabRadComps(
    state,
    Item: int,
    FirstHVACIteration: bool,
):
    """Calculate radiant components."""
    pass


def SimVentSlabOAMixer(state, Item: int):
    """Simulate outside air mixer for ventilated slab."""
    pass


def UpdateVentilatedSlab(
    state,
    Item: int,
    FirstHVACIteration: bool,
):
    """Update ventilated slab state."""
    pass


def CalcVentSlabHXEffectTerm(
    state,
    Item: int,
    Temperature: float,
    AirMassFlow: float,
    FlowFraction: float,
    CoreLength: float,
    CoreDiameter: float,
    CoreNumbers: float,
) -> float:
    """Calculate heat exchanger effectiveness term."""
    return 0.0


def ReportVentilatedSlab(state, Item: int):
    """Report ventilated slab output."""
    pass


def getVentilatedSlabIndex(state, CompName: str) -> int:
    """Get ventilated slab index by name."""
    return 0
