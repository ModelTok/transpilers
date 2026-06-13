from cmath import abs as cabs
from Data.EnergyPlusData import EnergyPlusData
from DataContaminantBalance import state.dataContaminantBalance
from DataEnvironment import state.dataEnvrn
from DataLoopNode import state.dataLoopNodes
from InputProcessing.InputProcessor import state.dataInputProcessing.inputProcessor
from NodeInputManager import GetOnlySingleNode
from Psychrometrics import PsyHFnTdbW
from SplitterComponent import SplitterComponentData, SplitterConditions
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, Util
from EnergyPlus import format

struct SplitterConditions:
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

    def __init__(inout self):
        self.SplitterName = ""
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


def SimAirLoopSplitter(inout state: EnergyPlusData, CompName: StringLiteral, FirstHVACIteration: Bool, FirstCall: Bool, inout SplitterInletChanged: Bool, inout CompIndex: Int):
    var SplitterNum: Int
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
    if CompIndex == 0:
        SplitterNum = Util.FindItemInList(CompName, state.dataSplitterComponent.SplitterCond, SplitterConditions.SplitterName)
        if SplitterNum == 0:
            ShowFatalError(state, format("SimAirLoopSplitter: Splitter not found={}", CompName))
        CompIndex = SplitterNum
    else:
        SplitterNum = CompIndex
        if SplitterNum > state.dataSplitterComponent.NumSplitters or SplitterNum < 1:
            ShowFatalError(state, format("SimAirLoopSplitter: Invalid CompIndex passed={}, Number of Splitters={}, Splitter name={}", SplitterNum, state.dataSplitterComponent.NumSplitters, CompName))
        if state.dataSplitterComponent.CheckEquipName[SplitterNum - 1]:
            if CompName != state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName:
                ShowFatalError(state, format("SimAirLoopSplitter: Invalid CompIndex passed={}, Splitter name={}, stored Splitter Name for that index={}", SplitterNum, CompName, state.dataSplitterComponent.SplitterCond[SplitterNum - 1].SplitterName))
            state.dataSplitterComponent.CheckEquipName[SplitterNum - 1] = False
    InitAirLoopSplitter(state, SplitterNum, FirstHVACIteration, FirstCall)
    CalcAirLoopSplitter(state, SplitterNum, FirstCall)
    UpdateSplitter(state, SplitterNum, SplitterInletChanged, FirstCall)
    ReportSplitter(SplitterNum)


