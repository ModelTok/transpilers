from math import abs
from Array import Array1D, Array1D_string, Array1D_bool, EPVector
from Optional import Optional
from BaseData import BaseGlobalStruct, BaseData
from DataGlobals import DataGlobals
from EnergyPlus import EnergyPlusData
from FluidProperties import FluidProperties
from General import General
from .Autosizing.HeatingAirFlowSizing import HeatingAirFlowSizer
from .Autosizing.HeatingCapacitySizing import HeatingCapacitySizer
from BranchNodeConnections import BranchNodeConnections
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from DataHeatBalance import DataHeatBalance
from DataLoopNode import DataLoopNode
from DataSizing import DataSizing
from DataZoneEnergyDemands import DataZoneEnergyDemands
from DataZoneEquipment import DataZoneEquipment
from Fans import Fans
from FluidProperties import FluidProperties
from General import General
from GeneralRoutines import GeneralRoutines
from HeatingCoils import HeatingCoils
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ReportCoilSelection import ReportCoilSelection
from ScheduleManager import ScheduleManager
from SteamCoils import SteamCoils
from UtilityRoutines import UtilityRoutines
from WaterCoils import WaterCoils
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from DataHeatBalance import DataHeatBalance
from DataLoopNode import DataLoopNode
from DataSizing import DataSizing
from DataZoneEnergyDemands import DataZoneEnergyDemands
from DataZoneEquipment import DataZoneEquipment
from Fans import Fans
from FluidProperties import FluidProperties
from General import General
from GeneralRoutines import GeneralRoutines
from HeatingCoils import HeatingCoils
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ReportCoilSelection import ReportCoilSelection
from ScheduleManager import ScheduleManager
from SteamCoils import SteamCoils
from UtilityRoutines import UtilityRoutines
from WaterCoils import WaterCoils
from FluidProperties import FluidProperties
from DataGlobals import DataGlobals
from DataPlant import DataPlant
from DataZoneEquipment import DataZoneEquipment
from HVAC import HVAC
from Sched import Sched
from Avail import Avail
from Constant import Constant
from Node import Node
from Util import Util
from DataSizing import DataSizing
from DataPlant import DataPlant
from DataLoopNode import DataLoopNode
from DataZoneEnergyDemand import DataZoneEnergyDemand
from Psychrometrics import Psychrometrics
from DataHeatBal import DataHeatBal
from DataSize import DataSize
from DataPlant import DataPlant
from ReportCoilSelection import ReportCoilSelection
from DataSize import DataSize
from DataWaterCoils import DataWaterCoils
from BaseSizer import BaseSizer
from Fluid import Fluid
from Clusive import Clusive
from ErrorObjectHeader import ErrorObjectHeader
from DataZoneEnergyDemand import DataZoneEnergyDemand
from DataHVACGlobal import DataHVACGlobal
from DataAvail import DataAvail

struct UnitHeaterData:
    var Name: String
    var availSched: Sched.Schedule
    var AirInNode: Int
    var AirOutNode: Int
    var fanType: HVAC.FanType
    var FanName: String
    var Fan_Index: Int
    var fanOpModeSched: Sched.Schedule
    var fanAvailSched: Sched.Schedule
    var ControlCompTypeNum: Int
    var CompErrIndex: Int
    var MaxAirVolFlow: Float64
    var MaxAirMassFlow: Float64
    var FanOperatesDuringNoHeating: String
    var FanOutletNode: Int
    var fanOp: HVAC.FanOp
    var heatCoilType: HVAC.CoilType
    var HCoilTypeCh: String
    var HCoilName: String
    var HCoil_Index: Int
    var HeatingCoilType: DataPlant.PlantEquipmentType
    var HCoil_fluid: Fluid.RefrigProps
    var MaxVolHotWaterFlow: Float64
    var MaxVolHotSteamFlow: Float64
    var MaxHotWaterFlow: Float64
    var MaxHotSteamFlow: Float64
    var MinVolHotWaterFlow: Float64
    var MinVolHotSteamFlow: Float64
    var MinHotWaterFlow: Float64
    var MinHotSteamFlow: Float64
    var HotControlNode: Int
    var HotControlOffset: Float64
    var HotCoilOutNodeNum: Int
    var HWplantLoc: DataPlant.PlantLocation
    var PartLoadFrac: Float64
    var HeatPower: Float64
    var HeatEnergy: Float64
    var ElecPower: Float64
    var ElecEnergy: Float64
    var AvailManagerListName: String
    var availStatus: Avail.Status
    var FanOffNoHeating: Bool
    var FanPartLoadRatio: Float64
    var ZonePtr: Int
    var HVACSizingIndex: Int
    var FirstPass: Bool
    var solveRootStats: General.SolveRootStats

    def __init__(inout self):
        self.Name = String("")
        self.availSched = Sched.getScheduleAlwaysOn()
        self.AirInNode = 0
        self.AirOutNode = 0
        self.fanType = HVAC.FanType.Invalid
        self.FanName = String("")
        self.Fan_Index = 0
        self.fanOpModeSched = Sched.getScheduleAlwaysOn()
        self.fanAvailSched = Sched.getScheduleAlwaysOn()
        self.ControlCompTypeNum = 0
        self.CompErrIndex = 0
        self.MaxAirVolFlow = 0.0
        self.MaxAirMassFlow = 0.0
        self.FanOperatesDuringNoHeating = String("")
        self.FanOutletNode = 0
        self.fanOp = HVAC.FanOp.Invalid
        self.heatCoilType = HVAC.CoilType.Invalid
        self.HCoilTypeCh = String("")
        self.HCoilName = String("")
        self.HCoil_Index = 0
        self.HeatingCoilType = DataPlant.PlantEquipmentType.Invalid
        self.HCoil_fluid = None
        self.MaxVolHotWaterFlow = 0.0
        self.MaxVolHotSteamFlow = 0.0
        self.MaxHotWaterFlow = 0.0
        self.MaxHotSteamFlow = 0.0
        self.MinVolHotWaterFlow = 0.0
        self.MinVolHotSteamFlow = 0.0
        self.MinHotWaterFlow = 0.0
        self.MinHotSteamFlow = 0.0
        self.HotControlNode = 0
        self.HotControlOffset = 0.0
        self.HotCoilOutNodeNum = 0
        self.HWplantLoc = DataPlant.PlantLocation()
        self.PartLoadFrac = 0.0
        self.HeatPower = 0.0
        self.HeatEnergy = 0.0
        self.ElecPower = 0.0
        self.ElecEnergy = 0.0
        self.AvailManagerListName = String("")
        self.availStatus = Avail.Status.NoAction
        self.FanOffNoHeating = False
        self.FanPartLoadRatio = 0.0
        self.ZonePtr = 0
        self.HVACSizingIndex = 0
        self.FirstPass = True
        self.solveRootStats = General.SolveRootStats()

struct UnitHeatNumericFieldData:
    var FieldNames: Array1D_string

    def __init__(inout self):

