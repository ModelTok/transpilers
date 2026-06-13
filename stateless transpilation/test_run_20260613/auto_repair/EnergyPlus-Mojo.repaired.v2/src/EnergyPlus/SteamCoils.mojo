// Header part (combined from SteamCoils.hh and SteamCoils.cc)
from Data.BaseData import BaseGlobalStruct
from DataGlobals import ...
from EnergyPlus import ...
from FluidProperties import ...
from Psychrometrics import PsyRhoAirFnPbTdbW, PsyCpAirFnW, PsyHFnTdbW
from PlantUtilities import MyPlantSizingIndex, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode, RegisterPlantCompDesignFlow
from ScheduleManager import Sched
from FaultsManager import ...
from DataLoopNode import Node
from DataHVACGlobals import HVAC
from DataEnvironment import ...
from DataSizing import ...
from BranchNodeConnections import TestCompSet
from NodeInputManager import GetOnlySingleNode
from OutputProcessor import SetupOutputVariable
from GlobalNames import VerifyUniqueCoilName
from GeneralRoutines import ...
from .InputProcessing.InputProcessor import ...
from Plant.DataPlant import PlantLocation, DataPlant
from Fans import ...
from .Autosizing.All_Simple_Sizing import HeatingCoilDesAirInletTempSizer, HeatingCoilDesAirOutletTempSizer
from .Autosizing.HeatingAirFlowSizing import HeatingAirFlowSizer
from ReportCoilSelection import ReportCoilSelection
from UtilityRoutines import Util
from DataContaminantBalance import ...
from <ObjexxFCL/Array.functions> import ...
from <ObjexxFCL/Optional> import Optional as ObjexxOptional

# Use Mojo's builtin Optional for compatibility
alias Optional = builtin.Optional

# Namespace SteamCoils
enum CoilControlType:
    Invalid = -1
    TemperatureSetPoint = 0
    ZoneLoadControl = 1
    Num = 2

let coilControlTypeNames: List[StringLiteral] = ["TEMPERATURESETPOINTCONTROL", "ZONELOADCONTROL"]

struct SteamCoilEquipConditions:
    var Name: String = ""
    var coilType: HVAC.CoilType = HVAC.CoilType.Invalid
    var coilReportNum: Int = -1
    var availSched: Optional[Sched.Schedule] = None # use Optional
    var InletAirMassFlowRate: Float64 = 0.0
    var OutletAirMassFlowRate: Float64 = 0.0
    var InletAirTemp: Float64 = 0.0
    var OutletAirTemp: Float64 = 0.0
    var InletAirHumRat: Float64 = 0.0
    var OutletAirHumRat: Float64 = 0.0
    var InletAirEnthalpy: Float64 = 0.0
    var OutletAirEnthalpy: Float64 = 0.0
    var TotSteamCoilLoad: Float64 = 0.0
    var SenSteamCoilLoad: Float64 = 0.0
    var TotSteamHeatingCoilEnergy: Float64 = 0.0
    var TotSteamCoolingCoilEnergy: Float64 = 0.0
    var SenSteamCoolingCoilEnergy: Float64 = 0.0
    var TotSteamHeatingCoilRate: Float64 = 0.0
    var LoopLoss: Float64 = 0.0
    var TotSteamCoolingCoilRate: Float64 = 0.0
    var SenSteamCoolingCoilRate: Float64 = 0.0
    var LeavingRelHum: Float64 = 0.0
    var DesiredOutletTemp: Float64 = 0.0
    var DesiredOutletHumRat: Float64 = 0.0
    var InletSteamTemp: Float64 = 0.0
    var OutletSteamTemp: Float64 = 0.0
    var InletSteamMassFlowRate: Float64 = 0.0
    var OutletSteamMassFlowRate: Float64 = 0.0
    var MaxSteamVolFlowRate: Float64 = 0.0
    var MaxSteamMassFlowRate: Float64 = 0.0
    var InletSteamEnthalpy: Float64 = 0.0
    var OutletWaterEnthalpy: Float64 = 0.0
    var InletSteamPress: Float64 = 0.0
    var InletSteamQuality: Float64 = 0.0
    var OutletSteamQuality: Float64 = 0.0
    var DegOfSubcooling: Float64 = 0.0
    var LoopSubcoolReturn: Float64 = 0.0
    var AirInletNodeNum: Int = 0
    var AirOutletNodeNum: Int = 0
    var SteamInletNodeNum: Int = 0
    var SteamOutletNodeNum: Int = 0
    var TempSetPointNodeNum: Int = 0
    var TypeOfCoil: CoilControlType = CoilControlType.Invalid
    var steam: Optional[Fluid.RefrigProps] = None
    var plantLoc: PlantLocation = PlantLocation()
    var CoilType: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var OperatingCapacity: Float64 = 0.0
    var DesiccantRegenerationCoil: Bool = False
    var DesiccantDehumNum: Int = 0
    var FaultyCoilSATFlag: Bool = False
    var FaultyCoilSATIndex: Int = 0
    var FaultyCoilSATOffset: Float64 = 0.0
    var reportCoilFinalSizes: Bool = True
    var DesCoilCapacity: Float64 = 0.0
    var DesAirVolFlow: Float64 = 0.0

    def __init__(inout self):
        # Already defaults set

# SteamCoilsData struct (from header)
struct SteamCoilsData(BaseGlobalStruct):
    var NumSteamCoils: Int = 0
    var MySizeFlag: List[Bool] = List[Bool]()
    var CoilWarningOnceFlag: List[Bool] = List[Bool]()
    var CheckEquipName: List[Bool] = List[Bool]()
    var GetSteamCoilsInputFlag: Bool = True
    var MyOneTimeFlag: Bool = True
    var MyEnvrnFlag: List[Bool] = List[Bool]()
    var MyPlantScanFlag: List[Bool] = List[Bool]()
    var ErrCount: Int = 0
    var SteamCoil: List[SteamCoilEquipConditions] = List[SteamCoilEquipConditions]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = SteamCoilsData()

# Functions

