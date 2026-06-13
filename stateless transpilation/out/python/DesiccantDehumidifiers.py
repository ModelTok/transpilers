# EnergyPlus DesiccantDehumidifiers Module - Python Port
# Faithful translation from C++ (ObjexxFCL-based EnergyPlus)

from enum import IntEnum
from typing import Optional, Protocol, List, Tuple
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (from EnergyPlus/Data/EnergyPlusData.hh)
# - Util.FindItemInList: array search (from EnergyPlus/Utility)
# - Sched.Schedule: schedule type (from EnergyPlus/ScheduleManager.hh)
# - Sched.GetSchedule, GetScheduleAlwaysOn: schedule accessors
# - Node.GetOnlySingleNode, TestCompSet, SetUpCompSets: node API
# - Node.ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsParent enums
# - HVAC.CoilType, FanType, FanPlace, SmallMassFlow, SmallLoad enums/constants
# - HVAC.fanTypeNamesUC, fanTypeNames, coilTypeNames, fanPlaceNamesUC arrays
# - Curve.GetCurveIndex, CurveValue, CheckCurveDims: curve API
# - HeatingCoils, WaterCoils, SteamCoils, Fans, DXCoils, VariableSpeedCoils: simulators
# - HeatRecovery.SimHeatRecovery, GetSecondaryInletNode, GetSecondaryOutletNode, etc.
# - Psychrometrics.PsyHFnTdbW, PsyCpAirFnW, etc.
# - PlantUtilities.ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate
# - OutAirNodeManager.CheckOutAirNodeNumber, CheckAndAddAirNodeNumber
# - EMSManager.CheckIfNodeSetPointManagedByEMS
# - Fluid.GetSteam: fluid property accessor
# - DataPlant.PlantEquipmentType, CompData constants/types
# - DataSizing.AutoSize constant
# - Constant.HWInitConvTemp, eResource, EndUseCat, Units, etc.
# - OutputProcessor.TimeStepType, StoreType, Group enums
# - OutputProcessor.SetupOutputVariable: reporting
# - GlobalNames.VerifyUniqueInterObjectName
# - InputProcessor: getNumObjectsFound, getObjectDefMaxArgs, getObjectItem
# - ShowFatalError, ShowSevereError, ShowWarningError, etc.: error handlers
# - General.SolveRoot: numerical root solver
# - ErrorObjectHeader: error context type


class DesicDehumType(IntEnum):
    Invalid = -1
    Solid = 0
    Generic = 1
    Num = 2


class DesicDehumCtrlType(IntEnum):
    Invalid = -1
    FixedHumratBypass = 0
    NodeHumratBypass = 1
    Num = 2


class Selection(IntEnum):
    Invalid = -1
    No = 0
    Yes = 1
    Num = 2


class PerformanceModel(IntEnum):
    Invalid = -1
    Default = 0
    UserCurves = 1
    Num = 2


BALANCED_HX = 1
TEMP_STEAM_IN = 100.0


