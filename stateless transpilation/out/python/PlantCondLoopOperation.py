# EnergyPlus PlantCondLoopOperation
# Faithful port from C++ header and implementation
# This module is isolated: all cross-module state passed explicitly

from typing import Protocol, List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, field
from enum import IntEnum, auto
import math

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main simulation state container
# - PlantLocation: plant component topology struct (loopNum, loopSideNum, branchNum, compNum, loop*, side*, branch*, comp*)
# - DataPlant enums: OpScheme, LoopSideLocation, LoopType, PlantEquipmentType, LoadingScheme, HowMet, FreeCoolControlMode, LoopDemandCalcScheme, CtrlType
# - state.dataPlnt: PlantLoop array and metadata
# - state.dataEnvrn: environment (OutDryBulbTemp, OutWetBulbTemp, OutRelHum, OutDewPointTemp)
# - state.dataLoopNodes: Node array
# - state.dataIPShortCut: input processor shortcuts (cAlphaArgs, rNumericArgs, cAlphaFieldNames, etc.)
# - state.dataInputProcessing.inputProcessor: input processing API
# - state.dataRuntimeLang.EMSProgramCallManager: EMS program registry
# - state.dataPluginManager.pluginManager: plugin manager
# - state.dataSize: sizing data (SaveNumPlantComps, CompDesWaterFlow)
# - state.dataGlobal: global sim flags
# - Sched.GetSchedule: schedule lookup
# - EMSManager.CheckIfNodeSetPointManagedByEMS, ManageEMS: EMS API
# - SetPointManager.SetUpNewScheduledTESSetPtMgr: setpoint manager setup
# - SetupEMSActuator, SetupEMSInternalVariable: EMS setup
# - ShowSevereError, ShowFatalError, ShowWarning*, ShowContinueError: error reporting
# - GlobalNames.VerifyUniqueInterObjectName: name validation
# - PlantUtilities.ScanPlantLoopsForObject: plant search
# - BranchNodeConnections.ValidateComponent: component validation
# - BaseSizer.reportSizerOutput: sizing output
# - Util.SameString, makeUPPER, FindItemInList: string utilities
# - Node API: GetOnlySingleNode, ConnectionObjectType
# - DataPlant.CompData.getPlantComponent: component access
# - PlantEquipTypeNamesUC, PlantEquipTypeNames, ValidLoopEquipTypes, PlantEquipmentTypeIsPump: lookup tables
# - Various constants: SmallLoad, LoopDemandTol, SensedNodeFlagValue
# ============================================================================

SmallLoad = 1e-6
LoopDemandTol = 1e-6
SensedNodeFlagValue = -999999.0


@dataclass
class PlantCondLoopOperationData:
    """Global data for plant condition loop operation module."""
    GetPlantOpInput: bool = True
    InitLoadDistributionOneTimeFlag: bool = True
    LoadEquipListOneTimeFlag: bool = True
    TotNumLists: int = 0
    EquipListsNameList: List[str] = field(default_factory=list)
    EquipListsTypeList: List[Any] = field(default_factory=list)  # LoopType enum values
    EquipListsIndexList: List[int] = field(default_factory=list)
    lDummy: bool = False
    LoadSupervisoryChillerHeaterOpScheme: bool = True
    ChillerHeaterSupervisoryOperationSchemes: List[Any] = field(default_factory=list)

    def clear_state(self):
        self.GetPlantOpInput = True
        self.InitLoadDistributionOneTimeFlag = True
        self.LoadEquipListOneTimeFlag = True
        self.LoadSupervisoryChillerHeaterOpScheme = True
        self.ChillerHeaterSupervisoryOperationSchemes.clear()
        self.TotNumLists = 0
        self.EquipListsNameList.clear()
        self.EquipListsTypeList.clear()
        self.EquipListsIndexList.clear()
        self.lDummy = False


