from memory import DTypePointer, UnsafePointer
from algorithm import parallelize
import math

alias NUM_MONTHS = 12
alias MAX_NUM_BLK = 15
alias VAR_IS_ARGUMENT = 1
alias VAR_IS_ASSIGNED = 2
alias VAR_USER_DEFINED = -1
alias VAR_NOT_YET_DEFINED = -2

enum ObjType:
    INVALID = -1
    TARIFF = 0
    QUALIFY = 1
    CHARGE_SIMPLE = 2
    CHARGE_BLOCK = 3
    RATCHET = 4
    VARIABLE = 5
    COMPUTATION = 6
    CATEGORY = 7
    NATIVE = 8
    ASSIGN_COMPUTE = 9
    NUM = 10

enum EconConv:
    INVALID = -1
    USERDEF = 0
    KWH = 1
    THERM = 2
    MMBTU = 3
    MJ = 4
    KBTU = 5
    MCF = 6
    CCF = 7
    M3 = 8
    GAL = 9
    KGAL = 10
    NUM = 11

enum DemandWindow:
    INVALID = -1
    QUARTER = 0
    HALF = 1
    HOUR = 2
    DAY = 3
    WEEK = 4
    NUM = 5

enum BuySell:
    INVALID = -1
    BUY_FROM_UTILITY = 0
    SELL_TO_UTILITY = 1
    NET_METERING = 2
    NUM = 3

enum Season:
    INVALID = -1
    UNUSED = 0
    WINTER = 1
    SPRING = 2
    SUMMER = 3
    FALL = 4
    ANNUAL = 5
    MONTHLY = 6
    NUM = 7

enum Op:
    INVALID = -1
    SUM = 0
    MULTIPLY = 1
    SUBTRACT = 2
    DIVIDE = 3
    ABSOLUTEVALUE = 4
    INTEGER = 5
    SIGN = 6
    ROUND = 7
    MAXIMUM = 8
    MINIMUM = 9
    EXCEEDS = 10
    ANNUALMINIMUM = 11
    ANNUALMAXIMUM = 12
    ANNUALSUM = 13
    ANNUALAVERAGE = 14
    ANNUALOR = 15
    ANNUALAND = 16
    ANNUALMAXIMUMZERO = 17
    ANNUALMINIMUMZERO = 18
    IF = 19
    GREATERTHAN = 20
    GREATEREQUAL = 21
    LESSTHAN = 22
    LESSEQUAL = 23
    EQUAL = 24
    NOTEQUAL = 25
    AND = 26
    OR = 27
    NOT = 28
    ADD = 29
    NOOP = 30
    NUM = 31

enum Cat:
    INVALID = -1
    ENERGY_CHARGES = 0
    DEMAND_CHARGES = 1
    SERVICE_CHARGES = 2
    BASIS = 3
    ADJUSTMENT = 4
    SURCHARGE = 5
    SUBTOTAL = 6
    TAXES = 7
    TOTAL = 8
    NOT_INCLUDED = 9
    NUM = 10

