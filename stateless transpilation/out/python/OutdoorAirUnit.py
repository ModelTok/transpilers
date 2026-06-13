from dataclasses import dataclass, field
from enum import IntEnum
from typing import Optional, List, Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object passed throughout
# - state.dataOutdoorAirUnit: OutdoorAirUnitData container
# - state.dataInputProcessing, state.dataIPShortCut: input processing
# - state.dataFans, state.dataEnvrn, state.dataHeatBal, state.dataLoopNodes: node/environment data
# - state.dataZoneTempPredictorCorrector, state.dataAvail, state.dataPlnt: zone/plant state
# - state.dataZoneEquip, state.dataSize, state.dataHVACGlobal: sizing/HVAC control
# - Psychrometrics: PsyHFnTdbW, PsyCpAirFnW
# - ScheduleManager.Schedule: schedule pointer objects
# - HVAC enums: FanType, FanPlace, FanOp, CompressorOp, UnitarySysType
# - DataPlant.PlantEquipmentType, PlantLocation: plant loop data
# - Utility functions: ShowFatalError, ShowSevereError, ShowWarningError, etc.
# - GlobalNames, Util: item finding, string utilities
# - ControlCompOutput: flow control callback
# - Component simulators: Fans, HeatingCoils, WaterCoils, SteamCoils, HeatRecovery, etc.


class CompType(IntEnum):
    Invalid = -1
    WaterCoil_Cooling = 0
    WaterCoil_SimpleHeat = 1
    SteamCoil_AirHeat = 2
    Coil_ElectricHeat = 3
    WaterCoil_DetailedCool = 4
    WaterCoil_CoolingHXAsst = 5
    Coil_GasHeat = 6
    DXSystem = 7
    HeatXchngrFP = 8
    HeatXchngrSL = 9
    Desiccant = 10
    DXHeatPumpSystem = 11
    UnitarySystemModel = 12
    Num = 13


COMP_TYPE_NAMES = [
    "Coil:Cooling:Water",
    "Coil:Heating:Water",
    "Coil:Heating:Steam",
    "Coil:Heating:Electric",
    "Coil:Cooling:Water:DetailedGeometry",
    "CoilSystem:Cooling:Water:HeatExchangerAssisted",
    "Coil:Heating:Fuel",
    "CoilSystem:Cooling:DX",
    "HeatExchanger:AirToAir:FlatPlate",
    "HeatExchanger:AirToAir:SensibleAndLatent",
    "Dehumidifier:Desiccant:NoFans",
    "CoilSystem:Heating:DX",
    "AirLoopHVAC:UnitarySystem",
]

COMP_TYPE_NAMES_UC = [
    "COIL:COOLING:WATER",
    "COIL:HEATING:WATER",
    "COIL:HEATING:STEAM",
    "COIL:HEATING:ELECTRIC",
    "COIL:COOLING:WATER:DETAILEDGEOMETRY",
    "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED",
    "COIL:HEATING:FUEL",
    "COILSYSTEM:COOLING:DX",
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT",
    "DEHUMIDIFIER:DESICCANT:NOFANS",
    "COILSYSTEM:HEATING:DX",
    "AIRLOOPHVAC:UNITARYSYSTEM",
]


class OAUnitCtrlType(IntEnum):
    Invalid = -1
    Neutral = 0
    Unconditioned = 1
    Temperature = 2
    Num = 3


class Operation(IntEnum):
    Invalid = -1
    HeatingMode = 0
    CoolingMode = 1
    NeutralMode = 2
    Num = 3


@dataclass
class OAEquipList:
    ComponentName: str = ""
    Type: CompType = CompType.Invalid
    ComponentIndex: int = 0
    compPointer: Optional[object] = None
    CoilAirInletNode: int = 0
    CoilAirOutletNode: int = 0
    CoilWaterInletNode: int = 0
    CoilWaterOutletNode: int = 0
    CoilType: int = 0
    plantLoc: object = field(default_factory=dict)
    FluidIndex: int = 0
    MaxVolWaterFlow: float = 0.0
    MaxWaterMassFlow: float = 0.0
    MinVolWaterFlow: float = 0.0
    MinWaterMassFlow: float = 0.0
    FirstPass: bool = True


