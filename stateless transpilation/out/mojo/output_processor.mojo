# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state param (contains dataOutputProcessor, dataGlobal, etc.)
# - Constant: Units, eResource, EndUse enums
# - Sched: Schedule struct and functions
# - Util: makeUPPER, SameString functions
# - General: DecodeMonDayHrMin, EncodeMonDayHrMin functions
# - DataOutputs: FindItemInVariableList, isKeyRegexLike functions
# - InputOutputFile: file I/O handles
# - OutputReportPredefined, ResultsFramework, SQLiteProcedures
# - Error/output functions: ShowWarningError, ShowFatalError, etc.
# - RE2: regex pattern matching

from collections import List, Dict
from math import floor

# ============================================================================
# ENUMS
# ============================================================================

struct ReportVDD:
    alias Invalid = -1
    alias No = 0
    alias Yes = 1
    alias IDF = 2
    alias Num = 3

struct VariableType:
    alias Invalid = -1
    alias Integer = 0
    alias Real = 1
    alias Meter = 2
    alias Schedule = 3
    alias Num = 4

struct MeterType:
    alias Invalid = -1
    alias Normal = 0
    alias Custom = 1
    alias CustomDec = 2
    alias CustomDiff = 3
    alias Num = 4

struct RT_IPUnits:
    alias Invalid = -1
    alias OtherJ = 0
    alias Electricity = 1
    alias Gas = 2
    alias Cooling = 3
    alias Water = 4
    alias OtherKG = 5
    alias OtherM3 = 6
    alias OtherL = 7
    alias Num = 8

struct ReportFreq:
    alias Invalid = -1
    alias EachCall = 0
    alias TimeStep = 1
    alias Hour = 2
    alias Day = 3
    alias Month = 4
    alias Simulation = 5
    alias Year = 6
    alias Num = 7

struct StoreType:
    alias Invalid = -1
    alias Average = 0
    alias Sum = 1
    alias Num = 2

struct TimeStepType:
    alias Invalid = -1
    alias Zone = 0
    alias System = 1
    alias Num = 2

struct EndUseCat:
    alias Invalid = -1
    alias Heating = 0
    alias Cooling = 1
    alias InteriorLights = 2
    alias ExteriorLights = 3
    alias InteriorEquipment = 4
    alias ExteriorEquipment = 5
    alias Fans = 6
    alias Pumps = 7
    alias HeatRejection = 8
    alias Humidification = 9
    alias HeatRecovery = 10
    alias WaterSystem = 11
    alias Refrigeration = 12
    alias Cogeneration = 13
    alias Baseboard = 14
    alias Boilers = 15
    alias CarbonEquivalentEmissions = 16
    alias Chillers = 17
    alias CoalEmissions = 18
    alias ColdStorageCharge = 19
    alias ColdStorageDischarge = 20
    alias Condensate = 21
    alias CoolingCoils = 22
    alias CoolingPanel = 23
    alias DieselEmissions = 24
    alias DistrictChilledWater = 25
    alias DistrictHotWater = 26
    alias ElectricityEmissions = 27
    alias ElectricStorage = 28
    alias FreeCooling = 29
    alias FuelOilNo1Emissions = 30
    alias FuelOilNo2Emissions = 31
    alias GasolineEmissions = 32
    alias HeatingCoils = 33
    alias HeatProduced = 34
    alias HeatRecoveryForCooling = 35
    alias HeatRecoveryForHeating = 36
    alias LoopToLoop = 37
    alias MainsWater = 38
    alias NaturalGasEmissions = 39
    alias OtherFuel1Emissions = 40
    alias OtherFuel2Emissions = 41
    alias Photovoltaic = 42
    alias PowerConversion = 43
    alias PropaneEmissions = 44
    alias PurchasedElectricityEmissions = 45
    alias RainWater = 46
    alias SoldElectricityEmissions = 47
    alias WellWater = 48
    alias WindTurbine = 49
    alias Num = 50

struct Group:
    alias Invalid = -1
    alias Building = 0
    alias HVAC = 1
    alias Plant = 2
    alias Zone = 3
    alias SpaceType = 4
    alias Num = 5

# ============================================================================
# CONSTANTS
# ============================================================================

alias MIN_SET_VALUE = 99999999999999.0
alias MAX_SET_VALUE = -99999999999999.0
alias I_MIN_SET_VALUE = 999999
alias I_MAX_SET_VALUE = -999999
alias N_WRITE_TIME_STAMP_FORMAT_DATA = 100

