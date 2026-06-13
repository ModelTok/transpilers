# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state param (contains dataOutputProcessor, dataGlobal, dataEnvrn, dataHVACGlobal, files, dataSysVars, dataSched, dataInputProcessing, dataStrGlobals, dataOutRptPredefined, dataResultsFramework, dataSQLiteProcedures)
# - Constant: Units, eResource, EndUse, HeatOrCool enums and name arrays
# - Sched: Schedule, GetSchedule, GetScheduleNum, dayTypeNames, schedule functions
# - Util: makeUPPER, SameString
# - General: DecodeMonDayHrMin, EncodeMonDayHrMin
# - DataOutputs: FindItemInVariableList, isKeyRegexLike
# - InputOutputFile: file I/O handles
# - OutputReportPredefined: PreDefTableEntry
# - ResultsFramework: resultsFramework, Meters, timeSeries
# - SQLiteProcedures: sqlite, SQL functions
# - ScheduleManager: schedule functions
# - UtilityRoutines: error reporting, print functions
# - RE2: regex pattern matching

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple, Any, Union
import re
from math import floor

# ============================================================================
# ENUMS
# ============================================================================

class ReportVDD(IntEnum):
    Invalid = -1
    No = 0
    Yes = 1
    IDF = 2
    Num = 3

class VariableType(IntEnum):
    Invalid = -1
    Integer = 0
    Real = 1
    Meter = 2
    Schedule = 3
    Num = 4

class MeterType(IntEnum):
    Invalid = -1
    Normal = 0
    Custom = 1
    CustomDec = 2
    CustomDiff = 3
    Num = 4

class RT_IPUnits(IntEnum):
    Invalid = -1
    OtherJ = 0
    Electricity = 1
    Gas = 2
    Cooling = 3
    Water = 4
    OtherKG = 5
    OtherM3 = 6
    OtherL = 7
    Num = 8

class ReportFreq(IntEnum):
    Invalid = -1
    EachCall = 0
    TimeStep = 1
    Hour = 2
    Day = 3
    Month = 4
    Simulation = 5
    Year = 6
    Num = 7

class StoreType(IntEnum):
    Invalid = -1
    Average = 0
    Sum = 1
    Num = 2

class TimeStepType(IntEnum):
    Invalid = -1
    Zone = 0
    System = 1
    Num = 2

class EndUseCat(IntEnum):
    Invalid = -1
    Heating = 0
    Cooling = 1
    InteriorLights = 2
    ExteriorLights = 3
    InteriorEquipment = 4
    ExteriorEquipment = 5
    Fans = 6
    Pumps = 7
    HeatRejection = 8
    Humidification = 9
    HeatRecovery = 10
    WaterSystem = 11
    Refrigeration = 12
    Cogeneration = 13
    Baseboard = 14
    Boilers = 15
    CarbonEquivalentEmissions = 16
    Chillers = 17
    CoalEmissions = 18
    ColdStorageCharge = 19
    ColdStorageDischarge = 20
    Condensate = 21
    CoolingCoils = 22
    CoolingPanel = 23
    DieselEmissions = 24
    DistrictChilledWater = 25
    DistrictHotWater = 26
    ElectricityEmissions = 27
    ElectricStorage = 28
    FreeCooling = 29
    FuelOilNo1Emissions = 30
    FuelOilNo2Emissions = 31
    GasolineEmissions = 32
    HeatingCoils = 33
    HeatProduced = 34
    HeatRecoveryForCooling = 35
    HeatRecoveryForHeating = 36
    LoopToLoop = 37
    MainsWater = 38
    NaturalGasEmissions = 39
    OtherFuel1Emissions = 40
    OtherFuel2Emissions = 41
    Photovoltaic = 42
    PowerConversion = 43
    PropaneEmissions = 44
    PurchasedElectricityEmissions = 45
    RainWater = 46
    SoldElectricityEmissions = 47
    WellWater = 48
    WindTurbine = 49
    Num = 50

