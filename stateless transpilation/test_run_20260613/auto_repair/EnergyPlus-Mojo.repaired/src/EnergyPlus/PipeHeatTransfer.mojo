module EnergyPlus:

from DataGlobals import *
from DataSurfaces import *
from EnergyPlus import *
from GroundTemperatureModeling.BaseGroundTemperatureModel import *
from Plant.Enums import *
from Plant.PlantLocation import *
from PlantComponent import *
from BranchNodeConnections import *
from Construction import *
from ConvectionCoefficients import *
from Data.EnergyPlusData import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataLoopNode import *
from FluidProperties import *
from General import *
from GlobalNames import *
from GroundTemperatureModeling.GroundTemperatureModelManager import *
from HeatBalanceInternalHeatGains import *
from InputProcessing.InputProcessor import *
from Material import *
from NodeInputManager import *
from OutAirNodeManager import *
from OutputProcessor import *
from Plant.DataPlant import *
from PlantUtilities import *
from ScheduleManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from Constant import *
from ObjexxFCL.Array.functions import *
from ObjexxFCL.Array3D import *
from ObjexxFCL.Fmath import *

struct BaseGlobalStruct:
    def init_constant_state(state: EnergyPlusData):

    def init_state(state: EnergyPlusData):

    def clear_state():

struct PlantComponent:
    def simulate(state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):

    def oneTimeInit_new(state: EnergyPlusData):

    def oneTimeInit(state: EnergyPlusData):

