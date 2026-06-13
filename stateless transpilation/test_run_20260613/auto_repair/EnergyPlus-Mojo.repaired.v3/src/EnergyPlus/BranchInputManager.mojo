from .. import EnergyPlusData
from ..DataBranchAirLoopPlant import DataBranchAirLoopPlant, PressureCurveType
from ..BranchNodeConnections import RegisterNodeConnection
from ..CurveManager import Curve
from ..DataLoopNode import Node, FluidType
from ..GeneralRoutines import GetNodeNums, ValidateComponent
from ..UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowSevereMessage, ShowMessage
from ..InputProcessing.InputProcessor import InputProcessor
from memory import Pointer
alias RoutineName_GetBranchInput = "GetBranchInput: "
alias RoutineName_GetBranchListInput = "GetBranchListInput: "
alias cMIXER = "Connector:Mixer"
alias cSPLITTER = "Connector:Splitter"
struct ConnectorData:
    var Name: String
    var NumOfConnectors: Int = 0
    var NumOfSplitters: Int = 0
    var NumOfMixers: Int = 0
    var ConnectorType: List[String]
    var ConnectorName: List[String]
    var ConnectorMatchNo: List[Int]
struct BranchListData:
    var Name: String
    var NumOfBranchNames: Int = 0
    var BranchNames: List[String]
    var LoopName: String
    var LoopType: String
struct ComponentData:
    var CType: String
    var Name: String
    var CtrlType: Int = 0
    var InletNodeName: String
    var InletNode: Int = 0
    var OutletNodeName: String
    var OutletNode: Int = 0
struct BranchData:
    var Name: String
    var AssignedLoopName: String
    var PressureCurveType: PressureCurveType = PressureCurveType.Invalid
    var PressureCurveIndex: Int = 0
    var FluidType: Node.FluidType = Node.FluidType.Blank
    var NumOfComponents: Int = 0
    var Component: List[ComponentData]
struct SplitterData:
    var Name: String
    var InletBranchName: String
    var NumOutletBranches: Int = 0
    var OutletBranchNames: List[String]
struct MixerData:
    var Name: String
    var OutletBranchName: String
    var NumInletBranches: Int = 0
    var InletBranchNames: List[String]
def ManageBranchInput(state: EnergyPlusData):
    if state.dataBranchInputManager.GetBranchInputFlag:
        GetBranchInput(state)
        if state.dataBranchInputManager.GetBranchListInputFlag:
            state.dataBranchInputManager.GetBranchListInputFlag = False
            GetBranchListInput(state)
        AuditBranches(state, False)
        state.dataBranchInputManager.GetBranchInputFlag = False
def ManageConnectorInput(state: EnergyPlusData):
    var hasSplitterOrMixer: Bool = False
    if state.dataBranchInputManager.GetSplitterInputFlag:
        hasSplitterOrMixer = True
        GetSplitterInput(state)
    if state.dataBranchInputManager.GetMixerInputFlag:
        hasSplitterOrMixer = True
        GetMixerInput(state)
    if hasSplitterOrMixer and state.dataBranchInputManager.GetConnectorListInputFlag:
        GetConnectorListInput(state)
def GetBranchList(state: EnergyPlusData, LoopName: String, BranchListName: String, ref NumBranchNames: Int, ref BranchNames: List[String], LoopType: String):
    var Found: Int
    var ErrFound: Bool = False
    if state.dataBranchInputManager.GetBranchListInputFlag:
        state.dataBranchInputManager.GetBranchListInputFlag = False
        GetBranchListInput(state)
    Found = Util.FindItemInList(BranchListName, state.dataBranchInputManager.BranchList)
    if Found == -1:
        ShowFatalError(state, "GetBranchList: BranchList Name not found=" + BranchListName)
    if state.dataBranchInputManager.BranchList[Found].LoopName == "":
        state.dataBranchInputManager.BranchList[Found].LoopName = LoopName
        state.dataBranchInputManager.BranchList[Found].LoopType = LoopType
    elif state.dataBranchInputManager.BranchList[Found].LoopName != LoopName:
        ShowSevereError(state, "GetBranchList: BranchList Loop Name already assigned")
        ShowContinueError(state, "BranchList=" + state.dataBranchInputManager.BranchList[Found].Name + ", already assigned to loop=" + state.dataBranchInputManager.BranchList[Found].LoopName)
        ShowContinueError(state, "Now requesting assignment to Loop=" + LoopName)
        ErrFound = True
    NumBranchNames = state.dataBranchInputManager.BranchList[Found].NumOfBranchNames
    if len(BranchNames) < NumBranchNames:
        ShowSevereError(state, "GetBranchList: Branch Names array not big enough to hold Branch Names")
        ShowContinueError(state, "Input BranchListName=" + BranchListName + ", in Loop=" + LoopName)
        ShowContinueError(state, "BranchName Array size=" + str(len(BranchNames)) + ", but input size=" + str(NumBranchNames))
        ErrFound = True
    else:
        for i in range(NumBranchNames):
            BranchNames[i] = state.dataBranchInputManager.BranchList[Found].BranchNames[i]
    if ErrFound:
        ShowFatalError(state, "GetBranchList: preceding condition(s) causes program termination.")
def NumBranchesInBranchList(state: EnergyPlusData, BranchListName: String) -> Int:
    var Found: Int
    if state.dataBranchInputManager.GetBranchListInputFlag:
        state.dataBranchInputManager.GetBranchListInputFlag = False
        GetBranchListInput(state)
    Found = Util.FindItemInList(BranchListName, state.dataBranchInputManager.BranchList)
    if Found == -1:
        ShowFatalError(state, "NumBranchesInBranchList: BranchList Name not found=" + BranchListName)
    return state.dataBranchInputManager.BranchList[Found].NumOfBranchNames
def GetBranchData(state: EnergyPlusData,
                 LoopName: String,
                 BranchName: String,
                 ref PressCurveType: PressureCurveType,
                 ref PressCurveIndex: Int,
                 ref NumComps: Int,
                 ref CompType: List[String],
                 ref CompName: List[String],
                 ref CompInletNodeNames: List[String],
                 ref CompInletNodeNums: List[Int],
                 ref CompOutletNodeNames: List[String],
                 ref CompOutletNodeNums: List[Int],
                 ref ErrorsFound: Bool):
    var Count: Int
    var MinCompsAllowed: Int
    state.dataBranchInputManager.BComponents = List[ComponentData]()
    state.dataBranchInputManager.BComponents.resize(NumComps)
    GetInternalBranchData(state, LoopName, BranchName, PressCurveType, PressCurveIndex, NumComps, state.dataBranchInputManager.BComponents, ErrorsFound)
    MinCompsAllowed = min(len(CompType), len(CompName), len(CompInletNodeNames), len(CompInletNodeNums), len(CompOutletNodeNames), len(CompOutletNodeNums))
    if MinCompsAllowed < NumComps:
        ShowSevereError(state, "GetBranchData: Component List arrays not big enough to hold Number of Components")
        ShowContinueError(state, "Input BranchName=" + BranchName + ", in Loop=" + LoopName)
        ShowContinueError(state, "Max Component Array size=" + str(MinCompsAllowed) + ", but input size=" + str(NumComps))
        ShowFatalError(state, "Program terminates due to preceding conditions.")
    for Count in range(NumComps):
        CompType[Count] = state.dataBranchInputManager.BComponents[Count].CType
        CompName[Count] = state.dataBranchInputManager.BComponents[Count].Name
        CompInletNodeNames[Count] = state.dataBranchInputManager.BComponents[Count].InletNodeName
        CompInletNodeNums[Count] = state.dataBranchInputManager.BComponents[Count].InletNode
        CompOutletNodeNames[Count] = state.dataBranchInputManager.BComponents[Count].OutletNodeName
        CompOutletNodeNums[Count] = state.dataBranchInputManager.BComponents[Count].OutletNode
def NumCompsInBranch(state: EnergyPlusData, BranchName: String) -> Int:
    var Found: Int
    if state.dataBranchInputManager.GetBranchInputFlag:
        state.dataBranchInputManager.GetBranchInputFlag = False
        GetBranchInput(state)
    Found = Util.FindItemInList(BranchName, state.dataBranchInputManager.Branch)
    if Found == -1:
        ShowSevereError(state, "NumCompsInBranch:  Branch not found=" + BranchName)
        return 0
    else:
        return state.dataBranchInputManager.Branch[Found].NumOfComponents
def GetAirBranchIndex(state: EnergyPlusData, CompType: String, CompName: String) -> Int:
    var GetAirBranchIndex_result: Int = 0
    var BranchNum: Int
    var CompNum: Int
    var NumBranches: Int
    if state.dataBranchInputManager.GetBranchInputFlag:
        state.dataBranchInputManager.GetBranchInputFlag = False
        GetBranchInput(state)
    NumBranches = len(state.dataBranchInputManager.Branch)
    if NumBranches == 0:
        ShowSevereError(state, "GetAirBranchIndex:  Branch not found with component = " + CompType + " \"" + CompName + "\"")
    else:
        var found_ = False
        for BranchNum in range(NumBranches):
            for CompNum in range(state.dataBranchInputManager.Branch[BranchNum].NumOfComponents):
                if Util.SameString(CompType, state.dataBranchInputManager.Branch[BranchNum].Component[CompNum].CType) and Util.SameString(CompName, state.dataBranchInputManager.Branch[BranchNum].Component[CompNum].Name):
                    GetAirBranchIndex_result = BranchNum + 1 # 1-based index
                    found_ = True
                    break
            if found_:
                break
    return GetAirBranchIndex_result
def GetBranchFanTypeName(state: EnergyPlusData,
                        BranchNum: Int,
                        ref FanType: String,
                        ref FanName: String,
                        ref ErrFound: Bool):
    var CompNum: Int
    var NumBranches: Int
    if state.dataBranchInputManager.GetBranchInputFlag:
        state.dataBranchInputManager.GetBranchInputFlag = False
        GetBranchInput(state)
    ErrFound = False
    NumBranches = len(state.dataBranchInputManager.Branch)
    FanType = ""
    FanName = ""
    if NumBranches == 0:
        ShowSevereError(state, "GetBranchFanTypeName:  Branch index not found = " + str(BranchNum))
        ErrFound = True
    else:
        if BranchNum > 0 and BranchNum <= NumBranches:
            for CompNum in range(state.dataBranchInputManager.Branch[BranchNum-1].NumOfComponents):
                var ctype = state.dataBranchInputManager.Branch[BranchNum-1].Component[CompNum].CType
                if Util.SameString("Fan:OnOff", ctype) or \
                   Util.SameString("Fan:ConstantVolume", ctype) or \
                   Util.SameString("Fan:VariableVolume", ctype) or \
                   Util.SameString("Fan:SystemModel", ctype):
                    FanType = ctype
                    FanName = state.dataBranchInputManager.Branch[BranchNum-1].Component[CompNum].Name
                    break
            if FanType == "":
                ErrFound = True
        else:
            ShowSevereError(state, "GetBranchFanTypeName:  Branch index not found = " + str(BranchNum))
            ErrFound = True
