from memory import Arc
from collections import Dict


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state.dataHVACDuct (HVACDuctData), state.dataIPShortCut (DataIPShortCuts),
#   state.dataInputProcessing.inputProcessor (InputProcessor), state.dataLoopNodes.Node,
#   state.dataContaminantBalance.Contaminant
# - Util.FindItemInList(name, array) -> Int
# - ShowFatalError(state, message) -> None
# - Node.GetOnlySingleNode(...) -> Int
# - Node.TestCompSet(state, module_name, component_name, inlet_name, outlet_name, node_type) -> None
# - Node.ConnectionObjectType.Duct (enum value)
# - Node.FluidType.Air (enum value)
# - Node.ConnectionType.Inlet, Node.ConnectionType.Outlet (enum values)
# - Node.CompFluidStream.Primary (enum value)
# - Node.ObjectIsNotParent (enum value)


struct DuctData:
    var Name: String
    var InletNodeNum: Int
    var OutletNodeNum: Int

    fn __init__(inout self) -> None:
        self.Name = ""
        self.InletNodeNum = 0
        self.OutletNodeNum = 0


struct HVACDuctData:
    var NumDucts: Int
    var CheckEquipName: List[Bool]
    var Duct: List[DuctData]
    var GetInputFlag: Bool

    fn __init__(inout self) -> None:
        self.NumDucts = 0
        self.CheckEquipName = List[Bool]()
        self.Duct = List[DuctData]()
        self.GetInputFlag = True

    fn init_constant_state(inout self, state: Arc[EnergyPlusData]) -> None:
        pass

    fn init_state(inout self, state: Arc[EnergyPlusData]) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.NumDucts = 0
        self.CheckEquipName.clear()
        self.Duct.clear()
        self.GetInputFlag = True


fn SimDuct(
    state: Arc[EnergyPlusData],
    CompName: StringSlice,
    FirstHVACIteration: Bool,
    inout CompIndex: Int,
) -> None:
    if state[].dataHVACDuct.GetInputFlag:
        GetDuctInput(state)
        state[].dataHVACDuct.GetInputFlag = False

    var DuctNum: Int

    if CompIndex == 0:
        DuctNum = FindItemInList(CompName, state[].dataHVACDuct.Duct)
        if DuctNum == 0:
            ShowFatalError(state, String("SimDuct: Component not found=") + String(CompName))
        CompIndex = DuctNum
    else:
        DuctNum = CompIndex
        if DuctNum > state[].dataHVACDuct.NumDucts or DuctNum < 1:
            ShowFatalError(
                state,
                String("SimDuct:  Invalid CompIndex passed=")
                + String(DuctNum)
                + String(", Number of Components=")
                + String(state[].dataHVACDuct.NumDucts)
                + String(", Entered Component name=")
                + String(CompName),
            )
        if state[].dataHVACDuct.CheckEquipName[DuctNum - 1]:
            if CompName != state[].dataHVACDuct.Duct[DuctNum - 1].Name:
                ShowFatalError(
                    state,
                    String("SimDuct: Invalid CompIndex passed=")
                    + String(DuctNum)
                    + String(", Component name=")
                    + String(CompName)
                    + String(", stored Component Name for that index=")
                    + String(state[].dataHVACDuct.Duct[DuctNum - 1].Name),
                )
            state[].dataHVACDuct.CheckEquipName[DuctNum - 1] = False

    CalcDuct(DuctNum)
    UpdateDuct(state, DuctNum)
    ReportDuct(DuctNum)


