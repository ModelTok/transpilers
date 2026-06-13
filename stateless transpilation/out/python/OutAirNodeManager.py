# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter, root of data hierarchy
# - state.dataOutAirNodeMgr: OutAirNodeManagerData instance
# - state.dataInputProcessing.inputProcessor: InputProcessor with getNumObjectsFound, getObjectDefMaxArgs, getObjectItem
# - state.dataLoopNodes: node container with Node(index) accessor and NodeID(index) lookup
# - state.dataEnvrn: DataEnvironment with OutDryBulbTemp, OutWetBulbTemp, WindSpeed, WindDir, OutHumRat, OutBaroPress
# - state.dataGlobal: AnyLocalEnvironmentsInModel flag
# - state.dataContaminantBalance: Contaminant object with CO2Simulation, GenericContamSimulation; OutdoorCO2, OutdoorGC
# - GetNodeNums: from NodeInputManager; modifies node list and increments fluid stream numbers
# - Sched.GetSchedule: from ScheduleManager; returns schedule object or None
# - PsyHFnTdbW, PsyTwbFnTdbWPb, PsyWFnTdbTwbPb: from Psychrometrics
# - OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt: from DataEnvironment (height-dependent)
# - ShowFatalError, ShowContinueError, ShowSevereError, ShowSevereItemNotFound: from UtilityRoutines
# - ErrorObjectHeader: from InputProcessing

from typing import Protocol, Optional, Any
from dataclasses import dataclass, field


@dataclass
class OutAirNodeManagerData:
    OutsideAirNodeList: list = field(default_factory=list)  # List[int]
    NumOutsideAirNodes: int = 0
    GetOutAirNodesInputFlag: bool = True

    def init_state(self, state: Any) -> None:
        pass

    def init_constant_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.OutsideAirNodeList = []
        self.NumOutsideAirNodes = 0
        self.GetOutAirNodesInputFlag = True


def any_eq(array: list, value: int) -> bool:
    """Check if value exists in array"""
    if not array:
        return False
    return value in array


def SetOutAirNodes(state: Any) -> None:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
    InitOutAirNodes(state)


