from dataclasses import dataclass, field
from enum import IntEnum
from typing import List, Dict, Optional, Protocol, Any
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state: all state.dataXXX accessors passed as parameters
# - Constant.eResource: enum for resource types (Electricity, NaturalGas, etc.)
# - Util.MonthNamesUC, Util.MonthNamesCC, Util.makeUPPER: string utilities
# - InputProcessor: getObjectDefMaxArgs, getNumObjectsFound, getObjectItem
# - OutputReportTabular: WriteReportHeaders, WriteSubtitle, WriteTable, RealToStr
# - DisplayString, ShowWarningError, ShowContinueError: output functions
# - hasi(str, substr): case-insensitive contains
# - getEnumValue(names_uc, upper_str): enum value lookup
# - CostEstimateManager.CurntBldg: building cost data
# - EconomicTariff.GetMonthlyCostForResource: energy cost retrieval
# - OutputProcessor.StoreType.Average: output averaging type
# - SQLiteProcedures, ResultsFramework: output backends

class DiscConv(IntEnum):
    Invalid = -1
    BeginOfYear = 0
    MidYear = 1
    EndOfYear = 2
    Num = 3

DISC_CONV_NAMES_UC = ["BEGINNINGOFYEAR", "MIDYEAR", "ENDOFYEAR"]
DISC_CONV_NAMES = ["BeginningOfYear", "MidYear", "EndOfYear"]

class InflAppr(IntEnum):
    Invalid = -1
    ConstantDollar = 0
    CurrentDollar = 1
    Num = 2

INFL_APPR_NAMES_UC = ["CONSTANTDOLLAR", "CURRENTDOLLAR"]
INFL_APPR_NAMES = ["ConstantDollar", "CurrentDollar"]

class DeprMethod(IntEnum):
    Invalid = -1
    MACRS3 = 0
    MACRS5 = 1
    MACRS7 = 2
    MACRS10 = 3
    MACRS15 = 4
    MACRS20 = 5
    Straight27 = 6
    Straight31 = 7
    Straight39 = 8
    Straight40 = 9
    None_ = 10
    Num = 11

SIZE_DEPR = 41

DEPRECIATION_PERCENT_TABLE = [
    [33.33, 44.45, 14.81, 7.41] + [0] * 37,
    [20.0, 32.0, 19.2, 11.52, 11.52, 5.76] + [0] * 35,
    [14.29, 24.49, 17.49, 12.49, 8.93, 8.92, 8.93, 4.46] + [0] * 33,
    [10.0, 18.0, 14.4, 11.52, 9.22, 7.37, 6.55, 6.55, 6.56, 6.55, 3.28] + [0] * 30,
    [5.0, 9.5, 8.55, 7.7, 6.93, 6.23, 5.9, 5.9, 5.91, 5.9, 5.91, 5.9, 5.91, 5.9, 5.91, 2.95] + [0] * 25,
    [3.75, 7.219, 6.677, 6.177, 5.713, 5.285, 4.888, 4.522, 4.462, 4.461, 4.462, 4.461, 4.462, 4.461, 4.462, 4.461, 4.462, 4.461, 4.462, 4.461, 2.231] + [0] * 20,
    [1.97, 3.636, 3.636, 3.636, 3.636, 3.636, 3.636, 3.636, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.637, 3.636, 3.485] + [0] * 13,
    [1.72, 3.175, 3.175, 3.175, 3.175, 3.175, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.174, 3.175, 3.042] + [0] * 9,
    [1.391, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 2.564, 1.177, 0],
    [1.354, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 1.146],
]

DEPR_METHOD_NAMES_UC = [
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-3YEAR",
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-5YEAR",
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-7YEAR",
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-10YEAR",
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-15YEAR",
    "MODIFIEDACCELERATEDCOSTRECOVERYSYSTEM-20YEAR",
    "STRAIGHTLINE-27YEAR",
    "STRAIGHTLINE-31YEAR",
    "STRAIGHTLINE-39YEAR",
    "STRAIGHTLINE-40YEAR",
    "NONE",
]

DEPR_METHOD_NAMES = [
    "ModifiedAcceleratedCostRecoverySystem-3year",
    "ModifiedAcceleratedCostRecoverySystem-5year",
    "ModifiedAcceleratedCostRecoverySystem-7year",
    "ModifiedAcceleratedCostRecoverySystem-10year",
    "ModifiedAcceleratedCostRecoverySystem-15year",
    "ModifiedAcceleratedCostRecoverySystem-20year",
    "StraightLine-27year",
    "StraightLine-31year",
    "StraightLine-39year",
    "StraightLine-40year",
    "None",
]

class CostCategory(IntEnum):
    Invalid = -1
    Maintenance = 0
    Repair = 1
    Operation = 2
    Replacement = 3
    MinorOverhaul = 4
    MajorOverhaul = 5
    OtherOperational = 6
    Water = 7
    Energy = 8
    TotOper = 9
    Construction = 10
    Salvage = 11
    OtherCapital = 12
    TotCaptl = 13
    TotEnergy = 14
    TotGrand = 15
    Num = 16

COST_CATEGORY_NAMES = [
    "Maintenance", "Repair", "Operation", "Replacement", "Minor Overhaul",
    "Major Overhaul", "Other Operational", "Water", "Energy", "Total Operation",
    "Construction", "Salvage", "Other Capital", "Total Capital", "Total Energy", "Grand Total"
]

COST_CATEGORY_NAMES_NO_SPACE = [
    "Maintenance", "Repair", "Operation", "Replacement", "MinorOverhaul",
    "MajorOverhaul", "OtherOperational", "Water", "Energy", "TotalOperational",
    "Construction", "Salvage", "OtherCapital", "TotalCapital", "TotalEnergy", "GrandTotal"
]

COST_CATEGORY_NAMES_UC = [
    "MAINTENANCE", "REPAIR", "OPERATION", "REPLACEMENT", "MINOR OVERHAUL",
    "MAJOR OVERHAUL", "OTHER OPERATIONAL", "WATER", "ENERGY", "TOTAL OPERATIONAL",
    "CONSTRUCTION", "SALVAGE", "OTHER CAPITAL", "TOTAL CAPITAL", "TOTAL ENERGY", "GRAND TOTAL"
]

COST_CATEGORY_NAMES_UC_NO_SPACE = [
    "MAINTENANCE", "REPAIR", "OPERATION", "REPLACEMENT", "MINOROVERHAUL",
    "MAJOROVERHAUL", "OTHEROPERATIONAL", "WATER", "ENERGY", "TOTALOPERATIONAL",
    "CONSTRUCTION", "SALVAGE", "OTHERCAPITAL", "TOTALCAPITAL", "TOTALENERGY", "GRANDTOTAL"
]

TOTAL = "Total"
TOTAL_UC = "TOTAL"

class StartCosts(IntEnum):
    Invalid = -1
    ServicePeriod = 0
    BasePeriod = 1
    Num = 2

START_COST_NAMES_UC = ["SERVICEPERIOD", "BASEPERIOD"]

class SourceKindType(IntEnum):
    Invalid = -1
    Recurring = 0
    Nonrecurring = 1
    Resource = 2
    Sum = 3
    Num = 4

