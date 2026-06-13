# Mojo translation of WeatherManager.cc (faithful 1:1, no refactoring)
# Imports from other modules (assumed translated)
from DataGlobals import Constant
from DataEnvironment import DataEnvironment, GroundTempType
from DataHeatBalance import DataHeatBal
from DataIPShortCuts import ErrorObjectHeader
from DataPrecisionGlobals import DataPrecisionGlobals
from DataReportingFlags import DataReportFlag
from DataSurfaces import DataSurface
from DataSystemVariables import DataSysVars
from DataWater import DataWater, RainfallMode
from DisplayRoutines import DisplaySimDaysProgress
from EMSManager import EMSManager, EMSCallFrom
from FileSystem import FileSystem
from General import General, BetweenDates, OrdinalDay, InvOrdinalDay, ProcessDateString, FindItemInList
from GlobalNames import GlobalNames
from GroundTemperatureModeling.BaseGroundTemperatureModel import GroundTemp, BaseGroundTempsModel
from InputProcessing.InputProcessor import InputProcessor, getNumObjectsFound, getObjectItem
from OutputProcessor import OutputProcessor, SetupOutputVariable, SetupEMSActuator, ReportFreq
from OutputReportPredefined import OutputReportPredefined, PreDefTableEntry
from OutputReportTabular import OutputReportTabular, StrToReal, GetColumnUsingTabs
from Psychrometrics import Psychrometrics, PsyRhoAirFnPbTdbW, PsyWFnTdbTwbPb, PsyWFnTdpPb, PsyTwbFnTdbWPb, PsyTdpFnWPb, PsyRhFnTdbWPb, PsyWFnTdbRhPb, PsyHFnTdbW, PsyRhoAirFnPbTdbW, PsyPsatFnTemp, PsyWFnTdbH
from ScheduleManager import Sched, DayType, DaySchedule, DayOrYearSchedule, Schedule, GetSchedule, GetDaySchedule
from StringUtilities import StringUtilities, makeUPPER, SameString
from SurfaceGeometry import SurfaceGeometry
from ThermalComfort import ThermalComfort
from UtilityRoutines import UtilityRoutines, ProcessNumber, FindItem
from Vectors import Vectors
from WaterManager import WaterManager, UpdatePrecipitation
from WeatherManager import WeatherManagerData  # circular but needed for type?
# Actually WeatherManagerData is defined in this module, so we define it below.

# --- Enums ---
enum EpwHeaderType(Int):
    Invalid = -1
    Location = 0
    DesignConditions = 1
    TypicalExtremePeriods = 2
    GroundTemperatures = 3
    HolidaysDST = 4
    Comments1 = 5
    Comments2 = 6
    DataPeriods = 7
    Num = 8

enum DateType(Int):
    Invalid = -1
    MonthDay = 1
    NthDayInMonth = 2
    LastDayInMonth = 3
    Num = 4

enum WaterMainsTempCalcMethod(Int):
    Invalid = -1
    Schedule = 0
    Correlation = 1
    CorrelationFromWeatherFile = 2
    FixedDefault = 3
    Num = 4

enum DesDaySolarModel(Int):
    Invalid = -1
    ASHRAE_ClearSky = 0
    Zhang_Huang = 1
    SolarModel_Schedule = 2
    ASHRAE_Tau = 3
    ASHRAE_Tau2017 = 4
    Num = 5

enum DesDayHumIndType(Int):
    Invalid = -1
    WetBulb = 0
    DewPoint = 1
    Enthalpy = 2
    HumRatio = 3
    RelHumSch = 4
    WBProfDef = 5
    WBProfDif = 6
    WBProfMul = 7
    Num = 8

enum DesDayDryBulbRangeType(Int):
    Invalid = -1
    Default = 0
    Multiplier = 1
    Difference = 2
    Profile = 3
    Num = 4

enum SkyTempModel(Int):
    Invalid = -1
    ClarkAllen = 0
    ScheduleValue = 1
    DryBulbDelta = 2
    DewPointDelta = 3
    Brunt = 4
    Idso = 5
    BerdahlMartin = 6
    Num = 7

