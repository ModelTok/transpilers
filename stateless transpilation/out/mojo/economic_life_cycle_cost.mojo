from math import pow
from collections import OrderedDict

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state: struct with dataXXX accessors
# - Constant.eResource: enum for resource types
# - Util functions: makeUPPER, MonthNamesUC, MonthNamesCC
# - InputProcessor: getObjectDefMaxArgs, getNumObjectsFound, getObjectItem
# - OutputReportTabular: WriteReportHeaders, WriteSubtitle, WriteTable, RealToStr
# - Display/output functions: DisplayString, ShowWarningError, ShowContinueError
# - hasi: case-insensitive string contains
# - getEnumValue: enum lookup
# - CostEstimateManager.CurntBldg: building cost data
# - EconomicTariff.GetMonthlyCostForResource: energy cost retrieval

struct DiscConv:
    alias Invalid = -1
    alias BeginOfYear = 0
    alias MidYear = 1
    alias EndOfYear = 2
    alias Num = 3

alias DISC_CONV_NAMES_UC = StaticTuple["BEGINNINGOFYEAR", "MIDYEAR", "ENDOFYEAR"]
alias DISC_CONV_NAMES = StaticTuple["BeginningOfYear", "MidYear", "EndOfYear"]

struct InflAppr:
    alias Invalid = -1
    alias ConstantDollar = 0
    alias CurrentDollar = 1
    alias Num = 2

alias INFL_APPR_NAMES_UC = StaticTuple["CONSTANTDOLLAR", "CURRENTDOLLAR"]
alias INFL_APPR_NAMES = StaticTuple["ConstantDollar", "CurrentDollar"]

struct DeprMethod:
    alias Invalid = -1
    alias MACRS3 = 0
    alias MACRS5 = 1
    alias MACRS7 = 2
    alias MACRS10 = 3
    alias MACRS15 = 4
    alias MACRS20 = 5
    alias Straight27 = 6
    alias Straight31 = 7
    alias Straight39 = 8
    alias Straight40 = 9
    alias None_ = 10
    alias Num = 11

alias SIZE_DEPR = 41

struct CostCategory:
    alias Invalid = -1
    alias Maintenance = 0
    alias Repair = 1
    alias Operation = 2
    alias Replacement = 3
    alias MinorOverhaul = 4
    alias MajorOverhaul = 5
    alias OtherOperational = 6
    alias Water = 7
    alias Energy = 8
    alias TotOper = 9
    alias Construction = 10
    alias Salvage = 11
    alias OtherCapital = 12
    alias TotCaptl = 13
    alias TotEnergy = 14
    alias TotGrand = 15
    alias Num = 16

alias COST_CATEGORY_NAMES_UC_NO_SPACE = StaticTuple[
    "MAINTENANCE", "REPAIR", "OPERATION", "REPLACEMENT", "MINOROVERHAUL",
    "MAJOROVERHAUL", "OTHEROPERATIONAL", "WATER", "ENERGY", "TOTALOPERATIONAL",
    "CONSTRUCTION", "SALVAGE", "OTHERCAPITAL", "TOTALCAPITAL", "TOTALENERGY", "GRANDTOTAL"
]