SOURCE_KIND_TYPE_NAMES = ["Recurring", "Nonrecurring"]

class ResourceCostCategory(IntEnum):
    Invalid = -1
    Water = 0
    Energy = 1
    Num = 2

RESOURCE_COST_CATEGORY_NAMES = ["Water Cost", "Energy Cost"]

class PrValKind(IntEnum):
    Invalid = -1
    Energy = 0
    NonEnergy = 1
    NotComputed = 2
    Num = 3

@dataclass
class RecurringCostsType:
    name: str = ""
    line_item: str = ""
    category: int = CostCategory.Maintenance
    cost: float = 0.0
    start_of_costs: int = StartCosts.ServicePeriod
    years_from_start: int = 0
    months_from_start: int = 0
    total_months_from_start: int = 0
    repeat_period_years: int = 0
    repeat_period_months: int = 0
    total_repeat_period_months: int = 0
    annual_escalation_rate: float = 0.0

@dataclass
class NonrecurringCostType:
    name: str = ""
    line_item: str = ""
    category: int = CostCategory.Construction
    cost: float = 0.0
    start_of_costs: int = StartCosts.ServicePeriod
    years_from_start: int = 0
    months_from_start: int = 0
    total_months_from_start: int = 0

@dataclass
class UsePriceEscalationType:
    name: str = ""
    resource: int = -1
    escalation_start_year: int = 0
    escalation_start_month: int = 0
    escalation: List[float] = field(default_factory=list)

@dataclass
class UseAdjustmentType:
    name: str = ""
    resource: int = -1
    adjustment: List[float] = field(default_factory=list)

@dataclass
class CashFlowType:
    name: str = ""
    source_kind: int = SourceKindType.Invalid
    resource: int = -1
    category: int = CostCategory.Invalid
    mn_amount: List[float] = field(default_factory=list)
    yr_amount: List[float] = field(default_factory=list)
    pv_kind: int = PrValKind.Invalid
    present_value: float = 0.0
    orginal_cost: float = 0.0
    yr_pres_val: List[float] = field(default_factory=list)

@dataclass
class EconomicLifeCycleCostData:
    lcc_param_present: bool = False
    lcc_name: str = ""
    discount_convention: int = DiscConv.EndOfYear
    inflation_approach: int = InflAppr.ConstantDollar
    real_discount_rate: float = 0.0
    nominal_discount_rate: float = 0.0
    inflation: float = 0.0
    base_date_month: int = 0
    base_date_year: int = 0
    service_date_month: int = 0
    service_date_year: int = 0
    length_study_years: int = 0
    length_study_total_months: int = 0
    tax_rate: float = 0.0
    depreciation_method: int = DeprMethod.None_
    last_date_year: int = 0
    num_recurring_costs: int = 0
    num_nonrecurring_cost: int = 0
    num_use_price_escalation: int = 0
    num_use_adjustment: int = 0
    num_cash_flow: int = 0
    num_resources_used: int = 0
    get_input_lifecycle_cost_input: bool = True
    use_price_escalation_esc_start_year: int = 0
    use_price_escalation_esc_num_years: int = 0
    use_price_escalation_esc_end_year: int = 0
    use_price_escalation_earlier_end_year: int = 0
    use_price_escalation_later_start_year: int = 0
    use_price_escalation_cur_esc: int = 0
    use_price_escalation_cur_fld: int = 0
    express_as_cashflows_base_months_1900: int = 0
    express_as_cashflows_service_months_1900: int = 0
    spv: List[float] = field(default_factory=list)
    energy_spv: Dict[int, List[float]] = field(default_factory=dict)
    depreciated_capital: List[float] = field(default_factory=list)
    taxable_income: List[float] = field(default_factory=list)
    taxes: List[float] = field(default_factory=list)
    after_tax_cashflow: List[float] = field(default_factory=list)
    after_tax_present_value: List[float] = field(default_factory=list)
    escalated_tot_energy: List[float] = field(default_factory=list)
    escalated_energy: Dict[int, List[float]] = field(default_factory=dict)
    recurring_costs: List[RecurringCostsType] = field(default_factory=list)
    nonrecurring_cost: List[NonrecurringCostType] = field(default_factory=list)
    use_price_escalation: List[UsePriceEscalationType] = field(default_factory=list)
    use_adjustment: List[UseAdjustmentType] = field(default_factory=list)
    cash_flow: List[CashFlowType] = field(default_factory=list)

def get_input_for_life_cycle_cost(state: Any) -> None:
    if state.dataEconLifeCycleCost.get_input_lifecycle_cost_input:
        get_input_lifecycle_cost_parameters(state)
        get_input_lifecycle_cost_recurring_costs(state)
        get_input_lifecycle_cost_nonrecurring_cost(state)
        get_input_lifecycle_cost_use_price_escalation(state)
        get_input_lifecycle_cost_use_adjustment(state)
        state.dataEconLifeCycleCost.get_input_lifecycle_cost_input = False

def compute_life_cycle_cost_and_report(state: Any) -> None:
    if state.dataEconLifeCycleCost.lcc_param_present:
        state.display_string(state, "Computing Life Cycle Costs and Reporting")
        express_as_cashflows(state)
        compute_present_value(state)
        compute_escalated_energy_costs(state)
        compute_tax_and_depreciation(state)
        write_tabular_life_cycle_cost_report(state)

