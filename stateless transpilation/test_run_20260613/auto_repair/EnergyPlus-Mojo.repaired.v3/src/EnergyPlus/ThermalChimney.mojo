# Mojo translation of EnergyPlus ThermalChimney.cc
# Faithful 1:1 translation, no refactoring. All names preserved except array indexing (1-based -> 0-based).
# ObjexxFCL array slices replaced with loops or list comprehensions where needed.

from Constants import Constant
from DataEnvironment import *
from DataHeatBalance import *
from DataSurfaces import *
from DataHeatBalSurface import *
from Psychrometrics import *
from ScheduleManager import Sched
from .InputProcessing.InputProcessor import InputProcessor
from General import Util
from EMSManager import *
from OutputProcessor import SetupOutputVariable, SetupEMSActuator
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError, ShowSevereItemNotFound, ErrorObjectHeader
from ZoneTempPredictorCorrector import *

from module includes:
import "Data/EnergyPlusData"
import "DataGlobals"
import "DataHVACGlobals"
import "DataIPShortCuts"
import "EnergyPlus"

# Ensure all imported names are available:
# DataEnvironment, DataHeatBalance, DataSurfaces, DataHeatBalSurface, Psychrometrics

# Struct definitions (from header)
struct ThermalChimneyData:
    var Name: String
    var RealZonePtr: Int
    var RealZoneName: String
    var availSched: Sched.Schedule = None
    var AbsorberWallWidth: Float64
    var AirOutletCrossArea: Float64
    var DischargeCoeff: Float64
    var TotZoneToDistrib: Int
    var EMSOverrideOn: Bool
    var EMSAirFlowRateValue: Float64
    var ZonePtr: List[Int]  # 1‑based translation -> 0-based list
    var spacePtr: List[Int]
    var ZoneName: List[String]
    var DistanceThermChimInlet: List[Float64]
    var RatioThermChimAirFlow: List[Float64]
    var EachAirInletCrossArea: List[Float64]

    def __init__(inout self):
        self.RealZonePtr = 0
        self.AbsorberWallWidth = 0.0
        self.AirOutletCrossArea = 0.0
        self.DischargeCoeff = 0.0
        self.TotZoneToDistrib = 0
        self.EMSOverrideOn = False
        self.EMSAirFlowRateValue = 0.0
        self.ZonePtr = List[Int]()
        self.spacePtr = List[Int]()
        self.ZoneName = List[String]()
        self.DistanceThermChimInlet = List[Float64]()
        self.RatioThermChimAirFlow = List[Float64]()
        self.EachAirInletCrossArea = List[Float64]()

struct ThermChimZnReportVars:
    var ThermalChimneyHeatLoss: Float64
    var ThermalChimneyHeatGain: Float64
    var ThermalChimneyVolume: Float64
    var ThermalChimneyMass: Float64
    def __init__(inout self):
        self.ThermalChimneyHeatLoss = 0.0
        self.ThermalChimneyHeatGain = 0.0
        self.ThermalChimneyVolume = 0.0
        self.ThermalChimneyMass = 0.0

struct ThermChimReportVars:
    var OverallTCVolumeFlow: Float64
    var OverallTCVolumeFlowStd: Float64
    var OverallTCMassFlow: Float64
    var OutletAirTempThermalChim: Float64
    def __init__(inout self):
        self.OverallTCVolumeFlow = 0.0
        self.OverallTCVolumeFlowStd = 0.0
        self.OverallTCMassFlow = 0.0
        self.OutletAirTempThermalChim = 0.0

# The external global struct is defined elsewhere; we define the functions directly.

def ManageThermalChimney(inout state: EnergyPlusData):
    if state.dataThermalChimneys.ThermalChimneyGetInputFlag:
        var ErrorsFound: Bool = False
        GetThermalChimney(state, ErrorsFound)
        state.dataThermalChimneys.ThermalChimneyGetInputFlag = False
    if state.dataThermalChimneys.TotThermalChimney == 0:
        return
    CalcThermalChimney(state)
    ReportThermalChimney(state)

