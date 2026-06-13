"""
EnergyPlus FanCoilUnits module — Python port.
Simulates 4-pipe fan coil units with various capacity control methods.
"""

from typing import Optional, Protocol, Any
from dataclasses import dataclass, field
from enum import IntEnum
import math

# ============================================================================
# EXTERNAL DEPENDENCIES (stubs — caller must inject implementations)
# ============================================================================

class Node:
    """Stub for node data."""
    def __init__(self):
        self.MassFlowRate = 0.0
        self.MassFlowRateMax = 0.0
        self.MassFlowRateMaxAvail = 0.0
        self.MassFlowRateMinAvail = 0.0
        self.Temp = 0.0
        self.HumRat = 0.0
        self.Enthalpy = 0.0
        self.Press = 0.0


class Schedule:
    """Stub for schedule data."""
    def getCurrentVal(self) -> float:
        return 1.0


class HVACFanType(IntEnum):
    Invalid = -1
    Constant = 0
    VAV = 1
    OnOff = 2
    SystemModel = 3


class HVACCoilType(IntEnum):
    Invalid = -1
    CoolingWater = 1
    CoolingWaterDetailed = 2
    CoolingWaterHXAssisted = 3
    HeatingWater = 10
    HeatingElectric = 11


class HVACMixerType(IntEnum):
    Invalid = -1
    InletSide = 1
    SupplySide = 2


class HVACFanOp(IntEnum):
    Cycling = 1
    Continuous = 2


class HVACSetptType(IntEnum):
    SingleHeat = 1
    SingleCool = 2
    SingleHeatCool = 3
    DualHeatCool = 4


class HVACCompressorOp(IntEnum):
    Off = 0
    On = 1


class AvailStatus(IntEnum):
    NoAction = 0


class DataPlantEquipmentType(IntEnum):
    Invalid = -1
    CoilWaterCooling = 1
    CoilWaterDetailedFlatCooling = 2
    CoilWaterSimpleHeating = 3


class DataPlantFlowLock(IntEnum):
    Unlocked = 0
    Locked = 1


class PlantLocation:
    """Stub for plant location data."""
    def __init__(self):
        self.loop = None
        self.side = None


class PlantSide:
    """Stub for plant side data."""
    def __init__(self):
        self.FlowLock = DataPlantFlowLock.Unlocked


class PlantLoop:
    """Stub for plant loop data."""
    def __init__(self):
        self.glycol = None


class EnergyPlusDataStub(Protocol):
    """Protocol stub for EnergyPlusData."""
    dataFanCoilUnits: Any
    dataSize: Any
    dataLoopNodes: Any
    dataHVACGlobal: Any
    dataZoneEnergyDemand: Any
    dataHeatBalFanSys: Any
    dataZoneEquip: Any
    dataFans: Any
    dataGlobal: Any
    dataEnvrn: Any
    dataAvail: Any
    dataPlnt: Any
    dataInputProcessing: Any
    dataWaterCoils: Any
    dataHeatingCoils: Any
    dataHeatBal: Any


# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================

Small5WLoad = 5.0
FanCoilUnit_4Pipe = 1