def get_input_lifecycle_cost_parameters(state: Any) -> None:
    j_fld = 0
    num_fields = 0
    num_alphas = 0
    num_nums = 0
    alpha_array = []
    num_array = []
    io_stat = 0
    current_module_object = "LifeCycleCost:Parameters"
    num_obj = 0

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, num_fields, num_alphas, num_nums)
    num_array = [0.0] * num_nums
    alpha_array = [""] * num_alphas
    num_obj = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)

    elcc = state.dataEconLifeCycleCost

    if num_obj == 0:
        elcc.lcc_param_present = False
    elif num_obj == 1:
        elcc.lcc_param_present = True
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, current_module_object, 1, alpha_array, num_alphas, num_array, num_nums, io_stat,
            state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames
        )

        for j_fld in range(num_alphas):
            if "LifeCycleCost:" in alpha_array[j_fld].upper():
                state.show_warning_error(
                    state,
                    f"In {current_module_object} named {alpha_array[0]} a field was found containing LifeCycleCost: which may indicate a missing comma."
                )

        elcc.lcc_name = alpha_array[0]
        elcc.discount_convention = state.get_enum_value(DISC_CONV_NAMES_UC, alpha_array[1].upper())
        if elcc.discount_convention == -1:
            elcc.discount_convention = DiscConv.EndOfYear
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[1]}=\"{alpha_array[1]}\". EndOfYear will be used."
            )

        elcc.inflation_approach = state.get_enum_value(INFL_APPR_NAMES_UC, alpha_array[2].upper())
        if elcc.inflation_approach == -1:
            elcc.inflation_approach = InflAppr.ConstantDollar
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[2]}=\"{alpha_array[2]}\". ConstantDollar will be used."
            )

        elcc.real_discount_rate = num_array[0]
        if elcc.inflation_approach == InflAppr.ConstantDollar and state.dataIPShortCut.lNumericFieldBlanks[0]:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid for field {state.dataIPShortCut.cNumericFieldNames[0]} to be blank when ConstantDollar analysis is be used."
            )
        if elcc.real_discount_rate > 0.30 or elcc.real_discount_rate < -0.30:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[0]}.  This value is the decimal value not a percentage so most values are between 0.02 and 0.15. "
            )

        elcc.nominal_discount_rate = num_array[1]
        if elcc.inflation_approach == InflAppr.CurrentDollar and state.dataIPShortCut.lNumericFieldBlanks[1]:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid for field {state.dataIPShortCut.cNumericFieldNames[1]} to be blank when CurrentDollar analysis is be used."
            )
        if elcc.nominal_discount_rate > 0.30 or elcc.nominal_discount_rate < -0.30:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[1]}.  This value is the decimal value not a percentage so most values are between 0.02 and 0.15. "
            )

        elcc.inflation = num_array[2]
        if elcc.inflation_approach == InflAppr.ConstantDollar and not state.dataIPShortCut.lNumericFieldBlanks[2]:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid for field {state.dataIPShortCut.cNumericFieldNames[2]} contain a value when ConstantDollar analysis is be used."
            )
        if elcc.inflation > 0.30 or elcc.inflation < -0.30:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[2]}.  This value is the decimal value not a percentage so most values are between 0.02 and 0.15. "
            )

        elcc.base_date_month = state.get_enum_value(state.util_month_names_uc, alpha_array[3].upper())
        if elcc.base_date_month == -1:
            elcc.base_date_month = 0
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid month entered in field {state.dataIPShortCut.cAlphaFieldNames[3]}. Using January instead of \"{alpha_array[3]}\""
            )

        elcc.base_date_year = int(num_array[3])
        if elcc.base_date_year > 2100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[3]}.  Value greater than 2100 yet it is representing a year. "
            )
        if elcc.base_date_year < 1900:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[3]}.  Value less than 1900 yet it is representing a year. "
            )

        elcc.service_date_month = state.get_enum_value(state.util_month_names_uc, alpha_array[4].upper())
        if elcc.service_date_month == -1:
            elcc.service_date_month = 0
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid month entered in field {state.dataIPShortCut.cAlphaFieldNames[4]}. Using January instead of \"{alpha_array[4]}\""
            )

        elcc.service_date_year = int(num_array[4])
        if elcc.service_date_year > 2100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[4]}.  Value greater than 2100 yet it is representing a year. "
            )
        if elcc.service_date_year < 1900:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[4]}.  Value less than 1900 yet it is representing a year. "
            )

        elcc.length_study_years = int(num_array[5])
        if elcc.length_study_years > 100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[5]}.  A value greater than 100 is not reasonable for an economic evaluation. "
            )
        if elcc.length_study_years < 1:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[5]}.  A value less than 1 is not reasonable for an economic evaluation. "
            )
        elcc.length_study_total_months = elcc.length_study_years * 12

        elcc.tax_rate = num_array[6]
        if elcc.tax_rate < 0.0 and not state.dataIPShortCut.lNumericFieldBlanks[6]:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[9]}.  A value less than 0 is not reasonable for a tax rate. "
            )

        elcc.depreciation_method = state.get_enum_value(DEPR_METHOD_NAMES_UC, alpha_array[5].upper())
        if elcc.depreciation_method == -1:
            elcc.depreciation_method = DeprMethod.None_
            if state.dataIPShortCut.lAlphaFieldBlanks[5]:
                state.show_warning_error(
                    state,
                    f"{current_module_object}: The input field {state.dataIPShortCut.cAlphaFieldNames[5]}is blank. \"None\" will be used."
                )
            else:
                state.show_warning_error(
                    state,
                    f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[5]}=\"{alpha_array[5]}\". \"None\" will be used."
                )

        elcc.last_date_year = elcc.base_date_year + elcc.length_study_years - 1
    else:
        state.show_warning_error(
            state,
            f"{current_module_object}: Only one instance of this object is allowed. No life-cycle cost reports will be generated."
        )
        elcc.lcc_param_present = False

def get_input_lifecycle_cost_recurring_costs(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost
    if not elcc.lcc_param_present:
        return

    current_module_object = "LifeCycleCost:RecurringCosts"
    num_fields = 0
    num_alphas = 0
    num_nums = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, num_fields, num_alphas, num_nums)
    
    num_array = [0.0] * num_nums
    alpha_array = [""] * num_alphas
    elcc.num_recurring_costs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    elcc.recurring_costs = [RecurringCostsType() for _ in range(elcc.num_recurring_costs)]

    for i_in_obj in range(elcc.num_recurring_costs):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, current_module_object, i_in_obj + 1, alpha_array, num_alphas, num_array, num_nums, 0,
            state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames
        )

        for j_fld in range(num_alphas):
            if "LifeCycleCost:" in alpha_array[j_fld].upper():
                state.show_warning_error(
                    state,
                    f"In {current_module_object} named {alpha_array[0]} a field was found containing LifeCycleCost: which may indicate a missing comma."
                )

        elcc.recurring_costs[i_in_obj].name = alpha_array[0]
        elcc.recurring_costs[i_in_obj].category = state.get_enum_value(COST_CATEGORY_NAMES_UC_NO_SPACE, alpha_array[1].upper())
        
        is_not_recurring = (
            elcc.recurring_costs[i_in_obj].category != CostCategory.Maintenance and
            elcc.recurring_costs[i_in_obj].category != CostCategory.Repair and
            elcc.recurring_costs[i_in_obj].category != CostCategory.Operation and
            elcc.recurring_costs[i_in_obj].category != CostCategory.Replacement and
            elcc.recurring_costs[i_in_obj].category != CostCategory.MinorOverhaul and
            elcc.recurring_costs[i_in_obj].category != CostCategory.MajorOverhaul and
            elcc.recurring_costs[i_in_obj].category != CostCategory.OtherOperational
        )
        if is_not_recurring:
            elcc.recurring_costs[i_in_obj].category = CostCategory.Maintenance
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[1]}=\"{alpha_array[1]}\". The category of Maintenance will be used."
            )

        elcc.recurring_costs[i_in_obj].cost = num_array[0]
        elcc.recurring_costs[i_in_obj].start_of_costs = state.get_enum_value(START_COST_NAMES_UC, alpha_array[2].upper())
        if elcc.recurring_costs[i_in_obj].start_of_costs == StartCosts.Invalid:
            elcc.recurring_costs[i_in_obj].start_of_costs = StartCosts.ServicePeriod
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[2]}=\"{alpha_array[2]}\". The start of the service period will be used."
            )

        elcc.recurring_costs[i_in_obj].years_from_start = int(num_array[1])
        if elcc.recurring_costs[i_in_obj].years_from_start > 100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[1]}.  This value is the number of years from the start so a value greater than 100 is not reasonable for an economic evaluation. "
            )
        if elcc.recurring_costs[i_in_obj].years_from_start < 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[1]}.  This value is the number of years from the start so a value less than 0 is not reasonable for an economic evaluation. "
            )

        elcc.recurring_costs[i_in_obj].months_from_start = int(num_array[2])
        if elcc.recurring_costs[i_in_obj].months_from_start > 1200:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[2]}.  This value is the number of months from the start so a value greater than 1200 is not reasonable for an economic evaluation. "
            )
        if elcc.recurring_costs[i_in_obj].months_from_start < 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[2]}.  This value is the number of months from the start so a value less than 0 is not reasonable for an economic evaluation. "
            )

        elcc.recurring_costs[i_in_obj].repeat_period_years = int(num_array[3])
        if elcc.recurring_costs[i_in_obj].repeat_period_years > 100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[3]}.  This value is the number of years between occurrences of the cost so a value greater than 100 is not reasonable for an economic evaluation. "
            )
        if elcc.recurring_costs[i_in_obj].repeat_period_years < 1:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[3]}.  This value is the number of years between occurrences of the cost so a value less than 1 is not reasonable for an economic evaluation. "
            )

        elcc.recurring_costs[i_in_obj].repeat_period_months = int(num_array[4])
        if elcc.recurring_costs[i_in_obj].repeat_period_months > 1200:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[4]}.  This value is the number of months between occurrences of the cost so a value greater than 1200 is not reasonable for an economic evaluation. "
            )
        if elcc.recurring_costs[i_in_obj].repeat_period_months < 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[4]}.  This value is the number of months between occurrences of the cost so a value less than 0 is not reasonable for an economic evaluation. "
            )
        if elcc.recurring_costs[i_in_obj].repeat_period_months == 0 and elcc.recurring_costs[i_in_obj].repeat_period_years == 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in fields {state.dataIPShortCut.cNumericFieldNames[4]} and {state.dataIPShortCut.cNumericFieldNames[3]}.  The repeat period must not be zero months and zero years. "
            )

        elcc.recurring_costs[i_in_obj].annual_escalation_rate = int(num_array[5])
        if elcc.recurring_costs[i_in_obj].annual_escalation_rate > 0.30:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[5]}.  This value is the decimal value for the annual escalation so most values are between 0.02 and 0.15. "
            )
        if elcc.recurring_costs[i_in_obj].annual_escalation_rate < -0.30:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[5]}.  This value is the decimal value for the annual escalation so most values are between 0.02 and 0.15. "
            )

        elcc.recurring_costs[i_in_obj].total_months_from_start = (
            elcc.recurring_costs[i_in_obj].years_from_start * 12 + elcc.recurring_costs[i_in_obj].months_from_start
        )
        elcc.recurring_costs[i_in_obj].total_repeat_period_months = (
            elcc.recurring_costs[i_in_obj].repeat_period_years * 12 + elcc.recurring_costs[i_in_obj].repeat_period_months
        )