def SimulateSteamCoilComponents(
    inout state: EnergyPlusData,
    CompName: StringLiteral,
    FirstHVACIteration: Bool,
    inout CompIndex: Int,
    QCoilReq: Optional[Float64] = None,
    QCoilActual: Optional[Float64] = None,
    fanOpMode: Optional[HVAC.FanOp] = None,
    PartLoadRatio: Optional[Float64] = None
):
    var QCoilActualTemp: Float64 = 0.0
    var CoilNum: Int = 0
    var fanOp: HVAC.FanOp = HVAC.FanOp.Continuous
    var PartLoadFrac: Float64 = 1.0
    var QCoilReqLocal: Float64 = 0.0

    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False

    if CompIndex == 0:
        CoilNum = Util.FindItemInList(CompName, state.dataSteamCoils.SteamCoil)
        if CoilNum == 0:
            ShowFatalError(state, "SimulateSteamCoilComponents: Coil not found={}".format(CompName))
        CompIndex = CoilNum
    else:
        CoilNum = CompIndex
        if CoilNum > state.dataSteamCoils.NumSteamCoils or CoilNum < 1:
            ShowFatalError(state, "SimulateSteamCoilComponents: Invalid CompIndex passed={}, Number of Steam Coils={}, Coil name={}".format(
                CoilNum, state.dataSteamCoils.NumSteamCoils, CompName
            ))
        if state.dataSteamCoils.CheckEquipName[CoilNum - 1]:
            if CompName != state.dataSteamCoils.SteamCoil[CoilNum - 1].Name:
                ShowFatalError(state, "SimulateSteamCoilComponents: Invalid CompIndex passed={}, Coil name={}, stored Coil Name for that index={}".format(
                    CoilNum, CompName, state.dataSteamCoils.SteamCoil[CoilNum - 1].Name
                ))
            state.dataSteamCoils.CheckEquipName[CoilNum - 1] = False

    InitSteamCoil(state, CoilNum, FirstHVACIteration)

    if fanOpMode.is_some():
        fanOp = fanOpMode.value()
    else:
        fanOp = HVAC.FanOp.Continuous

    if PartLoadRatio.is_some():
        PartLoadFrac = PartLoadRatio.value()
    else:
        PartLoadFrac = 1.0

    if QCoilReq.is_some():
        QCoilReqLocal = QCoilReq.value()
    else:
        QCoilReqLocal = 0.0

    CalcSteamAirCoil(state, CoilNum, QCoilReqLocal, QCoilActualTemp, fanOp, PartLoadFrac)

    if QCoilActual.is_some():
        QCoilActual = QCoilActualTemp

    UpdateSteamCoil(state, CoilNum)
    ReportSteamCoil(state, CoilNum)


