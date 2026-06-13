# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataSplitterComponent, .dataLoopNodes, .dataGlobal, .dataEnvrn, .dataContaminantBalance, .dataInputProcessing
# - Node.GetOnlySingleNode(state, name, ErrorsFound, connection_type, component_name, fluid_type, connection_side, stream, parent) → Int
# - Util.FindItemInList(name, array, field_name) → Int (0-based, or -1 if not found)
# - Psychrometrics.PsyHFnTdbW(T_db, W) → Float64
# - ShowFatalError(state, msg) → None
# - ShowSevereError(state, msg) → None
# - ShowContinueError(state, msg) → None
# - InputProcessor.getNumObjectsFound(state, module_name) → Int
# - InputProcessor.getObjectDefMaxArgs(state, module_name) → Tuple[Int, Int, Int]
# - InputProcessor.getObjectItem(...) → None (mutates arrays in place)

from collections.abc import Sized
from memory import UnsafePointer


struct SplitterConditions:
    """Splitter conditions — public because used by SimAirServingZones and Direct Air Unit"""
    var SplitterName: String
    var InletTemp: Float64
    var InletHumRat: Float64
    var InletEnthalpy: Float64
    var InletPressure: Float64
    var InletNode: Int
    var InletMassFlowRate: Float64
    var InletMassFlowRateMaxAvail: Float64
    var InletMassFlowRateMinAvail: Float64
    var NumOutletNodes: Int
    var OutletNode: List[Int]
    var OutletMassFlowRate: List[Float64]
    var OutletMassFlowRateMaxAvail: List[Float64]
    var OutletMassFlowRateMinAvail: List[Float64]
    var OutletTemp: List[Float64]
    var OutletHumRat: List[Float64]
    var OutletEnthalpy: List[Float64]
    var OutletPressure: List[Float64]
    
    fn __init__(inout self):
        self.SplitterName = String()
        self.InletTemp = 0.0
        self.InletHumRat = 0.0
        self.InletEnthalpy = 0.0
        self.InletPressure = 0.0
        self.InletNode = 0
        self.InletMassFlowRate = 0.0
        self.InletMassFlowRateMaxAvail = 0.0
        self.InletMassFlowRateMinAvail = 0.0
        self.NumOutletNodes = 0
        self.OutletNode = List[Int]()
        self.OutletMassFlowRate = List[Float64]()
        self.OutletMassFlowRateMaxAvail = List[Float64]()
        self.OutletMassFlowRateMinAvail = List[Float64]()
        self.OutletTemp = List[Float64]()
        self.OutletHumRat = List[Float64]()
        self.OutletEnthalpy = List[Float64]()
        self.OutletPressure = List[Float64]()


fn SimAirLoopSplitter(
    state: AnyType,
    CompName: String,
    FirstHVACIteration: Bool,
    FirstCall: Bool,
    inout SplitterInletChanged: List[Bool],
    inout CompIndex: List[Int]
) -> None:
    """Manages Splitter component simulation"""
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
    
    if CompIndex[0] == 0:
        var SplitterNum: Int = Util.FindItemInList(CompName, state.dataSplitterComponent.SplitterCond, "SplitterName")
        if SplitterNum == -1:
            ShowFatalError(state, String("SimAirLoopSplitter: Splitter not found=") + CompName)
        CompIndex[0] = SplitterNum + 1
    else:
        var SplitterNum: Int = CompIndex[0]
        if SplitterNum > state.dataSplitterComponent.NumSplitters or SplitterNum < 1:
            ShowFatalError(state, 
                String("SimAirLoopSplitter: Invalid CompIndex passed=") + str(SplitterNum) + 
                String(", Number of Splitters=") + str(state.dataSplitterComponent.NumSplitters) +
                String(", Splitter name=") + CompName)
        if state.dataSplitterComponent.CheckEquipName[SplitterNum - 1]:
            if CompName != state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName:
                ShowFatalError(state,
                    String("SimAirLoopSplitter: Invalid CompIndex passed=") + str(SplitterNum) +
                    String(", Splitter name=") + CompName +
                    String(", stored Splitter Name for that index=") +
                    state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName)
            state.dataSplitterComponent.CheckEquipName[SplitterNum - 1] = False
    
    InitAirLoopSplitter(state, CompIndex[0], FirstHVACIteration, FirstCall)
    CalcAirLoopSplitter(state, CompIndex[0], FirstCall)
    UpdateSplitter(state, CompIndex[0], SplitterInletChanged, FirstCall)
    ReportSplitter(CompIndex[0])