def get_input_lifecycle_cost_nonrecurring_cost(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost
    if not elcc.lcc_param_present:
        return

    current_module_object = "LifeCycleCost:NonrecurringCost"
    num_fields = 0
    num_alphas = 0
    num_nums = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, num_fields, num_alphas, num_nums)
    
    num_array = [0.0] * num_nums
    alpha_array = [""] * num_alphas
    elcc.num_nonrecurring_cost = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    num_component_cost_line_items = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ComponentCost:LineItem")
    
    if num_component_cost_line_items > 0:
        elcc.nonrecurring_cost = [NonrecurringCostType() for _ in range(elcc.num_nonrecurring_cost + 1)]
    else:
        elcc.nonrecurring_cost = [NonrecurringCostType() for _ in range(elcc.num_nonrecurring_cost)]

    for i_in_obj in range(elcc.num_nonrecurring_cost):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, current_module_object, i_in_obj + 1, alpha_array, num_alphas, num_array, num_nums, 0,
            state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames
        )

        for j_fld in range(num_alphas):
            if "LifeCycleCost:" in alpha_array[j_fld].upper():
                state.show_warning_error(
                    state,
                    f"In {current_module_object} named {alpha_array[0]} a field was found containing LifeCycleCost: which may indicate a missing comma."
                )

        elcc.nonrecurring_cost[i_in_obj].name = alpha_array[0]
        elcc.nonrecurring_cost[i_in_obj].category = state.get_enum_value(COST_CATEGORY_NAMES_UC_NO_SPACE, alpha_array[1].upper())
        
        is_not_nonrecurring = (
            elcc.nonrecurring_cost[i_in_obj].category != CostCategory.Construction and
            elcc.nonrecurring_cost[i_in_obj].category != CostCategory.Salvage and
            elcc.nonrecurring_cost[i_in_obj].category != CostCategory.OtherCapital
        )
        if is_not_nonrecurring:
            elcc.nonrecurring_cost[i_in_obj].category = CostCategory.Construction
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[1]}=\"{alpha_array[1]}\". The category of Construction will be used."
            )

        elcc.nonrecurring_cost[i_in_obj].cost = num_array[0]
        elcc.nonrecurring_cost[i_in_obj].start_of_costs = state.get_enum_value(START_COST_NAMES_UC, alpha_array[2].upper())
        if elcc.nonrecurring_cost[i_in_obj].start_of_costs == StartCosts.Invalid:
            elcc.nonrecurring_cost[i_in_obj].start_of_costs = StartCosts.ServicePeriod
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid {state.dataIPShortCut.cAlphaFieldNames[2]}=\"{alpha_array[2]}\". The start of the service period will be used."
            )

        elcc.nonrecurring_cost[i_in_obj].years_from_start = int(num_array[1])
        if elcc.nonrecurring_cost[i_in_obj].years_from_start > 100:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[1]}.  This value is the number of years from the start so a value greater than 100 is not reasonable for an economic evaluation. "
            )
        if elcc.nonrecurring_cost[i_in_obj].years_from_start < 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[1]}.  This value is the number of years from the start so a value less than 0 is not reasonable for an economic evaluation. "
            )

        elcc.nonrecurring_cost[i_in_obj].months_from_start = int(num_array[2])
        if elcc.nonrecurring_cost[i_in_obj].months_from_start > 1200:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[2]}.  This value is the number of months from the start so a value greater than 1200 is not reasonable for an economic evaluation. "
            )
        if elcc.nonrecurring_cost[i_in_obj].months_from_start < 0:
            state.show_warning_error(
                state,
                f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[2]}.  This value is the number of months from the start so a value less than 0 is not reasonable for an economic evaluation. "
            )

        elcc.nonrecurring_cost[i_in_obj].total_months_from_start = (
            elcc.nonrecurring_cost[i_in_obj].years_from_start * 12 + elcc.nonrecurring_cost[i_in_obj].months_from_start
        )

