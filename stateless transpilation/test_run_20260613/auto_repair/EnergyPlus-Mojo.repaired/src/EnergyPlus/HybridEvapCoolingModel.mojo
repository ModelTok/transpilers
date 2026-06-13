from math import abs, max, min
from builtin import String, List, Bool, Float64, Int, Enum, NoneType
from CurveManager import CurveValue, GetCurveIndex, GetCurveMinMaxValues
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import OutBaroPress, StdRhoAir
from DataHVACGlobals import TimeStepSysSec, SysTimeElapsed
from General import ShowSevereError, ShowContinueError, ShowWarningError
from Psychrometrics import PsyRhFnTdbWPb, PsyWFnTdbRhPb, PsyHFnTdbW, PsyCpAirFnW, PsyHfgAirFnWTdb
from ScheduleManager import Schedule
from UtilityRoutines import assert  # Not sure about assert, but keep
from SystemAvailabilityManager import Avail
from Constant import eFuel
from DataGlobals import HourOfDay, TimeStep, TimeStepZone, DayOfSim, WarmupFlag

const MINIMUM_LOAD_TO_ACTIVATE: Float64 = 0.5
const IMPLAUSIBLE_POWER: Float64 = 10000000
const DEF_Tdb: Int = 0
const DEF_RH: Int = 1
const TEMP_CURVE: Int = 0
const W_CURVE: Int = 1
const POWER_CURVE: Int = 2
const SUPPLY_FAN_POWER: Int = 3
const EXTERNAL_STATIC_PRESSURE: Int = 4
const SECOND_FUEL_USE: Int = 5
const THIRD_FUEL_USE: Int = 6
const WATER_USE: Int = 7

@value
enum SYSTEMOUTPUTS: Int32:
    Invalid = -1
    VENTILATION_AIR_V = 0
    SUPPLY_MASS_FLOW = 1
    SYSTEM_FUEL_USE = 2
    SUPPLY_AIR_TEMP = 3
    MIXED_AIR_TEMP = 4
    SUPPLY_AIR_HR = 5
    MIXED_AIR_HR = 6
    OSUPPLY_FAN_POWER = 7
    OSECOND_FUEL_USE = 8
    OTHIRD_FUEL_USE = 9
    OWATER_USE = 10
    OEXTERNAL_STATIC_PRESSURE = 11
    Num = 12

@value
enum ObjectiveFunctionType: Int32:
    Invalid = -1
    ElectricityUse = 0
    SecondFuelUse = 1
    ThirdFuelUse = 2
    WaterUse = 3
    Num = 4

var objectiveFunctionNamesUC: StaticArray[String, ObjectiveFunctionType.Num.value()] = StaticArray(
    "ELECTRICITY USE",
    "SECOND FUEL USE",
    "THIRD FUEL USE",
    "WATER USE"
)

struct CModeSolutionSpace:
    var MassFlowRatio: List[Float64] = List[Float64]()
    var OutdoorAirFraction: List[Float64] = List[Float64]()

