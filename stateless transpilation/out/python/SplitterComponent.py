# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataSplitterComponent, .dataLoopNodes, .dataGlobal, .dataEnvrn, .dataContaminantBalance, .dataInputProcessing
# - Node.GetOnlySingleNode(state, name, ErrorsFound, connection_type, component_name, fluid_type, connection_side, stream, parent) → int
# - Util.FindItemInList(name, array, field_name) → int (0-based, or -1 if not found)
# - Psychrometrics.PsyHFnTdbW(T_db, W) → float
# - ShowFatalError(state, msg) → None
# - ShowSevereError(state, msg) → None
# - ShowContinueError(state, msg) → None
# - InputProcessor.getNumObjectsFound(state, module_name) → int
# - InputProcessor.getObjectDefMaxArgs(state, module_name) → tuple (NumParams, NumAlphas, NumNums)
# - InputProcessor.getObjectItem(...) → None (mutates arrays in place)

from dataclasses import dataclass, field
from typing import List, Protocol, Any

@dataclass
class SplitterConditions:
    """Splitter conditions — public because used by SimAirServingZones and Direct Air Unit"""
    SplitterName: str = ""
    InletTemp: float = 0.0
    InletHumRat: float = 0.0
    InletEnthalpy: float = 0.0
    InletPressure: float = 0.0
    InletNode: int = 0
    InletMassFlowRate: float = 0.0
    InletMassFlowRateMaxAvail: float = 0.0
    InletMassFlowRateMinAvail: float = 0.0
    NumOutletNodes: int = 0
    OutletNode: List[int] = field(default_factory=list)
    OutletMassFlowRate: List[float] = field(default_factory=list)
    OutletMassFlowRateMaxAvail: List[float] = field(default_factory=list)
    OutletMassFlowRateMinAvail: List[float] = field(default_factory=list)
    OutletTemp: List[float] = field(default_factory=list)
    OutletHumRat: List[float] = field(default_factory=list)
    OutletEnthalpy: List[float] = field(default_factory=list)
    OutletPressure: List[float] = field(default_factory=list)


def SimAirLoopSplitter(
    state: Any,
    CompName: str,
    FirstHVACIteration: bool,
    FirstCall: bool,
    SplitterInletChanged: List[bool],
    CompIndex: List[int]
) -> None:
    """Manages Splitter component simulation"""
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
    
    if CompIndex[0] == 0:
        SplitterNum = Util.FindItemInList(CompName, state.dataSplitterComponent.SplitterCond, 'SplitterName')
        if SplitterNum == -1:
            ShowFatalError(state, f"SimAirLoopSplitter: Splitter not found={CompName}")
        CompIndex[0] = SplitterNum + 1
    else:
        SplitterNum = CompIndex[0]
        if SplitterNum > state.dataSplitterComponent.NumSplitters or SplitterNum < 1:
            ShowFatalError(state, 
                f"SimAirLoopSplitter: Invalid CompIndex passed={SplitterNum}, "
                f"Number of Splitters={state.dataSplitterComponent.NumSplitters}, "
                f"Splitter name={CompName}")
        if state.dataSplitterComponent.CheckEquipName[SplitterNum - 1]:
            if CompName != state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName:
                ShowFatalError(state,
                    f"SimAirLoopSplitter: Invalid CompIndex passed={SplitterNum}, "
                    f"Splitter name={CompName}, "
                    f"stored Splitter Name for that index={state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName}")
            state.dataSplitterComponent.CheckEquipName[SplitterNum - 1] = False
    
    InitAirLoopSplitter(state, SplitterNum, FirstHVACIteration, FirstCall)
    CalcAirLoopSplitter(state, SplitterNum, FirstCall)
    UpdateSplitter(state, SplitterNum, SplitterInletChanged, FirstCall)
    ReportSplitter(SplitterNum)