def GetOutAirNodesInput(state: Any) -> None:
    RoutineName = "GetOutAirNodesInput: "
    routineName = "GetOutAirNodesInput"

    NumOutAirInletNodeLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "OutdoorAir:NodeList"
    )
    NumOutsideAirNodeSingles = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "OutdoorAir:Node"
    )
    state.dataOutAirNodeMgr.NumOutsideAirNodes = 0
    ErrorsFound = False
    NextFluidStreamNum = 1

    ListSize = 0
    CurSize = 100
    TmpNums = [0] * CurSize

    MaxNums = 0
    MaxAlphas = 0

    # Get object definition max args for allocation sizing
    NumParams, NumAlphasTemp, NumNumsTemp = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "NodeList"
    )
    NodeNums = [0] * NumParams

    TotalArgs, NumAlphasTemp, NumNumsTemp = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "OutdoorAir:NodeList"
    )
    MaxNums = max(MaxNums, NumNumsTemp)
    MaxAlphas = max(MaxAlphas, NumAlphasTemp)

    TotalArgs, NumAlphasTemp, NumNumsTemp = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "OutdoorAir:Node"
    )
    MaxNums = max(MaxNums, NumNumsTemp)
    MaxAlphas = max(MaxAlphas, NumAlphasTemp)

    Alphas = [""] * MaxAlphas
    cAlphaFields = [""] * MaxAlphas
    cNumericFields = [""] * MaxNums
    Numbers = [0.0] * MaxNums
    lAlphaBlanks = [True] * MaxAlphas
    lNumericBlanks = [True] * MaxNums

    if NumOutAirInletNodeLists > 0:
        CurrentModuleObject = "OutdoorAir:NodeList"
        for OutAirInletNodeListNum in range(1, NumOutAirInletNodeLists + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                CurrentModuleObject,
                OutAirInletNodeListNum,
                Alphas,
                len(Alphas),
                Numbers,
                len(Numbers),
                lNumericBlanks,
                lAlphaBlanks,
                cAlphaFields,
                cNumericFields,
            )

            for AlphaNum in range(len(Alphas)):
                ErrInList = False
                NodeNums = []
                NumNodes = 0

                GetNodeNums(
                    state,
                    Alphas[AlphaNum],
                    NumNodes,
                    NodeNums,
                    ErrInList,
                    1,  # Node::FluidType::Air
                    1,  # Node::ConnectionObjectType::OutdoorAirNodeList
                    CurrentModuleObject,
                    1,  # Node::ConnectionType::OutsideAir
                    NextFluidStreamNum,
                    0,  # Node::ObjectIsNotParent
                    1,  # Node::IncrementFluidStreamYes
                    cAlphaFields[AlphaNum],
                )
                NextFluidStreamNum += NumNodes
                if ErrInList:
                    state.dataLoopNodes.format_string(
                        f"Occurred in {CurrentModuleObject}, {cAlphaFields[AlphaNum]} = {Alphas[AlphaNum]}"
                    )
                    ErrorsFound = True

                for NodeNum in range(NumNodes):
                    if not any_eq(TmpNums, NodeNums[NodeNum]):
                        ListSize += 1
                        if ListSize > CurSize:
                            CurSize += 100
                            TmpNums.extend([0] * 100)
                        TmpNums[ListSize - 1] = NodeNums[NodeNum]

        if ErrorsFound:
            raise RuntimeError(
                f"{RoutineName}Errors found in getting {CurrentModuleObject} input."
            )

    if NumOutsideAirNodeSingles > 0:
        CurrentModuleObject = "OutdoorAir:Node"
        for OutsideAirNodeSingleNum in range(1, NumOutsideAirNodeSingles + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                CurrentModuleObject,
                OutsideAirNodeSingleNum,
                Alphas,
                len(Alphas),
                Numbers,
                len(Numbers),
                lNumericBlanks,
                lAlphaBlanks,
                cAlphaFields,
                cNumericFields,
            )

            eoh = (routineName, CurrentModuleObject, Alphas[0])

            ErrInList = False
            NodeNums = []
            NumNodes = 0

            GetNodeNums(
                state,
                Alphas[0],
                NumNodes,
                NodeNums,
                ErrInList,
                1,  # Node::FluidType::Air
                2,  # Node::ConnectionObjectType::OutdoorAirNode
                CurrentModuleObject,
                1,  # Node::ConnectionType::OutsideAir
                NextFluidStreamNum,
                0,  # Node::ObjectIsNotParent
                1,  # Node::IncrementFluidStreamYes
                cAlphaFields[0],
            )
            NextFluidStreamNum += NumNodes
            if ErrInList:
                state.dataLoopNodes.show_continue_error(
                    state,
                    f"Occurred in {CurrentModuleObject}, {cAlphaFields[0]} = {Alphas[0]}",
                )
                ErrorsFound = True

            if NumNodes > 1:
                state.dataLoopNodes.show_severe_error(
                    state, f"{CurrentModuleObject}, {cAlphaFields[0]} = {Alphas[0]}"
                )
                state.dataLoopNodes.show_continue_error(
                    state, "...appears to point to a node list, not a single node."
                )
                ErrorsFound = True
                continue

            if not any_eq(TmpNums, NodeNums[0]):
                ListSize += 1
                if ListSize > CurSize:
                    CurSize += 100
                    TmpNums.extend([0] * 100)
                TmpNums[ListSize - 1] = NodeNums[0]
            else:
                state.dataLoopNodes.show_severe_error(
                    state,
                    f"{CurrentModuleObject}, duplicate {cAlphaFields[0]} = {Alphas[0]}",
                )
                state.dataLoopNodes.show_continue_error(
                    state,
                    f"Duplicate {cAlphaFields[0]} might be found in an OutdoorAir:NodeList.",
                )
                ErrorsFound = True
                continue

            if len(Numbers) > 0:
                state.dataLoopNodes.Node(NodeNums[0]).Height = Numbers[0]

            if len(Alphas) > 1:
                state.dataGlobal.AnyLocalEnvironmentsInModel = True

            if len(Alphas) <= 1 or lAlphaBlanks[1]:
                pass
            else:
                sched = state.dataSchedules.GetSchedule(state, Alphas[1])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, eoh, cAlphaFields[1], Alphas[1]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums[0]).outAirDryBulbSched = sched

            if len(Alphas) <= 2 or lAlphaBlanks[2]:
                pass
            else:
                sched = state.dataSchedules.GetSchedule(state, Alphas[2])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, eoh, cAlphaFields[2], Alphas[2]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums[0]).outAirWetBulbSched = sched

            if len(Alphas) <= 3 or lAlphaBlanks[3]:
                pass
            else:
                sched = state.dataSchedules.GetSchedule(state, Alphas[3])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, eoh, cAlphaFields[3], Alphas[3]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums[0]).outAirWindSpeedSched = sched

            if len(Alphas) <= 4 or lAlphaBlanks[4]:
                pass
            else:
                sched = state.dataSchedules.GetSchedule(state, Alphas[4])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, eoh, cAlphaFields[4], Alphas[4]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums[0]).outAirWindDirSched = sched

            if len(Alphas) > 8:
                state.dataLoopNodes.show_severe_error(
                    state, f"{CurrentModuleObject}, {cAlphaFields[0]} = {Alphas[0]}"
                )
                state.dataLoopNodes.show_continue_error(
                    state, "Object Definition indicates more than 7 Alpha Objects."
                )
                ErrorsFound = True
                continue

            if (
                state.dataLoopNodes.Node(NodeNums[0]).outAirDryBulbSched is not None
                or state.dataLoopNodes.Node(NodeNums[0]).outAirWetBulbSched is not None
            ):
                state.dataLoopNodes.Node(NodeNums[0]).IsLocalNode = True

        if ErrorsFound:
            raise RuntimeError(
                f"{RoutineName}Errors found in getting {CurrentModuleObject} input."
            )

    if ListSize > 0:
        state.dataOutAirNodeMgr.NumOutsideAirNodes = ListSize
        state.dataOutAirNodeMgr.OutsideAirNodeList = TmpNums[:ListSize]