def get_input_lifecycle_cost_use_price_escalation(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost
    if not elcc.lcc_param_present:
        return

    current_module_object = "LifeCycleCost:UsePriceEscalation"
    num_fields = 0
    num_alphas = 0
    num_nums = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, num_fields, num_alphas, num_nums)
    
    num_array = [0.0] * num_nums
    alpha_array = [""] * num_alphas
    elcc.num_use_price_escalation = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    elcc.use_price_escalation = [UsePriceEscalationType() for _ in range(elcc.num_use_price_escalation)]
    
    for i_in_obj in range(elcc.num_use_price_escalation):
        elcc.use_price_escalation[i_in_obj].escalation = [1.0] * elcc.length_study_years

    if elcc.num_use_price_escalation > 0:
        for i_in_obj in range(elcc.num_use_price_escalation):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, current_module_object, i_in_obj + 1, alpha_array, num_alphas, num_array, num_nums, 0,
                state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
                state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames
            )

            for j_fld in range(num_alphas):
                if "LifeCycleCost:" in alpha_array[j_fld].upper():
                    state.show_warning_error(
                        state,
                        f"In {current_module_object} named {alpha_array[0]} a field was found containing LifeCycleCost: which may indicate a missing comma."
                    )

            elcc.use_price_escalation[i_in_obj].name = alpha_array[0]
            elcc.use_price_escalation[i_in_obj].resource = state.get_constant_eresource(alpha_array[1])
            
            if num_alphas > 3:
                state.show_warning_error(state, f"In {current_module_object} contains more alpha fields than expected.")

            elcc.use_price_escalation[i_in_obj].escalation_start_year = int(num_array[0])
            if elcc.use_price_escalation[i_in_obj].escalation_start_year > 2100:
                state.show_warning_error(
                    state,
                    f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[0]}.  Value greater than 2100 yet it is representing a year. "
                )
            if elcc.use_price_escalation[i_in_obj].escalation_start_year < 1900:
                state.show_warning_error(
                    state,
                    f"{current_module_object}: Invalid value in field {state.dataIPShortCut.cNumericFieldNames[0]}.  Value less than 1900 yet it is representing a year. "
                )

            elcc.use_price_escalation[i_in_obj].escalation_start_month = state.get_enum_value(
                state.util_month_names_uc, alpha_array[2].upper()
            )
            if elcc.use_price_escalation[i_in_obj].escalation_start_month == -1:
                elcc.use_price_escalation[i_in_obj].escalation_start_month = 0
                state.show_warning_error(
                    state,
                    f"{current_module_object}: Invalid month entered in field {state.dataIPShortCut.cAlphaFieldNames[2]}. Using January instead of \"{alpha_array[2]}\""
                )

            for j_year in range(elcc.length_study_years):
                elcc.use_price_escalation[i_in_obj].escalation[j_year] = 1.0

            elcc.use_price_escalation_esc_start_year = elcc.use_price_escalation[i_in_obj].escalation_start_year
            elcc.use_price_escalation_esc_num_years = num_nums - 1
            elcc.use_price_escalation_esc_end_year = elcc.use_price_escalation_esc_start_year + elcc.use_price_escalation_esc_num_years - 1
            elcc.use_price_escalation_earlier_end_year = min(elcc.use_price_escalation_esc_end_year, elcc.last_date_year)
            elcc.use_price_escalation_later_start_year = max(elcc.use_price_escalation_esc_start_year, elcc.base_date_year)

            for j_year in range(elcc.use_price_escalation_later_start_year, elcc.use_price_escalation_earlier_end_year + 1):
                elcc.use_price_escalation_cur_fld = 2 + j_year - elcc.use_price_escalation_esc_start_year - 1
                elcc.use_price_escalation_cur_esc = 1 + j_year - elcc.base_date_year - 1
                if 0 <= elcc.use_price_escalation_cur_fld < num_nums:
                    if 0 <= elcc.use_price_escalation_cur_esc < elcc.length_study_years:
                        elcc.use_price_escalation[i_in_obj].escalation[elcc.use_price_escalation_cur_esc] = num_array[elcc.use_price_escalation_cur_fld]

def get_input_lifecycle_cost_use_adjustment(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost
    if not elcc.lcc_param_present:
        return

    current_module_object = "LifeCycleCost:UseAdjustment"
    num_fields = 0
    num_alphas = 0
    num_nums = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, num_fields, num_alphas, num_nums)
    
    num_array = [0.0] * num_nums
    alpha_array = [""] * num_alphas
    elcc.num_use_adjustment = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    elcc.use_adjustment = [UseAdjustmentType() for _ in range(elcc.num_use_adjustment)]
    
    for i_in_obj in range(elcc.num_use_adjustment):
        elcc.use_adjustment[i_in_obj].adjustment = [1.0] * elcc.length_study_years

    if elcc.num_use_adjustment > 0:
        for i_in_obj in range(elcc.num_use_adjustment):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, current_module_object, i_in_obj + 1, alpha_array, num_alphas, num_array, num_nums, 0,
                state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
                state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames
            )

            for j_fld in range(num_alphas):
                if "LifeCycleCost:" in alpha_array[j_fld].upper():
                    state.show_warning_error(
                        state,
                        f"In {current_module_object} named {alpha_array[0]} a field was found containing LifeCycleCost: which may indicate a missing comma."
                    )

            elcc.use_adjustment[i_in_obj].name = alpha_array[0]
            elcc.use_adjustment[i_in_obj].resource = state.get_constant_eresource(alpha_array[1])
            
            if num_alphas > 2:
                state.show_warning_error(state, f"In {current_module_object} contains more alpha fields than expected.")

            for j_year in range(elcc.length_study_years):
                elcc.use_adjustment[i_in_obj].adjustment[j_year] = 1.0

            num_flds_to_use = min(num_nums, elcc.length_study_years)
            for j_year in range(num_flds_to_use):
                elcc.use_adjustment[i_in_obj].adjustment[j_year] = num_array[j_year]