class CCM(IntEnum):
    """Capacity control method."""
    Invalid = -1
    ConsFanVarFlow = 0
    CycFan = 1
    VarFanVarFlow = 2
    VarFanConsFlow = 3
    MultiSpeedFan = 4
    ASHRAE = 5
    Num = 6


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class FanCoilData:
    """Fan coil unit data structure."""
    UnitType_Num: int = 0
    availSchedName: str = ""
    availSched: Optional[Schedule] = None
    SchedOutAir: str = ""
    oaSched: Optional[Schedule] = None
    fanType: HVACFanType = HVACFanType.Invalid
    SpeedFanSel: int = 0
    CapCtrlMeth_Num: CCM = CCM.Invalid
    PLR: float = 0.0
    MaxIterIndexH: int = 0
    BadMassFlowLimIndexH: int = 0
    MaxIterIndexC: int = 0
    BadMassFlowLimIndexC: int = 0
    FanAirVolFlow: float = 0.0
    MaxAirVolFlow: float = 0.0
    MaxAirMassFlow: float = 0.0
    LowSpeedRatio: float = 0.0
    MedSpeedRatio: float = 0.0
    SpeedFanRatSel: float = 0.0
    OutAirVolFlow: float = 0.0
    OutAirMassFlow: float = 0.0
    AirInNode: int = 0
    AirOutNode: int = 0
    OutsideAirNode: int = 0
    AirReliefNode: int = 0
    MixedAirNode: int = 0
    OAMixName: str = ""
    OAMixType: str = ""
    OAMixIndex: int = 0
    FanName: str = ""
    FanIndex: int = 0
    CCoilName: str = ""
    CCoilName_Index: int = 0
    CCoilType: str = ""
    coolCoilType: HVACCoilType = HVACCoilType.Invalid
    CCoilPlantName: str = ""
    CCoilPlantType: DataPlantEquipmentType = DataPlantEquipmentType.Invalid
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    MaxColdWaterVolFlow: float = 0.0
    MinColdWaterVolFlow: float = 0.0
    MinColdWaterFlow: float = 0.0
    ColdControlOffset: float = 0.0
    HCoilName: str = ""
    HCoilName_Index: int = 0
    HCoilType: str = ""
    heatCoilType: HVACCoilType = HVACCoilType.Invalid
    HCoilPlantTypeOf: DataPlantEquipmentType = DataPlantEquipmentType.Invalid
    MaxHotWaterVolFlow: float = 0.0
    MinHotWaterVolFlow: float = 0.0
    MinHotWaterFlow: float = 0.0
    HotControlOffset: float = 0.0
    DesignHeatingCapacity: float = 0.0
    availStatus: AvailStatus = AvailStatus.NoAction
    AvailManagerListName: str = ""
    ATMixerName: str = ""
    ATMixerIndex: int = 0
    ATMixerType: HVACMixerType = HVACMixerType.Invalid
    ATMixerPriNode: int = 0
    ATMixerSecNode: int = 0
    HVACSizingIndex: int = 0
    SpeedRatio: float = 0.0
    fanOpModeSched: Optional[Schedule] = None
    fanOp: HVACFanOp = HVACFanOp.Cycling
    ASHRAETempControl: bool = False
    QUnitOutNoHC: float = 0.0
    QUnitOutMaxH: float = 0.0
    QUnitOutMaxC: float = 0.0
    LimitErrCountH: int = 0
    LimitErrCountC: int = 0
    ConvgErrCountH: int = 0
    ConvgErrCountC: int = 0
    HeatPower: float = 0.0
    HeatEnergy: float = 0.0
    TotCoolPower: float = 0.0
    TotCoolEnergy: float = 0.0
    SensCoolPower: float = 0.0
    SensCoolEnergy: float = 0.0
    ElecPower: float = 0.0
    ElecEnergy: float = 0.0
    DesCoolingLoad: float = 0.0
    DesHeatingLoad: float = 0.0
    DesZoneCoolingLoad: float = 0.0
    DesZoneHeatingLoad: float = 0.0
    DSOAPtr: int = 0
    FirstPass: bool = True
    fanAvailSched: Optional[Schedule] = None
    Name: str = ""
    UnitType: str = ""
    MaxCoolCoilFluidFlow: float = 0.0
    MaxHeatCoilFluidFlow: float = 0.0
    DesignMinOutletTemp: float = 0.0
    DesignMaxOutletTemp: float = 0.0
    MaxNoCoolHeatAirMassFlow: float = 0.0
    MaxCoolAirMassFlow: float = 0.0
    MaxHeatAirMassFlow: float = 0.0
    LowSpeedCoolFanRatio: float = 0.0
    LowSpeedHeatFanRatio: float = 0.0
    CoolCoilFluidInletNode: int = 0
    CoolCoilFluidOutletNodeNum: int = 0
    HeatCoilFluidInletNode: int = 0
    HeatCoilFluidOutletNodeNum: int = 0
    CoolCoilPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    HeatCoilPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    CoolCoilInletNodeNum: int = 0
    CoolCoilOutletNodeNum: int = 0
    HeatCoilInletNodeNum: int = 0
    HeatCoilOutletNodeNum: int = 0
    ControlZoneNum: int = 0
    NodeNumOfControlledZone: int = 0
    ATMixerExists: bool = False
    ATMixerOutNode: int = 0
    FanPartLoadRatio: float = 0.0
    HeatCoilWaterFlowRatio: float = 0.0
    ControlZoneMassFlowFrac: float = 1.0
    MaxIterIndex: int = 0
    RegulaFalsiFailedIndex: int = 0