def GetInternalBranchData(state: EnergyPlusData,
                         LoopName: String,
                         BranchName: String,
                         ref PressCurveType: PressureCurveType,
                         ref PressCurveIndex: Int,
                         ref NumComps: Int,
                         ref BComponents: List[ComponentData],
                         ref ErrorsFound: Bool):
    var Found: Int
    if state.dataBranchInputManager.GetBranchInputFlag:
        GetBranchInput(state)
        state.dataBranchInputManager.GetBranchInputFlag = False
    Found = Util.FindItemInList(BranchName, state.dataBranchInputManager.Branch)
    if Found == -1:
        ShowSevereError(state, "GetInternalBranchData:  Branch not found=" + BranchName)
        ErrorsFound = True
        NumComps = 0
    else:
        if state.dataBranchInputManager.Branch[Found].AssignedLoopName == "":
            state.dataBranchInputManager.Branch[Found].AssignedLoopName = LoopName
            PressCurveType = state.dataBranchInputManager.Branch[Found].PressureCurveType
            PressCurveIndex = state.dataBranchInputManager.Branch[Found].PressureCurveIndex
            NumComps = state.dataBranchInputManager.Branch[Found].NumOfComponents
            for i in range(NumComps):
                BComponents[i] = state.dataBranchInputManager.Branch[Found].Component[i]
        elif state.dataBranchInputManager.Branch[Found].AssignedLoopName != LoopName:
            ShowSevereError(state, "Attempt to assign branch to two different loops, Branch=" + BranchName)
            ShowContinueError(state, "Branch already assigned to loop=" + state.dataBranchInputManager.Branch[Found].AssignedLoopName)
            ShowContinueError(state, "New attempt to assign to loop=" + LoopName)
            ErrorsFound = True
            NumComps = 0
        else:
            PressCurveType = state.dataBranchInputManager.Branch[Found].PressureCurveType
            PressCurveIndex = state.dataBranchInputManager.Branch[Found].PressureCurveIndex
            NumComps = state.dataBranchInputManager.Branch[Found].NumOfComponents
            for i in range(NumComps):
                BComponents[i] = state.dataBranchInputManager.Branch[Found].Component[i]
def GetNumSplitterMixerInConntrList(state: EnergyPlusData,
                                   LoopName: String,
                                   ConnectorListName: String,
                                   ref numSplitters: Int,
                                   ref numMixers: Int,
                                   ref ErrorsFound: Bool):
    var ConnNum: Int
    if state.dataBranchInputManager.GetConnectorListInputFlag:
        GetConnectorListInput(state)
        state.dataBranchInputManager.GetConnectorListInputFlag = False
    numSplitters = 0
    numMixers = 0
    ConnNum = Util.FindItemInList(ConnectorListName, state.dataBranchInputManager.ConnectorLists)
    if ConnNum >= 0:
        numSplitters = state.dataBranchInputManager.ConnectorLists[ConnNum].NumOfSplitters
        numMixers = state.dataBranchInputManager.ConnectorLists[ConnNum].NumOfMixers
    else:
        ShowSevereError(state, "Ref: Loop=" + LoopName + ", Connector List not found=" + ConnectorListName)
        ErrorsFound = True
def GetConnectorList(state: EnergyPlusData,
                    ConnectorListName: String,
                    ref Connectoid: ConnectorData,
                    NumInList: Optional[Int] = None):
    if state.dataBranchInputManager.GetConnectorListInputFlag:
        GetConnectorListInput(state)
        state.dataBranchInputManager.GetConnectorListInputFlag = False
    if ConnectorListName != "":
        var Count = Util.FindItemInList(ConnectorListName, state.dataBranchInputManager.ConnectorLists)
        if Count == -1:
            ShowFatalError(state, "GetConnectorList: Connector List not found=" + ConnectorListName)
        Connectoid = state.dataBranchInputManager.ConnectorLists[Count]
        if NumInList is not None:
            var n = NumInList.value()
            Connectoid.ConnectorType[0] = state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[n]
            Connectoid.ConnectorName[0] = state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[n]
            Connectoid.ConnectorType[1] = ""
            Connectoid.ConnectorName[1] = ""
    else:
        Connectoid.Name = ""
        Connectoid.NumOfConnectors = 0
        Connectoid.ConnectorType[0] = ""
        Connectoid.ConnectorType[1] = ""
        Connectoid.ConnectorName[0] = ""
        Connectoid.ConnectorName[1] = ""
def GetLoopMixer(state: EnergyPlusData,
                LoopName: String,
                ConnectorListName: String,
                ref MixerName: String,
                ref IsMixer: Bool,
                ref OutletNodeName: String,
                ref OutletNodeNum: Int,
                ref NumInletNodes: Int,
                ref InletNodeNames: List[String],
                ref InletNodeNums: List[Int],
                ref ErrorsFound: Bool,
                ConnectorNumber: Optional[Int] = None,
                MixerNumber: Optional[Int] = None):
    var Count: Int
    var PressCurveType: PressureCurveType
    var Connectoid: ConnectorData
    var BComponents: List[ComponentData]
    if state.dataBranchInputManager.GetMixerInputFlag:
        GetMixerInput(state)
        state.dataBranchInputManager.GetMixerInputFlag = False
    GetConnectorList(state, ConnectorListName, Connectoid, ConnectorNumber)
    if Util.SameString(Connectoid.ConnectorType[0], cMIXER):
        Count = Util.FindItemInList(Connectoid.ConnectorName[0], state.dataBranchInputManager.Mixers)
        if MixerNumber is not None:
            MixerNumber.value += 1
        if Count == -1:
            ShowFatalError(state, "GetLoopMixer: No Mixer Found=" + Connectoid.ConnectorName[0])
    elif Util.SameString(Connectoid.ConnectorType[1], cMIXER):
        Count = Util.FindItemInList(Connectoid.ConnectorName[1], state.dataBranchInputManager.Mixers)
        if Count == -1:
            ShowFatalError(state, "GetLoopMixer: No Mixer Found=" + Connectoid.ConnectorName[1])
    else:
        Count = -1
    IsMixer = False
    MixerName = ""
    OutletNodeName = ""
    OutletNodeNum = 0
    NumInletNodes = 0
    for i in range(len(InletNodeNames)):
        InletNodeNames[i] = ""
        InletNodeNums[i] = 0
    if Count != -1:
        var NumParams: Int
        var NumAlphas: Int
        var NumNumbers: Int
        MixerName = state.dataBranchInputManager.Mixers[Count].Name
        IsMixer = True
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Branch", NumParams, NumAlphas, NumNumbers)
        BComponents = List[ComponentData]()
        BComponents.resize(NumAlphas - 1)
        var errFlag: Bool = False
        var PressCurveIndex: Int
        var NumComps: Int
        GetInternalBranchData(state, LoopName, state.dataBranchInputManager.Mixers[Count].OutletBranchName, PressCurveType, PressCurveIndex, NumComps, BComponents, errFlag)
        if errFlag:
            ShowContinueError(state, "..occurs for Connector:Mixer Name=" + state.dataBranchInputManager.Mixers[Count].Name)
            ErrorsFound = True
        if NumComps > 0:
            OutletNodeName = BComponents[0].InletNodeName
            OutletNodeNum = BComponents[0].InletNode
            NumInletNodes = state.dataBranchInputManager.Mixers[Count].NumInletBranches
            errFlag = False
            RegisterNodeConnection(state, OutletNodeNum, state.dataLoopNodes.NodeID[OutletNodeNum], Node.ConnectionObjectType.ConnectorMixer, MixerName, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent, errFlag)
            if NumInletNodes > len(InletNodeNames) or NumInletNodes > len(InletNodeNums):
                ShowSevereError(state, "GetLoopMixer: Connector:Mixer=" + MixerName + " contains too many inlets for size of Inlet Array.")
                ShowContinueError(state, "Max array size=" + str(len(InletNodeNames)) + ", Mixer statement inlets=" + str(NumInletNodes))
                ShowFatalError(state, "Program terminates due to preceding condition.")
            for i in range(len(InletNodeNums)):
                InletNodeNums[i] = 0
            for i in range(len(InletNodeNames)):
                InletNodeNames[i] = ""
            for Loop in range(state.dataBranchInputManager.Mixers[Count].NumInletBranches):
                GetInternalBranchData(state, LoopName, state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop], PressCurveType, PressCurveIndex, NumComps, BComponents, ErrorsFound)
                if NumComps > 0:
                    InletNodeNames[Loop] = BComponents[NumComps-1].OutletNodeName
                    InletNodeNums[Loop] = BComponents[NumComps-1].OutletNode
                    errFlag = False
                    RegisterNodeConnection(state, InletNodeNums[Loop], state.dataLoopNodes.NodeID[InletNodeNums[Loop]], Node.ConnectionObjectType.ConnectorMixer, MixerName, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent, errFlag)
        else:
            IsMixer = False
