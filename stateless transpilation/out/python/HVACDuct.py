from dataclasses import dataclass, field
from typing import Any, Protocol


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state.dataHVACDuct (HVACDuctData), state.dataIPShortCut (DataIPShortCuts),
#   state.dataInputProcessing.inputProcessor (InputProcessor), state.dataLoopNodes.Node,
#   state.dataContaminantBalance.Contaminant
# - Util.FindItemInList(name, array) -> int
# - ShowFatalError(state, message) -> None
# - Node.GetOnlySingleNode(...) -> int
# - Node.TestCompSet(state, module_name, component_name, inlet_name, outlet_name, node_type) -> None
# - Node.ConnectionObjectType.Duct (enum value)
# - Node.FluidType.Air (enum value)
# - Node.ConnectionType.Inlet, Node.ConnectionType.Outlet (enum values)
# - Node.CompFluidStream.Primary (enum value)
# - Node.ObjectIsNotParent (enum value)


@dataclass
class DuctData:
    Name: str = ""
    InletNodeNum: int = 0
    OutletNodeNum: int = 0


@dataclass
class HVACDuctData:
    NumDucts: int = 0
    CheckEquipName: list[bool] = field(default_factory=list)
    Duct: list[DuctData] = field(default_factory=list)
    GetInputFlag: bool = True

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.NumDucts = 0
        self.CheckEquipName.clear()
        self.Duct.clear()
        self.GetInputFlag = True


def SimDuct(
    state: Any, CompName: str, FirstHVACIteration: bool, CompIndex: list[int]
) -> None:
    from Util import FindItemInList
    from UtilityRoutines import ShowFatalError

    if state.dataHVACDuct.GetInputFlag:
        GetDuctInput(state)
        state.dataHVACDuct.GetInputFlag = False

    if CompIndex[0] == 0:
        DuctNum = FindItemInList(CompName, state.dataHVACDuct.Duct)
        if DuctNum == 0:
            ShowFatalError(state, f"SimDuct: Component not found={CompName}")
        CompIndex[0] = DuctNum
    else:
        DuctNum = CompIndex[0]
        if DuctNum > state.dataHVACDuct.NumDucts or DuctNum < 1:
            ShowFatalError(
                state,
                f"SimDuct:  Invalid CompIndex passed={DuctNum}, "
                f"Number of Components={state.dataHVACDuct.NumDucts}, "
                f"Entered Component name={CompName}",
            )
        if state.dataHVACDuct.CheckEquipName[DuctNum - 1]:
            if CompName != state.dataHVACDuct.Duct[DuctNum - 1].Name:
                ShowFatalError(
                    state,
                    f"SimDuct: Invalid CompIndex passed={DuctNum}, "
                    f"Component name={CompName}, "
                    f"stored Component Name for that index={state.dataHVACDuct.Duct[DuctNum - 1].Name}",
                )
            state.dataHVACDuct.CheckEquipName[DuctNum - 1] = False

    CalcDuct(DuctNum)
    UpdateDuct(state, DuctNum)
    ReportDuct(DuctNum)


def GetDuctInput(state: Any) -> None:
    from Node import GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
    from UtilityRoutines import ShowFatalError

    RoutineName = "GetDuctInput:"
    ErrorsFound = False

    cCurrentModuleObject = "Duct"
    state.dataHVACDuct.NumDucts = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCurrentModuleObject
    )

    state.dataHVACDuct.Duct = [DuctData() for _ in range(state.dataHVACDuct.NumDucts)]
    state.dataHVACDuct.CheckEquipName = [True] * state.dataHVACDuct.NumDucts

    for DuctNum in range(1, state.dataHVACDuct.NumDucts + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            DuctNum,
            state.dataIPShortCut.cAlphaArgs,
            state.dataIPShortCut.rNumericArgs,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames,
        )

        state.dataHVACDuct.Duct[DuctNum - 1].Name = state.dataIPShortCut.cAlphaArgs[0]
        state.dataHVACDuct.Duct[DuctNum - 1].InletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs[1],
            ErrorsFound,
            ConnectionObjectType.Duct,
            state.dataIPShortCut.cAlphaArgs[0],
            FluidType.Air,
            ConnectionType.Inlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        state.dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs[2],
            ErrorsFound,
            ConnectionObjectType.Duct,
            state.dataIPShortCut.cAlphaArgs[0],
            FluidType.Air,
            ConnectionType.Outlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        TestCompSet(
            state,
            cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            "Air Nodes",
        )

    if ErrorsFound:
        ShowFatalError(state, f"{RoutineName} Errors found in input")


def CalcDuct(DuctNum: int) -> None:
    pass


def UpdateDuct(state: Any, DuctNum: int) -> None:
    InNode = state.dataHVACDuct.Duct[DuctNum - 1].InletNodeNum
    OutNode = state.dataHVACDuct.Duct[DuctNum - 1].OutletNodeNum

    state.dataLoopNodes.Node[OutNode].MassFlowRate = state.dataLoopNodes.Node[
        InNode
    ].MassFlowRate
    state.dataLoopNodes.Node[OutNode].Temp = state.dataLoopNodes.Node[InNode].Temp
    state.dataLoopNodes.Node[OutNode].HumRat = state.dataLoopNodes.Node[InNode].HumRat
    state.dataLoopNodes.Node[OutNode].Enthalpy = state.dataLoopNodes.Node[
        InNode
    ].Enthalpy
    state.dataLoopNodes.Node[OutNode].Quality = state.dataLoopNodes.Node[InNode].Quality
    state.dataLoopNodes.Node[OutNode].Press = state.dataLoopNodes.Node[InNode].Press
    state.dataLoopNodes.Node[OutNode].MassFlowRateMin = state.dataLoopNodes.Node[
        InNode
    ].MassFlowRateMin
    state.dataLoopNodes.Node[OutNode].MassFlowRateMax = state.dataLoopNodes.Node[
        InNode
    ].MassFlowRateMax
    state.dataLoopNodes.Node[OutNode].MassFlowRateMinAvail = state.dataLoopNodes.Node[
        InNode
    ].MassFlowRateMinAvail
    state.dataLoopNodes.Node[OutNode].MassFlowRateMaxAvail = state.dataLoopNodes.Node[
        InNode
    ].MassFlowRateMaxAvail

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[OutNode].CO2 = state.dataLoopNodes.Node[InNode].CO2

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[OutNode].GenContam = state.dataLoopNodes.Node[
            InNode
        ].GenContam


def ReportDuct(DuctNum: int) -> None:
    pass