fn get_report_freq_names() -> List[StringRef]:
    var names = List[StringRef](7)
    names.append("Each Call")
    names.append("TimeStep")
    names.append("Hourly")
    names.append("Daily")
    names.append("Monthly")
    names.append("RunPeriod")
    names.append("Annual")
    return names

fn get_report_freq_names_uc() -> List[StringRef]:
    var names = List[StringRef](7)
    names.append("EACH CALL")
    names.append("TIMESTEP")
    names.append("HOURLY")
    names.append("DAILY")
    names.append("MONTHLY")
    names.append("RUNPERIOD")
    names.append("ANNUAL")
    return names

fn get_report_freq_arbitrary_ints() -> List[Int32]:
    var ints = List[Int32](7)
    ints.append(1)
    ints.append(1)
    ints.append(1)
    ints.append(7)
    ints.append(9)
    ints.append(11)
    ints.append(11)
    return ints

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@register_passable("trivial")
struct TimeSteps:
    var TimeStep: Float64
    var CurMinute: Float64
    
    fn __init__() -> Self:
        return Self(0.0, 0.0)

struct OutVar:
    var ddVarNum: Int32
    var varType: Int32
    var timeStepType: Int32
    var storeType: Int32
    var Value: Float64
    var TSValue: Float64
    var EITSValue: Float64
    var StoreValue: Float64
    var NumStored: Float64
    var Stored: Bool
    var Report: Bool
    var tsStored: Bool
    var thisTSStored: Bool
    var thisTSCount: Int32
    var freq: Int32
    var MaxValue: Float64
    var MinValue: Float64
    var maxValueDate: Int32
    var minValueDate: Int32
    var ReportID: Int32
    var sched: UnsafePointer[Unknown]
    var ZoneMult: Int32
    var ZoneListMult: Int32
    
    var keyColonName: String
    var keyColonNameUC: String
    var name: String
    var nameUC: String
    var key: String
    var keyUC: String
    
    var units: UnsafePointer[Unknown]
    var unitNameCustomEMS: String
    
    var indexGroup: String
    var indexGroupKey: Int32
    
    var meterNums: List[Int32]
    
    fn __init__() -> Self:
        return Self(
            ddVarNum=-1,
            varType=VariableType.Invalid,
            timeStepType=TimeStepType.Zone,
            storeType=StoreType.Average,
            Value=0.0,
            TSValue=0.0,
            EITSValue=0.0,
            StoreValue=0.0,
            NumStored=0.0,
            Stored=False,
            Report=False,
            tsStored=False,
            thisTSStored=False,
            thisTSCount=0,
            freq=ReportFreq.Hour,
            MaxValue=-9999.0,
            MinValue=9999.0,
            maxValueDate=0,
            minValueDate=0,
            ReportID=0,
            sched=UnsafePointer[Unknown](),
            ZoneMult=1,
            ZoneListMult=1,
            keyColonName="",
            keyColonNameUC="",
            name="",
            nameUC="",
            key="",
            keyUC="",
            units=UnsafePointer[Unknown](),
            unitNameCustomEMS="",
            indexGroup="",
            indexGroupKey=-1,
            meterNums=List[Int32]()
        )
    
    fn multiplierString(self) -> String:
        if self.ZoneMult == 1 and self.ZoneListMult == 1:
            return ""
        let mult = self.ZoneMult * self.ZoneListMult
        return String.format(" * {}  (Zone Multiplier = {}, Zone List Multiplier = {})", mult, self.ZoneMult, self.ZoneListMult)

struct OutVarReal(OutVar):
    var Which: Float64
    
    fn __init__() -> Self:
        var base = OutVar()
        base.varType = VariableType.Real
        return Self(base, 0.0)

struct OutVarInt(OutVar):
    var Which: Int32
    
    fn __init__() -> Self:
        var base = OutVar()
        base.varType = VariableType.Integer
        return Self(base, 0)

struct DDOutVar:
    var name: String
    var timeStepType: Int32
    var storeType: Int32
    var variableType: Int32
    var Next: Int32
    var ReportedOnDDFile: Bool
    var units: UnsafePointer[Unknown]
    var unitNameCustomEMS: String
    var keyOutVarNums: List[Int32]
    
    fn __init__() -> Self:
        return Self(
            name="",
            timeStepType=TimeStepType.Invalid,
            storeType=StoreType.Invalid,
            variableType=VariableType.Invalid,
            Next=-1,
            ReportedOnDDFile=False,
            units=UnsafePointer[Unknown](),
            unitNameCustomEMS="",
            keyOutVarNums=List[Int32]()
        )

