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

from utils.static_tuple import StaticTuple


struct OutAirNodeManagerData:
    var OutsideAirNodeList: List[Int]
    var NumOutsideAirNodes: Int
    var GetOutAirNodesInputFlag: Bool

    fn __init__(inout self):
        self.OutsideAirNodeList = List[Int]()
        self.NumOutsideAirNodes = 0
        self.GetOutAirNodesInputFlag = True

    fn init_state(inout self, state: EnergyPlusDataPtr) -> None:
        pass

    fn init_constant_state(inout self, state: EnergyPlusDataPtr) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.OutsideAirNodeList.clear()
        self.NumOutsideAirNodes = 0
        self.GetOutAirNodesInputFlag = True


fn any_eq(array: List[Int], value: Int) -> Bool:
    """Check if value exists in array"""
    if len(array) == 0:
        return False
    for item in array:
        if item[] == value:
            return True
    return False


fn SetOutAirNodes(state: EnergyPlusDataPtr) -> None:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
    InitOutAirNodes(state)


fn GetOutAirNodesInput(state: EnergyPlusDataPtr) -> None:
    var RoutineName: StringRef = "GetOutAirNodesInput: "
    var routineName: StringRef = "GetOutAirNodesInput"

    var NumOutAirInletNodeLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "OutdoorAir:NodeList"
    )
    var NumOutsideAirNodeSingles = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "OutdoorAir:Node"
    )
    state.dataOutAirNodeMgr.NumOutsideAirNodes = 0
    var ErrorsFound = False
    var NextFluidStreamNum = 1

    var ListSize = 0
    var CurSize = 100
    var TmpNums = List[Int](capacity=CurSize)
    for _ in range(CurSize):
        TmpNums.append(0)

    var MaxNums = 0
    var MaxAlphas = 0

    # Get object definition max args for allocation sizing
    var NumParams: Int = 0
    var NumAlphasTemp: Int = 0
    var NumNumsTemp: Int = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "NodeList", NumParams, NumAlphasTemp, NumNumsTemp
    )
    var NodeNums = List[Int](capacity=NumParams)
    for _ in range(NumParams):
        NodeNums.append(0)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "OutdoorAir:NodeList", NumParams, NumAlphasTemp, NumNumsTemp
    )
    MaxNums = max(MaxNums, NumNumsTemp)
    MaxAlphas = max(MaxAlphas, NumAlphasTemp)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, "OutdoorAir:Node", NumParams, NumAlphasTemp, NumNumsTemp
    )
    MaxNums = max(MaxNums, NumNumsTemp)
    MaxAlphas = max(MaxAlphas, NumAlphasTemp)

    var Alphas = List[String](capacity=MaxAlphas)
    var cAlphaFields = List[String](capacity=MaxAlphas)
    var cNumericFields = List[String](capacity=MaxNums)
    var Numbers = List[Float64](capacity=MaxNums)
    var lAlphaBlanks = List[Bool](capacity=MaxAlphas)
    var lNumericBlanks = List[Bool](capacity=MaxNums)

    for _ in range(MaxAlphas):
        Alphas.append("")
        cAlphaFields.append("")
        lAlphaBlanks.append(True)

    for _ in range(MaxNums):
        cNumericFields.append("")
        Numbers.append(0.0)
        lNumericBlanks.append(True)

    if NumOutAirInletNodeLists > 0:
        var CurrentModuleObject = "OutdoorAir:NodeList"
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
                var ErrInList = False
                var NodeNums_local = List[Int]()
                var NumNodes = 0

                GetNodeNums(
                    state,
                    Alphas[AlphaNum],
                    NumNodes,
                    NodeNums_local,
                    ErrInList,
                    1,
                    1,
                    CurrentModuleObject,
                    1,
                    NextFluidStreamNum,
                    0,
                    1,
                    cAlphaFields[AlphaNum],
                )
                NextFluidStreamNum += NumNodes
                if ErrInList:
                    state.dataLoopNodes.format_string(
                        String("Occurred in ") + CurrentModuleObject + String(", ") + cAlphaFields[AlphaNum] + String(" = ") + Alphas[AlphaNum]
                    )
                    ErrorsFound = True

                for NodeNum in range(NumNodes):
                    if not any_eq(TmpNums, NodeNums_local[NodeNum]):
                        ListSize += 1
                        if ListSize > CurSize:
                            CurSize += 100
                            for _ in range(100):
                                TmpNums.append(0)
                        TmpNums[ListSize - 1] = NodeNums_local[NodeNum]

        if ErrorsFound:
            raise String(RoutineName + "Errors found in getting " + CurrentModuleObject + " input.")

    if NumOutsideAirNodeSingles > 0:
        var CurrentModuleObject = "OutdoorAir:Node"
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

            var ErrInList = False
            var NodeNums_local = List[Int]()
            var NumNodes = 0

            GetNodeNums(
                state,
                Alphas[0],
                NumNodes,
                NodeNums_local,
                ErrInList,
                1,
                2,
                CurrentModuleObject,
                1,
                NextFluidStreamNum,
                0,
                1,
                cAlphaFields[0],
            )
            NextFluidStreamNum += NumNodes
            if ErrInList:
                state.dataLoopNodes.show_continue_error(
                    state,
                    String("Occurred in ") + CurrentModuleObject + String(", ") + cAlphaFields[0] + String(" = ") + Alphas[0],
                )
                ErrorsFound = True

            if NumNodes > 1:
                state.dataLoopNodes.show_severe_error(
                    state, String(CurrentModuleObject) + String(", ") + cAlphaFields[0] + String(" = ") + Alphas[0]
                )
                state.dataLoopNodes.show_continue_error(
                    state, "...appears to point to a node list, not a single node."
                )
                ErrorsFound = True
                continue

            if not any_eq(TmpNums, NodeNums_local[0]):
                ListSize += 1
                if ListSize > CurSize:
                    CurSize += 100
                    for _ in range(100):
                        TmpNums.append(0)
                TmpNums[ListSize - 1] = NodeNums_local[0]
            else:
                state.dataLoopNodes.show_severe_error(
                    state,
                    String(CurrentModuleObject) + String(", duplicate ") + cAlphaFields[0] + String(" = ") + Alphas[0],
                )
                state.dataLoopNodes.show_continue_error(
                    state,
                    String("Duplicate ") + cAlphaFields[0] + String(" might be found in an OutdoorAir:NodeList."),
                )
                ErrorsFound = True
                continue

            if len(Numbers) > 0:
                state.dataLoopNodes.Node(NodeNums_local[0]).Height = Numbers[0]

            if len(Alphas) > 1:
                state.dataGlobal.AnyLocalEnvironmentsInModel = True

            if len(Alphas) <= 1 or lAlphaBlanks[1]:
                pass
            else:
                var sched = state.dataSchedules.GetSchedule(state, Alphas[1])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, (routineName, CurrentModuleObject, Alphas[0]), cAlphaFields[1], Alphas[1]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums_local[0]).outAirDryBulbSched = sched

            if len(Alphas) <= 2 or lAlphaBlanks[2]:
                pass
            else:
                var sched = state.dataSchedules.GetSchedule(state, Alphas[2])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, (routineName, CurrentModuleObject, Alphas[0]), cAlphaFields[2], Alphas[2]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums_local[0]).outAirWetBulbSched = sched

            if len(Alphas) <= 3 or lAlphaBlanks[3]:
                pass
            else:
                var sched = state.dataSchedules.GetSchedule(state, Alphas[3])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, (routineName, CurrentModuleObject, Alphas[0]), cAlphaFields[3], Alphas[3]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums_local[0]).outAirWindSpeedSched = sched

            if len(Alphas) <= 4 or lAlphaBlanks[4]:
                pass
            else:
                var sched = state.dataSchedules.GetSchedule(state, Alphas[4])
                if sched is None:
                    state.dataLoopNodes.show_severe_item_not_found(
                        state, (routineName, CurrentModuleObject, Alphas[0]), cAlphaFields[4], Alphas[4]
                    )
                    ErrorsFound = True
                else:
                    state.dataLoopNodes.Node(NodeNums_local[0]).outAirWindDirSched = sched

            if len(Alphas) > 8:
                state.dataLoopNodes.show_severe_error(
                    state, String(CurrentModuleObject) + String(", ") + cAlphaFields[0] + String(" = ") + Alphas[0]
                )
                state.dataLoopNodes.show_continue_error(
                    state, "Object Definition indicates more than 7 Alpha Objects."
                )
                ErrorsFound = True
                continue

            if (
                state.dataLoopNodes.Node(NodeNums_local[0]).outAirDryBulbSched is not None
                or state.dataLoopNodes.Node(NodeNums_local[0]).outAirWetBulbSched is not None
            ):
                state.dataLoopNodes.Node(NodeNums_local[0]).IsLocalNode = True

        if ErrorsFound:
            raise String(RoutineName + "Errors found in getting " + CurrentModuleObject + " input.")

    if ListSize > 0:
        state.dataOutAirNodeMgr.NumOutsideAirNodes = ListSize
        state.dataOutAirNodeMgr.OutsideAirNodeList = List[Int](capacity=ListSize)
        for idx in range(ListSize):
            state.dataOutAirNodeMgr.OutsideAirNodeList.append(TmpNums[idx])