class Group(IntEnum):
    Invalid = -1
    Building = 0
    HVAC = 1
    Plant = 2
    Zone = 3
    SpaceType = 4
    Num = 5

# ============================================================================
# CONSTANTS
# ============================================================================

MIN_SET_VALUE = 99999999999999.0
MAX_SET_VALUE = -99999999999999.0
I_MIN_SET_VALUE = 999999
I_MAX_SET_VALUE = -999999

N_WRITE_TIME_STAMP_FORMAT_DATA = 100

REPORT_FREQ_NAMES = (
    "Each Call", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Annual"
)

REPORT_FREQ_NAMES_UC = (
    "EACH CALL", "TIMESTEP", "HOURLY", "DAILY", "MONTHLY", "RUNPERIOD", "ANNUAL"
)

REPORT_FREQ_ARBITRARY_INTS = (1, 1, 1, 7, 9, 11, 11)

STORE_TYPE_NAMES = ("Average", "Sum")

TIME_STEP_TYPE_NAMES = ("Zone", "System")

END_USE_CAT_NAMES = (
    "Heating", "Cooling", "InteriorLights", "ExteriorLights", "InteriorEquipment",
    "ExteriorEquipment", "Fans", "Pumps", "HeatRejection", "Humidifier",
    "HeatRecovery", "WaterSystems", "Refrigeration", "Cogeneration", "Baseboard",
    "Boilers", "CarbonEquivalentEmissions", "Chillers", "CoalEmissions",
    "ColdStorageCharge", "ColdStorageDischarge", "Condensate", "CoolingCoils",
    "CoolingPanel", "DieselEmissions", "DistrictChilledWater", "DistrictHotWater",
    "ElectricityEmissions", "ElectricStorage", "FreeCooling", "FuelOilNo1Emissions",
    "FuelOilNo2Emissions", "GasolineEmissions", "HeatingCoils", "HeatProduced",
    "HeatRecoveryForCooling", "HeatRecoveryForHeating", "LoopToLoop", "MainsWater",
    "NaturalGasEmissions", "OtherFuel1Emissions", "OtherFuel2Emissions",
    "Photovoltaic", "PowerConversion", "PropaneEmissions", "PurchasedElectricityEmissions",
    "RainWater", "SoldElectricityEmissions", "WellWater", "WindTurbine"
)

END_USE_CAT_NAMES_UC = tuple(s.upper() for s in END_USE_CAT_NAMES)

GROUP_NAMES = ("Building", "HVAC", "Plant", "Zone", "SpaceType")

GROUP_NAMES_UC = ("BUILDING", "HVAC", "PLANT", "ZONE", "SPACETYPE")

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class TimeSteps:
    TimeStep: Optional[float] = None
    CurMinute: float = 0.0

@dataclass
class OutVar:
    ddVarNum: int = -1
    varType: VariableType = VariableType.Invalid
    timeStepType: TimeStepType = TimeStepType.Zone
    storeType: StoreType = StoreType.Average
    Value: float = 0.0
    TSValue: float = 0.0
    EITSValue: float = 0.0
    StoreValue: float = 0.0
    NumStored: float = 0.0
    Stored: bool = False
    Report: bool = False
    tsStored: bool = False
    thisTSStored: bool = False
    thisTSCount: int = 0
    freq: ReportFreq = ReportFreq.Hour
    MaxValue: float = -9999.0
    MinValue: float = 9999.0
    maxValueDate: int = 0
    minValueDate: int = 0
    ReportID: int = 0
    sched: Optional[Any] = None
    ZoneMult: int = 1
    ZoneListMult: int = 1
    
    keyColonName: str = ""
    keyColonNameUC: str = ""
    name: str = ""
    nameUC: str = ""
    key: str = ""
    keyUC: str = ""
    
    units: Any = None
    unitNameCustomEMS: str = ""
    
    indexGroup: str = ""
    indexGroupKey: int = -1
    
    meterNums: List[int] = field(default_factory=list)
    
    def multiplierString(self) -> str:
        if self.ZoneMult == 1 and self.ZoneListMult == 1:
            return ""
        mult = self.ZoneMult * self.ZoneListMult
        return f" * {mult}  (Zone Multiplier = {self.ZoneMult}, Zone List Multiplier = {self.ZoneListMult})"
    
    def writeReportData(self, state: Any) -> None:
        pass
    
    def writeOutput(self, state: Any, freq: ReportFreq) -> None:
        pass
    
    def writeReportDictionaryItem(self, state: Any) -> None:
        pass

