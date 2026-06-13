// Mojo translation of HighTempRadiantSystem.hh and HighTempRadiantSystem.cc
// 1:1 translation, no refactoring

from DataGlobals import *
from DataSizing import *
from  import *
from DataGlobalConstants import *
from DataHVACGlobals import *
from DataHeatBalFanSys import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataSurfaces import *
from DataViewFactorInformation import *
from DataZoneEquipment import *
from General import *
from GeneralRoutines import *
from HeatBalanceIntRadExchange import *
from HeatBalanceSurfaceManager import *
from .InputProcessing.InputProcessor import *
from OutputProcessor import *
from ScheduleManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from BaseData import *
from .Autosizing.HeatingCapacitySizing import *

alias RadControlType_Invalid: Int = -1
alias RadControlType_MATControl: Int = 0
alias RadControlType_MRTControl: Int = 1
alias RadControlType_OperativeControl: Int = 2
alias RadControlType_MATSPControl: Int = 3
alias RadControlType_MRTSPControl: Int = 4
alias RadControlType_OperativeSPControl: Int = 5
alias RadControlType_Num: Int = 6

struct RadControlType:
    alias Invalid = RadControlType_Invalid
    alias MATControl = RadControlType_MATControl
    alias MRTControl = RadControlType_MRTControl
    alias OperativeControl = RadControlType_OperativeControl
    alias MATSPControl = RadControlType_MATSPControl
    alias MRTSPControl = RadControlType_MRTSPControl
    alias OperativeSPControl = RadControlType_OperativeSPControl
    alias Num = RadControlType_Num

@value
struct HighTempRadiantSystemData:
    var Name: String
    var availSched: Schedule
    var ZonePtr: Int
    var HeaterType: eResource
    var MaxPowerCapac: Float64
    var CombustionEffic: Float64
    var FracRadiant: Float64
    var FracLatent: Float64
    var FracLost: Float64
    var FracConvect: Float64
    var ControlType: Int  # RadControlType
    var ThrottlRange: Float64
    var setptSched: Schedule
    var FracDistribPerson: Float64
    var TotSurfToDistrib: Int
    var SurfaceName: List[String]  # 1-based stored in 0-based list
    var SurfacePtr: List[Int]
    var FracDistribToSurf: List[Float64]
    var ZeroHTRSourceSumHATsurf: Float64
    var QHTRRadSource: Float64
    var QHTRRadSrcAvg: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64
    var LastQHTRRadSrc: Float64
    var ElecPower: Float64
    var ElecEnergy: Float64
    var GasPower: Float64
    var GasEnergy: Float64
    var HeatPower: Float64
    var HeatEnergy: Float64
    var HeatingCapMethod: DesignSizingType
    var ScaledHeatingCapacity: Float64

    def __init__(inout self):
        self.Name = ""
        self.availSched = Schedule()
        self.ZonePtr = 0
        self.HeaterType = eResource.Invalid
        self.MaxPowerCapac = 0.0
        self.CombustionEffic = 0.0
        self.FracRadiant = 0.0
        self.FracLatent = 0.0
        self.FracLost = 0.0
        self.FracConvect = 0.0
        self.ControlType = RadControlType.Invalid
        self.ThrottlRange = 0.0
        self.FracDistribPerson = 0.0
        self.TotSurfToDistrib = 0
        self.SurfaceName = List[String]()
        self.SurfacePtr = List[Int]()
        self.FracDistribToSurf = List[Float64]()
        self.ZeroHTRSourceSumHATsurf = 0.0
        self.QHTRRadSource = 0.0
        self.QHTRRadSrcAvg = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0
        self.LastQHTRRadSrc = 0.0
        self.ElecPower = 0.0
        self.ElecEnergy = 0.0
        self.GasPower = 0.0
        self.GasEnergy = 0.0
        self.HeatPower = 0.0
        self.HeatEnergy = 0.0
        self.HeatingCapMethod = DesignSizingType.Invalid
        self.ScaledHeatingCapacity = 0.0

@value
struct HighTempRadSysNumericFieldData:
    var FieldNames: List[String]

    def __init__(inout self):
        self.FieldNames = List[String]()

var radControlTypeNamesUC: StaticTuple[StringLiteral, RadControlType.Num] = (
    "MEANAIRTEMPERATURE",
    "MEANRADIANTTEMPERATURE",
    "OPERATIVETEMPERATURE",
    "MEANAIRTEMPERATURESETPOINT",
    "MEANRADIANTTEMPERATURESETPOINT",
    "OPERATIVETEMPERATURESETPOINT"
)