def GetLoopSplitter(state: EnergyPlusData,
                   LoopName: String,
                   ConnectorListName: String,
                   ref SplitterName: String,
                   ref IsSplitter: Bool,
                   ref InletNodeName: String,
                   ref InletNodeNum: Int,
                   ref NumOutletNodes: Int,
                   ref OutletNodeNames: List[String],
                   ref OutletNodeNums: List[Int],
                   ref ErrorsFound: Bool,
                   ConnectorNumber: Optional[Int] = None,
                   SplitterNumber: Optional[Int] = None):
    var Count: Int
    var PressCurveType: PressureCurveType
    var Connectoid: ConnectorData
    var BComponents: List[ComponentData]
    if state.dataBranchInputManager.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataBranchInputManager.GetSplitterInputFlag = False
    if ConnectorListName == "":
        ShowSevereError(state, "GetLoopSplitter: ConnectorListName is blank.  LoopName=" + LoopName)
        ShowFatalError(state, "Program terminates due to previous condition.")
    GetConnectorList(state, ConnectorListName, Connectoid, ConnectorNumber)
    if Util.SameString(Connectoid.ConnectorType[0], cSPLITTER):
        Count = Util.FindItemInList(Connectoid.ConnectorName[0], state.dataBranchInputManager.Splitters)
        if SplitterNumber is not None:
            SplitterNumber.value += 1
        if Count == -1:
            ShowFatalError(state, "GetLoopSplitter: No Splitter Found=" + Connectoid.ConnectorName[0])
    elif Util.SameString(Connectoid.ConnectorType[1], cSPLITTER):
        Count = Util.FindItemInList(Connectoid.ConnectorName[1], state.dataBranchInputManager.Splitters)
        if Count == -1:
            ShowFatalError(state, "GetLoopSplitter: No Splitter Found=" + Connectoid.ConnectorName[1])
    else:
        Count = -1
    SplitterName = ""
    IsSplitter = False
    InletNodeName = ""
    InletNodeNum = 0
    NumOutletNodes = 0
    for i in range(len(OutletNodeNames)):
        OutletNodeNames[i] = ""
    for i in range(len(OutletNodeNums)):
        OutletNodeNums[i] = 0
    if Count != -1:
        var NumComps: Int
        var NumParams: Int
        var NumAlphas: Int
        var NumNumbers: Int
        var PressCurveIndex: Int
        SplitterName = state.dataBranchInputManager.Splitters[Count].Name
        IsSplitter = True
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Branch", NumParams, NumAlphas, NumNumbers)
        BComponents = List[ComponentData]()
        BComponents.resize(NumAlphas - 1)
        var errFlag: Bool = False
        GetInternalBranchData(state, LoopName, state.dataBranchInputManager.Splitters[Count].InletBranchName, PressCurveType, PressCurveIndex, NumComps, BComponents, errFlag)
        if errFlag:
            ShowContinueError(state, "..occurs for Splitter Name=" + state.dataBranchInputManager.Splitters[Count].Name)
            ErrorsFound = True
        if NumComps > 0:
            InletNodeName = BComponents[NumComps-1].OutletNodeName
            InletNodeNum = BComponents[NumComps-1].OutletNode
            NumOutletNodes = state.dataBranchInputManager.Splitters[Count].NumOutletBranches
            errFlag = False
            RegisterNodeConnection(state, InletNodeNum, state.dataLoopNodes.NodeID[InletNodeNum], Node.ConnectionObjectType.ConnectorSplitter, SplitterName, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent, errFlag)
            if NumOutletNodes > len(OutletNodeNames) or NumOutletNodes > len(OutletNodeNums):
                ShowSevereError(state, "GetLoopSplitter: Connector:Splitter=" + SplitterName + " contains too many outlets for size of Outlet Array.")
                ShowContinueError(state, "Max array size=" + str(len(OutletNodeNames)) + ", Splitter statement outlets=" + str(NumOutletNodes))
                ShowFatalError(state, "Program terminates due to preceding condition.")
            for i in range(len(OutletNodeNums)):
                OutletNodeNums[i] = 0
            for i in range(len(OutletNodeNames)):
                OutletNodeNames[i] = ""
            for Loop in range(state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
                GetInternalBranchData(state, LoopName, state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop], PressCurveType, PressCurveIndex, NumComps, BComponents, ErrorsFound)
                if NumComps > 0:
                    OutletNodeNames[Loop] = BComponents[0].InletNodeName
                    OutletNodeNums[Loop] = BComponents[0].InletNode
                    errFlag = False
                    RegisterNodeConnection(state, OutletNodeNums[Loop], state.dataLoopNodes.NodeID[OutletNodeNums[Loop]], Node.ConnectionObjectType.ConnectorSplitter, SplitterName, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent, errFlag)
        else:
            IsSplitter = False
def GetFirstBranchInletNodeName(state: EnergyPlusData, BranchListName: String) -> String:
    var InletNodeName: String
    if state.dataBranchInputManager.GetBranchListInputFlag:
        state.dataBranchInputManager.GetBranchListInputFlag = False
        GetBranchListInput(state)
    var Found1 = Util.FindItemInList(BranchListName, state.dataBranchInputManager.BranchList)
    if Found1 == -1:
        ShowSevereError(state, "GetFirstBranchInletNodeName: BranchList=\"" + BranchListName + "\", not a valid BranchList Name")
        InletNodeName = "Invalid Node Name"
    else:
        var Found2 = Util.FindItemInList(state.dataBranchInputManager.BranchList[Found1].BranchNames[0], state.dataBranchInputManager.Branch)
        if Found2 == -1:
            ShowSevereError(state, "GetFirstBranchInletNodeName: BranchList=\"" + BranchListName + "\", Branch=\"" + state.dataBranchInputManager.BranchList[Found1].BranchNames[0] + "\" not a valid Branch Name")
            InletNodeName = "Invalid Node Name"
        else:
            InletNodeName = state.dataBranchInputManager.Branch[Found2].Component[0].InletNodeName
    return InletNodeName
def GetLastBranchOutletNodeName(state: EnergyPlusData, BranchListName: String) -> String:
    var OutletNodeName: String
    if state.dataBranchInputManager.GetBranchListInputFlag:
        state.dataBranchInputManager.GetBranchListInputFlag = False
        GetBranchListInput(state)
    var Found1 = Util.FindItemInList(BranchListName, state.dataBranchInputManager.BranchList)
    if Found1 == -1:
        ShowSevereError(state, "GetLastBranchOutletNodeName: BranchList=\"" + BranchListName + "\", not a valid BranchList Name")
        OutletNodeName = "Invalid Node Name"
    else:
        var lastIndex = state.dataBranchInputManager.BranchList[Found1].NumOfBranchNames - 1
        var Found2 = Util.FindItemInList(state.dataBranchInputManager.BranchList[Found1].BranchNames[lastIndex], state.dataBranchInputManager.Branch)
        if Found2 == -1:
            ShowSevereError(state, "GetLastBranchOutletNodeName: BranchList=\"" + BranchListName + "\", Branch=\"" + state.dataBranchInputManager.BranchList[Found1].BranchNames[lastIndex] + "\" not a valid Branch Name")
            OutletNodeName = "Invalid Node Name"
        else:
            var lastComp = state.dataBranchInputManager.Branch[Found2].NumOfComponents - 1
            OutletNodeName = state.dataBranchInputManager.Branch[Found2].Component[lastComp].OutletNodeName
    return OutletNodeName
def GetBranchInput(state: EnergyPlusData):
    var Alphas: List[String]
    var NodeNums: List[Int]
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    if state.dataBranchInputManager.GetBranchInputOneTimeFlag:
        var CurrentModuleObject = "Branch"
        var NumOfBranches = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
        if NumOfBranches > 0:
            state.dataBranchInputManager.Branch = List[BranchData]()
            state.dataBranchInputManager.Branch.resize(NumOfBranches)
            var NumNumbers: Int
            var NumAlphas: Int
            var NumParams: Int
            state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNumbers)
            NodeNums = List[Int]()
            NodeNums.resize(NumParams, 0)
            state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
            Alphas = List[String]()
            Alphas.resize(NumAlphas)
            Numbers = List[Float64]()
            Numbers.resize(NumNumbers, 0.0)
            cAlphaFields = List[String]()
            cAlphaFields.resize(NumAlphas)
            cNumericFields = List[String]()
            cNumericFields.resize(NumNumbers)
            lAlphaBlanks = List[Bool]()
            lAlphaBlanks.resize(NumAlphas, True)
            lNumericBlanks = List[Bool]()
            lNumericBlanks.resize(NumNumbers, True)
            var BCount: Int = 0
            var IOStat: Int
            for Count in range(1, NumOfBranches+1):
                state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
                BCount += 1
                GetSingleBranchInput(state, RoutineName_GetBranchInput, BCount, Alphas, cAlphaFields, NumAlphas, NodeNums, lAlphaBlanks)
            NumOfBranches = BCount
            Node.N.TestInletOutletNodes(state)
            state.dataBranchInputManager.GetBranchInputOneTimeFlag = False