def GetSteamCoilInput(inout state: EnergyPlusData):
    # use GlobalNames::VerifyUniqueCoilName, Node::GetOnlySingleNode, Node::TestCompSet
    # static string_view RoutineName("GetSteamCoilInput: ");
    # static string_view routineName = "GetSteamCoilInput";
    var CoilNum: Int
    var NumStmHeat: Int
    var StmHeatNum: Int
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String = "Coil:Heating:Steam"
    var AlphArray: List[String] = List[String]()
    var cAlphaFields: List[String] = List[String]()
    var cNumericFields: List[String] = List[String]()
    var NumArray: List[Float64] = List[Float64]()
    var lAlphaBlanks: List[Bool] = List[Bool]()
    var lNumericBlanks: List[Bool] = List[Bool]()
    var TotalArgs: Int = 0

    NumStmHeat = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataSteamCoils.NumSteamCoils = NumStmHeat
    if state.dataSteamCoils.NumSteamCoils > 0:
        # allocate SteamCoil
        state.dataSteamCoils.SteamCoil = List[SteamCoilEquipConditions](repeating=SteamCoilEquipConditions(), length=state.dataSteamCoils.NumSteamCoils)
        # CheckEquipName dimension
        state.dataSteamCoils.CheckEquipName = List[Bool](repeating=True, length=state.dataSteamCoils.NumSteamCoils)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNums)
    AlphArray = List[String](repeating="", length=NumAlphas)
    cAlphaFields = List[String](repeating="", length=NumAlphas)
    cNumericFields = List[String](repeating="", length=NumNums)
    NumArray = List[Float64](repeating=0.0, length=NumNums)
    lAlphaBlanks = List[Bool](repeating=True, length=NumAlphas)
    lNumericBlanks = List[Bool](repeating=True, length=NumNums)

    for StmHeatNum in range(1, NumStmHeat + 1):
        CoilNum = StmHeatNum
        # getObjectItem
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, StmHeatNum,
            AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields
        )
        var eoh = ErrorObjectHeader(routineName="GetSteamCoilInput", CurrentModuleObject, AlphArray[0])
        VerifyUniqueCoilName(state, CurrentModuleObject, AlphArray[0], ErrorsFound, CurrentModuleObject + " Name")
        var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
        steamCoil.Name = AlphArray[0]
        steamCoil.coilType = HVAC.CoilType.HeatingSteam
        steamCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, steamCoil.Name, steamCoil.coilType)
        if lAlphaBlanks[1]:
            steamCoil.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched.GetSchedule(state, AlphArray[1])
            if sched.is_none():
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], AlphArray[1])
                ErrorsFound = True
            else:
                steamCoil.availSched = sched
        steamCoil.CoilType = DataPlant.PlantEquipmentType.CoilSteamAirHeating
        steamCoil.MaxSteamVolFlowRate = NumArray[0]
        steamCoil.DegOfSubcooling = NumArray[1]
        steamCoil.LoopSubcoolReturn = NumArray[2]
        steamCoil.SteamInletNodeNum = GetOnlySingleNode(state,
            AlphArray[2], ErrorsFound,
            Node.ConnectionObjectType.CoilHeatingSteam,
            AlphArray[0],
            Node.FluidType.Steam,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Secondary,
            Node.ObjectIsNotParent)
        steamCoil.SteamOutletNodeNum = GetOnlySingleNode(state,
            AlphArray[3], ErrorsFound,
            Node.ConnectionObjectType.CoilHeatingSteam,
            AlphArray[0],
            Node.FluidType.Steam,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Secondary,
            Node.ObjectIsNotParent)
        steamCoil.AirInletNodeNum = GetOnlySingleNode(state,
            AlphArray[4], ErrorsFound,
            Node.ConnectionObjectType.CoilHeatingSteam,
            AlphArray[0],
            Node.FluidType.Air,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        steamCoil.AirOutletNodeNum = GetOnlySingleNode(state,
            AlphArray[5], ErrorsFound,
            Node.ConnectionObjectType.CoilHeatingSteam,
            AlphArray[0],
            Node.FluidType.Air,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        var controlMode = Util.makeUPPER(AlphArray[6])
        # getEnumValue: assume function exists
        steamCoil.TypeOfCoil = CoilControlType(getEnumValue(coilControlTypeNames, controlMode))
        if steamCoil.TypeOfCoil == CoilControlType.TemperatureSetPoint:
            steamCoil.TempSetPointNodeNum = GetOnlySingleNode(state,
                AlphArray[7], ErrorsFound,
                Node.ConnectionObjectType.CoilHeatingSteam,
                AlphArray[0],
                Node.FluidType.Air,
                Node.ConnectionType.Sensor,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent)
            if steamCoil.TempSetPointNodeNum == 0:
                ShowSevereError(state, "GetSteamCoilInput: {} not found for {} = {}".format(cAlphaFields[7], CurrentModuleObject, AlphArray[0]))
                ShowContinueError(state, "..required for Temperature Setpoint Controlled Coils.")
                ErrorsFound = True
        elif steamCoil.TypeOfCoil == CoilControlType.ZoneLoadControl:
            if not lAlphaBlanks[7]:
                ShowWarningError(state, "GetSteamCoilInput: ZoneLoad Controlled Coil, so {} not needed".format(cAlphaFields[7]))
                ShowContinueError(state, "for {} = {}".format(CurrentModuleObject, AlphArray[0]))
                steamCoil.TempSetPointNodeNum = 0
        else:
            ShowSevereError(state, "GetSteamCoilInput: Invalid {} [{}] specified for {} = {}".format(
                cAlphaFields[6], AlphArray[6], CurrentModuleObject, AlphArray[0]
            ))
            ErrorsFound = True

        TestCompSet(state, CurrentModuleObject, AlphArray[0], AlphArray[2], AlphArray[3], "Steam Nodes")
        TestCompSet(state, CurrentModuleObject, AlphArray[0], AlphArray[4], AlphArray[5], "Air Nodes")
        steamCoil.steam = Fluid.GetSteam(state)
        if steamCoil.steam.is_none() and CoilNum == 1:
            ShowSevereError(state, "GetSteamCoilInput: Steam Properties for {} not found.".format(AlphArray[0]))
            ShowContinueError(state, "Steam Fluid Properties should have been included in the input file.")
            ErrorsFound = True

    for CoilNum in range(1, NumStmHeat + 1):
        var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
        SetupOutputVariable(state,
            "Heating Coil Heating Energy",
            Constant.Units.J,
            steamCoil.TotSteamHeatingCoilEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            steamCoil.Name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.HeatingCoils)
        SetupOutputVariable(state,
            "Heating Coil Heating Rate",
            Constant.Units.W,
            steamCoil.TotSteamHeatingCoilRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            steamCoil.Name)
        SetupOutputVariable(state,
            "Heating Coil Steam Mass Flow Rate",
            Constant.Units.kg_s,
            steamCoil.OutletSteamMassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            steamCoil.Name)
        SetupOutputVariable(state,
            "Heating Coil Steam Inlet Temperature",
            Constant.Units.C,
            steamCoil.InletSteamTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            steamCoil.Name)
        SetupOutputVariable(state,
            "Heating Coil Steam Outlet Temperature",
            Constant.Units.C,
            steamCoil.OutletSteamTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            steamCoil.Name)
        SetupOutputVariable(state,
            "Heating Coil Steam Trap Loss Rate",
            Constant.Units.W,
            steamCoil.LoopLoss,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            steamCoil.Name)

    if ErrorsFound:
        ShowFatalError(state, "GetSteamCoilInput: Errors found in getting input.".format())

    # Deallocate not needed (Mojo GC)


def InitSteamCoil(inout state: EnergyPlusData, CoilNum: Int, FirstHVACIteration: Bool):
    # using PlantUtilities::InitComponentNodes;
    # static string_view RoutineName("InitSteamCoil");
    var AirInletNode: Int
    var SteamInletNode: Int
    var ControlNode: Int
    var AirOutletNode: Int
    var SteamDensity: Float64
    var StartEnthSteam: Float64

    if state.dataSteamCoils.MyOneTimeFlag:
        state.dataSteamCoils.MyEnvrnFlag = List[Bool](repeating=True, length=state.dataSteamCoils.NumSteamCoils)
        state.dataSteamCoils.MySizeFlag = List[Bool](repeating=True, length=state.dataSteamCoils.NumSteamCoils)
        state.dataSteamCoils.CoilWarningOnceFlag = List[Bool](repeating=True, length=state.dataSteamCoils.NumSteamCoils)
        state.dataSteamCoils.MyPlantScanFlag = List[Bool](repeating=True, length=state.dataSteamCoils.NumSteamCoils)
        state.dataSteamCoils.MyOneTimeFlag = False

    var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
    if state.dataSteamCoils.MyPlantScanFlag[CoilNum - 1] and (state.dataPlnt.PlantLoop is not None):
        var errFlag: Bool = False
        ScanPlantLoopsForObject(state, steamCoil.Name, steamCoil.CoilType, steamCoil.plantLoc, errFlag, None, None, None, None, None)
        if errFlag:
            ShowFatalError(state, "InitSteamCoil: Program terminated for previous conditions.")
        state.dataSteamCoils.MyPlantScanFlag[CoilNum - 1] = False

    if not state.dataGlobal.SysSizingCalc and state.dataSteamCoils.MySizeFlag[CoilNum - 1]:
        SizeSteamCoil(state, CoilNum)
        state.dataSteamCoils.MySizeFlag[CoilNum - 1] = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataSteamCoils.MyEnvrnFlag[CoilNum - 1]:
        steamCoil.TotSteamHeatingCoilEnergy = 0.0
        steamCoil.TotSteamCoolingCoilEnergy = 0.0
        steamCoil.SenSteamCoolingCoilEnergy = 0.0
        steamCoil.TotSteamHeatingCoilRate = 0.0
        steamCoil.TotSteamCoolingCoilRate = 0.0
        steamCoil.SenSteamCoolingCoilRate = 0.0
        steamCoil.InletAirMassFlowRate = 0.0
        steamCoil.OutletAirMassFlowRate = 0.0
        steamCoil.InletAirTemp = 0.0
        steamCoil.OutletAirTemp = 0.0
        steamCoil.InletAirHumRat = 0.0
        steamCoil.OutletAirHumRat = 0.0
        steamCoil.InletAirEnthalpy = 0.0
        steamCoil.OutletAirEnthalpy = 0.0
        steamCoil.TotSteamCoilLoad = 0.0
        steamCoil.SenSteamCoilLoad = 0.0
        steamCoil.LoopLoss = 0.0
        steamCoil.LeavingRelHum = 0.0
        steamCoil.DesiredOutletTemp = 0.0
        steamCoil.DesiredOutletHumRat = 0.0
        steamCoil.InletSteamTemp = 0.0
        steamCoil.OutletSteamTemp = 0.0
        steamCoil.InletSteamMassFlowRate = 0.0
        steamCoil.OutletSteamMassFlowRate = 0.0
        steamCoil.InletSteamEnthalpy = 0.0
        steamCoil.OutletWaterEnthalpy = 0.0
        steamCoil.InletSteamPress = 0.0
        steamCoil.InletSteamQuality = 0.0
        steamCoil.OutletSteamQuality = 0.0
        SteamInletNode = steamCoil.SteamInletNodeNum
        state.dataLoopNodes.Node[SteamInletNode - 1].Temp = 100.0
        state.dataLoopNodes.Node[SteamInletNode - 1].Press = 101325.0
        var steam = Fluid.GetSteam(state)
        SteamDensity = steam.getSatDensity(state, state.dataLoopNodes.Node[SteamInletNode - 1].Temp, 1.0, "InitSteamCoil")
        StartEnthSteam = steam.getSatEnthalpy(state, state.dataLoopNodes.Node[SteamInletNode - 1].Temp, 1.0, "InitSteamCoil")
        state.dataLoopNodes.Node[SteamInletNode - 1].Enthalpy = StartEnthSteam
        state.dataLoopNodes.Node[SteamInletNode - 1].Quality = 1.0
        state.dataLoopNodes.Node[SteamInletNode - 1].HumRat = 0.0
        steamCoil.MaxSteamMassFlowRate = SteamDensity * steamCoil.MaxSteamVolFlowRate
        InitComponentNodes(state, 0.0, steamCoil.MaxSteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum)
        state.dataSteamCoils.MyEnvrnFlag[CoilNum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataSteamCoils.MyEnvrnFlag[CoilNum - 1] = True

    AirInletNode = steamCoil.AirInletNodeNum
    SteamInletNode = steamCoil.SteamInletNodeNum
    ControlNode = steamCoil.TempSetPointNodeNum
    AirOutletNode = steamCoil.AirOutletNodeNum

    if ControlNode == 0:
        steamCoil.DesiredOutletTemp = 0.0
    elif ControlNode == AirOutletNode:
        steamCoil.DesiredOutletTemp = state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint
    else:
        steamCoil.DesiredOutletTemp = state.dataLoopNodes.Node[ControlNode - 1].TempSetPoint - \
            (state.dataLoopNodes.Node[ControlNode - 1].Temp - state.dataLoopNodes.Node[AirOutletNode - 1].Temp)

    steamCoil.InletAirMassFlowRate = state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRate
    steamCoil.InletAirTemp = state.dataLoopNodes.Node[AirInletNode - 1].Temp
    steamCoil.InletAirHumRat = state.dataLoopNodes.Node[AirInletNode - 1].HumRat
    steamCoil.InletAirEnthalpy = state.dataLoopNodes.Node[AirInletNode - 1].Enthalpy

    if FirstHVACIteration:
        steamCoil.InletSteamMassFlowRate = steamCoil.MaxSteamMassFlowRate
    else:
        steamCoil.InletSteamMassFlowRate = state.dataLoopNodes.Node[SteamInletNode - 1].MassFlowRate

    steamCoil.InletSteamTemp = state.dataLoopNodes.Node[SteamInletNode - 1].Temp
    steamCoil.InletSteamEnthalpy = state.dataLoopNodes.Node[SteamInletNode - 1].Enthalpy
    steamCoil.InletSteamPress = state.dataLoopNodes.Node[SteamInletNode - 1].Press
    steamCoil.InletSteamQuality = state.dataLoopNodes.Node[SteamInletNode - 1].Quality
    steamCoil.TotSteamHeatingCoilRate = 0.0
    steamCoil.TotSteamCoolingCoilRate = 0.0
    steamCoil.SenSteamCoolingCoilRate = 0.0


def SizeSteamCoil(inout state: EnergyPlusData, CoilNum: Int):
    # using namespace DataSizing;
    # using PlantUtilities::RegisterPlantCompDesignFlow;
    # static string_view RoutineName("SizeSteamCoil");
    var PltSizNum: Int = 0
    var PltSizSteamNum: Int = 0
    var ErrorsFound: Bool = False
    var CoilInTemp: Float64 = 0.0
    var CoilOutTemp: Float64 = 0.0
    var CoilOutHumRat: Float64 = 0.0
    var CoilInHumRat: Float64 = 0.0
    var DesCoilLoad: Float64 = 0.0
    var DesMassFlow: Float64 = 0.0
    var DesVolFlow: Float64 = 0.0
    var MinFlowFrac: Float64 = 0.0
    var OutAirFrac: Float64 = 0.0
    var TempSteamIn: Float64 = 100.0
    var EnthSteamInDry: Float64 = 0.0
    var EnthSteamOutWet: Float64 = 0.0
    var LatentHeatSteam: Float64 = 0.0
    var SteamDensity: Float64 = 0.0
    var RhoAirStd: Float64 = 0.0
    var CpAirStd: Float64 = 0.0
    var CpWater: Float64 = 0.0
    var TempSize: Float64 = 0.0

    RhoAirStd = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, 20.0, 0.0)
    CpAirStd = PsyCpAirFnW(0.0)
    var coilWasAutosized: Bool = False
    var TermUnitSizing = state.dataSize.TermUnitSizing
    var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]

    if steamCoil.MaxSteamVolFlowRate == AutoSize:
        coilWasAutosized = True
        PltSizSteamNum = MyPlantSizingIndex(
            state, "steam heating coil", steamCoil.Name, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, ErrorsFound
        )

    if PltSizSteamNum > 0:
        if state.dataSize.CurSysNum > 0:
            var finalSysSizing = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1]
            if steamCoil.MaxSteamVolFlowRate == AutoSize:
                CheckSysSizing(state, "Coil:Heating:Steam", steamCoil.Name)
                var CompName: String = ""
                var CompType: String = ""
                var bPRINT: Bool = False
                if steamCoil.DesiccantRegenerationCoil:
                    state.dataSize.DataDesicRegCoil = True
                    state.dataSize.DataDesicDehumNum = steamCoil.DesiccantDehumNum
                    CompType = HVAC.coilTypeNames[int(steamCoil.coilType)]
                    CompName = steamCoil.Name
                    bPRINT = False
                    var sizerHeatingDesInletTemp = HeatingCoilDesAirInletTempSizer()
                    var localErrorsFound: Bool = False
                    sizerHeatingDesInletTemp.initializeWithinEP(state, CompType, CompName, bPRINT, "SizeSteamCoil")
                    state.dataSize.DataDesInletAirTemp = sizerHeatingDesInletTemp.size(state, DataSizing.AutoSize, localErrorsFound)
                    var sizerHeatingDesOutletTemp = HeatingCoilDesAirOutletTempSizer()
                    localErrorsFound = False
                    sizerHeatingDesOutletTemp.initializeWithinEP(state, CompType, CompName, bPRINT, "SizeSteamCoil")
                    state.dataSize.DataDesOutletAirTemp = sizerHeatingDesOutletTemp.size(state, DataSizing.AutoSize, localErrorsFound)
                    if state.dataSize.CurOASysNum > 0:
                        state.dataSize.OASysEqSizing[state.dataSize.CurOASysNum - 1].AirFlow = True
                        state.dataSize.OASysEqSizing[state.dataSize.CurOASysNum - 1].AirVolFlow = finalSysSizing.DesOutAirVolFlow
                    TempSize = AutoSize

                # switch equivalent
                var ductType = state.dataSize.CurDuctType
                if ductType == HVAC.AirDuctType.Main:
                    DesVolFlow = finalSysSizing.SysAirMinFlowRat * finalSysSizing.DesMainVolFlow
                elif ductType == HVAC.AirDuctType.Cooling:
                    DesVolFlow = finalSysSizing.SysAirMinFlowRat * finalSysSizing.DesCoolVolFlow
                elif ductType == HVAC.AirDuctType.Heating:
                    DesVolFlow = finalSysSizing.DesHeatVolFlow
                elif ductType == HVAC.AirDuctType.Other:
                    DesVolFlow = finalSysSizing.DesMainVolFlow
                else:
                    DesVolFlow = finalSysSizing.DesMainVolFlow

                if state.dataSize.DataDesicRegCoil:
                    bPRINT = False
                    TempSize = AutoSize
                    var errorsFound: Bool = False
                    var sizingHeatingAirFlow = HeatingAirFlowSizer()
                    var SizingString: String = ""
                    sizingHeatingAirFlow.overrideSizingString(SizingString)
                    sizingHeatingAirFlow.initializeWithinEP(state, CompType, CompName, bPRINT, "SizeSteamCoil")
                    DesVolFlow = sizingHeatingAirFlow.size(state, TempSize, errorsFound)

                DesMassFlow = RhoAirStd * DesVolFlow
                if finalSysSizing.HeatOAOption == DataSizing.OAControl.MinOA:
                    if DesVolFlow > 0.0:
                        OutAirFrac = finalSysSizing.DesOutAirVolFlow / DesVolFlow
                    else:
                        OutAirFrac = 1.0
                    OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                else:
                    OutAirFrac = 1.0

                if state.dataSize.DataDesicRegCoil:
                    DesCoilLoad = CpAirStd * DesMassFlow * (state.dataSize.DataDesOutletAirTemp - state.dataSize.DataDesInletAirTemp)
                else:
                    CoilInTemp = OutAirFrac * finalSysSizing.HeatOutTemp + (1.0 - OutAirFrac) * finalSysSizing.HeatRetTemp
                    DesCoilLoad = CpAirStd * DesMassFlow * (finalSysSizing.HeatSupTemp - CoilInTemp)

                if DesCoilLoad >= HVAC.SmallLoad:
                    TempSteamIn = 100.0
                    EnthSteamInDry = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 1.0, "SizeSteamCoil")
                    EnthSteamOutWet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "SizeSteamCoil")
                    LatentHeatSteam = EnthSteamInDry - EnthSteamOutWet
                    SteamDensity = steamCoil.steam.getSatDensity(state, TempSteamIn, 1.0, "SizeSteamCoil")
                    CpWater = steamCoil.steam.getSatSpecificHeat(state, TempSteamIn, 0.0, "SizeSteamCoil")
                    steamCoil.MaxSteamVolFlowRate = DesCoilLoad / (SteamDensity * (LatentHeatSteam + steamCoil.DegOfSubcooling * CpWater))
                else:
                    steamCoil.MaxSteamVolFlowRate = 0.0
                    ShowWarningError(state, "The design coil load is zero for COIL:Heating:Steam {}".format(steamCoil.Name))

                BaseSizer.reportSizerOutput(
                    state, "Coil:Heating:Steam", steamCoil.Name, "Maximum Steam Flow Rate [m3/s]", steamCoil.MaxSteamVolFlowRate
                )

            state.dataSize.DataDesicRegCoil = False
            if state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].supFanNum > 0:
                ReportCoilSelection.setCoilSupplyFanInfo(
                    state,
                    steamCoil.coilReportNum,
                    state.dataFans.fans[state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].supFanNum - 1].Name,
                    state.dataFans.fans[state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].supFanNum - 1].type,
                    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].supFanNum
                )

        elif state.dataSize.CurZoneEqNum > 0:
            CheckZoneSizing(state, "Coil:Heating:Steam", steamCoil.Name)
            if steamCoil.MaxSteamVolFlowRate == AutoSize:
                if state.dataSize.TermUnitSingDuct or state.dataSize.TermUnitPIU or state.dataSize.TermUnitIU:
                    if state.dataSize.CurTermUnitSizingNum > 0:
                        steamCoil.MaxSteamVolFlowRate = TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].MaxSTVolFlow
                    else:
                        steamCoil.MaxSteamVolFlowRate = 0.0
                    DesCoilLoad = TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatingLoad
                    DesVolFlow = TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].AirVolFlow * \
                                 TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].ReheatAirFlowMult
                else:
                    CoilInTemp = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInTemp
                    CoilOutTemp = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesTemp
                    CoilOutHumRat = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesHumRat
                    DesMassFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatMassFlow
                    DesVolFlow = DesMassFlow / RhoAirStd
                    DesCoilLoad = PsyCpAirFnW(CoilOutHumRat) * DesMassFlow * (CoilOutTemp - CoilInTemp)
                    if DesCoilLoad >= HVAC.SmallLoad:
                        TempSteamIn = 100.0
                        EnthSteamInDry = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 1.0, "SizeSteamCoil")
                        EnthSteamOutWet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "SizeSteamCoil")
                        LatentHeatSteam = EnthSteamInDry - EnthSteamOutWet
                        SteamDensity = steamCoil.steam.getSatDensity(state, TempSteamIn, 1.0, "SizeSteamCoil")
                        CpWater = steamCoil.steam.getSatSpecificHeat(state, TempSteamIn, 0.0, "SizeSteamCoil")
                        steamCoil.MaxSteamVolFlowRate = DesCoilLoad / (SteamDensity * (LatentHeatSteam + steamCoil.DegOfSubcooling * CpWater))
                    else:
                        steamCoil.MaxSteamVolFlowRate = 0.0

                if steamCoil.MaxSteamVolFlowRate == 0.0:
                    ShowWarningError(state, "The design coil load is zero for COIL:Heating:Steam {}".format(steamCoil.Name))
                    ShowContinueError(state, "The autosize value for max Steam flow rate is zero")
                BaseSizer.reportSizerOutput(
                    state, "Coil:Heating:Steam", steamCoil.Name, "Maximum Steam Flow Rate [m3/s]", steamCoil.MaxSteamVolFlowRate
                )

    else:
        if steamCoil.MaxSteamVolFlowRate == AutoSize:
            ShowSevereError(state, "Autosizing of Steam coil requires a heating loop Sizing:Plant object")
            ShowContinueError(state, "Occurs in Steam coil object= {}".format(steamCoil.Name))
            ErrorsFound = True

    RegisterPlantCompDesignFlow(state, steamCoil.SteamInletNodeNum, steamCoil.MaxSteamVolFlowRate)

    ReportCoilSelection.setCoilHeatingCapacity(
        state, steamCoil.coilReportNum, DesCoilLoad, coilWasAutosized,
        state.dataSize.CurSysNum, state.dataSize.CurZoneEqNum, state.dataSize.CurOASysNum,
        0.0, 1.0, -999.0, -999.0
    )
    ReportCoilSelection.setCoilWaterFlowNodeNums(
        state, steamCoil.coilReportNum, steamCoil.MaxSteamVolFlowRate, coilWasAutosized,
        steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc.loopNum
    )
    ReportCoilSelection.setCoilWaterHeaterCapacityNodeNums(
        state, steamCoil.coilReportNum, DesCoilLoad, coilWasAutosized,
        steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc.loopNum
    )
    ReportCoilSelection.setCoilEntWaterTemp(state, steamCoil.coilReportNum, TempSteamIn)
    ReportCoilSelection.setCoilLvgWaterTemp(state, steamCoil.coilReportNum, TempSteamIn - steamCoil.DegOfSubcooling)
    ReportCoilSelection.setCoilWaterDeltaT(state, steamCoil.coilReportNum, steamCoil.DegOfSubcooling)

    steamCoil.DesCoilCapacity = DesCoilLoad
    steamCoil.DesAirVolFlow = DesVolFlow

    if ErrorsFound:
        ShowFatalError(state, "Preceding Steam coil sizing errors cause program termination")

    ReportCoilSelection.setRatedCoilConditions(
        state, steamCoil.coilReportNum, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0, -999.0
    )