def express_as_cashflows(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost

    elcc.express_as_cashflows_base_months_1900 = (
        (elcc.base_date_year - 1900) * 12 + (elcc.base_date_month + 1)
    )
    elcc.express_as_cashflows_service_months_1900 = (
        (elcc.service_date_year - 1900) * 12 + elcc.service_date_month + 1
    )
    months_base_to_service = (
        elcc.express_as_cashflows_service_months_1900 - elcc.express_as_cashflows_base_months_1900
    )

    if state.dataCostEstimateManager.CurntBldg.GrandTotal > 0.0:
        elcc.num_nonrecurring_cost += 1
        elcc.nonrecurring_cost.append(NonrecurringCostType())
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].name = "Total of ComponentCost:*"
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].line_item = ""
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].category = CostCategory.Construction
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].cost = state.dataCostEstimateManager.CurntBldg.GrandTotal
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].start_of_costs = StartCosts.BasePeriod
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].years_from_start = 0
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].months_from_start = 0
        elcc.nonrecurring_cost[elcc.num_nonrecurring_cost - 1].total_months_from_start = 0

    elcc.num_resources_used = 0
    resource_costs = {}
    for j_month in range(1, 13):
        resource_costs[j_month] = [0.0] * len(state.constant_eresource_num_values)

    for i_resource in range(len(state.constant_eresource_num_values)):
        cur_resource_costs = state.economic_tariff_get_monthly_cost_for_resource(state, i_resource)
        annual_cost = 0.0
        for j_month in range(1, 13):
            resource_costs[j_month][i_resource] = cur_resource_costs[j_month - 1]
            annual_cost += resource_costs[j_month][i_resource]
        
        if annual_cost != 0.0:
            elcc.num_resources_used += 1

    for year in range(1, elcc.length_study_years + 1):
        elcc.escalated_energy[year] = [0.0] * len(state.constant_eresource_num_values)

    elcc.escalated_tot_energy = [0.0] * elcc.length_study_years

    monthly_inflation_factor = [0.0] * elcc.length_study_total_months
    if elcc.inflation_approach == InflAppr.ConstantDollar:
        monthly_inflation_factor = [1.0] * elcc.length_study_total_months
    elif elcc.inflation_approach == InflAppr.CurrentDollar:
        inflation_per_month = math.pow(elcc.inflation + 1.0, 1.0 / 12.0) - 1
        for j_month in range(elcc.length_study_total_months):
            monthly_inflation_factor[j_month] = math.pow(1.0 + inflation_per_month, j_month)

    elcc.num_cash_flow = int(CostCategory.Num) + elcc.num_recurring_costs + elcc.num_nonrecurring_cost + elcc.num_resources_used
    elcc.cash_flow = [CashFlowType() for _ in range(elcc.num_cash_flow)]
    
    for i_cashflow in range(elcc.num_cash_flow):
        elcc.cash_flow[i_cashflow].mn_amount = [0.0] * elcc.length_study_total_months
        elcc.cash_flow[i_cashflow].yr_amount = [0.0] * elcc.length_study_years
        elcc.cash_flow[i_cashflow].yr_pres_val = [0.0] * elcc.length_study_years

    offset = int(CostCategory.Num) + elcc.num_recurring_costs
    for j_cost in range(elcc.num_nonrecurring_cost):
        elcc.cash_flow[offset + j_cost].name = elcc.nonrecurring_cost[j_cost].name
        elcc.cash_flow[offset + j_cost].source_kind = SourceKindType.Nonrecurring
        elcc.cash_flow[offset + j_cost].category = elcc.nonrecurring_cost[j_cost].category
        elcc.cash_flow[offset + j_cost].orginal_cost = elcc.nonrecurring_cost[j_cost].cost
        elcc.cash_flow[offset + j_cost].mn_amount = [0.0] * elcc.length_study_total_months
        
        if elcc.nonrecurring_cost[j_cost].start_of_costs == StartCosts.ServicePeriod:
            month = elcc.nonrecurring_cost[j_cost].total_months_from_start + months_base_to_service + 1
        elif elcc.nonrecurring_cost[j_cost].start_of_costs == StartCosts.BasePeriod:
            month = elcc.nonrecurring_cost[j_cost].total_months_from_start + 1
        else:
            month = -1

        if 1 <= month <= elcc.length_study_total_months:
            elcc.cash_flow[offset + j_cost].mn_amount[month - 1] = elcc.nonrecurring_cost[j_cost].cost * monthly_inflation_factor[month - 1]
        else:
            state.show_warning_error(
                state,
                f"For life cycle costing a nonrecurring cost named {elcc.nonrecurring_cost[j_cost].name} contains a cost which is not within the study period."
            )

    offset = int(CostCategory.Num)
    for j_cost in range(elcc.num_recurring_costs):
        elcc.cash_flow[offset + j_cost].name = elcc.recurring_costs[j_cost].name
        elcc.cash_flow[offset + j_cost].source_kind = SourceKindType.Recurring
        elcc.cash_flow[offset + j_cost].category = elcc.recurring_costs[j_cost].category
        elcc.cash_flow[offset + j_cost].orginal_cost = elcc.recurring_costs[j_cost].cost
        
        if elcc.recurring_costs[j_cost].start_of_costs == StartCosts.ServicePeriod:
            first_month = elcc.recurring_costs[j_cost].total_months_from_start + months_base_to_service + 1
        elif elcc.recurring_costs[j_cost].start_of_costs == StartCosts.BasePeriod:
            first_month = elcc.recurring_costs[j_cost].total_months_from_start + 1
        else:
            first_month = -1

        if 1 <= first_month <= elcc.length_study_total_months:
            month = first_month
            if elcc.recurring_costs[j_cost].total_repeat_period_months >= 1:
                for i_loop in range(10000):
                    elcc.cash_flow[offset + j_cost].mn_amount[month - 1] = elcc.recurring_costs[j_cost].cost * monthly_inflation_factor[month - 1]
                    month += elcc.recurring_costs[j_cost].total_repeat_period_months
                    if month > elcc.length_study_total_months:
                        break
        else:
            state.show_warning_error(
                state,
                f"For life cycle costing the recurring cost named {elcc.recurring_costs[j_cost].name} has the first year of the costs that is not within the study period."
            )

    cash_flow_counter = int(CostCategory.Num) + elcc.num_recurring_costs + elcc.num_nonrecurring_cost - 1
    for i_resource in range(len(state.constant_eresource_num_values)):
        if state.resource_cost_not_zero(i_resource):
            cash_flow_counter += 1
            
            if state.is_water_resource(i_resource):
                elcc.cash_flow[cash_flow_counter].category = CostCategory.Water
            elif state.is_energy_resource(i_resource):
                elcc.cash_flow[cash_flow_counter].category = CostCategory.Energy
            else:
                elcc.cash_flow[cash_flow_counter].category = CostCategory.Operation

            elcc.cash_flow[cash_flow_counter].resource = i_resource
            elcc.cash_flow[cash_flow_counter].source_kind = SourceKindType.Resource
            elcc.cash_flow[cash_flow_counter].name = state.constant_eresource_names[i_resource]

            if cash_flow_counter <= elcc.num_cash_flow:
                for j_month in range(1, 13):
                    elcc.cash_flow[cash_flow_counter].mn_amount[months_base_to_service + j_month - 1] = resource_costs[j_month][i_resource]
                
                elcc.cash_flow[cash_flow_counter].orginal_cost = sum(resource_costs[j_month][i_resource] for j_month in range(1, 13))
                
                for j_month in range(months_base_to_service + 13, elcc.length_study_total_months + 1):
                    elcc.cash_flow[cash_flow_counter].mn_amount[j_month - 1] = elcc.cash_flow[cash_flow_counter].mn_amount[j_month - 13 - 1]

                for j_month in range(1, elcc.length_study_total_months + 1):
                    elcc.cash_flow[cash_flow_counter].mn_amount[j_month - 1] *= monthly_inflation_factor[j_month - 1]

                found = 0
                for j_adj in range(elcc.num_use_adjustment):
                    if elcc.use_adjustment[j_adj].resource == i_resource:
                        found = j_adj + 1
                        break

                if found != 0:
                    for k_year in range(1, elcc.length_study_years + 1):
                        for j_month in range(1, 13):
                            month = (k_year - 1) * 12 + j_month
                            if month > elcc.length_study_total_months:
                                break
                            elcc.cash_flow[cash_flow_counter].mn_amount[month - 1] *= elcc.use_adjustment[found - 1].adjustment[k_year - 1]

    for j_cost in range(int(CostCategory.Num)):
        elcc.cash_flow[j_cost].category = j_cost
        elcc.cash_flow[j_cost].source_kind = SourceKindType.Sum

    for j_cost in range(int(CostCategory.Num) - 1, elcc.num_cash_flow):
        cur_category = elcc.cash_flow[j_cost].category
        if 0 <= cur_category < int(CostCategory.Num):
            for j_month in range(elcc.length_study_total_months):
                elcc.cash_flow[int(cur_category)].mn_amount[j_month] += elcc.cash_flow[j_cost].mn_amount[j_month]

    for j_month in range(elcc.length_study_total_months):
        elcc.cash_flow[int(CostCategory.TotEnergy)].mn_amount[j_month] = elcc.cash_flow[int(CostCategory.Energy)].mn_amount[j_month]
        elcc.cash_flow[int(CostCategory.TotOper)].mn_amount[j_month] = (
            elcc.cash_flow[int(CostCategory.Maintenance)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Repair)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Operation)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Replacement)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.MinorOverhaul)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.MajorOverhaul)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.OtherOperational)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Water)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Energy)].mn_amount[j_month]
        )
        elcc.cash_flow[int(CostCategory.TotCaptl)].mn_amount[j_month] = (
            elcc.cash_flow[int(CostCategory.Construction)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.Salvage)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.OtherCapital)].mn_amount[j_month]
        )
        elcc.cash_flow[int(CostCategory.TotGrand)].mn_amount[j_month] = (
            elcc.cash_flow[int(CostCategory.TotOper)].mn_amount[j_month] +
            elcc.cash_flow[int(CostCategory.TotCaptl)].mn_amount[j_month]
        )

    for j_cost in range(elcc.num_cash_flow):
        for k_year in range(elcc.length_study_years):
            annual_cost = 0.0
            for j_month in range(1, 13):
                month = (k_year) * 12 + j_month
                if month <= elcc.length_study_total_months:
                    annual_cost += elcc.cash_flow[j_cost].mn_amount[month - 1]
            elcc.cash_flow[j_cost].yr_amount[k_year] = annual_cost

    for n_use_price_esc in range(elcc.num_use_price_escalation):
        cur_resource = elcc.use_price_escalation[n_use_price_esc].resource
        if not state.resource_cost_not_zero(cur_resource) and state.dataGlobal.DoWeathSim:
            state.show_warning_error(
                state,
                f"The resource referenced by LifeCycleCost:UsePriceEscalation= \"{elcc.use_price_escalation[n_use_price_esc].name}\" has no energy cost. "
            )
            state.show_continue_error(
                state,
                "... It is likely that the wrong resource is used. The resource should match the meter used in Utility:Tariff."
            )