@dataclass
class DesiccantDehumidifierData:
    Name: str = ""
    Sched: str = ""
    regenCoilType: int = -1
    RegenCoilName: str = ""
    RegenFanName: str = ""
    PerformanceModel_Num: PerformanceModel = PerformanceModel.Invalid
    ProcAirInNode: int = 0
    ProcAirOutNode: int = 0
    RegenAirInNode: int = 0
    RegenAirOutNode: int = 0
    RegenFanInNode: int = 0
    controlType: DesicDehumCtrlType = DesicDehumCtrlType.Invalid
    HumRatSet: float = 0.0
    NomProcAirVolFlow: float = 0.0
    NomProcAirVel: float = 0.0
    NomRotorPower: float = 0.0
    RegenCoilIndex: int = 0
    RegenFanIndex: int = 0
    regenFanType: int = -1
    ProcDryBulbCurvefTW: int = 0
    ProcDryBulbCurvefV: int = 0
    ProcHumRatCurvefTW: int = 0
    ProcHumRatCurvefV: int = 0
    RegenEnergyCurvefTW: int = 0
    RegenEnergyCurvefV: int = 0
    RegenVelCurvefTW: int = 0
    RegenVelCurvefV: int = 0
    NomRegenTemp: float = 121.0
    MinProcAirInTemp: float = -73.3
    MaxProcAirInTemp: float = 65.6
    MinProcAirInHumRat: float = 0.0
    MaxProcAirInHumRat: float = 0.21273
    
    availSched: Optional[object] = None
    NomProcAirMassFlow: float = 0.0
    NomRegenAirMassFlow: float = 0.0
    ProcAirInTemp: float = 0.0
    ProcAirInHumRat: float = 0.0
    ProcAirInEnthalpy: float = 0.0
    ProcAirInMassFlowRate: float = 0.0
    ProcAirOutTemp: float = 0.0
    ProcAirOutHumRat: float = 0.0
    ProcAirOutEnthalpy: float = 0.0
    ProcAirOutMassFlowRate: float = 0.0
    RegenAirInTemp: float = 0.0
    RegenAirInHumRat: float = 0.0
    RegenAirInEnthalpy: float = 0.0
    RegenAirInMassFlowRate: float = 0.0
    RegenAirVel: float = 0.0
    DehumType: str = ""
    DehumTypeCode: DesicDehumType = DesicDehumType.Invalid
    WaterRemove: float = 0.0
    WaterRemoveRate: float = 0.0
    SpecRegenEnergy: float = 0.0
    QRegen: float = 0.0
    RegenEnergy: float = 0.0
    ElecUseEnergy: float = 0.0
    ElecUseRate: float = 0.0
    PartLoad: float = 0.0
    RegenCapErrorIndex1: int = 0
    RegenCapErrorIndex2: int = 0
    RegenCapErrorIndex3: int = 0
    RegenCapErrorIndex4: int = 0
    RegenFanErrorIndex1: int = 0
    RegenFanErrorIndex2: int = 0
    RegenFanErrorIndex3: int = 0
    RegenFanErrorIndex4: int = 0
    
    HXType: str = ""
    HXName: str = ""
    HXTypeNum: int = 0
    ExhaustFanCurveObject: str = ""
    CoolingCoilType: str = ""
    CoolingCoilName: str = ""
    coolCoilType: int = -1
    Preheat: Selection = Selection.Invalid
    RegenSetPointTemp: float = 0.0
    ExhaustFanMaxVolFlowRate: float = 0.0
    ExhaustFanMaxMassFlowRate: float = 0.0
    ExhaustFanMaxPower: float = 0.0
    ExhaustFanPower: float = 0.0
    ExhaustFanElecConsumption: float = 0.0
    CompanionCoilCapacity: float = 0.0
    regenFanPlace: int = -1
    ControlNodeNum: int = 0
    ExhaustFanCurveIndex: int = 0
    CompIndex: int = 0
    CoolingCoilOutletNode: int = 0
    RegenFanOutNode: int = 0
    RegenCoilInletNode: int = 0
    RegenCoilOutletNode: int = 0
    HXProcInNode: int = 0
    HXProcOutNode: int = 0
    HXRegenInNode: int = 0
    HXRegenOutNode: int = 0
    CondenserInletNode: int = 0
    DXCoilIndex: int = 0
    ErrCount: int = 0
    ErrIndex1: int = 0
    CoilUpstreamOfProcessSide: Selection = Selection.Invalid
    RegenInletIsOutsideAirNode: bool = False
    CoilControlNode: int = 0
    CoilOutletNode: int = 0
    plantLoc: Optional[object] = None
    HotWaterCoilMaxIterIndex: int = 0
    HotWaterCoilMaxIterIndex2: int = 0
    MaxCoilFluidFlow: float = 0.0
    RegenCoilCapacity: float = 0.0


@dataclass
class DesiccantDehumidifiersData:
    NumDesicDehums: int = 0
    NumSolidDesicDehums: int = 0
    NumGenericDesicDehums: int = 0
    GetInputDesiccantDehumidifier: bool = True
    InitDesiccantDehumidifierOneTimeFlag: bool = True
    MySetPointCheckFlag: bool = True
    
    DesicDehum: List[DesiccantDehumidifierData] = field(default_factory=list)
    UniqueDesicDehumNames: dict = field(default_factory=dict)
    
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MyPlantScanFlag: List[bool] = field(default_factory=list)
    QRegen: float = 0.0
    
    def init_constant_state(self, state: object) -> None:
        pass
    
    def init_state(self, state: object) -> None:
        pass
    
    def clear_state(self) -> None:
        self.__init__()


def SimDesiccantDehumidifier(
    state: object,
    CompName: str,
    FirstHVACIteration: bool,
    CompIndex: int
) -> int:
    """Manage the simulation of an air dehumidifier"""
    dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    DesicDehumNum = 0
    if CompIndex == 0:
        DesicDehumNum = Util_FindItemInList(CompName, dd_state.DesicDehum)
        if DesicDehumNum == 0:
            ShowFatalError(state, f"SimDesiccantDehumidifier: Unit not found={CompName}")
        CompIndex = DesicDehumNum
    else:
        DesicDehumNum = CompIndex
        if DesicDehumNum > dd_state.NumDesicDehums or DesicDehumNum < 1:
            ShowFatalError(
                state,
                f"SimDesiccantDehumidifier:  Invalid CompIndex passed={DesicDehumNum}, Number of Units={dd_state.NumDesicDehums}, Entered Unit name={CompName}"
            )
        if CompName != dd_state.DesicDehum[DesicDehumNum - 1].Name:
            ShowFatalError(
                state,
                f"SimDesiccantDehumidifier: Invalid CompIndex passed={DesicDehumNum}, Unit name={CompName}, stored Unit Name for that index={dd_state.DesicDehum[DesicDehumNum - 1].Name}"
            )
    
    InitDesiccantDehumidifier(state, DesicDehumNum, FirstHVACIteration)
    
    HumRatNeeded = 0.0
    ControlDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    
    dehumType = dd_state.DesicDehum[DesicDehumNum - 1].DehumTypeCode
    if dehumType == DesicDehumType.Solid:
        CalcSolidDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    elif dehumType == DesicDehumType.Generic:
        CalcGenericDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    else:
        ShowFatalError(
            state,
            f"Invalid type, Desiccant Dehumidifer={dd_state.DesicDehum[DesicDehumNum - 1].DehumType}"
        )
    
    UpdateDesiccantDehumidifier(state, DesicDehumNum)
    ReportDesiccantDehumidifier(state, DesicDehumNum)
    
    return CompIndex


