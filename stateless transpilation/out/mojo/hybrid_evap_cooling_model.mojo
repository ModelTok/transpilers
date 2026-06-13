"""
EnergyPlus HybridEvapCoolingModel - Mojo Port
Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
The Regents of the University of California, through Lawrence Berkeley National Laboratory
(subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
contributors. All rights reserved.
"""

from math import fabs, max, min
from collections import List

alias Real64 = Float64
alias Int = Int32

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying dataEnvrn, dataGlobal, dataHVACGlobal
# - Psychrometrics functions: PsyRhFnTdbWPb, PsyWFnTdbRhPb, PsyHFnTdbW, PsyHfgAirFnWTdb, PsyCpAirFnW, PsyHFnTdbRhPb
# - Curve functions: CurveValue, GetCurveIndex, GetCurveMinMaxValues
# - Show functions: ShowSevereError, ShowWarningError, ShowContinueError
# - Schedule: Schedule

alias MINIMUM_LOAD_TO_ACTIVATE = 0.5
alias IMPLAUSIBLE_POWER = 10000000

alias TEMP_CURVE = 0
alias W_CURVE = 1
alias POWER_CURVE = 2
alias SUPPLY_FAN_POWER = 3
alias EXTERNAL_STATIC_PRESSURE = 4
alias SECOND_FUEL_USE = 5
alias THIRD_FUEL_USE = 6
alias WATER_USE = 7


@value
struct SYSTEMOUTPUTS:
    alias Invalid = -1
    alias VENTILATION_AIR_V = 0
    alias SUPPLY_MASS_FLOW = 1
    alias SYSTEM_FUEL_USE = 2
    alias SUPPLY_AIR_TEMP = 3
    alias MIXED_AIR_TEMP = 4
    alias SUPPLY_AIR_HR = 5
    alias MIXED_AIR_HR = 6
    alias OSUPPLY_FAN_POWER = 7
    alias OSECOND_FUEL_USE = 8
    alias OTHIRD_FUEL_USE = 9
    alias OWATER_USE = 10
    alias OEXTERNAL_STATIC_PRESSURE = 11
    alias Num = 12


@value
struct ObjectiveFunctionType:
    alias Invalid = -1
    alias ElectricityUse = 0
    alias SecondFuelUse = 1
    alias ThirdFuelUse = 2
    alias WaterUse = 3
    alias Num = 4


@value
struct CModeSolutionSpace:
    var MassFlowRatio: List[Real64]
    var OutdoorAirFraction: List[Real64]

    fn __init__(inout self):
        self.MassFlowRatio = List[Real64]()
        self.OutdoorAirFraction = List[Real64]()