def GetThermalChimney(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    let routineName: String = "GetThermalChimney"
    let FlowFractionTolerance: Float64 = 0.0001
    var NumAlpha: Int
    var NumNumber: Int
    var AllRatiosSummed: Float64
    var TCZoneNum: Int
    var TCZoneNum1: Int
    var IOStat: Int
    var Loop: Int
    var cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject

    state.dataThermalChimneys.ZnRptThermChim = List[ThermChimZnReportVars](state.dataGlobal.NumOfZones)
    cCurrentModuleObject = "ZoneThermalChimney"
    state.dataThermalChimneys.TotThermalChimney = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataThermalChimneys.ThermalChimneySys = List[ThermalChimneyData](state.dataThermalChimneys.TotThermalChimney)
    state.dataThermalChimneys.ThermalChimneyReport = List[ThermChimReportVars](state.dataThermalChimneys.TotThermalChimney)

    for Loop in range(state.dataThermalChimneys.TotThermalChimney):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            cCurrentModuleObject,
            Loop + 1,
            state.dataIPShortCut.cAlphaArgs,
            NumAlpha,
            state.dataIPShortCut.rNumericArgs,
            NumNumber,
            IOStat,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames)
        let eoh = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0))

        state.dataThermalChimneys.ThermalChimneySys[Loop].Name = state.dataIPShortCut.cAlphaArgs(0)
        state.dataThermalChimneys.ThermalChimneySys[Loop].RealZonePtr = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs(1), state.dataHeatBal.Zone)

        if state.dataThermalChimneys.ThermalChimneySys[Loop].RealZonePtr == 0:
            ShowSevereError(state, format("{}=\"{} invalid Zone", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0)))
            ShowContinueError(state, format("invalid - not found {}=\"{}\".", state.dataIPShortCut.cAlphaFieldNames(1), state.dataIPShortCut.cAlphaArgs(1)))
            ErrorsFound = True
        else if not state.dataHeatBal.Zone[state.dataThermalChimneys.ThermalChimneySys[Loop].RealZonePtr - 1].HasWindow:
            # 0‑based indexing: RealZonePtr is 1‑based, so subtract 1
            ShowSevereError(state, format("{}=\"{} invalid Zone", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0)))
            ShowContinueError(state, format("...invalid - no window(s) in {}=\"{}\".", state.dataIPShortCut.cAlphaFieldNames(1), state.dataIPShortCut.cAlphaArgs(1)))
            ShowContinueError(state, "...thermal chimney zones must have window(s).")
            ErrorsFound = True

        state.dataThermalChimneys.ThermalChimneySys[Loop].RealZoneName = state.dataIPShortCut.cAlphaArgs(1)

        if state.dataIPShortCut.lAlphaFieldBlanks(2):
            state.dataThermalChimneys.ThermalChimneySys[Loop].availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            state.dataThermalChimneys.ThermalChimneySys[Loop].availSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs(2))
            if state.dataThermalChimneys.ThermalChimneySys[Loop].availSched == None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames(2), state.dataIPShortCut.cAlphaArgs(2))
                ErrorsFound = True

        state.dataThermalChimneys.ThermalChimneySys[Loop].AbsorberWallWidth = state.dataIPShortCut.rNumericArgs(0)
        if state.dataThermalChimneys.ThermalChimneySys[Loop].AbsorberWallWidth < 0.0:
            ShowSevereError(state, format("{}=\"{} invalid {} must be >= 0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(0), state.dataIPShortCut.rNumericArgs(0)))
            ErrorsFound = True

        state.dataThermalChimneys.ThermalChimneySys[Loop].AirOutletCrossArea = state.dataIPShortCut.rNumericArgs(1)
        if state.dataThermalChimneys.ThermalChimneySys[Loop].AirOutletCrossArea < 0.0:
            ShowSevereError(state, format("{}=\"{} invalid {} must be >= 0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(1), state.dataIPShortCut.rNumericArgs(1)))
            ErrorsFound = True

        state.dataThermalChimneys.ThermalChimneySys[Loop].DischargeCoeff = state.dataIPShortCut.rNumericArgs(2)
        if (state.dataThermalChimneys.ThermalChimneySys[Loop].DischargeCoeff <= 0.0) or (state.dataThermalChimneys.ThermalChimneySys[Loop].DischargeCoeff > 1.0):
            ShowSevereError(state, format("{}=\"{} invalid {} must be > 0 and <=1.0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(2), state.dataIPShortCut.rNumericArgs(2)))
            ErrorsFound = True

        state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib = NumAlpha - 3
        # Allocate dynamic arrays (1‑based in C++, but we use 0‑based lists)
        state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr = List[Int](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)
        state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr = List[Int](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)
        state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName = List[String](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)
        state.dataThermalChimneys.ThermalChimneySys[Loop].DistanceThermChimInlet = List[Float64](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)
        state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow = List[Float64](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)
        state.dataThermalChimneys.ThermalChimneySys[Loop].EachAirInletCrossArea = List[Float64](state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib)

        AllRatiosSummed = 0.0
        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            # C++ index TCZoneNum starts at 1, so alphaArgs index = TCZoneNum + 3 (1‑based)
            # In Mojo: TCZoneNum is 0‑based, so alphaArgs index = TCZoneNum + 3
            state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum] = state.dataIPShortCut.cAlphaArgs(TCZoneNum + 3)
            state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs(TCZoneNum + 3), state.dataHeatBal.Zone)
            if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == 0:
                let spaceNum = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs(TCZoneNum + 3), state.dataHeatBal.space)
                if spaceNum > 0:
                    state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr[TCZoneNum] = spaceNum
                    let zoneNum = state.dataHeatBal.space[spaceNum - 1].zoneNum
                    state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] = zoneNum
            # Numeric args: 1‑based index = 3*(TCZoneNum+1) + 1 ? In C++: rNumericArgs(3*TCZoneNum + 1) where TCZoneNum starts at 1.
            # So 0‑based: 3*(TCZoneNum+1) + 1? Let's derive: for TCZoneNum=1 (C++), index=3*1+1=4. For 0‑based TCZoneNum=0: 3*0+4=4. So formula: 3*TCZoneNum + 4
            state.dataThermalChimneys.ThermalChimneySys[Loop].DistanceThermChimInlet[TCZoneNum] = state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 4)
            state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] = state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 5)
            if state.dataIPShortCut.lNumericFieldBlanks(3 * TCZoneNum + 5):
                state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] = 1.0
            state.dataThermalChimneys.ThermalChimneySys[Loop].EachAirInletCrossArea[TCZoneNum] = state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 6)
            if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == 0:
                ShowSevereError(state, format("{}=\"{} invalid {}=\"{}\" not found.", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cAlphaFieldNames(TCZoneNum + 3), state.dataIPShortCut.cAlphaArgs(TCZoneNum + 3)))
                ErrorsFound = True
            else if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop].RealZonePtr:
                ShowSevereError(state, format("{}=\"{} invalid reference {}=\"{}\"", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cAlphaFieldNames(2), state.dataIPShortCut.cAlphaArgs(2)))
                ShowContinueError(state, format("...must not have same zone as reference= {}=\"{}\".", state.dataIPShortCut.cAlphaFieldNames(TCZoneNum + 3), state.dataIPShortCut.cAlphaArgs(TCZoneNum + 3)))
                ErrorsFound = True
            if state.dataThermalChimneys.ThermalChimneySys[Loop].DistanceThermChimInlet[TCZoneNum] < 0.0:
                ShowSevereError(state, format("{}=\"{} invalid {} must be >= 0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(3 * TCZoneNum + 4), state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 4)))
                ErrorsFound = True
            if (state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] <= 0.0) or (state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] > 1.0):
                ShowSevereError(state, format("{}=\"{} invalid {} must be > 0 and <=1.0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(3 * TCZoneNum + 5), state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 5)))
                ErrorsFound = True
            if state.dataThermalChimneys.ThermalChimneySys[Loop].EachAirInletCrossArea[TCZoneNum] < 0.0:
                ShowSevereError(state, format("{}=\"{} invalid {} must be >= 0, entered value=[{:.2R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), state.dataIPShortCut.cNumericFieldNames(3 * TCZoneNum + 6), state.dataIPShortCut.rNumericArgs(3 * TCZoneNum + 6)))
                ErrorsFound = True
            AllRatiosSummed += state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum]

        if Math.abs(AllRatiosSummed - 1.0) > FlowFractionTolerance:
            ShowSevereError(state, format("{}=\"{} invalid sum of fractions, must be =1.0, entered value (summed from entries)=[{:.4R}].", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs(0), AllRatiosSummed))
            ErrorsFound = True

    # RepVarSet: 1‑based bool array
    var RepVarSet = List[Bool](state.dataGlobal.NumOfZones, True)
    for Loop in range(state.dataHeatBal.TotInfiltration):
        let zoneNum = state.dataHeatBal.Infiltration[Loop].ZonePtr
        if zoneNum > 0 and not state.dataHeatBal.Zone[zoneNum - 1].zoneOAQuadratureSum:
            RepVarSet[zoneNum - 1] = False

    for Loop in range(state.dataThermalChimneys.TotThermalChimney):
        SetupOutputVariable(state, "Zone Thermal Chimney Current Density Air Volume Flow Rate", Constant.Units.m3_s, state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlow, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataThermalChimneys.ThermalChimneySys[Loop].Name)
        SetupOutputVariable(state, "Zone Thermal Chimney Standard Density Air Volume Flow Rate", Constant.Units.m3_s, state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlowStd, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataThermalChimneys.ThermalChimneySys[Loop].Name)
        SetupOutputVariable(state, "Zone Thermal Chimney Mass Flow Rate", Constant.Units.kg_s, state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCMassFlow, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataThermalChimneys.ThermalChimneySys[Loop].Name)
        SetupOutputVariable(state, "Zone Thermal Chimney Outlet Temperature", Constant.Units.C, state.dataThermalChimneys.ThermalChimneyReport[Loop].OutletAirTempThermalChim, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataThermalChimneys.ThermalChimneySys[Loop].Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Zone Thermal Chimney", state.dataThermalChimneys.ThermalChimneySys[Loop].Name, "Air Exchange Flow Rate", "[m3/s]", state.dataThermalChimneys.ThermalChimneySys[Loop].EMSOverrideOn, state.dataThermalChimneys.ThermalChimneySys[Loop].EMSAirFlowRateValue)
        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            let zoneIdx = state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] - 1  # 0‑based
            SetupOutputVariable(state, "Zone Thermal Chimney Heat Loss Energy", Constant.Units.J, state.dataThermalChimneys.ZnRptThermChim[zoneIdx].ThermalChimneyHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
            SetupOutputVariable(state, "Zone Thermal Chimney Heat Gain Energy", Constant.Units.J, state.dataThermalChimneys.ZnRptThermChim[zoneIdx].ThermalChimneyHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
            SetupOutputVariable(state, "Zone Thermal Chimney Volume", Constant.Units.m3, state.dataThermalChimneys.ZnRptThermChim[zoneIdx].ThermalChimneyVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
            SetupOutputVariable(state, "Zone Thermal Chimney Mass", Constant.Units.kg, state.dataThermalChimneys.ZnRptThermChim[zoneIdx].ThermalChimneyMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
            if RepVarSet[zoneIdx]:
                SetupOutputVariable(state, "Zone Infiltration Sensible Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Sensible Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Latent Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Latent Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilLatentGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Total Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Total Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilTotalGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilVdotCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilVdotStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Outdoor Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilVdotOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilVolumeCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilVolumeStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Mass", Constant.Units.kg, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Mass Flow Rate", Constant.Units.kg_s, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilMdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilAirChangeRateCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilAirChangeRateStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                SetupOutputVariable(state, "Zone Infiltration Outdoor Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[zoneIdx].InfilAirChangeRateOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[zoneIdx].Name)
                RepVarSet[zoneIdx] = False

    # Check for duplicate zones within the same chimney
    for Loop in range(state.dataThermalChimneys.TotThermalChimney):
        if state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib > 1:
            for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                if state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib >= (TCZoneNum + 2):
                    for TCZoneNum1 in range(TCZoneNum + 1, state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                        if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum1]:
                            ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                            ErrorsFound = True
                    for TCZoneNum1 in range(0, TCZoneNum):
                        if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum1]:
                            ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                            ErrorsFound = True
                else:
                    for TCZoneNum1 in range(0, TCZoneNum):
                        if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum1]:
                            ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                            ErrorsFound = True

    # Check for duplicate zones across different chimneys
    if state.dataThermalChimneys.TotThermalChimney > 1:
        for Loop in range(state.dataThermalChimneys.TotThermalChimney):
            if state.dataThermalChimneys.TotThermalChimney >= (Loop + 2):
                for Loop1 in range(Loop + 1, state.dataThermalChimneys.TotThermalChimney):
                    for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                        for TCZoneNum1 in range(state.dataThermalChimneys.ThermalChimneySys[Loop1].TotZoneToDistrib):
                            if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop1].ZonePtr[TCZoneNum1]:
                                ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                                ErrorsFound = True
                for Loop1 in range(0, Loop):
                    for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                        for TCZoneNum1 in range(state.dataThermalChimneys.ThermalChimneySys[Loop1].TotZoneToDistrib):
                            if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop1].ZonePtr[TCZoneNum1]:
                                ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                                ErrorsFound = True
            else:
                for Loop1 in range(0, Loop):
                    for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                        for TCZoneNum1 in range(state.dataThermalChimneys.ThermalChimneySys[Loop1].TotZoneToDistrib):
                            if state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum] == state.dataThermalChimneys.ThermalChimneySys[Loop1].ZonePtr[TCZoneNum1]:
                                ShowSevereError(state, format("Only one ZoneThermalChimney object allowed per zone but zone {} has two ZoneThermalChimney objects associated with it", state.dataThermalChimneys.ThermalChimneySys[Loop].ZoneName[TCZoneNum]))
                                ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(state, format("{} Errors found in input.  Preceding condition(s) cause termination.", cCurrentModuleObject))

def CalcThermalChimney(inout state: EnergyPlusData):
    let NTC: Int = 15
    var SurfTempAbsorberWall: Float64
    var SurfTempGlassCover: Float64
    var ConvTransCoeffWallFluid: Float64
    var ConvTransCoeffGlassFluid: Float64
    var minorW: Float64
    var majorW: Float64
    var TempmajorW: Float64
    var RoomAirTemp: Float64
    var AirSpecHeatThermalChim: Float64
    var AbsorberWallWidthTC: Float64
    var TCVolumeAirFlowRate: Float64
    var TCMassAirFlowRate: Float64
    var DischargeCoeffTC: Float64
    var AirOutletCrossAreaTC: Float64
    var AirInletCrossArea: Float64
    var AirRelativeCrossArea: Float64
    var OverallThermalChimLength: Float64
    var ThermChimTolerance: Float64
    var TempTCMassAirFlowRate = List[Float64](10, 0.0)
    var TempTCVolumeAirFlowRate = List[Float64](10, 0.0)
    var IterationLoop: Int
    var Process1: Float64
    var Process2: Float64
    var Process3: Float64
    var AirDensityThermalChim: Float64
    var AirDensity: Float64
    var CpAir: Float64
    var TemporaryWallSurfTemp: Float64
    var DeltaL: Float64
    var ThermChimLoop1: Int
    var ThermChimLoop2: Int
    # EquaCoef: NTC x NTC matrix (1‑based in C++, we make 0‑based list of lists)
    var EquaCoef = List[List[Float64]](NTC)
    for i in range(NTC):
        EquaCoef[i] = List[Float64](NTC, 0.0)
    var EquaConst = List[Float64](NTC, 0.0)
    var ThermChimSubTemp = List[Float64](NTC, 0.0)

    for Loop in range(state.dataThermalChimneys.TotThermalChimney):
        let ZoneNum = state.dataThermalChimneys.ThermalChimneySys[Loop].RealZonePtr  # 1‑based
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
        let firstSpaceHTSurfaceFirst = state.dataHeatBal.space[state.dataHeatBal.Zone[ZoneNum - 1].spaceIndexes[0] - 1].HTSurfaceFirst
        majorW = state.dataSurface.Surface[firstSpaceHTSurfaceFirst - 1].Width
        minorW = majorW
        TempmajorW = 0.0
        TemporaryWallSurfTemp = -10000.0

        for spaceNum in state.dataHeatBal.Zone[ZoneNum - 1].spaceIndexes:
            let thisSpace = state.dataHeatBal.space[spaceNum - 1]
            for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                if state.dataSurface.Surface[SurfNum - 1].Class != SurfaceClass.Wall:
                    continue
                if state.dataSurface.Surface[SurfNum - 1].Width > majorW:
                    majorW = state.dataSurface.Surface[SurfNum - 1].Width
                if state.dataSurface.Surface[SurfNum - 1].Width < minorW:
                    minorW = state.dataSurface.Surface[SurfNum - 1].Width
            for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                if state.dataSurface.Surface[SurfNum - 1].Width == majorW:
                    if state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] > TemporaryWallSurfTemp:
                        TemporaryWallSurfTemp = state.dataHeatBalSurf.SurfTempIn[SurfNum - 1]
                        ConvTransCoeffWallFluid = state.dataHeatBalSurf.SurfHConvInt[SurfNum - 1]
                        SurfTempAbsorberWall = state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] + Constant.Kelvin
            for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                if state.dataSurface.Surface[SurfNum - 1].Class == SurfaceClass.Window:
                    if state.dataSurface.Surface[SurfNum - 1].Width > TempmajorW:
                        TempmajorW = state.dataSurface.Surface[SurfNum - 1].Width
                        ConvTransCoeffGlassFluid = state.dataHeatBalSurf.SurfHConvInt[SurfNum - 1]
                        SurfTempGlassCover = state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] + Constant.Kelvin

        AbsorberWallWidthTC = majorW
        if state.dataThermalChimneys.ThermalChimneySys[Loop].AbsorberWallWidth != majorW:
            AbsorberWallWidthTC = state.dataThermalChimneys.ThermalChimneySys[Loop].AbsorberWallWidth

        AirDensityThermalChim = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, thisZoneHB.MAT, thisZoneHB.airHumRat)
        AirSpecHeatThermalChim = PsyCpAirFnW(thisZoneHB.airHumRat)
        AirOutletCrossAreaTC = state.dataThermalChimneys.ThermalChimneySys[Loop].AirOutletCrossArea
        DischargeCoeffTC = state.dataThermalChimneys.ThermalChimneySys[Loop].DischargeCoeff
        AirInletCrossArea = 0.0
        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            AirInletCrossArea += state.dataThermalChimneys.ThermalChimneySys[Loop].EachAirInletCrossArea[TCZoneNum]

        RoomAirTemp = 0.0
        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            let tcSpacePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr[TCZoneNum]
            if (state.dataHeatBal.doSpaceHeatBalance) and (tcSpacePtr > 0):
                RoomAirTemp += state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] * state.dataZoneTempPredictorCorrector.spaceHeatBalance[tcSpacePtr - 1].MAT
            else:
                let tcZonePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum]
                RoomAirTemp += state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] * state.dataZoneTempPredictorCorrector.zoneHeatBalance[tcZonePtr - 1].MAT
        RoomAirTemp += Constant.Kelvin

        Process1 = 0.0
        Process2 = 0.0
        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            let tcZonePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum]
            var thisTCZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[tcZonePtr - 1]
            var tcZoneMAT = thisTCZoneHB.MAT
            var tcZoneHumRat = thisTCZoneHB.airHumRat
            let tcSpacePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr[TCZoneNum]
            if (state.dataHeatBal.doSpaceHeatBalance) and (tcSpacePtr > 0):
                let thisTCspaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[tcSpacePtr - 1]
                tcZoneMAT = thisTCspaceHB.MAT
                tcZoneHumRat = thisTCspaceHB.airHumRat
            let tcZoneEnth = PsyHFnTdbW(tcZoneMAT, tcZoneHumRat)
            Process1 += tcZoneEnth * state.dataThermalChimneys.ThermalChimneySys[Loop].DistanceThermChimInlet[TCZoneNum] * state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum]
            Process2 += state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum] * tcZoneEnth
        OverallThermalChimLength = Process1 / Process2
        DeltaL = OverallThermalChimLength / NTC
        ThermChimTolerance = 10000000.0
        for IterationLoop in range(10):
            if IterationLoop == 0:
                TempTCMassAirFlowRate[IterationLoop] = 0.05
            else:
                TempTCMassAirFlowRate[IterationLoop] = TempTCVolumeAirFlowRate[IterationLoop - 1] * AirDensityThermalChim
                if abs(TempTCMassAirFlowRate[IterationLoop] - TempTCMassAirFlowRate[IterationLoop - 1]) < ThermChimTolerance:
                    ThermChimTolerance = abs(TempTCMassAirFlowRate[IterationLoop] - TempTCMassAirFlowRate[IterationLoop - 1])
                    TCMassAirFlowRate = TempTCMassAirFlowRate[IterationLoop]
            Process1 = AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid + AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid - 2.0 * TempTCMassAirFlowRate[IterationLoop] * AirSpecHeatThermalChim
            Process2 = AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid + AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid + 2.0 * TempTCMassAirFlowRate[IterationLoop] * AirSpecHeatThermalChim
            Process3 = 2.0 * AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid * SurfTempGlassCover + 2.0 * AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid * SurfTempAbsorberWall
            for ThermChimLoop1 in range(NTC):
                for ThermChimLoop2 in range(NTC):
                    EquaCoef[ThermChimLoop2][ThermChimLoop1] = 0.0
            EquaCoef[0][0] = Process2
            EquaConst[0] = Process3 - Process1 * RoomAirTemp
            for ThermChimLoop1 in range(1, NTC):
                EquaCoef[ThermChimLoop1 - 1][ThermChimLoop1] = Process1
                EquaCoef[ThermChimLoop1][ThermChimLoop1] = Process2
                EquaConst[ThermChimLoop1] = Process3
            GaussElimination(EquaCoef, EquaConst, ThermChimSubTemp, NTC)
            AirRelativeCrossArea = AirOutletCrossAreaTC / AirInletCrossArea
            if ThermChimSubTemp[NTC - 1] <= RoomAirTemp:
                TempTCVolumeAirFlowRate[IterationLoop] = 0.0
            else:
                TempTCVolumeAirFlowRate[IterationLoop] = DischargeCoeffTC * AirOutletCrossAreaTC * Math.sqrt(2.0 * ((ThermChimSubTemp[NTC - 1] - RoomAirTemp) / RoomAirTemp) * 9.8 * OverallThermalChimLength / Math.pow((1.0 + AirRelativeCrossArea), 2))

        Process1 = AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid + AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid - 2.0 * TCMassAirFlowRate * AirSpecHeatThermalChim
        Process2 = AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid + AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid + 2.0 * TCMassAirFlowRate * AirSpecHeatThermalChim
        Process3 = 2.0 * AbsorberWallWidthTC * DeltaL * ConvTransCoeffGlassFluid * SurfTempGlassCover + 2.0 * AbsorberWallWidthTC * DeltaL * ConvTransCoeffWallFluid * SurfTempAbsorberWall
        for ThermChimLoop1 in range(NTC):
            for ThermChimLoop2 in range(NTC):
                EquaCoef[ThermChimLoop2][ThermChimLoop1] = 0.0
        EquaCoef[0][0] = Process2
        EquaConst[0] = Process3 - Process1 * RoomAirTemp
        for ThermChimLoop1 in range(1, NTC):
            EquaCoef[ThermChimLoop1 - 1][ThermChimLoop1] = Process1
            EquaCoef[ThermChimLoop1][ThermChimLoop1] = Process2
            EquaConst[ThermChimLoop1] = Process3
        GaussElimination(EquaCoef, EquaConst, ThermChimSubTemp, NTC)
        AirRelativeCrossArea = AirOutletCrossAreaTC / AirInletCrossArea
        if ThermChimSubTemp[NTC - 1] <= RoomAirTemp:
            TCVolumeAirFlowRate = 0.0
        else:
            TCVolumeAirFlowRate = DischargeCoeffTC * AirOutletCrossAreaTC * Math.sqrt(2.0 * ((ThermChimSubTemp[NTC - 1] - RoomAirTemp) / RoomAirTemp) * 9.8 * OverallThermalChimLength / Math.pow((1.0 + AirRelativeCrossArea), 2))
            if state.dataThermalChimneys.ThermalChimneySys[Loop].EMSOverrideOn:
                TCVolumeAirFlowRate = state.dataThermalChimneys.ThermalChimneySys[Loop].EMSAirFlowRateValue

        for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
            let tcZonePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum]
            var thisTCZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[tcZonePtr - 1]
            var tcZoneMAT = thisTCZoneHB.MAT
            var tcZoneHumRat = thisTCZoneHB.airHumRat
            let tcSpacePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr[TCZoneNum]
            if (state.dataHeatBal.doSpaceHeatBalance) and (tcSpacePtr > 0):
                let thisTCSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[tcSpacePtr - 1]
                tcZoneMAT = thisTCSpaceHB.MAT
                tcZoneHumRat = thisTCSpaceHB.airHumRat
            AirDensity = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, tcZoneMAT, tcZoneHumRat)
            CpAir = PsyCpAirFnW(tcZoneHumRat)
            var thisMCPThermChim = TCVolumeAirFlowRate * AirDensity * CpAir * state.dataThermalChimneys.ThermalChimneySys[Loop].RatioThermChimAirFlow[TCZoneNum]
            if thisMCPThermChim <= 0.0:
                thisMCPThermChim = 0.0
            var thisThermChimAMFL = thisMCPThermChim / CpAir
            let thisMCPTThermChim = thisMCPThermChim * state.dataHeatBal.Zone[tcZonePtr - 1].OutDryBulbTemp
            thisTCZoneHB.MCPThermChim = thisMCPThermChim
            thisTCZoneHB.ThermChimAMFL = thisThermChimAMFL
            thisTCZoneHB.MCPTThermChim = thisMCPTThermChim
            if (state.dataHeatBal.doSpaceHeatBalance) and (tcSpacePtr > 0):
                var thisTCSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[tcSpacePtr - 1]
                thisTCSpaceHB.MCPThermChim = thisMCPThermChim
                thisTCSpaceHB.ThermChimAMFL = thisThermChimAMFL
                thisTCSpaceHB.MCPTThermChim = thisMCPTThermChim

        thisZoneHB.MCPThermChim = TCVolumeAirFlowRate * AirDensity * CpAir
        if thisZoneHB.MCPThermChim <= 0.0:
            thisZoneHB.MCPThermChim = 0.0
        thisZoneHB.ThermChimAMFL = thisZoneHB.MCPThermChim / CpAir
        thisZoneHB.MCPTThermChim = thisZoneHB.MCPThermChim * state.dataHeatBal.Zone[ZoneNum - 1].OutDryBulbTemp

        state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlow = TCVolumeAirFlowRate
        state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCMassFlow = TCMassAirFlowRate
        state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlowStd = TCMassAirFlowRate / state.dataEnvrn.StdRhoAir
        if state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCMassFlow != (TCVolumeAirFlowRate * AirDensityThermalChim):
            state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCMassFlow = state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlow * AirDensityThermalChim
        state.dataThermalChimneys.ThermalChimneyReport[Loop].OutletAirTempThermalChim = ThermChimSubTemp[NTC - 1] - Constant.Kelvin

        if state.dataThermalChimneys.ThermalChimneySys[Loop].availSched.getCurrentVal() <= 0.0:
            for TCZoneNum in range(state.dataThermalChimneys.ThermalChimneySys[Loop].TotZoneToDistrib):
                let tcZonePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].ZonePtr[TCZoneNum]
                var thisTCZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[tcZonePtr - 1]
                thisTCZoneHB.MCPThermChim = 0.0
                thisTCZoneHB.ThermChimAMFL = 0.0
                thisTCZoneHB.MCPTThermChim = 0.0
                let tcSpacePtr = state.dataThermalChimneys.ThermalChimneySys[Loop].spacePtr[TCZoneNum]
                if (state.dataHeatBal.doSpaceHeatBalance) and (tcSpacePtr > 0):
                    var thisTCSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[tcSpacePtr - 1]
                    thisTCSpaceHB.MCPThermChim = 0.0
                    thisTCSpaceHB.ThermChimAMFL = 0.0
                    thisTCSpaceHB.MCPTThermChim = 0.0
            thisZoneHB.MCPThermChim = 0.0
            thisZoneHB.ThermChimAMFL = 0.0
            thisZoneHB.MCPTThermChim = 0.0
            state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlow = 0.0
            state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCVolumeFlowStd = 0.0
            state.dataThermalChimneys.ThermalChimneyReport[Loop].OverallTCMassFlow = 0.0
            state.dataThermalChimneys.ThermalChimneyReport[Loop].OutletAirTempThermalChim = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT

def ReportThermalChimney(inout state: EnergyPlusData):
    let TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var ZoneLoop: Int
    var AirDensity: Float64
    var CpAir: Float64
    for ZoneLoop in range(state.dataGlobal.NumOfZones):
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop]
        AirDensity = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop].MAT, thisZoneHB.airHumRat)
        CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
        state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyVolume = (thisZoneHB.MCPThermChim / CpAir / AirDensity) * TimeStepSysSec
        state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyMass = (thisZoneHB.MCPThermChim / CpAir) * TimeStepSysSec
        state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatLoss = 0.0
        state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatGain = 0.0
        if state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop].ZT > state.dataHeatBal.Zone[ZoneLoop].OutDryBulbTemp:
            state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatLoss = thisZoneHB.MCPThermChim * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop].ZT - state.dataHeatBal.Zone[ZoneLoop].OutDryBulbTemp) * TimeStepSysSec
            state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatGain = 0.0
        else if state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop].ZT <= state.dataHeatBal.Zone[ZoneLoop].OutDryBulbTemp:
            state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatGain = thisZoneHB.MCPThermChim * (state.dataHeatBal.Zone[ZoneLoop].OutDryBulbTemp - state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop].ZT) * TimeStepSysSec
            state.dataThermalChimneys.ZnRptThermChim[ZoneLoop].ThermalChimneyHeatLoss = 0.0