struct ReqVar:
    var key: String
    var name: String
    var freq: Int32
    var sched: UnsafePointer[Unknown]
    var Used: Bool
    var is_simple_string: Bool
    var case_insensitive_pattern: UnsafePointer[Unknown]
    
    fn __init__() -> Self:
        return Self(
            key="",
            name="",
            freq=ReportFreq.Hour,
            sched=UnsafePointer[Unknown](),
            Used=False,
            is_simple_string=True,
            case_insensitive_pattern=UnsafePointer[Unknown]()
        )

struct MeterPeriod:
    var Value: Float64
    var MaxVal: Float64
    var MaxValDate: Int32
    var MinVal: Float64
    var MinValDate: Int32
    var Rpt: Bool
    var RptFO: Bool
    var RptNum: Int32
    var accRpt: Bool
    var accRptFO: Bool
    var accRptNum: Int32
    
    fn __init__() -> Self:
        return Self(
            Value=0.0,
            MaxVal=MAX_SET_VALUE,
            MaxValDate=-1,
            MinVal=MIN_SET_VALUE,
            MinValDate=-1,
            Rpt=False,
            RptFO=False,
            RptNum=0,
            accRpt=False,
            accRptFO=False,
            accRptNum=0
        )
    
    fn resetVals(mut self) -> None:
        self.Value = 0.0
        self.MaxVal = MAX_SET_VALUE
        self.MaxValDate = 0
        self.MinVal = MIN_SET_VALUE
        self.MinValDate = 0

struct Meter:
    var Name: String
    var type: Int32
    var resource: UnsafePointer[Unknown]
    var endUseCat: Int32
    var EndUseSub: String
    var group: Int32
    var units: UnsafePointer[Unknown]
    var RT_forIPUnits: Int32
    var CurTSValue: Float64
    var indexGroup: String
    var periods: List[MeterPeriod]
    var periodLastSM: MeterPeriod
    var periodFinYrSM: MeterPeriod
    var dstMeterNums: List[Int32]
    var decMeterNum: Int32
    var srcVarNums: List[Int32]
    var srcMeterNums: List[Int32]
    
    fn __init__(mut self, name: String) -> None:
        self.Name = name
        self.type = MeterType.Invalid
        self.resource = UnsafePointer[Unknown]()
        self.endUseCat = EndUseCat.Invalid
        self.EndUseSub = ""
        self.group = Group.Invalid
        self.units = UnsafePointer[Unknown]()
        self.RT_forIPUnits = RT_IPUnits.Invalid
        self.CurTSValue = 0.0
        self.indexGroup = ""
        self.periods = List[MeterPeriod](7)
        for _ in range(7):
            self.periods.append(MeterPeriod())
        self.periodLastSM = MeterPeriod()
        self.periodFinYrSM = MeterPeriod()
        self.dstMeterNums = List[Int32]()
        self.decMeterNum = -1
        self.srcVarNums = List[Int32]()
        self.srcMeterNums = List[Int32]()

struct MeteredVar:
    var num: Int32
    var name: String
    var resource: UnsafePointer[Unknown]
    var units: UnsafePointer[Unknown]
    var varType: Int32
    var timeStepType: Int32
    var endUseCat: Int32
    var group: Int32
    var rptNum: Int32
    
    fn __init__() -> Self:
        return Self(
            num=-1,
            name="",
            resource=UnsafePointer[Unknown](),
            units=UnsafePointer[Unknown](),
            varType=VariableType.Invalid,
            timeStepType=TimeStepType.Invalid,
            endUseCat=EndUseCat.Invalid,
            group=Group.Invalid,
            rptNum=-1
        )

struct MeterData(MeteredVar):
    var heatOrCool: UnsafePointer[Unknown]
    var curMeterReading: Float64
    
    fn __init__() -> Self:
        var base = MeteredVar()
        return Self(base, UnsafePointer[Unknown](), 0.0)

struct EndUseCategoryType:
    var Name: String
    var DisplayName: String
    var NumSubcategories: Int32
    var SubcategoryName: List[String]
    var numSpaceTypes: Int32
    var spaceTypeName: List[String]
    
    fn __init__() -> Self:
        return Self(
            Name="",
            DisplayName="",
            NumSubcategories=0,
            SubcategoryName=List[String](),
            numSpaceTypes=0,
            spaceTypeName=List[String]()
        )

struct APIOutputVariableRequest:
    var varName: String
    var varKey: String
    
    fn __init__() -> Self:
        return Self(varName="", varKey="")

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