@dataclass
class FanCoilNumericFieldData:
    """Numeric field data for fan coil."""
    FieldNames: list = field(default_factory=list)


# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

def SimFanCoilUnit(
    state: EnergyPlusDataStub,
    CompName: str,
    ControlledZoneNum: int,
    FirstHVACIteration: bool,
    PowerMet: list,  # out parameter
    LatOutputProvided: list,  # out parameter
    CompIndex: list  # in/out parameter
) -> None:
    """Manage simulation of a fan coil unit."""
    
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    # Find the correct fan coil equipment
    if CompIndex[0] == 0:
        FanCoilNum = find_item_in_list(CompName, state.dataFanCoilUnits.FanCoil)
        if FanCoilNum == 0:
            raise ValueError(f"SimFanCoil: Unit not found={CompName}")
        CompIndex[0] = FanCoilNum
    else:
        FanCoilNum = CompIndex[0]
        if FanCoilNum > state.dataFanCoilUnits.NumFanCoils or FanCoilNum < 1:
            raise ValueError(
                f"SimFanCoil: Invalid CompIndex passed={FanCoilNum}, "
                f"Number of Units={state.dataFanCoilUnits.NumFanCoils}, "
                f"Entered Unit name={CompName}"
            )
    
    state.dataSize.ZoneEqFanCoil = True
    
    # Initialize the fan coil unit
    InitFanCoilUnits(state, FanCoilNum, ControlledZoneNum)
    
    # Select the correct unit type
    if state.dataFanCoilUnits.FanCoil[FanCoilNum].UnitType_Num == FanCoilUnit_4Pipe:
        Sim4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, PowerMet, LatOutputProvided)
    
    # Report the result
    ReportFanCoilUnit(state, FanCoilNum)
    
    state.dataSize.ZoneEqFanCoil = False


def GetFanCoilUnits(state: EnergyPlusDataStub) -> None:
    """Obtain input data for fan coil units."""
    # Stub implementation — would read from input processor
    pass


def InitFanCoilUnits(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ControlledZoneNum: int
) -> None:
    """Initialize fan coil unit for simulation."""
    # Stub implementation
    pass


def SizeFanCoilUnit(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ControlledZoneNum: int
) -> None:
    """Size fan coil unit components."""
    # Stub implementation
    pass


def Sim4PipeFanCoil(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ControlledZoneNum: int,
    FirstHVACIteration: bool,
    PowerMet: list,
    LatOutputProvided: list
) -> None:
    """Simulate a 4-pipe fan coil unit."""
    # Stub implementation
    pass


def TightenWaterFlowLimits(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    CoolingLoad: bool,
    HeatingLoad: bool,
    WaterControlNode: int,
    ControlledZoneNum: int,
    FirstHVACIteration: bool,
    QZnReq: float,
    MinWaterFlow: list,
    MaxWaterFlow: list
) -> None:
    """Tighten water flow rate limits for fan coil unit."""
    # Stub implementation
    pass


def TightenAirAndWaterFlowLimits(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    CoolingLoad: bool,
    HeatingLoad: bool,
    WaterControlNode: int,
    ControlledZoneNum: int,
    FirstHVACIteration: bool,
    QZnReq: float,
    PLRMin: list,
    PLRMax: list
) -> None:
    """Tighten air and water flow limits."""
    # Stub implementation
    pass


def Calc4PipeFanCoil(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ControlledZoneNum: int,
    FirstHVACIteration: bool,
    LoadMet: list,
    PLR: Optional[float] = None,
    eHeatCoilCyclingR: float = 1.0
) -> None:
    """Calculate 4-pipe fan coil unit output."""
    # Stub implementation
    pass


