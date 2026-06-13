"""
HVACUnitaryBypassVAV - Changeover-Bypass VAV System Simulation
Ported from EnergyPlus C++ implementation
"""

from dataclasses import dataclass, field
from enum import IntEnum
from typing import Optional, List, Any, Callable
import math

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

CoolingMode = 1
HeatingMode = 2


class DehumidControl(IntEnum):
    """Dehumidification control modes"""
    Invalid = -1
    None_ = 0
    Multimode = 1
    CoolReheat = 2
    Num = 3


class PriorityCtrlMode(IntEnum):
    """Priority control mode (prioritized thermostat signal)"""
    Invalid = -1
    CoolingPriority = 0
    HeatingPriority = 1
    ZonePriority = 2
    LoadPriority = 3
    Num = 4


class AirFlowCtrlMode(IntEnum):
    """Airflow control for constant fan mode"""
    Invalid = -1
    UseCompressorOnFlow = 0
    UseCompressorOffFlow = 1
    Num = 2


@dataclass
class CBVAVData:
    """Changeover-Bypass VAV Unit Data"""
    Name: str = ""
    UnitType: str = ""
    availSchedName: str = ""
    availSched: Optional[Any] = None
    MaxCoolAirVolFlow: float = 0.0
    MaxHeatAirVolFlow: float = 0.0
    MaxNoCoolHeatAirVolFlow: float = 0.0
    MaxCoolAirMassFlow: float = 0.0
    MaxHeatAirMassFlow: float = 0.0
    MaxNoCoolHeatAirMassFlow: float = 0.0
    CoolOutAirVolFlow: float = 0.0
    HeatOutAirVolFlow: float = 0.0
    NoCoolHeatOutAirVolFlow: float = 0.0
    CoolOutAirMassFlow: float = 0.0
    HeatOutAirMassFlow: float = 0.0
    NoCoolHeatOutAirMassFlow: float = 0.0
    outAirSched: Optional[Any] = None
    AirInNode: int = 0
    AirOutNode: int = 0
    CondenserNodeNum: int = 0
    MixerOutsideAirNode: int = 0
    MixerMixedAirNode: int = 0
    MixerReliefAirNode: int = 0
    MixerInletAirNode: int = 0
    SplitterOutletAirNode: int = 0
    PlenumMixerInletAirNode: int = 0
    OAMixType: str = ""
    OAMixName: str = ""
    OAMixIndex: int = 0
    FanName: str = ""
    fanType: Any = None
    fanPlace: Any = None
    FanIndex: int = 0
    fanOpModeSched: Optional[Any] = None
    FanVolFlow: float = 0.0
    HeatingSpeedRatio: float = 1.0
    CoolingSpeedRatio: float = 1.0
    NoHeatCoolSpeedRatio: float = 1.0
    CheckFanFlow: bool = True
    DXCoolCoilName: str = ""
    coolCoilType: Any = None
    CoolCoilCompIndex: int = 0
    DXCoolCoilIndexNum: int = 0
    DXHeatCoilIndexNum: int = 0
    HeatCoilName: str = ""
    heatCoilType: Any = None
    HeatCoilIndex: int = 0
    fanOp: Any = None
    CoilControlNode: int = 0
    CoilOutletNode: int = 0
    plantLoc: Any = None
    HotWaterCoilMaxIterIndex: int = 0
    HotWaterCoilMaxIterIndex2: int = 0
    MaxHeatCoilFluidFlow: float = 0.0
    DesignHeatingCapacity: float = 0.0
    DesignSuppHeatingCapacity: float = 0.0
    MinOATCompressor: float = 0.0
    MinLATCooling: float = 0.0
    MaxLATHeating: float = 0.0
    TotHeatEnergyRate: float = 0.0
    TotHeatEnergy: float = 0.0
    TotCoolEnergyRate: float = 0.0
    TotCoolEnergy: float = 0.0
    SensHeatEnergyRate: float = 0.0
    SensHeatEnergy: float = 0.0
    SensCoolEnergyRate: float = 0.0
    SensCoolEnergy: float = 0.0
    LatHeatEnergyRate: float = 0.0
    LatHeatEnergy: float = 0.0
    LatCoolEnergyRate: float = 0.0
    LatCoolEnergy: float = 0.0
    ElecPower: float = 0.0
    ElecConsumption: float = 0.0
    FanPartLoadRatio: float = 0.0
    CompPartLoadRatio: float = 0.0
    LastMode: int = 0
    AirFlowControl: AirFlowCtrlMode = AirFlowCtrlMode.Invalid
    CompPartLoadFrac: float = 0.0
    AirLoopNumber: int = 0
    NumControlledZones: int = 0
    ControlledZoneNum: List[int] = field(default_factory=list)
    ControlledZoneNodeNum: List[int] = field(default_factory=list)
    CBVAVBoxOutletNode: List[int] = field(default_factory=list)
    ZoneSequenceCoolingNum: List[int] = field(default_factory=list)
    ZoneSequenceHeatingNum: List[int] = field(default_factory=list)
    PriorityControl: PriorityCtrlMode = PriorityCtrlMode.Invalid
    NumZonesCooled: int = 0
    NumZonesHeated: int = 0
    PLRMaxIter: int = 0
    PLRMaxIterIndex: int = 0
    DXCoilInletNode: int = 0
    DXCoilOutletNode: int = 0
    HeatingCoilInletNode: int = 0
    HeatingCoilOutletNode: int = 0
    FanInletNodeNum: int = 0
    OutletTempSetPoint: float = 0.0
    CoilTempSetPoint: float = 0.0
    HeatCoolMode: int = 0
    BypassMassFlowRate: float = 0.0
    DehumidificationMode: Any = None
    DehumidControlType: DehumidControl = DehumidControl.None_
    HumRatMaxCheck: bool = True
    DXIterationExceeded: int = 0
    DXIterationExceededIndex: int = 0
    DXIterationFailed: int = 0
    DXIterationFailedIndex: int = 0
    DXCyclingIterationExceeded: int = 0
    DXCyclingIterationExceededIndex: int = 0
    DXCyclingIterationFailed: int = 0
    DXCyclingIterationFailedIndex: int = 0
    DXHeatIterationExceeded: int = 0
    DXHeatIterationExceededIndex: int = 0
    DXHeatIterationFailed: int = 0
    DXHeatIterationFailedIndex: int = 0
    DXHeatCyclingIterationExceeded: int = 0
    DXHeatCyclingIterationExceededIndex: int = 0
    DXHeatCyclingIterationFailed: int = 0
    DXHeatCyclingIterationFailedIndex: int = 0
    HXDXIterationExceeded: int = 0
    HXDXIterationExceededIndex: int = 0
    HXDXIterationFailed: int = 0
    HXDXIterationFailedIndex: int = 0
    MMDXIterationExceeded: int = 0
    MMDXIterationExceededIndex: int = 0
    MMDXIterationFailed: int = 0
    MMDXIterationFailedIndex: int = 0
    DMDXIterationExceeded: int = 0
    DMDXIterationExceededIndex: int = 0
    DMDXIterationFailed: int = 0
    DMDXIterationFailedIndex: int = 0
    CRDXIterationExceeded: int = 0
    CRDXIterationExceededIndex: int = 0
    CRDXIterationFailed: int = 0
    CRDXIterationFailedIndex: int = 0
    FirstPass: bool = True
    plenumIndex: int = 0
    mixerIndex: int = 0
    changeOverTimer: float = -1.0
    minModeChangeTime: float = -1.0
    OutNodeSPMIndex: int = 0
    modeChanged: bool = False