fn GetSplitterInput(state: AnyType) -> None:
    """Gets splitter input from input file"""
    state.dataSplitterComponent.GetSplitterInputFlag = False
    
    var CurrentModuleObject: String = "AirLoopHVAC:ZoneSplitter"
    state.dataSplitterComponent.NumSplitters = \
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    
    if state.dataSplitterComponent.NumSplitters > 0:
        state.dataSplitterComponent.SplitterCond = List[SplitterConditions]()
        for i in range(state.dataSplitterComponent.NumSplitters):
            state.dataSplitterComponent.SplitterCond.append(SplitterConditions())
    
    state.dataSplitterComponent.CheckEquipName = List[Bool]()
    for i in range(state.dataSplitterComponent.NumSplitters):
        state.dataSplitterComponent.CheckEquipName.append(True)
    
    var NumParams: Int
    var NumAlphas: Int
    var NumNums: Int
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
    
    var AlphArray: List[String] = List[String]()
    for i in range(NumAlphas):
        AlphArray.append(String())
    
    var cAlphaFields: List[String] = List[String]()
    for i in range(NumAlphas):
        cAlphaFields.append(String())
    
    var lAlphaBlanks: List[Bool] = List[Bool]()
    for i in range(NumAlphas):
        lAlphaBlanks.append(True)
    
    var cNumericFields: List[String] = List[String]()
    for i in range(NumNums):
        cNumericFields.append(String())
    
    var lNumericBlanks: List[Bool] = List[Bool]()
    for i in range(NumNums):
        lNumericBlanks.append(True)
    
    var NumArray: List[Float64] = List[Float64]()
    for i in range(NumNums):
        NumArray.append(0.0)
    
    var ErrorsFound: Bool = False
    
    for SplitterNum in range(state.dataSplitterComponent.NumSplitters):
        var IOStat: Int = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, SplitterNum + 1,
            AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        
        var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
            state.dataSplitterComponent.SplitterCond[SplitterNum])
        
        splitter[].SplitterName = AlphArray[0]
        splitter[].InletNode = Node.GetOnlySingleNode(state, AlphArray[1], ErrorsFound,
                                                      "AirLoopHVACZoneSplitter", AlphArray[0],
                                                      "Air", "Inlet", "Primary", False)
        splitter[].NumOutletNodes = NumAlphas - 2
        
        splitter[].OutletNode = List[Int]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletNode.append(0)
        splitter[].OutletMassFlowRate = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletMassFlowRate.append(0.0)
        splitter[].OutletMassFlowRateMaxAvail = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletMassFlowRateMaxAvail.append(0.0)
        splitter[].OutletMassFlowRateMinAvail = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletMassFlowRateMinAvail.append(0.0)
        splitter[].OutletTemp = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletTemp.append(0.0)
        splitter[].OutletHumRat = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletHumRat.append(0.0)
        splitter[].OutletEnthalpy = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletEnthalpy.append(0.0)
        splitter[].OutletPressure = List[Float64]()
        for i in range(splitter[].NumOutletNodes):
            splitter[].OutletPressure.append(0.0)
        
        splitter[].InletMassFlowRate = 0.0
        splitter[].InletMassFlowRateMaxAvail = 0.0
        splitter[].InletMassFlowRateMinAvail = 0.0
        
        for NodeNum in range(splitter[].NumOutletNodes):
            splitter[].OutletNode[NodeNum] = Node.GetOnlySingleNode(
                state, AlphArray[2 + NodeNum + 1], ErrorsFound,
                "AirLoopHVACZoneSplitter", AlphArray[0],
                "Air", "Outlet", "Primary", False)
            if lAlphaBlanks[2 + NodeNum]:
                ShowSevereError(state,
                    cAlphaFields[2 + NodeNum] + " is Blank, " + CurrentModuleObject + " = " + AlphArray[0])
                ErrorsFound = True
    
    for SplitterNum in range(state.dataSplitterComponent.NumSplitters):
        var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
            state.dataSplitterComponent.SplitterCond[SplitterNum])
        var NodeNum: Int = splitter[].InletNode
        for OutNodeNum1 in range(splitter[].NumOutletNodes):
            if NodeNum == splitter[].OutletNode[OutNodeNum1]:
                ShowSevereError(state,
                    CurrentModuleObject + " = " + splitter[].SplitterName + " specifies an outlet node " +
                    "name the same as the inlet node.")
                ShowContinueError(state, ".." + cAlphaFields[1] + "=" + str(state.dataLoopNodes.NodeID(NodeNum)))
                ShowContinueError(state, "..Outlet Node #" + str(OutNodeNum1 + 1) + " is duplicate.")
                ErrorsFound = True
        
        for OutNodeNum1 in range(splitter[].NumOutletNodes):
            for OutNodeNum2 in range(OutNodeNum1 + 1, splitter[].NumOutletNodes):
                if splitter[].OutletNode[OutNodeNum1] == splitter[].OutletNode[OutNodeNum2]:
                    ShowSevereError(state,
                        CurrentModuleObject + " = " + splitter[].SplitterName + " specifies duplicate " +
                        "outlet nodes in its outlet node list.")
                    ShowContinueError(state,
                        "..Outlet Node #" + str(OutNodeNum1 + 1) + " Name=" + 
                        str(state.dataLoopNodes.NodeID(OutNodeNum1)))
                    ShowContinueError(state, "..Outlet Node #" + str(OutNodeNum2 + 1) + " is duplicate.")
                    ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, "GetSplitterInput: Errors found in getting input.")