def SimUnitHeater(inout state: EnergyPlusData, CompName: StringLiteral, ZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout LatOutputProvided: Float64, inout CompIndex: Int):
    var UnitHeatNum: Int
    if state.dataUnitHeaters.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        state.dataUnitHeaters.GetUnitHeaterInputFlag = False
    if CompIndex == 0:
        UnitHeatNum = Util.FindItemInList(CompName, state.dataUnitHeaters.UnitHeat)
        if UnitHeatNum == 0:
            ShowFatalError(state, format("SimUnitHeater: Unit not found={}", CompName))
        CompIndex = UnitHeatNum
    else:
        UnitHeatNum = CompIndex
        if UnitHeatNum > state.dataUnitHeaters.NumOfUnitHeats or UnitHeatNum < 1:
            ShowFatalError(state, format("SimUnitHeater:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}", UnitHeatNum, state.dataUnitHeaters.NumOfUnitHeats, CompName))
        if state.dataUnitHeaters.CheckEquipName[UnitHeatNum]:
            if CompName != state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name:
                ShowFatalError(state, format("SimUnitHeater: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}", UnitHeatNum, CompName, state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
            state.dataUnitHeaters.CheckEquipName[UnitHeatNum] = False
    state.dataSize.ZoneEqUnitHeater = True
    InitUnitHeater(state, UnitHeatNum, ZoneNum, FirstHVACIteration)
    state.dataSize.ZoneHeatingOnlyFan = True
    CalcUnitHeater(state, UnitHeatNum, ZoneNum, FirstHVACIteration, PowerMet, LatOutputProvided)
    state.dataSize.ZoneHeatingOnlyFan = False
    ReportUnitHeater(state, UnitHeatNum)
    state.dataSize.ZoneEqUnitHeater = False

def GetUnitHeaterInput(inout state: EnergyPlusData):
    var RoutineName: StringLiteral = "GetUnitHeaterInput: "
    var routineName: StringLiteral = "GetUnitHeaterInput"
    var ErrorsFound: Bool = False
    var IOStatus: Int
    var IsNotOK: Bool
    var errFlag: Bool = False
    var NumAlphas: Int
    var NumNumbers: Int
    var NumFields: Int
    var FanVolFlow: Float64
    var Alphas: Array1D_string
    var Numbers: Array1D[Float64]
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    var CtrlZone: Int
    var NodeNum: Int
    var CurrentModuleObject: String = state.dataUnitHeaters.cMO_UnitHeater
    state.dataUnitHeaters.NumOfUnitHeats = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumFields, NumAlphas, NumNumbers)
    Alphas = Array1D_string(NumAlphas)
    Numbers = Array1D[Float64](NumNumbers)
    cAlphaFields = Array1D_string(NumAlphas)
    cNumericFields = Array1D_string(NumNumbers)
    lAlphaBlanks = Array1D_bool(NumAlphas)
    lNumericBlanks = Array1D_bool(NumNumbers)
    if state.dataUnitHeaters.NumOfUnitHeats > 0:
        state.dataUnitHeaters.UnitHeat = EPVector[UnitHeaterData](state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.CheckEquipName = Array1D_bool(state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.UnitHeatNumericFields = EPVector[UnitHeatNumericFieldData](state.dataUnitHeaters.NumOfUnitHeats)
    state.dataUnitHeaters.CheckEquipName = True
    for UnitHeatNum in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, UnitHeatNum, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[1])
        state.dataUnitHeaters.UnitHeatNumericFields[UnitHeatNum].FieldNames = Array1D_string(NumNumbers)
        state.dataUnitHeaters.UnitHeatNumericFields[UnitHeatNum].FieldNames = ""
        state.dataUnitHeaters.UnitHeatNumericFields[UnitHeatNum].FieldNames = cNumericFields
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name = Alphas[1]
        if lAlphaBlanks[2]:
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].availSched = Sched.GetScheduleAlwaysOn(state)
        elif (state.dataUnitHeaters.UnitHeat[UnitHeatNum].availSched = Sched.GetSchedule(state, Alphas[2])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
            ErrorsFound = True
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode = Node.GetOnlySingleNode(state, Alphas[3], ErrorsFound, Node.ConnectionObjectType.ZoneHVACUnitHeater, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsParent)
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirOutNode = Node.GetOnlySingleNode(state, Alphas[4], ErrorsFound, Node.ConnectionObjectType.ZoneHVACUnitHeater, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsParent)
        var unitHeat: UnitHeaterData = state.dataUnitHeaters.UnitHeat[UnitHeatNum]
        unitHeat.fanType = HVAC.FanType(getEnumValue(HVAC.fanTypeNamesUC, Alphas[5]))
        if unitHeat.fanType != HVAC.FanType.Constant and unitHeat.fanType != HVAC.FanType.VAV and unitHeat.fanType != HVAC.FanType.OnOff and unitHeat.fanType != HVAC.FanType.SystemModel:
            ShowSevereInvalidKey(state, eoh, cAlphaFields[5], Alphas[5], "Fan Type must be Fan:ConstantVolume, Fan:VariableVolume, or Fan:OnOff")
            ErrorsFound = True
        unitHeat.FanName = Alphas[6]
        unitHeat.MaxAirVolFlow = Numbers[1]
        if (unitHeat.Fan_Index = Fans.GetFanIndex(state, unitHeat.FanName)) == 0:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[6], unitHeat.FanName)
            ErrorsFound = True
        else:
            var fan = state.dataFans.fans[unitHeat.Fan_Index]
            unitHeat.FanOutletNode = fan.outletNodeNum
            FanVolFlow = fan.maxAirFlowRate
            if FanVolFlow != DataSizing.AutoSize and unitHeat.MaxAirVolFlow != DataSizing.AutoSize and FanVolFlow < unitHeat.MaxAirVolFlow:
                ShowSevereError(state, format("Specified in {} = {}", CurrentModuleObject, unitHeat.Name))
                ShowContinueError(state, format("...air flow rate ({:.7f}) in fan object {} is less than the unit heater maximum supply air flow rate ({:.7f}).", FanVolFlow, unitHeat.FanName, unitHeat.MaxAirVolFlow))
                ShowContinueError(state, "...the fan flow rate must be greater than or equal to the unit heater maximum supply air flow rate.")
                ErrorsFound = True
            elif FanVolFlow == DataSizing.AutoSize and unitHeat.MaxAirVolFlow != DataSizing.AutoSize:
                ShowWarningError(state, format("Specified in {} = {}", CurrentModuleObject, unitHeat.Name))
                ShowContinueError(state, "...the fan flow rate is autosized while the unit heater flow rate is not.")
                ShowContinueError(state, "...this can lead to unexpected results where the fan flow rate is less than required.")
            elif FanVolFlow != DataSizing.AutoSize and unitHeat.MaxAirVolFlow == DataSizing.AutoSize:
                ShowWarningError(state, format("Specified in {} = {}", CurrentModuleObject, unitHeat.Name))
                ShowContinueError(state, "...the unit heater flow rate is autosized while the fan flow rate is not.")
                ShowContinueError(state, "...this can lead to unexpected results where the fan flow rate is less than required.")
            unitHeat.fanAvailSched = fan.availSched
        unitHeat.heatCoilType = HVAC.CoilType(getEnumValue(HVAC.coilTypeNamesUC, Util.makeUPPER(Alphas[7])))
        if unitHeat.heatCoilType == HVAC.CoilType.HeatingWater:
            unitHeat.HeatingCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        elif unitHeat.heatCoilType == HVAC.CoilType.HeatingSteam:
            unitHeat.HeatingCoilType = DataPlant.PlantEquipmentType.CoilSteamAirHeating
        elif unitHeat.heatCoilType == HVAC.CoilType.HeatingElectric or unitHeat.heatCoilType == HVAC.CoilType.HeatingGasOrOtherFuel:

        else:
            ShowSevereError(state, format("Illegal {} = {}", cAlphaFields[7], Alphas[7]))
            ShowContinueError(state, format("Occurs in {}={}", CurrentModuleObject, unitHeat.Name))
            ErrorsFound = True
            errFlag = True
        if not errFlag:
            unitHeat.HCoilTypeCh = Alphas[7]
            unitHeat.HCoilName = Alphas[8]
            ValidateComponent(state, Alphas[7], unitHeat.HCoilName, IsNotOK, CurrentModuleObject)
            if IsNotOK:
                ShowContinueError(state, format("specified in {} = \"{}\"", CurrentModuleObject, unitHeat.Name))
                ErrorsFound = True
            else:
                if unitHeat.heatCoilType == HVAC.CoilType.HeatingWater or unitHeat.heatCoilType == HVAC.CoilType.HeatingSteam:
                    errFlag = False
                    if unitHeat.heatCoilType == HVAC.CoilType.HeatingWater:
                        unitHeat.HotControlNode = WaterCoils.GetCoilWaterInletNode(state, "Coil:Heating:Water", unitHeat.HCoilName, errFlag)
                    else:
                        unitHeat.HCoil_Index = SteamCoils.GetSteamCoilIndex(state, "COIL:HEATING:STEAM", unitHeat.HCoilName, errFlag)
                        unitHeat.HotControlNode = SteamCoils.GetCoilSteamInletNode(state, unitHeat.HCoil_Index, unitHeat.HCoilName, errFlag)
                        unitHeat.HCoil_fluid = Fluid.GetSteam(state)
                    if errFlag:
                        ShowContinueError(state, format("that was specified in {} = \"{}\"", CurrentModuleObject, unitHeat.Name))
                        ErrorsFound = True
        if lAlphaBlanks[9]:
            unitHeat.fanOp = HVAC.FanOp.Cycling if (unitHeat.fanType == HVAC.FanType.OnOff or unitHeat.fanType == HVAC.FanType.SystemModel) else HVAC.FanOp.Continuous
        elif (state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOpModeSched = Sched.GetSchedule(state, Alphas[9])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[9], Alphas[9])
            ErrorsFound = True
        elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanType == HVAC.FanType.Constant and not state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOpModeSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
            Sched.ShowSevereBadMinMax(state, eoh, cAlphaFields[9], Alphas[9], Clusive.In, 0.0, Clusive.In, 1.0)
            ErrorsFound = True
        unitHeat.FanOperatesDuringNoHeating = Alphas[10]
        if (not Util.SameString(unitHeat.FanOperatesDuringNoHeating, "Yes")) and (not Util.SameString(unitHeat.FanOperatesDuringNoHeating, "No")):
            ErrorsFound = True
            ShowSevereError(state, format("Illegal {} = {}", cAlphaFields[10], Alphas[10]))
            ShowContinueError(state, format("Occurs in {}={}", CurrentModuleObject, unitHeat.Name))
        elif Util.SameString(unitHeat.FanOperatesDuringNoHeating, "No"):
            unitHeat.FanOffNoHeating = True
        unitHeat.MaxVolHotWaterFlow = Numbers[2]
        unitHeat.MinVolHotWaterFlow = Numbers[3]
        unitHeat.MaxVolHotSteamFlow = Numbers[2]
        unitHeat.MinVolHotSteamFlow = Numbers[3]
        unitHeat.HotControlOffset = Numbers[4]
        if unitHeat.HotControlOffset <= 0.0:
            unitHeat.HotControlOffset = 0.001
        if not lAlphaBlanks[11]:
            unitHeat.AvailManagerListName = Alphas[11]
        unitHeat.HVACSizingIndex = 0
        if not lAlphaBlanks[12]:
            unitHeat.HVACSizingIndex = Util.FindItemInList(Alphas[12], state.dataSize.ZoneHVACSizing)
            if unitHeat.HVACSizingIndex == 0:
                ShowSevereError(state, format("{} = {} not found.", cAlphaFields[12], Alphas[12]))
                ShowContinueError(state, format("Occurs in {} = {}", CurrentModuleObject, unitHeat.Name))
                ErrorsFound = True
        var ZoneNodeNotFound: Bool = True
        for CtrlZone in range(1, state.dataGlobal.NumOfZones + 1):
            if not state.dataZoneEquip.ZoneEquipConfig[CtrlZone].IsControlled:
                continue
            for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[CtrlZone].NumExhaustNodes + 1):
                if unitHeat.AirInNode == state.dataZoneEquip.ZoneEquipConfig[CtrlZone].ExhaustNode[NodeNum]:
                    ZoneNodeNotFound = False
                    break
        if ZoneNodeNotFound:
            ShowSevereError(state, format("{} = \"{}\". Unit heater air inlet node name must be the same as a zone exhaust node name.", CurrentModuleObject, unitHeat.Name))
            ShowContinueError(state, "..Zone exhaust node name is specified in ZoneHVAC:EquipmentConnections object.")
            ShowContinueError(state, format("..Unit heater air inlet node name = {}", state.dataLoopNodes.NodeID[unitHeat.AirInNode]))
            ErrorsFound = True
        ZoneNodeNotFound = True
        for CtrlZone in range(1, state.dataGlobal.NumOfZones + 1):
            if not state.dataZoneEquip.ZoneEquipConfig[CtrlZone].IsControlled:
                continue
            for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[CtrlZone].NumInletNodes + 1):
                if unitHeat.AirOutNode == state.dataZoneEquip.ZoneEquipConfig[CtrlZone].InletNode[NodeNum]:
                    unitHeat.ZonePtr = CtrlZone
                    ZoneNodeNotFound = False
                    break
        if ZoneNodeNotFound:
            ShowSevereError(state, format("{} = \"{}\". Unit heater air outlet node name must be the same as a zone inlet node name.", CurrentModuleObject, unitHeat.Name))
            ShowContinueError(state, "..Zone inlet node name is specified in ZoneHVAC:EquipmentConnections object.")
            ShowContinueError(state, format("..Unit heater air outlet node name = {}", state.dataLoopNodes.NodeID[unitHeat.AirOutNode]))
            ErrorsFound = True
        Node.SetUpCompSets(state, CurrentModuleObject, unitHeat.Name, HVAC.fanTypeNamesUC[unitHeat.fanType], unitHeat.FanName, state.dataLoopNodes.NodeID[unitHeat.AirInNode], state.dataLoopNodes.NodeID[unitHeat.FanOutletNode])
        Node.SetUpCompSets(state, CurrentModuleObject, unitHeat.Name, unitHeat.HCoilTypeCh, unitHeat.HCoilName, state.dataLoopNodes.NodeID[unitHeat.FanOutletNode], state.dataLoopNodes.NodeID[unitHeat.AirOutNode])
    Alphas.deallocate()
    Numbers.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    lAlphaBlanks.deallocate()
    lNumericBlanks.deallocate()
    if ErrorsFound:
        ShowFatalError(state, format("{}Errors found in input", RoutineName))
    for UnitHeatNum in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
        var unitHeat = state.dataUnitHeaters.UnitHeat[UnitHeatNum]
        SetupOutputVariable(state, "Zone Unit Heater Heating Rate", Constant.Units.W, unitHeat.HeatPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, unitHeat.Name)
        SetupOutputVariable(state, "Zone Unit Heater Heating Energy", Constant.Units.J, unitHeat.HeatEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, unitHeat.Name)
        SetupOutputVariable(state, "Zone Unit Heater Fan Electricity Rate", Constant.Units.W, unitHeat.ElecPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, unitHeat.Name)
        SetupOutputVariable(state, "Zone Unit Heater Fan Electricity Energy", Constant.Units.J, unitHeat.ElecEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, unitHeat.Name)
        SetupOutputVariable(state, "Zone Unit Heater Fan Availability Status", Constant.Units.None, unitHeat.availStatus, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, unitHeat.Name)
        if unitHeat.fanType == HVAC.FanType.OnOff:
            SetupOutputVariable(state, "Zone Unit Heater Fan Part Load Ratio", Constant.Units.None, unitHeat.FanPartLoadRatio, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, unitHeat.Name)
        ReportCoilSelection.setCoilSupplyFanInfo(state, ReportCoilSelection.getReportIndex(state, unitHeat.HCoilName, unitHeat.heatCoilType), unitHeat.FanName, unitHeat.fanType, unitHeat.Fan_Index)