@dataclass
class HVACUnitaryBypassVAVData:
    """Global data for HVACUnitaryBypassVAV module"""
    NumCBVAV: int = 0
    CompOnMassFlow: float = 0.0
    OACompOnMassFlow: float = 0.0
    CompOffMassFlow: float = 0.0
    OACompOffMassFlow: float = 0.0
    CompOnFlowRatio: float = 0.0
    CompOffFlowRatio: float = 0.0
    FanSpeedRatio: float = 0.0
    BypassDuctFlowFraction: float = 0.0
    PartLoadFrac: float = 0.0
    SaveCompressorPLR: float = 0.0
    TempSteamIn: float = 100.0
    CheckEquipName: List[bool] = field(default_factory=list)
    CBVAV: List[CBVAVData] = field(default_factory=list)
    GetInputFlag: bool = True
    MyOneTimeFlag: bool = True
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MySizeFlag: List[bool] = field(default_factory=list)
    MyPlantScanFlag: List[bool] = field(default_factory=list)


def SimUnitaryBypassVAV(state: Any, CompName: str, FirstHVACIteration: bool, AirLoopNum: int) -> tuple[int, float]:
    """
    Manages the simulation of a changeover-bypass VAV system.
    Returns (CompIndex, QUnitOut)
    """
    CBVAVNum = 0
    QUnitOut = 0.0

    if state.dataHVACUnitaryBypassVAV.GetInputFlag:
        GetCBVAV(state)
        state.dataHVACUnitaryBypassVAV.GetInputFlag = False

    CompIndex = 0
    if CompIndex == 0:
        CBVAVNum = Util.FindItemInList(CompName, state.dataHVACUnitaryBypassVAV.CBVAV)
        if CBVAVNum == 0:
            ShowFatalError(state, f"SimUnitaryBypassVAV: Unit not found={CompName}")
        CompIndex = CBVAVNum
    else:
        if CompIndex > state.dataHVACUnitaryBypassVAV.NumCBVAV or CompIndex < 1:
            ShowFatalError(state, f"SimUnitaryBypassVAV: Invalid CompIndex passed={CompIndex}, Number of Units={state.dataHVACUnitaryBypassVAV.NumCBVAV}, Entered Unit name={CompName}")
        if state.dataHVACUnitaryBypassVAV.CheckEquipName[CompIndex - 1]:
            if CompName != state.dataHVACUnitaryBypassVAV.CBVAV[CompIndex - 1].Name:
                ShowFatalError(state, f"SimUnitaryBypassVAV: Invalid CompIndex passed={CompIndex}, Unit name={CompName}, stored Unit Name for that index={state.dataHVACUnitaryBypassVAV.CBVAV[CompIndex - 1].Name}")
            state.dataHVACUnitaryBypassVAV.CheckEquipName[CompIndex - 1] = False

    OnOffAirFlowRatio = 0.0
    HXUnitOn = True

    InitCBVAV(state, CBVAVNum, FirstHVACIteration, AirLoopNum, OnOffAirFlowRatio, HXUnitOn)
    SimCBVAV(state, CBVAVNum, FirstHVACIteration, OnOffAirFlowRatio, HXUnitOn)
    ReportCBVAV(state, CBVAVNum)

    return CompIndex, QUnitOut