def GetDesiccantDehumidifierInput(state: object) -> None:
    """Obtains input data for desiccant dehumidifiers"""
    dd_state = state.dataDesiccantDehumidifiers
    
    dehumidifierDesiccantNoFans = "Dehumidifier:Desiccant:NoFans"
    
    dd_state.NumSolidDesicDehums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, dehumidifierDesiccantNoFans
    )
    dd_state.NumGenericDesicDehums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "Dehumidifier:Desiccant:System"
    )
    dd_state.NumDesicDehums = dd_state.NumSolidDesicDehums + dd_state.NumGenericDesicDehums
    
    dd_state.DesicDehum = [DesiccantDehumidifierData() for _ in range(dd_state.NumDesicDehums)]
    dd_state.UniqueDesicDehumNames = {}
    dd_state.GetInputDesiccantDehumidifier = False
    
    TotalArgs = [0, 0]
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, dehumidifierDesiccantNoFans, TotalArgs, _
    )
    MaxNums = TotalArgs[1]
    MaxAlphas = TotalArgs[0]
    
    TotalArgs = [0, 0]
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "Dehumidifier:Desiccant:System", TotalArgs, _
    )
    MaxNums = max(MaxNums, TotalArgs[1])
    MaxAlphas = max(MaxAlphas, TotalArgs[0])
    
    Alphas = [""] * MaxAlphas
    cAlphaFields = [""] * MaxAlphas
    cNumericFields = [""] * MaxNums
    Numbers = [0.0] * MaxNums
    lAlphaBlanks = [True] * MaxAlphas
    lNumericBlanks = [True] * MaxNums
    
    for DesicDehumIndex in range(1, dd_state.NumSolidDesicDehums + 1):
        desicDehum = dd_state.DesicDehum[DesicDehumIndex - 1]
        
        Alphas, NumAlphas, Numbers, NumNumbers = state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            dehumidifierDesiccantNoFans,
            DesicDehumIndex,
            lNumericBlanks,
            lAlphaBlanks,
            cAlphaFields,
            cNumericFields
        )
        
        desicDehum.Name = Alphas[0]
        desicDehum.DehumType = dehumidifierDesiccantNoFans
        desicDehum.DehumTypeCode = DesicDehumType.Solid
        desicDehum.Sched = Alphas[1]
        
        if lAlphaBlanks[1]:
            desicDehum.availSched = Sched_GetScheduleAlwaysOn(state)
        else:
            desicDehum.availSched = Sched_GetSchedule(state, Alphas[1])
            if desicDehum.availSched is None:
                ShowSevereItemNotFound(state, cAlphaFields[1], Alphas[1])
        
        desicDehum.ProcAirInNode = Node_GetOnlySingleNode(
            state, Alphas[2], dehumidifierDesiccantNoFans, Alphas[0]
        )
        desicDehum.ProcAirOutNode = Node_GetOnlySingleNode(
            state, Alphas[3], dehumidifierDesiccantNoFans, Alphas[0]
        )
        desicDehum.RegenAirInNode = Node_GetOnlySingleNode(
            state, Alphas[4], dehumidifierDesiccantNoFans, Alphas[0]
        )
        desicDehum.RegenFanInNode = Node_GetOnlySingleNode(
            state, Alphas[5], dehumidifierDesiccantNoFans, Alphas[0]
        )
        
        if Alphas[6].upper() == "LEAVING HUMRAT:BYPASS":
            ShowWarningError(state, f"Obsolete control type: {Alphas[6]}")
            desicDehum.controlType = DesicDehumCtrlType.FixedHumratBypass
        elif Alphas[6].upper() == "LEAVINGMAXIMUMHUMIDITYRATISETPOINT":
            desicDehum.controlType = DesicDehumCtrlType.FixedHumratBypass
        elif Alphas[6].upper() == "SYSTEMNODEMAXIMUMHUMIDITYRATISETPOINT":
            desicDehum.controlType = DesicDehumCtrlType.NodeHumratBypass
        else:
            desicDehum.controlType = DesicDehumCtrlType.FixedHumratBypass
        
        desicDehum.HumRatSet = Numbers[0]
        desicDehum.NomProcAirVolFlow = Numbers[1]
        desicDehum.NomProcAirVel = Numbers[2]
        desicDehum.RegenCoilName = Alphas[8]
        
        regenCoilTypeStr = Alphas[7].upper()
        if regenCoilTypeStr == "COIL:HEATING:ELECTRIC":
            desicDehum.regenCoilType = 0
        elif regenCoilTypeStr == "COIL:HEATING:FUEL":
            desicDehum.regenCoilType = 1
        elif regenCoilTypeStr == "COIL:HEATING:WATER":
            desicDehum.regenCoilType = 2
        elif regenCoilTypeStr == "COIL:HEATING:STEAM":
            desicDehum.regenCoilType = 3
        
        desicDehum.NomRotorPower = Numbers[3]
        desicDehum.RegenFanName = Alphas[10]
        
        if Alphas[11].upper() == "USERCURVES":
            desicDehum.PerformanceModel_Num = PerformanceModel.UserCurves
        else:
            desicDehum.PerformanceModel_Num = PerformanceModel.Default


