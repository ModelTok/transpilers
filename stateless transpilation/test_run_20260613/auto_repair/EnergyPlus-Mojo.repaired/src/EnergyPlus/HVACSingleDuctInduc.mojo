// Mojo translation of src/EnergyPlus/HVACSingleDuctInduc.cc
// WARNING: This is an automated translation; not yet verified.

from ObjexxFCL.Array import Array1D_string, Array1D_bool, Array1D
from ObjexxFCL.Fmath import *
from ObjexxFCL.Array.functions import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataDefineEquip import AirDistUnit
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import Node, NodeID, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsParent
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import ZoneSysEnergyDemand
from EnergyPlus.DataZoneEquipment import ZoneEquipConfig, CheckZoneEquipmentList
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import SolveRoot
from EnergyPlus.GeneralRoutines import *
from EnergyPlus.HVACSingleDuctInduc import *  // self-referential? Avoid circular if possible.
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor, getObjectDefMaxArgs, getObjectItem, getNumObjectsFound
from EnergyPlus.MixerComponent import GetZoneMixerIndex, SimAirMixer
from EnergyPlus.NodeInputManager import GetOnlySingleNode
from EnergyPlus.OutputProcessor import SetupOutputVariable
from EnergyPlus.OutputReportPredefined import PreDefTableEntry
from EnergyPlus.Plant.DataPlant import PlantLoop, PlantEquipmentType, CompData
from EnergyPlus.PlantUtilities import MyPlantSizingIndex, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate
from EnergyPlus.Psychrometrics import PsyCpAirFnW, PsyDeltaHSenFnTdb2W2Tdb1W1
from EnergyPlus.ScheduleManager import GetSchedule, GetScheduleAlwaysOn
from EnergyPlus.UtilityRoutines import FindItemInList, ShowFatalError, ShowSevereError, ShowContinueError, ShowContinueErrorTimeStamp, ShowWarningMessage, ShowRecurringWarningErrorAtEnd
from EnergyPlus.WaterCoils import GetCoilWaterInletNode, GetCoilWaterOutletNode, SimulateWaterCoilComponents, SetCoilDesFlow
from EnergyPlus.DataGlobals import *
from EnergyPlus.Autosizing.Base import reportSizerOutput, BaseSizer
from EnergyPlus.BranchNodeConnections import SetUpCompSets, TestCompSet
from EnergyPlus.DataZoneEquipment import ZoneEquipConfig
from EnergyPlus.DataSizing import TermUnitSizing
from EnergyPlus.DataPlant import PlantLocation
from EnergyPlus.DataDefineEquip import termUnitSizing
from EnergyPlus.Plant.Enums import *
from EnergyPlus.Data.Plant.Enums import PlantEquipmentType  // duplicate? Use single.
from EnergyPlus.DataSizing import TermUnitSizing

// Type aliases to match C++ names
alias Real64 = Float64
alias int = Int  // use with caution; prefer Int
alias bool = Bool

// Enum for induction unit type
@value
enum SingleDuct_CV: Int32 {
    Invalid = -1
    TwoPipeInduc = 0
    FourPipeInduc = 1
    Num = 2
}

