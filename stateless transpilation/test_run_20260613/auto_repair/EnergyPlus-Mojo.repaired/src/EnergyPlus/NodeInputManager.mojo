# Adapted from C++ source: EnergyPlus/src/EnergyPlus/NodeInputManager.cc
# 1:1 translation, no refactoring.

from BranchNodeConnections import RegisterNodeConnection
from Data.EnergyPlusData import EnergyPlusData
from DataGlobals import Constant
from DataLoopNode import (Node, ConnectionObjectType, ConnectionType, CompFluidStream,
                            FluidType, NodeListDef, MoreNodeInfo)
from DataContaminantBalance import ContaminantBalance
from DataEnvironment import Environment
from DataErrorTracking import ErrorTracking
from EMSManager import CheckIfNodeMoreInfoSensedByEMS
from FluidProperties import Fluid, GetSteam, GlycolProps
from InputProcessing.InputProcessor import InputProcessor
from OutputProcessor import SetupOutputVariable, OutputProcessor, reqVars, TimeStepType, StoreType
from Psychrometrics import (PsyCpAirFnW, PsyHFnTdbW, PsyRhFnTdbWPb, PsyRhoAirFnPbTdbW,
                              PsyTdpFnWPb, PsyTwbFnTdbWPb, CPCW, RhoH2O)
from ScheduleManager import Schedule
from UtilityRoutines import Util
from Utils import format  # assuming Mojo's built-in format? or string interpolation

from NodeInputManager import (NodeInputManagerData, GetNodeNums, SetupNodeVarsForReporting,
                                 GetNodeListsInput, AssignNodeNumber, GetOnlySingleNode,
                                 InitUniqueNodeCheck, CheckUniqueNodeNames, CheckUniqueNodeNumbers,
                                 EndUniqueNodeCheck, CalcMoreNodeInfo, MarkNode, CheckMarkedNodes)

# The above imports are references; actual implementation in this file.

alias Node = EnergyPlus.Node
alias Constant = EnergyPlus.Constant
alias TimeStepType = OutputProcessor.TimeStepType
alias StoreType = OutputProcessor.StoreType

def GetNodeNums(state: EnergyPlusData, Name: String,
               ref NumNodes: Int, ref NodeNumbers: List[Int],
               ref ErrorsFound: Bool,
               nodeFluidType: Node.FluidType,
               NodeObjectType: Node.ConnectionObjectType,
               NodeObjectName: String,
               nodeConnectionType: Node.ConnectionType,
               NodeFluidStream: Node.CompFluidStream,
               ObjectIsParent: Bool,
               IncrementFluidStream: Bool = False,
               InputFieldName: StringLiteral = ""):
    alias RoutineName: StringLiteral = "GetNodeNums: "
    objTypeStr = Node.ConnectionObjectTypeNames[Int(NodeObjectType)]
    if state.dataNodeInputMgr.GetNodeInputFlag:
        GetNodeListsInput(state, ErrorsFound)
        state.dataNodeInputMgr.GetNodeInputFlag = False

    if nodeFluidType != Node.FluidType.Air and nodeFluidType != Node.FluidType.Water and nodeFluidType != Node.FluidType.Electric and nodeFluidType != Node.FluidType.Steam and nodeFluidType != Node.FluidType.Blank:
        ShowSevereError(state, f"{RoutineName}{objTypeStr}=\"{NodeObjectName}=\", invalid fluid type.")
        ShowContinueError(state, f"..Invalid FluidType={Node.FluidTypeNames[Int(nodeFluidType)]}")
        ErrorsFound = True
        ShowFatalError(state, "Preceding issue causes termination.")

    if not Name.empty():
        ThisOne = Util.FindItemInList(Name, state.dataNodeInputMgr.NodeLists)
        if ThisOne != 0:
            NumNodes = state.dataNodeInputMgr.NodeLists[ThisOne-1].NumOfNodesInList
            # Copy slice {1..NumNodes} to NodeNumbers
            # C++: NodeNumbers({1, NumNodes}) = state...NodeNumbers({1, NumNodes})
            for i in range(NumNodes):
                NodeNumbers[i] = state.dataNodeInputMgr.NodeLists[ThisOne-1].NodeNumbers[i]
            for Loop in range(1, NumNodes+1):
                idx = Loop - 1
                if nodeFluidType != Node.FluidType.Blank and state.dataLoopNodes.Node[NodeNumbers[Loop-1]-1].fluidType != Node.FluidType.Blank:
                    if state.dataLoopNodes.Node[NodeNumbers[Loop-1]-1].fluidType != nodeFluidType:
                        ShowSevereError(state, f"{RoutineName}{objTypeStr}=\"{NodeObjectName}=\", invalid data.")
                        if not InputFieldName.empty():
                            ShowContinueError(state, f"...Ref field={InputFieldName}")
                        ShowContinueError(state, f"Existing Fluid type for node, incorrect for request. Node={state.dataLoopNodes.NodeID[NodeNumbers[Loop-1]]}")
                        ShowContinueError(state, f"Existing Fluid type={Node.FluidTypeNames[Int(state.dataLoopNodes.Node[NodeNumbers[Loop-1]-1].fluidType)]}, Requested Fluid Type={Node.FluidTypeNames[Int(nodeFluidType)]}")
                        ErrorsFound = True
                if state.dataLoopNodes.Node[NodeNumbers[Loop-1]-1].fluidType == Node.FluidType.Blank:
                    state.dataLoopNodes.Node[NodeNumbers[Loop-1]-1].fluidType = nodeFluidType
                state.dataNodeInputMgr.NodeRef[NodeNumbers[Loop-1]-1] += 1
        else:
            ThisOne = AssignNodeNumber(state, Name, nodeFluidType, ErrorsFound)
            NumNodes = 1
            NodeNumbers[0] = ThisOne
    else:
        NumNodes = 0
        NodeNumbers[0] = 0

    FluidStreamNum = NodeFluidStream
    for Loop in range(1, NumNodes+1):
        if IncrementFluidStream:
            FluidStreamNum = Node.CompFluidStream(Int(NodeFluidStream) + (Loop - 1))
        RegisterNodeConnection(state,
                               NodeNumbers[Loop-1],
                               state.dataLoopNodes.NodeID[NodeNumbers[Loop-1]-1],
                               NodeObjectType,
                               NodeObjectName,
                               nodeConnectionType,
                               FluidStreamNum,
                               ObjectIsParent,
                               ErrorsFound,
                               InputFieldName)