def GetSplitterInput(state: Any) -> None:
    """Gets splitter input from input file"""
    state.dataSplitterComponent.GetSplitterInputFlag = False
    
    CurrentModuleObject = "AirLoopHVAC:ZoneSplitter"
    state.dataSplitterComponent.NumSplitters = \
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    
    if state.dataSplitterComponent.NumSplitters > 0:
        state.dataSplitterComponent.SplitterCond = [
            SplitterConditions() for _ in range(state.dataSplitterComponent.NumSplitters)
        ]
    state.dataSplitterComponent.CheckEquipName = [True] * state.dataSplitterComponent.NumSplitters
    
    NumParams, NumAlphas, NumNums = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, CurrentModuleObject)
    
    AlphArray = [""] * NumAlphas
    cAlphaFields = [""] * NumAlphas
    lAlphaBlanks = [True] * NumAlphas
    cNumericFields = [""] * NumNums
    lNumericBlanks = [True] * NumNums
    NumArray = [0.0] * NumNums
    
    ErrorsFound = False
    
    for SplitterNum in range(state.dataSplitterComponent.NumSplitters):
        IOStat = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, SplitterNum + 1,
            AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        
        splitter = state.dataSplitterComponent.SplitterCond[SplitterNum]
        
        splitter.SplitterName = AlphArray[0]
        splitter.InletNode = Node.GetOnlySingleNode(state, AlphArray[1], ErrorsFound,
                                                    "AirLoopHVACZoneSplitter", AlphArray[0],
                                                    "Air", "Inlet", "Primary", False)
        splitter.NumOutletNodes = NumAlphas - 2
        
        splitter.OutletNode = [0] * splitter.NumOutletNodes
        splitter.OutletMassFlowRate = [0.0] * splitter.NumOutletNodes
        splitter.OutletMassFlowRateMaxAvail = [0.0] * splitter.NumOutletNodes
        splitter.OutletMassFlowRateMinAvail = [0.0] * splitter.NumOutletNodes
        splitter.OutletTemp = [0.0] * splitter.NumOutletNodes
        splitter.OutletHumRat = [0.0] * splitter.NumOutletNodes
        splitter.OutletEnthalpy = [0.0] * splitter.NumOutletNodes
        splitter.OutletPressure = [0.0] * splitter.NumOutletNodes
        
        splitter.InletMassFlowRate = 0.0
        splitter.InletMassFlowRateMaxAvail = 0.0
        splitter.InletMassFlowRateMinAvail = 0.0
        
        for NodeNum in range(splitter.NumOutletNodes):
            splitter.OutletNode[NodeNum] = Node.GetOnlySingleNode(
                state, AlphArray[2 + NodeNum + 1], ErrorsFound,
                "AirLoopHVACZoneSplitter", AlphArray[0],
                "Air", "Outlet", "Primary", False)
            if lAlphaBlanks[2 + NodeNum]:
                ShowSevereError(state,
                    f"{cAlphaFields[2 + NodeNum]} is Blank, {CurrentModuleObject} = {AlphArray[0]}")
                ErrorsFound = True
    
    for SplitterNum in range(state.dataSplitterComponent.NumSplitters):
        splitter = state.dataSplitterComponent.SplitterCond[SplitterNum]
        NodeNum = splitter.InletNode
        for OutNodeNum1 in range(splitter.NumOutletNodes):
            if NodeNum == splitter.OutletNode[OutNodeNum1]:
                ShowSevereError(state,
                    f"{CurrentModuleObject} = {splitter.SplitterName} specifies an outlet node "
                    f"name the same as the inlet node.")
                ShowContinueError(state, f"..{cAlphaFields[1]}={state.dataLoopNodes.NodeID(NodeNum)}")
                ShowContinueError(state, f"..Outlet Node #{OutNodeNum1 + 1} is duplicate.")
                ErrorsFound = True
        
        for OutNodeNum1 in range(splitter.NumOutletNodes):
            for OutNodeNum2 in range(OutNodeNum1 + 1, splitter.NumOutletNodes):
                if splitter.OutletNode[OutNodeNum1] == splitter.OutletNode[OutNodeNum2]:
                    ShowSevereError(state,
                        f"{CurrentModuleObject} = {splitter.SplitterName} specifies duplicate "
                        f"outlet nodes in its outlet node list.")
                    ShowContinueError(state,
                        f"..Outlet Node #{OutNodeNum1 + 1} Name={state.dataLoopNodes.NodeID(OutNodeNum1)}")
                    ShowContinueError(state, f"..Outlet Node #{OutNodeNum2 + 1} is duplicate.")
                    ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, "GetSplitterInput: Errors found in getting input.")