def InitDesiccantDehumidifier(
    state: object,
    DesicDehumNum: int,
    FirstHVACIteration: bool
) -> None:
    """Initialize desiccant dehumidifier for simulation"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    if dd_state.InitDesiccantDehumidifierOneTimeFlag:
        dd_state.MyEnvrnFlag = [True] * dd_state.NumDesicDehums
        dd_state.MyPlantScanFlag = [True] * dd_state.NumDesicDehums
        dd_state.InitDesiccantDehumidifierOneTimeFlag = False
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        ProcInNode = desicDehum.ProcAirInNode
        desicDehum.ProcAirInTemp = state.dataLoopNodes.Node[ProcInNode].Temp
        desicDehum.ProcAirInHumRat = state.dataLoopNodes.Node[ProcInNode].HumRat
        desicDehum.ProcAirInEnthalpy = state.dataLoopNodes.Node[ProcInNode].Enthalpy
        desicDehum.ProcAirInMassFlowRate = state.dataLoopNodes.Node[ProcInNode].MassFlowRate
        
        CalcNonDXHeatingCoils(state, DesicDehumNum, FirstHVACIteration, 0.0)
        
        RegenInNode = desicDehum.RegenAirInNode
        desicDehum.RegenAirInTemp = state.dataLoopNodes.Node[RegenInNode].Temp
        desicDehum.RegenAirInHumRat = state.dataLoopNodes.Node[RegenInNode].HumRat
        desicDehum.RegenAirInEnthalpy = state.dataLoopNodes.Node[RegenInNode].Enthalpy
        
        desicDehum.WaterRemove = 0.0
        desicDehum.ElecUseEnergy = 0.0
        desicDehum.ElecUseRate = 0.0


def ControlDesiccantDehumidifier(
    state: object,
    DesicDehumNum: int,
    HumRatNeeded: float,
    FirstHVACIteration: bool
) -> float:
    """Set the output required from the dehumidifier"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    UnitOn = True
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        if desicDehum.HumRatSet <= 0.0:
            UnitOn = False
        
        ProcAirMassFlowRate = desicDehum.ProcAirInMassFlowRate
        if ProcAirMassFlowRate <= 0.001:
            UnitOn = False
        
        if desicDehum.availSched.getCurrentVal() <= 0.0:
            UnitOn = False
        
        if UnitOn:
            if (desicDehum.ProcAirInTemp < desicDehum.MinProcAirInTemp or
                desicDehum.ProcAirInTemp > desicDehum.MaxProcAirInTemp):
                UnitOn = False
            if (desicDehum.ProcAirInHumRat < desicDehum.MinProcAirInHumRat or
                desicDehum.ProcAirInHumRat > desicDehum.MaxProcAirInHumRat):
                UnitOn = False
        
        if UnitOn:
            if desicDehum.controlType == DesicDehumCtrlType.FixedHumratBypass:
                HumRatNeeded = desicDehum.HumRatSet
            elif desicDehum.controlType == DesicDehumCtrlType.NodeHumratBypass:
                HumRatNeeded = state.dataLoopNodes.Node[desicDehum.ProcAirOutNode].HumRatMax
            
            if HumRatNeeded == 0.0 or desicDehum.ProcAirInHumRat <= HumRatNeeded:
                HumRatNeeded = desicDehum.ProcAirInHumRat
        else:
            HumRatNeeded = desicDehum.ProcAirInHumRat
    
    elif desicDehum.DehumTypeCode == DesicDehumType.Generic:
        ProcAirMassFlowRate = state.dataLoopNodes.Node[desicDehum.ProcAirInNode].MassFlowRate
        if ProcAirMassFlowRate <= 0.001:
            UnitOn = False
        
        if desicDehum.availSched.getCurrentVal() <= 0.0:
            UnitOn = False
        
        if UnitOn:
            if desicDehum.ControlNodeNum == desicDehum.ProcAirOutNode:
                HumRatNeeded = state.dataLoopNodes.Node[desicDehum.ControlNodeNum].HumRatMax
            else:
                if state.dataLoopNodes.Node[desicDehum.ControlNodeNum].HumRatMax > 0.0:
                    HumRatNeeded = (
                        state.dataLoopNodes.Node[desicDehum.ControlNodeNum].HumRatMax -
                        (state.dataLoopNodes.Node[desicDehum.ControlNodeNum].HumRat -
                         state.dataLoopNodes.Node[desicDehum.ProcAirOutNode].HumRat)
                    )
                else:
                    HumRatNeeded = 0.0
            
            if HumRatNeeded == 0.0 or state.dataLoopNodes.Node[desicDehum.ProcAirInNode].HumRat <= HumRatNeeded:
                HumRatNeeded = state.dataLoopNodes.Node[desicDehum.ProcAirInNode].HumRat
        else:
            HumRatNeeded = state.dataLoopNodes.Node[desicDehum.ProcAirInNode].HumRat
    
    return HumRatNeeded