@dataclass
class OAUnitData:
    Name: str = ""
    availSched: Optional[object] = None
    ZoneName: str = ""
    ZonePtr: int = 0
    ZoneNodeNum: int = 0
    UnitControlType: str = ""
    controlType: OAUnitCtrlType = OAUnitCtrlType.Invalid
    AirInletNode: int = 0
    AirOutletNode: int = 0
    SFanName: str = ""
    SFan_Index: int = 0
    supFanType: int = -1
    supFanAvailSched: Optional[object] = None
    supFanPlace: int = -1
    FanCorTemp: float = 0.0
    FanEffect: bool = False
    SFanOutletNode: int = 0
    ExtFanName: str = ""
    ExtFan_Index: int = 0
    extFanType: int = -1
    extFanAvailSched: Optional[object] = None
    ExtFan: bool = False
    outAirSched: Optional[object] = None
    OutsideAirNode: int = 0
    OutAirVolFlow: float = 0.0
    OutAirMassFlow: float = 0.0
    ExtAirVolFlow: float = 0.0
    ExtAirMassFlow: float = 0.0
    extAirSched: Optional[object] = None
    SMaxAirMassFlow: float = 0.0
    EMaxAirMassFlow: float = 0.0
    SFanMaxAirVolFlow: float = 0.0
    EFanMaxAirVolFlow: float = 0.0
    hiCtrlTempSched: Optional[object] = None
    loCtrlTempSched: Optional[object] = None
    OperatingMode: Operation = Operation.Invalid
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    AirMassFlow: float = 0.0
    FlowError: bool = False
    NumComponents: int = 0
    ComponentListName: str = ""
    CompOutSetTemp: float = 0.0
    availStatus: int = 0
    AvailManagerListName: str = ""
    OAEquip: List[OAEquipList] = field(default_factory=list)
    TotCoolingRate: float = 0.0
    TotCoolingEnergy: float = 0.0
    SensCoolingRate: float = 0.0
    SensCoolingEnergy: float = 0.0
    LatCoolingRate: float = 0.0
    LatCoolingEnergy: float = 0.0
    ElecFanRate: float = 0.0
    ElecFanEnergy: float = 0.0
    SensHeatingEnergy: float = 0.0
    SensHeatingRate: float = 0.0
    LatHeatingEnergy: float = 0.0
    LatHeatingRate: float = 0.0
    TotHeatingEnergy: float = 0.0
    TotHeatingRate: float = 0.0
    FirstPass: bool = True


@dataclass
class OutdoorAirUnitData:
    NumOfOAUnits: int = 0
    OAMassFlowRate: float = 0.0
    MyOneTimeErrorFlag: List[bool] = field(default_factory=list)
    GetOutdoorAirUnitInputFlag: bool = True
    MySizeFlag: List[bool] = field(default_factory=list)
    CheckEquipName: List[bool] = field(default_factory=list)
    OutAirUnit: List[OAUnitData] = field(default_factory=list)
    MyOneTimeFlag: bool = True
    ZoneEquipmentListChecked: bool = False
    SupplyFanUniqueNames: set = field(default_factory=set)
    ExhaustFanUniqueNames: set = field(default_factory=set)
    ComponentListUniqueNames: set = field(default_factory=set)
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MyPlantScanFlag: List[bool] = field(default_factory=list)
    MyZoneEqFlag: List[bool] = field(default_factory=list)
    HeatActive: bool = False
    CoolActive: bool = False


ZONE_HVAC_OA_UNIT = "ZoneHVAC:OutdoorAirUnit"
ZONE_HVAC_EQ_LIST = "ZoneHVAC:OutdoorAirUnit:EquipmentList"