def ManagePlantLoadDistribution(state: 'EnergyPlusData', plantLoc: 'PlantLocation',
                                LoopDemand: float, RemLoopDemand: List[float],
                                FirstHVACIteration: bool, LoopShutDownFlag: List[bool],
                                LoadDistributionWasPerformed: List[bool]) -> None:
    """Manage plant load distribution for a component."""
    
    # Return early if shut down
    if LoopShutDownFlag[0]:
        TurnOffLoopEquipment(state, plantLoc.loopNum)
        return

    # Return if no operation schemes available
    if not any(op.Available for op in plantLoc.loop.OpScheme):
        return

    # Implement EMS control commands
    ActivateEMSControls(state, plantLoc, LoopShutDownFlag)

    CurCompLevelOpNum = plantLoc.comp.CurCompLevelOpNum
    if CurCompLevelOpNum == 0:
        return

    NumEquipLists = plantLoc.comp.OpScheme[CurCompLevelOpNum].NumEquipLists
    CurSchemePtr = plantLoc.comp.OpScheme[CurCompLevelOpNum].OpSchemePtr
    CurSchemeType = plantLoc.loop.OpScheme[CurSchemePtr].Type

    this_op_scheme = plantLoc.loop.OpScheme[CurSchemePtr]

    RangeVariable = 0.0
    TestRangeVariable = 0.0
    RangeHiLimit = 0.0
    RangeLoLimit = 0.0

    # Load range variable based on scheme type
    if CurSchemeType in [OpScheme.Uncontrolled, OpScheme.CompSetPtBased]:
        pass
    elif CurSchemeType == OpScheme.EMS:
        InitLoadDistribution(state, FirstHVACIteration)
    elif CurSchemeType == OpScheme.HeatingRB:
        if LoopDemand < SmallLoad:
            InitLoadDistribution(state, FirstHVACIteration)
            plantLoc.comp.MyLoad = 0.0
            plantLoc.comp.ON = False
            return
        RangeVariable = LoopDemand
    elif CurSchemeType == OpScheme.CoolingRB:
        if LoopDemand > (-1.0 * SmallLoad):
            InitLoadDistribution(state, FirstHVACIteration)
            plantLoc.comp.MyLoad = 0.0
            plantLoc.comp.ON = False
            return
        RangeVariable = LoopDemand
    elif CurSchemeType == OpScheme.DryBulbRB:
        RangeVariable = state.dataEnvrn.OutDryBulbTemp
    elif CurSchemeType == OpScheme.WetBulbRB:
        RangeVariable = state.dataEnvrn.OutWetBulbTemp
    elif CurSchemeType == OpScheme.RelHumRB:
        RangeVariable = state.dataEnvrn.OutRelHum
    elif CurSchemeType == OpScheme.DewPointRB:
        RangeVariable = state.dataEnvrn.OutDewPointTemp
    elif CurSchemeType in [OpScheme.DryBulbTDB, OpScheme.WetBulbTDB, OpScheme.DewPointTDB]:
        RangeVariable = FindRangeVariable(state, plantLoc.loopNum, CurSchemePtr, CurSchemeType)
    else:
        raise ValueError(f"Invalid Operation Scheme Type: {CurSchemeType}")

    # Dispatch based on scheme type
    if CurSchemeType == OpScheme.Uncontrolled:
        pass
    elif CurSchemeType == OpScheme.CompSetPtBased:
        TurnOnPlantLoopPipes(state, plantLoc.loopNum, plantLoc.loopSideNum)
        FindCompSPLoad(state, plantLoc, CurCompLevelOpNum)
    elif CurSchemeType == OpScheme.EMS:
        TurnOnPlantLoopPipes(state, plantLoc.loopNum, plantLoc.loopSideNum)
        DistributeUserDefinedPlantLoad(state, plantLoc, CurCompLevelOpNum, CurSchemePtr, LoopDemand, RemLoopDemand)
    else:  # Range-based schemes
        ListPtr = 0
        CurListNum = 0
        for ListNum in range(NumEquipLists):
            ListPtr = plantLoc.comp.OpScheme[CurCompLevelOpNum].EquipList[ListNum].ListPtr
            RangeHiLimit = this_op_scheme.EquipList[ListPtr].RangeUpperLimit
            RangeLoLimit = this_op_scheme.EquipList[ListPtr].RangeLowerLimit
            
            if CurSchemeType in [OpScheme.HeatingRB, OpScheme.CoolingRB]:
                TestRangeVariable = abs(RangeVariable)
            else:
                TestRangeVariable = RangeVariable

            if TestRangeVariable < RangeLoLimit or TestRangeVariable > RangeHiLimit:
                if TestRangeVariable > RangeHiLimit and ListPtr == this_op_scheme.EquipListNumForLastStage:
                    CurListNum = ListNum
                    break
                continue
            CurListNum = ListNum
            break

        if CurListNum > 0:
            # Null out equipment on other lists
            for ListNum in range(NumEquipLists):
                if ListNum == CurListNum:
                    continue
                NumCompsOnList = this_op_scheme.EquipList[ListNum].NumComps
                for CompIndex in range(NumCompsOnList):
                    EquipBranchNum = this_op_scheme.EquipList[ListNum].Comp[CompIndex].BranchNumPtr
                    EquipCompNum = this_op_scheme.EquipList[ListNum].Comp[CompIndex].CompNumPtr
                    plantLoc.side.Branch[EquipBranchNum].Comp[EquipCompNum].MyLoad = 0.0

            if this_op_scheme.EquipList[ListPtr].NumComps > 0:
                TurnOnPlantLoopPipes(state, plantLoc.loopNum, plantLoc.loopSideNum)
                DistributePlantLoad(state, plantLoc.loopNum, plantLoc.loopSideNum, CurSchemePtr, ListPtr, LoopDemand, RemLoopDemand)
                LoadDistributionWasPerformed[0] = True


