# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state container from EnergyPlus.Data.EnergyPlusData)
# - BaseGlobalStruct (base class from EnergyPlus.Data.BaseData)
# - equali (case-insensitive comparison from EnergyPlus.UtilityRoutines)
# - ShowSevereError, ShowContinueError, ShowFatalError (logging from EnergyPlus.UtilityRoutines)

from typing import Dict, Optional, Protocol
import re


class EnergyPlusData(Protocol):
    """Stub for EnergyPlusData state container"""
    def show_severe_error(self, msg: str) -> None: ...
    def show_continue_error(self, msg: str) -> None: ...
    def show_fatal_error(self, msg: str) -> None: ...
    class DataOutput:
        output_variables_for_simulation: Dict


class BaseGlobalStruct(Protocol):
    """Stub for base global struct"""
    def init_constant_state(self, state: EnergyPlusData) -> None: ...
    def init_state(self, state: EnergyPlusData) -> None: ...
    def clear_state(self) -> None: ...


def equali(a: str, b: str) -> bool:
    """Case-insensitive string equality (stub)"""
    return a.lower() == b.lower()


NUM_MONTHLY_REPORTS = 63

MONTHLY_NAMED_REPORTS = [
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
]


def is_key_regex_like(key: str) -> bool:
    if key == "*":
        return False
    return any(c in key for c in "*+?()|[]\\")


def is_key_regex_like_ori(key: str) -> bool:
    if key == "*":
        return False
    return any(c in key for c in "*+?()|[]\\")


class OutputReportingVariables:
    def __init__(self, state: EnergyPlusData, key_value: str, variable_name: str):
        self.key = key_value
        self.variable_name = variable_name
        self.is_simple_string = not is_key_regex_like(key_value)
        self.pattern: Optional[re.Pattern] = None
        self.case_insensitive_pattern: Optional[re.Pattern] = None

        if self.is_simple_string:
            return

        try:
            self.pattern = re.compile(key_value)
            self.case_insensitive_pattern = re.compile(f"(?i){key_value}")
        except re.error as e:
            state.show_severe_error(
                f'Regular expression "{key_value}" for variable name "{variable_name}" in input file is incorrect'
            )
            state.show_continue_error(str(e))
            state.show_fatal_error("Error found in regular expression. Previous error(s) cause program termination.")


class OutputsData:
    def __init__(self):
        self.max_considered_output_variables = 0
        self.num_considered_output_variables = 0
        self.i_number_of_records = 0
        self.i_number_of_defaulted_fields = 0
        self.i_total_fields_with_defaults = 0
        self.i_number_of_auto_sized_fields = 0
        self.i_total_auto_sizable_fields = 0
        self.i_number_of_auto_calced_fields = 0
        self.i_total_auto_calculatable_fields = 0
        self.output_variables_for_simulation: Dict[str, Dict[str, OutputReportingVariables]] = {}

    def init_constant_state(self, state: EnergyPlusData) -> None:
        pass

    def init_state(self, state: EnergyPlusData) -> None:
        pass

    def clear_state(self) -> None:
        self.__init__()


def find_item_in_variable_list(
    state: EnergyPlusData,
    keyed_value: str,
    variable_name: str
) -> bool:
    found_variable = state.dataOutput.output_variables_for_simulation.get(variable_name)
    if found_variable is None:
        return False

    found_key = found_variable.get(keyed_value)
    if found_key is not None:
        return True

    found_key = found_variable.get("*")
    if found_key is not None:
        return True

    for key, var_obj in found_variable.items():
        if equali(keyed_value, var_obj.key):
            return True
        if var_obj.is_simple_string:
            continue
        if var_obj.pattern is not None and var_obj.pattern.fullmatch(keyed_value):
            return True
        if var_obj.case_insensitive_pattern is not None and var_obj.case_insensitive_pattern.fullmatch(keyed_value):
            return True

    return False