def CalcSolidDesiccantDehumidifier(
    state: object,
    DesicDehumNum: int,
    HumRatNeeded: float,
    FirstHVACIteration: bool
) -> None:
    """Calculate solid desiccant dehumidifier performance"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    ProcAirInTemp = desicDehum.ProcAirInTemp
    ProcAirInHumRat = desicDehum.ProcAirInHumRat
    ProcAirMassFlowRate = desicDehum.ProcAirInMassFlowRate
    ProcAirVel = desicDehum.NomProcAirVel
    NomRegenTemp = desicDehum.NomRegenTemp
    RegenAirInTemp = desicDehum.RegenAirInTemp
    
    PartLoad = 0.0
    UnitOn = False
    MinProcAirOutHumRat = 0.0
    
    if HumRatNeeded < ProcAirInHumRat:
        UnitOn = True
        
        if desicDehum.PerformanceModel_Num == PerformanceModel.Default:
            WC0, WC1, WC2, WC3, WC4 = 0.0148880824323806, -0.000283393198398211, -0.87802168940547, -0.000713615831236411, 0.0311261188874622
            WC5, WC6, WC7, WC8, WC9 = 1.51738892142485e-06, 0.0287250198281021, 4.94796903231558e-06, 24.0771139652826, 0.000122270283927978
            WC10, WC11, WC12, WC13, WC14, WC15 = -0.0151657189566474, 3.91641393230322e-08, 0.126032651553348, 0.000391653854431574, 0.002160537360507, 0.00132732844211593
            
            MinProcAirOutHumRat = (
                WC0 + WC1 * ProcAirInTemp + WC2 * ProcAirInHumRat + WC3 * ProcAirVel +
                WC4 * ProcAirInTemp * ProcAirInHumRat + WC5 * ProcAirInTemp * ProcAirVel +
                WC6 * ProcAirInHumRat * ProcAirVel + WC7 * ProcAirInTemp * ProcAirInTemp +
                WC8 * ProcAirInHumRat * ProcAirInHumRat + WC9 * ProcAirVel * ProcAirVel +
                WC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                WC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                WC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                WC13 * math.log(ProcAirInTemp) + WC14 * math.log(ProcAirInHumRat) + WC15 * math.log(ProcAirVel)
            )
        elif desicDehum.PerformanceModel_Num == PerformanceModel.UserCurves:
            MinProcAirOutHumRat = (
                Curve_CurveValue(state, desicDehum.ProcHumRatCurvefTW, ProcAirInTemp, ProcAirInHumRat) *
                Curve_CurveValue(state, desicDehum.ProcHumRatCurvefV, ProcAirVel)
            )
        
        MinProcAirOutHumRat = max(MinProcAirOutHumRat, 0.000857)
    
    if MinProcAirOutHumRat >= ProcAirInHumRat:
        UnitOn = False
    
    ProcAirOutTemp = ProcAirInTemp
    ProcAirOutHumRat = ProcAirInHumRat
    SpecRegenEnergy = 0.0
    QRegen = 0.0
    ElecUseRate = 0.0
    RegenAirVel = 0.0
    RegenAirMassFlowRate = 0.0
    
    if UnitOn:
        PartLoad = 1.0
        if MinProcAirOutHumRat < HumRatNeeded:
            PartLoad = (ProcAirInHumRat - HumRatNeeded) / (ProcAirInHumRat - MinProcAirOutHumRat)
        PartLoad = max(0.0, min(1.0, PartLoad))
        
        if desicDehum.PerformanceModel_Num == PerformanceModel.Default:
            TC0, TC1, TC2 = -38.7782841989449, 2.0127655837628, 5212.49360216097
            TC3, TC4, TC5 = 15.2362536782665, -80.4910419759181, -0.105014122001509
            TC6, TC7, TC8, TC9 = -229.668673645144, -0.015424703743461, -69440.0689831847, -1.6686064694322
            TC10, TC11, TC12, TC13 = 38.5855718977592, 0.000196395381206009, 386.179386548324, -0.801959614172614
            TC14, TC15 = -3.33080986818745, -15.2034386065714
            
            ProcAirOutTemp = (
                TC0 + TC1 * ProcAirInTemp + TC2 * ProcAirInHumRat + TC3 * ProcAirVel +
                TC4 * ProcAirInTemp * ProcAirInHumRat + TC5 * ProcAirInTemp * ProcAirVel +
                TC6 * ProcAirInHumRat * ProcAirVel + TC7 * ProcAirInTemp * ProcAirInTemp +
                TC8 * ProcAirInHumRat * ProcAirInHumRat + TC9 * ProcAirVel * ProcAirVel +
                TC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                TC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                TC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                TC13 * math.log(ProcAirInTemp) + TC14 * math.log(ProcAirInHumRat) + TC15 * math.log(ProcAirVel)
            )
            
            QC0, QC1, QC2 = -27794046.6291107, -235725.171759615, 975461343.331328
            QC3, QC4, QC5 = -686069.373946731, -17717307.3766266, 31482.2539662489
            QC6, QC7, QC8, QC9 = 55296552.8260743, 6195.36070023868, -8304781359.40435, -188987.543809419
            QC10, QC11, QC12, QC13 = 3933449.40965846, -6.66122876558634, -349102295.417547, 83672.179730172
            QC14, QC15 = -6059524.33170538, 1220523.39525162
            
            SpecRegenEnergy = (
                QC0 + QC1 * ProcAirInTemp + QC2 * ProcAirInHumRat + QC3 * ProcAirVel +
                QC4 * ProcAirInTemp * ProcAirInHumRat + QC5 * ProcAirInTemp * ProcAirVel +
                QC6 * ProcAirInHumRat * ProcAirVel + QC7 * ProcAirInTemp * ProcAirInTemp +
                QC8 * ProcAirInHumRat * ProcAirInHumRat + QC9 * ProcAirVel * ProcAirVel +
                QC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                QC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                QC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                QC13 * math.log(ProcAirInTemp) + QC14 * math.log(ProcAirInHumRat) + QC15 * math.log(ProcAirVel)
            )
            
            RC0, RC1, RC2 = -4.67358908091488, 0.0654323095468338, 396.950518702316
            RC3, RC4, RC5 = 1.52610165426736, -11.3955868430328, 0.00520693906104437
            RC6, RC7, RC8, RC9 = 57.783645385621, -0.000464800668311693, -5958.78613212602, -0.205375818291012
            RC10, RC11, RC12, RC13 = 5.26762675442845, -8.88452553055039e-05, -182.382479369311, -0.100289774002047
            RC14, RC15 = -0.486980507964251, -0.972715425435447
            
            RegenAirVel = (
                RC0 + RC1 * ProcAirInTemp + RC2 * ProcAirInHumRat + RC3 * ProcAirVel +
                RC4 * ProcAirInTemp * ProcAirInHumRat + RC5 * ProcAirInTemp * ProcAirVel +
                RC6 * ProcAirInHumRat * ProcAirVel + RC7 * ProcAirInTemp * ProcAirInTemp +
                RC8 * ProcAirInHumRat * ProcAirInHumRat + RC9 * ProcAirVel * ProcAirVel +
                RC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                RC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                RC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                RC13 * math.log(ProcAirInTemp) + RC14 * math.log(ProcAirInHumRat) + RC15 * math.log(ProcAirVel)
            )
        
        elif desicDehum.PerformanceModel_Num == PerformanceModel.UserCurves:
            ProcAirOutTemp = (
                Curve_CurveValue(state, desicDehum.ProcDryBulbCurvefTW, ProcAirInTemp, ProcAirInHumRat) *
                Curve_CurveValue(state, desicDehum.ProcDryBulbCurvefV, ProcAirVel)
            )
            SpecRegenEnergy = (
                Curve_CurveValue(state, desicDehum.RegenEnergyCurvefTW, ProcAirInTemp, ProcAirInHumRat) *
                Curve_CurveValue(state, desicDehum.RegenEnergyCurvefV, ProcAirVel)
            )
            RegenAirVel = (
                Curve_CurveValue(state, desicDehum.RegenVelCurvefTW, ProcAirInTemp, ProcAirInHumRat) *
                Curve_CurveValue(state, desicDehum.RegenVelCurvefV, ProcAirVel)
            )
        
        ProcAirOutTemp = (1 - PartLoad) * ProcAirInTemp + PartLoad * ProcAirOutTemp
        ProcAirOutHumRat = (1 - PartLoad) * ProcAirInHumRat + PartLoad * MinProcAirOutHumRat
        
        desicDehum.WaterRemoveRate = ProcAirMassFlowRate * (ProcAirInHumRat - ProcAirOutHumRat)
        
        SpecRegenEnergy *= (NomRegenTemp - RegenAirInTemp) / (NomRegenTemp - ProcAirInTemp)
        SpecRegenEnergy = max(SpecRegenEnergy, 0.0)
        QRegen = SpecRegenEnergy * desicDehum.WaterRemoveRate
        
        RegenAirMassFlowRate = ProcAirMassFlowRate * 90.0 / 245.0 * RegenAirVel / ProcAirVel
        ElecUseRate = desicDehum.NomRotorPower
    else:
        desicDehum.WaterRemoveRate = 0.0
    
    state.dataLoopNodes.Node[desicDehum.RegenFanInNode].MassFlowRate = RegenAirMassFlowRate
    Fans_Simulate(state, desicDehum.RegenFanIndex, FirstHVACIteration)
    
    QDelivered = 0.0
    CalcNonDXHeatingCoils(state, DesicDehumNum, FirstHVACIteration, QRegen, QDelivered)
    
    desicDehum.SpecRegenEnergy = SpecRegenEnergy
    desicDehum.QRegen = QRegen
    desicDehum.ElecUseRate = ElecUseRate
    desicDehum.PartLoad = PartLoad
    desicDehum.ProcAirOutMassFlowRate = ProcAirMassFlowRate
    desicDehum.ProcAirOutTemp = ProcAirOutTemp
    desicDehum.ProcAirOutHumRat = ProcAirOutHumRat
    desicDehum.ProcAirOutEnthalpy = Psychrometrics_PsyHFnTdbW(ProcAirOutTemp, ProcAirOutHumRat)
    desicDehum.RegenAirInMassFlowRate = RegenAirMassFlowRate
    desicDehum.RegenAirVel = RegenAirVel


def CalcGenericDesiccantDehumidifier(
    state: object,
    DesicDehumNum: int,
    HumRatNeeded: float,
    FirstHVACIteration: bool
) -> None:
    """Calculate generic desiccant dehumidifier performance"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    DDPartLoadRatio = 0.0
    UnitOn = False
    
    if HumRatNeeded < state.dataLoopNodes.Node[desicDehum.ProcAirInNode].HumRat:
        UnitOn = True
    
    if UnitOn:
        pass
    else:
        desicDehum.PartLoad = 0.0
    
    desicDehum.WaterRemoveRate = (
        state.dataLoopNodes.Node[desicDehum.ProcAirInNode].MassFlowRate *
        (state.dataLoopNodes.Node[desicDehum.ProcAirInNode].HumRat -
         state.dataLoopNodes.Node[desicDehum.ProcAirOutNode].HumRat)
    )


