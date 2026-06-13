# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state object (from EnergyPlus main module)
# SimAirServingZones.CompType - enum
# HVACSystemData - class/type
# HVAC.AirDuctType - enum
# HVAC.FanType - enum
# HVAC.FanPlace - enum
# DataPlant.SubcomponentData - class
# OutputProcessor.MeterData - class
# BaseGlobalStruct - base class

from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Protocol, Any
from enum import Enum


class CompType(Enum):
    Invalid = -1


class AirDuctType(Enum):
    Invalid = -1


class FanType(Enum):
    Invalid = -1


class FanPlace(Enum):
    Invalid = -1


@dataclass
class SubcomponentData:
    pass


@dataclass
class MeterData:
    pass


class HVACSystemData:
    pass


class BaseGlobalStruct:
    pass


@dataclass
class AirLoopCompData:
    TypeOf: str = ""
    Name: str = ""
    CompType_Num: CompType = CompType.Invalid
    CompIndex: int = 0
    compPointer: Optional[HVACSystemData] = None
    FlowCtrl: int = 0
    ON: bool = True
    Parent: bool = False
    NodeNameIn: str = ""
    NodeNameOut: str = ""
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    MeteredVarsFound: bool = False
    NumMeteredVars: int = 0
    NumSubComps: int = 0
    EnergyTransComp: int = 0
    Capacity: float = 0.0
    OpMode: int = 0
    TotPlantSupplyElec: float = 0.0
    PlantSupplyElecEff: float = 0.0
    PeakPlantSupplyElecEff: float = 0.0
    TotPlantSupplyGas: float = 0.0
    PlantSupplyGasEff: float = 0.0
    PeakPlantSupplyGasEff: float = 0.0
    TotPlantSupplyPurch: float = 0.0
    PlantSupplyPurchEff: float = 0.0
    PeakPlantSupplyPurchEff: float = 0.0
    TotPlantSupplyOther: float = 0.0
    PlantSupplyOtherEff: float = 0.0
    PeakPlantSupplyOtherEff: float = 0.0
    AirSysToPlantPtr: int = 0
    MeteredVar: List[MeterData] = field(default_factory=list)
    SubComp: List[SubcomponentData] = field(default_factory=list)


@dataclass
class AirLoopBranchData:
    Name: str = ""
    ControlType: str = ""
    TotalComponents: int = 0
    FirstCompIndex: List[int] = field(default_factory=list)
    LastCompIndex: List[int] = field(default_factory=list)
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    DuctType: AirDuctType = AirDuctType.Invalid
    Comp: List[AirLoopCompData] = field(default_factory=list)
    TotalNodes: int = 0
    NodeNum: List[int] = field(default_factory=list)


@dataclass
class AirLoopSplitterData:
    Exists: bool = False
    Name: str = ""
    NodeNumIn: int = 0
    BranchNumIn: int = 0
    NodeNameIn: str = ""
    TotalOutletNodes: int = 0
    NodeNumOut: List[int] = field(default_factory=list)
    BranchNumOut: List[int] = field(default_factory=list)
    NodeNameOut: List[str] = field(default_factory=list)


@dataclass
class AirLoopMixerData:
    Exists: bool = False
    Name: str = ""
    NodeNumOut: int = 0
    BranchNumOut: int = 0
    NodeNameOut: str = ""
    TotalInletNodes: int = 0
    NodeNumIn: List[int] = field(default_factory=list)
    BranchNumIn: List[int] = field(default_factory=list)
    NodeNameIn: List[str] = field(default_factory=list)