def InitUnitHeater(inout state: EnergyPlusData, UnitHeatNum: Int, ZoneNum: Int, FirstHVACIteration: Bool):
    var RoutineName: StringLiteral = "InitUnitHeater"
    var InNode: Int
    var OutNode: Int
    var RhoAir: Float64
    var TempSteamIn: Float64
    var SteamDensity: Float64
    var rho: Float64
    if state.dataUnitHeaters.InitUnitHeaterOneTimeFlag:
        state.dataUnitHeaters.MyEnvrnFlag = Array1D_bool(state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.MySizeFlag = Array1D_bool(state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.MyPlantScanFlag = Array1D_bool(state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.MyZoneEqFlag = Array1D_bool(state.dataUnitHeaters.NumOfUnitHeats)
        state.dataUnitHeaters.MyEnvrnFlag = True
        state.dataUnitHeaters.MySizeFlag = True
        state.dataUnitHeaters.MyPlantScanFlag = True
        state.dataUnitHeaters.MyZoneEqFlag = True
        state.dataUnitHeaters.InitUnitHeaterOneTimeFlag = False
    if allocated(state.dataAvail.ZoneComp):
        var availMgr = state.dataAvail.ZoneComp[DataZoneEquipment.ZoneEquipType.UnitHeater].ZoneCompAvailMgrs[UnitHeatNum]
        if state.dataUnitHeaters.MyZoneEqFlag[UnitHeatNum]:
            availMgr.AvailManagerListName = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AvailManagerListName
            availMgr.ZoneNum = ZoneNum
            state.dataUnitHeaters.MyZoneEqFlag[UnitHeatNum] = False
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].availStatus = availMgr.availStatus
    if state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum] and allocated(state.dataPlnt.PlantLoop):
        if (state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatingCoilType == DataPlant.PlantEquipmentType.CoilWaterSimpleHeating) or (state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatingCoilType == DataPlant.PlantEquipmentType.CoilSteamAirHeating):
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatingCoilType, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowContinueError(state, format("Reference Unit=\"{}\", type=ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
                ShowFatalError(state, "InitUnitHeater: Program terminated due to previous condition(s).")
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum = DataPlant.CompData.getPlantComponent(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc).NodeNumOut
        state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum] = False
    elif state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum] and not state.dataGlobal.AnyPlantInModel:
        state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum] = False
    if not state.dataUnitHeaters.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataUnitHeaters.ZoneEquipmentListChecked = True
        for Loop in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
            if DataZoneEquipment.CheckZoneEquipmentList(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[Loop].Name):
                continue
            ShowSevereError(state, format("InitUnitHeater: Unit=[UNIT HEATER,{}] is not on any ZoneHVAC:EquipmentList.  It will not be simulated.", state.dataUnitHeaters.UnitHeat[Loop].Name))
    if not state.dataGlobal.SysSizingCalc and state.dataUnitHeaters.MySizeFlag[UnitHeatNum] and not state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum]:
        SizeUnitHeater(state, UnitHeatNum)
        state.dataUnitHeaters.MySizeFlag[UnitHeatNum] = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataUnitHeaters.MyEnvrnFlag[UnitHeatNum] and not state.dataUnitHeaters.MyPlantScanFlag[UnitHeatNum]:
        InNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode
        OutNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirOutNode
        RhoAir = state.dataEnvrn.StdRhoAir
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow = RhoAir * state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRateMax = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRateMin = 0.0
        state.dataLoopNodes.Node[InNode].MassFlowRateMax = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[InNode].MassFlowRateMin = 0.0
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
            rho = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotWaterFlow = rho * state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinHotWaterFlow = rho * state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinVolHotWaterFlow
            PlantUtilities.InitComponentNodes(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinHotWaterFlow, state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotWaterFlow, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum)
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
            TempSteamIn = 100.00
            SteamDensity = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_fluid.getSatDensity(state, TempSteamIn, 1.0, RoutineName)
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotSteamFlow = SteamDensity * state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinHotSteamFlow = SteamDensity * state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinVolHotSteamFlow
            PlantUtilities.InitComponentNodes(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinHotSteamFlow, state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotSteamFlow, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum)
        state.dataUnitHeaters.MyEnvrnFlag[UnitHeatNum] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataUnitHeaters.MyEnvrnFlag[UnitHeatNum] = True
    InNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode
    OutNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirOutNode
    state.dataUnitHeaters.QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOpModeSched != None:
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOpModeSched.getCurrentVal() == 0.0 and state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanType == HVAC.FanType.OnOff:
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOp = HVAC.FanOp.Cycling
        else:
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOp = HVAC.FanOp.Continuous
        if (state.dataUnitHeaters.QZnReq < HVAC.SmallLoad) or state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]:
            if not state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOffNoHeating and state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOpModeSched.getCurrentVal() > 0.0:
                state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOp = HVAC.FanOp.Continuous
    state.dataUnitHeaters.SetMassFlowRateToZero = False
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].availSched.getCurrentVal() > 0:
        if (state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanAvailSched.getCurrentVal() > 0 or state.dataHVACGlobal.TurnFansOn) and not state.dataHVACGlobal.TurnFansOff:
            if state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOffNoHeating and ((state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP < HVAC.SmallLoad) or (state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum])):
                state.dataUnitHeaters.SetMassFlowRateToZero = True
        else:
            state.dataUnitHeaters.SetMassFlowRateToZero = True
    else:
        state.dataUnitHeaters.SetMassFlowRateToZero = True
    if state.dataUnitHeaters.SetMassFlowRateToZero:
        state.dataLoopNodes.Node[InNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[InNode].MassFlowRateMaxAvail = 0.0
        state.dataLoopNodes.Node[InNode].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[OutNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[OutNode].MassFlowRateMaxAvail = 0.0
        state.dataLoopNodes.Node[OutNode].MassFlowRateMinAvail = 0.0
    else:
        state.dataLoopNodes.Node[InNode].MassFlowRate = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[InNode].MassFlowRateMaxAvail = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[InNode].MassFlowRateMinAvail = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRate = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRateMaxAvail = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRateMinAvail = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirMassFlow
    state.dataLoopNodes.Node[OutNode].Temp = state.dataLoopNodes.Node[InNode].Temp
    state.dataLoopNodes.Node[OutNode].Press = state.dataLoopNodes.Node[InNode].Press
    state.dataLoopNodes.Node[OutNode].HumRat = state.dataLoopNodes.Node[InNode].HumRat
    state.dataLoopNodes.Node[OutNode].Enthalpy = state.dataLoopNodes.Node[InNode].Enthalpy

def SizeUnitHeater(inout state: EnergyPlusData, UnitHeatNum: Int):
    var RoutineName: StringLiteral = "SizeUnitHeater"
    var PltSizHeatNum: Int
    var DesCoilLoad: Float64
    var TempSteamIn: Float64
    var EnthSteamInDry: Float64
    var EnthSteamOutWet: Float64
    var LatentHeatSteam: Float64
    var SteamDensity: Float64
    var Cp: Float64
    var rho: Float64
    var SizingString: String
    var TempSize: Float64
    var PrintFlag: Bool
    var zoneHVACIndex: Int
    var WaterCoilSizDeltaT: Float64
    var CurZoneEqNum: Int = state.dataSize.CurZoneEqNum
    var ErrorsFound: Bool = False
    var MaxVolHotWaterFlowDes: Float64 = 0.0
    var MaxVolHotWaterFlowUser: Float64 = 0.0
    var MaxVolHotSteamFlowDes: Float64 = 0.0
    var MaxVolHotSteamFlowUser: Float64 = 0.0
    state.dataSize.DataScalableSizingON = False
    state.dataSize.DataScalableCapSizingON = False
    state.dataSize.ZoneHeatingOnlyFan = True
    var CompType: String = "ZoneHVAC:UnitHeater"
    var CompName: String = state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name
    state.dataSize.DataZoneNumber = state.dataUnitHeaters.UnitHeat[UnitHeatNum].ZonePtr
    state.dataSize.DataFanType = state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanType
    state.dataSize.DataFanIndex = state.dataUnitHeaters.UnitHeat[UnitHeatNum].Fan_Index
    state.dataSize.DataFanPlacement = HVAC.FanPlace.BlowThru
    if CurZoneEqNum > 0:
        var ZoneEqSizing = state.dataSize.ZoneEqSizing[CurZoneEqNum]
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex > 0:
            zoneHVACIndex = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex
            var SizingMethod: Int = HVAC.HeatingAirflowSizing
            var FieldNum: Int = 1
            PrintFlag = True
            SizingString = state.dataUnitHeaters.UnitHeatNumericFields[UnitHeatNum].FieldNames[FieldNum] + " [m3/s]"
            var SAFMethod: Int = state.dataSize.ZoneHVACSizing[zoneHVACIndex].HeatingSAFMethod
            ZoneEqSizing.SizingMethod[SizingMethod] = SAFMethod
            if SAFMethod == DataSizing.None or SAFMethod == DataSizing.SupplyAirFlowRate or SAFMethod == DataSizing.FlowPerFloorArea or SAFMethod == DataSizing.FractionOfAutosizedHeatingAirflow:
                if SAFMethod == DataSizing.SupplyAirFlowRate:
                    if state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow > 0.0:
                        ZoneEqSizing.AirVolFlow = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow
                        ZoneEqSizing.SystemAirFlow = True
                    TempSize = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow
                elif SAFMethod == DataSizing.FlowPerFloorArea:
                    ZoneEqSizing.SystemAirFlow = True
                    ZoneEqSizing.AirVolFlow = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                    TempSize = ZoneEqSizing.AirVolFlow
                    state.dataSize.DataScalableSizingON = True
                elif SAFMethod == DataSizing.FractionOfAutosizedHeatingAirflow:
                    state.dataSize.DataFracOfAutosizedCoolingAirflow = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow
                    TempSize = DataSizing.AutoSize
                    state.dataSize.DataScalableSizingON = True
                else:
                    TempSize = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow
                var errorsFound: Bool = False
                var sizingHeatingAirFlow: HeatingAirFlowSizer = HeatingAirFlowSizer()
                sizingHeatingAirFlow.overrideSizingString(SizingString)
                sizingHeatingAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow = sizingHeatingAirFlow.size(state, TempSize, errorsFound)
            elif SAFMethod == DataSizing.FlowPerHeatingCapacity:
                TempSize = DataSizing.AutoSize
                PrintFlag = False
                state.dataSize.DataScalableSizingON = True
                state.dataSize.DataFlowUsedForSizing = state.dataSize.FinalZoneSizing[CurZoneEqNum].DesHeatVolFlow
                var errorsFound: Bool = False
                var sizerHeatingCapacity: HeatingCapacitySizer = HeatingCapacitySizer()
                sizerHeatingCapacity.overrideSizingString(SizingString)
                sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                TempSize = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                if state.dataSize.ZoneHVACSizing[zoneHVACIndex].HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity
                state.dataSize.DataAutosizedHeatingCapacity = TempSize
                state.dataSize.DataFlowPerHeatingCapacity = state.dataSize.ZoneHVACSizing[zoneHVACIndex].MaxHeatAirVolFlow
                PrintFlag = True
                TempSize = DataSizing.AutoSize
                errorsFound = False
                var sizingHeatingAirFlow2: HeatingAirFlowSizer = HeatingAirFlowSizer()
                sizingHeatingAirFlow2.overrideSizingString(SizingString)
                sizingHeatingAirFlow2.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow = sizingHeatingAirFlow2.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableSizingON = False
        else:
            var FieldNum: Int = 1
            PrintFlag = True
            SizingString = state.dataUnitHeaters.UnitHeatNumericFields[UnitHeatNum].FieldNames[FieldNum] + " [m3/s]"
            TempSize = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow
            var errorsFound: Bool = False
            var sizingHeatingAirFlow: HeatingAirFlowSizer = HeatingAirFlowSizer()
            sizingHeatingAirFlow.overrideSizingString(SizingString)
            sizingHeatingAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow = sizingHeatingAirFlow.size(state, TempSize, errorsFound)
    var IsAutoSize: Bool = False
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
        if CurZoneEqNum > 0:
            if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow > 0.0:
                    BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "User-Specified Maximum Hot Water Flow [m3/s]", state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow)
            else:
                CheckZoneSizing(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name)
                var CoilWaterInletNode: Int = WaterCoils.GetCoilWaterInletNode(state, "Coil:Heating:Water", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, ErrorsFound)
                var CoilWaterOutletNode: Int = WaterCoils.GetCoilWaterOutletNode(state, "Coil:Heating:Water", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, ErrorsFound)
                if IsAutoSize:
                    var DoWaterCoilSizing: Bool = False
                    PltSizHeatNum = PlantUtilities.MyPlantSizingIndex(state, "Coil:Heating:Water", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, CoilWaterInletNode, CoilWaterOutletNode, ErrorsFound)
                    var CoilNum: Int = WaterCoils.GetWaterCoilIndex(state, "COIL:HEATING:WATER", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, ErrorsFound)
                    if state.dataWaterCoils.WaterCoil[CoilNum].UseDesignWaterDeltaTemp:
                        WaterCoilSizDeltaT = state.dataWaterCoils.WaterCoil[CoilNum].DesignWaterDeltaTemp
                        DoWaterCoilSizing = True
                    else:
                        if PltSizHeatNum > 0:
                            WaterCoilSizDeltaT = state.dataSize.PlantSizData[PltSizHeatNum].DeltaT
                            DoWaterCoilSizing = True
                        else:
                            DoWaterCoilSizing = False
                            ShowSevereError(state, "Autosizing of water coil requires a heating loop Sizing:Plant object")
                            ShowContinueError(state, format("Occurs in ZoneHVAC:UnitHeater Object={}", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
                            ErrorsFound = True
                    if DoWaterCoilSizing:
                        var ZoneEqSizing = state.dataSize.ZoneEqSizing[CurZoneEqNum]
                        var SizingMethod: Int = HVAC.HeatingCapacitySizing
                        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex > 0:
                            zoneHVACIndex = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex
                            var CapSizingMethod: Int = state.dataSize.ZoneHVACSizing[zoneHVACIndex].HeatingCapMethod
                            ZoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod
                            if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                                if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                                    if state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity == DataSizing.AutoSize:
                                        ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[CurZoneEqNum].DesHeatLoad
                                    else:
                                        ZoneEqSizing.DesHeatingLoad = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity
                                    ZoneEqSizing.HeatingCapacity = True
                                    TempSize = DataSizing.AutoSize
                                elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                                    ZoneEqSizing.HeatingCapacity = True
                                    ZoneEqSizing.DesHeatingLoad = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                                    state.dataSize.DataScalableCapSizingON = True
                                elif CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                                    state.dataSize.DataFracOfAutosizedHeatingCapacity = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity
                                    state.dataSize.DataScalableCapSizingON = True
                                    TempSize = DataSizing.AutoSize
                            PrintFlag = False
                            var errorsFound: Bool = False
                            var sizerHeatingCapacity: HeatingCapacitySizer = HeatingCapacitySizer()
                            sizerHeatingCapacity.overrideSizingString(SizingString)
                            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                            DesCoilLoad = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                            state.dataSize.DataScalableCapSizingON = False
                        else:
                            SizingString = ""
                            PrintFlag = False
                            TempSize = DataSizing.AutoSize
                            ZoneEqSizing.HeatingCapacity = True
                            ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[CurZoneEqNum].DesHeatLoad
                            var errorsFound: Bool = False
                            var sizerHeatingCapacity: HeatingCapacitySizer = HeatingCapacitySizer()
                            sizerHeatingCapacity.overrideSizingString(SizingString)
                            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                            DesCoilLoad = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                        if DesCoilLoad >= HVAC.SmallLoad:
                            rho = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                            Cp = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                            MaxVolHotWaterFlowDes = DesCoilLoad / (WaterCoilSizDeltaT * Cp * rho)
                        else:
                            MaxVolHotWaterFlowDes = 0.0
                    state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow = MaxVolHotWaterFlowDes
                    BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "Design Size Maximum Hot Water Flow [m3/s]", MaxVolHotWaterFlowDes)
                else:
                    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow > 0.0 and MaxVolHotWaterFlowDes > 0.0:
                        MaxVolHotWaterFlowUser = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow
                        BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "Design Size Maximum Hot Water Flow [m3/s]", MaxVolHotWaterFlowDes, "User-Specified Maximum Hot Water Flow [m3/s]", MaxVolHotWaterFlowUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(MaxVolHotWaterFlowDes - MaxVolHotWaterFlowUser) / MaxVolHotWaterFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, format("SizeUnitHeater: Potential issue with equipment sizing for ZoneHVAC:UnitHeater {}", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
                                ShowContinueError(state, format("User-Specified Maximum Hot Water Flow of {:.5R} [m3/s]", MaxVolHotWaterFlowUser))
                                ShowContinueError(state, format("differs from Design Size Maximum Hot Water Flow of {:.5R} [m3/s]", MaxVolHotWaterFlowDes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
    else:
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow = 0.0
    IsAutoSize = False
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
        if CurZoneEqNum > 0:
            if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow > 0.0:
                    BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "User-Specified Maximum Steam Flow [m3/s]", state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow)
            else:
                var ZoneEqSizing = state.dataSize.ZoneEqSizing[CurZoneEqNum]
                CheckZoneSizing(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name)
                var CoilSteamInletNode: Int = SteamCoils.GetCoilSteamInletNode(state, "Coil:Heating:Steam", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, ErrorsFound)
                var CoilSteamOutletNode: Int = SteamCoils.GetCoilSteamInletNode(state, "Coil:Heating:Steam", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, ErrorsFound)
                if IsAutoSize:
                    PltSizHeatNum = PlantUtilities.MyPlantSizingIndex(state, "Coil:Heating:Steam", state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, CoilSteamInletNode, CoilSteamOutletNode, ErrorsFound)
                    if PltSizHeatNum > 0:
                        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex > 0:
                            zoneHVACIndex = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HVACSizingIndex
                            var SizingMethod: Int = HVAC.HeatingCapacitySizing
                            var CapSizingMethod: Int = state.dataSize.ZoneHVACSizing[zoneHVACIndex].HeatingCapMethod
                            ZoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod
                            if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                                if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                                    if state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity == DataSizing.AutoSize:
                                        ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[CurZoneEqNum].DesHeatLoad
                                    else:
                                        ZoneEqSizing.DesHeatingLoad = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity
                                    ZoneEqSizing.HeatingCapacity = True
                                    TempSize = DataSizing.AutoSize
                                elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                                    ZoneEqSizing.HeatingCapacity = True
                                    ZoneEqSizing.DesHeatingLoad = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                                    state.dataSize.DataScalableCapSizingON = True
                                elif CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                                    state.dataSize.DataFracOfAutosizedHeatingCapacity = state.dataSize.ZoneHVACSizing[zoneHVACIndex].ScaledHeatingCapacity
                                    TempSize = DataSizing.AutoSize
                                    state.dataSize.DataScalableCapSizingON = True
                            PrintFlag = False
                            var errorsFound: Bool = False
                            var sizerHeatingCapacity: HeatingCapacitySizer = HeatingCapacitySizer()
                            sizerHeatingCapacity.overrideSizingString(SizingString)
                            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                            DesCoilLoad = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                            state.dataSize.DataScalableCapSizingON = False
                        else:
                            DesCoilLoad = state.dataSize.FinalZoneSizing[CurZoneEqNum].DesHeatLoad
                        if DesCoilLoad >= HVAC.SmallLoad:
                            TempSteamIn = 100.00
                            var steam = Fluid.GetSteam(state)
                            EnthSteamInDry = steam.getSatEnthalpy(state, TempSteamIn, 1.0, RoutineName)
                            EnthSteamOutWet = steam.getSatEnthalpy(state, TempSteamIn, 0.0, RoutineName)
                            LatentHeatSteam = EnthSteamInDry - EnthSteamOutWet
                            SteamDensity = steam.getSatDensity(state, TempSteamIn, 1.0, RoutineName)
                            MaxVolHotSteamFlowDes = DesCoilLoad / (SteamDensity * (LatentHeatSteam + state.dataSize.PlantSizData[PltSizHeatNum].DeltaT * Psychrometrics.CPHW(state.dataSize.PlantSizData[PltSizHeatNum].ExitTemp)))
                        else:
                            MaxVolHotSteamFlowDes = 0.0
                    else:
                        ShowSevereError(state, "Autosizing of Steam flow requires a heating loop Sizing:Plant object")
                        ShowContinueError(state, format("Occurs in ZoneHVAC:UnitHeater Object={}", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
                        ErrorsFound = True
                    state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow = MaxVolHotSteamFlowDes
                    BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "Design Size Maximum Steam Flow [m3/s]", MaxVolHotSteamFlowDes)
                else:
                    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow > 0.0 and MaxVolHotSteamFlowDes > 0.0:
                        MaxVolHotSteamFlowUser = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow
                        BaseSizer.reportSizerOutput(state, "ZoneHVAC:UnitHeater", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, "Design Size Maximum Steam Flow [m3/s]", MaxVolHotSteamFlowDes, "User-Specified Maximum Steam Flow [m3/s]", MaxVolHotSteamFlowUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(MaxVolHotSteamFlowDes - MaxVolHotSteamFlowUser) / MaxVolHotSteamFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, format("SizeUnitHeater: Potential issue with equipment sizing for ZoneHVAC:UnitHeater {}", state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name))
                                ShowContinueError(state, format("User-Specified Maximum Steam Flow of {:.5R} [m3/s]", MaxVolHotSteamFlowUser))
                                ShowContinueError(state, format("differs from Design Size Maximum Steam Flow of {:.5R} [m3/s]", MaxVolHotSteamFlowDes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
    else:
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotSteamFlow = 0.0
    WaterCoils.SetCoilDesFlow(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilTypeCh, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxAirVolFlow, ErrorsFound)
    if CurZoneEqNum > 0:
        var ZoneEqSizing = state.dataSize.ZoneEqSizing[CurZoneEqNum]
        ZoneEqSizing.MaxHWVolFlow = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxVolHotWaterFlow
    if ErrorsFound:
        ShowFatalError(state, "Preceding sizing errors cause program termination")

def CalcUnitHeater(inout state: EnergyPlusData, inout UnitHeatNum: Int, ZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout LatOutputProvided: Float64):
    var MaxIter: Int = 100
    var SpecHumOut: Float64
    var SpecHumIn: Float64
    var mdot: Float64
    var QUnitOut: Float64 = 0.0
    var NoOutput: Float64 = 0.0
    var FullOutput: Float64 = 0.0
    var LatentOutput: Float64 = 0.0
    var MaxWaterFlow: Float64 = 0.0
    var MinWaterFlow: Float64 = 0.0
    var PartLoadFrac: Float64 = 0.0
    var InletNode: Int = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode
    var OutletNode: Int = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirOutNode
    var ControlNode: Int = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode
    var ControlOffset: Float64 = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlOffset
    var fanOp: HVAC.FanOp = state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanOp
    if fanOp != HVAC.FanOp.Cycling:
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].availSched.getCurrentVal() <= 0 or ((state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanAvailSched.getCurrentVal() <= 0 and not state.dataHVACGlobal.TurnFansOn) or state.dataHVACGlobal.TurnFansOff):
            state.dataUnitHeaters.HCoilOn = False
            if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
                mdot = 0.0
                PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
            if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
                mdot = 0.0
                PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
            CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut)
        elif (state.dataUnitHeaters.QZnReq < HVAC.SmallLoad) or state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]:
            if not state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOffNoHeating:
                state.dataUnitHeaters.HCoilOn = False
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
                    mdot = 0.0
                    PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
                    mdot = 0.0
                    PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
                CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut)
            else:
                state.dataUnitHeaters.HCoilOn = False
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
                    mdot = 0.0
                    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc.loopNum > 0:
                        PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
                if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
                    mdot = 0.0
                    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc.loopNum > 0:
                        PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
                CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut)
        else:
            if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
                if FirstHVACIteration:
                    MaxWaterFlow = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotWaterFlow
                    MinWaterFlow = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MinHotWaterFlow
                else:
                    MaxWaterFlow = state.dataLoopNodes.Node[ControlNode].MassFlowRateMaxAvail
                    MinWaterFlow = state.dataLoopNodes.Node[ControlNode].MassFlowRateMinAvail
                ControlCompOutput(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, state.dataUnitHeaters.cMO_UnitHeater, UnitHeatNum, FirstHVACIteration, state.dataUnitHeaters.QZnReq, ControlNode, MaxWaterFlow, MinWaterFlow, ControlOffset, state.dataUnitHeaters.UnitHeat[UnitHeatNum].ControlCompTypeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].CompErrIndex, _, _, _, _, _, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
            elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingElectric or state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingGasOrOtherFuel or state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
                state.dataUnitHeaters.HCoilOn = True
                CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut)
        if state.dataLoopNodes.Node[InletNode].MassFlowRateMax > 0.0:
            state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanPartLoadRatio = state.dataLoopNodes.Node[InletNode].MassFlowRate / state.dataLoopNodes.Node[InletNode].MassFlowRateMax
    else:
        if (state.dataUnitHeaters.QZnReq < HVAC.SmallLoad) or (state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]) or state.dataUnitHeaters.UnitHeat[UnitHeatNum].availSched.getCurrentVal() <= 0 or ((state.dataUnitHeaters.UnitHeat[UnitHeatNum].fanAvailSched.getCurrentVal() <= 0 and not state.dataHVACGlobal.TurnFansOn) or state.dataHVACGlobal.TurnFansOff):
            PartLoadFrac = 0.0
            state.dataUnitHeaters.HCoilOn = False
            CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut, fanOp, PartLoadFrac)
            if state.dataLoopNodes.Node[InletNode].MassFlowRateMax > 0.0:
                state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanPartLoadRatio = state.dataLoopNodes.Node[InletNode].MassFlowRate / state.dataLoopNodes.Node[InletNode].MassFlowRateMax
        else:
            state.dataUnitHeaters.HCoilOn = True
            PartLoadFrac = 0.0
            CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, NoOutput, fanOp, PartLoadFrac)
            if (NoOutput - state.dataUnitHeaters.QZnReq) < HVAC.SmallLoad:
                PartLoadFrac = 1.0
                CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, FullOutput, fanOp, PartLoadFrac)
                if (FullOutput - state.dataUnitHeaters.QZnReq) > HVAC.SmallLoad:
                    var f = fn(state: EnergyPlusData, UnitHeatNum: Int, FirstHVACIteration: Bool, fanOp: HVAC.FanOp, PartLoadRatio: Float64) -> Float64:
                        var QUnitOut: Float64
                        CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut, fanOp, PartLoadRatio)
                        if state.dataUnitHeaters.QZnReq != 0.0:
                            return (QUnitOut - state.dataUnitHeaters.QZnReq) / state.dataUnitHeaters.QZnReq
                        return 0.0
                    var SolFlag: Int = 0
                    PartLoadFrac = General.SolveRoot2(state, 0.001, MaxIter, SolFlag, f, 0.0, 1.0, state.dataUnitHeaters.UnitHeat[UnitHeatNum].solveRootStats)
            CalcUnitHeaterComponents(state, UnitHeatNum, FirstHVACIteration, QUnitOut, fanOp, PartLoadFrac)
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].PartLoadFrac = PartLoadFrac
        state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanPartLoadRatio = PartLoadFrac
        state.dataLoopNodes.Node[OutletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRate
    SpecHumOut = state.dataLoopNodes.Node[OutletNode].HumRat
    SpecHumIn = state.dataLoopNodes.Node[InletNode].HumRat
    LatentOutput = state.dataLoopNodes.Node[OutletNode].MassFlowRate * (SpecHumOut - SpecHumIn)
    QUnitOut = state.dataLoopNodes.Node[OutletNode].MassFlowRate * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat) - Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat))
    state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatPower = max(0.0, QUnitOut)
    state.dataUnitHeaters.UnitHeat[UnitHeatNum].ElecPower = state.dataFans.fans[state.dataUnitHeaters.UnitHeat[UnitHeatNum].Fan_Index].totalPower
    PowerMet = QUnitOut
    LatOutputProvided = LatentOutput