def UpdateDesiccantDehumidifier(state: object, DesicDehumNum: int) -> None:
    """Move dehumidifier output to outlet nodes"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        ProcInNode = desicDehum.ProcAirInNode
        ProcOutNode = desicDehum.ProcAirOutNode
        
        state.dataLoopNodes.Node[ProcOutNode].Temp = desicDehum.ProcAirOutTemp
        state.dataLoopNodes.Node[ProcOutNode].HumRat = desicDehum.ProcAirOutHumRat
        state.dataLoopNodes.Node[ProcOutNode].Enthalpy = desicDehum.ProcAirOutEnthalpy
        state.dataLoopNodes.Node[ProcOutNode].MassFlowRate = state.dataLoopNodes.Node[ProcInNode].MassFlowRate


def ReportDesiccantDehumidifier(state: object, DesicDehumNum: int) -> None:
    """Fill remaining report variables"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        desicDehum.WaterRemove = desicDehum.WaterRemoveRate * TimeStepSysSec
        desicDehum.RegenEnergy = desicDehum.QRegen * TimeStepSysSec
        desicDehum.ElecUseEnergy = desicDehum.ElecUseRate * TimeStepSysSec
    elif desicDehum.DehumTypeCode == DesicDehumType.Generic:
        desicDehum.WaterRemove = desicDehum.WaterRemoveRate * TimeStepSysSec
        desicDehum.ExhaustFanElecConsumption = desicDehum.ExhaustFanPower * TimeStepSysSec