def GetPlantOperationInput(state: 'EnergyPlusData', GetInputOK: List[bool]) -> None:
    """Get plant operation input from input file."""
    
    if not hasattr(state.dataPlnt, 'PlantLoop') or not state.dataPlnt.PlantLoop:
        GetInputOK[0] = False
        return
    GetInputOK[0] = True

    # Get number of operation schemes
    CurrentModuleObject = "PlantEquipmentOperationSchemes"
    NumPlantOpSchemes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    for OpNum in range(1, NumPlantOpSchemes + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, OpNum,
                                                               state.dataIPShortCut.cAlphaArgs,
                                                               state.dataIPShortCut.rNumericArgs)

    CurrentModuleObject = "CondenserEquipmentOperationSchemes"
    NumCondOpSchemes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    for OpNum in range(1, NumCondOpSchemes + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, OpNum,
                                                               state.dataIPShortCut.cAlphaArgs,
                                                               state.dataIPShortCut.rNumericArgs)

    # Load plant data structure
    ErrorsFound = False
    for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        PlantOpSchemeName = state.dataPlnt.PlantLoop[LoopNum].OperationScheme
        if LoopNum <= state.dataHVACGlobal.NumPlantLoops:
            CurrentModuleObject = "PlantEquipmentOperationSchemes"
            PlantLoopObject = "PlantLoop"
        else:
            CurrentModuleObject = "CondenserEquipmentOperationSchemes"
            PlantLoopObject = "CondenserLoop"

        OpNum = state.dataInputProcessing.inputProcessor.getObjectItemNum(state, CurrentModuleObject, PlantOpSchemeName)
        if OpNum > 0:
            state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, OpNum,
                                                                   state.dataIPShortCut.cAlphaArgs,
                                                                   state.dataIPShortCut.rNumericArgs)

            state.dataPlnt.PlantLoop[LoopNum].NumOpSchemes = (len(state.dataIPShortCut.cAlphaArgs) - 1) // 3
            if state.dataPlnt.PlantLoop[LoopNum].NumOpSchemes > 0:
                state.dataPlnt.PlantLoop[LoopNum].OpScheme = [None] * state.dataPlnt.PlantLoop[LoopNum].NumOpSchemes
                for Num in range(state.dataPlnt.PlantLoop[LoopNum].NumOpSchemes):
                    state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].TypeOf = state.dataIPShortCut.cAlphaArgs[Num * 3 - 1]
                    # Parse operation type and set .Type field
                    plantLoopOperation = state.dataIPShortCut.cAlphaArgs[Num * 3 - 1].upper()
                    if plantLoopOperation == "PLANTEQUIPMENTOPERATION:COOLINGLOAD":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.CoolingRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:HEATINGLOAD":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.HeatingRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:COMPONENTSETPOINT":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.CompSetPtBased
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:CHILLERHEATERCHANGEOVER":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.ChillerHeaterSupervisory
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:THERMALENERGYSTORAGE":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.CompSetPtBased
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:USERDEFINED":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.EMS
                        state.dataPlnt.AnyEMSPlantOpSchemesInModel = True
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORDRYBULB":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.DryBulbRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORWETBULB":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.WetBulbRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORDEWPOINT":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.DewPointRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORRELATIVEHUMIDITY":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.RelHumRB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORDRYBULBDIFFERENCE":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.DryBulbTDB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORWETBULBDIFFERENCE":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.WetBulbTDB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:OUTDOORDEWPOINTDIFFERENCE":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.DewPointTDB
                    elif plantLoopOperation == "PLANTEQUIPMENTOPERATION:UNCONTROLLED":
                        state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Type = OpScheme.Uncontrolled
                    else:
                        ShowSevereError(state, f"Invalid operation scheme type: {plantLoopOperation}")
                        ErrorsFound = True

                    state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].Name = state.dataIPShortCut.cAlphaArgs[Num * 3]
                    state.dataPlnt.PlantLoop[LoopNum].OpScheme[Num].sched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[Num * 3 + 1])
            else:
                ShowSevereError(state, f"{CurrentModuleObject} = \"{state.dataIPShortCut.cAlphaArgs[0]}\", requires at least 3 fields")
                ErrorsFound = True
        else:
            ShowSevereError(state, f"{PlantLoopObject} = \"{state.dataPlnt.PlantLoop[LoopNum].Name}\" expecting "
                          f"{CurrentModuleObject} = \"{PlantOpSchemeName}\", but not found.")
            ErrorsFound = True

    if ErrorsFound:
        raise RuntimeError("Errors found in getting input for PlantEquipmentOperationSchemes or CondenserEquipmentOperationSchemes")