def GetSingleBranchInput(state: EnergyPlusData,
                        RoutineName: String,
                        BCount: Int,
                        Alphas: List[String],
                        cAlphaFields: List[String],
                        NumAlphas: Int,
                        ref NodeNums: List[Int],
                        lAlphaBlanks: List[Bool]):
    var pressureCurveType: PressureCurveType
    var PressureCurveIndex: Int
    var ErrFound: Bool = False
    var Comp: Int
    var IsNotOK: Bool
    var NumInComps: Int
    var ConnectionType: Node.ConnectionType
    var NumNodes: Int
    var CurrentModuleObject = "Branch"
    var branchIdx = BCount - 1
    state.dataBranchInputManager.Branch[branchIdx].Name = Alphas[0]
    Curve.GetPressureCurveTypeAndIndex(state, Alphas[1], pressureCurveType, PressureCurveIndex)
    if pressureCurveType == DataBranchAirLoopPlant.PressureCurveType.Invalid:
        ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
        ShowContinueError(state, "..Invalid " + cAlphaFields[1] + "=\"" + Alphas[1] + "\".")
        ShowContinueError(state, "This curve could not be found in the input deck.  Ensure that this curve has been entered")
        ShowContinueError(state, " as either a Curve:Functional:PressureDrop or one of Curve:{Linear,Quadratic,Cubic,Exponent}")
        ShowContinueError(state, "This error could be caused by a misspelled curve name")
        ErrFound = True
    state.dataBranchInputManager.Branch[branchIdx].PressureCurveType = pressureCurveType
    state.dataBranchInputManager.Branch[branchIdx].PressureCurveIndex = PressureCurveIndex
    state.dataBranchInputManager.Branch[branchIdx].NumOfComponents = (NumAlphas - 2) // 4
    if state.dataBranchInputManager.Branch[branchIdx].NumOfComponents * 4 != (NumAlphas - 2):
        state.dataBranchInputManager.Branch[branchIdx].NumOfComponents += 1
    NumInComps = state.dataBranchInputManager.Branch[branchIdx].NumOfComponents
    state.dataBranchInputManager.Branch[branchIdx].Component = List[ComponentData]()
    state.dataBranchInputManager.Branch[branchIdx].Component.resize(state.dataBranchInputManager.Branch[branchIdx].NumOfComponents)
    Comp = 0
    for Loop in range(2, NumAlphas, 4):
        if Util.SameString(Alphas[Loop], cSPLITTER) or Util.SameString(Alphas[Loop], cMIXER):
            ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
            ShowContinueError(state, "Connector:Splitter/Connector:Mixer not allowed in object " + CurrentModuleObject)
            ErrFound = True
            continue
        if Comp >= NumInComps:
            ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
            ShowContinueError(state, "...Number of Arguments indicate [" + str(NumInComps) + "], but count of fields indicates [" + str(Comp+1) + "]")
            ShowContinueError(state, "...examine " + CurrentModuleObject + " carefully.")
            continue
        state.dataBranchInputManager.Branch[branchIdx].Component[Comp].CType = Alphas[Loop]
        state.dataBranchInputManager.Branch[branchIdx].Component[Comp].Name = Alphas[Loop+1]
        ValidateComponent(state, Alphas[Loop], Alphas[Loop+1], IsNotOK, CurrentModuleObject)
        if IsNotOK:
            ShowContinueError(state, "Occurs on " + CurrentModuleObject + "=" + Alphas[0])
            ErrFound = True
        state.dataBranchInputManager.Branch[branchIdx].Component[Comp].InletNodeName = Alphas[Loop+2]
        if Loop == 2:
            ConnectionType = Node.ConnectionType.Inlet
        else:
            ConnectionType = Node.ConnectionType.Internal
        if not lAlphaBlanks[Loop+2]:
            GetNodeNums(state, state.dataBranchInputManager.Branch[branchIdx].Component[Comp].InletNodeName, NumNodes, NodeNums, ErrFound, Node.FluidType.Blank, Node.ConnectionObjectType.Branch, state.dataBranchInputManager.Branch[branchIdx].Name, ConnectionType, Node.CompFluidStream.Primary, Node.ObjectIsParent, False, cAlphaFields[Loop+2])
            if NumNodes > 1:
                ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
                ShowContinueError(state, "..invalid " + cAlphaFields[Loop+2] + "=\"" + state.dataBranchInputManager.Branch[branchIdx].Component[Comp].InletNodeName + "\" must be a single node - appears to be a list.")
                ShowContinueError(state, "Occurs on " + cAlphaFields[Loop] + "=\"" + Alphas[Loop] + "\", " + cAlphaFields[Loop+1] + "=\"" + Alphas[Loop+1] + "\".")
                ErrFound = True
            else:
                state.dataBranchInputManager.Branch[branchIdx].Component[Comp].InletNode = NodeNums[0]
        else:
            ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
            ShowContinueError(state, "blank required field: " + cAlphaFields[Loop+2])
            ShowContinueError(state, "Occurs on " + cAlphaFields[Loop] + "=\"" + Alphas[Loop] + "\", " + cAlphaFields[Loop+1] + "=\"" + Alphas[Loop+1] + "\".")
            ErrFound = True
        state.dataBranchInputManager.Branch[branchIdx].Component[Comp].OutletNodeName = Alphas[Loop+3]
        if Loop == NumAlphas - 4:
            ConnectionType = Node.ConnectionType.Outlet
        else:
            ConnectionType = Node.ConnectionType.Internal
        if not lAlphaBlanks[Loop+3]:
            GetNodeNums(state, state.dataBranchInputManager.Branch[branchIdx].Component[Comp].OutletNodeName, NumNodes, NodeNums, ErrFound, Node.FluidType.Blank, Node.ConnectionObjectType.Branch, state.dataBranchInputManager.Branch[branchIdx].Name, ConnectionType, Node.CompFluidStream.Primary, Node.ObjectIsParent, False, cAlphaFields[Loop+3])
            if NumNodes > 1:
                ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
                ShowContinueError(state, "..invalid " + cAlphaFields[Loop+2] + "=\"" + state.dataBranchInputManager.Branch[branchIdx].Component[Comp].InletNodeName + "\" must be a single node - appears to be a list.")
                ShowContinueError(state, "Occurs on " + cAlphaFields[Loop] + "=\"" + Alphas[Loop] + "\", " + cAlphaFields[Loop+1] + "=\"" + Alphas[Loop+1] + "\".")
                ErrFound = True
            else:
                state.dataBranchInputManager.Branch[branchIdx].Component[Comp].OutletNode = NodeNums[0]
        else:
            ShowSevereError(state, RoutineName + CurrentModuleObject + "=\"" + Alphas[0] + "\", invalid data.")
            ShowContinueError(state, "blank required field: " + cAlphaFields[Loop+3])
            ShowContinueError(state, "Occurs on " + cAlphaFields[Loop] + "=\"" + Alphas[Loop] + "\", " + cAlphaFields[Loop+1] + "=\"" + Alphas[Loop+1] + "\".")
            ErrFound = True
        if not lAlphaBlanks[Loop] and not lAlphaBlanks[Loop+1] and not lAlphaBlanks[Loop+2] and not lAlphaBlanks[Loop+3]:
            Node.SetUpCompSets(state, CurrentModuleObject, state.dataBranchInputManager.Branch[branchIdx].Name, Alphas[Loop], Alphas[Loop+1], Alphas[Loop+2], Alphas[Loop+3])
        Comp += 1
    state.dataBranchInputManager.Branch[branchIdx].NumOfComponents = NumInComps
def GetBranchListInput(state: EnergyPlusData):
    var Count: Int
    var BCount: Int
    var Loop: Int
    var Found: Int
    var ErrFound: Bool = False
    var NumAlphas: Int
    var Alphas: List[String]
    var NumNumbers: Int
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    var NumParams: Int
    var TestName: String
    var CurrentModuleObject = "BranchList"
    var NumOfBranchLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataBranchInputManager.BranchList = List[BranchListData]()
    state.dataBranchInputManager.BranchList.resize(NumOfBranchLists)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers, 0.0)
    cAlphaFields = List[String]()
    cAlphaFields.resize(NumAlphas)
    cNumericFields = List[String]()
    cNumericFields.resize(NumNumbers)
    lAlphaBlanks = List[Bool]()
    lAlphaBlanks.resize(NumAlphas, True)
    lNumericBlanks = List[Bool]()
    lNumericBlanks.resize(NumNumbers, True)
    if NumNumbers > 0:
        ShowSevereError(state, RoutineName_GetBranchListInput + CurrentModuleObject + " Object definition contains numbers, cannot be decoded by GetBranchListInput routine.")
        ErrFound = True
    BCount = 0
    for Count in range(1, NumOfBranchLists+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        BCount += 1
        var idx = BCount - 1
        state.dataBranchInputManager.BranchList[idx].Name = Alphas[0]
        state.dataBranchInputManager.BranchList[idx].NumOfBranchNames = NumAlphas - 1
        state.dataBranchInputManager.BranchList[idx].BranchNames = List[String]()
        state.dataBranchInputManager.BranchList[idx].BranchNames.resize(NumAlphas - 1)
        if state.dataBranchInputManager.BranchList[idx].NumOfBranchNames == 0:
            ShowSevereError(state, RoutineName_GetBranchListInput + CurrentModuleObject + "=\"" + state.dataBranchInputManager.BranchList[idx].Name + "\", No branch names entered.")
            ErrFound = True
        else:
            for i in range(NumAlphas - 1):
                state.dataBranchInputManager.BranchList[idx].BranchNames[i] = Alphas[i+1]
            for Loop in range(state.dataBranchInputManager.BranchList[idx].NumOfBranchNames):
                if len(state.dataBranchInputManager.Branch) == 0:
                    GetBranchInput(state)
                if state.dataBranchInputManager.BranchList[idx].BranchNames[Loop] != "":
                    Found = Util.FindItemInList(state.dataBranchInputManager.BranchList[idx].BranchNames[Loop], state.dataBranchInputManager.Branch)
                    if Found == -1:
                        ShowSevereError(state, RoutineName_GetBranchListInput + CurrentModuleObject + "=\"" + state.dataBranchInputManager.BranchList[idx].Name + "\", invalid data.")
                        ShowContinueError(state, "..invalid Branch Name not found=\"" + state.dataBranchInputManager.BranchList[idx].BranchNames[Loop] + "\".")
                        ErrFound = True
    for Count in range(NumOfBranchLists):
        if state.dataBranchInputManager.BranchList[Count].NumOfBranchNames == 0:
            continue
        TestName = state.dataBranchInputManager.BranchList[Count].BranchNames[0]
        for Loop in range(1, state.dataBranchInputManager.BranchList[Count].NumOfBranchNames):
            if TestName != state.dataBranchInputManager.BranchList[Count].BranchNames[Loop]:
                continue
            ShowSevereError(state, RoutineName_GetBranchListInput + CurrentModuleObject + "=\"" + state.dataBranchInputManager.BranchList[BCount-1].Name + "\", invalid data.")
            ShowContinueError(state, "..invalid: duplicate branch name specified in the list.")
            ShowContinueError(state, "..Branch Name=" + TestName)
            ShowContinueError(state, "..Branch Name #" + str(Loop+1) + " is duplicate.")
            ErrFound = True
    if ErrFound:
        ShowSevereError(state, RoutineName_GetBranchListInput + " Invalid Input -- preceding condition(s) will likely cause termination.")
def GetConnectorListInput(state: EnergyPlusData):
    var Count: Int
    var NumAlphas: Int
    var Alphas: List[String]
    var NumNumbers: Int
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    var NumParams: Int
    var Arg: Int
    var SplitNum: Int
    var MixerNum: Int
    var BranchNames: List[String]
    var NumBranchNames: Int
    var errorsFound: Bool = False
    var Loop: Int
    var Loop1: Int
    var Loop2: Int
    var CurMixer: Bool
    var CurSplitter: Bool
    var TestNum: Int
    var MatchFound: Bool
    if not state.dataBranchInputManager.GetConnectorListInputFlag:
        return
    errorsFound = False
    var CurrentModuleObject = "ConnectorList"
    var NumOfConnectorLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataBranchInputManager.ConnectorLists = List[ConnectorData]()
    state.dataBranchInputManager.ConnectorLists.resize(NumOfConnectorLists)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    if NumAlphas != 5 or NumNumbers != 0:
        ShowWarningError(state, "GetConnectorList: Illegal \"extension\" to " + CurrentModuleObject + " object. Internal code does not support > 2 connectors (Connector:Splitter and Connector:Mixer)")
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers, 0.0)
    cAlphaFields = List[String]()
    cAlphaFields.resize(NumAlphas)
    cNumericFields = List[String]()
    cNumericFields.resize(NumNumbers)
    lAlphaBlanks = List[Bool]()
    lAlphaBlanks.resize(NumAlphas, True)
    lNumericBlanks = List[Bool]()
    lNumericBlanks.resize(NumNumbers, True)
    for Count in range(1, NumOfConnectorLists+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var idx = Count - 1
        state.dataBranchInputManager.ConnectorLists[idx].Name = Alphas[0]
        var NumConnectors = (NumAlphas - 1) // 2
        if (NumAlphas - 1) % 2 != 0:
            NumConnectors += 1
        state.dataBranchInputManager.ConnectorLists[idx].NumOfConnectors = NumConnectors
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorType = List[String]()
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorType.resize(NumConnectors)
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorName = List[String]()
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorName.resize(NumConnectors)
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorMatchNo = List[Int]()
        state.dataBranchInputManager.ConnectorLists[idx].ConnectorMatchNo.resize(NumConnectors)
        for i in range(NumConnectors):
            state.dataBranchInputManager.ConnectorLists[idx].ConnectorType[i] = "UNKNOWN"
            state.dataBranchInputManager.ConnectorLists[idx].ConnectorName[i] = "UNKNOWN"
            state.dataBranchInputManager.ConnectorLists[idx].ConnectorMatchNo[i] = 0
        state.dataBranchInputManager.ConnectorLists[idx].NumOfSplitters = 0
        state.dataBranchInputManager.ConnectorLists[idx].NumOfMixers = 0
        var CCount = 0
        for Arg in range(1, NumAlphas, 2):
            if CCount >= NumConnectors:
                break
            if Util.SameString(Alphas[Arg], cSPLITTER):
                state.dataBranchInputManager.ConnectorLists[idx].ConnectorType[CCount] = Alphas[Arg][0:30]
                state.dataBranchInputManager.ConnectorLists[idx].NumOfSplitters += 1
            elif Util.SameString(Alphas[Arg], cMIXER):
                state.dataBranchInputManager.ConnectorLists[idx].ConnectorType[CCount] = Alphas[Arg][0:30]
                state.dataBranchInputManager.ConnectorLists[idx].NumOfMixers += 1
            else:
                ShowWarningError(state, "GetConnectorListInput: Invalid " + cAlphaFields[Arg] + "=" + Alphas[Arg] + " in " + CurrentModuleObject + "=" + Alphas[0])
            state.dataBranchInputManager.ConnectorLists[idx].ConnectorName[CCount] = Alphas[Arg+1]
            CCount += 1
    state.dataBranchInputManager.GetConnectorListInputFlag = False
    if state.dataBranchInputManager.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataBranchInputManager.GetSplitterInputFlag = False
    if state.dataBranchInputManager.GetMixerInputFlag:
        GetMixerInput(state)
        state.dataBranchInputManager.GetMixerInputFlag = False
    SplitNum = 0
    MixerNum = 0
    for Count in range(NumOfConnectorLists):
        if state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors <= 1:
            continue
        if state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors > 2:
            continue
        for Loop in range(state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors):
            if state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop] != 0:
                continue
            if Util.SameString(state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop], cSPLITTER):
                CurSplitter = True
                CurMixer = False
                SplitNum = Util.FindItemInList(state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop], state.dataBranchInputManager.Splitters)
                if SplitNum == -1:
                    ShowSevereError(state, "Invalid Connector:Splitter(none)=" + state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop] + ", referenced by " + CurrentModuleObject + "=" + state.dataBranchInputManager.ConnectorLists[Count].Name)
                    errorsFound = True
                    continue
                NumBranchNames = state.dataBranchInputManager.Splitters[SplitNum].NumOutletBranches
                BranchNames = state.dataBranchInputManager.Splitters[SplitNum].OutletBranchNames
            elif Util.SameString(state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop], cMIXER):
                CurSplitter = False
                CurMixer = True
                MixerNum = Util.FindItemInList(state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop], state.dataBranchInputManager.Mixers)
                if MixerNum == -1:
                    ShowSevereError(state, "Invalid Connector:Mixer(none)=" + state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop] + ", referenced by " + CurrentModuleObject + "=" + state.dataBranchInputManager.ConnectorLists[Count].Name)
                    errorsFound = True
                    continue
                NumBranchNames = state.dataBranchInputManager.Mixers[MixerNum].NumInletBranches
                BranchNames = state.dataBranchInputManager.Mixers[MixerNum].InletBranchNames
            else:
                continue
            for Loop1 in range(Loop+1, state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors):
                if CurMixer and not Util.SameString(state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop1], cSPLITTER):
                    continue
                if CurSplitter and not Util.SameString(state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop1], cMIXER):
                    continue
                if state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop1] != 0:
                    continue
                if CurSplitter:
                    MixerNum = Util.FindItemInList(state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop1], state.dataBranchInputManager.Mixers)
                    if MixerNum == -1:
                        continue
                    if state.dataBranchInputManager.Mixers[MixerNum].NumInletBranches != NumBranchNames:
                        continue
                    MatchFound = True
                    for Loop2 in range(state.dataBranchInputManager.Mixers[MixerNum].NumInletBranches):
                        TestNum = Util.FindItemInList(state.dataBranchInputManager.Mixers[MixerNum].InletBranchNames[Loop2], BranchNames, NumBranchNames)
                        if TestNum == -1:
                            MatchFound = False
                            break
                    if MatchFound:
                        state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop1] = MixerNum
                        state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop] = SplitNum
                else:
                    SplitNum = Util.FindItemInList(state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop1], state.dataBranchInputManager.Splitters)
                    if SplitNum == -1:
                        continue
                    if state.dataBranchInputManager.Splitters[SplitNum].NumOutletBranches != NumBranchNames:
                        continue
                    MatchFound = True
                    for Loop2 in range(state.dataBranchInputManager.Splitters[SplitNum].NumOutletBranches):
                        TestNum = Util.FindItemInList(state.dataBranchInputManager.Splitters[SplitNum].OutletBranchNames[Loop2], BranchNames, NumBranchNames)
                        if TestNum == -1:
                            MatchFound = False
                            break
                    if MatchFound:
                        state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop1] = SplitNum
                        state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop] = MixerNum
    for Count in range(NumOfConnectorLists):
        if state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors <= 1:
            continue
        if state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors > 2:
            continue
        for Loop in range(state.dataBranchInputManager.ConnectorLists[Count].NumOfConnectors):
            if state.dataBranchInputManager.ConnectorLists[Count].ConnectorMatchNo[Loop] != 0:
                continue
            ShowSevereError(state, "For " + CurrentModuleObject + "=" + state.dataBranchInputManager.ConnectorLists[Count].Name)
            ShowContinueError(state, "...Item=" + state.dataBranchInputManager.ConnectorLists[Count].ConnectorName[Loop] + ", Type=" + state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop] + " was not matched.")
            if Util.SameString(state.dataBranchInputManager.ConnectorLists[Count].ConnectorType[Loop], "Connector:Splitter"):
                ShowContinueError(state, "The BranchList for this Connector:Splitter does not match the BranchList for its corresponding Connector:Mixer.")
            else:
                ShowContinueError(state, "The BranchList for this Connector:Mixer does not match the BranchList for its corresponding Connector:Splitter.")
            errorsFound = True
    if errorsFound:
        ShowFatalError(state, "GetConnectorListInput: Program terminates for preceding conditions.")