# --- Structs ---
struct EnvironmentData:
    var Title: String
    var cKindOfEnvrn: String
    var KindOfEnvrn: Constant.KindOfSim = Constant.KindOfSim.Invalid
    var DesignDayNum: Int = 0
    var RunPeriodDesignNum: Int = 0
    var SeedEnvrnNum: Int = 0
    var HVACSizingIterationNum: Int = 0
    var TotalDays: Int = 0
    var StartJDay: Int = 0
    var StartMonth: Int = 0
    var StartDay: Int = 0
    var StartYear: Int = 0
    var StartDate: Int = 0
    var EndMonth: Int = 0
    var EndDay: Int = 0
    var EndJDay: Int = 0
    var EndYear: Int = 0
    var EndDate: Int = 0
    var DayOfWeek: Int = 0
    var UseDST: Bool = False
    var UseHolidays: Bool = False
    var ApplyWeekendRule: Bool = False
    var UseRain: Bool = True
    var UseSnow: Bool = True
    var MonWeekDay: List[Int] = [0]*12
    var SetWeekDays: Bool = False
    var NumSimYears: Int = 1
    var CurrentCycle: Int = 0
    var WP_Type1: Int = 0
    var skyTempModel: SkyTempModel = SkyTempModel.ClarkAllen
    var UseWeatherFileHorizontalIR: Bool = True
    var CurrentYear: Int = 0
    var IsLeapYear: Bool = False
    var RollDayTypeOnRepeat: Bool = True
    var TreatYearsAsConsecutive: Bool = True
    var MatchYear: Bool = False
    var ActualWeather: Bool = False
    var RawSimDays: Int = 0
    var firstHrInterpUseHr1: Bool = False
    var maxCoolingOATSizing: Float64 = -1000.0
    var maxCoolingOADPSizing: Float64 = -1000.0
    var minHeatingOATSizing: Float64 = 1000.0
    var minHeatingOADPSizing: Float64 = 1000.0

struct DesignDayData:
    var Title: String
    var MaxDryBulb: Float64 = 0.0
    var DailyDBRange: Float64 = 0.0
    var HumIndValue: Float64 = 0.0
    var HumIndType: DesDayHumIndType = DesDayHumIndType.WetBulb
    var PressBarom: Float64 = 0.0
    var WindSpeed: Float64 = 0.0
    var WindDir: Float64 = 0.0
    var SkyClear: Float64 = 0.0
    var RainInd: Int = 0
    var SnowInd: Int = 0
    var DayOfMonth: Int = 0
    var Month: Int = 0
    var DayType: Int = 0
    var DSTIndicator: Int = 0
    var solarModel: DesDaySolarModel = DesDaySolarModel.ASHRAE_ClearSky
    var dryBulbRangeType: DesDayDryBulbRangeType = DesDayDryBulbRangeType.Default
    var tempRangeSched: Optional[Sched.DaySchedule] = None
    var humIndSched: Optional[Sched.DaySchedule] = None
    var beamSolarSched: Optional[Sched.DaySchedule] = None
    var diffuseSolarSched: Optional[Sched.DaySchedule] = None
    var TauB: Float64 = 0.0
    var TauD: Float64 = 0.0
    var DailyWBRange: Float64 = 0.0
    var PressureEntered: Bool = False
    var DewPointNeedsSet: Bool = False
    var maxWarmupDays: Int = -1
    var suppressBegEnvReset: Bool = False

struct ReportPeriodData:
    var title: String
    var reportName: String
    var startYear: Int = 2017
    var startMonth: Int = 1
    var startDay: Int = 1
    var startHour: Int = 1
    var startJulianDate: Int = 2457755
    var endYear: Int = 2017
    var endMonth: Int = 12
    var endDay: Int = 31
    var endHour: Int = 24
    var endJulianDate: Int = 2458119
    var totalElectricityUse: Float64 = 0.0

