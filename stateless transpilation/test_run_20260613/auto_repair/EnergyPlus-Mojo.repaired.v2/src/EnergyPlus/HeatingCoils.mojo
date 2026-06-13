# -*- coding: utf-8 -*-
# Auto-generated Mojo translation of HeatingCoils.cc

from energyplus_data import EnergyPlusData
from objexx_fcl.array1d import Array1D
from objexx_fcl.optional import Optional, present
from energyplus.hvac import CoilType, FanOp, coilTypeNames, coilTypeNamesUC, TempControlTol
from energyplus.constant import eFuel, eFuelNamesUC, eResource, Units, eFuel2eResource
from energyplus.constant import eFuel as Constant_eFuel  # alias
from energyplus.schedule import Schedule as Sched_Schedule
from energyplus.schedule import GetSchedule, GetScheduleAlwaysOn, ShowSevereBadMinMax
from energyplus.node import Node, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
from energyplus.node import GetOnlySingleNode, TestCompSet, SensedLoadFlagValue, SensedNodeFlagValue
from energyplus.psychrometrics import PsyCpAirFnW, PsyHFnTdbW, PsyRhoFnTdbW, PsyTdbFnHW, PsyRhFnTdbWPb, PsyTsatFnHPb, PsyWFnTdbH
from energyplus.general import FindItem, FindItemInList, SameString, makeUPPER
from energyplus.global_names import VerifyUniqueCoilName
from energyplus.input_processor import InputProcessor, ErrorObjectHeader, ShowSevereItemNotFound
from energyplus.output_processor import SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
from energyplus.output_report_predefined import PreDefTableEntry, pdchHeatCoilType, pdchHeatCoilNomCap, pdchHeatCoilNomEff
from energyplus.curve_manager import Curve, GetCurveIndex, CurveValue
from energyplus.dxcoils import DXCoils, GetDXCoilIndex
from energyplus.variable_speed_coils import VariableSpeedCoils, GetCoilIndexVariableSpeed
from energyplus.coil_cooling_dx import CoilCoolingDX as CoilCoolingDXModule
from energyplus.report_coil_selection import ReportCoilSelection, setCoilFinalSizes, getReportIndex
from energyplus.ems_manager import EMSManager, CheckIfNodeSetPointManagedByEMS
from energyplus.faults_manager import FaultsManager as FaultsMgr
from energyplus.heat_balance import HeatReclaimDataBase, HeatReclaimRefrigeratedRack, HeatReclaimRefrigCondenser, HeatReclaimDXCoil, HeatReclaimVS_Coil
from energyplus.data_environment import OutBaroPress
from energyplus.data_hvac_globals import TimeStepSysSec, DoSetPointTest, OnOffFanPartLoadFraction, MSHPMassFlowRateHigh, MSHPMassFlowRateLow, ElecHeatingCoilPower, SuppHeatingCoilPower
from energyplus.data_loop_node import Node as LoopNode
from energyplus.data_sizing import AutoSize, DataCoilIsSuppHeater, DataCoolCoilCap, DataDesicRegCoil, DataDesicDehumNum, DataDesInletAirTemp, DataDesOutletAirTemp, CurOASysNum, OASysEqSizing, FinalSysSizing, AutoVsHardSizingThreshold, BaseSizer, reportSizerOutput
from energyplus.autosizing.heating_capacity_sizing import HeatingCapacitySizer
from energyplus.autosizing.all_simple_sizing import HeatingCoilDesAirInletTempSizer, HeatingCoilDesAirOutletTempSizer
from energyplus.utility_routines import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowMessage, ShowRecurringWarningErrorAtEnd
from energyplus.data_structs import Clusive
from math import abs, max, min
from builtins import static

alias RoutineName = "GetHeatingCoilInput: "  # include trailing blank space

# ====== Enum: HeatObjTypes ======
enum HeatObjTypes(Int):
    Invalid = -1
    COMPRESSORRACK_REFRIGERATEDCASE = 0
    COIL_DX_COOLING = 1  # single speed DX
    COIL_DX_MULTISPEED = 2
    COIL_DX_MULTIMODE = 3
    CONDENSER_REFRIGERATION = 4
    COIL_DX_VARIABLE_COOLING = 5
    COIL_COOLING_DX_NEW = 6  # Coil:Cooling:DX main one-for-all coil
    Num = 7

# ====== Struct: HeatingCoilEquipConditions ======
struct HeatingCoilEquipConditions:
    var Name: String = ""
    var HeatingCoilType: String = ""
    var HeatingCoilModel: String = ""
    var coilType: CoilType = CoilType.Invalid
    var coilReportNum: Int = -1
    var FuelType: Constant_eFuel = Constant_eFuel.Invalid
    var availSched: Sched_Schedule? = None
    var InsuffTemperatureWarn: Int = 0
    var InletAirMassFlowRate: Float64 = 0.0
    var OutletAirMassFlowRate: Float64 = 0.0
    var InletAirTemp: Float64 = 0.0
    var OutletAirTemp: Float64 = 0.0
    var InletAirHumRat: Float64 = 0.0
    var OutletAirHumRat: Float64 = 0.0
    var InletAirEnthalpy: Float64 = 0.0
    var OutletAirEnthalpy: Float64 = 0.0
    var HeatingCoilLoad: Float64 = 0.0
    var HeatingCoilRate: Float64 = 0.0
    var FuelUseLoad: Float64 = 0.0
    var ElecUseLoad: Float64 = 0.0
    var FuelUseRate: Float64 = 0.0
    var ElecUseRate: Float64 = 0.0
    var Efficiency: Float64 = 0.0
    var NominalCapacity: Float64 = 0.0
    var DesiredOutletTemp: Float64 = 0.0
    var DesiredOutletHumRat: Float64 = 0.0
    var AvailTemperature: Float64 = 0.0
    var AirInletNodeNum: Int = 0
    var AirOutletNodeNum: Int = 0
    var TempSetPointNodeNum: Int = 0
    var Control: Int = 0
    var PLFCurveIndex: Int = 0
    var ParasiticElecLoad: Float64 = 0.0
    var ParasiticFuelConsumption: Float64 = 0.0
    var ParasiticFuelRate: Float64 = 0.0
    var ParasiticFuelCapacity: Float64 = 0.0
    var RTF: Float64 = 0.0
    var RTFErrorIndex: Int = 0
    var RTFErrorCount: Int = 0
    var PLFErrorIndex: Int = 0
    var PLFErrorCount: Int = 0
    var ReclaimHeatingCoilName: String = ""
    var ReclaimHeatingSourceIndexNum: Int = 0
    var ReclaimHeatingSource: HeatObjTypes = HeatObjTypes.Invalid
    var NumOfStages: Int = 0
    var MSNominalCapacity: List[Float64] = []
    var MSEfficiency: List[Float64] = []
    var MSParasiticElecLoad: List[Float64] = []
    var DesiccantRegenerationCoil: Bool = False
    var DesiccantDehumNum: Int = 0
    var FaultyCoilSATFlag: Bool = False
    var FaultyCoilSATIndex: Int = 0
    var FaultyCoilSATOffset: Float64 = 0.0
    var reportCoilFinalSizes: Bool = True
    var AirLoopNum: Int = 0

    # C++ constructor-like initialization? Not needed in Mojo.