// Struct for induction unit data
struct IndUnitData:
    var Name: String
    var UnitType: String
    var UnitType_Num: SingleDuct_CV
    var MaxTotAirVolFlow: Real64
    var MaxTotAirMassFlow: Real64
    var InducRatio: Real64
    var PriAirInNode: Int
    var SecAirInNode: Int
    var OutAirNode: Int
    var HWControlNode: Int
    var CWControlNode: Int
    var HCoilType: String
    var HCoil: String
    var HCoil_Num: Int
    var HeatingCoilType: PlantEquipmentType
    var MaxVolHotWaterFlow: Real64
    var MaxHotWaterFlow: Real64
    var MinVolHotWaterFlow: Real64
    var MinHotWaterFlow: Real64
    var HotControlOffset: Real64
    var HWPlantLoc: PlantLocation
    var HWCoilFailNum1: Int
    var HWCoilFailNum2: Int
    var CCoilType: String
    var CCoil: String
    var CCoil_Num: Int
    var CoolingCoilType: PlantEquipmentType
    var MaxVolColdWaterFlow: Real64
    var MaxColdWaterFlow: Real64
    var MinVolColdWaterFlow: Real64
    var MinColdWaterFlow: Real64
    var ColdControlOffset: Real64
    var CWPlantLoc: PlantLocation
    var CWCoilFailNum1: Int
    var CWCoilFailNum2: Int
    var MixerName: String
    var Mixer_Num: Int
    var MaxPriAirMassFlow: Real64
    var MaxSecAirMassFlow: Real64
    var ADUNum: Int
    var DesCoolingLoad: Real64
    var DesHeatingLoad: Real64
    var CtrlZoneNum: Int
    var CtrlZoneInNodeIndex: Int
    var AirLoopNum: Int
    var OutdoorAirFlowRate: Real64

    var availSched: Sched.Schedule

    def __init__(inout self):
        self.Name = ""
        self.UnitType = ""
        self.UnitType_Num = SingleDuct_CV.Invalid
        self.MaxTotAirVolFlow = 0.0
        self.MaxTotAirMassFlow = 0.0
        self.InducRatio = 2.5
        self.PriAirInNode = 0
        self.SecAirInNode = 0
        self.OutAirNode = 0
        self.HWControlNode = 0
        self.CWControlNode = 0
        self.HCoilType = ""
        self.HCoil = ""
        self.HCoil_Num = 0
        self.HeatingCoilType = PlantEquipmentType.Invalid
        self.MaxVolHotWaterFlow = 0.0
        self.MaxHotWaterFlow = 0.0
        self.MinVolHotWaterFlow = 0.0
        self.MinHotWaterFlow = 0.0
        self.HotControlOffset = 0.0
        self.HWPlantLoc = PlantLocation()
        self.HWCoilFailNum1 = 0
        self.HWCoilFailNum2 = 0
        self.CCoilType = ""
        self.CCoil = ""
        self.CCoil_Num = 0
        self.CoolingCoilType = PlantEquipmentType.Invalid
        self.MaxVolColdWaterFlow = 0.0
        self.MaxColdWaterFlow = 0.0
        self.MinVolColdWaterFlow = 0.0
        self.MinColdWaterFlow = 0.0
        self.ColdControlOffset = 0.0
        self.CWPlantLoc = PlantLocation()
        self.CWCoilFailNum1 = 0
        self.CWCoilFailNum2 = 0
        self.MixerName = ""
        self.Mixer_Num = 0
        self.MaxPriAirMassFlow = 0.0
        self.MaxSecAirMassFlow = 0.0
        self.ADUNum = 0
        self.DesCoolingLoad = 0.0
        self.DesHeatingLoad = 0.0
        self.CtrlZoneNum = 0
        self.CtrlZoneInNodeIndex = 0
        self.AirLoopNum = 0
        self.OutdoorAirFlowRate = 0.0
        self.availSched = Sched.Schedule()

    // Methods
    def ReportIndUnit(inout self, inout state: EnergyPlusData):
        self.CalcOutdoorAirVolumeFlowRate(state)

    def CalcOutdoorAirVolumeFlowRate(inout self, inout state: EnergyPlusData):
        if self.AirLoopNum > 0:
            self.OutdoorAirFlowRate = (state.dataLoopNodes.Node[self.PriAirInNode].MassFlowRate / state.dataEnvrn.StdRhoAir) * state.dataAirLoop.AirLoopFlow[self.AirLoopNum].OAFrac
        else:
            self.OutdoorAirFlowRate = 0.0

    def reportTerminalUnit(inout self, inout state: EnergyPlusData):
        var orp = state.dataOutRptPredefined
        var adu = state.dataDefineEquipment.AirDistUnit[self.ADUNum]
        if state.dataSize.TermUnitFinalZoneSizing.size() > 0:
            var sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum]
            PreDefTableEntry(state, orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
            PreDefTableEntry(state, orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
            PreDefTableEntry(state, orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
            PreDefTableEntry(state, orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
            PreDefTableEntry(state, orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
            PreDefTableEntry(state, orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
        PreDefTableEntry(state, orp.pdchAirTermTypeInp, adu.Name, self.UnitType)
        PreDefTableEntry(state, orp.pdchAirTermPrimFlow, adu.Name, self.MaxPriAirMassFlow)
        PreDefTableEntry(state, orp.pdchAirTermSecdFlow, adu.Name, self.MaxSecAirMassFlow)
        PreDefTableEntry(state, orp.pdchAirTermMinFlowSch, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermMaxFlowReh, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermMinOAflowSch, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermHeatCoilType, adu.Name, self.HCoilType)
        PreDefTableEntry(state, orp.pdchAirTermCoolCoilType, adu.Name, self.CCoilType)
        PreDefTableEntry(state, orp.pdchAirTermFanType, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermFanName, adu.Name, "n/a")


struct HVACSingleDuctInducData:
    var NumIndUnits: Int = 0
    var NumFourPipes: Int = 0
    var CheckEquipName: Array1D_bool
    var GetIUInputFlag: Bool = true
    var MyOneTimeFlag: Bool = true
    var MyEnvrnFlag: Array1D_bool
    var MySizeFlag: Array1D_bool
    var MyPlantScanFlag: Array1D_bool
    var MyAirDistInitFlag: Array1D_bool
    var IndUnit: Array1D[IndUnitData]
    var ZoneEquipmentListChecked: Bool = false

    def __init__(inout self):
        self.NumIndUnits = 0
        self.NumFourPipes = 0
        self.GetIUInputFlag = true
        self.MyOneTimeFlag = true
        self.ZoneEquipmentListChecked = false

    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self.NumIndUnits = 0
        self.IndUnit = Array1D[IndUnitData]()
        self.GetIUInputFlag = true
        self.NumFourPipes = 0
        self.MyOneTimeFlag = true
        self.MyEnvrnFlag = Array1D_bool()
        self.MySizeFlag = Array1D_bool()
        self.MyPlantScanFlag = Array1D_bool()
        self.MyAirDistInitFlag = Array1D_bool()
        self.CheckEquipName = Array1D_bool()
        self.ZoneEquipmentListChecked = false


// Global functions

def SimIndUnit(inout state: EnergyPlusData, CompName: StringLiteral, FirstHVACIteration: Bool, ZoneNum: Int, ZoneNodeNum: Int, inout CompIndex: Int):
    var IUNum: Int
    if state.dataHVACSingleDuctInduc.GetIUInputFlag:
        GetIndUnits(state)
        state.dataHVACSingleDuctInduc.GetIUInputFlag = false
    if CompIndex == 0:
        IUNum = FindItemInList(CompName, state.dataHVACSingleDuctInduc.IndUnit)
        if IUNum == 0:
            ShowFatalError(state, "SimIndUnit: Induction Unit not found=" + CompName)
        CompIndex = IUNum
    else:
        IUNum = CompIndex
        if IUNum > state.dataHVACSingleDuctInduc.NumIndUnits or IUNum < 1:
            ShowFatalError(state, "SimIndUnit: Invalid CompIndex passed=" + str(CompIndex) + ", Number of Induction Units=" + str(state.dataHVACSingleDuctInduc.NumIndUnits) + ", System name=" + CompName)
        if state.dataHVACSingleDuctInduc.CheckEquipName[IUNum]:
            if CompName != state.dataHVACSingleDuctInduc.IndUnit[IUNum].Name:
                ShowFatalError(state, "SimIndUnit: Invalid CompIndex passed=" + str(CompIndex) + ", Induction Unit name=" + CompName + ", stored Induction Unit for that index=" + state.dataHVACSingleDuctInduc.IndUnit[IUNum].Name)
            state.dataHVACSingleDuctInduc.CheckEquipName[IUNum] = false

    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]
    state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[indUnit.ADUNum].TermUnitSizingNum
    InitIndUnit(state, IUNum, FirstHVACIteration)
    state.dataSize.TermUnitIU = true
    match indUnit.UnitType_Num:
        case SingleDuct_CV.FourPipeInduc:
            SimFourPipeIndUnit(state, IUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
        case _:
            ShowSevereError(state, "Illegal Induction Unit Type used=" + indUnit.UnitType)
            ShowContinueError(state, "Occurs in Induction Unit=" + indUnit.Name)
            ShowFatalError(state, "Preceding condition causes termination.")
    state.dataSize.TermUnitIU = false
    indUnit.ReportIndUnit(state)


def GetIndUnits(inout state: EnergyPlusData):
    var RoutineName = "GetIndUnits "
    var routineName = "GetIndUnits"
    var Alphas: Array1D_string
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var Numbers: Array1D[Real64]
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    var NumAlphas: Int = 0
    var NumNumbers: Int = 0
    var TotalArgs: Int = 0
    var IOStatus: Int
    var ErrorsFound: Bool = false
    var CurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:FourPipeInduction"
    state.dataHVACSingleDuctInduc.NumFourPipes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACSingleDuctInduc.NumIndUnits = state.dataHVACSingleDuctInduc.NumFourPipes
    state.dataHVACSingleDuctInduc.IndUnit = Array1D[IndUnitData](size=state.dataHVACSingleDuctInduc.NumIndUnits)
    state.dataHVACSingleDuctInduc.CheckEquipName = Array1D_bool(size=state.dataHVACSingleDuctInduc.NumIndUnits, fill=True)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
    Alphas = Array1D_string(size=NumAlphas)
    cAlphaFields = Array1D_string(size=NumAlphas)
    cNumericFields = Array1D_string(size=NumNumbers)
    Numbers = Array1D[Real64](size=NumNumbers, fill=0.0)
    lAlphaBlanks = Array1D_bool(size=NumAlphas, fill=True)
    lNumericBlanks = Array1D_bool(size=NumNumbers, fill=True)

    for IUIndex in range(1, state.dataHVACSingleDuctInduc.NumFourPipes+1):   // 1-based index
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, IUIndex, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[1])
        var IUNum = IUIndex
        var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]
        indUnit.Name = Alphas[1]
        indUnit.UnitType = CurrentModuleObject
        indUnit.UnitType_Num = SingleDuct_CV.FourPipeInduc
        if lAlphaBlanks[2]:
            indUnit.availSched = GetScheduleAlwaysOn(state)
        elif (indUnit.availSched = GetSchedule(state, Alphas[2])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
            ErrorsFound = true
        indUnit.MaxTotAirVolFlow = Numbers[1]
        indUnit.InducRatio = Numbers[2]
        if lNumericBlanks[2]:
            indUnit.InducRatio = 2.5
        indUnit.PriAirInNode = GetOnlySingleNode(state, Alphas[3], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeInduction, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsParent, cAlphaFields[3])
        indUnit.SecAirInNode = GetOnlySingleNode(state, Alphas[4], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeInduction, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsParent, cAlphaFields[4])
        indUnit.OutAirNode = GetOnlySingleNode(state, Alphas[5], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeInduction, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsParent, cAlphaFields[5])
        indUnit.HCoilType = Alphas[6]
        if SameString(indUnit.HCoilType, "Coil:Heating:Water"):
            indUnit.HeatingCoilType = PlantEquipmentType.CoilWaterSimpleHeating
        indUnit.HCoil = Alphas[7]
        var IsNotOK: Bool = false
        indUnit.HWControlNode = GetCoilWaterInletNode(state, indUnit.HCoilType, indUnit.HCoil, IsNotOK)
        if IsNotOK:
            ShowContinueError(state, "In " + CurrentModuleObject + " = " + indUnit.Name)
            ShowContinueError(state, "..Only Coil:Heating:Water is allowed.")
            ErrorsFound = true
        indUnit.MaxVolHotWaterFlow = Numbers[3]
        indUnit.MinVolHotWaterFlow = Numbers[4]
        indUnit.HotControlOffset = Numbers[5]
        indUnit.CCoilType = Alphas[8]
        if SameString(indUnit.CCoilType, "Coil:Cooling:Water"):
            indUnit.CoolingCoilType = PlantEquipmentType.CoilWaterCooling
        elif SameString(indUnit.CCoilType, "Coil:Cooling:Water:DetailedGeometry"):
            indUnit.CoolingCoilType = PlantEquipmentType.CoilWaterDetailedFlatCooling
        indUnit.CCoil = Alphas[9]
        IsNotOK = false
        indUnit.CWControlNode = GetCoilWaterInletNode(state, indUnit.CCoilType, indUnit.CCoil, IsNotOK)
        if IsNotOK:
            ShowContinueError(state, "In " + CurrentModuleObject + " = " + indUnit.Name)
            ShowContinueError(state, "..Only Coil:Cooling:Water or Coil:Cooling:Water:DetailedGeometry is allowed.")
            ErrorsFound = true
        indUnit.MaxVolColdWaterFlow = Numbers[6]
        indUnit.MinVolColdWaterFlow = Numbers[7]
        indUnit.ColdControlOffset = Numbers[8]
        var errFlag: Bool = false
        indUnit.MixerName = Alphas[10]
        GetZoneMixerIndex(state, indUnit.MixerName, indUnit.Mixer_Num, errFlag, CurrentModuleObject)
        if errFlag:
            ShowContinueError(state, "...specified in " + CurrentModuleObject + " = " + indUnit.Name)
            ErrorsFound = true
        SetUpCompSets(state, indUnit.UnitType, indUnit.Name, indUnit.HCoilType, indUnit.HCoil, Alphas[4], "UNDEFINED")
        SetUpCompSets(state, indUnit.UnitType, indUnit.Name, indUnit.CCoilType, indUnit.CCoil, "UNDEFINED", "UNDEFINED")
        TestCompSet(state, indUnit.UnitType, indUnit.Name, NodeID(state, indUnit.PriAirInNode), NodeID(state, indUnit.OutAirNode), "Air Nodes")

        for ADUNum in range(1, state.dataDefineEquipment.AirDistUnit.size()+1):
            if indUnit.OutAirNode == state.dataDefineEquipment.AirDistUnit[ADUNum].OutletNodeNum:
                indUnit.ADUNum = ADUNum
        if indUnit.ADUNum == 0:
            ShowSevereError(state, RoutineName + "No matching Air Distribution Unit, for Unit = [" + indUnit.UnitType + "," + indUnit.Name + "].")
            ShowContinueError(state, "...should have outlet node=" + NodeID(state, indUnit.OutAirNode))
            ErrorsFound = true
        else:
            var AirNodeFound = false
            for CtrlZone in range(1, state.dataGlobal.NumOfZones+1):
                var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[CtrlZone]
                if not zoneEquipConfig.IsControlled:
                    continue
                for SupAirIn in range(1, zoneEquipConfig.NumInletNodes+1):
                    if indUnit.OutAirNode == zoneEquipConfig.InletNode[SupAirIn]:
                        if zoneEquipConfig.AirDistUnitCool[SupAirIn].OutNode > 0:
                            ShowSevereError(state, "Error in connecting a terminal unit to a zone")
                            ShowContinueError(state, NodeID(state, indUnit.OutAirNode) + " already connects to another zone")
                            ShowContinueError(state, "Occurs for terminal unit " + indUnit.UnitType + " = " + indUnit.Name)
                            ShowContinueError(state, "Check terminal unit node names for errors")
                            ErrorsFound = true
                        else:
                            zoneEquipConfig.AirDistUnitCool[SupAirIn].InNode = indUnit.PriAirInNode
                            zoneEquipConfig.AirDistUnitCool[SupAirIn].OutNode = indUnit.OutAirNode
                            state.dataDefineEquipment.AirDistUnit[indUnit.ADUNum].TermUnitSizingNum = zoneEquipConfig.AirDistUnitCool[SupAirIn].TermUnitSizingIndex
                            state.dataDefineEquipment.AirDistUnit[indUnit.ADUNum].ZoneEqNum = CtrlZone
                            indUnit.CtrlZoneNum = CtrlZone
                        indUnit.CtrlZoneInNodeIndex = SupAirIn
                        AirNodeFound = true
                        break
            if not AirNodeFound:
                ShowSevereError(state, "The outlet air node from the " + CurrentModuleObject + " = " + indUnit.Name)
                ShowContinueError(state, "did not have a matching Zone Equipment Inlet Node, Node =" + Alphas[3])
                ErrorsFound = true

        SetupOutputVariable(state, "Zone Air Terminal Outdoor Air Volume Flow Rate", Constant.Units.m3_s, indUnit.OutdoorAirFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, indUnit.Name)

    Alphas = Array1D_string()
    cAlphaFields = Array1D_string()
    cNumericFields = Array1D_string()
    Numbers = Array1D[Real64]()
    lAlphaBlanks = Array1D_bool()
    lNumericBlanks = Array1D_bool()
    if ErrorsFound:
        ShowFatalError(state, RoutineName + "Errors found in getting input. Preceding conditions cause termination.")


def InitIndUnit(inout state: EnergyPlusData, IUNum: Int, FirstHVACIteration: Bool):
    var RoutineName = "InitIndUnit"
    var PriNode: Int
    var SecNode: Int
    var IndRat: Real64
    var RhoAir: Real64
    var rho: Real64
    var ZoneEquipmentListChecked = state.dataHVACSingleDuctInduc.ZoneEquipmentListChecked

    if state.dataHVACSingleDuctInduc.MyOneTimeFlag:
        state.dataHVACSingleDuctInduc.MyEnvrnFlag = Array1D_bool(size=state.dataHVACSingleDuctInduc.NumIndUnits)
        state.dataHVACSingleDuctInduc.MySizeFlag = Array1D_bool(size=state.dataHVACSingleDuctInduc.NumIndUnits)
        state.dataHVACSingleDuctInduc.MyPlantScanFlag = Array1D_bool(size=state.dataHVACSingleDuctInduc.NumIndUnits)
        state.dataHVACSingleDuctInduc.MyAirDistInitFlag = Array1D_bool(size=state.dataHVACSingleDuctInduc.NumIndUnits)
        for i in range(state.dataHVACSingleDuctInduc.NumIndUnits):
            state.dataHVACSingleDuctInduc.MyEnvrnFlag[i] = true
            state.dataHVACSingleDuctInduc.MySizeFlag[i] = true
            state.dataHVACSingleDuctInduc.MyPlantScanFlag[i] = true
            state.dataHVACSingleDuctInduc.MyAirDistInitFlag[i] = true
        state.dataHVACSingleDuctInduc.MyOneTimeFlag = false

    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]

    if state.dataHVACSingleDuctInduc.MyPlantScanFlag[IUNum] and allocated(state.dataPlnt.PlantLoop):
        var errFlag: Bool = false
        if indUnit.HeatingCoilType == PlantEquipmentType.CoilWaterSimpleHeating:
            errFlag = false
            ScanPlantLoopsForObject(state, indUnit.HCoil, indUnit.HeatingCoilType, indUnit.HWPlantLoc, errFlag)
        if errFlag:
            ShowContinueError(state, "Reference Unit=\"" + indUnit.Name + "\", type=" + indUnit.UnitType)
        if indUnit.CoolingCoilType == PlantEquipmentType.CoilWaterCooling or indUnit.CoolingCoilType == PlantEquipmentType.CoilWaterDetailedFlatCooling:
            errFlag = false
            ScanPlantLoopsForObject(state, indUnit.CCoil, indUnit.CoolingCoilType, indUnit.CWPlantLoc, errFlag)
        if errFlag:
            ShowContinueError(state, "Reference Unit=\"" + indUnit.Name + "\", type=" + indUnit.UnitType)
            ShowFatalError(state, "InitIndUnit: Program terminated for previous conditions.")
        state.dataHVACSingleDuctInduc.MyPlantScanFlag[IUNum] = false
    elif state.dataHVACSingleDuctInduc.MyPlantScanFlag[IUNum] and not state.dataGlobal.AnyPlantInModel:
        state.dataHVACSingleDuctInduc.MyPlantScanFlag[IUNum] = false

    if state.dataHVACSingleDuctInduc.MyAirDistInitFlag[IUNum]:
        if state.dataSize.CurTermUnitSizingNum > 0:
            state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum].InducRat = indUnit.InducRatio
        if indUnit.AirLoopNum == 0:
            if (indUnit.CtrlZoneNum > 0) and (indUnit.CtrlZoneInNodeIndex > 0):
                indUnit.AirLoopNum = state.dataZoneEquip.ZoneEquipConfig[indUnit.CtrlZoneNum].InletNodeAirLoopNum[indUnit.CtrlZoneInNodeIndex]
                state.dataDefineEquipment.AirDistUnit[indUnit.ADUNum].AirLoopNum = indUnit.AirLoopNum
        else:
            state.dataHVACSingleDuctInduc.MyAirDistInitFlag[IUNum] = false

    if not ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        ZoneEquipmentListChecked = true
        for Loop in range(1, state.dataHVACSingleDuctInduc.NumIndUnits+1):
            if state.dataHVACSingleDuctInduc.IndUnit[Loop].ADUNum == 0:
                continue
            if CheckZoneEquipmentList(state, "ZONEHVAC:AIRDISTRIBUTIONUNIT", state.dataDefineEquipment.AirDistUnit[state.dataHVACSingleDuctInduc.IndUnit[Loop].ADUNum].Name):
                continue
            ShowSevereError(state, "InitIndUnit: ADU=[Air Distribution Unit," + state.dataDefineEquipment.AirDistUnit[state.dataHVACSingleDuctInduc.IndUnit[Loop].ADUNum].Name + "] is not on any ZoneHVAC:EquipmentList.")
            ShowContinueError(state, "...Unit=[" + state.dataHVACSingleDuctInduc.IndUnit[Loop].UnitType + "," + state.dataHVACSingleDuctInduc.IndUnit[Loop].Name + "] will not be simulated.")

    if not state.dataGlobal.SysSizingCalc and state.dataHVACSingleDuctInduc.MySizeFlag[IUNum]:
        SizeIndUnit(state, IUNum)
        state.dataHVACSingleDuctInduc.MySizeFlag[IUNum] = false

    if state.dataGlobal.BeginEnvrnFlag and state.dataHVACSingleDuctInduc.MyEnvrnFlag[IUNum]:
        RhoAir = state.dataEnvrn.StdRhoAir
        PriNode = indUnit.PriAirInNode
        SecNode = indUnit.SecAirInNode
        var OutletNode = indUnit.OutAirNode
        IndRat = indUnit.InducRatio
        if SameString(indUnit.UnitType, "AirTerminal:SingleDuct:ConstantVolume:FourPipeInduction"):
            indUnit.MaxTotAirMassFlow = RhoAir * indUnit.MaxTotAirVolFlow
            indUnit.MaxPriAirMassFlow = indUnit.MaxTotAirMassFlow / (1.0 + IndRat)
            indUnit.MaxSecAirMassFlow = IndRat * indUnit.MaxTotAirMassFlow / (1.0 + IndRat)
            state.dataLoopNodes.Node[PriNode].MassFlowRateMax = indUnit.MaxPriAirMassFlow
            state.dataLoopNodes.Node[PriNode].MassFlowRateMin = indUnit.MaxPriAirMassFlow
            state.dataLoopNodes.Node[SecNode].MassFlowRateMax = indUnit.MaxSecAirMassFlow
            state.dataLoopNodes.Node[SecNode].MassFlowRateMin = indUnit.MaxSecAirMassFlow
            state.dataLoopNodes.Node[OutletNode].MassFlowRateMax = indUnit.MaxTotAirMassFlow
        var HotConNode = indUnit.HWControlNode
        if HotConNode > 0 and not state.dataHVACSingleDuctInduc.MyPlantScanFlag[IUNum]:
            rho = indUnit.HWPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
            indUnit.MaxHotWaterFlow = rho * indUnit.MaxVolHotWaterFlow
            indUnit.MinHotWaterFlow = rho * indUnit.MinVolHotWaterFlow
            var HWOutletNode = getPlantComponent(state, indUnit.HWPlantLoc).NodeNumOut
            InitComponentNodes(state, indUnit.MinHotWaterFlow, indUnit.MaxHotWaterFlow, HotConNode, HWOutletNode)
        var ColdConNode = indUnit.CWControlNode
        if ColdConNode > 0:
            rho = indUnit.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
            indUnit.MaxColdWaterFlow = rho * indUnit.MaxVolColdWaterFlow
            indUnit.MinColdWaterFlow = rho * indUnit.MinVolColdWaterFlow
            var CWOutletNode = getPlantComponent(state, indUnit.CWPlantLoc).NodeNumOut
            InitComponentNodes(state, indUnit.MinColdWaterFlow, indUnit.MaxColdWaterFlow, ColdConNode, CWOutletNode)
        state.dataHVACSingleDuctInduc.MyEnvrnFlag[IUNum] = false

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHVACSingleDuctInduc.MyEnvrnFlag[IUNum] = true

    PriNode = indUnit.PriAirInNode
    SecNode = indUnit.SecAirInNode
    if FirstHVACIteration:
        if indUnit.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[PriNode].MassFlowRate > 0.0:
            if SameString(indUnit.UnitType, "AirTerminal:SingleDuct:ConstantVolume:FourPipeInduction"):
                state.dataLoopNodes.Node[PriNode].MassFlowRate = indUnit.MaxPriAirMassFlow
                state.dataLoopNodes.Node[SecNode].MassFlowRate = indUnit.MaxSecAirMassFlow
        else:
            state.dataLoopNodes.Node[PriNode].MassFlowRate = 0.0
            state.dataLoopNodes.Node[SecNode].MassFlowRate = 0.0
        if indUnit.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail > 0.0:
            if SameString(indUnit.UnitType, "AirTerminal:SingleDuct:ConstantVolume:FourPipeInduction"):
                state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail = indUnit.MaxPriAirMassFlow
                state.dataLoopNodes.Node[PriNode].MassFlowRateMinAvail = indUnit.MaxPriAirMassFlow
                state.dataLoopNodes.Node[SecNode].MassFlowRateMaxAvail = indUnit.MaxSecAirMassFlow
                state.dataLoopNodes.Node[SecNode].MassFlowRateMinAvail = indUnit.MaxSecAirMassFlow
        else:
            state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail = 0.0
            state.dataLoopNodes.Node[PriNode].MassFlowRateMinAvail = 0.0
            state.dataLoopNodes.Node[SecNode].MassFlowRateMaxAvail = 0.0
            state.dataLoopNodes.Node[SecNode].MassFlowRateMinAvail = 0.0


def SizeIndUnit(inout state: EnergyPlusData, IUNum: Int):
    var RoutineName = "SizeIndUnit"
    var DesCoilLoad: Real64
    var Cp: Real64
    var rho: Real64
    var DesPriVolFlow: Real64 = 0.0
    var CpAir: Real64 = 0.0
    var RhoAir = state.dataEnvrn.StdRhoAir
    var ErrorsFound: Bool = false
    var IsAutoSize: Bool = false
    var MaxTotAirVolFlowDes: Real64 = 0.0
    var MaxTotAirVolFlowUser: Real64 = 0.0
    var MaxVolHotWaterFlowDes: Real64 = 0.0
    var MaxVolHotWaterFlowUser: Real64 = 0.0
    var MaxVolColdWaterFlowDes: Real64 = 0.0
    var MaxVolColdWaterFlowUser: Real64 = 0.0

    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]

    if indUnit.MaxTotAirVolFlow == DataSizing.AutoSize:
        IsAutoSize = true

    if state.dataSize.CurZoneEqNum > 0:
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if indUnit.MaxTotAirVolFlow > 0.0:
                reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "User-Specified Maximum Total Air Flow Rate [m3/s]", indUnit.MaxTotAirVolFlow)
        else:
            CheckZoneSizing(state, indUnit.UnitType, indUnit.Name)
            if state.dataSize.CurTermUnitSizingNum > 0:
                MaxTotAirVolFlowDes = max(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow, state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow)
            else:
                MaxTotAirVolFlowDes = 0.0
            if MaxTotAirVolFlowDes < HVAC.SmallAirVolFlow:
                MaxTotAirVolFlowDes = 0.0
            if IsAutoSize:
                indUnit.MaxTotAirVolFlow = MaxTotAirVolFlowDes
                reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Total Air Flow Rate [m3/s]", MaxTotAirVolFlowDes)
            else:
                if indUnit.MaxTotAirVolFlow > 0.0 and MaxTotAirVolFlowDes > 0.0:
                    MaxTotAirVolFlowUser = indUnit.MaxTotAirVolFlow
                    reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Total Air Flow Rate [m3/s]", MaxTotAirVolFlowDes, "User-Specified Maximum Total Air Flow Rate [m3/s]", MaxTotAirVolFlowUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(MaxTotAirVolFlowDes - MaxTotAirVolFlowUser) / MaxTotAirVolFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, "SizeHVACSingleDuctInduction: Potential issue with equipment sizing for " + indUnit.UnitType + " = \"" + indUnit.Name + "\".")
                            ShowContinueError(state, "User-Specified Maximum Total Air Flow Rate of {:.6g} [m3/s]".format(MaxTotAirVolFlowUser))
                            ShowContinueError(state, "differs from Design Size Maximum Total Air Flow Rate of {:.6g} [m3/s]".format(MaxTotAirVolFlowDes))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")

    IsAutoSize = false
    if indUnit.MaxVolHotWaterFlow == DataSizing.AutoSize:
        IsAutoSize = true
    if (state.dataSize.CurZoneEqNum > 0) and (state.dataSize.CurTermUnitSizingNum > 0):
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if indUnit.MaxVolHotWaterFlow > 0.0:
                reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "User-Specified Maximum Hot Water Flow Rate [m3/s]", indUnit.MaxVolHotWaterFlow)
        else:
            CheckZoneSizing(state, indUnit.UnitType, indUnit.Name)
            if SameString(indUnit.HCoilType, "Coil:Heating:Water"):
                var CoilWaterInletNode = GetCoilWaterInletNode(state, "Coil:Heating:Water", indUnit.HCoil, ErrorsFound)
                var CoilWaterOutletNode = GetCoilWaterOutletNode(state, "Coil:Heating:Water", indUnit.HCoil, ErrorsFound)
                if IsAutoSize:
                    var PltSizHeatNum = MyPlantSizingIndex(state, "Coil:Heating:Water", indUnit.HCoil, CoilWaterInletNode, CoilWaterOutletNode, ErrorsFound)
                    if PltSizHeatNum > 0:
                        if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatMassFlow >= HVAC.SmallAirVolFlow:
                            DesPriVolFlow = indUnit.MaxTotAirVolFlow / (1.0 + indUnit.InducRatio)
                            CpAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].HeatDesHumRat)
                            if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtHeatPeak > 0.0:
                                DesCoilLoad = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].NonAirSysDesHeatLoad - CpAir * RhoAir * DesPriVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtHeatPeak)
                            else:
                                DesCoilLoad = CpAir * RhoAir * DesPriVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneSizThermSetPtLo - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU)
                            indUnit.DesHeatingLoad = DesCoilLoad
                            Cp = indUnit.HWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                            rho = indUnit.HWPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                            MaxVolHotWaterFlowDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizHeatNum].DeltaT * Cp * rho)
                            MaxVolHotWaterFlowDes = max(MaxVolHotWaterFlowDes, 0.0)
                        else:
                            MaxVolHotWaterFlowDes = 0.0
                    else:
                        ShowSevereError(state, "Autosizing of water flow requires a heating loop Sizing:Plant object")
                        ShowContinueError(state, "Occurs in " + indUnit.UnitType + " Object=" + indUnit.Name)
                        ErrorsFound = true
                    indUnit.MaxVolHotWaterFlow = MaxVolHotWaterFlowDes
                    reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Hot Water Flow Rate [m3/s]", MaxVolHotWaterFlowDes)
                    reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Inlet Air Temperature [C]", state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU)
                    reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Inlet Air Humidity Ratio [kgWater/kgDryAir]", state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInHumRatTU)
                else:
                    if indUnit.MaxVolHotWaterFlow > 0.0 and MaxVolHotWaterFlowDes > 0.0:
                        MaxVolHotWaterFlowUser = indUnit.MaxVolHotWaterFlow
                        reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Hot Water Flow Rate [m3/s]", MaxVolHotWaterFlowDes, "User-Specified Maximum Hot Water Flow Rate [m3/s]", MaxVolHotWaterFlowUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(MaxVolHotWaterFlowDes - MaxVolHotWaterFlowUser) / MaxVolHotWaterFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, "SizeHVACSingleDuctInduction: Potential issue with equipment sizing for " + indUnit.UnitType + " = \"" + indUnit.Name + "\".")
                                ShowContinueError(state, "User-Specified Maximum Hot Water Flow Rate of {:.6g} [m3/s]".format(MaxVolHotWaterFlowUser))
                                ShowContinueError(state, "differs from Design Size Maximum Hot Water Flow Rate of {:.6g} [m3/s]".format(MaxVolHotWaterFlowDes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            else:
                indUnit.MaxVolHotWaterFlow = 0.0

    IsAutoSize = false
    if indUnit.MaxVolColdWaterFlow == DataSizing.AutoSize:
        IsAutoSize = true
    if (state.dataSize.CurZoneEqNum > 0) and (state.dataSize.CurTermUnitSizingNum > 0):
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if indUnit.MaxVolColdWaterFlow > 0.0:
                reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "User-Specified Maximum Cold Water Flow Rate [m3/s]", indUnit.MaxVolColdWaterFlow)
        else:
            CheckZoneSizing(state, indUnit.UnitType, indUnit.Name)
            if SameString(indUnit.CCoilType, "Coil:Cooling:Water") or SameString(indUnit.CCoilType, "Coil:Cooling:Water:DetailedGeometry"):
                var CoilWaterInletNode = GetCoilWaterInletNode(state, indUnit.CCoilType, indUnit.CCoil, ErrorsFound)
                var CoilWaterOutletNode = GetCoilWaterOutletNode(state, indUnit.CCoilType, indUnit.CCoil, ErrorsFound)
                if IsAutoSize:
                    var PltSizCoolNum = MyPlantSizingIndex(state, indUnit.CCoilType, indUnit.CCoil, CoilWaterInletNode, CoilWaterOutletNode, ErrorsFound)
                    if PltSizCoolNum > 0:
                        if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolMassFlow >= HVAC.SmallAirVolFlow:
                            DesPriVolFlow = indUnit.MaxTotAirVolFlow / (1.0 + indUnit.InducRatio)
                            CpAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].CoolDesHumRat)
                            if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak > 0.0:
                                DesCoilLoad = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].NonAirSysDesCoolLoad - CpAir * RhoAir * DesPriVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU)
                            else:
                                DesCoilLoad = CpAir * RhoAir * DesPriVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneSizThermSetPtHi)
                            indUnit.DesCoolingLoad = DesCoilLoad
                            Cp = indUnit.CWPlantLoc.loop.glycol.getSpecificHeat(state, 5.0, RoutineName)
                            rho = indUnit.CWPlantLoc.loop.glycol.getDensity(state, 5.0, RoutineName)
                            MaxVolColdWaterFlowDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizCoolNum].DeltaT * Cp * rho)
                            MaxVolColdWaterFlowDes = max(MaxVolColdWaterFlowDes, 0.0)
                        else:
                            MaxVolColdWaterFlowDes = 0.0
                    else:
                        ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                        ShowContinueError(state, "Occurs in " + indUnit.UnitType + " Object=" + indUnit.Name)
                        ErrorsFound = true
                    indUnit.MaxVolColdWaterFlow = MaxVolColdWaterFlowDes
                    reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowDes)
                else:
                    if indUnit.MaxVolColdWaterFlow > 0.0 and MaxVolColdWaterFlowDes > 0.0:
                        MaxVolColdWaterFlowUser = indUnit.MaxVolColdWaterFlow
                        reportSizerOutput(state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowDes, "User-Specified Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(MaxVolColdWaterFlowDes - MaxVolColdWaterFlowUser) / MaxVolColdWaterFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, "SizeHVACSingleDuctInduction: Potential issue with equipment sizing for " + indUnit.UnitType + " = \"" + indUnit.Name + "\".")
                                ShowContinueError(state, "User-Specified Maximum Cold Water Flow Rate of {:.6g} [m3/s]".format(MaxVolColdWaterFlowUser))
                                ShowContinueError(state, "differs from Design Size Maximum Cold Water Flow Rate of {:.6g} [m3/s]".format(MaxVolColdWaterFlowDes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            else:
                indUnit.MaxVolColdWaterFlow = 0.0

    if state.dataSize.CurTermUnitSizingNum > 0:
        var termUnitSizing = state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum]
        termUnitSizing.AirVolFlow = indUnit.MaxTotAirVolFlow * indUnit.InducRatio / (1.0 + indUnit.InducRatio)
        termUnitSizing.MaxHWVolFlow = indUnit.MaxVolHotWaterFlow
        termUnitSizing.MaxCWVolFlow = indUnit.MaxVolColdWaterFlow
        termUnitSizing.DesCoolingLoad = indUnit.DesCoolingLoad
        termUnitSizing.DesHeatingLoad = indUnit.DesHeatingLoad
        termUnitSizing.InducRat = indUnit.InducRatio
        if SameString(indUnit.HCoilType, "Coil:Heating:Water"):
            SetCoilDesFlow(state, indUnit.HCoilType, indUnit.HCoil, termUnitSizing.AirVolFlow, ErrorsFound)
        if SameString(indUnit.CCoilType, "Coil:Cooling:Water:DetailedGeometry"):
            SetCoilDesFlow(state, indUnit.CCoilType, indUnit.CCoil, termUnitSizing.AirVolFlow, ErrorsFound)


def SimFourPipeIndUnit(inout state: EnergyPlusData, IUNum: Int, ZoneNum: Int, ZoneNodeNum: Int, FirstHVACIteration: Bool):
    var SolveMaxIter = 50
    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]
    var HWFlow: Real64
    var CWFlow: Real64
    var QPriOnly: Real64
    var ErrTolerance: Real64
    var UnitOn: Bool = true
    var PowerMet: Real64 = 0.0
    var InducRat = indUnit.InducRatio
    var PriNode = indUnit.PriAirInNode
    var SecNode = indUnit.SecAirInNode
    var OutletNode = indUnit.OutAirNode
    var HotControlNode = indUnit.HWControlNode
    var HWOutletNode = getPlantComponent(state, indUnit.HWPlantLoc).NodeNumOut
    var ColdControlNode = indUnit.CWControlNode
    var CWOutletNode = getPlantComponent(state, indUnit.CWPlantLoc).NodeNumOut
    var PriAirMassFlow = state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail
    var SecAirMassFlow = InducRat * PriAirMassFlow
    var QToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
    var QToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
    var MaxHotWaterFlow = indUnit.MaxHotWaterFlow
    SetComponentFlowRate(state, MaxHotWaterFlow, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)
    var MinHotWaterFlow = indUnit.MinHotWaterFlow
    SetComponentFlowRate(state, MinHotWaterFlow, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)
    var MaxColdWaterFlow = indUnit.MaxColdWaterFlow
    SetComponentFlowRate(state, MaxColdWaterFlow, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)
    var MinColdWaterFlow = indUnit.MinColdWaterFlow
    SetComponentFlowRate(state, MinColdWaterFlow, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)
    if indUnit.availSched.getCurrentVal() <= 0.0:
        UnitOn = false
    if PriAirMassFlow <= HVAC.SmallMassFlow:
        UnitOn = false
    state.dataLoopNodes.Node[PriNode].MassFlowRate = PriAirMassFlow
    state.dataLoopNodes.Node[SecNode].MassFlowRate = SecAirMassFlow
    CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow, QPriOnly)
    if UnitOn:
        var SolFlag = 0
        if QToHeatSetPt - QPriOnly > HVAC.SmallLoad:
            CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MaxHotWaterFlow, MinColdWaterFlow, PowerMet)
            if PowerMet > QToHeatSetPt + HVAC.SmallLoad:
                ErrTolerance = indUnit.HotControlOffset
                def f(HWFlow: Real64) -> Real64:
                    var UnitOutput: Real64
                    CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, HWFlow, MinColdWaterFlow, UnitOutput)
                    return (QToHeatSetPt - UnitOutput) / (PowerMet - QPriOnly)
                SolveRoot(state, ErrTolerance, SolveMaxIter, SolFlag, HWFlow, f, MinHotWaterFlow, MaxHotWaterFlow)
                if SolFlag == -1:
                    if indUnit.HWCoilFailNum1 == 0:
                        ShowWarningMessage(state, "SimFourPipeIndUnit: Hot water coil control failed for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"")
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "  Iteration limit [" + str(SolveMaxIter) + "] exceeded in calculating hot water mass flow rate")
                    ShowRecurringWarningErrorAtEnd(state, "SimFourPipeIndUnit: Hot water coil control failed (iteration limit [" + str(SolveMaxIter) + "]) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"", indUnit.HWCoilFailNum1)
                elif SolFlag == -2:
                    if indUnit.HWCoilFailNum2 == 0:
                        ShowWarningMessage(state, "SimFourPipeIndUnit: Hot water coil control failed (maximum flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"")
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "...Bad hot water maximum flow rate limits")
                        ShowContinueError(state, "...Given minimum water flow rate={:.6g} kg/s".format(MinHotWaterFlow))
                        ShowContinueError(state, "...Given maximum water flow rate={:.6g} kg/s".format(MaxHotWaterFlow))
                    ShowRecurringWarningErrorAtEnd(state, "SimFourPipeIndUnit: Hot water coil control failed (flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"", indUnit.HWCoilFailNum2, MaxHotWaterFlow, MinHotWaterFlow, _ , "[kg/s]", "[kg/s]")
        elif QToCoolSetPt - QPriOnly < -HVAC.SmallLoad:
            CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MaxColdWaterFlow, PowerMet)
            if PowerMet < QToCoolSetPt - HVAC.SmallLoad:
                ErrTolerance = indUnit.ColdControlOffset
                def f(CWFlow: Real64) -> Real64:
                    var UnitOutput: Real64
                    CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, CWFlow, UnitOutput)
                    return (QToCoolSetPt - UnitOutput) / (PowerMet - QPriOnly)
                SolveRoot(state, ErrTolerance, SolveMaxIter, SolFlag, CWFlow, f, MinColdWaterFlow, MaxColdWaterFlow)
                if SolFlag == -1:
                    if indUnit.CWCoilFailNum1 == 0:
                        ShowWarningMessage(state, "SimFourPipeIndUnit: Cold water coil control failed for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"")
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "  Iteration limit [" + str(SolveMaxIter) + "] exceeded in calculating cold water mass flow rate")
                    ShowRecurringWarningErrorAtEnd(state, "SimFourPipeIndUnit: Cold water coil control failed (iteration limit [" + str(SolveMaxIter) + "]) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"", indUnit.CWCoilFailNum1)
                elif SolFlag == -2:
                    if indUnit.CWCoilFailNum2 == 0:
                        ShowWarningMessage(state, "SimFourPipeIndUnit: Cold water coil control failed (maximum flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"")
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "...Bad cold water maximum flow rate limits")
                        ShowContinueError(state, "...Given minimum water flow rate={:.6g} kg/s".format(MinColdWaterFlow))
                        ShowContinueError(state, "...Given maximum water flow rate={:.6g} kg/s".format(MaxColdWaterFlow))
                    ShowRecurringWarningErrorAtEnd(state, "SimFourPipeIndUnit: Cold water coil control failed (flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"", indUnit.CWCoilFailNum2, MaxColdWaterFlow, MinColdWaterFlow, _ , "[kg/s]", "[kg/s]")
        else:
            CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow, PowerMet)
    else:
        CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow, PowerMet)
    state.dataLoopNodes.Node[OutletNode].MassFlowRateMax = indUnit.MaxTotAirMassFlow