def SetupNodeVarsForReporting(state: EnergyPlusData):
    if not state.dataNodeInputMgr.NodeVarsSetup:
        if not state.dataErrTracking.AbortProcessing:
            state.dataLoopNodes.MoreNodeInfo.allocate(state.dataNodeInputMgr.NumOfUniqueNodeNames)
            for NumNode in range(1, state.dataNodeInputMgr.NumOfUniqueNodeNames+1):
                Node = state.dataLoopNodes.Node[NumNode-1]
                NodeID = state.dataLoopNodes.NodeID[NumNode-1]
                SetupOutputVariable(state,
                                    "System Node Temperature",
                                    Constant.Units.C,
                                    Node.Temp,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Mass Flow Rate",
                                    Constant.Units.kg_s,
                                    Node.MassFlowRate,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Humidity Ratio",
                                    Constant.Units.kgWater_kgDryAir,
                                    Node.HumRat,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint Temperature",
                                    Constant.Units.C,
                                    Node.TempSetPoint,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint High Temperature",
                                    Constant.Units.C,
                                    Node.TempSetPointHi,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint Low Temperature",
                                    Constant.Units.C,
                                    Node.TempSetPointLo,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint Humidity Ratio",
                                    Constant.Units.kgWater_kgDryAir,
                                    Node.HumRatSetPoint,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint Minimum Humidity Ratio",
                                    Constant.Units.kgWater_kgDryAir,
                                    Node.HumRatMin,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Setpoint Maximum Humidity Ratio",
                                    Constant.Units.kgWater_kgDryAir,
                                    Node.HumRatMax,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Relative Humidity",
                                    Constant.Units.Perc,
                                    state.dataLoopNodes.MoreNodeInfo[NumNode-1].RelHumidity,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Pressure",
                                    Constant.Units.Pa,
                                    Node.Press,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Standard Density Volume Flow Rate",
                                    Constant.Units.m3_s,
                                    state.dataLoopNodes.MoreNodeInfo[NumNode-1].VolFlowRateStdRho,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                if Node.fluidType == Node.FluidType.Air or Node.fluidType == Node.FluidType.Water:
                    SetupOutputVariable(state,
                                        "System Node Current Density Volume Flow Rate",
                                        Constant.Units.m3_s,
                                        state.dataLoopNodes.MoreNodeInfo[NumNode-1].VolFlowRateCrntRho,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Current Density",
                                        Constant.Units.kg_m3,
                                        state.dataLoopNodes.MoreNodeInfo[NumNode-1].Density,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Specific Heat",
                                        Constant.Units.J_kgK,
                                        state.dataLoopNodes.MoreNodeInfo[NumNode-1].SpecificHeat,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                SetupOutputVariable(state,
                                    "System Node Enthalpy",
                                    Constant.Units.J_kg,
                                    state.dataLoopNodes.MoreNodeInfo[NumNode-1].ReportEnthalpy,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Wetbulb Temperature",
                                    Constant.Units.C,
                                    state.dataLoopNodes.MoreNodeInfo[NumNode-1].WetBulbTemp,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Dewpoint Temperature",
                                    Constant.Units.C,
                                    state.dataLoopNodes.MoreNodeInfo[NumNode-1].AirDewPointTemp,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Wind Speed",
                                    Constant.Units.m_s,
                                    Node.OutAirWindSpeed,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Wind Direction",
                                    Constant.Units.deg,
                                    Node.OutAirWindDir,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Quality",
                                    Constant.Units.None,
                                    Node.Quality,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                SetupOutputVariable(state,
                                    "System Node Height",
                                    Constant.Units.m,
                                    Node.Height,
                                    TimeStepType.System,
                                    StoreType.Average,
                                    NodeID)
                if state.dataGlobal.DisplayAdvancedReportVariables:
                    SetupOutputVariable(state,
                                        "System Node Minimum Temperature",
                                        Constant.Units.C,
                                        Node.TempMin,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Maximum Temperature",
                                        Constant.Units.C,
                                        Node.TempMax,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Minimum Limit Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateMin,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Maximum Limit Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateMax,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Minimum Available Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateMinAvail,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Maximum Available Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateMaxAvail,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Setpoint Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateSetPoint,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Requested Mass Flow Rate",
                                        Constant.Units.kg_s,
                                        Node.MassFlowRateRequest,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Last Timestep Temperature",
                                        Constant.Units.C,
                                        Node.TempLastTimestep,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                    SetupOutputVariable(state,
                                        "System Node Last Timestep Enthalpy",
                                        Constant.Units.J_kg,
                                        Node.EnthalpyLastTimestep,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    SetupOutputVariable(state,
                                        "System Node CO2 Concentration",
                                        Constant.Units.ppm,
                                        Node.CO2,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)
                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    SetupOutputVariable(state,
                                        "System Node Generic Air Contaminant Concentration",
                                        Constant.Units.ppm,
                                        Node.GenContam,
                                        TimeStepType.System,
                                        StoreType.Average,
                                        NodeID)

        state.dataNodeInputMgr.NodeVarsSetup = True
        state.files.bnd.print("! This file shows details about the branches, nodes, and other")
        state.files.bnd.print("! elements of the flow connections.")
        state.files.bnd.print("! This file is intended for use in \"debugging\" potential problems")
        state.files.bnd.print("! that may also be detected by the program, but may be more easily")
        state.files.bnd.print("! identified by \"eye\".")
        state.files.bnd.print("! This file is also intended to support software which draws a")
        state.files.bnd.print("! schematic diagram of the HVAC system.")
        state.files.bnd.print("! ===============================================================")
        alias Format_700: StringLiteral = "! #Nodes,<Number of Unique Nodes>"
        state.files.bnd.print(f"{Format_700}\n")
        state.files.bnd.print(f" #Nodes,{state.dataNodeInputMgr.NumOfUniqueNodeNames}\n")
        if state.dataNodeInputMgr.NumOfUniqueNodeNames > 0:
            alias Format_702: StringLiteral = "! <Node>,<NodeNumber>,<Node Name>,<Node Fluid Type>,<# Times Node Referenced After Definition>"
            state.files.bnd.print(f"{Format_702}\n")
        Count0 = 0
        for NumNode in range(1, state.dataNodeInputMgr.NumOfUniqueNodeNames+1):
            Node = state.dataLoopNodes.Node[NumNode-1]
            NodeID = state.dataLoopNodes.NodeID[NumNode-1]
            state.files.bnd.print(f" Node,{NumNode},{NodeID},{Node.FluidTypeNames[Int(Node.fluidType)]},{state.dataNodeInputMgr.NodeRef[NumNode-1]}\n")
            if state.dataNodeInputMgr.NodeRef[NumNode-1] == 0:
                Count0 += 1
        if Count0 > 0:
            state.files.bnd.print("! ===============================================================\n")
            state.files.bnd.print("! Suspicious nodes have 0 references.  It is normal for some nodes, however.\n")
            state.files.bnd.print("! Listing nodes with 0 references (culled from previous list):\n")
            alias Format_703: StringLiteral = "! <Suspicious Node>,<NodeNumber>,<Node Name>,<Node Fluid Type>,<# Times Node Referenced After Definition>"
            state.files.bnd.print(f"{Format_703}\n")
            for NumNode in range(1, state.dataNodeInputMgr.NumOfUniqueNodeNames+1):
                Node = state.dataLoopNodes.Node[NumNode-1]
                NodeID = state.dataLoopNodes.NodeID[NumNode-1]
                if state.dataNodeInputMgr.NodeRef[NumNode-1] > 0:
                    continue
                state.files.bnd.print(f" Suspicious Node,{NumNode},{NodeID},{Node.FluidTypeNames[Int(Node.fluidType)]},{state.dataNodeInputMgr.NodeRef[NumNode-1]}\n")

def GetNodeListsInput(state: EnergyPlusData, ref ErrorsFound: Bool):
    alias RoutineName: StringLiteral = "GetNodeListsInput: "
    var CurrentModuleObject: String = "NodeList"
    var NumAlphas: Int
    var NumNumbers: Int
    var IOStatus: Int
    var NCount: Int
    var flagError: Bool
    var localErrorsFound: Bool = False
    var cAlphas: List[String]
    var rNumbers: List[Float64]

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NCount, NumAlphas, NumNumbers)
    cAlphas = List[String](size=NumAlphas, fill="")
    rNumbers = List[Float64](size=NumNumbers, fill=0.0)

    state.dataNodeInputMgr.NumOfNodeLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataNodeInputMgr.NodeLists = List[Node.NodeListDef](size=state.dataNodeInputMgr.NumOfNodeLists)
    for i in range(1, state.dataNodeInputMgr.NumOfNodeLists+1):
        state.dataNodeInputMgr.NodeLists[i-1].Name.clear()
        state.dataNodeInputMgr.NodeLists[i-1].NumOfNodesInList = 0

    NCount = 0
    for Loop in range(1, state.dataNodeInputMgr.NumOfNodeLists+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Loop, cAlphas, NumAlphas, rNumbers, NumNumbers, IOStatus)
        NCount += 1
        state.dataNodeInputMgr.NodeLists[NCount-1].Name = cAlphas[0]  # cAlphas(1) -> index 0
        # allocate NodeNames and NodeNumbers with size NumAlphas - 1
        nodeList = state.dataNodeInputMgr.NodeLists[NCount-1]
        nodeList.NodeNames = List[String](size=NumAlphas - 1, fill="")
        nodeList.NodeNumbers = List[Int](size=NumAlphas - 1, fill=0)
        nodeList.NumOfNodesInList = NumAlphas - 1
        if NumAlphas <= 1:
            if NumAlphas == 1:
                ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{cAlphas[0]}\" does not have any nodes.")
            else:
                ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=<blank> does not have any nodes or nodelist name.")
            localErrorsFound = True
            continue
        for Loop1 in range(1, NumAlphas):  # Loop1 from 1 to NumAlphas-1
            nodeList.NodeNames[Loop1-1] = cAlphas[Loop1]  # cAlphas(Loop1+1) -> index Loop1
            if cAlphas[Loop1].empty():
                ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{cAlphas[0]}\", blank node name in list.")
                nodeList.NumOfNodesInList -= 1
                if nodeList.NumOfNodesInList <= 0:
                    ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{cAlphas[0]}\" does not have any nodes.")
                    localErrorsFound = True
                    break
                continue
            nodeList.NodeNumbers[Loop1-1] = AssignNodeNumber(state, nodeList.NodeNames[Loop1-1], Node.FluidType.Blank, localErrorsFound)
            if Util.SameString(nodeList.NodeNames[Loop1-1], nodeList.Name):
                ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{cAlphas[0]}\", invalid node name in list.")
                ShowContinueError(state, f"... Node {Loop1} Name=\"{cAlphas[Loop1]}\", duplicates NodeList Name.")
                localErrorsFound = True

        flagError = True
        for Loop1 in range(1, nodeList.NumOfNodesInList+1):
            for Loop2 in range(Loop1+1, nodeList.NumOfNodesInList+1):
                if nodeList.NodeNumbers[Loop1-1] != nodeList.NodeNumbers[Loop2-1]:
                    continue
                if flagError:
                    ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{cAlphas[0]}\" has duplicate nodes:")
                    flagError = False
                ShowContinueError(state, f"...list item={Loop1}, \"{state.dataLoopNodes.NodeID[nodeList.NodeNumbers[Loop1-1]-1]}\", duplicate list item={Loop2}, \"{state.dataLoopNodes.NodeID[nodeList.NodeNumbers[Loop2-1]-1]}\".")
                localErrorsFound = True

    for Loop in range(1, state.dataNodeInputMgr.NumOfNodeLists+1):
        for Loop2 in range(1, state.dataNodeInputMgr.NodeLists[Loop-1].NumOfNodesInList+1):
            for Loop1 in range(1, state.dataNodeInputMgr.NumOfNodeLists+1):
                if Loop == Loop1:
                    continue
                if not Util.SameString(state.dataNodeInputMgr.NodeLists[Loop-1].NodeNames[Loop2-1], state.dataNodeInputMgr.NodeLists[Loop1-1].Name):
                    continue
                ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{state.dataNodeInputMgr.NodeLists[Loop1-1].Name}\", invalid node name in list.")
                ShowContinueError(state, f"... Node {Loop2} Name=\"{state.dataNodeInputMgr.NodeLists[Loop-1].NodeNames[Loop2-1]}\", duplicates NodeList Name.")
                ShowContinueError(state, f"... NodeList=\"{state.dataNodeInputMgr.NodeLists[Loop1-1].Name}\", is duplicated.")
                ShowContinueError(state, "... Items in NodeLists must not be the name of another NodeList.")
                localErrorsFound = True

    cAlphas = List[String]()
    rNumbers = List[Float64]()
    if localErrorsFound:
        ShowFatalError(state, f"{RoutineName}{CurrentModuleObject}: Error getting input - causes termination.")
        ErrorsFound = True