fn GetDuctInput(state: Arc[EnergyPlusData]) -> None:
    var RoutineName = "GetDuctInput:"
    var ErrorsFound: Bool = False

    var cCurrentModuleObject = "Duct"
    state[].dataHVACDuct.NumDucts = (
        state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, cCurrentModuleObject
        )
    )

    state[].dataHVACDuct.Duct = List[DuctData](
        capacity=state[].dataHVACDuct.NumDucts
    )
    for _ in range(state[].dataHVACDuct.NumDucts):
        state[].dataHVACDuct.Duct.append(DuctData())

    state[].dataHVACDuct.CheckEquipName = List[Bool](
        capacity=state[].dataHVACDuct.NumDucts
    )
    for _ in range(state[].dataHVACDuct.NumDucts):
        state[].dataHVACDuct.CheckEquipName.append(True)

    for DuctNum in range(1, state[].dataHVACDuct.NumDucts + 1):
        state[].dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            DuctNum,
            state[].dataIPShortCut.cAlphaArgs,
            state[].dataIPShortCut.rNumericArgs,
            state[].dataIPShortCut.lNumericFieldBlanks,
            state[].dataIPShortCut.lAlphaFieldBlanks,
            state[].dataIPShortCut.cAlphaFieldNames,
            state[].dataIPShortCut.cNumericFieldNames,
        )

        state[].dataHVACDuct.Duct[DuctNum - 1].Name = state[].dataIPShortCut.cAlphaArgs[
            0
        ]
        state[].dataHVACDuct.Duct[DuctNum - 1].InletNodeNum = GetOnlySingleNode(
            state,
            state[].dataIPShortCut.cAlphaArgs[1],
            ErrorsFound,
            ConnectionObjectType.Duct,
            state[].dataIPShortCut.cAlphaArgs[0],
            FluidType.Air,
            ConnectionType.Inlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        state[].dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum = GetOnlySingleNode(
            state,
            state[].dataIPShortCut.cAlphaArgs[2],
            ErrorsFound,
            ConnectionObjectType.Duct,
            state[].dataIPShortCut.cAlphaArgs[0],
            FluidType.Air,
            ConnectionType.Outlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        TestCompSet(
            state,
            cCurrentModuleObject,
            state[].dataIPShortCut.cAlphaArgs[0],
            state[].dataIPShortCut.cAlphaArgs[1],
            state[].dataIPShortCut.cAlphaArgs[2],
            "Air Nodes",
        )

    if ErrorsFound:
        ShowFatalError(state, RoutineName + " Errors found in input")


fn CalcDuct(DuctNum: Int) -> None:
    pass


fn UpdateDuct(state: Arc[EnergyPlusData], DuctNum: Int) -> None:
    var InNode: Int = state[].dataHVACDuct.Duct[DuctNum - 1].InletNodeNum
    var OutNode: Int = state[].dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum

    state[].dataLoopNodes.Node[OutNode].MassFlowRate = state[].dataLoopNodes.Node[
        InNode
    ].MassFlowRate
    state[].dataLoopNodes.Node[OutNode].Temp = state[].dataLoopNodes.Node[InNode].Temp
    state[].dataLoopNodes.Node[OutNode].HumRat = state[].dataLoopNodes.Node[
        InNode
    ].HumRat
    state[].dataLoopNodes.Node[OutNode].Enthalpy = state[].dataLoopNodes.Node[
        InNode
    ].Enthalpy
    state[].dataLoopNodes.Node[OutNode].Quality = state[].dataLoopNodes.Node[
        InNode
    ].Quality
    state[].dataLoopNodes.Node[OutNode].Press = state[].dataLoopNodes.Node[InNode].Press
    state[].dataLoopNodes.Node[OutNode].MassFlowRateMin = state[].dataLoopNodes.Node[
        InNode
    ].MassFlowRateMin
    state[].dataLoopNodes.Node[OutNode].MassFlowRateMax = state[].dataLoopNodes.Node[
        InNode
    ].MassFlowRateMax
    state[].dataLoopNodes.Node[OutNode].MassFlowRateMinAvail = (
        state[].dataLoopNodes.Node[InNode].MassFlowRateMinAvail
    )
    state[].dataLoopNodes.Node[OutNode].MassFlowRateMaxAvail = (
        state[].dataLoopNodes.Node[InNode].MassFlowRateMaxAvail
    )

    if state[].dataContaminantBalance.Contaminant.CO2Simulation:
        state[].dataLoopNodes.Node[OutNode].CO2 = state[].dataLoopNodes.Node[InNode].CO2

    if state[].dataContaminantBalance.Contaminant.GenericContamSimulation:
        state[].dataLoopNodes.Node[OutNode].GenContam = state[].dataLoopNodes.Node[
            InNode
        ].GenContam


fn ReportDuct(DuctNum: Int) -> None:
    pass