fn determine_minute_for_reporting(state: UnsafePointer[Unknown]) -> Int32:
    let frac_to_min: Float64 = 60.0
    return Int32((state.dataGlobal.CurrentTime + state.dataHVACGlobal.SysTimeElapsed - 
                  Int32(state.dataGlobal.CurrentTime)) * frac_to_min)

fn initialize_output(state: UnsafePointer[Unknown]) -> None:
    pass

fn setup_time_pointers(state: UnsafePointer[Unknown], time_step_type: Int32, timestep: Float64) -> None:
    pass

fn check_report_variable(state: UnsafePointer[Unknown], name: String, key: String, 
                        req_var_list: UnsafePointer[List[Int32]]) -> None:
    pass

fn get_report_variable_input(state: UnsafePointer[Unknown]) -> None:
    pass

fn determine_frequency(state: UnsafePointer[Unknown], freq_string: String) -> Int32:
    let freq_upper = freq_string.upper()
    if len(freq_upper) < 4:
        return ReportFreq.Hour
    
    let freq_trim = freq_upper[0:4]
    let possible = ["DETA", "TIME", "HOUR", "DAIL", "MONT", "RUNP", "ENVI", "ANNU"]
    let values = [ReportFreq.EachCall, ReportFreq.TimeStep, ReportFreq.Hour, ReportFreq.Day,
                  ReportFreq.Month, ReportFreq.Simulation, ReportFreq.Simulation, ReportFreq.Year]
    
    for i in range(len(possible)):
        if freq_trim == possible[i]:
            return max(values[i], state.dataOutputProcessor.minimumReportFreq)
    
    return ReportFreq.Hour

fn produce_date_string(date: Int32, freq: Int32) -> String:
    if date == 0:
        return "-"
    
    return ""

fn get_custom_meter_input(state: UnsafePointer[Unknown]) -> Bool:
    return False

fn add_meter(state: UnsafePointer[Unknown], name: String, units: UnsafePointer[Unknown],
            resource: UnsafePointer[Unknown], end_use_cat: Int32, end_use_sub: String,
            group: Int32, out_var_num: Int32) -> Int32:
    return -1

fn attach_meters(state: UnsafePointer[Unknown], units: UnsafePointer[Unknown],
                resource: UnsafePointer[Unknown], end_use_cat: Int32, end_use_sub: String,
                group: Int32, zone_name: String, space_type_name: String,
                rep_var_num: Int32) -> None:
    pass

fn get_resource_ip_units(state: UnsafePointer[Unknown], resource: UnsafePointer[Unknown],
                        units: UnsafePointer[Unknown]) -> Int32:
    return RT_IPUnits.OtherJ

fn update_meters(state: UnsafePointer[Unknown], time_stamp: Int32) -> None:
    pass

fn reset_accumulation_when_warmup_complete(state: UnsafePointer[Unknown]) -> None:
    pass

fn update_data_and_report(state: UnsafePointer[Unknown], time_step_type_key: Int32) -> None:
    pass

fn gen_output_variables_audit_report(state: UnsafePointer[Unknown]) -> None:
    pass

fn update_meter_reporting(state: UnsafePointer[Unknown]) -> None:
    pass

fn set_initial_meter_reporting_and_output_names(state: UnsafePointer[Unknown], which_meter: Int32,
                                               meter_file_only: Bool, freq: Int32,
                                               cumulative: Bool) -> None:
    pass

fn get_meter_index(state: UnsafePointer[Unknown], name: String) -> Int32:
    return -1

fn get_meter_resource_type(state: UnsafePointer[Unknown], meter_number: Int32) -> UnsafePointer[Unknown]:
    return UnsafePointer[Unknown]()

fn get_current_meter_value(state: UnsafePointer[Unknown], meter_number: Int32) -> Float64:
    if meter_number != -1:
        return state.dataOutputProcessor.meters[meter_number].CurTSValue
    return 0.0

fn get_internal_variable_value(state: UnsafePointer[Unknown], var_type: Int32, 
                              key_var_index: Int32) -> Float64:
    if var_type == VariableType.Invalid:
        return 0.0
    return 0.0

fn get_num_metered_variables(state: UnsafePointer[Unknown], component_type: String,
                            component_name: String) -> Int32:
    return 0

fn add_dd_out_var(state: UnsafePointer[Unknown], name: String, time_step_type: Int32,
                 store_type: Int32, variable_type: Int32, units: UnsafePointer[Unknown],
                 custom_unit_name: String = "") -> Int32:
    return -1

fn init_error_file(state: UnsafePointer[Unknown]) -> Int32:
    return 0

fn reporting_this_variable(state: UnsafePointer[Unknown], rep_var_name: String) -> Bool:
    return False
