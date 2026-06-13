# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state struct from EnergyPlus/Data/EnergyPlusData.hh
# - PlantComponent: base trait from EnergyPlus/PlantComponent.hh
# - PlantLocation: struct from EnergyPlus/Plant/PlantLocation.hh
# - DataPlant.PlantEquipmentType: enum from EnergyPlus/Plant/DataPlant.hh
# - PlantUtilities.SafeCopyPlantNode: from EnergyPlus/PlantUtilities.hh
# - PlantUtilities.ScanPlantLoopsForObject: from EnergyPlus/PlantUtilities.hh
# - PlantUtilities.InitComponentNodes: from EnergyPlus/PlantUtilities.hh
# - GlobalNames.VerifyUniqueInterObjectName: from EnergyPlus/GlobalNames.hh
# - Node.GetOnlySingleNode: from EnergyPlus/NodeInputManager.hh
# - Node.TestCompSet: from EnergyPlus/BranchNodeConnections.hh
# - ShowFatalError: from EnergyPlus/UtilityRoutines.hh

from collections import InlineArray


enum PlantEquipmentType:
    Invalid = 0
    Pipe = 1
    PipeSteam = 2


struct PlantLocation:
    var loopNum: Int = 0
    var compNum: Int = 0
    var loop: Pointer[UnsafePointer[UInt8]] = Pointer[UnsafePointer[UInt8]]()


trait PlantComponent:
    fn simulate(
        self: Self,
        inout state: EnergyPlusData,
        called_from_location: PlantLocation,
        first_hvac_iteration: Bool,
        inout cur_load: Float64,
        run_flag: Bool,
    ):
        ...

    fn oneTimeInit_new(self: Self, inout state: EnergyPlusData):
        ...

    fn oneTimeInit(self: Self, inout state: EnergyPlusData):
        ...


struct LocalPipeData(PlantComponent):
    var Name: String
    var Type: PlantEquipmentType
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var plantLoc: PlantLocation
    var CheckEquipName: Bool
    var EnvrnFlag: Bool

    fn __init__(inout self):
        self.Name = String()
        self.Type = PlantEquipmentType.Invalid
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.plantLoc = PlantLocation()
        self.CheckEquipName = True
        self.EnvrnFlag = True

    @staticmethod
    fn factory(
        inout state: EnergyPlusData,
        object_type: PlantEquipmentType,
        object_name: String,
    ) -> Pointer[LocalPipeData]:
        if state.dataPipes.GetPipeInputFlag:
            GetPipeInput(state)
            state.dataPipes.GetPipeInputFlag = False

        for i in range(len(state.dataPipes.LocalPipe)):
            pipe = Pointer.address_of(state.dataPipes.LocalPipe[i])
            if pipe.pointee.Type == object_type and pipe.pointee.Name == object_name:
                return pipe

        _ = ShowFatalError(
            state,
            String("LocalPipeDataFactory: Error getting inputs for pipe named: ")
            + object_name,
        )
        return Pointer[LocalPipeData]()

    fn simulate(
        self: Self,
        inout state: EnergyPlusData,
        called_from_location: PlantLocation,
        first_hvac_iteration: Bool,
        inout cur_load: Float64,
        run_flag: Bool,
    ):
        if state.dataGlobal.BeginEnvrnFlag and self.EnvrnFlag:
            self.initEachEnvironment(state)
            var mutable_self = self
            mutable_self.EnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            var mutable_self = self
            mutable_self.EnvrnFlag = True

        _ = PlantUtilities.SafeCopyPlantNode(
            state, self.InletNodeNum, self.OutletNodeNum, self.plantLoc.loopNum
        )

    fn oneTimeInit_new(self: Self, inout state: EnergyPlusData):
        var found_on_loop: Int = 0
        var err_flag: Bool = False

        _ = PlantUtilities.ScanPlantLoopsForObject(
            state,
            self.Name,
            self.Type,
            self.plantLoc,
            err_flag,
            Pointer[UInt8](),
            Pointer[UInt8](),
            found_on_loop,
            Pointer[UInt8](),
            Pointer[UInt8](),
        )

        if found_on_loop == 0:
            _ = ShowFatalError(
                state,
                String('SimPipes: Pipe="') + self.Name + String('" not found on a Plant Loop.'),
            )

        if err_flag:
            _ = ShowFatalError(
                state,
                String("SimPipes: Program terminated due to previous condition(s)."),
            )

    fn initEachEnvironment(self: Self, inout state: EnergyPlusData):
        _ = PlantUtilities.InitComponentNodes(
            state,
            0.0,
            self.plantLoc.loop.pointee.MaxMassFlowRate,
            self.InletNodeNum,
            self.OutletNodeNum,
        )

    fn oneTimeInit(self: Self, inout state: EnergyPlusData):
        pass


struct PipesData:
    var GetPipeInputFlag: Bool
    var LocalPipe: DynamicVector[LocalPipeData]
    var LocalPipeUniqueNames: InlineDict[String, String, 1024]

    fn __init__(inout self):
        self.GetPipeInputFlag = True
        self.LocalPipe = DynamicVector[LocalPipeData]()
        self.LocalPipeUniqueNames = InlineDict[String, String, 1024]()

    fn init_constant_state(inout self, inout state: EnergyPlusData):
        pass

    fn init_state(inout self, inout state: EnergyPlusData):
        pass

    fn clear_state(inout self):
        self.GetPipeInputFlag = True
        self.LocalPipe.clear()
        self.LocalPipeUniqueNames.clear()


