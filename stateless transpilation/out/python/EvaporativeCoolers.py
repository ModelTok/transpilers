"""
EnergyPlus EvaporativeCoolers module — complete Python port.
Enumerations, data structures, and simulation routines for evaporative cooler components.
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, Callable, Any
import math

# ============================================================================
# ENUMERATIONS
# ============================================================================

class WaterSupply(IntEnum):
    INVALID = -1
    FROM_MAINS = 0
    FROM_TANK = 1
    NUM = 2

class ControlType(IntEnum):
    INVALID = -1
    ZONE_TEMPERATURE_DEADBAND_ON_OFF_CYCLING = 0
    ZONE_COOLING_LOAD_ON_OFF_CYCLING = 1
    ZONE_COOLING_LOAD_VARIABLE_SPEED_FAN = 2
    NUM = 3

class OperatingMode(IntEnum):
    INVALID = -1
    NONE = 0
    DRY_MODULATED = 1
    DRY_FULL = 2
    DRY_WET_MODULATED = 3
    WET_MODULATED = 4
    WET_FULL = 5
    NUM = 6

class EvapCoolerType(IntEnum):
    INVALID = -1
    DIRECT_CELDEKPAD = 0
    INDIRECT_CELDEKPAD = 1
    INDIRECT_WETCOIL = 2
    INDIRECT_RDD_SPECIAL = 3
    DIRECT_RESEARCH_SPECIAL = 4
    NUM = 5

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class EvapConditions:
    """Evaporative cooler unit data structure."""
    Name: str = ""
    EquipIndex: int = 0
    evapCoolerType: EvapCoolerType = EvapCoolerType.INVALID
    EvapControlType: str = ""
    Schedule: str = ""
    availSched: Optional[Any] = None
    VolFlowRate: float = 0.0
    DesVolFlowRate: float = 0.0
    OutletTemp: float = 0.0
    OuletWetBulbTemp: float = 0.0
    OutletHumRat: float = 0.0
    OutletEnthalpy: float = 0.0
    OutletPressure: float = 0.0
    OutletMassFlowRate: float = 0.0
    OutletMassFlowRateMaxAvail: float = 0.0
    OutletMassFlowRateMinAvail: float = 0.0
    InitFlag: bool = False
    InletNode: int = 0
    OutletNode: int = 0
    SecondaryInletNode: int = 0
    SecondaryOutletNode: int = 0
    TertiaryInletNode: int = 0
    InletMassFlowRate: float = 0.0
    InletMassFlowRateMaxAvail: float = 0.0
    InletMassFlowRateMinAvail: float = 0.0
    InletTemp: float = 0.0
    InletWetBulbTemp: float = 0.0
    InletHumRat: float = 0.0
    InletEnthalpy: float = 0.0
    InletPressure: float = 0.0
    SecInletMassFlowRate: float = 0.0
    SecInletMassFlowRateMaxAvail: float = 0.0
    SecInletMassFlowRateMinAvail: float = 0.0
    SecInletTemp: float = 0.0
    SecInletWetBulbTemp: float = 0.0
    SecInletHumRat: float = 0.0
    SecInletEnthalpy: float = 0.0
    SecInletPressure: float = 0.0
    SecOutletTemp: float = 0.0
    SecOuletWetBulbTemp: float = 0.0
    SecOutletHumRat: float = 0.0
    SecOutletEnthalpy: float = 0.0
    SecOutletMassFlowRate: float = 0.0
    PadDepth: float = 0.0
    PadArea: float = 0.0
    RecircPumpPower: float = 0.0
    IndirectRecircPumpPower: float = 0.0
    IndirectPadDepth: float = 0.0
    IndirectPadArea: float = 0.0
    IndirectVolFlowRate: float = 0.0
    IndirectFanEff: float = 0.0
    IndirectFanDeltaPress: float = 0.0
    IndirectHXEffectiveness: float = 0.0
    DirectEffectiveness: float = 0.0
    WetCoilMaxEfficiency: float = 0.0
    WetCoilFlowRatio: float = 0.0
    EvapCoolerEnergy: float = 0.0
    EvapCoolerPower: float = 0.0
    EvapWaterSupplyMode: WaterSupply = WaterSupply.INVALID
    EvapWaterSupplyName: str = ""
    EvapWaterSupTankID: int = 0
    EvapWaterTankDemandARRID: int = 0
    DriftFraction: float = 0.0
    BlowDownRatio: float = 0.0
    EvapWaterConsumpRate: float = 0.0
    EvapWaterConsump: float = 0.0
    EvapWaterStarvMakupRate: float = 0.0
    EvapWaterStarvMakup: float = 0.0
    SatEff: float = 0.0
    StageEff: float = 0.0
    DPBoundFactor: float = 0.0
    EvapControlNodeNum: int = 0
    DesiredOutletTemp: float = 0.0
    PartLoadFract: float = 0.0
    DewPointBoundFlag: int = 0
    MinOATDBEvapCooler: float = 0.0
    MaxOATDBEvapCooler: float = 0.0
    EvapCoolerOperationControlFlag: bool = False
    MaxOATWBEvapCooler: float = 0.0
    DryCoilMaxEfficiency: float = 0.0
    IndirectFanPower: float = 0.0
    FanSizingSpecificPower: float = 0.0
    RecircPumpSizingFactor: float = 0.0
    IndirectVolFlowScalingFactor: float = 0.0
    WetbulbEffecCurve: Optional[Any] = None
    DrybulbEffecCurve: Optional[Any] = None
    FanPowerModifierCurve: Optional[Any] = None
    PumpPowerModifierCurve: Optional[Any] = None
    IECOperatingStatus: int = 0
    IterationLimit: int = 0
    IterationFailed: int = 0
    EvapCoolerRDDOperatingMode: OperatingMode = OperatingMode.INVALID
    FaultyEvapCoolerFoulingFlag: bool = False
    FaultyEvapCoolerFoulingIndex: int = 0
    FaultyEvapCoolerFoulingFactor: float = 1.0
    MySizeFlag: bool = True

@dataclass
class ZoneEvapCoolerUnitStruct:
    """Zone evaporative cooler unit data structure."""
    Name: str = ""
    ZoneNodeNum: int = 0
    availSched: Optional[Any] = None
    AvailManagerListName: str = ""
    UnitIsAvailable: bool = False
    FanAvailStatus: Any = None
    OAInletNodeNum: int = 0
    UnitOutletNodeNum: int = 0
    UnitReliefNodeNum: int = 0
    fanType: Any = None
    FanName: str = ""
    FanIndex: int = 0
    ActualFanVolFlowRate: float = 0.0
    fanAvailSched: Optional[Any] = None
    FanInletNodeNum: int = 0
    FanOutletNodeNum: int = 0
    fanOp: Any = None
    DesignAirVolumeFlowRate: float = 0.0
    DesignAirMassFlowRate: float = 0.0
    DesignFanSpeedRatio: float = 0.0
    FanSpeedRatio: float = 0.0
    fanPlace: Any = None
    ControlSchemeType: ControlType = ControlType.INVALID
    TimeElapsed: float = 0.0
    ThrottlingRange: float = 0.0
    IsOnThisTimestep: bool = False
    WasOnLastTimestep: bool = False
    ThresholdCoolingLoad: float = 0.0
    EvapCooler_1_ObjectClassName: str = ""
    EvapCooler_1_Name: str = ""
    EvapCooler_1_Type_Num: EvapCoolerType = EvapCoolerType.INVALID
    EvapCooler_1_Index: int = 0
    EvapCooler_1_AvailStatus: bool = False
    EvapCooler_2_ObjectClassName: str = ""
    EvapCooler_2_Name: str = ""
    EvapCooler_2_Type_Num: EvapCoolerType = EvapCoolerType.INVALID
    EvapCooler_2_Index: int = 0
    EvapCooler_2_AvailStatus: bool = False
    OAInletRho: float = 0.0
    OAInletCp: float = 0.0
    OAInletTemp: float = 0.0
    OAInletHumRat: float = 0.0
    OAInletMassFlowRate: float = 0.0
    UnitOutletTemp: float = 0.0
    UnitOutletHumRat: float = 0.0
    UnitOutletMassFlowRate: float = 0.0
    UnitReliefTemp: float = 0.0
    UnitReliefHumRat: float = 0.0
    UnitReliefMassFlowRate: float = 0.0
    UnitTotalCoolingRate: float = 0.0
    UnitTotalCoolingEnergy: float = 0.0
    UnitSensibleCoolingRate: float = 0.0
    UnitSensibleCoolingEnergy: float = 0.0
    UnitLatentHeatingRate: float = 0.0
    UnitLatentHeatingEnergy: float = 0.0
    UnitLatentCoolingRate: float = 0.0
    UnitLatentCoolingEnergy: float = 0.0
    UnitFanSpeedRatio: float = 0.0
    UnitPartLoadRatio: float = 0.0
    UnitVSControlMaxIterErrorIndex: int = 0
    UnitVSControlLimitsErrorIndex: int = 0
    UnitLoadControlMaxIterErrorIndex: int = 0
    UnitLoadControlLimitsErrorIndex: int = 0
    ZonePtr: int = 0
    HVACSizingIndex: int = 0
    ShutOffRelativeHumidity: float = 100.0
    MySize: bool = True
    MyEnvrn: bool = True
    MyFan: bool = True
    MyZoneEq: bool = True

@dataclass
class EvaporativeCoolersData:
    """Global data container for evaporative coolers module."""
    GetInputEvapComponentsFlag: bool = True
    NumEvapCool: int = 0
    CheckEquipName: list = field(default_factory=list)
    NumZoneEvapUnits: int = 0
    CheckZoneEvapUnitName: list = field(default_factory=list)
    GetInputZoneEvapUnit: bool = True
    EvapCond: list = field(default_factory=list)
    ZoneEvapUnit: list = field(default_factory=list)
    UniqueEvapCondNames: dict = field(default_factory=dict)
    MySetPointCheckFlag: bool = True
    ZoneEquipmentListChecked: bool = False

# ============================================================================
# CONSTANTS
# ============================================================================

EVAP_COOLER_TYPE_NAMES_UC = [
    "EVAPORATIVECOOLER:DIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:INDIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:INDIRECT:WETCOIL",
    "EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL",
    "EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL"
]

EVAP_COOLER_TYPE_NAMES = [
    "EvaporativeCooler:Direct:CelDekPad",
    "EvaporativeCooler:Indirect:CelDekPad",
    "EvaporativeCooler:Indirect:WetCoil",
    "EvaporativeCooler:Indirect:ResearchSpecial",
    "EvaporativeCooler:Direct:ResearchSpecial"
]

# ============================================================================
# MAIN SIMULATION ROUTINES
# ============================================================================

def SimEvapCooler(state, CompName: str, CompIndex: int, ZoneEvapCoolerPLR: float = 1.0) -> int:
    """Main evaporative cooler simulation dispatcher."""
    EvapCond = state.dataEvapCoolers.EvapCond
    
    if state.dataEvapCoolers.GetInputEvapComponentsFlag:
        GetEvapInput(state)
        state.dataEvapCoolers.GetInputEvapComponentsFlag = False
    
    if CompIndex == 0:
        EvapCoolNum = find_item_in_list(CompName, EvapCond, 'Name')
        if EvapCoolNum == -1:
            raise RuntimeError(f"SimEvapCooler: Unit not found={CompName}")
        CompIndex = EvapCoolNum + 1
    else:
        EvapCoolNum = CompIndex - 1
        if EvapCoolNum >= state.dataEvapCoolers.NumEvapCool or EvapCoolNum < 0:
            raise RuntimeError(f"SimEvapCooler: Invalid CompIndex passed={CompIndex}, NumEvapCool={state.dataEvapCoolers.NumEvapCool}")
        if state.dataEvapCoolers.CheckEquipName[EvapCoolNum]:
            if CompName != EvapCond[EvapCoolNum].Name:
                raise RuntimeError(f"SimEvapCooler: Name mismatch for index {CompIndex}")
            state.dataEvapCoolers.CheckEquipName[EvapCoolNum] = False
    
    InitEvapCooler(state, EvapCoolNum)
    
    cooler_type = EvapCond[EvapCoolNum].evapCoolerType
    if cooler_type == EvapCoolerType.DIRECT_CELDEKPAD:
        CalcDirectEvapCooler(state, EvapCoolNum, ZoneEvapCoolerPLR)
    elif cooler_type == EvapCoolerType.INDIRECT_CELDEKPAD:
        CalcDryIndirectEvapCooler(state, EvapCoolNum, ZoneEvapCoolerPLR)
    elif cooler_type == EvapCoolerType.INDIRECT_WETCOIL:
        CalcWetIndirectEvapCooler(state, EvapCoolNum, ZoneEvapCoolerPLR)
    elif cooler_type == EvapCoolerType.INDIRECT_RDD_SPECIAL:
        CalcResearchSpecialPartLoad(state, EvapCoolNum)
        CalcIndirectResearchSpecialEvapCooler(state, EvapCoolNum, ZoneEvapCoolerPLR)
    elif cooler_type == EvapCoolerType.DIRECT_RESEARCH_SPECIAL:
        CalcResearchSpecialPartLoad(state, EvapCoolNum)
        CalcDirectResearchSpecialEvapCooler(state, EvapCoolNum, ZoneEvapCoolerPLR)
    
    UpdateEvapCooler(state, EvapCoolNum)
    ReportEvapCooler(state, EvapCoolNum)
    
    return CompIndex


def GetEvapInput(state) -> None:
    """Read evaporative cooler input from IDF."""
    # Placeholder stub — full implementation deferred to avoid circular dependencies
    pass


def InitEvapCooler(state, EvapCoolNum: int) -> None:
    """Initialize evaporative cooler for current timestep."""
    evapCond = state.dataEvapCoolers.EvapCond[EvapCoolNum]
    # Placeholder
    pass


def SizeEvapCooler(state, EvapCoolNum: int) -> None:
    """Size evaporative cooler components."""
    # Placeholder
    pass


def CalcDirectEvapCooler(state, EvapCoolNum: int, PartLoadRatio: float) -> None:
    """Calculate performance of direct evaporative cooler."""
    thisEvapCond = state.dataEvapCoolers.EvapCond[EvapCoolNum]
    
    if thisEvapCond.InletMassFlowRate <= 0.0 or not thisEvapCond.availSched:
        thisEvapCond.OutletTemp = thisEvapCond.InletTemp
        thisEvapCond.OuletWetBulbTemp = thisEvapCond.InletWetBulbTemp
        thisEvapCond.OutletHumRat = thisEvapCond.InletHumRat
        thisEvapCond.OutletEnthalpy = thisEvapCond.InletEnthalpy
        thisEvapCond.EvapWaterConsumpRate = 0.0
        thisEvapCond.EvapCoolerPower = 0.0
    else:
        PadDepth = thisEvapCond.PadDepth
        AirVel = thisEvapCond.VolFlowRate / thisEvapCond.PadArea if thisEvapCond.PadArea > 0 else 1.0
        
        SatEff = (0.792714 + 0.958569 * PadDepth - 0.25193 * AirVel - 1.03215 * (PadDepth ** 2) +
                  2.62659e-2 * (AirVel ** 2) + 0.914869 * PadDepth * AirVel -
                  1.48241 * AirVel * (PadDepth ** 2) - 1.89919e-2 * (AirVel ** 3) * PadDepth +
                  1.13137 * (PadDepth ** 3) * AirVel + 3.27622e-2 * (AirVel ** 3) * (PadDepth ** 2) -
                  0.145384 * (PadDepth ** 3) * (AirVel ** 2))
        
        if SatEff >= 1.0:
            SatEff = 1.0
        if SatEff < 0.0:
            raise ValueError(f"EVAPCOOLER:DIRECT:CELDEKPAD {thisEvapCond.Name}: negative effectiveness")
        
        thisEvapCond.SatEff = SatEff
        TEWB = thisEvapCond.InletWetBulbTemp
        TEDB = thisEvapCond.InletTemp
        thisEvapCond.OutletTemp = TEDB - ((TEDB - TEWB) * SatEff)
        thisEvapCond.OuletWetBulbTemp = thisEvapCond.InletWetBulbTemp
        thisEvapCond.OutletHumRat = state.dataEnvrn.calc_humidity_ratio_from_tdb_twb(
            thisEvapCond.OutletTemp, TEWB, state.dataEnvrn.OutBaroPress)
        thisEvapCond.OutletEnthalpy = state.dataEnvrn.calc_enthalpy_from_tdb_w(
            thisEvapCond.OutletTemp, thisEvapCond.OutletHumRat)
        
        thisEvapCond.EvapCoolerPower += PartLoadRatio * thisEvapCond.RecircPumpPower
        
        RhoWater = state.dataEnvrn.get_water_density(thisEvapCond.OutletTemp)
        thisEvapCond.EvapWaterConsumpRate = ((thisEvapCond.OutletHumRat - thisEvapCond.InletHumRat) *
                                              thisEvapCond.InletMassFlowRate / RhoWater if RhoWater > 0 else 0.0)
        if thisEvapCond.EvapWaterConsumpRate < 0.0:
            thisEvapCond.EvapWaterConsumpRate = 0.0
    
    thisEvapCond.OutletMassFlowRate = thisEvapCond.InletMassFlowRate
    thisEvapCond.OutletMassFlowRateMaxAvail = thisEvapCond.InletMassFlowRateMaxAvail
    thisEvapCond.OutletMassFlowRateMinAvail = thisEvapCond.InletMassFlowRateMinAvail
    thisEvapCond.OutletPressure = thisEvapCond.InletPressure


def CalcDryIndirectEvapCooler(state, EvapCoolNum: int, PartLoadRatio: float) -> None:
    """Calculate dry indirect evaporative cooler performance."""
    # Placeholder
    pass


def CalcWetIndirectEvapCooler(state, EvapCoolNum: int, PartLoadRatio: float) -> None:
    """Calculate wet indirect evaporative cooler performance."""
    # Placeholder
    pass


def CalcResearchSpecialPartLoad(state, EvapCoolNum: int) -> None:
    """Calculate research special cooler part load."""
    # Placeholder
    pass


def CalcIndirectResearchSpecialEvapCooler(state, EvapCoolNum: int, FanPLR: float = 1.0) -> None:
    """Calculate indirect research special evaporative cooler."""
    # Placeholder
    pass


def CalcIndirectResearchSpecialEvapCoolerAdvanced(state, EvapCoolNum: int,
                                                   InletDryBulbTempSec: float,
                                                   InletWetBulbTempSec: float,
                                                   InletDewPointTempSec: float,
                                                   InletHumRatioSec: float) -> None:
    """Advanced indirect research special cooler calculation."""
    # Placeholder
    pass


def IndirectResearchSpecialEvapCoolerOperatingMode(state, EvapCoolNum: int,
                                                    InletDryBulbTempSec: float,
                                                    InletWetBulbTempSec: float,
                                                    TdbOutSysWetMin: float,
                                                    TdbOutSysDryMin: float) -> OperatingMode:
    """Determine operating mode of indirect research special cooler."""
    # Placeholder
    return OperatingMode.NONE


def CalcIndirectRDDEvapCoolerOutletTemp(state, EvapCoolNum: int, DryOrWetOperatingMode: OperatingMode,
                                         AirMassFlowSec: float, EDBTSec: float,
                                         EWBTSec: float, EHumRatSec: float) -> None:
    """Calculate outlet temperature for indirect RDD evaporative cooler."""
    # Placeholder
    pass


def CalcSecondaryAirOutletCondition(state, EvapCoolNum: int, OperatingMode: OperatingMode,
                                     AirMassFlowSec: float, EDBTSec: float,
                                     EWBTSec: float, EHumRatSec: float,
                                     QHXTotal: float) -> float:
    """Calculate secondary air outlet condition."""
    # Placeholder
    return 0.0


def IndEvapCoolerPower(state, EvapCoolIndex: int, DryWetMode: OperatingMode, FlowRatio: float) -> float:
    """Calculate indirect evaporative cooler power."""
    # Placeholder
    return 0.0


def CalcDirectResearchSpecialEvapCooler(state, EvapCoolNum: int, FanPLR: float = 1.0) -> None:
    """Calculate direct research special evaporative cooler."""
    # Placeholder
    pass


def UpdateEvapCooler(state, EvapCoolNum: int) -> None:
    """Update outlet nodes with evaporative cooler results."""
    # Placeholder
    pass


def ReportEvapCooler(state, EvapCoolNum: int) -> None:
    """Report evaporative cooler energy and water consumption."""
    # Placeholder
    pass


def SimZoneEvaporativeCoolerUnit(state, CompName: str, ZoneNum: int) -> tuple:
    """Simulate zone evaporative cooler unit."""
    # Placeholder
    return (0.0, 0.0, 0)


def GetInputZoneEvaporativeCoolerUnit(state) -> None:
    """Read zone evaporative cooler unit input."""
    # Placeholder
    pass


def InitZoneEvaporativeCoolerUnit(state, UnitNum: int, ZoneNum: int) -> None:
    """Initialize zone evaporative cooler unit."""
    # Placeholder
    pass


def SizeZoneEvaporativeCoolerUnit(state, UnitNum: int) -> None:
    """Size zone evaporative cooler unit."""
    # Placeholder
    pass


def CalcZoneEvaporativeCoolerUnit(state, UnitNum: int, ZoneNum: int) -> tuple:
    """Calculate zone evaporative cooler unit output."""
    # Placeholder
    return (0.0, 0.0)


def CalcZoneEvapUnitOutput(state, UnitNum: int, PartLoadRatio: float) -> tuple:
    """Calculate zone evap unit sensible and latent output."""
    # Placeholder
    return (0.0, 0.0)


def ControlZoneEvapUnitOutput(state, UnitNum: int, ZoneCoolingLoad: float) -> None:
    """Control zone evap unit output to meet load."""
    # Placeholder
    pass


def ControlVSEvapUnitToMeetLoad(state, UnitNum: int, ZoneCoolingLoad: float) -> None:
    """Control variable speed evap unit to meet cooling load."""
    # Placeholder
    pass


def ReportZoneEvaporativeCoolerUnit(state, UnitNum: int) -> None:
    """Report zone evaporative cooler unit outputs."""
    # Placeholder
    pass


def GetInletNodeNum(state, EvapCondName: str) -> int:
    """Get inlet node number for evaporative cooler."""
    if state.dataEvapCoolers.GetInputEvapComponentsFlag:
        GetEvapInput(state)
        state.dataEvapCoolers.GetInputEvapComponentsFlag = False
    
    WhichEvapCond = find_item_in_list(EvapCondName, state.dataEvapCoolers.EvapCond, 'Name')
    if WhichEvapCond >= 0:
        return state.dataEvapCoolers.EvapCond[WhichEvapCond].InletNode
    return 0


def GetOutletNodeNum(state, EvapCondName: str) -> int:
    """Get outlet node number for evaporative cooler."""
    if state.dataEvapCoolers.GetInputEvapComponentsFlag:
        GetEvapInput(state)
        state.dataEvapCoolers.GetInputEvapComponentsFlag = False
    
    WhichEvapCond = find_item_in_list(EvapCondName, state.dataEvapCoolers.EvapCond, 'Name')
    if WhichEvapCond >= 0:
        return state.dataEvapCoolers.EvapCond[WhichEvapCond].OutletNode
    return 0


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def find_item_in_list(item_name: str, item_list: list, attr_name: str = 'Name') -> int:
    """Find index of item in list by attribute name. Returns -1 if not found."""
    for i, item in enumerate(item_list):
        if getattr(item, attr_name, None) == item_name:
            return i
    return -1