struct CMode:
    var ModeID: Int = 0
    var sol: CModeSolutionSpace = CModeSolutionSpace()
    var ModeName: String = ""
    var Tsa_curve_pointer: Int = -1
    var HRsa_curve_pointer: Int = -1
    var Psa_curve_pointer: Int = -1
    var SFPsa_curve_pointer: Int = -1
    var ESPsa_curve_pointer: Int = -1
    var SFUsa_curve_pointer: Int = -1
    var TFUsa_curve_pointer: Int = -1
    var WUsa_curve_pointer: Int = -1
    var Max_Msa: Float64 = 0.0
    var Min_Msa: Float64 = 0.0
    var Min_OAF: Float64 = 0.0
    var Max_OAF: Float64 = 0.0
    var Minimum_Outdoor_Air_Temperature: Float64 = 0.0
    var Maximum_Outdoor_Air_Temperature: Float64 = 0.0
    var Minimum_Outdoor_Air_Temperature_Blank: Bool = False
    var Maximum_Outdoor_Air_Temperature_Blank: Bool = False
    var Minimum_Outdoor_Air_Humidity_Ratio: Float64 = 0.0
    var Maximum_Outdoor_Air_Humidity_Ratio: Float64 = 0.0
    var Minimum_Outdoor_Air_Relative_Humidity: Float64 = 0.0
    var Maximum_Outdoor_Air_Relative_Humidity: Float64 = 0.0
    var Minimum_Return_Air_Temperature: Float64 = 0.0
    var Maximum_Return_Air_Temperature: Float64 = 0.0
    var Minimum_Return_Air_Temperature_Blank: Bool = False
    var Maximum_Return_Air_Temperature_Blank: Bool = False
    var Minimum_Return_Air_Humidity_Ratio: Float64 = 0.0
    var Maximum_Return_Air_Humidity_Ratio: Float64 = 0.0
    var Minimum_Return_Air_Relative_Humidity: Float64 = 0.0
    var Maximum_Return_Air_Relative_Humidity: Float64 = 0.0
    var ModelScalingFactor: Float64 = 0.0
    var MODE_BLOCK_OFFSET_Alpha: Int = 9
    var BLOCK_HEADER_OFFSET_Alpha: Int = 20
    var MODE1_BLOCK_OFFSET_Number: Int = 2
    var MODE_BLOCK_OFFSET_Number: Int = 16
    var BLOCK_HEADER_OFFSET_Number: Int = 6

    def __init__(inout self):
        self.ModeID = 0
        self.Max_Msa = 0.0
        self.Min_Msa = 0.0
        self.Min_OAF = 0.0
        self.Max_OAF = 0.0
        self.Minimum_Outdoor_Air_Temperature = 0.0
        self.Maximum_Outdoor_Air_Temperature = 0.0
        self.Minimum_Outdoor_Air_Humidity_Ratio = 0.0
        self.Maximum_Outdoor_Air_Humidity_Ratio = 0.0
        self.ModelScalingFactor = 0.0
        self.MODE_BLOCK_OFFSET_Alpha = 9
        self.BLOCK_HEADER_OFFSET_Alpha = 20
        self.MODE1_BLOCK_OFFSET_Number = 2
        self.MODE_BLOCK_OFFSET_Number = 16
        self.BLOCK_HEADER_OFFSET_Number = 6

    def InitializeOutdoorAirTemperatureConstraints(inout self, min: Float64, max: Float64, minBlank: Bool, maxBlank: Bool):
        self.Minimum_Outdoor_Air_Temperature = min
        self.Maximum_Outdoor_Air_Temperature = max
        self.Minimum_Outdoor_Air_Temperature_Blank = minBlank
        self.Maximum_Outdoor_Air_Temperature_Blank = maxBlank

    def InitializeOutdoorAirHumidityRatioConstraints(inout self, min: Float64, max: Float64):
        self.Minimum_Outdoor_Air_Humidity_Ratio = min
        self.Maximum_Outdoor_Air_Humidity_Ratio = max

    def InitializeOutdoorAirRelativeHumidityConstraints(inout self, min: Float64, max: Float64):
        self.Minimum_Outdoor_Air_Relative_Humidity = min
        self.Maximum_Outdoor_Air_Relative_Humidity = max

    def InitializeReturnAirTemperatureConstraints(inout self, min: Float64, max: Float64, minBlank: Bool, maxBlank: Bool):
        self.Minimum_Return_Air_Temperature = min
        self.Maximum_Return_Air_Temperature = max
        self.Minimum_Return_Air_Temperature_Blank = minBlank
        self.Maximum_Return_Air_Temperature_Blank = maxBlank

    def InitializeReturnAirHumidityRatioConstraints(inout self, min: Float64, max: Float64):
        self.Minimum_Return_Air_Humidity_Ratio = min
        self.Maximum_Return_Air_Humidity_Ratio = max

    def InitializeReturnAirRelativeHumidityConstraints(inout self, min: Float64, max: Float64):
        self.Minimum_Return_Air_Relative_Humidity = min
        self.Maximum_Return_Air_Relative_Humidity = max

    def InitializeOSAFConstraints(inout self, minOSAF: Float64, maxOSAF: Float64):
        self.Min_OAF = minOSAF
        self.Max_OAF = maxOSAF

    def InitializeMsaRatioConstraints(inout self, minMsa: Float64, maxMsa: Float64):
        self.Min_Msa = minMsa
        self.Max_Msa = maxMsa

    def ValidPointer(self, curve_pointer: Int) -> Bool:
        if curve_pointer >= 0:
            return True
        return False

    def CalculateCurveVal(self, inout state: EnergyPlusData, Tosa: Float64, Wosa: Float64, Tra: Float64, Wra: Float64, Msa: Float64, OSAF: Float64, curveType: Int) -> Float64:
        var Y_val: Float64 = 0
        if curveType == TEMP_CURVE:
            if self.ValidPointer(self.Tsa_curve_pointer):
                Y_val = CurveValue(state, self.Tsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = Tra # return air temp
        elif curveType == W_CURVE:
            if self.ValidPointer(self.HRsa_curve_pointer):
                Y_val = CurveValue(state, self.HRsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
                Y_val = max(min(Y_val, 1.0), 0.0)
            else:
                Y_val = Wra # return HR
        elif curveType == POWER_CURVE:
            if self.ValidPointer(self.Psa_curve_pointer):
                Y_val = self.ModelScalingFactor * CurveValue(state, self.Psa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        elif curveType == SUPPLY_FAN_POWER:
            if self.ValidPointer(self.SFPsa_curve_pointer):
                Y_val = self.ModelScalingFactor * CurveValue(state, self.SFPsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        elif curveType == EXTERNAL_STATIC_PRESSURE:
            if self.ValidPointer(self.ESPsa_curve_pointer):
                Y_val = CurveValue(state, self.ESPsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        elif curveType == SECOND_FUEL_USE:
            if self.ValidPointer(self.SFUsa_curve_pointer):
                Y_val = self.ModelScalingFactor * CurveValue(state, self.SFUsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        elif curveType == THIRD_FUEL_USE:
            if self.ValidPointer(self.TFUsa_curve_pointer):
                Y_val = self.ModelScalingFactor * CurveValue(state, self.TFUsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        elif curveType == WATER_USE:
            if self.ValidPointer(self.WUsa_curve_pointer):
                Y_val = self.ModelScalingFactor * CurveValue(state, self.WUsa_curve_pointer, Tosa, Wosa, Tra, Wra, Msa, OSAF)
            else:
                Y_val = 0
        else:

        return Y_val

    def InitializeCurve(inout self, curveType: Int, curve_ID: Int):
        if curveType == TEMP_CURVE:
            self.Tsa_curve_pointer = curve_ID
        elif curveType == W_CURVE:
            self.HRsa_curve_pointer = curve_ID
        elif curveType == POWER_CURVE:
            self.Psa_curve_pointer = curve_ID
        elif curveType == SUPPLY_FAN_POWER:
            self.SFPsa_curve_pointer = curve_ID
        elif curveType == EXTERNAL_STATIC_PRESSURE:
            self.ESPsa_curve_pointer = curve_ID
        elif curveType == SECOND_FUEL_USE:
            self.SFUsa_curve_pointer = curve_ID
        elif curveType == THIRD_FUEL_USE:
            self.TFUsa_curve_pointer = curve_ID
        elif curveType == WATER_USE:
            self.WUsa_curve_pointer = curve_ID
        else:

    def GenerateSolutionSpace(inout self):
        if self.Min_Msa == self.Max_Msa:
            self.sol.MassFlowRatio.append(self.Max_Msa)
        else:
            var ResolutionMsa: Float64 = (self.Max_Msa - self.Min_Msa) * 0.2
            var Msa_val: Float64 = self.Max_Msa
            while Msa_val >= self.Min_Msa:
                self.sol.MassFlowRatio.append(Msa_val)
                Msa_val -= ResolutionMsa

        if self.Min_OAF == self.Max_OAF:
            self.sol.OutdoorAirFraction.append(self.Max_OAF)
        else:
            var ResolutionOSA: Float64 = (self.Max_OAF - self.Min_OAF) * 0.2
            var OAF_val: Float64 = self.Max_OAF
            while OAF_val >= self.Min_OAF:
                self.sol.OutdoorAirFraction.append(OAF_val)
                OAF_val -= ResolutionOSA

    def ParseMode(inout self, inout state: EnergyPlusData, ModeCounter: Int, inout OperatingModes: List[CMode], ScalingFactor: Float64, Alphas: List[String], cAlphaFields: List[String], Numbers: List[Float64], lAlphaBlanks: List[Bool], lNumericBlanks: List[Bool], cCurrentModuleObject: String) -> Bool:
        self.ModeID = ModeCounter
        self.ModelScalingFactor = ScalingFactor
        var inter_Number: Int = 0
        var ErrorsFound: Bool = False
        var inter_Alpha: Int = self.BLOCK_HEADER_OFFSET_Alpha + self.MODE_BLOCK_OFFSET_Alpha * self.ModeID
        if self.ModeID > 0:
            inter_Number = self.BLOCK_HEADER_OFFSET_Number + self.MODE1_BLOCK_OFFSET_Number + self.MODE_BLOCK_OFFSET_Number * (self.ModeID - 1)
        else:
            inter_Number = self.BLOCK_HEADER_OFFSET_Number + self.MODE1_BLOCK_OFFSET_Number
        # Note: indices are 1-based in C++, convert to 0-based
        var strs: String = String(self.ModeID)
        var curveID: Int = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.ModeName = "Mode" + strs
        else:
            self.ModeName = Alphas[inter_Alpha - 1]

        curveID = -1
        inter_Alpha = inter_Alpha + 1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(TEMP_CURVE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(TEMP_CURVE, -1)
            else:
                self.InitializeCurve(TEMP_CURVE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(W_CURVE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(W_CURVE, -1)
            else:
                self.InitializeCurve(W_CURVE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(POWER_CURVE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(POWER_CURVE, -1)
            else:
                self.InitializeCurve(POWER_CURVE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(SUPPLY_FAN_POWER, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(SUPPLY_FAN_POWER, -1)
            else:
                self.InitializeCurve(SUPPLY_FAN_POWER, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(EXTERNAL_STATIC_PRESSURE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(EXTERNAL_STATIC_PRESSURE, -1)
            else:
                self.InitializeCurve(EXTERNAL_STATIC_PRESSURE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(SECOND_FUEL_USE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(SECOND_FUEL_USE, -1)
            else:
                self.InitializeCurve(SECOND_FUEL_USE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(THIRD_FUEL_USE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(THIRD_FUEL_USE, -1)
            else:
                self.InitializeCurve(THIRD_FUEL_USE, curveID)

        inter_Alpha = inter_Alpha + 1
        curveID = -1
        if lAlphaBlanks[inter_Alpha - 1]:
            self.InitializeCurve(WATER_USE, curveID)
        else:
            curveID = GetCurveIndex(state, Alphas[inter_Alpha - 1])
            if curveID == 0:
                ShowSevereError(state, String.format("Invalid {}={}", cAlphaFields[inter_Alpha - 1], Alphas[inter_Alpha - 1]))
                ShowContinueError(state, String.format("Entered in {}", cCurrentModuleObject))
                ErrorsFound = True
                self.InitializeCurve(WATER_USE, -1)
            else:
                self.InitializeCurve(WATER_USE, curveID)

        if self.ModeID == 0:
            OperatingModes.append(self)
            return ErrorsFound

        self.InitializeOutdoorAirTemperatureConstraints(
            Numbers[inter_Number - 1], Numbers[inter_Number], lNumericBlanks[inter_Number - 1], lNumericBlanks[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeOutdoorAirHumidityRatioConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeOutdoorAirRelativeHumidityConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeReturnAirTemperatureConstraints(
            Numbers[inter_Number - 1], Numbers[inter_Number], lNumericBlanks[inter_Number - 1], lNumericBlanks[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeReturnAirHumidityRatioConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeReturnAirRelativeHumidityConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeOSAFConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        inter_Number = inter_Number + 2
        self.InitializeMsaRatioConstraints(Numbers[inter_Number - 1], Numbers[inter_Number])
        OperatingModes.append(self)
        return ErrorsFound

    def MeetsConstraints(self, Tosa: Float64, Wosa: Float64, RHosa: Float64, Tra: Float64, Wra: Float64, RHra: Float64) -> Bool:
        var OATempConstraintMet: Bool = (self.Minimum_Outdoor_Air_Temperature_Blank or Tosa >= self.Minimum_Outdoor_Air_Temperature) and \
                                        (self.Maximum_Outdoor_Air_Temperature_Blank or Tosa <= self.Maximum_Outdoor_Air_Temperature)
        var OAHRConstraintMet: Bool = (Wosa >= self.Minimum_Outdoor_Air_Humidity_Ratio and Wosa <= self.Maximum_Outdoor_Air_Humidity_Ratio)
        var OARHConstraintMet: Bool = (RHosa >= self.Minimum_Outdoor_Air_Relative_Humidity and RHosa <= self.Maximum_Outdoor_Air_Relative_Humidity)
        var RATempConstraintMet: Bool = (self.Minimum_Return_Air_Temperature_Blank or Tra >= self.Minimum_Return_Air_Temperature) and \
                                        (self.Maximum_Return_Air_Temperature_Blank or Tra <= self.Maximum_Return_Air_Temperature)
        var RAHRConstraintMet: Bool = (Wra >= self.Minimum_Return_Air_Humidity_Ratio and Wra <= self.Maximum_Return_Air_Humidity_Ratio)
        var RARHConstraintMet: Bool = (RHra >= self.Minimum_Return_Air_Relative_Humidity and RHra <= self.Maximum_Return_Air_Relative_Humidity)
        return OATempConstraintMet and OAHRConstraintMet and OARHConstraintMet and RATempConstraintMet and RAHRConstraintMet and RARHConstraintMet

struct CSetting:
    var Runtime_Fraction: Float64 = 0
    var Mode: Float64 = 0
    var Outdoor_Air_Fraction: Float64 = 0
    var Unscaled_Supply_Air_Mass_Flow_Rate: Float64 = 0
    var ScaledSupply_Air_Mass_Flow_Rate: Float64 = 0
    var Supply_Air_Ventilation_Volume: Float64 = 0
    var ScaledSupply_Air_Ventilation_Volume: Float64 = 0
    var Supply_Air_Mass_Flow_Rate_Ratio: Float64 = 0
    var SupplyAirTemperature: Float64 = 0
    var Mixed_Air_Temperature: Float64 = 0
    var SupplyAirW: Float64 = 0
    var Mixed_Air_W: Float64 = 0
    var TotalSystem: Float64 = 0
    var SensibleSystem: Float64 = 0
    var LatentSystem: Float64 = 0
    var TotalZone: Float64 = 0
    var SensibleZone: Float64 = 0
    var LatentZone: Float64 = 0
    var ElectricalPower: Float64 = IMPLAUSIBLE_POWER
    var SupplyFanElectricPower: Float64 = 0
    var SecondaryFuelConsumptionRate: Float64 = 0
    var ThirdFuelConsumptionRate: Float64 = 0
    var WaterConsumptionRate: Float64 = 0
    var ExternalStaticPressure: Float64 = 0
    var oMode: CMode = CMode()

    def __init__(inout self):
        self.Runtime_Fraction = 0
        self.Mode = 0
        self.Outdoor_Air_Fraction = 0
        self.Unscaled_Supply_Air_Mass_Flow_Rate = 0
        self.ScaledSupply_Air_Mass_Flow_Rate = 0
        self.Supply_Air_Ventilation_Volume = 0
        self.ScaledSupply_Air_Ventilation_Volume = 0
        self.Supply_Air_Mass_Flow_Rate_Ratio = 0
        self.SupplyAirTemperature = 0
        self.Mixed_Air_Temperature = 0
        self.SupplyAirW = 0
        self.Mixed_Air_W = 0
        self.TotalSystem = 0
        self.SensibleSystem = 0
        self.LatentSystem = 0
        self.TotalZone = 0
        self.SensibleZone = 0
        self.LatentZone = 0
        self.ElectricalPower = IMPLAUSIBLE_POWER
        self.SupplyFanElectricPower = 0
        self.SecondaryFuelConsumptionRate = 0
        self.ThirdFuelConsumptionRate = 0
        self.WaterConsumptionRate = 0
        self.ExternalStaticPressure = 0

struct CStepInputs:
    var Tosa: Float64 = 0
    var Tra: Float64 = 0
    var RHosa: Float64 = 0
    var RHra: Float64 = 0
    var RequestedCoolingLoad: Float64 = 0
    var RequestedHeatingLoad: Float64 = 0
    var ZoneMoistureLoad: Float64 = 0
    var ZoneDehumidificationLoad: Float64 = 0
    var MinimumOA: Float64 = 0

    def __init__(inout self):
        self.Tosa = 0
        self.Tra = 0
        self.RHosa = 0
        self.RHra = 0
        self.RequestedCoolingLoad = 0
        self.RequestedHeatingLoad = 0
        self.ZoneMoistureLoad = 0
        self.ZoneDehumidificationLoad = 0
        self.MinimumOA = 0

struct Model:
    var Name: String = ""
    var Initialized: Bool = False
    var ZoneNum: Int = 0
    var availSched: Schedule = None  # will be assigned later
    var ZoneNodeNum: Int = 0
    var AvailManagerListName: String = ""
    var availStatus: Avail.Status = Avail.Status.NoAction
    var SystemMaximumSupplyAirFlowRate: Float64 = 0.0
    var FanHeatGain: Bool = False
    var FanHeatGainLocation: String = ""
    var FanHeatInAirFrac: Float64 = 0.0
    var ScalingFactor: Float64 = 0.0
    var ScaledSystemMaximumSupplyAirMassFlowRate: Float64 = 0.0
    var ScaledSystemMaximumSupplyAirVolumeFlowRate: Float64 = 0.0
    var firstFuel: eFuel = eFuel.Invalid
    var secondFuel: eFuel = eFuel.Invalid
    var thirdFuel: eFuel = eFuel.Invalid
    var ObjectiveFunction: ObjectiveFunctionType = ObjectiveFunctionType.ElectricityUse
    var UnitOn: Int = 0
    var UnitTotalCoolingRate: Float64 = 0.0
    var UnitTotalCoolingEnergy: Float64 = 0.0
    var UnitSensibleCoolingRate: Float64 = 0.0
    var UnitSensibleCoolingEnergy: Float64 = 0.0
    var UnitLatentCoolingRate: Float64 = 0.0
    var UnitLatentCoolingEnergy: Float64 = 0.0
    var SystemTotalCoolingRate: Float64 = 0.0
    var SystemTotalCoolingEnergy: Float64 = 0.0
    var SystemSensibleCoolingRate: Float64 = 0.0
    var SystemSensibleCoolingEnergy: Float64 = 0.0
    var SystemLatentCoolingRate: Float64 = 0.0
    var SystemLatentCoolingEnergy: Float64 = 0.0
    var UnitTotalHeatingRate: Float64 = 0.0
    var UnitTotalHeatingEnergy: Float64 = 0.0
    var UnitSensibleHeatingRate: Float64 = 0.0
    var UnitSensibleHeatingEnergy: Float64 = 0.0
    var UnitLatentHeatingRate: Float64 = 0.0
    var UnitLatentHeatingEnergy: Float64 = 0.0
    var SystemTotalHeatingRate: Float64 = 0.0
    var SystemTotalHeatingEnergy: Float64 = 0.0
    var SystemSensibleHeatingRate: Float64 = 0.0
    var SystemSensibleHeatingEnergy: Float64 = 0.0
    var SystemLatentHeatingRate: Float64 = 0.0
    var SystemLatentHeatingEnergy: Float64 = 0.0
    var SupplyFanElectricPower: Float64 = 0.0
    var SupplyFanElectricEnergy: Float64 = 0.0
    var SecondaryFuelConsumptionRate: Float64 = 0.0
    var SecondaryFuelConsumption: Float64 = 0.0
    var ThirdFuelConsumptionRate: Float64 = 0.0
    var ThirdFuelConsumption: Float64 = 0.0
    var WaterConsumptionRate: Float64 = 0.0
    var WaterConsumption: Float64 = 0.0
    var QSensZoneOut: Float64 = 0.0
    var QLatentZoneOut: Float64 = 0.0
    var QLatentZoneOutMass: Float64 = 0.0
    var ExternalStaticPressure: Float64 = 0.0
    var RequestedHumidificationMass: Float64 = 0.0
    var RequestedHumidificationLoad: Float64 = 0.0
    var RequestedHumidificationEnergy: Float64 = 0.0
    var RequestedDeHumidificationMass: Float64 = 0.0
    var RequestedDeHumidificationLoad: Float64 = 0.0
    var RequestedDeHumidificationEnergy: Float64 = 0.0
    var RequestedLoadToHeatingSetpoint: Float64 = 0.0
    var RequestedLoadToCoolingSetpoint: Float64 = 0.0
    var TsaMinSched: Schedule = None
    var TsaMaxSched: Schedule = None
    var RHsaMinSched: Schedule = None
    var RHsaMaxSched: Schedule = None
    var PrimaryMode: Int = 0
    var PrimaryModeRuntimeFraction: Float64 = 0.0
    var averageOSAF: Float64 = 0.0
    var ErrorCode: Int = 0
    var StandBy: Bool = False
    var InletNode: Int = 0
    var OutletNode: Int = 0
    var SecondaryInletNode: Int = 0
    var SecondaryOutletNode: Int = 0
    var FinalElectricalPower: Float64 = 0.0
    var FinalElectricalEnergy: Float64 = 0.0
    var InletMassFlowRate: Float64 = 0.0
    var InletVolumetricFlowRate: Float64 = 0.0
    var InletTemp: Float64 = 0.0
    var InletWetBulbTemp: Float64 = 0.0
    var InletHumRat: Float64 = 0.0
    var InletEnthalpy: Float64 = 0.0
    var InletPressure: Float64 = 0.0
    var InletRH: Float64 = 0.0
    var OutletVolumetricFlowRate: Float64 = 0.0
    var OutletMassFlowRate: Float64 = 0.0
    var PowerLossToAir: Float64 = 0.0
    var FanHeatTemp: Float64 = 0.0
    var OutletTemp: Float64 = 0.0
    var OutletWetBulbTemp: Float64 = 0.0
    var OutletHumRat: Float64 = 0.0
    var OutletEnthalpy: Float64 = 0.0
    var OutletPressure: Float64 = 0.0
    var OutletRH: Float64 = 0.0
    var SecInletMassFlowRate: Float64 = 0.0
    var SecInletTemp: Float64 = 0.0
    var SecInletWetBulbTemp: Float64 = 0.0
    var SecInletHumRat: Float64 = 0.0
    var SecInletEnthalpy: Float64 = 0.0
    var SecInletPressure: Float64 = 0.0
    var SecInletRH: Float64 = 0.0
    var SecOutletVolumetricFlowRate: Float64 = 0.0
    var SecOutletMassFlowRate: Float64 = 0.0
    var SecOutletTemp: Float64 = 0.0
    var SecOutletWetBulbTemp: Float64 = 0.0
    var SecOutletHumRat: Float64 = 0.0
    var SecOutletEnthalpy: Float64 = 0.0
    var SecOutletPressure: Float64 = 0.0
    var SecOutletRH: Float64 = 0.0
    var Wsa: Float64 = 0.0
    var SupplyVentilationAir: Float64 = 0.0
    var SupplyVentilationVolume: Float64 = 0.0
    var OutdoorAir: Bool = False
    var MinOA_Msa: Float64 = 0.0
    var OARequirementsPtr: Int = 0
    var Tsa: Float64 = 0.0
    var ModeCounter: Int = 0
    var CoolingRequested: Bool = False
    var HeatingRequested: Bool = False
    var VentilationRequested: Bool = False
    var DehumidificationRequested: Bool = False
    var HumidificationRequested: Bool = False
    var Tsa_curve_pointer: List[Int] = List[Int]()
    var HRsa_curve_pointer: List[Int] = List[Int]()
    var Psa_curve_pointer: List[Int] = List[Int]()
    var OperatingModes: List[CMode] = List[CMode]()
    var CurrentOperatingSettings: List[CSetting] = List[CSetting]()
    var OptimalSetting: CSetting = CSetting()
    var oStandBy: CSetting = CSetting()
    var Settings: List[CSetting] = List[CSetting]()
    var SAT_OC_MetinMode_v: List[Int] = List[Int]()
    var SAHR_OC_MetinMode_v: List[Int] = List[Int]()
    var WarnOnceFlag: Bool = False
    var count_EnvironmentConditionsNotMet: Int = 0
    var count_EnvironmentConditionsMetOnce: Int = 0
    var count_SAHR_OC_MetOnce: Int = 0
    var count_SAT_OC_MetOnce: Int = 0
    var count_DidWeMeetLoad: Int = 0
    var count_DidWeNotMeetLoad: Int = 0
    var optimal_EnvCondMet: Bool = False
    var RunningPeakCapacity_EnvCondMet: Bool = False
    var PolygonXs: List[Float64] = List[Float64]()
    var PolygonYs: List[Float64] = List[Float64]()

    def __init__(inout self):
        self.Initialized = False
        self.ZoneNum = 0
        self.SystemMaximumSupplyAirFlowRate = 0.0
        self.ScalingFactor = 0.0
        self.ScaledSystemMaximumSupplyAirMassFlowRate = 0.0
        self.UnitOn = 0
        self.UnitTotalCoolingRate = 0.0
        self.UnitTotalCoolingEnergy = 0.0
        self.UnitSensibleCoolingRate = 0.0
        self.UnitSensibleCoolingEnergy = 0.0
        self.UnitLatentCoolingRate = 0.0
        self.UnitLatentCoolingEnergy = 0.0
        self.SystemTotalCoolingRate = 0.0
        self.SystemTotalCoolingEnergy = 0.0
        self.SystemSensibleCoolingRate = 0.0
        self.SystemSensibleCoolingEnergy = 0.0
        self.SystemLatentCoolingRate = 0.0
        self.SystemLatentCoolingEnergy = 0.0
        self.UnitTotalHeatingRate = 0.0
        self.UnitTotalHeatingEnergy = 0.0
        self.UnitSensibleHeatingRate = 0.0
        self.UnitSensibleHeatingEnergy = 0.0
        self.UnitLatentHeatingRate = 0.0
        self.UnitLatentHeatingEnergy = 0.0
        self.SystemTotalHeatingRate = 0.0
        self.SystemTotalHeatingEnergy = 0.0
        self.SystemSensibleHeatingRate = 0.0
        self.SystemSensibleHeatingEnergy = 0.0
        self.SystemLatentHeatingRate = 0.0
        self.SystemLatentHeatingEnergy = 0.0
        self.SupplyFanElectricPower = 0.0
        self.SupplyFanElectricEnergy = 0.0
        self.SecondaryFuelConsumptionRate = 0.0
        self.SecondaryFuelConsumption = 0.0
        self.ThirdFuelConsumptionRate = 0.0
        self.ThirdFuelConsumption = 0.0
        self.WaterConsumptionRate = 0.0
        self.WaterConsumption = 0.0
        self.QSensZoneOut = 0.0
        self.QLatentZoneOut = 0.0
        self.QLatentZoneOutMass = 0.0
        self.ExternalStaticPressure = 0.0
        self.RequestedHumidificationMass = 0.0
        self.RequestedHumidificationLoad = 0.0
        self.RequestedHumidificationEnergy = 0.0
        self.RequestedDeHumidificationMass = 0.0
        self.RequestedDeHumidificationLoad = 0.0
        self.RequestedDeHumidificationEnergy = 0.0
        self.RequestedLoadToHeatingSetpoint = 0.0
        self.RequestedLoadToCoolingSetpoint = 0.0
        self.PrimaryMode = 0
        self.PrimaryModeRuntimeFraction = 0.0
        self.averageOSAF = 0.0
        self.ErrorCode = 0
        self.InletNode = 0
        self.OutletNode = 0
        self.SecondaryInletNode = 0
        self.SecondaryOutletNode = 0
        self.FinalElectricalPower = 0.0
        self.FinalElectricalEnergy = 0.0
        self.InletMassFlowRate = 0.0
        self.InletTemp = 0.0
        self.InletWetBulbTemp = 0.0
        self.InletHumRat = 0.0
        self.InletEnthalpy = 0.0
        self.InletPressure = 0.0
        self.InletRH = 0.0
        self.OutletVolumetricFlowRate = 0.0
        self.OutletMassFlowRate = 0.0
        self.PowerLossToAir = 0.0
        self.FanHeatTemp = 0.0
        self.OutletTemp = 0.0
        self.OutletWetBulbTemp = 0.0
        self.OutletHumRat = 0.0
        self.OutletEnthalpy = 0.0
        self.OutletPressure = 0.0
        self.OutletRH = 0.0
        self.SecInletMassFlowRate = 0.0
        self.SecInletTemp = 0.0
        self.SecInletWetBulbTemp = 0.0
        self.SecInletHumRat = 0.0
        self.SecInletEnthalpy = 0.0
        self.SecInletPressure = 0.0
        self.SecInletRH = 0.0
        self.SecOutletMassFlowRate = 0.0
        self.SecOutletTemp = 0.0
        self.SecOutletWetBulbTemp = 0.0
        self.SecOutletHumRat = 0.0
        self.SecOutletEnthalpy = 0.0
        self.SecOutletPressure = 0.0
        self.SecOutletRH = 0.0
        self.Wsa = 0.0
        self.SupplyVentilationAir = 0.0
        self.SupplyVentilationVolume = 0.0
        self.OutdoorAir = False
        self.MinOA_Msa = 0.0
        self.OARequirementsPtr = 0
        self.Tsa = 0.0
        self.ModeCounter = 0
        self.CoolingRequested = False
        self.HeatingRequested = False
        self.VentilationRequested = False
        self.DehumidificationRequested = False
        self.HumidificationRequested = False
        # Initialize vectors
        self.SAT_OC_MetinMode_v = List[Int](repeating=0, count=25)
        self.SAHR_OC_MetinMode_v = List[Int](repeating=0, count=25)
        self.ModeCounter = 0
        self.CurrentOperatingSettings = List[CSetting](repeating=CSetting(), count=5)
        self.InitializeModelParams()

    def ResetOutputs(inout self):
        self.UnitTotalCoolingRate = 0
        self.UnitTotalCoolingEnergy = 0
        self.UnitSensibleCoolingRate = 0
        self.UnitSensibleCoolingEnergy = 0
        self.UnitLatentCoolingRate = 0
        self.UnitLatentCoolingEnergy = 0
        self.SystemTotalCoolingRate = 0
        self.SystemTotalCoolingEnergy = 0
        self.SystemSensibleCoolingRate = 0
        self.SystemSensibleCoolingEnergy = 0
        self.SystemLatentCoolingRate = 0
        self.SystemLatentCoolingEnergy = 0
        self.UnitTotalHeatingRate = 0
        self.UnitTotalHeatingEnergy = 0
        self.UnitSensibleHeatingRate = 0
        self.UnitSensibleHeatingEnergy = 0
        self.UnitLatentHeatingRate = 0
        self.UnitLatentHeatingEnergy = 0
        self.SystemTotalHeatingRate = 0
        self.SystemTotalHeatingEnergy = 0
        self.SystemSensibleHeatingRate = 0
        self.SystemSensibleHeatingEnergy = 0
        self.SystemLatentHeatingRate = 0
        self.SystemLatentHeatingEnergy = 0
        self.SupplyFanElectricPower = 0
        self.SupplyFanElectricEnergy = 0
        self.SecondaryFuelConsumptionRate = 0
        self.SecondaryFuelConsumption = 0
        self.ThirdFuelConsumptionRate = 0
        self.ThirdFuelConsumption = 0
        self.WaterConsumptionRate = 0
        self.WaterConsumption = 0
        self.ExternalStaticPressure = 0

    def InitializeModelParams(inout self):
        self.ResetOutputs()
        self.PrimaryMode = 0
        self.PrimaryModeRuntimeFraction = 0
        self.optimal_EnvCondMet = False
        self.Tsa = 0
        self.RunningPeakCapacity_EnvCondMet = False
        self.Settings.clear()

    def Initialize(inout self, ZoneNumber: Int):
        self.ZoneNum = ZoneNumber
        if self.Initialized:
            return
        self.Initialized = True
        for thisOperatingMode in self.OperatingModes:
            thisOperatingMode.GenerateSolutionSpace()
        self.Initialized = True

    def CheckVal_W(self, inout state: EnergyPlusData, W: Float64, T: Float64, P: Float64) -> Float64:
        var OutletRHtest: Float64 = PsyRhFnTdbWPb(state, T, W, P)
        var OutletW: Float64 = PsyWFnTdbRhPb(state, T, OutletRHtest, P, "Humidity ratio exceeded realistic range error called in " + self.Name + ", check performance curve")
        return OutletW

    def CheckVal_T(self, inout state: EnergyPlusData, T: Float64) -> Float64:
        if (T > 100) or (T < 0):
            ShowWarningError(state, String.format("Supply air temperature exceeded realistic range error called in {}, check performance curve", self.Name))
        return T

    def SetStandByMode(self, inout state: EnergyPlusData, Mode0: CMode, Tosa: Float64, Wosa: Float64, Tra: Float64, Wra: Float64) -> Bool:
        if len(Mode0.sol.MassFlowRatio) > 0:
            var MsaRatio: Float64 = Mode0.sol.MassFlowRatio[0]
            var OSAF: Float64 = Mode0.sol.OutdoorAirFraction[0]
            self.oStandBy.ScaledSupply_Air_Mass_Flow_Rate = MsaRatio * self.ScaledSystemMaximumSupplyAirMassFlowRate
            self.oStandBy.Unscaled_Supply_Air_Mass_Flow_Rate = self.oStandBy.ScaledSupply_Air_Mass_Flow_Rate / self.ScalingFactor
            self.oStandBy.ScaledSupply_Air_Ventilation_Volume = MsaRatio * self.ScaledSystemMaximumSupplyAirMassFlowRate / state.dataEnvrn.StdRhoAir
            self.oStandBy.Supply_Air_Mass_Flow_Rate_Ratio = MsaRatio
            self.oStandBy.ElectricalPower = Mode0.CalculateCurveVal(state, Tosa, Wosa, Tra, Wra, self.oStandBy.Unscaled_Supply_Air_Mass_Flow_Rate, OSAF, POWER_CURVE)
            self.oStandBy.Outdoor_Air_Fraction = OSAF
            self.oStandBy.SupplyAirTemperature = Tra
            self.oStandBy.SupplyAirW = Wra
            self.oStandBy.Mode = 0
            self.oStandBy.Mixed_Air_Temperature = Tra
            self.oStandBy.Mixed_Air_W = Wra
        else:
            return True
        return False

    def CalculateTimeStepAverage(self, val: SYSTEMOUTPUTS) -> Float64:
        var averagedVal: Float64 = 0
        var MassFlowDependentDenominator: Float64 = 0
        var value: Float64 = 0
        for thisOperatingSettings in self.CurrentOperatingSettings:
            if val == SYSTEMOUTPUTS.VENTILATION_AIR_V:
                value = thisOperatingSettings.ScaledSupply_Air_Ventilation_Volume
            elif val == SYSTEMOUTPUTS.SYSTEM_FUEL_USE:
                value = thisOperatingSettings.ElectricalPower
            elif val == SYSTEMOUTPUTS.OSUPPLY_FAN_POWER:
                value = thisOperatingSettings.SupplyFanElectricPower
            elif val == SYSTEMOUTPUTS.OSECOND_FUEL_USE:
                value = thisOperatingSettings.SecondaryFuelConsumptionRate
            elif val == SYSTEMOUTPUTS.OTHIRD_FUEL_USE:
                value = thisOperatingSettings.ThirdFuelConsumptionRate
            elif val == SYSTEMOUTPUTS.OEXTERNAL_STATIC_PRESSURE:
                value = thisOperatingSettings.ExternalStaticPressure * thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.OWATER_USE:
                value = thisOperatingSettings.WaterConsumptionRate
            elif val == SYSTEMOUTPUTS.SUPPLY_AIR_TEMP:
                value = thisOperatingSettings.SupplyAirTemperature * thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.MIXED_AIR_TEMP:
                value = thisOperatingSettings.Mixed_Air_Temperature * thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.SUPPLY_MASS_FLOW:
                value = thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.SUPPLY_AIR_HR:
                value = thisOperatingSettings.SupplyAirW * thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.MIXED_AIR_HR:
                value = thisOperatingSettings.Mixed_Air_W * thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate
            else:
                assert(False)
            var part_run: Float64 = thisOperatingSettings.Runtime_Fraction
            averagedVal = averagedVal + value * part_run
            MassFlowDependentDenominator = thisOperatingSettings.ScaledSupply_Air_Mass_Flow_Rate * part_run + MassFlowDependentDenominator

        var StandbyMode: CSetting = self.CurrentOperatingSettings[0]
        if val == SYSTEMOUTPUTS.SUPPLY_AIR_TEMP:
            if MassFlowDependentDenominator == 0:
                averagedVal = StandbyMode.SupplyAirTemperature
            else:
                averagedVal = averagedVal / MassFlowDependentDenominator
        elif val == SYSTEMOUTPUTS.OEXTERNAL_STATIC_PRESSURE:
            if MassFlowDependentDenominator == 0:
                averagedVal = StandbyMode.ExternalStaticPressure
            else:
                averagedVal = averagedVal / MassFlowDependentDenominator
        elif val == SYSTEMOUTPUTS.SUPPLY_AIR_HR:
            if MassFlowDependentDenominator == 0:
                averagedVal = StandbyMode.SupplyAirW
            else:
                averagedVal = averagedVal / MassFlowDependentDenominator
        elif val == SYSTEMOUTPUTS.MIXED_AIR_TEMP:
            if MassFlowDependentDenominator == 0:
                averagedVal = StandbyMode.Mixed_Air_Temperature
            else:
                averagedVal = averagedVal / MassFlowDependentDenominator
        elif val == SYSTEMOUTPUTS.MIXED_AIR_HR:
            if MassFlowDependentDenominator == 0:
                averagedVal = StandbyMode.Mixed_Air_W
            else:
                averagedVal = averagedVal / MassFlowDependentDenominator
        else:

        return averagedVal

    def CalculatePartRuntimeFraction(self, MinOA_Msa: Float64, Mvent: Float64, RequestedCoolingLoad: Float64, RequestedHeatingLoad: Float64, SensibleRoomORZone: Float64, RequestedDehumidificationLoad: Float64, RequestedMoistureLoad: Float64, LatentRoomORZone: Float64) -> Float64:
        var PLHumidRatio: Float64 = 0
        var PLDehumidRatio: Float64 = 0
        var PLVentRatio: Float64 = 0
        var PLSensibleCoolingRatio: Float64 = 0
        var PLSensibleHeatingRatio: Float64 = 0
        var PartRuntimeFraction: Float64 = 0
        PLHumidRatio = 0
        PLDehumidRatio = 0
        PLVentRatio = 0
        PLSensibleCoolingRatio = 0
        PLSensibleHeatingRatio = 0
        if Mvent > 0:
            PLVentRatio = MinOA_Msa / Mvent
        PartRuntimeFraction = PLVentRatio
        if SensibleRoomORZone > 0:
            PLSensibleCoolingRatio = abs(RequestedCoolingLoad) / abs(SensibleRoomORZone)
        if PLSensibleCoolingRatio > PartRuntimeFraction:
            PartRuntimeFraction = PLSensibleCoolingRatio
        if SensibleRoomORZone < 0:
            PLSensibleHeatingRatio = abs(RequestedHeatingLoad) / abs(SensibleRoomORZone)
        if PLSensibleHeatingRatio > PartRuntimeFraction:
            PartRuntimeFraction = PLSensibleHeatingRatio
        if RequestedDehumidificationLoad > 0:
            PLDehumidRatio = abs(RequestedDehumidificationLoad) / abs(LatentRoomORZone)
        if PLDehumidRatio > PartRuntimeFraction:
            PartRuntimeFraction = PLDehumidRatio
        if RequestedMoistureLoad > 0:
            PLHumidRatio = abs(RequestedMoistureLoad) / abs(LatentRoomORZone)
        if PLHumidRatio > PartRuntimeFraction:
            PartRuntimeFraction = PLHumidRatio
        if PartRuntimeFraction < 0:
            PartRuntimeFraction = 0
        if PartRuntimeFraction > 1:
            PartRuntimeFraction = 1
        return PartRuntimeFraction

    def ParseMode(inout self, inout state: EnergyPlusData, Alphas: List[String], cAlphaFields: List[String], Numbers: List[Float64], lAlphaBlanks: List[Bool], lNumericBlanks: List[Bool], cCurrentModuleObject: String) -> Bool:
        var newMode: CMode = CMode()
        var error: Bool = newMode.ParseMode(state, self.ModeCounter, self.OperatingModes, self.ScalingFactor, Alphas, cAlphaFields, Numbers, lAlphaBlanks, lNumericBlanks, cCurrentModuleObject)
        self.ModeCounter = self.ModeCounter + 1
        return error

    def MeetsSupplyAirTOC(self, inout state: EnergyPlusData, Tsupplyair: Float64) -> Bool:
        var MinSAT: Float64 = 10
        var MaxSAT: Float64 = 20
        if self.TsaMinSched != None:
            MinSAT = self.TsaMinSched.getCurrentVal()
        if self.TsaMaxSched != None:
            MaxSAT = self.TsaMaxSched.getCurrentVal()
        if Tsupplyair < MinSAT or Tsupplyair > MaxSAT:
            return False
        return True

    def MeetsSupplyAirRHOC(self, inout state: EnergyPlusData, SupplyW: Float64) -> Bool:
        var MinRH: Float64 = 0
        var MaxRH: Float64 = 1
        if self.RHsaMinSched != None:
            MinRH = self.RHsaMinSched.getCurrentVal()
        if self.RHsaMaxSched != None:
            MaxRH = self.RHsaMaxSched.getCurrentVal()
        if SupplyW < MinRH or SupplyW > MaxRH:
            return False
        return True

    def SetOperatingSetting(inout self, inout state: EnergyPlusData, StepIns: CStepInputs) -> Int:
        var DidWeMeetLoad: Bool = False
        var DidWeMeetHumidification: Bool = False
        var DidWePartlyMeetLoad: Bool = False
        var OptimalSetting_RunFractionTotalFuel: Float64 = IMPLAUSIBLE_POWER
        var Tma: Float64 = 0
        var Wma: Float64 = 0
        var Hsa: Float64 = 0
        var Hma: Float64 = 0
        var PreviousMaxiumConditioningOutput: Float64 = 0
        var PreviousMaxiumHumidOrDehumidOutput: Float64 = 0
        var ObjectID: String = self.Name
        if StepIns.RHosa > 1:
            ShowSevereError(state, String.format("Unitary hybrid system error, required relative humidity value 0-1, called in object{}.Check inputs", ObjectID))
            assert(True)
            return -1
        if StepIns.RHra > 1:
            ShowSevereError(state, String.format("Unitary hybrid system error,  required relative humidity value 0-1, called in object{}.Check inputs", ObjectID))
            assert(True)
            return -1
        var Wosa: Float64 = PsyWFnTdbRhPb(state, StepIns.Tosa, StepIns.RHosa, state.dataEnvrn.OutBaroPress)
        var Wra: Float64 = PsyWFnTdbRhPb(state, StepIns.Tra, StepIns.RHra, self.InletPressure)
        var EnvironmentConditionsMet: Bool = False
        var EnvironmentConditionsMetOnce: Bool = False
        var MinVRMet: Bool = False
        var SAT_OC_MetOnce: Bool = False
        var SAHR_OC_MetOnce: Bool = False
        EnvironmentConditionsMetOnce = False
        SAT_OC_MetOnce = False
        SAHR_OC_MetOnce = False
        self.MinOA_Msa = StepIns.MinimumOA

        var iterator_index: Int = 1
        while iterator_index < len(self.OperatingModes):
            var Mode: CMode = self.OperatingModes[iterator_index]
            var SAHR_OC_MetinMode: Bool = False
            var SAT_OC_MetinMode: Bool = False
            var solution_map_sizeX: Int = len(Mode.sol.MassFlowRatio)
            var solution_map_sizeY: Int = len(Mode.sol.OutdoorAirFraction)
            if Mode.MeetsConstraints(StepIns.Tosa, Wosa, 100 * StepIns.RHosa, StepIns.Tra, Wra, 100 * StepIns.RHra):
                EnvironmentConditionsMet = True
                EnvironmentConditionsMetOnce = True
            else:
                EnvironmentConditionsMet = False

            if EnvironmentConditionsMet:
                var indexMassFlowRatio: Int = 0
                while indexMassFlowRatio < solution_map_sizeX:
                    var indexOutdoorAirFraction: Int = 0
                    while indexOutdoorAirFraction < solution_map_sizeY:
                        var MsaRatio: Float64 = Mode.sol.MassFlowRatio[indexMassFlowRatio]
                        var OSAF: Float64 = Mode.sol.OutdoorAirFraction[indexOutdoorAirFraction]
                        var ScaledMsa: Float64 = self.ScaledSystemMaximumSupplyAirMassFlowRate * MsaRatio
                        var UnscaledMsa: Float64 = self.ScaledSystemMaximumSupplyAirMassFlowRate / self.ScalingFactor
                        var Supply_Air_Ventilation_Volume: Float64 = 0
                        var Mvent: Float64 = ScaledMsa * OSAF
                        if state.dataEnvrn.StdRhoAir > 1:
                            Supply_Air_Ventilation_Volume = Mvent / state.dataEnvrn.StdRhoAir
                        else:
                            Supply_Air_Ventilation_Volume = Mvent / 1.225
                        if Mvent - self.MinOA_Msa > -0.000001:
                            MinVRMet = True
                        else:
                            MinVRMet = False
                        if MinVRMet:
                            StepIns.Tosa = self.SecInletTemp
                            StepIns.Tra = self.InletTemp
                            var FanPower: Float64 = Mode.CalculateCurveVal(state, StepIns.Tosa, Wosa, StepIns.Tra, Wra, UnscaledMsa, OSAF, SUPPLY_FAN_POWER) * self.ScalingFactor
                            if self.FanHeatGain and self.FanHeatGainLocation == "MIXEDAIRSTREAM":
                                self.PowerLossToAir = FanPower * self.FanHeatInAirFrac
                            else:
                                self.PowerLossToAir = 0.0
                            var FanHeatTempOA: Float64 = self.PowerLossToAir / (PsyCpAirFnW(Wosa) * (ScaledMsa * OSAF))
                            StepIns.Tosa = StepIns.Tosa + FanHeatTempOA
                            if OSAF < 1.0:
                                var FanHeatTempRA: Float64 = self.PowerLossToAir / (PsyCpAirFnW(Wra) * (ScaledMsa * (1 - OSAF)))
                                StepIns.Tra = StepIns.Tra + FanHeatTempRA
                            self.Tsa = Mode.CalculateCurveVal(state, StepIns.Tosa, Wosa, StepIns.Tra, Wra, UnscaledMsa, OSAF, TEMP_CURVE)
                            self.Wsa = Mode.CalculateCurveVal(state, StepIns.Tosa, Wosa, StepIns.Tra, Wra, Un