@dataclass
class OutVarReal(OutVar):
    Which: Optional[float] = None
    
    def __post_init__(self):
        self.varType = VariableType.Real

@dataclass
class OutVarInt(OutVar):
    Which: Optional[int] = None
    
    def __post_init__(self):
        self.varType = VariableType.Integer

@dataclass
class DDOutVar:
    name: str = ""
    timeStepType: TimeStepType = TimeStepType.Invalid
    storeType: StoreType = StoreType.Invalid
    variableType: VariableType = VariableType.Invalid
    Next: int = -1
    ReportedOnDDFile: bool = False
    units: Any = None
    unitNameCustomEMS: str = ""
    keyOutVarNums: List[int] = field(default_factory=list)

@dataclass
class ReqVar:
    key: str = ""
    name: str = ""
    freq: ReportFreq = ReportFreq.Hour
    sched: Optional[Any] = None
    Used: bool = False
    is_simple_string: bool = True
    case_insensitive_pattern: Optional[Any] = None

@dataclass
class MeterPeriod:
    Value: float = 0.0
    MaxVal: float = MAX_SET_VALUE
    MaxValDate: int = -1
    MinVal: float = MIN_SET_VALUE
    MinValDate: int = -1
    
    Rpt: bool = False
    RptFO: bool = False
    RptNum: int = 0
    accRpt: bool = False
    accRptFO: bool = False
    accRptNum: int = 0
    
    def resetVals(self) -> None:
        self.Value = 0.0
        self.MaxVal = MAX_SET_VALUE
        self.MaxValDate = 0
        self.MinVal = MIN_SET_VALUE
        self.MinValDate = 0
    
    def WriteReportData(self, state: Any, freq: ReportFreq) -> None:
        pass

@dataclass
class Meter:
    Name: str = ""
    type: MeterType = MeterType.Invalid
    resource: Any = None
    endUseCat: EndUseCat = EndUseCat.Invalid
    EndUseSub: str = ""
    group: Group = Group.Invalid
    units: Any = None
    RT_forIPUnits: RT_IPUnits = RT_IPUnits.Invalid
    
    CurTSValue: float = 0.0
    indexGroup: str = ""
    
    periods: List[MeterPeriod] = field(default_factory=lambda: [MeterPeriod() for _ in range(int(ReportFreq.Num))])
    periodLastSM: MeterPeriod = field(default_factory=MeterPeriod)
    periodFinYrSM: MeterPeriod = field(default_factory=MeterPeriod)
    
    dstMeterNums: List[int] = field(default_factory=list)
    decMeterNum: int = -1
    srcVarNums: List[int] = field(default_factory=list)
    srcMeterNums: List[int] = field(default_factory=list)

@dataclass
class MeteredVar:
    num: int = -1
    name: str = ""
    resource: Any = None
    units: Any = None
    varType: VariableType = VariableType.Invalid
    timeStepType: TimeStepType = TimeStepType.Invalid
    endUseCat: EndUseCat = EndUseCat.Invalid
    group: Group = Group.Invalid
    rptNum: int = -1

@dataclass
class MeterData(MeteredVar):
    heatOrCool: Any = None
    curMeterReading: float = 0.0

@dataclass
class EndUseCategoryType:
    Name: str = ""
    DisplayName: str = ""
    NumSubcategories: int = 0
    SubcategoryName: List[str] = field(default_factory=list)
    numSpaceTypes: int = 0
    spaceTypeName: List[str] = field(default_factory=list)

@dataclass
class APIOutputVariableRequest:
    varName: str = ""
    varKey: str = ""

# ============================================================================
# FUNCTION IMPLEMENTATIONS
# ============================================================================

