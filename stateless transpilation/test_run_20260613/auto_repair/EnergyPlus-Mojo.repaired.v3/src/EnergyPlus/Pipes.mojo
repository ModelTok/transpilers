from ...BranchNodeConnections import TestCompSet
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataHVACGlobals import *
from ...DataIPShortCuts import *
from ...DataLoopNode import *
from ...General import *
from ...GlobalNames import VerifyUniqueInterObjectName
from ...InputProcessing.InputProcessor import *
from ...NodeInputManager import GetOnlySingleNode
from ...PlantComponent import PlantComponent
from ...Plant.DataPlant import DataPlant, PlantEquipmentType
from ...Plant.PlantLocation import PlantLocation
from ...PlantUtilities import *
from ...UtilityRoutines import ShowFatalError

# Mojo does not have include mechanism; the following are implicit from the struct definitions
# We rely on EnergyPlusData, PlantLocation, etc. being imported via the above

struct PipesData(BaseGlobalStruct):
    var GetPipeInputFlag: Bool = True
    var LocalPipe: EPVector[LocalPipeData]  # EPVector should be a wrapper
    var LocalPipeUniqueNames: Dict[String, String]
    
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.GetPipeInputFlag = True
        self.LocalPipe.deallocate()
        self.LocalPipeUniqueNames.clear()

struct LocalPipeData(PlantComponent):
    var Name: String
    var Type: DataPlant.PlantEquipmentType
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var plantLoc: PlantLocation
    var CheckEquipName: Bool
    var EnvrnFlag: Bool
    
    def __init__(inout self):
        self.Type = DataPlant.PlantEquipmentType.Invalid
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.plantLoc = PlantLocation()
        self.CheckEquipName = True
        self.EnviroFlag = True  # Note: original name is EnvrnFlag, not EnviroFlag
    
    @staticmethod
    def factory(state: inout EnergyPlusData, objectType: DataPlant.PlantEquipmentType, objectName: borrowed String) -> borrowed LocalPipeData:
        if state.dataPipes.GetPipeInputFlag:
            GetPipeInput(state)
            state.dataPipes.GetPipeInputFlag = False
        for pipe in state.dataPipes.LocalPipe:
            if pipe.Type == objectType and pipe.Name == objectName:
                return pipe
        ShowFatalError(state, format("LocalPipeDataFactory: Error getting inputs for pipe named: {}", objectName))  # LCOV_EXCL_LINE
        return None  # LCOV_EXCL_LINE
    
    def simulate(
        inout self,
        state: inout EnergyPlusData,
        calledFromLocation: borrowed PlantLocation,
        FirstHVACIteration: Bool,
        CurLoad: inout Float64,
        RunFlag: Bool
    ):
        if state.dataGlobal.BeginEnvrnFlag and self.EnvrnFlag:
            self.initEachEnvironment(state)
            self.EnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.EnvrnFlag = True
        PlantUtilities.SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum, self.plantLoc.loopNum)
    
    def oneTimeInit_new(inout self, state: inout EnergyPlusData):
        var FoundOnLoop: Int = 0
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.Type, self.plantLoc, errFlag, _, _, FoundOnLoop, _, _)
        if FoundOnLoop == 0:
            ShowFatalError(state, format("SimPipes: Pipe=\"{}\" not found on a Plant Loop.", self.Name))  # LCOV_EXCL_LINE
        if errFlag:
            ShowFatalError(state, "SimPipes: Program terminated due to previous condition(s).")  # LCOV_EXCL_LINE
    
    def initEachEnvironment(self, state: inout EnergyPlusData):
        PlantUtilities.InitComponentNodes(state, 0.0, self.plantLoc.loop.MaxMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
    
    def oneTimeInit(self, state: EnergyPlusData):

def GetPipeInput(state: inout EnergyPlusData):
    var PipeNum: Int = 0
    var NumAlphas: Int = 0
    var NumNums: Int = 0
    var IOStat: Int = 0
    var ErrorsFound: Bool = False
    var NumWaterPipes: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Pipe:Adiabatic")
    var NumSteamPipes: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Pipe:Adiabatic:Steam")
    var NumLocalPipes: Int = NumWaterPipes + NumSteamPipes
    state.dataPipes.LocalPipe.allocate(NumLocalPipes)
    state.dataPipes.LocalPipeUniqueNames.reserve(NumLocalPipes.to_uint())
    var cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "Pipe:Adiabatic"
    for PipeWaterNum in range(1, NumWaterPipes + 1):
        PipeNum += 1
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            PipeWaterNum,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNums,
            IOStat
        )
        GlobalNames.VerifyUniqueInterObjectName(
            state, state.dataPipes.LocalPipeUniqueNames, state.dataIPShortCut.cAlphaArgs(1), cCurrentModuleObject, ErrorsFound
        )
        state.dataPipes.LocalPipe(PipeNum).Name = state.dataIPShortCut.cAlphaArgs(1)
        state.dataPipes.LocalPipe(PipeNum).Type = DataPlant.PlantEquipmentType.Pipe
        state.dataPipes.LocalPipe(PipeNum).InletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs(2),
            ErrorsFound,
            Node.ConnectionObjectType.PipeAdiabatic,
            state.dataIPShortCut.cAlphaArgs(1),
            Node.FluidType.Water,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        state.dataPipes.LocalPipe(PipeNum).OutletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs(3),
            ErrorsFound,
            Node.ConnectionObjectType.PipeAdiabatic,
            state.dataIPShortCut.cAlphaArgs(1),
            Node.FluidType.Water,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        TestCompSet(
            state,
            cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs(1),
            state.dataIPShortCut.cAlphaArgs(2),
            state.dataIPShortCut.cAlphaArgs(3),
            "Pipe Nodes"
        )
    PipeNum = NumWaterPipes
    cCurrentModuleObject = "Pipe:Adiabatic:Steam"
    for PipeSteamNum in range(1, NumSteamPipes + 1):
        PipeNum += 1
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            PipeSteamNum,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNums,
            IOStat
        )
        GlobalNames.VerifyUniqueInterObjectName(
            state, state.dataPipes.LocalPipeUniqueNames, state.dataIPShortCut.cAlphaArgs(1), cCurrentModuleObject, ErrorsFound
        )
        state.dataPipes.LocalPipe(PipeNum).Name = state.dataIPShortCut.cAlphaArgs(1)
        state.dataPipes.LocalPipe(PipeNum).Type = DataPlant.PlantEquipmentType.PipeSteam
        state.dataPipes.LocalPipe(PipeNum).InletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs(2),
            ErrorsFound,
            Node.ConnectionObjectType.PipeAdiabaticSteam,
            state.dataIPShortCut.cAlphaArgs(1),
            Node.FluidType.Steam,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        state.dataPipes.LocalPipe(PipeNum).OutletNodeNum = GetOnlySingleNode(
            state,
            state.dataIPShortCut.cAlphaArgs(3),
            ErrorsFound,
            Node.ConnectionObjectType.PipeAdiabaticSteam,
            state.dataIPShortCut.cAlphaArgs(1),
            Node.FluidType.Steam,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        TestCompSet(
            state,
            cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs(1),
            state.dataIPShortCut.cAlphaArgs(2),
            state.dataIPShortCut.cAlphaArgs(3),
            "Pipe Nodes"
        )
    if ErrorsFound:
        ShowFatalError(state, "GetPipeInput: Errors getting input for pipes")  # LCOV_EXCL_LINE