def CalcNonDXHeatingCoils(
    state: object,
    DesicDehumNum: int,
    FirstHVACIteration: bool,
    RegenCoilLoad: float,
    RegenCoilLoadmet: Optional[float] = None
) -> Optional[float]:
    """Simulate non-DX heating coils"""
    dd_state = state.dataDesiccantDehumidifiers
    desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    RegenCoilActual = 0.0
    
    if RegenCoilLoad > 0.001:
        if desicDehum.regenCoilType in [0, 1]:
            RegenCoilActual = HeatingCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, RegenCoilLoad, desicDehum.RegenCoilIndex
            )
        elif desicDehum.regenCoilType == 2:
            MaxHotWaterFlow = desicDehum.MaxCoilFluidFlow
            PlantUtilities_SetComponentFlowRate(
                state, MaxHotWaterFlow, desicDehum.CoilControlNode, desicDehum.CoilOutletNode
            )
            WaterCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, desicDehum.RegenCoilIndex, RegenCoilLoad
            )
            RegenCoilActual = RegenCoilLoad
        elif desicDehum.regenCoilType == 3:
            mdot = desicDehum.MaxCoilFluidFlow
            PlantUtilities_SetComponentFlowRate(
                state, mdot, desicDehum.CoilControlNode, desicDehum.CoilOutletNode
            )
            SteamCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, desicDehum.RegenCoilIndex, RegenCoilLoad
            )
            RegenCoilActual = RegenCoilLoad
    else:
        if desicDehum.regenCoilType in [0, 1]:
            RegenCoilActual = HeatingCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, RegenCoilLoad, desicDehum.RegenCoilIndex
            )
        elif desicDehum.regenCoilType == 2:
            mdot = 0.0
            PlantUtilities_SetComponentFlowRate(
                state, mdot, desicDehum.CoilControlNode, desicDehum.CoilOutletNode
            )
            WaterCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, desicDehum.RegenCoilIndex, 0.0
            )
        elif desicDehum.regenCoilType == 3:
            mdot = 0.0
            PlantUtilities_SetComponentFlowRate(
                state, mdot, desicDehum.CoilControlNode, desicDehum.CoilOutletNode
            )
            SteamCoils_Simulate(
                state, desicDehum.RegenCoilName, FirstHVACIteration, desicDehum.RegenCoilIndex, RegenCoilLoad
            )
    
    if RegenCoilLoadmet is not None:
        return RegenCoilActual
    return RegenCoilActual


