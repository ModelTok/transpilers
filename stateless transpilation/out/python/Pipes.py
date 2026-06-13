# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state struct from EnergyPlus/Data/EnergyPlusData.hh
# - PlantComponent: base class from EnergyPlus/PlantComponent.hh
# - PlantLocation: struct from EnergyPlus/Plant/PlantLocation.hh
# - DataPlant.PlantEquipmentType: enum from EnergyPlus/Plant/DataPlant.hh
# - PlantUtilities.SafeCopyPlantNode: from EnergyPlus/PlantUtilities.hh
# - PlantUtilities.ScanPlantLoopsForObject: from EnergyPlus/PlantUtilities.hh
# - PlantUtilities.InitComponentNodes: from EnergyPlus/PlantUtilities.hh
# - GlobalNames.VerifyUniqueInterObjectName: from EnergyPlus/GlobalNames.hh
# - Node.GetOnlySingleNode: from EnergyPlus/NodeInputManager.hh
# - Node.TestCompSet: from EnergyPlus/BranchNodeConnections.hh
# - ShowFatalError: from EnergyPlus/UtilityRoutines.hh

from typing import Protocol, Any, Dict, List, Optional
from dataclasses import dataclass, field
from enum import IntEnum


class PlantEquipmentType(IntEnum):
    Invalid = 0
    Pipe = 1
    PipeSteam = 2


@dataclass
class PlantLocation:
    loopNum: int = 0
    compNum: int = 0
    loop: Optional[Any] = None


class PlantComponent:
    pass


class BaseGlobalStruct:
    pass


class PlantUtilitiesProto(Protocol):
    @staticmethod
    def SafeCopyPlantNode(state: Any, inlet_node: int, outlet_node: int, loop_num: int) -> None:
        ...

    @staticmethod
    def ScanPlantLoopsForObject(
        state: Any,
        name: str,
        obj_type: PlantEquipmentType,
        plant_loc: PlantLocation,
        err_flag: bool,
        *args: Any,
        **kwargs: Any,
    ) -> None:
        ...

    @staticmethod
    def InitComponentNodes(
        state: Any,
        min_mass_flow: float,
        max_mass_flow: float,
        inlet_node: int,
        outlet_node: int,
    ) -> None:
        ...


class GlobalNamesProto(Protocol):
    @staticmethod
    def VerifyUniqueInterObjectName(
        state: Any,
        unique_names: Dict[str, str],
        name: str,
        obj_type: str,
        error_flag: bool,
    ) -> None:
        ...


class NodeProto(Protocol):
    @staticmethod
    def GetOnlySingleNode(
        state: Any,
        name: str,
        error_flag: bool,
        conn_obj_type: str,
        obj_name: str,
        fluid_type: str,
        conn_type: str,
        comp_fluid_stream: str,
        obj_is_parent: str,
    ) -> int:
        ...

    @staticmethod
    def TestCompSet(
        state: Any,
        obj_type: str,
        name: str,
        inlet: str,
        outlet: str,
        node_description: str,
    ) -> None:
        ...


def ShowFatalError(state: Any, message: str) -> None:
    raise RuntimeError(message)


class LocalPipeData(PlantComponent):
    def __init__(self) -> None:
        self.Name: str = ""
        self.Type: PlantEquipmentType = PlantEquipmentType.Invalid
        self.InletNodeNum: int = 0
        self.OutletNodeNum: int = 0
        self.plantLoc: PlantLocation = PlantLocation()
        self.CheckEquipName: bool = True
        self.EnvrnFlag: bool = True

    @staticmethod
    def factory(
        state: Any, object_type: PlantEquipmentType, object_name: str
    ) -> "LocalPipeData":
        if state.dataPipes.GetPipeInputFlag:
            GetPipeInput(state)
            state.dataPipes.GetPipeInputFlag = False

        for pipe in state.dataPipes.LocalPipe:
            if pipe.Type == object_type and pipe.Name == object_name:
                return pipe

        ShowFatalError(
            state,
            f"LocalPipeDataFactory: Error getting inputs for pipe named: {object_name}",
        )
        return None

    def simulate(
        self,
        state: Any,
        called_from_location: PlantLocation,
        first_hvac_iteration: bool,
        cur_load: float,
        run_flag: bool,
    ) -> None:
        if state.dataGlobal.BeginEnvrnFlag and self.EnvrnFlag:
            self.initEachEnvironment(state)
            self.EnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.EnvrnFlag = True

        state.PlantUtilities.SafeCopyPlantNode(
            state, self.InletNodeNum, self.OutletNodeNum, self.plantLoc.loopNum
        )

    def oneTimeInit_new(self, state: Any) -> None:
        found_on_loop = 0
        err_flag = False
        state.PlantUtilities.ScanPlantLoopsForObject(
            state,
            self.Name,
            self.Type,
            self.plantLoc,
            err_flag,
            None,
            None,
            found_on_loop,
            None,
            None,
        )

        if found_on_loop == 0:
            ShowFatalError(
                state,
                f'SimPipes: Pipe="{self.Name}" not found on a Plant Loop.',
            )

        if err_flag:
            ShowFatalError(
                state, "SimPipes: Program terminated due to previous condition(s)."
            )

    def initEachEnvironment(self, state: Any) -> None:
        state.PlantUtilities.InitComponentNodes(
            state,
            0.0,
            self.plantLoc.loop.MaxMassFlowRate,
            self.InletNodeNum,
            self.OutletNodeNum,
        )

    def oneTimeInit(self, state: Any) -> None:
        pass


