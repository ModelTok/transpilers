# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state container from EnergyPlus.Data.EnergyPlusData)
# - BaseGlobalStruct (base class from EnergyPlus.Data.BaseData)
# - equali (case-insensitive comparison from EnergyPlus.UtilityRoutines)
# - show_severe_error, show_continue_error, show_fatal_error (logging from EnergyPlus.UtilityRoutines)

from collections.deque import Deque
from memory.unsafe import Pointer


alias NUM_MONTHLY_REPORTS = 63


struct MonthlyNamedReportsArray:
    var data: InlineArray[String, 63]

    fn __init__(inout self):
        self.data = InlineArray[String, 63](
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


var monthly_named_reports = MonthlyNamedReportsArray()


struct EnergyPlusData:
    pass


struct REPattern:
    var pattern: String

    fn __init__(inout self, pattern: String):
        self.pattern = pattern

    fn ok(self) -> Bool:
        return True

    fn error(self) -> String:
        return ""

    fn full_match(self, text: String) -> Bool:
        return True


fn is_key_regex_like(key: String) -> Bool:
    if key == "*":
        return False
    let special_chars = "*+?()|[]\\"
    for i in range(len(key)):
        for j in range(len(special_chars)):
            if key[i] == special_chars[j]:
                return True
    return False


fn is_key_regex_like_ori(key: String) -> Bool:
    if key == "*":
        return False
    let special_chars = "*+?()|[]\\"
    for i in range(len(key)):
        for j in range(len(special_chars)):
            if key[i] == special_chars[j]:
                return True
    return False


@value
struct OutputReportingVariables:
    var key: String
    var variable_name: String
    var is_simple_string: Bool
    var pattern: Pointer[REPattern]
    var case_insensitive_pattern: Pointer[REPattern]

    fn __init__(inout self, state: Pointer[EnergyPlusData], key_value: String, variable_name_arg: String):
        self.key = key_value
        self.variable_name = variable_name_arg
        self.is_simple_string = not is_key_regex_like(key_value)
        self.pattern = Pointer[REPattern]()
        self.case_insensitive_pattern = Pointer[REPattern]()

        if self.is_simple_string:
            return

        let pat = REPattern(key_value)
        self.pattern = Pointer[REPattern].alloc(1)
        self.pattern.store(0, pat)

        var case_insensitive_str = String("(?i)")
        case_insensitive_str += key_value
        let case_pat = REPattern(case_insensitive_str)
        self.case_insensitive_pattern = Pointer[REPattern].alloc(1)
        self.case_insensitive_pattern.store(0, case_pat)

        if not pat.ok():
            var msg = String("Regular expression \"")
            msg += key_value
            msg += String("\" for variable name \"")
            msg += variable_name_arg
            msg += String("\" in input file is incorrect")


@value
struct OutputsData:
    var max_considered_output_variables: Int32
    var num_considered_output_variables: Int32
    var i_number_of_records: Int32
    var i_number_of_defaulted_fields: Int32
    var i_total_fields_with_defaults: Int32
    var i_number_of_auto_sized_fields: Int32
    var i_total_auto_sizable_fields: Int32
    var i_number_of_auto_calced_fields: Int32
    var i_total_auto_calculatable_fields: Int32
    var output_variables_for_simulation: Dict[String, Dict[String, OutputReportingVariables]]

    fn __init__(inout self):
        self.max_considered_output_variables = 0
        self.num_considered_output_variables = 0
        self.i_number_of_records = 0
        self.i_number_of_defaulted_fields = 0
        self.i_total_fields_with_defaults = 0
        self.i_number_of_auto_sized_fields = 0
        self.i_total_auto_sizable_fields = 0
        self.i_number_of_auto_calced_fields = 0
        self.i_total_auto_calculatable_fields = 0
        self.output_variables_for_simulation = Dict[String, Dict[String, OutputReportingVariables]]()

    fn init_constant_state(inout self, state: Pointer[EnergyPlusData]):
        pass

    fn init_state(inout self, state: Pointer[EnergyPlusData]):
        pass

    fn clear_state(inout self):
        self.max_considered_output_variables = 0
        self.num_considered_output_variables = 0
        self.i_number_of_records = 0
        self.i_number_of_defaulted_fields = 0
        self.i_total_fields_with_defaults = 0
        self.i_number_of_auto_sized_fields = 0
        self.i_total_auto_sizable_fields = 0
        self.i_number_of_auto_calced_fields = 0
        self.i_total_auto_calculatable_fields = 0
        self.output_variables_for_simulation = Dict[String, Dict[String, OutputReportingVariables]]()


fn equali(a: String, b: String) -> Bool:
    return a.lower() == b.lower()


fn find_item_in_variable_list(
    state: Pointer[EnergyPlusData],
    keyed_value: String,
    variable_name: String
) -> Bool:
    let outputs_data = Pointer[OutputsData]()

    if variable_name not in outputs_data[].output_variables_for_simulation:
        return False

    let found_variable = outputs_data[].output_variables_for_simulation[variable_name]

    if keyed_value in found_variable:
        return True

    if "*" in found_variable:
        return True

    for key in found_variable:
        let var_obj = found_variable[key]
        if equali(keyed_value, var_obj.key):
            return True
        if var_obj.is_simple_string:
            continue
        if var_obj.pattern and var_obj.pattern[].full_match(keyed_value):
            return True
        if var_obj.case_insensitive_pattern and var_obj.case_insensitive_pattern[].full_match(keyed_value):
            return True

    return False