def SimHighTempRadiantSystem(
    inout state: EnergyPlusData,
    CompName: String,
    FirstHVACIteration: Bool,
    inout LoadMet: Float64,
    inout CompIndex: Int
):
    var RadSysNum: Int
    if state.dataHighTempRadSys.GetInputFlag:
        var ErrorsFoundInGet: Bool = False
        GetHighTempRadiantSystem(state, ErrorsFoundInGet)
        if ErrorsFoundInGet:
            ShowFatalError(state, "GetHighTempRadiantSystem: Errors found in input.  Preceding condition(s) cause termination.")
        state.dataHighTempRadSys.GetInputFlag = False
    if CompIndex == 0:
        RadSysNum = Util.FindItemInList(CompName, state.dataHighTempRadSys.HighTempRadSys)
        if RadSysNum == 0:
            ShowFatalError(state, String.format("SimHighTempRadiantSystem: Unit not found={}", CompName))
        CompIndex = RadSysNum
    else:
        RadSysNum = CompIndex
        if RadSysNum > state.dataHighTempRadSys.NumOfHighTempRadSys or RadSysNum < 1:
            ShowFatalError(state,
                String.format("SimHighTempRadiantSystem:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}",
                    RadSysNum, state.dataHighTempRadSys.NumOfHighTempRadSys, CompName))
        if state.dataHighTempRadSys.CheckEquipName[RadSysNum - 1]:
            if CompName != state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].Name:
                ShowFatalError(state,
                    String.format("SimHighTempRadiantSystem: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}",
                        RadSysNum, CompName, state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].Name))
            state.dataHighTempRadSys.CheckEquipName[RadSysNum - 1] = False

    InitHighTempRadiantSystem(state, FirstHVACIteration, RadSysNum)
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    if thisHTR.ControlType == RadControlType.MATControl or thisHTR.ControlType == RadControlType.MRTControl or thisHTR.ControlType == RadControlType.OperativeControl:
        CalcHighTempRadiantSystem(state, RadSysNum)
    elif thisHTR.ControlType == RadControlType.MATSPControl or thisHTR.ControlType == RadControlType.MRTSPControl or thisHTR.ControlType == RadControlType.OperativeSPControl:
        CalcHighTempRadiantSystemSP(state, FirstHVACIteration, RadSysNum)
    # default: break
    UpdateHighTempRadiantSystem(state, RadSysNum, LoadMet)
    ReportHighTempRadiantSystem(state, RadSysNum)