fn InitOutAirNodes(state: EnergyPlusDataPtr) -> None:
    for OutsideAirNodeNum in range(1, state.dataOutAirNodeMgr.NumOutsideAirNodes + 1):
        var NodeNum = state.dataOutAirNodeMgr.OutsideAirNodeList[OutsideAirNodeNum - 1]
        SetOANodeValues(state, NodeNum, True)


fn CheckOutAirNodeNumber(state: EnergyPlusDataPtr, NodeNumber: Int) -> Bool:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
        SetOutAirNodes(state)

    var Okay = any_eq(state.dataOutAirNodeMgr.OutsideAirNodeList, NodeNumber)
    return Okay


fn CheckAndAddAirNodeNumber(state: EnergyPlusDataPtr, NodeNumber: Int) -> Bool:
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
        SetOutAirNodes(state)

    var Okay = False

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
            var TmpNums = List[Int]()
            for item in state.dataOutAirNodeMgr.OutsideAirNodeList:
                TmpNums.append(item[])
            var errFlag = False
            var DummyNumber = 0

            GetNodeNums(
                state,
                state.dataLoopNodes.NodeID(NodeNumber),
                DummyNumber,
                TmpNums,
                errFlag,
                1,
                2,
                "OutdoorAir:Node",
                1,
                state.dataOutAirNodeMgr.NumOutsideAirNodes,
                0,
                1,
                "",
            )
            SetOANodeValues(state, NodeNumber, False)

    return Okay


fn SetOANodeValues(state: EnergyPlusDataPtr, NodeNum: Int, InitCall: Bool) -> None:
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