def CalcSteamAirCoil(
    inout state: EnergyPlusData,
    CoilNum: Int,
    QCoilRequested: Float64,
    inout QCoilActual: Float64,
    fanOp: HVAC.FanOp,
    PartLoadRatio: Float64
):
    # using HVAC::TempControlTol;
    # using PlantUtilities::SetComponentFlowRate;
    # static string_view RoutineName("CalcSteamAirCoil");
    # static string_view RoutineNameSizeSteamCoil("SizeSteamCoil");
    var SteamMassFlowRate: Float64 = 0.0
    var AirMassFlow: Float64 = 0.0
    var TempAirIn: Float64 = 0.0
    var TempAirOut: Float64 = 0.0
    var Win: Float64 = 0.0
    var TempSteamIn: Float64 = 0.0
    var TempWaterOut: Float64 = 0.0
    var CapacitanceAir: Float64 = 0.0
    var HeatingCoilLoad: Float64 = 0.0
    var CoilPress: Float64 = 0.0
    var EnthSteamInDry: Float64 = 0.0
    var EnthSteamOutWet: Float64 = 0.0
    var LatentHeatSteam: Float64 = 0.0
    var SubcoolDeltaTemp: Float64 = 0.0
    var TempSetPoint: Float64 = 0.0
    var QCoilReq: Float64 = 0.0
    var QCoilCap: Float64 = 0.0
    var QSteamCoilMaxHT: Float64 = 0.0
    var TempWaterAtmPress: Float64 = 0.0
    var TempLoopOutToPump: Float64 = 0.0
    var EnergyLossToEnvironment: Float64 = 0.0
    var EnthCoilOutlet: Float64 = 0.0
    var EnthPumpInlet: Float64 = 0.0
    var EnthAtAtmPress: Float64 = 0.0
    var CpWater: Float64 = 0.0

    var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
    QCoilReq = QCoilRequested
    TempAirIn = steamCoil.InletAirTemp
    Win = steamCoil.InletAirHumRat
    TempSteamIn = steamCoil.InletSteamTemp
    CoilPress = steamCoil.InletSteamPress
    SubcoolDeltaTemp = steamCoil.DegOfSubcooling
    TempSetPoint = steamCoil.DesiredOutletTemp

    if steamCoil.FaultyCoilSATFlag and (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing) and \
        (not state.dataGlobal.KickOffSimulation):
        var FaultIndex = steamCoil.FaultyCoilSATIndex
        steamCoil.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[FaultIndex].CalFaultOffsetAct(state)
        TempSetPoint -= steamCoil.FaultyCoilSATOffset

    if fanOp == HVAC.FanOp.Cycling:
        if PartLoadRatio > 0.0:
            AirMassFlow = steamCoil.InletAirMassFlowRate / PartLoadRatio
            SteamMassFlowRate = min(steamCoil.InletSteamMassFlowRate / PartLoadRatio, steamCoil.MaxSteamMassFlowRate)
            QCoilReq /= PartLoadRatio
        else:
            AirMassFlow = 0.0
            SteamMassFlowRate = 0.0
    else:
        AirMassFlow = steamCoil.InletAirMassFlowRate
        SteamMassFlowRate = steamCoil.InletSteamMassFlowRate

    if AirMassFlow > 0.0:
        CapacitanceAir = PsyCpAirFnW(Win) * AirMassFlow
    else:
        CapacitanceAir = 0.0

    if steamCoil.TypeOfCoil == CoilControlType.ZoneLoadControl:
        if (CapacitanceAir > 0.0) and (steamCoil.InletSteamMassFlowRate > 0.0) and \
            (steamCoil.availSched.getCurrentVal() > 0.0 or state.dataSteamCoils.MySizeFlag[CoilNum - 1]) and (QCoilReq > 0.0):
            EnthSteamInDry = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 1.0, "CalcSteamAirCoil")
            EnthSteamOutWet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "CalcSteamAirCoil")
            LatentHeatSteam = EnthSteamInDry - EnthSteamOutWet
            CpWater = steamCoil.steam.getSatSpecificHeat(state, TempSteamIn, 0.0, "SizeSteamCoil")
            QSteamCoilMaxHT = steamCoil.MaxSteamMassFlowRate * (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
            steamCoil.OperatingCapacity = QSteamCoilMaxHT
            if QCoilReq > QSteamCoilMaxHT:
                QCoilCap = QSteamCoilMaxHT
            else:
                QCoilCap = QCoilReq
            SteamMassFlowRate = QCoilCap / (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
            SetComponentFlowRate(state, SteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc)
            QCoilCap = SteamMassFlowRate * (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
            TempWaterOut = TempSteamIn - SubcoolDeltaTemp
            HeatingCoilLoad = QCoilCap
            TempAirOut = TempAirIn + QCoilCap / (AirMassFlow * PsyCpAirFnW(Win))
            steamCoil.OutletSteamMassFlowRate = SteamMassFlowRate
            steamCoil.InletSteamMassFlowRate = SteamMassFlowRate
            TempWaterAtmPress = steamCoil.steam.getSatTemperature(state, state.dataEnvrn.StdBaroPress, "CalcSteamAirCoil")
            TempLoopOutToPump = TempWaterAtmPress - steamCoil.LoopSubcoolReturn
            EnthCoilOutlet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "CalcSteamAirCoil") - CpWater * SubcoolDeltaTemp
            EnthAtAtmPress = steamCoil.steam.getSatEnthalpy(state, TempWaterAtmPress, 0.0, "CalcSteamAirCoil")
            CpWater = steamCoil.steam.getSatSpecificHeat(state, TempLoopOutToPump, 0.0, "SizeSteamCoil")
            EnthPumpInlet = EnthAtAtmPress - CpWater * steamCoil.LoopSubcoolReturn
            steamCoil.OutletWaterEnthalpy = EnthPumpInlet
            EnergyLossToEnvironment = SteamMassFlowRate * (EnthCoilOutlet - EnthPumpInlet)
            steamCoil.LoopLoss = EnergyLossToEnvironment
        else:
            TempAirOut = TempAirIn
            TempWaterOut = TempSteamIn
            HeatingCoilLoad = 0.0
            steamCoil.OutletWaterEnthalpy = steamCoil.InletSteamEnthalpy
            steamCoil.OutletSteamMassFlowRate = 0.0
            steamCoil.OutletSteamQuality = 0.0
            steamCoil.LoopLoss = 0.0
            TempLoopOutToPump = TempWaterOut

    elif steamCoil.TypeOfCoil == CoilControlType.TemperatureSetPoint:
        if (CapacitanceAir > 0.0) and (steamCoil.InletSteamMassFlowRate > 0.0) and \
            (steamCoil.availSched.getCurrentVal() > 0.0 or state.dataSteamCoils.MySizeFlag[CoilNum - 1]) and \
            (abs(TempSetPoint - TempAirIn) > HVAC.TempControlTol):
            EnthSteamInDry = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 1.0, "CalcSteamAirCoil")
            EnthSteamOutWet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "CalcSteamAirCoil")
            LatentHeatSteam = EnthSteamInDry - EnthSteamOutWet
            CpWater = steamCoil.steam.getSatSpecificHeat(state, TempSteamIn, 0.0, "SizeSteamCoil")
            QSteamCoilMaxHT = steamCoil.MaxSteamMassFlowRate * (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
            QCoilCap = CapacitanceAir * (TempSetPoint - TempAirIn)
            if QCoilCap <= 0.0:
                QCoilCap = 0.0
                TempAirOut = TempAirIn
                SteamMassFlowRate = 0.0
                SetComponentFlowRate(state, SteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc)
                TempWaterOut = TempSteamIn
                HeatingCoilLoad = QCoilCap
                steamCoil.OutletWaterEnthalpy = steamCoil.InletSteamEnthalpy
                steamCoil.OutletSteamMassFlowRate = SteamMassFlowRate
                steamCoil.InletSteamMassFlowRate = SteamMassFlowRate
            elif QCoilCap > QSteamCoilMaxHT:
                QCoilCap = QSteamCoilMaxHT
                TempWaterOut = TempSteamIn - SubcoolDeltaTemp
                SteamMassFlowRate = QCoilCap / (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
                SetComponentFlowRate(state, SteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc)
                QCoilCap = SteamMassFlowRate * (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
                TempAirOut = TempAirIn + QCoilCap / (AirMassFlow * PsyCpAirFnW(Win))
                HeatingCoilLoad = QCoilCap
                steamCoil.OutletWaterEnthalpy = steamCoil.InletSteamEnthalpy - HeatingCoilLoad / SteamMassFlowRate
                steamCoil.OutletSteamMassFlowRate = SteamMassFlowRate
                steamCoil.InletSteamMassFlowRate = SteamMassFlowRate
            else:
                TempWaterOut = TempSteamIn - SubcoolDeltaTemp
                SteamMassFlowRate = QCoilCap / (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
                SetComponentFlowRate(state, SteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc)
                QCoilCap = SteamMassFlowRate * (LatentHeatSteam + SubcoolDeltaTemp * CpWater)
                TempAirOut = TempAirIn + QCoilCap / (AirMassFlow * PsyCpAirFnW(Win))
                HeatingCoilLoad = QCoilCap
                steamCoil.OutletSteamMassFlowRate = SteamMassFlowRate
                steamCoil.InletSteamMassFlowRate = SteamMassFlowRate
                TempWaterAtmPress = steamCoil.steam.getSatTemperature(state, state.dataEnvrn.StdBaroPress, "CalcSteamAirCoil")
                TempLoopOutToPump = TempWaterAtmPress - steamCoil.LoopSubcoolReturn
                EnthCoilOutlet = steamCoil.steam.getSatEnthalpy(state, TempSteamIn, 0.0, "CalcSteamAirCoil") - CpWater * SubcoolDeltaTemp
                EnthAtAtmPress = steamCoil.steam.getSatEnthalpy(state, TempWaterAtmPress, 0.0, "CalcSteamAirCoil")
                CpWater = steamCoil.steam.getSatSpecificHeat(state, TempLoopOutToPump, 0.0, "SizeSteamCoil")
                EnthPumpInlet = EnthAtAtmPress - CpWater * steamCoil.LoopSubcoolReturn
                steamCoil.OutletWaterEnthalpy = EnthPumpInlet
                EnergyLossToEnvironment = SteamMassFlowRate * (EnthCoilOutlet - EnthPumpInlet)
                steamCoil.LoopLoss = EnergyLossToEnvironment
        else:
            SteamMassFlowRate = 0.0
            SetComponentFlowRate(state, SteamMassFlowRate, steamCoil.SteamInletNodeNum, steamCoil.SteamOutletNodeNum, steamCoil.plantLoc)
            TempAirOut = TempAirIn
            TempWaterOut = TempSteamIn
            HeatingCoilLoad = 0.0
            steamCoil.OutletWaterEnthalpy = steamCoil.InletSteamEnthalpy
            steamCoil.OutletSteamMassFlowRate = 0.0
            steamCoil.OutletSteamQuality = 0.0
            steamCoil.LoopLoss = 0.0
            TempLoopOutToPump = TempWaterOut
    else:
        assert(False)

    if fanOp == HVAC.FanOp.Cycling:
        HeatingCoilLoad *= PartLoadRatio

    steamCoil.TotSteamHeatingCoilRate = HeatingCoilLoad
    steamCoil.OutletAirTemp = TempAirOut
    steamCoil.OutletSteamTemp = TempLoopOutToPump
    steamCoil.OutletSteamQuality = 0.0
    QCoilActual = HeatingCoilLoad
    steamCoil.OutletAirHumRat = steamCoil.InletAirHumRat
    steamCoil.OutletAirMassFlowRate = steamCoil.InletAirMassFlowRate
    steamCoil.OutletAirEnthalpy = PsyHFnTdbW(steamCoil.OutletAirTemp, steamCoil.OutletAirHumRat)


def UpdateSteamCoil(inout state: EnergyPlusData, CoilNum: Int):
    # using PlantUtilities::SafeCopyPlantNode;
    var AirInletNode: Int
    var SteamInletNode: Int
    var AirOutletNode: Int
    var SteamOutletNode: Int
    var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
    AirInletNode = steamCoil.AirInletNodeNum
    SteamInletNode = steamCoil.SteamInletNodeNum
    AirOutletNode = steamCoil.AirOutletNodeNum
    SteamOutletNode = steamCoil.SteamOutletNodeNum

    state.dataLoopNodes.Node[AirOutletNode - 1].MassFlowRate = steamCoil.OutletAirMassFlowRate
    state.dataLoopNodes.Node[AirOutletNode - 1].Temp = steamCoil.OutletAirTemp
    state.dataLoopNodes.Node[AirOutletNode - 1].HumRat = steamCoil.OutletAirHumRat
    state.dataLoopNodes.Node[AirOutletNode - 1].Enthalpy = steamCoil.OutletAirEnthalpy

    SafeCopyPlantNode(state, SteamInletNode, SteamOutletNode)
    state.dataLoopNodes.Node[SteamOutletNode - 1].Temp = steamCoil.OutletSteamTemp
    state.dataLoopNodes.Node[SteamOutletNode - 1].Enthalpy = steamCoil.OutletWaterEnthalpy
    state.dataLoopNodes.Node[SteamOutletNode - 1].Quality = steamCoil.OutletSteamQuality

    state.dataLoopNodes.Node[AirOutletNode - 1].Quality = state.dataLoopNodes.Node[AirInletNode - 1].Quality
    state.dataLoopNodes.Node[AirOutletNode - 1].Press = state.dataLoopNodes.Node[AirInletNode - 1].Press
    state.dataLoopNodes.Node[AirOutletNode - 1].MassFlowRateMin = state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMin
    state.dataLoopNodes.Node[AirOutletNode - 1].MassFlowRateMax = state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMax
    state.dataLoopNodes.Node[AirOutletNode - 1].MassFlowRateMinAvail = state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMinAvail
    state.dataLoopNodes.Node[AirOutletNode - 1].MassFlowRateMaxAvail = state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMaxAvail

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[AirOutletNode - 1].CO2 = state.dataLoopNodes.Node[AirInletNode - 1].CO2

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[AirOutletNode - 1].GenContam = state.dataLoopNodes.Node[AirInletNode - 1].GenContam


def ReportSteamCoil(inout state: EnergyPlusData, CoilNum: Int):
    var steamCoil = state.dataSteamCoils.SteamCoil[CoilNum - 1]
    steamCoil.TotSteamHeatingCoilEnergy = steamCoil.TotSteamHeatingCoilRate * state.dataHVACGlobal.TimeStepSysSec


def GetSteamCoilIndex(
    inout state: EnergyPlusData,
    CoilType: StringLiteral,
    CoilName: String,
    inout ErrorsFound: Bool
) -> Int:
    var IndexNum: Int = 0
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False

    if CoilType == "COIL:HEATING:STEAM":
        IndexNum = Util.FindItemInList(CoilName, state.dataSteamCoils.SteamCoil)
    else:
        IndexNum = 0

    if IndexNum == 0:
        ShowSevereError(state, "GetSteamCoilIndex: Could not find CoilType=\"{}\" with Name=\"{}\"".format(CoilType, CoilName))
        ErrorsFound = True

    return IndexNum


def GetCompIndex(inout state: EnergyPlusData, coilName: StringLiteral) -> Int:
    if state