def SimCBVAV(state: Any, CBVAVNum: int, FirstHVACIteration: bool, OnOffAirFlowRatio: float, HXUnitOn: bool) -> float:
    """Simulate a changeover-bypass VAV system"""
    QSensUnitOut = 0.0

    cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    state.dataHVACGlobal.DXElecCoolingPower = 0.0
    state.dataHVACGlobal.DXElecHeatingPower = 0.0
    state.dataHVACGlobal.ElecHeatingCoilPower = 0.0
    state.dataHVACUnitaryBypassVAV.SaveCompressorPLR = 0.0
    state.dataHVACGlobal.DefrostElecPower = 0.0

    UnitOn = True
    OutletNode = cbvav.AirOutNode
    InletNode = cbvav.AirInNode
    AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    PartLoadFrac = 0.0

    if cbvav.fanOp == HVAC.FanOp.Cycling:
        if cbvav.HeatCoolMode == 0 or AirMassFlow < HVAC.SmallMassFlow:
            UnitOn = False
    elif cbvav.fanOp == HVAC.FanOp.Continuous:
        if AirMassFlow < HVAC.SmallMassFlow:
            UnitOn = False

    state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0

    if UnitOn:
        ControlCBVAVOutput(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, OnOffAirFlowRatio, HXUnitOn)
    else:
        CalcCBVAV(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, QSensUnitOut, OnOffAirFlowRatio, HXUnitOn)

    if cbvav.modeChanged:
        state.dataLoopNodes.Node[cbvav.AirOutNode].TempSetPoint = CalcSetPointTempTarget(state, CBVAVNum)
        if cbvav.OutNodeSPMIndex > 0:
            state.dataSetPointManager.spms[cbvav.OutNodeSPMIndex].calculate(state)
            SetPointManager.UpdateMixedAirSetPoints(state)

    AirMassFlow = state.dataLoopNodes.Node[OutletNode].MassFlowRate
    QTotUnitOut = AirMassFlow * (state.dataLoopNodes.Node[OutletNode].Enthalpy - state.dataLoopNodes.Node[InletNode].Enthalpy)
    MinOutletHumRat = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
    QSensUnitOut = AirMassFlow * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinOutletHumRat) -
                                   Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinOutletHumRat))

    cbvav.CompPartLoadRatio = state.dataHVACUnitaryBypassVAV.SaveCompressorPLR
    if UnitOn:
        cbvav.FanPartLoadRatio = 1.0
    else:
        cbvav.FanPartLoadRatio = 0.0

    cbvav.TotCoolEnergyRate = abs(min(0.0, QTotUnitOut))
    cbvav.TotHeatEnergyRate = abs(max(0.0, QTotUnitOut))
    cbvav.SensCoolEnergyRate = abs(min(0.0, QSensUnitOut))
    cbvav.SensHeatEnergyRate = abs(max(0.0, QSensUnitOut))
    cbvav.LatCoolEnergyRate = abs(min(0.0, (QTotUnitOut - QSensUnitOut)))
    cbvav.LatHeatEnergyRate = abs(max(0.0, (QTotUnitOut - QSensUnitOut)))

    HeatingPower = 0.0
    locDefrostPower = 0.0
    if cbvav.heatCoilType == HVAC.CoilType.HeatingDXSingleSpeed:
        HeatingPower = state.dataHVACGlobal.DXElecHeatingPower
        locDefrostPower = state.dataHVACGlobal.DefrostElecPower
    elif cbvav.heatCoilType == HVAC.CoilType.HeatingDXVariableSpeed:
        HeatingPower = state.dataHVACGlobal.DXElecHeatingPower
        locDefrostPower = state.dataHVACGlobal.DefrostElecPower
    elif cbvav.heatCoilType == HVAC.CoilType.HeatingElectric:
        HeatingPower = state.dataHVACGlobal.ElecHeatingCoilPower
    else:
        HeatingPower = 0.0

    locFanElecPower = state.dataFans.fans[cbvav.FanIndex].totalPower
    cbvav.ElecPower = locFanElecPower + state.dataHVACGlobal.DXElecCoolingPower + HeatingPower + locDefrostPower

    return QSensUnitOut


