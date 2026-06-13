from enum import IntEnum, auto
from dataclasses import dataclass, field
from typing import List, Optional, Protocol, Any
from array import array
import math

# Constants
NUM_MONTHS = 12
MAX_NUM_BLK = 15

# Variable usage flags
VAR_IS_ARGUMENT = 1
VAR_IS_ASSIGNED = 2

# Variable definition status
VAR_USER_DEFINED = -1
VAR_NOT_YET_DEFINED = -2

# Enums
class ObjType(IntEnum):
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

class EconConv(IntEnum):
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

class DemandWindow(IntEnum):
    INVALID = -1
    QUARTER = 0
    HALF = 1
    HOUR = 2
    DAY = 3
    WEEK = 4
    NUM = 5

class BuySell(IntEnum):
    INVALID = -1
    BUY_FROM_UTILITY = 0
    SELL_TO_UTILITY = 1
    NET_METERING = 2
    NUM = 3

class Season(IntEnum):
    INVALID = -1
    UNUSED = 0
    WINTER = 1
    SPRING = 2
    SUMMER = 3
    FALL = 4
    ANNUAL = 5
    MONTHLY = 6
    NUM = 7

class Op(IntEnum):
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

class Cat(IntEnum):
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

class Native(IntEnum):
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

class Period(IntEnum):
    INVALID = -1
    UNUSED = 0
    PEAK = 1
    SHOULDER = 2
    OFFPEAK = 3
    MIDPEAK = 4
    NUM = 5

class MeterType(IntEnum):
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

class VarUnitType(IntEnum):
    INVALID = -1
    ENERGY = 0
    DEMAND = 1
    DIMENSIONLESS = 2
    CURRENCY = 3
    NUM = 4

class StepType(IntEnum):
    OP = 0
    VAR = 1
    EOL = 2

# String arrays for conversions
CONV_ENERGY_STRINGS = ["", "kWh", "Therm", "MMBtu", "MJ", "kBTU", "MCF", "CCF", "m3", "gal", "kgal"]
CONV_DEMAND_STRINGS = ["", "kW", "Therm", "MMBtu", "MJ", "kBTU", "MCF", "CCF", "m3", "gal", "kgal"]
ECON_CONV_NAMES_UC = ["USERDEFINED", "KWH", "THERM", "MMBTU", "MJ", "KBTU", "MCF", "CCF", "M3", "GAL", "KGAL"]

DEMAND_WINDOW_STRINGS = ["/Hr", "/Hr", "/Hr", "/Day", "/Wk"]
BUY_SELL_NAMES = ["BuyFromUtility", "SellToUtility", "NetMetering"]
BUY_SELL_NAMES_UC = ["BUYFROMUTILITY", "SELLTOUTILITY", "NETMETERING"]

SEASON_NAMES = ["Unused", "Winter", "Spring", "Summer", "Fall", "Annual", "Monthly"]
SEASON_NAMES_UC = ["UNUSED", "WINTER", "SPRING", "SUMMER", "FALL", "ANNUAL", "MONTHLY"]

OP_NAMES_UC = [
    "SUM", "MULTIPLY", "SUBTRACT", "DIVIDE", "ABSOLUTE", "INTEGER", "SIGN", "ROUND",
    "MAXIMUM", "MINIMUM", "EXCEEDS", "ANNUALMINIMUM", "ANNUALMAXIMUM", "ANNUALSUM",
    "ANNUALAVERAGE", "ANNUALOR", "ANNUALAND", "ANNUALMAXIMUMZERO", "ANNUALMINIMUMZERO",
    "IF", "GREATERTHAN", "GREATEREQUAL", "LESSTHAN", "LESSEQUAL", "EQUAL", "NOTEQUAL",
    "AND", "OR", "NOT", "ADD", "FROM"
]

OP_NAMES2_UC = [
    "SUM", "MULT", "SUBT", "DIV", "ABS", "INT", "SIGN", "ROUND", "MAX", "MIN", "EXCEEDS",
    "ANMIN", "ANMAX", "ANSUM", "ANAVG", "ANOR", "ANAND", "ANMAXZ", "ANMINZ", "IF", "GT",
    "GE", "LT", "LE", "EQ", "NE", "AND", "OR", "NOT", "ADD", "NOOP"
]