def AssignNodeNumber(state: EnergyPlusData, Name: String,
                    nodeFluidType: Node.FluidType,
                    ref ErrorsFound: Bool) -> Int:
    # Return value
    if nodeFluidType != Node.FluidType.Air and nodeFluidType != Node.FluidType.Water and nodeFluidType != Node.FluidType.Electric and nodeFluidType != Node.FluidType.Steam and nodeFluidType != Node.FluidType.Blank:
        ShowSevereError(state, f"AssignNodeNumber: Invalid FluidType={Node.FluidTypeNames[Int(nodeFluidType)]}")
        ErrorsFound = True
        ShowFatalError(state, "AssignNodeNumber: Preceding issue causes termination.")

    if state.dataNodeInputMgr.NumOfUniqueNodeNames > 0:
        # FindItemInList over NodeID slice (1..NumOfUniqueNodeNames)
        NumNode = Util.FindItemInList(Name,
                                     state.dataLoopNodes.NodeID[0:state.dataNodeInputMgr.NumOfUniqueNodeNames],
                                     state.dataNodeInputMgr.NumOfUniqueNodeNames)
        if NumNode > 0:
            result = NumNode  # 1-based index from FindItemInList
            state.dataNodeInputMgr.NodeRef[result-1] += 1
            if nodeFluidType != Node.FluidType.Blank:
                if state.dataLoopNodes.Node[result-1].fluidType != nodeFluidType and state.dataLoopNodes.Node[result-1].fluidType != Node.FluidType.Blank:
                    ShowSevereError(state, f"Existing Fluid type for node, incorrect for request. Node={state.dataLoopNodes.NodeID[result-1]}")
                    ShowContinueError(state, f"Existing Fluid type={Node.FluidTypeNames[Int(state.dataLoopNodes.Node[result-1].fluidType)]}, Requested Fluid Type={Node.FluidTypeNames[Int(nodeFluidType)]}")
                    ErrorsFound = True
            if state.dataLoopNodes.Node[result-1].fluidType == Node.FluidType.Blank:
                state.dataLoopNodes.Node[result-1].fluidType = nodeFluidType
            return result
        else:
            state.dataNodeInputMgr.NumOfUniqueNodeNames += 1
            state.dataLoopNodes.NumOfNodes = state.dataNodeInputMgr.NumOfUniqueNodeNames
            state.dataLoopNodes.Node.redimension(state.dataLoopNodes.NumOfNodes)
            state.dataLoopNodes.NodeID.redimension(0, state.dataLoopNodes.NumOfNodes)
            state.dataNodeInputMgr.NodeRef.redimension(state.dataLoopNodes.NumOfNodes)
            state.dataLoopNodes.MarkedNode.redimension(state.dataLoopNodes.NumOfNodes)
            state.dataLoopNodes.NodeSetpointCheck.redimension(state.dataLoopNodes.NumOfNodes)
            state.dataLoopNodes.Node[state.dataLoopNodes.NumOfNodes-1].fluidType = nodeFluidType
            state.dataNodeInputMgr.NodeRef[state.dataLoopNodes.NumOfNodes-1] = 0
            state.dataLoopNodes.NodeID[state.dataNodeInputMgr.NumOfUniqueNodeNames-1] = Name
            return state.dataNodeInputMgr.NumOfUniqueNodeNames
    else:
        state.dataLoopNodes.Node.allocate(1)
        state.dataLoopNodes.Node[0].fluidType = nodeFluidType
        state.dataLoopNodes.NumOfNodes = 1
        state.dataLoopNodes.NodeID.allocate(0, 1)
        state.dataNodeInputMgr.NodeRef.allocate(1)
        state.dataLoopNodes.MarkedNode.allocate(1)
        state.dataLoopNodes.NodeSetpointCheck.allocate(1)
        state.dataNodeInputMgr.NumOfUniqueNodeNames = 1
        state.dataLoopNodes.NodeID[0] = "Undefined"
        state.dataLoopNodes.NodeID[1-1] = Name  # index 0? Actually NodeID(1) -> NodeID[0]
        return 1
        state.dataNodeInputMgr.NodeRef[0] = 0