def InitAirLoopSplitter(state: Any, SplitterNum: int, 
                        FirstHVACIteration: bool, FirstCall: bool) -> None:
    """Initializes the splitter"""
    
    splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataSplitterComponent.MyEnvrnFlag:
        AirEnthalpy = Psychrometrics.PsyHFnTdbW(20.0, state.dataEnvrn.OutHumRat)
        
        inletNode = state.dataLoopNodes.Node[splitter.InletNode]
        inletNode.Temp = 20.0
        inletNode.HumRat = state.dataEnvrn.OutHumRat
        inletNode.Enthalpy = AirEnthalpy
        inletNode.Press = state.dataEnvrn.OutBaroPress
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            inletNode.CO2 = state.dataContaminantBalance.OutdoorCO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            inletNode.GenContam = state.dataContaminantBalance.OutdoorGC
        
        state.dataSplitterComponent.MyEnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataSplitterComponent.MyEnvrnFlag = True
    
    inletNode = state.dataLoopNodes.Node[splitter.InletNode]
    
    if FirstHVACIteration and FirstCall:
        if inletNode.MassFlowRate > 0.0:
            for NodeNum in range(splitter.NumOutletNodes):
                outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum]]
                outletNode.MassFlowRate = inletNode.MassFlowRate / splitter.NumOutletNodes
        
        if inletNode.MassFlowRateMaxAvail > 0.0:
            for NodeNum in range(splitter.NumOutletNodes):
                outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum]]
                outletNode.MassFlowRateMaxAvail = inletNode.MassFlowRateMaxAvail / splitter.NumOutletNodes
    
    if FirstCall:
        if inletNode.MassFlowRateMaxAvail == 0.0:
            for NodeNum in range(splitter.NumOutletNodes):
                outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum]]
                outletNode.MassFlowRate = 0.0
                outletNode.MassFlowRateMaxAvail = 0.0
                outletNode.MassFlowRateMinAvail = 0.0
        
        splitter.InletTemp = inletNode.Temp
        splitter.InletHumRat = inletNode.HumRat
        splitter.InletEnthalpy = inletNode.Enthalpy
        splitter.InletPressure = inletNode.Press
    else:
        for NodeNum in range(splitter.NumOutletNodes):
            outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum]]
            splitter.OutletMassFlowRate[NodeNum] = outletNode.MassFlowRate
            splitter.OutletMassFlowRateMaxAvail[NodeNum] = outletNode.MassFlowRateMaxAvail
            splitter.OutletMassFlowRateMinAvail[NodeNum] = outletNode.MassFlowRateMinAvail


def CalcAirLoopSplitter(state: Any, SplitterNum: int, FirstCall: bool) -> None:
    """Calculates splitter conditions"""
    
    splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    
    if FirstCall:
        for OutletNodeNum in range(splitter.NumOutletNodes):
            splitter.OutletHumRat[OutletNodeNum] = splitter.InletHumRat
        
        for OutletNodeNum in range(splitter.NumOutletNodes):
            splitter.OutletPressure[OutletNodeNum] = splitter.InletPressure
        
        for OutletNodeNum in range(splitter.NumOutletNodes):
            splitter.OutletEnthalpy[OutletNodeNum] = splitter.InletEnthalpy
        
        for OutletNodeNum in range(splitter.NumOutletNodes):
            splitter.OutletTemp[OutletNodeNum] = splitter.InletTemp
    else:
        splitter.InletMassFlowRate = 0.0
        splitter.InletMassFlowRateMaxAvail = 0.0
        splitter.InletMassFlowRateMinAvail = 0.0
        
        for OutletNodeNum in range(splitter.NumOutletNodes):
            splitter.InletMassFlowRate += splitter.OutletMassFlowRate[OutletNodeNum]
            splitter.InletMassFlowRateMaxAvail += splitter.OutletMassFlowRateMaxAvail[OutletNodeNum]
            splitter.InletMassFlowRateMinAvail += splitter.OutletMassFlowRateMinAvail[OutletNodeNum]