@dataclass
class DefinePrimaryAirSystem:
    Name: str = ""
    DesignVolFlowRate: float = 0.0
    DesignReturnFlowFraction: float = 1.0
    NumControllers: int = 0
    ControllerName: List[str] = field(default_factory=list)
    ControllerType: List[str] = field(default_factory=list)
    ControllerIndex: List[int] = field(default_factory=list)
    CanBeLockedOutByEcono: List[bool] = field(default_factory=list)
    NumBranches: int = 0
    Branch: List[AirLoopBranchData] = field(default_factory=list)
    Splitter: AirLoopSplitterData = field(default_factory=AirLoopSplitterData)
    Mixer: AirLoopMixerData = field(default_factory=AirLoopMixerData)
    ControlConverged: List[bool] = field(default_factory=list)
    NumOutletBranches: int = 0
    OutletBranchNum: Tuple[int, int, int] = (0, 0, 0)
    NumInletBranches: int = 0
    InletBranchNum: Tuple[int, int, int] = (0, 0, 0)
    CentralHeatCoilExists: bool = True
    CentralCoolCoilExists: bool = True
    OASysExists: bool = False
    isAllOA: bool = False
    OASysInletNodeNum: int = 0
    OASysOutletNodeNum: int = 0
    OAMixOAInNodeNum: int = 0
    RABExists: bool = False
    RABMixInNode: int = 0
    SupMixInNode: int = 0
    MixOutNode: int = 0
    RABSplitOutNode: int = 0
    OtherSplitOutNode: int = 0
    NumOACoolCoils: int = 0
    NumOAHeatCoils: int = 0
    NumOAHXs: int = 0
    SizeAirloopCoil: bool = True
    supFanType: FanType = FanType.Invalid
    supFanNum: int = 0
    supFanPlace: FanPlace = FanPlace.Invalid
    retFanType: FanType = FanType.Invalid
    retFanNum: int = 0
    FanDesCoolLoad: float = 0.0
    EconomizerStagingCheckFlag: bool = False


@dataclass
class ConnectionPoint:
    LoopType: int = 0
    LoopNum: int = 0
    BranchNum: int = 0
    CompNum: int = 0


@dataclass
class ConnectZoneComp:
    ZoneEqListNum: int = 0
    ZoneEqCompNum: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


@dataclass
class ConnectZoneSubComp:
    ZoneEqListNum: int = 0
    ZoneEqCompNum: int = 0
    ZoneEqSubCompNum: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


@dataclass
class ConnectZoneSubSubComp:
    ZoneEqListNum: int = 0
    ZoneEqCompNum: int = 0
    ZoneEqSubCompNum: int = 0
    ZoneEqSubSubCompNum: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


@dataclass
class ConnectAirSysComp:
    AirLoopNum: int = 0
    AirLoopBranch: int = 0
    AirLoopComp: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


@dataclass
class ConnectAirSysSubComp:
    AirLoopNum: int = 0
    AirLoopBranch: int = 0
    AirLoopComp: int = 0
    AirLoopSubComp: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


@dataclass
class ConnectAirSysSubSubComp:
    AirLoopNum: int = 0
    AirLoopBranch: int = 0
    AirLoopComp: int = 0
    AirLoopSubComp: int = 0
    AirLoopSubSubComp: int = 0
    PlantLoopType: int = 0
    PlantLoopNum: int = 0
    PlantLoopBranch: int = 0
    PlantLoopComp: int = 0
    FirstDemandSidePtr: int = 0
    LastDemandSidePtr: int = 0


def calc_fan_design_heat_gain(state: Any, data_fan_index: int, des_vol_flow: float) -> float:
    if data_fan_index <= 0 or des_vol_flow == 0.0:
        return 0.0
    
    return state.dataFans.fans[data_fan_index - 1].getDesignHeatGain(state, des_vol_flow)


class AirSystemsData(BaseGlobalStruct):
    def __init__(self) -> None:
        self.PrimaryAirSystems: List[DefinePrimaryAirSystem] = []
        self.DemandSideConnect: List[ConnectionPoint] = []
        self.ZoneCompToPlant: List[ConnectZoneComp] = []
        self.ZoneSubCompToPlant: List[ConnectZoneSubComp] = []
        self.ZoneSubSubCompToPlant: List[ConnectZoneSubSubComp] = []
        self.AirSysCompToPlant: List[ConnectAirSysComp] = []
        self.AirSysSubCompToPlant: List[ConnectAirSysSubComp] = []
        self.AirSysSubSubCompToPlant: List[ConnectAirSysSubSubComp] = []

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.__init__()