def GetOnlySingleNode(state: EnergyPlusData, NodeName: String,
                     ref errFlag: Bool,
                     NodeObjectType: Node.ConnectionObjectType,
                     NodeObjectName: String,
                     nodeFluidType: Node.FluidType,
                     nodeConnectionType: Node.ConnectionType,
                     NodeFluidStream: Node.CompFluidStream,
                     ObjectIsParent: Bool,
                     InputFieldName: StringLiteral = "") -> Int:
    alias RoutineName: StringLiteral = "GetOnlySingleNode: "
    var NumNodes: Int
    objTypeStr = Node.ConnectionObjectTypeNames[Int(NodeObjectType)]
    if state.dataNodeInputMgr.GetOnlySingleNodeFirstTime:
        var NumParams: Int
        var NumAlphas: Int
        var NumNums: Int
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNums)
        state.dataNodeInputMgr.GetOnlySingleNodeNodeNums.dimension(NumParams, 0)
        state.dataNodeInputMgr.GetOnlySingleNodeFirstTime = False

    GetNodeNums(state, NodeName, NumNodes, state.dataNodeInputMgr.GetOnlySingleNodeNodeNums,
                errFlag, nodeFluidType, NodeObjectType, NodeObjectName,
                nodeConnectionType, NodeFluidStream, ObjectIsParent, False, InputFieldName)

    if NumNodes > 1:
        ShowSevereError(state, f"{RoutineName}{objTypeStr}=\"{NodeObjectName}=\", invalid data.")
        if not InputFieldName.empty():
            ShowContinueError(state, f"...Ref field={InputFieldName}")
        ShowContinueError(state, f"Only 1st Node used from NodeList=\"{NodeName}\".")
        ShowContinueError(state, "...a Nodelist may not be valid in this context.")
        errFlag = True
    elif NumNodes == 0:
        state.dataNodeInputMgr.GetOnlySingleNodeNodeNums[0] = 0

    return state.dataNodeInputMgr.GetOnlySingleNodeNodeNums[0]