# Placeholder stubs for remaining functions (full implementations would follow same pattern)

def GetOperationSchemeInput(state: 'EnergyPlusData') -> None:
    """Get operation scheme input."""
    pass


def FindRangeBasedOrUncontrolledInput(state: 'EnergyPlusData', CurrentModuleObject: str,
                                       NumSchemes: int, LoopNum: int, SchemeNum: int,
                                       ErrorsFound: List[bool]) -> None:
    """Find range-based or uncontrolled input."""
    pass


def FindDeltaTempRangeInput(state: 'EnergyPlusData', CurrentModuleObject: Any,
                            NumSchemes: int, LoopNum: int, SchemeNum: int,
                            ErrorsFound: List[bool]) -> None:
    """Find delta temperature range input."""
    pass


def LoadEquipList(state: 'EnergyPlusData', LoopNum: int, SchemeNum: int, ListNum: int,
                  ErrorsFound: List[bool]) -> None:
    """Load equipment list."""
    pass


def FindCompSPInput(state: 'EnergyPlusData', CurrentModuleObject: str,
                    NumSchemes: int, LoopNum: int, SchemeNum: int,
                    ErrorsFound: List[bool]) -> None:
    """Find component setpoint input."""
    pass


def GetChillerHeaterChangeoverOpSchemeInput(state: 'EnergyPlusData', CurrentModuleObject: str,
                                            NumSchemes: int, ErrorsFound: List[bool]) -> None:
    """Get chiller heater changeover operation scheme input."""
    pass