def CalcUnitHeaterComponents(inout state: EnergyPlusData, UnitHeatNum: Int, FirstHVACIteration: Bool, inout LoadMet: Float64, fanOp: HVAC.FanOp = HVAC.FanOp.Continuous, PartLoadRatio: Float64 = 1.0):
    var AirMassFlow: Float64
    var CpAirZn: Float64
    var HCoilInAirNode: Int
    var mdot: Float64
    var InletNode: Int = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode
    var OutletNode: Int = state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirOutNode
    var QCoilReq: Float64 = 0.0
    if fanOp != HVAC.FanOp.Cycling:
        state.dataFans.fans[state.dataUnitHeaters.UnitHeat[UnitHeatNum].Fan_Index].simulate(state, FirstHVACIteration, _, _)
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
            WaterCoils.SimulateWaterCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index)
        elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
            if not state.dataUnitHeaters.HCoilOn:
                QCoilReq = 0.0
            else:
                HCoilInAirNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOutletNode
                CpAirZn = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].HumRat)
                QCoilReq = state.dataUnitHeaters.QZnReq - state.dataLoopNodes.Node[HCoilInAirNode].MassFlowRate * CpAirZn * (state.dataLoopNodes.Node[HCoilInAirNode].Temp - state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].Temp)
            if QCoilReq < 0.0:
                QCoilReq = 0.0
            SteamCoils.SimulateSteamCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index, QCoilReq)
        elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingElectric or state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingGasOrOtherFuel:
            if not state.dataUnitHeaters.HCoilOn:
                QCoilReq = 0.0
            else:
                HCoilInAirNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOutletNode
                CpAirZn = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].HumRat)
                QCoilReq = state.dataUnitHeaters.QZnReq - state.dataLoopNodes.Node[HCoilInAirNode].MassFlowRate * CpAirZn * (state.dataLoopNodes.Node[HCoilInAirNode].Temp - state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].Temp)
            if QCoilReq < 0.0:
                QCoilReq = 0.0
            HeatingCoils.SimulateHeatingCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, QCoilReq, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index)
        AirMassFlow = state.dataLoopNodes.Node[OutletNode].MassFlowRate
        state.dataLoopNodes.Node[InletNode].MassFlowRate = state.dataLoopNodes.Node[OutletNode].MassFlowRate
    else:
        state.dataLoopNodes.Node[InletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRateMax * PartLoadRatio
        AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = AirMassFlow
        if QCoilReq < 0.0:
            QCoilReq = 0.0
        state.dataFans.fans[state.dataUnitHeaters.UnitHeat[UnitHeatNum].Fan_Index].simulate(state, FirstHVACIteration, _, _)
        if state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingWater:
            if not state.dataUnitHeaters.HCoilOn:
                mdot = 0.0
                QCoilReq = 0.0
            else:
                HCoilInAirNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOutletNode
                CpAirZn = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].HumRat)
                QCoilReq = state.dataUnitHeaters.QZnReq - state.dataLoopNodes.Node[HCoilInAirNode].MassFlowRate * CpAirZn * (state.dataLoopNodes.Node[HCoilInAirNode].Temp - state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].Temp)
                mdot = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotWaterFlow * PartLoadRatio
            if QCoilReq < 0.0:
                QCoilReq = 0.0
            PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
            WaterCoils.SimulateWaterCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index, QCoilReq, fanOp, PartLoadRatio)
        elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingSteam:
            if not state.dataUnitHeaters.HCoilOn:
                mdot = 0.0
                QCoilReq = 0.0
            else:
                HCoilInAirNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOutletNode
                CpAirZn = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].HumRat)
                QCoilReq = state.dataUnitHeaters.QZnReq - state.dataLoopNodes.Node[HCoilInAirNode].MassFlowRate * CpAirZn * (state.dataLoopNodes.Node[HCoilInAirNode].Temp - state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].Temp)
                mdot = state.dataUnitHeaters.UnitHeat[UnitHeatNum].MaxHotSteamFlow * PartLoadRatio
            if QCoilReq < 0.0:
                QCoilReq = 0.0
            PlantUtilities.SetComponentFlowRate(state, mdot, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotControlNode, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HotCoilOutNodeNum, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HWplantLoc)
            SteamCoils.SimulateSteamCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index, QCoilReq, _, fanOp, PartLoadRatio)
        elif state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingElectric or state.dataUnitHeaters.UnitHeat[UnitHeatNum].heatCoilType == HVAC.CoilType.HeatingGasOrOtherFuel:
            if not state.dataUnitHeaters.HCoilOn:
                QCoilReq = 0.0
            else:
                HCoilInAirNode = state.dataUnitHeaters.UnitHeat[UnitHeatNum].FanOutletNode
                CpAirZn = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].HumRat)
                QCoilReq = state.dataUnitHeaters.QZnReq - state.dataLoopNodes.Node[HCoilInAirNode].MassFlowRate * CpAirZn * (state.dataLoopNodes.Node[HCoilInAirNode].Temp - state.dataLoopNodes.Node[state.dataUnitHeaters.UnitHeat[UnitHeatNum].AirInNode].Temp)
            if QCoilReq < 0.0:
                QCoilReq = 0.0
            HeatingCoils.SimulateHeatingCoilComponents(state, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoilName, FirstHVACIteration, QCoilReq, state.dataUnitHeaters.UnitHeat[UnitHeatNum].HCoil_Index, _, _, fanOp, PartLoadRatio)
        state.dataLoopNodes.Node[OutletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRate
    LoadMet = AirMassFlow * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat) - Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat))