CAT_NAMES = [
    "EnergyCharges", "DemandCharges", "ServiceCharges", "Basis", "Adjustment",
    "Surcharge", "Subtotal", "Taxes", "Total", "NotIncluded"
]

CAT_NAMES_UC = [
    "ENERGYCHARGES", "DEMANDCHARGES", "SERVICECHARGES", "BASIS", "ADJUSTMENT",
    "SURCHARGE", "SUBTOTAL", "TAXES", "TOTAL", "NOTINCLUDED"
]

NATIVE_NAMES = [
    "TotalEnergy", "TotalDemand", "PeakEnergy", "PeakDemand", "ShoulderEnergy",
    "ShoulderDemand", "OffPeakEnergy", "OffPeakDemand", "MidPeakEnergy", "MidPeakDemand",
    "PeakExceedsOffPeak", "OffPeakExceedsPeak", "PeakExceedsMidPeak", "MidPeakExceedsPeak",
    "PeakExceedsShoulder", "ShoulderExceedsPeak", "IsWinter", "IsNotWinter", "IsSpring",
    "IsNotSpring", "IsSummer", "IsNotSummer", "IsAutumn", "IsNotAutumn",
    "PeakAndShoulderEnergy", "PeakAndShoulderDemand", "PeakAndMidPeakEnergy",
    "PeakAndMidPeakDemand", "ShoulderAndOffPeakEnergy", "ShoulderAndOffPeakDemand",
    "PeakAndOffPeakEnergy", "PeakAndOffPeakDemand", "RealTimePriceCosts",
    "AboveCustomerBaseCosts", "BelowCustomerBaseCosts", "AboveCustomerBaseEnergy",
    "BelowCustomerBaseEnergy"
]

NATIVE_NAMES_UC = [
    "TOTALENERGY", "TOTALDEMAND", "PEAKENERGY", "PEAKDEMAND", "SHOULDERENERGY",
    "SHOULDERDEMAND", "OFFPEAKENERGY", "OFFPEAKDEMAND", "MIDPEAKENERGY", "MIDPEAKDEMAND",
    "PEAKEXCEEDSOFFPEAK", "OFFPEAKEXCEEDSPEAK", "PEAKEXCEEDSMIDPEAK", "MIDPEAKEXCEEDSPEAK",
    "PEAKEXCEEDSSHOULDER", "SHOULDEREXCEEDSPEAK", "ISWINTER", "ISNOTWINTER", "ISSPRING",
    "ISNOTSPRING", "ISSUMMER", "ISNOTSUMMER", "ISAUTUMN", "ISNOTAUTUMN",
    "PEAKANDSHOULDERENERGY", "PEAKANDSHOULDERDEMAND", "PEAKANDMIDPEAKENERGY",
    "PEAKANDMIDPEAKDEMAND", "SHOULDERANDOFFPEAKENERGY", "SHOULDERANDOFFPEAKDEMAND",
    "PEAKANDOFFPEAKENERGY", "PEAKANDOFFPEAKDEMAND", "REALTIMEPRICECOSTS",
    "ABOVECUSTOMERBASECOSTS", "BELOWCUSTOMERBASECOSTS", "ABOVECUSTOMERBASEENERGY",
    "BELOWCUSTOMERBASEENERGY"
]

VAR_UNIT_TYPE_NAMES_UC = ["ENERGY", "DEMAND", "DIMENSIONLESS", "CURRENCY"]

YES_NO_NAMES = ["No", "Yes"]

@dataclass
class Step:
    type: StepType = StepType.EOL
    op: Op = Op.INVALID
    var_num: int = 0

@dataclass
class EconVarType:
    name: str = ""
    tariff_indx: int = 0
    kind_of_obj: ObjType = ObjType.INVALID
    index: int = 0
    values: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    is_argument: bool = False
    is_assigned: bool = False
    specific: int = 0
    cnt_me_depend_on: int = 0
    operator: Op = Op.INVALID
    first_operand: int = 0
    last_operand: int = 0
    active_now: bool = False
    is_evaluated: bool = False
    is_reported: bool = False
    var_unit_type: VarUnitType = VarUnitType.INVALID