def GetSplitterInput(inout state: EnergyPlusData):
    var RoutineName: StringLiteral = "GetSplitterInput: "
    var SplitterNum: Int
    var NumAlphas: Int
    var NumNums: Int
    var NodeNum: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    var NumParams: Int
    var OutNodeNum1: Int
    var OutNodeNum2: Int
    var CurrentModuleObject: String
    var AlphArray: List[String]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var NumArray: List[Float64]
    var lAlphaBlanks: List[Bool]
    var lNumericBlanks: List[Bool]

    state.dataSplitterComponent.GetSplitterInputFlag = False
    CurrentModuleObject = "AirLoopHVAC:ZoneSplitter"
    state.dataSplitterComponent.NumSplitters = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    if state.dataSplitterComponent.NumSplitters > 0:
        state.dataSplitterComponent.SplitterCond = List[SplitterConditions](state.dataSplitterComponent.NumSplitters)
    state.dataSplitterComponent.CheckEquipName = List[Bool](state.dataSplitterComponent.NumSplitters)
    for i in range(state.dataSplitterComponent.NumSplitters):
        state.dataSplitterComponent.CheckEquipName[i] = True

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
    AlphArray = List[String](NumAlphas)
    cAlphaFields = List[String](NumAlphas)
    lAlphaBlanks = List[Bool](NumAlphas)
    for i in range(NumAlphas):
        lAlphaBlanks[i] = True
    cNumericFields = List[String](NumNums)
    lNumericBlanks = List[Bool](NumNums)
    for i in range(NumNums):
        lNumericBlanks[i] = True
    NumArray = List[Float64](NumNums)
    for i in range(NumNums):
        NumArray[i] = 0.0

    for SplitterNum in range(1, state.dataSplitterComponent.NumSplitters + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, SplitterNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
        splitter.SplitterName = AlphArray[0]
        splitter.InletNode = GetOnlySingleNode(state, AlphArray[1], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACZoneSplitter, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        splitter.NumOutletNodes = NumAlphas - 2
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode = List[Int](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletMassFlowRate = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletMassFlowRateMaxAvail = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletMassFlowRateMinAvail = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletTemp = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletHumRat = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletEnthalpy = List[Float64](splitter.NumOutletNodes)
        state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletPressure = List[Float64](splitter.NumOutletNodes)
        splitter.InletMassFlowRate = 0.0
        splitter.InletMassFlowRateMaxAvail = 0.0
        splitter.InletMassFlowRateMinAvail = 0.0
        for NodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.OutletNode[NodeNum - 1] = GetOnlySingleNode(state, AlphArray[1 + NodeNum], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACZoneSplitter, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            if lAlphaBlanks[1 + NodeNum]:
                ShowSevereError(state, format("{} is Blank, {} = {}", cAlphaFields[1 + NodeNum], CurrentModuleObject, AlphArray[0]))
                ErrorsFound = True

    for SplitterNum in range(1, state.dataSplitterComponent.NumSplitters + 1):
        var splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
        NodeNum = splitter.InletNode
        for OutNodeNum1 in range(1, splitter.NumOutletNodes + 1):
            if NodeNum != splitter.OutletNode[OutNodeNum1 - 1]:
                continue
            ShowSevereError(state, format("{} = {} specifies an outlet node name the same as the inlet node.", CurrentModuleObject, splitter.SplitterName))
            ShowContinueError(state, format("..{}={}", cAlphaFields[1], state.dataLoopNodes.NodeID[NodeNum - 1]))
            ShowContinueError(state, format("..Outlet Node #{} is duplicate.", OutNodeNum1))
            ErrorsFound = True
        for OutNodeNum1 in range(1, splitter.NumOutletNodes + 1):
            for OutNodeNum2 in range(OutNodeNum1 + 1, splitter.NumOutletNodes + 1):
                if splitter.OutletNode[OutNodeNum1 - 1] != splitter.OutletNode[OutNodeNum2 - 1]:
                    continue
                ShowSevereError(state, format("{} = {} specifies duplicate outlet nodes in its outlet node list.", CurrentModuleObject, splitter.SplitterName))
                ShowContinueError(state, format("..Outlet Node #{} Name={}", OutNodeNum1, state.dataLoopNodes.NodeID[OutNodeNum1 - 1]))
                ShowContinueError(state, format("..Outlet Node #{} is duplicate.", OutNodeNum2))
                ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(state, format("{}Errors found in getting input.", RoutineName))


def InitAirLoopSplitter(inout state: EnergyPlusData, SplitterNum: Int, FirstHVACIteration: Bool, FirstCall: Bool):
    var NodeNum: Int
    var AirEnthalpy: Float64
    var splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    if state.dataGlobal.BeginEnvrnFlag and state.dataSplitterComponent.MyEnvrnFlag:
        AirEnthalpy = PsyHFnTdbW(20.0, state.dataEnvrn.OutHumRat)
        var inletNode = state.dataLoopNodes.Node[splitter.InletNode - 1]
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
    var inletNode = state.dataLoopNodes.Node[splitter.InletNode - 1]
    if FirstHVACIteration and FirstCall:
        if inletNode.MassFlowRate > 0.0:
            for NodeNum in range(1, splitter.NumOutletNodes + 1):
                var outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum - 1] - 1]
                outletNode.MassFlowRate = inletNode.MassFlowRate / splitter.NumOutletNodes
        if inletNode.MassFlowRateMaxAvail > 0.0:
            for NodeNum in range(1, splitter.NumOutletNodes + 1):
                var outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum - 1] - 1]
                outletNode.MassFlowRateMaxAvail = inletNode.MassFlowRateMaxAvail / splitter.NumOutletNodes
    if FirstCall:
        if inletNode.MassFlowRateMaxAvail == 0.0:
            for NodeNum in range(1, splitter.NumOutletNodes + 1):
                var outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum - 1] - 1]
                outletNode.MassFlowRate = 0.0
                outletNode.MassFlowRateMaxAvail = 0.0
                outletNode.MassFlowRateMinAvail = 0.0
        splitter.InletTemp = inletNode.Temp
        splitter.InletHumRat = inletNode.HumRat
        splitter.InletEnthalpy = inletNode.Enthalpy
        splitter.InletPressure = inletNode.Press
    else:
        for NodeNum in range(1, splitter.NumOutletNodes + 1):
            var outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum - 1] - 1]
            splitter.OutletMassFlowRate[NodeNum - 1] = outletNode.MassFlowRate
            splitter.OutletMassFlowRateMaxAvail[NodeNum - 1] = outletNode.MassFlowRateMaxAvail
            splitter.OutletMassFlowRateMinAvail[NodeNum - 1] = outletNode.MassFlowRateMinAvail