alias DEPR_METHOD_NAMES_UC = StaticTuple[
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

alias START_COST_NAMES_UC = StaticTuple["SERVICEPERIOD", "BASEPERIOD"]

struct SourceKindType:
    alias Invalid = -1
    alias Recurring = 0
    alias Nonrecurring = 1
    alias Resource = 2
    alias Sum = 3
    alias Num = 4

alias SOURCE_KIND_TYPE_NAMES = StaticTuple["Recurring", "Nonrecurring"]

struct ResourceCostCategory:
    alias Invalid = -1
    alias Water = 0
    alias Energy = 1
    alias Num = 2

alias RESOURCE_COST_CATEGORY_NAMES = StaticTuple["Water Cost", "Energy Cost"]

struct PrValKind:
    alias Invalid = -1
    alias Energy = 0
    alias NonEnergy = 1
    alias NotComputed = 2
    alias Num = 3

alias StartCosts = StaticTuple[0, 1]

struct RecurringCostsType:
    var name: String
    var line_item: String
    var category: Int
    var cost: Float64
    var start_of_costs: Int
    var years_from_start: Int
    var months_from_start: Int
    var total_months_from_start: Int
    var repeat_period_years: Int
    var repeat_period_months: Int
    var total_repeat_period_months: Int
    var annual_escalation_rate: Float64

    fn __init__(inout self):
        self.name = ""
        self.line_item = ""
        self.category = CostCategory.Maintenance
        self.cost = 0.0
        self.start_of_costs = 0
        self.years_from_start = 0
        self.months_from_start = 0
        self.total_months_from_start = 0
        self.repeat_period_years = 0
        self.repeat_period_months = 0
        self.total_repeat_period_months = 0
        self.annual_escalation_rate = 0.0

struct NonrecurringCostType:
    var name: String
    var line_item: String
    var category: Int
    var cost: Float64
    var start_of_costs: Int
    var years_from_start: Int
    var months_from_start: Int
    var total_months_from_start: Int

    fn __init__(inout self):
        self.name = ""
        self.line_item = ""
        self.category = CostCategory.Construction
        self.cost = 0.0
        self.start_of_costs = 0
        self.years_from_start = 0
        self.months_from_start = 0
        self.total_months_from_start = 0

struct UsePriceEscalationType:
    var name: String
    var resource: Int
    var escalation_start_year: Int
    var escalation_start_month: Int
    var escalation: DynamicVector[Float64]

    fn __init__(inout self):
        self.name = ""
        self.resource = -1
        self.escalation_start_year = 0
        self.escalation_start_month = 0
        self.escalation = DynamicVector[Float64]()

struct UseAdjustmentType:
    var name: String
    var resource: Int
    var adjustment: DynamicVector[Float64]

    fn __init__(inout self):
        self.name = ""
        self.resource = -1
        self.adjustment = DynamicVector[Float64]()

struct CashFlowType:
    var name: String
    var source_kind: Int
    var resource: Int
    var category: Int
    var mn_amount: DynamicVector[Float64]
    var yr_amount: DynamicVector[Float64]
    var pv_kind: Int
    var present_value: Float64
    var orginal_cost: Float64
    var yr_pres_val: DynamicVector[Float64]

    fn __init__(inout self):
        self.name = ""
        self.source_kind = SourceKindType.Invalid
        self.resource = -1
        self.category = CostCategory.Invalid
        self.mn_amount = DynamicVector[Float64]()
        self.yr_amount = DynamicVector[Float64]()
        self.pv_kind = PrValKind.Invalid
        self.present_value = 0.0
        self.orginal_cost = 0.0
        self.yr_pres_val = DynamicVector[Float64]()

struct EconomicLifeCycleCostData:
    var lcc_param_present: Bool
    var lcc_name: String
    var discount_convention: Int
    var inflation_approach: Int
    var real_discount_rate: Float64
    var nominal_discount_rate: Float64
    var inflation: Float64
    var base_date_month: Int
    var base_date_year: Int
    var service_date_month: Int
    var service_date_year: Int
    var length_study_years: Int
    var length_study_total_months: Int
    var tax_rate: Float64
    var depreciation_method: Int
    var last_date_year: Int
    var num_recurring_costs: Int
    var num_nonrecurring_cost: Int
    var num_use_price_escalation: Int
    var num_use_adjustment: Int
    var num_cash_flow: Int
    var num_resources_used: Int
    var get_input_lifecycle_cost_input: Bool
    var use_price_escalation_esc_start_year: Int
    var use_price_escalation_esc_num_years: Int
    var use_price_escalation_esc_end_year: Int
    var use_price_escalation_earlier_end_year: Int
    var use_price_escalation_later_start_year: Int
    var use_price_escalation_cur_esc: Int
    var use_price_escalation_cur_fld: Int
    var express_as_cashflows_base_months_1900: Int
    var express_as_cashflows_service_months_1900: Int
    var spv: DynamicVector[Float64]
    var energy_spv: OrderedDict[Int, DynamicVector[Float64]]
    var depreciated_capital: DynamicVector[Float64]
    var taxable_income: DynamicVector[Float64]
    var taxes: DynamicVector[Float64]
    var after_tax_cashflow: DynamicVector[Float64]
    var after_tax_present_value: DynamicVector[Float64]
    var escalated_tot_energy: DynamicVector[Float64]
    var escalated_energy: OrderedDict[Int, DynamicVector[Float64]]
    var recurring_costs: DynamicVector[RecurringCostsType]
    var nonrecurring_cost: DynamicVector[NonrecurringCostType]
    var use_price_escalation: DynamicVector[UsePriceEscalationType]
    var use_adjustment: DynamicVector[UseAdjustmentType]
    var cash_flow: DynamicVector[CashFlowType]

    fn __init__(inout self):
        self.lcc_param_present = False
        self.lcc_name = ""
        self.discount_convention = DiscConv.EndOfYear
        self.inflation_approach = InflAppr.ConstantDollar
        self.real_discount_rate = 0.0
        self.nominal_discount_rate = 0.0
        self.inflation = 0.0
        self.base_date_month = 0
        self.base_date_year = 0
        self.service_date_month = 0
        self.service_date_year = 0
        self.length_study_years = 0
        self.length_study_total_months = 0
        self.tax_rate = 0.0
        self.depreciation_method = DeprMethod.None_
        self.last_date_year = 0
        self.num_recurring_costs = 0
        self.num_nonrecurring_cost = 0
        self.num_use_price_escalation = 0
        self.num_use_adjustment = 0
        self.num_cash_flow = 0
        self.num_resources_used = 0
        self.get_input_lifecycle_cost_input = True
        self.use_price_escalation_esc_start_year = 0
        self.use_price_escalation_esc_num_years = 0
        self.use_price_escalation_esc_end_year = 0
        self.use_price_escalation_earlier_end_year = 0
        self.use_price_escalation_later_start_year = 0
        self.use_price_escalation_cur_esc = 0
        self.use_price_escalation_cur_fld = 0
        self.express_as_cashflows_base_months_1900 = 0
        self.express_as_cashflows_service_months_1900 = 0
        self.spv = DynamicVector[Float64]()
        self.energy_spv = OrderedDict[Int, DynamicVector[Float64]]()
        self.depreciated_capital = DynamicVector[Float64]()
        self.taxable_income = DynamicVector[Float64]()
        self.taxes = DynamicVector[Float64]()
        self.after_tax_cashflow = DynamicVector[Float64]()
        self.after_tax_present_value = DynamicVector[Float64]()
        self.escalated_tot_energy = DynamicVector[Float64]()
        self.escalated_energy = OrderedDict[Int, DynamicVector[Float64]]()
        self.recurring_costs = DynamicVector[RecurringCostsType]()
        self.nonrecurring_cost = DynamicVector[NonrecurringCostType]()
        self.use_price_escalation = DynamicVector[UsePriceEscalationType]()
        self.use_adjustment = DynamicVector[UseAdjustmentType]()
        self.cash_flow = DynamicVector[CashFlowType]()

fn depreciation_table_init() -> DynamicVector[DynamicVector[Float64]]:
    var table = DynamicVector[DynamicVector[Float64]]()
    var row0 = DynamicVector[Float64]()
    row0.push_back(33.33)
    row0.push_back(44.45)
    row0.push_back(14.81)
    row0.push_back(7.41)
    for _ in range(37):
        row0.push_back(0.0)
    table.push_back(row0)
    return table

fn get_input_for_life_cycle_cost(state: AnyType) -> None:
    pass

fn compute_life_cycle_cost_and_report(state: AnyType) -> None:
    pass

fn get_input_lifecycle_cost_parameters(state: AnyType) -> None:
    pass

fn get_input_lifecycle_cost_recurring_costs(state: AnyType) -> None:
    pass

fn get_input_lifecycle_cost_nonrecurring_cost(state: AnyType) -> None:
    pass

fn get_input_lifecycle_cost_use_price_escalation(state: AnyType) -> None:
    pass

fn get_input_lifecycle_cost_use_adjustment(state: AnyType) -> None:
    pass

fn express_as_cashflows(state: AnyType) -> None:
    pass

fn compute_escalated_energy_costs(state: AnyType) -> None:
    pass

fn compute_present_value(state: AnyType) -> None:
    pass

fn compute_tax_and_depreciation(state: AnyType) -> None:
    pass

fn write_tabular_life_cycle_cost_report(state: AnyType) -> None:
    pass