struct RunPeriodData:
    var title: String
    var periodType: String
    var totalDays: Int = 365
    var startMonth: Int = 1
    var startDay: Int = 1
    var startJulianDate: Int = 2457755
    var startYear: Int = 2017
    var endMonth: Int = 12
    var endDay: Int = 31
    var endJulianDate: Int = 2458119
    var endYear: Int = 2017
    var dayOfWeek: Int = 1
    var startWeekDay: Sched.DayType = Sched.DayType.Sunday
    var useDST: Bool = False
    var useHolidays: Bool = False
    var applyWeekendRule: Bool = False
    var useRain: Bool = True
    var useSnow: Bool = True
    var monWeekDay: List[Int] = [1,4,4,7,2,5,7,3,6,1,4,6]
    var numSimYears: Int = 1
    var isLeapYear: Bool = False
    var RollDayTypeOnRepeat: Bool = True
    var TreatYearsAsConsecutive: Bool = True
    var actualWeather: Bool = False
    var firstHrInterpUsingHr1: Bool = False

struct DayWeatherVariables:
    var DayOfYear: Int = 0
    var DayOfYear_Schedule: Int = 0
    var Year: Int = 0
    var Month: Int = 0
    var DayOfMonth: Int = 0
    var DayOfWeek: Int = 0
    var DaylightSavingIndex: Int = 0
    var HolidayIndex: Int = 0
    var SinSolarDeclinAngle: Float64 = 0.0
    var CosSolarDeclinAngle: Float64 = 0.0
    var EquationOfTime: Float64 = 0.0

struct SpecialDayData:
    var Name: String
    var dateType: DateType = DateType.Invalid
    var Month: Int = 0
    var Day: Int = 0
    var WeekDay: Int = 0
    var CompDate: Int = 0
    var WthrFile: Bool = False
    var Duration: Int = 0
    var DayType: Int = 0
    var ActStMon: Int = 0
    var ActStDay: Int = 0
    var Used: Bool = False

struct DataPeriodData:
    var Name: String
    var DayOfWeek: String
    var NumYearsData: Int = 1
    var WeekDay: Int = 0
    var StMon: Int = 0
    var StDay: Int = 0
    var StYear: Int = 0
    var EnMon: Int = 0
    var EnDay: Int = 0
    var EnYear: Int = 0
    var NumDays: Int = 0
    var MonWeekDay: List[Int] = [0]*12
    var DataStJDay: Int = 0
    var DataEnJDay: Int = 0
    var HasYearData: Bool = False

struct DSTPeriod:
    var StDateType: DateType = DateType.Invalid
    var StWeekDay: Int = 0
    var StMon: Int = 0
    var StDay: Int = 0
    var EnDateType: DateType = DateType.Invalid
    var EnMon: Int = 0
    var EnDay: Int = 0
    var EnWeekDay: Int = 0

struct WeatherVarCounts:
    var OutDryBulbTemp: Int = 0
    var OutDewPointTemp: Int = 0
    var OutRelHum: Int = 0
    var OutBaroPress: Int = 0
    var WindDir: Int = 0
    var WindSpeed: Int = 0
    var BeamSolarRad: Int = 0
    var DifSolarRad: Int = 0
    var TotalSkyCover: Int = 0
    var OpaqueSkyCover: Int = 0
    var Visibility: Int = 0
    var Ceiling: Int = 0
    var LiquidPrecip: Int = 0
    var WaterPrecip: Int = 0
    var AerOptDepth: Int = 0
    var SnowDepth: Int = 0
    var DaysLastSnow: Int = 0
    var WeathCodes: Int = 0
    var Albedo: Int = 0

struct TypicalExtremeData:
    var Title: String
    var ShortTitle: String
    var MatchValue: String
    var MatchValue1: String
    var MatchValue2: String
    var TEType: String
    var TotalDays: Int = 0
    var StartJDay: Int = 0
    var StartMonth: Int = 0
    var StartDay: Int = 0
    var EndMonth: Int = 0
    var EndDay: Int = 0
    var EndJDay: Int = 0

struct WeatherProperties:
    var Name: String
    var IsSchedule: Bool = True
    var skyTempModel: SkyTempModel = SkyTempModel.ClarkAllen
    var sched: Optional[Sched.DayOrYearSchedule] = None
    var UsedForEnvrn: Bool = False
    var UseWeatherFileHorizontalIR: Bool = True

struct UnderwaterBoundary:
    var Name: String
    var distanceFromLeadingEdge: Float64 = 0.0
    var OSCMIndex: Int = 0
    var waterTempSched: Optional[Sched.Schedule] = None
    var velocitySched: Optional[Sched.Schedule] = None