fn InitAirLoopSplitter(state: AnyType, SplitterNum: Int, 
                       FirstHVACIteration: Bool, FirstCall: Bool) -> None:
    """Initializes the splitter"""
    
    var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1])
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataSplitterComponent.MyEnvrnFlag:
        var AirEnthalpy: Float64 = Psychrometrics.PsyHFnTdbW(20.0, state.dataEnvrn.OutHumRat)
        
        var inletNode: AnyType = state.dataLoopNodes.Node[splitter[].InletNode]
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
    
    var inletNode: AnyType = state.dataLoopNodes.Node[splitter[].InletNode]
    
    if FirstHVACIteration and FirstCall:
        if inletNode.MassFlowRate > 0.0:
            for NodeNum in range(splitter[].NumOutletNodes):
                var outletNode: AnyType = state.dataLoopNodes.Node[splitter[].OutletNode[NodeNum]]
                outletNode.MassFlowRate = inletNode.MassFlowRate / splitter[].NumOutletNodes
        
        if inletNode.MassFlowRateMaxAvail > 0.0:
            for NodeNum in range(splitter[].NumOutletNodes):
                var outletNode: AnyType = state.dataLoopNodes.Node[splitter[].OutletNode[NodeNum]]
                outletNode.MassFlowRateMaxAvail = inletNode.MassFlowRateMaxAvail / splitter[].NumOutletNodes
    
    if FirstCall:
        if inletNode.MassFlowRateMaxAvail == 0.0:
            for NodeNum in range(splitter[].NumOutletNodes):
                var outletNode: AnyType = state.dataLoopNodes.Node[splitter[].OutletNode[NodeNum]]
                outletNode.MassFlowRate = 0.0
                outletNode.MassFlowRateMaxAvail = 0.0
                outletNode.MassFlowRateMinAvail = 0.0
        
        splitter[].InletTemp = inletNode.Temp
        splitter[].InletHumRat = inletNode.HumRat
        splitter[].InletEnthalpy = inletNode.Enthalpy
        splitter[].InletPressure = inletNode.Press
    else:
        for NodeNum in range(splitter[].NumOutletNodes):
            var outletNode: AnyType = state.dataLoopNodes.Node[splitter[].OutletNode[NodeNum]]
            splitter[].OutletMassFlowRate[NodeNum] = outletNode.MassFlowRate
            splitter[].OutletMassFlowRateMaxAvail[NodeNum] = outletNode.MassFlowRateMaxAvail
            splitter[].OutletMassFlowRateMinAvail[NodeNum] = outletNode.MassFlowRateMinAvail


fn CalcAirLoopSplitter(state: AnyType, SplitterNum: Int, FirstCall: Bool) -> None:
    """Calculates splitter conditions"""
    
    var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1])
    
    if FirstCall:
        for OutletNodeNum in range(splitter[].NumOutletNodes):
            splitter[].OutletHumRat[OutletNodeNum] = splitter[].InletHumRat
        
        for OutletNodeNum in range(splitter[].NumOutletNodes):
            splitter[].OutletPressure[OutletNodeNum] = splitter[].InletPressure
        
        for OutletNodeNum in range(splitter[].NumOutletNodes):
            splitter[].OutletEnthalpy[OutletNodeNum] = splitter[].InletEnthalpy
        
        for OutletNodeNum in range(splitter[].NumOutletNodes):
            splitter[].OutletTemp[OutletNodeNum] = splitter[].InletTemp
    else:
        splitter[].InletMassFlowRate = 0.0
        splitter[].InletMassFlowRateMaxAvail = 0.0
        splitter[].InletMassFlowRateMinAvail = 0.0
        
        for OutletNodeNum in range(splitter[].NumOutletNodes):
            splitter[].InletMassFlowRate += splitter[].OutletMassFlowRate[OutletNodeNum]
            splitter[].InletMassFlowRateMaxAvail += splitter[].OutletMassFlowRateMaxAvail[OutletNodeNum]
            splitter[].InletMassFlowRateMinAvail += splitter[].OutletMassFlowRateMinAvail[OutletNodeNum]


