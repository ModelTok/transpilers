from .Data.EnergyPlusData import EnergyPlusData
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError, equali
from .DataGlobals import *
from .Data.BaseData import BaseGlobalStruct
from python import Python
let _re = Python.import_module("re")
struct RE2:
    var re: PythonObject  # compiled pattern
    var pattern_str: String
    var error: String = ""
    def __init__(inout self, pattern: String):
        self.pattern_str = pattern
        self.re = _re.compile(pattern)
        if self.re is None:
            self.error = "Invalid regex"
    def ok(self) -> Bool:
        return self.re is not None
    def error(self) -> String:
        return self.error
    @staticmethod
    def FullMatch(text: String, re: Self) -> Bool:
        return bool(_re.fullmatch(text, re.re))
def case_insensitive_comparator(a: String, b: String) -> Bool:
    return equali(a, b)
def _lower(s: String) -> String:
    return s.lower()
struct OutputReportingVariables:
    var key: String
    var variableName: String
    var is_simple_string: Bool = True
    var pattern: Optional[RE2] = None
    var case_insensitive_pattern: Optional[RE2] = None
    def __init__(inout self, state: EnergyPlusData, KeyValue: String, VariableName: String):
        self.key = KeyValue
        self.variableName = VariableName
        self.is_simple_string = not isKeyRegexLike(KeyValue)
        if self.is_simple_string:
            return
        self.pattern = Optional[RE2](RE2(KeyValue))
        self.case_insensitive_pattern = Optional[RE2](RE2("(?i)" + KeyValue))
        let pat = self.pattern.value()
        if not pat.ok():
            ShowSevereError(state, String.format("Regular expression \"{}\" for variable name \"{}\" in input file is incorrect", KeyValue, VariableName))
            ShowContinueError(state, pat.error())
            ShowFatalError(state, "Error found in regular expression. Previous error(s) cause program termination.")
def isKeyRegexLike(key: String) -> Bool:
    if key == "*":
        return False
    return key.find_first_of("*+?()|[]\\.") != -1
def FindItemInVariableList(state: EnergyPlusData, KeyedValue: String, VariableName: String) -> Bool:
    let lower_var = _lower(VariableName)
    let lower_key = _lower(KeyedValue)
    let found_variable = state.dataOutput.OutputVariablesForSimulation.get(lower_var)
    if not found_variable:
        return False
    let inner_map = found_variable.value()
    let found_key = inner_map.get(lower_key)
    if found_key:
        return True
    let wildcard = inner_map.get("*")
    if wildcard:
        return True
    for it in inner_map.values():
        if equali(KeyedValue, it.key):
            return True
        if it.is_simple_string:
            continue
        if not it.pattern and not it.case_insensitive_pattern:
            continue
        let pat = it.pattern.value()
        let ipat = it.case_insensitive_pattern.value()
        if (pat and RE2.FullMatch(KeyedValue, pat)) or (ipat and RE2.FullMatch(KeyedValue, ipat)):
            return True
    return False