@dataclass
class TariffType:
    tariff_name: str = ""
    report_meter: str = ""
    report_meter_indx: int = 0
    kind_mtr: MeterType = MeterType.INVALID
    resource: int = -1
    conv_choice: EconConv = EconConv.USERDEF
    energy_conv: float = 0.0
    demand_conv: float = 0.0
    period_sched: Optional[Any] = None
    season_sched: Optional[Any] = None
    month_sched: Optional[Any] = None
    demand_window: DemandWindow = DemandWindow.INVALID
    dem_win_time: float = 0.0
    month_chg_val: float = 0.0
    month_chg_pt: int = 0
    min_month_chg_val: float = 0.0
    min_month_chg_pt: int = 0
    charge_sched: Optional[Any] = None
    base_use_sched: Optional[Any] = None
    group_name: str = ""
    monetary_unit: str = ""
    buy_or_sell: BuySell = BuySell.INVALID
    first_category: int = 0
    last_category: int = 0
    cats: List[int] = field(default_factory=lambda: [0] * int(Cat.NUM))
    first_native: int = 0
    last_native: int = 0
    natives: List[int] = field(default_factory=lambda: [0] * int(Native.NUM))
    gather_energy: List[List[float]] = field(default_factory=lambda: [[0.0] * int(Period.NUM) for _ in range(NUM_MONTHS)])
    gather_demand: List[List[float]] = field(default_factory=lambda: [[0.0] * int(Period.NUM) for _ in range(NUM_MONTHS)])
    collect_time: float = 0.0
    collect_energy: float = 0.0
    rtp_cost: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    rtp_above_base_cost: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    rtp_below_base_cost: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    rtp_above_base_energy: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    rtp_below_base_energy: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)
    season_for_month: List[Season] = field(default_factory=lambda: [Season.INVALID] * NUM_MONTHS)
    is_qualified: bool = False
    pt_disqualifier: int = 0
    is_selected: bool = False
    total_annual_cost: float = 0.0
    total_annual_energy: float = 0.0

@dataclass
class QualifyType:
    name_pt: int = 0
    tariff_indx: int = 0
    source_pt: int = 0
    is_maximum: bool = False
    threshold_val: float = 0.0
    threshold_pt: int = 0
    season: Season = Season.INVALID
    is_consecutive: bool = False
    number_of_months: int = 0

@dataclass
class ChargeSimpleType:
    name_pt: int = 0
    tariff_indx: int = 0
    source_pt: int = 0
    season: Season = Season.INVALID
    category_pt: int = 0
    cost_per_val: float = 0.0
    cost_per_pt: int = 0

@dataclass
class ChargeBlockType:
    name_pt: int = 0
    tariff_indx: int = 0
    source_pt: int = 0
    season: Season = Season.INVALID
    category_pt: int = 0
    remaining_pt: int = 0
    blk_sz_mult_val: float = 0.0
    blk_sz_mult_pt: int = 0
    num_blk: int = 0
    blk_sz_val: List[float] = field(default_factory=lambda: [0.0] * MAX_NUM_BLK)
    blk_sz_pt: List[int] = field(default_factory=lambda: [0] * MAX_NUM_BLK)
    blk_cost_val: List[float] = field(default_factory=lambda: [0.0] * MAX_NUM_BLK)
    blk_cost_pt: List[int] = field(default_factory=lambda: [0] * MAX_NUM_BLK)

@dataclass
class RatchetType:
    name_pt: int = 0
    tariff_indx: int = 0
    baseline_pt: int = 0
    adjustment_pt: int = 0
    season_from: Season = Season.INVALID
    season_to: Season = Season.INVALID
    multiplier_val: float = 0.0
    multiplier_pt: int = 0
    offset_val: float = 0.0
    offset_pt: int = 0

@dataclass
class ComputationType:
    compute_name: str = ""
    first_step: int = 0
    last_step: int = 0
    is_user_def: bool = False

@dataclass
class StackType:
    var_pt: int = 0
    values: List[float] = field(default_factory=lambda: [0.0] * NUM_MONTHS)

def get_enum_value(names_uc: List[str], text: str) -> int:
    """Helper to find enum value from uppercase names list."""
    text_upper = text.upper()
    try:
        return names_uc.index(text_upper)
    except ValueError:
        return -1

def same_string(s1: str, s2: str) -> bool:
    """Case-insensitive string comparison."""
    return s1.upper() == s2.upper()

def process_number(text: str, is_not_numeric: List[bool]) -> float:
    """Parse number from text, set flag if not numeric."""
    try:
        is_not_numeric[0] = False
        return float(text)
    except ValueError:
        is_not_numeric[0] = True
        return 0.0