fn UpdateSplitter(state: AnyType, SplitterNum: Int, 
                  inout SplitterInletChanged: List[Bool], FirstCall: Bool) -> None:
    """Updates splitter outlet conditions"""
    
    var FlowRateToler: Float64 = 0.01
    
    var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1])
    var inletNode: AnyType = state.dataLoopNodes.Node[splitter[].InletNode]
    
    if FirstCall:
        for NodeNum in range(splitter[].NumOutletNodes):
            var outletNode: AnyType = state.dataLoopNodes.Node[splitter[].OutletNode[NodeNum]]
            outletNode.Temp = splitter[].OutletTemp[NodeNum]
            outletNode.HumRat = splitter[].OutletHumRat[NodeNum]
            outletNode.Enthalpy = splitter[].OutletEnthalpy[NodeNum]
            outletNode.Quality = inletNode.Quality
            outletNode.Press = splitter[].OutletPressure[NodeNum]
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                outletNode.CO2 = inletNode.CO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                outletNode.GenContam = inletNode.GenContam
    else:
        if abs(inletNode.MassFlowRate - splitter[].InletMassFlowRate) > FlowRateToler:
            SplitterInletChanged[0] = True
        inletNode.MassFlowRate = splitter[].InletMassFlowRate
        inletNode.MassFlowRateMaxAvail = splitter[].InletMassFlowRateMaxAvail
        inletNode.MassFlowRateMinAvail = splitter[].InletMassFlowRateMinAvail


fn ReportSplitter(SplitterNum: Int) -> None:
    """Reports splitter results"""
    pass


fn GetSplitterOutletNumber(state: AnyType, SplitterName: String, 
                           SplitterNum: Int, inout ErrorsFound: List[Bool]) -> Int:
    """Returns the number of outlet nodes for a splitter"""
    
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    
    var WhichSplitter: Int
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName, 
                                            state.dataSplitterComponent.SplitterCond,
                                            "SplitterName")
    else:
        WhichSplitter = SplitterNum - 1
    
    var SplitterOutletNumber: Int = 0
    if WhichSplitter != -1:
        SplitterOutletNumber = state.dataSplitterComponent.SplitterCond[WhichSplitter].NumOutletNodes
    
    if WhichSplitter == -1:
        ShowSevereError(state, String("GetSplitterOuletNumber: Could not find Splitter = \"") + SplitterName + "\"")
        ErrorsFound[0] = True
        SplitterOutletNumber = 0
    
    return SplitterOutletNumber


fn GetSplitterNodeNumbers(state: AnyType, SplitterName: String,
                          SplitterNum: Int, inout ErrorsFound: List[Bool]) -> List[Int]:
    """Returns the node numbers for a splitter"""
    
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    
    var WhichSplitter: Int
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName,
                                            state.dataSplitterComponent.SplitterCond,
                                            "SplitterName")
    else:
        WhichSplitter = SplitterNum - 1
    
    var SplitterNodeNumbers: List[Int] = List[Int]()
    if WhichSplitter != -1:
        var splitter: UnsafePointer[SplitterConditions] = UnsafePointer.address_of(
            state.dataSplitterComponent.SplitterCond[WhichSplitter])
        for i in range(splitter[].NumOutletNodes + 2):
            SplitterNodeNumbers.append(0)
        SplitterNodeNumbers[0] = splitter[].InletNode
        SplitterNodeNumbers[1] = splitter[].NumOutletNodes
        for i in range(splitter[].NumOutletNodes):
            SplitterNodeNumbers[i + 2] = splitter[].OutletNode[i]
    
    if WhichSplitter == -1:
        ShowSevereError(state, String("GetSplitterNodeNumbers: Could not find Splitter = \"") + SplitterName + "\"")
        ErrorsFound[0] = True
    
    return SplitterNodeNumbers