alias NumMonthlyReports = 63
let MonthlyNamedReports: List[String] = List[String](
    "ZONECOOLINGSUMMARYMONTHLY",
    "ZONEHEATINGSUMMARYMONTHLY",
    "ZONEELECTRICSUMMARYMONTHLY",
    "SPACEGAINSMONTHLY",
    "PEAKSPACEGAINSMONTHLY",
    "SPACEGAINCOMPONENTSATCOOLINGPEAKMONTHLY",
    "ENERGYCONSUMPTIONELECTRICITYNATURALGASMONTHLY",
    "ENERGYCONSUMPTIONELECTRICITYGENERATEDPROPANEMONTHLY",
    "ENERGYCONSUMPTIONDIESELFUELOILMONTHLY",
    "ENERGYCONSUMPTIONDISTRICTHEATINGCOOLINGMONTHLY",
    "ENERGYCONSUMPTIONCOALGASOLINEMONTHLY",
    "ENERGYCONSUMPTIONOTHERFUELSMONTHLY",
    "ENDUSEENERGYCONSUMPTIONELECTRICITYMONTHLY",
    "ENDUSEENERGYCONSUMPTIONNATURALGASMONTHLY",
    "ENDUSEENERGYCONSUMPTIONDIESELMONTHLY",
    "ENDUSEENERGYCONSUMPTIONFUELOILMONTHLY",
    "ENDUSEENERGYCONSUMPTIONCOALMONTHLY",
    "ENDUSEENERGYCONSUMPTIONPROPANEMONTHLY",
    "ENDUSEENERGYCONSUMPTIONGASOLINEMONTHLY",
    "ENDUSEENERGYCONSUMPTIONOTHERFUELSMONTHLY",
    "PEAKENERGYENDUSEELECTRICITYPART1MONTHLY",
    "PEAKENERGYENDUSEELECTRICITYPART2MONTHLY",
    "ELECTRICCOMPONENTSOFPEAKDEMANDMONTHLY",
    "PEAKENERGYENDUSENATURALGASMONTHLY",
    "PEAKENERGYENDUSEDIESELMONTHLY",
    "PEAKENERGYENDUSEFUELOILMONTHLY",
    "PEAKENERGYENDUSECOALMONTHLY",
    "PEAKENERGYENDUSEPROPANEMONTHLY",
    "PEAKENERGYENDUSEGASOLINEMONTHLY",
    "PEAKENERGYENDUSEOTHERFUELSMONTHLY",
    "SETPOINTSNOTMETWITHTEMPERATURESMONTHLY",
    "COMFORTREPORTSIMPLE55MONTHLY",
    "UNGLAZEDTRANSPIREDSOLARCOLLECTORSUMMARYMONTHLY",
    "OCCUPANTCOMFORTDATASUMMARYMONTHLY",
    "CHILLERREPORTMONTHLY",
    "TOWERREPORTMONTHLY",
    "BOILERREPORTMONTHLY",
    "DXREPORTMONTHLY",
    "WINDOWREPORTMONTHLY",
    "WINDOWENERGYREPORTMONTHLY",
    "WINDOWZONESUMMARYMONTHLY",
    "WINDOWENERGYZONESUMMARYMONTHLY",
    "AVERAGEOUTDOORCONDITIONSMONTHLY",
    "OUTDOORCONDITIONSMAXIMUMDRYBULBMONTHLY",
    "OUTDOORCONDITIONSMINIMUMDRYBULBMONTHLY",
    "OUTDOORCONDITIONSMAXIMUMWETBULBMONTHLY",
    "OUTDOORCONDITIONSMAXIMUMDEWPOINTMONTHLY",
    "OUTDOORGROUNDCONDITIONSMONTHLY",
    "WINDOWACREPORTMONTHLY",
    "WATERHEATERREPORTMONTHLY",
    "GENERATORREPORTMONTHLY",
    "DAYLIGHTINGREPORTMONTHLY",
    "COILREPORTMONTHLY",
    "PLANTLOOPDEMANDREPORTMONTHLY",
    "FANREPORTMONTHLY",
    "PUMPREPORTMONTHLY",
    "CONDLOOPDEMANDREPORTMONTHLY",
    "ZONETEMPERATUREOSCILLATIONREPORTMONTHLY",
    "AIRLOOPSYSTEMENERGYANDWATERUSEMONTHLY",
    "AIRLOOPSYSTEMCOMPONENTLOADSMONTHLY",
    "AIRLOOPSYSTEMCOMPONENTENERGYUSEMONTHLY",
    "MECHANICALVENTILATIONLOADSMONTHLY",
    "HEATEMISSIONSREPORTMONTHLY"
)
alias OutputVariablesForSimulationType = Dict[
    String,
    Dict[String, OutputReportingVariables]
]
struct OutputsData(BaseGlobalStruct):
    var MaxConsideredOutputVariables: Int = 0
    var NumConsideredOutputVariables: Int = 0
    var iNumberOfRecords: Int = 0
    var iNumberOfDefaultedFields: Int = 0
    var iTotalFieldsWithDefaults: Int = 0
    var iNumberOfAutoSizedFields: Int = 0
    var iTotalAutoSizableFields: Int = 0
    var iNumberOfAutoCalcedFields: Int = 0
    var iTotalAutoCalculatableFields: Int = 0
    var OutputVariablesForSimulation: OutputVariablesForSimulationType = Dict[String, Dict[String, OutputReportingVariables]]()
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = OutputsData()