def InitUniqueNodeCheck(state: EnergyPlusData, ContextName: String):
    if state.dataNodeInputMgr.GetNodeInputFlag:
        var errFlag: Bool = False
        GetNodeListsInput(state, errFlag)
        state.dataNodeInputMgr.GetNodeInputFlag = False

    if not state.dataNodeInputMgr.CurCheckContextName.empty():
        ShowFatalError(state,
                       f"Init Uniqueness called for \"{ContextName}, but checks for \"{state.dataNodeInputMgr.CurCheckContextName}\" was already in progress.")
    if ContextName.empty():
        ShowFatalError(state, "Init Uniqueness called with Blank Context Name")

    if allocated(state.dataNodeInputMgr.UniqueNodeNames):
        state.dataNodeInputMgr.UniqueNodeNames.deallocate()

    state.dataNodeInputMgr.NumCheckNodes = 0
    state.dataNodeInputMgr.MaxCheckNodes = 100
    state.dataNodeInputMgr.UniqueNodeNames.allocate(state.dataNodeInputMgr.MaxCheckNodes)
    state.dataNodeInputMgr.CurCheckContextName = ContextName

def CheckUniqueNodeNames(state: EnergyPlusData, NodeTypes: String,
                        ref ErrorsFound: Bool,
                        CheckName: String, ObjectName: String):
    if not CheckName.empty():
        Found = Util.FindItemInList(CheckName, state.dataNodeInputMgr.UniqueNodeNames, state.dataNodeInputMgr.NumCheckNodes)
        if Found != 0:
            ShowSevereError(state, f"{state.dataNodeInputMgr.CurCheckContextName}=\"{ObjectName}\", duplicate node names found.")
            ShowContinueError(state, f"...for Node Type(s)={NodeTypes}, duplicate node name=\"{CheckName}\".")
            ShowContinueError(state, "...Nodes must be unique across instances of this object.")
            ErrorsFound = True
        else:
            state.dataNodeInputMgr.NumCheckNodes += 1
            if state.dataNodeInputMgr.NumCheckNodes > state.dataNodeInputMgr.MaxCheckNodes:
                state.dataNodeInputMgr.UniqueNodeNames.redimension(state.dataNodeInputMgr.MaxCheckNodes += 100)
            state.dataNodeInputMgr.UniqueNodeNames[state.dataNodeInputMgr.NumCheckNodes-1] = CheckName