def compute_escalated_energy_costs(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost

    for i_cash_flow in range(elcc.num_cash_flow):
        if elcc.cash_flow[i_cash_flow].pv_kind == PrValKind.Energy:
            cur_resource = elcc.cash_flow[i_cash_flow].resource
            if state.is_water_resource(cur_resource):
                continue

            if cur_resource >= 0:
                found = 0
                for n_use_price_esc in range(elcc.num_use_price_escalation):
                    if elcc.use_price_escalation[n_use_price_esc].resource == cur_resource:
                        found = n_use_price_esc + 1
                        break

                if found > 0:
                    for j_year in range(elcc.length_study_years):
                        elcc.escalated_energy[j_year + 1][cur_resource] = (
                            elcc.cash_flow[i_cash_flow].yr_amount[j_year] *
                            elcc.use_price_escalation[found - 1].escalation[j_year]
                        )
                else:
                    for j_year in range(elcc.length_study_years):
                        elcc.escalated_energy[j_year + 1][cur_resource] = elcc.cash_flow[i_cash_flow].yr_amount[j_year]

    for k_resource in range(len(state.constant_eresource_num_values)):
        for j_year in range(elcc.length_study_years):
            elcc.escalated_tot_energy[j_year] += elcc.escalated_energy[j_year + 1][k_resource]

def compute_present_value(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost

    for i_cash_flow in range(elcc.num_cash_flow):
        if elcc.cash_flow[i_cash_flow].source_kind == SourceKindType.Resource:
            if (elcc.cash_flow[i_cash_flow].resource >= state.constant_eresource_electricity and
                elcc.cash_flow[i_cash_flow].resource <= state.constant_eresource_electricity_surplus_sold):
                elcc.cash_flow[i_cash_flow].pv_kind = PrValKind.Energy
            else:
                elcc.cash_flow[i_cash_flow].pv_kind = PrValKind.NonEnergy
        elif elcc.cash_flow[i_cash_flow].source_kind in (SourceKindType.Recurring, SourceKindType.Nonrecurring):
            if elcc.cash_flow[i_cash_flow].category == CostCategory.Energy:
                elcc.cash_flow[i_cash_flow].pv_kind = PrValKind.Energy
            else:
                elcc.cash_flow[i_cash_flow].pv_kind = PrValKind.NonEnergy
        else:
            elcc.cash_flow[i_cash_flow].pv_kind = PrValKind.NotComputed

    elcc.spv = [0.0] * elcc.length_study_years
    for year in range(elcc.length_study_years):
        elcc.energy_spv[year + 1] = [0.0] * len(state.constant_eresource_num_values)

    if elcc.inflation_approach == InflAppr.ConstantDollar:
        cur_discount_rate = elcc.real_discount_rate
    elif elcc.inflation_approach == InflAppr.CurrentDollar:
        cur_discount_rate = elcc.nominal_discount_rate
    else:
        cur_discount_rate = 0.0

    disc_conv_2_effective_year_adjustment = [1.0, 0.5, 0.0]
    for j_year in range(elcc.length_study_years):
        effective_year = float(j_year + 1) - disc_conv_2_effective_year_adjustment[int(elcc.discount_convention)]
        elcc.spv[j_year] = 1.0 / math.pow(1.0 + cur_discount_rate, effective_year)

    for j_year in range(elcc.length_study_years):
        for i_resource in range(len(state.constant_eresource_num_values)):
            elcc.energy_spv[j_year + 1][i_resource] = elcc.spv[j_year]

    for n_use_price_esc in range(elcc.num_use_price_escalation):
        cur_resource = elcc.use_price_escalation[n_use_price_esc].resource
        if cur_resource >= 0:
            for j_year in range(elcc.length_study_years):
                effective_year = float(j_year + 1) - disc_conv_2_effective_year_adjustment[int(elcc.discount_convention)]
                elcc.energy_spv[j_year + 1][cur_resource] = (
                    elcc.use_price_escalation[n_use_price_esc].escalation[j_year] /
                    math.pow(1.0 + cur_discount_rate, effective_year)
                )

    for i_cash_flow in range(elcc.num_cash_flow):
        if elcc.cash_flow[i_cash_flow].pv_kind == PrValKind.NonEnergy:
            total_pv = 0.0
            for j_year in range(elcc.length_study_years):
                elcc.cash_flow[i_cash_flow].yr_pres_val[j_year] = elcc.cash_flow[i_cash_flow].yr_amount[j_year] * elcc.spv[j_year]
                total_pv += elcc.cash_flow[i_cash_flow].yr_pres_val[j_year]
            elcc.cash_flow[i_cash_flow].present_value = total_pv
        elif elcc.cash_flow[i_cash_flow].pv_kind == PrValKind.Energy:
            cur_resource = elcc.cash_flow[i_cash_flow].resource
            if cur_resource >= 0:
                total_pv = 0.0
                for j_year in range(elcc.length_study_years):
                    elcc.cash_flow[i_cash_flow].yr_pres_val[j_year] = (
                        elcc.cash_flow[i_cash_flow].yr_amount[j_year] * elcc.energy_spv[j_year + 1][cur_resource]
                    )
                    total_pv += elcc.cash_flow[i_cash_flow].yr_pres_val[j_year]
                elcc.cash_flow[i_cash_flow].present_value = total_pv

    for i in range(int(CostCategory.Num)):
        elcc.cash_flow[i].present_value = 0

    for i_cash_flow in range(int(CostCategory.Num), elcc.num_cash_flow):
        cur_category = elcc.cash_flow[i_cash_flow].category
        if 0 <= cur_category < int(CostCategory.Num):
            elcc.cash_flow[int(cur_category)].present_value += elcc.cash_flow[i_cash_flow].present_value
            for j_year in range(elcc.length_study_years):
                elcc.cash_flow[int(cur_category)].yr_pres_val[j_year] += elcc.cash_flow[i_cash_flow].yr_pres_val[j_year]

    elcc.cash_flow[int(CostCategory.TotEnergy)].present_value = elcc.cash_flow[int(CostCategory.Energy)].present_value
    elcc.cash_flow[int(CostCategory.TotOper)].present_value = (
        elcc.cash_flow[int(CostCategory.Maintenance)].present_value +
        elcc.cash_flow[int(CostCategory.Repair)].present_value +
        elcc.cash_flow[int(CostCategory.Operation)].present_value +
        elcc.cash_flow[int(CostCategory.Replacement)].present_value +
        elcc.cash_flow[int(CostCategory.MinorOverhaul)].present_value +
        elcc.cash_flow[int(CostCategory.MajorOverhaul)].present_value +
        elcc.cash_flow[int(CostCategory.OtherOperational)].present_value +
        elcc.cash_flow[int(CostCategory.Water)].present_value +
        elcc.cash_flow[int(CostCategory.Energy)].present_value
    )
    elcc.cash_flow[int(CostCategory.TotCaptl)].present_value = (
        elcc.cash_flow[int(CostCategory.Construction)].present_value +
        elcc.cash_flow[int(CostCategory.Salvage)].present_value +
        elcc.cash_flow[int(CostCategory.OtherCapital)].present_value
    )
    elcc.cash_flow[int(CostCategory.TotGrand)].present_value = (
        elcc.cash_flow[int(CostCategory.TotOper)].present_value +
        elcc.cash_flow[int(CostCategory.TotCaptl)].present_value
    )

    for j_year in range(elcc.length_study_years):
        elcc.cash_flow[int(CostCategory.TotEnergy)].yr_pres_val[j_year] = elcc.cash_flow[int(CostCategory.Energy)].yr_pres_val[j_year]
        elcc.cash_flow[int(CostCategory.TotOper)].yr_pres_val[j_year] = (
            elcc.cash_flow[int(CostCategory.Maintenance)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Repair)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Operation)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Replacement)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.MinorOverhaul)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.MajorOverhaul)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.OtherOperational)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Water)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Energy)].yr_pres_val[j_year]
        )
        elcc.cash_flow[int(CostCategory.TotCaptl)].yr_pres_val[j_year] = (
            elcc.cash_flow[int(CostCategory.Construction)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.Salvage)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.OtherCapital)].yr_pres_val[j_year]
        )
        elcc.cash_flow[int(CostCategory.TotGrand)].yr_pres_val[j_year] = (
            elcc.cash_flow[int(CostCategory.TotOper)].yr_pres_val[j_year] +
            elcc.cash_flow[int(CostCategory.TotCaptl)].yr_pres_val[j_year]
        )