enum Native:
    INVALID = -1
    TOTAL_ENERGY = 0
    TOTAL_DEMAND = 1
    PEAK_ENERGY = 2
    PEAK_DEMAND = 3
    SHOULDER_ENERGY = 4
    SHOULDER_DEMAND = 5
    OFFPEAK_ENERGY = 6
    OFFPEAK_DEMAND = 7
    MIDPEAK_ENERGY = 8
    MIDPEAK_DEMAND = 9
    PEAK_EXCEEDS_OFFPEAK = 10
    OFFPEAK_EXCEEDS_PEAK = 11
    PEAK_EXCEEDS_MIDPEAK = 12
    MIDPEAK_EXCEEDS_PEAK = 13
    PEAK_EXCEEDS_SHOULDER = 14
    SHOULDER_EXCEEDS_PEAK = 15
    IS_WINTER = 16
    IS_NOT_WINTER = 17
    IS_SPRING = 18
    IS_NOT_SPRING = 19
    IS_SUMMER = 20
    IS_NOT_SUMMER = 21
    IS_AUTUMN = 22
    IS_NOT_AUTUMN = 23
    PEAK_AND_SHOULDER_ENERGY = 24
    PEAK_AND_SHOULDER_DEMAND = 25
    PEAK_AND_MIDPEAK_ENERGY = 26
    PEAK_AND_MIDPEAK_DEMAND = 27
    SHOULDER_AND_OFFPEAK_ENERGY = 28
    SHOULDER_AND_OFFPEAK_DEMAND = 29
    PEAK_AND_OFFPEAK_ENERGY = 30
    PEAK_AND_OFFPEAK_DEMAND = 31
    REAL_TIME_PRICE_COSTS = 32
    ABOVE_CUSTOMER_BASE_COSTS = 33
    BELOW_CUSTOMER_BASE_COSTS = 34
    ABOVE_CUSTOMER_BASE_ENERGY = 35
    BELOW_CUSTOMER_BASE_ENERGY = 36
    NUM = 37

enum Period:
    INVALID = -1
    UNUSED = 0
    PEAK = 1
    SHOULDER = 2
    OFFPEAK = 3
    MIDPEAK = 4
    NUM = 5

enum MeterType:
    INVALID = -1
    ELEC_SIMPLE = 0
    ELEC_PRODUCED = 1
    ELEC_PURCHASED = 2
    ELEC_SURPLUS_SOLD = 3
    ELEC_NET = 4
    WATER = 5
    GAS = 6
    OTHER = 7
    NUM = 8

enum VarUnitType:
    INVALID = -1
    ENERGY = 0
    DEMAND = 1
    DIMENSIONLESS = 2
    CURRENCY = 3
    NUM = 4

enum StepType:
    OP = 0
    VAR = 1
    EOL = 2

struct Step:
    var step_type: StepType
    var op: Op
    var var_num: Int32

struct EconVarType:
    var name: String
    var tariff_indx: Int32
    var kind_of_obj: ObjType
    var index: Int32
    var values: InlineArray[Float64, NUM_MONTHS]
    var is_argument: Bool
    var is_assigned: Bool
    var specific: Int32
    var cnt_me_depend_on: Int32
    var operator: Op
    var first_operand: Int32
    var last_operand: Int32
    var active_now: Bool
    var is_evaluated: Bool
    var is_reported: Bool
    var var_unit_type: VarUnitType
    
    fn __init__(inout self):
        self.name = ""
        self.tariff_indx = 0
        self.kind_of_obj = ObjType.INVALID
        self.index = 0
        self.values = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.is_argument = False
        self.is_assigned = False
        self.specific = 0
        self.cnt_me_depend_on = 0
        self.operator = Op.INVALID
        self.first_operand = 0
        self.last_operand = 0
        self.active_now = False
        self.is_evaluated = False
        self.is_reported = False
        self.var_unit_type = VarUnitType.INVALID