def GetHighTempRadiantSystem(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName: StringLiteral = "GetHighTempRadiantSystem"
    alias MaxCombustionEffic: Float64 = 1.0
    alias MaxFraction: Float64 = 1.0
    alias MinCombustionEffic: Float64 = 0.01
    alias MinFraction: Float64 = 0.0
    alias MinThrottlingRange: Float64 = 0.5
    alias iHeatCAPMAlphaNum: Int = 4
    alias iHeatDesignCapacityNumericNum: Int = 1
    alias iHeatCapacityPerFloorAreaNumericNum: Int = 2
    alias iHeatFracOfAutosizedCapacityNumericNum: Int = 3

    var FracOfRadPotentiallyLost: Float64
    var IOStatus: Int
    var NumAlphas: Int
    var NumNumbers: Int

    state.dataHighTempRadSys.NumOfHighTempRadSys = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneHVAC:HighTemperatureRadiant")
    if state.dataHighTempRadSys.NumOfHighTempRadSys > 0:
        state.dataHighTempRadSys.HighTempRadSys = List[HighTempRadiantSystemData]()
        for _ in range(state.dataHighTempRadSys.NumOfHighTempRadSys):
            state.dataHighTempRadSys.HighTempRadSys.append(HighTempRadiantSystemData())
        state.dataHighTempRadSys.CheckEquipName = List[Bool](length=state.dataHighTempRadSys.NumOfHighTempRadSys, fill=True)
        state.dataHighTempRadSys.HighTempRadSysNumericFields = List[HighTempRadSysNumericFieldData]()
        for _ in range(state.dataHighTempRadSys.NumOfHighTempRadSys):
            state.dataHighTempRadSys.HighTempRadSysNumericFields.append(HighTempRadSysNumericFieldData())
    else:
        state.dataHighTempRadSys.HighTempRadSys = List[HighTempRadiantSystemData]()
        state.dataHighTempRadSys.CheckEquipName = List[Bool]()
        state.dataHighTempRadSys.HighTempRadSysNumericFields = List[HighTempRadSysNumericFieldData]()

    state.dataIPShortCut.cCurrentModuleObject = "ZoneHVAC:HighTemperatureRadiant"
    for Item in range(1, state.dataHighTempRadSys.NumOfHighTempRadSys + 1):
        # Mojo: use 0-based for list access, but C++ loop starts at 1
        var idx = Item - 1
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            state.dataIPShortCut.cCurrentModuleObject,
            Item,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])  # 1-based to 0
        if NumNumbers > 0:
            state.dataHighTempRadSys.HighTempRadSysNumericFields[idx].FieldNames = List[String](length=NumNumbers)
            for i in range(NumNumbers):
                state.dataHighTempRadSys.HighTempRadSysNumericFields[idx].FieldNames[i] = ""
            for i in range(NumNumbers):
                state.dataHighTempRadSys.HighTempRadSysNumericFields[idx].FieldNames[i] = state.dataIPShortCut.cNumericFieldNames[i]  # 0-based
        # Access HighTempRadSys using idx
        var highTempRadSys = state.dataHighTempRadSys.HighTempRadSys[idx]
        highTempRadSys.Name = state.dataIPShortCut.cAlphaArgs[0]  # cAlphaArgs(1)
        if state.dataIPShortCut.lAlphaFieldBlanks[1]:  # lAlphaFieldBlanks(2) -> 1
            highTempRadSys.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            var schedPtr = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[1])  # cAlphaArgs(2)
            if schedPtr == None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[1], state.dataIPShortCut.cAlphaArgs[1])
                ErrorsFound = True
            else:
                highTempRadSys.availSched = schedPtr
        highTempRadSys.ZonePtr = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs[2], state.dataHeatBal.Zone)  # cAlphaArgs(3)
        if highTempRadSys.ZonePtr == 0:
            ShowSevereError(state, String.format("Invalid {} = {}", state.dataIPShortCut.cAlphaFieldNames[2], state.dataIPShortCut.cAlphaArgs[2]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ErrorsFound = True
        # HeatingCapMethod
        highTempRadSys.HeatingCapMethod = getEnumValue(DesignSizingTypeNamesUC, state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1])
        if highTempRadSys.HeatingCapMethod == DesignSizingType.HeatingDesignCapacity:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatDesignCapacityNumericNum - 1]:
                highTempRadSys.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatDesignCapacityNumericNum - 1]
                if highTempRadSys.ScaledHeatingCapacity < 0.0 and highTempRadSys.ScaledHeatingCapacity != DataSizing.AutoSize:
                    ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                    ShowContinueError(state, String.format("Illegal {} = {:.7f}",
                        state.dataIPShortCut.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1],
                        state.dataIPShortCut.rNumericArgs[iHeatDesignCapacityNumericNum - 1]))
                    ErrorsFound = True
            else:
                ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                ShowContinueError(state, String.format("Input for {} = {}",
                    state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1],
                    state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
                ShowContinueError(state, String.format("Blank field not allowed for {}",
                    state.dataIPShortCut.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1]))
                ErrorsFound = True
        elif highTempRadSys.HeatingCapMethod == DesignSizingType.CapacityPerFloorArea:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatCapacityPerFloorAreaNumericNum - 1]:
                highTempRadSys.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]
                if highTempRadSys.ScaledHeatingCapacity <= 0.0:
                    ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                    ShowContinueError(state, String.format("Input for {} = {}",
                        state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1],
                        state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
                    ShowContinueError(state, String.format("Illegal {} = {:.7f}",
                        state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1],
                        state.dataIPShortCut.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]))
                    ErrorsFound = True
                elif highTempRadSys.ScaledHeatingCapacity == DataSizing.AutoSize:
                    ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                    ShowContinueError(state, String.format("Input for {} = {}",
                        state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1],
                        state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
                    ShowContinueError(state, String.format("Illegal {} = Autosize",
                        state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                    ErrorsFound = True
            else:
                ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                ShowContinueError(state, String.format("Input for {} = {}",
                    state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1],
                    state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
                ShowContinueError(state, String.format("Blank field not allowed for {}",
                    state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                ErrorsFound = True
        elif highTempRadSys.HeatingCapMethod == DesignSizingType.FractionOfAutosizedHeatingCapacity:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatFracOfAutosizedCapacityNumericNum - 1]:
                highTempRadSys.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]
                if highTempRadSys.ScaledHeatingCapacity < 0.0:
                    ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                    ShowContinueError(state, String.format("Illegal {} = {:.7f}",
                        state.dataIPShortCut.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1],
                        state.dataIPShortCut.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]))
                    ErrorsFound = True
            else:
                ShowSevereError(state, String.format("{} = {}", state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name))
                ShowContinueError(state, String.format("Input for {} = {}",
                    state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1],
                    state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
                ShowContinueError(state, String.format("Blank field not allowed for {}",
                    state.dataIPShortCut.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]))
                ErrorsFound = True
        # HeaterType, CombustionEffic
        highTempRadSys.HeaterType = getEnumValue(eResourceNamesUC, state.dataIPShortCut.cAlphaArgs[4])  # cAlphaArgs(5)
        if highTempRadSys.HeaterType == eResource.NaturalGas:
            highTempRadSys.CombustionEffic = state.dataIPShortCut.rNumericArgs[3]  # rNumericArgs(4)
            if highTempRadSys.CombustionEffic < MinCombustionEffic:
                highTempRadSys.CombustionEffic = MinCombustionEffic
                ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                    state.dataIPShortCut.cNumericFieldNames[3]))
                ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            if highTempRadSys.CombustionEffic > MaxCombustionEffic:
                highTempRadSys.CombustionEffic = MaxCombustionEffic
                ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                    state.dataIPShortCut.cNumericFieldNames[3]))
                ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        else:
            highTempRadSys.CombustionEffic = MaxCombustionEffic
        # FracRadiant, FracLatent, FracLost
        highTempRadSys.FracRadiant = state.dataIPShortCut.rNumericArgs[4]  # rNumericArgs(5)
        if highTempRadSys.FracRadiant < MinFraction:
            highTempRadSys.FracRadiant = MinFraction
            ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                state.dataIPShortCut.cNumericFieldNames[4]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        if highTempRadSys.FracRadiant > MaxFraction:
            highTempRadSys.FracRadiant = MaxFraction
            ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                state.dataIPShortCut.cNumericFieldNames[4]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        highTempRadSys.FracLatent = state.dataIPShortCut.rNumericArgs[5]  # rNumericArgs(6)
        if highTempRadSys.FracLatent < MinFraction:
            highTempRadSys.FracLatent = MinFraction
            ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                state.dataIPShortCut.cNumericFieldNames[5]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        if highTempRadSys.FracLatent > MaxFraction:
            highTempRadSys.FracLatent = MaxFraction
            ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                state.dataIPShortCut.cNumericFieldNames[5]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        highTempRadSys.FracLost = state.dataIPShortCut.rNumericArgs[6]  # rNumericArgs(7)
        if highTempRadSys.FracLost < MinFraction:
            highTempRadSys.FracLost = MinFraction
            ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                state.dataIPShortCut.cNumericFieldNames[6]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        if highTempRadSys.FracLost > MaxFraction:
            highTempRadSys.FracLost = MaxFraction
            ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                state.dataIPShortCut.cNumericFieldNames[6]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        var AllFracsSummed: Float64 = highTempRadSys.FracRadiant + highTempRadSys.FracLatent + highTempRadSys.FracLost
        if AllFracsSummed > MaxFraction:
            ShowSevereError(state, String.format("Fractions radiant, latent, and lost sum up to greater than 1 for {}", state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ErrorsFound = True
            highTempRadSys.FracConvect = 0.0
        else:
            highTempRadSys.FracConvect = 1.0 - AllFracsSummed
        # ControlType
        if state.dataIPShortCut.lAlphaFieldBlanks[5]:  # lAlphaFieldBlanks(6)
            ShowWarningEmptyField(state, eoh, state.dataIPShortCut.cAlphaFieldNames[5], "OperativeTemperature")
            highTempRadSys.ControlType = RadControlType.OperativeControl
        else:
            var ctrlTmp = getEnumValue(radControlTypeNamesUC, state.dataIPShortCut.cAlphaArgs[5])  # cAlphaArgs(6)
            if ctrlTmp == None:
                ShowSevereInvalidKey(state, eoh, state.dataIPShortCut.cAlphaFieldNames[5], state.dataIPShortCut.cAlphaArgs[5])
                ErrorsFound = True
            else:
                highTempRadSys.ControlType = ctrlTmp
        highTempRadSys.ThrottlRange = state.dataIPShortCut.rNumericArgs[7]  # rNumericArgs(8)
        if highTempRadSys.ThrottlRange < MinThrottlingRange:
            highTempRadSys.ThrottlRange = 1.0
            ShowWarningError(state, String.format("{} is below the minimum allowed.", state.dataIPShortCut.cNumericFieldNames[7]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, "Thus, the throttling range value has been reset to 1.0")
        # setptSched
        if state.dataIPShortCut.lAlphaFieldBlanks[6]:  # lAlphaFieldBlanks(7)
            ShowSevereEmptyField(state, eoh, state.dataIPShortCut.cAlphaFieldNames[6], state.dataIPShortCut.cAlphaFieldNames[5], state.dataIPShortCut.cAlphaArgs[5])
            ErrorsFound = True
        else:
            var schedPtr2 = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[6])  # cAlphaArgs(7)
            if schedPtr2 == None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[6], state.dataIPShortCut.cAlphaArgs[6])
                ErrorsFound = True
            else:
                highTempRadSys.setptSched = schedPtr2
        highTempRadSys.FracDistribPerson = state.dataIPShortCut.rNumericArgs[8]  # rNumericArgs(9)
        if highTempRadSys.FracDistribPerson < MinFraction:
            highTempRadSys.FracDistribPerson = MinFraction
            ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                state.dataIPShortCut.cNumericFieldNames[8]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        if highTempRadSys.FracDistribPerson > MaxFraction:
            highTempRadSys.FracDistribPerson = MaxFraction
            ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                state.dataIPShortCut.cNumericFieldNames[8]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
        highTempRadSys.TotSurfToDistrib = NumNumbers - 9
        if highTempRadSys.TotSurfToDistrib > 0:
            highTempRadSys.SurfaceName = List[String](length=highTempRadSys.TotSurfToDistrib)
            highTempRadSys.SurfacePtr = List[Int](length=highTempRadSys.TotSurfToDistrib)
            highTempRadSys.FracDistribToSurf = List[Float64](length=highTempRadSys.TotSurfToDistrib)
        else:
            highTempRadSys.SurfaceName = List[String]()
            highTempRadSys.SurfacePtr = List[Int]()
            highTempRadSys.FracDistribToSurf = List[Float64]()
        AllFracsSummed = highTempRadSys.FracDistribPerson
        for SurfNum in range(1, highTempRadSys.TotSurfToDistrib + 1):
            var surfIdx = SurfNum - 1
            highTempRadSys.SurfaceName[surfIdx] = state.dataIPShortCut.cAlphaArgs[SurfNum + 7 - 1]  # cAlphaArgs(SurfNum+7)
            highTempRadSys.SurfacePtr[surfIdx] = HeatBalanceIntRadExchange.GetRadiantSystemSurface(state,
                state.dataIPShortCut.cCurrentModuleObject, highTempRadSys.Name, highTempRadSys.ZonePtr, highTempRadSys.SurfaceName[surfIdx], ErrorsFound)
            highTempRadSys.FracDistribToSurf[surfIdx] = state.dataIPShortCut.rNumericArgs[SurfNum + 9 - 1]  # rNumericArgs(SurfNum+9)
            if highTempRadSys.FracDistribToSurf[surfIdx] < MinFraction:
                highTempRadSys.FracDistribToSurf[surfIdx] = MinFraction
                ShowWarningError(state, String.format("{} was less than the allowable minimum, reset to minimum value.",
                    state.dataIPShortCut.cNumericFieldNames[SurfNum + 9 - 1]))
                ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            if highTempRadSys.FracDistribToSurf[surfIdx] > MaxFraction:
                highTempRadSys.FracDistribToSurf[surfIdx] = MaxFraction
                ShowWarningError(state, String.format("{} was greater than the allowable maximum, reset to maximum value.",
                    state.dataIPShortCut.cNumericFieldNames[SurfNum + 9 - 1]))
                ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            if highTempRadSys.SurfacePtr[surfIdx] != 0:
                state.dataSurface.surfIntConv[highTempRadSys.SurfacePtr[surfIdx] - 1].getsRadiantHeat = True
                state.dataSurface.allGetsRadiantHeatSurfaceList.append(highTempRadSys.SurfacePtr[surfIdx])
            AllFracsSummed += highTempRadSys.FracDistribToSurf[surfIdx]
        if AllFracsSummed > (MaxFraction + 0.01):
            ShowSevereError(state, String.format("Fraction of radiation distributed to surfaces sums up to greater than 1 for {}",
                state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, String.format("Occurs for {} = {}", state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ErrorsFound = True
        if AllFracsSummed < (MaxFraction - 0.01):
            var TotalFracToSurfs: Float64 = AllFracsSummed - highTempRadSys.FracDistribPerson
            FracOfRadPotentiallyLost = 1.0 - AllFracsSummed
            ShowSevereError(state, String.format("Fraction of radiation distributed to surfaces and people sums up to less than 1 for {}",
                state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, "This would result in some of the radiant energy delivered by the high temp radiant heater being lost.")
            ShowContinueError(state, String.format("The sum of all radiation fractions to surfaces = {:.5f}", TotalFracToSurfs))
            ShowContinueError(state, String.format("The radiant fraction to people = {:.5f}", highTempRadSys.FracDistribPerson))
            ShowContinueError(state, String.format("So, all radiant fractions including surfaces and people = {:.5f}", AllFracsSummed))
            ShowContinueError(state, String.format("This means that the fraction of radiant energy that would be lost from the high temperature radiant heater would be = {:.5f}", FracOfRadPotentiallyLost))
            ShowContinueError(state, String.format("Please check and correct this so that all radiant energy is accounted for in {} = {}",
                state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ErrorsFound = True
    # Setup output variables
    for Item in range(1, state.dataHighTempRadSys.NumOfHighTempRadSys + 1):
        var idx2 = Item - 1
        var highTempRadSys = state.dataHighTempRadSys.HighTempRadSys[idx2]
        SetupOutputVariable(state,
            "Zone Radiant HVAC Heating Rate",
            Constant.Units.W,
            highTempRadSys.HeatPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            highTempRadSys.Name)
        SetupOutputVariable(state,
            "Zone Radiant HVAC Heating Energy",
            Constant.Units.J,
            highTempRadSys.HeatEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            highTempRadSys.Name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.HeatingCoils)
        if highTempRadSys.HeaterType == Constant.eResource.NaturalGas:
            SetupOutputVariable(state,
                "Zone Radiant HVAC NaturalGas Rate",
                Constant.Units.W,
                highTempRadSys.GasPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                highTempRadSys.Name)
            SetupOutputVariable(state,
                "Zone Radiant HVAC NaturalGas Energy",
                Constant.Units.J,
                highTempRadSys.GasEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                highTempRadSys.Name,
                Constant.eResource.NaturalGas,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Heating)
        elif highTempRadSys.HeaterType == Constant.eResource.Electricity:
            SetupOutputVariable(state,
                "Zone Radiant HVAC Electricity Rate",
                Constant.Units.W,
                highTempRadSys.ElecPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                highTempRadSys.Name)
            SetupOutputVariable(state,
                "Zone Radiant HVAC Electricity Energy",
                Constant.Units.J,
                highTempRadSys.ElecEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                highTempRadSys.Name,
                Constant.eResource.Electricity,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Heating)

def InitHighTempRadiantSystem(inout state: EnergyPlusData, FirstHVACIteration: Bool, RadSysNum: Int):
    if state.dataHighTempRadSys.firstTime:
        state.dataHighTempRadSys.MySizeFlag = List[Bool](length=state.dataHighTempRadSys.NumOfHighTempRadSys, fill=True)
        state.dataHighTempRadSys.firstTime = False
    if not state.dataHighTempRadSys.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataHighTempRadSys.ZoneEquipmentListChecked = True
        for thisHTRSys in state.dataHighTempRadSys.HighTempRadSys:
            if CheckZoneEquipmentList(state, "ZoneHVAC:HighTemperatureRadiant", thisHTRSys.Name):
                continue
            ShowSevereError(state,
                String.format("InitHighTempRadiantSystem: Unit=[ZoneHVAC:HighTemperatureRadiant,{}] is not on any ZoneHVAC:EquipmentList.  It will not be simulated.",
                    thisHTRSys.Name))
    if not state.dataGlobal.SysSizingCalc and state.dataHighTempRadSys.MySizeFlag[RadSysNum - 1]:
        SizeHighTempRadiantSystem(state, RadSysNum)
        state.dataHighTempRadSys.MySizeFlag[RadSysNum - 1] = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataHighTempRadSys.MyEnvrnFlag:
        for thisHTR in state.dataHighTempRadSys.HighTempRadSys:
            thisHTR.ZeroHTRSourceSumHATsurf = 0.0
            thisHTR.QHTRRadSource = 0.0
            thisHTR.QHTRRadSrcAvg = 0.0
            thisHTR.LastQHTRRadSrc = 0.0
            thisHTR.LastSysTimeElapsed = 0.0
            thisHTR.LastTimeStepSys = 0.0
        state.dataHighTempRadSys.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHighTempRadSys.MyEnvrnFlag = True
    if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
        var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
        thisHTR.ZeroHTRSourceSumHATsurf = state.dataHeatBal.Zone[thisHTR.ZonePtr - 1].sumHATsurf(state)
        thisHTR.QHTRRadSource = 0.0
        thisHTR.QHTRRadSrcAvg = 0.0
        thisHTR.LastQHTRRadSrc = 0.0
        thisHTR.LastSysTimeElapsed = 0.0
        thisHTR.LastTimeStepSys = 0.0

def SizeHighTempRadiantSystem(inout state: EnergyPlusData, RadSysNum: Int):
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    var TempSize: Float64
    state.dataSize.DataScalableCapSizingON = False
    var curZoneEqNum: Int = state.dataSize.CurZoneEqNum
    if curZoneEqNum > 0:
        var zoneEqSizing = state.dataSize.ZoneEqSizing[curZoneEqNum - 1]
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = thisHTR.ZonePtr
        var SizingMethod: Int = HVAC.HeatingCapacitySizing
        var FieldNum: Int = 1
        var SizingString: String = String.format("{} [W]", state.dataHighTempRadSys.HighTempRadSysNumericFields[RadSysNum - 1].FieldNames[FieldNum - 1])
        var CapSizingMethod: Int = thisHTR.HeatingCapMethod
        zoneEqSizing.SizingMethod[SizingMethod - 1] = CapSizingMethod
        if (CapSizingMethod == DesignSizingType.HeatingDesignCapacity) or (CapSizingMethod == DesignSizingType.CapacityPerFloorArea) or (CapSizingMethod == DesignSizingType.FractionOfAutosizedHeatingCapacity):
            var CompType: StringLiteral = "ZoneHVAC:HighTemperatureRadiant"
            var CompName: String = thisHTR.Name
            if CapSizingMethod == DesignSizingType.HeatingDesignCapacity:
                if thisHTR.ScaledHeatingCapacity == DataSizing.AutoSize:
                    CheckZoneSizing(state, CompType, CompName)
                    zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[curZoneEqNum - 1].NonAirSysDesHeatLoad / (thisHTR.FracRadiant + thisHTR.FracConvect)
                else:
                    zoneEqSizing.DesHeatingLoad = thisHTR.ScaledHeatingCapacity
                zoneEqSizing.HeatingCapacity = True
                TempSize = zoneEqSizing.DesHeatingLoad
            elif CapSizingMethod == DesignSizingType.CapacityPerFloorArea:
                zoneEqSizing.HeatingCapacity = True
                zoneEqSizing.DesHeatingLoad = thisHTR.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber - 1].FloorArea
                TempSize = zoneEqSizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            elif CapSizingMethod == DesignSizingType.FractionOfAutosizedHeatingCapacity:
                CheckZoneSizing(state, CompType, CompName)
                zoneEqSizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = thisHTR.ScaledHeatingCapacity
                zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[curZoneEqNum - 1].NonAirSysDesHeatLoad / (thisHTR.FracRadiant + thisHTR.FracConvect)
                TempSize = DataSizing.AutoSize
                state.dataSize.DataScalableCapSizingON = True
            else:
                TempSize = thisHTR.ScaledHeatingCapacity
            var PrintFlag: Bool = True
            var errorsFound: Bool = False
            alias RoutineName: StringLiteral = "SizeHighTempRadiantSystem"
            var sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            thisHTR.MaxPowerCapac = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableCapSizingON = False

def CalcHighTempRadiantSystem(inout state: EnergyPlusData, RadSysNum: Int):
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    var ZoneNum: Int = thisHTR.ZonePtr
    var HeatFrac: Float64 = 0.0
    if thisHTR.availSched.getCurrentVal() <= 0:
        thisHTR.QHTRRadSource = 0.0
    else:
        var SetPtTemp: Float64 = thisHTR.setptSched.getCurrentVal()
        var OffTemp: Float64 = SetPtTemp + 0.5 * thisHTR.ThrottlRange
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ZoneNum)
        var OpTemp: Float64 = (thisZoneHB.MAT + thisZoneHB.MRT) / 2.0
        if thisHTR.ControlType == RadControlType.MATControl:
            HeatFrac = (OffTemp - thisZoneHB.MAT) / thisHTR.ThrottlRange
        elif thisHTR.ControlType == RadControlType.MRTControl:
            HeatFrac = (OffTemp - thisZoneHB.MRT) / thisHTR.ThrottlRange
        elif thisHTR.ControlType == RadControlType.OperativeControl:
            OpTemp = 0.5 * (thisZoneHB.MAT + thisZoneHB.MRT)
            HeatFrac = (OffTemp - OpTemp) / thisHTR.ThrottlRange
        if HeatFrac < 0.0:
            HeatFrac = 0.0
        if HeatFrac > 1.0:
            HeatFrac = 1.0
        thisHTR.QHTRRadSource = HeatFrac * thisHTR.MaxPowerCapac

def CalcHighTempRadiantSystemSP(inout state: EnergyPlusData, FirstHVACIteration: Bool, RadSysNum: Int):
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    alias TempConvToler: Float32 = 0.1
    alias MaxIterations: Int = 10
    var ZoneTemp: Float64 = 0.0
    var ZoneNum: Int = thisHTR.ZonePtr
    thisHTR.QHTRRadSource = 0.0
    if thisHTR.availSched.getCurrentVal() > 0:
        var SetPtTemp: Float64 = thisHTR.setptSched.getCurrentVal()
        DistributeHTRadGains(state)
        HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
        HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ZoneNum)
        if thisHTR.ControlType == RadControlType.MATSPControl:
            ZoneTemp = thisZoneHB.MAT
        elif thisHTR.ControlType == RadControlType.MRTSPControl:
            ZoneTemp = thisZoneHB.MRT
        elif thisHTR.ControlType == RadControlType.OperativeSPControl:
            ZoneTemp = 0.5 * (thisZoneHB.MAT + thisZoneHB.MRT)
        else:
            assert(False)
        if ZoneTemp < (SetPtTemp - TempConvToler):
            var IterNum: Int = 0
            var ConvergFlag: Bool = False
            var HeatFrac: Float32
            var HeatFracMax: Float32 = 1.0
            var HeatFracMin: Float32 = 0.0
            while (IterNum <= MaxIterations) and (not ConvergFlag):
                if IterNum == 0:
                    HeatFrac = 1.0
                else:
                    HeatFrac = (HeatFracMin + HeatFracMax) / 2.0
                thisHTR.QHTRRadSource = HeatFrac * thisHTR.MaxPowerCapac
                DistributeHTRadGains(state)
                HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
                var thisZoneHBMod = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ZoneNum)
                if thisHTR.ControlType == RadControlType.MATControl:
                    ZoneTemp = thisZoneHBMod.MAT
                elif thisHTR.ControlType == RadControlType.MRTControl:
                    ZoneTemp = thisZoneHBMod.MRT
                elif thisHTR.ControlType == RadControlType.OperativeControl:
                    ZoneTemp = 0.5 * (thisZoneHBMod.MAT + thisZoneHBMod.MRT)
                if (abs(ZoneTemp - SetPtTemp)) <= TempConvToler:
                    ConvergFlag = True
                elif ZoneTemp < SetPtTemp:
                    if IterNum == 0:
                        ConvergFlag = True
                    else:
                        HeatFracMin = HeatFrac
                else:  # ZoneTemp > SetPtTemp
                    if IterNum > 0:
                        HeatFracMax = HeatFrac
                IterNum += 1

def UpdateHighTempRadiantSystem(inout state: EnergyPlusData, RadSysNum: Int, inout LoadMet: Float64):
    var ZoneNum: Int
    var SysTimeElapsed: Float64 = state.dataHVACGlobal.SysTimeElapsed
    var TimeStepSys: Float64 = state.dataHVACGlobal.TimeStepSys
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    if thisHTR.LastSysTimeElapsed == SysTimeElapsed:
        thisHTR.QHTRRadSrcAvg -= thisHTR.LastQHTRRadSrc * thisHTR.LastTimeStepSys / state.dataGlobal.TimeStepZone
    thisHTR.QHTRRadSrcAvg += thisHTR.QHTRRadSource * TimeStepSys / state.dataGlobal.TimeStepZone
    thisHTR.LastQHTRRadSrc = thisHTR.QHTRRadSource
    thisHTR.LastSysTimeElapsed = SysTimeElapsed
    thisHTR.LastTimeStepSys = TimeStepSys
    if (thisHTR.ControlType == RadControlType.MATControl) or (thisHTR.ControlType == RadControlType.MRTControl) or (thisHTR.ControlType == RadControlType.OperativeControl):
        DistributeHTRadGains(state)
        ZoneNum = thisHTR.ZonePtr
        HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
        HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
    if thisHTR.QHTRRadSource <= 0.0:
        LoadMet = 0.0
    else:
        ZoneNum = thisHTR.ZonePtr
        LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - thisHTR.ZeroHTRSourceSumHATsurf) + state.dataHeatBalFanSys.SumConvHTRadSys[ZoneNum - 1]

def UpdateHTRadSourceValAvg(inout state: EnergyPlusData, inout HighTempRadSysOn: Bool):
    HighTempRadSysOn = False
    if state.dataHighTempRadSys.NumOfHighTempRadSys == 0:
        return
    for thisHTR in state.dataHighTempRadSys.HighTempRadSys:
        thisHTR.QHTRRadSource = thisHTR.QHTRRadSrcAvg
        if thisHTR.QHTRRadSrcAvg != 0.0:
            HighTempRadSysOn = True
    DistributeHTRadGains(state)

def DistributeHTRadGains(inout state: EnergyPlusData):
    alias SmallestArea: Float64 = 0.001
    var ThisSurfIntensity: Float64
    var dataHBFS = state.dataHeatBalFanSys
    dataHBFS.SumConvHTRadSys = List[Float64](length=state.dataGlobal.NumOfZones, fill=0.0)
    dataHBFS.SumLatentHTRadSys = List[Float64](length=state.dataGlobal.NumOfZones, fill=0.0)
    # First pass: reset surfQRadFromHVAC.HTRadSys to 0 for all surfaces
    for thisHTR in state.dataHighTempRadSys.HighTempRadSys:
        for radSurfNum in range(1, thisHTR.TotSurfToDistrib + 1):
            var surfNum = thisHTR.SurfacePtr[radSurfNum - 1]
            state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum - 1].HTRadSys = 0.0
    dataHBFS.ZoneQHTRadSysToPerson = List[Float64](length=state.dataGlobal.NumOfZones, fill=0.0)
    for thisHTR in state.dataHighTempRadSys.HighTempRadSys:
        var ZoneNum: Int = thisHTR.ZonePtr
        dataHBFS.ZoneQHTRadSysToPerson[ZoneNum - 1] = thisHTR.QHTRRadSource * thisHTR.FracRadiant * thisHTR.FracDistribPerson
        dataHBFS.SumConvHTRadSys[ZoneNum - 1] += thisHTR.QHTRRadSource * thisHTR.FracConvect
        dataHBFS.SumLatentHTRadSys[ZoneNum - 1] += thisHTR.QHTRRadSource * thisHTR.FracLatent
        for RadSurfNum in range(1, thisHTR.TotSurfToDistrib + 1):
            var SurfNum = thisHTR.SurfacePtr[RadSurfNum - 1]
            if state.dataSurface.Surface[SurfNum - 1].Area > SmallestArea:
                ThisSurfIntensity = (thisHTR.QHTRRadSource * thisHTR.FracRadiant * thisHTR.FracDistribToSurf[RadSurfNum - 1] / state.dataSurface.Surface[SurfNum - 1].Area)
                state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum - 1].HTRadSys += ThisSurfIntensity
                if ThisSurfIntensity > DataHeatBalFanSys.MaxRadHeatFlux:
                    ShowSevereError(state, "DistributeHTRadGains:  excessive thermal radiation heat flux intensity detected")
                    ShowContinueError(state, String.format("Surface = {}", state.dataSurface.Surface[SurfNum - 1].Name))
                    ShowContinueError(state, String.format("Surface area = {:.3f} [m2]", state.dataSurface.Surface[SurfNum - 1].Area))
                    ShowContinueError(state, String.format("Occurs in ZoneHVAC:HighTemperatureRadiant = {}", thisHTR.Name))
                    ShowContinueError(state, String.format("Radiation intensity = {:#G} [W/m2]", ThisSurfIntensity))
                    ShowContinueError(state, "Assign a larger surface area or more surfaces in ZoneHVAC:HighTemperatureRadiant")
                    ShowFatalError(state, "DistributeHTRadGains:  excessive thermal radiation heat flux intensity detected")
            else:
                ShowSevereError(state, "DistributeHTRadGains:  surface not large enough to receive thermal radiation heat flux")
                ShowContinueError(state, String.format("Surface = {}", state.dataSurface.Surface[SurfNum - 1].Name))
                ShowContinueError(state, String.format("Surface area = {:.3f} [m2]", state.dataSurface.Surface[SurfNum - 1].Area))
                ShowContinueError(state, String.format("Occurs in ZoneHVAC:HighTemperatureRadiant = {}", thisHTR.Name))
                ShowContinueError(state, "Assign a larger surface area or more surfaces in ZoneHVAC:HighTemperatureRadiant")
                ShowFatalError(state, "DistributeHTRadGains:  surface not large enough to receive thermal radiation heat flux")
    for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
        dataHBFS.SumConvHTRadSys[ZoneNum - 1] += dataHBFS.ZoneQHTRadSysToPerson[ZoneNum - 1]