def GetSplitterInput(state: EnergyPlusData):
    var NumAlphas: Int
    var Alphas: List[String]
    var NumNumbers: Int
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    var NumParams: Int
    var Loop: Int
    var Loop1: Int
    var Count: Int
    var ErrorsFound: Bool = False
    var TestName: String
    var FoundSupplyDemandAir: String
    var SaveSupplyDemandAir: String
    var FoundLoop: String
    var SaveLoop: String
    var MatchedLoop: Bool
    if not state.dataBranchInputManager.GetSplitterInputFlag:
        return
    var CurrentModuleObject = cSPLITTER
    var NumSplitters = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataBranchInputManager.Splitters = List[SplitterData]()
    state.dataBranchInputManager.Splitters.resize(NumSplitters)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers, 0.0)
    cAlphaFields = List[String]()
    cAlphaFields.resize(NumAlphas)
    cNumericFields = List[String]()
    cNumericFields.resize(NumNumbers)
    lAlphaBlanks = List[Bool]()
    lAlphaBlanks.resize(NumAlphas, True)
    lNumericBlanks = List[Bool]()
    lNumericBlanks.resize(NumNumbers, True)
    for Count in range(1, NumSplitters+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var idx = Count - 1
        state.dataBranchInputManager.Splitters[idx].Name = Alphas[0]
        state.dataBranchInputManager.Splitters[idx].InletBranchName = Alphas[1]
        state.dataBranchInputManager.Splitters[idx].NumOutletBranches = NumAlphas - 2
        state.dataBranchInputManager.Splitters[idx].OutletBranchNames = List[String]()
        state.dataBranchInputManager.Splitters[idx].OutletBranchNames.resize(state.dataBranchInputManager.Splitters[idx].NumOutletBranches)
        for Loop in range(state.dataBranchInputManager.Splitters[idx].NumOutletBranches):
            state.dataBranchInputManager.Splitters[idx].OutletBranchNames[Loop] = Alphas[2+Loop+1] # Alphas is 0-indexed, so field 3 becomes index 2
    state.dataBranchInputManager.GetSplitterInputFlag = False
    if not state.dataBranchInputManager.GetBranchInputFlag:
        GetBranchInput(state)
        state.dataBranchInputManager.GetBranchInputFlag = False
    for Count in range(NumSplitters):
        var Found = Util.FindItemInList(state.dataBranchInputManager.Splitters[Count].InletBranchName, state.dataBranchInputManager.Branch)
        if Found == -1:
            ShowSevereError(state, "GetSplitterInput: Invalid Branch=" + state.dataBranchInputManager.Splitters[Count].InletBranchName + ", referenced as Inlet Branch to " + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
            Found = Util.FindItemInList(state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop], state.dataBranchInputManager.Branch)
            if Found == -1:
                ShowSevereError(state, "GetSplitterInput: Invalid Branch=" + state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop] + ", referenced as Outlet Branch # " + str(Loop+1) + " to " + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
                ErrorsFound = True
    for Count in range(NumSplitters):
        TestName = state.dataBranchInputManager.Splitters[Count].InletBranchName
        for Loop in range(state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
            if TestName != state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop]:
                continue
            ShowSevereError(state, CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name + " specifies an outlet node name the same as the inlet node.")
            ShowContinueError(state, "..Inlet Node=" + TestName)
            ShowContinueError(state, "..Outlet Node #" + str(Loop+1) + " is duplicate.")
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
            for Loop1 in range(Loop+1, state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
                if state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop] != state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop1]:
                    continue
                ShowSevereError(state, CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name + " specifies duplicate outlet nodes in its outlet node list.")
                ShowContinueError(state, "..Outlet Node #" + str(Loop+1) + " Name=" + state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop])
                ShowContinueError(state, "..Outlet Node #" + str(Loop+1) + " is duplicate.")
                ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetSplitterInput: Fatal Errors Found in " + CurrentModuleObject + ", program terminates.")
    SaveSupplyDemandAir = ""
    for Count in range(NumSplitters):
        TestName = state.dataBranchInputManager.Splitters[Count].InletBranchName
        var BranchListName: String = ""
        for Loop1 in range(len(state.dataBranchInputManager.BranchList)):
            if Util.any_eq(state.dataBranchInputManager.BranchList[Loop1].BranchNames, TestName):
                BranchListName = state.dataBranchInputManager.BranchList[Loop1].Name
                break
        if BranchListName != "":
            FoundSupplyDemandAir = ""
            FoundLoop = ""
            MatchedLoop = False
            FindAirPlantCondenserLoopFromBranchList(state, BranchListName, FoundLoop, FoundSupplyDemandAir, MatchedLoop)
            if MatchedLoop:
                SaveSupplyDemandAir = FoundSupplyDemandAir
                SaveLoop = FoundLoop
            else:
                ShowSevereError(state, "GetSplitterInput: Inlet Splitter Branch=\"" + TestName + "\" and BranchList=\"" + BranchListName + "\" not matched to a Air/Plant/Condenser Loop")
                ShowContinueError(state, "...and therefore, not a valid Loop Splitter.")
                ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
                ErrorsFound = True
        else:
            ShowSevereError(state, "GetSplitterInput: Inlet Splitter Branch=\"" + TestName + "\" not on BranchList")
            ShowContinueError(state, "...and therefore, not a valid Loop Splitter.")
            ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Splitters[Count].NumOutletBranches):
            TestName = state.dataBranchInputManager.Splitters[Count].OutletBranchNames[Loop]
            BranchListName = ""
            for Loop1 in range(len(state.dataBranchInputManager.BranchList)):
                if Util.any_eq(state.dataBranchInputManager.BranchList[Loop1].BranchNames, TestName):
                    BranchListName = state.dataBranchInputManager.BranchList[Loop1].Name
                    break
            if BranchListName != "":
                FoundSupplyDemandAir = ""
                FoundLoop = ""
                MatchedLoop = False
                FindAirPlantCondenserLoopFromBranchList(state, BranchListName, FoundLoop, FoundSupplyDemandAir, MatchedLoop)
                if MatchedLoop:
                    if SaveSupplyDemandAir != FoundSupplyDemandAir or SaveLoop != FoundLoop:
                        ShowSevereError(state, "GetSplitterInput: Outlet Splitter Branch=\"" + TestName + "\" does not match types of Inlet Branch.")
                        ShowContinueError(state, "...Inlet Branch is on \"" + SaveLoop + "\" on \"" + SaveSupplyDemandAir + "\" side.")
                        ShowContinueError(state, "...Outlet Branch is on \"" + FoundLoop + "\" on \"" + FoundSupplyDemandAir + "\" side.")
                        ShowContinueError(state, "...All branches in Loop Splitter must be on same kind of loop and supply/demand side.")
                        ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
                        ErrorsFound = True
                else:
                    ShowSevereError(state, "GetSplitterInput: Outlet Splitter Branch=\"" + TestName + "\" and BranchList=\"" + BranchListName + "\" not matched to a Air/Plant/Condenser Loop")
                    ShowContinueError(state, "...and therefore, not a valid Loop Splitter.")
                    ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
                    ErrorsFound = True
            else:
                ShowSevereError(state, "GetSplitterInput: Outlet Splitter Branch=\"" + TestName + "\" not on BranchList")
                ShowContinueError(state, "...and therefore, not a valid Loop Splitter")
                ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Splitters[Count].Name)
                ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetSplitterInput: Fatal Errors Found in " + CurrentModuleObject + ", program terminates.")