struct TariffType:
    var tariff_name: String
    var report_meter: String
    var report_meter_indx: Int32
    var kind_mtr: MeterType
    var resource: Int32
    var conv_choice: EconConv
    var energy_conv: Float64
    var demand_conv: Float64
    var period_sched: UnsafePointer[UInt8]
    var season_sched: UnsafePointer[UInt8]
    var month_sched: UnsafePointer[UInt8]
    var demand_window: DemandWindow
    var dem_win_time: Float64
    var month_chg_val: Float64
    var month_chg_pt: Int32
    var min_month_chg_val: Float64
    var min_month_chg_pt: Int32
    var charge_sched: UnsafePointer[UInt8]
    var base_use_sched: UnsafePointer[UInt8]
    var group_name: String
    var monetary_unit: String
    var buy_or_sell: BuySell
    var first_category: Int32
    var last_category: Int32
    var cats: InlineArray[Int32, Int(Cat.NUM)]
    var first_native: Int32
    var last_native: Int32
    var natives: InlineArray[Int32, Int(Native.NUM)]
    var gather_energy: UnsafePointer[UInt8]
    var gather_demand: UnsafePointer[UInt8]
    var collect_time: Float64
    var collect_energy: Float64
    var rtp_cost: InlineArray[Float64, NUM_MONTHS]
    var rtp_above_base_cost: InlineArray[Float64, NUM_MONTHS]
    var rtp_below_base_cost: InlineArray[Float64, NUM_MONTHS]
    var rtp_above_base_energy: InlineArray[Float64, NUM_MONTHS]
    var rtp_below_base_energy: InlineArray[Float64, NUM_MONTHS]
    var season_for_month: InlineArray[Season, NUM_MONTHS]
    var is_qualified: Bool
    var pt_disqualifier: Int32
    var is_selected: Bool
    var total_annual_cost: Float64
    var total_annual_energy: Float64
    
    fn __init__(inout self):
        self.tariff_name = ""
        self.report_meter = ""
        self.report_meter_indx = 0
        self.kind_mtr = MeterType.INVALID
        self.resource = -1
        self.conv_choice = EconConv.USERDEF
        self.energy_conv = 0.0
        self.demand_conv = 0.0
        self.period_sched = UnsafePointer[UInt8]()
        self.season_sched = UnsafePointer[UInt8]()
        self.month_sched = UnsafePointer[UInt8]()
        self.demand_window = DemandWindow.INVALID
        self.dem_win_time = 0.0
        self.month_chg_val = 0.0
        self.month_chg_pt = 0
        self.min_month_chg_val = 0.0
        self.min_month_chg_pt = 0
        self.charge_sched = UnsafePointer[UInt8]()
        self.base_use_sched = UnsafePointer[UInt8]()
        self.group_name = ""
        self.monetary_unit = ""
        self.buy_or_sell = BuySell.INVALID
        self.first_category = 0
        self.last_category = 0
        self.cats = InlineArray[Int32, Int(Cat.NUM)](fill=0)
        self.first_native = 0
        self.last_native = 0
        self.natives = InlineArray[Int32, Int(Native.NUM)](fill=0)
        self.gather_energy = UnsafePointer[UInt8]()
        self.gather_demand = UnsafePointer[UInt8]()
        self.collect_time = 0.0
        self.collect_energy = 0.0
        self.rtp_cost = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.rtp_above_base_cost = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.rtp_below_base_cost = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.rtp_above_base_energy = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.rtp_below_base_energy = InlineArray[Float64, NUM_MONTHS](fill=0.0)
        self.season_for_month = InlineArray[Season, NUM_MONTHS](fill=Season.INVALID)
        self.is_qualified = False
        self.pt_disqualifier = 0
        self.is_selected = False
        self.total_annual_cost = 0.0
        self.total_annual_energy = 0.0

struct QualifyType:
    var name_pt: Int32
    var tariff_indx: Int32
    var source_pt: Int32
    var is_maximum: Bool
    var threshold_val: Float64
    var threshold_pt: Int32
    var season: Season
    var is_consecutive: Bool
    var number_of_months: Int32
    
    fn __init__(inout self):
        self.name_pt = 0
        self.tariff_indx = 0
        self.source_pt = 0
        self.is_maximum = False
        self.threshold_val = 0.0
        self.threshold_pt = 0
        self.season = Season.INVALID
        self.is_consecutive = False
        self.number_of_months = 0

struct ChargeSimpleType:
    var name_pt: Int32
    var tariff_indx: Int32
    var source_pt: Int32
    var season: Season
    var category_pt: Int32
    var cost_per_val: Float64
    var cost_per_pt: Int32
    
    fn __init__(inout self):
        self.name_pt = 0
        self.tariff_indx = 0
        self.source_pt = 0
        self.season = Season.INVALID
        self.category_pt = 0
        self.cost_per_val = 0.0
        self.cost_per_pt = 0