struct WeatherVars:
    var IsRain: Bool = False
    var IsSnow: Bool = False
    var OutDryBulbTemp: Float64 = 0.0
    var OutDewPointTemp: Float64 = 0.0
    var OutBaroPress: Float64 = 0.0
    var OutRelHum: Float64 = 0.0
    var WindSpeed: Float64 = 0.0
    var WindDir: Float64 = 0.0
    var SkyTemp: Float64 = 0.0
    var HorizIRSky: Float64 = 0.0
    var BeamSolarRad: Float64 = 0.0
    var DifSolarRad: Float64 = 0.0
    var Albedo: Float64 = 0.0
    var WaterPrecip: Float64 = 0.0
    var LiquidPrecip: Float64 = 0.0
    var TotalSkyCover: Float64 = 0.0
    var OpaqueSkyCover: Float64 = 0.0

struct ExtWeatherVars(WeatherVars):
    var Visibility: Float64 = 0.0
    var Ceiling: Float64 = 0.0
    var AerOptDepth: Float64 = 0.0
    var SnowDepth: Float64 = 0.0
    var DaysLastSnow: Int = 0

struct DesDayMods:
    var OutDryBulbTemp: Float64 = 0.0
    var OutRelHum: Float64 = 0.0
    var BeamSolarRad: Float64 = 0.0
    var DifSolarRad: Float64 = 0.0
    var SkyTemp: Float64 = 0.0

struct SPSiteSchedules:
    var OutDryBulbTemp: Float64 = 0.0
    var OutRelHum: Float64 = 0.0
    var BeamSolarRad: Float64 = 0.0
    var DifSolarRad: Float64 = 0.0
    var SkyTemp: Float64 = 0.0

# --- Module-level constants and static arrays (converted to module-level vars) ---
var epwHeaders: List[StringLiteral] = ["LOCATION","DESIGN CONDITIONS","TYPICAL/EXTREME PERIODS","GROUND TEMPERATURES","HOLIDAYS/DAYLIGHT SAVING","COMMENTS 1","COMMENTS 2","DATA PERIODS"]
var waterMainsCalcMethodNames: List[StringLiteral] = ["Schedule","Correlation","CorrelationFromWeatherFile","FixedDefault"]
var waterMainsCalcMethodNamesUC: List[StringLiteral] = ["SCHEDULE","CORRELATION","CORRELATIONFROMWEATHERFILE","FIXEDDEFAULT"]
var SkyTempModelNamesUC: List[StringLiteral] = ["CLARKALLEN","SCHEDULEVALUE","DIFFERENCESCHEDULEDRYBULBVALUE","DIFFERENCESCHEDULEDEWPOINTVALUE","BRUNT","IDSO","BERDAHLMARTIN"]
var SkyTempModelNames: List[StringLiteral] = ["Clark and Allen","Schedule Value","DryBulb Difference Schedule Value","Dewpoint Difference Schedule Value","Brunt","Idso","Berdahl and Martin"]
var DesDaySolarModelNames: List[StringLiteral] = ["ASHRAEClearSky","ZhangHuang","Schedule","ASHRAETau","ASHRAETau2017"]
var DesDaySolarModelNamesUC: List[StringLiteral] = ["ASHRAECLEARSKY","ZHANGHUANG","SCHEDULE","ASHRAETAU","ASHRAETAU2017"]
var DesDayHumIndTypeNamesUC: List[StringLiteral] = ["WETBULB","DEWPOINT","ENTHALPY","HUMIDITYRATIO","RELATIVEHUMIDITYSCHEDULE","WETBULBPROFILEDEFAULTMULTIPLIERS","WETBULBPROFILEDIFFERENCESCHEDULE","WETBULBPROFILEMULTIPLIERSCHEDULE"]
var DesDayDryBulbRangeTypeNamesUC: List[StringLiteral] = ["DEFAULTMULTIPLIERS","MULTIPLIERSCHEDULE","DIFFERENCESCHEDULE","TEMPERATUREPROFILESCHEDULE"]

# --- Functions ---
def ManageWeather(inout state: EnergyPlusData):
    InitializeWeather(state, state.dataWeather.PrintEnvrnStamp)
    if not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation:
        var anyEMSRan: Bool = False
        EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.BeginZoneTimestepBeforeSetCurrentWeather, anyEMSRan, Optional[Int]())  # calling point
    SetCurrentWeather(state)
    ReportWeatherAndTimeInformation(state, state.dataWeather.PrintEnvrnStamp)