def GetMixerInput(state: EnergyPlusData):
    var NumAlphas: Int
    var Alphas: List[String]
    var NumNumbers: Int
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    var NumParams: Int
    var Loop: Int
    var Loop1: Int
    var Count: Int
    var ErrorsFound: Bool = False
    var TestName: String
    var FoundSupplyDemandAir: String
    var SaveSupplyDemandAir: String
    var FoundLoop: String
    var SaveLoop: String
    var MatchedLoop: Bool
    if not state.dataBranchInputManager.GetMixerInputFlag:
        return
    var CurrentModuleObject = cMIXER
    var NumMixers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataBranchInputManager.Mixers = List[MixerData]()
    state.dataBranchInputManager.Mixers.resize(NumMixers)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers, 0.0)
    cAlphaFields = List[String]()
    cAlphaFields.resize(NumAlphas)
    cNumericFields = List[String]()
    cNumericFields.resize(NumNumbers)
    lAlphaBlanks = List[Bool]()
    lAlphaBlanks.resize(NumAlphas, True)
    lNumericBlanks = List[Bool]()
    lNumericBlanks.resize(NumNumbers, True)
    for Count in range(1, NumMixers+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var idx = Count - 1
        state.dataBranchInputManager.Mixers[idx].Name = Alphas[0]
        state.dataBranchInputManager.Mixers[idx].OutletBranchName = Alphas[1]
        state.dataBranchInputManager.Mixers[idx].NumInletBranches = NumAlphas - 2
        state.dataBranchInputManager.Mixers[idx].InletBranchNames = List[String]()
        state.dataBranchInputManager.Mixers[idx].InletBranchNames.resize(state.dataBranchInputManager.Mixers[idx].NumInletBranches)
        for Loop in range(state.dataBranchInputManager.Mixers[idx].NumInletBranches):
            state.dataBranchInputManager.Mixers[idx].InletBranchNames[Loop] = Alphas[2+Loop+1]
    state.dataBranchInputManager.GetMixerInputFlag = False
    if not state.dataBranchInputManager.GetBranchInputFlag:
        GetBranchInput(state)
        state.dataBranchInputManager.GetBranchInputFlag = False
    for Count in range(NumMixers):
        var Found = Util.FindItemInList(state.dataBranchInputManager.Mixers[Count].OutletBranchName, state.dataBranchInputManager.Branch)
        if Found == -1:
            ShowSevereError(state, "GetMixerInput: Invalid Branch=" + state.dataBranchInputManager.Mixers[Count].OutletBranchName + ", referenced as Outlet Branch in " + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Mixers[Count].NumInletBranches):
            Found = Util.FindItemInList(state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop], state.dataBranchInputManager.Branch)
            if Found == -1:
                ShowSevereError(state, "GetMixerInput: Invalid Branch=" + state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop] + ", referenced as Inlet Branch # " + str(Loop+1) + " in " + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
                ErrorsFound = True
    for Count in range(NumMixers):
        TestName = state.dataBranchInputManager.Mixers[Count].OutletBranchName
        for Loop in range(state.dataBranchInputManager.Mixers[Count].NumInletBranches):
            if TestName != state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop]:
                continue
            ShowSevereError(state, CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name + " specifies an inlet node name the same as the outlet node.")
            ShowContinueError(state, "..Outlet Node=" + TestName)
            ShowContinueError(state, "..Inlet Node #" + str(Loop+1) + " is duplicate.")
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Mixers[Count].NumInletBranches):
            for Loop1 in range(Loop+1, state.dataBranchInputManager.Mixers[Count].NumInletBranches):
                if state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop] != state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop1]:
                    continue
                ShowSevereError(state, CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name + " specifies duplicate inlet nodes in its inlet node list.")
                ShowContinueError(state, "..Inlet Node #" + str(Loop+1) + " Name=" + state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop])
                ShowContinueError(state, "..Inlet Node #" + str(Loop+1) + " is duplicate.")
                ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetMixerInput: Fatal Errors Found in " + CurrentModuleObject + ", program terminates.")
    SaveSupplyDemandAir = ""
    for Count in range(NumMixers):
        TestName = state.dataBranchInputManager.Mixers[Count].OutletBranchName
        var BranchListName: String = ""
        for Loop1 in range(len(state.dataBranchInputManager.BranchList)):
            if Util.any_eq(state.dataBranchInputManager.BranchList[Loop1].BranchNames, TestName):
                BranchListName = state.dataBranchInputManager.BranchList[Loop1].Name
                break
        if BranchListName != "":
            FoundSupplyDemandAir = ""
            FoundLoop = ""
            MatchedLoop = False
            FindAirPlantCondenserLoopFromBranchList(state, BranchListName, FoundLoop, FoundSupplyDemandAir, MatchedLoop)
            if MatchedLoop:
                SaveSupplyDemandAir = FoundSupplyDemandAir
                SaveLoop = FoundLoop
            else:
                ShowSevereError(state, "GetMixerInput: Outlet Mixer Branch=\"" + TestName + "\" and BranchList=\"" + BranchListName + "\" not matched to a Air/Plant/Condenser Loop")
                ShowContinueError(state, "...and therefore, not a valid Loop Mixer.")
                ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
                ErrorsFound = True
        else:
            ShowSevereError(state, "GetMixerInput: Outlet Mixer Branch=\"" + TestName + "\" not on BranchList")
            ShowContinueError(state, "...and therefore, not a valid Loop Mixer.")
            ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
            ErrorsFound = True
        for Loop in range(state.dataBranchInputManager.Mixers[Count].NumInletBranches):
            TestName = state.dataBranchInputManager.Mixers[Count].InletBranchNames[Loop]
            BranchListName = ""
            for Loop1 in range(len(state.dataBranchInputManager.BranchList)):
                if Util.any_eq(state.dataBranchInputManager.BranchList[Loop1].BranchNames, TestName):
                    BranchListName = state.dataBranchInputManager.BranchList[Loop1].Name
                    break
            if BranchListName != "":
                FoundSupplyDemandAir = ""
                FoundLoop = ""
                MatchedLoop = False
                FindAirPlantCondenserLoopFromBranchList(state, BranchListName, FoundLoop, FoundSupplyDemandAir, MatchedLoop)
                if MatchedLoop:
                    if SaveSupplyDemandAir != FoundSupplyDemandAir or SaveLoop != FoundLoop:
                        ShowSevereError(state, "GetMixerInput: Outlet Mixer Branch=\"" + TestName + "\" does not match types of Inlet Branch.")
                        ShowContinueError(state, "...Outlet Branch is on \"" + SaveLoop + "\" on \"" + SaveSupplyDemandAir + "\" side.")
                        ShowContinueError(state, "...Inlet Branch is on \"" + FoundLoop + "\" on \"" + FoundSupplyDemandAir + "\" side.")
                        ShowContinueError(state, "...All branches in Loop Mixer must be on same kind of loop and supply/demand side.")
                        ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
                        ErrorsFound = True
                else:
                    ShowSevereError(state, "GetMixerInput: Inlet Mixer Branch=\"" + TestName + "\" and BranchList=\"" + BranchListName + "\" not matched to a Air/Plant/Condenser Loop")
                    ShowContinueError(state, "...and therefore, not a valid Loop Mixer.")
                    ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
                    ErrorsFound = True
            else:
                ShowSevereError(state, "GetMixerInput: Inlet Mixer Branch=\"" + TestName + "\" not on BranchList")
                ShowContinueError(state, "...and therefore, not a valid Loop Mixer")
                ShowContinueError(state, "..." + CurrentModuleObject + "=" + state.dataBranchInputManager.Mixers[Count].Name)
                ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetMixerInput: Fatal Errors Found in " + CurrentModuleObject + ", program terminates.")
def FindPlantLoopBranchConnection(state: EnergyPlusData,
                                 BranchListName: String,
                                 ref FoundPlantLoopName: String,
                                 ref FoundPlantLoopNum: Int,
                                 ref FoundSupplyDemand: String,
                                 ref FoundVolFlowRate: Float64,
                                 ref MatchedPlantLoop: Bool):
    var Num: Int
    var NumPlantLoops: Int
    var NumParams: Int
    var Alphas: List[String]
    var NumAlphas: Int
    var Numbers: List[Float64]
    var NumNumbers: Int
    var IOStat: Int
    var CurrentModuleObject = "PlantLoop"
    NumPlantLoops = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers)
    for Num in range(1, NumPlantLoops+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Num, Alphas, NumAlphas, Numbers, NumNumbers, IOStat)
        if Alphas[7] == BranchListName:  # 8th field, index 7
            FoundPlantLoopName = Alphas[0]
            FoundSupplyDemand = "Supply"
            FoundVolFlowRate = Numbers[2]  # 4th numeric field index 2
            FoundPlantLoopNum = Num
            MatchedPlantLoop = True
            break
        if Alphas[11] == BranchListName:  # 12th field, index 11
            FoundPlantLoopName = Alphas[0]
            FoundSupplyDemand = "Demand"
            FoundVolFlowRate = Numbers[2]
            FoundPlantLoopNum = Num
            MatchedPlantLoop = True
            break