def determine_minute_for_reporting(state: Any) -> int:
    frac_to_min = 60.0
    return int((state.dataGlobal.CurrentTime + state.dataHVACGlobal.SysTimeElapsed - int(state.dataGlobal.CurrentTime)) * frac_to_min)

def initialize_output(state: Any) -> None:
    op = state.dataOutputProcessor
    op.EndUseCategory = [EndUseCategoryType() for _ in range(int(50))]
    for i in range(int(50)):
        op.EndUseCategory[i].Name = END_USE_CAT_NAMES[i]
        op.EndUseCategory[i].DisplayName = END_USE_CAT_NAMES[i]
    op.EndUseCategory[0].DisplayName = "Heating"
    op.EndUseCategory[1].DisplayName = "Cooling"
    op.EndUseCategory[2].DisplayName = "Interior Lighting"
    op.EndUseCategory[3].DisplayName = "Exterior Lighting"
    op.EndUseCategory[4].DisplayName = "Interior Equipment"
    op.EndUseCategory[5].DisplayName = "Exterior Equipment"
    op.EndUseCategory[6].DisplayName = "Fans"
    op.EndUseCategory[7].DisplayName = "Pumps"
    op.EndUseCategory[8].DisplayName = "Heat Rejection"
    op.EndUseCategory[9].DisplayName = "Humidification"
    op.EndUseCategory[10].DisplayName = "Heat Recovery"
    op.EndUseCategory[11].DisplayName = "Water Systems"
    op.EndUseCategory[12].DisplayName = "Refrigeration"
    op.EndUseCategory[13].DisplayName = "Generators"
    
    op.OutputInitialized = True
    op.TimeStepZoneSec = state.dataGlobal.MinutesInTimeStep * 60.0
    state.files.mtd.ensure_open(state, "InitializeMeters", state.files.outputControl.mtd)

def setup_time_pointers(state: Any, time_step: int, timestep_val: float) -> None:
    if state.dataOutputProcessor.TimeValue[time_step].TimeStep is not None:
        raise RuntimeError(f"SetupTimePointers already called for {TIME_STEP_TYPE_NAMES[time_step]}")
    state.dataOutputProcessor.TimeValue[time_step].TimeStep = timestep_val

def check_report_variable(state: Any, name: str, key: str, req_var_list: List[int]) -> None:
    get_report_variable_input(state)
    op = state.dataOutputProcessor
    name_upper = name.upper()
    
    for i, req_var in enumerate(op.reqVars):
        if req_var.name.upper() != name_upper:
            continue
        if req_var.key and not (req_var.is_simple_string and req_var.key.upper() == key.upper()):
            if not (not req_var.is_simple_string and req_var.case_insensitive_pattern and 
                    req_var.case_insensitive_pattern.match(key)):
                continue
        req_var.Used = True
        dup = False
        for j in req_var_list:
            if op.reqVars[j].freq == req_var.freq and op.reqVars[j].sched == req_var.sched:
                dup = True
                break
        if not dup:
            req_var_list.append(i)

def get_report_variable_input(state: Any) -> None:
    op = state.dataOutputProcessor
    if not op.GetOutputInputFlag:
        return
    op.GetOutputInputFlag = False
    
    if state.dataSysVars.MinReportFrequency:
        op.minimumReportFreq = determine_frequency(state, state.dataSysVars.MinReportFrequency)

def determine_frequency(state: Any, freq_string: str) -> ReportFreq:
    freq_upper = freq_string.upper()
    if len(freq_upper) < 4:
        return ReportFreq.Hour
    
    freq_trim = freq_upper[:4]
    possible = ["DETA", "TIME", "HOUR", "DAIL", "MONT", "RUNP", "ENVI", "ANNU"]
    values = [ReportFreq.EachCall, ReportFreq.TimeStep, ReportFreq.Hour, ReportFreq.Day,
              ReportFreq.Month, ReportFreq.Simulation, ReportFreq.Simulation, ReportFreq.Year]
    
    for i, p in enumerate(possible):
        if freq_trim == p:
            return max(values[i], state.dataOutputProcessor.minimumReportFreq)
    return ReportFreq.Hour