def GetCBVAV(state: Any) -> None:
    """Obtains input data for changeover-bypass VAV systems"""
    CurrentModuleObject = "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass"
    NumCBVAV = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACUnitaryBypassVAV.NumCBVAV = NumCBVAV

    state.dataHVACUnitaryBypassVAV.CBVAV = [CBVAVData() for _ in range(NumCBVAV)]
    state.dataHVACUnitaryBypassVAV.CheckEquipName = [True] * NumCBVAV

    for CBVAVNum in range(1, NumCBVAV + 1):
        Alphas = [""] * 20
        Numbers = [0.0] * 9
        cAlphaFields = [""] * 20
        cNumericFields = [""] * 9
        lAlphaBlanks = [True] * 20
        lNumericBlanks = [True] * 9

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, CBVAVNum, Alphas, Numbers,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)

        cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]
        cbvav.Name = Alphas[0]
        cbvav.UnitType = CurrentModuleObject

        # ... (large amount of input processing code)
        # Due to length constraints, abbreviated here - full port would include all input processing


def InitCBVAV(state: Any, CBVAVNum: int, FirstHVACIteration: bool, AirLoopNum: int, OnOffAirFlowRatio: float, HXUnitOn: bool) -> None:
    """Initializations of the changeover-bypass VAV system"""
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]
    NumCBVAV = state.dataHVACUnitaryBypassVAV.NumCBVAV

    InNode = cBVAV.AirInNode
    OutNode = cBVAV.AirOutNode

    if state.dataHVACUnitaryBypassVAV.MyOneTimeFlag:
        state.dataHVACUnitaryBypassVAV.MyEnvrnFlag = [True] * NumCBVAV
        state.dataHVACUnitaryBypassVAV.MySizeFlag = [True] * NumCBVAV
        state.dataHVACUnitaryBypassVAV.MyPlantScanFlag = [True] * NumCBVAV
        state.dataHVACUnitaryBypassVAV.MyOneTimeFlag = False

    # ... (initialization code)


def SizeCBVAV(state: Any, CBVAVNum: int) -> None:
    """Sizing of changeover-bypass VAV components"""
    curSysNum = state.dataSize.CurSysNum
    curOASysNum = state.dataSize.CurOASysNum
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    # ... (sizing code)