def FindCondenserLoopBranchConnection(state: EnergyPlusData,
                                     BranchListName: String,
                                     ref FoundCondLoopName: String,
                                     ref FoundCondLoopNum: Int,
                                     ref FoundSupplyDemand: String,
                                     ref FoundVolFlowRate: Float64,
                                     ref MatchedCondLoop: Bool):
    var Num: Int
    var NumCondLoops: Int
    var NumParams: Int
    var Alphas: List[String]
    var NumAlphas: Int
    var Numbers: List[Float64]
    var NumNumbers: Int
    var IOStat: Int
    var CurrentModuleObject = "CondenserLoop"
    NumCondLoops = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers)
    for Num in range(1, NumCondLoops+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Num, Alphas, NumAlphas, Numbers, NumNumbers, IOStat)
        if Alphas[7] == BranchListName:
            FoundCondLoopName = Alphas[0]
            FoundSupplyDemand = "Supply"
            FoundVolFlowRate = Numbers[2]
            FoundCondLoopNum = Num
            MatchedCondLoop = True
            break
        if Alphas[11] == BranchListName:
            FoundCondLoopName = Alphas[0]
            FoundSupplyDemand = "Demand"
            FoundVolFlowRate = Numbers[2]
            FoundCondLoopNum = Num
            MatchedCondLoop = True
            break
def FindAirLoopBranchConnection(state: EnergyPlusData,
                               BranchListName: String,
                               ref FoundAirLoopName: String,
                               ref FoundAirLoopNum: Int,
                               ref FoundAir: String,
                               ref FoundVolFlowRate: Float64,
                               ref MatchedAirLoop: Bool):
    var Num: Int
    var NumAirLoops: Int
    var NumParams: Int
    var Alphas: List[String]
    var NumAlphas: Int
    var Numbers: List[Float64]
    var NumNumbers: Int
    var IOStat: Int
    var CurrentModuleObject = "AirLoopHVAC"
    NumAirLoops = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
    Alphas = List[String]()
    Alphas.resize(NumAlphas)
    Numbers = List[Float64]()
    Numbers.resize(NumNumbers)
    for Num in range(1, NumAirLoops+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Num, Alphas, NumAlphas, Numbers, NumNumbers, IOStat)
        if Alphas[3] == BranchListName:  # 4th field, index 3
            FoundAirLoopName = Alphas[0]
            FoundAir = "Air"
            FoundVolFlowRate = Numbers[0]  # 1st numeric field
            FoundAirLoopNum = Num
            MatchedAirLoop = True
            break
def FindAirPlantCondenserLoopFromBranchList(state: EnergyPlusData,
                                           BranchListName: String,
                                           ref LoopType: String,
                                           ref LoopSupplyDemandAir: String,
                                           ref MatchedLoop: Bool):
    var FoundLoopName: String
    var FoundLoopNum: Int
    var FoundLoopVolFlowRate: Float64
    LoopSupplyDemandAir = ""
    FoundLoopName = ""
    FoundLoopNum = 0
    FoundLoopVolFlowRate = 0.0
    MatchedLoop = False
    LoopType = ""
    FindPlantLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopSupplyDemandAir, FoundLoopVolFlowRate, MatchedLoop)
    if MatchedLoop:
        LoopType = "Plant"
    if not MatchedLoop:
        LoopSupplyDemandAir = ""
        FoundLoopName = ""
        FoundLoopNum = 0
        FoundLoopVolFlowRate = 0.0
        MatchedLoop = False
        FindCondenserLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopSupplyDemandAir, FoundLoopVolFlowRate, MatchedLoop)
        if MatchedLoop:
            LoopType = "Condenser"
    if not MatchedLoop:
        LoopSupplyDemandAir = ""
        FoundLoopName = ""
        FoundLoopNum = 0
        FoundLoopVolFlowRate = 0.0
        MatchedLoop = False
        FindAirLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopSupplyDemandAir, FoundLoopVolFlowRate, MatchedLoop)
        if MatchedLoop:
            LoopType = "Air"
def AuditBranches(state: EnergyPlusData,
                 mustprint: Bool,
                 CompType: Optional[String] = None,
                 CompName: Optional[String] = None):
    var NumDanglingCount: Int = 0
    var BlNum: Int
    var BrN: Int
    var CpN: Int
    var NeverFound: Bool = True
    var compType: String = ""
    var compName: String = ""
    if CompType is not None:
        compType = CompType.value()
    if CompName is not None:
        compName = CompName.value()
    for BrN in range(len(state.dataBranchInputManager.Branch)):
        var Found: Int = -1
        var FoundBranchName: String = ""
        if (CompType is not None) and (CompName is not None):
            for CpN in range(state.dataBranchInputManager.Branch[BrN].NumOfComponents):
                if not Util.SameString(compType, state.dataBranchInputManager.Branch[BrN].Component[CpN].CType) or \
                   not Util.SameString(compName, state.dataBranchInputManager.Branch[BrN].Component[CpN].Name):
                    continue
                FoundBranchName = state.dataBranchInputManager.Branch[BrN].Name
                NeverFound = False
        for BlNum in range(len(state.dataBranchInputManager.BranchList)):
            Found = Util.FindItemInList(state.dataBranchInputManager.Branch[BrN].Name, state.dataBranchInputManager.BranchList[BlNum].BranchNames, state.dataBranchInputManager.BranchList[BlNum].NumOfBranchNames)
            if Found != -1:
                break
        if Found != -1:
            continue
        NumDanglingCount += 1
        if state.dataGlobal.DisplayExtraWarnings or mustprint:
            if mustprint:
                ShowContinueError(state, "AuditBranches: Branch=\"" + state.dataBranchInputManager.Branch[BrN].Name + "\" not found on any BranchLists.")
                if FoundBranchName != "":
                    ShowContinueError(state, "Branch contains component, type=\"" + compType + "\", name=\"" + compName + "\"")
            else:
                ShowSevereMessage(state, "AuditBranches: Branch=\"" + state.dataBranchInputManager.Branch[BrN].Name + "\" not found on any BranchLists.")
                state.dataErrTracking.TotalSevereErrors += 1
    if mustprint and NeverFound:
        ShowContinueError(state, "Component, type=\"" + compType + "\", name=\"" + compName + "\" was not found on any Branch.")
        ShowContinueError(state, "Look for mistyped branch or component names/types.")
    if not mustprint and NumDanglingCount > 0:
        ShowSevereMessage(state, "AuditBranches: There are " + str(NumDanglingCount) + " branch(es) that do not appear on any BranchList.")
        state.dataErrTracking.TotalSevereErrors += NumDanglingCount
        ShowContinueError(state, "Use Output:Diagnostics,DisplayExtraWarnings; for detail of each branch not on a branch list.")