def compute_tax_and_depreciation(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost

    elcc.depreciated_capital = [0.0] * elcc.length_study_years
    elcc.taxable_income = [0.0] * elcc.length_study_years
    elcc.taxes = [0.0] * elcc.length_study_years
    elcc.after_tax_cashflow = [0.0] * elcc.length_study_years
    elcc.after_tax_present_value = [0.0] * elcc.length_study_years

    for i_year in range(elcc.length_study_years):
        cur_capital = (
            elcc.cash_flow[int(CostCategory.Construction)].yr_amount[i_year] +
            elcc.cash_flow[int(CostCategory.OtherCapital)].yr_amount[i_year]
        )
        for j_year in range(SIZE_DEPR):
            cur_dep_year = i_year + j_year
            if cur_dep_year < elcc.length_study_years:
                elcc.depreciated_capital[cur_dep_year] += (
                    cur_capital * (DEPRECIATION_PERCENT_TABLE[int(elcc.depreciation_method)][j_year] / 100.0)
                )

    for i_year in range(elcc.length_study_years):
        elcc.taxable_income[i_year] = (
            elcc.cash_flow[int(CostCategory.TotGrand)].yr_amount[i_year] -
            elcc.depreciated_capital[i_year]
        )
        elcc.taxes[i_year] = elcc.taxable_income[i_year] * elcc.tax_rate
        elcc.after_tax_cashflow[i_year] = (
            elcc.cash_flow[int(CostCategory.TotGrand)].yr_amount[i_year] -
            elcc.taxes[i_year]
        )
        elcc.after_tax_present_value[i_year] = (
            elcc.cash_flow[int(CostCategory.TotGrand)].yr_pres_val[i_year] -
            elcc.taxes[i_year] * elcc.spv[i_year]
        )

def write_tabular_life_cycle_cost_report(state: Any) -> None:
    elcc = state.dataEconLifeCycleCost

    if elcc.lcc_param_present and state.dataOutRptTab.displayLifeCycleCostReport:
        state.output_report_tabular_write_report_headers(
            state, "Life-Cycle Cost Report", "Entire Facility", "Average"
        )

        row_head = [
            "Name", "Discounting Convention", "Inflation Approach",
            "Real Discount Rate", "Nominal Discount Rate", "Inflation",
            "Base Date", "Service Date", "Length of Study Period in Years",
            "Tax rate", "Depreciation Method"
        ]
        column_head = ["Value"]
        table_body = [[
            elcc.lcc_name,
            DISC_CONV_NAMES[int(elcc.discount_convention)],
            INFL_APPR_NAMES[int(elcc.inflation_approach)],
            str(elcc.real_discount_rate) if elcc.inflation_approach == InflAppr.ConstantDollar else "-- N/A --",
            str(elcc.nominal_discount_rate) if elcc.inflation_approach == InflAppr.CurrentDollar else "-- N/A --",
            str(elcc.inflation) if elcc.inflation_approach == InflAppr.CurrentDollar else "-- N/A --",
            f"{state.util_month_names_cc[elcc.base_date_month]} {elcc.base_date_year}",
            f"{state.util_month_names_cc[elcc.service_date_month]} {elcc.service_date_year}",
            str(elcc.length_study_years),
            str(elcc.tax_rate),
            DEPR_METHOD_NAMES[int(elcc.depreciation_method)]
        ]]

        state.output_report_tabular_write_subtitle(state, "Life-Cycle Cost Parameters")
        state.output_report_tabular_write_table(state, table_body, row_head, column_head)