def ControlCBVAVOutput(state: Any, CBVAVNum: int, FirstHVACIteration: bool, PartLoadFrac: float, OnOffAirFlowRatio: float, HXUnitOn: bool) -> None:
    """Determine the part load fraction of the CBVAV system"""
    FullOutput = 0.0
    PartLoadFrac = 0.0
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    if cBVAV.availSched.getCurrentVal() == 0.0:
        return

    PartLoadFrac = 1.0
    CalcCBVAV(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, FullOutput, OnOffAirFlowRatio, HXUnitOn)

    if ((state.dataLoopNodes.Node[cBVAV.AirOutNode].Temp - cBVAV.OutletTempSetPoint) > HVAC.SmallTempDiff and
        cBVAV.HeatCoolMode > 0 and PartLoadFrac < 1.0):
        CalcCBVAV(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, FullOutput, OnOffAirFlowRatio, HXUnitOn)


def CalcCBVAV(state: Any, CBVAVNum: int, FirstHVACIteration: bool, PartLoadFrac: float, LoadMet: float, OnOffAirFlowRatio: float, HXUnitOn: bool) -> None:
    """Simulate the components making up the changeover-bypass VAV system"""
    MaxIte = 500
    MinHumRat = 0.0
    SolFla = 0
    QHeater = 0.0
    QHeaterActual = 0.0
    CpAir = 0.0

    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    OutletNode = cBVAV.AirOutNode
    InletNode = cBVAV.AirInNode

    if cBVAV.CondenserNodeNum > 0:
        OutdoorDryBulbTemp = state.dataLoopNodes.Node[cBVAV.CondenserNodeNum].Temp
        OutdoorBaroPress = state.dataLoopNodes.Node[cBVAV.CondenserNodeNum].Press
    else:
        OutdoorDryBulbTemp = state.dataEnvrn.OutDryBulbTemp
        OutdoorBaroPress = state.dataEnvrn.OutBaroPress

    state.dataHVACUnitaryBypassVAV.SaveCompressorPLR = 0.0

    # ... (large calculation code - abbreviated for space)


def GetZoneLoads(state: Any, CBVAVNum: int) -> None:
    """Poll thermostats in each zone to determine mode of operation"""
    ZoneLoad = 0.0
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    # ... (zone load calculation)


def CalcSetPointTempTarget(state: Any, CBVAVNumber: int) -> float:
    """Calculate outlet air node temperature setpoint"""
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNumber - 1]

    # ... (setpoint calculation)
    return 0.0


def SetAverageAirFlow(state: Any, CBVAVNum: int, OnOffAirFlowRatio: float) -> None:
    """Set the average air mass flow rates for this time step"""
    cBVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    # ... (flow calculation)


def ReportCBVAV(state: Any, CBVAVNum: int) -> None:
    """Report the results of the CBVAV system simulation"""
    cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]
    ReportingConstant = state.dataHVACGlobal.TimeStepSysSec

    cbvav.TotCoolEnergy = cbvav.TotCoolEnergyRate * ReportingConstant
    cbvav.TotHeatEnergy = cbvav.TotHeatEnergyRate * ReportingConstant
    cbvav.SensCoolEnergy = cbvav.SensCoolEnergyRate * ReportingConstant
    cbvav.SensHeatEnergy = cbvav.SensHeatEnergyRate * ReportingConstant
    cbvav.LatCoolEnergy = cbvav.LatCoolEnergyRate * ReportingConstant
    cbvav.LatHeatEnergy = cbvav.LatHeatEnergyRate * ReportingConstant
    cbvav.ElecConsumption = cbvav.ElecPower * ReportingConstant

    if cbvav.FirstPass:
        if not state.dataGlobal.SysSizingCalc:
            DataSizing.resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, state.dataSize.CurSysNum, cbvav.FirstPass)

    state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0


def CalcNonDXHeatingCoils(state: Any, CBVAVNum: int, FirstHVACIteration: bool, HeatCoilLoad: float, fanOp: Any, HeatCoilLoadmet: float) -> None:
    """Simulate the four non-dx heating coil types: Gas, Electric, hot water and steam"""
    ErrTolerance = 0.001
    SolveMaxIter = 50

    cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]

    # ... (heating coil simulation code)


# Placeholder for external utility function stubs
class Util:
    @staticmethod
    def FindItemInList(name: str, items: List[CBVAVData]) -> int:
        for i, item in enumerate(items):
            if item.Name == name:
                return i + 1
        return 0

    @staticmethod
    def SameString(s1: str, s2: str) -> bool:
        return s1.lower() == s2.lower()