def SimOutdoorAirUnit(state, CompName, ZoneNum, FirstHVACIteration):
    OAUnitNum = 0
    
    if state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        GetOutdoorAirUnitInputs(state)
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
    
    if CompIndex == 0:
        OAUnitNum = Util.FindItemInList(CompName, [u.Name for u in state.dataOutdoorAirUnit.OutAirUnit])
        if OAUnitNum == 0:
            raise FatalError(f"ZoneHVAC:OutdoorAirUnit not found={CompName}")
        return OAUnitNum, 0.0, 0.0
    else:
        OAUnitNum = CompIndex
        if OAUnitNum > state.dataOutdoorAirUnit.NumOfOAUnits or OAUnitNum < 1:
            raise FatalError(f"SimOutdoorAirUnit: Invalid CompIndex passed={OAUnitNum}")
        if state.dataOutdoorAirUnit.CheckEquipName[OAUnitNum - 1]:
            if CompName != state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].Name:
                raise FatalError(f"SimOutdoorAirUnit: Invalid CompIndex passed={OAUnitNum}")
            state.dataOutdoorAirUnit.CheckEquipName[OAUnitNum - 1] = False
    
    state.dataSize.ZoneEqOutdoorAirUnit = True
    
    if state.dataGlobal.ZoneSizingCalc or state.dataGlobal.SysSizingCalc:
        return OAUnitNum, 0.0, 0.0
    
    InitOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration)
    PowerMet, LatOutputProvided = CalcOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration)
    ReportOutdoorAirUnit(state, OAUnitNum)
    
    state.dataSize.ZoneEqOutdoorAirUnit = False
    
    return OAUnitNum, PowerMet, LatOutputProvided


def GetOutdoorAirUnitInputs(state):
    if not state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        return
    
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, ZONE_HVAC_OA_UNIT)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, ZONE_HVAC_EQ_LIST)
    
    state.dataOutdoorAirUnit.NumOfOAUnits = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ZONE_HVAC_OA_UNIT)
    
    state.dataOutdoorAirUnit.OutAirUnit = [OAUnitData() for _ in range(state.dataOutdoorAirUnit.NumOfOAUnits)]
    state.dataOutdoorAirUnit.MyOneTimeErrorFlag = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
    state.dataOutdoorAirUnit.CheckEquipName = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
    
    for OAUnitNum in range(state.dataOutdoorAirUnit.NumOfOAUnits):
        thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum]
        
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ZONE_HVAC_OA_UNIT, OAUnitNum + 1)
        
        thisOutAirUnit.Name = state.dataIPShortCut.cAlphaArgs[0]
        thisOutAirUnit.ZoneName = state.dataIPShortCut.cAlphaArgs[2]
        thisOutAirUnit.OutAirVolFlow = 0.0
        thisOutAirUnit.ExtAirVolFlow = 0.0
        thisOutAirUnit.NumComponents = 0
    
    state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False


def InitOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    
    if state.dataOutdoorAirUnit.MyOneTimeFlag:
        state.dataOutdoorAirUnit.MyEnvrnFlag = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
        state.dataOutdoorAirUnit.MySizeFlag = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
        state.dataOutdoorAirUnit.MyPlantScanFlag = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
        state.dataOutdoorAirUnit.MyZoneEqFlag = [True] * state.dataOutdoorAirUnit.NumOfOAUnits
        state.dataOutdoorAirUnit.MyOneTimeFlag = False
    
    if not state.dataGlobal.SysSizingCalc and state.dataOutdoorAirUnit.MySizeFlag[OAUnitNum - 1]:
        SizeOutdoorAirUnit(state, OAUnitNum)
        state.dataOutdoorAirUnit.MySizeFlag[OAUnitNum - 1] = False


def SizeOutdoorAirUnit(state, OAUnitNum):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    pass


def CalcOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    
    AirMassFlow = 0.0
    QUnitOut = 0.0
    LatentOutput = 0.0
    
    thisOutAirUnit.TotHeatingRate = 0.0
    thisOutAirUnit.SensHeatingRate = 0.0
    thisOutAirUnit.LatHeatingRate = 0.0
    thisOutAirUnit.TotCoolingRate = 0.0
    thisOutAirUnit.SensCoolingRate = 0.0
    thisOutAirUnit.LatCoolingRate = 0.0
    
    PowerMet = QUnitOut
    LatOutputProvided = LatentOutput
    
    return PowerMet, LatOutputProvided