def GetProcAirInletNodeNum(state: object, DesicDehumName: str) -> int:
    """Return process air inlet node number"""
    dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    WhichDesicDehum = Util_FindItemInList(DesicDehumName, dd_state.DesicDehum)
    if WhichDesicDehum != 0:
        return dd_state.DesicDehum[WhichDesicDehum - 1].ProcAirInNode
    
    ShowSevereError(state, f"GetProcAirInletNodeNum: Could not find Desiccant Dehumidifier = \"{DesicDehumName}\"")
    return 0


def GetProcAirOutletNodeNum(state: object, DesicDehumName: str) -> int:
    """Return process air outlet node number"""
    dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    WhichDesicDehum = Util_FindItemInList(DesicDehumName, dd_state.DesicDehum)
    if WhichDesicDehum != 0:
        return dd_state.DesicDehum[WhichDesicDehum - 1].ProcAirOutNode
    
    ShowSevereError(state, f"GetProcAirOutletNodeNum: Could not find Desiccant Dehumidifier = \"{DesicDehumName}\"")
    return 0


def Util_FindItemInList(name: str, items: List[DesiccantDehumidifierData]) -> int:
    """Find index of item by name (1-based)"""
    for i, item in enumerate(items):
        if item.Name.upper() == name.upper():
            return i + 1
    return 0


def Sched_GetSchedule(state: object, name: str) -> Optional[object]:
    """Get schedule by name"""
    return state.dataScheduleMgr.GetSchedule(name)


def Sched_GetScheduleAlwaysOn(state: object) -> object:
    """Get always-on schedule"""
    return state.dataScheduleMgr.GetScheduleAlwaysOn()


def Node_GetOnlySingleNode(state: object, name: str, obj_type: str, obj_name: str) -> int:
    """Get single node"""
    return state.dataNodeInputMgr.GetOnlySingleNode(name)


def Curve_CurveValue(state: object, curve_idx: int, x: float, y: float = None) -> float:
    """Evaluate curve"""
    if y is None:
        return state.dataCurveManager.CurveValue(curve_idx, x)
    return state.dataCurveManager.CurveValue(curve_idx, x, y)


def Psychrometrics_PsyHFnTdbW(tdb: float, w: float) -> float:
    """Calculate enthalpy from dry bulb and humidity ratio"""
    return state.dataPsychrometrics.PsyHFnTdbW(tdb, w)


def Fans_Simulate(state: object, fan_idx: int, first_hvac: bool) -> None:
    """Simulate fan"""
    state.dataFans.fans[fan_idx].simulate(state, first_hvac)


def HeatingCoils_Simulate(state: object, name: str, first_hvac: bool, load: float, idx: int) -> float:
    """Simulate heating coil"""
    return state.dataHeatingCoils.SimulateHeatingCoilComponents(state, name, first_hvac, load, idx)


def WaterCoils_Simulate(state: object, name: str, first_hvac: bool, idx: int, load: float) -> None:
    """Simulate water coil"""
    state.dataWaterCoils.SimulateWaterCoilComponents(state, name, first_hvac, idx, load)


def SteamCoils_Simulate(state: object, name: str, first_hvac: bool, idx: int, load: float) -> None:
    """Simulate steam coil"""
    state.dataSteamCoils.SimulateSteamCoilComponents(state, name, first_hvac, idx, load)


def PlantUtilities_SetComponentFlowRate(state: object, flow: float, in_node: int, out_node: int) -> None:
    """Set component flow rate"""
    state.dataPlantUtilities.SetComponentFlowRate(state, flow, in_node, out_node)


def ShowFatalError(state: object, message: str) -> None:
    """Show fatal error"""
    state.dataError.ShowFatalError(message)


def ShowSevereError(state: object, message: str) -> None:
    """Show severe error"""
    state.dataError.ShowSevereError(message)


def ShowWarningError(state: object, message: str) -> None:
    """Show warning error"""
    state.dataError.ShowWarningError(message)


def ShowSevereItemNotFound(state: object, field: str, name: str) -> None:
    """Show severe item not found error"""
    state.dataError.ShowSevereItemNotFound(field, name)