def ResetEnvironmentCounter(inout state: EnergyPlusData):
    state.dataWeather.Envrn = 0

def CheckIfAnyUnderwaterBoundaries(inout state: EnergyPlusData) -> Bool:
    var errorsFound: Bool = False
    var NumAlpha: Int = 0; var NumNumber: Int = 0; var IOStat: Int = 0
    const routineName: StringLiteral = "CheckIfAnyUnderwaterBoundaries"
    var ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "SurfaceProperty:Underwater"
    var Num: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    for i in range(1, Num+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, i, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, ipsc.lNumericFieldBlanks, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        state.dataWeather.underwaterBoundaries.append(UnderwaterBoundary())
        var underwaterBoundary = state.dataWeather.underwaterBoundaries[i-1]
        underwaterBoundary.Name = ipsc.cAlphaArgs[1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, underwaterBoundary.Name)
        underwaterBoundary.distanceFromLeadingEdge = ipsc.rNumericArgs[1]
        underwaterBoundary.OSCMIndex = Util.FindItemInList(underwaterBoundary.Name, state.dataSurface.OSCM)
        if underwaterBoundary.OSCMIndex <= 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errorsFound = True
        if ipsc.lAlphaFieldBlanks[2]:
            ShowSevereEmptyField(state, eoh, ipsc.cAlphaFieldNames[2])
            errorsFound = True
        elif (underwaterBoundary.waterTempSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[2])) == None:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
            errorsFound = True
        if ipsc.lAlphaFieldBlanks[3]:

        elif (underwaterBoundary.velocitySched = Sched.GetSchedule(state, ipsc.cAlphaArgs[3])) == None:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[3], ipsc.cAlphaArgs[3])
            errorsFound = True
        if errorsFound:
            break
    if errorsFound:
        ShowFatalError(state, "Previous input problems cause program termination")
    return Num > 0

def calculateWaterBoundaryConvectionCoefficient(curWaterTemp: Float64, freeStreamVelocity: Float64, distanceFromLeadingEdge: Float64) -> Float64:
    const waterKinematicViscosity: Float64 = 1e-6
    const waterPrandtlNumber: Float64 = 6.0
    const waterThermalConductivity: Float64 = 0.6
    var localReynoldsNumber: Float64 = freeStreamVelocity * distanceFromLeadingEdge / waterKinematicViscosity
    var localNusseltNumber: Float64 = 0.0296 * pow(localReynoldsNumber, 0.8) * pow(waterPrandtlNumber, 1.0/3.0)
    var localConvectionCoeff: Float64 = localNusseltNumber * waterThermalConductivity / distanceFromLeadingEdge
    const distanceFromBottomOfHull: Float64 = 12.0
    var prandtlCorrection: Float64 = (0.75 * pow(waterPrandtlNumber, 0.5)) / pow(0.609 + 1.221 * pow(waterPrandtlNumber, 0.5) + 1.238 * waterPrandtlNumber, 0.25)
    const gravity: Float64 = 9.81
    const beta: Float64 = 0.000214
    const assumedSurfaceTemp: Float64 = 25.0
    var localGrashofNumber: Float64 = (gravity * beta * abs(assumedSurfaceTemp - curWaterTemp) * pow(distanceFromBottomOfHull, 3)) / pow(waterKinematicViscosity, 2)
    var localNusseltFreeConvection: Float64 = pow(localGrashofNumber / 4, 0.25) * prandtlCorrection
    var localConvectionCoeffFreeConv: Float64 = localNusseltFreeConvection * waterThermalConductivity / distanceFromBottomOfHull
    return max(localConvectionCoeff, localConvectionCoeffFreeConv)

