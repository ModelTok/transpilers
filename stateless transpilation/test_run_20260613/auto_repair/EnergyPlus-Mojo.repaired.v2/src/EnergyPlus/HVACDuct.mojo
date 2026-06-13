from BranchNodeConnections import ...
from .Data.EnergyPlusData import EnergyPlusData
from DataContaminantBalance import ...
from DataIPShortCuts import ...
from DataLoopNode import ...
from .InputProcessing.InputProcessor import ...
from NodeInputManager import GetOnlySingleNode, TestCompSet
from UtilityRoutines import ShowFatalError, Util

struct DuctData:
    var Name: String
    var InletNodeNum: Int
    var OutletNodeNum: Int

    def __init__(inout self):
        self.Name = String("")
        self.InletNodeNum = 0
        self.OutletNodeNum = 0

struct HVACDuctData:
    var NumDucts: Int = 0
    var CheckEquipName: List[Bool]
    var Duct: List[DuctData]
    var GetInputFlag: Bool = True

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumDucts = 0
        self.CheckEquipName = List[Bool]()
        self.Duct = List[DuctData]()
        self.GetInputFlag = True


def SimDuct(mut state: EnergyPlusData, CompName: String, FirstHVACIteration: Bool, mut CompIndex: Int):
    var DuctNum: Int
    if state.dataHVACDuct.GetInputFlag:
        GetDuctInput(state)
        state.dataHVACDuct.GetInputFlag = False
    if CompIndex == 0:
        DuctNum = Util.FindItemInList(CompName, state.dataHVACDuct.Duct)
        if DuctNum == 0:
            ShowFatalError(state, String("SimDuct: Component not found=") + CompName)
        CompIndex = DuctNum
    else:
        DuctNum = CompIndex
        if DuctNum > state.dataHVACDuct.NumDucts or DuctNum < 1:
            ShowFatalError(state, String("SimDuct:  Invalid CompIndex passed=") + String(DuctNum) + 
                           ", Number of Components=" + String(state.dataHVACDuct.NumDucts) + 
                           ", Entered Component name=" + CompName)
        if state.dataHVACDuct.CheckEquipName[DuctNum - 1]:
            if CompName != state.dataHVACDuct.Duct[DuctNum - 1].Name:
                ShowFatalError(state, String("SimDuct: Invalid CompIndex passed=") + String(DuctNum) + 
                               ", Component name=" + CompName + 
                               ", stored Component Name for that index=" + state.dataHVACDuct.Duct[DuctNum - 1].Name)
            state.dataHVACDuct.CheckEquipName[DuctNum - 1] = False
    CalcDuct(DuctNum)
    UpdateDuct(state, DuctNum)
    ReportDuct(DuctNum)

def GetDuctInput(mut state: EnergyPlusData):
    var DuctNum: Int
    let RoutineName: String = "GetDuctInput:"
    var NumAlphas: Int
    var NumNumbers: Int
    var IOStatus: Int
    var ErrorsFound: Bool = False
    var cCurrentModuleObject = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "Duct"
    state.dataHVACDuct.NumDucts = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataHVACDuct.Duct = List[DuctData](capacity=state.dataHVACDuct.NumDucts)
    for _ in range(state.dataHVACDuct.NumDucts):
        state.dataHVACDuct.Duct.append(DuctData())
    state.dataHVACDuct.CheckEquipName = List[Bool](capacity=state.dataHVACDuct.NumDucts)
    for _ in range(state.dataHVACDuct.NumDucts):
        state.dataHVACDuct.CheckEquipName.append(True)
    for DuctNum in range(1, state.dataHVACDuct.NumDucts + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            DuctNum,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames)
        state.dataHVACDuct.Duct[DuctNum - 1].Name = state.dataIPShortCut.cAlphaArgs[0]
        state.dataHVACDuct.Duct[DuctNum - 1].InletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs[1],
            ErrorsFound,
            Node.ConnectionObjectType.Duct,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Air,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        state.dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs[2],
            ErrorsFound,
            Node.ConnectionObjectType.Duct,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Air,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        TestCompSet(
            state,
            cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            "Air Nodes")
    if ErrorsFound:
        ShowFatalError(state, RoutineName + " Errors found in input")

def CalcDuct(DuctNum: Int):

def UpdateDuct(mut state: EnergyPlusData, DuctNum: Int):
    var InNode: Int
    var OutNode: Int
    InNode = state.dataHVACDuct.Duct[DuctNum - 1].InletNodeNum
    OutNode = state.dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum
    state.dataLoopNodes.Node[OutNode - 1].MassFlowRate = state.dataLoopNodes.Node[InNode - 1].MassFlowRate
    state.dataLoopNodes.Node[OutNode - 1].Temp = state.dataLoopNodes.Node[InNode - 1].Temp
    state.dataLoopNodes.Node[OutNode - 1].HumRat = state.dataLoopNodes.Node[InNode - 1].HumRat
    state.dataLoopNodes.Node[OutNode - 1].Enthalpy = state.dataLoopNodes.Node[InNode - 1].Enthalpy
    state.dataLoopNodes.Node[OutNode - 1].Quality = state.dataLoopNodes.Node[InNode - 1].Quality
    state.dataLoopNodes.Node[OutNode - 1].Press = state.dataLoopNodes.Node[InNode - 1].Press
    state.dataLoopNodes.Node[OutNode - 1].MassFlowRateMin = state.dataLoopNodes.Node[InNode - 1].MassFlowRateMin
    state.dataLoopNodes.Node[OutNode - 1].MassFlowRateMax = state.dataLoopNodes.Node[InNode - 1].MassFlowRateMax
    state.dataLoopNodes.Node[OutNode - 1].MassFlowRateMinAvail = state.dataLoopNodes.Node[InNode - 1].MassFlowRateMinAvail
    state.dataLoopNodes.Node[OutNode - 1].MassFlowRateMaxAvail = state.dataLoopNodes.Node[InNode - 1].MassFlowRateMaxAvail
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[OutNode - 1].CO2 = state.dataLoopNodes.Node[InNode - 1].CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[OutNode - 1].GenContam = state.dataLoopNodes.Node[InNode - 1].GenContam

def ReportDuct(DuctNum: Int):