def InitOutAirNodes(state: Any) -> None:
    for OutsideAirNodeNum in range(1, state.dataOutAirNodeMgr.NumOutsideAirNodes + 1):
        NodeNum = state.dataOutAirNodeMgr.OutsideAirNodeList[OutsideAirNodeNum - 1]
        SetOANodeValues(state, NodeNum, True)


def CheckOutAirNodeNumber(state: Any, NodeNumber: int) -> bool:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
        SetOutAirNodes(state)

    Okay = any_eq(state.dataOutAirNodeMgr.OutsideAirNodeList, NodeNumber)
    return Okay


def CheckAndAddAirNodeNumber(state: Any, NodeNumber: int) -> bool:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
        SetOutAirNodes(state)

    Okay = False

    if state.dataOutAirNodeMgr.NumOutsideAirNodes > 0:
        if any_eq(state.dataOutAirNodeMgr.OutsideAirNodeList, NodeNumber):
            Okay = True
        else:
            Okay = False
    else:
        Okay = False

    if NodeNumber > 0:
        if not Okay:
            state.dataOutAirNodeMgr.NumOutsideAirNodes += 1
            state.dataOutAirNodeMgr.OutsideAirNodeList.append(NodeNumber)
            TmpNums = state.dataOutAirNodeMgr.OutsideAirNodeList[:]
            errFlag = False
            DummyNumber = 0

            GetNodeNums(
                state,
                state.dataLoopNodes.NodeID(NodeNumber),
                DummyNumber,
                TmpNums,
                errFlag,
                1,  # Node::FluidType::Air
                2,  # Node::ConnectionObjectType::OutdoorAirNode
                "OutdoorAir:Node",
                1,  # Node::ConnectionType::OutsideAir
                state.dataOutAirNodeMgr.NumOutsideAirNodes,
                0,  # Node::ObjectIsNotParent
                1,  # Node::IncrementFluidStreamYes
                "",
            )
            SetOANodeValues(state, NodeNumber, False)

    return Okay