def CheckUniqueNodeNumbers(state: EnergyPlusData, NodeTypes: String,
                          ref ErrorsFound: Bool,
                          CheckNumber: Int, ObjectName: String):
    if CheckNumber != 0:
        Found = Util.FindItemInList(state.dataLoopNodes.NodeID[CheckNumber-1],
                                   state.dataNodeInputMgr.UniqueNodeNames,
                                   state.dataNodeInputMgr.NumCheckNodes)
        if Found != 0:
            ShowSevereError(state, f"{state.dataNodeInputMgr.CurCheckContextName}=\"{ObjectName}\", duplicate node names found.")
            ShowContinueError(state, f"...for Node Type(s)={NodeTypes}, duplicate node name=\"{state.dataLoopNodes.NodeID[CheckNumber-1]}\".")
            ShowContinueError(state, "...Nodes must be unique across instances of this object.")
            ErrorsFound = True
        else:
            state.dataNodeInputMgr.NumCheckNodes += 1
            if state.dataNodeInputMgr.NumCheckNodes > state.dataNodeInputMgr.MaxCheckNodes:
                state.dataNodeInputMgr.UniqueNodeNames.redimension(state.dataNodeInputMgr.MaxCheckNodes += 100)
            state.dataNodeInputMgr.UniqueNodeNames[state.dataNodeInputMgr.NumCheckNodes-1] = state.dataLoopNodes.NodeID[CheckNumber-1]

def EndUniqueNodeCheck(state: EnergyPlusData, ContextName: String):
    if state.dataNodeInputMgr.CurCheckContextName != ContextName:
        ShowFatalError(state,
                       f"End Uniqueness called for \"{ContextName}, but checks for \"{state.dataNodeInputMgr.CurCheckContextName}\" was in progress.")
    if ContextName.empty():
        ShowFatalError(state, "End Uniqueness called with Blank Context Name")

    state.dataNodeInputMgr.CurCheckContextName = ""
    if allocated(state.dataNodeInputMgr.UniqueNodeNames):
        state.dataNodeInputMgr.UniqueNodeNames.deallocate()