fn GetPipeInput(inout state: EnergyPlusData):
    var num_water_pipes: Int = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, String("Pipe:Adiabatic")
        )
    )
    var num_steam_pipes: Int = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, String("Pipe:Adiabatic:Steam")
        )
    )
    var num_local_pipes: Int = num_water_pipes + num_steam_pipes

    state.dataPipes.LocalPipe.reserve(num_local_pipes)
    for _ in range(num_local_pipes):
        state.dataPipes.LocalPipe.push_back(LocalPipeData())

    var pipe_num: Int = 0
    var num_alphas: Int = 0
    var num_nums: Int = 0
    var io_stat: Int = 0
    var errors_found: Bool = False

    var current_module_object: String = String("Pipe:Adiabatic")

    for pipe_water_num in range(1, num_water_pipes + 1):
        pipe_num += 1

        _ = state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            pipe_water_num,
            state.dataIPShortCut.cAlphaArgs,
            num_alphas,
            state.dataIPShortCut.rNumericArgs,
            num_nums,
            io_stat,
        )

        _ = GlobalNames.VerifyUniqueInterObjectName(
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
            Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[1],
                errors_found,
                String("Pipe:Adiabatic"),
                state.dataIPShortCut.cAlphaArgs[0],
                String("Water"),
                String("Inlet"),
                String("Primary"),
                String("ObjectIsNotParent"),
            )
        )

        state.dataPipes.LocalPipe[pipe_num - 1].OutletNodeNum = (
            Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[2],
                errors_found,
                String("Pipe:Adiabatic"),
                state.dataIPShortCut.cAlphaArgs[0],
                String("Water"),
                String("Outlet"),
                String("Primary"),
                String("ObjectIsNotParent"),
            )
        )

        _ = Node.TestCompSet(
            state,
            current_module_object,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            String("Pipe Nodes"),
        )

    pipe_num = num_water_pipes
    current_module_object = String("Pipe:Adiabatic:Steam")

    for pipe_steam_num in range(1, num_steam_pipes + 1):
        pipe_num += 1

        _ = state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            pipe_steam_num,
            state.dataIPShortCut.cAlphaArgs,
            num_alphas,
            state.dataIPShortCut.rNumericArgs,
            num_nums,
            io_stat,
        )

        _ = GlobalNames.VerifyUniqueInterObjectName(
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
            Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[1],
                errors_found,
                String("Pipe:Adiabatic:Steam"),
                state.dataIPShortCut.cAlphaArgs[0],
                String("Steam"),
                String("Inlet"),
                String("Primary"),
                String("ObjectIsNotParent"),
            )
        )

        state.dataPipes.LocalPipe[pipe_num - 1].OutletNodeNum = (
            Node.GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[2],
                errors_found,
                String("Pipe:Adiabatic:Steam"),
                state.dataIPShortCut.cAlphaArgs[0],
                String("Steam"),
                String("Outlet"),
                String("Primary"),
                String("ObjectIsNotParent"),
            )
        )

        _ = Node.TestCompSet(
            state,
            current_module_object,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            String("Pipe Nodes"),
        )

    if errors_found:
        _ = ShowFatalError(
            state, String("GetPipeInput: Errors getting input for pipes")
        )


fn ShowFatalError(inout state: EnergyPlusData, message: String) -> None:
    raise Error(message)


struct PlantUtilities:
    @staticmethod
    fn SafeCopyPlantNode(
        inout state: EnergyPlusData,
        inlet_node: Int,
        outlet_node: Int,
        loop_num: Int,
    ) -> None:
        pass

    @staticmethod
    fn ScanPlantLoopsForObject(
        inout state: EnergyPlusData,
        name: String,
        obj_type: PlantEquipmentType,
        inout plant_loc: PlantLocation,
        inout err_flag: Bool,
        arg1: Pointer[UInt8],
        arg2: Pointer[UInt8],
        inout found_on_loop: Int,
        arg3: Pointer[UInt8],
        arg4: Pointer[UInt8],
    ) -> None:
        pass

    @staticmethod
    fn InitComponentNodes(
        inout state: EnergyPlusData,
        min_mass_flow: Float64,
        max_mass_flow: Float64,
        inlet_node: Int,
        outlet_node: Int,
    ) -> None:
        pass


struct GlobalNames:
    @staticmethod
    fn VerifyUniqueInterObjectName(
        inout state: EnergyPlusData,
        inout unique_names: InlineDict[String, String, 1024],
        name: String,
        obj_type: String,
        inout error_flag: Bool,
    ) -> None:
        pass


struct Node:
    @staticmethod
    fn GetOnlySingleNode(
        inout state: EnergyPlusData,
        name: String,
        inout error_flag: Bool,
        conn_obj_type: String,
        obj_name: String,
        fluid_type: String,
        conn_type: String,
        comp_fluid_stream: String,
        obj_is_parent: String,
    ) -> Int:
        return 0

    @staticmethod
    fn TestCompSet(
        inout state: EnergyPlusData,
        obj_type: String,
        name: String,
        inlet: String,
        outlet: String,
        node_description: String,
    ) -> None:
        pass