def GaussElimination(inout EquaCoef: List[List[Float64]], inout EquaConst: List[Float64], inout ThermChimSubTemp: List[Float64], NTC: Int):
    # EquaCoef is NTC x NTC, EquaConst size NTC, ThermChimSubTemp size NTC
    var tempor = List[Float64](NTC)
    var tempb: Float64
    var TCvalue: Float64
    var TCcoefficient: Float64
    var ThermalChimSum: Float64
    var ThermChimLoop1: Int
    var ThermChimLoop2: Int
    var ThermChimLoop3: Int

    for ThermChimLoop1 in range(NTC):
        TCvalue = abs(EquaCoef[ThermChimLoop1][ThermChimLoop1])
        var pivot = ThermChimLoop1
        for ThermChimLoop2 in range(ThermChimLoop1 + 1, NTC):
            if abs(EquaCoef[ThermChimLoop1][ThermChimLoop2]) > TCvalue:
                TCvalue = abs(EquaCoef[ThermChimLoop1][ThermChimLoop2])
                pivot = ThermChimLoop2
        if pivot != ThermChimLoop1:
            # Swap rows: slice from ThermChimLoop1 to NTC-1 along column dimension? Original: tempor({ThermChimLoop1, NTC}) = EquaCoef({ThermChimLoop1, NTC}, ThermChimLoop1)
            # This is a 1D slice of column ThermChimLoop1 from rows ThermChimLoop1 to NTC. We'll implement with loop.
            for i in range(ThermChimLoop1, NTC):
                tempor[i] = EquaCoef[i][ThermChimLoop1]
            tempb = EquaConst[ThermChimLoop1]
            # EquaCoef({ThermChimLoop1, NTC}, ThermChimLoop1) = EquaCoef({ThermChimLoop1, NTC}, pivot)
            for i in range(ThermChimLoop1, NTC):
                EquaCoef[i][ThermChimLoop1] = EquaCoef[i][pivot]
            EquaConst[ThermChimLoop1] = EquaConst[pivot]
            # EquaCoef({ThermChimLoop1, NTC}, pivot) = tempor({ThermChimLoop1, NTC})
            for i in range(ThermChimLoop1, NTC):
                EquaCoef[i][pivot] = tempor[i]
            EquaConst[pivot] = tempb

        for ThermChimLoop2 in range(ThermChimLoop1 + 1, NTC):
            TCcoefficient = -EquaCoef[ThermChimLoop1][ThermChimLoop2] / EquaCoef[ThermChimLoop1][ThermChimLoop1]
            # EquaCoef({ThermChimLoop1, NTC}, ThermChimLoop2) += TCcoefficient * EquaCoef({ThermChimLoop1, NTC}, ThermChimLoop1)
            for i in range(ThermChimLoop1, NTC):
                EquaCoef[i][ThermChimLoop2] += TCcoefficient * EquaCoef[i][ThermChimLoop1]
            EquaConst[ThermChimLoop2] += TCcoefficient * EquaConst[ThermChimLoop1]

    ThermChimSubTemp[NTC - 1] = EquaConst[NTC - 1] / EquaCoef[NTC - 1][NTC - 1]
    for ThermChimLoop2 in range(NTC - 2, -1, -1):
        ThermalChimSum = 0.0
        for ThermChimLoop3 in range(ThermChimLoop2 + 1, NTC):
            ThermalChimSum += EquaCoef[ThermChimLoop3][ThermChimLoop2] * ThermChimSubTemp[ThermChimLoop3]
        ThermChimSubTemp[ThermChimLoop2] = (EquaConst[ThermChimLoop2] - ThermalChimSum) / EquaCoef[ThermChimLoop2][ThermChimLoop2]