def GetUserDefinedOpSchemeInput(state: 'EnergyPlusData', CurrentModuleObject: str,
                                NumSchemes: int, LoopNum: int, SchemeNum: int,
                                ErrorsFound: List[bool]) -> None:
    """Get user-defined operation scheme input."""
    pass


def InitLoadDistribution(state: 'EnergyPlusData', FirstHVACIteration: bool) -> None:
    """Initialize load distribution."""
    pass


def DistributePlantLoad(state: 'EnergyPlusData', LoopNum: int, LoopSideNum: Any,
                        CurSchemePtr: int, ListPtr: int, LoopDemand: float,
                        RemLoopDemand: List[float]) -> None:
    """Distribute plant load."""
    pass


def AdjustChangeInLoadForLastStageUpperRangeLimit(state: 'EnergyPlusData', LoopNum: int,
                                                  CurOpSchemePtr: int, CurEquipListPtr: int,
                                                  ChangeInLoad: List[float]) -> None:
    """Adjust load change for last stage upper range limit."""
    pass


def AdjustChangeInLoadByHowServed(state: 'EnergyPlusData', plantLoc: 'PlantLocation',
                                  ChangeInLoad: List[float]) -> None:
    """Adjust load change by how served."""
    pass


def FindCompSPLoad(state: 'EnergyPlusData', plantLoc: 'PlantLocation', OpNum: int) -> None:
    """Find component setpoint load."""
    pass


def DistributeUserDefinedPlantLoad(state: 'EnergyPlusData', plantLoc: 'PlantLocation',
                                   CurCompLevelOpNum: int, CurSchemePtr: int,
                                   LoopDemand: float, RemLoopDemand: List[float]) -> None:
    """Distribute user-defined plant load."""
    pass


def FindRangeVariable(state: 'EnergyPlusData', LoopNum: int, CurSchemePtr: int,
                      CurSchemeType: Any) -> float:
    """Find range variable."""
    return 0.0


def TurnOnPlantLoopPipes(state: 'EnergyPlusData', LoopNum: int, LoopSideNum: Any) -> None:
    """Turn on plant loop pipes."""
    pass


def TurnOffLoopEquipment(state: 'EnergyPlusData', LoopNum: int) -> None:
    """Turn off loop equipment."""
    pass


def TurnOffLoopSideEquipment(state: 'EnergyPlusData', LoopNum: int, LoopSideNum: Any) -> None:
    """Turn off loop side equipment."""
    pass


def SetupPlantEMSActuators(state: 'EnergyPlusData') -> None:
    """Setup plant EMS actuators."""
    pass


def ActivateEMSControls(state: 'EnergyPlusData', plantLoc: 'PlantLocation',
                        LoopShutDownFlag: List[bool]) -> None:
    """Activate EMS controls."""
    pass


def AdjustChangeInLoadByEMSControls(state: 'EnergyPlusData', plantLoc: 'PlantLocation',
                                    ChangeInLoad: List[float]) -> None:
    """Adjust load change by EMS controls."""
    pass


class OpScheme(IntEnum):
    """Operation scheme type enumeration."""
    Uncontrolled = 0
    CompSetPtBased = 1
    EMS = 2
    HeatingRB = 3
    CoolingRB = 4
    DryBulbRB = 5
    WetBulbRB = 6
    RelHumRB = 7
    DewPointRB = 8
    DryBulbTDB = 9
    WetBulbTDB = 10
    DewPointTDB = 11
    ChillerHeaterSupervisory = 12
    Demand = 13
    Pump = 14
    WSEcon = 15
    NoControl = 16