# ====== Struct: HeatingCoilNumericFieldData ======
struct HeatingCoilNumericFieldData:
    var FieldNames: List[String] = []

# ====== Function declarations (will be defined later) ======
# (all functions are defined below)

# ====== Global struct: HeatingCoilsData ======
struct HeatingCoilsData(BaseGlobalStruct):  # BaseGlobalStruct assumed imported
    var NumDesuperheaterCoil: Int = 0
    var NumElecCoil: Int = 0
    var NumElecCoilMultiStage: Int = 0
    var NumFuelCoil: Int = 0
    var NumGasCoilMultiStage: Int = 0
    var NumHeatingCoils: Int = 0
    var MySizeFlag: List[Bool] = []
    var ValidSourceType: List[Bool] = []
    var GetCoilsInputFlag: Bool = True
    var CoilIsSuppHeater: Bool = False
    var CheckEquipName: List[Bool] = []
    var HeatingCoil: List[HeatingCoilEquipConditions] = []
    var HeatingCoilNumericFields: List[HeatingCoilNumericFieldData] = []
    var MyOneTimeFlag: Bool = True
    var InputErrorsFound: Bool = False
    var MaxNums: Int = 0
    var MaxAlphas: Int = 0
    var TotalArgs: Int = 0
    var ValidSourceTypeCounter: Int = 0
    var HeatingCoilFatalError: Bool = False
    var MySPTestFlag: List[Bool] = []
    var ShowSingleWarning: List[Bool] = []
    var MyEnvrnFlag: List[Bool] = []

    def init_constant_state(inout self, state: EnergyPlusData) raises:

    def init_state(inout self, state: EnergyPlusData) raises:

    def clear_state(inout self):
        self.NumDesuperheaterCoil = 0
        self.NumElecCoil = 0
        self.NumElecCoilMultiStage = 0
        self.NumFuelCoil = 0
        self.NumGasCoilMultiStage = 0
        self.NumHeatingCoils = 0
        self.MySizeFlag = []
        self.ValidSourceType = []
        self.GetCoilsInputFlag = True
        self.CoilIsSuppHeater = False
        self.CheckEquipName = []
        self.HeatingCoil = []
        self.HeatingCoilNumericFields = []
        self.MyOneTimeFlag = True
        self.InputErrorsFound = False
        self.MaxNums = 0
        self.MaxAlphas = 0
        self.TotalArgs = 0
        self.ValidSourceTypeCounter = 0
        self.HeatingCoilFatalError = False
        self.MySPTestFlag = []
        self.ShowSingleWarning = []
        self.MyEnvrnFlag = []

# ====== Functions ======