def CalcAirLoopSplitter(inout state: EnergyPlusData, SplitterNum: Int, FirstCall: Bool):
    var OutletNodeNum: Int
    var splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    if FirstCall:
        for OutletNodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.OutletHumRat[OutletNodeNum - 1] = splitter.InletHumRat
        for OutletNodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.OutletPressure[OutletNodeNum - 1] = splitter.InletPressure
        for OutletNodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.OutletEnthalpy[OutletNodeNum - 1] = splitter.InletEnthalpy
        for OutletNodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.OutletTemp[OutletNodeNum - 1] = splitter.InletTemp
    else:
        splitter.InletMassFlowRate = 0.0
        splitter.InletMassFlowRateMaxAvail = 0.0
        splitter.InletMassFlowRateMinAvail = 0.0
        for OutletNodeNum in range(1, splitter.NumOutletNodes + 1):
            splitter.InletMassFlowRate += splitter.OutletMassFlowRate[OutletNodeNum - 1]
            splitter.InletMassFlowRateMaxAvail += splitter.OutletMassFlowRateMaxAvail[OutletNodeNum - 1]
            splitter.InletMassFlowRateMinAvail += splitter.OutletMassFlowRateMinAvail[OutletNodeNum - 1]


def UpdateSplitter(inout state: EnergyPlusData, SplitterNum: Int, inout SplitterInletChanged: Bool, FirstCall: Bool):
    var FlowRateToler: Float64 = 0.01
    var splitter = state.dataSplitterComponent.SplitterCond[SplitterNum - 1]
    var inletNode = state.dataLoopNodes.Node[splitter.InletNode - 1]
    if FirstCall:
        for NodeNum in range(1, splitter.NumOutletNodes + 1):
            var outletNode = state.dataLoopNodes.Node[splitter.OutletNode[NodeNum - 1] - 1]
            outletNode.Temp = splitter.OutletTemp[NodeNum - 1]
            outletNode.HumRat = splitter.OutletHumRat[NodeNum - 1]
            outletNode.Enthalpy = splitter.OutletEnthalpy[NodeNum - 1]
            outletNode.Quality = inletNode.Quality
            outletNode.Press = splitter.OutletPressure[NodeNum - 1]
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                outletNode.CO2 = inletNode.CO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                outletNode.GenContam = inletNode.GenContam
    else:
        if cabs(inletNode.MassFlowRate - splitter.InletMassFlowRate) > FlowRateToler:
            SplitterInletChanged = True
        inletNode.MassFlowRate = splitter.InletMassFlowRate
        inletNode.MassFlowRateMaxAvail = splitter.InletMassFlowRateMaxAvail
        inletNode.MassFlowRateMinAvail = splitter.InletMassFlowRateMinAvail


def ReportSplitter(SplitterNum: Int):

def GetSplitterOutletNumber(inout state: EnergyPlusData, SplitterName: String, SplitterNum: Int, inout ErrorsFound: Bool) -> Int:
    var SplitterOutletNumber: Int
    var WhichSplitter: Int
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName, state.dataSplitterComponent.SplitterCond, SplitterConditions.SplitterName)
    else:
        WhichSplitter = SplitterNum
    if WhichSplitter != 0:
        SplitterOutletNumber = state.dataSplitterComponent.SplitterCond[WhichSplitter - 1].NumOutletNodes
    if WhichSplitter == 0:
        ShowSevereError(state, format("GetSplitterOuletNumber: Could not find Splitter = \"{}\"", SplitterName))
        ErrorsFound = True
        SplitterOutletNumber = 0
    return SplitterOutletNumber


def GetSplitterNodeNumbers(inout state: EnergyPlusData, SplitterName: String, SplitterNum: Int, inout ErrorsFound: Bool) -> List[Int]:
    var SplitterNodeNumbers: List[Int]
    var WhichSplitter: Int
    if state.dataSplitterComponent.GetSplitterInputFlag:
        GetSplitterInput(state)
        state.dataSplitterComponent.GetSplitterInputFlag = False
    if SplitterNum == 0:
        WhichSplitter = Util.FindItemInList(SplitterName, state.dataSplitterComponent.SplitterCond, SplitterConditions.SplitterName)
    else:
        WhichSplitter = SplitterNum
    if WhichSplitter != 0:
        SplitterNodeNumbers = List[Int](state.dataSplitterComponent.SplitterCond[WhichSplitter - 1].NumOutletNodes + 2)
        SplitterNodeNumbers[0] = state.dataSplitterComponent.SplitterCond[WhichSplitter - 1].InletNode
        SplitterNodeNumbers[1] = state.dataSplitterComponent.SplitterCond[WhichSplitter - 1].NumOutletNodes
        for i in range(1, SplitterNodeNumbers[1] + 1):
            SplitterNodeNumbers[i + 1] = state.dataSplitterComponent.SplitterCond[WhichSplitter - 1].OutletNode[i - 1]
    if WhichSplitter == 0:
        ShowSevereError(state, format("GetSplitterNodeNumbers: Could not find Splitter = \"{}\"", SplitterName))
        ErrorsFound = True
    return SplitterNodeNumbers