@value
struct CMode:
    var ModeID: Int
    var sol: CModeSolutionSpace
    var ModeName: String
    var Tsa_curve_pointer: Int
    var HRsa_curve_pointer: Int
    var Psa_curve_pointer: Int
    var SFPsa_curve_pointer: Int
    var ESPsa_curve_pointer: Int
    var SFUsa_curve_pointer: Int
    var TFUsa_curve_pointer: Int
    var WUsa_curve_pointer: Int
    var Max_Msa: Real64
    var Min_Msa: Real64
    var Min_OAF: Real64
    var Max_OAF: Real64
    var Minimum_Outdoor_Air_Temperature: Real64
    var Maximum_Outdoor_Air_Temperature: Real64
    var Minimum_Outdoor_Air_Temperature_Blank: Bool
    var Maximum_Outdoor_Air_Temperature_Blank: Bool
    var Minimum_Outdoor_Air_Humidity_Ratio: Real64
    var Maximum_Outdoor_Air_Humidity_Ratio: Real64
    var Minimum_Outdoor_Air_Relative_Humidity: Real64
    var Maximum_Outdoor_Air_Relative_Humidity: Real64
    var Minimum_Return_Air_Temperature: Real64
    var Maximum_Return_Air_Temperature: Real64
    var Minimum_Return_Air_Temperature_Blank: Bool
    var Maximum_Return_Air_Temperature_Blank: Bool
    var Minimum_Return_Air_Humidity_Ratio: Real64
    var Maximum_Return_Air_Humidity_Ratio: Real64
    var Minimum_Return_Air_Relative_Humidity: Real64
    var Maximum_Return_Air_Relative_Humidity: Real64
    var ModelScalingFactor: Real64
    var MODE_BLOCK_OFFSET_Alpha: Int
    var BLOCK_HEADER_OFFSET_Alpha: Int
    var MODE1_BLOCK_OFFSET_Number: Int
    var MODE_BLOCK_OFFSET_Number: Int
    var BLOCK_HEADER_OFFSET_Number: Int

    fn __init__(inout self):
        self.ModeID = 0
        self.sol = CModeSolutionSpace()
        self.ModeName = ""
        self.Tsa_curve_pointer = -1
        self.HRsa_curve_pointer = -1
        self.Psa_curve_pointer = -1
        self.SFPsa_curve_pointer = -1
        self.ESPsa_curve_pointer = -1
        self.SFUsa_curve_pointer = -1
        self.TFUsa_curve_pointer = -1
        self.WUsa_curve_pointer = -1
        self.Max_Msa = 0.0
        self.Min_Msa = 0.0
        self.Min_OAF = 0.0
        self.Max_OAF = 0.0
        self.Minimum_Outdoor_Air_Temperature = 0.0
        self.Maximum_Outdoor_Air_Temperature = 0.0
        self.Minimum_Outdoor_Air_Temperature_Blank = False
        self.Maximum_Outdoor_Air_Temperature_Blank = False
        self.Minimum_Outdoor_Air_Humidity_Ratio = 0.0
        self.Maximum_Outdoor_Air_Humidity_Ratio = 0.0
        self.Minimum_Outdoor_Air_Relative_Humidity = 0.0
        self.Maximum_Outdoor_Air_Relative_Humidity = 0.0
        self.Minimum_Return_Air_Temperature = 0.0
        self.Maximum_Return_Air_Temperature = 0.0
        self.Minimum_Return_Air_Temperature_Blank = False
        self.Maximum_Return_Air_Temperature_Blank = False
        self.Minimum_Return_Air_Humidity_Ratio = 0.0
        self.Maximum_Return_Air_Humidity_Ratio = 0.0
        self.Minimum_Return_Air_Relative_Humidity = 0.0
        self.Maximum_Return_Air_Relative_Humidity = 0.0
        self.ModelScalingFactor = 0.0
        self.MODE_BLOCK_OFFSET_Alpha = 9
        self.BLOCK_HEADER_OFFSET_Alpha = 20
        self.MODE1_BLOCK_OFFSET_Number = 2
        self.MODE_BLOCK_OFFSET_Number = 16
        self.BLOCK_HEADER_OFFSET_Number = 6

    fn valid_pointer(self, curve_pointer: Int) -> Bool:
        return curve_pointer >= 0

    fn calculate_curve_val(self, state, tosa: Real64, wosa: Real64, tra: Real64, wra: Real64,
                           msa: Real64, osaf: Real64, curve_type: Int) -> Real64:
        var y_val: Real64 = 0.0
        
        if curve_type == TEMP_CURVE:
            if self.valid_pointer(self.Tsa_curve_pointer):
                y_val = CurveValue(state, self.Tsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = tra
        elif curve_type == W_CURVE:
            if self.valid_pointer(self.HRsa_curve_pointer):
                y_val = CurveValue(state, self.HRsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
                y_val = max(min(y_val, 1.0), 0.0)
            else:
                y_val = wra
        elif curve_type == POWER_CURVE:
            if self.valid_pointer(self.Psa_curve_pointer):
                y_val = self.ModelScalingFactor * CurveValue(state, self.Psa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        elif curve_type == SUPPLY_FAN_POWER:
            if self.valid_pointer(self.SFPsa_curve_pointer):
                y_val = self.ModelScalingFactor * CurveValue(state, self.SFPsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        elif curve_type == EXTERNAL_STATIC_PRESSURE:
            if self.valid_pointer(self.ESPsa_curve_pointer):
                y_val = CurveValue(state, self.ESPsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        elif curve_type == SECOND_FUEL_USE:
            if self.valid_pointer(self.SFUsa_curve_pointer):
                y_val = self.ModelScalingFactor * CurveValue(state, self.SFUsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        elif curve_type == THIRD_FUEL_USE:
            if self.valid_pointer(self.TFUsa_curve_pointer):
                y_val = self.ModelScalingFactor * CurveValue(state, self.TFUsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        elif curve_type == WATER_USE:
            if self.valid_pointer(self.WUsa_curve_pointer):
                y_val = self.ModelScalingFactor * CurveValue(state, self.WUsa_curve_pointer, tosa, wosa, tra, wra, msa, osaf)
            else:
                y_val = 0.0
        
        return y_val

    fn initialize_curve(inout self, curve_type: Int, curve_id: Int) -> None:
        if curve_type == TEMP_CURVE:
            self.Tsa_curve_pointer = curve_id
        elif curve_type == W_CURVE:
            self.HRsa_curve_pointer = curve_id
        elif curve_type == POWER_CURVE:
            self.Psa_curve_pointer = curve_id
        elif curve_type == SUPPLY_FAN_POWER:
            self.SFPsa_curve_pointer = curve_id
        elif curve_type == EXTERNAL_STATIC_PRESSURE:
            self.ESPsa_curve_pointer = curve_id
        elif curve_type == SECOND_FUEL_USE:
            self.SFUsa_curve_pointer = curve_id
        elif curve_type == THIRD_FUEL_USE:
            self.TFUsa_curve_pointer = curve_id
        elif curve_type == WATER_USE:
            self.WUsa_curve_pointer = curve_id

    fn initialize_osaf_constraints(inout self, min_osaf: Real64, max_osaf: Real64) -> None:
        self.Min_OAF = min_osaf
        self.Max_OAF = max_osaf

    fn initialize_msa_ratio_constraints(inout self, min_msa: Real64, max_msa: Real64) -> None:
        self.Min_Msa = min_msa
        self.Max_Msa = max_msa

    fn initialize_outdoor_air_temperature_constraints(inout self, min_val: Real64, max_val: Real64,
                                                       min_blank: Bool, max_blank: Bool) -> None:
        self.Minimum_Outdoor_Air_Temperature = min_val
        self.Maximum_Outdoor_Air_Temperature = max_val
        self.Minimum_Outdoor_Air_Temperature_Blank = min_blank
        self.Maximum_Outdoor_Air_Temperature_Blank = max_blank

    fn initialize_outdoor_air_humidity_ratio_constraints(inout self, min_val: Real64, max_val: Real64) -> None:
        self.Minimum_Outdoor_Air_Humidity_Ratio = min_val
        self.Maximum_Outdoor_Air_Humidity_Ratio = max_val

    fn initialize_outdoor_air_relative_humidity_constraints(inout self, min_val: Real64, max_val: Real64) -> None:
        self.Minimum_Outdoor_Air_Relative_Humidity = min_val
        self.Maximum_Outdoor_Air_Relative_Humidity = max_val

    fn initialize_return_air_temperature_constraints(inout self, min_val: Real64, max_val: Real64,
                                                      min_blank: Bool, max_blank: Bool) -> None:
        self.Minimum_Return_Air_Temperature = min_val
        self.Maximum_Return_Air_Temperature = max_val
        self.Minimum_Return_Air_Temperature_Blank = min_blank
        self.Maximum_Return_Air_Temperature_Blank = max_blank

    fn initialize_return_air_humidity_ratio_constraints(inout self, min_val: Real64, max_val: Real64) -> None:
        self.Minimum_Return_Air_Humidity_Ratio = min_val
        self.Maximum_Return_Air_Humidity_Ratio = max_val

    fn initialize_return_air_relative_humidity_constraints(inout self, min_val: Real64, max_val: Real64) -> None:
        self.Minimum_Return_Air_Relative_Humidity = min_val
        self.Maximum_Return_Air_Relative_Humidity = max_val

    fn generate_solution_space(inout self) -> None:
        if self.Min_Msa == self.Max_Msa:
            self.sol.MassFlowRatio.append(self.Max_Msa)
        else:
            var resolution_msa = (self.Max_Msa - self.Min_Msa) * 0.2
            var msa_val = self.Max_Msa
            while msa_val >= self.Min_Msa:
                self.sol.MassFlowRatio.append(msa_val)
                msa_val -= resolution_msa

        if self.Min_OAF == self.Max_OAF:
            self.sol.OutdoorAirFraction.append(self.Max_OAF)
        else:
            var resolution_osa = (self.Max_OAF - self.Min_OAF) * 0.2
            var oaf_val = self.Max_OAF
            while oaf_val >= self.Min_OAF:
                self.sol.OutdoorAirFraction.append(oaf_val)
                oaf_val -= resolution_osa

    fn meets_constraints(self, tosa: Real64, wosa: Real64, rhosa: Real64, tra: Real64,
                         wra: Real64, rhra: Real64) -> Bool:
        var oa_temp_constraint_met = (self.Minimum_Outdoor_Air_Temperature_Blank or
                                      tosa >= self.Minimum_Outdoor_Air_Temperature) and \
                                    (self.Maximum_Outdoor_Air_Temperature_Blank or
                                     tosa <= self.Maximum_Outdoor_Air_Temperature)
        var oa_hr_constraint_met = (wosa >= self.Minimum_Outdoor_Air_Humidity_Ratio and
                                   wosa <= self.Maximum_Outdoor_Air_Humidity_Ratio)
        var oa_rh_constraint_met = (rhosa >= self.Minimum_Outdoor_Air_Relative_Humidity and
                                   rhosa <= self.Maximum_Outdoor_Air_Relative_Humidity)
        
        var ra_temp_constraint_met = (self.Minimum_Return_Air_Temperature_Blank or
                                      tra >= self.Minimum_Return_Air_Temperature) and \
                                    (self.Maximum_Return_Air_Temperature_Blank or
                                     tra <= self.Maximum_Return_Air_Temperature)
        var ra_hr_constraint_met = (wra >= self.Minimum_Return_Air_Humidity_Ratio and
                                   wra <= self.Maximum_Return_Air_Humidity_Ratio)
        var ra_rh_constraint_met = (rhra >= self.Minimum_Return_Air_Relative_Humidity and
                                   rhra <= self.Maximum_Return_Air_Relative_Humidity)
        
        return (oa_temp_constraint_met and oa_hr_constraint_met and oa_rh_constraint_met and
                ra_temp_constraint_met and ra_hr_constraint_met and ra_rh_constraint_met)


@value
struct CSetting:
    var Runtime_Fraction: Real64
    var Mode: Int
    var Outdoor_Air_Fraction: Real64
    var Unscaled_Supply_Air_Mass_Flow_Rate: Real64
    var ScaledSupply_Air_Mass_Flow_Rate: Real64
    var Supply_Air_Ventilation_Volume: Real64
    var ScaledSupply_Air_Ventilation_Volume: Real64
    var Supply_Air_Mass_Flow_Rate_Ratio: Real64
    var SupplyAirTemperature: Real64
    var Mixed_Air_Temperature: Real64
    var SupplyAirW: Real64
    var Mixed_Air_W: Real64
    var TotalSystem: Real64
    var SensibleSystem: Real64
    var LatentSystem: Real64
    var TotalZone: Real64
    var SensibleZone: Real64
    var LatentZone: Real64
    var ElectricalPower: Real64
    var SupplyFanElectricPower: Real64
    var SecondaryFuelConsumptionRate: Real64
    var ThirdFuelConsumptionRate: Real64
    var WaterConsumptionRate: Real64
    var ExternalStaticPressure: Real64
    var oMode: CMode

    fn __init__(inout self):
        self.Runtime_Fraction = 0.0
        self.Mode = 0
        self.Outdoor_Air_Fraction = 0.0
        self.Unscaled_Supply_Air_Mass_Flow_Rate = 0.0
        self.ScaledSupply_Air_Mass_Flow_Rate = 0.0
        self.Supply_Air_Ventilation_Volume = 0.0
        self.ScaledSupply_Air_Ventilation_Volume = 0.0
        self.Supply_Air_Mass_Flow_Rate_Ratio = 0.0
        self.SupplyAirTemperature = 0.0
        self.Mixed_Air_Temperature = 0.0
        self.SupplyAirW = 0.0
        self.Mixed_Air_W = 0.0
        self.TotalSystem = 0.0
        self.SensibleSystem = 0.0
        self.LatentSystem = 0.0
        self.TotalZone = 0.0
        self.SensibleZone = 0.0
        self.LatentZone = 0.0
        self.ElectricalPower = IMPLAUSIBLE_POWER
        self.SupplyFanElectricPower = 0.0
        self.SecondaryFuelConsumptionRate = 0.0
        self.ThirdFuelConsumptionRate = 0.0
        self.WaterConsumptionRate = 0.0
        self.ExternalStaticPressure = 0.0
        self.oMode = CMode()


@value
struct CStepInputs:
    var Tosa: Real64
    var Tra: Real64
    var RHosa: Real64
    var RHra: Real64
    var RequestedCoolingLoad: Real64
    var RequestedHeatingLoad: Real64
    var ZoneMoistureLoad: Real64
    var ZoneDehumidificationLoad: Real64
    var MinimumOA: Real64

    fn __init__(inout self):
        self.Tosa = 0.0
        self.Tra = 0.0
        self.RHosa = 0.0
        self.RHra = 0.0
        self.RequestedCoolingLoad = 0.0
        self.RequestedHeatingLoad = 0.0
        self.ZoneMoistureLoad = 0.0
        self.ZoneDehumidificationLoad = 0.0
        self.MinimumOA = 0.0


@value
struct Model:
    var Name: String
    var Initialized: Bool
    var ZoneNum: Int
    var SystemMaximumSupplyAirFlowRate: Real64
    var FanHeatGain: Bool
    var FanHeatGainLocation: String
    var FanHeatInAirFrac: Real64
    var ScalingFactor: Real64
    var ScaledSystemMaximumSupplyAirMassFlowRate: Real64
    var ObjectiveFunction: Int
    var UnitOn: Int
    var UnitTotalCoolingRate: Real64
    var UnitSensibleCoolingRate: Real64
    var UnitLatentCoolingRate: Real64
    var SystemTotalCoolingRate: Real64
    var SystemSensibleCoolingRate: Real64
    var SystemLatentCoolingRate: Real64
    var UnitTotalHeatingRate: Real64
    var UnitSensibleHeatingRate: Real64
    var UnitLatentHeatingRate: Real64
    var SystemTotalHeatingRate: Real64
    var SystemSensibleHeatingRate: Real64
    var SystemLatentHeatingRate: Real64
    var SupplyFanElectricPower: Real64
    var SecondaryFuelConsumptionRate: Real64
    var ThirdFuelConsumptionRate: Real64
    var WaterConsumptionRate: Real64
    var QSensZoneOut: Real64
    var QLatentZoneOut: Real64
    var QLatentZoneOutMass: Real64
    var ExternalStaticPressure: Real64
    var RequestedHumidificationLoad: Real64
    var RequestedDeHumidificationLoad: Real64
    var RequestedLoadToHeatingSetpoint: Real64
    var RequestedLoadToCoolingSetpoint: Real64
    var PrimaryMode: Int
    var PrimaryModeRuntimeFraction: Real64
    var averageOSAF: Real64
    var ErrorCode: Int
    var StandBy: Bool
    var InletNode: Int
    var OutletNode: Int
    var SecondaryInletNode: Int
    var SecondaryOutletNode: Int
    var FinalElectricalPower: Real64
    var InletMassFlowRate: Real64
    var InletTemp: Real64
    var InletHumRat: Real64
    var InletEnthalpy: Real64
    var InletPressure: Real64
    var InletRH: Real64
    var OutletVolumetricFlowRate: Real64
    var OutletMassFlowRate: Real64
    var PowerLossToAir: Real64
    var FanHeatTemp: Real64
    var OutletTemp: Real64
    var OutletHumRat: Real64
    var OutletEnthalpy: Real64
    var OutletPressure: Real64
    var OutletRH: Real64
    var SecInletMassFlowRate: Real64
    var SecInletTemp: Real64
    var SecInletHumRat: Real64
    var SecInletEnthalpy: Real64
    var SecInletPressure: Real64
    var SecInletRH: Real64
    var SecOutletMassFlowRate: Real64
    var SecOutletTemp: Real64
    var SecOutletHumRat: Real64
    var SecOutletEnthalpy: Real64
    var SecOutletPressure: Real64
    var SecOutletRH: Real64
    var Wsa: Real64
    var SupplyVentilationAir: Real64
    var SupplyVentilationVolume: Real64
    var MinOA_Msa: Real64
    var Tsa: Real64
    var ModeCounter: Int
    var CoolingRequested: Bool
    var HeatingRequested: Bool
    var VentilationRequested: Bool
    var DehumidificationRequested: Bool
    var HumidificationRequested: Bool
    var OperatingModes: List[CMode]
    var CurrentOperatingSettings: List[CSetting]
    var OptimalSetting: CSetting
    var oStandBy: CSetting
    var Settings: List[CSetting]
    var WarnOnceFlag: Bool
    var count_EnvironmentConditionsNotMet: Int
    var count_DidWeNotMeetLoad: Int
    var SAT_OC_MetinMode_v: List[Int]
    var SAHR_OC_MetinMode_v: List[Int]

    fn __init__(inout self):
        self.Name = ""
        self.Initialized = False
        self.ZoneNum = 0
        self.SystemMaximumSupplyAirFlowRate = 0.0
        self.FanHeatGain = False
        self.FanHeatGainLocation = ""
        self.FanHeatInAirFrac = 0.0
        self.ScalingFactor = 0.0
        self.ScaledSystemMaximumSupplyAirMassFlowRate = 0.0
        self.ObjectiveFunction = ObjectiveFunctionType.ElectricityUse
        self.UnitOn = 0
        self.UnitTotalCoolingRate = 0.0
        self.UnitSensibleCoolingRate = 0.0
        self.UnitLatentCoolingRate = 0.0
        self.SystemTotalCoolingRate = 0.0
        self.SystemSensibleCoolingRate = 0.0
        self.SystemLatentCoolingRate = 0.0
        self.UnitTotalHeatingRate = 0.0
        self.UnitSensibleHeatingRate = 0.0
        self.UnitLatentHeatingRate = 0.0
        self.SystemTotalHeatingRate = 0.0
        self.SystemSensibleHeatingRate = 0.0
        self.SystemLatentHeatingRate = 0.0
        self.SupplyFanElectricPower = 0.0
        self.SecondaryFuelConsumptionRate = 0.0
        self.ThirdFuelConsumptionRate = 0.0
        self.WaterConsumptionRate = 0.0
        self.QSensZoneOut = 0.0
        self.QLatentZoneOut = 0.0
        self.QLatentZoneOutMass = 0.0
        self.ExternalStaticPressure = 0.0
        self.RequestedHumidificationLoad = 0.0
        self.RequestedDeHumidificationLoad = 0.0
        self.RequestedLoadToHeatingSetpoint = 0.0
        self.RequestedLoadToCoolingSetpoint = 0.0
        self.PrimaryMode = 0
        self.PrimaryModeRuntimeFraction = 0.0
        self.averageOSAF = 0.0
        self.ErrorCode = 0
        self.StandBy = False
        self.InletNode = 0
        self.OutletNode = 0
        self.SecondaryInletNode = 0
        self.SecondaryOutletNode = 0
        self.FinalElectricalPower = 0.0
        self.InletMassFlowRate = 0.0
        self.InletTemp = 0.0
        self.InletHumRat = 0.0
        self.InletEnthalpy = 0.0
        self.InletPressure = 0.0
        self.InletRH = 0.0
        self.OutletVolumetricFlowRate = 0.0
        self.OutletMassFlowRate = 0.0
        self.PowerLossToAir = 0.0
        self.FanHeatTemp = 0.0
        self.OutletTemp = 0.0
        self.OutletHumRat = 0.0
        self.OutletEnthalpy = 0.0
        self.OutletPressure = 0.0
        self.OutletRH = 0.0
        self.SecInletMassFlowRate = 0.0
        self.SecInletTemp = 0.0
        self.SecInletHumRat = 0.0
        self.SecInletEnthalpy = 0.0
        self.SecInletPressure = 0.0
        self.SecInletRH = 0.0
        self.SecOutletMassFlowRate = 0.0
        self.SecOutletTemp = 0.0
        self.SecOutletHumRat = 0.0
        self.SecOutletEnthalpy = 0.0
        self.SecOutletPressure = 0.0
        self.SecOutletRH = 0.0
        self.Wsa = 0.0
        self.SupplyVentilationAir = 0.0
        self.SupplyVentilationVolume = 0.0
        self.MinOA_Msa = 0.0
        self.Tsa = 0.0
        self.ModeCounter = 0
        self.CoolingRequested = False
        self.HeatingRequested = False
        self.VentilationRequested = False
        self.DehumidificationRequested = False
        self.HumidificationRequested = False
        self.OperatingModes = List[CMode]()
        self.CurrentOperatingSettings = List[CSetting]()
        self.OptimalSetting = CSetting()
        self.oStandBy = CSetting()
        self.Settings = List[CSetting]()
        self.WarnOnceFlag = False
        self.count_EnvironmentConditionsNotMet = 0
        self.count_DidWeNotMeetLoad = 0
        self.SAT_OC_MetinMode_v = List[Int]()
        self.SAHR_OC_MetinMode_v = List[Int]()
        for _ in range(25):
            self.SAT_OC_MetinMode_v.append(0)
            self.SAHR_OC_MetinMode_v.append(0)
        for _ in range(5):
            self.CurrentOperatingSettings.append(CSetting())
        self.initialize_model_params()

    fn current_primary_mode(self) -> Int:
        if self.CurrentOperatingSettings.size() > 0:
            return self.CurrentOperatingSettings[0].Mode
        return -1

    fn current_primary_runtime_fraction(self) -> Real64:
        if self.CurrentOperatingSettings.size() > 0:
            return self.CurrentOperatingSettings[0].Runtime_Fraction
        return -1.0

    fn calculate_part_runtime_fraction(self, min_oa_msa: Real64, mvent: Real64,
                                       requested_cooling_load: Real64, requested_heating_load: Real64,
                                       sensible_room_or_zone: Real64, requested_dehumidification_load: Real64,
                                       requested_moisture_load: Real64, latent_room_or_zone: Real64) -> Real64:
        var pl_humid_ratio: Real64 = 0.0
        var pl_dehumid_ratio: Real64 = 0.0
        var pl_vent_ratio: Real64 = 0.0
        var pl_sensible_cooling_ratio: Real64 = 0.0
        var pl_sensible_heating_ratio: Real64 = 0.0

        if mvent > 0:
            pl_vent_ratio = min_oa_msa / mvent

        var part_runtime_fraction = pl_vent_ratio

        if sensible_room_or_zone > 0:
            pl_sensible_cooling_ratio = fabs(requested_cooling_load) / fabs(sensible_room_or_zone)

        if pl_sensible_cooling_ratio > part_runtime_fraction:
            part_runtime_fraction = pl_sensible_cooling_ratio

        if sensible_room_or_zone < 0:
            pl_sensible_heating_ratio = fabs(requested_heating_load) / fabs(sensible_room_or_zone)

        if pl_sensible_heating_ratio > part_runtime_fraction:
            part_runtime_fraction = pl_sensible_heating_ratio

        if requested_dehumidification_load > 0:
            pl_dehumid_ratio = fabs(requested_dehumidification_load) / fabs(latent_room_or_zone)

        if pl_dehumid_ratio > part_runtime_fraction:
            part_runtime_fraction = pl_dehumid_ratio

        if requested_moisture_load > 0:
            pl_humid_ratio = fabs(requested_moisture_load) / fabs(latent_room_or_zone)

        if pl_humid_ratio > part_runtime_fraction:
            part_runtime_fraction = pl_humid_ratio

        if part_runtime_fraction < 0:
            part_runtime_fraction = 0.0

        if part_runtime_fraction > 1:
            part_runtime_fraction = 1.0

        return part_runtime_fraction

    fn reset_outputs(inout self) -> None:
        self.UnitTotalCoolingRate = 0.0
        self.UnitSensibleCoolingRate = 0.0
        self.UnitLatentCoolingRate = 0.0
        self.SystemTotalCoolingRate = 0.0
        self.SystemSensibleCoolingRate = 0.0
        self.SystemLatentCoolingRate = 0.0
        self.UnitTotalHeatingRate = 0.0
        self.UnitSensibleHeatingRate = 0.0
        self.UnitLatentHeatingRate = 0.0
        self.SystemTotalHeatingRate = 0.0
        self.SystemSensibleHeatingRate = 0.0
        self.SystemLatentHeatingRate = 0.0
        self.SupplyFanElectricPower = 0.0
        self.SecondaryFuelConsumptionRate = 0.0
        self.ThirdFuelConsumptionRate = 0.0
        self.WaterConsumptionRate = 0.0
        self.ExternalStaticPressure = 0.0

    fn initialize_model_params(inout self) -> None:
        self.reset_outputs()
        self.PrimaryMode = 0
        self.PrimaryModeRuntimeFraction = 0.0
        self.Tsa = 0.0
        self.Settings.clear()

    fn initialize(inout self, zone_number: Int) -> None:
        self.ZoneNum = zone_number
        if self.Initialized:
            return
        self.Initialized = True
        for i in range(self.OperatingModes.size()):
            self.OperatingModes[i].generate_solution_space()
        self.Initialized = True

    fn check_val_w(self, state, w: Real64, t: Real64, p: Real64) -> Real64:
        var outlet_rh_test = PsyRhFnTdbWPb(state, t, w, p)
        var outlet_w = PsyWFnTdbRhPb(state, t, outlet_rh_test, p)
        return outlet_w

    fn check_val_t(self, state, t: Real64) -> Real64:
        if (t > 100) or (t < 0):
            ShowWarningError(state, "Supply air temperature exceeded realistic range error called in " + self.Name + ", check performance curve")
        return t

    fn meets_supply_air_toc(self, state, tsupplyair: Real64) -> Bool:
        var min_sat: Real64 = 10.0
        var max_sat: Real64 = 20.0
        if tsupplyair < min_sat or tsupplyair > max_sat:
            return False
        return True

    fn meets_supply_air_rhoc(self, state, supply_w: Real64) -> Bool:
        var min_rh: Real64 = 0.0
        var max_rh: Real64 = 1.0
        if supply_w < min_rh or supply_w > max_rh:
            return False
        return True

    fn set_stand_by_mode(inout self, state, mode0: CMode, tosa: Real64, wosa: Real64, tra: Real64, wra: Real64) -> Bool:
        if mode0.sol.MassFlowRatio.size() > 0:
            var msa_ratio = mode0.sol.MassFlowRatio[0]
            var osaf = mode0.sol.OutdoorAirFraction[0]

            self.oStandBy.ScaledSupply_Air_Mass_Flow_Rate = msa_ratio * self.ScaledSystemMaximumSupplyAirMassFlowRate
            self.oStandBy.Unscaled_Supply_Air_Mass_Flow_Rate = self.oStandBy.ScaledSupply_Air_Mass_Flow_Rate / self.ScalingFactor
            self.oStandBy.ScaledSupply_Air_Ventilation_Volume = msa_ratio * self.ScaledSystemMaximumSupplyAirMassFlowRate
            self.oStandBy.Supply_Air_Mass_Flow_Rate_Ratio = msa_ratio
            self.oStandBy.ElectricalPower = mode0.calculate_curve_val(state, tosa, wosa, tra, wra,
                                                                      self.oStandBy.Unscaled_Supply_Air_Mass_Flow_Rate,
                                                                      osaf, POWER_CURVE)
            self.oStandBy.Outdoor_Air_Fraction = osaf
            self.oStandBy.SupplyAirTemperature = tra
            self.oStandBy.SupplyAirW = wra
            self.oStandBy.Mode = 0
            self.oStandBy.Mixed_Air_Temperature = tra
            self.oStandBy.Mixed_Air_W = wra
        else:
            return True

        return False

    fn calculate_time_step_average(self, val: Int) -> Real64:
        var averaged_val: Real64 = 0.0
        var mass_flow_dependent_denominator: Real64 = 0.0
        var value: Real64 = 0.0

        for i in range(self.CurrentOperatingSettings.size()):
            var this_operating_settings = self.CurrentOperatingSettings[i]
            if val == SYSTEMOUTPUTS.VENTILATION_AIR_V:
                value = this_operating_settings.ScaledSupply_Air_Ventilation_Volume
            elif val == SYSTEMOUTPUTS.SYSTEM_FUEL_USE:
                value = this_operating_settings.ElectricalPower
            elif val == SYSTEMOUTPUTS.OSUPPLY_FAN_POWER:
                value = this_operating_settings.SupplyFanElectricPower
            elif val == SYSTEMOUTPUTS.OSECOND_FUEL_USE:
                value = this_operating_settings.SecondaryFuelConsumptionRate
            elif val == SYSTEMOUTPUTS.OTHIRD_FUEL_USE:
                value = this_operating_settings.ThirdFuelConsumptionRate
            elif val == SYSTEMOUTPUTS.OEXTERNAL_STATIC_PRESSURE:
                value = this_operating_settings.ExternalStaticPressure * this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.OWATER_USE:
                value = this_operating_settings.WaterConsumptionRate
            elif val == SYSTEMOUTPUTS.SUPPLY_AIR_TEMP:
                value = this_operating_settings.SupplyAirTemperature * this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.MIXED_AIR_TEMP:
                value = this_operating_settings.Mixed_Air_Temperature * this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.SUPPLY_MASS_FLOW:
                value = this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.SUPPLY_AIR_HR:
                value = this_operating_settings.SupplyAirW * this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate
            elif val == SYSTEMOUTPUTS.MIXED_AIR_HR:
                value = this_operating_settings.Mixed_Air_W * this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate

            var part_run = this_operating_settings.Runtime_Fraction
            averaged_val = averaged_val + value * part_run
            mass_flow_dependent_denominator = this_operating_settings.ScaledSupply_Air_Mass_Flow_Rate * part_run + mass_flow_dependent_denominator

        var standby_mode = self.CurrentOperatingSettings[0]
        if val == SYSTEMOUTPUTS.SUPPLY_AIR_TEMP:
            if mass_flow_dependent_denominator == 0:
                averaged_val = standby_mode.SupplyAirTemperature
            else:
                averaged_val = averaged_val / mass_flow_dependent_denominator
        elif val == SYSTEMOUTPUTS.OEXTERNAL_STATIC_PRESSURE:
            if mass_flow_dependent_denominator == 0:
                averaged_val = standby_mode.ExternalStaticPressure
            else:
                averaged_val = averaged_val / mass_flow_dependent_denominator
        elif val == SYSTEMOUTPUTS.SUPPLY_AIR_HR:
            if mass_flow_dependent_denominator == 0:
                averaged_val = standby_mode.SupplyAirW
            else:
                averaged_val = averaged_val / mass_flow_dependent_denominator
        elif val == SYSTEMOUTPUTS.MIXED_AIR_TEMP:
            if mass_flow_dependent_denominator == 0:
                averaged_val = standby_mode.Mixed_Air_Temperature
            else:
                averaged_val = averaged_val / mass_flow_dependent_denominator
        elif val == SYSTEMOUTPUTS.MIXED_AIR_HR:
            if mass_flow_dependent_denominator == 0:
                averaged_val = standby_mode.Mixed_Air_W
            else:
                averaged_val = averaged_val / mass_flow_dependent_denominator

        return averaged_val

    fn determine_cooling_ventilation_or_humidification_needs(inout self, inout step_ins: CStepInputs) -> None:
        self.CoolingRequested = False
        self.HeatingRequested = False
        self.VentilationRequested = False
        self.DehumidificationRequested = False
        self.HumidificationRequested = False

        if step_ins.RequestedCoolingLoad >= MINIMUM_LOAD_TO_ACTIVATE:
            self.CoolingRequested = True
            step_ins.RequestedHeatingLoad = 0.0

        if step_ins.RequestedHeatingLoad <= -MINIMUM_LOAD_TO_ACTIVATE:
            self.HeatingRequested = True
            step_ins.RequestedCoolingLoad = 0.0

        if step_ins.MinimumOA > 0:
            self.VentilationRequested = True

        if step_ins.ZoneDehumidificationLoad < 0:
            self.DehumidificationRequested = True
            step_ins.ZoneMoistureLoad = 0.0

        if step_ins.ZoneMoistureLoad > 0:
            step_ins.ZoneDehumidificationLoad = 0.0
            self.HumidificationRequested = True

    fn do_step(inout self, state, requested_cooling_load: Real64, requested_heating_load: Real64,
               output_required_to_humidify: Real64, output_required_to_dehumidify: Real64,
               design_min_vr: Real64) -> None:
        self.RequestedLoadToHeatingSetpoint = requested_heating_load
        self.RequestedLoadToCoolingSetpoint = requested_cooling_load

        var lambda_ra = PsyHfgAirFnWTdb(0, self.InletTemp)
        self.RequestedHumidificationLoad = output_required_to_humidify * lambda_ra
        self.RequestedDeHumidificationLoad = output_required_to_dehumidify * lambda_ra

        self.MinOA_Msa = design_min_vr

        var step_ins = CStepInputs()
        step_ins.Tosa = self.SecInletTemp
        step_ins.Tra = self.InletTemp
        step_ins.RHosa = self.SecInletRH
        step_ins.RHra = self.InletRH
        step_ins.RequestedCoolingLoad = -requested_cooling_load
        step_ins.RequestedHeatingLoad = -requested_heating_load
        step_ins.ZoneMoistureLoad = self.RequestedHumidificationLoad
        step_ins.ZoneDehumidificationLoad = self.RequestedDeHumidificationLoad
        step_ins.MinimumOA = design_min_vr

        var wosa = PsyWFnTdbRhPb(state, step_ins.Tosa, step_ins.RHosa, state.dataEnvrn.OutBaroPress)
        var wra = PsyWFnTdbRhPb(state, step_ins.Tra, step_ins.RHra, self.InletPressure)

        self.determine_cooling_ventilation_or_humidification_needs(step_ins)

        var mode = self.OperatingModes[0]
        if self.set_stand_by_mode(state, mode, step_ins.Tosa, wosa, step_ins.Tra, wra):
            ShowSevereError(state,
                "Standby mode not defined correctly, as the mode is defined there are zero combinations of acceptable outside air "
                "fractions and supply air mass flow rate, called in object " + self.Name)

        self.UnitOn = 1
        var force_off = False
        self.StandBy = False

        for i in range(1, self.CurrentOperatingSettings.size()):
            self.CurrentOperatingSettings[i] = CSetting()

        if (not self.CoolingRequested and not self.HeatingRequested and not self.VentilationRequested and
            not self.HumidificationRequested and not self.DehumidificationRequested) or force_off:
            self.StandBy = True
            self.oStandBy.Runtime_Fraction = 1.0
            self.CurrentOperatingSettings[0] = self.oStandBy
            self.ErrorCode = 0
            self.PrimaryMode = 0
            self.PrimaryModeRuntimeFraction = 0.0

        var q_tot_zone_out: Real64 = 0.0

        self.SupplyVentilationVolume = self.calculate_time_step_average(SYSTEMOUTPUTS.VENTILATION_AIR_V)
        self.OutletTemp = self.check_val_t(state, self.calculate_time_step_average(SYSTEMOUTPUTS.SUPPLY_AIR_TEMP))
        self.OutletHumRat = self.check_val_w(state, self.calculate_time_step_average(SYSTEMOUTPUTS.SUPPLY_AIR_HR),
                                             self.OutletTemp, self.OutletPressure)

        self.OutletRH = PsyRhFnTdbWPb(state, self.OutletTemp, self.OutletHumRat, self.OutletPressure)
        var operating_average_mixed_air_temperature = self.calculate_time_step_average(SYSTEMOUTPUTS.MIXED_AIR_TEMP)
        var operating_mixed_air_w = self.calculate_time_step_average(SYSTEMOUTPUTS.MIXED_AIR_HR)
        var mixed_air_enthalpy = PsyHFnTdbW(operating_average_mixed_air_temperature, operating_mixed_air_w)
        self.OutletEnthalpy = PsyHFnTdbRhPb(state, self.OutletTemp, self.OutletRH, self.InletPressure)
        self.OutletMassFlowRate = self.calculate_time_step_average(SYSTEMOUTPUTS.SUPPLY_MASS_FLOW)

        if not self.StandBy:
            var outlet_cp = PsyCpAirFnW(self.OutletHumRat)
            var return_cp = PsyCpAirFnW(wra)
            var outlet_mass_flow_rate_dry = self.OutletMassFlowRate * (1 - self.Wsa)
            var lambda_sa = PsyHfgAirFnWTdb(0, self.OutletTemp)
            self.QLatentZoneOutMass = outlet_mass_flow_rate_dry * (self.InletHumRat - self.OutletHumRat)
            self.QLatentZoneOut = self.QLatentZoneOutMass * lambda_sa
            q_tot_zone_out = outlet_mass_flow_rate_dry * (self.InletEnthalpy - self.OutletEnthalpy)

            self.reset_outputs()

            if q_tot_zone_out > 0:
                self.UnitTotalCoolingRate = fabs(q_tot_zone_out)
            else:
                self.UnitTotalHeatingRate = fabs(q_tot_zone_out)

            self.SupplyFanElectricPower = self.calculate_time_step_average(SYSTEMOUTPUTS.OSUPPLY_FAN_POWER)
            self.SecondaryFuelConsumptionRate = self.calculate_time_step_average(SYSTEMOUTPUTS.OSECOND_FUEL_USE)
            self.ThirdFuelConsumptionRate = self.calculate_time_step_average(SYSTEMOUTPUTS.OTHIRD_FUEL_USE)
            self.WaterConsumptionRate = self.calculate_time_step_average(SYSTEMOUTPUTS.OWATER_USE)
            self.ExternalStaticPressure = self.calculate_time_step_average(SYSTEMOUTPUTS.OEXTERNAL_STATIC_PRESSURE)

            self.FinalElectricalPower = self.calculate_time_step_average(SYSTEMOUTPUTS.SYSTEM_FUEL_USE)
        else:
            self.QSensZoneOut = 0.0
            self.QLatentZoneOut = 0.0
            self.QLatentZoneOutMass = 0.0
            self.reset_outputs()


fn GetCurveIndex(state, name: String) -> Int:
    return 0


fn CurveValue(state, curve_id: Int, x1: Real64, x2: Real64, x3: Real64, x4: Real64, x5: Real64, x6: Real64) -> Real64:
    return 0.0


fn GetCurveMinMaxValues(state, curve_id: Int):
    pass


fn ShowSevereError(state, message: String) -> None:
    pass


fn ShowWarningError(state, message: String) -> None:
    pass


fn ShowContinueError(state, message: String) -> None:
    pass


fn PsyRhFnTdbWPb(state, tdb: Real64, w: Real64, pb: Real64) -> Real64:
    return 0.0


fn PsyWFnTdbRhPb(state, tdb: Real64, rh: Real64, pb: Real64) -> Real64:
    return 0.0


fn PsyHFnTdbW(tdb: Real64, w: Real64) -> Real64:
    return 0.0


fn PsyCpAirFnW(w: Real64) -> Real64:
    return 0.0


fn PsyHfgAirFnWTdb(w: Real64, tdb: Real64) -> Real64:
    return 0.0


fn PsyHFnTdbRhPb(state, tdb: Real64, rh: Real64, pb: Real64) -> Real64:
    return 0.0