def produce_date_string(date: int, freq: ReportFreq) -> str:
    if date == 0:
        return "-"
    
    from GeneralModule import decode_mon_day_hr_min
    month, day, hour, minute = decode_mon_day_hr_min(date)
    
    if month < 1 or month > 12 or day < 1 or day > 31 or hour < 1 or hour > 24 or minute < 0 or minute > 60:
        return "-"
    
    hour -= 1
    if minute == 60:
        hour += 1
        minute = 0
    
    month_names = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    
    if freq == ReportFreq.Day:
        return f"{hour:2d},{minute:2d}"
    elif freq == ReportFreq.Month:
        return f"{day:2d},{hour:2d},{minute:2d}"
    elif freq == ReportFreq.Year or freq == ReportFreq.Simulation:
        return f"{month:2d},{day:2d},{hour:2d},{minute:2d}"
    return ""

def add_meter(state: Any, name: str, units: Any, resource: Any, end_use_cat: EndUseCat,
              end_use_sub: str, group: Group, out_var_num: int) -> int:
    op = state.dataOutputProcessor
    name_uc = name.upper()
    
    if name_uc in op.meterMap:
        return op.meterMap[name_uc]
    
    meter_num = len(op.meters)
    meter = Meter(Name=name)
    op.meters.append(meter)
    op.meterMap[name_uc] = meter_num
    
    meter.type = MeterType.Normal
    meter.resource = resource
    meter.endUseCat = end_use_cat
    meter.EndUseSub = end_use_sub
    meter.group = group
    meter.units = units
    meter.CurTSValue = 0.0
    
    for freq in [ReportFreq.TimeStep, ReportFreq.Hour, ReportFreq.Day, ReportFreq.Month, ReportFreq.Year, ReportFreq.Simulation]:
        op.ReportNumberCounter += 1
        meter.periods[int(freq)].RptNum = op.ReportNumberCounter
    
    for freq in [ReportFreq.TimeStep, ReportFreq.Hour, ReportFreq.Day, ReportFreq.Month, ReportFreq.Year, ReportFreq.Simulation]:
        op.ReportNumberCounter += 1
        meter.periods[int(freq)].accRptNum = op.ReportNumberCounter
    
    if meter.resource is not None:
        meter.RT_forIPUnits = get_resource_ip_units(state, meter.resource, units)
    
    if out_var_num != -1:
        op.outVars[out_var_num].meterNums.append(meter_num)
        meter.srcVarNums.append(out_var_num)
    
    return meter_num

def attach_meters(state: Any, units: Any, resource: Any, end_use_cat: EndUseCat,
                  end_use_sub: str, group: Group, zone_name: str, space_type_name: str,
                  rep_var_num: int) -> None:
    pass

def get_resource_ip_units(state: Any, resource: Any, units: Any) -> RT_IPUnits:
    return RT_IPUnits.OtherJ

def update_meters(state: Any, time_stamp: int) -> None:
    op = state.dataOutputProcessor
    if state.dataGlobal.WarmupFlag:
        return
    if not op.meters or not op.meterValues:
        return

def reset_accumulation_when_warmup_complete(state: Any) -> None:
    op = state.dataOutputProcessor
    for meter in op.meters:
        for i in range(int(ReportFreq.Hour), int(ReportFreq.Num)):
            meter.periods[i].resetVals()
        meter.periodFinYrSM.resetVals()

def setup_output_variable(state: Any, name: str, units: Any, actual_variable: float, 
                         time_step_type: TimeStepType, store_type: StoreType, key: str,
                         resource: Any = None, group: Group = Group.Invalid,
                         end_use_cat: EndUseCat = EndUseCat.Invalid, end_use_sub: str = "",
                         zone: str = "", zone_mult: int = 1, zone_list_mult: int = 1,
                         space_type: str = "", index_group_key: int = -999, 
                         custom_unit_name: str = "", report_freq: ReportFreq = ReportFreq.Hour) -> None:
    pass