def CalcMoreNodeInfo(state: EnergyPlusData):
    alias RoutineName: StringLiteral = "CalcMoreNodeInfo"
    var NodeReportingCalc: String = "NodeReportingCalc:"
    RhoAirStdInit = state.dataNodeInputMgr.RhoAirStdInit
    RhoWaterStdInit = state.dataNodeInputMgr.RhoWaterStdInit
    NodeWetBulbScheds = state.dataNodeInputMgr.NodeWetBulbScheds
    NodeRelHumidityRepReq = state.dataNodeInputMgr.NodeRelHumidityRepReq
    NodeRelHumidityScheds = state.dataNodeInputMgr.NodeRelHumidityScheds
    NodeDewPointRepReq = state.dataNodeInputMgr.NodeDewPointRepReq
    NodeDewPointScheds = state.dataNodeInputMgr.NodeDewPointScheds
    NodeSpecificHeatRepReq = state.dataNodeInputMgr.NodeSpecificHeatRepReq
    NodeSpecificHeatScheds = state.dataNodeInputMgr.NodeSpecificHeatScheds
    nodeReportingStrings = state.dataNodeInputMgr.nodeReportingStrings
    nodeFluids = state.dataNodeInputMgr.nodeFluids

    var SteamDensity: Float64
    var EnthSteamInDry: Float64
    var RhoAirCurrent: Float64
    var rho: Float64
    var Cp: Float64
    var rhoStd: Float64

    if state.dataNodeInputMgr.CalcMoreNodeInfoMyOneTimeFlag:
        RhoAirStdInit = state.dataEnvrn.StdRhoAir
        RhoWaterStdInit = RhoH2O(Constant.InitConvTemp)
        state.dataNodeInputMgr.NodeWetBulbRepReq.allocate(state.dataLoopNodes.NumOfNodes)
        NodeWetBulbScheds.allocate(state.dataLoopNodes.NumOfNodes)
        NodeRelHumidityRepReq.allocate(state.dataLoopNodes.NumOfNodes)
        NodeRelHumidityScheds.allocate(state.dataLoopNodes.NumOfNodes)
        NodeDewPointRepReq.allocate(state.dataLoopNodes.NumOfNodes)
        NodeDewPointScheds.allocate(state.dataLoopNodes.NumOfNodes)
        NodeSpecificHeatRepReq.allocate(state.dataLoopNodes.NumOfNodes)
        NodeSpecificHeatScheds.allocate(state.dataLoopNodes.NumOfNodes)
        nodeReportingStrings.reserve(state.dataLoopNodes.NumOfNodes)
        nodeFluids.reserve(state.dataLoopNodes.NumOfNodes)
        state.dataNodeInputMgr.NodeWetBulbRepReq[:] = False
        for i in range(state.dataLoopNodes.NumOfNodes):
            NodeWetBulbScheds[i] = None
        NodeRelHumidityRepReq[:] = False
        for i in range(state.dataLoopNodes.NumOfNodes):
            NodeRelHumidityScheds[i] = None
        NodeDewPointRepReq[:] = False
        for i in range(state.dataLoopNodes.NumOfNodes):
            NodeDewPointScheds[i] = None
        NodeSpecificHeatRepReq[:] = False
        for i in range(state.dataLoopNodes.NumOfNodes):
            NodeSpecificHeatScheds[i] = None

        for iNode in range(1, state.dataLoopNodes.NumOfNodes+1):
            nodeReportingStrings.append(f"{NodeReportingCalc}{state.dataLoopNodes.NodeID[iNode-1]}")
            if state.dataLoopNodes.Node[iNode-1].FluidIndex == 0:
                nodeFluids.append(None)
            else:
                nodeFluids.append(state.dataFluid.glycols[state.dataLoopNodes.Node[iNode-1].FluidIndex - 1])

            for reqVar in state.dataOutputProcessor.reqVars:
                if Util.SameString(reqVar.key, state.dataLoopNodes.NodeID[iNode-1]) or reqVar.key.empty():
                    if Util.SameString(reqVar.name, "System Node Wetbulb Temperature"):
                        state.dataNodeInputMgr.NodeWetBulbRepReq[iNode-1] = True
                        NodeWetBulbScheds[iNode-1] = reqVar.sched
                    elif Util.SameString(reqVar.name, "System Node Relative Humidity"):
                        NodeRelHumidityRepReq[iNode-1] = True
                        NodeRelHumidityScheds[iNode-1] = reqVar.sched
                    elif Util.SameString(reqVar.name, "System Node Dewpoint Temperature"):
                        NodeDewPointRepReq[iNode-1] = True
                        NodeDewPointScheds[iNode-1] = reqVar.sched
                    elif Util.SameString(reqVar.name, "System Node Specific Heat"):
                        NodeSpecificHeatRepReq[iNode-1] = True
                        NodeSpecificHeatScheds[iNode-1] = reqVar.sched

            if CheckIfNodeMoreInfoSensedByEMS(state, iNode, "System Node Wetbulb Temperature"):
                state.dataNodeInputMgr.NodeWetBulbRepReq[iNode-1] = True
                NodeWetBulbScheds[iNode-1] = None
            if CheckIfNodeMoreInfoSensedByEMS(state, iNode, "System Node Relative Humidity"):
                NodeRelHumidityRepReq[iNode-1] = True
                NodeRelHumidityScheds[iNode-1] = None
            if CheckIfNodeMoreInfoSensedByEMS(state, iNode, "System Node Dewpoint Temperature"):
                NodeDewPointRepReq[iNode-1] = True
                NodeDewPointScheds[iNode-1] = None
            if CheckIfNodeMoreInfoSensedByEMS(state, iNode, "System Node Specific Heat"):
                NodeSpecificHeatRepReq[iNode-1] = True
                NodeSpecificHeatScheds[iNode-1] = None

        state.dataNodeInputMgr.CalcMoreNodeInfoMyOneTimeFlag = False

    for iNode in range(1, state.dataLoopNodes.NumOfNodes+1):
        ReportWetBulb = False
        ReportRelHumidity = False
        ReportDewPoint = False
        ReportSpecificHeat = False

        if state.dataNodeInputMgr.NodeWetBulbRepReq[iNode-1] and NodeWetBulbScheds[iNode-1] != None:
            ReportWetBulb = (NodeWetBulbScheds[iNode-1].getCurrentVal() > 0.0)
        elif state.dataNodeInputMgr.NodeWetBulbRepReq[iNode-1] and NodeWetBulbScheds[iNode-1] == None:
            ReportWetBulb = True
        elif state.dataLoopNodes.Node[iNode-1].SPMNodeWetBulbRepReq:
            ReportWetBulb = True

        if NodeRelHumidityRepReq[iNode-1] and NodeRelHumidityScheds[iNode-1] != None:
            ReportRelHumidity = (NodeRelHumidityScheds[iNode-1].getCurrentVal() > 0.0)
        elif NodeRelHumidityRepReq[iNode-1] and NodeRelHumidityScheds[iNode-1] == None:
            ReportRelHumidity = True

        if NodeDewPointRepReq[iNode-1] and NodeDewPointScheds[iNode-1] != None:
            ReportDewPoint = (NodeDewPointScheds[iNode-1].getCurrentVal() > 0.0)
        elif NodeDewPointRepReq[iNode-1] and NodeDewPointScheds[iNode-1] == None:
            ReportDewPoint = True

        if NodeSpecificHeatRepReq[iNode-1] and NodeSpecificHeatScheds[iNode-1] != None:
            ReportSpecificHeat = (NodeSpecificHeatScheds[iNode-1].getCurrentVal() > 0.0)
        elif NodeSpecificHeatRepReq[iNode-1] and NodeSpecificHeatScheds[iNode-1] == None:
            ReportSpecificHeat = True

        if state.dataLoopNodes.Node[iNode-1].fluidType == Node.FluidType.Air:
            state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / RhoAirStdInit
            RhoAirCurrent = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress,
                                              state.dataLoopNodes.Node[iNode-1].Temp,
                                              state.dataLoopNodes.Node[iNode-1].HumRat)
            state.dataLoopNodes.MoreNodeInfo[iNode-1].Density = RhoAirCurrent
            if RhoAirCurrent != 0.0:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateCrntRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / RhoAirCurrent
            state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = PsyHFnTdbW(state.dataLoopNodes.Node[iNode-1].Temp,
                                                                                   state.dataLoopNodes.Node[iNode-1].HumRat)
            if ReportWetBulb:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = PsyTwbFnTdbWPb(state,
                                                                                        state.dataLoopNodes.Node[iNode-1].Temp,
                                                                                        state.dataLoopNodes.Node[iNode-1].HumRat,
                                                                                        state.dataEnvrn.OutBaroPress,
                                                                                        nodeReportingStrings[iNode-1])
            else:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
            if ReportDewPoint:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].AirDewPointTemp = PsyTdpFnWPb(state,
                                                                                         state.dataLoopNodes.Node[iNode-1].HumRat,
                                                                                         state.dataEnvrn.OutBaroPress)
            else:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].AirDewPointTemp = 0.0
            if ReportRelHumidity:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 100.0 * PsyRhFnTdbWPb(state,
                                                                                                state.dataLoopNodes.Node[iNode-1].Temp,
                                                                                                state.dataLoopNodes.Node[iNode-1].HumRat,
                                                                                                state.dataEnvrn.OutBaroPress,
                                                                                                nodeReportingStrings[iNode-1])
            else:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 0.0
            if ReportSpecificHeat:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = PsyCpAirFnW(state.dataLoopNodes.Node[iNode-1].HumRat)
            else:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = 0.0

        elif state.dataLoopNodes.Node[iNode-1].fluidType == Node.FluidType.Water:
            if not ((state.dataLoopNodes.Node[iNode-1].FluidIndex > 0) and
                    (state.dataLoopNodes.Node[iNode-1].FluidIndex <= state.dataFluid.glycols.size())):
                rho = RhoWaterStdInit
                rhoStd = RhoWaterStdInit
                Cp = CPCW(state.dataLoopNodes.Node[iNode-1].Temp)
            else:
                Cp = nodeFluids[iNode-1].getSpecificHeat(state, state.dataLoopNodes.Node[iNode-1].Temp, nodeReportingStrings[iNode-1])
                rhoStd = nodeFluids[iNode-1].getDensity(state, Constant.InitConvTemp, nodeReportingStrings[iNode-1])
                rho = nodeFluids[iNode-1].getDensity(state, state.dataLoopNodes.Node[iNode-1].Temp, nodeReportingStrings[iNode-1])
            state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / rhoStd
            state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateCrntRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / rho
            state.dataLoopNodes.MoreNodeInfo[iNode-1].Density = rho
            state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = Cp * state.dataLoopNodes.Node[iNode-1].Temp
            state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = Cp
            state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
            state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 100.0

        elif state.dataLoopNodes.Node[iNode-1].fluidType == Node.FluidType.Steam:
            if state.dataLoopNodes.Node[iNode-1].Quality == 1.0:
                steam = GetSteam(state)
                SteamDensity = steam.getSatDensity(state, state.dataLoopNodes.Node[iNode-1].Temp,
                                                    state.dataLoopNodes.Node[iNode-1].Quality, RoutineName)
                EnthSteamInDry = steam.getSatEnthalpy(state, state.dataLoopNodes.Node[iNode-1].Temp,
                                                       state.dataLoopNodes.Node[iNode-1].Quality, RoutineName)
                state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / SteamDensity
                state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = EnthSteamInDry
                state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
                state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 0.0
            elif state.dataLoopNodes.Node[iNode-1].Quality == 0.0:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / RhoWaterStdInit
                state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = CPCW(state.dataLoopNodes.Node[iNode-1].Temp) * state.dataLoopNodes.Node[iNode-1].Temp
                state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
                state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 0.0

        elif state.dataLoopNodes.Node[iNode-1].fluidType == Node.FluidType.Electric:
            state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = 0.0
            state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = 0.0
            state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
            state.dataLoopNodes.MoreNodeInfo[iNode-1].RelHumidity = 0.0
            state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = 0.0

        else:
            state.dataLoopNodes.MoreNodeInfo[iNode-1].VolFlowRateStdRho = state.dataLoopNodes.Node[iNode-1].MassFlowRate / RhoAirStdInit
            if state.dataLoopNodes.Node[iNode-1].HumRat > 0.0:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = PsyHFnTdbW(state.dataLoopNodes.Node[iNode-1].Temp,
                                                                                       state.dataLoopNodes.Node[iNode-1].HumRat)
                if ReportWetBulb:
                    state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = PsyTwbFnTdbWPb(state,
                                                                                            state.dataLoopNodes.Node[iNode-1].Temp,
                                                                                            state.dataLoopNodes.Node[iNode-1].HumRat,
                                                                                            state.dataEnvrn.StdBaroPress)
                else:
                    state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
                if ReportSpecificHeat:
                    state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = PsyCpAirFnW(state.dataLoopNodes.Node[iNode-1].HumRat)
                else:
                    state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = 0.0
            else:
                state.dataLoopNodes.MoreNodeInfo[iNode-1].ReportEnthalpy = CPCW(state.dataLoopNodes.Node[iNode-1].Temp) * state.dataLoopNodes.Node[iNode-1].Temp
                state.dataLoopNodes.MoreNodeInfo[iNode-1].WetBulbTemp = 0.0
                state.dataLoopNodes.MoreNodeInfo[iNode-1].SpecificHeat = 0.0