def SetOANodeValues(state: Any, NodeNum: int, InitCall: bool) -> None:
    from Psychrometrics import (
        PsyHFnTdbW,
        PsyTwbFnTdbWPb,
        PsyWFnTdbTwbPb,
    )
    from DataEnvironment import (
        OutDryBulbTempAt,
        OutWetBulbTempAt,
        WindSpeedAt,
    )

    if state.dataLoopNodes.Node(NodeNum).Height < 0.0:
        state.dataLoopNodes.Node(NodeNum).OutAirDryBulb = (
            state.dataEnvrn.OutDryBulbTemp
        )
        state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = (
            state.dataEnvrn.OutWetBulbTemp
        )
        if InitCall:
            state.dataLoopNodes.Node(NodeNum).OutAirWindSpeed = state.dataEnvrn.WindSpeed
    else:
        state.dataLoopNodes.Node(NodeNum).OutAirDryBulb = OutDryBulbTempAt(
            state, state.dataLoopNodes.Node(NodeNum).Height
        )
        state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = OutWetBulbTempAt(
            state, state.dataLoopNodes.Node(NodeNum).Height
        )
        if InitCall:
            state.dataLoopNodes.Node(NodeNum).OutAirWindSpeed = WindSpeedAt(
                state, state.dataLoopNodes.Node(NodeNum).Height
            )

    if not InitCall:
        state.dataLoopNodes.Node(NodeNum).OutAirWindSpeed = state.dataEnvrn.WindSpeed

    state.dataLoopNodes.Node(NodeNum).OutAirWindDir = state.dataEnvrn.WindDir

    if InitCall:
        if state.dataLoopNodes.Node(NodeNum).outAirDryBulbSched is not None:
            state.dataLoopNodes.Node(NodeNum).OutAirDryBulb = (
                state.dataLoopNodes.Node(NodeNum).outAirDryBulbSched.getCurrentVal()
            )
        if state.dataLoopNodes.Node(NodeNum).outAirWetBulbSched is not None:
            state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = (
                state.dataLoopNodes.Node(NodeNum).outAirWetBulbSched.getCurrentVal()
            )
        if state.dataLoopNodes.Node(NodeNum).outAirWindSpeedSched is not None:
            state.dataLoopNodes.Node(NodeNum).OutAirWindSpeed = (
                state.dataLoopNodes.Node(NodeNum).outAirWindSpeedSched.getCurrentVal()
            )
        if state.dataLoopNodes.Node(NodeNum).outAirWindDirSched is not None:
            state.dataLoopNodes.Node(NodeNum).OutAirWindDir = (
                state.dataLoopNodes.Node(NodeNum).outAirWindDirSched.getCurrentVal()
            )

        if state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirDryBulb:
            state.dataLoopNodes.Node(NodeNum).OutAirDryBulb = (
                state.dataLoopNodes.Node(NodeNum).EMSValueForOutAirDryBulb
            )
        if state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirWetBulb:
            state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = (
                state.dataLoopNodes.Node(NodeNum).EMSValueForOutAirWetBulb
            )
        if state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirWindSpeed:
            state.dataLoopNodes.Node(NodeNum).OutAirWindSpeed = (
                state.dataLoopNodes.Node(NodeNum).EMSValueForOutAirWindSpeed
            )
        if state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirWindDir:
            state.dataLoopNodes.Node(NodeNum).OutAirWindDir = (
                state.dataLoopNodes.Node(NodeNum).EMSValueForOutAirWindDir
            )

    state.dataLoopNodes.Node(NodeNum).Temp = (
        state.dataLoopNodes.Node(NodeNum).OutAirDryBulb
    )
    if (
        state.dataLoopNodes.Node(NodeNum).IsLocalNode
        or state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirDryBulb
        or state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirWetBulb
    ):
        if InitCall:
            if (
                state.dataLoopNodes.Node(NodeNum).OutAirWetBulb
                > state.dataLoopNodes.Node(NodeNum).OutAirDryBulb
            ):
                state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = (
                    state.dataLoopNodes.Node(NodeNum).OutAirDryBulb
                )
            if (
                state.dataLoopNodes.Node(NodeNum).outAirWetBulbSched is None
                and not state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirWetBulb
                and (
                    state.dataLoopNodes.Node(NodeNum).EMSOverrideOutAirDryBulb
                    or state.dataLoopNodes.Node(NodeNum).outAirDryBulbSched is not None
                )
            ):
                state.dataLoopNodes.Node(NodeNum).HumRat = state.dataEnvrn.OutHumRat
                state.dataLoopNodes.Node(NodeNum).OutAirWetBulb = PsyTwbFnTdbWPb(
                    state,
                    state.dataLoopNodes.Node(NodeNum).OutAirDryBulb,
                    state.dataEnvrn.OutHumRat,
                    state.dataEnvrn.OutBaroPress,
                )
            else:
                state.dataLoopNodes.Node(NodeNum).HumRat = PsyWFnTdbTwbPb(
                    state,
                    state.dataLoopNodes.Node(NodeNum).OutAirDryBulb,
                    state.dataLoopNodes.Node(NodeNum).OutAirWetBulb,
                    state.dataEnvrn.OutBaroPress,
                )
        else:
            state.dataLoopNodes.Node(NodeNum).HumRat = PsyWFnTdbTwbPb(
                state,
                state.dataLoopNodes.Node(NodeNum).OutAirDryBulb,
                state.dataLoopNodes.Node(NodeNum).OutAirWetBulb,
                state.dataEnvrn.OutBaroPress,
            )
    else:
        state.dataLoopNodes.Node(NodeNum).HumRat = state.dataEnvrn.OutHumRat

    state.dataLoopNodes.Node(NodeNum).Enthalpy = PsyHFnTdbW(
        state.dataLoopNodes.Node(NodeNum).OutAirDryBulb,
        state.dataLoopNodes.Node(NodeNum).HumRat,
    )
    state.dataLoopNodes.Node(NodeNum).Press = state.dataEnvrn.OutBaroPress
    state.dataLoopNodes.Node(NodeNum).Quality = 0.0

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node(NodeNum).CO2 = (
            state.dataContaminantBalance.OutdoorCO2
        )
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node(NodeNum).GenContam = (
            state.dataContaminantBalance.OutdoorGC
        )