def ReportUnitHeater(inout state: EnergyPlusData, UnitHeatNum: Int):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatEnergy = state.dataUnitHeaters.UnitHeat[UnitHeatNum].HeatPower * TimeStepSysSec
    state.dataUnitHeaters.UnitHeat[UnitHeatNum].ElecEnergy = state.dataUnitHeaters.UnitHeat[UnitHeatNum].ElecPower * TimeStepSysSec
    if state.dataUnitHeaters.UnitHeat[UnitHeatNum].FirstPass:
        if not state.dataGlobal.SysSizingCalc:
            DataSizing.resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, 0, state.dataUnitHeaters.UnitHeat[UnitHeatNum].FirstPass)

def getUnitHeaterIndex(inout state: EnergyPlusData, CompName: StringLiteral) -> Int:
    if state.dataUnitHeaters.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        state.dataUnitHeaters.GetUnitHeaterInputFlag = False
    for UnitHeatNum in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
        if Util.SameString(state.dataUnitHeaters.UnitHeat[UnitHeatNum].Name, CompName):
            return UnitHeatNum
    return 0

struct UnitHeatersData(BaseGlobalStruct):
    var cMO_UnitHeater: String = "ZoneHVAC:UnitHeater"
    var HCoilOn: Bool
    var NumOfUnitHeats: Int
    var QZnReq: Float64
    var MySizeFlag: Array1D_bool
    var CheckEquipName: Array1D_bool
    var InitUnitHeaterOneTimeFlag: Bool = True
    var GetUnitHeaterInputFlag: Bool = True
    var ZoneEquipmentListChecked: Bool = False
    var SetMassFlowRateToZero: Bool = False
    var UnitHeat: EPVector[UnitHeaterData]
    var UnitHeatNumericFields: EPVector[UnitHeatNumericFieldData]
    var MyEnvrnFlag: Array1D_bool
    var MyPlantScanFlag: Array1D_bool
    var MyZoneEqFlag: Array1D_bool

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.HCoilOn = False
        self.NumOfUnitHeats = 0
        self.QZnReq = 0.0
        self.MySizeFlag.deallocate()
        self.CheckEquipName.deallocate()
        self.UnitHeat.deallocate()
        self.UnitHeatNumericFields.deallocate()
        self.InitUnitHeaterOneTimeFlag = True
        self.GetUnitHeaterInputFlag = True
        self.ZoneEquipmentListChecked = False
        self.SetMassFlowRateToZero = False
        self.MyEnvrnFlag.deallocate()
        self.MyPlantScanFlag.deallocate()
        self.MyZoneEqFlag.deallocate()

    def __init__(inout self):
