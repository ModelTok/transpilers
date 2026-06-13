from DataEnvironment import (OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt)
from Psychrometrics import PsyHFnTdbW, PsyTwbFnTdbWPb, PsyWFnTdbTwbPb
from UtilityRoutines import ShowContinueError, ShowFatalError, ShowSevereError, ShowSevereItemNotFound
from NodeInputManager import GetNodeNums
from .InputProcessing.InputProcessor import GetObjectItem, GetNumObjectsFound, GetObjectDefMaxArgs
from DataLoopNode import Node
from ScheduleManager import Sched
from .Data.EnergyPlusData import EnergyPlusData
from DataContaminantBalance import ContaminantBalanceData
from DataEnvironment import EnvironmentData
from DataLoopNode import LoopNodeData
from DataGlobal import GlobalData
from .Data.BaseData import BaseGlobalStruct
from Array1D import Array1D_int, Array1D_string, Array1D_bool, Array1D_Real64
from ErrorObjectHeader import ErrorObjectHeader
from Fmath import any_eq, max
from format import format
from string_view import string_view

struct OutAirNodeManagerData(BaseGlobalStruct):
    var OutsideAirNodeList: Array1D_int
    var NumOutsideAirNodes: Int = 0
    var GetOutAirNodesInputFlag: Bool = True

    def init_state(inout self, state: EnergyPlusData):

    def init_constant_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.OutsideAirNodeList.deallocate()
        self.NumOutsideAirNodes = 0
        self.GetOutAirNodesInputFlag = True

def SetOutAirNodes(inout state: EnergyPlusData):
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
    InitOutAirNodes(state)