def CalcFourPipeIndUnit(inout state: EnergyPlusData, IUNum: Int, FirstHVACIteration: Bool, ZoneNode: Int, HWFlow: Real64, CWFlow: Real64, inout LoadMet: Real64):
    var OutletNode: Int
    var PriNode: Int
    var HotControlNode: Int
    var ColdControlNode: Int
    var PriAirMassFlow: Real64
    var SecAirMassFlow: Real64
    var TotAirMassFlow: Real64
    var InducRat: Real64
    var mdotHW: Real64
    var mdotCW: Real64
    var HWOutletNode: Int
    var CWOutletNode: Int
    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum]
    PriNode = indUnit.PriAirInNode
    OutletNode = indUnit.OutAirNode
    PriAirMassFlow = state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail
    InducRat = indUnit.InducRatio
    SecAirMassFlow = InducRat * PriAirMassFlow
    TotAirMassFlow = PriAirMassFlow + SecAirMassFlow
    HotControlNode = indUnit.HWControlNode
    HWOutletNode = getPlantComponent(state, indUnit.HWPlantLoc).NodeNumOut
    ColdControlNode = indUnit.CWControlNode
    CWOutletNode = getPlantComponent(state, indUnit.CWPlantLoc).NodeNumOut
    mdotHW = HWFlow
    SetComponentFlowRate(state, mdotHW, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)
    mdotCW = CWFlow
    SetComponentFlowRate(state, mdotCW, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)
    SimulateWaterCoilComponents(state, indUnit.HCoil, FirstHVACIteration, indUnit.HCoil_Num)
    SimulateWaterCoilComponents(state, indUnit.CCoil, FirstHVACIteration, indUnit.CCoil_Num)
    SimAirMixer(state, indUnit.MixerName, indUnit.Mixer_Num)
    LoadMet = TotAirMassFlow * PsyDeltaHSenFnTdb2W2Tdb1W1(state.dataLoopNodes.Node[OutletNode].Temp, state.dataLoopNodes.Node[OutletNode].HumRat, state.dataLoopNodes.Node[ZoneNode].Temp, state.dataLoopNodes.Node[ZoneNode].HumRat)


def FourPipeInductionUnitHasMixer(inout state: EnergyPlusData, CompName: StringLiteral) -> Bool:
    if state.dataHVACSingleDuctInduc.GetIUInputFlag:
        GetIndUnits(state)
        state.dataHVACSingleDuctInduc.GetIUInputFlag = false
    if state.dataHVACSingleDuctInduc.NumIndUnits > 0:
        var ItemNum = FindItemInList(CompName, state.dataHVACSingleDuctInduc.IndUnit, lambda x: x.MixerName)
        if ItemNum > 0:
            return true
    return false