def has_i(text: str, substr: str) -> bool:
    """Case-insensitive contains."""
    return substr.upper() in text.upper()

def len_str(s: Optional[str]) -> int:
    """Safe string length."""
    return len(s) if s else 0

def huge_value() -> float:
    """Return a huge number."""
    return 1e30

def initialize_monetary_unit(state: Any) -> None:
    """Initialize monetary unit data."""
    num_monetary_unit = 111
    state.dataCostEstimateManager = type('obj', (object,), {
        'monetaryUnit': [type('obj', (object,), {'code': '', 'txt': '', 'html': ''})() for _ in range(num_monetary_unit)],
        'selectedMonetaryUnit': 0
    })()
    
    currencies = [
        ("USD", "$", "$"), ("AFN", "AFN", "&#x060b;"), ("ALL", "Lek", "Lek"),
        ("ANG", "ANG", "&#x0192;"), ("ARS", "$", "$"), ("AUD", "$", "$"),
        ("AWG", "AWG", "&#x0192;"), ("AZN", "AZN", "&#x043c;&#x0430;&#x043d;"),
        ("BAM", "KM", "KM"), ("BBD", "$", "$"), ("BGN", "BGN", "&#x043b;&#x0432;"),
        ("BMD", "$", "$"), ("BND", "$", "$"), ("BOB", "$b", "$b"),
        ("BRL", "R$", "R$"), ("BSD", "$", "$"), ("BWP", "P", "P"),
        ("BYR", "p.", "p."), ("BZD", "BZ$", "BZ$"), ("CAD", "$", "$"),
        ("CHF", "CHF", "CHF"), ("CLP", "$", "$"), ("CNY", "CNY", "&#x5143;"),
        ("COP", "$", "$"), ("CRC", "CRC", "&#x20a1;"), ("CUP", "CUP", "&#x20b1;"),
        ("CZK", "CZK", "&#x004b;&#x010d;"), ("DKK", "kr", "kr"), ("DOP", "RD$", "RD$"),
        ("EEK", "kr", "kr"), ("EGP", "£", "£"), ("EUR", "EUR", "&#x20ac;"),
        ("FJD", "$", "$"), ("GBP", "£", "£"), ("GHC", "¢", "¢"),
        ("GIP", "£", "£"), ("GTQ", "Q", "Q"), ("GYD", "$", "$"),
        ("HKD", "HK$", "HK$"), ("HNL", "L", "L"), ("HRK", "kn", "kn"),
        ("HUF", "Ft", "Ft"), ("IDR", "Rp", "Rp"), ("ILS", "ILS", "&#x20aa;"),
        ("IMP", "£", "£"), ("INR", "INR", "&#x20a8;"), ("IRR", "IRR", "&#xfdfc;"),
        ("ISK", "kr", "kr"), ("JEP", "£", "£"), ("JMD", "J$", "J$"),
        ("JPY", "¥", "¥"), ("KGS", "KGS", "&#x043b;&#x0432;"), ("KHR", "KHR", "&#x17db;"),
        ("KPW", "KPW", "&#x20a9;"), ("KRW", "KRW", "&#x20a9;"), ("KYD", "$", "$"),
        ("KZT", "KZT", "&#x043b;&#x0432;"), ("LAK", "LAK", "&#x20ad;"), ("LBP", "£", "£"),
        ("LKR", "LKR", "&#x20a8;"), ("LRD", "$", "$"), ("LTL", "Lt", "Lt"),
        ("LVL", "Ls", "Ls"), ("MKD", "MKD", "&#x0434;&#x0435;&#x043d;"), ("MNT", "MNT", "&#x20ae;"),
        ("MUR", "MUR", "&#x20a8;"), ("MXN", "$", "$"), ("MYR", "RM", "RM"),
        ("MZN", "MT", "MT"), ("NAD", "$", "$"), ("NGN", "NGN", "&#x20a6;"),
        ("NIO", "C$", "C$"), ("NOK", "kr", "kr"), ("NPR", "NPR", "&#x20a8;"),
        ("NZD", "$", "$"), ("OMR", "OMR", "&#xfdfc;"), ("PAB", "B/.", "B/."),
        ("PEN", "S/.", "S/."), ("PHP", "Php", "Php"), ("PKR", "PKR", "&#x20a8;"),
        ("PLN", "PLN", "&#x007a;&#x0142;"), ("PYG", "Gs", "Gs"), ("QAR", "QAR", "&#xfdfc;"),
        ("RON", "lei", "lei"), ("RSD", "RSD", "&#x0414;&#x0438;&#x043d;&#x002e;"),
        ("RUB", "RUB", "&#x0440;&#x0443;&#x0431;"), ("SAR", "SAR", "&#xfdfc;"),
        ("SBD", "$", "$"), ("SCR", "SCR", "&#x20a8;"), ("SEK", "kr", "kr"),
        ("SGD", "$", "$"), ("SHP", "£", "£"), ("SOS", "S", "S"),
        ("SRD", "$", "$"), ("SVC", "$", "$"), ("SYP", "£", "£"),
        ("THB", "THB", "&#x0e3f;"), ("TRL", "TRL", "&#x20a4;"), ("TRY", "YTL", "YTL"),
        ("TTD", "TT$", "TT$"), ("TVD", "$", "$"), ("TWD", "NT$", "NT$"),
        ("UAH", "UAH", "&#x20b4;"), ("UYU", "$U", "$U"), ("UZS", "UZS", "&#x043b;&#x0432;"),
        ("VEF", "Bs", "Bs"), ("VND", "VND", "&#x20ab;"), ("XCD", "$", "$"),
        ("YER", "YER", "&#xfdfc;"), ("ZAR", "R", "R"), ("ZWD", "Z$", "Z$"),
    ]
    
    for i, (code, txt, html) in enumerate(currencies):
        if i < num_monetary_unit:
            state.dataCostEstimateManager.monetaryUnit[i].code = code
            state.dataCostEstimateManager.monetaryUnit[i].txt = txt
            state.dataCostEstimateManager.monetaryUnit[i].html = html