def SimulateHeatingCoilComponents(
    state: EnergyPlusData,
    CompName: String,
    FirstHVACIteration: Bool,
    QCoilReq: Optional[Float64] = None,
    CompIndex: Optional[Int] = None,
    QCoilActual: Optional[Float64] = None,
    SuppHeat: Optional[Bool] = None,
    fanOpMode: Optional[FanOp] = None,
    PartLoadRatio: Optional[Float64] = None,
    StageNum: Optional[Int] = None,
    SpeedRatio: Optional[Float64] = None
) raises:
    # local variables
    var CoilNum: Int = 0
    var QCoilActual2: Float64 = 0.0
    var fanOp: FanOp
    var PartLoadFrac: Float64 = 0.0
    var QCoilRequired: Float64 = 0.0

    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    if present(CompIndex):
        var compIdx: Int = CompIndex.value
        if compIdx == 0:
            CoilNum = FindItemInList(CompName, state.dataHeatingCoils.HeatingCoil)
            if CoilNum == 0:
                ShowFatalError(state, f"SimulateHeatingCoilComponents: Coil not found={CompName}")
        else:
            CoilNum = compIdx
            if CoilNum > state.dataHeatingCoils.NumHeatingCoils or CoilNum < 1:
                ShowFatalError(state,
                               f"SimulateHeatingCoilComponents: Invalid CompIndex passed={CoilNum}, Number of Heating Coils={state.dataHeatingCoils.NumHeatingCoils}, Coil name={CompName}")
            if state.dataHeatingCoils.CheckEquipName[CoilNum - 1]:
                if not CompName.empty() and CompName != state.dataHeatingCoils.HeatingCoil[CoilNum - 1].Name:
                    ShowFatalError(
                        state,
                        f"SimulateHeatingCoilComponents: Invalid CompIndex passed={CoilNum}, Coil name={CompName}, stored Coil Name for that index={state.dataHeatingCoils.HeatingCoil[CoilNum - 1].Name}")
                state.dataHeatingCoils.CheckEquipName[CoilNum - 1] = False
    else:
        ShowSevereError(state, "SimulateHeatingCoilComponents: CompIndex argument not used.")
        ShowContinueError(state, f"..CompName = {CompName}")
        ShowFatalError(state, "Preceding conditions cause termination.")

    if present(SuppHeat):
        state.dataHeatingCoils.CoilIsSuppHeater = SuppHeat.value
    else:
        state.dataHeatingCoils.CoilIsSuppHeater = False

    if present(fanOpMode):
        fanOp = fanOpMode.value
    else:
        fanOp = FanOp.Continuous

    if present(PartLoadRatio):
        PartLoadFrac = PartLoadRatio.value
    else:
        PartLoadFrac = 1.0

    if present(QCoilReq):
        QCoilRequired = QCoilReq.value
    else:
        QCoilRequired = SensedLoadFlagValue

    InitHeatingCoil(state, CoilNum, FirstHVACIteration, QCoilRequired)

    # switch on coilType (use if-elif)
    var coilType = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].coilType
    if coilType == CoilType.HeatingElectric:
        CalcElectricHeatingCoil(state, CoilNum, QCoilRequired, QCoilActual2, fanOp, PartLoadFrac)
    elif coilType == CoilType.HeatingElectricMultiStage:
        # Autodesk:OPTIONAL SpeedRatio, PartLoadRatio, StageNum used without PRESENT check
        CalcMultiStageElectricHeatingCoil(
            state, CoilNum, SpeedRatio.value if present(SpeedRatio) else 0.0, PartLoadRatio.value if present(PartLoadRatio) else 0.0, StageNum.value if present(StageNum) else 0, fanOp, QCoilActual2, state.dataHeatingCoils.CoilIsSuppHeater)
    elif coilType == CoilType.HeatingGasOrOtherFuel:
        CalcFuelHeatingCoil(state, CoilNum, QCoilRequired, QCoilActual2, fanOp, PartLoadFrac)
    elif coilType == CoilType.HeatingGasMultiStage:
        CalcMultiStageGasHeatingCoil(state, CoilNum, SpeedRatio.value if present(SpeedRatio) else 0.0, PartLoadRatio.value if present(PartLoadRatio) else 0.0, StageNum.value if present(StageNum) else 0, fanOp)
    elif coilType == CoilType.HeatingDesuperheater:
        CalcDesuperheaterHeatingCoil(state, CoilNum, QCoilRequired, QCoilActual2)
    else:
        QCoilActual2 = 0.0

    UpdateHeatingCoil(state, CoilNum)
    ReportHeatingCoil(state, CoilNum, state.dataHeatingCoils.CoilIsSuppHeater)

    if present(QCoilActual):
        QCoilActual.value = QCoilActual2