def SimMultiStage4PipeFanCoil(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ZoneNum: int,
    FirstHVACIteration: bool,
    PowerMet: list
) -> None:
    """Simulate multi-stage 4-pipe fan coil."""
    # Stub implementation
    pass


def CalcMultiStage4PipeFanCoil(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    ZoneNum: int,
    FirstHVACIteration: bool,
    QZnReq: float,
    SpeedRatio: list,
    PartLoadRatio: list,
    PowerMet: list
) -> None:
    """Calculate multi-stage fan coil output."""
    # Stub implementation
    pass


def ReportFanCoilUnit(state: EnergyPlusDataStub, FanCoilNum: int) -> None:
    """Report fan coil unit results."""
    ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
    fc = state.dataFanCoilUnits.FanCoil[FanCoilNum]
    fc.HeatEnergy = fc.HeatPower * ReportingConstant
    fc.SensCoolEnergy = fc.SensCoolPower * ReportingConstant
    fc.TotCoolEnergy = fc.TotCoolPower * ReportingConstant
    fc.ElecEnergy = fc.ElecPower * ReportingConstant


def GetFanCoilZoneInletAirNode(state: EnergyPlusDataStub, FanCoilNum: int) -> int:
    """Get zone inlet air node."""
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    if 0 < FanCoilNum <= state.dataFanCoilUnits.NumFanCoils:
        return state.dataFanCoilUnits.FanCoil[FanCoilNum - 1].AirOutNode
    return 0


def GetFanCoilOutAirNode(state: EnergyPlusDataStub, FanCoilNum: int) -> int:
    """Get outdoor air node."""
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    if 0 < FanCoilNum <= state.dataFanCoilUnits.NumFanCoils:
        return state.dataFanCoilUnits.FanCoil[FanCoilNum - 1].OutsideAirNode
    return 0


def GetFanCoilReturnAirNode(state: EnergyPlusDataStub, FanCoilNum: int) -> int:
    """Get return air node."""
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    if 0 < FanCoilNum <= state.dataFanCoilUnits.NumFanCoils:
        if state.dataFanCoilUnits.FanCoil[FanCoilNum - 1].OAMixIndex > 0:
            # Stub call to external function
            return 0
    return 0


def GetFanCoilMixedAirNode(state: EnergyPlusDataStub, FanCoilNum: int) -> int:
    """Get mixed air node."""
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    if 0 < FanCoilNum <= state.dataFanCoilUnits.NumFanCoils:
        if state.dataFanCoilUnits.FanCoil[FanCoilNum - 1].OAMixIndex > 0:
            # Stub call to external function
            return 0
    return 0