def TestBranchIntegrity(state: EnergyPlusData, ref ErrFound: Bool):
    var Loop: Int
    var Count: Int
    var MatchNode: Int
    var MatchNodeName: String
    var BranchInletNodeName: String
    var BranchOutletNodeName: String
    var BranchLoopName: String
    var BranchLoopType: String
    var NumErr: Int
    var BranchReported: List[Bool]
    var BCount: Int
    var Found: Int
    var Loop2: Int
    var BranchFluidType: Node.FluidType
    var InitialBranchFluidNode: Int
    var BranchFluidNodes: List[Int]
    var FoundBranches: List[Int]
    var BranchPtrs: List[Int]
    var cBranchFluidType: String
    var Ptr: Int
    var EndPtr: Int
    struct BranchUniqueNodes:
        var NumNodes: Int = 0
        var UniqueNodeNames: List[String]
    var BranchNodes: List[BranchUniqueNodes]
    BranchReported = List[Bool]()
    BranchReported.resize(len(state.dataBranchInputManager.Branch), False)
    ShowMessage(state, "Testing Individual Branch Integrity")
    ErrFound = False
    BranchNodes = List[BranchUniqueNodes]()
    BranchNodes.resize(len(state.dataBranchInputManager.Branch))
    state.files.bnd.write("! ===============================================================\n")
    var Format_700 = "! <#Branch Lists>,<Number of Branch Lists>"
    state.files.bnd.write(Format_700 + "\n")
    state.files.bnd.write("#Branch Lists," + str(len(state.dataBranchInputManager.BranchList)) + "\n")
    var Format_702 = "! <Branch List>,<Branch List Count>,<Branch List Name>,<Loop Name>,<Loop Type>,<Number of Branches>"
    state.files.bnd.write(Format_702 + "\n")
    var Format_704 = "! <Branch>,<Branch Count>,<Branch Name>,<Loop Name>,<Loop Type>,<Branch Inlet Node Name>,<Branch Outlet Node Name>"
    state.files.bnd.write(Format_704 + "\n")
    for BCount in range(1, len(state.dataBranchInputManager.BranchList)+1):
        var blIdx = BCount - 1
        state.files.bnd.write("Branch List," + str(BCount) + "," + state.dataBranchInputManager.BranchList[blIdx].Name + "," + state.dataBranchInputManager.BranchList[blIdx].LoopName + "," + state.dataBranchInputManager.BranchList[blIdx].LoopType + "," + str(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames) + "\n")
        BranchFluidType = Node.FluidType.Blank
        var MixedFluidTypesOnBranchList: Bool = False
        var NumNodesOnBranchList: Int = 0
        FoundBranches = List[Int]()
        FoundBranches.resize(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames, -1)
        BranchPtrs = List[Int]()
        BranchPtrs.resize(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames + 2, 0)
        for Count in range(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames):
            Found = Util.FindItemInList(state.dataBranchInputManager.BranchList[blIdx].BranchNames[Count], state.dataBranchInputManager.Branch)
            if Found >= 0:
                NumNodesOnBranchList += state.dataBranchInputManager.Branch[Found].NumOfComponents * 2
                FoundBranches[Count] = Found
                BranchPtrs[Count] = NumNodesOnBranchList
            else:
                ShowSevereError(state, "Branch not found=" + state.dataBranchInputManager.BranchList[blIdx].BranchNames[Count])
                ErrFound = True
        BranchPtrs[state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames] = NumNodesOnBranchList + 1  # BranchPtrs last +1
        BranchFluidNodes = List[Int]()
        BranchFluidNodes.resize(NumNodesOnBranchList, 0)
        var OriginalBranchFluidType: String = ""
        var NumFluidNodes: Int = 0
        for Count in range(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames):
            Found = FoundBranches[Count]
            if Found == -1:
                state.files.bnd.write("   Branch," + str(Count+1) + "," + state.dataBranchInputManager.BranchList[blIdx].BranchNames[Count] + ",(not found),**Unknown**,**Unknown**,**Unknown**,**Unknown**\n")
                continue
            BranchReported[Found] = True
            MatchNode = 0
            InitialBranchFluidNode = 0
            if state.dataBranchInputManager.Branch[Found].NumOfComponents > 0:
                MatchNode = state.dataBranchInputManager.Branch[Found].Component[0].InletNode
                MatchNodeName = state.dataBranchInputManager.Branch[Found].Component[0].InletNodeName
                BranchInletNodeName = state.dataBranchInputManager.Branch[Found].Component[0].InletNodeName
            else:
                ShowWarningError(state, "Branch has no components=" + state.dataBranchInputManager.Branch[Found].Name)
            NumErr = 0
            for Loop in range(state.dataBranchInputManager.Branch[Found].NumOfComponents):
                var inletNode = state.dataBranchInputManager.Branch[Found].Component[Loop].InletNode
                var outletNode = state.dataBranchInputManager.Branch[Found].Component[Loop].OutletNode
                if BranchFluidType == Node.FluidType.Blank:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = inletNode
                    BranchFluidType = state.dataLoopNodes.Node[inletNode].fluidType
                    InitialBranchFluidNode = inletNode
                    OriginalBranchFluidType = Node.FluidTypeNames[Int(Node.FluidType.Blank)]
                elif BranchFluidType != state.dataLoopNodes.Node[inletNode].fluidType and state.dataLoopNodes.Node[inletNode].fluidType != Node.FluidType.Blank:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = inletNode
                    MixedFluidTypesOnBranchList = True
                else:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = inletNode
                if BranchFluidType == Node.FluidType.Blank:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = outletNode
                    BranchFluidType = state.dataLoopNodes.Node[outletNode].fluidType
                    InitialBranchFluidNode = outletNode
                    OriginalBranchFluidType = Node.FluidTypeNames[Int(BranchFluidType)]
                elif BranchFluidType != state.dataLoopNodes.Node[outletNode].fluidType and state.dataLoopNodes.Node[outletNode].fluidType != Node.FluidType.Blank:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = outletNode
                    MixedFluidTypesOnBranchList = True
                else:
                    NumFluidNodes += 1
                    BranchFluidNodes[NumFluidNodes-1] = outletNode
                if state.dataBranchInputManager.Branch[Found].Component[Loop].InletNode != MatchNode:
                    ShowSevereError(state, "Error Detected in BranchList=" + state.dataBranchInputManager.BranchList[blIdx].Name)
                    ShowContinueError(state, "Actual Error occurs in Branch=" + state.dataBranchInputManager.Branch[Found].Name)
                    ShowContinueError(state, "Branch Outlet does not match Inlet, Outlet=" + MatchNodeName)
                    ShowContinueError(state, "Inlet Name=" + state.dataBranchInputManager.Branch[Found].Component[Loop].InletNodeName)
                    ErrFound = True
                    NumErr += 1
                else:
                    MatchNode = state.dataBranchInputManager.Branch[Found].Component[Loop].OutletNode
                    MatchNodeName = state.dataBranchInputManager.Branch[Found].Component[Loop].OutletNodeName
            state.dataBranchInputManager.Branch[Found].FluidType = BranchFluidType
            BranchOutletNodeName = MatchNodeName
            if state.dataBranchInputManager.Branch[Found].AssignedLoopName == "":
                BranchLoopName = "**Unknown**"
                BranchLoopType = "**Unknown**"
            elif state.dataBranchInputManager.Branch[Found].AssignedLoopName == state.dataBranchInputManager.BranchList[blIdx].LoopName:
                BranchLoopName = state.dataBranchInputManager.BranchList[blIdx].LoopName
                BranchLoopType = state.dataBranchInputManager.BranchList[blIdx].LoopType
            else:
                BranchLoopName = state.dataBranchInputManager.Branch[Found].AssignedLoopName
                BranchLoopType = "**Unknown**"
            state.files.bnd.write("   Branch," + str(Count+1) + "," + state.dataBranchInputManager.Branch[Found].Name + "," + BranchLoopName + "," + BranchLoopType + "," + BranchInletNodeName + "," + BranchOutletNodeName + "\n")
        if MixedFluidTypesOnBranchList:
            ShowSevereError(state, "BranchList=" + state.dataBranchInputManager.BranchList[blIdx].Name + " has mixed fluid types in its nodes.")
            ErrFound = True
            if OriginalBranchFluidType == "":
                OriginalBranchFluidType = "**Unknown**"
            ShowContinueError(state, "Initial Node=" + state.dataLoopNodes.NodeID[InitialBranchFluidNode] + ", Fluid Type=" + OriginalBranchFluidType)
            ShowContinueError(state, "BranchList Topology - Note nodes which do not match that fluid type:")
            Ptr = 0
            EndPtr = BranchPtrs[0] if len(BranchPtrs) > 0 else 0
            for Loop in range(state.dataBranchInputManager.BranchList[blIdx].NumOfBranchNames):
                if FoundBranches[Loop] != -1:
                    ShowContinueError(state, "..Branch=" + state.dataBranchInputManager.Branch[FoundBranches[Loop]].Name)
                else:
                    ShowContinueError(state, "..Illegal Branch=" + state.dataBranchInputManager.BranchList[blIdx].BranchNames[Loop])
                    continue
                for Loop2 in range(Ptr, EndPtr):
                    cBranchFluidType = Node.FluidTypeNames[Int(state.dataLoopNodes.Node[BranchFluidNodes[Loop2]].fluidType)]
                    if cBranchFluidType == "":
                        cBranchFluidType = "**Unknown**"
                    ShowContinueError(state, "....Node=" + state.dataLoopNodes.NodeID[BranchFluidNodes[Loop2]] + ", Fluid Type=" + cBranchFluidType)
                Ptr = EndPtr + 1
                EndPtr = BranchPtrs[Loop+1] if Loop+1 < len(BranchPtrs) else 0
    for Count in range(len(state.dataBranchInputManager.Branch)):
        BranchNodes[Count] = BranchUniqueNodes()
        BranchNodes[Count].UniqueNodeNames = List[String]()
        BranchNodes[Count].UniqueNodeNames.resize(state.dataBranchInputManager.Branch[Count].NumOfComponents * 2)
        var NodeNum: Int = 0
        for Loop in range(state.dataBranchInputManager.Branch[Count].NumOfComponents):
            var inletName = state.dataBranchInputManager.Branch[Count].Component[Loop].InletNodeName
            var outletName = state.dataBranchInputManager.Branch[Count].Component[Loop].OutletNodeName
            Found = Util.FindItemInList(inletName, BranchNodes[Count].UniqueNodeNames, NodeNum)
            if Found == -1:
                BranchNodes[Count].UniqueNodeNames[NodeNum] = inletName
                NodeNum += 1
            Found = Util.FindItemInList(outletName, BranchNodes[Count].UniqueNodeNames, NodeNum)
            if Found == -1:
                BranchNodes[Count].UniqueNodeNames[NodeNum] = outletName
                NodeNum += 1
        BranchNodes[Count].NumNodes = NodeNum
    for Count in range(len(state.dataBranchInputManager.Branch)):
        for Loop in range(Count+1, len(state.dataBranchInputManager.Branch)):
            for Loop2 in range(BranchNodes[Count].NumNodes):
                Found = Util.FindItemInList(BranchNodes[Count].UniqueNodeNames[Loop2], BranchNodes[Loop].UniqueNodeNames, BranchNodes[Loop].NumNodes)
                if Found != -1:
                    ShowSevereError(state, "Non-unique node name found, name=" + BranchNodes[Count].UniqueNodeNames[Loop2])
                    ShowContinueError(state, "..1st occurrence in Branch=" + state.dataBranchInputManager.Branch[Count].Name)
                    ShowContinueError(state, "..duplicate occurrence in Branch=" + state.dataBranchInputManager.Branch[Loop].Name)
                    ErrFound = True
    BCount = 0
    for Count in range(len(state.dataBranchInputManager.Branch)):
        if BranchReported[Count]:
            continue
        BCount += 1
    if BCount > 0:
        var Format_706 = "! <# Orphaned Branches>,<Number of Branches not on Branch Lists>"
        state.files.bnd.write(Format_706 + "\n")
        state.files.bnd.write("#Orphaned Branches," + str(BCount) + "\n")
        ShowWarningError(state, "There are orphaned Branches in input. See .bnd file for details.")
        BCount = 0
        for Count in range(len(state.dataBranchInputManager.Branch)):
            if BranchReported[Count]:
                continue
            BCount += 1
            ShowWarningError(state, "Orphan Branch=\"" + state.dataBranchInputManager.Branch[Count].Name + "\".")
            if state.dataBranchInputManager.Branch[Count].NumOfComponents > 0:
                MatchNode = state.dataBranchInputManager.Branch[Count].Component[0].InletNode
                MatchNodeName = state.dataBranchInputManager.Branch[Count].Component[0].InletNodeName
                BranchInletNodeName = state.dataBranchInputManager.Branch[Count].Component[0].InletNodeName
            else:
                ShowWarningError(state, "Branch has no components=" + state.dataBranchInputManager.Branch[Count].Name)
            NumErr = 0
            for Loop in range(state.dataBranchInputManager.Branch[Count].NumOfComponents):
                if state.dataBranchInputManager.Branch[Count].Component[Loop].InletNode != MatchNode:
                    ShowSevereError(state, "Error Detected in Branch=" + state.dataBranchInputManager.Branch[Count].Name)
                    ShowContinueError(state, "Branch Outlet does not match Inlet, Outlet=" + MatchNodeName)
                    ShowContinueError(state, "Inlet Name=" + state.dataBranchInputManager.Branch[Count].Component[Loop].InletNodeName)
                    ErrFound = True
                    NumErr += 1
                else:
                    MatchNode = state.dataBranchInputManager.Branch[Count].Component[Loop].OutletNode
                    MatchNodeName = state.dataBranchInputManager.Branch[Count].Component[Loop].OutletNodeName
            BranchOutletNodeName = MatchNodeName
            if state.dataBranchInputManager.Branch[Count].AssignedLoopName == "":
                BranchLoopName = "**Unknown**"
                BranchLoopType = "**Unknown**"
            else:
                BranchLoopName = state.dataBranchInputManager.Branch[Count].AssignedLoopName
                BranchLoopType = "**Unknown**"
            state.files.bnd.write(" Branch," + str(BCount) + "," + state.dataBranchInputManager.Branch[Count].Name + "," + BranchLoopName + "," + BranchLoopType + "," + BranchInletNodeName + "," + BranchOutletNodeName + "\n")
    if ErrFound:
        ShowSevereError(state, "Branch(es) did not pass integrity testing")
    else:
        ShowMessage(state, "All Branches passed integrity testing")