def update_utility_bills(state: Any) -> None:
    """Main entry point for economics calculations."""
    s_econ = state.dataEconTariff
    
    if s_econ.update_get_input:
        errors_found = False
        
        get_input_economics_tariff(state, errors_found)
        get_input_economics_currency_type(state, errors_found)
        
        if s_econ.num_tariff >= 1:
            if not errors_found:
                pass
            create_category_native_variables(state)
            get_input_economics_qualify(state, errors_found)
            get_input_economics_charge_simple(state, errors_found)
            get_input_economics_charge_block(state, errors_found)
            get_input_economics_ratchet(state, errors_found)
            get_input_economics_variable(state, errors_found)
            get_input_economics_computation(state, errors_found)
            create_default_computation(state)
        
        s_econ.update_get_input = False
        
        if errors_found:
            raise RuntimeError("UpdateUtilityBills: Preceding errors cause termination.")
    
    if state.dataGlobal.do_output_reporting:
        gather_for_economics(state)

def get_input_economics_tariff(state: Any, errors_found: bool) -> None:
    """Get tariff input."""
    pass

def get_input_economics_qualify(state: Any, errors_found: bool) -> None:
    """Get qualify input."""
    pass

def get_input_economics_charge_simple(state: Any, errors_found: bool) -> None:
    """Get charge simple input."""
    pass

def get_input_economics_charge_block(state: Any, errors_found: bool) -> None:
    """Get charge block input."""
    pass

def get_input_economics_ratchet(state: Any, errors_found: bool) -> None:
    """Get ratchet input."""
    pass

def get_input_economics_variable(state: Any, errors_found: bool) -> None:
    """Get variable input."""
    pass

def get_input_economics_computation(state: Any, errors_found: bool) -> None:
    """Get computation input."""
    pass

def get_input_economics_currency_type(state: Any, errors_found: bool) -> None:
    """Get currency type input."""
    initialize_monetary_unit(state)
    state.dataCostEstimateManager.selectedMonetaryUnit = 1

def create_category_native_variables(state: Any) -> None:
    """Create category and native variables."""
    pass

def create_default_computation(state: Any) -> None:
    """Create default computation steps."""
    pass

def gather_for_economics(state: Any) -> None:
    """Gather economic data for timestep."""
    pass

def compute_tariff(state: Any) -> None:
    """Compute tariff costs."""
    pass

def select_tariff(state: Any) -> None:
    """Select lowest cost tariff."""
    pass

def get_monthly_cost_for_resource(state: Any, resource_number: int) -> List[float]:
    """Get monthly costs for a resource."""
    return [0.0] * 12