@dataclass
class PipesData(BaseGlobalStruct):
    GetPipeInputFlag: bool = True
    LocalPipe: List[LocalPipeData] = field(default_factory=list)
    LocalPipeUniqueNames: Dict[str, str] = field(default_factory=dict)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.GetPipeInputFlag = True
        self.LocalPipe.clear()
        self.LocalPipeUniqueNames.clear()


def GetPipeInput(state: Any) -> None:
    num_water_pipes = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, "Pipe:Adiabatic"
        )
    )
    num_steam_pipes = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, "Pipe:Adiabatic:Steam"
        )
    )
    num_local_pipes = num_water_pipes + num_steam_pipes

    state.dataPipes.LocalPipe = [LocalPipeData() for _ in range(num_local_pipes)]
    state.dataPipes.LocalPipeUniqueNames.clear()

    pipe_num = 0
    num_alphas = 0
    num_nums = 0
    io_stat = 0
    errors_found = False

    current_module_object = "Pipe:Adiabatic"

    for pipe_water_num in range(1, num_water_pipes + 1):
        pipe_num += 1

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            pipe_water_num,
            state.dataIPShortCut.cAlphaArgs,
            num_alphas,
            state.dataIPShortCut.rNumericArgs,
            num_nums,
            io_stat,
        )

        state.GlobalNames.VerifyUniqueInterObjectName(
            state,
            state.dataPipes.LocalPipeUniqueNames,
            state.dataIPShortCut.cAlphaArgs[0],
            current_module_object,
            errors_found,
        )

        state.dataPipes.LocalPipe[pipe_num - 1].Name = (
            state.dataIPShortCut.cAlphaArgs[0]
        )
        state.dataPipes.LocalPipe[pipe_num - 1].Type = PlantEquipmentType.Pipe

        state.dataPipes.LocalPipe[pipe_num - 1].InletNodeNum = (
            state.Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[1],
                errors_found,
                "Pipe:Adiabatic",
                state.dataIPShortCut.cAlphaArgs[0],
                "Water",
                "Inlet",
                "Primary",
                "ObjectIsNotParent",
            )
        )

        state.dataPipes.LocalPipe[pipe_num - 1].OutletNodeNum = (
            state.Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[2],
                errors_found,
                "Pipe:Adiabatic",
                state.dataIPShortCut.cAlphaArgs[0],
                "Water",
                "Outlet",
                "Primary",
                "ObjectIsNotParent",
            )
        )

        state.Node.TestCompSet(
            state,
            current_module_object,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            "Pipe Nodes",
        )

    pipe_num = num_water_pipes
    current_module_object = "Pipe:Adiabatic:Steam"

    for pipe_steam_num in range(1, num_steam_pipes + 1):
        pipe_num += 1

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            pipe_steam_num,
            state.dataIPShortCut.cAlphaArgs,
            num_alphas,
            state.dataIPShortCut.rNumericArgs,
            num_nums,
            io_stat,
        )

        state.GlobalNames.VerifyUniqueInterObjectName(
            state,
            state.dataPipes.LocalPipeUniqueNames,
            state.dataIPShortCut.cAlphaArgs[0],
            current_module_object,
            errors_found,
        )

        state.dataPipes.LocalPipe[pipe_num - 1].Name = (
            state.dataIPShortCut.cAlphaArgs[0]
        )
        state.dataPipes.LocalPipe[pipe_num - 1].Type = PlantEquipmentType.PipeSteam

        state.dataPipes.LocalPipe[pipe_num - 1].InletNodeNum = (
            state.Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[1],
                errors_found,
                "Pipe:Adiabatic:Steam",
                state.dataIPShortCut.cAlphaArgs[0],
                "Steam",
                "Inlet",
                "Primary",
                "ObjectIsNotParent",
            )
        )

        state.dataPipes.LocalPipe[pipe_num - 1].OutletNodeNum = (
            state.Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[2],
                errors_found,
                "Pipe:Adiabatic:Steam",
                state.dataIPShortCut.cAlphaArgs[0],
                "Steam",
                "Outlet",
                "Primary",
                "ObjectIsNotParent",
            )
        )

        state.Node.TestCompSet(
            state,
            current_module_object,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            "Pipe Nodes",
        )

    if errors_found:
        ShowFatalError(state, "GetPipeInput: Errors getting input for pipes")