def UpdateSplitter(state: Any, SplitterNum: int, 
                   SplitterInletChanged: List[bool], FirstCall: bool) -> None:
    """Updates splitter outlet conditions"""
    
    FlowRateToler = 0.01
    
    splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    inletNode = state.dataLoopNodes.Node[splitter.InletNode]
    
    if FirstCall:
        for NodeNum in range(splitter.NumOutletNodes):
            outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum]]
            outletNode.Temp = splitter.OutletTemp[NodeNum]
            outletNode.HumRat = splitter.OutletHumRat[NodeNum]
            outletNode.Enthalpy = splitter.OutletEnthalpy[NodeNum]
            outletNode.Quality = inletNode.Quality
            outletNode.Press = splitter.OutletPressure[NodeNum]
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                outletNode.CO2 = inletNode.CO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                outletNode.GenContam = inletNode.GenContam
    else:
        if abs(inletNode.MassFlowRate - splitter.InletMassFlowRate) > FlowRateToler:
            SplitterInletChanged[0] = True
        inletNode.MassFlowRate = splitter.InletMassFlowRate
        inletNode.MassFlowRateMaxAvail = splitter.InletMassFlowRateMaxAvail
        inletNode.MassFlowRateMinAvail = splitter.InletMassFlowRateMinAvail


def ReportSplitter(SplitterNum: int) -> None:
    """Reports splitter results"""
    pass


def GetSplitterOutletNumber(state: Any, SplitterName: str, 
                            SplitterNum: int, ErrorsFound: List[bool]) -> int:
    """Returns the number of outlet nodes for a splitter"""
    
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName, 
                                            state.dataSplitterComponent.SplitterCond,
                                            'SplitterName')
    else:
        WhichSplitter = SplitterNum - 1
    
    SplitterOutletNumber = 0
    if WhichSplitter != -1:
        SplitterOutletNumber = state.dataSplitterComponent.SplitterCond[WhichSplitter].NumOutletNodes
    
    if WhichSplitter == -1:
        ShowSevereError(state, f"GetSplitterOuletNumber: Could not find Splitter = \"{SplitterName}\"")
        ErrorsFound[0] = True
        SplitterOutletNumber = 0
    
    return SplitterOutletNumber


def GetSplitterNodeNumbers(state: Any, SplitterName: str,
                          SplitterNum: int, ErrorsFound: List[bool]) -> List[int]:
    """Returns the node numbers for a splitter"""
    
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName,
                                            state.dataSplitterComponent.SplitterCond,
                                            'SplitterName')
    else:
        WhichSplitter = SplitterNum - 1
    
    SplitterNodeNumbers: List[int] = []
    if WhichSplitter != -1:
        splitter = state.dataSplitterComponent.SplitterCond[WhichSplitter]
        SplitterNodeNumbers = [0] * (splitter.NumOutletNodes + 2)
        SplitterNodeNumbers[0] = splitter.InletNode
        SplitterNodeNumbers[1] = splitter.NumOutletNodes
        for i in range(splitter.NumOutletNodes):
            SplitterNodeNumbers[i + 2] = splitter.OutletNode[i]
    
    if WhichSplitter == -1:
        ShowSevereError(state, f"GetSplitterNodeNumbers: Could not find Splitter = \"{SplitterName}\"")
        ErrorsFound[0] = True
    
    return SplitterNodeNumbers