struct PipeHeatTransfer:
    enum EnvrnPtr:
        Invalid = -1
        None = 0
        ZoneEnv = 1
        ScheduleEnv = 2
        OutsideAirEnv = 3
        GroundEnv = 4
        Num = 5

    enum TimeIndex:
        Invalid = -1
        Previous = 1
        Current = 2
        Tentative = 3

    const InnerDeltaTime: Float64 = 60.0

    struct PipeHTData(PlantComponent):
        var Name: String
        var Construction: String
        var Environment: String
        var envrSched: Sched.Schedule = None
        var envrVelSched: Sched.Schedule = None
        var EnvrAirNode: String
        var Length: Float64 = 0.0
        var PipeID: Float64 = 0.0
        var InletNode: String
        var OutletNode: String
        var InletNodeNum: Int32 = 0
        var OutletNodeNum: Int32 = 0
        var Type: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
        var ConstructionNum: Int32 = 0
        var EnvironmentPtr: EnvrnPtr = EnvrnPtr.None
        var EnvrZonePtr: Int32 = 0
        var EnvrAirNodeNum: Int32 = 0
        var NumSections: Int32 = 0
        var FluidSpecHeat: Float64 = 0.0
        var FluidDensity: Float64 = 0.0
        var MaxFlowRate: Float64 = 0.0
        var InsideArea: Float64 = 0.0
        var OutsideArea: Float64 = 0.0
        var SectionArea: Float64 = 0.0
        var PipeHeatCapacity: Float64 = 0.0
        var PipeOD: Float64 = 0.0
        var PipeCp: Float64 = 0.0
        var PipeDensity: Float64 = 0.0
        var PipeConductivity: Float64 = 0.0
        var InsulationOD: Float64 = 0.0
        var InsulationCp: Float64 = 0.0
        var InsulationDensity: Float64 = 0.0
        var InsulationConductivity: Float64 = 0.0
        var InsulationThickness: Float64 = 0.0
        var InsulationResistance: Float64 = 0.0
        var CurrentSimTime: Float64 = 0.0
        var PreviousSimTime: Float64 = 0.0
        var TentativeFluidTemp: Array1D[Float64]
        var FluidTemp: Array1D[Float64]
        var PreviousFluidTemp: Array1D[Float64]
        var TentativePipeTemp: Array1D[Float64]
        var PipeTemp: Array1D[Float64]
        var PreviousPipeTemp: Array1D[Float64]
        var NumDepthNodes: Int32 = 0
        var PipeNodeDepth: Int32 = 0
        var PipeNodeWidth: Int32 = 0
        var PipeDepth: Float64 = 0.0
        var DomainDepth: Float64 = 0.0
        var dSregular: Float64 = 0.0
        var OutdoorConvCoef: Float64 = 0.0
        var SoilMaterial: String
        var SoilMaterialNum: Int32 = 0
        var MonthOfMinSurfTemp: Int32 = 0
        var MinSurfTemp: Float64 = 0.0
        var SoilDensity: Float64 = 0.0
        var SoilDepth: Float64 = 0.0
        var SoilCp: Float64 = 0.0
        var SoilConductivity: Float64 = 0.0
        var SoilRoughness: Material.SurfaceRoughness = Material.SurfaceRoughness.Invalid
        var SoilThermAbs: Float64 = 0.0
        var SoilSolarAbs: Float64 = 0.0
        var CoefA1: Float64 = 0.0
        var CoefA2: Float64 = 0.0
        var FourierDS: Float64 = 0.0
        var SoilDiffusivity: Float64 = 0.0
        var SoilDiffusivityPerDay: Float64 = 0.0
        var T: Array4D[Float64]
        var BeginSimInit: Bool = True
        var BeginSimEnvrn: Bool = True
        var FirstHVACupdateFlag: Bool = True
        var BeginEnvrnupdateFlag: Bool = True
        var SolarExposed: Bool = True
        var SumTK: Float64 = 0.0
        var ZoneHeatGainRate: Float64 = 0.0
        var plantLoc: PlantLocation
        var CheckEquipName: Bool = True
        var groundTempModel: GroundTemp.BaseGroundTempsModel = None
        var FluidInletTemp: Float64 = 0.0
        var FluidOutletTemp: Float64 = 0.0
        var MassFlowRate: Float64 = 0.0
        var FluidHeatLossRate: Float64 = 0.0
        var FluidHeatLossEnergy: Float64 = 0.0
        var PipeInletTemp: Float64 = 0.0
        var PipeOutletTemp: Float64 = 0.0
        var EnvironmentHeatLossRate: Float64 = 0.0
        var EnvHeatLossEnergy: Float64 = 0.0
        var VolumeFlowRate: Float64 = 0.0

        def __init__(inout self):
            self.Length = 0.0
            self.PipeID = 0.0
            self.InletNodeNum = 0
            self.OutletNodeNum = 0
            self.Type = DataPlant.PlantEquipmentType.Invalid
            self.ConstructionNum = 0
            self.EnvironmentPtr = EnvrnPtr.None
            self.EnvrZonePtr = 0
            self.EnvrAirNodeNum = 0
            self.NumSections = 0
            self.FluidSpecHeat = 0.0
            self.FluidDensity = 0.0
            self.MaxFlowRate = 0.0
            self.InsideArea = 0.0
            self.OutsideArea = 0.0
            self.SectionArea = 0.0
            self.PipeHeatCapacity = 0.0
            self.PipeOD = 0.0
            self.PipeCp = 0.0
            self.PipeDensity = 0.0
            self.PipeConductivity = 0.0
            self.InsulationOD = 0.0
            self.InsulationCp = 0.0
            self.InsulationDensity = 0.0
            self.InsulationConductivity = 0.0
            self.InsulationThickness = 0.0
            self.InsulationResistance = 0.0
            self.CurrentSimTime = 0.0
            self.PreviousSimTime = 0.0
            self.NumDepthNodes = 0
            self.PipeNodeDepth = 0
            self.PipeNodeWidth = 0
            self.PipeDepth = 0.0
            self.DomainDepth = 0.0
            self.dSregular = 0.0
            self.OutdoorConvCoef = 0.0
            self.SoilMaterialNum = 0
            self.MonthOfMinSurfTemp = 0
            self.MinSurfTemp = 0.0
            self.SoilDensity = 0.0
            self.SoilDepth = 0.0
            self.SoilCp = 0.0
            self.SoilConductivity = 0.0
            self.SoilRoughness = Material.SurfaceRoughness.Invalid
            self.SoilThermAbs = 0.0
            self.SoilSolarAbs = 0.0
            self.CoefA1 = 0.0
            self.CoefA2 = 0.0
            self.FourierDS = 0.0
            self.SoilDiffusivity = 0.0
            self.SoilDiffusivityPerDay = 0.0
            self.BeginSimInit = True
            self.BeginSimEnvrn = True
            self.FirstHVACupdateFlag = True
            self.BeginEnvrnupdateFlag = True
            self.SolarExposed = True
            self.SumTK = 0.0
            self.ZoneHeatGainRate = 0.0
            self.plantLoc = PlantLocation()
            self.CheckEquipName = True
            self.FluidInletTemp = 0.0
            self.FluidOutletTemp = 0.0
            self.MassFlowRate = 0.0
            self.FluidHeatLossRate = 0.0
            self.FluidHeatLossEnergy = 0.0
            self.PipeInletTemp = 0.0
            self.PipeOutletTemp = 0.0
            self.EnvironmentHeatLossRate = 0.0
            self.EnvHeatLossEnergy = 0.0
            self.VolumeFlowRate = 0.0

        @staticmethod
        def factory(state: EnergyPlusData, objectType: DataPlant.PlantEquipmentType, objectName: String) -> PlantComponent:
            if state.dataPipeHT.GetPipeInputFlag:
                Self.GetPipesHeatTransfer(state)
                state.dataPipeHT.GetPipeInputFlag = False
            var thisObj = state.dataPipeHT.PipeHT.find(lambda myObj: myObj.Type == objectType and myObj.Name == objectName)
            if thisObj != -1:
                return state.dataPipeHT.PipeHT[thisObj]
            ShowFatalError(state, "PipeHTFactory: Error getting inputs for pipe named: {}".format(objectName))
            return None

        def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
            self.InitPipesHeatTransfer(state, FirstHVACIteration)
            for InnerTimeStepCtr in range(1, state.dataPipeHT.nsvNumInnerTimeSteps + 1):
                if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                    self.CalcBuriedPipeSoil(state)
                else:
                    self.CalcPipesHeatTransfer(state)
                self.PushInnerTimeStepArrays()
            self.UpdatePipesHeatTransfer(state)
            self.ReportPipesHeatTransfer(state)

        def PushInnerTimeStepArrays(inout self):
            if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                for LengthIndex in range(2, self.NumSections + 1):
                    for DepthIndex in range(1, self.NumDepthNodes + 1):
                        for WidthIndex in range(2, self.PipeNodeWidth + 1):
                            self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Previous] = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Current]
            self.PreviousFluidTemp = self.FluidTemp
            self.PreviousPipeTemp = self.PipeTemp

        @staticmethod
        def GetPipesHeatTransfer(state: EnergyPlusData):
            using Node.TestCompSet
            using Node.GetOnlySingleNode
            using OutAirNodeManager.CheckOutAirNodeNumber
            const routineName: String = "GetPipeHeatTransfer"
            const NumPipeSections: Int32 = 20
            const NumberOfDepthNodes: Int32 = 8
            var ErrorsFound: Bool = False
            var IOStatus: Int32
            var NumAlphas: Int32
            var NumNumbers: Int32
            var NumOfPipeHTInt: Int32
            var NumOfPipeHTExt: Int32
            var NumOfPipeHTUG: Int32
            var s_ipsc = state.dataIPShortCut
            var s_mat = state.dataMaterial
            s_ipsc.cCurrentModuleObject = "Pipe:Indoor"
            NumOfPipeHTInt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
            s_ipsc.cCurrentModuleObject = "Pipe:Outdoor"
            NumOfPipeHTExt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
            s_ipsc.cCurrentModuleObject = "Pipe:Underground"
            NumOfPipeHTUG = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
            state.dataPipeHT.nsvNumOfPipeHT = NumOfPipeHTInt + NumOfPipeHTExt + NumOfPipeHTUG
            if allocated(state.dataPipeHT.PipeHT):
                state.dataPipeHT.PipeHT.deallocate()
            state.dataPipeHT.PipeHT.allocate(state.dataPipeHT.nsvNumOfPipeHT)
            state.dataPipeHT.PipeHTUniqueNames.reserve(state.dataPipeHT.nsvNumOfPipeHT)
            var Item: Int32 = 0
            s_ipsc.cCurrentModuleObject = "Pipe:Indoor"
            for PipeItem in range(1, NumOfPipeHTInt + 1):
                Item += 1
                state.dataInputProcessing.inputProcessor.getObjectItem(state, s_ipsc.cCurrentModuleObject, PipeItem, s_ipsc.cAlphaArgs, NumAlphas, s_ipsc.rNumericArgs, NumNumbers, IOStatus, s_ipsc.lNumericFieldBlanks, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)
                GlobalNames.VerifyUniqueInterObjectName(state, state.dataPipeHT.PipeHTUniqueNames, s_ipsc.cAlphaArgs[1], s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
                state.dataPipeHT.PipeHT[Item].Name = s_ipsc.cAlphaArgs[1]
                state.dataPipeHT.PipeHT[Item].Type = DataPlant.PlantEquipmentType.PipeInterior
                state.dataPipeHT.PipeHT[Item].Construction = s_ipsc.cAlphaArgs[2]
                state.dataPipeHT.PipeHT[Item].ConstructionNum = Util.FindItemInList(s_ipsc.cAlphaArgs[2], state.dataConstruction.Construct)
                if state.dataPipeHT.PipeHT[Item].ConstructionNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].InletNode = s_ipsc.cAlphaArgs[3]
                state.dataPipeHT.PipeHT[Item].InletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[3], ErrorsFound, Node.ConnectionObjectType.PipeIndoor, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].InletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[3], s_ipsc.cAlphaArgs[3]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].OutletNode = s_ipsc.cAlphaArgs[4]
                state.dataPipeHT.PipeHT[Item].OutletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[4], ErrorsFound, Node.ConnectionObjectType.PipeIndoor, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].OutletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                TestCompSet(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaArgs[3], s_ipsc.cAlphaArgs[4], "Pipe Nodes")
                if s_ipsc.lAlphaFieldBlanks[5]:
                    s_ipsc.cAlphaArgs[5] = "ZONE"
                var indoorType: PipeIndoorBoundaryType = getEnumValue(pipeIndoorBoundaryTypeNamesUC, s_ipsc.cAlphaArgs[5])
                if indoorType == PipeIndoorBoundaryType.Zone:
                    state.dataPipeHT.PipeHT[Item].EnvironmentPtr = EnvrnPtr.ZoneEnv
                    state.dataPipeHT.PipeHT[Item].EnvrZonePtr = Util.FindItemInList(s_ipsc.cAlphaArgs[6], state.dataHeatBal.Zone)
                    if state.dataPipeHT.PipeHT[Item].EnvrZonePtr == 0:
                        ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[6], s_ipsc.cAlphaArgs[6]))
                        ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                        ErrorsFound = True
                elif indoorType == PipeIndoorBoundaryType.Schedule:
                    state.dataPipeHT.PipeHT[Item].EnvironmentPtr = EnvrnPtr.ScheduleEnv
                    state.dataPipeHT.PipeHT[Item].envrSched = Sched.GetSchedule(state, s_ipsc.cAlphaArgs[7])
                    state.dataPipeHT.PipeHT[Item].envrVelSched = Sched.GetSchedule(state, s_ipsc.cAlphaArgs[8])
                    if state.dataPipeHT.PipeHT[Item].envrSched == None:
                        ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[7], s_ipsc.cAlphaArgs[7]))
                        ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                        ErrorsFound = True
                    if state.dataPipeHT.PipeHT[Item].envrVelSched == None:
                        ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[8], s_ipsc.cAlphaArgs[8]))
                        ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                        ErrorsFound = True
                else:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ShowContinueError(state, "Should be \"ZONE\" or \"SCHEDULE\"")
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].PipeID = s_ipsc.rNumericArgs[1]
                if s_ipsc.rNumericArgs[1] <= 0.0:
                    ShowSevereError(state, "GetPipesHeatTransfer: invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[1], s_ipsc.rNumericArgs[1]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[1]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].Length = s_ipsc.rNumericArgs[2]
                if s_ipsc.rNumericArgs[2] <= 0.0:
                    ShowSevereError(state, "GetPipesHeatTransfer: invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[2], s_ipsc.rNumericArgs[2]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                if state.dataPipeHT.PipeHT[Item].ConstructionNum != 0:
                    state.dataPipeHT.PipeHT[Item].ValidatePipeConstruction(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[2], s_ipsc.cAlphaFieldNames[2], state.dataPipeHT.PipeHT[Item].ConstructionNum, ErrorsFound)
            s_ipsc.cCurrentModuleObject = "Pipe:Outdoor"
            for PipeItem in range(1, NumOfPipeHTExt + 1):
                Item += 1
                state.dataInputProcessing.inputProcessor.getObjectItem(state, s_ipsc.cCurrentModuleObject, PipeItem, s_ipsc.cAlphaArgs, NumAlphas, s_ipsc.rNumericArgs, NumNumbers, IOStatus, s_ipsc.lNumericFieldBlanks, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)
                GlobalNames.VerifyUniqueInterObjectName(state, state.dataPipeHT.PipeHTUniqueNames, s_ipsc.cAlphaArgs[1], s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
                state.dataPipeHT.PipeHT[Item].Name = s_ipsc.cAlphaArgs[1]
                state.dataPipeHT.PipeHT[Item].Type = DataPlant.PlantEquipmentType.PipeExterior
                state.dataPipeHT.PipeHT[Item].Construction = s_ipsc.cAlphaArgs[2]
                state.dataPipeHT.PipeHT[Item].ConstructionNum = Util.FindItemInList(s_ipsc.cAlphaArgs[2], state.dataConstruction.Construct)
                if state.dataPipeHT.PipeHT[Item].ConstructionNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].InletNode = s_ipsc.cAlphaArgs[3]
                state.dataPipeHT.PipeHT[Item].InletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[3], ErrorsFound, Node.ConnectionObjectType.PipeOutdoor, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].InletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[3], s_ipsc.cAlphaArgs[3]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].OutletNode = s_ipsc.cAlphaArgs[4]
                state.dataPipeHT.PipeHT[Item].OutletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[4], ErrorsFound, Node.ConnectionObjectType.PipeOutdoor, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].OutletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                TestCompSet(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaArgs[3], s_ipsc.cAlphaArgs[4], "Pipe Nodes")
                state.dataPipeHT.PipeHT[Item].EnvironmentPtr = EnvrnPtr.OutsideAirEnv
                state.dataPipeHT.PipeHT[Item].EnvrAirNode = s_ipsc.cAlphaArgs[5]
                state.dataPipeHT.PipeHT[Item].EnvrAirNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[5], ErrorsFound, Node.ConnectionObjectType.PipeOutdoor, s_ipsc.cAlphaArgs[1], Node.FluidType.Air, Node.ConnectionType.OutsideAirReference, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if not s_ipsc.lAlphaFieldBlanks[5]:
                    if not CheckOutAirNodeNumber(state, state.dataPipeHT.PipeHT[Item].EnvrAirNodeNum):
                        ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5]))
                        ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                        ShowContinueError(state, "Outdoor Air Node not on OutdoorAir:NodeList or OutdoorAir:Node")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ShowContinueError(state, "An {} must be used ".format(s_ipsc.cAlphaFieldNames[5]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].PipeID = s_ipsc.rNumericArgs[1]
                if s_ipsc.rNumericArgs[1] <= 0.0:
                    ShowSevereError(state, "Invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[1], s_ipsc.rNumericArgs[1]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[1]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].Length = s_ipsc.rNumericArgs[2]
                if s_ipsc.rNumericArgs[2] <= 0.0:
                    ShowSevereError(state, "Invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[2], s_ipsc.rNumericArgs[2]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                if state.dataPipeHT.PipeHT[Item].ConstructionNum != 0:
                    state.dataPipeHT.PipeHT[Item].ValidatePipeConstruction(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[2], s_ipsc.cAlphaFieldNames[2], state.dataPipeHT.PipeHT[Item].ConstructionNum, ErrorsFound)
            s_ipsc.cCurrentModuleObject = "Pipe:Underground"
            for PipeItem in range(1, NumOfPipeHTUG + 1):
                Item += 1
                state.dataInputProcessing.inputProcessor.getObjectItem(state, s_ipsc.cCurrentModuleObject, PipeItem, s_ipsc.cAlphaArgs, NumAlphas, s_ipsc.rNumericArgs, NumNumbers, IOStatus, s_ipsc.lNumericFieldBlanks, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)
                var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1])
                GlobalNames.VerifyUniqueInterObjectName(state, state.dataPipeHT.PipeHTUniqueNames, s_ipsc.cAlphaArgs[1], s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
                state.dataPipeHT.PipeHT[Item].Name = s_ipsc.cAlphaArgs[1]
                state.dataPipeHT.PipeHT[Item].Type = DataPlant.PlantEquipmentType.PipeUnderground
                state.dataPipeHT.PipeHT[Item].Construction = s_ipsc.cAlphaArgs[2]
                state.dataPipeHT.PipeHT[Item].ConstructionNum = Util.FindItemInList(s_ipsc.cAlphaArgs[2], state.dataConstruction.Construct)
                if state.dataPipeHT.PipeHT[Item].ConstructionNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].InletNode = s_ipsc.cAlphaArgs[3]
                state.dataPipeHT.PipeHT[Item].InletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[3], ErrorsFound, Node.ConnectionObjectType.PipeUnderground, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].InletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[3], s_ipsc.cAlphaArgs[3]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].OutletNode = s_ipsc.cAlphaArgs[4]
                state.dataPipeHT.PipeHT[Item].OutletNodeNum = GetOnlySingleNode(state, s_ipsc.cAlphaArgs[4], ErrorsFound, Node.ConnectionObjectType.PipeUnderground, s_ipsc.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                if state.dataPipeHT.PipeHT[Item].OutletNodeNum == 0:
                    ShowSevereError(state, "Invalid {}={}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                TestCompSet(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaArgs[3], s_ipsc.cAlphaArgs[4], "Pipe Nodes")
                state.dataPipeHT.PipeHT[Item].EnvironmentPtr = EnvrnPtr.GroundEnv
                if Util.SameString(s_ipsc.cAlphaArgs[5], "SUNEXPOSED"):
                    state.dataPipeHT.PipeHT[Item].SolarExposed = True
                elif Util.SameString(s_ipsc.cAlphaArgs[5], "NOSUN"):
                    state.dataPipeHT.PipeHT[Item].SolarExposed = False
                else:
                    ShowSevereError(state, "GetPipesHeatTransfer: invalid key for sun exposure flag for {}".format(s_ipsc.cAlphaArgs[1]))
                    ShowContinueError(state, "Key should be either SunExposed or NoSun.  Entered Key: {}".format(s_ipsc.cAlphaArgs[5]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].PipeID = s_ipsc.rNumericArgs[1]
                if s_ipsc.rNumericArgs[1] <= 0.0:
                    ShowSevereError(state, "Invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[1], s_ipsc.rNumericArgs[1]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[1]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].Length = s_ipsc.rNumericArgs[2]
                if s_ipsc.rNumericArgs[2] <= 0.0:
                    ShowSevereError(state, "Invalid {} of {:.4f}".format(s_ipsc.cNumericFieldNames[2], s_ipsc.rNumericArgs[2]))
                    ShowContinueError(state, "{} must be > 0.0".format(s_ipsc.cNumericFieldNames[2]))
                    ShowContinueError(state, "Entered in {}={}".format(s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].SoilMaterial = s_ipsc.cAlphaArgs[6]
                state.dataPipeHT.PipeHT[Item].SoilMaterialNum = Material.GetMaterialNum(state, s_ipsc.cAlphaArgs[6])
                if state.dataPipeHT.PipeHT[Item].SoilMaterialNum == 0:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[6], s_ipsc.cAlphaArgs[6])
                    ErrorsFound = True
                else:
                    var matSoil = s_mat.materials[state.dataPipeHT.PipeHT[Item].SoilMaterialNum]
                    state.dataPipeHT.PipeHT[Item].SoilDensity = matSoil.Density
                    state.dataPipeHT.PipeHT[Item].SoilDepth = matSoil.Thickness
                    state.dataPipeHT.PipeHT[Item].SoilCp = matSoil.SpecHeat
                    state.dataPipeHT.PipeHT[Item].SoilConductivity = matSoil.Conductivity
                    state.dataPipeHT.PipeHT[Item].SoilThermAbs = matSoil.AbsorpThermal
                    state.dataPipeHT.PipeHT[Item].SoilSolarAbs = matSoil.AbsorpSolar
                    state.dataPipeHT.PipeHT[Item].SoilRoughness = matSoil.Roughness
                    state.dataPipeHT.PipeHT[Item].PipeDepth = state.dataPipeHT.PipeHT[Item].SoilDepth + state.dataPipeHT.PipeHT[Item].PipeID / 2.0
                    state.dataPipeHT.PipeHT[Item].DomainDepth = state.dataPipeHT.PipeHT[Item].PipeDepth * 2.0
                    state.dataPipeHT.PipeHT[Item].SoilDiffusivity = state.dataPipeHT.PipeHT[Item].SoilConductivity / (state.dataPipeHT.PipeHT[Item].SoilDensity * state.dataPipeHT.PipeHT[Item].SoilCp)
                    state.dataPipeHT.PipeHT[Item].SoilDiffusivityPerDay = state.dataPipeHT.PipeHT[Item].SoilDiffusivity * Constant.rSecsInDay
                    state.dataPipeHT.PipeHT[Item].NumDepthNodes = NumberOfDepthNodes
                    state.dataPipeHT.PipeHT[Item].PipeNodeDepth = state.dataPipeHT.PipeHT[Item].NumDepthNodes // 2
                    state.dataPipeHT.PipeHT[Item].PipeNodeWidth = state.dataPipeHT.PipeHT[Item].NumDepthNodes // 2
                    state.dataPipeHT.PipeHT[Item].DomainDepth = state.dataPipeHT.PipeHT[Item].PipeDepth * 2.0
                    state.dataPipeHT.PipeHT[Item].dSregular = state.dataPipeHT.PipeHT[Item].DomainDepth / (state.dataPipeHT.PipeHT[Item].NumDepthNodes - 1)
                if state.dataPipeHT.PipeHT[Item].ConstructionNum != 0:
                    state.dataPipeHT.PipeHT[Item].ValidatePipeConstruction(state, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[2], s_ipsc.cAlphaFieldNames[2], state.dataPipeHT.PipeHT[Item].ConstructionNum, ErrorsFound)
                var gtmType: GroundTemp.ModelType = getEnumValue(GroundTemp.modelTypeNamesUC, s_ipsc.cAlphaArgs[7])
                if gtmType == GroundTemp.ModelType.Invalid:
                    ShowSevereInvalidKey(state, eoh, s_ipsc.cAlphaFieldNames[7], s_ipsc.cAlphaArgs[7])
                    ErrorsFound = True
                state.dataPipeHT.PipeHT[Item].groundTempModel = GroundTemp.GetGroundTempModelAndInit(state, gtmType, s_ipsc.cAlphaArgs[8])
                state.dataPipeHT.PipeHT[Item].NumSections = NumPipeSections
                state.dataPipeHT.PipeHT[Item].T.allocate(state.dataPipeHT.PipeHT[Item].PipeNodeWidth, state.dataPipeHT.PipeHT[Item].NumDepthNodes, state.dataPipeHT.PipeHT[Item].NumSections, TimeIndex.Tentative)
                state.dataPipeHT.PipeHT[Item].T = 0.0
            for Item in range(1, state.dataPipeHT.nsvNumOfPipeHT + 1):
                var NumSections = NumPipeSections
                state.dataPipeHT.PipeHT[Item].NumSections = NumPipeSections
                state.dataPipeHT.PipeHT[Item].TentativeFluidTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].TentativePipeTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].FluidTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].PreviousFluidTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].PipeTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].PreviousPipeTemp.allocate(0, NumSections)
                state.dataPipeHT.PipeHT[Item].TentativeFluidTemp = 0.0
                state.dataPipeHT.PipeHT[Item].FluidTemp = 0.0
                state.dataPipeHT.PipeHT[Item].PreviousFluidTemp = 0.0
                state.dataPipeHT.PipeHT[Item].TentativePipeTemp = 0.0
                state.dataPipeHT.PipeHT[Item].PipeTemp = 0.0
                state.dataPipeHT.PipeHT[Item].PreviousPipeTemp = 0.0
                state.dataPipeHT.PipeHT[Item].InsideArea = Constant.Pi * state.dataPipeHT.PipeHT[Item].PipeID * state.dataPipeHT.PipeHT[Item].Length / NumSections
                state.dataPipeHT.PipeHT[Item].OutsideArea = Constant.Pi * (state.dataPipeHT.PipeHT[Item].PipeOD + 2 * state.dataPipeHT.PipeHT[Item].InsulationThickness) * state.dataPipeHT.PipeHT[Item].Length / NumSections
                state.dataPipeHT.PipeHT[Item].SectionArea = Constant.Pi * 0.25 * pow_2(state.dataPipeHT.PipeHT[Item].PipeID)
                state.dataPipeHT.PipeHT[Item].PipeHeatCapacity = state.dataPipeHT.PipeHT[Item].PipeCp * state.dataPipeHT.PipeHT[Item].PipeDensity * (Constant.Pi * 0.25 * pow_2(state.dataPipeHT.PipeHT[Item].PipeOD) - state.dataPipeHT.PipeHT[Item].SectionArea)
            if ErrorsFound:
                ShowFatalError(state, "GetPipesHeatTransfer: Errors found in input. Preceding conditions cause termination.")
            for Item in range(1, state.dataPipeHT.nsvNumOfPipeHT + 1):
                SetupOutputVariable(state, "Pipe Fluid Heat Transfer Rate", Constant.Units.W, state.dataPipeHT.PipeHT[Item].FluidHeatLossRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)
                SetupOutputVariable(state, "Pipe Fluid Heat Transfer Energy", Constant.Units.J, state.dataPipeHT.PipeHT[Item].FluidHeatLossEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataPipeHT.PipeHT[Item].Name)
                if state.dataPipeHT.PipeHT[Item].EnvironmentPtr == EnvrnPtr.ZoneEnv:
                    SetupOutputVariable(state, "Pipe Ambient Heat Transfer Rate", Constant.Units.W, state.dataPipeHT.PipeHT[Item].EnvironmentHeatLossRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)
                    SetupOutputVariable(state, "Pipe Ambient Heat Transfer Energy", Constant.Units.J, state.dataPipeHT.PipeHT[Item].EnvHeatLossEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataPipeHT.PipeHT[Item].Name)
                    SetupZoneInternalGain(state, state.dataPipeHT.PipeHT[Item].EnvrZonePtr, state.dataPipeHT.PipeHT[Item].Name, DataHeatBalance.IntGainType.PipeIndoor, &state.dataPipeHT.PipeHT[Item].ZoneHeatGainRate)
                SetupOutputVariable(state, "Pipe Mass Flow Rate", Constant.Units.kg_s, state.dataPipeHT.PipeHT[Item].MassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)
                SetupOutputVariable(state, "Pipe Volume Flow Rate", Constant.Units.m3_s, state.dataPipeHT.PipeHT[Item].VolumeFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)
                SetupOutputVariable(state, "Pipe Inlet Temperature", Constant.Units.C, state.dataPipeHT.PipeHT[Item].FluidInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)
                SetupOutputVariable(state, "Pipe Outlet Temperature", Constant.Units.C, state.dataPipeHT.PipeHT[Item].FluidOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPipeHT.PipeHT[Item].Name)

        def ValidatePipeConstruction(inout self, state: EnergyPlusData, PipeType: String, ConstructionName: String, FieldName: String, ConstructionNum: Int32, ErrorsFound: Bool):
            var Density: Float64 = 0.0
            var SpHeat: Float64 = 0.0
            var Resistance: Float64 = 0.0
            var TotThickness: Float64 = 0.0
            var s_mat = state.dataMaterial
            var TotalLayers = state.dataConstruction.Construct[ConstructionNum].TotLayers
            if TotalLayers == 1:
                var mat = s_mat.materials[state.dataConstruction.Construct[ConstructionNum].LayerPoint[1]]
                self.PipeConductivity = mat.Conductivity
                self.PipeDensity = mat.Density
                self.PipeCp = mat.SpecHeat
                self.PipeOD = self.PipeID + 2.0 * mat.Thickness
                self.InsulationOD = self.PipeOD
                self.SumTK = mat.Thickness / mat.Conductivity
            elif TotalLayers >= 2:
                for LayerNum in range(1, TotalLayers):
                    var mat = state.dataMaterial.materials[state.dataConstruction.Construct[ConstructionNum].LayerPoint[LayerNum]]
                    Resistance += mat.Thickness / mat.Conductivity
                    Density = mat.Density * mat.Thickness
                    TotThickness += mat.Thickness
                    SpHeat = mat.SpecHeat * mat.Thickness
                    self.InsulationThickness = mat.Thickness
                    self.SumTK += mat.Thickness / mat.Conductivity
                self.InsulationResistance = Resistance
                self.InsulationConductivity = TotThickness / Resistance
                self.InsulationDensity = Density / TotThickness
                self.InsulationCp = SpHeat / TotThickness
                self.InsulationThickness = TotThickness
                var mat = state.dataMaterial.materials[state.dataConstruction.Construct[ConstructionNum].LayerPoint[TotalLayers]]
                self.PipeConductivity = mat.Conductivity
                self.PipeDensity = mat.Density
                self.PipeCp = mat.SpecHeat
                self.PipeOD = self.PipeID + 2.0 * mat.Thickness
                self.InsulationOD = self.PipeOD + 2.0 * self.InsulationThickness
            else:
                ShowSevereError(state, "{}: invalid {}=\"{}\", too many layers=[{}], only 1 or 2 allowed.".format(PipeType, FieldName, ConstructionName, TotalLayers))
                ErrorsFound = True

        def oneTimeInit_new(inout self, state: EnergyPlusData):
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.Type, self.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "InitPipesHeatTransfer: Program terminated due to previous condition(s).")

        def InitPipesHeatTransfer(inout self, state: EnergyPlusData, FirstHVACIteration: Bool):
            var SysTimeElapsed: Float64 = state.dataHVACGlobal.SysTimeElapsed
            var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
            const RoutineName: String = "InitPipesHeatTransfer"
            var FirstTemperatures: Float64 = 0.0
            var TimeIndex: Int32
            var LengthIndex: Int32
            var DepthIndex: Int32
            var WidthIndex: Int32
            var CurrentDepth: Float64 = 0.0
            var CurTemp: Float64 = 0.0
            var CurSimDay: Float64 = 0.0
            var PushArrays: Bool = False
            CurSimDay = Float64(state.dataGlobal.DayOfSim)
            state.dataPipeHT.nsvInletNodeNum = self.InletNodeNum
            state.dataPipeHT.nsvOutletNodeNum = self.OutletNodeNum
            state.dataPipeHT.nsvMassFlowRate = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRate
            state.dataPipeHT.nsvInletTemp = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].Temp
            if (state.dataGlobal.BeginSimFlag and self.BeginSimInit) or (state.dataGlobal.BeginEnvrnFlag and self.BeginSimEnvrn):
                if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                    for TimeIndex in range(TimeIndex.Previous, TimeIndex.Tentative + 1):
                        for LengthIndex in range(1, self.NumSections + 1):
                            for DepthIndex in range(1, self.NumDepthNodes + 1):
                                for WidthIndex in range(1, self.PipeNodeWidth + 1):
                                    CurrentDepth = (DepthIndex - 1) * self.dSregular
                                    self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex] = self.TBND(state, CurrentDepth)
                FirstTemperatures = 21.0
                self.TentativeFluidTemp = FirstTemperatures
                self.FluidTemp = FirstTemperatures
                self.PreviousFluidTemp = FirstTemperatures
                self.TentativePipeTemp = FirstTemperatures
                self.PipeTemp = FirstTemperatures
                self.PreviousPipeTemp = FirstTemperatures
                self.PreviousSimTime = 0.0
                state.dataPipeHT.nsvDeltaTime = 0.0
                state.dataPipeHT.nsvOutletTemp = 0.0
                state.dataPipeHT.nsvEnvironmentTemp = 0.0
                state.dataPipeHT.nsvEnvHeatLossRate = 0.0
                state.dataPipeHT.nsvFluidHeatLossRate = 0.0
                self.BeginSimInit = False
                self.BeginSimEnvrn = False
            if not state.dataGlobal.BeginSimFlag:
                self.BeginSimInit = True
            if not state.dataGlobal.BeginEnvrnFlag:
                self.BeginSimEnvrn = True
            state.dataPipeHT.nsvDeltaTime = TimeStepSysSec
            state.dataPipeHT.nsvNumInnerTimeSteps = Int32(state.dataPipeHT.nsvDeltaTime / InnerDeltaTime)
            if (FirstHVACIteration and self.FirstHVACupdateFlag) or (state.dataGlobal.BeginEnvrnFlag and self.BeginEnvrnupdateFlag):
                if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                    for TimeIndex in range(1, TimeIndex.Tentative + 1):
                        for LengthIndex in range(1, self.NumSections + 1):
                            for DepthIndex in range(1, self.NumDepthNodes + 1):
                                CurrentDepth = (DepthIndex - 1) * self.dSregular
                                CurTemp = self.TBND(state, CurrentDepth)
                                self.T[1, DepthIndex, LengthIndex, TimeIndex] = CurTemp
                            for WidthIndex in range(1, self.PipeNodeWidth + 1):
                                CurrentDepth = self.DomainDepth
                                CurTemp = self.TBND(state, CurrentDepth)
                                self.T[WidthIndex, self.NumDepthNodes, LengthIndex, TimeIndex] = CurTemp
                if self.EnvironmentPtr == EnvrnPtr.GroundEnv:

                elif self.EnvironmentPtr == EnvrnPtr.OutsideAirEnv:
                    state.dataPipeHT.nsvEnvironmentTemp = state.dataEnvrn.OutDryBulbTemp
                elif self.EnvironmentPtr == EnvrnPtr.ZoneEnv:
                    state.dataPipeHT.nsvEnvironmentTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.EnvrZonePtr].MAT
                elif self.EnvironmentPtr == EnvrnPtr.ScheduleEnv:
                    state.dataPipeHT.nsvEnvironmentTemp = self.envrSched.getCurrentVal()
                elif self.EnvironmentPtr == EnvrnPtr.None:
                    state.dataPipeHT.nsvEnvironmentTemp = state.dataEnvrn.OutDryBulbTemp
                else:

                self.BeginEnvrnupdateFlag = False
                self.FirstHVACupdateFlag = False
            if not state.dataGlobal.BeginEnvrnFlag:
                self.BeginEnvrnupdateFlag = True
            if not FirstHVACIteration:
                self.FirstHVACupdateFlag = True
            self.CurrentSimTime = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.HourOfDay - 1 + (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + SysTimeElapsed
            if abs(self.CurrentSimTime - self.PreviousSimTime) > 1.0e-6:
                PushArrays = True
                self.PreviousSimTime = self.CurrentSimTime
            else:
                PushArrays = False
            if PushArrays:
                if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                    for LengthIndex in range(2, self.NumSections + 1):
                        for DepthIndex in range(1, self.NumDepthNodes + 1):
                            for WidthIndex in range(2, self.PipeNodeWidth + 1):
                                self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Current] = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative]
                self.FluidTemp = self.TentativeFluidTemp
                self.PipeTemp = self.TentativePipeTemp
            else:
                for LengthIndex in range(2, self.NumSections + 1):
                    for DepthIndex in range(1, self.NumDepthNodes + 1):
                        for WidthIndex in range(2, self.PipeNodeWidth + 1):
                            self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Current]
                self.TentativeFluidTemp = self.FluidTemp
                self.TentativePipeTemp = self.PipeTemp
            self.FluidSpecHeat = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataPipeHT.nsvInletTemp, RoutineName)
            self.FluidDensity = self.plantLoc.loop.glycol.getDensity(state, state.dataPipeHT.nsvInletTemp, RoutineName)
            self.FluidHeatLossRate = 0.0
            self.FluidHeatLossEnergy = 0.0
            self.EnvironmentHeatLossRate = 0.0
            self.EnvHeatLossEnergy = 0.0
            self.ZoneHeatGainRate = 0.0
            state.dataPipeHT.nsvFluidHeatLossRate = 0.0
            state.dataPipeHT.nsvEnvHeatLossRate = 0.0
            state.dataPipeHT.nsvOutletTemp = 0.0
            if self.FluidDensity > 0.0:
                state.dataPipeHT.nsvVolumeFlowRate = state.dataPipeHT.nsvMassFlowRate / self.FluidDensity

        def CalcPipesHeatTransfer(inout self, state: EnergyPlusData, LengthIndex: Int32 = None):
            using DataEnvironment
            var A1: Float64 = 0.0
            var A2: Float64 = 0.0
            var A3: Float64 = 0.0
            var A4: Float64 = 0.0
            var B1: Float64 = 0.0
            var B2: Float64 = 0.0
            var B3: Float64 = 0.0
            var B4: Float64 = 0.0
            var AirConvCoef: Float64 = 0.0
            var FluidConvCoef: Float64 = 0.0
            var EnvHeatTransCoef: Float64 = 0.0
            var FluidNodeHeatCapacity: Float64 = 0.0
            var TempBelow: Float64 = 0.0
            var TempBeside: Float64 = 0.0
            var TempAbove: Float64 = 0.0
            var Numerator: Float64 = 0.0
            var Denominator: Float64 = 0.0
            var SurfaceTemp: Float64 = 0.0
            if self.FluidSpecHeat <= 0.0 or self.FluidDensity <= 0.0:
                state.dataPipeHT.nsvOutletTemp = self.TentativeFluidTemp[self.NumSections]
                state.dataPipeHT.nsvEnvHeatLossRate = 0.0
                state.dataPipeHT.nsvFluidHeatLossRate = 0.0
                return
            if self.EnvironmentPtr != EnvrnPtr.GroundEnv:
                AirConvCoef = 1.0 / (1.0 / self.OutsidePipeHeatTransCoef(state) + self.InsulationResistance)
            FluidConvCoef = self.CalcPipeHeatTransCoef(state, state.dataPipeHT.nsvInletTemp, state.dataPipeHT.nsvMassFlowRate, self.PipeID)
            if self.EnvironmentPtr == EnvrnPtr.GroundEnv:
                EnvHeatTransCoef = self.SoilConductivity / (self.dSregular - (self.PipeID / 2.0))
            elif self.EnvironmentPtr == EnvrnPtr.OutsideAirEnv:
                EnvHeatTransCoef = AirConvCoef
            elif self.EnvironmentPtr == EnvrnPtr.ZoneEnv:
                EnvHeatTransCoef = AirConvCoef
            elif self.EnvironmentPtr == EnvrnPtr.ScheduleEnv:
                EnvHeatTransCoef = AirConvCoef
            elif self.EnvironmentPtr == EnvrnPtr.None:
                EnvHeatTransCoef = 0.0
            else:
                EnvHeatTransCoef = 0.0
            FluidNodeHeatCapacity = self.SectionArea * self.Length / self.NumSections * self.FluidSpecHeat * self.FluidDensity
            A1 = FluidNodeHeatCapacity + state.dataPipeHT.nsvMassFlowRate * self.FluidSpecHeat * state.dataPipeHT.nsvDeltaTime + FluidConvCoef * self.InsideArea * state.dataPipeHT.nsvDeltaTime
            A2 = state.dataPipeHT.nsvMassFlowRate * self.FluidSpecHeat * state.dataPipeHT.nsvDeltaTime
            A3 = FluidConvCoef * self.InsideArea * state.dataPipeHT.nsvDeltaTime
            A4 = FluidNodeHeatCapacity
            B1 = self.PipeHeatCapacity + FluidConvCoef * self.InsideArea * state.dataPipeHT.nsvDeltaTime + EnvHeatTransCoef * self.OutsideArea * state.dataPipeHT.nsvDeltaTime
            B2 = A3
            B3 = EnvHeatTransCoef * self.OutsideArea * state.dataPipeHT.nsvDeltaTime
            B4 = self.PipeHeatCapacity
            self.TentativeFluidTemp[0] = state.dataPipeHT.nsvInletTemp
            self.TentativePipeTemp[0] = self.PipeTemp[1]
            if LengthIndex != None:
                var PipeDepth = self.PipeNodeDepth
                var PipeWidth = self.PipeNodeWidth
                TempBelow = self.T[PipeWidth, PipeDepth + 1, LengthIndex, TimeIndex.Current]
                TempBeside = self.T[PipeWidth - 1, PipeDepth, LengthIndex, TimeIndex.Current]
                TempAbove = self.T[PipeWidth, PipeDepth - 1, LengthIndex, TimeIndex.Current]
                state.dataPipeHT.nsvEnvironmentTemp = (TempBelow + TempBeside + TempAbove) / 3.0
                self.TentativeFluidTemp[LengthIndex] = (A2 * self.TentativeFluidTemp[LengthIndex - 1] + A3 / B1 * (B3 * state.dataPipeHT.nsvEnvironmentTemp + B4 * self.PreviousPipeTemp[LengthIndex]) + A4 * self.PreviousFluidTemp[LengthIndex]) / (A1 - A3 * B2 / B1)
                self.TentativePipeTemp[LengthIndex] = (B2 * self.TentativeFluidTemp[LengthIndex] + B3 * state.dataPipeHT.nsvEnvironmentTemp + B4 * self.PreviousPipeTemp[LengthIndex]) / B1
                Numerator = state.dataPipeHT.nsvEnvironmentTemp - self.TentativeFluidTemp[LengthIndex]
                Denominator = EnvHeatTransCoef * ((1 / EnvHeatTransCoef) + self.SumTK)
                SurfaceTemp = state.dataPipeHT.nsvEnvironmentTemp - Numerator / Denominator
                state.dataPipeHT.nsvEnvHeatLossRate += EnvHeatTransCoef * self.OutsideArea * (SurfaceTemp - state.dataPipeHT.nsvEnvironmentTemp)
            else:
                for curnode in range(1, self.NumSections + 1):
                    self.TentativeFluidTemp[curnode] = (A2 * self.TentativeFluidTemp[curnode - 1] + A3 / B1 * (B3 * state.dataPipeHT.nsvEnvironmentTemp + B4 * self.PreviousPipeTemp[curnode]) + A4 * self.PreviousFluidTemp[curnode]) / (A1 - A3 * B2 / B1)
                    self.TentativePipeTemp[curnode] = (B2 * self.TentativeFluidTemp[curnode] + B3 * state.dataPipeHT.nsvEnvironmentTemp + B4 * self.PreviousPipeTemp[curnode]) / B1
                    Numerator = state.dataPipeHT.nsvEnvironmentTemp - self.TentativeFluidTemp[curnode]
                    Denominator = EnvHeatTransCoef * ((1 / EnvHeatTransCoef) + self.SumTK)
                    SurfaceTemp = state.dataPipeHT.nsvEnvironmentTemp - Numerator / Denominator
                    state.dataPipeHT.nsvEnvHeatLossRate += EnvHeatTransCoef * self.OutsideArea * (SurfaceTemp - state.dataPipeHT.nsvEnvironmentTemp)
            state.dataPipeHT.nsvFluidHeatLossRate = state.dataPipeHT.nsvMassFlowRate * self.FluidSpecHeat * (self.TentativeFluidTemp[0] - self.TentativeFluidTemp[self.NumSections])
            state.dataPipeHT.nsvOutletTemp = self.TentativeFluidTemp[self.NumSections]

        def CalcBuriedPipeSoil(inout self, state: EnergyPlusData):
            using Convect.CalcASHRAESimpExtConvCoeff
            const NumSections: Int32 = 20
            const ConvCrit: Float64 = 0.05
            const MaxIterations: Int32 = 200
            const StefBoltzmann: Float64 = 5.6697e-08
            var IterationIndex: Int32 = 0
            var DepthIndex: Int32 = 0
            var WidthIndex: Int32 = 0
            var ConvCoef: Float64 = 0.0
            var RadCoef: Float64 = 0.0
            var QSolAbsorbed: Float64 = 0.0
            var T_O: Array3D[Float64] = Array3D[Float64](self.PipeNodeWidth, self.NumDepthNodes, NumSections)
            var A1: Float64 = 0.0
            var A2: Float64 = 0.0
            var NodeBelow: Float64 = 0.0
            var NodeAbove: Float64 = 0.0
            var NodeRight: Float64 = 0.0
            var NodeLeft: Float64 = 0.0
            var NodePast: Float64 = 0.0
            var PastNodeTempAbs: Float64 = 0.0
            var Ttemp: Float64 = 0.0
            var SkyTempAbs: Float64 = 0.0
            var TopRoughness: Material.SurfaceRoughness = Material.SurfaceRoughness.Invalid
            var TopThermAbs: Float64 = 0.0
            var TopSolarAbs: Float64 = 0.0
            var kSoil: Float64 = 0.0
            var dS: Float64 = 0.0
            var rho: Float64 = 0.0
            var Cp: Float64 = 0.0
            self.FourierDS = self.SoilDiffusivity * state.dataPipeHT.nsvDeltaTime / pow_2(self.dSregular)
            self.CoefA1 = self.FourierDS / (1 + 4 * self.FourierDS)
            self.CoefA2 = 1 / (1 + 4 * self.FourierDS)
            for IterationIndex in range(1, MaxIterations + 1):
                if IterationIndex == MaxIterations:
                    ShowWarningError(state, "BuriedPipeHeatTransfer: Large number of iterations detected in object: {}".format(self.Name))
                for LengthIndex in range(2, self.NumSections + 1):
                    for DepthIndex in range(1, self.NumDepthNodes):
                        for WidthIndex in range(2, self.PipeNodeWidth + 1):
                            T_O[WidthIndex, DepthIndex, LengthIndex] = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative]
                for LengthIndex in range(1, self.NumSections + 1):
                    for DepthIndex in range(1, self.NumDepthNodes):
                        for WidthIndex in range(2, self.PipeNodeWidth + 1):
                            if DepthIndex == 1:
                                NodePast = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Previous]
                                PastNodeTempAbs = NodePast + Constant.Kelvin
                                SkyTempAbs = state.dataEnvrn.SkyTemp + Constant.Kelvin
                                TopRoughness = self.SoilRoughness
                                TopThermAbs = self.SoilThermAbs
                                TopSolarAbs = self.SoilSolarAbs
                                kSoil = self.SoilConductivity
                                dS = self.dSregular
                                rho = self.SoilDensity
                                Cp = self.SoilCp
                                self.OutdoorConvCoef = CalcASHRAESimpExtConvCoeff(TopRoughness, state.dataEnvrn.WindSpeed)
                                ConvCoef = self.OutdoorConvCoef
                                if abs(PastNodeTempAbs - SkyTempAbs) > Constant.rTinyValue:
                                    RadCoef = StefBoltzmann * TopThermAbs * (pow_4(PastNodeTempAbs) - pow_4(SkyTempAbs)) / (PastNodeTempAbs - SkyTempAbs)
                                else:
                                    RadCoef = 0.0
                                QSolAbsorbed = TopSolarAbs * (max(state.dataEnvrn.SOLCOS[3], 0.0) * state.dataEnvrn.BeamSolarRad + state.dataEnvrn.DifSolarRad)
                                if not self.SolarExposed:
                                    RadCoef = 0.0
                                    QSolAbsorbed = 0.0
                                if WidthIndex == self.PipeNodeWidth:
                                    NodeBelow = self.T[WidthIndex, DepthIndex + 1, LengthIndex, TimeIndex.Current]
                                    NodeLeft = self.T[WidthIndex - 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                    self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = (QSolAbsorbed + RadCoef * state.dataEnvrn.SkyTemp + ConvCoef * state.dataEnvrn.OutDryBulbTemp + (kSoil / dS) * (NodeBelow + 2 * NodeLeft) + (rho * Cp / state.dataPipeHT.nsvDeltaTime) * NodePast) / (RadCoef + ConvCoef + 3 * (kSoil / dS) + (rho * Cp / state.dataPipeHT.nsvDeltaTime))
                                else:
                                    NodeBelow = self.T[WidthIndex, DepthIndex + 1, LengthIndex, TimeIndex.Current]
                                    NodeLeft = self.T[WidthIndex - 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                    NodeRight = self.T[WidthIndex + 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                    self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = (QSolAbsorbed + RadCoef * state.dataEnvrn.SkyTemp + ConvCoef * state.dataEnvrn.OutDryBulbTemp + (kSoil / dS) * (NodeBelow + NodeLeft + NodeRight) + (rho * Cp / state.dataPipeHT.nsvDeltaTime) * NodePast) / (RadCoef + ConvCoef + 3 * (kSoil / dS) + (rho * Cp / state.dataPipeHT.nsvDeltaTime))
                            elif WidthIndex == self.PipeNodeWidth:
                                if DepthIndex == self.PipeNodeDepth:
                                    self.CalcPipesHeatTransfer(state, LengthIndex)
                                    self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = self.PipeTemp[LengthIndex]
                                else:
                                    NodeLeft = self.T[WidthIndex - 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                    NodeAbove = self.T[WidthIndex, DepthIndex - 1, LengthIndex, TimeIndex.Current]
                                    NodeBelow = self.T[WidthIndex, DepthIndex + 1, LengthIndex, TimeIndex.Current]
                                    NodePast = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Current - 1]
                                    A1 = self.CoefA1
                                    A2 = self.CoefA2
                                    self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = A1 * (NodeBelow + NodeAbove + 2 * NodeLeft) + A2 * NodePast
                            else:
                                A1 = self.CoefA1
                                A2 = self.CoefA2
                                NodeBelow = self.T[WidthIndex, DepthIndex + 1, LengthIndex, TimeIndex.Current]
                                NodeAbove = self.T[WidthIndex, DepthIndex - 1, LengthIndex, TimeIndex.Current]
                                NodeRight = self.T[WidthIndex + 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                NodeLeft = self.T[WidthIndex - 1, DepthIndex, LengthIndex, TimeIndex.Current]
                                NodePast = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Current - 1]
                                self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative] = A1 * (NodeBelow + NodeAbove + NodeRight + NodeLeft) + A2 * NodePast
                var converged: Bool = True
                for LengthIndex in range(2, self.NumSections + 1):
                    for DepthIndex in range(1, self.NumDepthNodes):
                        for WidthIndex in range(2, self.PipeNodeWidth + 1):
                            Ttemp = self.T[WidthIndex, DepthIndex, LengthIndex, TimeIndex.Tentative]
                            if abs(T_O[WidthIndex, DepthIndex, LengthIndex] - Ttemp) > ConvCrit:
                                converged = False
                                break
                        if not converged:
                            break
                    if not converged:
                        break
                if converged:
                    break

        def UpdatePipesHeatTransfer(inout self, state: EnergyPlusData):
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].Temp = state.dataPipeHT.nsvOutletTemp
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].TempMin = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].TempMin
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].TempMax = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].TempMax
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].MassFlowRate = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRate
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].MassFlowRateMin = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRateMin
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].MassFlowRateMax = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRateMax
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].MassFlowRateMinAvail = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRateMinAvail
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].MassFlowRateMaxAvail = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].MassFlowRateMaxAvail
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].Quality = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].Quality
            if self.plantLoc.loop.PressureSimType == DataPlant.PressureSimType.NoPressure:
                state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].Press = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].Press
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].Enthalpy = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].Enthalpy
            state.dataLoopNodes.Node[state.dataPipeHT.nsvOutletNodeNum].HumRat = state.dataLoopNodes.Node[state.dataPipeHT.nsvInletNodeNum].HumRat

        def ReportPipesHeatTransfer(inout self, state: EnergyPlusData):
            self.FluidInletTemp = state.dataPipeHT.nsvInletTemp
            self.FluidOutletTemp = state.dataPipeHT.nsvOutletTemp
            self.MassFlowRate = state.dataPipeHT.nsvMassFlowRate
            self.VolumeFlowRate = state.dataPipeHT.nsvVolumeFlowRate
            self.FluidHeatLossRate = state.dataPipeHT.nsvFluidHeatLossRate
            self.FluidHeatLossEnergy = state.dataPipeHT.nsvFluidHeatLossRate * state.dataPipeHT.nsvDeltaTime
            self.PipeInletTemp = self.PipeTemp[1]
            self.PipeOutletTemp = self.PipeTemp[self.NumSections]
            self.EnvironmentHeatLossRate = state.dataPipeHT.nsvEnvHeatLossRate / state.dataPipeHT.nsvNumInnerTimeSteps
            self.EnvHeatLossEnergy = self.EnvironmentHeatLossRate * state.dataPipeHT.nsvDeltaTime
            if self.EnvironmentPtr == EnvrnPtr.ZoneEnv:
                self.ZoneHeatGainRate = self.EnvironmentHeatLossRate

        @staticmethod
        def CalcZonePipesHeatGain(state: EnergyPlusData):
            if state.dataPipeHT.nsvNumOfPipeHT == 0:
                return
            if state.dataGlobal.BeginEnvrnFlag and state.dataPipeHT.MyEnvrnFlag:
                for e in state.dataPipeHT.PipeHT:
                    e.ZoneHeatGainRate = 0.0
                state.dataPipeHT.MyEnvrnFlag = False
            if not state.dataGlobal.BeginEnvrnFlag:
                state.dataPipeHT.MyEnvrnFlag = True

        def CalcPipeHeatTransCoef(inout self, state: EnergyPlusData, Temperature: Float64, MassFlowRate: Float64, Diameter: Float64) -> Float64:
            var CalcPipeHeatTransCoef: Float64 = 0.0
            const RoutineName: String = "PipeHeatTransfer::CalcPipeHeatTransCoef: "
            const MaxLaminarRe: Float64 = 2300.0
            const NumOfPropDivisions: Int32 = 13
            const Temps: List[Float64] = [1.85, 6.85, 11.85, 16.85, 21.85, 26.85, 31.85, 36.85, 41.85, 46.85, 51.85, 56.85, 61.85]
            const Pr: List[Float64] = [12.22, 10.26, 8.81, 7.56, 6.62, 5.83, 5.20, 4.62, 4.16, 3.77, 3.42, 3.15, 2.88]
            var InterpFrac: Float64 = 0.0
            var NuD: Float64 = 0.0
            var ReD: Float64 = 0.0
            var Kactual: Float64 = 0.0
            var MUactual: Float64 = 0.0
            var PRactual: Float64 = 0.0
            var LoopNum: Int32 = self.plantLoc.loopNum
            var idx: Int32 = 0
            while idx < NumOfPropDivisions:
                if Temperature < Temps[idx]:
                    break
                idx += 1
            if idx == 0:
                PRactual = Pr[idx]
            elif idx >= NumOfPropDivisions:
                PRactual = Pr[NumOfPropDivisions - 1]
            else:
                InterpFrac = (Temperature - Temps[idx - 1]) / (Temps[idx] - Temps[idx - 1])
                PRactual = Pr[idx - 1] + InterpFrac * (Pr[idx] - Pr[idx - 1])
            Kactual = state.dataPlnt.PlantLoop[LoopNum].glycol.getConductivity(state, self.FluidTemp[0], RoutineName)
            MUactual = state.dataPlnt.PlantLoop[LoopNum].glycol.getViscosity(state, self.FluidTemp[0], RoutineName) / 1000.0
            ReD = 4.0 * MassFlowRate / (Constant.Pi * MUactual * Diameter)
            if ReD == 0.0:
                NuD = 3.66
            else:
                if ReD >= MaxLaminarRe:
                    NuD = 0.023 * pow(ReD, 0.8) * pow(PRactual, 1.0 / 3.0)
                else:
                    NuD = 3.66
            CalcPipeHeatTransCoef = Kactual * NuD / Diameter
            return CalcPipeHeatTransCoef

        def OutsidePipeHeatTransCoef(inout self, state: EnergyPlusData) -> Float64:
            var OutsidePipeHeatTransCoef: Float64 = 0.0
            const Pr: Float64 = 0.7
            const CondAir: Float64 = 0.025
            const RoomAirVel: Float64 = 0.381
            const NaturalConvNusselt: Float64 = 0.36
            const NumOfParamDivisions: Int32 = 5
            const NumOfPropDivisions: Int32 = 12
            const CCoef: List[Float64] = [0.989, 0.911, 0.683, 0.193, 0.027]
            const mExp: List[Float64] = [0.33, 0.385, 0.466, 0.618, 0.805]
            const UpperBound: List[Float64] = [4.0, 40.0, 4000.0, 40000.0, 400000.0]
            const Temperature: List[Float64] = [-73.0, -23.0, -10.0, 0.0, 10.0, 20.0, 27.0, 30.0, 40.0, 50.0, 76.85, 126.85]
            const DynVisc: List[Float64] = [75.52e-7, 11.37e-6, 12.44e-6, 13.3e-6, 14.18e-6, 15.08e-6, 15.75e-6, 16e-6, 16.95e-6, 17.91e-6, 20.92e-6, 26.41e-6]
            var idx: Int32 = 0
            var NuD: Float64 = 0.0
            var ReD: Float64 = 0.0
            var Coef: Float64 = 0.0
            var rExp: Float64 = 0.0
            var AirVisc: Float64 = 0.0
            var AirVel: Float64 = 0.0
            var AirTemp: Float64 = 0.0
            var PipeOD: Float64 = 0.0
            var ViscositySet: Bool = False
            var CoefSet: Bool = False
            if self.Type == DataPlant.PlantEquipmentType.PipeInterior:
                if self.EnvironmentPtr == EnvrnPtr.ScheduleEnv:
                    AirTemp = self.envrSched.getCurrentVal()
                    AirVel = self.envrVelSched.getCurrentVal()
                elif self.EnvironmentPtr == EnvrnPtr.ZoneEnv:
                    AirTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.EnvrZonePtr].MAT
                    AirVel = RoomAirVel
            elif self.Type == DataPlant.PlantEquipmentType.PipeExterior:
                if self.EnvironmentPtr == EnvrnPtr.OutsideAirEnv:
                    AirTemp = state.dataLoopNodes.Node[self.EnvrAirNodeNum].Temp
                    AirVel = state.dataEnvrn.WindSpeed
            PipeOD = self.InsulationOD
            ViscositySet = False
            for idx in range(NumOfPropDivisions):
                if AirTemp <= Temperature[idx]:
                    AirVisc = DynVisc[idx]
                    ViscositySet = True
                    break
            if not ViscositySet:
                AirVisc = DynVisc[NumOfPropDivisions - 1]
                if AirTemp > Temperature[NumOfPropDivisions - 1]:
                    ShowWarningError(state, "Heat Transfer Pipe = {}Viscosity out of range, air temperature too high, setting to upper limit.".format(self.Name))
            CoefSet = False
            if AirVisc > 0.0:
                ReD = AirVel * PipeOD / AirVisc
            for idx in range(NumOfParamDivisions):
                if ReD <= UpperBound[idx]:
                    Coef = CCoef[idx]
                    rExp = mExp[idx]
                    CoefSet = True
                    break
            if not CoefSet:
                Coef = CCoef[NumOfParamDivisions - 1]
                rExp = mExp[NumOfParamDivisions - 1]
                if ReD > UpperBound[NumOfParamDivisions - 1]:
                    ShowWarningError(state, "Heat Transfer Pipe = {}Reynolds Number out of range, setting coefficients to upper limit.".format(self.Name))
            NuD = Coef * pow(ReD, rExp) * pow(Pr, 1.0 / 3.0)
            NuD = max(NuD, NaturalConvNusselt)
            OutsidePipeHeatTransCoef = CondAir * NuD / PipeOD
            return OutsidePipeHeatTransCoef

        def TBND(inout self, state: EnergyPlusData, z: Float64) -> Float64:
            var curSimTime: Float64 = state.dataGlobal.DayOfSim * Constant.rSecsInDay
            return self.groundTempModel.getGroundTempAtTimeInSeconds(state, z, curSimTime)

        def oneTimeInit(inout self, state: EnergyPlusData):

    enum PipeIndoorBoundaryType:
        Invalid = -1
        Zone = 0
        Schedule = 1
        Num = 2

    const pipeIndoorBoundaryTypeNamesUC: List[String] = ["ZONE", "SCHEDULE"]