def update_data_and_report(state: Any, time_step_type_key: TimeStepType) -> None:
    pass

def gen_output_variables_audit_report(state: Any) -> None:
    pass

def update_meter_reporting(state: Any) -> None:
    pass

def set_initial_meter_reporting_and_output_names(state: Any, which_meter: int, meter_file_only: bool,
                                                 freq: ReportFreq, cumulative: bool) -> None:
    pass

def get_meter_index(state: Any, name: str) -> int:
    op = state.dataOutputProcessor
    name_uc = name.upper()
    return op.meterMap.get(name_uc, -1)

def get_meter_resource_type(state: Any, meter_number: int) -> Any:
    if meter_number != -1:
        return state.dataOutputProcessor.meters[meter_number].resource
    return None

def get_current_meter_value(state: Any, meter_number: int) -> float:
    if meter_number != -1:
        return state.dataOutputProcessor.meters[meter_number].CurTSValue
    return 0.0

def get_internal_variable_value(state: Any, var_type: VariableType, key_var_index: int) -> float:
    op = state.dataOutputProcessor
    if var_type == VariableType.Invalid:
        return 0.0
    elif var_type == VariableType.Integer or var_type == VariableType.Real:
        if key_var_index < 0 or key_var_index >= len(op.outVars):
            return 0.0
        return float(op.outVars[key_var_index].Which or 0.0)
    elif var_type == VariableType.Meter:
        return get_current_meter_value(state, key_var_index)
    return 0.0

def add_dd_out_var(state: Any, name: str, time_step_type: TimeStepType, store_type: StoreType,
                   variable_type: VariableType, units: Any, custom_unit_name: str = "") -> int:
    op = state.dataOutputProcessor
    name_uc = name.upper()
    
    if name_uc not in op.ddOutVarMap:
        dd_var = DDOutVar(name=name, timeStepType=time_step_type, storeType=store_type,
                         variableType=variable_type, units=units)
        if custom_unit_name and units is not None:
            dd_var.unitNameCustomEMS = custom_unit_name
        op.ddOutVars.append(dd_var)
        op.ddOutVarMap[name_uc] = len(op.ddOutVars) - 1
        return len(op.ddOutVars) - 1
    
    return op.ddOutVarMap[name_uc]

def init_error_file(state: Any) -> int:
    return 0

def get_num_metered_variables(state: Any, component_type: str, component_name: str) -> int:
    op = state.dataOutputProcessor
    num_vars = 0
    for var in op.outVars:
        if var.varType != VariableType.Real:
            continue
        if component_name.upper() != var.keyUC:
            continue
        if var.meterNums:
            num_vars += 1
    return num_vars

def get_variable_key_count_and_type(state: Any, name: str) -> Tuple[int, VariableType, StoreType, TimeStepType, Any]:
    op = state.dataOutputProcessor
    name_uc = name.upper()
    
    if name_uc in op.ddOutVarMap:
        dd_var = op.ddOutVars[op.ddOutVarMap[name_uc]]
        return (len(dd_var.keyOutVarNums), dd_var.variableType, dd_var.storeType, dd_var.timeStepType, dd_var.units)
    
    if name_uc in op.meterMap:
        return (1, VariableType.Meter, StoreType.Sum, TimeStepType.Zone, None)
    
    return (0, VariableType.Invalid, StoreType.Average, TimeStepType.Zone, None)

def reporting_this_variable(state: Any, rep_var_name: str) -> bool:
    op = state.dataOutputProcessor
    name = rep_var_name.upper()
    
    for req_var in op.reqVars:
        if req_var.name.upper() == name:
            return True
    
    if name in op.meterMap:
        meter = op.meters[op.meterMap[name]]
        for i in range(int(ReportFreq.TimeStep), int(ReportFreq.Num)):
            if i == int(ReportFreq.Year):
                continue
            if meter.periods[i].Rpt or meter.periods[i].RptFO or meter.periods[i].accRpt or meter.periods[i].accRptFO:
                return True
    
    return False