def SimZoneOutAirUnitComps(state, OAUnitNum, FirstHVACIteration):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    for EquipNum in range(thisOutAirUnit.NumComponents):
        thisOAEquip = thisOutAirUnit.OAEquip[EquipNum]
        SimOutdoorAirEquipComps(state, OAUnitNum, COMP_TYPE_NAMES[int(thisOAEquip.Type)],
                               thisOAEquip.ComponentName, EquipNum + 1, thisOAEquip.Type,
                               FirstHVACIteration, thisOAEquip.ComponentIndex, True)


def SimOutdoorAirEquipComps(state, OAUnitNum, EquipType, EquipName, EquipNum, CompTypeNum, FirstHVACIteration, CompIndex, Sim):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    thisOAEquip = thisOutAirUnit.OAEquip[EquipNum - 1]
    
    if not Sim:
        return
    
    if thisOAEquip.Type == CompType.HeatXchngrFP or thisOAEquip.Type == CompType.HeatXchngrSL:
        pass
    elif thisOAEquip.Type == CompType.Desiccant:
        pass
    elif thisOAEquip.Type == CompType.WaterCoil_SimpleHeat:
        pass
    elif thisOAEquip.Type == CompType.WaterCoil_Cooling:
        pass


def CalcOAUnitCoilComps(state, CompNum, FirstHVACIteration, EquipIndex):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[CompNum - 1]
    LoadMet = 0.0
    return LoadMet


def ReportOutdoorAirUnit(state, OAUnitNum):
    thisOutAirUnit = state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1]
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    thisOutAirUnit.TotHeatingEnergy = thisOutAirUnit.TotHeatingRate * TimeStepSysSec
    thisOutAirUnit.SensHeatingEnergy = thisOutAirUnit.SensHeatingRate * TimeStepSysSec
    thisOutAirUnit.LatHeatingEnergy = thisOutAirUnit.LatHeatingRate * TimeStepSysSec
    thisOutAirUnit.SensCoolingEnergy = thisOutAirUnit.SensCoolingRate * TimeStepSysSec
    thisOutAirUnit.LatCoolingEnergy = thisOutAirUnit.LatCoolingRate * TimeStepSysSec
    thisOutAirUnit.TotCoolingEnergy = thisOutAirUnit.TotCoolingRate * TimeStepSysSec
    thisOutAirUnit.ElecFanEnergy = thisOutAirUnit.ElecFanRate * TimeStepSysSec


def GetOutdoorAirUnitOutAirNode(state, OAUnitNum):
    if state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        GetOutdoorAirUnitInputs(state)
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
    
    if OAUnitNum > 0 and OAUnitNum <= state.dataOutdoorAirUnit.NumOfOAUnits:
        return state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OutsideAirNode
    return 0


def GetOutdoorAirUnitZoneInletNode(state, OAUnitNum):
    if state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        GetOutdoorAirUnitInputs(state)
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
    
    if OAUnitNum > 0 and OAUnitNum <= state.dataOutdoorAirUnit.NumOfOAUnits:
        return state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].AirOutletNode
    return 0


def GetOutdoorAirUnitReturnAirNode(state, OAUnitNum):
    if state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        GetOutdoorAirUnitInputs(state)
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
    
    if OAUnitNum > 0 and OAUnitNum <= state.dataOutdoorAirUnit.NumOfOAUnits:
        return state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].AirInletNode
    return 0


def getOutdoorAirUnitEqIndex(state, EquipName):
    if state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag:
        GetOutdoorAirUnitInputs(state)
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
    
    for OAUnitNum in range(state.dataOutdoorAirUnit.NumOfOAUnits):
        if state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum].Name == EquipName:
            return OAUnitNum + 1
    return 0