def ReportHighTempRadiantSystem(inout state: EnergyPlusData, RadSysNum: Int):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var thisHTR = state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1]
    if thisHTR.HeaterType == Constant.eResource.NaturalGas:
        thisHTR.GasPower = thisHTR.QHTRRadSource / thisHTR.CombustionEffic
        thisHTR.GasEnergy = thisHTR.GasPower * TimeStepSysSec
        thisHTR.ElecPower = 0.0
        thisHTR.ElecEnergy = 0.0
    elif thisHTR.HeaterType == Constant.eResource.Electricity:
        thisHTR.GasPower = 0.0
        thisHTR.GasEnergy = 0.0
        thisHTR.ElecPower = thisHTR.QHTRRadSource
        thisHTR.ElecEnergy = thisHTR.ElecPower * TimeStepSysSec
    else:
        ShowWarningError(state, "Someone forgot to add a high temperature radiant heater type to the reporting subroutine")
    thisHTR.HeatPower = thisHTR.QHTRRadSource
    thisHTR.HeatEnergy = thisHTR.HeatPower * TimeStepSysSec

# Global struct (outside inner namespace)
@value
struct HighTempRadiantSystemData_Global:
    var NumOfHighTempRadSys: Int = 0
    var MySizeFlag: List[Bool]
    var CheckEquipName: List[Bool]
    var HighTempRadSys: List[HighTempRadiantSystemData]
    var HighTempRadSysNumericFields: List[HighTempRadSysNumericFieldData]
    var GetInputFlag: Bool = True
    var firstTime: Bool = True
    var MyEnvrnFlag: Bool = True
    var ZoneEquipmentListChecked: Bool = False
    def init_constant_state(inout self, inout state: EnergyPlusData): pass
    def init_state(inout self, inout state: EnergyPlusData): pass
    def clear_state(inout self):
        self.NumOfHighTempRadSys = 0
        self.MySizeFlag = List[Bool]()
        self.CheckEquipName = List[Bool]()
        self.HighTempRadSys = List[HighTempRadiantSystemData]()
        self.HighTempRadSysNumericFields = List[HighTempRadSysNumericFieldData]()
        self.GetInputFlag = True
        self.firstTime = True
        self.MyEnvrnFlag = True
        self.ZoneEquipmentListChecked = False