struct ChargeBlockType:
    var name_pt: Int32
    var tariff_indx: Int32
    var source_pt: Int32
    var season: Season
    var category_pt: Int32
    var remaining_pt: Int32
    var blk_sz_mult_val: Float64
    var blk_sz_mult_pt: Int32
    var num_blk: Int32
    var blk_sz_val: InlineArray[Float64, MAX_NUM_BLK]
    var blk_sz_pt: InlineArray[Int32, MAX_NUM_BLK]
    var blk_cost_val: InlineArray[Float64, MAX_NUM_BLK]
    var blk_cost_pt: InlineArray[Int32, MAX_NUM_BLK]
    
    fn __init__(inout self):
        self.name_pt = 0
        self.tariff_indx = 0
        self.source_pt = 0
        self.season = Season.INVALID
        self.category_pt = 0
        self.remaining_pt = 0
        self.blk_sz_mult_val = 0.0
        self.blk_sz_mult_pt = 0
        self.num_blk = 0
        self.blk_sz_val = InlineArray[Float64, MAX_NUM_BLK](fill=0.0)
        self.blk_sz_pt = InlineArray[Int32, MAX_NUM_BLK](fill=0)
        self.blk_cost_val = InlineArray[Float64, MAX_NUM_BLK](fill=0.0)
        self.blk_cost_pt = InlineArray[Int32, MAX_NUM_BLK](fill=0)

struct RatchetType:
    var name_pt: Int32
    var tariff_indx: Int32
    var baseline_pt: Int32
    var adjustment_pt: Int32
    var season_from: Season
    var season_to: Season
    var multiplier_val: Float64
    var multiplier_pt: Int32
    var offset_val: Float64
    var offset_pt: Int32
    
    fn __init__(inout self):
        self.name_pt = 0
        self.tariff_indx = 0
        self.baseline_pt = 0
        self.adjustment_pt = 0
        self.season_from = Season.INVALID
        self.season_to = Season.INVALID
        self.multiplier_val = 0.0
        self.multiplier_pt = 0
        self.offset_val = 0.0
        self.offset_pt = 0

struct ComputationType:
    var compute_name: String
    var first_step: Int32
    var last_step: Int32
    var is_user_def: Bool
    
    fn __init__(inout self):
        self.compute_name = ""
        self.first_step = 0
        self.last_step = 0
        self.is_user_def = False

struct StackType:
    var var_pt: Int32
    var values: InlineArray[Float64, NUM_MONTHS]
    
    fn __init__(inout self):
        self.var_pt = 0
        self.values = InlineArray[Float64, NUM_MONTHS](fill=0.0)

fn huge_value() -> Float64:
    return 1e30

fn initialize_monetary_unit(state: UnsafePointer[UInt8]) -> None:
    pass

fn update_utility_bills(state: UnsafePointer[UInt8]) -> None:
    pass

fn get_input_economics_tariff(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_qualify(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_charge_simple(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_charge_block(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_ratchet(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_variable(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_computation(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    pass

fn get_input_economics_currency_type(state: UnsafePointer[UInt8], inout errors_found: Bool) -> None:
    initialize_monetary_unit(state)

fn create_category_native_variables(state: UnsafePointer[UInt8]) -> None:
    pass

fn create_default_computation(state: UnsafePointer[UInt8]) -> None:
    pass

fn gather_for_economics(state: UnsafePointer[UInt8]) -> None:
    pass

fn compute_tariff(state: UnsafePointer[UInt8]) -> None:
    pass

fn select_tariff(state: UnsafePointer[UInt8]) -> None:
    pass

fn get_monthly_cost_for_resource(state: UnsafePointer[UInt8], resource_number: Int32) -> InlineArray[Float64, 12]:
    return InlineArray[Float64, 12](fill=0.0)