def CalcFanCoilLoadResidual(
    state: EnergyPlusDataStub,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ControlledZoneNum: int,
    QZnReq: float,
    PartLoadRatio: float
) -> float:
    """Calculate load residual for solver."""
    QUnitOut = [0.0]
    Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PartLoadRatio)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def CalcFanCoilPLRResidual(
    state: EnergyPlusDataStub,
    PLR: float,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ControlledZoneNum: int,
    WaterControlNode: int,
    QZnReq: float
) -> float:
    """Calculate PLR residual."""
    QUnitOut = [0.0]
    fc = state.dataFanCoilUnits.FanCoil[FanCoilNum]
    
    if WaterControlNode == fc.CoolCoilFluidInletNode:
        state.dataLoopNodes.Node[WaterControlNode].MassFlowRate = PLR * fc.MaxCoolCoilFluidFlow
        Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PLR)
    elif WaterControlNode == fc.HeatCoilFluidInletNode and fc.heatCoilType != HVACCoilType.HeatingElectric:
        state.dataLoopNodes.Node[WaterControlNode].MassFlowRate = PLR * fc.MaxHeatCoilFluidFlow
        Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PLR)
    else:
        Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PLR)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def CalcFanCoilHeatCoilPLRResidual(
    state: EnergyPlusDataStub,
    CyclingR: float,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ZoneNum: int,
    QZnReq: float
) -> float:
    """Calculate heat coil PLR residual."""
    QUnitOut = [0.0]
    Calc4PipeFanCoil(state, FanCoilNum, ZoneNum, FirstHVACIteration, QUnitOut, 1.0, CyclingR)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def CalcFanCoilCWLoadResidual(
    state: EnergyPlusDataStub,
    CWFlow: float,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ControlledZoneNum: int,
    QZnReq: float
) -> float:
    """Calculate cold water load residual."""
    QUnitOut = [0.0]
    fc = state.dataFanCoilUnits.FanCoil[FanCoilNum]
    state.dataLoopNodes.Node[fc.CoolCoilFluidInletNode].MassFlowRate = CWFlow
    Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, 1.0)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def CalcFanCoilWaterFlowResidual(
    state: EnergyPlusDataStub,
    PLR: float,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ControlledZoneNum: int,
    QZnReq: float,
    AirInNode: int,
    WaterControlNode: int,
    maxCoilFluidFlow: float,
    AirMassFlowRate: float
) -> float:
    """Calculate water flow residual."""
    mDot = PLR * maxCoilFluidFlow
    if WaterControlNode > 0:
        state.dataLoopNodes.Node[WaterControlNode].MassFlowRate = mDot
    state.dataLoopNodes.Node[AirInNode].MassFlowRate = AirMassFlowRate
    
    QUnitOut = [0.0]
    fc = state.dataFanCoilUnits.FanCoil[FanCoilNum]
    
    if (WaterControlNode == fc.CoolCoilFluidInletNode or 
        (WaterControlNode == fc.HeatCoilFluidInletNode and fc.heatCoilType != HVACCoilType.HeatingElectric)):
        Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, 0.0)
    else:
        Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PLR)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def CalcFanCoilAirAndWaterFlowResidual(
    state: EnergyPlusDataStub,
    PLR: float,
    FanCoilNum: int,
    FirstHVACIteration: bool,
    ControlledZoneNum: int,
    QZnReq: float,
    AirInNode: int,
    WaterControlNode: int,
    MinWaterFlow: float
) -> float:
    """Calculate air and water flow residual."""
    fc = state.dataFanCoilUnits.FanCoil[FanCoilNum]
    
    state.dataLoopNodes.Node[AirInNode].MassFlowRate = fc.MaxAirMassFlow * (
        fc.LowSpeedRatio + (PLR * (1.0 - fc.LowSpeedRatio))
    )
    
    if WaterControlNode == fc.CoolCoilFluidInletNode:
        state.dataLoopNodes.Node[WaterControlNode].MassFlowRate = (
            MinWaterFlow + (PLR * (fc.MaxCoolCoilFluidFlow - MinWaterFlow))
        )
    elif WaterControlNode == fc.HeatCoilFluidInletNode:
        state.dataLoopNodes.Node[WaterControlNode].MassFlowRate = (
            MinWaterFlow + (PLR * (fc.MaxHeatCoilFluidFlow - MinWaterFlow))
        )
    
    QUnitOut = [0.0]
    Calc4PipeFanCoil(state, FanCoilNum, ControlledZoneNum, FirstHVACIteration, QUnitOut, PLR)
    
    if abs(QZnReq) <= 100.0:
        return (QUnitOut[0] - QZnReq) / 100.0
    return (QUnitOut[0] - QZnReq) / QZnReq


def getEqIndex(state: EnergyPlusDataStub, CompName: str) -> int:
    """Get equipment index by name."""
    if state.dataFanCoilUnits.GetFanCoilInputFlag:
        GetFanCoilUnits(state)
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
    
    for i, fc in enumerate(state.dataFanCoilUnits.FanCoil):
        if fc.Name == CompName:
            return i + 1
    
    return 0


# ============================================================================
# HELPERS
# ============================================================================

def find_item_in_list(item_name: str, item_list: list) -> int:
    """Find item index in list by name (1-based)."""
    for i, item in enumerate(item_list):
        if hasattr(item, 'Name') and item.Name == item_name:
            return i + 1
    return 0


def calcZoneSensibleOutput(
    AirMassFlow: float,
    OutTemp: float,
    InTemp: float,
    InHumRat: float
) -> float:
    """Calculate sensible output of zone equipment."""
    return AirMassFlow * 1006.0 * (OutTemp - InTemp)
