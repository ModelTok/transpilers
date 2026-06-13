# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from collections.vector import DynamicVector
from memory import UnsafePointer

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: opaque pointer to state object
# - DataSizing enums: OAFlowCalcMethod, PeakLoad, LoadSizing, SizingConcurrence
# - Constant enums: KindOfSim, CallIndicator
# - Error/message functions: ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError
# - Schedule functions: GetSchedule, GetScheduleAlwaysOn
# - Weather functions: ResetEnvironmentCounter, GetNextEnvironment, ManageWeather
# - HeatBalance functions: ManageHeatBalance
# - ZoneEquipment functions: ManageZoneEquipment, UpdateZoneSizing, RezeroZoneSizingArrays
# - AirLoop functions: ManageAirLoops, UpdateSysSizing
# - Output functions: PreDefTableEntry, DisplayString
# - Util functions: FindItemInList, makeUPPER, SameString
# - Format functions: EnergyPlus.format

struct KindOfSim:
    alias RunPeriodDesign = 1
    alias RunPeriodWeather = 2

struct CallIndicator:
    alias BeginDay = 1
    alias DuringDay = 2
    alias EndDay = 3
    alias EndZoneSizingCalc = 4

struct OAFlowCalcMethod:
    alias PerPerson = 0
    alias PerZone = 1
    alias PerArea = 2
    alias ACH = 3
    alias Sum = 4
    alias Max = 5
    alias IAQProcedure = 6
    alias PCOccSch = 7
    alias PCDesOcc = 8
    alias Invalid = 9

struct ZoneListData:
    var Name: String
    var NumOfZones: Int
    var Zones: DynamicVector[Int]

    fn __init__(inout self):
        self.Name = String()
        self.NumOfZones = 0
        self.Zones = DynamicVector[Int]()

struct SizingManagerData:
    var NumAirLoops: Int
    var ReportZoneSizingMyOneTimeFlag: Bool
    var ReportSpaceSizingMyOneTimeFlag: Bool
    var ReportSysSizingMyOneTimeFlag: Bool
    var runZeroingOnce: Bool

    fn __init__(inout self):
        self.NumAirLoops = 0
        self.ReportZoneSizingMyOneTimeFlag = True
        self.ReportSpaceSizingMyOneTimeFlag = True
        self.ReportSysSizingMyOneTimeFlag = True
        self.runZeroingOnce = True

    fn init_constant_state(inout self, state: UnsafePointer[UInt8]):
        pass

    fn init_state(inout self, state: UnsafePointer[UInt8]):
        pass

    fn clear_state(inout self):
        self.NumAirLoops = 0
        self.ReportZoneSizingMyOneTimeFlag = True
        self.ReportSpaceSizingMyOneTimeFlag = True
        self.ReportSysSizingMyOneTimeFlag = True
        self.runZeroingOnce = True

alias OAFlowCalcMethodNamesUC = InlineArray[StringLiteral, 9](
    "FLOW/PERSON",
    "FLOW/ZONE",
    "FLOW/AREA",
    "AIRCHANGES/HOUR",
    "SUM",
    "MAXIMUM",
    "INDOORAIRQUALITYPROCEDURE",
    "PROPORTIONALCONTROLBASEDONOCCUPANCYSCHEDULE",
    "PROPORTIONALCONTROLBASEDONDESIGNOCCUPANCY"
)

fn ManageSizing(state: UnsafePointer[UInt8]) -> None:
    pass

fn CalcdoLoadComponentPulseNow(
    state: UnsafePointer[UInt8],
    isPulseZoneSizing: Bool,
    WarmupFlag: Bool,
    HourOfDay: Int,
    TimeStep: Int,
    KindOfSim: Int
) -> Bool:
    let HourDayToPulse: Int = 10
    let TimeStepToPulse: Int = 1
    
    if (isPulseZoneSizing) and (not WarmupFlag) and (HourOfDay == HourDayToPulse) and \
       (TimeStep == TimeStepToPulse):
        return True
    return False

fn ManageSystemSizingAdjustments(state: UnsafePointer[UInt8]) -> None:
    pass

fn ManageSystemVentilationAdjustments(state: UnsafePointer[UInt8]) -> None:
    pass

fn DetermineSystemPopulationDiversity(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetOARequirements(state: UnsafePointer[UInt8]) -> None:
    pass

fn ProcessInputOARequirements(
    state: UnsafePointer[UInt8],
    CurrentModuleObject: String,
    OAIndex: Int,
    Alphas: DynamicVector[String],
    NumAlphas: Int,
    Numbers: DynamicVector[Float64],
    NumNumbers: Int,
    lAlphaBlanks: DynamicVector[Bool],
    cAlphaFields: DynamicVector[String],
    inout ErrorsFound: Bool
) -> None:
    pass

fn GetZoneAirDistribution(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetZoneHVACSizing(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetAirTerminalSizing(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetSizingParams(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetZoneSizingInput(state: UnsafePointer[UInt8]) -> None:
    pass

fn ReportTemperatureInputError(
    state: UnsafePointer[UInt8],
    cObjectName: String,
    paramNum: Int,
    comparisonTemperature: Float64,
    shouldFlagSevere: Bool,
    inout ErrorsFound: Bool
) -> None:
    pass

fn GetZoneAndZoneListNames(
    state: UnsafePointer[UInt8],
    inout ErrorsFound: Bool,
    inout NumZones: Int,
    inout ZoneNames: DynamicVector[String],
    inout NumZoneLists: Int,
    inout ZoneListNames: DynamicVector[ZoneListData]
) -> None:
    pass

fn GetSystemSizingInput(state: UnsafePointer[UInt8]) -> None:
    pass

fn GetPlantSizingInput(state: UnsafePointer[UInt8]) -> None:
    pass

fn SetupZoneSizing(state: UnsafePointer[UInt8], inout ErrorsFound: Bool) -> None:
    pass

fn reportZoneSizing(
    state: UnsafePointer[UInt8],
    zoneOrSpace: UnsafePointer[UInt8],
    zsFinalSizing: UnsafePointer[UInt8],
    zsCalcFinalSizing: UnsafePointer[UInt8],
    zsCalcSizing: UnsafePointer[UInt8],
    zSizing: UnsafePointer[UInt8],
    zoneMult: Float64,
    isSpace: Bool
) -> None:
    pass

fn reportZoneSizingEio(
    state: UnsafePointer[UInt8],
    ZoneName: String,
    LoadType: String,
    CalcDesLoad: Float64,
    UserDesLoad: Float64,
    CalcDesFlow: Float64,
    UserDesFlow: Float64,
    DesDayName: String,
    PeakHrMin: String,
    PeakTemp: Float64,
    PeakHumRat: Float64,
    FloorArea: Float64,
    TotOccs: Float64,
    MinOAVolFlow: Float64,
    DOASHeatAddRate: Float64,
    isSpace: Bool
) -> None:
    pass

fn ReportSysSizing(
    state: UnsafePointer[UInt8],
    SysName: String,
    LoadType: String,
    PeakLoadType: String,
    UserDesCap: Float64,
    CalcDesVolFlow: Float64,
    UserDesVolFlow: Float64,
    DesDayName: String,
    DesDayDate: String,
    TimeStepIndex: Int
) -> None:
    pass

fn TimeIndexToHrMinString(state: UnsafePointer[UInt8], timeIndex: Int) -> String:
    return String()

fn UpdateFacilitySizing(state: UnsafePointer[UInt8], CallIndicator: Int) -> None:
    pass

fn UpdateTermUnitFinalZoneSizing(state: UnsafePointer[UInt8]) -> None:
    pass