def MarkNode(state: EnergyPlusData, NodeNumber: Int,
            ObjectType: Node.ConnectionObjectType,
            ObjectName: String, FieldName: String):
    state.dataLoopNodes.MarkedNode[NodeNumber-1].IsMarked = True
    state.dataLoopNodes.MarkedNode[NodeNumber-1].ObjectType = ObjectType
    state.dataLoopNodes.MarkedNode[NodeNumber-1].ObjectName = ObjectName
    state.dataLoopNodes.MarkedNode[NodeNumber-1].FieldName = FieldName

def CheckMarkedNodes(state: EnergyPlusData, ref ErrorsFound: Bool):
    for NodeNum in range(1, state.dataLoopNodes.NumOfNodes+1):
        if state.dataLoopNodes.MarkedNode[NodeNum-1].IsMarked:
            if state.dataNodeInputMgr.NodeRef[NodeNum-1] == 0:
                objType = Node.ConnectionObjectTypeNames[Int(state.dataLoopNodes.MarkedNode[NodeNum-1].ObjectType)]
                ShowSevereError(state, f"Node=\"{state.dataLoopNodes.NodeID[NodeNum-1]}\" did not find reference by another object.")
                ShowContinueError(state,
                                  f"Object=\"{objType}\", Name=\"{state.dataLoopNodes.MarkedNode[NodeNum-1].ObjectName}\", Field=[{state.dataLoopNodes.MarkedNode[NodeNum-1].FieldName}]")
                ErrorsFound = True