struct PipeHeatTransferData(BaseGlobalStruct):
    var nsvNumOfPipeHT: Int32 = 0
    var nsvInletNodeNum: Int32 = 0
    var nsvOutletNodeNum: Int32 = 0
    var nsvMassFlowRate: Float64 = 0.0
    var nsvVolumeFlowRate: Float64 = 0.0
    var nsvDeltaTime: Float64 = 0.0
    var nsvInletTemp: Float64 = 0.0
    var nsvOutletTemp: Float64 = 0.0
    var nsvEnvironmentTemp: Float64 = 0.0
    var nsvEnvHeatLossRate: Float64 = 0.0
    var nsvFluidHeatLossRate: Float64 = 0.0
    var nsvNumInnerTimeSteps: Int32 = 0
    var GetPipeInputFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var PipeHT: List[PipeHeatTransfer.PipeHTData]
    var PipeHTUniqueNames: Dict[String, String]

    def init_constant_state(state: EnergyPlusData):

    def init_state(state: EnergyPlusData):

    def clear_state(inout self):
        self.nsvNumOfPipeHT = 0
        self.nsvInletNodeNum = 0
        self.nsvOutletNodeNum = 0
        self.nsvMassFlowRate = 0.0
        self.nsvVolumeFlowRate = 0.0
        self.nsvDeltaTime = 0.0
        self.nsvInletTemp = 0.0
        self.nsvOutletTemp = 0.0
        self.nsvEnvironmentTemp = 0.0
        self.nsvEnvHeatLossRate = 0.0
        self.nsvFluidHeatLossRate = 0.0
        self.nsvNumInnerTimeSteps = 0
        self.GetPipeInputFlag = True
        self.MyEnvrnFlag = True
        self.PipeHT.deallocate()
        self.PipeHTUniqueNames.clear()