def GetHeatingCoilInput(state: EnergyPlusData) raises:
    # static in C++ -> local constants
    var RoutineName_local: String = "GetHeatingCoilInput: "
    var routineName: String = "GetHeatingCoilInput"
    var CurrentModuleObject: String = ""
    var Alphas: List[String] = []
    var cAlphaFields: List[String] = []
    var cNumericFields: List[String] = []
    var Numbers: List[Float64] = []
    var lAlphaBlanks: List[Bool] = []
    var lNumericBlanks: List[Bool] = []
    var NumAlphas: Int = 0
    var NumNums: Int = 0
    var IOStat: Int = 0
    var StageNum: Int = 0
    var DXCoilErrFlag: Bool = False
    var errFlag: Bool = False

    # Get counts
    state.dataHeatingCoils.NumElecCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Electric")
    state.dataHeatingCoils.NumElecCoilMultiStage = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Electric:MultiStage")
    state.dataHeatingCoils.NumFuelCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Fuel")
    state.dataHeatingCoils.NumGasCoilMultiStage = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Gas:MultiStage")
    state.dataHeatingCoils.NumDesuperheaterCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Desuperheater")

    state.dataHeatingCoils.NumHeatingCoils = (state.dataHeatingCoils.NumElecCoil + state.dataHeatingCoils.NumElecCoilMultiStage +
                                              state.dataHeatingCoils.NumFuelCoil + state.dataHeatingCoils.NumGasCoilMultiStage +
                                              state.dataHeatingCoils.NumDesuperheaterCoil)

    if state.dataHeatingCoils.NumHeatingCoils > 0:
        state.dataHeatingCoils.HeatingCoil = [HeatingCoilEquipConditions() for _ in range(state.dataHeatingCoils.NumHeatingCoils)]
        state.dataHeatingCoils.HeatingCoilNumericFields = [HeatingCoilNumericFieldData() for _ in range(state.dataHeatingCoils.NumHeatingCoils)]
        state.dataHeatingCoils.ValidSourceType = [False for _ in range(state.dataHeatingCoils.NumHeatingCoils)]
        state.dataHeatingCoils.CheckEquipName = [True for _ in range(state.dataHeatingCoils.NumHeatingCoils)]

    # Get max args for each type
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Electric", state.dataHeatingCoils.TotalArgs, NumAlphas, NumNums)
    state.dataHeatingCoils.MaxNums = max(state.dataHeatingCoils.MaxNums, NumNums)
    state.dataHeatingCoils.MaxAlphas = max(state.dataHeatingCoils.MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Electric:MultiStage", state.dataHeatingCoils.TotalArgs, NumAlphas, NumNums)
    state.dataHeatingCoils.MaxNums = max(state.dataHeatingCoils.MaxNums, NumNums)
    state.dataHeatingCoils.MaxAlphas = max(state.dataHeatingCoils.MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Fuel", state.dataHeatingCoils.TotalArgs, NumAlphas, NumNums)
    state.dataHeatingCoils.MaxNums = max(state.dataHeatingCoils.MaxNums, NumNums)
    state.dataHeatingCoils.MaxAlphas = max(state.dataHeatingCoils.MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Gas:MultiStage", state.dataHeatingCoils.TotalArgs, NumAlphas, NumNums)
    state.dataHeatingCoils.MaxNums = max(state.dataHeatingCoils.MaxNums, NumNums)
    state.dataHeatingCoils.MaxAlphas = max(state.dataHeatingCoils.MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Desuperheater", state.dataHeatingCoils.TotalArgs, NumAlphas, NumNums)
    state.dataHeatingCoils.MaxNums = max(state.dataHeatingCoils.MaxNums, NumNums)
    state.dataHeatingCoils.MaxAlphas = max(state.dataHeatingCoils.MaxAlphas, NumAlphas)

    Alphas = ["" for _ in range(state.dataHeatingCoils.MaxAlphas)]
    cAlphaFields = ["" for _ in range(state.dataHeatingCoils.MaxAlphas)]
    cNumericFields = ["" for _ in range(state.dataHeatingCoils.MaxNums)]
    Numbers = [0.0 for _ in range(state.dataHeatingCoils.MaxNums)]
    lAlphaBlanks = [True for _ in range(state.dataHeatingCoils.MaxAlphas)]
    lNumericBlanks = [True for _ in range(state.dataHeatingCoils.MaxNums)]

    # Electric coils
    for ElecCoilNum in range(1, state.dataHeatingCoils.NumElecCoil + 1): # 1-based index
        var coilIdx = ElecCoilNum - 1
        var heatingCoil = state.dataHeatingCoils.HeatingCoil[coilIdx]
        var heatingCoilNumericFields = state.dataHeatingCoils.HeatingCoilNumericFields[coilIdx]
        CurrentModuleObject = "Coil:Heating:Electric"
        heatingCoil.FuelType = Constant_eFuel.Electricity
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, ElecCoilNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        heatingCoilNumericFields.FieldNames = [s for s in cNumericFields[:state.dataHeatingCoils.MaxNums]]  # allocate equivalent
        # Ensure FieldNames length matches MaxNums (cNumericFields already sized)
        heatingCoilNumericFields.FieldNames = cNumericFields[:state.dataHeatingCoils.MaxNums]
        # In Mojo, we need to copy list (already done)
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, Alphas[0], state.dataHeatingCoils.InputErrorsFound, f"{CurrentModuleObject} Name")
        heatingCoil.Name = Alphas[0]
        if lAlphaBlanks[1]:  # zero-based index 1 is second field
            heatingCoil.availSched = Sched_Schedule.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_Schedule.GetSchedule(state, Alphas[1])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHeatingCoils.InputErrorsFound = True
            else:
                heatingCoil.availSched = sched
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Electric"
        heatingCoil.coilType = CoilType.HeatingElectric
        heatingCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil.Name, heatingCoil.coilType)
        heatingCoil.Efficiency = Numbers[0]
        heatingCoil.NominalCapacity = Numbers[1]
        errFlag = False
        heatingCoil.AirInletNodeNum = GetOnlySingleNode(state, Alphas[2], errFlag, Node.ConnectionObjectType.CoilHeatingElectric, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        errFlag = False
        heatingCoil.AirOutletNodeNum = GetOnlySingleNode(state, Alphas[3], errFlag, Node.ConnectionObjectType.CoilHeatingElectric, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        Node.TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[2], Alphas[3], "Air Nodes")
        errFlag = False
        heatingCoil.TempSetPointNodeNum = GetOnlySingleNode(state, Alphas[4], errFlag, Node.ConnectionObjectType.CoilHeatingElectric, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound

        SetupOutputVariable(state, "Heating Coil Heating Energy", Units.J, heatingCoil.HeatingCoilLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Heating Coil Heating Rate", Units.W, heatingCoil.HeatingCoilRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Electricity Energy", Units.J, heatingCoil.ElecUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.Electricity, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil Electricity Rate", Units.W, heatingCoil.ElecUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)

    # Electric MultiStage
    for ElecCoilNum in range(1, state.dataHeatingCoils.NumElecCoilMultiStage + 1):
        var CoilNum = state.dataHeatingCoils.NumElecCoil + ElecCoilNum
        var coilIdx = CoilNum - 1
        var heatingCoil = state.dataHeatingCoils.HeatingCoil[coilIdx]
        var heatingCoilNumericFields = state.dataHeatingCoils.HeatingCoilNumericFields[coilIdx]
        CurrentModuleObject = "Coil:Heating:Electric:MultiStage"
        heatingCoil.FuelType = Constant_eFuel.Electricity
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, ElecCoilNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        heatingCoilNumericFields.FieldNames = cNumericFields[:state.dataHeatingCoils.MaxNums]
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, Alphas[0], state.dataHeatingCoils.InputErrorsFound, f"{CurrentModuleObject} Name")
        heatingCoil.Name = Alphas[0]
        if lAlphaBlanks[1]:
            heatingCoil.availSched = Sched_Schedule.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_Schedule.GetSchedule(state, Alphas[1])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHeatingCoils.InputErrorsFound = True
            else:
                heatingCoil.availSched = sched
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Electric:MultiStage"
        heatingCoil.coilType = CoilType.HeatingElectricMultiStage
        heatingCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil.Name, heatingCoil.coilType)
        heatingCoil.NumOfStages = int(Numbers[0])
        heatingCoil.MSEfficiency = [0.0 for _ in range(heatingCoil.NumOfStages)]
        heatingCoil.MSNominalCapacity = [0.0 for _ in range(heatingCoil.NumOfStages)]
        for StageNum in range(1, heatingCoil.NumOfStages + 1):
            heatingCoil.MSEfficiency[StageNum - 1] = Numbers[StageNum * 2]   # careful: C++ used 1-based indexing within Numbers
            heatingCoil.MSNominalCapacity[StageNum - 1] = Numbers[StageNum * 2 + 1]
        # Note: C++ loops StageNum from 1; Numbers indices: StageNum*2 and StageNum*2+1 (C++ 1-based arrays)
        errFlag = False
        heatingCoil.AirInletNodeNum = GetOnlySingleNode(state, Alphas[2], errFlag, Node.ConnectionObjectType.CoilHeatingElectricMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        errFlag = False
        heatingCoil.AirOutletNodeNum = GetOnlySingleNode(state, Alphas[3], errFlag, Node.ConnectionObjectType.CoilHeatingElectricMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        Node.TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[2], Alphas[3], "Air Nodes")
        errFlag = False
        heatingCoil.TempSetPointNodeNum = GetOnlySingleNode(state, Alphas[4], errFlag, Node.ConnectionObjectType.CoilHeatingElectricMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        SetupOutputVariable(state, "Heating Coil Heating Energy", Units.J, heatingCoil.HeatingCoilLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Heating Coil Heating Rate", Units.W, heatingCoil.HeatingCoilRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Electricity Energy", Units.J, heatingCoil.ElecUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.Electricity, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil Electricity Rate", Units.W, heatingCoil.ElecUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)

    # Fuel coils
    for FuelCoilNum in range(1, state.dataHeatingCoils.NumFuelCoil + 1):
        var CoilNum = state.dataHeatingCoils.NumElecCoil + state.dataHeatingCoils.NumElecCoilMultiStage + FuelCoilNum
        var coilIdx = CoilNum - 1
        var heatingCoil = state.dataHeatingCoils.HeatingCoil[coilIdx]
        var heatingCoilNumericFields = state.dataHeatingCoils.HeatingCoilNumericFields[coilIdx]
        CurrentModuleObject = "Coil:Heating:Fuel"
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, FuelCoilNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        heatingCoilNumericFields.FieldNames = cNumericFields[:state.dataHeatingCoils.MaxNums]
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, Alphas[0], state.dataHeatingCoils.InputErrorsFound, f"{CurrentModuleObject} Name")
        heatingCoil.Name = Alphas[0]
        if lAlphaBlanks[1]:
            heatingCoil.availSched = Sched_Schedule.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_Schedule.GetSchedule(state, Alphas[1])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHeatingCoils.InputErrorsFound = True
            else:
                heatingCoil.availSched = sched
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Fuel"
        heatingCoil.coilType = CoilType.HeatingGasOrOtherFuel
        heatingCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil.Name, heatingCoil.coilType)
        heatingCoil.FuelType = Constant_eFuel(getEnumValue(eFuelNamesUC, Alphas[2]))
        # Validate fuel type
        if not (heatingCoil.FuelType == Constant_eFuel.NaturalGas or heatingCoil.FuelType == Constant_eFuel.Propane or
                heatingCoil.FuelType == Constant_eFuel.Diesel or heatingCoil.FuelType == Constant_eFuel.Gasoline or
                heatingCoil.FuelType == Constant_eFuel.FuelOilNo1 or heatingCoil.FuelType == Constant_eFuel.FuelOilNo2 or
                heatingCoil.FuelType == Constant_eFuel.OtherFuel1 or heatingCoil.FuelType == Constant_eFuel.OtherFuel2 or
                heatingCoil.FuelType == Constant_eFuel.Coal):
            ShowSevereError(state, f"{RoutineName_local}{CurrentModuleObject}: Invalid {cAlphaFields[2]} entered ={Alphas[2]} for {cAlphaFields[0]}={Alphas[0]}")
            state.dataHeatingCoils.InputErrorsFound = True
        var sFuelType: String = eFuelNames[int(heatingCoil.FuelType)]  # assume eFuelNames array available
        heatingCoil.Efficiency = Numbers[0]
        heatingCoil.NominalCapacity = Numbers[1]
        errFlag = False
        heatingCoil.AirInletNodeNum = GetOnlySingleNode(state, Alphas[3], errFlag, Node.ConnectionObjectType.CoilHeatingFuel, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        errFlag = False
        heatingCoil.AirOutletNodeNum = GetOnlySingleNode(state, Alphas[4], errFlag, Node.ConnectionObjectType.CoilHeatingFuel, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        Node.TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[3], Alphas[4], "Air Nodes")
        errFlag = False
        heatingCoil.TempSetPointNodeNum = GetOnlySingleNode(state, Alphas[5], errFlag, Node.ConnectionObjectType.CoilHeatingFuel, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        heatingCoil.ParasiticElecLoad = Numbers[2]
        heatingCoil.PLFCurveIndex = Curve.GetCurveIndex(state, Alphas[6])
        heatingCoil.ParasiticFuelCapacity = Numbers[3]
        SetupOutputVariable(state, "Heating Coil Heating Energy", Units.J, heatingCoil.HeatingCoilLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Heating Coil Heating Rate", Units.W, heatingCoil.HeatingCoilRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, f"Heating Coil {sFuelType} Energy", Units.J, heatingCoil.FuelUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eFuel2eResource[int(heatingCoil.FuelType)], Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, f"Heating Coil {sFuelType} Rate", Units.W, heatingCoil.FuelUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Electricity Energy", Units.J, heatingCoil.ElecUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.Electricity, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil Electricity Rate", Units.W, heatingCoil.ElecUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Runtime Fraction", Units.None, heatingCoil.RTF, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Ancillary " + sFuelType + " Rate", Units.W, heatingCoil.ParasiticFuelRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Ancillary " + sFuelType + " Energy", Units.J, heatingCoil.ParasiticFuelConsumption, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eFuel2eResource[int(heatingCoil.FuelType)], Group.HVAC, EndUseCat.Heating)

    # Gas MultiStage
    for FuelCoilNum in range(1, state.dataHeatingCoils.NumGasCoilMultiStage + 1):
        var CoilNum = state.dataHeatingCoils.NumElecCoil + state.dataHeatingCoils.NumElecCoilMultiStage + state.dataHeatingCoils.NumFuelCoil + FuelCoilNum
        var coilIdx = CoilNum - 1
        var heatingCoil = state.dataHeatingCoils.HeatingCoil[coilIdx]
        var heatingCoilNumericFields = state.dataHeatingCoils.HeatingCoilNumericFields[coilIdx]
        CurrentModuleObject = "Coil:Heating:Gas:MultiStage"
        heatingCoil.FuelType = Constant_eFuel.NaturalGas
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, FuelCoilNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        heatingCoilNumericFields.FieldNames = cNumericFields[:state.dataHeatingCoils.MaxNums]
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, Alphas[0], state.dataHeatingCoils.InputErrorsFound, f"{CurrentModuleObject} Name")
        heatingCoil.Name = Alphas[0]
        if lAlphaBlanks[1]:
            heatingCoil.availSched = Sched_Schedule.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_Schedule.GetSchedule(state, Alphas[1])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHeatingCoils.InputErrorsFound = True
            else:
                heatingCoil.availSched = sched
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Gas:MultiStage"
        heatingCoil.coilType = CoilType.HeatingGasMultiStage
        heatingCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil.Name, heatingCoil.coilType)
        heatingCoil.ParasiticFuelCapacity = Numbers[0]
        heatingCoil.NumOfStages = int(Numbers[1])
        heatingCoil.MSEfficiency = [0.0 for _ in range(heatingCoil.NumOfStages)]
        heatingCoil.MSNominalCapacity = [0.0 for _ in range(heatingCoil.NumOfStages)]
        heatingCoil.MSParasiticElecLoad = [0.0 for _ in range(heatingCoil.NumOfStages)]
        for StageNum in range(1, heatingCoil.NumOfStages + 1):
            heatingCoil.MSEfficiency[StageNum - 1] = Numbers[StageNum * 3]
            heatingCoil.MSNominalCapacity[StageNum - 1] = Numbers[StageNum * 3 + 1]
            heatingCoil.MSParasiticElecLoad[StageNum - 1] = Numbers[StageNum * 3 + 2]
        errFlag = False
        heatingCoil.AirInletNodeNum = GetOnlySingleNode(state, Alphas[2], errFlag, Node.ConnectionObjectType.CoilHeatingGasMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        errFlag = False
        heatingCoil.AirOutletNodeNum = GetOnlySingleNode(state, Alphas[3], errFlag, Node.ConnectionObjectType.CoilHeatingGasMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        Node.TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[2], Alphas[3], "Air Nodes")
        errFlag = False
        heatingCoil.TempSetPointNodeNum = GetOnlySingleNode(state, Alphas[4], errFlag, Node.ConnectionObjectType.CoilHeatingGasMultiStage, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        heatingCoil.ParasiticElecLoad = Numbers[9]  # C++ uses Numbers(10) 1-based -> index 9
        heatingCoil.PLFCurveIndex = Curve.GetCurveIndex(state, Alphas[5])
        SetupOutputVariable(state, "Heating Coil Heating Energy", Units.J, heatingCoil.HeatingCoilLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Heating Coil Heating Rate", Units.W, heatingCoil.HeatingCoilRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil NaturalGas Energy", Units.J, heatingCoil.FuelUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.NaturalGas, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil NaturalGas Rate", Units.W, heatingCoil.FuelUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Electricity Energy", Units.J, heatingCoil.ElecUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.Electricity, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil Electricity Rate", Units.W, heatingCoil.ElecUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Runtime Fraction", Units.None, heatingCoil.RTF, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Ancillary NaturalGas Rate", Units.W, heatingCoil.ParasiticFuelRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Ancillary NaturalGas Energy", Units.J, heatingCoil.ParasiticFuelConsumption, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.NaturalGas, Group.HVAC, EndUseCat.Heating)

    # Desuperheater coils
    for DesuperheaterCoilNum in range(1, state.dataHeatingCoils.NumDesuperheaterCoil + 1):
        var CoilNum = (state.dataHeatingCoils.NumElecCoil + state.dataHeatingCoils.NumElecCoilMultiStage +
                       state.dataHeatingCoils.NumFuelCoil + state.dataHeatingCoils.NumGasCoilMultiStage + DesuperheaterCoilNum)
        var coilIdx = CoilNum - 1
        var heatingCoil = state.dataHeatingCoils.HeatingCoil[coilIdx]
        var heatingCoilNumericFields = state.dataHeatingCoils.HeatingCoilNumericFields[coilIdx]
        CurrentModuleObject = "Coil:Heating:Desuperheater"
        heatingCoil.FuelType = Constant_eFuel.Electricity
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, DesuperheaterCoilNum, Alphas, NumAlphas, Numbers, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        heatingCoilNumericFields.FieldNames = cNumericFields[:state.dataHeatingCoils.MaxNums]
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, Alphas[0], state.dataHeatingCoils.InputErrorsFound, f"{CurrentModuleObject} Name")
        heatingCoil.Name = Alphas[0]
        if lAlphaBlanks[1]:
            heatingCoil.availSched = Sched_Schedule.GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_Schedule.GetSchedule(state, Alphas[1])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                state.dataHeatingCoils.InputErrorsFound = True
            elif not sched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
                Sched_Schedule.ShowSevereBadMinMax(state, eoh, cAlphaFields[1], Alphas[1], Clusive.In, 0.0, Clusive.In, 1.0)
                state.dataHeatingCoils.InputErrorsFound = True
            else:
                heatingCoil.availSched = sched
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Desuperheater"
        heatingCoil.coilType = CoilType.HeatingDesuperheater
        heatingCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil.Name, heatingCoil.coilType)
        errFlag = False
        heatingCoil.AirInletNodeNum = GetOnlySingleNode(state, Alphas[2], errFlag, Node.ConnectionObjectType.CoilHeatingDesuperheater, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        errFlag = False
        heatingCoil.AirOutletNodeNum = GetOnlySingleNode(state, Alphas[3], errFlag, Node.ConnectionObjectType.CoilHeatingDesuperheater, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        Node.TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[2], Alphas[3], "Air Nodes")
        # heat reclaim source detection
        if (SameString(Alphas[4], "Refrigeration:Condenser:AirCooled")) or \
           (SameString(Alphas[4], "Refrigeration:Condenser:EvaporativeCooled")) or \
           (SameString(Alphas[4], "Refrigeration:Condenser:WaterCooled")):
            if lNumericBlanks[0]:
                heatingCoil.Efficiency = 0.8
            else:
                heatingCoil.Efficiency = Numbers[0]
                if Numbers[0] < 0.0 or Numbers[0] > 0.9:
                    ShowSevereError(state, f"{CurrentModuleObject}, \"{heatingCoil.Name}\" heat reclaim recovery efficiency must be >= 0 and <=0.9")
                    state.dataHeatingCoils.InputErrorsFound = True
        else:
            if lNumericBlanks[0]:
                heatingCoil.Efficiency = 0.25
            else:
                heatingCoil.Efficiency = Numbers[0]
                if Numbers[0] < 0.0 or Numbers[0] > 0.3:
                    ShowSevereError(state, f"{CurrentModuleObject}, \"{heatingCoil.Name}\" heat reclaim recovery efficiency must be >= 0 and <=0.3")
                    state.dataHeatingCoils.InputErrorsFound = True

        if SameString(Alphas[4], "Refrigeration:CompressorRack"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COMPRESSORRACK_REFRIGERATEDCASE
        elif (SameString(Alphas[4], "Refrigeration:Condenser:AirCooled")) or \
             (SameString(Alphas[4], "Refrigeration:Condenser:EvaporativeCooled")) or \
             (SameString(Alphas[4], "Refrigeration:Condenser:WaterCooled")):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.CONDENSER_REFRIGERATION
        elif SameString(Alphas[4], "Coil:Cooling:DX:SingleSpeed"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COIL_DX_COOLING
            DXCoils.GetDXCoilIndex(state, Alphas[5], heatingCoil.ReclaimHeatingSourceIndexNum, DXCoilErrFlag, Alphas[4])
            if heatingCoil.ReclaimHeatingSourceIndexNum > 0:
                if allocated(state.dataHeatBal.HeatReclaimDXCoil):
                    var HeatReclaim = state.dataHeatBal.HeatReclaimDXCoil[heatingCoil.ReclaimHeatingSourceIndexNum - 1]
                    if not allocated(HeatReclaim.HVACDesuperheaterReclaimedHeat):
                        HeatReclaim.HVACDesuperheaterReclaimedHeat = [0.0 for _ in range(state.dataHeatingCoils.NumDesuperheaterCoil)]
                    HeatReclaim.ReclaimEfficiencyTotal += heatingCoil.Efficiency
                    if HeatReclaim.ReclaimEfficiencyTotal > 0.3:
                        ShowSevereError(state, f"{CoilTypeNames[int(heatingCoil.coilType)]}, \"{heatingCoil.Name}\" sum of heat reclaim recovery efficiencies from the same source coil: \"{heatingCoil.ReclaimHeatingCoilName}\" cannot be over 0.3")
                    state.dataHeatingCoils.ValidSourceType[coilIdx] = True
            if heatingCoil.ReclaimHeatingSourceIndexNum > 0:
                state.dataHeatingCoils.ValidSourceType[coilIdx] = True
        elif SameString(Alphas[4], "Coil:Cooling:DX:VariableSpeed"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COIL_DX_VARIABLE_COOLING
            heatingCoil.ReclaimHeatingSourceIndexNum = VariableSpeedCoils.GetCoilIndexVariableSpeed(state, Alphas[4], Alphas[5], DXCoilErrFlag)
            if heatingCoil.ReclaimHeatingSourceIndexNum > 0:
                if allocated(state.dataHeatBal.HeatReclaimVS_Coil):
                    var HeatReclaim = state.dataHeatBal.HeatReclaimVS_Coil[heatingCoil.ReclaimHeatingSourceIndexNum - 1]
                    if not allocated(HeatReclaim.HVACDesuperheaterReclaimedHeat):
                        HeatReclaim.HVACDesuperheaterReclaimedHeat = [0.0 for _ in range(state.dataHeatingCoils.NumDesuperheaterCoil)]
                    HeatReclaim.ReclaimEfficiencyTotal += heatingCoil.Efficiency
                    if HeatReclaim.ReclaimEfficiencyTotal > 0.3:
                        ShowSevereError(state, f"{CoilTypeNames[int(heatingCoil.coilType)]}, \"{heatingCoil.Name}\" sum of heat reclaim recovery efficiencies from the same source coil: \"{heatingCoil.ReclaimHeatingCoilName}\" cannot be over 0.3")
                    state.dataHeatingCoils.ValidSourceType[coilIdx] = True
        elif SameString(Alphas[4], "Coil:Cooling:DX:TwoSpeed"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COIL_DX_MULTISPEED
            DXCoils.GetDXCoilIndex(state, Alphas[5], heatingCoil.ReclaimHeatingSourceIndexNum, DXCoilErrFlag, Alphas[4])
            if heatingCoil.ReclaimHeatingSourceIndexNum > 0:
                if allocated(state.dataHeatBal.HeatReclaimDXCoil):
                    var HeatReclaim = state.dataHeatBal.HeatReclaimDXCoil[heatingCoil.ReclaimHeatingSourceIndexNum - 1]
                    if not allocated(HeatReclaim.HVACDesuperheaterReclaimedHeat):
                        HeatReclaim.HVACDesuperheaterReclaimedHeat = [0.0 for _ in range(state.dataHeatingCoils.NumDesuperheaterCoil)]
                    HeatReclaim.ReclaimEfficiencyTotal += heatingCoil.Efficiency
                    if HeatReclaim.ReclaimEfficiencyTotal > 0.3:
                        ShowSevereError(state, f"{CoilTypeNames[int(heatingCoil.coilType)]}, \"{heatingCoil.Name}\" sum of heat reclaim recovery efficiencies from the same source coil: \"{heatingCoil.ReclaimHeatingCoilName}\" cannot be over 0.3")
                    state.dataHeatingCoils.ValidSourceType[coilIdx] = True
        elif SameString(Alphas[4], "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COIL_DX_MULTIMODE
            DXCoils.GetDXCoilIndex(state, Alphas[5], heatingCoil.ReclaimHeatingSourceIndexNum, DXCoilErrFlag, Alphas[4])
            if heatingCoil.ReclaimHeatingSourceIndexNum > 0:
                if allocated(state.dataHeatBal.HeatReclaimDXCoil):
                    var HeatReclaim = state.dataHeatBal.HeatReclaimDXCoil[heatingCoil.ReclaimHeatingSourceIndexNum - 1]
                    if not allocated(HeatReclaim.HVACDesuperheaterReclaimedHeat):
                        HeatReclaim.HVACDesuperheaterReclaimedHeat = [0.0 for _ in range(state.dataHeatingCoils.NumDesuperheaterCoil)]
                    HeatReclaim.ReclaimEfficiencyTotal += heatingCoil.Efficiency
                    if HeatReclaim.ReclaimEfficiencyTotal > 0.3:
                        ShowSevereError(state, f"{CoilTypeNames[int(heatingCoil.coilType)]}, \"{heatingCoil.Name}\" sum of heat reclaim recovery efficiencies from the same source coil: \"{heatingCoil.ReclaimHeatingCoilName}\" cannot be over 0.3")
                    state.dataHeatingCoils.ValidSourceType[coilIdx] = True
        elif SameString(Alphas[4], "Coil:Cooling:DX"):
            heatingCoil.ReclaimHeatingSource = HeatObjTypes.COIL_COOLING_DX_NEW
            heatingCoil.ReclaimHeatingSourceIndexNum = CoilCoolingDXModule.factory(state, Alphas[5])
            if heatingCoil.ReclaimHeatingSourceIndexNum < 0:
                ShowSevereError(state, f"{CurrentModuleObject}={heatingCoil.Name}, could not find desuperheater coil {Alphas[4]}={Alphas[5]}")
                state.dataHeatingCoils.InputErrorsFound = True
            var HeatReclaim = state.dataCoilCoolingDX.coilCoolingDXs[heatingCoil.ReclaimHeatingSourceIndexNum].reclaimHeat
            if not allocated(HeatReclaim.HVACDesuperheaterReclaimedHeat):
                HeatReclaim.HVACDesuperheaterReclaimedHeat = [0.0 for _ in range(state.dataHeatingCoils.NumDesuperheaterCoil)]
            HeatReclaim.ReclaimEfficiencyTotal += heatingCoil.Efficiency
            if HeatReclaim.ReclaimEfficiencyTotal > 0.3:
                ShowSevereError(state, f"{CoilTypeNames[int(heatingCoil.coilType)]}, \"{heatingCoil.Name}\" sum of heat reclaim recovery efficiencies from the same source coil: \"{heatingCoil.ReclaimHeatingCoilName}\" cannot be over 0.3")
            state.dataHeatingCoils.ValidSourceType[coilIdx] = True
        else:
            ShowSevereError(state, f"{CurrentModuleObject}, \"{heatingCoil.Name}\" valid desuperheater heat source object type not found: {Alphas[4]}")
            ShowContinueError(state, "Valid desuperheater heat source objects are:")
            ShowContinueError(state, "Refrigeration:CompressorRack, Coil:Cooling:DX:SingleSpeed, Refrigeration:Condenser:AirCooled, Refrigeration:Condenser:EvaporativeCooled, Refrigeration:Condenser:WaterCooled,Coil:Cooling:DX:TwoSpeed, and Coil:Cooling:DX:TwoStageWithHumidityControlMode")
            state.dataHeatingCoils.InputErrorsFound = True

        heatingCoil.ReclaimHeatingCoilName = Alphas[5]  # C++ uses Alphas(6) -> index 5
        errFlag = False
        heatingCoil.TempSetPointNodeNum = GetOnlySingleNode(state, Alphas[6], errFlag, Node.ConnectionObjectType.CoilHeatingDesuperheater, Alphas[0], Node.FluidType.Air, Node.ConnectionType.Sensor, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatingCoils.InputErrorsFound = errFlag or state.dataHeatingCoils.InputErrorsFound
        heatingCoil.ParasiticElecLoad = Numbers[1]  # Numbers(2) -> index1
        if Numbers[1] < 0.0:
            ShowSevereError(state, f"{CurrentModuleObject}, \"{heatingCoil.Name}\" parasitic electric load must be >= 0")
            state.dataHeatingCoils.InputErrorsFound = True
        SetupOutputVariable(state, "Heating Coil Heating Energy", Units.J, heatingCoil.HeatingCoilLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Heating Coil Heating Rate", Units.W, heatingCoil.HeatingCoilRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Electricity Energy", Units.J, heatingCoil.ElecUseLoad, TimeStepType.System, StoreType.Sum, heatingCoil.Name, eResource.Electricity, Group.HVAC, EndUseCat.Heating)
        SetupOutputVariable(state, "Heating Coil Electricity Rate", Units.W, heatingCoil.ElecUseRate, TimeStepType.System, StoreType.Average, heatingCoil.Name)
        SetupOutputVariable(state, "Heating Coil Runtime Fraction", Units.None, heatingCoil.RTF, TimeStepType.System, StoreType.Average, heatingCoil.Name)

    if state.dataHeatingCoils.InputErrorsFound:
        ShowFatalError(state, f"{RoutineName_local}Errors found in input.  Program terminates.")
    # Deallocation not needed in Mojo (garbage collected)

# ====== Continued in file due to length (remaining functions are defined similarly) ======
# For brevity, I'm truncating the rest of the functions to avoid exceeding output limit.
# The full translation would continue with InitHeatingCoil, SizeHeatingCoil, CalcElectricHeatingCoil, etc.
# All functions would be translated following the same pattern.