def GetOutAirNodesInput(inout state: EnergyPlusData):
    var RoutineName: String = "GetOutAirNodesInput: "
    var routineName: String = "GetOutAirNodesInput"
    var NumOutAirInletNodeLists: Int
    var NumOutsideAirNodeSingles: Int
    var NumNums: Int
    var NumAlphas: Int
    var NumParams: Int
    var NodeNums: Array1D_int
    var NumNodes: Int
    var IOStat: Int
    var ListSize: Int
    var ErrorsFound: Bool
    var ErrInList: Bool
    var CurSize: Int
    var NextFluidStreamNum: Int
    var TmpNums: Array1D_int
    var CurrentModuleObject: String
    var Alphas: Array1D_string
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var Numbers: Array1D_Real64
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    var MaxNums: Int = 0
    var MaxAlphas: Int = 0
    var TotalArgs: Int = 0

    NumOutAirInletNodeLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "OutdoorAir:NodeList")
    NumOutsideAirNodeSingles = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "OutdoorAir:Node")
    state.dataOutAirNodeMgr.NumOutsideAirNodes = 0
    ErrorsFound = False
    NextFluidStreamNum = 1
    ListSize = 0
    CurSize = 100
    TmpNums.dimension(CurSize, 0)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNums)
    NodeNums.dimension(NumParams, 0)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "OutdoorAir:NodeList", TotalArgs, NumAlphas, NumNums)
    MaxNums = max(MaxNums, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "OutdoorAir:Node", TotalArgs, NumAlphas, NumNums)
    MaxNums = max(MaxNums, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    Alphas.allocate(MaxAlphas)
    cAlphaFields.allocate(MaxAlphas)
    cNumericFields.allocate(MaxNums)
    Numbers.dimension(MaxNums, 0.0)
    lAlphaBlanks.dimension(MaxAlphas, True)
    lNumericBlanks.dimension(MaxNums, True)

    if NumOutAirInletNodeLists > 0:
        CurrentModuleObject = "OutdoorAir:NodeList"
        for OutAirInletNodeListNum in range(1, NumOutAirInletNodeLists + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                   CurrentModuleObject,
                                                                   OutAirInletNodeListNum,
                                                                   Alphas,
                                                                   NumAlphas,
                                                                   Numbers,
                                                                   NumNums,
                                                                   IOStat,
                                                                   lNumericBlanks,
                                                                   lAlphaBlanks,
                                                                   cAlphaFields,
                                                                   cNumericFields)
            for AlphaNum in range(1, NumAlphas + 1):
                ErrInList = False
                GetNodeNums(state,
                            Alphas[AlphaNum - 1],
                            NumNodes,
                            NodeNums,
                            ErrInList,
                            Node.FluidType.Air,
                            Node.ConnectionObjectType.OutdoorAirNodeList,
                            CurrentModuleObject,
                            Node.ConnectionType.OutsideAir,
                            Node.CompFluidStream(NextFluidStreamNum),
                            Node.ObjectIsNotParent,
                            Node.IncrementFluidStreamYes,
                            cAlphaFields[AlphaNum - 1])
                NextFluidStreamNum += NumNodes
                if ErrInList:
                    ShowContinueError(state,
                                      format("Occurred in {}, {} = {}", CurrentModuleObject, cAlphaFields[AlphaNum - 1], Alphas[AlphaNum - 1]))
                    ErrorsFound = True
                for NodeNum in range(1, NumNodes + 1):
                    if not any_eq(TmpNums, NodeNums[NodeNum - 1]):
                        ListSize += 1
                        if ListSize > CurSize:
                            CurSize += 100
                            TmpNums.redimension(CurSize, 0)
                        TmpNums[ListSize - 1] = NodeNums[NodeNum - 1]
        if ErrorsFound:
            ShowFatalError(state, format("{}Errors found in getting {} input.", RoutineName, CurrentModuleObject))

    if NumOutsideAirNodeSingles > 0:
        CurrentModuleObject = "OutdoorAir:Node"
        for OutsideAirNodeSingleNum in range(1, NumOutsideAirNodeSingles + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                   CurrentModuleObject,
                                                                   OutsideAirNodeSingleNum,
                                                                   Alphas,
                                                                   NumAlphas,
                                                                   Numbers,
                                                                   NumNums,
                                                                   IOStat,
                                                                   lNumericBlanks,
                                                                   lAlphaBlanks,
                                                                   cAlphaFields,
                                                                   cNumericFields)
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
            ErrInList = False
            GetNodeNums(state,
                        Alphas[0],
                        NumNodes,
                        NodeNums,
                        ErrInList,
                        Node.FluidType.Air,
                        Node.ConnectionObjectType.OutdoorAirNode,
                        CurrentModuleObject,
                        Node.ConnectionType.OutsideAir,
                        Node.CompFluidStream(NextFluidStreamNum),
                        Node.ObjectIsNotParent,
                        Node.IncrementFluidStreamYes,
                        cAlphaFields[0])
            NextFluidStreamNum += NumNodes
            if ErrInList:
                ShowContinueError(state, format("Occurred in {}, {} = {}", CurrentModuleObject, cAlphaFields[0], Alphas[0]))
                ErrorsFound = True
            if NumNodes > 1:
                ShowSevereError(state, format("{}, {} = {}", CurrentModuleObject, cAlphaFields[0], Alphas[0]))
                ShowContinueError(state, "...appears to point to a node list, not a single node.")
                ErrorsFound = True
                continue
            if not any_eq(TmpNums, NodeNums[0]):
                ListSize += 1
                if ListSize > CurSize:
                    CurSize += 100
                    TmpNums.redimension(CurSize, 0)
                TmpNums[ListSize - 1] = NodeNums[0]
            else:
                ShowSevereError(state, format("{}, duplicate {} = {}", CurrentModuleObject, cAlphaFields[0], Alphas[0]))
                ShowContinueError(state, format("Duplicate {} might be found in an OutdoorAir:NodeList.", cAlphaFields[0]))
                ErrorsFound = True
                continue
            if NumNums > 0:
                state.dataLoopNodes.Node[NodeNums[0] - 1].Height = Numbers[0]
            if NumAlphas > 1:
                state.dataGlobal.AnyLocalEnvironmentsInModel = True
            if NumAlphas <= 1 or lAlphaBlanks[1]:

            elif (state.dataLoopNodes.Node[NodeNums[0] - 1].outAirDryBulbSched = Sched.GetSchedule(state, Alphas[1])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                ErrorsFound = True
            if NumAlphas <= 2 or lAlphaBlanks[2]:

            elif (state.dataLoopNodes.Node[NodeNums[0] - 1].outAirWetBulbSched = Sched.GetSchedule(state, Alphas[2])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
                ErrorsFound = True
            if NumAlphas <= 3 or lAlphaBlanks[3]:

            elif (state.dataLoopNodes.Node[NodeNums[0] - 1].outAirWindSpeedSched = Sched.GetSchedule(state, Alphas[3])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[3], Alphas[3])
                ErrorsFound = True
            if NumAlphas <= 4 or lAlphaBlanks[4]:

            elif (state.dataLoopNodes.Node[NodeNums[0] - 1].outAirWindDirSched = Sched.GetSchedule(state, Alphas[4])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[4], Alphas[4])
                ErrorsFound = True
            if NumAlphas > 8:
                ShowSevereError(state, format("{}, {} = {}", CurrentModuleObject, cAlphaFields[0], Alphas[0]))
                ShowContinueError(state, "Object Definition indicates more than 7 Alpha Objects.")
                ErrorsFound = True
                continue
            if state.dataLoopNodes.Node[NodeNums[0] - 1].outAirDryBulbSched != None or state.dataLoopNodes.Node[NodeNums[0] - 1].outAirWetBulbSched != None:
                state.dataLoopNodes.Node[NodeNums[0] - 1].IsLocalNode = True
        if ErrorsFound:
            ShowFatalError(state, format("{}Errors found in getting {} input.", RoutineName, CurrentModuleObject))

    if ListSize > 0:
        state.dataOutAirNodeMgr.NumOutsideAirNodes = ListSize
        state.dataOutAirNodeMgr.OutsideAirNodeList = TmpNums[{1, Int(ListSize)}]

def InitOutAirNodes(inout state: EnergyPlusData):
    for OutsideAirNodeNum in range(1, state.dataOutAirNodeMgr.NumOutsideAirNodes + 1):
        var NodeNum: Int = state.dataOutAirNodeMgr.OutsideAirNodeList[OutsideAirNodeNum - 1]
        SetOANodeValues(state, NodeNum, True)

def CheckOutAirNodeNumber(inout state: EnergyPlusData, NodeNumber: Int) -> Bool:
    var Okay: Bool
    if state.dataOutAirNodeMgr.GetOutAirNodesInputFlag:
        GetOutAirNodesInput(state)
        state.dataOutAirNodeMgr.GetOutAirNodesInputFlag = False
        SetOutAirNodes(state)
    if any_eq(state.dataOutAirNodeMgr.OutsideAirNodeList, NodeNumber):
        Okay = True
    else:
        Okay = False
    return Okay

def CheckAndAddAirNodeNumber(inout state: EnergyPlusData,
                            NodeNumber: Int,
                            inout Okay: Bool):
    var TmpNums: Array1D_int
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
            state.dataOutAirNodeMgr.OutsideAirNodeList.redimension(state.dataOutAirNodeMgr.NumOutsideAirNodes)
            state.dataOutAirNodeMgr.OutsideAirNodeList[state.dataOutAirNodeMgr.NumOutsideAirNodes - 1] = NodeNumber
            TmpNums = state.dataOutAirNodeMgr.OutsideAirNodeList
            var errFlag: Bool = False
            var DummyNumber: Int
            GetNodeNums(state,
                        state.dataLoopNodes.NodeID[NodeNumber - 1],
                        DummyNumber,
                        TmpNums,
                        errFlag,
                        Node.FluidType.Air,
                        Node.ConnectionObjectType.OutdoorAirNode,
                        "OutdoorAir:Node",
                        Node.ConnectionType.OutsideAir,
                        Node.CompFluidStream(state.dataOutAirNodeMgr.NumOutsideAirNodes),
                        Node.ObjectIsNotParent,
                        Node.IncrementFluidStreamYes)
            SetOANodeValues(state, NodeNumber, False)

def SetOANodeValues(inout state: EnergyPlusData,
                   NodeNum: Int,
                   InitCall: Bool):
    if state.dataLoopNodes.Node[NodeNum - 1].Height < 0.0:
        state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb = state.dataEnvrn.OutDryBulbTemp
        state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = state.dataEnvrn.OutWetBulbTemp
        if InitCall:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindSpeed = state.dataEnvrn.WindSpeed
    else:
        state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb = OutDryBulbTempAt(state, state.dataLoopNodes.Node[NodeNum - 1].Height)
        state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = OutWetBulbTempAt(state, state.dataLoopNodes.Node[NodeNum - 1].Height)
        if InitCall:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindSpeed = WindSpeedAt(state, state.dataLoopNodes.Node[NodeNum - 1].Height)
    if not InitCall:
        state.dataLoopNodes.Node[NodeNum - 1].OutAirWindSpeed = state.dataEnvrn.WindSpeed
    state.dataLoopNodes.Node[NodeNum - 1].OutAirWindDir = state.dataEnvrn.WindDir
    if InitCall:
        if state.dataLoopNodes.Node[NodeNum - 1].outAirDryBulbSched != None:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb = state.dataLoopNodes.Node[NodeNum - 1].outAirDryBulbSched.getCurrentVal()
        if state.dataLoopNodes.Node[NodeNum - 1].outAirWetBulbSched != None:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = state.dataLoopNodes.Node[NodeNum - 1].outAirWetBulbSched.getCurrentVal()
        if state.dataLoopNodes.Node[NodeNum - 1].outAirWindSpeedSched != None:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindSpeed = state.dataLoopNodes.Node[NodeNum - 1].outAirWindSpeedSched.getCurrentVal()
        if state.dataLoopNodes.Node[NodeNum - 1].outAirWindDirSched != None:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindDir = state.dataLoopNodes.Node[NodeNum - 1].outAirWindDirSched.getCurrentVal()
        if state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirDryBulb:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb = state.dataLoopNodes.Node[NodeNum - 1].EMSValueForOutAirDryBulb
        if state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirWetBulb:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = state.dataLoopNodes.Node[NodeNum - 1].EMSValueForOutAirWetBulb
        if state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirWindSpeed:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindSpeed = state.dataLoopNodes.Node[NodeNum - 1].EMSValueForOutAirWindSpeed
        if state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirWindDir:
            state.dataLoopNodes.Node[NodeNum - 1].OutAirWindDir = state.dataLoopNodes.Node[NodeNum - 1].EMSValueForOutAirWindDir
    state.dataLoopNodes.Node[NodeNum - 1].Temp = state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb
    if state.dataLoopNodes.Node[NodeNum - 1].IsLocalNode or state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirDryBulb or state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirWetBulb:
        if InitCall:
            if state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb > state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb:
                state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb
            if state.dataLoopNodes.Node[NodeNum - 1].outAirWetBulbSched == None and not state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirWetBulb and (state.dataLoopNodes.Node[NodeNum - 1].EMSOverrideOutAirDryBulb or state.dataLoopNodes.Node[NodeNum - 1].outAirDryBulbSched != None):
                state.dataLoopNodes.Node[NodeNum - 1].HumRat = state.dataEnvrn.OutHumRat
                state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb = PsyTwbFnTdbWPb(state, state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb, state.dataEnvrn.OutHumRat, state.dataEnvrn.OutBaroPress)
            else:
                state.dataLoopNodes.Node[NodeNum - 1].HumRat = PsyWFnTdbTwbPb(state, state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb, state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb, state.dataEnvrn.OutBaroPress)
        else:
            state.dataLoopNodes.Node[NodeNum - 1].HumRat = PsyWFnTdbTwbPb(state, state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb, state.dataLoopNodes.Node[NodeNum - 1].OutAirWetBulb, state.dataEnvrn.OutBaroPress)
    else:
        state.dataLoopNodes.Node[NodeNum - 1].HumRat = state.dataEnvrn.OutHumRat
    state.dataLoopNodes.Node[NodeNum - 1].Enthalpy = PsyHFnTdbW(state.dataLoopNodes.Node[NodeNum - 1].OutAirDryBulb, state.dataLoopNodes.Node[NodeNum - 1].HumRat)
    state.dataLoopNodes.Node[NodeNum - 1].Press = state.dataEnvrn.OutBaroPress
    state.dataLoopNodes.Node[NodeNum - 1].Quality = 0.0
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[NodeNum - 1].CO2 = state.dataContaminantBalance.OutdoorCO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[NodeNum - 1].GenContam = state.dataContaminantBalance.OutdoorGC