def UpdateUnderwaterBoundaries(inout state: EnergyPlusData):
    for thisBoundary in state.dataWeather.underwaterBoundaries:
        var curWaterTemp: Float64 = thisBoundary.waterTempSched.getCurrentVal()  # C
        var freeStreamVelocity: Float64 = 0.0
        if thisBoundary.velocitySched != None:
            freeStreamVelocity = thisBoundary.velocitySched.getCurrentVal()
        state.dataSurface.OSCM[thisBoundary.OSCMIndex].TConv = curWaterTemp
        state.dataSurface.OSCM[thisBoundary.OSCMIndex].HConv = Weather.calculateWaterBoundaryConvectionCoefficient(curWaterTemp, freeStreamVelocity, thisBoundary.distanceFromLeadingEdge)
        state.dataSurface.OSCM[thisBoundary.OSCMIndex].TRad = curWaterTemp
        state.dataSurface.OSCM[thisBoundary.OSCMIndex].HRad = 0.0

def ReadVariableLocationOrientation(inout state: EnergyPlusData):
    const routineName: StringLiteral = "ReadVariableLocationOrientation"
    var NumAlpha: Int = 0; var NumNumber: Int = 0; var IOStat: Int = 0
    var ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "Site:VariableLocation"
    if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject) == 0:
        return
    state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, 1, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, ipsc.lNumericFieldBlanks, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
    var newName: String = Util.makeUPPER(ipsc.cAlphaArgs[1])
    var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, newName)
    if ipsc.lAlphaFieldBlanks[2]:

    elif (state.dataEnvrn.varyingLocationLatSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[2])) == None:
        ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
    if ipsc.lAlphaFieldBlanks[3]:

    elif (state.dataEnvrn.varyingLocationLongSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[3])) == None:
        ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[3], ipsc.cAlphaArgs[3])
    if ipsc.lAlphaFieldBlanks[4]:

    elif (state.dataEnvrn.varyingOrientationSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[4])) == None:
        ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[4], ipsc.cAlphaArgs[4])

def UpdateLocationAndOrientation(inout state: EnergyPlusData):
    if state.dataEnvrn.varyingLocationLatSched != None:
        state.dataEnvrn.Latitude = state.dataEnvrn.varyingLocationLatSched.getCurrentVal()
    if state.dataEnvrn.varyingLocationLongSched != None:
        state.dataEnvrn.Longitude = state.dataEnvrn.varyingLocationLongSched.getCurrentVal()
    CheckLocationValidity(state)
    if state.dataEnvrn.varyingOrientationSched != None:
        state.dataHeatBal.BuildingAzimuth = mod(state.dataEnvrn.varyingOrientationSched.getCurrentVal(), 360.0)
        state.dataSurfaceGeometry.CosBldgRelNorth = cos(-(state.dataHeatBal.BuildingAzimuth + state.dataHeatBal.BuildingRotationAppendixG) * Constant.DegToRad)
        state.dataSurfaceGeometry.SinBldgRelNorth = sin(-(state.dataHeatBal.BuildingAzimuth + state.dataHeatBal.BuildingRotationAppendixG) * Constant.DegToRad)
        for SurfNum in range(1, len(state.dataSurface.Surface)):
            var surf = state.dataSurface.Surface[SurfNum]
            for n in range(1, surf.Sides+1):
                var Xb = surf.Vertex[n].x
                var Yb = surf.Vertex[n].y
                surf.NewVertex[n].x = Xb * state.dataSurfaceGeometry.CosBldgRelNorth - Yb * state.dataSurfaceGeometry.SinBldgRelNorth
                surf.NewVertex[n].y = Xb * state.dataSurfaceGeometry.SinBldgRelNorth + Yb * state.dataSurfaceGeometry.CosBldgRelNorth
                surf.NewVertex[n].z = surf.Vertex[n].z
            Vectors.CreateNewellSurfaceNormalVector(surf.NewVertex, surf.Sides, surf.NewellSurfaceNormalVector)
            var SurfWorldAz: Float64 = 0.0
            var SurfTilt: Float64 = 0.0
            Vectors.DetermineAzimuthAndTilt(surf.NewVertex, SurfWorldAz, SurfTilt, surf.lcsx, surf.lcsy, surf.lcsz, surf.NewellSurfaceNormalVector)
            surf.Azimuth = SurfWorldAz
            surf.SinAzim = sin(SurfWorldAz * Constant.DegToRad)
            surf.CosAzim = cos(SurfWorldAz * Constant.DegToRad)
            surf.OutNormVec = surf.NewellSurfaceNormalVector

# ... (truncated due to length) ...